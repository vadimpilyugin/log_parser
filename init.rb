system "clear"
puts("Preparation: Initialization started")
require_relative 'src/tools'
require_relative 'src/config'

puts
puts
Printer::debug(msg:"============= Log Parser v1.2 ============", who:"Init")
puts
puts

parse_logs = Config['overall']['parse_logs'] == 'true' ? true : false
create_report = Config['overall']['create_report'] == 'true' ? true : false

# Printer::debug("Parse log file at #{}", debug_msg:"Main")


if parse_logs
  require_relative 'src/parser'
  require_relative 'src/db'
  require_relative 'src/loader'

  if !Dir.exists? 'archive'
    Dir.mkdir 'archive'
  end
  if !File.exists? Config["database"]["database_file"]
    fn = Tools.abs_path Config["database"]["database_file"]
    `touch #{fn}`
    Printer::assert(expr:Tools.file_exists?(Config["database"]["database_file"]), msg:"Database file was not created")
  end
  Database.init Tools.abs_path(Config["database"]["database_file"])
  Loader.get_logs_names.each_pair do | server, files |
    files.each do |filename|
      table = Parser.parse!(filename,server)
      Database.save!(table)
    end
  end
end

# Создаем отчеты по базе данных
if create_report
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
