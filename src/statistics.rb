require_relative 'date'
require_relative 'tools'
require_relative 'config'

# class Distribution<Statistics
#   def initialize(params)
    # Printer::debug("Grouping? #{@group_by_val ? "Yes, "+@group_by_val : "No"} Excluding? #{@exclude_val ? "Yes, "+@exclude_val : "No"}")

# class Flag<Statistics
#   def initialize(params)
#     @threshold = params["threshold"]
#     super
#     Printer::assert(@service, "No service specified for Flag", msg:"Reporter", "Description":@descr)
#     if Aggregator.lines.size != 0
#       @result = Aggregator.keys_keys(@fields)
#       @result = @result.to_a.delete_if { |ar|  ar[1] < @threshold }.to_h
#     end
#   end
# end


    # @report_file = Tools.load(Config["report"]["report_config"])
    # Printer::debug("Loaded configuration for Report from #{Config["report"]["report_config"]}", debug_msg:"Preparations")

# This class is used to group different stats in one place
class Statistics
  attr_reader :stats
  # @param [Hash] stat_opts opts for statistics
  def initialize(stat_opts)
    @stats = []
    Printer::debug(msg:"Creating #{stat_opts.size} statistics")
    stat_opts.each do |stat_params|
      if stat_params.has_key? "Counter"
        # Counter
        @stats << Counter.new(stat_params)
      elsif stat_params.has_key? "Distribution"
        # Distribution
        @stats << Distribution.new(stat_params)
      else
        Printer::error(msg:"No such statistics", params:stat_params)
      end 
    end
  end
  # @return [Counter, Distribution] returns a statistics at i'th place
  def [] (i)
    @stats[i]
  end

  # Return stat by description
  # 
  # @param [String] descr description of the statistics
  # @return [Counter,Distribution,nil] the statistics or nil if not found
  def by_descr(descr)
    i = @stats.index {|stat| stat.descr == descr}
    i ? @stats[i] : nil
  end

  def remove(descr)
    i = @stats.index {|stat| stat.descr == descr}
    if i != nil
      @stats.delete_at(i)
    end
  end

  # Add new statistics to the array
  # 
  # @param [Hash] params Parameters of the statistics
  # @return [void]
  def add(params)
    if params.has_key? "Counter"
      @stats << Counter.new(params)
    elsif params.has_key? "Distribution"
      @stats << Distribution.new(params)
    else
      Printer::error(msg:"Undefined statistics")
    end
  end

  def process(table)
    Printer::debug(who:"Report processing", msg:"Processing started")
    table.each_with_index do |logline,i|
      Printer::assert(expr:by_descr("Pagination").conditions.check(logline), msg:"Check does not hold")
      Printer::debug(who:"Обработано строк", msg:"#{i+1}".red+"/".white+"#{table.size}".red+"".white, in_place:true)
      @stats.each do |stat|
        stat.increment(logline)
      end
    end
    puts
    Printer::debug(who: "Report processing", msg:"Sorting and stuff")
    @stats.each_with_index do |stat,i|
      Printer::debug(who:"Статистик готово", msg:"#{i+1}".red+"/".white+"#{@stats.size}".red+"".white, in_place:true)
      stat.finalize
    end
    puts
    Printer::debug(who: "Report processing", msg:"Статистики построены!")
  end
end

