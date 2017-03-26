gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require 'pp'
require_relative "../../services/service.rb"

class TestSaving < Minitest::Test
  def test_apache_logline
  	s = "93.180.9.182 - - [03/Feb/1997:18:30:00 +0300] \"GET /robots.txt?uuid=180&path=yandex.ru HTTP/1.0\" 200 177 \"-\" \"Wget/1.12 (linux-gnu)\" - - newserv.srcc.msu.ru"
  	service = Services["apache"]
  	assert service.check(s)
  	result = service.parse! s
  	true_result = {
  	  "data" => {
  	  	"method" => "GET",
  	  	"path" => "/robots.txt",
  	  	"user_ip" => "93.180.9.182",
  	  	"code" => "200"
  	  },
  	  "descr" => "Connection information"
  	}
  	true_result.each_pair do |key,value|
  	  if key == "data"
  	  	true_result["data"].each_pair do |k1,v1|
  	  	  assert result["data"][k1] == true_result["data"][k1], "#{k1} in data is wrong! #{result["data"][k1]}"
  	  	end
  	  end
  	  assert result[key] == true_result[key], "#{key} is wrong! #{result[key]}"
  	end
  end
  def test_sshd
  	s = "Connection from 192.168.0.1 port 666 on 127.0.0.1 port 1"
  	service = Services["sshd"]
  	assert service.check(s)
  	result = service.parse! s
  	true_result = {
  	  "data" => {
	    "user_ip" => "192.168.0.1",
	    "user_port" => "666",
	    "server_ip" => "127.0.0.1",
	    "server_port" => "1"
  	  },
  	  "descr" => "New connection"
  	}
  	true_result.each_pair do |key,value|
  	  if key == "data"
  	  	true_result["data"].each_pair do |k1,v1|
  	  	  assert result["data"][k1] == true_result["data"][k1], "#{k1} in data is wrong! #{result["data"][k1]}"
  	  	end
  	  end
  	  assert result[key] == true_result[key], "#{key} is wrong! #{result[key]}"
  	end
  end
  def test_sshd_not_found
  	s = "Connection to 192.168.0.1 on port 666 cannot be established"
  	result = Services["sshd"].parse! s
  	true_result = nil
  	assert result == true_result
  end
  def test_fail2ban
    str = [
      "Log rotation detected for /var/log/auth.log",
      "Found 212.129.63.254",
      "Connection cannot be established",
    ]
    true_result = [true, true, false]
    result = str.map do |msg|
      Services["fail2ban"].check(msg)
    end
    assert true_result == result
    true_result = [
      {
        "data" => {"path" => "/var/log/auth.log"},
        "descr" => "Log rotation"
      },
      {
        "data" => {},
        "descr" => "Ban/unban"
      },
      nil
    ]
    true_result.each_with_index do |true_res,i|
      assert true_res == Services["fail2ban"].parse!(str[i])
    end
  end
end