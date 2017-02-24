require_relative 'tools'

# module Regexes
# 	Word = "\\b[a-zA-Z0-9]+\\b"
# 	Ip = "\\b[.\d]+\\b"
# 	Path = "[^\\s\\?]+"
# 	Code = "\\d+"
# 	Pid = Code
# 	Port = Pid
# 	Username = "\\b[a-zA-Z0-9]+\\b"
# 	#Date = "\\b\\w{3}\\s+\\d{1,2}\\s+[\\d:]+\\b"
# 	Date = "(\\S+\\s+){3}"
# 	Apache = %r{
# 		^(?<user_ip>\S+)									# 141.8.142.23
# 		[^"]+"										# - - [09/Oct/2016:06:35:46 +0300]"
# 		(?<method>\S+)\s (?<path>#{Path})			# GET /images/logos/russia/vmk.gif
# 		[^"]+"\s (?<code>\S+)						# HTTP/1.0" 404
# 	}x
# 	Syslog = %r{
# 		^#{Date}	 								# Oct  9 06:36:12 - три первых слова
# 		(?<server>\S+)\s+ 							# newserv
# 		(?<service>[^\[:]+)							# systemd-logind - все, вплоть до квадратной скобки или :
# 		(\[(?<pid>#{Pid})\])?						# [10405] - может идти, а может и не идти за именем сервиса
# 		:\s+(?<msg>.*)								# : Accepted publickey for autocheck
# 	}x
# 	Unidentified = %r{.*}
# end

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
  #Date = "\\b\\w{3}\\s+\\d{1,2}\\s+[\\d:]+\\b"
  Date = "(\\S+\\s+){3}"
  SyslogTime = %r{ ^
    (?<month>\S+)\s+    # Oct
    (?<day>\S+)\s+)     # 9
    (?<hour>[^:]+):     # 06:
    (?<minute>[^:]+):   # 08:
    (?<second>[^\s]+)   # 05
  }x
  ApacheTime = %r{
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
    return %r{
      ^#{Date}                  # Oct  9 06:36:12 - три первых слова
      (?<server>\S+)\s+               # newserv
      (?<service>#{service})             # systemd-logind - все, вплоть до квадратной скобки или :
      (\[(?<pid>#{Pid})\])?           # [10405] - может идти, а может и не идти за именем сервиса
      :\s+(?<msg>.*)                # : Accepted publickey for autocheck
    }x
  end
  Apache = %r{
    ^(?<user_ip>\S+)                              # 141.8.142.23
    [^"]+"                                        # - - [09/Oct/2016:06:35:46 +0300]"
    (?<method>\S+)\s (?<path>#{Templates::Path})   # GET /images/logos/russia/vmk.gif
    [^"]+"\s (?<code>\S+)                         # HTTP/1.0" 404
  }x
end

class Service
  @@msg_field = nil
  @@time_regex = nil

  def Service.build_datetime(hsh)
    year = hsh[:year].to_i
    month = hsh[:month]
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
      else printf("Something went wrong: Unknown month #{month}")
    end
    day = hsh[:day].to_i
    hour = hsh[:hour].to_i
    minute = hsh[:minute].to_i
    second = hsh[:second].to_i
    Printer::assert(year >= 1900 && year <= 3000, "Something went wrong", "Year":year)
    Printer::assert(month >= 1 && month <= 12, "Something went wrong", "Month":month)
    Printer::assert(day >= 1 && day <= 31, "Something went wrong", "Day":day)
    Printer::assert(hour >= 0 && hour <= 24, "Something is wrong", "Hour":hour)
    Printer::assert(minute >= 0 && minute <= 60, "Something is wrong", "Minute":minute)
    Printer::assert(second >= 0 && second <= 60, "Something went wrong", "Second":second)
    # return "#{year}-#{month}-#{day}T#{hours}-#{minutes}-#{seconds}-0600"
    return [year,month,day,hour,minute,second]
  end
  def self.get_datetime(logline)
    assert(@@time_regex != nil, "You should assign a value to @@time_regex or redefine get_datetime!")
    logline =~ @@time_regex
    return self.build_datetime($~.to_h)
  end
  def self.get_data(logline)
    if @@msg_field
      logline =~ @@service_template
      logline = $~[@@msg_field]
    end
    s = nil
    res = nil
    @@service_regexes.each do |key,value|
      break if s
      value.each do |regex|
        if logline =~ regex
          s = key
          res = $~.to_h
          break
        end
      end
    end
    return {:descr => s, :md => res}
  end
public
  def self.services
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
  def self.is_this_it? (logline)
  	if logline =~ @@service_template
  	  return true
  	else
  	  return false
  	end
  end
  def self.parse(logline)
    server_name = get_server_name(logline)
    service_name = @@service_name
    datetime = self.get_datetime(logline)
    match_data = self.get_data(logline)
    descr = match_data[:descr]
    data = match_data[:md]

    return {:server_name => server_name, :service_name => service_name, 
            :datetime => datetime, :descr => descr, :data => data}
  end
end
  

class SyslogService<Service
  @@service_template = Templates::syslog(@@service_name)
  @@msg_field = :msg

  def self.get_datetime(logline)
    logline =~ Templates::SyslogTime
    time_hsh = $~.to_h
    time_hsh[:year] = 1997    # FIXME: we need a correct year
    return self.build_datetime(time_hsh)
  end
  def self.get_server_name(logline)
    logline =~ @@service_template
    return $~[:server]
  end
end