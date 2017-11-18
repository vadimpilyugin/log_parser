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
