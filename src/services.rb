require_relative 'regex'
require 'yaml'

#           Each subclass should define these variables:
#           @service_name - a string that contains the name of the service
#           @service_template - to check whether this logline belongs to 
#                                current service
#           @service_regexes - hash of type "Description" => [reg1, reg2,...]
#           @time_regex - regex with fields named year, month, day, hour, minute, second
#             OR
#           get_datetime(logline) - returns a Ruby Time object
#                                   redefine this method if your log doesn't have some fields, like year        

#           Each subclass should define these methods:
#           get_server_name(logline) - returns the name of the server from where
#                                      this log came from
#           Additionally, each subclass can change the value of these variables:
#           @msg_field - may contain a symbol which represents a field in the 
#                         @service_template. nil by default. Change it if you
#                         want to parse only a part of logline
#           @ignore - just ignore this service. Don't store its lines in the database, don't parse its lines.
#           Additionally, each subclass can redefine these methods from the base class:
#           get_data(logline) - returns a hash of form {:descr => descr_str, :md => data}
#                               redefine this method if your service is like sshd, i.e., needs to compare
#                               only a part of a logline containing message

# class ServiceName<Service
#   @service_name = 
#   @service_template = 
#   @service_regexes = 
#   @time_regex = 
#   def self.get_server_name(logline)

class Apache<Service
  @service_name = "apache"
  @service_template = Templates::Apache
  @time_regex = Templates::ApacheTime
  @service_regexes = {
    "Connection information" => [@service_template]
  }
  def self.get_server_name(logline)
    return 'fixme'    # FIXME: we need a correct server name here 
  end
end

class SyslogService<Service

  def self.get_datetime(logline)
    logline =~ Templates::SyslogTime
    time_hsh = $~.to_h
    time_hsh["year"] = 1997    # FIXME: we need a correct year
    return build_datetime(time_hsh)
  end
  def self.init
    @service_template = Templates::syslog(@service_name)
    @msg_field = :msg
    @service_regexes = @service_regexes ? @service_regexes : Templates::load(@service_name) # you can choose to write templates to file
                                                                                            # or to keep them in code
    self
  end
  def self.get_server_name(logline)
    logline =~ @service_template
    return $~[:server]
  end
end

class Sshd<SyslogService
  @service_name = "sshd"
end

class Cron<SyslogService
  @service_name = "CRON"
end

class SystemdLogind<SyslogService
  @service_name = "systemd-logind"
end

class Systemd<SyslogService
  @service_name = "systemd"
end

class Su<SyslogService
  @service_name = "su"
end

class IgnoredSyslogService<SyslogService
  def self.get_datetime(logline)
    Printer::assert(false, "Called get_datetime for ignored service", msg:"Parser")
  end
  def self.init
    @service_template = Templates::syslog(@service_name)
    @ignore = true
    self
  end
  def self.get_server_name(logline)
    Printer::assert(false, "Called get_server_name for ignored service", msg:"Parser")
  end
end

class ConsoleKitDaemon<IgnoredSyslogService
  @service_name = "console-kit-daemon"
  @service_regexes = {
    "Ignore" => [
        /GLib-CRITICAL: Source ID \S+ was not found when attempting to remove it/,
        /\(process:(\d+)\): GLib-CRITICAL \*\*: g_slice_set_config: assertion 'sys_page_size == 0' failed/,
        /missing action/
    ]
  }
end

class Rsyslogd<IgnoredSyslogService
  @service_name = "rsyslogd"
end

class Dnsproxy<IgnoredSyslogService
  @service_name = "dnsproxy"
end

Services = [Apache,Sshd,Cron,SystemdLogind,Systemd,Su,ConsoleKitDaemon,Rsyslogd,Dnsproxy].map {|cl| cl.init}