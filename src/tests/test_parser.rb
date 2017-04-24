gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require 'pp'

require_relative "../parser"
require_relative "../config"
require_relative "../tools"

class TestParser < Minitest::Test

  def test_log_to_numbers
    fn = Tools.abs_path "logs/fail2ban/fail2ban.log"
    output_file = Tools.abs_path "src/tests/files/fail2ban.numbers"
    output_file_desc = Tools.abs_path "src/tests/files/fail2ban.descr"
    Parser.transform(fn, output_file, false)
    Parser.transform(fn, output_file_desc, true)
    # hash_table = {}
    # i = 1
    # result.map! do |hsh|
    #   if hsh[:uid] == -1 or hsh[:uid] == -2 or hsh[:uid] == -3
    #     nil
    #   elsif hash_table.has_key? hsh[:uid]
    #     hsh[:uid] = hash_table[hsh[:uid]]
    #     hsh
    #   else
    #     hash_table[hsh[:uid]] = i
    #     hsh[:uid] = i
    #     i += 1
    #     hsh
    #   end
    # end
    # numbers = Parser.stream_of_numbers(result)
    # result.each_with_index do |hsh,i|
    #   if numbers[i] == -1 or numbers[i] == -2 or numbers[i] == -3
    #     next
    #   end
    #   printf "#{numbers[i]}\t-\t#{hsh[:service]}::#{hsh[:type]} ( "
    #   hsh[:data].to_a[0..1].to_h.each_pair do |key,value|
    #     printf "#{key} : #{value}, "
    #   end
    #     printf " )\n"
    # end
    # output_file = 'files/newserv_auth.num'
    # File.open(output_file, "w") do |f|
    #   numbers.each do |num|
    #     f.puts(num);
    #   end
    # end

  end

  def test_parser_apache_file
  	fn = "src/tests/files/apache_test"
  	result = Parser.parse!(Tools.abs_path(fn), "newserv")
  	true_result = [
  	  {
  	  	:server => "newserv",
  	  	:service => "apache",
  	  	:date => Time.new(2017,"Feb",13,06,48,26),
	  	  "user_ip" => "192.168.0.1",
	  	  "method" => "POST",
	  	  "path" => "/form.aspx",
	  	  "code" => "200",
  	  	:type => "Connection information"
  	  },
  	  {
  	  	:server => "newserv",
  	  	:service => "apache",
  	  	:date => Time.new(2017,"Feb",13,06,52,59),
	  	  "user_ip" => "192.168.0.1",
	  	  "method" => "GET",
	  	  "path" => "/robots.txt",
	  	  "code" => "301",
  	  	:type => "Connection information"
  	  },
      {
        "logline" => "Feb 13 06:47:41 newserv systemd[7279]: Reached target Timers.",
        :type => "Wrong format"
      },
  	  {
  	  	:server => "newserv",
  	  	:service => "apache",
  	  	:date => Time.new(2017,"Feb",13,07,06,24),
	  	  "user_ip" => "127.0.0.1",
	  	  "method" => "GET",
	  	  "path" => "/robots_are_good",
	  	  "code" => "404",
  	  	:type => "Connection information"
  	  }
  	]
  	true_result.each_with_index do |hsh,i|
    if hsh.class == String
        assert result[i] == true_result[i], "Result[#{i}] is not #{true_result[i]}, but #{result[i]}"
        next
      end
  	  hsh.each_pair do |key,value|
  	  	if key == :data
  	  	  value.each do |data_key, data_val|
  	  	  	assert result[i][:data][data_key] == data_val, "Data value is not the same: true value #{data_val}, got #{result[i][:data][data_key]}"
  	  	  end
  	  	else
  	  	  assert result[i][key] == value, "Value is not the same: true value #{value}, got #{result[i][key]}"
  	  	end
  	  end
  	end
  end
  def test_syslog
  	fn = "src/tests/files/syslog_test"
  	result = Parser.parse!(Tools.abs_path(fn), "newserv")
  	true_result = [
  	  {
  	  	:server => "newserv",
  	  	:service => "sshd",
  	  	:date => Time.new(2017,"Oct",9,06,36,11),
	  	  "user_ip" => "93.180.9.182",
	  	  "user_port" => "43718",
	  	  "server_ip" => "93.180.9.8",
	  	  "server_port" => "22",
  	  	:type => "New connection"
  	  },
  	  {
  	  	:server => "newserv",
  	  	:service => "sshd",
  	  	:date => Time.new(2017,"Oct",9,06,36,11),
	  	  "username" => "autocheck",
	  	  "user_ip" => "93.180.9.182",
	  	  "user_port" => "43718",
	  	  "protocol" => "RSA",
	  	  "hashing_alg" => "SHA256",
	  	  "publickey" => "EMJlgs25cBdZgixd0cGU31Uc1SoASY4IM2NLVq8LqlQ",
  	  	:type => "Accepted publickey"
  	  },
  	  {
  	  	:server => "newserv",
  	  	:service => "session-manager",
  	  	:date => Time.new(2017,"Oct",9,06,36,11),
  	  	"logline" => "New session 124403 of user autocheck.",
  	  	:type => "Service not found"
  	  },
  	  {
  	  	:server => "newserv",
  	  	:service => "systemd",
  	  	:date => Time.new(2017,"Oct",9,06,36,11),
	  	  "action" => "opened",
	  	  "username" => "autocheck",
  	  	:type => "Session activity"
  	  },
  	  {
  	  	:server => "newserv",
  	  	:service => "pid-master",
  	  	:date => Time.new(2017,"Oct",9,06,36,12),
	  	  "logline" => "User child is on pid 10801",
  	  	:type => "Service not found"
  	  },
      {
        "logline" => "kernel_panic: traceback: Received disconnect from 93.180.9.182: 11: disconnected by user",
        :type => "Wrong format"
      },
  	  {
  	  	:server => "newserv",
  	  	:service => "sshd",
  	  	:date => Time.new(2017,"Oct",9,06,36,12),
	  	  "logline" => "Disconnected client autocheck: no more lies",
  	  	:type => "Template not found"
  	  }
  	]
  	true_result.each_with_index do |hsh,i|
    if hsh.class == String
        assert result[i] == true_result[i], "Result[#{i}] is not #{true_result[i]}, but #{result[i]}"
        next
      end
  	  hsh.each_pair do |key,value|
  	  	assert result[i][key] == value, "Value is not the same: true value #{value}, got #{result[i][key]}"
  	  end
  	end
  end
end
