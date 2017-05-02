require 'sinatra'
require_relative '../tools'

def nested_hash
  {
    "Counter 1" => 30,
    "Counter 2" => 40,
    "Distribution 1" => 
	{
	  "1" => 1,
	  "2" => 2,
	  :total => 3,
	  :distinct => 2
	},
	:total => 100
  }
end

configure do
  helpers Helpers
end

get '/' do
  @hsh = nested_hash
  slim Tools.abs_path('src/tests/views/main.slim')
end