require 'yaml'
require 'yaml/store'
require_relative 'regex.rb'

class MatchData
public
	def to_h
		self.names.zip(self.captures).to_h			# представление в виде хэша {<named_group_1> => "data_1", ...}
	end
end

class Parser
	include Regexes
	
	attr_reader :table
	
	def include?(array, line)
		if array.index {|rxp| line =~ rxp}		# дан массив регулярок и строка. Определить вхождение или не вхождение	
			# printf "#{$~.to_h}\n"
			@md = $~
		else
			nil
		end
	end

	def initialize(hsh = {})
		Dir.chdir(File.expand_path("../../", __FILE__))												# переходим в корень проекта
		@config = YAML.load_file('default.conf/parser.cfg')											# это конфиг самого парсера
		@error_log = File.new(@config["error_log"], File::CREAT|File::TRUNC|File::RDWR, 0644)		# сюда пишем ошибки
		@filename = hsh[:filename] ? hsh[:filename] : @config["log_file"]							# по умолчанию из конфига, можно указать свой
		@log_template = case @filename
						when /auth\d*\.log/ then Syslog												# определяем тип лога на основе имени файла
						when /access/ then Apache
						else
							@error_log.puts "Неопознанный формат лога: имя файла #{@filename}\n"
							puts "Неопознанный формат лога: имя файла #{@filename}\n"
							raise "Неопознанный формат"
						end
		@thing = {} 			# {sshd => {Name1 => [Patterns], ...}, CRON => {Name1 => [Patterns1], ...}, ...}
		@table = [] 			# [filename, line, data => {key:value}, meta => {key:value}]
		@md = $~
	end

	# подгрузка сервиса по имени
	def load_service(service, f)
		filename = "#{@config["services_dir"]}/#{service.downcase}"			# имя файла это путь до директории плюс
																			# имя сервиса в lowercase
		unless File.exists?(filename)
			@error_log.puts "Неопознанный сервис: #{service}, строка #{f.lineno}, файл #{@filename}\n"
			puts "Неопознанный сервис: #{service}, строка #{f.lineno}, файл #{@filename}\n"
			return nil
		end
		hsh = YAML.load_file(filename)					# загружаем в хэш из файла
		hsh.update(hsh) do |k, o, n|					# и проходимся по нему, чтобы строки скомпилить в регулярки
			o.map { |e| Regexp.new(e) }
		end
		return hsh
	end

public
	def parse!
		f = File.open(@filename)
		f.each_line{ |line|
			unless line =~ @log_template												# сравниваем строку с шаблоном, определенным по имени файла
				@error_log.puts "Строка не соответствует шаблону(in #{@filename}) #{f.lineno}:1): #{line}\n"
				puts "Строка не соответствует шаблону(in #{@filename}) #{f.lineno}:1): #{line}\n"
			end
			if @log_template == Apache 													# для апача просто сбрасываем в таблицу все именованные группы из регулярки
				@table << [@filename, f.lineno, $~.to_h, {"service" => "apache"}]
			elsif @log_template == Syslog
				service = $~[:service]
				msg = $~[:msg]
				server = $~[:server]
				unless @thing.has_key?(service)											# подгружаем сервисы по мере надобности, изначально нет ни одного
					if hsh = load_service(service, f)									# проверяем, что файл с шаблонами существует
						@thing.store(service, hsh)										# и включаем хэш регулярок в "штуку" по всем сервисам
					else																# если набора шаблонов для такого сервиса не существует
						next															# пропускаем эту строку
					end
				end
				i = @thing[service].to_a.index { |ar|									# поиск совпадений по указанному сервису
					include?(ar[1], msg)												# описывается ли данное сообщение какой-нибудь регуляркой?
				}
				$~ = @md
				# printf "#{$~.to_h}\n"
				if i
					elem = @thing[service].to_a[i]										# если описывается, то MatchData из него выгружаем целиком
																						# плюс описание, из какой команды мы ее получили
					@table << [@filename, f.lineno, $~.to_h, {"service" => service, "server" => server, "type" => elem[0]}] unless elem[0] == "Ignore" 
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