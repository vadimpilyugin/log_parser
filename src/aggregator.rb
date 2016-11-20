require_relative "db.rb"
require "yaml/store"

module Aggregator
class Aggregator
	def initialize(filename)
		@db = Database::Database.new filename: filename
	end
	# def aggregate_by_field(hsh = {})
	# 	field = hsh[:field]
	# 	coll = hsh[:coll]
	# 	if field == nil
	# 		printf "Не указаны ключи для фильтрации. Сбрасываю на ключи по умолчанию\n"
	# 		field = "ip"
	# 	end
	# 	return coll.aggregate(field, :all.count).sort{|a, b| b[1] <=> a[1]}
	# end

	# def aggregate_by_two_fields(hsh = {})
	# 	key = hsh[:key]																# агрегация проводится по двум полям
	# 	sec_key = hsh[:sec_key]														# 
	# 	if key == nil || sec_key == nil
	# 		printf "Не указаны ключи для фильтрации. Сбрасываю на ключи по умолчанию\n"
	# 		key = "ip"
	# 		sec_key = "path"
	# 	end
	# 	count = hsh[:count] ? hsh[:count] : 15										# просто число строк в выдаче																	
	# 	printf "\n\t\t\t#{key.upcase} - #{sec_key.upcase} DISTRIBUTION: \n"
	# 	a = Database::Data.all(name: key)											# выбрать все айпишники из базы
	# 	a = aggregate_by_field(coll: a, field: :value)								# просуммировать по значениям
	# 	count.times do |i|															# для первых нескольких построить распределение
	# 		printf "#{i})\t#{key.upcase}: #{elem = a[i][0]}\n"						
	# 		printf "\t#{sec_key.upcase}s distribution: \n"
	# 		p = Database::Logline.all datas: {:name => key, :value => elem}			# из всех строк выбрать с нужным айпишником
	# 		p = p.datas.all name: sec_key 											# для этих строк взять их данные и выбрать из них пути
	# 		p = aggregate_by_field coll: p, field: :value 							# просуммировать по значениям путей
	# 		print_kv p[0..count].to_h
	# 		printf "\t\tMore #{p.size - count} entries...\n" if p.size > count
	# 	end
	# 	printf "More #{a.size - count} entries...\n" if a.size > count
	# end

	def aggregate_by_field(field, keys_hash = {})
		a = Database::Logline.all
		keys_hash.each_pair do |key, value|
			a = a & Database::Logline.all(datas: {:name => key, :value => value})
		end
		return a.datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}.to_h
	end
public
	def aggregate_by_keys(*keys)
		@result = {}
		max = 15
		if keys.size > 3
			printf "Max aggregation keys = 3\n"
			return
		end
		return if keys == nil || keys.size == 0

		@keys = keys
		@result = aggregate_by_field(keys[0]).to_a[0..(max-1)].to_h
		return self if keys.size == 1

		@result.update(@result) do |k,o,n|
			aggregate_by_field(keys[1], {keys[0] => k})
		end
		return self if keys.size == 2

		@result.update(@result) do |k,o,n|
			o.update(o) do |k1,o1,n1|
				aggregate_by_field(keys[2], {keys[0] => k, keys[1] => k1})
			end
		end
		return self
	end

	def save(filename)
		File.delete filename if File.exists? filename
		store = YAML::Store.new filename
		name = ""
		@keys.each {|e| name << e.upcase << " - "}
		name[-3..-1] = ""
		name << " DISTRIBUTION"
		store.transaction do
			store["Report Name"] = name
			store["Data"] = @result
		end	
	end
end
end
