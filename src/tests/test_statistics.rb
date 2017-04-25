gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require 'pp'

require_relative "../statistics"
require_relative "../config"
require_relative "../tools"

class TestParser < Minitest::Test
  def setup
  	@statistics = YAML.load_file Tools.abs_path(Config["report"]["report_config"])
  end
  def test_create_stats
  	Statistics.new(@statistics)
  end
  def test_create_counter
  	stat = [
  	  {
  	  	"Counter" => "Simple counter",
  	  	:server => "newserv",
  	  	:service => "sshd",
  	  	:except => {
  	  		"username" => "autocheck"
  	  	  }
  	  }
  	]
  	st = Statistics.new(stat)
  	logline_true = {
  	  :server => "newserv",
  	  :service => "sshd",
  	  :time => Time.now,
  	  "username" => "not autocheck"
  	}
  	assert st[0].conditions.check logline_true
  	logline_false = {
  	  :server => "newserv",
  	  :service => "sshd",
  	  :time => Time.now,
  	  "username" => "autocheck"
  	}
  	refute st[0].conditions.check logline_false
  end
  def test_distribution
  	table = []
  	table << {:service => "sshd", :server => "newserv"}
  	table << {:service => "apache", :server => "newserv"}
  	table << {:service => "syslog", :server => "newserv"}
  	table << {:service => "nginx", :server => "nginx"}
  	table << {:service => "nginx", :server => "nginx"}
  	table << {:service => "nginx", :server => "nginx"}
  	table << {:service => "sshd", :server => "nginx"}
  	table << {:server => "newserv", :service => "apache", 
  			  "path" => "/", "user_ip" => "127.0.0.1"}
  	table << {:server => "newserv", :service => "apache", 
  			  "path" => "/robots.txt", "user_ip" => "127.0.0.1"}
  	params = [
  	  {
  	  	"Counter" => "Total lines from newserv",
  	  	:server => "newserv",
  	  	:except => {
  	  	  :service => "syslog",
  	  	  "user_ip" => "127.0.0.1"
  	  	}
  	  },
  	  {
  	  	"Distribution" => "Server - Service",
  	  	:keys => [
  	  		:server,
  	  		:service
  	  	  ]
  	  },
  	  {
  	  	"Distribution" => "IP - PATH",
  	  	:keys => [
  	  		"user_ip",
  	  		"path"
  	  	  ]
  	  },
  	  {
  	  	"Distribution" => "Server requests total",
  	  	:keys => [
  	  		:server
  	  	  ]
  	  }
  	]
  	stats = Statistics.new(params)
  	stats.process table
  	assert stats[0].value == 2, "Wrong counter value!"
  	pp stats[1].value
  	assert stats[1].value == {
  	  "nginx" => {
  	  	"nginx" => 3,
  	  	"sshd" => 1,
  	  	:total => 4,
  	  	:distinct => 2
  	  },
  	  "newserv" => {
  	  	"sshd" => 1,
  	  	"apache" => 3,
  	  	"syslog" => 1,
  	  	:total => 5,
  	  	:distinct => 3
  	  },
  	  :total => 9,
  	  :distinct => 2
  	}
  	assert stats[2].value == {
  	  "127.0.0.1" => {
  	  	"/" => 1,
  	  	"/robots.txt" => 1,
  	  	:total => 2,
  	  	:distinct => 2
  	  },
  	  :total => 2,
  	  :distinct => 1
  	}
  	assert stats[3].value == {
  	  "nginx" => 4,
  	  "newserv" => 5,
  	  :total => 9,
  	  :distinct => 2
  	}
  end
end

