require 'yaml/store'

module Config
  # again - it's a singleton, thus implemented as a self-extended module
  extend self

  @_settings = {}
  attr_reader :_settings

  # This is the main point of entry - we call Settings.load! and provide
  # a name of the file to read as it's argument. We can also pass in some
  # options, but at the moment it's being used to allow per-environment
  # overrides in Rails
  def load!(filename = "")
    filename = 'default.conf/config.yml' if filename == ""
    raise "Конфигурационный файл по пути #{filename} не найден!" if !File.exists? filename
    newsets = YAML.load_file(filename)
    @_settings.update(newsets)
  end

  def method_missing(name, *args, &block)
	name = name.to_s
    @_settings[name] ||
    fail(NoMethodError, "unknown configuration root #{name}", caller)
  end

end
