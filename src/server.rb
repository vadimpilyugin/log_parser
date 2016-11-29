require 'sinatra'
require 'slim'
require 'stringio'

require_relative 'parser'
require_relative 'output'

p = Parser::Parser.new filename: "logs/access.log"

io = StringIO.new
out = Output.new ostream: io
out.out_entry p.parse!.table[10], 10
puts io.empty?

Dir.chdir(File.expand_path("../../", __FILE__))

get '/' do 
  @items = {"thing1" => "name1", "thing2" => "name2"}
  @table = p.parse!.table
  slim :template1 do
    puts io.gets.class
    io.gets
  end
end

get 'favicon.ico' do
  status 404
  "Something wrong! Try to type URL correctly or call to UFO."
end
