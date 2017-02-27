
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


class ConsoleKitDaemon<IgnoredSyslogService
  @service_name = "console-kit-daemon"
end

class Rsyslogd<IgnoredSyslogService
  @service_name = "rsyslogd"
end

class Dnsproxy<IgnoredSyslogService
  @service_name = "dnsproxy"
end