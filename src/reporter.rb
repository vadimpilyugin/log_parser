require_relative 'tools'
require_relative 'config'
require_relative 'aggregator'

class Statistics
  def initialize(params)
    # @params = {
    #   "stat_description" => nil,
    #   "server" => nil,
    #   "service" => nil,
    #   "fields" => nil,
    #   "look_for" => nil,
    #   "group_by" => nil,
    #   "exclude_val" => nil,
    #   "threshold" => nil
    # }
    # @params.each do |param_name|
    #   @params[param_name] = params[param_name]
    # end
    # @stat_description = params[self.class.to_s]
    Printer::debug("", debug_msg:"=====================")

    @descr = params[self.class.to_s]
    @service = params["service"]  #  may be nil
    @fields = params["fields"]
    @server = params["server"]  #  may be nil
    @event_type = params["look_for"]  #  may be nil
    Printer::assert(@descr, "No description specified for #{self.class}", params.update(msg:"Reporter"))
    Printer::assert(@fields, "No fields specified for #{self.class}", msg:"Reporter", "Description":@descr)
    Printer::debug("Created a #{self.class.to_s}!", "Description":@descr, debug_msg:"Reporter", "Service":@service)
    # filter all lines using the provided parameters
    Aggregator.reset
    @request = {}
    @request[:server] = @server if @server
    @request[:service] = @service if @service
    @request[:descr] = @event_type if @event_type
    Printer::debug("Request to database: #{@request}", debug_msg:"Reporter")

    Aggregator.lines = Aggregator.lines.all(@request)
    Printer::note(Aggregator.lines.size == 0, "The Statistics is empty!", msg:"Reporter", "Type":(self.class), "Description":@descr, "Service":@service)
  end
  def Statistics.create(params)
    stat_type,stat_descr = params.to_a[0]
    case stat_type
      when /Counter/ then Counter.new(params)
      when /Distribution/ then Distribution.new(params)
      when /Flag/ then Flag.new(params)
    end
  end
  attr_accessor :descr, :service, :fields, :server, :event_type, :request, :result
  def empty?
    return Aggregator.lines.empty?
  end
end

class Counter<Statistics
  def initialize(params)
    super
    # Printer::assert(@fields, "No field specified for Counter", msg:"Reporter", "Description":@descr)
    if Aggregator.lines.size != 0
      @result = Aggregator.aggregate_by_keys(@fields).keys.size
      Printer::debug("Counter value", "Description":@descr, "Value":@result)
    end
  end
end

class Distribution<Statistics
  def initialize(params)
    @group_by_val = params["group_by"]
    @exclude_val = params["exclude"]
    super
    Printer::debug("Grouping? #{@group_by_val ? "Yes, "+@group_by_val : "No"} Excluding? #{@exclude_val ? "Yes, "+@exclude_val : "No"}")
    # Printer::assert(@fields, "No fields specified for Distribution", msg:"Reporter", "Description":@descr)
    if Aggregator.lines.size != 0
      @result = Aggregator.aggregate_by_keys(@fields,@exclude_val,@group_by_val)
      # Printer::debug("Distribution result", @result)
    end
  end
end

class Flag<Statistics
  def initialize(params)
    @threshold = params["threshold"]
    super
    Printer::assert(@service, "No service specified for Flag", msg:"Reporter", "Description":@descr)
    if Aggregator.lines.size != 0
      @result = Aggregator.aggregate_by_keys(@fields)
      @result = @result.to_a.delete_if { |ar|  ar[1] < @threshold }.to_h
    end
  end
end

class Report
  @stats = []
  class << self; attr_accessor(:stats) end
  def self.init
    @report_file = Tools.load(Config["report"]["report_config"])
    Printer::debug("Loaded configuration for Report from #{Config["report"]["report_config"]}", debug_msg:"Preparations")
    @report_file.each do |stat|
      st = Statistics.create(stat)
      @stats << st unless st.empty?
    end
  end
end









def classifier(key)
  key = key.to_s
  if ["server", "service", "time", "type"].include? key
    return "Main key"
  elsif ["except", "unique"].include? key
    return "Conditional key"
  else
    return "Data key"
  end
end

def request_builder(cond, type)
  key = cond.to_a[0].to_s
  value = cond.to_a[1].to_s
  if classifier(key) == "Main key"
    if type == "except"
      return {key.to_sym.not => value}
    else
      return {key.to_sym => value}
    end
  elsif classifier(key) == "Data key"
    if type == "except"
      return {data: {:name => key, :value.not => value}}
    else
      return {data: {:name => key, :value => value}}
    end
  else
    return {}
  end
end

class Hash
  def my_update(hsh)
    if hsh[:data] and self[:data]
      self[:data].update(hsh[:data])
    else
      self.update hsh
    end
  end
end

require_relative 'date'

