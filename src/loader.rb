require_relative 'config'
require_relative 'tools'
require_relative '../services/service'
# require 'sinatra/reloader'

class LoglineStream

  DEFAULT_LOG_FOLDER = Tools.abs_path Config["parser"]["log_folder"]
  DEFAULT_SERVER = "undefined"
  SLASH = '/'
  # чтобы обязательно последним стоял слэш
  DEFAULT_LOG_FOLDER << SLASH unless DEFAULT_LOG_FOLDER[-1] == SLASH

  def self.from_directory(log_folder:DEFAULT_LOG_FOLDER, 
    n_lines_to_process:Float::INFINITY, n_lines_to_skip:0)
    # Printer::assert(expr:log_folder[-1] == SLASH, msg:"Последним не стоит слэш")
    # возвращается итератор по строкам логов
    Enumerator.new do |yielder|
      n_lines = 0
      # для каждого имени файла внутри директории с логами
      Dir.foreach(log_folder) do |server_name|
        # папка сервера это папка логов плюс имя сервера
        server_folder = log_folder+server_name
        # если это папка и не . или ..
        if File.directory?(server_folder) && server_name != '.' && server_name != '..'
          # для каждого имени файла внутри папки сервера
          Printer::debug(
            who:"Заходим в папку",
            msg:server_folder
          )
          Dir.foreach(server_folder) do |filename|
            # получаем полное имя файла
            full_path = server_folder+SLASH+filename
            # проверяем, что файл не является . или .. или директорией
            if File.file? full_path
              # открываем файл
              Printer::debug(
                who:"Открываем файл",
                msg:full_path
              )
              line_no = 1
              File.open(full_path, 'r') do |file|
                # каждую строку файла отдаем как результат
                file.each do |line|
                  if n_lines_to_skip > 0
                    n_lines_to_skip -= 1
                    next
                  end
                  Printer::debug(
                    who: full_path,
                    msg: line_no.to_s.red+"".white,
                    log_every_n: true,
                    line_no: line_no,
                    in_place: true
                  )
                  line_no += 1
                  yielder.yield(
                    logline:line,
                    filename:full_path,
                    server:server_name
                  )
                  n_lines += 1
                  if n_lines >= n_lines_to_process
                    raise StopIteration
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def self.open
    self.from_directory
  end

  def self.load_from_file(fn)
    # возвращается итератор по строкам логов
    Enumerator.new do |yielder|
      # открываем файл
      File.open(fn, 'r') do |file|
        # каждую строку файла отдаем как результат
        file.each do |line|
          yielder.yield(
            logline: line,
            filename: fn,
            server: DEFAULT_SERVER
          )
        end
      end
    end
  end
end

