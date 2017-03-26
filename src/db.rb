gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require  'dm-migrations'
require  'dm-aggregates'
require 'dm-transactions'

require_relative 'tools'
require_relative 'config'


class Logline
  include DataMapper::Resource

  property :id, Serial
  property :server, String, :required => true
  property :service, String, :required => true
  property :time, DateTime, :required => true
                            # 2010-11-03T21:33:00-0600; all(:time => start_t..end_t)
                            # Logline.create(:time => DateTime.new(2011,1,1,0,0,4)) 
                            # Logline.all(:time => DateTime.parse('2011-1-1T00:00:04+0100'))
  property :descr, String
  has n, :linedatas  
end

class Linedata
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :value, String, :required => true, :length => 512
  belongs_to :logline
end

# Database.save!(table,filename) - сохраняет массив в базу данных
# table - массив хэшей(такой же формат, как у парсера)
# filename - путь до базы данных от корня

class Database
  def save!(table, filename)

    Printer::note(!File.exists?(filename), "Database file not found", "Filename":filename)
    DataMapper.setup(:default, "sqlite3://#{filename}")
    Printer::debug("Connection to database was established", debug_msg:"Database", "Database file":filename)
    DataMapper.finalize
    DataMapper.auto_upgrade!
    Printer::note(Logline.all.size == 0, "Database is empty!", msg:"Database")
  end
public
  def Database.save(table)
    resources = []
    stat = {:requests => 0, :success => 0, :errors => {},:errors_cnt => 0}
    table.each_with_index do |hsh, i|
      stat[:requests] += 1
      Printer::debug("Creating resources #{stat[:requests].to_s.red+'/'.white+table.size.to_s.red}", debug_msg:"Database", in_place:1234)
      resources << Logline.new(
        server: hsh[:server],
        service: hsh[:service],
        time: hsh[:time],
        linedatas: hsh[:data_values],
        descr: hsh[:descr]
      )
    end
    Printer::debug("Закончили создание ресурсов, начинаем сохранение", debug_msg:"\nDatabase")
    Logline.transaction do |t|
      resources.each_with_index do |resource, i|
        Printer::debug("Saving to database #{(i+1).to_s.red+'/'.white+stat[:requests].to_s.red}", debug_msg:"Database", in_place:1234)
        success = resource.save
        if success
          stat[:success] += 1
        else
          stat[:errors].update(resource.id => resource.full_messages)
          stat[:errors_cnt] += 1
        end
        # Printer::debug(success, debug_msg:"Запись ##{i} сохранена")
      end
    end
    max = 10
    Printer::debug("",debug_msg:"\n==================")
    Printer::debug("#{stat[:requests].to_s.red+" total requests".green}",debug_msg:"Saving finished")
    Printer::debug("",debug_msg:"#{stat[:success].to_s.red+"".green} resources successfully saved")
    size = stat[:errors].values.size
    stat[:errors] = stat[:errors].to_a[0..max].to_h
    Printer::debug("",stat[:errors].update(debug_msg:"#{stat[:errors_cnt].to_s.red+"".green} resources were not saved"))
    Printer::debug("",debug_msg:"\tShow #{(size-max).to_s.red+"".green} more") if size > max
    Printer::debug("",debug_msg:"==================")
    # Printer::assert(0 == 1, "",msg:"Breakpoint")
  end
end

Database.new