gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"
require 'pp'
require_relative "../../services/log_formats.rb"

class TestSaving < Minitest::Test
  def test_apache_log_format
  	s = "93.180.9.50 - - [13/Feb/2017:07:22:52 +0300] \"GET /pipermail/par-news/2012-December.txt.gz?uuid=123&redirect=yandex.ru HTTP/1.0\" 200 2015 \"-\" \"Mozilla/5.0 (compatible;"
  	assert ApacheFormat.check(s)
  	result = ApacheFormat.parse! s
  	true_result = {
  	  "user_ip" => "93.180.9.50",
  	  "year" => "2017",
  	  "month" => "Feb",
  	  "day" => "13",
  	  "hour" => "07",
  	  "minute" => "22",
  	  "second" => "52",
  	  "timezone" => "+0300",
  	  "method" => "GET",
  	  "path" => "/pipermail/par-news/2012-December.txt.gz",
  	  "http_version" => "1.0",
  	  "code" => "200"
  	}
  	true_result.each_pair do |key,value|
  	  assert result[key] == true_result[key], "#{key} is wrong! #{result[key]}"
  	end
  end
  def test_syslog_log_format
  	s = "Feb 15 07:00:01 newserv CRON[18735]: (otrs) CMD ((test -x $HOME/bin/GenericAgent.pl && $HOME/bin/GenericAgent.pl)||true > /dev/null)"
  	assert SyslogFormat.check s
  	result = SyslogFormat.parse! s
  	true_result = {
  	  "month" => "Feb",
  	  "day" => "15",
  	  "hour" => "07",
  	  "minute" => "00",
  	  "second" => "01",
  	  "server" => "newserv",
  	  "service" => "CRON",
  	  "pid" => "18735",
  	  "msg" => "(otrs) CMD ((test -x $HOME/bin/GenericAgent.pl && $HOME/bin/GenericAgent.pl)||true > /dev/null)"
  	}
  	true_result.each_pair do |key,value|
  	  assert result[key] == true_result[key], "#{key} is wrong! #{result[key]}"
  	end
  end
  def test_fail2ban_log_format
  	s = "2017-02-14 04:22:15,208 fail2ban.actions        [1686]: NOTICE  [ssh] 223.99.60.47 already banned"
  	assert Fail2BanFormat.check s
  	result = Fail2BanFormat.parse! s
  	true_result = {
  	  "year" => "2017",
  	  "month" => "02",
  	  "day" => "14",
  	  "hour" => "04",
  	  "minute" => "22",
  	  "second" => "15",
  	  "msecond" => "208",
  	  "server" => "fail2ban",
  	  "type" => "actions",
  	  "pid" => "1686",
  	  "level" => "NOTICE",
  	  "service" => "ssh",
  	  "msg" => "223.99.60.47 already banned"
  	}
  	true_result.each_pair do |key,value|
  	  assert result[key] == true_result[key], "#{key} is wrong! #{result[key]}"
  	end
  end
  def test_log_format_finding
    str = [
      "93.180.9.182 - - [13/Feb/2017:07:49:54 +0300] \"GET / HTTP/1.0\" 200 177 \"-\" \"Wget/1.12 (linux-gnu)\" - - newserv.srcc.msu.ru",
      "141.8.142.23 - - [13/Feb/2017:07:58:40 +0300] \"GET /MIU_XIX/images/memuary/tsvetaev/small/000ai.jpg HTTP/1.0\" 304 - \"-\" \"Mozilla/5.0 (compatible; YandexImages/3.0; +http://yandex.com/bots)\" - - newserv.srcc.msu.ru",
      "109.63.236.190 - - [13/Feb/2017:09:17:49 +0300] \"GET /sites/all/modules/ctools/css/ctools.css?nhpgh0 HTTP/1.0\" 200 252 \"http://ccoe.msu.ru/ru/articles/openacc-intro\" \"Mozilla/5.0 (Windows NT 6.1; rv:26.0) Gecko/20100101 Firefox/26.0\" - - cuda-center.parallel.ru",
      "109.63.236.190 - - [13/Feb/2017:09:17:49 +0300] \"GET /misc/drupal.js?nhpgh0 HTTP/1.0\" 200 4976 \"http://ccoe.msu.ru/ru/articles/openacc-intro\" \"Mozilla/5.0 (Windows NT 6.1; rv:26.0) Gecko/20100101 Firefox/26.0\" - - cuda-center.parallel.ru",
      "Feb 13 06:47:41 newserv console-kit-daemon[1410]: (process:7337): GLib-CRITICAL **: g_slice_set_config: assertion 'sys_page_size == 0' failed",
      "Feb 13 06:47:41 newserv systemd[1]: Started Session 169968 of user autocheck.",
      "Feb 13 06:52:00 newserv systemd[25207]: Received SIGRTMIN+24 from PID 25221 (kill).",
      "2017/02/13 08:58:10 [error] 25350#25350: *9502388 upstream timed out (110: Connection timed out) while reading response header from upstream, client: 141.8.132.12, server: octoshell.ru, request: \"GET /robots.txt HTTP/1.1\", upstream: \"http://192.168.254.110:8080/robots.txt\", host: \"www.octoshell.ru\"",
      "2017/02/13 09:06:10 [error] 25353#25353: *9502932 upstream timed out (110: Connection timed out) while reading response header from upstream, client: 93.158.152.38, server: octoshell.ru, request: \"GET /robots.txt HTTP/1.1\", upstream: \"http://192.168.254.110:8080/robots.txt\", host: \"www.octoshell.ru\"",
      "2017-02-13 06:48:36,398 fail2ban.filter         [1686]: INFO    Log rotation detected for /var/log/exim4/mainlog",
      "2017-02-13 08:34:34,191 fail2ban.filter         [1686]: INFO    [pam-generic] Found 212.129.63.254",
      "2017-02-13 08:34:34,311 fail2ban.filter         [1686]: INFO    [ssh-ddos] Found 212.129.63.254",
    ]
    true_result = [
      ApacheFormat,
      ApacheFormat,
      ApacheFormat,
      ApacheFormat,
      SyslogFormat,
      SyslogFormat,
      SyslogFormat,
      nil,
      nil,
      Fail2BanFormat,
      Fail2BanFormat,
      Fail2BanFormat
    ]
    str.each_with_index do |logline,i|
      assert LogFormat.find(logline) == true_result[i], "Wrong log format! True: #{true_result[i]}, got #{LogFormat.find(logline)}"
    end
  end
end