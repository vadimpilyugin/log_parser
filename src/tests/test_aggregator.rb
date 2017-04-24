gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require 'pp'

require_relative "../aggregator"
require_relative "../config"
require_relative "../tools"

class TestParser < Minitest::Test
  def test_simple
    keys = ["user_ip", "path"]
    c = Aggregator.sql_group_by keys
    Printer::debug(msg:"Must be on screen")
    puts c.size
 #    assert Logline.first(:id => 14).data_at("id") == 14, "data_at failed"
	# pp Logline.first(service:"sshd").to_h #["path"].inspect#.data_at("path")
	# lines = Logline.all(:id.lt => 100).map {|line| line.id}
	
  end
end

