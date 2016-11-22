gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require "yaml"
require_relative "../config"

require_relative "../aggregator.rb"

class TestReport < Minitest::Test
	
	Config.load!
	def setup
		@a = Aggregator::Aggregator.new
	end
	
	def test_report
		@a.select(:metas => {:name => "service", :value => "sshd"}).aggregate_by_keys("user-ip", "user-port").save("report/report.yml")
	end
	
	def test_aggregate_by_field
		skip "finish this one"
		@a.select(metas: {:service => "sshd"})
	end
end
