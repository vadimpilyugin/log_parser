require_relative "db"
require_relative "config"
require_relative "tools"
require "yaml/store"

module Aggregator

class Aggregator

  @lines = nil
  @filename = nil
  @group_by = nil

  class << self; attr_accessor(:lines, :group_by) end

  def initialize(filename = "")
    Config.new
    Chdir.chdir
    filename = Config["aggregator"]["database_file"] if filename == ""
    return if filename == @filename
    @filename = filename
    Database::Database.new
    @lines = Database::Logline.all
    Tools.assert File.exists?(filename), "Database file not found: #{filename}"
    Database::Database.new filename: filename
  end

  # def aggregate_by_field(field, keys_hash = {})
  # 	if keys_hash != {}
  # 	  return @lines.all(datas: keys_hash).datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
  # 	else
  # 	  return @lines.all.datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
  # 	end
  # end

def Aggregator.hash_cnt(cnt)
    if cnt > 0
      Hash.new {|hash, key| hash[key] = hash_cnt(cnt-1)}
    else
      0
    end
  end

  def Aggregator.hash_inc(hash,*args)
    hsh = hash
    args.flatten!
    args[0..-2].each do |arg|
      hsh = hsh[arg]
    end
    if @group_by == nil || @group_by != nil && args.last == @group_by
      hsh[args.last] += 1
    else
      hsh["not #{@group_by}"] += 1
    end
  end

  def Aggregator.sum(hsh)
    if hsh.class == Hash
      total = 0
      hsh.each_value do |v|
        total += sum(v)
      end
      return total
    else
      return hsh
    end
  end

public

  def Aggregator.reset
    @lines = Database::Logline.all
    @group_by = nil
    return self
  end

  def Aggregator.count
    return @lines.size
  end

  def Aggregator.select(keys_hash)
    Tools.assert !keys_hash.empty? 
    keys_hash.each_pair do |k,v|
      Tools.assert k.class == Symbol, "#{k} is not a symbol in #{keys_hash}"
      v.each_pair do |k1,v1|
        Tools.assert k1.class == String, "#{k1} is not a string in #{keys_hash}"
        Tools.assert v1.class == String, "#{v1} is not a string in #{keys_hash}"
      end
    end
    query_list = []
    keys_hash.each_pair do |k,v|
      v.each_pair do |k1,v1|
        if v1 =~ /^not/
          v1[0..3] = ""
          query_list << {k => {:name => k1, :value.not => v1}}
        else
          query_list << {k => {:name => k1, :value => v1}}
        end
      end
    end
    Database::Logline.transaction do |t|
      query_list.each do |query|
        @lines = @lines.all query
      end
    end
    return self
  end

  def Aggregator.aggregate_by_keys(keys)
    Tools.assert keys != nil && keys.size != 0
    keys.each do |key|
      Tools.assert key.class == String, "Key #{key} is not a String!"
    end
    puts "Aggregation by keys: #{keys}"
    result = hash_cnt(keys.size)
    Database::Logline.transaction do |t|
      @lines.each_with_index do |line,i|
        puts "Processing line ##{i}"
        ar = keys.map {|e| line[data: e]}
        next if ar.include? nil
        hash_inc(result,ar)
      end
    end
    # if keys.size == 1
    #   result = result.sort{|a, b| b[1] <=> a[1]}.to_h
    # elsif keys.size == 2
    #   result.each_pair do |k,v|
    #     result[k] = v.sort{|a, b| b[1] <=> a[1]}.to_h
    #   end
    # end
    result = result.to_a.sort{|a,b| sum(b[1]) <=> sum(a[1])}.to_h
    return result
  end

  # def save(filename = Config["aggregator"]["report_file"])
  # 	Dir.mkdir("report", 0777) unless Dir.exists? "report"
  # 	File.delete filename if File.exists? filename
  # 	store = YAML::Store.new filename
  # 	name = ""
  # 	@keys.each {|e| name << e.upcase << " - "}
  # 	name[-3..-1] = ""
  # 	name << " DISTRIBUTION"
  # 	store.transaction do
  # 	  store["Report Name"] = name
  # 	  store["Result"] = @result
  # 	end
  #   printf "Result saved in ==> #{filename}\n"
  # end

  # def show_report(filename = Config["aggregator"]["report_file"])
  #   raise "Report file does not exist at #{filename}" unless File.exists? filename
  #   file = YAML.load_file filename
  #   printf "#{file.to_yaml}\n"
  # end
end
end
