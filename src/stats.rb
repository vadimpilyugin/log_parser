require_relative 'tools'

module Stats
  Max_lines = 5

  # initialize(name,descr) - вернет статистику
  # Параметры:
  # name - имя статистики
  # descr - строка с описанием, необязательный параметр
  # print - напечатает статистику

  class Counter
    def initialize(name,descr)
      @name = name
      @descr = descr
      @value = 0
    end
    def increment
      @value += 1
    end
    def print
      Printer::debug(who:@descr, msg:@value.to_s.red)
    end
    def to_s
      "#{@value}"
    end
  end
  class HashCounter
    def initialize(name,descr)
      @name = name
      @descr = descr
      @value = Hash.new { |hash, key| hash[key] = 0 }
    end
    def increment(value)
      @value[value] += 1
    end
    def print
      lines_left = @value.keys.size - Max_lines
      total = @value.values.inject(0){|sum,x| sum + x }
      @value = @value.to_a[0...Max_lines]
      msg = "всего ".green + "#{total}".red
      Printer::debug(who:@descr, msg:msg, params:@value.to_a.sort {|a,b| b[1] <=> a[1]}.map{|ar| [ar[0],ar[1].to_s.red]}.to_h)
      printf "".white
      Printer::debug(who:"\tShow #{lines_left.to_s.red+"".green} more") if lines_left > 0
    end
  end

  # initialize(params) - выдает новый объект статистики
  # Параметры:
  # [[<тип статистики>, <Название>, <Описание>], ...]
  # Доступные типы статистики:
  # :Counter - счетчик
  # :HashCounter - хэш, ключи это элементы, значения это сколько раз каждый элемент попался

  class Stats
    def initialize(params)
      @stats = {}
      params.each do |ar|
        stat = ar[0]
        name = ar[1]
        descr = ar[2]
        @stats.update(name.to_s => Object.const_get('Stats').const_get(stat).new(name,descr))
      end
    end
    def [](name)
      return @stats[name.to_s]
    end
    def method_missing(m, *args, &block)
      return @stats[m.to_s]
    end
    def print
      Printer::debug(who:"==================")
      @stats.values.each do |stat|
        stat.print
      end
      Printer::debug(who:"==================")
    end
  end
end