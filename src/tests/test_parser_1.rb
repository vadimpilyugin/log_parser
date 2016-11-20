gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require_relative "../parser.rb"


class TestParser < Minitest::Test
  def setup
    @parser = Parser::Parser.new(filename: "logs/auth.log", error_log: "/tmp/parser", services_dir: "default.conf/services")
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

