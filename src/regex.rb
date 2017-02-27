require_relative 'tools'
require_relative 'config'

class MatchData
  def to_h
    a = self.captures.delete_if {|e| e == nil}
    self.names.zip(a).to_h
  end
end

class Templates
  Word = "\\b[a-zA-Z0-9]+\\b"
  Ip = "\\b[.\d]+\\b"
  Path = "[^\\s\\?]+"
  Code = "\\d+"
  Pid = Code
  Port = Pid
  Username = "\\b[a-zA-Z0-9]+\\b"
  # Ip = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
  Ip = "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}"
  #Date = "\\b\\w{3}\\s+\\d{1,2}\\s+[\\d:]+\\b"
  Date = "(\\S+\\s+){3}"
  SyslogTime = %r{ ^
    (?<month>\S+)\s+    # Oct
    (?<day>\S+)\s+      # 9
    (?<hour>[^:]+):     # 06:
    (?<minute>[^:]+):   # 08:
    (?<second>[^\s]+)   # 05
  }x
  ApacheTime = %r{  ^
    ^(\S+)              # 141.8.142.23
    [^\[]+\[            # - - [
    (?<day>[^\/]+)\/    # 09/
    (?<month>[^\/]+)\/  # Oct/
    (?<year>[^\:]+)\:   # 2016:
    (?<hour>[^\:]+)\:   # 06:
    (?<minute>[^\:]+)\: # 35:
    (?<second>[^\s]+)\s # 46
  }x
  def self.syslog(service)
    return %r{  ^
      ^#{Date}                  # Oct  9 06:36:12 - три первых слова
      (?<server>\S+)\s+               # newserv
      (?<service>#{service})             # systemd-logind - все, вплоть до квадратной скобки или :
      (\[(?<pid>#{Pid})\])?           # [10405] - может идти, а может и не идти за именем сервиса
      :\s+(?<msg>.*)                # : Accepted publickey for autocheck
    }x
  end
  Apache = %r{  ^
    ^(?<user_ip>#{Ip})                              # 141.8.142.23
    [^"]+"                                        # - - [09/Oct/2016:06:35:46 +0300]"
    (?<method>\S+)\s (?<path>#{Templates::Path})   # GET /images/logos/russia/vmk.gif
    [^"]+"\s (?<code>\S+)                         # HTTP/1.0" 404
  }x
  def Templates.load(service)
    services_dir = Config["parser"]["services_dir"]
    filename = "#{services_dir}/#{service.downcase}"
    Printer::assert(Tools.file_exists?(filename), "Шаблоны для сервиса не найдены", "Path to services files":services_dir, "Service":service)
    hsh = YAML.load_file(filename)
    Printer::assert(hsh != nil, "Templates for service have not been loaded", "Service":service)
    hsh.each_value do |ar|
      ar.map! do |s|
        Regexp.new(s)
      end
    end
    return hsh
  end
end

class Service

  def Service.build_datetime(hsh)
    # Printer::debug("Got a datetime request", hsh)
    if hsh.empty?
      return Time.new(1917,"Oct",7,1,0,0,0)
    else
      year = hsh["year"].to_i
      month = hsh["month"]
      month = case month
        when "Jan", "01" then 1
        when "Feb", "02" then 2
        when "Mar", "03" then 3
        when "Apr", "04" then 4
        when "May", "05" then 5
        when "Jun", "06" then 6
        when "Jul", "07" then 7
        when "Aug", "08" then 8
        when "Sep", "09" then 9
        when "Oct", "10" then 10
        when "Nov", "11" then 11
        when "Dec", "12" then 12
        # else Printer::note(true, "Something went wrong: Unknown month", "Month":month, "Service":@service_name)
      end
      day = hsh["day"].to_i
      hour = hsh["hour"].to_i
      minute = hsh["minute"].to_i
      second = hsh["second"].to_i
      Printer::assert(year >= 1900 && year <= 2100, "Year is incorrect", hsh.update(:msg => "Parser"))
      Printer::assert(month >= 1 && month <= 12, "Month is incorrect", hsh.update(:msg => "Parser"))
      Printer::assert(day >= 1 && day <= 31, "Day is incorrect", hsh.update(:msg => "Parser"))
      Printer::assert(hour >= 0 && hour <= 24, "Hour is incorrect", hsh.update(:msg => "Parser"))
      Printer::assert(minute >= 0 && minute <= 60, "Minute is incorrect", hsh.update(:msg => "Parser"))
      Printer::assert(second >= 0 && second <= 60, "Second is incorrect", hsh.update(:msg => "Parser"))
      # return "#{year}-#{month}-#{day}T#{hours}-#{minutes}-#{seconds}-0600"
      return Time.new(year,month,day,hour,minute,second)
    end
  end
  def self.init
    # @service_name = nil
    # @service_template = nil
    # @service_regexes = nil
    # @msg_field = nil
    # @time_regex = nil
    self
  end
  def self.get_datetime(logline)
    Printer::assert(@time_regex != nil, "You should assign a value to @time_regex or redefine get_datetime!")
    success = (logline =~ @time_regex)
    if !success
      Printer::note(true, "Date was not parsed",msg:"Parser","Line":logline,"Time regex":@time_regex)
    end
    datetime = $~.to_h
    return build_datetime(datetime)
  end
  def self.get_data(logline)
    if @msg_field
      Printer::assert(@msg_field.class == Symbol, "You should assign a Symbol value to @msg_field", "Value":@msg_field)
      logline =~ @service_template
      logline = $~[@msg_field]
      Printer::assert(logline != nil, "No such field in @service_template", "Field":@msg_field, 
                              "Available fields":@service_template.named_captures.keys,
                              "Service":@service_name)
    end
    s = nil
    res = nil
    @service_regexes.each do |key,value|
      break if s
      value.each do |regex|
        if logline =~ regex
          s = key
          res = $~.to_h
          break
        end
      end
    end
    if s == nil || res == nil
      Printer::note(s == nil || res == nil, "Не удалось распарсить строку", "Line":logline, "Service":@service_name)
      return {:descr => "__UNDEFINED__", :md => [{"logline" => logline}]}
    end
    data = []
    res.each_pair do |key,value|
      data << {:name => key, :value => value}
    end
    return {:descr => s, :md => data}
  end
public
  def self.services
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
  def self.check (logline)
    Printer::assert(@service_template, "Template is empty! Check that you have assigned a value to @service_template in your class")
  	if logline =~ @service_template
  	  return true
  	else
  	  return false
  	end
  end
  def self.ignore?
    return @ignore
  end
  def self.name
    return @service_name
  end
  def self.parse!(logline)
    server_name = get_server_name(logline)
    service_name = @service_name
    datetime = self.get_datetime(logline)
    match_data = self.get_data(logline)
    descr = match_data[:descr]
    data = match_data[:md]

    return {:server => server_name, :service => service_name, 
            :time => datetime, :descr => descr, :data_values => data}
  end
end