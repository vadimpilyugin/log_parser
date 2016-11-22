require_relative "db.rb"
require "yaml/store"

module Aggregator
class Aggregator

  def initialize(filename = Config["aggregator"]["database_file"])
    raise "Database file not found: #{filename}" unless File.exists? filename
    Database::Database.new filename: filename
    @lines = Database::Logline.all
    @max = 15
  end

  # def aggregate_by_field(field, keys_hash = {})
  # 	if keys_hash != {}
  # 	  return @lines.all(datas: keys_hash).datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
  # 	else
  # 	  return @lines.all.datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
  # 	end
  # end

public

  def reset
    @lines = Database::Logline.all
  end

  def select(keys_hash)
    return @lines if keys_hash.empty?
  	keys_hash.each_key {|k| raise "#{k} is not a symbol" if k.class != Symbol}
    query_list = []
    keys_hash.each_pair do |k,v|
      return @lines if v.empty?
      v.each_pair do |k1,v1|
        query_list << {k => {:name => k1, :value => v1}}
      end
    end
    query_list.each do |query|
      @lines = @lines.all query
    end
    return @lines
  end

  def aggregate_by_field(field, keys_hash = {})
    lines = @lines.clone
    select(keys_hash).datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
  end

  def aggregate_by_keys(*keys)
  	return if keys == nil || keys.size == 0
  	if keys.size > 3
  	  printf "Max aggregation keys = 3\n"
  	  return nil
  	end

  	@keys = keys
  	@result = aggregate_by_field(keys[0]) 
  	return @result if keys.size == 1

  	@result.each_key do |k|
  	  @result[k] = aggregate_by_field(keys[1], {:datas => {keys[0] => k}})
  	end
  	return @result if keys.size == 2

  	@result.each_key do |k|
  	  v.each_key do |k1|
  	    v[k1] = aggregate_by_field(keys[2], {:datas => {keys[0] => k, keys[1] => k1}})
  	  end
  	end
  	return @result
  end

  def save(filename = Config["aggregator"]["report_file"])
  	Dir.mkdir("report", 0777) unless Dir.exists? "report"
  	File.delete filename if File.exists? filename
  	store = YAML::Store.new filename
  	name = ""
  	@keys.each {|e| name << e.upcase << " - "}
  	name[-3..-1] = ""
  	name << " DISTRIBUTION"
  	store.transaction do
  	  store["Report Name"] = name
  	  store["Result"] = @result
  	end	
  end

  def show_report(filename = Config["aggregator"]["report_file"])
    raise "Report file does not exist at #{filename}" unless File.exists? filename
    file = YAML.load_file filename
    printf "#{file.to_yaml}\n"
  end
end
end
