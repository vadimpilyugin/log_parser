require_relative "db"
require_relative "config"
require_relative "tools"

class Aggregator
  # @@aggregator = nil
  # @@filename = nil
  @lines = Logline.all

  # def initialize()
  #   return @@aggregator if @@aggregator
  #   @@aggregator = self
  #   # @@filename = Config["aggregator"]["database_file"]
  #   # Printer::assert(Tools.file_exists?(@@filename), "Database file does not exist", msg:"Aggregator.initialize()")
  #   @lines = Logline.all
  # end
  def Aggregator.hash_cnt(cnt)
    if cnt > 0
      Hash.new {|hash, key| hash[key] = hash_cnt(cnt-1)}
    else
      0
    end
  end
  def self.loglines_ids
    Printer::note(@lines == nil, "Request for loglines_ids when there are no lines")
    return "(0)" if @lines == nil
    str = "("
    @lines.each do |line|
      str << "#{line.id},"
    end
    str[-1] = ")"
    str
  end
  def self.collection(request)
    repository(:default).adapter.select(request)
  end
  def self.sql_group_by(keys)
<<STR
    select d1.value,d2.value,count(*) FROM linedata d1,linedata d2 WHERE
      d1.name = 'user_ip' and
       d2.name = 'path'  and 
      d1.logline_id = d2.logline_id  GROUP BY d1.value, d2.value
    ORDER BY (select count(*) FROM linedata WHERE name = 'user_ip' and value = d1.value) DESC
STR
    request = ""
    if keys.size == 1
      name = keys[0]
      request << "SELECT value as #{name}, count(*) as count FROM linedata WHERE name = #{name} and logline_id IN #{loglines_ids} ORDER BY count(*) DESC"
    else
      request << "SELECT "
      keys.each_with_index do |key,i|
        request << "d#{i+1}.value as #{key},"
      end
      request << "count(*) as count FROM \n"
      keys.each_with_index do |key,i|
        request << "\tlinedata d#{i+1},\n"
      end
      request[-2] = ""
      request << "WHERE \n"
      keys.each_with_index do |key,i|
        request << "\td#{i+1}.name = '#{key}' and \n"
      end
      keys[0..-2].each_with_index do |key,i|
        request << "\td#{i+1}.logline_id = d#{i+2}.logline_id and \n"
      end
      # request[-5..-2] = ""
      request << "d1.logline_id IN #{loglines_ids}\n"
      request << "GROUP BY "
      keys.each_with_index do |key,i|
        request << "d#{i+1}.value,"
      end
      request[-1] = "\n"
      request << "ORDER BY (SELECT count(*) FROM linedata WHERE name = '#{keys[0]}' and value = d1.value) DESC\n"
    end
    request
  end
public
  class << self; attr_accessor(:lines) end

  def self.reset
    @lines = Logline.all
  end

  def self.group_by(keys)
    Printer::assert(keys.class == Array, "Not an array", msg:"Aggregator.group_by()")
    Printer::assert(keys.size != 0, "No keys specified for aggregation", msg:"Aggregator.group_by()")
    keys.each do |key|
      Printer::assert(key.class == String, "Key is not a string", "Key class":key.class, "Key":key)
    end
    request = sql_group_by(keys)
    ar = collection(request)
    return {} if ar.class == nil || ar.empty?
    if keys.size == 1
      result = {}
      ar.each do |struct|
        result.store(*(struct.values))
      end
      return result
    end
    result = hash_cnt(keys.size)
    ar.each do |struct|
      tmp = result
      struct.values[0..-3].each do |value|
        tmp = tmp[value]
      end
      tmp[struct.values[-2]] = struct.values[-1]
    end
    return result
    # pp result.to_a[0..10].to_h
  end
end


# Aggregator.group_by(["user_ip", "path"])

# Aggregator.lines = Aggregator.lines.all(service:"apache")











# class Aggregator

#   @lines = nil
#   @filename = nil
#   @group_by = nil

#   class << self; attr_accessor(:lines, :group_by) end

