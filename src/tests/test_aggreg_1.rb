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
    Aggregator::Aggregator.new @db_name
    @print_test = false
  end
  
  def print_line(hsh = {})
    line = hsh[:line]
    i = hsh[:i]
    printf "#{i})\tFilename: #{line.filename}\n"
    printf "\tLineNo: #{line.line}\n"
    printf "\tData:\n"
    line.datas.each do |data|
      printf "\t\t#{data.name} = #{data.value}\n"
    end
    printf "\tMeta:\n"
    line.metas.each do |data|
      printf "\t\t#{data.name} = #{data.value}\n"
    end
  end

  def print_coll(table)
    table.each_with_index {|line, i| print_line line: line, i: i}
  end

  def test_ip_distr
    skip unless @db_name =~ /access/
    skip if !@print_test
    refute_empty Aggregator::Aggregator.aggregate_by_keys("ip")
    Aggregator::Aggregator.save "report/ip_distr.yml"
    Aggregator::Aggregator.show_report "report/ip_distr.yml"
  end
  
  def test_ip_path_distr
    skip unless @db_name =~ /access/
    skip if !@print_test
    refute_empty Aggregator::Aggregator.aggregate_by_keys("ip", "path")
    Aggregator::Aggregator.save "report/ip_path_distr.yml"
    Aggregator::Aggregator.show_report "report/ip_path_distr.yml"
  end
  
  def test_ip_path_code_distr
    skip
    skip unless @db_name =~ /access/
    skip if !@print_test
    refute_empty Aggregator::Aggregator.aggregate_by_keys("ip", "path", "code")
    Aggregator::Aggregator.save "report/ip_path_distr.yml"
    Aggregator::Aggregator.show_report "report/ip_path_distr.yml"
  end

  def test_select
    skip unless @db_name =~ /access.sqlite3/
    refute_empty Aggregator::Aggregator.select(metas: {"service" => "apache"}).lines
    assert_empty Aggregator::Aggregator.select(metas: {"service" => "sshd"}, datas: {"ip" => "127.0.0.1"}).lines
    assert_equal Aggregator::Aggregator.reset.select(datas: {"ip" => "124.219.152.208"}).count, 78
    refute_empty Aggregator::Aggregator.reset.lines
  end

  def test_root_bug
    skip unless @db_name =~ /auth/
    print_coll Aggregator::Aggregator.select(datas: {"user_ip" => "root"}).lines
    #print_coll Aggregator::Aggregator.select(datas: {"user_ip" => "163.172.114.58"})
  end
end