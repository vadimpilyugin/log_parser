$:.unshift(File.expand_path("../", __FILE__))

require 'config'
require 'parser'
require 'db'
require 'aggregator'
require 'reporter'
require 'tools'

Config.new
Chdir.chdir
Tools.clean

# database_file = "archive/access.sqlite3"
# log_file = "logs/access.log"
report_only = true	# чтобы не парсить логи заново, можно пропустить эту часть

if !report_only
  # Подготовка данных для парсера
  p = Parser::Parser.new
  p.parse!
  
  # Выгружаем распарсенный лог в базу данных
  Database::Database.new drop: true #filename: database_file, drop: true
  Database::Database.save p.table
end

# Создаем отчеты по базе данных
a = Reporter::Reporter.new
a.report()

# Запускаем сервер
require 'sinatra'

report_file = Config["reporter"]["report_file"]
get '/' do
  send_file report_file
end
get '/tmp/:filename' do |fn|
  printf "tmp/#{fn}\n"
  send_file "tmp/#{fn}"
end
get '/tmp' do
  "Hello, World!"
end