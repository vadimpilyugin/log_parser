class Fail2Ban<Service
  @service_name = "fail2ban"
  @service_template = %r{
    
    (\S+)\s+              # 2017-02-05
    (\S+)\s+              # 07:05:13,390
    (?<server>\S+)\s+     # fail2ban.server
    (\[\d+\]):\s+         # [1686]: 
    (\S+)\s+              # INFO    
    (?<msg>.*)            # rollover performed on /var/log/fail2ban.log
  }x
  @service_regexes = {
    "Ban/unban action" => [
        /\[(?<service>\S+)\] Found \S+/,
        /\[(?<service>\S+)\] Ban (?<user_ip>\S+)/,
        /\[(?<service>\S+)\] Unban (?<user_ip>\S+)/,
        /\[(?<service>\S+)\] \S+ already banned/,
        /\[(?<service>\S+)\] Ignore (?<user_ip>\S+) by ip/,
      ],
    "Failed ban/unban action" => [
        /Failed to execute ban jail/,
        /Failed to execute unban jail/
      ],
    "Log rotation" => [
        /Log rotation detected for (?<path>\S+)/,
        /rollover performed on (\S+)/
      ],
    "Strange errors" => [
        /Invariant check failed\. Trying to restore a sane environment/,
        /iptables (.*) -- stderr/
      ],
    "Ignore" => [
        /iptables/
      ],
  }
  @time_regex = %r{ ^
    (?<year>\d+)-       # 2017-
    (?<month>\d+)-      # 02-
    (?<day>\d+)\s+      # 05
    (?<hour>\d+):       # 07:
    (?<minute>\d+):     # 05:
    (?<second>\d+)      # 13
  }x
  def self.get_server_name(logline)
    logline =~ @service_template
    return $~["server"]
  end
  # @msg_field = :msg
end