class Hash
	def increment(key)
        self.update(key => 1) {|k, o, n| o+n}
    end
    def at(key)
		self[key]? self[key]: 0
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
			codes_distrib["sum"] += 1
			
			# Подсчет числа запросов страниц
			unique_pages[line[:path]][line[:code]] += 1 # распределение по кодам
			unique_pages[line[:path]]["sum"] += 1 # число запросов конкретной страницы
			
			# Подсчет числа запросов пользователей
			ip_table[line[:ip]][line[:code]] += 1 # распределение по кодам
			ip_table[line[:ip]]["sum"] += 1 # суммарно по пользователю
			
			# Детализированный отчет по каждому коду
			codes_detail_users[line[:code]][line[:ip]] += 1 # по пользователям
			codes_detail_page[line[:code]][line[:path]] += 1 # по страницам
			
			#unique_pages.update(line[:path] => {line[:code] => 1}) { |k,o,n|
				#o.increment(line[:code])
			#}
			#ip_table.update(line[:ip] => {line[:code] => 1}) { |k,o,n|
				#o.increment(line[:code])
			#}
			#codes_detail_users.update(line[:code] => {line[:ip] => 1}) { |k,o,n|
				#o.increment(line[:ip])
			#}
			#codes_detail_page.update(line[:code] => {line[:path] => 1}) { |k,o,n|
				#o.increment(line[:path])
			#}
		}
		good_pages = unique_pages.count { |elem| elem[1]["200"] > 0 if elem[1].has_key? ("200") }
		
		# Основной отчет
		File.open("./report/summary.txt", "w", 0644) { |summary|
			summary << "\t\t\t\t\t\tОсновной отчет\n"
			summary << "Число запросов (OK/не ОК): #{codes_distrib.at("200")}/#{codes_distrib["sum"] - codes_distrib.at("200")}\n"
			summary << "Число IP(уникальных): #{ip_table.size}\n"
			summary << "Число уникальных страниц (OK/не ОК): #{good_pages}/#{unique_pages.size - good_pages}\n"
			summary << "\n----------------------\n\n"
			summary << "Ошибки на страницах:\n"
			(unique_pages.to_a.sort_by{ |elem| -(elem[1]["sum"] - elem[1].at("200"))})[0..9].each{ |elem|
				#summary << "#{elem[0]}: #{elem[1]["sum"] - elem[1].at("200")} ошибок, из них #{elem[1].at("404")} 404-ых\n"
				summary << "#{elem[0]}: 404: #{elem[1].at("404")}; другие: #{elem[1]["sum"] - elem[1].at("200") - elem[1].at("404")}\n"
			}
			summary << "Еще #{unique_pages.size-10} записи(ей)...\n" if unique_pages.size>10
			summary << "\n----------------------\n\n"
			summary << "Распределение по кодам:\n"
			(codes_distrib.to_a.sort_by{ |elem| -elem[1] }).each{ |elem|
				summary << "CODE #{elem[0]}: #{elem[1]} раз(а)\n"
			}
			summary << "\n----------------------\n\n"
			summary << "Самые активные пользователи: \n"
			(ip_table.sort_by { |v| -v[1]["sum"] })[0..9].each{ |elem|
				summary << "#{elem[0]}: #{elem[1]["sum"]} запрос(ов), из них #{elem[1]["sum"] - elem[1].at("200")} неудачных\n"
			}
			summary << "Еще #{ip_table.size-10} записи(ей)...\n" if ip_table.size>10
		}
		
		# Отчет по самым активным пользователям
		most_active = (ip_table.to_a.sort_by { |v| -v[1]["sum"] })[0..2]
		user_table = {}
		@table.each{ |line|
			if most_active.member? line[:ip]
				user_table[line[:ip]][line[:path]][line[:code]] += 1
				user_table[line[:ip]][line[:path]]["sum"] += 1
				user_table[line[:ip]]["sum"] += 1
				user_table[line[:ip]]["OK"] += 1 if line[:code] == "200"
			end
		}
		File.open("./report/users/most_active.txt", "w", 0644) { |f|
			f << "\t\t\t\t\t\tОтчет по пользователям\n"
			user_table.each{ |key, value|
				f << "User: #{key}\n"
				f << "Успешных/неуспешных попыток: #{value
				f << "Посещенные страницы:\n"
				value.each{ |key, value|
					f << "#{key}: #{value["sum"]} раз, с кодами "
					value.each{ |key, value|
						f << "#{key} - #{value}; " unless key == "sum"
					}
					f << "\n"
				}
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
=begin
not_found = {}
cnt = 0
table.each { |line| 
	if line[:code] == "404"
		#not_found.update(line[:pathname] => 1) {|k, o, n| o+n}
		not_found.add!(line[:pathname])
		cnt += 1
	end
}
not_found = not_found.sort_by { |n, cnt| -cnt}

codes_table = {}
table.each{ |line|
	if line[:code] != "200"
		codes_table.add!(line[:code])
	end
}

ip_table = {}
table.each{ |line|
	ip_table.update( line[:ip_addr] => [{line[:code] => 1}, 1] ) { |k,o,n| [o[0].add!(line[:code]), o[1]+n[1]] }
}
ip_table = ip_table.sort_by { |name, val| -val[1]}

system "clear; clear"
puts "Failed attempts - #{cnt} time(s):"
not_found[0..9].each{ |line|
	puts "#{line[0]} - #{line[1]} time(s)"
}
puts "More #{not_found.size - 10} entries..." if not_found.size - 10 > 0
printf "\n--------------\n"
puts "All error codes:"
codes_table.each{ |line|
	puts "ERROR #{line[0]} - #{line[1]}"
}
printf "\n--------------\n"
puts "Most active IP(s):"
ip_table[0..9].each{ |line|
	puts "#{line[0]} - #{line[1][1]} time(s): #{line[1][0].print}"
}
puts "More #{ip_table.size - 10} entries..." if ip_table.size - 10 > 0
=end
