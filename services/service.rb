require_relative '../src/tools.rb'
require_relative '../src/config.rb'

# Метод parse! возвращает хэш, содержащий поля: 
# uid, data и descr. Поле data содержит хэш, в котором лежит вся
# информация, полученная из шаблонов сервиса. Поле descr содержит
# описание подошедшего шаблона. Поле uid содержит уникальный код
# того регулярного выражения, под которое подошла строка. Метод 
# вернет nil, если строка не подходит ни под один шаблон сервиса.
# "data" => {"user_ip" => 127.0.0.1, "user_port" => 2222}
# "descr" => "New connection"

# Метод check проверяет, принадлежит ли строка к данному сервису.
# Эквивалентно parse(s) != nil

class Service

public
  def initialize(service_name, service_templates)
  	@service_name = service_name
  	@service_templates = service_templates
  end

  def check(logline)
  	return self.parse!(logline) != nil
  end

  def parse!(logline)
  	data = nil
    descr = nil
    reg = nil
    @service_templates.each do |key,value|
      break if data != nil
      value.each do |regex|
        if logline =~ regex
          descr = key
          data = $~.to_h
          reg = regex
          break
        end
      end
    end
    if data == nil
      return nil
    else
      return {"data" => data, "type" => descr, "uid" => reg.hash}
    end
  end
end

# Services.[] - Получить доступ к сервису по имени. Если такого сервиса нет, вернется nil
# Если есть, то вернется instance класса Service, представляющий нужный сервис.
# Services.init - загрузить шаблоны сервисов из файлов, создать соответствующие объекты

class Services
  @services = {}

  def Services.init
  	return @services if !@services.empty?
  	templates_dir = Tools.abs_path(Config["parser"]["templates_dir"])
  	Dir.entries(templates_dir).keep_if {|name| name =~ /.*\.yml/}.each do |filename|
      service_templates = YAML.load_file(templates_dir+'/'+filename)
      service_templates.each_value do |ar|
        ar.map! do |s|
          Regexp.new(s)
        end
      end
      filename =~ /(?<service_name>.*)\.yml/
      service_name = $~["service_name"]
      Printer::debug(msg:"Found new service: #{service_name}", who:"Preparations")
  	  @services[service_name] = Service.new(service_name, service_templates)
  	end
  end

  def Services.[](service_name)
  	return @services[service_name]
  end
end

Services.init
