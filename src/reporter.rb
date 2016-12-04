require_relative "aggregator"
require "yaml/store"

module Reporter

class Reporter
  def initialize

  end
end

class Counter
  def initialize(hsh)
  	@descr = hsh.to_a[0][0]		# Описание, которое в первой строке
  	params = hsh[@descr]		# Параметры отображения
  	# Счетчик имеет следующие параметры:
  	# Поле - подсчитывает уникальные значения данного поля. Например, уникальные IP адреса
  	@field = params["field"]
  	@value = 
  end