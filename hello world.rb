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
	#puts "For i=#{i} min num is #{y}"
	x=y
}
#puts "Between 0 and 1 are #{(1/y - 1)} numbers"
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
#ar=[]
#File.open("matrix1.txt") do |f|
	#f.each { |line| ar << line.split.map {|num| num.to_f} unless /^[fd]/ === line}
#end
#print ar, "\n"
words = %w(how much wood would a wood chuck chuck)
words.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
# {"how"=>1, "much"=>1, "wood"=>2, "could"=>1, "a"=>1, "chuck"=>2}

class Hash
	alias square_braces []
	def [] (key)
		puts "Hash::[](#{key})"
		if key.class == "String".class
			self.update(key => {}) unless self.square_braces(key)
		end
		square_braces(key)
	end
	alias assignment_braces []=
	def []= (key, value)
		puts "Hash::[]=(#{key}, #{value})"
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
a = {}
a["192.168.0.1"]["/robots.txt"]["404"] += 1
a["192.168.0.1"]["/robots.txt"]["404"] += 1
a["192.168.0.1"]["/robots.txt"]["404"] += 1
a["192.168.0.1"]["/robots.txt"]["404"] += 1
a["255.255.255.0"]["/robots.txt"]["404"] += 1
a["255.255.255.0"]["/forum"]["300"] += 1
a["255.255.255.0"]["sum"] += 1

puts a

	#def access(*keys_sequence)
		#return nil if keys_sequence.is_empty?
		#hsh = self
		#keys_sequence[0..-2].each{ |key|
			#hsh.update(key => {}) unless hsh[key]
			#hsh = hsh[key]
		#}
		#hsh[keys_sequence.last]
	#end
