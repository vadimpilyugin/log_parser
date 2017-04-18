gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require  'dm-migrations'
require  'dm-aggregates'
require 'dm-transactions'

require_relative 'tools'
require_relative 'config'
require_relative 'stats'


class Logline
  include DataMapper::Resource

  property :id, Serial
  property :server, String, :required => true
  property :service, String, :required => true
  property :time, DateTime, :required => true
                            # 2010-11-03T21:33:00-0600; all(:time => start_t..end_t)
                            # Logline.create(:time => DateTime.new(2011,1,1,0,0,4)) 
                            # Logline.all(:time => DateTime.parse('2011-1-1T00:00:04+0100'))
  property :type, String
  has n, :linedatas  
end

class Linedata
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :value, String, :required => true, :length => 512
  belongs_to :logline
end

# Database.save!(table) - сохраняет массив в базу данных
# table - массив хэшей(такой же формат, как у парсера)
# Database.init - создать соединение с базой
# filename - полный путь до базы

class Database
  def Database.init(filename)
    DataMapper.finalize
    Printer::note(expr:!File.exists?(filename), msg:"Database file not found: #{filename}")
    DataMapper.setup(:default, "sqlite3://#{filename}")
    Printer::debug(msg:"Connection to database #{filename} was established", who:"Database")
    DataMapper.auto_upgrade!
    Printer::note(expr:Logline.all.size == 0, msg:"Database is empty!")
  end
  def Database.save!(table)
    resources = []
    stat = Stats::Stats.new(  [
      ["Counter", :requests, "Всего запросов"],
      ["Counter", :success, "Успешно сохранено"],
      ["HashCounter", :errors, "Не сохранено"],
      ["Counter", :ignored, "Проигнорировано"]
    ])
    table.each_with_index do |logline, i|
      stat.requests.increment
      Printer::debug(msg:"Creating resources #{(i+1).to_s.red+'/'.white+table.size.to_s.red}", who:"Database", in_place:true)
      if logline[:descr] != "Wrong format" && logline[:descr] != "Ignore"
        linedata = []
        logline[:data].each_pair do |key,value|
          linedata << {:name => key, :value => value}
        end
        resources << Logline.new(
          server: logline[:server],
          service: logline[:service],
          time: logline[:date],
          linedatas: linedata,
          type: logline[:descr]
        )
      else
        stat.ignored.increment
      end
    end
    puts
    Printer::debug(msg:"Закончили создание ресурсов, начинаем сохранение", who:"Database")
    Logline.transaction do |t|
      resources.each_with_index do |resource, i|
        Printer::debug(msg:"Saving to database #{(i+1).to_s.red+'/'.white+stat.requests.to_s.red}", who:"Database", in_place:true)
        if resource.save
          stat[:success].increment
        else
          stat[:errors].increment
        end
      end
    end
    puts
    stat.print
  end
end