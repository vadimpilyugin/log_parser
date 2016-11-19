gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../db.rb"
require_relative "../parser.rb"

class TestSaving < Minitest::Test
	@db = Database::Database.new(filename: "archive/test.sqlite3")
	#@db.drop
	#@p = Parser.new(filename: "logs/access-test_log")
	#@db.save(@p.parse!.table)

	def setup
		# puts "Next test"
	end

	def test_prime_key
		a = Database::Logline.all.first
		puts a.class
		l = Database::Logline.first filename: "logs/access-test_log", line: 1
		puts l.datas.class
	end

	def test_looking
		l = Database::Logline.first(Database::Logline.datas.key_string => "ip", Database::Logline.datas.value => "192.168.0.1")
	end
end