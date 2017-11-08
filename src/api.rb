require 'sinatra'
require 'irb'
require 'json'

require_relative 'printer'
require_relative 'parser'

module ApiHelpers
  def check_params(*params)
    params.each do |param|
      if param.nil? || param.empty?
        Printer::error(
          msg: "значение параметра #{param} не указано"
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
