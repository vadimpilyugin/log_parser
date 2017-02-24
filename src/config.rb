require 'yaml/store'

class Config
  @@config = nil
  @@filename = nil

  def initialize(hsh)
    filename = hsh[:filename]
    return @@config if @@config && filename == @@filename
    @@filename = filename
    Tools.assert Tools.file_exists? filename, "Config file does not exist! (#{filename})" 
    @@config = YAML.load_file filename
    puts "Checking file and directory names: "
    check_all_paths()
  end

  def Config.[] (arg)
    return @@config[arg]
  end

  def Config.hsh
    return @@config
  end
end

Config.new filename: "default.conf/config.yml"
