require_relative 'views'
require 'sinatra'
require 'sinatra/reloader'
load 'src/api.rb'
load 'services/service.rb'

module ApiHelpers
  def params_assert(*keys)
    keys.each do |key|
      if params[key].nil? || params[key].empty?
        Printer::error(
          msg: "значение параметра #{key} не указано"
        )
        return false
      end
    end
  end
end


configure do
  helpers View
  helpers ApiHelpers
  set :bind, "0.0.0.0"
  set :port, 4567
  set :public_folder, 'public'
end

get '*' do
  Printer::debug who:request.env["REQUEST_PATH"], params:params.to_h
  pass
end
post '*' do
  Printer::debug who:request.env["REQUEST_PATH"], params:params.to_h
  pass
end

get '/' do
  redirect '/servers'
end

# params[server] - опционально
get '/servers' do
  # params_assert("server")
  # get_servers(**params)
  get_servers(server:params["server"])
end

# params[regexp]
# params[type]
get '/services' do
  content_type :json
  # opts = {}
  # opts = Hash[params.map{|(k,v)| [k.to_sym,v]}] if params
  # get_services(**opts).to_json
  get_services(
    regexp: params["regexp"],
    type: params["type"]
  ).to_json
end

# params[regexp]
# params[type]
get '/services/no_template_found' do
  content_type :json
  # opts = {}
  # opts = Hash[params.map{|(k,v)| [k.to_sym,v]}] if params
  # get_services(**opts).to_json
  get_services(
    type: "no_template_found"
  ).to_json
end

# params[type]
get '/services/all_service_groups' do
  content_type :json
  # opts = {}
  # opts = Hash[params.map{|(k,v)| [k.to_sym,v]}] if params
  # get_services(**opts).to_json
  get_services(
    type: params["type"]
  ).to_json
end

# params[service]
get '/service/categories' do
  content_type :json
  # opts = {}
  # opts = Hash[params.map{|(k,v)| [k.to_sym,v]}] if params
  # get_service_categories(**opts).to_json
  get_service_categories(
    service_group: params["service_group"]
  ).to_json
end


# params[service_group]
# params[regexp] - опциональный
get '/loglines/no_template_found' do
  content_type :json
  # opts = {}
  # opts = Hash[params.map{|(k,v)| [k.to_sym,v]}] if params
  # get_loglines_no_template_found(**opts).to_json
  get_loglines_no_template_found(
    regexp: params["regexp"],
    service_group: params["service_group"]
  ).to_json
end

# params[string]
get '/string/escape' do
  content_type :json
  # opts = {}
  # opts = Hash[params.map{|(k,v)| [k.to_sym,v]}] if params
  # get_string_escape(**opts).to_json
  get_string_escape(
    string: params["string"]
  ).to_json
end

# params[service_group]
# params[service_regexp]
post '/add/service' do
  content_type :json
  begin
    srv = Services.create(
      service_group:params["service_group"],
      service_regexp:params["service_regexp"]
    )
    regexp = Regexp.new params["service_regexp"]
    # сначала удалим из неизвестных сервисов
    ar = []
    Statistics[$stats['UNKNOWN_SERVICES']].distrib\
      .delete_if do |service, lines|
        if service =~ regexp
          lines.add(ar)
          true
        else
          false
        end
      end
    # распарсим заново строки, относящиеся к этой группе сервисов
    pls = Parser.new.parsed_logline_stream(ar.each)
    # теперь добавим в число ненайденных шаблонов
    Statistics.process(table:pls,stats_no:[$stats['TEMPLATE_NOT_FOUND']])

    # обновляем статистику
    # Statistics[$stats['UNKNOWN_SERVICES']].clear
    # Statistics[$stats['NO_TEMPLATE_FOUND']].clear
    # Statistics[$stats['TEMPLATE_NOT_FOUND']].clear
    # process_stats(stats_no:[
      # $stats['UNKNOWN_SERVICES'],
      # $stats['NO_TEMPLATE_FOUND'],
      # $stats['TEMPLATE_NOT_FOUND']
    # ]
    # )
    {
      ok:true,
      data:"Новый сервис добавлен: #{srv.service_name}"
    }.to_json

  rescue StandardError => exc
    # произошла ошибка
    resp = {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }
    Printer::error(who: '/add/service', params:resp)
    resp.to_json
  end