class ServiceLoader
  DEFAULT_DIR = Tools.abs_path Config["parser"]["templates_dir"]
  YML_EXT = '.yml'
  SLASH = '/'
  DEFAULT_TEMPLATES = nil

  @regex_count = 0

  def self.not_empty(*params)
    params.each do |param|
      Printer::assert(expr:!param.nil?, msg: "#{param} is nil")
      Printer::assert(expr:!param.empty?, msg: "#{param} is empty")
    end
  end

  def self.get_path(dir:,fn:,add_ext:)
    dir = dir[-1] == SLASH ? dir : dir+SLASH
    dir+fn+(add_ext ? YML_EXT : '')
  end

  def self.get_fn(service_group:)
    service_group+YML_EXT
  end

  def self.create(service_group:,service_regexp:, dir:DEFAULT_DIR,
    service_templates: DEFAULT_TEMPLATES)

    Printer::debug(
      who:"ServiceLoader.create(#{service_group},#{service_regexp},#{dir},#{service_templates})",
    )

    not_empty(service_group, service_regexp)
    fn = get_fn(service_group:service_group)
    Printer::assert(
      expr: !dir_list(dir:dir).include?(fn),
      who: dir,
      msg: "файл #{fn} уже существует"
    )
    # параметры не пустые и такой сервис еще не существует
    # новый объект типа Yaml::Store
    store = YAML::Store.new(get_path(dir:dir,fn:service_group,add_ext:true))
    # записываем информацию
    store.transaction do
      store['regex'] = service_regexp
      store['service'] = service_group
      store['templates'] = service_templates
    end
  end

  def self.update(service_group:,service_regexp:,
    new_service_group:, dir:DEFAULT_DIR)

    Printer::debug(
who:"ServiceLoader.update(#{service_group},#{service_regexp},#{new_service_group},#{dir})",
    )
    # если нет такого файла в директории
    fn = get_fn(service_group:service_group)
    Printer::assert(
      expr: dir_list(dir:dir).include?(fn),
      who: "ServiceLoader.update",
      msg: "нет такого файла в директории: #{fn}"
    )
    # загружаем содержимое
    content = get_file_content(dir:dir,fn:fn,add_ext:false)
    # меняем поля
    content['service'] = new_service_group
    content['regex'] = service_regexp
    # проверяем корректность
    check_service_descr(file_content:content)
    # удаляем файл
    File.delete(get_path(dir:dir,fn:fn,add_ext:false))
    # сохраняем файл
    create(
      service_group:new_service_group,
      service_regexp:service_regexp,
      dir:dir,
      service_templates:content['templates']
    )
  end

  def self.delete(service_group:,dir:DEFAULT_DIR)
    Printer::debug(
      who:"ServiceLoader.delete(#{service_group})",
    )
    fn = get_fn(service_group:service_group)
    # если в директории есть такой файл
    if dir_list(dir:dir).include?(fn)
      # удаляем его
      File.delete(get_path(dir:dir,fn:fn,add_ext:false))
    else
      Printer::note(
        who: "ServiceLoader.delete(#{service_group},#{dir})",
        msg: "файл #{fn} уже удален"
      )
    end
  end

  def self.add_template(service_group:,service_category:,regexp:, logline_type:,
    dir:DEFAULT_DIR)

    Printer::debug(
      who:"ServiceLoader.add_template(#{service_group},#{service_category},"+\
        +"#{regexp}, #{logline_type})",
    )
    # если сервис не существует
    Printer::assert(
      expr: service_exist?(service_group:service_group, dir:dir),
      who: "ServiceLoader.add_template",
      msg: "нет такого сервиса в директории: #{service_group}"
    )
    # если категория пустая
    Printer::assert(
      expr: service_category && !service_category.empty?,
      who: "ServiceLoader.add_template",
      msg: "категория отсутствует"
    )
    fn = get_fn(service_group:service_group)
    # загружаем содержимое
    content = get_file_content(dir:dir,fn:fn,add_ext:false)
    # если нет категорий
    if content['templates'].nil?
      content['templates'] = {}
    end
    # если типа не существует
    if content['templates'][logline_type].nil?
      content['templates'][logline_type] = {}
    end
    # если категории не существует
    if content['templates'][logline_type][service_category].nil?
      content['templates'][logline_type][service_category] = []
    end
    # if content['templates'][service_category].nil?
    #   content['templates'][service_category] = []
    # end
    # меняем поля
    content['templates'][logline_type][service_category] << regexp;
    # проверяем корректность
    check_service_descr(file_content:content)
    # удаляем файл
    File.delete(get_path(dir:dir,fn:fn,add_ext:false))
    # сохраняем файл
    create(
      service_group:content['service'],
      service_regexp:content['regex'],
      dir:dir,
      service_templates:content['templates']
    )
    # возвращаем шаблоны
    return content['templates']
  end

  def self.dir_list(dir:DEFAULT_DIR)
    # если директория не существует
    Printer::assert(
      expr: Dir.exists?(dir),
      who:'ServiceLoader.dir_list',
      msg: "Директория #{dir} не существует в #{Tools.homedir}"
    )
    Dir.entries(dir).keep_if {|entry| entry != '.' && entry != '..'}.sort
  end

  def self.service_exist?(service_group:, dir:DEFAULT_DIR)
    # если нет такого файла в директории
    fn = get_fn(service_group:service_group)
    dir_list(dir:dir).include?(fn)
  end

  def self.get_file_content(dir:DEFAULT_DIR, fn:, add_ext:false)

    # путь к файлу
    path = get_path(dir:dir,fn:fn,add_ext:add_ext)
    # path = dir+'/'+fn+(add_ext ? YML_EXT : '')
    YAML.load_file(path)
  end
  def self.check_service_descr(file_content:)
    # проверяем, что есть имя сервиса
    service_name = file_content['service']
    Printer::assert(
      expr:!service_name.nil? && !service_name.empty?,
      who:'ServiceLoader.check_service_descr',
      msg:'отсутствует поле service'
    )
    # проверяем, что есть регулярное выражение
    Printer::assert(
      expr:!file_content['regex'].nil?,
      who:'ServiceLoader.check_service_descr',
      msg:'отсутствует поле regex'
    )
    service_name_regex = Regexp.new(file_content['regex'])
    # проверяем, что есть шаблоны
    Printer::assert(
      expr:file_content.has_key?('templates'),
      who:'ServiceLoader.check_service_descr',
      msg:'отсутствует поле templates'
    )
    # проверяем каждое регулярное выражение в templates
    if file_content['templates']
      file_content['templates'].each_pair do |logline_type, categories|
        if categories
          categories.each_pair do |category, regexes|
            if regexes
              regexes.each do |regex|
                Printer::assert(
                  expr: regex && !regex.empty?,
                  who:"ServiceLoader.check_service_descr",
                  msg:"Регулярное выражение в категории #{category} пусто"
                )
                Regexp.new(regex)
              end
            else
              Printer::assert(
                expr:false,
                who:"ServiceLoader.check_service_descr",
                msg:"Категория #{category} пустая"
              )
            end
          end
        else
          Printer::assert(
            expr:false,
            who:"ServiceLoader.check_service_descr",
            msg:"Тип #{logline_type} пуст"
          )
        end
      end
      # file_content['templates'].each_pair do |category, regexes|
      #   Printer::assert(
      #     expr: regexes,
      #     msg:"Категория #{category} пустая"
      #   )
      #   regexes.each do |regex|
      #     Printer::assert(expr: regex && !regex.empty?, msg:"Regexp is empty")
      #     Regexp.new(regex)
      #   end
      # end
    end
  end
  def self.transform_templates(templates:)
    if templates
      service_templates = templates
      # создаем Regexp, вставляем категорию и тип во внутренний хэш
      ar = []
      service_templates.each_pair do |logline_type, categories|
        categories.each_pair do |category, regexes|
          regexes.each do |regex|
            @regex_count += 1
            ar << {
              regex: Regexp.new(regex),
              regex_id: @regex_count,
              regex_string: regex,
              type:category,
              logline_type:logline_type
            }
          end
        end
      end
      ar
      # вставляем описание шаблона внутрь описания регулярного выражения
      # service_templates.each_pair do |type, regexes|
      #   regexes.map! {|regex_hash| regex_hash.update(type:type)}
      # end
      # теперь каждое регулярное выражение сидит в своем хэше внутри массива
      # что-то вроде [
      #   {regex: /foobar/, regex_id: 12, type: 'Foobar String', regex_string: 'foobar'},
      #   {regex: /barfoo/, regex_id: 13, type: 'Barfoo String', regex_string: 'barfoo'}
      # ]
      # service_templates = service_templates.values.sum([])
      # service_templates
    else
      []
    end
  end
  def self.load_service(service_group:, add_ext:true)
    content = get_file_content(fn:service_group, add_ext:add_ext)
    check_service_descr(file_content:content)
    if add_ext
      # сравниваем без расширения
      Printer::assert(
        expr: content['service'] == service_group,
        who: "ServiceLoader.load_service",
        msg: "имя файла #{service_group} не совпадает с указанным в поле service"
      )
    else
      # сравниваем с расширением
      Printer::assert(
        expr: get_fn(service_group:content['service']) == service_group,
        who: "ServiceLoader.load_service",
        msg: "имя файла #{service_group} не совпадает с указанным в поле service"
      )
    end
    service_categories = []
    if content['templates']
      content['templates'].each do |logline_type, categories|
        service_categories << categories.keys
      end
    end
    service_categories.flatten!
    service_categories.sort!
    service_categories.uniq!
    if service_categories.include?('Ignore')
      service_categories.delete('Ignore')
    end
    service_categories.unshift('Ignore')
    Service.new(
      service_name: content['service'],
      service_regexp_string: content['regex'],
      service_categories: service_categories,
      service_templates: transform_templates(templates:content['templates']),
    )
  end
  def self.load_from_dir(dir:DEFAULT_DIR)
    # отображаем содержимое директории
    filenames = dir_list(dir:dir)
    # фильтруем по расширению
    filenames.keep_if do |fn|
      if fn.include?(YML_EXT)
        true
      else
        Printer::note(msg: "#{dir}: файл #{fn} лишний!")
        false
      end
    end
    if filenames.empty?
      Printer::note(msg:"В папке #{dir} нет шаблонов")
    end
    # загружаем сервисы
    services = []
    filenames.each do |fn|
      begin
        srv = load_service(service_group: fn, add_ext: false)
        services << srv
        Printer::debug(
          who:"ServiceLoader.load_from_dir",
          msg:"Найден сервис #{srv.service_name}"
        )
        if srv.service_templates.empty?
          Printer::note(
            who: 'ServiceLoader.load_from_dir',
            msg: "у сервиса #{srv.service_name} нет шаблонов"
          )
        end
      rescue StandardError => exc
        Printer::error(
          who:"ServiceLoader.load_from_dir",
          msg:"Не удалось загрузить шаблоны #{fn}",
          params: {
            msg:exc.inspect
          }
        )
      end
    end
    services
  end
end
