require 'yaml/store'
require_relative 'tools'
require 'parseconfig'

class Config
  @@config = nil
  @@filename = nil

  def initialize(hsh)
    filename = hsh[:filename]
    return @@config if @@config != nil && filename == @@filename
    @@filename = filename
    Printer::assert(expr:Tools.file_exists?(filename),who:"Config", msg:"Config file does not exist!", params:{"Filename":@@filename})
    @@config = ParseConfig.new Tools.abs_path(filename)
    Printer::assert(expr:@@config, msg:"Config file is not loaded or nil")
    Printer::debug(msg:"Config file was found at #{@@filename}",who:"Preparations")
    # @@config = YAML.load_file Tools.abs_path(filename)

  end

  def Config.[] (arg)
    return @@config[arg]
  end

  # def Config.hsh
  #   return @@config
  # end
end

Config.new filename: "default.conf/config.cfg"
