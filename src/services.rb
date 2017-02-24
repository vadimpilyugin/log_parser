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

class Sshd<SyslogService
  @@service_name = "sshd"
  @@service_regexes = {
    "New connection" => [
        /Connection from (?<user_ip>S+) port (?<user_port>S+) on (?<server_ip>S+) port (?<server_port>S+)/
      ],
    "Disconnect" => [
        /Received disconnect from (?<user_ip>S+)/,
        /Disconnected from (?<user_ip>S+)/,
        /Connection closed by (?<user_ip>S+)/,
        /Connection reset by (?<user_ip>S+)/,
      ],
    "Accepted publickey" => [
        /Accepted publickey for (?<username>S+) from (?<user_ip>S+) port (?<user_port>S+) S+: (?<protocol>S+) (?<hashing-alg>S+):(?<publickey>S+)/
      ],
    "Session activity" => [
        /pam_unix(sshd:session): session (?<action>S+) for user (?<username>S+)/
      ],
    "Auth fail" => [
        /Failed (S+) for invalid user (?<username>S+) from (?<user_ip>S+) port (?<user_port>S+) ssh2/,
        /Failed (S+) for (?<username>S+) from (?<user_ip>S+) port (?<user_port>S+) ssh2/
      ],
    "Invalid user" => [
        /Invalid user (?<username>S+) from (?<user_ip>S+)/
      ],
    "Postponed publickey" => [
        /Postponed publickey for (?<username>S+) from (?<user_ip>S+) port (?<user_port>S+)/
      ],
    "Ignore" => [
        /^(PAM|pam_unix|error: PAM|Disconnecting)/
        /^input_userauth_request/
        /^User child is on pid/
        /^Starting session: command for S+/
        /^fatal: Unable to negotiate with/
        /^Postponed keyboard-interactive/
        /^Did not receive identification string/
        /^Starting session: shell on S+/
        /Received SIGHUP; restarting.|Server listening/
        /maximum authentication attempts exceeded/
        /Bad protocol version identification/
      ]
    }
end

class Cron<Service
  @@service_name = "cron"
  @@service_regexes = {
    "Session activity" => [
        /pam_unix\(cron:session\): session (?<action>\S+) for user (?<username>\S+)/
    ]
  }
end

class SystemdLogind<SyslogService
  @@service_name = "systemd-logind"
  @@service_regexes = {
    "New session" => [
        "New session (?<pid>d+) of user (?<username>S+)"
      ],
    "Removed session" => [
        "Removed session (?<pid>d+)"
      ]
  }