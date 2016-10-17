puts 1.class
3.times { print "Ruby!\n"  }
1.upto(9) { |x| print x }
puts
a = [3, 2, 1] # индексация с 0
a[3] = a[1] - 2
print a
puts
a.each do |elem|
	print "a[i] = "
	print elem
	print "\n"
end
print a.map { |x| x*x}
puts
print a.select { |x| x%2 == 0}
puts
sum = a.inject do |sum, x|
	sum+x
end
=begin
print "Сумма элементов массива равна #{sum}\n"
print "2^1024-2*2^1023 = #{2 ** 1024 - 2*2 ** 1023}\n"
printf "%d %s\n" % [3, "rubies"]
=end
p a
массив = [1, 2, 3, 4]
print массив.map { |x| x*x }; puts
x=1.0
#while x>0 do
#	printf "#{x} - #{x.class}\n"
#	x=x/2
#end
printf "#{(1..10).to_a}\n"
empty_matrix = Array.new(3) { Array.new(3) }
arr = ('A'..'Z').to_a
puts arr.first
puts arr.last
puts arr.include?('B')
arr.unshift('z')
arr.insert(0, 'y')
print "#{"Hello".chars}\n"
p = "Hello, World!"
q = p
q[0..7] = ""
puts p
puts q
y=x=1.0
(2..1000).each { |i|
	while x>0 do
		y=x
		x/=i
	end
	puts "For i=#{i} min num is #{y}"
	x=y
}
puts "Between 0 and 1 are #{(1/y - 1)} numbers"
##file.each do |line|
	##print line if line =~ /^192./..line =~ /^$/
##end
#while line=gets.chomp do
	#case line
	#when /^\s*#/
		#next
	#when /^quit$/
		#break
	#else
		#puts line.reverse
	#end
#end
ar=[]
File.open("matrix1.txt") do |f|
	f.each { |line| ar << line.split.map {|num| num.to_f} unless /^[fd]/ === line}
end
print ar, "\n"
#{
	#block = /\b(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\b/
	#date = /\[[\d\w\s\:\/\+]+\]/
	#date = /\b\[.*\]\b/ # пока не парсим, просто пропускаем
	#name = /[^\\\/\?%\*:"<>\ ]+/ # все, что валидно в UNIX
	#path = 	/\A \/ ( #{name} (\g<0>)? )? \Z/x
	#path = /\A(\/|(\/[^\\\/\?%\*:"<>\ ]+)+\/?)\Z/
	#path = / \b ( \/ (#{name})? )+/x
	#path = / \b ( \/ #{name} )+ \/?/x
	#puts "#{$~.to_s}" if "/home/vadim/Documents/papi_5.5.0/src/libpapi.a" =~ path
	#puts "#{$~.to_s}" if "/home/" =~ path
	#args = /#{name}=#{name}(;#{name}=#{name})*/
	#args = /#{name}=#{name}(;\g<0>)?/
	#printf "Yes!\n" if "C=N;O=A" =~ args
	#printf "No!\n" if "C=N;O=A;" =~ path
	#log = /#{ip} - - #{date} "(A-Z)+ #{path}(?:\?#{args})? .*" ([0-9]+) .+ "-" ".*" - - .*/
	#puts "IP = #{$~.to_s}" if real_line =~ ip
	#puts "Path = #{Regexp.last_match[1]}" if real_line =~ /.*GET (#{path}).*/
	#puts real_line =~ /.*GET #{path}.*/
	#puts real_line =~ /.*GET #{path}.*/
	#puts "/apple-touch-icon.png?hello=world" =~ path
