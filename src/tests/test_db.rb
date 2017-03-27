gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require 'pp'
require_relative "../db"
require_relative "../parser"
require_relative "../config"
require_relative "../tools"

class TestSaving < Minitest::Test
  def test_saving
  	table = Parser.parse!(Tools.abs_path('src/tests/files/syslog_test'), 'newserv')
  	Database.init('src/tests/files/syslog_test.sqlite3')
  	Database.save!(table)
  end
  def test_saving_big_log
  	table = Parser.parse!(Tools.abs_path('src/tests/files/daemon.log'), 'newserv')
  	Database.init(Tools.abs_path('src/tests/files/daemon.sqlite3'))
  	Database.save!(table)
  end
end