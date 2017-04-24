require 'yaml/store'
require_relative 'tools'
require 'parseconfig'

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
 
  # @param [Hash] hsh options for config
  # @option hsh [String] :filename relative path to config file. Starts at the home directory of the project
  def initialize(hsh)
    filename = hsh[:filename]
    return @config if @config != nil && filename == @filename
    @filename = filename
    Printer::assert(expr:File.exists?(Tools.abs_path(filename)),who:"Config", msg:"Config file does not exist!", params:{"Filename":@filename})
    @config = ParseConfig.new Tools.abs_path(filename)
    Printer::assert(expr:@config, msg:"Config file is not loaded or nil")
    Printer::debug(msg:"Config file was found at #{@filename}",who:"Preparations")

  end

  # Get all options that belong to the specified section
  # @param [String] arg name of the section
  # @return [Hash, nil] all options that belong to the section. nil if there is no such section
  #
  def Config.[] (arg)
    return @config[arg]
  end
end

Config.new filename: "default.conf/config.cfg"
