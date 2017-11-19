gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require 'pp'
require 'irb'


require_relative "../statistics"
require_relative "../config"
require_relative "../tools"

class TestParser < Minitest::Test
  # def setup
  	# @statistics = YAML.load_file Tools.abs_path(Config["report"]["report_config"])
  # end
  # def test_create_stats
  	# Statistics.new(@statistics)
  # end
  def test_simple_counter
  	params = {
  	  	"Counter" => "Simple counter",
        "server" => "foo",
        "service" => "bar",
        "linedata" => {
          "username" => "baz"
        }
  	  }
  	stat_no = Statistics.create_stat params
    lines = [
      {server:"foo",service:"bar",linedata:{"username" => "baz"}},
      {server:"foo",service:"bar",linedata:{"username" => "foo"}},
    ]
    Statistics.process lines
    assert Statistics[stat_no].conditions.fit?(lines[0]), "lines[0] не подходит под условия"
  	refute Statistics[stat_no].conditions.fit?(lines[1]), "lines[1] не подходит под условия"

  end
  def test_counter_linedata
    params = [
      {
        "Counter" => "Simple counter",
        "linedata" => 
        {
          "foo" => "bar",
        }
      },
      {
        "Counter" => "Simple counter",
        "linedata" => 
        {
          "foo" => "bar",
          "bar" => "baz",
        }
      },
      {
        "Counter" => "Simple counter",
        "linedata" => 
        {
          "foo" => "bar",
          "bar" => "baz",
          "baz" => "foo"
        }
      },
    ]
    lines = [
      {linedata:{"foo" => "bar"}},
      {linedata:{"foo" => "bar", "bar" => "baz"}},
      {linedata:{"foo" => "bar", "bar" => "baz", "baz" => "foo"}},
    ]
    stat_ids = Statistics.init params
    assert Statistics[stat_ids[0]].conditions.fit?(lines[0]), "stat_ids[0], line[0]"
    assert Statistics[stat_ids[0]].conditions.fit?(lines[1]), "stat_ids[0], line[1]"
    assert Statistics[stat_ids[0]].conditions.fit?(lines[2]), "stat_ids[0], line[2]"

    refute Statistics[stat_ids[1]].conditions.fit?(lines[0]), "stat_ids[1], line[0]"
    assert Statistics[stat_ids[1]].conditions.fit?(lines[1]), "stat_ids[1], line[1]"
    assert Statistics[stat_ids[1]].conditions.fit?(lines[2]), "stat_ids[1], line[2]"

    refute Statistics[stat_ids[2]].conditions.fit?(lines[0]), "stat_ids[2], line[0]"
    refute Statistics[stat_ids[2]].conditions.fit?(lines[1]), "stat_ids[2], line[1]"
    assert Statistics[stat_ids[2]].conditions.fit?(lines[2]), "stat_ids[2], line[2]"


    Statistics.process lines
    assert Statistics[stat_ids[0]].count == 3
    assert Statistics[stat_ids[1]].count == 2
    assert Statistics[stat_ids[2]].count == 1
  end
  def test_distr_keys
    params = {
      "Distribution" => "Simple distr",
      "keys" => [
        "foo",
        "bar",
        "server"
      ],
    }
    lines = [
      {:server => "undefined", :linedata => {"foo" => "bar", "bar" => "baz"}},
      {:server => "undefined", :linedata => {"baz" => "bar", "bar" => "baz"}},
      {:linedata => {"foo" => "bar", "bar" => "baz"}},
    ]
    d = Distribution.new params
    assert d.conditions.fit?(lines[0])
    refute d.conditions.fit?(lines[1])
    refute d.conditions.fit?(lines[2])
  end

  def test_distribution
  	table = [
    	{:service => "sshd", :server => "newserv", :linedata => {}},
    	{:service => "apache", :server => "newserv", :linedata => {}},
    	{:service => "syslog", :server => "newserv", :linedata => {}},
    	{:service => "nginx", :server => "nginx", :linedata => {}},
    	{:service => "nginx", :server => "nginx", :linedata => {}},
    	{:service => "nginx", :server => "nginx", :linedata => {}},
    	{:service => "sshd", :server => "nginx", :linedata => {}},
    	{:server => "newserv", :service => "apache", :linedata => 
        {
          "path" => "/", 
          "user_ip" => "127.0.0.1"
        }
      },
    	{:server => "newserv", :service => "apache", :linedata => 
        {
          "path" => "/robots.txt", 
          "user_ip" => "127.0.0.1"
        }
      }
    ]
  	params = [
  	  {
  	  	"Counter" => "Total lines from newserv",
  	  	"server" => "newserv"
  	  },
      {
        "Distribution" => "server - service distr",
        "keys" => [
          "server",
          "service"
        ]
      },
      {
        "Distribution" => "ip-path distr",
        "keys" => [
          "user_ip",
          "path"
        ]
      },
      {
        "Distribution" => "Server requests total",
        "keys" => [
          "server"
        ]
      },
      {
        "Counter" => "Total requests to home page",
        "linedata" => {"path" => "/"}
      },
    ]
    stats = Statistics.init(params)
    Statistics.process table
    assert Statistics[stats[0]].count == 5, "counter is #{Statistics[stats[0]].count}"
    pp Statistics[stats[1]].distrib
    assert Statistics[stats[1]].distrib == {
      "nginx" => {
        :total => 4,
        "nginx" => 3,
        :distinct => 2,
        "sshd" => 1,
      },
      "newserv" => {
  	  	:total => 5,
        "apache" => 3,
  	  	:distinct => 3,
        "sshd" => 1,
        "syslog" => 1,
  	  },
  	  :total => 9,
  	  :distinct => 2
  	}
  	assert Statistics[stats[2]].distrib == {
  	  "127.0.0.1" => {
  	  	"/" => 1,
  	  	"/robots.txt" => 1,
  	  	:total => 2,
  	  	:distinct => 2,
  	  },
  	  :total => 2,
  	  :distinct => 1,
  	}
  	assert Statistics[stats[3]].distrib == {
      "nginx" => 4,
      "newserv" => 5,
      :total => 9,
      :distinct => 2
    }
    assert Statistics[stats[4]].count == 1
  end
  
end

