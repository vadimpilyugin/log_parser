require_relative 'config'
require_relative 'tools'
require_relative '../services/service.rb'
require_relative 'date.rb'
require_relative '../services/log_formats.rb'
require_relative 'stats'

# Парсер имеет следующие методы:
# Parser.parse! (filename, server_name)
# filename - полное имя файла, начиная от корня
# server_name - имя сервера, с которого этот файл пришел

# Парсит файл и возвращает результат в виде массива хэшей.
# Каждой строке соответствует ровно один хэш в итоговом массиве.
# Хэш имеет следующие поля:
# :server - имя сервера, строка, берется из входных параметров
# :service - имя сервиса, который сделал данную запись в логе
# :date - время записи в лог. Если отсуствует, берется текущее время
# :data - хэш, содержащий распарсенное сообщение, уже на уровне сервиса.
#         Хэш, ключом является название поля, значением-значение поля.
# :descr - описание данной записи. Берется из шаблона сервиса
# :uid - уникальный номер регулярного выражения, под который подошла строка
#        Равен 0, если строка подошла под формат лога, но не под сервис

# Если строка не подходит ни под один формат лога, то хэш будет содержать
# два поля: descr и data:
# :data => {"logline" => <unknown_line>}
# :descr => "Wrong format"
# :uid => -1
# Если строка подходит под формат лога, но не подходит ни под
# один сервис, то поля data и descr будут содержать следующие значения:
# :data => {"logline" => <unknown line>},
# :descr => "Service not found"
# :uid => -2
# Если строка подошла под формат и сервис известен, но в нем не описан
# шаблон, под который подошла бы строка, то поля data и descr будут содержать 
# следующие значения:
# :data => {"logline" => <unknown line>},
# :descr => "Template not found"
# :uid => -3

class Parser

  def Parser.parse!(filename, server_name = 'n/a')
    Printer::assert(expr:File.exists?(filename), msg:"Файл лога по пути #{filename} не найден")
    table = []
    log_format = nil
    File.open(filename, 'r') do |f|
      Printer::debug(msg:"Файл лога успешно открыт: #{filename}",who:"Parser")
      f.each_with_index do |logline, i|
        Printer::debug(who:"Обработано строк", msg:"#{i+1}".red, in_place:true)
        if log_format == nil
          # Формат лога определяется его первой строкой
          log_format = LogFormat.find(logline)
          # Если первая строка плохая, будет взята следующая и т.д. до 10 строки
          if log_format == nil
            table << {:descr => "Wrong format", :data => {"logline" => logline[0...-1]}, :uid => -1}  #  убрать \n
            if i == 10
              break
            else
              next
            end
          end
        end
        # Основной цикл: получить имя сервиса из формата лога, распарсить сообщение,
        # преобразовать дату и время в класс Ruby, записать результат в таблицу
        parsed_line = log_format.parse!(logline)
        if parsed_line == nil
          table << {:descr => "Wrong format", :data => {"logline" => logline[0...-1]}, :uid => -1}
          next
        end
        service_name = log_format.get_service_name(logline)
        # Далее нужно парсить только часть строки лога или всю строку целиком?
        # Если есть поле msg, то оно берется в качестве части строки
        message = parsed_line["msg"] ? parsed_line["msg"] : logline
        service = Services[service_name]
        data = {}
        descr = ""
        uid = 0
        if service == nil
          # Нет такого сервиса среди описанных => 
          data = {"logline" => message}
          descr = "Service not found"
          uid = -2
        else
          parsed_msg = Services[service_name].parse!(message)
          if parsed_msg == nil
            # Нет такого шаблона в сервисе
            data = {"logline" => message}
            descr = "Template not found"
            uid = -3
          else
            # Все хорошо, сообщение распарсено
            data = parsed_msg["data"]
            descr = parsed_msg["descr"]
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
          :data => data,
          :descr => descr,
          :uid => uid
        }
      end
    end
    Parser.stats(table)
    return table
  end
  def Parser.stats(table)
    st = Stats::Stats.new( [
      ["Counter", "total_lines", "Всего прочитано строк"],
      ["Counter", "successfully_parsed", "Полностью распознанных"],
      ["Counter", "ignored_services_lines", "Проигнорировано строк"],
      ["HashCounter", "unknown_lines", "Строки, не подходящие под формат лога"],
      ["HashCounter", "unrecognized_services", "Неопознанные сервисы"],
      ["HashCounter", "no_template_provided", "Строки, для которых не найдено шаблона"],
      ["HashCounter", "services_distr", "Распределение по сервисам"]
    ])    
    puts
    table.each do |line|
      st.total_lines.increment
      if line[:descr] == "Wrong format"
        # Не распарсена, т.к. не подошла под формат
        st.unknown_lines.increment(line[:data]["logline"])
      elsif line[:descr] == "Service not found"
        # Подошла под формат, но сервис не был найден
        st.unrecognized_services.increment(line[:service])
        st.services_distr.increment(line[:service])
      elsif line[:descr] == "Template not found"
        # Подошла под сервис, но не нашлось шаблона
        st.no_template_provided.increment(line[:data]["logline"])
        st.services_distr.increment(line[:service])
      elsif line[:descr] == "Ignore"
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
  def Parser.transform(input_file, output_file, descr=true, server="n/a")
    result = Parser.parse!(input_file,server)
    numbers = Parser.stream_of_numbers(result)
    f = File.open(output_file, "w")
    result.each_with_index do |hsh,i|
      if !descr
        f.puts(numbers[i])
      elsif numbers[i] == -1 or numbers[i] == -2 or numbers[i] == -3
          f.printf "#{numbers[i]}\t-\t(#{hsh[:service] ? hsh[:service] : 'unknown'})::#{hsh[:descr]['logline']}\n"
      else
        f.printf "#{numbers[i]}\t-\t#{hsh[:service]}::#{hsh[:descr]} ( "
        hsh[:data].to_a[0..1].to_h.each_pair do |key,value|
          f.printf "#{key} : #{value}, "
        end
        f.printf " )\n"
      end
    end
    f.close
  end
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
