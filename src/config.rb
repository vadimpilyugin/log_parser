require 'yaml/store'
require_relative 'tools'

class Config
  @@config = nil
  @@filename = nil

  def initialize(hsh)
    filename = hsh[:filename]
    return @@config if @@config != nil && filename == @@filename
    @@filename = filename
    Printer::assert(Tools.file_exists?(filename), "Config file does not exist!", "Filename":@@filename)
    @@config = YAML.load_file Tools.abs_path(filename)
  end

  def Config.[] (arg)
    return @@config[arg]
  end

  def Config.hsh
    return @@config
  end
end

Config.new filename: "default.conf/config.yml"
