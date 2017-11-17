# require_relative 'config'
# require_relative 'tools'
# require_relative 'stats'

require_relative 'loader'
require_relative 'date.rb'
require_relative '../services/service.rb'
require_relative '../services/log_formats.rb'


# Класс занимается обработкой входного потока логов и переводом их в структурированный вид
#
class Parser
  OK = 1
  FORMAT_NOT_FOUND = 1
  UNKNOWN_SERVICE = 2
  TEMPLATE_NOT_FOUND = 3
  WRONG_FORMAT = 4

  def Parser.strerror(errno)
    case errno
    when OK
      "All OK"
    when FORMAT_NOT_FOUND
      "Отсутствует описание формата лога"
    when UNKNOWN_SERVICE
      "Неопознанный сервис"
    when TEMPLATE_NOT_FOUND
      "Не найден шаблон"
    when WRONG_FORMAT
      "Строка не соответствует формату остального лога"
    end
  end

  def initialize
    # отображение из имени файла в формат
    @filename_to_format_mapping = {}
    @parsed_lines = []
    @erroneous_lines = []
  end

  attr_reader :parsed_lines, :filename_to_format_mapping, :erroneous_lines

  def parse_line(line_hash)
    # если у файла еще не определен формат
    if !@filename_to_format_mapping.has_key? line_hash[:filename]
      # добавляем отображение для данного файла
      @filename_to_format_mapping[line_hash[:filename]] = LogFormat.find(line_hash[:logline])
    end
    # формат файла определен
    # запоминаем формат файла в переменную
    log_format = @filename_to_format_mapping[line_hash[:filename]]
    # если это NoFormat
    if log_format == NoFormat
      return line_hash.update(
        ok:false,
        description:Parser.strerror(FORMAT_NOT_FOUND),
        errno:FORMAT_NOT_FOUND
      )
    end
    # формат файла не NoFormat
    # парсим строку, используя формат лога
    # получаем поля server, service, date
    parsed_line = log_format.extract_fields(line_hash[:logline])
    # если не удалось распарсить
    if parsed_line.nil?
      return line_hash.update(
        ok:false,
        description:Parser.strerror(WRONG_FORMAT),
        errno:WRONG_FORMAT,
        log_format:log_format.to_s
      )
    end
    # удалось распарсить строку по формату лога
    # добавляем правильный сервер, если был в формате лога
    line_hash[:server] = parsed_line[:server] if parsed_line.has_key?(:server)
    # если нужно парсить отдельно сообщение, то сохраняем его, иначе сохраняем всю строку
    msg = log_format.needs_more_parsing? ? parsed_line[:msg] : line_hash[:logline]
    # находим сервис по имени
    service = Services[parsed_line[:service]]
    # если сервис не найден
    if service.nil?
      return line_hash.update(
        ok:false,
        description:Parser.strerror(UNKNOWN_SERVICE),
        errno:UNKNOWN_SERVICE,
        service:parsed_line[:service],
        date:parsed_line[:date],
        log_format:log_format.to_s,
        msg:line_hash[:logline] # потому что мы хотим видеть всю строку в отчете
      )
    end
    # сервис найден
    # вызываем метод parse над полем с сообщением сервиса
    parsed_msg = service.parse msg
    # если распарсить сообщение не удалось
    if parsed_msg.nil?
      return line_hash.update(
        ok:false,
        description:Parser.strerror(TEMPLATE_NOT_FOUND),
        errno:TEMPLATE_NOT_FOUND,
        service_group:service.service_name,
        service:parsed_line[:service],
        date:parsed_line[:date],
        log_format:log_format.to_s,
        msg:msg
      )
    end
    # сообщение успешно распарсено
    # если в формате и в сообщении есть поля с одинаковыми именами
    if parsed_line[:linedata].keys.map {|k| parsed_msg[:linedata].has_key?(k)}.any?
      # выводим предупреждение
      Printer::note(
        who: "#{service.service_name}, группа #{parsed_msg[:type]}",
        msg: "#{parsed_msg[:regex]} пересекается названиями полей с #{log_format}!"
      )
    end
    # объединяем linedat-ы формата и сообщения
    parsed_msg[:linedata].update(parsed_line[:linedata])
    return line_hash.update(
      ok:true,
      service_group:service.service_name,
      service: parsed_line[:service],
      date:parsed_line[:date],
      log_format:log_format.to_s,
      msg: msg,
      errno: OK # чтобы перезаписывать errno ошибочных строк
    ).update(parsed_msg)
  end

  def parse(log_stream)
    # для каждой строки во входном потоке
    cnt = 1
    Signal.trap("SIGINT") do
      puts
      Printer::debug who:"Parser", msg:"Закончили парсинг"
      return self
    end
    log_stream.each_with_index do |line_hash,i|
      Printer::debug(
        who:"Parser",
        msg:"Строк #{cnt}",
        in_place:true,
        log_every_n: true,
        line_no: i
      )
      cnt += 1
      parsed_line = parse_line(line_hash)
      if parsed_line[:ok] && parsed_line[:linedata][:type] != "Ignore"
        @parsed_lines << parsed_line #refine_parsed_line(parsed_line)
      elsif !parsed_line[:ok]
        # для того, чтобы показывать msg в erroneous stat
        parsed_line[:msg] = parsed_line[:logline] unless parsed_line.has_key?(:msg)
        @erroneous_lines << parsed_line
      end
    end
    puts
    return self
  end

  def refine_parsed_line(parsed_line)
    parsed_line.delete(:ok)
    parsed_line.delete(:logline)
    parsed_line
  end

  def parsed_logline_stream(log_stream)
    Enumerator.new do |yielder|
      cnt = 0
      loop do
        parsed_line = parse_line(log_stream.next)
        if parsed_line[:ok] && parsed_line[:linedata][:type] != "Ignore"
          @parsed_lines << parsed_line #refine_parsed_line(parsed_line)
        elsif !parsed_line[:ok]
          # для того, чтобы показывать msg в erroneous stat
          parsed_line[:msg] = parsed_line[:logline] unless parsed_line.has_key?(:msg)
          @erroneous_lines << parsed_line
        end
        yielder.yield(parsed_line)
        Printer::debug who:"Parser", msg:"Строк #{cnt}", in_place:true if cnt % Printer::LOG_EVERY_N == 0
        cnt += 1
      end
    end
  end
end
