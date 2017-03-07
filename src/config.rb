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
    Printer::assert(Tools.file_exists?(filename), "Config file does not exist!", "Filename":@@filename)
    @@config = ParseConfig.new Tools.abs_path(filename)
    Printer::assert(@@config, "Config file is not loaded or nil")
    Printer::debug("Config file was found at #{@@filename}",debug_msg:"Preparations")
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
