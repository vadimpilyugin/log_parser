gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require  'dm-migrations'
require  'dm-aggregates'
require 'dm-transactions'

require_relative 'tools'
require_relative 'config'
require_relative 'stats'
require_relative 'date'


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
  property :uid, Integer
  has n, :linedatas

  @regular_keys = Set.new ["id","server", "service", "time", "type", "linedatas"]
  def self.is_regular? (key)
    return @regular_keys.include?(key.to_s)
  end
  def data_keys
    self.linedatas.map { |data| data.name }
  end
  def datas_at(keys)
    result = []
    for key in keys
      result << data_at(key)
    end
    result
  end
  def to_h
    result = Hash.new
    result.update(:server => self.server,
                  :service => self.service,
                  :date => CreateDate.datetime_to_time(self.time),
                  :type => self.type,
                  :uid => self.uid)
    for data in self.linedatas
      result.update(data.name => data.value)
    end
    return result
  end
  def data_at (key)
    if Logline.is_regular? key
      return self[key]
    elsif data_keys.include? key
      return self.linedatas.first(:name => key).value
    else
      return nil
    end
  end
end

class Linedata
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :value, String, :required => true, :length => 100
  belongs_to :logline
end

# Class that allows you to save and load processed data from log files
# 
class Database
  DataMapper.finalize
  Printer::debug(msg:"Models were finalized", who:"Database")

  # Saves log to database storage. Completely rewrites a database file
  #
  # @raise [ArgumentError] invalid argument was passed
  # @raise [DataObjects::ConnectionError] database is not available
  # @param [Array] table an array with parsed logs
  # @param [String] filename name of the database
  # @return [True, False] returns True if saving was successful
  def Database.save!(filename, table)
    Printer::note(msg:"Database file not found: #{filename}") if !File.exists?(filename)
    begin
      DataMapper.setup(:default, "sqlite3://#{filename}")
      Printer::debug(msg:"Setup was complete: #{filename}")
      DataMapper.auto_migrate!
      Printer::debug(msg:"Migration was successful")
    rescue ArgumentError => what
      Printer::error(msg:what.to_s)
      raise
    rescue DataObjects::ConnectionError => what
      Printer::error(msg:what.to_s)
      raise
    end
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
      # if logline[:type] != "Wrong format" && logline[:type] != "Ignore"
      linedata = []
      logline.keys.keep_if{ |key| key.class == String }.each do |key|
        value = logline[key]
        linedata << {:name => key, :value => value}
      end
      resources << Logline.new(
        server: logline[:server],
        service: logline[:service],
        time: logline[:date],
        linedatas: linedata,
        type: logline[:type],
        uid: logline[:uid]
      )
      # else
        # stat.ignored.increment
      # end
    end
    puts
    Printer::debug(msg:"Закончили создание ресурсов, начинаем сохранение", who:"Database")
    Logline.transaction do |t|
      resources.each_with_index do |resource, i|
        Printer::debug(msg:"Saving to database #{(i+1).to_s.red+'/'.white+stat.requests.to_s.red}", who:"Database", in_place:true)
        if resource.save
          stat[:success].increment
        else
          stat[:errors].increment table[i]
        end
      end
    end
    puts
    stat.print
    return stat[:errors].value.size == 0
  end

  # Load data from database file
  #
  # @param [String] filename absolute path to database file
  # @return [Array] data retrieved from the database
  # @raise [Error::FileNotExistError] database file does not exist
  # @raise [DataObjects::ConnectionError] database is not available
  def Database.load(filename)
    if !File.exists?(filename)
      Printer::error(msg:"File #{filename} does not exist")
      raise Error::FileNotExistError(filename)
    end
    begin
      DataMapper.setup(:default, "sqlite3://#{filename}")
      Printer::debug(msg:"Setup was complete: #{filename}")
      DataMapper.auto_upgrade!
      Printer::debug(msg:"Migration was successful")
    rescue ArgumentError => what
      Printer::error(msg:what.to_s)
      raise
    rescue DataObjects::ConnectionError => what
      Printer::error(msg:what.to_s)
      raise
    end
    table = []
    Logline.all.each do |logline|
      table << logline.to_h
    end
    return table
  end
end