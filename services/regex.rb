require_relative '../src/tools'
require_relative '../src/config'

class MatchData
  def to_h
    a = self.captures.delete_if {|e| e == nil}
    self.names.zip(a).to_h
  end
end

class Templates
  Word = "\\b[a-zA-Z0-9]+\\b"
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
  def Templates.load(service,services_dir)
    # services_dir = Config["parser"]["services_dir"]
    filename = "#{services_dir}/#{service.downcase}.yml"
    Printer::assert(Tools.file_exists?(filename), "Templates have not been found", "Path to services files":services_dir, "Service":service)
    hsh = YAML.load_file(filename)
    Printer::assert(hsh != nil, "Templates for service have not been loaded", "Service":service)
    hsh.each_value do |ar|
      ar.map! do |s|
        Regexp.new(s)
      end
    end
    Printer::debug("Successfully loaded template file for #{service}!", debug_msg:"Preparations")
    return hsh
  end
end
