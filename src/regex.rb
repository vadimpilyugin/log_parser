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

class Service
  Word = "\\b[a-zA-Z0-9]+\\b"
  Ip = "\\b[.\d]+\\b"
  Path = "[^\\s\\?]+"
  Code = "\\d+"
  Pid = Code
  Port = Pid
  Username = "\\b[a-zA-Z0-9]+\\b"
  #Date = "\\b\\w{3}\\s+\\d{1,2}\\s+[\\d:]+\\b"
  Date = "(\\S+\\s+){3}"
  # def is_this_it?
  # uses service_template
public
  def Service.is_this_it? (logline)
  	if logline =~ @@service_template
  	  return true
  	else
  	  return false
  	end
  end
  # def get_parsed_data
  # uses service_regexes
  # service_regexes = {
  # "New connection" => [
  # ]
  # }
  def Service.get_data(logline)
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
    return {:descr => s, md: => res}
  end
  # uses datetime_regex
  def get_time(logline)
end

class Apache<Service
  