gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../parser"
require_relative "../config"

class TestParser < Minitest::Test
  Config.new

  def setup
    @parser = Parser::Parser.new filename: "logs/access.log"
  end

  def test_output
    @parser.parse!
    @parser.table.each_with_index do |entry, i|
      printf "##{i})\tFilename = #{entry[0]}\n"
      printf "\tLine No = #{entry[1]}\n"
      printf "\tData:\n"
      entry[2].each_pair do |k, v|
        printf "\t  #{k} = #{v}\n"
      end
      printf "\tMeta:\n"
      entry[3].each_pair do |k, v|
        printf "\t  #{k} = #{v}\n"
      end
    end
  end
end

