require_relative "aggregator"
require_relative "config"
require "yaml/store"
require "slim"

Aggregator::Aggregator.new

module Reporter

class Statistics
  def self.create(service, hsh)
    type = hsh[0].to_a[0][0]
    case type
      when "Counter" then Counter.new service, hsh
      when "Distribution" then Distribution.new service, hsh
      when "Flag" then Flag.new service, hsh
      else raise "Неопределенный тип статистики в #{hsh}"
    end
  end
end

class Reporter
  def initialize
    Dir.chdir(File.expand_path("../../", __FILE__)) # переходим в корень проекта
    Config.new
    folder = Config["reporter"]["config_folder"]
    raise "Report directory does not exist: #{folder}" if Dir.entries(folder).empty?
    raise "No templates found at report dir: #{folder}" if Dir.entries(folder).size == 2
    @report_struct = {}
    Dir.entries(folder).each do |service|    # загружаем шаблоны построения отчета
      service_template = YAML.load_file "#{folder}/#{service}"
      service_template.map! { |hsh| Reporter::Statistics.create service, hsh }
      @report_struct[service] = service_template
    end
    @filename = Config["reporter"]["report_file"]
  end
public
  def report()
    Dir.mkdir("report", 0777) unless Dir.exists? "report"
    f = File.open(@filename, File::CREAT|File::TRUNC|File::RDWR, 0644)
    # f = File.open("src/views/report.slim", File::CREAT|File::TRUNC|File::RDWR, 0644)
    f << "<!DOCTYPE html>\n"
    f << "<html>\n"
    f << "<head><title>Report</title></head>\n"
    f << "<body>\n"
    f << "<h2>Report on #{Config["parser"]["log_file"]}</h2>"
  end
end

class Counter
  def initialize(service, hsh)
  	@descr = hsh["Counter"]		# Описание, которое в первой строке
  	params = hsh[@descr]		# Параметры агрегации
  	# Счетчик имеет следующие параметры:
  	# Поле - подсчитывает уникальные значения данного поля. Например, уникальные IP адреса
  	@field = params["field"]
  	raise "Service is not a string! #{service}" if service.class != String
  	@value = Aggregator::Aggregator.reset.select(meta: {:service => service}).aggregate_by_keys(@field).size
  end
end

class Distribution
  def initialize(service, hsh)
  	@descr = hsh["Distribution"]		# Описание, которое в первой строке
  	params = hsh[@descr]		# Параметры агрегации
  	# Распределение имеет следующие параметры:
  	# Поля - показывает их взаимное распределение. Например, какие IP по каким портам заходили(распределение user_ip, server_port)
  	# Группировка - не показывать полное распределение, а по отношению к какому-то значению. Например, коды ошибок 200/не 200
  	# Исключение - в распределении убрать из рассмотрения определенное поле. Например, в распределении по кодам ошибок убрать код 200
  	raise "Service is not a string! #{service}" if service.class != String
    @keys = params["fields"]
  	@value = Aggregator::Aggregator.reset.select(meta: {:service => service})
    @value = Aggregator::Aggregator.select(true, data: {@keys.last => params["exclude"]}) if params["exclude"]  # убрать строки со значением params[exclude] 
    @value = Aggregator::Aggregator.aggregate_by_keys(params["group_by"], @keys)    # выполнить агрегацию, если нужно, сгруппировать по значению
  end
end

class Flag
  def initialize(service, hsh)
    @descr = hsh["Flag"]   # Описание, которое в первой строке
    params = hsh[@descr]    # Параметры агрегации
    # Флаг имеет следующие параметры:
    # look_for - подсчитываем события с данным именем. Должно совпадать с именем события в описании регулярок сервиса.
    # Например, подсчет числа событий Auth fail - сколько раз было попыток неправильной авторизации
    # threshold - порог, если >=, то флаг становится активен
    # Поля - подсчет числа событий, у которых совпадают значения данных полей. Например, подсчет числа неверных авторизаций
    # с одного IP адреса.
    raise "Service is not a string! #{service}" if service.class != String
    @fields = params["fields"]
    raise "Агрегация по нескольким полям пока не поддерживается!" if @fields.size > 1
    @value = Aggregator::Aggregator.reset.select(meta: {:service => service})
    @value = Aggregator::Aggregator.select(meta: {:type => params["look_for"]})
    @value = Aggregator::Aggregator.aggregate_by_keys(@fields[0])
    # Переписать для поддержки многоуровневой агрегации
    threshold = params["threshold"].to_i
    @value = @value.delete_if { |ar|  ar[1] < threshold }.to_h
    @flag = !@value.empty?
  end
end