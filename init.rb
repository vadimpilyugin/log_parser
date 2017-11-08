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
require 'json'

puts
puts
Printer::debug(msg:"============= Log Parser v3.02 ============", who:"Init")
puts
puts

p = Parser.new
logline_stream = LoglineStream.from_directory
100000.times {logline_stream.next}
parsed_logline_stream = p.parsed_logline_stream(logline_stream)
20000.times { parsed_logline_stream.next }
puts
Printer::debug(
  who: "Парсинг окончен",
  msg: "",
  params:{
    'Число ошибочных строк'=>p.erroneous_lines.size,
    'Число нормальных строк'=>p.parsed_lines.size
  }
)

# константы для обозначения статистик
NORMAL_STATS = 0
SERVER_NAMES = 1
ERRONEOUS_LINES = 2
ERR_LINES_BY_ERRNO = 3
NO_TEMPLATE_BY_SERVICE = 4

# хэш для хранения статистик
stats = {}

# создаем нужные статистики
stats[NORMAL_STATS] = Statistics.init

# добавляем имена серверов для веб-странички
stats[SERVER_NAMES] = Statistics.create_stat(
  "Distribution" => "Server names",
  "keys" => ["server"]
)

# статистика для подсчета ошибочных строк
stats[ERRONEOUS_LINES] = Statistics.create_stat(
  "Distribution" => "Нераспознанные строки",
  "keys" => ["filename","msg"]
)

# подсчет ошибочных строк по типу
stats[ERR_LINES_BY_ERRNO] = Statistics.create_stat(
  "Distribution" => "Распределение ошибочных строк по типу",
  "keys" => ["errno"]
)

# подсчет строк, для которых не найдено шаблона
stats[NO_TEMPLATE_BY_SERVICE] = Statistics.create_stat(
  "Distribution" => "Шаблон не найден",
  "errno" => Parser::TEMPLATE_NOT_FOUND,
  "keys" => ["service"]
)

Statistics.process stats[NORMAL_STATS].push(stats[SERVER_NAMES]), p.parsed_lines
Statistics.process [].push(stats[ERRONEOUS_LINES]).push(stats[ERR_LINES_BY_ERRNO])\
  .push(stats[NO_TEMPLATE_BY_SERVICE]), p.erroneous_lines

# список серверов
server_list = Statistics[stats[SERVER_NAMES]].distrib.keys.keep_if do |key|
  key.class == String
end
server_list.unshift("All")

# распределение по сервисам
erroneous_lines = {}
erroneous_lines[Parser::TEMPLATE_NOT_FOUND] = Statistics[stats[NO_TEMPLATE_BY_SERVICE]]\
  .distrib

# список сервисов со строками, не подошедшими ни под один шаблон
services = {}
services['no_template_found'] = Statistics[stats[NO_TEMPLATE_BY_SERVICE]]\
  .distrib.keys
services['no_template_found'].delete(:total)
services['no_template_found'].delete(:distinct)

require 'sinatra'
configure do
  helpers View
  set :bind, "0.0.0.0"
  set :port, 4567
  set :public_folder, 'public'
end

module ApiHelpers
  def check_params(*keys)
    keys.each do |key|
      if params[key].nil? || params[key].empty?
        Printer::error(
          msg: "значение параметра #{key} не указано"
        )
        return false
      end
    end
  end
end


configure do
  helpers ApiHelpers
end

get '*' do
  Printer::debug who:request.env["REQUEST_PATH"], params:params
  pass
end


# params[service]
# params[regexp]

# erroneous_lines = {
#   Parser::TEMPLATE_NOT_FOUND => {
#     "sshd" => [
#       {
#         msg: 'Invalid user 0101 from 5.188.10.176'
#       },
#       {
#         msg:"sshd started on 34"
#       },
#     ],
#     "kernel" => [
#       {
#         msg: "[4196503.930936] Corrupted low memory at ffff8bb00000e000 (e000 phys) = 082fb5a2"
#       },
#       {
#         msg: "[4211128.036967] Corrupted low memory at ffff8bb00000e000 (e000 phys) = 08361801"
#       }
#     ]
#   }
# }

# services={}
# services["no_template_found"] = ["sshd","kernel"]

