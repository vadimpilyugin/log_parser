require_relative 'date'
require_relative 'tools'
require_relative 'config'
require_relative 'aggregator'

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

class Report
  def initialize(hsh)
    @stats = []
    Printer::debug(msg:"Create report with #{hsh.keys.size} statistics")
    hsh.to_a.each do |stat_params|
      if stat.has_key? "Counter"
        # Counter
        @stats << Counter.new(stat_params)
      elsif stat.has_key? "Distribution"
        # Distribution
        @stats << Distribution.new(stat_params_)
      else
        Printer::error(msg:"No such statistics", params:stat_params)
      end 
    end
  end
  def process(table)
    Printer::debug(who:"Report processing", "Processing started")
    table.each_with_index do |logline,i|
      Printer::debug(who:"Обработано строк", msg:"#{i}".red+"/".white+"#{table.size}".red+"".white, in_place:true)
      @stats.each do |stat|
        stat.increment(logline)
      end
    end
    puts
    Printer::debug(who: "Report processing", msg:"Sorting and stuff")
    @stats.each_with_index do |stat,i|
      Printer::debug(who:"Статистик готово", msg:"#{i}".red+"/".white+"#{@stats.size}".red+"".white, in_place:true)
      stat.finalize
    end
    puts
    Printer::debug(who: "Report processing", msg:"Статистики построены!")
  end
end


class Condition
  def initialize(hsh)
    @server = hsh[:server]
    @service = hsh[:service]
    @type = hsh[:type]
    if hsh[:time]
      @time_from = DateTime.create_from(hsh[:time][0], "min")
      @time_to = DateTime.create_from(hsh[:time][1], "max")
    else
      @time_from = nil
      @time_to = nil
    end
    @except = hsh["except"]
  end
  def check(logline)
    return false if @server and @server != logline[:server]
    return false if @service and @service != logline[:service]
    return false if @type and @type != logline[:type]
    return false if @time_from and logline[:time] < time_from
    return false if @time_to and logline[:time] > time_to
    if @except
      @except.each do |key,value|
        return false if logline[key] == value
      end
    end
    return true
  end
end

class Counter
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
  def value
    @value
  end
end

class Distribution
  def initialize(hsh)
    @descr = hsh["Distribution"]
    @conditions = Condition.new(hsh)
    @keys = hsh["keys"] ? Printer::fatal(msg:"No aggregation fields specified for distribution!", params:hsh)
    @top = hsh["top"]
    @sort_type = hsh["sort_type"] ? hsh["sort_type"] : "total"
    @value = Distribution::hash_cnt(@keys.size)
  end
  def Distribution.hash_cnt(cnt)
    if cnt > 0
      Hash.new {|hash, key| key == :distinct or key == :total ? 0 : hash[key] = hash_cnt(cnt-1)}
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
      hsh[:distinct] += 1 unless hsh.has_key?(@keys[-1])
      hsh[:total] += 1
      hsh[logline[@keys[-1]]] += 1
    end
  end
  def finalize
    total = @value.delete(:total)
    distinct = @value.delete(:distinct)
    if @sort_type == "total"
      @value = @value.to_a.sort!{|a,b| b[1][:total] <=> a[1][:total]}.to_h.update(total:total, distinct: distinct)
    else
      @value = @value.to_a.sort!{|a,b| b[1][:distinct] <=> a[1][:distinct]}.to_h.update(total:total, distinct: distinct)
    end
    if @top
      size = @value.keys.size
      if size > @top
        @value = @value.to_a[0..@top].to_h
        @value.update(:more => size-@top)
      end
    end
  end
  def value
    @value
  end
end