end


# params[service_group]
# params[new_service_group]
# params[service_regexp]
post '/update/service' do
  content_type :json
  begin
    service_group = params["service_group"]
    srv = Services.update(
      service_group:service_group,
      new_service_group:params["new_service_group"],
      service_regexp:params["service_regexp"]
    )
    regexp = Regexp.new params["service_regexp"]
    # сначала удалим из неизвестных сервисов
    ar = []
    Statistics[$stats['UNKNOWN_SERVICES']].distrib\
      .delete_if do |service, lines|
        if service =~ regexp
          lines.add(ar)
          true
        else
          false
        end
      end
    # распарсим заново строки, относящиеся к этой группе сервисов
    pls = Parser.new.parsed_logline_stream(ar.each)
    # теперь добавим в число ненайденных шаблонов
    Statistics.process(table:pls,stats_no:[$stats['TEMPLATE_NOT_FOUND']])
    # обновляем статистику
    # Statistics[$stats['UNKNOWN_SERVICES']].clear
    # Statistics[$stats['NO_TEMPLATE_FOUND']].clear
    # Statistics[$stats['TEMPLATE_NOT_FOUND']].clear
    # process_stats(stats_no:[
      # $stats['UNKNOWN_SERVICES'],
      # $stats['NO_TEMPLATE_FOUND'],
      # $stats['TEMPLATE_NOT_FOUND']
    # ]
    # )
    {
      ok:true,
      data: "Обновили сервис: #{service_group} ~~> #{srv.service_name}"
    }.to_json
  rescue StandardError => exc
    # произошла ошибка
    resp = {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }
    Printer::error(who: '/update/service', params:resp)
    resp.to_json
  end
end

# params[service_group]
post '/remove/service' do
  content_type :json
  begin
    srv = Services.delete(
      service_group:params["service_group"]
    )
    # обновляем статистику
    # Statistics[$stats['UNKNOWN_SERVICES']].clear
    # Statistics[$stats['NO_TEMPLATE_FOUND']].clear
    # Statistics[$stats['TEMPLATE_NOT_FOUND']].clear
    # process_stats(stats_no:[
      # $stats['UNKNOWN_SERVICES'],
      # $stats['NO_TEMPLATE_FOUND'],
      # $stats['TEMPLATE_NOT_FOUND']
    # ]
    # )
    {
      ok:true,
      data:srv.inspect
    }.to_json
  rescue StandardError => exc
    # произошла ошибка
    resp = {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }
    Printer::error(who: '/remove/service', params:resp)
    resp.to_json
  end
end

post '/add/template' do
  content_type :json
  service_group = params['service_group']
  service_category = params['service_category']
  begin
    templates = Services.add_template(
      service_group: service_group,
      service_category: service_category,
      regexp: params['regexp']
    )
    # массив с подошедшими строками
    ar = []
    # регулярное выражение
    regexp = Regexp.new(params['regexp'])
    # вырезаем строки из числа ошибочных
    Statistics[$stats['TEMPLATE_NOT_FOUND']].distrib[service_group]\
      .delete_if do |msg, lines|
        if msg =~ regexp
          lines.add(ar)
          true
        else
          false
        end
      end
    pls = Parser.new.parsed_logline_stream(ar.each)
    # NORMAL_STATS - статистики из конфига
    # TODO: пока не могу, так как они финализированы
    # Statistics.process(table:pls, stats_no: $stats['NORMAL_STATS'])
    {
      ok:true,
      data:"#{service_group}: шаблон добавлен в категорию #{service_category}"
    }.to_json
  rescue StandardError => exc
    # произошла ошибка
    resp = {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }.to_json
    Printer::error(who: '/add/template', msg: exc.message)
    resp
  end
end
