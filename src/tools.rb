require 'fileutils'
require_relative 'printer'

# Class that contains some helpful methods
class Tools
  @homedir = File.expand_path("../../", __FILE__)
  Printer::debug(msg:"Root directory of the project was set to #{@homedir}", who:"Tools")
public
  # Get absolute path
  # @param [String] path relative path that begins in the project's home directory
  # @return [String] absolute path
  def Tools.abs_path(path)
    if path[0] == '/'
      path
    else
      @homedir[-1] == '/' ? @homedir+path : @homedir+'/'+path
    end
  end

  # Get the project's home directory
  # @return [String] home directory of the project
  def Tools.homedir
    @homedir
  end
end
