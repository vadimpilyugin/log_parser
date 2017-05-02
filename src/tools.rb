require 'fileutils'
require 'pp'

class MatchData
  def to_h
    a = self.captures.delete_if {|e| e == nil}
    self.names.zip(a).to_h
  end
end

class String 
  # @private
  def colorize(i)
    return "\x1b[1;#{i}m#{self}" # \x1b[0m"
  end
  # When printed, sets the output stream color to red
  # @return [String] output same string with control characters
  def red
    return colorize(31)
  end
  # When printed, sets the output stream color to green
  # @return [String] output same string with control characters
  def green
    return colorize(32)
  end
  # When printed, sets the output stream color to yellow
  # @return [String] output same string with control characters
  def yellow
    return colorize(33)
  end
  # When printed, sets the output stream color to white
  # @return [String] output same string with control characters
  def white
    return colorize(37)
  end
  # Escape all % signs
  def perc_esc
    self.index('%') ? self.gsub('%','%%') : self
  end
end

# @private
class Hash
  # @private
  def my_pp
    self.each_pair do |s1,s2|
      # s1 = first.to_s.index('%') ? first.to_s.gsub!('%','%%') : first.to_s 
      # s2 = second.to_s.index('%') ? second.to_s.gsub!('%','%%') : second.to_s
      printf "\t#{s1.to_s.perc_esc.white}:  #{s2.to_s.perc_esc.white}\n"
    end
  end
end

# Namespace for project's own Exception classes
module Error
  # Any error
  class Error<RuntimeError
  end
  # Fatal error exception
  class FatalError<Error
  end
  # Assertion failed exception
  class AssertError<Error
  end
  # File not found exception
  class FileNotFoundError<Error
  end
end

# Class used for printing debug messages. Also used for checking assertions
# 
class Printer
  # @attr [String] debug_msg_color Sets the color of debug messages
  # @attr [String] note_msg_color Sets the color of note messages
  # @attr [String] assert_msg_color Sets the color of assert messages
  # @attr [String] error_msg_color Sets the color of error messages
  # @attr [String] fatal_msg_color Sets the color of fatal messages
  # @attr [String] msg_color Sets the color of messages

  @debug_msg_color = 'green'
  @assert_msg_color = 'red'
  @error_msg_color = 'red'
  @fatal_msg_color = 'red'
  @note_msg_color = 'yellow'
  @msg_color = 'white'

  # @attr [String] debug_msg Default debug message
  # @attr [String] note_msg Default note message
  # @attr [String] assert_msg Default assert message
  # @attr [String] error_msg Default error message
  # @attr [String] fatal_msg Default fatal message

  @debug_msg = "Debug"
  @assert_msg = "Assertion failed"
  @error_msg = "Error"
  @fatal_msg = "Fatal error"
  @note_msg = "Note"

  # Print a debug message
  # @param [Hash] hsh options to print message with
  # @option hsh [String] :who Text before the :
  # @option hsh [String] :msg The message itself (text after the :)
  # @option hsh [bool] :in_place If True, then \r instead of \n is printed
  # @option hsh [Hash] :params Any additional information
  # @return [void]
  def Printer.debug(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @debug_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@debug_msg_color)

    in_place = hsh[:in_place] ? hsh[:in_place] : false
    if in_place
      printf "#{who}: #{msg}\r"
    else
      printf "#{who}: #{msg}\n"
      if hsh[:params]
        hsh[:params].my_pp
      end
    end
  end

  # Check assertion and throw an exception if assertion had failed
  # @param [Hash] hsh options to print message with
  # @option hsh [String] :who Text before the :
  # @option hsh [String] :msg The message itself (text after the :)
  # @option hsh [bool] :expr If false, then the exception will be raised
  # @option hsh [Hash] :params Any additional information
  # @return [void]
  # @raise [Error::AssertionError]
  def Printer.assert(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @assert_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@assert_msg_color)

    if !hsh[:expr]
      printf "#{who}: #{msg}\n"
      if hsh[:params]
        hsh[:params].my_pp
      end
      raise Error::AssertError.new("Assertion failed")
    end
  end
  # Print a error message
  # @param [Hash] hsh options to print message with
  # @option hsh [String] :who Text before the :
  # @option hsh [String] :msg The message itself (text after the :)
  # @option hsh [Hash] :params Any additional information
  # @return [void]
  def Printer.error(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @error_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@error_msg_color)

    printf "#{who}: #{msg}\n"
    if hsh[:params]
      hsh[:params].my_pp
    end
  end
  # Print a message and raise an exception
  # @param [Hash] hsh options to print message with
  # @option hsh [String] :who Text before the :
  # @option hsh [String] :msg The message itself (text after the :)
  # @option hsh [Hash] :params Any additional information
  # @return [void]
  # @raise [Error::FatalError]
  def Printer.fatal(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @fatal_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@fatal_msg_color)
    printf "#{who}: #{msg}\n"
    if hsh[:params]
      hsh[:params].my_pp
    end
    raise Error::FatalError.new("Fatal error")
  end
  # You might want to use this method to indicate that something strange is happening
  # @param [Hash] hsh options to print message with
  # @option hsh [String] :who Text before the :
  # @option hsh [String] :msg The message itself (text after the :)
  # @option hsh [Hash] :params Any additional information
  # @option hsh [bool] :expr If true, then print the message
  # @option hsh [bool] :in_place If True, then \r instead of \n is printed
  # @return [void]
  def Printer.note(hsh)
    msg = hsh[:msg] ? hsh[:msg] : ""
    who = hsh[:who] ? hsh[:who] : @note_msg
    msg = msg.to_s.perc_esc.send(@msg_color)
    who = who.to_s.perc_esc.send(@note_msg_color)

    in_place = hsh[:in_place] ? hsh[:in_place] : false
    expr = hsh[:expr] == nil ? true : hsh[:expr]
    if expr
      if in_place
        printf "#{who}: #{msg}\r"
      else
        printf "#{who}: #{msg}\n"
      end
      if hsh[:params]
        hsh[:params].my_pp
      end
    end
  end
end

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
      return path
    else
      return @homedir[-1] == '/' ? @homedir+path : @homedir+'/'+path
    end
  end

  # Get the project's home directory
  # @return [String] home directory of the project
  def Tools.homedir
    @homedir
  end
end
