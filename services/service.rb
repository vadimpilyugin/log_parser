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
  	return self.parse!(logline)["uid"] != nil
  end

  # @param [String] logline строка
  # @return [Hash] хэш, содержащий три поля: data, type и uid
  # Если шаблон не найден, то все три поля равны nil
  # Если шаблон найден, то поля будут содержать соответственно:
  # {
  #   data => хэш с ключами равными именам полей и значениями равными, собственно, значениям полей
  #   type => строка-описание, которая находится рядом с шаблоном в конфиге
  #   uid => целое число > 0, уникальный номер шаблона
  # }
  
  def parse!(logline)
  	data = nil
    descr = nil
    uid = nil
    @service_templates.each do |key,value|
      break if data != nil
      value.each do |regex|
        if logline =~ regex
          descr = key
          data = $~.to_h
          uid = regex.hash.abs
          break
        end
      end
    end
    return {"data" => data, "type" => descr, "uid" => uid}
  end
end

# Services.[] - Получить доступ к сервису по имени. Если такого сервиса нет, вернется nil
# Если есть, то вернется instance класса Service, представляющий нужный сервис.
# Services.load - загрузить шаблоны сервисов из файлов, создать соответствующие объекты

class Services
  @services = {}

  def Services.load
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
      Printer::debug(msg:"Loaded #{service_name} templates", who:"Services.load")
  	  @services.update(service_name => Service.new(service_name, service_templates))
  	end
  end

  def Services.[](service_name)
  	return @services[service_name]
  end
end

Services.load
