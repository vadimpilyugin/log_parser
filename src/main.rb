require_relative 'tools'
require_relative 'config'
require_relative 'parser'
require_relative 'db'
# require_relative 'aggregator'
# require_relative 'reporter'
# require_relative 'server'

parse_logs = Config['overall']['parse_logs']
create_report = Config['overall']['create_report']
# parse_logs = false # чтобы не парсить логи заново, можно пропустить эту часть
# create_report = false
system "clear"
Printer::debug("============= Log Parser v1.2 ============", debug_msg:"Main")
# Printer::debug("Parse log file at #{}", debug_msg:"Main")


if parse_logs
  Parser.parse!  
  # Выгружаем распарсенный лог в базу данных
  Database.save(Parser.table)
end

# Создаем отчеты по базе данных
if create_report
  a = Reporter::Reporter.new
  a.report()

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
end