require 'sinatra'
require 'slim'
require 'stringio'

require_relative 'parser'
require_relative 'output'

p = Parser::Parser.new filename: "logs/access.log"
p.parse!

Chdir.chdir

class Stat
  def to_slim
  	"<p><h3>This string shows up</h3></p>"
  end
end

get '/' do
  @str = "Hello, World!\n"
  @test = {"sshd" => {"Count" => "256", "Flag" => "Yes"}, "apache" => {"Count" => "240"}}
  @st = Stat.new
  slim :helloworld
end

get '/table' do
  @table = p.table
  puts @table.class
  slim :template1
end
