gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../parser"
require_relative "../loader"

class TestParser < Minitest::Test
  def test_parser_apache_file
    fn = 'files/apache_test'
    stream = LoglineStream.load_from_file fn
  	p = Parser.new.parse stream
  	true_result = [
  	  {
  	  	:server => "newserv.srcc.msu.ru",
  	  	:service => "apache",
  	  	:date => Time.new(2017,"Feb",13,06,48,26, "+03:00"),
        :type => "Connection information",
        :linedata => {
  	  	  "user_ip" => "192.168.0.1",
  	  	  "method" => "POST",
  	  	  "path" => "/form.aspx",
  	  	  "code" => "200",
          "http_version"=>"1.0"
        }
  	  },
  	  {
  	  	:server => "newserv.srcc.msu.ru",
  	  	:service => "apache",
  	  	:date => Time.new(2017,"Feb",13,06,52,59, "+03:00"),
        :type => "Connection information",
        :linedata => {
  	  	  "user_ip" => "192.168.0.1",
  	  	  "method" => "GET",
  	  	  "path" => "/robots.txt",
  	  	  "code" => "301",
          "http_version"=>"1.1"
        }
  	  },
  	  {
  	  	:server => "newserv.srcc.msu.ru",
  	  	:service => "apache",
  	  	:date => Time.new(2017,"Feb",13,07,06,24, "+03:00"),
        :type => "Connection information",
        :linedata => {
  	  	  "user_ip" => "127.0.0.1",
  	  	  "method" => "GET",
  	  	  "path" => "/robots_are_good",
  	  	  "code" => "404",
          "http_version"=>"2.0"
        }
  	  }
  	]
    true_err_result = [
      {
        filename: fn,
        server: "undefined",
        ok: false,
        description: Parser.strerror(Parser::WRONG_FORMAT),
        errno: Parser::WRONG_FORMAT,
        log_format: "ApacheFormat"
      }
    ]
    # binding.irb
    assert true_result.zip(p.parsed_lines).map {|tpl, pl| tpl <= pl }.all?, "Ошибка в парсинге"
    assert true_result.zip(p.parsed_lines).map {|tpl, pl| tpl[:linedata] <= pl[:linedata] }.all?, 
          "Ошибка в парсинге linedata"
    assert true_err_result.zip(p.erroneous_lines).map {|tel, el| tel <= el }.all?, "Ошибка в парсинге неправильных строк"
  end
  def test_syslog
  	fn = "files/syslog_test"
  	p = Parser.new.parse LoglineStream.load_from_file(fn)
  	true_result = [
  	  {
  	  	:server => "newserv",
  	  	:service => "sshd",
  	  	:date => Time.new(2017,"Oct",9,06,36,11),
  	  	:type => "New connection",
        :linedata => {
          "user_ip" => "93.180.9.182",
          "user_port" => "43718",
          "server_ip" => "93.180.9.8",
          "server_port" => "22",
          "pid"=>"10547"
        }
  	  },
  	  {
  	  	:server => "newserv",
  	  	:service => "sshd",
  	  	:date => Time.new(2017,"Oct",9,06,36,11),
  	  	:type => "Accepted",
        :linedata => {
          "username" => "autocheck",
          "user_ip" => "93.180.9.182",
          "user_port" => "43718",
          "protocol" => "RSA",
          "hashing_alg" => "SHA256",
          "publickey" => "EMJlgs25cBdZgixd0cGU31Uc1SoASY4IM2NLVq8LqlQ",
          "pid"=>"10547"
        }
  	  },
  	  {
  	  	:server => "newserv",
  	  	:service => "systemd",
  	  	:date => Time.new(2017,"Oct",9,06,36,11),
  	  	:type => "Session activity",
        :linedata => {
          "action" => "opened",
          "username" => "autocheck",
          "pid"=>nil
        }
      }
  	]
    true_err_result = [

      {
        :server => "newserv",
        :service => "session-manager",
        :date => Time.new(2017,"Oct",9,06,36,11),
        :errno => Parser::UNKNOWN_SERVICE,
        :description => Parser.strerror(Parser::UNKNOWN_SERVICE)
      },
      {
        :server => "newserv",
        :service => "pid-master",
        :date => Time.new(2017,"Oct",9,06,36,12),
        :errno => Parser::UNKNOWN_SERVICE,
        :description => Parser.strerror(Parser::UNKNOWN_SERVICE)
      },
      {
        :errno => Parser::WRONG_FORMAT,
        :description => Parser.strerror(Parser::WRONG_FORMAT)
      },
      {
        :server => "newserv",
        :service => "sshd",
        :date => Time.new(2017,"Oct",9,06,36,12),
        :errno => Parser::TEMPLATE_NOT_FOUND,
        :description => Parser.strerror(Parser::TEMPLATE_NOT_FOUND)
      }
    ]
    # binding.irb

    assert true_result.zip(p.parsed_lines).map {|tpl, pl| tpl <= pl }.all?, "Ошибка в парсинге"
    assert true_result.zip(p.parsed_lines).map {|tpl, pl| tpl[:linedata] <= pl[:linedata] }.all?, 
          "Ошибка в парсинге linedata"
    assert true_err_result.zip(p.erroneous_lines).map {|tel, el| tel <= el }.all?, "Ошибка в парсинге неправильных строк"
  end
end
