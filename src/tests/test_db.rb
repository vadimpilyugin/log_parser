gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require 'pp'
require_relative "../db"
require_relative "../parser"
require_relative "../config"
require_relative "../tools"

class TestSaving < Minitest::Test
  def setup
    @filename = Tools.abs_path('src/tests/files/auth_test')
    @table = Parser.parse!(@filename, 'newserv')
  end
  def test_save_load
    filename = Tools.abs_path('src/tests/files/auth_test.sqlite3')
    Database.save!(filename, @table)
    table = Database.load(filename)
    for i in 0...table.size
      if table[i] != @table[i]
        puts "==============="
        printf "Было : #{@table[i]}\n"
        printf "Стало: #{table[i]}\n"
      end
    end
    assert table == @table
  end
  def test_save_load_empty
    table = []
    filename = Tools.abs_path('src/tests/files/test.sqlite3')
    assert Database.save!(filename, table), "Saving was unsuccessful"
    table = Database.load(filename)
    assert table == []
  end
end