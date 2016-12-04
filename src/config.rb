require 'yaml/store'

class Config
  @@config = nil
  @@filename = nil

  def initialize(filename = "")
    filename = 'default.conf/config.yml' if filename == ""
    return @@config if @@config && filename == @@filename
    @@filename = filename
    Chdir.chdir
    throw "Config file does not exist! (#{filename})" unless File.exists? filename
    @@config = YAML.load_file filename
  end

  def Config.[] (arg)
    return @@config[arg]
  end

  def Config.hsh
    return @@config
  end
end

class Chdir
  @@chdir = nil
public
  def Chdir.chdir()
    if @@chdir == nil
      Dir.chdir(File.expand_path("../../", __FILE__)) # переходим в корень проекта
      @@chdir = Dir.pwd
    else
      return
    end
  end
end