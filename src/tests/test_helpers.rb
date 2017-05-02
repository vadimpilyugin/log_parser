gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require 'pp'

require_relative "../helpers"
require_relative "../config"
require_relative "../tools"

class HelperClass
  include Helpers
end

class TestParser < Minitest::Test
  def setup
  	@helper = HelperClass.new()
  end
  def test_recursive_hash_simple
    hsh = {
      "Counter 1" => 30,
      "Counter 2" => 40
    }
    puts @helper.recursive_hash(hsh)
  end
  def test_recursive_hash_medium
    hsh = {
      "Counter 1" => 30,
      "Counter 2" => 40,
      "Distribution 1" => {
        "1" => 1,
        "2" => 2,
        :total => 3,
        :distinct => 2
      }
    }
    puts @helper.recursive_hash(hsh)
  end
  	
end

