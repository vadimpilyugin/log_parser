require 'fileutils'
require 'colorize'

class Tools
  @@homedir = nil

  def initialize
    @@homedir = unshift(File.expand_path("../", __FILE__))
  end
  def Tools.rprint(str)
    puts str.red
    printf "from #{caller[0].light_white}\n"
    raise str
  end
public
  def Tools.abs_path(path)
    @@homedir+path
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
    printf "Checking if file exists(#{Tools.abs_path(filename)}): "
    s = File.exists? Tools.abs_path(filename)
    puts s ? "File exists" : "File does not exist"
    return s
  end

  def Tools.mkdir(path)
    printf "Created folder: "
    puts @@homedir+path
    Dir.mkdir(@@homedir+path) if !Dir.exists? @@homedir+path
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
  def Tools.assert(cond, str = "No description")
    # rprint "Assertion::Not a boolean value: #{cond}" if cond != true && cond != false && cond != nil
    rprint "Assertion::Not a string: #{str}" if str.class != String
    if !cond
      printf "-----\n".light_white
      printf "Assertion failed: ".red
      printf "from #{caller[0].light_white}:\n"
      printf "\t#{str}\n"
      printf "-----\n".light_white
      printf "\n"
      raise str    
    end
  end
end

# class Chdir
#   @@chdir = nil
# public
#   def Chdir.chdir()
#     if @@chdir == nil
#       Dir.chdir(File.expand_path("../../", __FILE__)) # переходим в корень проекта
#       @@chdir = Dir.pwd
#     else
#       return
#     end
#   end
# end

Tools.new