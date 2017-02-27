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
        /\[(ssh|pam-generic)\] Ban (?<user_ip>\S+)/,
        /\[(ssh|pam-generic)\] Unban (?<user_ip>\S+)/,
        /\[(ssh|pam-generic)\] \S+ already banned/,
      ],
    "Failed ban/unban action" => [
        /Failed to execute ban jail/,
        /Failed to execute unban jail/
      ],
    "Log rotation" => [
        /Log rotation detected for (?<path>\S+)/,
        /rollover performed on (\S+)/
      ],
    "DDOS detected" => [
        /\[ssh-ddos\] Found (?<user_ip>\S+)/
      ],
    "Strange errors" => [
        /Invariant check failed\. Trying to restore a sane environment/,
        /iptables (.*) -- stderr/
      ],
    "Ignore" => [
        /\[(ssh|pam-generic)\] Found \S+/,
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