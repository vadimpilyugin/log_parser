gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../config"

  class Hash
  	def ph
      s = ""
  	  self.each_pair do |key, value|
  		  s << "  #{key} = #{value.class == Hash ? value.ph : value}\n"
  	  end
      printf s
      s
  	end
  end

class TestReport < Minitest::Test
  Config.new "default.conf/config.yml"

  def test_entries
  	refute_empty Config.hsh
  	entries = []
  	Config.hsh.each_key do |k|
  		entries << k
  	end
  	refute_empty entries, "config is empty!"
    Config.hsh.ph
  	# entries.each do |e|
  	# 	refute_empty Config[e], "section #{e} is empty!"
  	# 	printf "Config entry #{e}:\n"
  	# 	Config[e].ph
  	# end
  end

  def test_non_existent
  	refute Config["btekvie"]
  	refute Config["parser"]["utpwhc"]
  end
end