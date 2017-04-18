require 'fileutils'
require 'pp'

class MatchData
  def to_h
    a = self.captures.delete_if {|e| e == nil}
    self.names.zip(a).to_h
  end
end

# Tools.file_exists?(filename) - проверяет, существует ли файл с заданным именем
# filename - путь от корня проекта
# Возвращает true, если файл найден, или false, если не найден

class Tools
  @@tools = nil
  @@homedir = nil

  def initialize
    return @@tools if @@tools
    @@tools = "New tools"
    @@homedir = File.expand_path("../../", __FILE__)
    Printer::debug(msg:"Root directory of the project was set to #{@@homedir}", who:"Preparations")
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
    Printer::assert(expr:Tools.file_exists?("init.rb"), msg:"File does not exist: #{path}")
    file = YAML.load_file(path)
    Printer::assert(expr:(file != nil), msg:"File is not in YAML format: #{path}")
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
    self.index('%') ? self.gsub('%','%%') : self
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
      printf "\t#{s1.to_s.perc_esc.white}:  #{s2.to_s.perc_esc.white}\n"
    end
  end
end

# Printer.debug(hsh) - напечатать отладочное сообщение
# Printer.assert(hsh) - проверить выражение, если не true, то завершить программу и напечатать сообщение
# Printer.error(hsh) - напечатать сообщение и вернуть управление
# Printer.fatal - напечатать и завершить
# Printer.note - то же самое, что error
# Параметры:
# who - от кого пришло сообщение
# msg - само сообщение
# in_place - true/false - переводить ли строку
# expr - true/false - делать что-либо только если значение выражения равно true
# params - Hash - дополнительные параметры

class Printer
  @debug_msg_color = 'green'
  @assert_msg_color = 'red'
  @error_msg_color = 'red'
  @fatal_msg_color = 'red'
  @note_msg_color = 'yellow'
  @msg_color = 'white'

  @debug_msg = "Debug"
  @assert_msg = "Assertion failed"
  @error_msg = "Error"
  @fatal_msg = "Fatal error"
  @note_msg = "Note"

  def Printer.debug(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @debug_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@debug_msg_color)

    in_place = hsh[:in_place] ? hsh[:in_place] : false
    if in_place
      printf "#{who}: #{msg}\r"
    else
      printf "#{who}: #{msg}\n"
    end
    if hsh[:params]
      hsh[:params].my_pp
    end
  end
  def Printer.assert(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @assert_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@assert_msg_color)

    expr = hsh[:expr]
    if !expr
      printf "#{who}: #{msg}\n"
      if hsh[:params]
        hsh[:params].my_pp
      end
      raise "Assertion failed"
    end
  end
  def Printer.error(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @error_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@error_msg_color)

    printf "#{who}: #{msg}\n"
    if hsh[:params]
      hsh[:params].my_pp
    end
  end
  def Printer.fatal(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @fatal_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@fatal_msg_color)
    printf "#{who}: #{msg}\n"
    if hsh[:params]
      hsh[:params].my_pp
    end
    raise "Fatal error"
  end
  def Printer.note(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @note_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@note_msg_color)

    in_place = hsh[:in_place] ? hsh[:in_place] : false
    expr = hsh[:expr] ? hsh[:expr] : true
    if expr
      if in_place
        printf "#{who}: #{msg}\r"
      else
        printf "#{who}: #{msg}\n"
      end
      if hsh[:params]
        hsh[:params].my_pp
      end
    end
  end
end


Tools.new

