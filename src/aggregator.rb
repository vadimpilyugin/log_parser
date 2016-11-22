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

  attr_accessor :lines

  # def aggregate_by_field(field, keys_hash = {})
  # 	if keys_hash != {}
  # 	  return @lines.all(datas: keys_hash).datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
  # 	else
  # 	  return @lines.all.datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
  # 	end
  # end

  def hash_cnt(cnt)
    if cnt > 0
      Hash.new {|hash, key| hash[key] = hash_cnt(cnt-1)}
    else
      0
    end
  end

  def hash_inc(hash, *args)
    hsh = hash
    args.flatten!
    args[0..-2].each do |arg|
      hsh = hsh[arg]
    end
    hsh[args.last]+=1
  end

public

  def reset
    @lines = Database::Logline.all
    return self
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

  def aggregate_by_keys(*keys)
  	return if keys == nil || keys.size == 0
  	@keys = keys
    @result = hash_cnt(keys.size)
    Database::Logline.transaction do |t|
      @lines.each do |line|
        puts "Next line"
        hash_inc(@result, keys.map {|e| line[e]})
      end
    end
    if keys.size == 1
      @result = @result.sort{|a, b| b[1] <=> a[1]}.to_h
    elsif keys.size == 2
      @result.each_pair do |k,v|
        @result[k] = v.sort{|a, b| b[1] <=> a[1]}.to_h
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
