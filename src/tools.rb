require 'fileutils'
require 'colorize'

class Tools
  def initialize
    Config.new
    Chdir.chdir
  end
  def Tools.rprint(str)
    puts str.red
    printf "from #{caller[0].light_white}\n"
    raise str
  end
public
  def Tools.clean
  	`mkdir tmp`
    FileUtils.rm_rf(Dir.glob('./tmp/*'))
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

