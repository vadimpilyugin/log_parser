

system "clear"
puts("Preparation: Initialization started")

require 'sinatra'
require 'irb'
require 'json'

require_relative 'src/loader'
require_relative 'services/service'
require_relative 'src/parser'
require_relative 'src/statistics'

puts
puts
Printer::debug(msg:"============= Log Parser v3.02 ============", who:"Init")
puts
puts

NUMBER_OF_LINES_TO_PROCESS = 300000
def process_stats(stats_no:nil)
  # загрузка строк
  logline_stream = LoglineStream.from_directory
  # 100000.times {logline_stream.next}
  # парсер
  p = Parser.new
  # распарсенный поток строк
  parsed_logline_stream = p.parsed_logline_stream(logline_stream)
  # обрабатываем статистики
  params = {}
  params[:table] = parsed_logline_stream.first(NUMBER_OF_LINES_TO_PROCESS)
  params[:stats_no] = stats_no if stats_no
  Statistics.process(**params)
end

# загрузка сервисов
Services.init
# статистики из файла
$stats = {}
$stats['NORMAL_STATS'] = Statistics.init
# добавляем имена серверов для веб-странички
$stats['SERVER_LIST'] = Statistics.create_stat(
  "Distribution" => "Названия серверов",
  "keys" => ["server"]
)
# строки, для которых не найдено шаблона
# красная снизу
$stats['TEMPLATE_NOT_FOUND'] = Statistics.create_stat(
  "Distribution" => "Нераспознанные строки",
  "errno" => Parser::TEMPLATE_NOT_FOUND,
  "no_finalize" => true,
  "keys" => ["service_group","msg"]
)
# статистика для списка сервисов, для которых есть нераспознанные строки
# TODO: избавиться в пользу TEMPLATE_NOT_FOUND
# $stats['NO_TEMPLATE_FOUND'] = Statistics.create_stat(
#   "Distribution" => "Шаблон не найден",
#   "errno" => Parser::TEMPLATE_NOT_FOUND,
#   "keys" => ["service_group"]
# )
# статистика для поиска всех сервисов, обнаруженных в логах
$stats['DISCOVERED_SERVICES'] = Statistics.create_stat(
  "Distribution" => "Обнаруженные сервисы",
  "keys" => ["service"],
)
# статистика для определения неизвестных сервисов
# красная сверху
$stats['UNKNOWN_SERVICES'] = Statistics.create_stat(
  "Distribution" => "Неизвестные сервисы",
  "errno" => Parser::UNKNOWN_SERVICE,
  "no_finalize" => true,
  "keys" => ["service"]
)
# статистика для соответствия "сервис - строки"
# $stats['ALL_SERVICES'] = Statistics.create_stat(
#   "Distribution" => "Строки сервисов",
#   "keys" => ["service", "msg"]
# )
process_stats
# выводим результаты
require_relative 'src/server'




# require_relative 'src/tools'
# require_relative 'src/config'
# require_relative 'src/parser'
# require_relative 'src/loader'
# require_relative 'src/statistics'
# require_relative 'src/helpers'
# require_relative 'src/views'
# require 'irb'
# require 'json'
# require "sinatra/reloader"


# p = Parser.new
# logline_stream = LoglineStream.from_directory
# # 100000.times {logline_stream.next}
# parsed_logline_stream = p.parsed_logline_stream(logline_stream)
# 20000.times { parsed_logline_stream.next }
# puts
# Printer::debug(
#   who: "Парсинг окончен",
#   msg: "",
#   params:{
#     'Число ошибочных строк'=>p.erroneous_lines.size,
#     'Число нормальных строк'=>p.parsed_lines.size
#   }
# )

# # константы для обозначения статистик
# SERVER_NAMES = 1
# ERRONEOUS_LINES = 2
# ERR_LINES_BY_ERRNO = 3
# NO_TEMPLATE_FOUND = 4
# DISCOVERED_SERVICES = 7

# # хэш для хранения статистик
# $stats = {}

# # создаем нужные статистики
# NORMAL_STATS = Statistics.init

# # добавляем имена серверов для веб-странички
# $stats[SERVER_NAMES] = Statistics.create_stat(
#   "Distribution" => "Server names",
#   "keys" => ["server"]
# )

