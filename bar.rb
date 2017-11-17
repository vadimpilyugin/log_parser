require 'sinatra'
require 'sinatra/reloader'
require_relative 'src/tools'
load 'src/printer.rb'
require 'json'
load 'src/loader.rb'
load 'services/service.rb'

Printer::note(msg:'Reloaded')

get '/' do
  s=''
  ServiceLoader.dir_list.each do |srv|
    Printer::debug(msg:srv)
    s = s + srv.to_s + "\n"
  end
  fn = '05efi.yml'
  begin
    content = ServiceLoader.get_file_content(fn:fn)
    ServiceLoader.check_service_descr(file_content:content).to_json
    ServiceLoader.transform_templates(templates:content['templates']).to_json
    ServiceLoader.dir_list.to_json
    ServiceLoader.load_from_dir.map{|srv| srv.service_name}.to_json
    ServiceLoader.load_service(service_group:fn,add_ext:false).inspect

  rescue StandardError => exc

    Printer::error(
      who:"Services.load_from_dir",
      msg:"Не удалось загрузить шаблоны #{fn}",
      params: {
        msg:exc.inspect
      }
    )

    exc.inspect
  end
end

begin
  Services.init
rescue Error::AssertError => exc
  'foo'
end


get '/foo' do
  content_type :json
  begin
    templates = Services.add_template(
      service_group: params['service_group'],
      service_category: params['service_category'],
      regexp: params['regexp']
    )
    {
      ok:true,
      data:templates
    }.to_json
  rescue StandardError => exc
    # произошла ошибка
    resp = {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }.to_json
    Printer::error(who: '/foo')
    resp
  end
end

# params[service_group]
# params[service_regexp]
post '/create/service' do
  content_type :json
  begin
    srv = Services.create(
      service_group:params["service_group"],
      service_regexp:params["service_regexp"]
    )
    {
      ok:true,
      data:srv.inspect
    }.to_json
  rescue StandardError => exc
    # произошла ошибка
    {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }.to_json
  end
end

# params[service_group]
# params[service_regexp]
post '/update/service' do
  content_type :json
  begin
    srv = Services.update(
      service_group:params["service_group"],
      service_regexp:params["service_regexp"]
    )
    {
      ok:true,
      data:srv.inspect
    }.to_json
  rescue StandardError => exc
    # произошла ошибка
    {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }.to_json
  end
end

# params[service_group]
post '/remove/service' do
  content_type :json
  begin
    srv = Services.delete(
      service_group:params["service_group"]
    )
    {
      ok:true,
      data:srv.inspect
    }.to_json
  rescue StandardError => exc
    # произошла ошибка
    {
      ok:false,
      what:exc.message,
      descr:exc.inspect
    }.to_json

  end
end
