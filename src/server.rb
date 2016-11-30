require 'sinatra'
require 'slim'
require 'stringio'

require_relative 'parser'
require_relative 'output'

p = Parser::Parser.new filename: "logs/access.log"

io = StringIO.new
out = Output.new ostream: io
out.out_entry p.parse!.table[10], 10
# puts io.empty?

Dir.chdir(File.expand_path("../../", __FILE__))

get '/' do
  @test = {"a" => "apple"}
  slim :helloworld
end

get '/table' do
  @table = p.table
  puts @table.class
  slim :template1
end
