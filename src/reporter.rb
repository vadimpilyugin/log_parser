require_relative "aggregator"
require "yaml/store"

Aggregator::Aggregator.new

module Reporter

class Reporter
  def initialize

  end
end

class Counter
  def initialize(service, hsh)
  	@descr = hsh.to_a[0][0]		# Описание, которое в первой строке
  	params = hsh[@descr]		# Параметры отображения
  	# Счетчик имеет следующие параметры:
  	# Поле - подсчитывает уникальные значения данного поля. Например, уникальные IP адреса
  	@field = params["field"]
  	raise "Service is not a string! #{service}" if service.class != String
  	@value = Aggregator::Aggregator.select(meta: {:service => service}).aggregate_by_keys(@field).size
  end
end

class Distribution
  def exclude(field)


  def initialize(service, hsh)
  	@descr = hsh.to_a[0][0]		# Описание, которое в первой строке
  	params = hsh[@descr]		# Параметры отображения
  	# Распределение имеет следующие параметры:
  	# Поля - показывает их взаимное распределение. Например, какие IP по каким портам заходили(распределение user_ip, server_port)
  	# Группировка - не показывать полное распределение, а по отношению к какому-то значению. Например, коды ошибок 200/не 200
  	# Исключение - в распределении убрать из рассмотрения определенное поле. Например, в распределении по кодам ошибок убрать код 200
  	raise "Service is not a string! #{service}" if service.class != String
    @keys = params["fields"]

  	@value = Aggregator::Aggregator.select(meta: {:service => service}).aggregate_by_keys(@keys)
  end
end