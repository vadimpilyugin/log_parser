require_relative 'date'
require_relative 'tools'
require_relative 'config'
require_relative 'fields'

require 'deepsort'

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

class Hash
  def keys_to_sym
    new_hsh = {}
    self.keys.each {|k| new_hsh[k.to_sym] = self[k]}
    new_hsh
  end
end


# This class is used to group different stats in one place
class Statistics

  @stats = {}
  @stats_counter = 0

  DEFAULT_INIT = YAML.load_file(Config["report"]["report_config"])

  class << self
    attr_reader :stats
  end

  def self.init(stats_arr = DEFAULT_INIT)
    @stats.clear
    Printer::debug msg:"Создаем #{stats_arr.size} статистик"
    stats_arr.map { |stat_opts| create_stat stat_opts }
  end
  # @return [Counter, Distribution] returns a statistics at i'th place
  def self.[](indices)
    indices.respond_to?(:map) ? indices.map {|ind| @stats[ind] } : @stats[indices]
  end

  def self.all
    @stats.values
  end

  def self.delete(ind)
    @stats.delete(ind)
  end

  # Return stat by description
  #
  # @param [String] descr description of the statistics
  # @return [Counter,Distribution,nil] the statistics or nil if not found
  # def by_descr(descr)
  #   i = @stats.index {|stat| stat.descr == descr}
  #   i ? @stats[i] : nil
  # end

  # def remove(descr)
  #   i = @stats.index {|stat| stat.descr == descr}
  #   if i != nil
  #     @stats.delete_at(i)
  #   end
  # end

  # Add new statistics to the array
  #
  # @param [Hash] params Parameters of the statistics
  # @return [void]
  def self.create_stat(params)
    if params.has_key? "Counter"
      @stats.update(@stats_counter => Counter.new(params))
    elsif params.has_key? "Distribution"
      @stats.update(@stats_counter => Distribution.new(params))
    else
      Printer::error(
        who: "Статистика без названия",
        params: stat_opts
      )
    end
    @stats_counter += 1
    return @stats_counter-1
  end

  def self.process(table)
    Printer::debug(who:"Report processing", msg:"Processing started")
    table.each_with_index do |line_hash,i|
      Printer::debug(who:"Обработано строк", msg:"#{i+1}".red+"/".white+"#{table.size}".red+"".white, in_place:true) if i%Printer::LOG_EVERY_N==0
      @stats.each_value do |stat|
        stat.increment(line_hash)
      end
    end
    puts
    @stats.values.each_with_index do |stat,i|
      Printer::debug(who:"Статистик готово", msg:"#{i+1}".red+"/".white+"#{@stats.size}".red+"".white, in_place:true)
      stat.finalize
    end
    puts
    Printer::debug(who: "Report processing", msg:"Статистики построены!")
  end
end

# Class that checks that all conditions are true
class Condition
  attr_reader :filename,:server,:service,:date,:type,:linedata,:keys
  def initialize( filename:nil, server:nil, service:nil, date:nil,
                  type:nil, linedata:nil, keys:nil)
    @filename = filename
    @server   = server
    @service  = service
    @date     = date
    @type     = type
    @linedata = linedata
    @keys     = keys
  end
  # Checks if a logline suffices all conditions
  # @param [String] logline a line to check. See Parser::parse!
  # @return [bool] True if logline suffices all conditions
  def fit?(line_hash)
    return false if @filename and @filename != line_hash[:filename]
    return false if @server   and @server   != line_hash[:server]
    return false if @service  and @service  != line_hash[:service]
    return false if @date     and @date     != line_hash[:date]
    return false if @type     and @type     != line_hash[:type]
    return false if @date     and @date     != line_hash[:date]
    # если поля и их значения в условии не являются подмножеством полей в строке
    # binding.irb
    return false if @linedata && !(@linedata <= line_hash[:linedata])
    # ключевые поля обязательно должны содержаться в строке, если они указаны
    # binding.irb
    if @keys && !@keys.map {|key| key.class == String ? line_hash[:linedata].has_key?(key) : line_hash.has_key?(key)}.all?
      return false
    end
    return true
  end
end


class Counter
  attr_reader :count, :conditions, :descr

  def initialize(stat_params)
    @descr = stat_params["Counter"]
    stat_params.delete("Counter")
    @conditions = Condition.new(stat_params.keys_to_sym)
    @count = 0
  end
  def increment(line_hash)
    @count += 1 if @conditions.fit?(line_hash)
  end
  def finalize
    @count
  end
  # def to_s
  #   @descr + ": " + @count.to_s
  # end
