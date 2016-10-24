class Hash
	def increment(key)
        self.update(key => 1) {|k, o, n| o+n}
    end
    def at(key)
		if self.has_key?(key)
			self[key]
		else
			0
		end
	end
	alias square_braces []
	def [] (key)
		#puts "Hash::[](#{key})"
		if key.class == "String".class
			self.update(key => {}) unless self.square_braces(key)
		end
		square_braces(key)
	end
	alias assignment_braces []=
	def []= (key, value)
		#puts "Hash::[]=(#{key}, #{value})"
		if key.class == "String".class
			self.update(key => {}) unless self.square_braces(key)
		end
		assignment_braces(key, value)
	end
	def +(val)
		return val if self.empty?
		raise "Нельзя использовать + на непустом хэше!"
	end
end

class Parser
	def initialize
		@ip_addr = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
		pathname = /(\/[^\/\?]*)+/
		@format = /^(?<ip>#{@ip_addr}) - - \[[^\]]*\] "(?<method>[A-Z]+) (?<path>#{pathname}).* HTTP\/1\.[01]" (?<code>\d{1,3})/
		@table = []
		@misses = []
	end
	def parse(filename)
		File.open(filename) { |f|
			f.each{ |line|
				if line =~ @format
					@table << {ip: $~[:ip], path: $~[:path], method: $~[:method], code: $~[:code]}
				else
					@misses << line
				end
			}
		}
	end
	def write_to_file
		unique_pages = {}
		ip_table = {}
		codes_distrib = {}
		codes_detail_users = {}
		codes_detail_page = {}
		@table.each { |line|
			# Распределение кодов ошибок
			codes_distrib[line[:code]] += 1
			codes_distrib["not OK"] += 1 if line[:code] != "200"
			
			# Подсчет числа запросов страниц
			unique_pages[line[:path]][line[:code]] += 1 # распределение по кодам
			unique_pages[line[:path]]["not OK"] += 1 if line[:code] != "200" # число ошибочных запросов конкретной страницы
			
			# Подсчет числа запросов пользователей
			ip_table[line[:ip]][line[:code]] += 1 # распределение по кодам
			ip_table[line[:ip]]["not OK"] += 1 if line[:code] != "200" # ошибочные запросы пользователя
			ip_table[line[:ip]]["sum"] += 1 # число всех запросов пользователя
			
			# Детализированный отчет по каждому коду
			codes_detail_users[line[:code]][line[:ip]] += 1 # по пользователям
			codes_detail_page[line[:code]][line[:path]] += 1 # по страницам
		}
		good_pages = unique_pages.count { |elem| elem[1].has_key? ("200") }
		
		# Основной отчет
		File.open("./report/summary.txt", "w", 0644) { |summary|
			summary << "\t\t\t\t\t\tОсновной отчет\n\n"
			summary << "----------------------\n\n"
			summary << "Число запросов (OK/не ОК): #{codes_distrib.at("200")}/#{codes_distrib.at("not OK")}\n"
			summary << "Число IP(уникальных): #{ip_table.size}\n"
			summary << "Число уникальных страниц (OK/не ОК): #{good_pages}/#{unique_pages.size - good_pages}\n"
			summary << "\n----------------------\n\n"
			summary << "Ошибки на страницах:\n"
			(unique_pages.to_a.sort_by{ |elem| -(elem[1].at("not OK"))})[0..9].each{ |elem|
				summary << "#{elem[0]}: 404: #{elem[1].at("404")}; другие: #{elem[1].at("not OK") - elem[1].at("404")}\n"
			}
			summary << "Еще #{unique_pages.size-good_pages-10} записей...\n" if unique_pages.size>10
			summary << "\n----------------------\n\n"
			summary << "Распределение по кодам:\n"
			(codes_distrib.to_a.sort_by{ |elem| -elem[1] }).each{ |elem|
				summary << "CODE #{elem[0]}: #{elem[1]} раз(а)\n" if elem[0] =~ /^\d/
			}
			summary << "\n----------------------\n\n"
			summary << "Самые активные пользователи: \n"
			(ip_table.sort_by { |v| -v[1]["sum"] })[0..9].each{ |elem|
				summary << "#{elem[0]}: #{elem[1]["sum"]} запрос(ов), из них #{elem[1].at("not OK")} неудачных\n"
			}
			summary << "Еще #{ip_table.size-10} записей...\n" if ip_table.size>10
			summary << "\n----------------------\n\n"
		}
		
		# Отчет по самым активным пользователям
		most_active = (ip_table.to_a.sort_by { |v| -v[1]["sum"] })[0..9].map{ |val| val[0] }
		user_table = {}
		@table.each{ |line|
			if most_active.member? line[:ip]
				user_table[line[:ip]][line[:path]][line[:code]] += 1 # какие страницы с какими кодами
				user_table[line[:ip]][line[:path]]["sum"] += 1 # сколько всего запросов к конкретной странице
				user_table[line[:ip]]["sum"] += 1 # сколько всего сделал запросов
				user_table[line[:ip]]["OK"] += 1 if line[:code] == "200" # сколько из них успешных
			end
		}
		File.open("./report/users/most_active.txt", "w", 0644) { |f|
			f << "\t\t\t\t\t\tОтчет по пользователям\n"
			user_table.sort_by{ |val| -val[1]["sum"]}.each{ |val|
				key = val[0]
				value = val[1]
				f << "\n----------------------\n\n"
				f << "User: #{key}\n"
				f << "Успешных/неуспешных попыток: #{value.at("OK")}/#{value["sum"] - value.at("OK")}\n"
				f << "Посещенные страницы:\n"
				((value.delete_if{ |key| key == "OK" || key == "sum"}).sort_by{ |val| -val[1]["sum"] })[0..9].each{ |val|
					f << "#{val[0]}: #{val[1]["sum"]} раз(а), с кодами: "
					val[1].each{ |key, val|
						f << "#{key} - #{val}; " if key =~ /^\d/
					}
					f << "\n"
				}
				f << "Еще #{value.size-10-2} страниц(а)...\n" if value.size>12
			}
		}
		
		# Отчет по каждому коду ошибки, по страницам
		basename = "./report/codes/pages"
		codes_detail_page.to_a.each{ |elem|
			File.open("#{basename}/code_#{elem[0]}.txt", "w", 0644) { |f|
				f << "\t\t\t\t\t\Отчет по #{elem[0]} коду\n"
				(elem[1].to_a.sort_by{ |val| -val[1] }).each{ |val| 
					f << "#{val[0]}: #{val[1]} раз(а)\n"
				}
			}
		}
		
		# А это по пользователям
		basename = "./report/codes/users"
		codes_detail_users.to_a.each{ |elem|
			File.open("#{basename}/code_#{elem[0]}.txt", "w", 0644) { |f|
				f << "\t\t\t\t\t\Отчет по #{elem[0]} коду\n"
				(elem[1].to_a.sort_by{ |val| -val[1] }).each{ |val| 
					f << "#{val[0]}: #{val[1]} раз(а)\n"
				}
			}
		}
	end
end

p = Parser.new()
p.parse("./logs/access-parallel_ru_log")
p.write_to_file
