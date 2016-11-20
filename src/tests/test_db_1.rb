gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require "yaml"

require_relative "../db.rb"
require_relative "../parser.rb"

class TestSaving < Minitest::Test
	@db = Database::Database.new(filename: "archive/access.sqlite3", drop: false)
	#@p = Parser.new(filename: "logs/access-big_log")
	#@db.save(@p.parse!.table)

	def setup
		# puts "Next test"
	end

	def print_line(hsh = {})
		line = hsh[:line]
		i = hsh[:i]
		printf "#{i})\tFilename: #{line.filename}\n"
		printf "\tLineNo: #{line.line}\n"
		printf "\tData:\n"
		line.datas.each do |data|
			printf "\t\t#{data.name} = #{data.value}\n"
		end
		printf "\tMeta:\n"
		line.metas.each do |data|
			printf "\t\t#{data.name} = #{data.value}\n"
		end
	end

	def print_coll(table)
		table.each_with_index {|line, i| print_line line: line, i: i}
	end

	def print_kv(hsh = {})
		hsh.each_pair do |k, v|
			printf "\t\t#{k} = #{v}\n"
		end
	end

	def print_datas_coll(datas)
		datas.each_with_index do |elem, i|
			printf "#{i})"
			print_kv(elem.name => elem.value)
		end
	end

	def test_print
		# skip "all works"
		# a = Database::Logline.all.each_with_index do |line, i|
		# 	print_line line: line, i: i
		# end
	end

	def test_first_line
		# skip "all works"
		a = Database::Logline.first line: 1
		assert a
		puts a.datas.class
		# print_line line: a, i: 1
	end

	def test_look_for_local
		# skip "all works"
		a = (Database::Logline.all datas: {:name => "ip", :value => "217.69.133.29"}) & (Database::Logline.all datas: {:name => "code", :value => "404"})
		assert !a.empty? 
		a.each_with_index do | line, i|
			print_line line: line, i: i
		end
	end

	def test_count
		skip "all works"
		key_str = "method"
		a = Database::Data.all name: key_str
		hsh = Hash.new { |hash, key| hash[key] = 0 }
		a.each do |data|
			hsh[data.value] += 1
		end
		puts
		printf "Counting #{key_str.upcase}s: \n"
		print_kv hsh
		hsh.keys.each do |key|
			assert_equal Database::Data.all(name: key_str, value: key).size, hsh[key]
		end
	end

	def test_count_if
		skip "todo: finish"
		first_key = "code"
		second_key = "ip"
		hsh = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = 0 } }
		a = Database::Logline.all
		a.each do |record|
			first_val = record.datas.first
			second_val = record.datas.all 
		end
	end

	def test_aggregate_column
		skip "all works"
		key = "code"
		printf "Все возможные коды и их частота: \n" if key == "code"
		# a = Database::Data.all(name: "code").aggregate(:all.count, :fields => [ :value ])
		a = Database::Data.all(name: key).aggregate(:value, :all.count)
		print_kv a.to_h
		#puts Database::Data.count value: "/robots.txt"
		#printf "#{Database::Data.aggregate(:name => "code", :value)}\n"
	end

	def aggregate_by_field(hsh = {})
		field = hsh[:field]
		coll = hsh[:coll]
		return coll.aggregate(field, :all.count).sort{|a, b| b[1] <=> a[1]}
	end


	def test_aggregate_double
		skip "all works"
		key = "ip"
		sec_key = "path"
		count = 15
		printf "\t\t\t#{key.upcase} - #{sec_key.upcase} DISTRIBUTION: \n"
		a = Database::Data.all(name: key)											# выбрать все айпишники из базы
		a = aggregate_by_field(coll: a, field: :value)								# просуммировать по значениям
		count.times do |i|
			printf "#{i})\t#{key.upcase}: #{elem = a[i][0]}\n"						# для первых нескольких построить распределение
			printf "\t#{sec_key.upcase}s distribution: \n"
			p = Database::Logline.all datas: {:name => key, :value => elem}			# из всех строк выбрать с нужным айпишником
			p = p.datas.all name: sec_key 											# для этих строк взять их данные и выбрать из них пути
			p = aggregate_by_field coll: p, field: :value 							# просуммировать по значениям путей
			print_kv p[0..count].to_h
		end
	end

	def test_range
		field = "code"
		printf "#{Database::Data.all(name: field).aggregate(:value)}\n"
	end

	def test_aggregate_by_field
		field = "code"
		keys_hash = {"ip" => "217.69.133.29", "path" => "/ftp/computers/compaq/"}
		a = Database::Logline.all
		keys_hash.each_pair do |key, value|
			a = a & Database::Logline.all(datas: {:name => key, :value => value})
		end
		print_kv a.datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}.to_h
	end

	def aggregate_by_field(field, keys_hash = {})
		a = Database::Logline.all
		count = 15
		keys_hash.each_pair do |key, value|
			a = a & Database::Logline.all(datas: {:name => key, :value => value})
		end
		return a.datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..count-1].to_h
	end

	# alias values_range aggregate_by_field

	def test_aggregate_by_keys
			keys = ["ip", "path", "code", "method"]
			result = aggregate_by_field(keys[0])
			printf "First level:\n"
			printf "#{result.to_yaml}\n"

			result.update(result) do |k,o,n|
				aggregate_by_field(keys[1], {keys[0] => k})
			end
			printf "Second level:\n"
			printf "#{result.to_yaml}\n"

			result.update(result) do |k,o,n|
				o.update(o) do |k1,o1,n1|
					aggregate_by_field(keys[2], {keys[0] => k, keys[1] => k1})
				end
			end
			printf "Third level:\n"
			printf "#{result.to_yaml}\n"

			result.update(result) do |k,o,n|
				o.update(o) do |k1,o1,n1|
					o1.update(o1) do |k2,o2,n2|
						aggregate_by_field(keys[3], {keys[0] => k, keys[1] => k1, keys[2] => k2})
					end
				end
			end
			printf "Fourth level:\n"
			printf "#{result.to_yaml}\n"
		end
end