class Counter
  def initialize(hsh)
    @descr = hsh["Counter"]
    hsh.delete "Counter"
    request = {}
    for i in ["server", "service", "type"]
      request.update { i.to_sym => hsh[i] }
      hsh.delete i
    end
    if hsh["time"]
      request.my_update({ :time.gt => DateTime.create_from(hsh["time"][0], "min"), 
                          :time.lt => DateTime.create_from(hsh["time"][1], "max")})
      hsh.delete "time"
    end
    if hsh["except"]
      hsh["except"].each do |cond|
        request.my_update request_builder(cond, "except")
      end
      hsh.delete "except"
    end
    unique = hsh["unique"]
    hsh.delete "unique"
    hsh.each_pair do |key,value|
      request.my_update request_builder({key => value})
    end
    lines = Aggregator.lines.all request
    Printer::debug(msg:"Counter: #{@descr}", params:request)
    Printer::error(expr:lines != nil, msg:"No lines left after a request", params: request)
    if unique
      Aggregator.




























# require_relative "aggregator"
# require_relative "config"
# require_relative "server"
# require_relative "output"
# require "yaml/store"
# require 'yaml'
# require "slim"

# module Reporter

# class Statistics
#   def self.create(service, hsh)
#     type = hsh.to_a[0][0]
#     case type
#       when "Counter" then Counter.new service, hsh
#       when "Distribution" then Distribution.new service, hsh
#       when "Flag" then Flag.new service, hsh
#       else Tools.assert false, "Неопределенный тип статистики в #{hsh}"
#     end
#   end
# end

# class Reporter
#   def initialize
#     folder = Config["reporter"]["config_folder"]
#     Tools.assert !Dir.entries(folder).empty?,  "Report directory does not exist: #{folder}"
#     Tools.assert Dir.entries(folder).size > 2, "No templates found at report dir: #{folder}"
#     @report_struct = {}
#     Dir.entries(folder).each do |service|    # загружаем шаблоны построения отчета
#       next if service == "." || service == ".."
#       service_template = YAML.load_file "#{folder}/#{service}"
#       printf "#{service}\n#{service_template.to_yaml}\n"
#       service_template.each do |elem|
#         printf "#{elem}\n#{elem.class}\n"
#         printf "#{elem.to_a[0][0]} - #{elem.to_a[0][0].class}\n"
#       end
#       service_template.map! { |hsh| Statistics.create service, hsh }
#       @report_struct[service] = service_template
#     end
#     @filename = Config["reporter"]["report_file"]
#   end
# public
#   def report()
#     Dir.mkdir("report", 0777) unless Dir.exists? "report"
#     f = File.open(@filename, File::CREAT|File::TRUNC|File::RDWR, 0644)
#     @log_file = Config["parser"]["log_file"]
#     # f = File.open("src/views/report.slim", File::CREAT|File::TRUNC|File::RDWR, 0644)
#     f << "<!DOCTYPE html>\n"
#     f << "<html>\n"
#     f << "<head><title>Report</title></head>\n"
#     f << "<body>\n<PRE>"
#     f << "<h4>Report on #{Config["parser"]["log_file"]}</h4>\n"
#     @report_struct.each_pair do |service, template|
#       f << "=================#{service.upcase}=================\n"
#       template.each do |stat|
#         f << stat.to_html
#       end
#       f << "=================#{service.upcase} END=================\n\n\n"
#     end
#     f << "</PRE></body></html>"
#     f.close
#   end
# end

# class Counter
#   def initialize(service, params)
#   	@descr = params["Counter"]		# Описание, которое в первой строке
#   	Счетчик имеет следующие параметры:
#   	Поле - подсчитывает уникальные значения данного поля. Например, уникальные IP адреса
#     Описание строки. Например, "New connection" с полем "user_ip" выберет только те ip,
#                       которые присутствовали в сообщениях о подключении
#   	@field = params["field"]
#   	Tools.assert service.class == String, "Service is not a string! #{service}"
#   	@value = Aggregator::Aggregator.reset.select(metas: {"service" => service}).aggregate_by_keys([@field]).size
#     @service = service
#   end
# public
#   def to_html()
#     return "<b>#{@descr}</b>: #{Reference.href(text: @value, select: {"service" => @service}, distrib: [@field])}" + "\n" if @value > 0
#     return "<b>#{@descr}</b>: 0\n"
#   end
# end

# class Distribution
#   def initialize(service, params)
#   	@descr = params["Distribution"]		# Описание, которое в первой строке
#     Printer::note(@descr == nil, "No description provided for distribution", "Service")
#   	# Распределение имеет следующие параметры:
#   	# Поля - показывает их взаимное распределение. Например, какие IP по каким портам заходили(распределение user_ip, server_port)
#   	# Группировка - не показывать полное распределение, а по отношению к какому-то значению. Например, коды ошибок 200/не 200
#   	# Исключение - в распределении убрать из рассмотрения определенное поле. Например, в распределении по кодам ошибок убрать код 200
#   	Printer::assert(service.class == String, "Service is not a string! #{service}")
#     @keys = params["fields"]
#   	@value = Aggregator::Aggregator.reset.select(metas: {"service" => service})
#     @value = Aggregator::Aggregator.select(datas: {@keys.last => "not "+params["exclude"]}) if params["exclude"]  # убрать строки со значением params[exclude] 
#     Aggregator::Aggregator.group_by = params["group_by"]
#     @value = Aggregator::Aggregator.aggregate_by_keys(@keys)    # выполнить агрегацию, если нужно, сгруппировать по значению
#     @service = service
#     @exclude = params["exclude"]
#     @max = params["max"] ? params["max"] : 15
#   end

