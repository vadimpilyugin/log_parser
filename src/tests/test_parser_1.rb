gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../parser"
require_relative "../config"
require_relative "../tools"

class TestParser < Minitest::Test

  def test_apache_regex
    s = <<FILE
180.76.15.152 - - [09/Oct/2016:08:34:45 +0300] "GET /system/10769 HTTP/1.0" 404 291 "-" "Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)" - - old.parallel.ru
FILE
    # puts (s =~ Templates::Apache)
    # puts Apache.check(s)
    # $~.to_h.pretty_print
    assert Apache.check(s), "Not an Apache string!"
  end
  def test_sshd_regex
    s = <<FILE
Oct  9 06:36:12 newserv sshd[10801]: Received disconnect from 93.180.9.182: 11: disconnected by user
FILE
    assert Sshd.check(s), "Not an sshd string!"
  end
  def test_output
    # pass
    Parser.parse!
    Parser.table[0..5].each_with_index do |entry, i|
      printf "##{i})\tServer = #{entry[:server]}\n"
      printf "\tService = #{entry[:service]}\n"
      printf "\tTime = #{entry[:time]}\n"
      printf "\tData:\n"
      entry[:data].each_pair do |k, v|
        printf "\t  #{k} = #{v}\n"
      end
      printf "\tDescription = #{entry[:descr]}\n"
    end
  end
end

