require_relative 'tools'

# Пусть он вернет в href id записи в своей таблице
# Тогда при обращении по данному id выдать то, что записано в таблице
class Reference
@@ip = "127.0.0.1"
@@table = []

public
  def Reference.href(hsh)
    Tools.assert hsh.keys.size <= 3, "Too many keys #{hsh.keys}"
    Tools.assert (hsh.keys - [:select, :distrib, :text]).empty?, "Unknown key(s) #{hsh.keys - [:select, :distrib, :text]}"
    Tools.assert hsh[:distrib] == nil || hsh[:distrib].class == Array, "Keys are not in form of array: #{hsh[:distrib]}"
    # Tools.assert hsh[:title] == nil || hsh[:title].class == String, "A title is in wrong format"
    Tools.assert hsh[:select]["service"] != nil, "Service not specified: #{hsh}"
    
    id = @@table.size
    s = "<a href=\"/id/#{id}\">#{hsh[:text]}</a>"
    @@table << {:id => id, :params => hsh, :page => ""}
    return s
  end
  def Reference.[] (line)
    ref = @@table[line.to_i]
    if ref[:page] == ""
      params = ref[:params]
      s = "<!DOCTYPE html>\n"
      s << "<html>\n"
      s << "<head><title>Detail on #{ref[:id]}</title></head>\n"
      s << "<body>\n<PRE>"
      if params[:distrib] == nil
        s << Reporter::Lines.new(params).to_html
      else
        s << Reporter::Distribution.new(params[:select]["service"], {"Distribution" => "#{params[:distrib]}", "fields" => params[:distrib], "max" => -1}).to_html
      end
      s << "</PRE></body></html>"
      ref[:page] = s
    end
    return ref[:page]
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
