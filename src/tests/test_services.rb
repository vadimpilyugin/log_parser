gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require 'pp'
require 'irb'
require_relative "../../services/service.rb"

class TestSaving < Minitest::Test
  # def test_service
  #   s = Services['org.mate.panel.applet.MultiLoadA']
  #   binding.irb
  #   assert s
  # end
  def test_sshd_pam
    s = 'pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=58.218.198.142 user=root'
    assert Services["sshd"].check(s)
  end
  def test_apache_logline
  	s = "93.180.9.182 - - [03/Feb/1997:18:30:00 +0300] \"GET /robots.txt?uuid=180&path=yandex.ru HTTP/1.0\" 200 177 \"-\" \"Wget/1.12 (linux-gnu)\" - - newserv.srcc.msu.ru"
  	service = Services["apache"]
  	assert service.check(s)
  	result = service.parse s
  	true_result = {
  	  linedata: {
  	  	"method" => "GET",
  	  	"path" => "/robots.txt",
  	  	"user_ip" => "93.180.9.182",
  	  	"code" => "200"
  	  },
  	  type: "Connection information"
  	}
  	true_result.each_pair do |key,value|
  	  if key == :linedata
  	  	true_result[:linedata].each_pair do |k1,v1|
  	  	  assert result[:linedata][k1] == true_result[:linedata][k1], "#{k1} in :linedata is wrong! #{result[:linedata][k1]}"
  	  	end
  	  end
  	  assert result[key] == true_result[key], "#{key} is wrong! #{result[key]}"
  	end
  end
  def test_sshd
  	s = "Connection from 192.168.0.1 port 666 on 127.0.0.1 port 1"
  	service = Services["sshd"]
  	assert service.check(s)
  	result = service.parse s
  	true_result = {
  	  :linedata => {
  	    "user_ip" => "192.168.0.1",
  	    "user_port" => "666",
  	    "server_ip" => "127.0.0.1",
  	    "server_port" => "1"
  	  },
  	  type:"New connection"
  	}
  	true_result.each_pair do |key,value|
  	  if key == :linedata
  	  	true_result[:linedata].each_pair do |k1,v1|
  	  	  assert result[:linedata][k1] == true_result[:linedata][k1], "#{k1} in :linedata is wrong! #{result[:linedata][k1]}"
  	  	end
  	  end
  	  assert result[key] == true_result[key], "#{key} is wrong! #{result[key]}"
  	end
  	assert Services["sshd"].parse("foo bar baz").nil?
  end
  def test_fail2ban
    str = [
      "Log rotation detected for /var/log/auth.log",
      "Found 212.129.63.254",
    ]
    true_result = [true, true]
    result = str.map { |msg| Services["fail2ban"].check(msg)}
    assert true_result == result, "Wrong: #{result}"
    true_result = [
      {
        linedata: {"path" => "/var/log/auth.log"},
        type: "Log rotation"
      },
      {
        linedata: {"user_ip"=>"212.129.63.25"},
        type: "Ban/unban"
      }
    ]
    true_result.each_with_index do |true_res,i|
      if true_res == nil
        assert Services["fail2ban"].parse(str[i]) == nil
      else
        true_res.each_pair do |key,value|
          assert value == Services["fail2ban"].parse(str[i])[key], "Got #{Services["fail2ban"].parse(str[i])[key]}, expected #{value}"
        end
      end
    end
    assert Services["fail2ban"].parse("foo bar baz").nil?
  end
end
