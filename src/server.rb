require_relative 'tools'

# Пусть он вернет в href id записи в своей таблице
# Тогда при обращении по данному id выдать то, что записано в таблице
class Reference
@@ip = "127.0.0.1"
@@table = []

public
  def Reference.href(hsh)
    Tools.assert hsh.keys.size <= 3, "Too many keys #{hsh.keys}"
    Tools.assert ([:select, :distrib, :text] - hsh.keys).empty?, "Unknown key(s) #{[:select, :distrib, :text] - hsh.keys}"
    Tools.assert hsh[:distrib].class == Array, "Keys are not in form of array"
    
    id = @@table.size
    s = "<a href=\"#{@@ip}/id/#{id}\">#{hsh[:text]}</a>"
    @@table << [id, hsh]
    return s
  end
  def Reference.[] (line)
    return @@table[line]
  end
end

# Simple class to represent an environment
# class Env
# attr_accessor :name
# def initialize
# @string = "Hello, World!"
# end
# end

# scope = Env.new
# scope.name = "test this layout"

# layout =<<EOS
# h1 Hello
# .content
# = yield
# EOS

# contents =<<EOS
# = name
# EOS

# layout = Slim::Template.new { layout }
# content = Slim::Template.new { contents }.render(scope)

# puts layout.render{ content }

# get '/test' do
# #layout.render{ content }
# "---\n127.0.0.1:\n  24: 2\n  22: 3\n255.255.255.0:\n  22: 4\n  80: 6\n"
# end
