require_relative 'regex.rb'
require_relative 'config.rb'

class MatchData
  def to_h
    a = self.captures.delete_if {|e| e == nil}
    self.names.zip(a).to_h
  end
end

module Parser

class Parser
  include Regexes

  attr_reader :table

  def include?(array, line)
    a = array.index {|rxp| line =~ rxp} # дан массив регулярок и строка. Определить вхождение или не вхождение
    @md = $~
    if @ind == -1 and a != nil
      printf "Array of regexes: #{array}\n"
      printf "Line: #{line}\n"
      printf "Index found at #{a}\n"
      printf "MatchData is #{@md.to_h}\n"
      line =~ array[a]
      @md = $~
      printf "And now MatchData is #{@md.to_h}\n"
    end
    return a
  end

  def initialize(hsh = {})
    Dir.chdir(File.expand_path("../../", __FILE__))	# переходим в корень проекта
    @error_log = File.new(Config["overall"]["error_log"], File::CREAT|File::TRUNC|File::RDWR, 0644)	# сюда пишем ошибки
    @filename = hsh[:filename] ? hsh[:filename] : Config["parser"]["log_file"]	# отсюда читаем лог
    raise "Log file does not exist: #{@filename}" if !File.exists? @filename
    @services_dir = Config["parser"]["services_dir"]  # здесь храним описания сервисов
    raise "Services directory does not exist: #{@services_dir}" if Dir.entries(@services_dir).empty?
    raise "No templates found at services dir: #{@services_dir}" if Dir.entries(@services_dir).empty?
    @log_template = case @filename	# определяем тип лога по имени файла
      when /auth.*log/ then Syslog	
      when /access/ then Apache
      else
        @error_log.puts "Неопознанный формат лога: имя файла #{@filename}\n"
        puts "Неопознанный формат лога: имя файла #{@filename}\n"
        raise "Неопознанный формат лога"
    end
    @thing = {} 	# {sshd => {Name1 => [Patterns], ...}, CRON => {Name1 => [Patterns1], ...}, ...}
    @table = [] 	# [filename, line, data => {key:value}, meta => {key:value}]    
  end

# подгрузка сервиса по имени
def load_service(service, f)
  filename = "#{@services_dir}/#{service.downcase}"		# имя файла это путь до директории плюс имя сервиса в lowercase
  if !File.exists? filename
    @error_log.puts "Неопознанный сервис: #{service}, строка #{f.lineno}, файл #{@filename}\n"
    puts "Неопознанный сервис: #{service}, строка #{f.lineno}, файл #{@filename}\n"
    return nil
  end
  hsh = YAML.load_file(filename)	# загружаем в хэш из файла
  hsh.each_value do |ar|			# и проходимся по нему, чтобы строки скомпилить в регулярки
    ar.map! do |s|
  	  Regexp.new(s)
  	end
  end
  return hsh
end
public
  def parse!
    f = File.open(@filename)
    f.each_line{ |line|
      @ind = f.lineno
      if line !~ @log_template													# сравниваем строку с шаблоном, определенным по имени файла
        @error_log.puts "Строка не соответствует шаблону( #{@filename}) #{f.lineno}:1): #{line}\n"
        puts "Строка не соответствует шаблону( #{@filename}) #{f.lineno}:1): #{line}\n"
      end
      if @log_template == Apache 												# для апача просто сбрасываем в таблицу все именованные группы из регулярки
        @table << [@filename, f.lineno, $~.to_h, {"service" => "apache"}]
      elsif @log_template == Syslog
        service = $~[:service]
        msg = $~[:msg]
        server = $~[:server]
        if !@thing.has_key?(service)											# подгружаем сервисы по мере надобности, изначально нет ни одного
          if hsh = load_service(service, f)										# проверяем, что файл с шаблонами существует
            @thing.store(service, hsh)											# и включаем хэш регулярок в хэш по всем сервисам
          else																	# если набора шаблонов для такого сервиса не существует
            next																# пропускаем эту строку
          end
        end
        i = @thing[service].to_a.index { |ar|									# поиск совпадений по указанному сервису
          include?(ar[1], msg)												# описывается ли данное сообщение какой-нибудь регуляркой?
        }
        # printf "#{md_h($~)}\n"
        if i
          elem = @thing[service].to_a[i]			# если описывается, то MatchData из него выгружаем целиком
          																    # плюс описание, из какой команды мы ее получили
          @table << [@filename, f.lineno, @md.to_h, {"service" => service, "server" => server, "type" => elem[0]}] unless elem[0] == "Ignore" 
          else
          																    # все сообщения сервиса, для которых не нашлось
          																    # регулярки, идут в таблицу с типом undefined
          @table << [@filename, f.lineno, {"msg" => msg}, {"service" => service, "type" => "undefined"}] 	
        end
      end
    }
    self
  end
end
end
