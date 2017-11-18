require 'rubygems'
require 'data_mapper'

require_relative 'tools'
require_relative 'config'
require_relative 'stats'
# require_relative 'date'


class Logline
  include DataMapper::Resource

  property :id, Serial
  # property :logline, Text, :required => true
  property :filename, String
  property :server, String, :required => true
  property :service, String, :required => true
  property :log_format, String, :required => true # тип формата лога
  property :type, String, :required => true # строка с описанием типа шаблона
  property :regex_id, Integer, :required => true # что-то вроде уникального номера шаблона
  property :date, DateTime, :required => true
  has n, :linedatas # пары ключ-значений

  def Logline.save_parsed_lines(parsed_lines)
    cnt = 0
    t = Time.now
    resourses = parsed_lines.map do |parsed_line|
      cnt += 1
      Printer::debug who:"Database", msg:"Создаем ресурсы: #{cnt}", in_place:true # if cnt % Printer::LOG_EVERY_N == 0
      linedatas = Linedata.create_from_hash parsed_line[:linedata]
      parsed_line.delete(:linedata)
      parsed_line.delete(:regex)
      Logline.new(parsed_line.update(linedatas:linedatas))
    end
    puts
    Printer::debug who:"Database",msg:"Создание завершено за #{(Time.now-t).round} секунд"
    cnt = 0
    Logline.transaction do |t|
      resourses.each do |logline| 
        cnt += 1
        if logline.save
          Printer::debug who:"Database", msg:"Сохраняем ресурсы: #{cnt}", in_place:true
        else
          logline.errors.each do |error|
            Printer::debug who:"Ошибки", msg:error
          end
        end
      end
    end
  end
end

class Linedata
  include DataMapper::Resource

  property :id, Serial
  property :field_name, String, :required => true
  property :field_value, String, :required => true, :length => 128
  belongs_to :logline

  def Linedata.create_from_hash(linedata)
    linedata_models = []
    linedata.each_pair do |field_name,field_value| 
      linedata_models << Linedata.new(
        field_name:field_name,
        field_value:field_value
      )
    end
    linedata_models
  end
end

# class Database
#   # Saves log to database storage. Completely rewrites a database file
#   #
#   # @raise [ArgumentError] invalid argument was passed
#   # @raise [DataObjects::ConnectionError] database is not available
#   # @param [Array] table an array with parsed logs
#   # @param [String] filename name of the database
#   # @return [True, False] returns True if saving was successful
#   def Database.save!(filename, table)
#     Printer::note(msg:"Database file not found: #{filename}") if !File.exists?(filename)
#     begin
#       DataMapper.setup(:default, "sqlite3://#{filename}")
#       Printer::debug(msg:"Setup was complete: #{filename}")
#       DataMapper.auto_migrate!
#       Printer::debug(msg:"Migration was successful")
#     rescue ArgumentError => what
#       Printer::error(msg:what.to_s)
#       raise
#     rescue DataObjects::ConnectionError => what
#       Printer::error(msg:what.to_s)
#       raise
#     end
#     resources = []
#     stat = Stats::Stats.new(  [
#       ["Counter", :requests, "Всего запросов"],
#       ["Counter", :success, "Успешно сохранено"],
#       ["HashCounter", :errors, "Не сохранено"],
#       ["Counter", :ignored, "Проигнорировано"]
#     ])
#     table.each_with_index do |logline, i|
#       stat.requests.increment
#       Printer::debug(msg:"Creating resources #{(i+1).to_s.red+'/'.white+table.size.to_s.red}", who:"Database", in_place:true)
#       # if logline[:type] != "Wrong format" && logline[:type] != "Ignore"
#       linedata = []
#       logline.keys.keep_if{ |key| key.class == String }.each do |key|
#         value = logline[key]
#         linedata << {:name => key, :value => value}
#       end
#       resources << Logline.new(
#         server: logline[:server],
#         service: logline[:service],
#         date: logline[:date],
#         linedatas: linedata,
#         type: logline[:type],
#         uid: logline[:uid]
#       )
#       # else
#         # stat.ignored.increment
#       # end
#     end
#     puts
#     Printer::debug(msg:"Закончили создание ресурсов, начинаем сохранение", who:"Database")
#     Logline.transaction do |t|
#       resources.each_with_index do |resource, i|
#         Printer::debug(msg:"Saving to database #{(i+1).to_s.red+'/'.white+stat.requests.to_s.red}", who:"Database", in_place:true)
#         if resource.save
#           stat[:success].increment
#         else
#           stat[:errors].increment table[i]
#         end
#       end
#     end
#     puts
#     stat.print
#     return stat[:errors].value.size == 0
#   end

#   # Load data from database file
#   #
#   # @param [String] filename absolute path to database file
#   # @return [Array] data retrieved from the database
#   # @raise [Error::FileNotExistError] database file does not exist
#   # @raise [DataObjects::ConnectionError] database is not available
#   def Database.load(filename)
#     if !File.exists?(filename)
#       Printer::error(msg:"File #{filename} does not exist")
#       raise Error::FileNotExistError(filename)
#     end
#     begin
#       DataMapper.setup(:default, "sqlite3://#{filename}")
#       Printer::debug(msg:"Setup was complete: #{filename}")
#       DataMapper.auto_upgrade!
#       Printer::debug(msg:"Migration was successful")
#     rescue ArgumentError => what
#       Printer::error(msg:what.to_s)
#       raise
#     rescue DataObjects::ConnectionError => what
#       Printer::error(msg:what.to_s)
#       raise
#     end
#     table = []
#     Logline.all.each do |logline|
#       table << logline.to_h
#     end
#     return table
#   end
# end

DataMapper.finalize
Printer::debug(msg:"Models were finalized", who:"Database")
# An in-memory Sqlite3 connection:
DataMapper.setup(:default, 'sqlite::memory:')
Printer::debug msg:"Соединение с базой данных установлено", who:"Database"
DataMapper.auto_migrate!