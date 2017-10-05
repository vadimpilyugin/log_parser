system "clear"
puts("Preparation: Initialization started")


require_relative 'src/tools'
require_relative 'src/config'
require_relative 'src/parser'
require_relative 'src/loader'
require_relative 'src/statistics'
require_relative 'src/helpers'
require_relative 'src/views'
# require_relative 'src/db'
require 'irb'

puts
puts
Printer::debug(msg:"============= Log Parser v3.02 ============", who:"Init")
puts
puts

p = Parser.new
logline_stream = LoglineStream.open
parsed_logline_stream = p.parsed_logline_stream(logline_stream)
10000.times { parsed_logline_stream.next }
puts
# Logline.save_parsed_lines(p.parsed_lines)
stat_ids = Statistics.init
# добавляем специальные статистики для веб-странички
servers_stat_no = Statistics.create_stat(
  "Distribution" => "Server names",
  "keys" => [:server]
)
Statistics.process p.parsed_lines
server_list = Statistics.delete(servers_stat_no).distrib.keys.keep_if do |key|
  key.class == String
end
server_list.unshift("All")

require 'sinatra'
configure do
  helpers View
  set :bind, "0.0.0.0"
  set :port, 4567
  set :public_folder, 'public'
end

get '/servers/:server?' do |server|
  # если зашли на главную страницу
  if server.nil?
    @counters = Statistics.all.keep_if do |st|
      st.conditions.server.nil? && st.class == Counter
    end
    @dist_arr = Statistics.all.keep_if do |st|
      st.conditions.server.nil? && st.class == Distribution
    end
    @pagination = View.pagination(
      server_list:server_list,
      active:0
    )
    slim :main
  else
    # зашли на какой-то отдельный сервер
    @counters = Statistics.all.keep_if do |st|
      st.conditions.server == server && st.class == Counter
    end
    @dist_arr = Statistics.all.keep_if do |st|
      st.conditions.server == server && st.class == Distribution
    end
    @pagination = View.pagination(
      server_list:server_list,
      active:server_list[1..-1].index{|serv| serv == server}+1,
    )
    # binding.irb
    slim :main
  end
end
# get "/:server" do
#   @stats = st
#   @pagination = pagination
#   @for_each_server = for_each_server
#   @server = params['server']
#   slim :server_view
# end


# save_results = Config['database']['save_result'] == 'true' ? true : false
# create_report = Config['overall']['create_report'] == 'true' ? true : false
# load_from_file = Config['overall']['load_from_file'] == 'false' ? false : Tools.abs_path(Config['overall']['load_from_file'])

# start_time=Time.now

# table = []
# if load_from_file
#   table = Database.load load_from_file
# else
#   Loader.get_logs_names.each_pair do | server, files |
#     files.each do |filename|
#       table += Parser.parse!(filename,server)
#       Printer::debug(who:"Init", msg:"#{filename} was successfully parsed, now table has #{table.size.to_s.red+"".white} lines")
#     end
#   end
# end
# Printer::debug(who:"Preparation time:", msg:"#{(Time.now-start_time)} сек.".red)
# #start_time=Time.now

# if save_results
#   filename = Tools.abs_path Config['database']['database_file']
#   Database.save!(filename, table)
#   Printer::debug(who:"Init", msg:"Log file was successfully saved to #{filename}")
# end

# # Создаем отчеты по базе данных
# if create_report
#   require_relative 'src/statistics'
#   report_config = Config['report']['report_config']
#   config = YAML.load_file Tools.abs_path(report_config)
#   Printer::debug(who:"Init", msg:"Configuration file for report was loaded successfully")
#   st = Statistics.new(config)
#   st.add({"Distribution" => "Pagination", :keys => [:server]})
#   st.add({"Distribution" => "For each server", :keys => [:server, :service, :type]})
#   st.process(table)
#   pagination = st.by_descr("Pagination")
#   for_each_server = st.by_descr("For each server")
#   st.remove("Pagination")
#   st.remove("For each server")

#   Printer::debug(who:"Full processing time:", msg:"#{(Time.now-start_time)} сек.".red+"".white)
  # Запускаем сервер
