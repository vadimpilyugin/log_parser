DEBUG = true

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
Printer::debug(msg:"============= Log Parser v4 ============", who:"Init")
puts
puts


NUMBER_OF_LINES_TO_PROCESS = 30000
NUMBER_OF_LINES_TO_SKIP = 0

def process_stats(stats_no:nil)
  # загрузка строк
  if DEBUG
    logline_stream = LoglineStream.from_directory(
      n_lines_to_process:NUMBER_OF_LINES_TO_PROCESS,
      n_lines_to_skip: NUMBER_OF_LINES_TO_SKIP
    )
  else
    logline_stream = LoglineStream.from_directory
  end
  # распарсенный поток строк
  pls = Parser.new.parsed_logline_stream(logline_stream)
  # обрабатываем статистики
  params = {}
  params[:table] = pls
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
  "keys" => ["server"],
)
# строки, для которых не найдено шаблона
# красная снизу
# сохраняем строки, чтобы после добавления шаблона перепарсить
$stats['TEMPLATE_NOT_FOUND'] = Statistics.create_stat(
  "Distribution" => "Нераспознанные строки",
  "errno" => Parser::TEMPLATE_NOT_FOUND,
  "no_finalize" => true,
  "keys" => ["service_group","msg"],
  "save_lines" => true
)
# статистика для поиска всех сервисов, обнаруженных в логах
$stats['DISCOVERED_SERVICES'] = Statistics.create_stat(
  "Distribution" => "Обнаруженные сервисы",
  "keys" => ["service"],
)
# статистика для отображения строк без формата
$stats['WRONG_FORMAT'] = Statistics.create_stat(
  "Distribution" => "Неизвестный формат",
  "errno" => Parser::WRONG_FORMAT,
  "keys" => ["filename", "msg"],
)
# статистика для определения неизвестных сервисов
$stats['UNKNOWN_SERVICES'] = Statistics.create_stat(
  "Distribution" => "Неизвестные сервисы",
  "errno" => Parser::UNKNOWN_SERVICE,
  "no_finalize" => true,
  "keys" => ["service"],
  "save_lines" => true
)
process_stats
# выводим результаты
require_relative 'src/server'
