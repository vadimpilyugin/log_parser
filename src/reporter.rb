require_relative "aggregator"
require_relative "config"
require "yaml/store"

Aggregator::Aggregator.new

module Reporter

class Reporter
  def initialize
    Config.new
    folder = Config["reporter"]["config_folder"]
    @report_struct = []

  end
end

class Counter
  def initialize(service, hsh)
  	@descr = hsh.to_a[0][0]		# Описание, которое в первой строке
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
  	@descr = hsh.to_a[0][0]		# Описание, которое в первой строке
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
    @descr = hsh.to_a[0][0]   # Описание, которое в первой строке
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