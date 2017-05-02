gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require_relative "../config"

class TestReport < Minitest::Test

  def setup
    @entries = ["overall", "parser", "database", "report"]
    @not_entries = ["foo", "bar", "foobar"]
  end

  def test_entries
    @entries.each do |entry_name|
      assert Config[entry_name] != nil, "#{entry_name} section does not exist!"
    end
  end

  def test_non_existent
    @not_entries.each do |entry_name|
      refute Config[entry_name]
    end
    @entries.each do |entry_name|
      @not_entries.each do |not_ename|
        refute Config[entry_name][not_ename]
      end
    end
  end
end