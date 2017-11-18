require_relative 'tools'

# Use this module to measure some interesting statistics in your program
# The main difference with statistics is that statistics is used for the
# parsed log data
module Stats
  MAX_LINES = 5

  # initialize(name,descr) - вернет статистику
  # Параметры:
  # name - имя статистики
  # descr - строка с описанием, необязательный параметр
  # print - напечатает статистику

  # Represents a simple incrementing variable
  # @attr_reader [Integer] value value of the counter
  # @attr_reader [String] name name of the counter
  # @attr_reader [String] descr description of the counter
  class Counter
    # @param [String] name name of the counter
    # @param [String] descr description of the counter
    def initialize(name,descr)
      @name = name
      @descr = descr
      @value = 0
    end
    attr_reader :value, :descr, :name
    # Increment the value of the counter
    # @return [Integer] current value of the counter
    def increment
      @value += 1
    end
    # Print the name and the value of the counter
    def print
      Printer::debug(who:@descr, msg:@value.to_s.red+"".white)
    end
    # String representation
    # @return [String]
    def to_s
      "#{@value}"
    end
  end
  # Represents a distribution, not a simple counter
  # @attr_reader [Integer] value value of the distribution
  # @attr_reader [String] name name of the distribution
  # @attr_reader [String] descr description of the distribution
  class HashCounter
    # @param [String] name name of the distribution
    # @param [String] descr description of the distribution
    def initialize(name,descr)
      @name = name
      @descr = descr
      @value = Hash.new { |hash, key| hash[key] = 0 }
      @count = 0
    end
    attr_reader :name, :descr, :value, :count

    # Increase the number of values equal to the given value
    # @param [Object] value value to increase
    # @return [Hash] current value of the distribution  
    def increment(value)
      @value[value] += 1
      @count += 1
    end
    # Pretty print for the distribution
    # @return [void]
    def print(max_lines = MAX_LINES)
      lines_left = @value.keys.size - max_lines
      total = @value.values.inject(0){|sum,x| sum + x }
      # @value = @value.to_a[0...max_lines]
      msg = "всего ".green + "#{total}".red
      Printer::debug(who:@descr, msg:msg, params:@value.to_a[0...max_lines].sort {|a,b| b[1] <=> a[1]}.map{|ar| [ar[0],ar[1].to_s.red]}.to_h)
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

  # Creates a list of statistics
  class Stats
    # Input options are in this format:
    # {
    #   [
    #     ["<stat_type>", "<stat_name>", "<stat_descr>"], 
    #     ["<stat_type>", "<stat_name>", "<stat_descr>"], 
    #     ...,
    #     ["<stat_type>", "<stat_name>", "<stat_descr>"], 
    #   ]
    # }
    # @param [Array] params opts for creating stats
    def initialize(params)
      @stats = {}
      params.each do |ar|
        stat = ar[0]
        name = ar[1]
        descr = ar[2]
        @stats.update(name.to_s => Object.const_get('Stats').const_get(stat).new(name,descr))
      end
    end
    # Get a stat by its name
    # @param [String] name name that was assigned in the constructor
    def [](name)
      return @stats[name.to_s]
    end
    # @private
    def method_missing(m, *args, &block)
      return @stats[m.to_s]
    end
    # Pretty print all of the statistics
    # @return [void]
    def print
      Printer::debug(who:"==================")
      @stats.values.each do |stat|
        stat.print
      end
      Printer::debug(who:"==================")
    end
  end
end