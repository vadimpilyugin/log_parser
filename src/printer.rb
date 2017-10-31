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

  LOG_EVERY_N = 1

  class Chars
    DELIM = ": "
    CR = "\r"
    LF = "\n"
    TAB = "\t"
  end

  class Messages
    DEBUG = 'Debug'
    ASSERT = 'Assertion failed'
    ERROR = 'Error'
    FATAL = 'Fatal error'
    NOTE = 'Note'
    EMPTY = ''
  end

  class Colors
    GREEN = 'green'
    WHITE = 'white'
    RED = 'red'
    YELLOW = 'yellow'
  end

  def self.generic_print(
    who:, msg:, in_place:false, params:{}, \
    who_color:Colors::WHITE, msg_color:Colors::WHITE, delim:Chars::DELIM,
    log_every_n: false, line_no: 0)

    if !log_every_n || log_every_n && line_no % LOG_EVERY_N == 0
      printf(who.to_s.public_send(who_color)+\
        Chars::DELIM+msg.to_s.public_send(msg_color)
      )
      if in_place
        printf Chars::CR
      else
        printf Chars::LF
        params.each_pair do |s1,s2|
          printf Chars::TAB+s1.to_s.perc_esc.white+\
            Chars::DELIM+s2.to_s.perc_esc.white+Chars::LF
        end
      end
    end
  end

  def self.debug(who: Messages::DEBUG, msg: Messages::EMPTY, \
    params: {}, in_place:false, log_every_n: false, line_no: 0)

    generic_print(
      msg:msg,
      who:who,
      in_place:in_place,
      log_every_n: log_every_n,
      line_no: line_no,
      params:params,
      who_color: Colors::GREEN,
      msg_color: Colors::WHITE
    )
  end

  def self.assert(expr:, who: Messages::ASSERT, msg: Messages::EMPTY, params: {})
    if !expr
      generic_print(
        msg:msg,
        who:who,
        in_place:false,
        params:params,
        who_color: Colors::RED,
        msg_color: Colors::WHITE
      )
      raise Error::AssertError.new(Messages::ASSERT)
    end
  end

  def self.note(who: Messages::NOTE, msg: Messages::EMPTY, \
    params: {}, in_place:false, log_every_n: false, line_no: 0)

    generic_print(
      msg:msg,
      who:who,
      in_place:in_place,
      log_every_n: log_every_n,
      line_no: line_no,
      params:params,
      who_color: Colors::YELLOW,
      msg_color: Colors::WHITE
    )
  end

  def self.error(who: Messages::ERROR, msg: Messages::EMPTY, params: {})

    generic_print(
      msg:msg,
      who:who,
      in_place:false,
      params:params,
      who_color: Colors::RED,
      msg_color: Colors::WHITE
    )
  end

  def self.fatal(who: Messages::FATAL, msg: Messages::EMPTY, params: {})

    generic_print(
      msg:msg,
      who:who,
      in_place:false,
      params:params,
      who_color: Colors::RED,
      msg_color: Colors::WHITE
    )
    raise Error::FatalError.new(Messages::FATAL)
  end
end
