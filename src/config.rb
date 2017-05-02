require 'yaml/store'
require 'parseconfig'
require_relative 'tools'

# Class representing configuration file
# 
# The format of the configuration file is:
# {
#   [SECTION 1]
#   opt_1 = <some value>
#   opt_2 = <some value>
#   [SECTION 2]
#   opt_3 = <some value>
#   opt_4 = <some value>
# }
class Config
  @config = nil
  @filename = nil
 
  # Load configuration from file
  # @param [Hash] hsh options for config
  # @option hsh [String] filename relative path to config file. Starts at the home directory of the project
  # @raise [Error] if config file is in bad format or does not exist
  def Config.load(hsh)
    if File.exists? Tools.abs_path(hsh[:filename])
      @filename = hsh[:filename]
      Printer::debug(msg:"Config file was found at #{@filename}",who:"Config")
      @config = ParseConfig.new Tools.abs_path(@filename)
      if @config.class == NilClass
        Printer::error(msg:"Config file was not loaded!")
        raise Error::Error("Config file was not loaded")
      end
    else
      Printer::error(msg:"File does not exist!", params:{"Filename" => hsh[:filename]})
      raise Error::FileNotFoundError(hsh[:filename])
    end
  end

  # Get all options that belong to the specified section
  # @param [String] arg name of the section
  # @return [Hash, nil] all options in that section. nil if there is no such section
  # @raise [AssertError] if config is not loaded
  def Config.[] (arg)
    Printer::assert(expr:@config.class!=NilClass, msg:"Trying to use config when it's not loaded!")
    return @config[arg]
  end
end

Config.load filename: "default.conf/config.cfg"
