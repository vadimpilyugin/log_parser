gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../config"
require_relative "../aggregator.rb"

  class Hash
    def ph
      self.each_pair do |key, value|
        printf "  #{key} = #{value}\n"
      end
    end
  end

class TestReport < Minitest::Test
  Config.new	

  def setup
    @db_name = "archive/access.sqlite3"
    @a = Aggregator::Aggregator.new @db_name
  end
  
  def test_ip_distr
    skip unless @db_name =~ /access/
    refute_empty @a.aggregate_by_keys("ip")
    @a.save "report/ip_distr.yml"
    @a.show_report "report/ip_distr.yml"
  end
  
  def test_ip_path_distr
    skip unless @db_name =~ /access/
    refute_empty @a.aggregate_by_keys("ip", "path")
    @a.save "report/ip_path_distr.yml"
    @a.show_report "report/ip_path_distr.yml"
  end
  
  def test_select
    skip unless @db_name =~ /access/
    refute_empty @a.select(metas: {"service" => "apache"})
    refute @a.select(metas: {"service" => "sshd"}, datas: {"ip" => "127.0.0.1"})
    refute_empty @a.reset
  end
end