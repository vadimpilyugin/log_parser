require 'logger'
require 'config'

class CustomFormater < Logger::Formater
  def call(severity, time, progname, msg)
   # msg2str is the internal helper that handles different msgs correctly
    "#{time} - #{msg2str(msg)}"
  end
end

class Printer
  @@logger = nil

  def initialize()
  	if @@logger
  	  return @@logger
  	else
  	  @@logger = Logger.new File.new(Config["overall"]["error_log"])
  	end
  end
public
  def assert(bool_expr, str, hsh)
  	if !bool_expr
  	  