get '/loglines/no_template_found' do
  max_lines = 10

  # проверка на корректность
  if !check_params("service", "regexp")
    halt({
        "ok" => false,
        "what" => "bad_params",
        "descr" => "сервис либо регулярное выражение не указаны"
      }.to_json
    )
  end
  # берем все строки, для которых не найдено шаблона
  lines = erroneous_lines[Parser::TEMPLATE_NOT_FOUND]
  # отсеиваем все, которые не принадлежат данному сервису
  lines = lines[params["service"]]
  # если ничего не осталось
  if lines.nil? || lines.empty?
    halt({
      "ok" => true,
      "data" => []
    }).to_json
  else
    # какие-то строки есть
    begin
      # создаем регулярное выражение
      regexp = Regexp.new(params["regexp"])
      # сюда будем записывать подошедшие строки
      recognized_lines = []
      # для каждой строки
      lines.each do |line_hash|
        Printer::note(
          msg: "Отсутствует поле :msg",
          params: line_hash
        ) unless line_hash.has_key?(:msg)
        # если строка подходит под регулярное выражение
        if line_hash[:msg] =~ regexp
          # добавляем именованные группы
          line_hash[:linedata] = $~.named_captures
          # записываем в ответ эту строку
          recognized_lines << {msg:line_hash[:msg]}
          # recognized_lines << line_hash
        end
      end
      # если строк слишком много
      if recognized_lines.size > max_lines
        Printer::note(
          msg: "Строк слишком много (#{recognized_lines.size}), возвращаем #{max_lines}"
        )
        # возвращаем только первые max_lines
        recognized_lines = recognized_lines.first(max_lines)
      end
      # возвращаем отсеянные строки
      halt({
          "ok" => true,
          "data" => recognized_lines,
        }.to_json
      )
    rescue StandardError => exc
      halt({
          "ok" => false,
          "what" => "bad_regex",
          "descr" => exc.message
        }.to_json
      )
    end
  end
end


# params[]
# Возвращает список всех сервисов, у которых
# есть строки, не подошедшие ни под один шаблон
get '/service/no_template_found' do
  # проверка на корректность
  # параметров нет
  halt({
      "ok" => true,
      "data" => services["no_template_found"]
    }.to_json
  )
end

# params[service]
# возвращает список категорий из шаблона сервиса
get '/service/categories' do
  # проверка на корректность
  if !check_params("service")
    halt({
        "ok" => false,
        "what" => "bad_params",
        "descr" => "сервис не указан"
      }.to_json
    )
  end
  # находим сервис по имени
  service = Services[params["service"]]
  # если сервис не найден
  if service.nil?
    halt({
        "ok" => false,
        "what" => "bad_service",
        "descr" => "указанный сервис не найден среди описанных"
      }.to_json
    )
  end
  # сервис найден
  # возвращаем список категорий
  halt({
      "ok" => true,
      "data" => service.categories
    }.to_json
  )
end

# params[service]
# params[category]
post '/service/categories/new' do
  # проверка на корректность
  if !check_params("service", "category")
    halt({
        "ok" => false,
        "what" => "bad_params",
        "descr" => "не указаны сервис либо категория"
      }.to_json
    )
  end
  # запрос корректный
  # находим сервис по имени
  service = Services[params["service"]]
  # если сервис не найден
  if service.nil?
    halt({
        "ok" => false,
        "what" => "bad_service",
        "descr" => "указанный сервис не найден среди описанных"
      }.to_json
    )
  end
  # сервис найден
  # добавляем в него новую категорию
  if service.new_category(category:params["category"])
    halt({
        "ok" => true
      }.to_json
    )
  else
    halt({
        "ok" => false,
        "what" => "category_add_fail",
        "descr" => "failed to create category"
      }.to_json
    )
  end
end

get '/service/unknown_services' do

end

get '/' do
  redirect '/servers/'
end

post '/check/regexp' do

end

get '/check/regexp/line' do
  Printer::debug msg:request.env["HTTP_X_CUSTOM"]
  begin
    Printer::debug params:{line:params['line'], regexp:params['regexp']}
    if Regexp.new(params['regexp']) =~ params['line']
      if $~.named_captures.empty?
        return 'True'
      else
        $~.named_captures.to_json
      end
    else
      return 'No'
    end
  rescue RegexpError => exc
    return exc.inspect
  end
end

get '/loglines/bad' do
  content_type :json
  p.erroneous_lines.to_json
end
get '/loglines/good' do
  content_type :json
  p.parsed_lines.to_json
end

get '/add/service/:service' do
  # если сервис задан и непустой
  if params[:service] && !params[:service].empty?
    # запоминаем имя сервиса
    service_name = params[:service]
    # если такого сервиса еще нет
    if Services[service_name].nil?
      begin
        # добавляем сервис
        Services.create_service(service_name:service_name)
        # обновляем главную страницу
        redirect '/'
      # если произошла ошибка при добавлении
      rescue StandardError => exc
        # печатаем ошибку
        Printer::error(
          who:'Add service',
          msg:exc.inspect
        )
        Printer::error(
          who:'Add service',
          msg:'не получилось создать новый сервис'
        )
        # TODO: отображаем ошибку на странице
        redirect '/'
      end
    else
      # сервис уже есть
      # FIXME: ничего не делаем
      redirect '/'
    end
  end
end

get '/servers/:server?' do |server|
  # если зашли на главную страницу
  if server.nil?
    @counters = stats[NORMAL_STATS].map{|stat_id| Statistics[stat_id]}.keep_if do |st|
      st.conditions.server.nil? && st.class == Counter
    end
    @dist_arr = stats[NORMAL_STATS].map{|stat_id| Statistics[stat_id]}.keep_if do |st|
      st.conditions.server.nil? && st.class == Distribution
    end
    @pagination = View.pagination(
      server_list:server_list,
      active:0
    )
    @erroneous_stat = Statistics[stats[ERRONEOUS_LINES]]
    # binding.irb
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
    slim :main
  end
end
