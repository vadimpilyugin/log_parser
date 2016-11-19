gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require_relative "../parser.rb"


class TestParser < Minitest::Test
  def setup
    @parser = Parser.new(filename: "logs/access-test_log")
  end

  def test_output
	@parser.parse!
	@parser.table.each_with_index{ |entry, i|
		printf "##{i})\tFilename = #{entry[0]}\n"
		printf "\tLine No = #{entry[1]}\n"
		printf "\tData:\n"
		entry[2].each_pair{ |k, v|
			printf "\t\t#{k} = #{v}\n"
		}
		printf "\tMeta:\n"
		entry[3].each_pair{ |k, v|
			printf "\t\t#{k} = #{v}\n"
		}
		
	}
  end
end