# Class that checks that all conditions are true
class Condition
  attr_reader :server,:service,:type
  # @param [Hash] hsh various conditions
  # @option hsh [String] :server check that name of the server is equal to this value
  # @option hsh [String] :service check the name of the service
  # @option hsh [Array<String, String>] :time check that the time is greater than the first value and less than the second value
  # @option hsh [Array] :except remove lines that contain these fields with these values
  # @example
  # {
  #   :server => "newserv",
  #   :service => "sshd",
  #   :time => [
  #       "10 Oct 2016",
  #       "11 Oct 2016"
  #     ],
  #   :except => {
  #       "username" => "autocheck"
  #     }
  # }
  def initialize(hsh)
    @server = hsh[:server]
    @service = hsh[:service]
    @type = hsh[:type]
    if hsh[:time]
      @time_from = CreateDate.create_from(hsh[:time][0], "min")
      @time_to = CreateDate.create_from(hsh[:time][1], "max")
    else
      @time_from = nil
      @time_to = nil
    end
    @except = hsh[:except]
    # User defined conditions on custom keys
    @user_params = {}
    hsh.keys.keep_if {|key| key.class == String}.each do |key|
      @user_params.update({key => hsh[key]}) if key != "Distribution" and key != "Counter"
    end
  end
  # Checks if a logline suffices all conditions
  # @param [String] logline a line to check. See Parser::parse!
  # @return [bool] True if logline suffices all conditions
  def check(logline)
    return false if @server and @server != logline[:server]
    return false if @service and @service != logline[:service]
    return false if @type and @type != logline[:type]
    return false if @time_from and logline[:date] < @time_from
    return false if @time_to and logline[:date] > @time_to
    if @except
      @except.each do |key,value|
        return false if logline[key] == value
      end
    end
    @user_params.each_pair do |key,value|
      return false if logline[key] != value
    end
    return true
  end
end

class Counter
  attr_reader :value, :conditions, :descr

  def initialize(hsh)
    @descr = hsh["Counter"]
    @conditions = Condition.new(hsh)
    @value = 0
  end
  def increment(logline)
    @value += 1 if @conditions.check(logline)
  end
  def finalize
    @value
  end
  def to_s
    @descr + ": " + @value.to_s
  end
end

#   "nginx" => {
#     "nginx" => 3,
#     "sshd" => 1,
#     :total => 4,
#     :distinct => 2
#   },
#   "newserv" => {
#     "sshd" => 1,
#     "apache" => 3,
#     "syslog" => 1,
#     :total => 5,
#     :distinct => 3
#   },
#   :total => 9,
#   :distinct => 2
class Distribution
  attr_reader :conditions, :descr, :keys, :value, :sort_type

  def initialize(hsh)
    @descr = hsh["Distribution"]
    @conditions = Condition.new(hsh)
    if hsh[:keys] == nil
      Printer::fatal(msg:"No aggregation fields specified for distribution!", params:hsh)
    end
    @keys = hsh[:keys]
    @top = hsh[:top]
    @sort_type = hsh[:sort_type] ? hsh[:sort_type] : "total"
    @value = Distribution::hash_cnt(@keys.size)
  end
  def to_h
    return {@descr => @value}
  end
  def Distribution.hash_cnt(cnt)
    if cnt > 0
      Hash.new {|hash, key| (key == :distinct or key == :total) ? 0 : hash[key] = hash_cnt(cnt-1)}
    else
      0
    end
  end
  def increment(logline)
    if @conditions.check(logline)
      @keys.each do |key| 
        return if !logline.has_key?(key)
      end
      hsh = @value
      @keys[0..-2].each do |key|
        hsh[:distinct] += 1 unless hsh.has_key?(logline[key])
        hsh[:total] += 1
        hsh = hsh[logline[key]]
      end
      hsh[:distinct] += 1 unless hsh.has_key?(logline[@keys[-1]])
      hsh[:total] += 1
      hsh[logline[@keys[-1]]] += 1
    end
  end
  def finalize
    total = @value.delete(:total)
    distinct = @value.delete(:distinct)
    if @keys.size == 1
      @value = @value.to_a.sort{|a,b| b[1] <=> a[1]}
    else
      if @sort_type == "total"
        @value = @value.to_a.sort{|a,b| b[1][:total] <=> a[1][:total]}
      else
        @value = @value.to_a.sort{|a,b| b[1][:distinct] <=> a[1][:distinct]}
      end
    end
    if @top
      size = @value.size
      if size > @top
        @value = @value[0..@top]
        @value << [:more, size-@top]
      end
    end
    @value << [:total, total]
    @value << [:distinct, distinct]
    @value = @value.to_h
  end
end
