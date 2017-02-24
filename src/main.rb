HOME = unshift(File.expand_path("../", __FILE__))
$:.HOME

require 'tools'
require 'config'
require 'parser'
require 'db'
require 'aggregator'
require 'reporter'
require 'server'

Tools.chdir

# database_file = "archive/access.sqlite3"
# log_file = "logs/access.log"
report_only = true	# чтобы не парсить логи заново, можно пропустить эту часть
without_report = false # чтобы отослать готовый отчет

if !report_only
  # Подготовка данных для парсера
  p = Parser::Parser.new filename: "logs/auth-test_log"
  p.parse!
  
  q = Parser::Parser.new filename: "logs/access.log"
  q.parse!
  
  # Выгружаем распарсенный лог в базу данных
  Database::Database.new drop: true
  Database::Database.save p.table
  
  Database::Database.save q.table
end

# Создаем отчеты по базе данных
unless without_report
  a = Reporter::Reporter.new
  a.report()
end

# Запускаем сервер
require 'sinatra'

set :bind, "138.68.105.137"
set :port, 4567

report_file = Config["reporter"]["report_file"]
get '/' do
  send_file report_file
end

get '/id/:id' do |id|
  Reference[id]
end
