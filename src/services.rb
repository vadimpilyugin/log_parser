require_relative 'regex'
require 'YAML'

#           Each subclass should define these variables:
#           @@service_name - a string that contains the name of the service
#           @@service_template - to check whether this logline belongs to 
#                                current service
#           @@service_regexes - hash of type "Description" => [reg1, reg2,...]
#           @@time_regex - regex with fields named year, month, day, hour, minute, second
#             OR
#           get_datetime(logline) - returns an array of form [y,m,d,h,m,s]
#                                   redefine this method if your log doesn't have some fields, like year         

#           Each subclass should define these methods:
#           get_server_name(logline) - returns the name of the server from where
#                                      this log came from
#           Additionally, each subclass can change the value of these variables:
#           @@msg_field - may contain a symbol which represents a field in the 
#                         @@service_template. nil by default. Change it if you
#                         want to parse only a part of logline
#           Additionally, each subclass can redefine these methods from the base class:
#           get_data(logline) - returns a hash of form {:descr => descr_str, :md => data}
#                               redefine this method if your service is like sshd, i.e., needs to compare
#                               only a part of a logline containing message

# class ServiceName<Service
#   @@service_name = 
#   @@service_template = 
#   @@service_regexes = 
#   @@time_regex = 
#   def self.get_server_name(logline)

class Apache<Service
  @@service_name = "apache"
  @@service_template = Templates::Apache
  @@time_regex = Templates::ApacheTime
  @@service_regexes = {
    "Connection information" => [@@service_template]
  }
  def self.get_server_name(logline)
    return 'fixme'    # FIXME: we need a correct server name here 
  end
end

class SyslogService<Service
  @@service_template = Templates::syslog(@@service_name)
  @@msg_field = :msg
  @@service_regexes = Templates::load(@@service_name)

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

class Sshd<SyslogService
  @@service_name = "sshd"
end

class Cron<SyslogService
  @@service_name = "cron"
end

class SystemdLogind<SyslogService
  @@service_name = "systemd-logind"
end

class Systemd<SyslogService
  @@service_name = "systemd"
end

class Su<SyslogService
  @@service_name = "su"
end

Services = [Apache, Sshd, Cron, SystemdLogind, Systemd, Su]