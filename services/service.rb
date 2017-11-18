require_relative '../src/tools'
require_relative '../src/config'
require_relative '../src/loader'

class Service

  attr_reader :service_templates, :service_name, :service_regexp_string
  attr_reader :service_categories

  alias_method :categories, :service_categories

  def initialize(service_templates:, service_name:,
    service_categories:, service_regexp_string:)
    @service_name = service_name
  	@service_templates = service_templates
    @service_categories = service_categories
    @service_regexp_string = service_regexp_string
    @service_regexp = Regexp.new(service_regexp_string)
  end

  def check(logline)
  	return !self.parse(logline).nil?
  end

  def belongs?(service_name)
    service_name =~ @service_regexp
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
        regex: regex_hash[:regex],
        logline_type: regex_hash[:logline_type]
      }
    end
  end
end

require 'deepsort'

class Services

  def self.init
    @service_groups.clear if @service_groups
    @service_groups = {}
    # список сервисов пустой
    Printer::assert(
      expr:@service_groups.empty?,
      who: "Services.init",
      msg: "список @service_groups непустой!"
    )
    ServiceLoader.load_from_dir.each do |srv|
      add_service(srv:srv)
    end
    sort
    # список сервисов непустой
    Printer::note(
      who: "Services.init",
      msg: "список @service_groups пустой!"
    ) if @service_groups.empty?
  end

  def self.add_service(srv:)
    key = srv.service_name
    Printer::assert(
      expr: !@service_groups.has_key?(key),
      who: "Services.add_service",
      msg: "сервис уже существует: #{srv.inspect}"
    )
    @service_groups[key] = srv
  end

  def self.load_and_add(service_group:)
    # загружаем сервис
    srv = ServiceLoader.load_service(service_group:service_group)
    # добавляем в хэш
    add_service(srv:srv)
    # сортируем
    sort
    return srv
  end

  def self.sort
    # список сервисов непустой
    Printer::note(
      who: "Services.sort",
      msg: "список @service_groups пустой!"
    ) if @service_groups.empty?
    # сортируем по имени группы
    @service_groups.deep_sort_by {|o| o[0]}
  end

  def self.[](service)
    # список сервисов непустой
    Printer::note(
      who: "Services.[]",
      msg: "список @service_groups пустой!"
    ) if @service_groups.empty?
    # ищем среди всех сервисов по регулярным выражениям
    @service_groups.values.find {|srv| srv.belongs?(service)}
  end

  def self.by_group(service_group:)
    # список сервисов непустой
    Printer::note(
      who: "Services.by_group",
      msg: "список @service_groups пустой!"
    ) if @service_groups.empty?
    # ищем среди всех сервисов по идентификатору группы
    @service_groups[service_group]
  end

  def self.all
    @service_groups.values.each
  end

  def self.create(service_group:,service_regexp:)
    Printer::debug(who:"Services.create(#{service_group},#{service_regexp})")
    Printer::assert(
      expr: !@service_groups.has_key?(service_group),
      who: "Services.create",
      msg: "такой сервис уже существует"
    )
    # создаем файл в директории
    ServiceLoader.create(
      service_group:service_group,
      service_regexp:service_regexp
    )
    load_and_add(service_group:service_group)
  end

  def self.update(service_group:,service_regexp:,new_service_group:)
    Printer::debug(who:"Services.update(#{service_group},#{service_regexp})")
    # проверим, что сервис уже существует
    Printer::assert(
      expr: !@service_groups[service_group].nil?,
      who: "Services.update",
      msg: "сервис не найден"
    )
    # сервис существует
    # обновляем файл
    ServiceLoader.update(
      service_group:service_group,
      service_regexp:service_regexp,
      new_service_group:new_service_group
    )
    @service_groups.delete(service_group)
    # загружаем заново
    load_and_add(service_group:new_service_group)
  end

  def self.delete(service_group:)
    Printer::debug(who:"Services.delete(#{service_group})")
    # проверим, что сервис уже существует
    Printer::assert(
      expr: !@service_groups[service_group].nil?,
      who: "Services.delete(#{service_group})",
      msg: "сервис не найден"
    )
    # сервис существует, удаляем его
    srv = @service_groups.delete(service_group)
    # удаляем файл
    ServiceLoader.delete(service_group:service_group)
    srv
  end

  def self.add_template(service_group:,service_category:,regexp:,logline_type:)

    Printer::debug(who:"Services.add_template(#{service_group},#{service_category},#{regexp})")
    # список сервисов непустой
    Printer::assert(
      expr:!@service_groups.empty?,
      who: "Services.add_template",
      msg: "список @service_groups пустой!"
    )
    # проверим, что сервис уже существует
    Printer::assert(
      expr: !@service_groups[service_group].nil?,
      who: "Services.add_template",
      msg: "сервис #{service_group} не найден"
    )
    # проверяем, что logline_type в нужных пределах
    Printer::assert(
      expr: ['Debug','Info','Warning','Error'].include?(logline_type),
      who: "Services.add_template",
      msg: "logline_type == #{logline_type} не в нужных пределах"
    )
    # обновляем файл
    templates = ServiceLoader.add_template(
      service_group: service_group,
      service_category: service_category,
      regexp: regexp,
      logline_type: logline_type
    )
    # сервис существует
    @service_groups.delete(service_group)
    # загружаем заново
    load_and_add(service_group:service_group)
    return templates
  end
end
