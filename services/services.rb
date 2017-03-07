require_relative 'regex'

#           Each Service's subclass should define these variables:
#           @service_name - a string that contains the name of the service
#           @service_template - a regex which is used to check whether the current logline belongs to 
#                               the given service
#           @service_regexes - a hash containing service templates. Example: 
#           {
#             "New connection" => [/Received connection/, /Connection from/,...],
#             "Connection closed" => [/Received disconnect from/]
#             "Ignore" => [/PAM: unix/]
#           }
#           @time_regex - regex with fields named year, month, day, hour, minute, second
#             OR
#           self.get_datetime(logline) - returns a Ruby Time object
#                                   redefine this method if your log doesn't have some of the required fields, like year        

#           Each subclass should define these methods:
#           self.get_server_name(logline) - returns the name of the server from where
#                                      this log came from
#           Additionally, each subclass can change the value of these variables:
#           @msg_field - may contain a symbol which represents a field in the 
#                         @service_template. nil by default. Change it if you
#                         want to parse only a part of logline
#           @ignore - just ignore this service. Don't store its lines in the database, don't even parse them.
#           Additionally, each subclass can redefine these methods from the base class:

# class ServiceName<Service
#   @service_name = 
#   @service_template = 
#   @service_regexes = 
#   @time_regex = 
#   def self.get_server_name(logline)


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

    Printer::assert("No name provided for service", "Service":self.class, msg:"Preparations")
    Printer::debug("Found new service: #{@service_name}", debug_msg:"Preparations")
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
      # Printer::note(s == nil || res == nil, "Не удалось распарсить строку", "Line":logline, "Service":@service_name)
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

require_relative './syslog/syslog.rb'
require_relative './apache/apache.rb'
require_relative './fail2ban/fail2ban.rb'


Services = [Fail2Ban,Apache,Sshd,Cron,SystemdLogind,Systemd,Su,ConsoleKitDaemon,Rsyslogd,Dnsproxy].map {|service| service.init}
