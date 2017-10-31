require_relative '../src/tools'
require_relative '../src/config'
require_relative '../src/stats'

require 'yaml/store'

class Service

  attr_reader :service_templates, :service_name

  def initialize(service_templates:, service_name:)
    @service_name = service_name
  	@service_templates = service_templates
  end

  def check(logline)
  	return !self.parse(logline).nil?
  end

  # @param [String] logline строка
  # @return [Hash] хэш, содержащий поля linedata, type и regex_id
  # Если шаблон не найден, то вернется nil
  # Если шаблон найден, то поля будут содержать соответственно:
  # {
  #   linedata => MatchData от строки
  #   type => строка-описание, которая находится рядом с шаблоном в конфиге
  #   regex_id => целое число > 0, уникальный номер шаблона
  # }

  def parse(logline)
  	i = @service_templates.index {|regex_hash| logline =~ regex_hash[:regex]}
    if i.nil?
      nil
    else
      regex_hash = @service_templates[i]
      {
        linedata: $~.named_captures,
        regex_id: regex_hash[:regex_id],
        type: regex_hash[:type],
        regex: regex_hash[:regex]
      }
    end
  end

  def check_field_names
    dictionary = [
      "username",
      "user_ip",
      "motion",
      "motion_type",
      "motion_mask",
      "ip",
      "user_port",
      "user",
      "mac_addr",
      "service",
      "action",
      "ip_addr",
      "dhcp_method",
      "path",
      "by_username",
      "method",
      "sessid",
      "upsname",
      "updaname",
      "by_user",
      "servicename",
    ]
    @service_templates.each do |regex_hash|
      regex_hash[:regex].names.each do |field_name|
        DidYouMean::SpellChecker.new(dictionary: ['foo','bar']).correct('bazinga')
      end
    end
  end
end

# Services.[] - Получить доступ к сервису по имени. Если такого сервиса нет, вернется nil
# Если есть, то вернется instance класса Service, представляющий нужный сервис.
# Services.init - загрузить шаблоны сервисов из файлов, создать соответствующие объекты