end

class Distribution
  attr_reader :conditions, :descr, :keys, :distrib, :sort_type, :top

  TOTAL_SORT_TYPE = 'total'
  DISTINCT_SORT_TYPE = 'distinct'

  FORWARD_SORT_ORDER = 'forward'
  BACKWARD_SORT_ORDER = 'backward'

  DEFAULT_TOP_VALUE = 10
  KEYS_FIELD    = Fields["Statistics"][:keys]
  TOP_FIELD     = Fields["Statistics"][:top]
  SORT_FIELD    = Fields["Statistics"][:sort_type]
  SORT_ORDER    = Fields["Statistics"][:sort_order]

  def initialize(stat_params)
    @descr      = stat_params.delete "Distribution"
    if !stat_params.has_key?(KEYS_FIELD)
      binding.irb
    end
    @keys       = Fields.keys_to_sym stat_params.delete(KEYS_FIELD)
    @top        = stat_params.delete TOP_FIELD
    @sort_type  = stat_params.delete SORT_FIELD
    @sort_order  = stat_params.delete SORT_ORDER
    # binding.irb
    @conditions = Condition.new(stat_params.keys_to_sym.update(keys:@keys))
    @distrib    = Distribution::hash_cnt(@keys.size)

    @sort_type  = TOTAL_SORT_TYPE if @sort_type.nil?
    @sort_order  = FORWARD_SORT_ORDER if @sort_order.nil?
    @top        = DEFAULT_TOP_VALUE if @top.nil?

    Printer::assert(
      expr: !@keys.nil?,
      who: @descr,
      msg:"в распределении не указаны ключи (поле :keys)",
    )
  end
  # def to_h
  #   return {@descr => @distrib}
  # end
  def Distribution.hash_cnt(cnt)
    if cnt > 0
      Hash.new {|hash, key| (key == :distinct or key == :total) ? 0 : hash[key] = hash_cnt(cnt-1)}
    else
      0
    end
  end

  def update_distrib(keys)
    distr_part = @distrib
    keys[0..-2].each do |key|
      distr_part[:distinct] += 1 unless distr_part.has_key?(key)
      distr_part[:total] += 1
      distr_part = distr_part[key]
    end
    distr_part[:distinct] += 1 unless distr_part.has_key?(keys.last)
    distr_part[:total] += 1
    distr_part[keys.last] += 1
  end

  def increment(line_hash)
    # если строка подходит под условия
    if @conditions.fit?(line_hash)
      # binding.irb
      keys = @keys.map {|key| key.class == Symbol ? line_hash[key] : line_hash[:linedata][key]}
      update_distrib(keys)
      # hsh = @distrib
      # @keys[0..-2].each do |field_name|
      #   hsh[:distinct] += 1 unless hsh.has_key?(line_hash[key])
      #   hsh[:total] += 1
      #   hsh = hsh[line_hash[key]]
      # end
      # hsh[:distinct] += 1 unless hsh.has_key?(line_hash[@keys[-1]])
      # hsh[:total] += 1
      # hsh[line_hash[@keys[-1]]] += 1
    end
  end
  def finalize
  #   total     = @distrib.delete(:total)
  #   distinct  = @distrib.delete(:distinct)
  #   # если уровней вложенности всего один
  #   if @keys.size == 1
  #     # сортируем по убыванию
  #     @distrib = @distrib.sort_by {|k,v| -v}.to_h
  #   else
  #     # уровней вложенности больше одного
  #     # если сортировка по общему числу
  #     if @sort_type == TOTAL_SORT_TYPE
  #       @distrib = @distrib.sort_by {|k,v| -v[:total]}
  #     else
  #       @distrib = @distrib.sort_by {|k,v| -v[:distinct]}
  #     end
  #   end
  #   if @top
  #     size = @distrib.size
  #     if size > @top
  #       @distrib = @distrib[0..@top]
  #       @distrib << [:more, size-@top]
  #     end
  #   end
  #   @distrib << [:total, total]
  #   @distrib << [:distinct, distinct]
  #   @distrib = @distrib.to_h
  # end
    @distrib = @distrib.deep_sort_by do |o|
      if o[1].class == Hash
        sym = @sort_type == TOTAL_SORT_TYPE ? :total : :distinct
        if @sort_order == FORWARD_SORT_ORDER
          -o[1][sym]
        else
          o[1][sym]
        end
      else
        if @sort_order == FORWARD_SORT_ORDER
          -o[1]
        else
          o[1]
        end
      end
    end
  end
end
