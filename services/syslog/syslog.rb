require 'yaml'

class SyslogService<Service

  def self.get_datetime(logline)
    logline =~ Templates::SyslogTime
    time_hsh = $~.to_h
    time_hsh["year"] = 1997    # FIXME: we need a correct year
    return build_datetime(time_hsh)
  end
  def self.init
    @service_template = Templates::syslog(@service_name)
    return self if @ignore
    @msg_field = :msg
    @service_regexes = @service_regexes ? @service_regexes : Templates::load(@service_name, 'services/syslog') 
                                                            # you can choose to write templates to file
                                                            # or to keep them in code
    super
    self
  end
  def self.get_server_name(logline)
    logline =~ @service_template
    return $~[:server]
  end
end


# class IgnoredSyslogService<SyslogService
#   def self.get_datetime(logline)
#     Printer::assert(false, "Called get_datetime for ignored service", msg:"Parser")
#   end
#   def self.init
#     @service_template = Templates::syslog(@service_name)
#     @ignore = true
#     self
#   end
#   def self.get_server_name(logline)
#     Printer::assert(false, "Called get_server_name for ignored service", msg:"Parser")
#   end
# end


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


class ConsoleKitDaemon<SyslogService
  @service_name = "console-kit-daemon"
  @service_regexes = {
    "Strange errors" => [
        /assertion '.*' failed/,
        /missing action/,
        /Source ID (\S+) was not found when attempting to remove it/
      ],
  	"Ignore" => [
  	    /pam_unix/
  	  ]
  }
end

class Rsyslogd<SyslogService
  @service_name = "rsyslogd"
  @service_regexes = {
    "Strange errors" => [
        /rsyslogd was HUPed/
      ],
    "Ignore" => [
        /-- MARK --/
      ]
  }
end

class KernelService<SyslogService
  @service_name = "kernel"
  @service_regexes = {
    "Segmentation fault" => [
        /segfault/
      ]
  }  
end

class Dnsproxy<SyslogService
  @service_name = "dnsproxy"
  @ignore = true
end
