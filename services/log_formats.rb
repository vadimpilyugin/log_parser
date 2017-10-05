require_relative '../src/tools'
require_relative '../src/fields'
require_relative '../src/date'
require 'irb'

# service(logline) -  возвращает имя сервиса, которому
#   принадлежит данная строка. Если строка не удовлетворяет шаблону,
#   то возвращается nil. Предполагается, что либо в регулярном выражении 
#   присутствует поле service, либо метод переопределен так, чтобы возвращать
#   имя определенного сервиса
# LogFormat.find(logline) - возвращает либо nil, если такой формат лога
#                           не найден, либо нужный подкласс
# Этот класс отвечает за поля 'service', 'date' и 'msg'
class LogFormat
  @format = nil
  @all_formats = nil
  @service_name

  class << self
    attr_accessor :format
  end

  MESSAGE_FIELD = Fields["LogFormat"][:msg]
  SERVICE_FIELD = Fields["LogFormat"][:service]
  SERVER_FIELD  = Fields["LogFormat"][:server]
  DATE_FIELDS   = Fields["LogFormat"][:date_fields]

  def LogFormat.check(logline)
    !(logline =~ @format).nil?
  end

  def LogFormat.parse(logline)
    if logline =~ @format
      data = $~.named_captures
    else
      nil
    end
  end

  def LogFormat.extract_fields(logline)
    line_hash = {}
    # сначала распарсим строку
    linedata = parse(logline)
    if linedata.nil?
      return nil
    end
    # если в распарсенной строке есть имя сервиса
    if linedata.has_key? SERVICE_FIELD
      # выносим его во внешний хэш
      line_hash[:service] = linedata[SERVICE_FIELD]
      linedata.delete SERVICE_FIELD
    else
      # в строке не было имени сервиса
      # если сервис не определен в функции
      if self.service == LogFormat.service
        Printer::error(
          msg:"При парсинге строки по формату #{self} не определилось имя сервиса",
          who:"LogFormat.extract_fields"
        )
      end
      # имя сервиса берется из функции
      line_hash[:service] = service
    end
    # если в распарсенной строке было сообщение
    if linedata.has_key? MESSAGE_FIELD
      # выносим его
      line_hash[:msg] = linedata[MESSAGE_FIELD]
      linedata.delete MESSAGE_FIELD
    end
    # если в строке есть имя сервера
    if linedata.has_key? SERVER_FIELD
      # выносим его
      line_hash[:server] = linedata[SERVER_FIELD]
      linedata.delete SERVER_FIELD
    end
    # получим значение даты в виде Ruby-объекта и вынесем его во внешний хэш
    line_hash[:date] = CreateDate.create linedata
    # уберем ненужные теперь поля с распарсенной датой из внутреннего хэша
    DATE_FIELDS.each {|date_field| linedata.delete date_field}
    line_hash[:linedata] = linedata
    line_hash
  end

  def LogFormat.service
    return 'default_service'
  end

  def self.format_contains_service?
    !@format.names.find(SERVICE_FIELD).nil?
  end

  def self.service_defined?
    # либо поле сервис есть в шаблоне, либо определена функция, возвращающая имя сервиса
    format_contains_service? || self.service != LogFormat.service
  end

  def self.undefined_date_fields
    Printer::debug msg:"Format name: #{self}"
    DATE_FIELDS - @format.names
  end

  def LogFormat.init_formats
    @all_formats = ObjectSpace.each_object(Class).select {|klass| klass < self}
    # если дефолтный формат стоит не на последнем месте
    if @all_formats[-1] != NoFormat
      # находим, где он на самом деле
      i = @all_formats.index {|format| format == NoFormat}
      if !i.nil?
        # переставляем его и последний элементы 
        @all_formats[-1], @all_formats[i] = @all_formats[i], @all_formats[-1]
      end
    end 
    # дефолтный формат на последнем месте
    Printer::assert expr:@all_formats[-1] == NoFormat, msg: "Дефолтный #{NoFormat} стоит не на последнем месте!"
    # проверяем регулярные выражения 
    @all_formats.each do |format| 
      Printer::debug msg:"Format: #{format}"
      # если не определено имя сервиса
      if !format.service_defined?
        Printer::error(
          msg:"Не определено имя сервиса для формата #{format}!", 
          who:"LogFormat.init_formats"
        )
      end
      # если не определены поля даты
      if format != NoFormat && !format.undefined_date_fields.empty?
        Printer::note(
          msg:"Не определены поля даты: #{format.undefined_date_fields}, выставляем значения по умолчанию",
          who:"#{format}"
        )
      end
    end
  end

  def LogFormat.find(logline)
    init_formats if @all_formats.nil?
    i = @all_formats.index {|log_format| log_format.check(logline)}
    Printer::assert expr:!i.nil?, msg: "Не нашелся формат, хотя есть дефолтный #{NoFormat}!"
    return @all_formats[i]
  end

  def LogFormat.needs_more_parsing?
    !@format.names.index {|field_name| field_name == MESSAGE_FIELD}.nil?
  end
