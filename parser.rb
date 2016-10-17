class Hash
	def add!(str)
		self.update(str => 1) {|k, o, n| o+n}
	end
	def print
		s = ""
		self.each{ |x| s << "#{x[0]}-#{x[1]} time(s); " }
		s
	end
end

#real_line = "124.219.152.208 - - [11/Oct/2016:06:17:00 +0300] \"GET /apple-touch-icon.png?hello=world HTTP/1.0\" 404 299 \"-\" \"Safari/11602\" - - old.parallel.ru"
block = /\d{1,3}/
#puts "#{$~.to_s}" if "124.219.152.208" =~ block
ip = /#{block}\.#{block}\.#{block}\.#{block}/
#puts "#{$~.to_s}" if "124.219.152.208" =~ ip
# path = /\/[^\/\?]*\g<0>?/
path = /(\/[^\/\?]*)+/
#puts "#{$~.to_s}" if "/apple-touch-icon.png?hello=world" =~ path
log = /^(?<ip_addr>#{ip}) - - \[[^\]]*\] "(?<method>[A-Z]+) (?<pathname>#{path}).* HTTP\/1\.[01]" (?<code>\d{1,3})/
#printf "IP = %s\nMethod = %s\nCode = %s\nPath = %s\n" %[$~[:ip_addr], $~[:method], $~[:code], $~[:pathname]] if real_line =~ log
table = []
not_logged = []
File.open("./logs/access-parallel_ru_log") { |f|
	f.each { |line|
		if line !~ log
			table << line
		else
			table << {ip_addr: $~[:ip_addr], pathname: $~[:pathname], method: $~[:method], code: $~[:code]};
		end
	}
}
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
