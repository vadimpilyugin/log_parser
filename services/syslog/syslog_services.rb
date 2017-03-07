
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