class Services
  DEFAULT_DIR = Tools.abs_path Config["parser"]["templates_dir"]
  YML_EXT = '.yml'

  @services = {}
  @total_regexes = 0
  # @name_cache = {}
  def Services.load_from_dir
    return @services if !@services.empty?
    @service_names = {}
    templates_dir = DEFAULT_DIR
    Dir.entries(templates_dir).keep_if {|name| name =~ /.*#{YML_EXT}/}.each do |fn|
      Printer::debug(
        msg:"Found new service file: #{fn}",
        who:"Services.load_from_dir"
      )
      service_name = ""
      begin
        # загружаем из YAML-файла все описания шаблонов для данного сервиса
        service_templates_with_regex = YAML.load_file(templates_dir+'/'+fn)
        # проверяем, что есть имя сервиса
        service_name = service_templates_with_regex['service']
        Printer::assert(
          expr:!service_name.nil? && !service_name.empty?,
          who:fn,
          msg:'не хватает имени сервиса!'
        )
        # проверяем, что есть регулярное выражение
        Printer::assert(
          expr:!service_templates_with_regex['regex'].nil?,
          who:fn,
          msg:'не хватает регулярного выражения!'
        )
        service_name_regex = Regexp.new(service_templates_with_regex['regex'])
        # проверяем, что есть шаблоны
        Printer::assert(
          expr:!service_templates_with_regex['templates'].nil?,
          who:fn,
          msg:'не хватает шаблонов!'
        )
        service_templates = service_templates_with_regex['templates']
        # для каждого массива строк-шаблонов
        service_templates.each_value do |reg_strings|
          # создаем новый Regexp и определяем его id
          reg_strings.map! do |reg_s|
            @total_regexes += 1
            {:regex => Regexp.new(reg_s), :regex_id => @total_regexes}
          end
        end
        # вставляем описание шаблона внутрь описания регулярного выражения
        service_templates.each_pair do |type, regexes|
          regexes.map! {|regex_hash| regex_hash.update(type:type)}
        end
        # теперь каждое регулярное выражение сидит в своем хэше внутри массива
        # что-то вроде [
        #   {regex: /foobar/, regex_id: 12, type: 'string is foobar'},
        #   {regex: /barfoo/, regex_id: 13, type: 'string like barfoo'}
        # ]
        service_templates = service_templates.values.sum([])
      rescue StandardError => exc
        Printer::error who:"Services.load_from_dir", msg:exc.inspect
        Printer::error who:"Services.load_from_dir", msg:"Не удалось загрузить шаблоны #{fn}"
        service_templates = []
      end
      @services[service_name_regex] = Service.new(
        service_templates:service_templates,
        service_name:service_name
      )
      if @service_names.has_key?(service_name)
        # Возможно, ошибка, повторяющийся сервис
        Printer::note(
          who:fn,
          msg:"сервис #{service_name.inspect} уже был в #{@service_names[service_name]}"
        )
      else
        @service_names[service_name] = fn
      end
    end
  end

  def Services.[](service_name)
    # ищем среди всех сервисов по регулярным выражениям
    ind = @services.keys.index{|rgx| service_name =~ rgx}
    # если такого сервиса нет
    if ind.nil?
      nil
    else
      # сервис есть
      @services[@services.keys[ind]]
    end
  end

  def Services.all
    @services.each_value
  end

  def Services.load_service(service_name:)
    # если еще не загружен
    if Services[service_name].nil?
      begin
        # загружаем из YAML-файла все описания шаблонов для данного сервиса
        service_templates_with_regex = YAML.load_file(DEFAULT_DIR+'/'+service_name+YML_EXT)
        # проверяем, что есть имя сервиса
        service_name = service_templates_with_regex['service']
        Printer::assert(
          expr:!service_name.nil? && !service_name.empty?,
          who:fn,
          msg:'не хватает имени сервиса!'
        )
        # проверяем, что есть регулярное выражение
        Printer::assert(
          expr:!service_templates_with_regex['regex'].nil?,
          who:fn,
          msg:'не хватает регулярного выражения!'
        )
        service_name_regex = Regexp.new(service_templates_with_regex['regex'])
        # проверяем, что есть шаблоны
        Printer::assert(
          expr:!service_templates_with_regex['templates'].nil?,
          who:fn,
          msg:'не хватает шаблонов!'
        )
        service_templates = service_templates_with_regex['templates']
        # для каждого массива строк-шаблонов
        service_templates.each_value do |reg_strings|
          # создаем новый Regexp и определяем его id
          reg_strings.map! do |reg_s|
            @total_regexes += 1
            {:regex => Regexp.new(reg_s), :regex_id => @total_regexes}
          end
        end
        # вставляем описание шаблона внутрь описания регулярного выражения
        service_templates.each_pair do |type, regexes|
          regexes.map! {|regex_hash| regex_hash.update(type:type)}
        end
        # теперь каждое регулярное выражение сидит в своем хэше внутри массива
        # что-то вроде [
        #   {regex: /foobar/, regex_id: 12, type: 'string is foobar'},
        #   {regex: /barfoo/, regex_id: 13, type: 'string like barfoo'}
        # ]
        service_templates = service_templates.values.sum([])
      rescue StandardError => exc

      end
    end
  end

  def Services.create_service(service_name:)
    # новый объект типа Yaml::Store
    store = YAML::Store.new DEFAULT_DIR+'/'+service_name+YML_EXT
    # записываем информацию
    store.transaction do
      store['regex'] = service_name
      store['service'] = service_name
      store['templates'] = ""
    end
    # загружаем информацию о сервисе
    load_service(service_name:service_name)
  end
end

# class CheckSpelling
#   def self.count_fields
#     # заводим новый счетчик
#     counter = Stats::HashCounter.new("","")
#     # для каждого сервиса в каждом его шаблоне находим именованные поля и увеличиваем счетчик
#     Service.all.each do |srv|
#       srv.service_templates.each {|regex_hash| regex_hash[:regex].names.each {|name| counter.increment name}}
#     end
#     # возвращаем имена полей и сколько раз они нам встретились
#     counter.value
#   end

#   def self.top_popular
#     count_fields
#   end

Services.load_from_dir
