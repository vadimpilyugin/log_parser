require 'dm-core'

# Various date manipulations.
class CreateDate
  # Create Ruby Time object from hash of parameters. Default to Time.now
  # @param [Hash] hsh opts for creating the date
  # @option hsh [Integer] :year year
  # @option hsh [Integer] :month month
  # @option hsh [Integer] :day day
  # @option hsh [Integer] :hour hour
  # @option hsh [Integer] :minute minute
  # @option hsh [Integer] :second second
  # @return [Time] time object built from params. Default to Time.now
  def self.create(hsh)
  	default_time = Time.now
  	return Time.new(
  	  hsh[:year] ? hsh[:year] : default_time.year,
  	  hsh[:month] ? hsh[:month] : default_time.month,
  	  hsh[:day] ? hsh[:day] : default_time.day,
  	  hsh[:hour] ? hsh[:hour] : default_time.hour,
  	  hsh[:minute] ? hsh[:minute] : default_time.min,
  	  hsh[:second] ? hsh[:second] : default_time.sec,
  	)
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