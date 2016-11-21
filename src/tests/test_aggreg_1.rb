gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require "yaml"

require_relative "../aggregator.rb"

class TestReport < Minitest::Test
	
	def setup
		# puts "Next test"
	end
	
	def test_report
		a = Aggregator::Aggregator.new("archive/access.sqlite3")
		a.aggregate_by_keys("ip").save("report/report.yaml")
	end
	
	def test_aggregate_by_field
		a = Aggregator::Aggregator.new("archive/auth_test.sqlite3")
		a.select_where(metas: {:service => "sshd"})
end