# # статистика для подсчета ошибочных строк
# TEMPLATE_NOT_FOUND = Statistics.create_stat(
#   "Distribution" => "Нераспознанные строки",
#   "errno" => Parser::TEMPLATE_NOT_FOUND,
#   "keys" => ["service","msg"]
# )

# # статистика для определения неизвестных сервисов
# UNKNOWN_SERVICES = Statistics.create_stat(
#   "Distribution" => "Неизвестные сервисы",
#   "errno" => Parser::UNKNOWN_SERVICE,
#   "keys" => ["service"]
# )

# # статистика для поиска всех сервисов, обнаруженных в логах
# $stats[DISCOVERED_SERVICES] = Statistics.create_stat(
#   "Distribution" => "Обнаруженные сервисы",
#   "keys" => ["service"],
#   "no_finalize" => true
# )

# # статистика для определения строк, не подходящих под формат лога
# WRONG_FORMAT_LINES = Statistics.create_stat(
#   "Distribution" => "Строки неизвестных форматов",
#   "errno" => [Parser::WRONG_FORMAT, Parser::FORMAT_NOT_FOUND],
#   "keys" => ["filename", "logline"]
# )

# # подсчет ошибочных строк по типу
# $stats[ERR_LINES_BY_ERRNO] = Statistics.create_stat(
#   "Distribution" => "Распределение ошибочных строк по типу",
#   "keys" => ["errno"]
# )

# # статистика для списка сервисов, для которых есть нераспознанные строки
# $stats[NO_TEMPLATE_FOUND] = Statistics.create_stat(
#   "Distribution" => "Шаблон не найден",
#   "errno" => Parser::TEMPLATE_NOT_FOUND,
#   "keys" => ["service"]
# )

# Statistics.process ([]+$stats[NORMAL_STATS]).push($stats[SERVER_NAMES])\
#   .push($stats[DISCOVERED_SERVICES]), p.parsed_lines

# # финализуем статистику
# Statistics[$stats[DISCOVERED_SERVICES]].no_finalize = false;

# Statistics.process [].push($stats[ERRONEOUS_LINES]).push($stats[ERR_LINES_BY_ERRNO])\
#   .push($stats[NO_TEMPLATE_FOUND]).push($stats[UNKNOWN_SERVICES])\
#   .push($stats[WRONG_FORMAT_LINES]).push($stats[DISCOVERED_SERVICES]), p.erroneous_lines

# # список серверов
# server_list = Statistics[$stats[SERVER_NAMES]].distrib.keys.keep_if do |key|
#   key.class == String
# end
# server_list.unshift("All")

# # распределение по сервисам
# erroneous_lines = {}
# erroneous_lines[Parser::TEMPLATE_NOT_FOUND] = Statistics[$stats[NO_TEMPLATE_FOUND]]\
#   .distrib

# # список сервисов со строками, не подошедшими ни под один шаблон
# # services = {}
# # services['no_template_found'] = Statistics[$stats[NO_TEMPLATE_FOUND]]\
# #   .distrib.keys
# # services['no_template_found'].delete(:total)
# # services['no_template_found'].delete(:distinct)

# # список всех обнаруженных сервисов
# # services["discovered_services"] = Statistics[$stats[DISCOVERED_SERVICES]].list

# services = {}
# services[NO_TEMPLATE_FOUND] = Statistics[$stats[NO_TEMPLATE_FOUND]].list
# services[DISCOVERED_SERVICES] = Statistics[$stats[DISCOVERED_SERVICES]].list
# services[UNKNOWN_SERVICES] = Statistics[$stats[UNKNOWN_SERVICES]].list

# require 'sinatra'
# configure do
#   helpers View
#   set :bind, "0.0.0.0"
#   set :port, 4567
#   set :public_folder, 'public'
# end

# module ApiHelpers
#   def check_params(*keys)
#     keys.each do |key|
#       if params[key].nil? || params[key].empty?
#         Printer::error(
#           msg: "значение параметра #{key} не указано"
#         )
#         return false
#       end
#     end
#   end
# end


# configure do
#   helpers ApiHelpers
# end

# get '*' do
#   Printer::debug who:request.env["REQUEST_PATH"], params:params
#   Printer::error msg:"Foobar!"
#   pass
# end