#   def hash_to_html(hsh, cnt = 0)
#     if cnt == 0
#       Tools.assert hsh.class == Hash, "Not a hash! #{hsh.class}"
#       # Tools.assert hsh.size > 0, "Hash size equals zero!"
#       s = ""
#       hsh.each_pair do |key, value|
#         s << Reference.href(text: key, select: {"service" => @service, @keys[0] => key})
#         s << ": #{value.class == Hash ? "\n"+hash_to_html(value, cnt+1) : value.to_s + "\n"}"
#       end
#       return s
#     else
#       s = ""
#       if cnt == @keys.size-1 && @exclude
#         keys = hsh.keys
#         if keys[0] =~ /^not/
#           key2 = keys[0]
#           key = keys[1]
#         else
#           key = keys[0]
#           key2 = keys[1]
#         end
#         s << "#{"  "*cnt}#{key}: #{hsh[key].to_s + "\n"}" if key != nil
#         s << "#{"  "*cnt}#{key2}: #{hsh[key2].to_s + "\n"}" if key2 != nil
#       elsif cnt == @keys.size-1
#         hsh.each_pair do |k, v|
#           s << "#{"  "*cnt}#{k}: #{v.to_s + "\n"}"
#         end
#       else
#         hsh.each_pair do |k, v|
#           Tools.assert v.class == Hash, "Value is not a hash: #{k} => #{v.class}"
#           s << "#{"  "*cnt}#{k}: #{"\n"+hash_to_html(v, cnt+1)+"\n"}"
#         end
#       end
#       return s
#     end
#   end

# public
#   def to_html()
#     if @value.size > 0
#       s = "<b>#{@descr}</b>: \n"
#       s << hash_to_html(@value.to_a[0..@max-1].to_h)
#       if @value.size > @max && @max != -1
#         s << ":\n"
#         s << Reference.href(text: "show #{@value.size-@max} more entries", select: {"service" => @service}, distrib: @keys) << "\n"
#       end
#       s << "\n"
#     else
#       "<b>#{@descr}</b>: Empty\n"
#     end
#   end
# end

# class Flag
#   def initialize(service, params)
#     @descr = params["Flag"]   # Описание, которое в первой строке
#     # Флаг имеет следующие параметры:
#     # look_for - подсчитываем события с данным именем. Должно совпадать с именем события в описании регулярок сервиса.
#     # Например, подсчет числа событий Auth fail - сколько раз было попыток неправильной авторизации
#     # threshold - порог, если >=, то флаг становится активен
#     # Поля - подсчет числа событий, у которых совпадают значения данных полей. Например, подсчет числа неверных авторизаций
#     # с одного IP адреса.
#     Tools.assert service.class == String, "Service is not a string! #{service}"
#     @fields = params["fields"]
#     Tools.assert @fields.size == 1, "Агрегация по нескольким полям пока не поддерживается!"
#     @value = Aggregator::Aggregator.reset.select(metas: {"service" => service})
#     @value = Aggregator::Aggregator.select(metas: {"type" => params["look_for"]})
#     @value = Aggregator::Aggregator.aggregate_by_keys(@fields)
#     # Переписать для поддержки многоуровневой агрегации
#     threshold = params["threshold"].to_i
#     @value = @value.to_a.delete_if { |ar|  ar[1] < threshold }.to_h
#     @flag = !@value.empty?
#     @service = service
#   end
# public
#   def to_html()
#     s = ""
#     if @flag
#       s << "<b>#{@descr}</b>:  Да\n"
#       @value.each_pair do |k,v|
#         s << Reference.href(text: k, select: {"service" => @service, @fields[0] => k})
#         s << ": #{v}\n"
#       end
#     else
#       s << "<b>#{@descr}</b>:  Нет\n"
#     end
#     return s
#   end
# end

# class Lines
#   def initialize(params)
#     # Tools.assert params[:text], "No description: #{params}"
#     Tools.assert params[:select], "No parameters specified for selection: #{params}"
#     # Tools.assert !params[:distrib], "This is not for distribution: #{params}"
#     @descr = "#{params[:select]}"
#     service = params[:select]["service"]
#     select_params = params[:select].reject {|k,v| k == "service"}
#     @value = []
#     lines = Aggregator::Aggregator.reset.select(metas: {"service" => service}, datas: select_params).lines
#     lines.each do |line|
#       @value << line.to_a
#     end
#   end
# public
#   def to_html()
#     s = "<b>Value:</b> #{@descr}\n"
#     s << "<b>Log lines containing value:</b>\n"
#     s << Output.out_table(@value)
#   end
# end
# end