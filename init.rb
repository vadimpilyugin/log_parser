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

def get_table
  load_from_file = Config['overall']['load_from_file'] == 'false' ? false : Tools.abs_path(Config['overall']['load_from_file'])
  table = []
  if load_from_file
    table = Database.load load_from_file
  else
    table = Parser.parse_dir
  end
  table
end

table = get_table

if save_results
  filename = Tools.abs_path Config['database']['database_file']
  Database.save!(filename, table)
  Printer::debug(who:"Init", msg:"Log file was successfully saved to #{filename}")
end

# Создаем отчеты по базе данных
if create_report
  require_relative 'src/statistics'
  Printer::debug(who:"Init", msg:"Configuration file for report was loaded successfully")
  st = Statistics.new(YAML.load_file Tools.abs_path(Config['report']['report_config']))
  st.add([
    # numbers that are in navbar
    {"Distribution" => "__PAGINATION__", :keys => [:server]}, 
    # for each server name we want to know which services it runs and what types of messages had been registered
    {"Distribution" => "__SERVER_SERVICES__", :keys => [:server, :service, :type]}
  ])
  st.process(table)
  pagination = st.remove("__PAGINATION__")
  for_each_server = st.remove("__SERVER_SERVICES__")

  # Запускаем сервер
  require 'sinatra'
  configure do
    helpers Helpers
    # set :bind, "138.68.105.137"
    # set :port, 4567
  end

  get '/' do
    @stats = st
    @pagination = pagination
    @bad_lines = Parser.bad_lines
    # Массив статистик
    slim :main
  end
  get "/reload" do
    Services.load
    table = get_table
    # all stats are recalculated
    st = Statistics.new Statistics.read_file
    st.process table
    redirect '/'
  end
  get "/:server" do
    @stats = st
    @pagination = pagination
    @for_each_server = for_each_server
    @server = params['server']
    slim :server_view
  end
end
