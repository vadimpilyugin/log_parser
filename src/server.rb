require 'sinatra'
require 'slim'
require 'stringio'

require_relative 'parser'
require_relative 'output'

Chdir.chdir
Config.new

report_file = Config["reporter"]["report_file"]
get '/' do
  send_file @report_file
end

# Simple class to represent an environment
# class Env
#   attr_accessor :name
#   def initialize
#     @string = "Hello, World!"
#   end
# end

# scope = Env.new
# scope.name = "test this layout"

# layout =<<EOS
# h1 Hello
# .content
#   = yield
# EOS

# contents =<<EOS
#   = name
# EOS

# layout = Slim::Template.new { layout }
# content = Slim::Template.new { contents }.render(scope)

# puts layout.render{ content }

# get '/test' do
#   #layout.render{ content }
#   "---\n127.0.0.1:\n  24: 2\n  22: 3\n255.255.255.0:\n  22: 4\n  80: 6\n"
# end
