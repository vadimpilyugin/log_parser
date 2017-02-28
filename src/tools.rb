require 'fileutils'
require 'pp'

class Tools
  @@tools = nil
  @@homedir = nil

  def initialize
    return @@tools if @@tools
    @@tools = "New tools"
    @@homedir = File.expand_path("../../", __FILE__)
    Printer::debug("Root directory of the project was set to #{@@homedir}", debug_msg:"Preparations")
  end
  def Tools.rprint(str)
    puts str.red
    printf "from #{caller[0].light_white}\n"
    raise str
  end
public
  def Tools.abs_path(path)
    @@homedir[-1] == '/' ? @@homedir+path : @@homedir+'/'+path
  end
  # def Tools.clean
  # 	`mkdir tmp`
  #   FileUtils.rm_rf(Dir.glob('./tmp/*'))
  # end
  def Tools.chdir
    Dir.chdir(@@homedir)
  end
  def Tools.homedir
    @@homedir
  end
  def Tools.file_exists? (filename)
    # Printer::debug("Checking if file exists", "Filename":filename)
    s = File.exists? Tools.abs_path(filename)
    # Printer::debug(s ? "File exists" : "File does not exist", "Absolute path":Tools.abs_path(filename))
    return s
  end

  def Tools.mkdir(path)
    Printer::debug "Created folder"
    puts @@homedir+path
    Dir.mkdir(@@homedir+path) if !Dir.exists? @@homedir+path
  end

  def Tools.rm(path)
    Printer::debug("Removing file", "Path":path)
    b = Tools.file_exists? path
    File.delete(Tools.abs_path(path)) if b
    Printer::debug(b ? "Successfully removed file" : "File does not exist, so not removed", "Path":path)
  end

  def Tools.load(path)
    Printer::assert(Tools.file_exists?(path), "File does not exist", "Filename":path)
    file = YAML.load_file(path)
    Printer::assert(file != nil, "File is not in YAML format", "Filename":path)
    return file
  end

  # def Tools.assert(hsh)
  #   raise "Assertion::Not a hash" if hsh.class != Hash
  #   raise "Assertion::Empty condition!" if hsh.size == 0
  #   hsh.each_pair do |k, v|
  #     raise "Assertion::Not a string: #{k.inspect}" if k.class != string
  #     raise "Assertion::Not a condition: #{k.inspect} => #{v.inspect}" if v != true || v != false
  #   end
    
  #   if hsh.has_value? false
  #     printf "Assertion failed: from #{caller[0]}:\n"
  #     hsh.each_pair do |k,v|
  #       printf "\t#{k}\n" if v == false       
  #     end
  #   end
  # end
  # def Tools.assert(cond, str = "No description")
  #   # rprint "Assertion::Not a boolean value: #{cond}" if cond != true && cond != false && cond != nil
  #   rprint "Assertion::Not a string: #{str}" if str.class != String
  #   if !cond
  #     printf "-----\n".light_white
  #     printf "Assertion failed: ".red
  #     printf "from #{caller[0].light_white}:\n"
  #     printf "\t#{str}\n"
  #     printf "-----\n".light_white
  #     printf "\n"
  #     raise str    
  #   end
end

class String 
  def colorize(i)
    return "\x1b[1;#{i}m#{self}" # \x1b[0m"
  end
  def red
    return colorize(31)
  end
  def green
    return colorize(32)
  end
  def yellow
    return colorize(33)
  end
  def white
    return colorize(37)
  end
  def perc_esc
    self.index('%') ? self.gsub!('%','%%') : self
  end
  # def method_missing(m, *args, &block)
  #   printf "Method missing: #{m}, with args = #{args}\n"
  #   i = case m.to_s
  #     when "red"    then  31
  #     when "green"  then  32
  #     when "yellow" then  33
  #     when "white"  then  37
  #     when "to_ary" then  return 
  #     else 
  #       raise "No color: #{m.to_s}"
  #   end
  #   return colorize(i)
  # end
end

class Hash
  def my_pp
    self.each_pair do |s1,s2|
      # s1 = first.to_s.index('%') ? first.to_s.gsub!('%','%%') : first.to_s 
      # s2 = second.to_s.index('%') ? second.to_s.gsub!('%','%%') : second.to_s
      printf "\t#{s1.to_s.perc_esc.white}:\t#{s2.to_s.perc_esc.white}\n"
    end
  end
end

class Printer
  @@printer = nil
  Debug = true
  Assertion = true
  @@assert_msg = "Assertion failed"
  @@note_msg = "Note"
  @@debug_msg = "Debug"
  def initialize
    @@printer ? return : @@printer = 'New printer'
  end
public
  def self.assert(bool_expr, str, params = {})
    if !bool_expr and Assertion
      msg = @@assert_msg
      if params[:msg]
        msg = params[:msg]
        params.delete(:msg)
      end
      printf "#{msg.to_s.perc_esc.red}: #{str.to_s.perc_esc.white}\n"
      params.my_pp
      # puts caller
      exit 1
      raise "Assertion failed"
    end
  end
  def self.refute(bool_expr, str, params = {})
    self.assert(!bool_expr, str, params)
  end
  def self.note(bool_expr, str, params = {})
    if bool_expr
      msg = @@note_msg
      if params[:msg]
        msg = params[:msg]
        params.delete(:msg)
      end
      printf "#{msg.to_s.perc_esc.yellow}: #{str.to_s.perc_esc.white}\n"
      params.my_pp
    end
  end
  def self.debug(str, params = {})
    msg = @@debug_msg
    if params[:debug_msg]
      msg = params[:debug_msg]
      params.delete(:debug_msg)
    end
    if params.has_key?(:in_place) && params[:in_place] == 1234
      printf "#{msg.to_s.perc_esc.green}: #{str.to_s.perc_esc.white}\r"
      params.delete(:in_place)
    else
      printf "#{msg.to_s.perc_esc.green}: #{str.to_s.perc_esc.white}\n"
    end
    params.my_pp
  end
end

Tools.new
Printer.new