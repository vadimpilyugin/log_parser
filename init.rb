system "clear"
puts("Preparation: Initialization started")

require_relative 'src/tools'
require_relative 'src/config'
require_relative 'src/parser'
require_relative 'src/loader'
require_relative 'src/db'
require_relative 'src/helpers'

puts
puts
Printer::debug(msg:"============= Log Parser v1.2 ============", who:"Init")
puts
puts

save_results = Config['database']['save_result'] == 'true' ? true : false
create_report = Config['overall']['create_report'] == 'true' ? true : false
load_from_file = Config['overall']['load_from_file'] == 'false' ? false : Tools.abs_path(Config['overall']['load_from_file'])

table = []
if load_from_file
  table = Database.load load_from_file
else
  Loader.get_logs_names.each_pair do | server, files |
    files.each do |filename|
      table += Parser.parse!(filename,server)
      Printer::debug(who:"Init", msg:"#{filename} was successfully parsed, now table has #{table.size.to_s.red+"".white} lines")
    end
  end
end

if save_results
  filename = Tools.abs_path Config['database']['database_file']
  Database.save!(filename, table)
  Printer::debug(who:"Init", msg:"Log file was successfully saved to #{filename}")
end

# Создаем отчеты по базе данных
if create_report
  require_relative 'src/statistics'
  report_config = Config['report']['report_config']
  config = YAML.load_file Tools.abs_path(report_config)
  Printer::debug(who:"Init", msg:"Configuration file for report was loaded successfully")
  st = Statistics.new(config)
  st.add({"Distribution" => "Pagination", :keys => [:server]})
  st.add({"Distribution" => "For each server", :keys => [:server, :service]})
  st.process(table)
  pagination = st.by_descr("Pagination")
  for_each_server = st.by_descr("For each server")
  st.remove("Pagination")
  st.remove("For each server")

  # Запускаем сервер
  require 'sinatra'
  configure do
    helpers Helpers
    # set :bind, "138.68.105.137"
    # set :port, 4567
    # set :public_folder, File.dirname(__FILE__)+'/public'
    # set :root, File.dirname(__FILE__)

  end

  get '/' do
    @stats = st
    @pagination = pagination
    @bad_lines = Parser.bad_lines
    # Массив статистик
    slim :main
  end
  get "/:server" do
    @stats = st
    @pagination = pagination
    @for_each_server = for_each_server
    @server = params['server']
    slim :server_view
  end
end
