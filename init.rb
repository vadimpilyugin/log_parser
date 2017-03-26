system "clear"
puts("Preparation: Initialization started")

require_relative 'src/tools'
require_relative 'src/config'
# require_relative 'src/server'

parse_logs = Config['overall']['parse_logs']
create_report = Config['overall']['create_report']
# parse_logs = false # чтобы не парсить логи заново, можно пропустить эту часть
# create_report = false

Printer::debug("============= Log Parser v1.2 ============"+"\n\n", debug_msg:"\n\nMain")
# Printer::debug("Parse log file at #{}", debug_msg:"Main")


if parse_logs == 'true'
  require_relative 'src/parser'
  require_relative 'src/db'
  
  Parser.parse!  
  # Выгружаем распарсенный лог в базу данных
  Database.save(Parser.table)
end

# Создаем отчеты по базе данных
if create_report == 'true'
  require_relative 'src/reporter'
  Report.init

  # Запускаем сервер
  require 'sinatra'
  configure do
    # set :bind, "138.68.105.137"
    # set :port, 4567
    # set :public_folder, File.dirname(__FILE__)+'/public'
    # set :root, File.dirname(__FILE__)
  end

  get '/' do
    report_file = Config["report"]["report_file"]
    # result = ""
    # result << "<PRE>"
    # Report.stats.each do |stat|
    #   result << "++++++++++++++ New Stat +++++++++++++++\n"
    #   result << "Name: #{stat.descr}\n"
    #   result << "Service: #{stat.service}\n"
    #   result << "Value: #{stat.result.class == Fixnum ? stat.result : stat.result}\n"
    # end
    # result << "</PRE>\n"
    # result

    # Массив статистик
    @ar = Report.stats
    # У каждой статистики есть свойство descr и result

    slim :main
  end

  # get '/id/:id' do |id|
  #   Reference[id]
  # end
end
