require_relative "aggregator"
require_relative "config"
require "yaml/store"
require 'yaml'
require "slim"

module Reporter

class Statistics
  def self.create(service, hsh)
    type = hsh.to_a[0][0]
    case type
      when "Counter" then Counter.new service, hsh
      when "Distribution" then Distribution.new service, hsh
      when "Flag" then Flag.new service, hsh
      else raise "Неопределенный тип статистики в #{hsh}"
    end
  end
end

class Reporter
  def initialize
    Chdir.chdir
    Config.new
    Aggregator::Aggregator.new
    folder = Config["reporter"]["config_folder"]
    raise "Report directory does not exist: #{folder}" if Dir.entries(folder).empty?
    raise "No templates found at report dir: #{folder}" if Dir.entries(folder).size == 2
    @report_struct = {}
    Dir.entries(folder).each do |service|    # загружаем шаблоны построения отчета
      next if service == "." || service == ".."
      service_template = YAML.load_file "#{folder}/#{service}"
      printf "#{service}\n#{service_template.to_yaml}\n"
      service_template.each do |elem|
        printf "#{elem}\n#{elem.class}\n"
        printf "#{elem.to_a[0][0]} - #{elem.to_a[0][0].class}\n"
      end
      service_template.map! { |hsh| Statistics.create service, hsh }
      @report_struct[service] = service_template
    end
    @filename = Config["reporter"]["report_file"]
  end
public
  def report()
    Dir.mkdir("report", 0777) unless Dir.exists? "report"
    f = File.open(@filename, File::CREAT|File::TRUNC|File::RDWR, 0644)
    @log_file = Config["parser"]["log_file"]
    # f = File.open("src/views/report.slim", File::CREAT|File::TRUNC|File::RDWR, 0644)
    f << "<!DOCTYPE html>\n"
    f << "<html>\n"
    f << "<head><title>Report</title></head>\n"
    f << "<body>\n"
    f << "<h3>Report on #{Config["parser"]["log_file"]}</h3>\n"
    f << "<br>"
    @report_struct.each_pair do |service, template|
      f << "<p>=================#{service.upcase}=================</p>\n"
      template.each do |stat|
        f << stat.to_html << "\n"
      end
      f << "<p>=================#{service.upcase} END=================</p>\n"
      f << "<br>"
    end
    f << "</body></html>"
    f.close
  end
end

class Counter
  def initialize(service, params)
    printf "#{params} - Params\n"
  	@descr = params["Counter"]		# Описание, которое в первой строке
  	# Счетчик имеет следующие параметры:
  	# Поле - подсчитывает уникальные значения данного поля. Например, уникальные IP адреса
  	@field = params["field"]
  	raise "Service is not a string! #{service}" if service.class != String
  	@value = Aggregator::Aggregator.reset.select(metas: {:service => service}).aggregate_by_keys(nil, [@field]).size
  end
public
  def to_html()
    s = ""
    s << "<p>#{@descr}: <a href=localhost:4567/>#{@value}</a></p>"
  end
end

class Distribution
  def initialize(service, params)
  	@descr = params["Distribution"]		# Описание, которое в первой строке
  	# Распределение имеет следующие параметры:
  	# Поля - показывает их взаимное распределение. Например, какие IP по каким портам заходили(распределение user_ip, server_port)
  	# Группировка - не показывать полное распределение, а по отношению к какому-то значению. Например, коды ошибок 200/не 200
  	# Исключение - в распределении убрать из рассмотрения определенное поле. Например, в распределении по кодам ошибок убрать код 200
  	raise "Service is not a string! #{service}" if service.class != String
    @keys = params["fields"]
  	@value = Aggregator::Aggregator.reset.select(metas: {:service => service})
    @value = Aggregator::Aggregator.select(true, datas: {@keys.last => params["exclude"]}) if params["exclude"]  # убрать строки со значением params[exclude] 
    @value = Aggregator::Aggregator.aggregate_by_keys(params["group_by"], @keys)    # выполнить агрегацию, если нужно, сгруппировать по значению
    @service = service
  end

  def hash_to_html(hsh, cnt = 0)
    if cnt == 0
      s = "<p>"
      hsh.each_pair do |k, v|
        s << "<a href='127.0.0.1/select?#{@keys[0]}=#{k}&service=#{@service}'>#{k}</a>: #{v.class == Hash ? "<br>"+hash_to_html(v, cnt+1) : v.to_s + "<br>"}\n"
      end
      s << "</p>"
      return s
    else
      s = ""
      hsh.each_pair do |k, v|
        s << "#{"  "*cnt}#{k}: #{v.class == Hash ? "<br>"+hash_to_html(v, cnt+1) : v.to_s + "<br>"}\n"
      end
      return s
    end
  end

public
  def to_html()
    max = 15
    s = ""
    s << "#{@descr}: <br>\n"
    s << hash_to_html(@value[0..max].to_h)
    s << "<a href='127.0.0.1/distrib?service=#{@service}'>show more #{@value.size-max} entries</a>\n" unless @value.size < max


    filename = "tmp/#{self.hash}.txt"
    store = YAML::Store.new filename
    store.transaction do
      name = ""
      @keys.each do |key|
        name << "#{key.upcase} - "
      end      
      name[-3..-1] = ""
      name << " DISTRIBUTION"
      store["Report Name"] = name
      store["Result"] = @value
    end
    s = "<p>#{@descr}: <a href=localhost:4567/#{filename} >show #{@value.size} #{@keys[0]}'s</a></p>"
  end
end

class Flag
  def initialize(service, params)
    @descr = params["Flag"]   # Описание, которое в первой строке
    # Флаг имеет следующие параметры:
    # look_for - подсчитываем события с данным именем. Должно совпадать с именем события в описании регулярок сервиса.
    # Например, подсчет числа событий Auth fail - сколько раз было попыток неправильной авторизации
    # threshold - порог, если >=, то флаг становится активен
    # Поля - подсчет числа событий, у которых совпадают значения данных полей. Например, подсчет числа неверных авторизаций
    # с одного IP адреса.
    raise "Service is not a string! #{service}" if service.class != String
    @fields = params["fields"]
    raise "Агрегация по нескольким полям пока не поддерживается!" if @fields.size > 1
    @value = Aggregator::Aggregator.reset.select(metas: {:service => service})
    @value = Aggregator::Aggregator.select(metas: {:type => params["look_for"]})
    @value = Aggregator::Aggregator.aggregate_by_keys(nil, @fields)
    # Переписать для поддержки многоуровневой агрегации
    threshold = params["threshold"].to_i
    @value = @value.to_a.delete_if { |ar|  ar[1] < threshold }.to_h
    @flag = !@value.empty?
  end
public
  def to_html()
    s = ""
    s << "<p>#{@descr}:  #{@flag ? "Yes" : "No"}</p>"
  end
end
end