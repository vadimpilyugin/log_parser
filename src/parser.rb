require_relative 'config'
require_relative 'tools'
require_relative '../services/service.rb'
require_relative 'date.rb'
require_relative '../services/log_formats.rb'
require_relative 'stats'

# Класс занимается обработкой входящих логов и переводом их в структурированный вид
#
class Parser
  def Parser.bad_lines
    @bad_lines
  end

  @bad_lines = {:total => 0}
  @log_format_not_found = -1
  @unknown_service = -2
  @template_for_msg_not_found = -3
  @does_not_match_log_format = -4

  def Parser.uid_to_s(uid)
    case uid
    when @log_format_not_found
      "Отсутствует описание формата лога"
    when @unknown_service
      "Неопознанный сервис"
    when @template_for_msg_not_found
      "Не найден шаблон"
    when @does_not_match_log_format
      "Строка не соответствует формату остального лога"
    end
  end

  def Parser.uid_to_type(uid)
    case uid
    when @log_format_not_found
      "Format not found"
    when @unknown_service
      "Service not found"
    when @template_for_msg_not_found
      "Template not found"
    when @does_not_match_log_format
      "Bad format"
    end
  end

  @bad_lines = {:total => 0}

  # @param [String] filename полный путь до файла лога
  # @param [String] server_name имя сервера, с которого пришел файл
  # @raise [Error::FileNotFoundError] если файл не существует
  # Парсит файл и возвращает результат в виде массива хэшей.
  # Каждой строке соответствует ровно один хэш в итоговом массиве.
  # {
  #   :server - имя сервера, строка, берется из входных параметров
  #   :service - имя сервиса, который сделал данную запись в логе
  #   :date - время записи в лог. Если отсуствует, берется текущее время
  #   :type - описание данной записи. Берется из шаблона сервиса
  #   :uid - уникальный номер регулярного выражения, под который подошла строка
  #   <другие ключи> - сам пользователь выбирает им имена в шаблонах
  # }
  # Если строка не подходит ни под один формат лога, то хэш будет содержать
  # три поля: uid, type и logline:
  # {
  #   logline => <unknown_line>
  #   :type => "Format not found"
  #   :uid => @log_format_not_found
  # }
  # Если строка подходит под формат лога и сервис не описан, 
  # то:
  # {
  #   "logline" => <unknown line>,
  #   :type => "Service not found"
  #   :uid => @unknown_service
  # }
  # Если строка подошла под формат и сервис известен, но в нем не описан
  # шаблон, под который подошла бы строка, то:
  # {
  #   logline => <unknown message>,
  #   :type => "Template not found"
  #   :uid => @template_for_msg_not_found
  # }
  # В этом случае записывается вся информация, полученная из формата
  # лога, а также само не распарсенное сообщение.
  #
  # Если строка не подходит под формат лога, но предыдущие подходили,
  # тогда:
  # {
  #   logline => <unknown line>,
  #   :type => "Bad format"
  #   :uid => @does_not_match_log_format
  # }
  # @example Нормальная строка
  #   Hash.new(
  #      :server => "newserv", 
  #      :service => "sshd", 
  #      :date => <time>, 
  #      :type => "New connection", 
  #      :uid => 12345,
  #      "user_ip" => "127.0.0.1",
  #      "user_port" => "22"
  #    )
  # @example Не найден сервис
  #   Hash.new(
  #      :server => "newserv", 
  #      :service => "sshd", 
  #      :date => <time>, 
  #      :type => "Service not found",
  #      "logline" => <unknown message>,
  #      :uid => -2
  #   )
  def Parser.parse_full!(filename, server_name = 'n/a')
    if !File.exists?(filename)
      Printer::error(msg:"Файл лога по пути #{filename} не найден")
      raise Error::FileNotFoundError.new(filename)
    end
    table = []
    # Сюда будем записывать плохие строки
    @bad_lines.update({filename => []})
    log_format = nil
    File.open(filename, 'r') do |f|
      Printer::debug(msg:"Файл лога успешно открыт: #{filename}",who:"Parser")
      f.each_with_index do |logline, i|
        Printer::debug(who:"Обработано строк", msg:"#{i+1}".red, in_place:true)
        if log_format == nil
          # Формат лога определяется его первой строкой
          log_format = LogFormat.find(logline)
          # Если первая строка плохая, будет взята следующая и т.д.
          if log_format == nil
            table << {:type => uid_to_type(@log_format_not_found), "logline" => logline[0...-1], :uid => @log_format_not_found}  #  убрать \n
            @bad_lines[:total] += 1
            @bad_lines[filename] << [logline, 'n/a', uid_to_s(@log_format_not_found)]
            next
          end
        end
        # Основной цикл: получить имя сервиса из формата лога, распарсить сообщение,
        # преобразовать дату и время в класс Ruby, записать результат в таблицу
        parsed_line = log_format.parse!(logline)
        if parsed_line == nil
          table << {:type => uid_to_type(@log_format_not_found), "logline" => logline[0...-1], :uid => @log_format_not_found}
          @bad_lines[:total] += 1
          @bad_lines[filename] << [logline, 'n/a', uid_to_s(@log_format_not_found)]
          next
        end

        service_name = parsed_line["service"].downcase
        # Далее нужно парсить только часть строки лога или всю строку целиком?
        # Если есть поле msg, то оно берется в качестве части строки
        message = parsed_line["msg"] ? parsed_line["msg"] : logline
        service = Services[service_name]
        data = {}
        type = ""
        uid = 0
        if service == nil
          # Нет такого сервиса среди описанных
          data = {"logline" => message}
          type = uid_to_type(@unknown_service)
          uid = @unknown_service
        else
          parsed_msg = Services[service_name].parse!(message)
          if parsed_msg["uid"] == nil
            # Нет такого шаблона в сервисе
            data = {"logline" => message}
            type = uid_to_type(@template_for_msg_not_found)
            uid = @template_for_msg_not_found
          else
            # Все хорошо, сообщение распарсено
            data = parsed_msg["data"]
            type = parsed_msg["type"]
            uid = parsed_msg["uid"]
          end
        end
        date = CreateDate.create(
          year: parsed_line["year"],
          month: parsed_line["month"],
          day: parsed_line["day"],
          hour: parsed_line["hour"],
          minute: parsed_line["minute"],
          second: parsed_line["second"]
        )
        table << {
          :server => server_name,
          :service => service_name,
          :date => date,
          :type => type,
          :uid => uid
        }.update(data)

        # Здесь мы сохраняем некорректные строки для того, чтобы вывести их через веб-интерфейс
        if uid < 0
          @bad_lines[:total] += 1
          case uid
          when @log_format_not_found
            @bad_lines[filename] << [logline, 'n/a', uid_to_s(@log_format_not_found)]
          when @unknown_service
            @bad_lines[filename] << [logline, service_name, uid_to_s(@unknown_service)]
          when @template_for_msg_not_found
            @bad_lines[filename] << [message, service_name, uid_to_s(@template_for_msg_not_found)]
          when @does_not_match_log_format
            ; # уже было записано
          end
        end
      end
    end
    @bad_lines.delete(filename) if @bad_lines[filename].size == 0
    Parser.stats(table)
    return table
  end

  def Parser.parse!(filename, server_name = 'n/a')
    table = Parser.parse_full!(filename, server_name)
    table.keep_if{|line| line[:uid] >= 0 and line[:type] != "Ignore"}
    table
  end

  # Show statistics on parsed data
  # 
  # @param [Array] table see Parser::parse!
  # @return [void]
  def Parser.stats(table)
    st = Stats::Stats.new( [
      ["Counter", "total_lines", "Всего прочитано строк"],
      ["Counter", "successfully_parsed", "Полностью распознанных"],
      ["Counter", "ignored_services_lines", "Проигнорировано строк"],
      ["HashCounter", "unknown_lines", "Строки, не подходящие под формат лога"],
      ["HashCounter", "unrecognized_services", "Неопознанные сервисы"],
      ["HashCounter", "no_template_provided", "Строки, для которых не найдено шаблона"],
      ["HashCounter", "unknown_format", "Неизвестный формат лога"],
      ["HashCounter", "services_distr", "Распределение по сервисам"],
    ])
    puts
    table.each do |line|
      st.total_lines.increment
      if line[:uid] == @does_not_match_log_format
        # Не распарсена, т.к. не подошла под формат
        st.unknown_lines.increment(line["logline"])
      elsif line[:uid] == @unknown_service
        # Подошла под формат, но сервис не был найден
        st.unrecognized_services.increment(line[:service])
        st.services_distr.increment(line[:service])
      elsif line[:uid] == @template_for_msg_not_found
        # Подошла под сервис, но не нашлось шаблона
        st.no_template_provided.increment(line["logline"])
        st.services_distr.increment(line[:service])
      elsif line[:uid] == @log_format_not_found
        # Не распарсена, так как формат неизвестен
        st.unknown_format.increment(line["logline"])
      elsif line[:type] == "Ignore"
        # Полностью распознана, но проигнорирована
        st.services_distr.increment(line[:service])
        st.successfully_parsed.increment
        st.ignored_services_lines.increment
      else
        # Полностью распарсенная строка
        st.services_distr.increment(line[:service])
        st.successfully_parsed.increment
      end
    end
    st.print

  end
  # Transform log file into more readable form
  #
  # @param [String] input_file filename of input log file
  # @param [String] server name of the server from which the log file came from
  # @param [bool] type if false then write only numbers to output log
  # @param [String] output_file filename of the output log file
  # @raise [Error::FileNotFoundError] if log file was not found
  def Parser.transform(input_file, output_file, type=true, server="n/a")
    result = Parser.parse!(input_file,server)
    numbers = Parser.stream_of_numbers(result)
    f = File.open(output_file, "w")
    result.each_with_index do |hsh,i|
      if !type
        f.puts(numbers[i])
      elsif numbers[i] == @log_format_not_found or numbers[i] == @unknown_service or numbers[i] == @template_for_msg_not_found
          f.printf "#{numbers[i]}\t-\t(#{hsh[:service] ? hsh[:service] : 'unknown'})::#{hsh[:type]['logline']}\n"
      else
        f.printf "#{numbers[i]}\t-\t#{hsh[:service]}::#{hsh[:type]} ( "
        hsh.keys.keep_if{|key| key.class == String }.each do |key|
          value = hsh[key]
          f.printf "#{key} : #{value}, "
        end
        f.printf " )\n"
      end
    end
    f.close
  end

  # @private
  #
  def Parser.stream_of_numbers(table)
    result = []
    hash_table = {}
    i = 1
    table.each do |hsh|
      if !hash_table.has_key?(hsh[:uid])
        hash_table[hsh[:uid]] = i
        i += 1
      end
      result << hash_table[hsh[:uid]]
    end
    return result
  end
end 
