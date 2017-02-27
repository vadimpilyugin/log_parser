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