#   def initialize(filename = "")
#     Config.new
#     Chdir.chdir
#     filename = Config["aggregator"]["database_file"] if filename == ""
#     return if filename == @filename
#     @filename = filename
#     Database::Database.new
#     @lines = Database::Logline.all
#     Tools.assert File.exists?(filename), "Database file not found: #{filename}"
#     Database::Database.new filename: filename
#   end

#   # def aggregate_by_field(field, keys_hash = {})
#   # 	if keys_hash != {}
#   # 	  return @lines.all(datas: keys_hash).datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
#   # 	else
#   # 	  return @lines.all.datas.all(name: field).aggregate(:value, :all.count).sort{|a, b| b[1] <=> a[1]}[0..(@max-1)].to_h
#   # 	end
#   # end



#   def Aggregator.hash_inc(hash,*args)
#     hsh = hash
#     args.flatten!
#     args[0..-2].each do |arg|
#       hsh = hsh[arg]
#     end
#     if @group_by == nil || @group_by != nil && args.last == @group_by
#       hsh[args.last] += 1
#     else
#       hsh["not #{@group_by}"] += 1
#     end
#   end

#   def Aggregator.sum(hsh)
#     if hsh.class == Hash
#       total = 0
#       hsh.each_value do |v|
#         total += sum(v)
#       end
#       return total
#     else
#       return hsh
#     end
#   end

# public

#   def Aggregator.reset
#     @lines = Database::Logline.all
#     @group_by = nil
#     return self
#   end

#   def Aggregator.count
#     return @lines.size
#   end

#   def Aggregator.select(keys_hash)
#     Tools.assert !keys_hash.empty? 
#     keys_hash.each_pair do |k,v|
#       Tools.assert k.class == Symbol, "#{k} is not a symbol in #{keys_hash}"
#       v.each_pair do |k1,v1|
#         Tools.assert k1.class == String, "#{k1} is not a string in #{keys_hash}"
#         Tools.assert v1.class == String, "#{v1} is not a string in #{keys_hash}"
#       end
#     end
#     query_list = []
#     keys_hash.each_pair do |k,v|
#       v.each_pair do |k1,v1|
#         if v1 =~ /^not/
#           v1[0..3] = ""
#           query_list << {k => {:name => k1, :value.not => v1}}
#         else
#           query_list << {k => {:name => k1, :value => v1}}
#         end
#       end
#     end
#     Database::Logline.transaction do |t|
#       query_list.each do |query|
#         @lines = @lines.all query
#       end
#     end
#     return self
#   end

#   def Aggregator.aggregate_by_keys(keys)
#     Tools.assert keys != nil && keys.size != 0
#     keys.each do |key|
#       Tools.assert key.class == String, "Key #{key} is not a String!"
#     end
#     puts "Aggregation by keys: #{keys}"
#     result = hash_cnt(keys.size)
#     @lines.each_with_index do |line,i|
#       puts "Processing line ##{i}"
#       ar = keys.map {|e| line[data: e]}
#       next if ar.include? nil
#       hash_inc(result,ar)
#     end
#     # if keys.size == 1
#     #   result = result.sort{|a, b| b[1] <=> a[1]}.to_h
#     # elsif keys.size == 2
#     #   result.each_pair do |k,v|
#     #     result[k] = v.sort{|a, b| b[1] <=> a[1]}.to_h
#     #   end
#     # end
#     result = result.to_a.sort{|a,b| sum(b[1]) <=> sum(a[1])}.to_h
#     return result
#   end

#   # def save(filename = Config["aggregator"]["report_file"])
#   # 	Dir.mkdir("report", 0777) unless Dir.exists? "report"
#   # 	File.delete filename if File.exists? filename
#   # 	store = YAML::Store.new filename
#   # 	name = ""
#   # 	@keys.each {|e| name << e.upcase << " - "}
#   # 	name[-3..-1] = ""
#   # 	name << " DISTRIBUTION"
#   # 	store.transaction do
#   # 	  store["Report Name"] = name
#   # 	  store["Result"] = @result
#   # 	end
#   #   printf "Result saved in ==> #{filename}\n"
#   # end

#   # def show_report(filename = Config["aggregator"]["report_file"])
#   #   raise "Report file does not exist at #{filename}" unless File.exists? filename
#   #   file = YAML.load_file filename
#   #   printf "#{file.to_yaml}\n"
#   # end
# end
