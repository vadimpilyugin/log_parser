require_relative 'printer'
require_relative 'views'
require_relative 'parser'

def get_loglines_no_template_found(service_group:, regexp:'.*')
  max_lines = 30
  # статистика распределения строк по сервисам
  lines = Statistics[$stats['TEMPLATE_NOT_FOUND']]
  # lines = Statistics[$stats['NO_TEMPLATE_FOUND']]
  # отсеиваем все, которые не принадлежат данному сервису
  lines = lines.distrib[service_group].keys.clone
  Printer::assert(expr:lines, msg:"Не нашлось строк с сервисом #{service_group}")
  lines.delete(:total)
  lines.delete(:distinct)
  # lines = lines.distrib[service_group]
  # если не нашлось
  # if lines.nil?
  #   return {
  #     "ok" => false,
  #     "descr" => "Не нашлось строк с сервисом #{service_group}",
  #     "what" => "no_lines"
  #   }
  # else
    # какие-то строки есть
    begin
      # создаем регулярное выражение
      regexp = Regexp.new(regexp)
      # сюда будем записывать подошедшие строки
      recognized_lines = []
      # для каждой строки
      lines.each do |msg|
        # Printer::note(
        #   msg: "Отсутствует поле :msg",
        #   params: line_hash
        # ) unless line_hash.has_key?(:msg)
        # если строка подходит под регулярное выражение
        if msg =~ regexp
          hsh = {}
          # добавляем именованные группы
          hsh[:linedata] = $~.named_captures unless $~.named_captures.empty?
          # добавляем саму строку
          hsh[:msg] = msg
          # записываем в ответ эту строку
          recognized_lines << hsh
        end
      end
      # если строк слишком много
      if recognized_lines.size > max_lines
        Printer::note(
          msg: "Строк слишком много (#{recognized_lines.size}), возвращаем #{max_lines}"
        )
        # возвращаем только первые max_lines
        recognized_lines = recognized_lines.first(max_lines)
      end
      # возвращаем отсеянные строки
      return {
        "ok" => true,
        "data" => recognized_lines,
      }
    rescue StandardError => exc
      return {
        "ok" => false,
        "what" => "bad_regex",
        "descr" => exc.message
      }
    end
  # end
end

# Возвращает список сервисов заданного типа
def get_services(regexp:'.*', type:, group: '')
  begin
    regexp = Regexp.new(regexp)
  rescue StandardError => exc
    # произошла ошибка создания регулярного выражения
    return {
      "ok" => false,
      "what" => "bad_regex",
      "descr" => exc.message
    }
  end
  service_list = []
  case type
  when 'no_template_found'
    service_list = Statistics[$stats['TEMPLATE_NOT_FOUND']].list
  when 'discovered_services'
    service_list = Statistics[$stats['DISCOVERED_SERVICES']].list
  when 'unknown_services'
    # перегонять при посте нового сервиса
    service_list = Statistics[$stats['UNKNOWN_SERVICES']].list
  when 'all_service_groups'
    # берем все сервисы, из них вытаскиваем имя группы и regex
    service_list = Services.all.map do |srv|
      {
        service_group: srv.service_name,
        regexp: srv.service_regexp_string
      }
    end
    # сортируем по имени сервиса
    service_list.sort! {|a,b| a[:service_group] <=> b[:service_group]}
    return {
      ok:true,
      data:service_list
    }
  else
    # если такой категории нет
    return {
      "ok" => false,
      "what" => "bad_type",
      "descr" => "такого типа сервисов нет: <#{type}>"
    }
  end
  # возвращаем отсеянные сервисы
  return {
    "ok" => true,
    "data" => service_list.select {|s| s =~ regexp}
  }
end


# params[string]
# возвращает отэскейпенную строку
# get '/string/escape' do
def get_string_escape(string:)
  # возвращаем отэскейпенную строку
  return {
    "ok" => true,
    "data" => Regexp.escape(string).gsub("\\ "," ")
  }
end


