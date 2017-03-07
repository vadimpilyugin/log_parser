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

require_relative 'syslog_services.rb'