end

# Дефолтный формат, под который подходит любая строка. Должен стоять последним
class NoFormat<LogFormat
  @format = //
  def NoFormat.service
    'unknown service'
  end
end

class SyslogFormat<LogFormat
  @format = %r{  ^
      (?<month>\S+)\s+    		# Oct
      (?<day>\d+)\s+      		# 9
      (?<hour>\d+):     		# 06:
      (?<minute>\d+):   		# 08:
      (?<second>\d+)\s+   		# 05
      (?<server>\S+)\s+         # newserv
      (?<service>[^\[:]+)    # systemd-logind - все, вплоть до квадратной скобки или :
      (\[(?<pid>\d+)\])?     # [10405] - может идти, а может и не идти за именем сервиса
      :\s+(?<msg>.*)            # : Accepted publickey for autocheck
  }x
end

class ApacheFormat<LogFormat
  @format = %r{  ^
  	# IP Address
  	(?<user_ip> \S+)    # 93.180.9.182
  	# Time
  	(\s-\s-\s\[)           #  - - [
   	(?<day> \d+)\/      # 09/
   	(?<month> \w+)\/    # Oct/
   	(?<year> \d+)\:     # 2016:
   	(?<hour> \d+)\:     # 06:
   	(?<minute> \d+)\:   # 35:
   	(?<second> \d+)\s   # 46
   	(?<timezone> \+\d+)\]\s 	# +0300] 
   	# Method
   	\" (?<method> \S+)\s   					# "GET
   	# Path
   	(?<path> [^\?\s]+)\S*\s    				# /robots.txt
   	# HTTP version
   	\w+\/(?<http_version> \d\.\d)\"\s   		# HTTP/1.0"
   	# Error code
   	(?<code> \d+)      
    (.*)\s-\s-\s
    (?<server>\S+) # - - parallel.ru
  }x
  def self.service
  	'apache'
  end
end

class Fail2BanFormat<LogFormat
  @format = %r{	 ^
  	# Time
    (?<year>\d+)-       # 2017-
    (?<month>\d+)-      # 02-
    (?<day>\d+)\s+      # 05
    (?<hour>\d+):       # 07:
    (?<minute>\d+):     # 05:
    (?<second>\d+),     # 13,
    (?<msecond>\d+)		# 390
    \s+
    # Service, type
    (?<service>[^\.]+)
    \.
    (?<type>\S+)
    \s+
    # PID
    \[(?<pid>\d+)\]:     # [1686]: 
    \s+
    # Warning level
    (?<level>\S+)        # INFO
    \s+
    # Service name
    (\[([\w\-]+)\])? # [pam-generic]
    \s+
    (?<msg>.*)             # rollover performed on /var/log/fail2ban.log
  }x
end

