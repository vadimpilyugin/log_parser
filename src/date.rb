require 'dm-core'

class MyDate
  attr_reader :year,:month,:day,:hour,:minute,:second,:timezone
  def initialize(year,month,day,hour,minute,second,timezone)
    @year = year.to_i
    @month = Date::MONTHNAMES.index("month")
    @month = 0 unless @month
    @day = day.to_i
    @hour = hour.to_i
    @minute = minute.to_i
    @second = second.to_i
    @timezone = timezone
    # Printer::note(who:"MyDate(#{@year},#{@month},#{@day},#{@hour},#{@minute},#{@second},#{@timezone})")
    # Printer::note(who:"MyDate(#{@year.class},#{@month.class},#{@day.class},#{@hour.class},#{@minute.class},#{@second.class},#{@timezone.class})")
  end
end

# Various date manipulations.
class CreateDate
  # Create Ruby Time object from hash of parameters. Default to Time.now
  # @param [Hash] hsh opts for creating the date
  # @option hsh [Integer] 'year' year
  # @option hsh [Integer] 'month' month
  # @option hsh [Integer] 'day' day
  # @option hsh [Integer] 'hour' hour
  # @option hsh [Integer] 'minute' minute
  # @option hsh [Integer] 'second' second
  # @return [Time] time object built from params. Default to Time.now

	CURRENT_TIME = Time.now
  DEFAULT_TIMEZONE = "+03:00"
  DEFAULT_TIME = MyDate.new(CURRENT_TIME.year,CURRENT_TIME.month,CURRENT_TIME.day,
    CURRENT_TIME.hour,CURRENT_TIME.min,CURRENT_TIME.sec,DEFAULT_TIMEZONE)

  def self.create(
    year:   DEFAULT_TIME.year, 
    month:  DEFAULT_TIME.month, 
    day:    DEFAULT_TIME.day, 
    hour:   DEFAULT_TIME.hour, 
    minute: DEFAULT_TIME.minute, 
    second: DEFAULT_TIME.second,
    timezone: DEFAULT_TIME.timezone
  )
    # begin
      MyDate.new(year, month, day, hour, minute, second, timezone)
      # Time.new(year, month, day, hour, minute, second, timezone)
    # rescue ArgumentError => exc
    #   if exc.message == "mon out of range"
    #     Printer::error(
    #       who: "DateError",
    #       msg: "Значение месяца неверное: #{month.inspect}"
    #     )
    #     # Time.new(year, DEFAULT_TIME.month, day, hour, minute, second, timezone)
    #   else
    #     Printer::error(
    #       who: "DateError",
    #       msg: "Значение поля неверное: #{exc.inspect}"
    #     )
    #     DEFAULT_TIME
    #   end
    # end
  end
  # Creates time object from a string
  # @param [String] string string containing time
  # @param [Regexp] regex regular expression to parse the string with
  # @param ["min", "max"] cond Set the hour, minute and second to max value if cond == "max"
  # @return [Time] Time object constructed from string
  def self.create_from(string, regex = /(?<day>\d+)\s+(?<month>\S+)\s+(?<year>\d+)\s*/, cond)
    if (string =~ regex) == nil
      return Time.new(0)
    else
      date = {}
      $~.names.each do |key|
        date.update({key.to_sym => $~[key.to_sym]})
      end
      if cond == "max"
        date.update(hour: "23", minute: "59", second: "59")
      elsif cond == "min"
        date.update(hour: "00", minute: "00", second: "00")
      end
      return CreateDate.create(date)
    end
  end
  # Build date based on this regex:
  # {
  #   /(?<year>\d+)-(?<month>\d+)-(?<day>\d+)T(?<hour>\d+):(?<minute>\d+):(?<second>\d+)/
  # }
  # @param [String] date String containing date
  # @return [Time] Time object
  def self.datetime_to_time(date)
    r = /(?<year>\d+)-(?<month>\d+)-(?<day>\d+)T(?<hour>\d+):(?<minute>\d+):(?<second>\d+)/
    date.to_s =~ r
    hsh = $~.to_h
    hsh.keys.each do |key|
      a = hsh.delete(key)
      hsh.update(key.to_sym => a)
    end
    return create(hsh)
  end
end
