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
			table << {ip: $~[:ip_addr], pathname: $~[:pathname], method: $~[:method], code: $~[:code]};
		end
	}
}
not_found = {}
cnt = 0
table.each { |line| 
	if line[:code] == "404"
		not_found.update(line[:pathname] => 1) {|k, o, n| o+n}
		cnt += 1
	end
}
not_found = not_found.sort_by { |n, cnt| -cnt}

system "clear"
puts "Failed attempts - #{cnt} time(s):"
not_found[0..9].each{ |line|
	puts "old.parallel.ru#{line[0]} - #{line[1]} time(s)"
}
puts "More #{not_found.size - 10} entries..." if not_found.size - 10 > 0

