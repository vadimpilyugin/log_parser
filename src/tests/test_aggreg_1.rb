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
    @db_name = "archive/auth-test.sqlite3"
    @a = Aggregator::Aggregator.new @db_name
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
    refute_empty @a.aggregate_by_keys("ip")
    @a.save "report/ip_distr.yml"
    @a.show_report "report/ip_distr.yml"
  end
  
  def test_ip_path_distr
    skip unless @db_name =~ /access/
    skip if !@print_test
    refute_empty @a.aggregate_by_keys("ip", "path")
    @a.save "report/ip_path_distr.yml"
    @a.show_report "report/ip_path_distr.yml"
  end
  
  def test_ip_path_code_distr
    skip
    skip unless @db_name =~ /access/
    skip if !@print_test
    refute_empty @a.aggregate_by_keys("ip", "path", "code")
    @a.save "report/ip_path_distr.yml"
    @a.show_report "report/ip_path_distr.yml"
  end

  def test_select
    skip unless @db_name =~ /access.sqlite3/
    refute_empty @a.select(metas: {"service" => "apache"})
    assert_empty @a.select(metas: {"service" => "sshd"}, datas: {"ip" => "127.0.0.1"})
    assert_equal @a.reset.select(datas: {"ip" => "124.219.152.208"}).size, 78
    refute_empty @a.reset.lines
  end

  def test_root_bug
    skip unless @db_name =~ /auth/
    print_coll @a.select(datas: {"user_ip" => "root"})
    #print_coll @a.select(datas: {"user_ip" => "163.172.114.58"})
  end
end