# params[service]
# возвращает список категорий из шаблона сервиса
# get '/service/categories' do
def get_service_categories(service_group:)
  Printer::debug(who:"API::get_service_categories service_group:#{service_group.inspect}")
  # находим сервис по категории
  srv = Services.by_group(service_group:service_group)
  # если сервис не найден
  if srv.nil?
    return {
      "ok" => false,
      "what" => "bad_service",
      "descr" => "сервис #{service_group.inspect} не найден среди описанных"
    }
  end
  # сервис найден
  # возвращаем список категорий
  return {
    "ok" => true,
    "data" => srv.categories
  }
end


# params[service]
# params[category]
# post '/service/categories/new' do
def post_service_categories_new(service:,category:)
  # находим сервис по имени
  service = Services[service]
  # если сервис не найден
  if service.nil?
    return {
      "ok" => false,
      "what" => "bad_service",
      "descr" => "указанный сервис не найден среди описанных"
    }
  end
  # сервис найден
  # добавляем в него новую категорию
  if service.new_category(category:category)
    return {
      "ok" => true
    }
  else
    return {
      "ok" => false,
      "what" => "category_add_fail",
      "descr" => "failed to create category"
    }
  end
end

def post_add_service(service_group:, service_regexp:)
  # если сервис отсутствует или пустой
  if service_group.nil? || service_group.empty?
    return {
      ok:false,
      what:'empty_service',
      descr:'Отсутствует название группы'
    }
  end
  # сервис не пустой
  # если регулярное выражение пустое или отсутствует
  if service_regexp.nil? ||service_regexp.empty?
    return {
      ok:false,
      what:'empty_regexp',
      descr:'Регулярное выражение отсутствует либо пустое'
    }
  end
  # регулярное выражение не пустое
  # пытаемся создать регулярное выражение
  begin
    Regexp.new(service_regexp)
  rescue StandardError => exc
    return {
      ok:false,
      what:'wrong_regexp',
      descr:exc.message
    }
  end
  # успешно создано
  msg = ''
  # ищем сервис по имени группы
  srv = Services.by_group(service_group)
  # если такой сервис уже существует
  if srv
    # если регулярное выражение изменилось
    if srv.service_regexp_string != service_regexp
      # обновляем его
      Services.update(
        service_regexp:service_regexp
      )
      msg = "changed regexp for #{service_group} to #{service_regexp}"
    else
      Printer::note(msg:"Обновление сервиса #{service_group} на тот же regexp")
      msg = "regexp is the same: nothing was changed"
    end
  else
    # сервис не существует
    # создаем его
    Services.create(
      service_group: service_group,
      service_regexp: service_regexp
    )
    msg = "created service #{service_group} with regexp #{service_regexp}"
  end
  # возвращаем успех
  return {
    ok:true,
    data: msg
  }
end


def get_servers(server:nil)
  # если зашли на главную страницу
  if server.nil?
    @counters = $stats['NORMAL_STATS'].map{|stat_id| Statistics[stat_id]}.keep_if do |st|
      st.conditions.server.nil? && st.class == Counter
    end
    @dist_arr = $stats['NORMAL_STATS'].map{|stat_id| Statistics[stat_id]}.keep_if do |st|
      st.conditions.server.nil? && st.class == Distribution
    end
    server_list = Statistics[$stats['SERVER_LIST']].list
    @pagination = View.pagination(
      server_list:server_list,
      active:0
    )
    @template_not_found = Statistics[$stats['TEMPLATE_NOT_FOUND']]
    @unknown_services = Statistics[$stats['UNKNOWN_SERVICES']]
    # @wrong_format_lines = Statistics[$stats['WRONG_FORMAT_LINES']]
    slim :main
  else
    # зашли на какой-то отдельный сервер
    # @counters = Statistics.all.keep_if do |st|
    #   st.conditions.server == server && st.class == Counter
    # end
    # @dist_arr = Statistics.all.keep_if do |st|
    #   st.conditions.server == server && st.class == Distribution
    # end
    # @pagination = View.pagination(
    #   server_list:server_list,
    #   active:server_list[1..-1].index{|serv| serv == server}+1,
    # )
    # slim :main
  end
end
