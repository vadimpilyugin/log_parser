require 'sinatra'

configure do
  set :port, 8888
  set :bind, "0.0.0.0"
end

require_relative 'bar.rb'
