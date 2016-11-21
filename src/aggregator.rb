require_relative "db.rb"
require "yaml/store"

module Aggregator
class Aggregator
	def initialize(filename)
		raise "Wrong conditions" unless keys.class == Hash
		@db = Database::Database.new filename: filename
		@lines = Database::Logline.all
		@max = 15
	end

	def aggregate_by_field(field, keys_hash)
		return @lines.all(datas: keys_hash).datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
	end
	
public
	def reset
		@lines = Database::Logline.all
	end
	
	def select(keys_hash)
		raise "Wrong conditions" if keys_hash.class != Hash
		keys_hash.each_key {|k| raise "#{k} is not a symbol" if k.class != Symbol}
		@lines = @lines.all keys
	end
		
	def aggregate_by_keys(*keys)
		max = 15

		return if keys == nil || keys.size == 0
		if keys.size > 3
			printf "Max aggregation keys = 3\n"
			return
		end

		@keys = keys
		result = aggregate_by_field(keys[0])
		return self if keys.size == 1

		result.each_pair do |k, v|
			result[k] = aggregate_by_field(keys[1], {keys[0] => k})
		end
		return self if keys.size == 2

		result.each_pair do |k, v|
			v.each_pair do |k1, v1|
				v[k1] = aggregate_by_field(keys[2], {keys[0] => k, keys[1] => k1})
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
