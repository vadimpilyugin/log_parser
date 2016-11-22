gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../db"
require_relative "../parser"
require_relative "../config"

class TestSaving < Minitest::Test
  Config.new
  @@db_name = "archive/test.sqlite3"
  db = Database::Database.new filename: @@db_name, drop: false
  #@p = Parser::Parser.new filename: "logs/auth-test_log"
  #db.save(@p.parse!.table)

  def setup
    @test_print = true
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

  def print_kv(hsh = {})
    hsh.each_pair do |k, v|
      printf "\t\t#{k} = #{v}\n"
  	end
  end

  def print_datas_coll(datas)
  	datas.each_with_index do |elem, i|
  	  printf "#{i})"
      print_kv(elem.name => elem.value)
    end
  end

  def test_first_line
    skip unless @test_print
    a = Database::Logline.first line: 1
    assert a
    print_line line: a, i: 1
  end

  def test_look_for_local
    skip unless @@db_name == "test.sqlite3"
    a = Database::Logline.all datas: {:name => "ip", :value => "217.69.133.29"} 
    a = a.all datas: {:name => "code", :value => "404"}
    refute_empty a 
    a.each_with_index do | line, i|
	  print_line line: line, i: i
    end
  end

  def test_count
    skip unless @test_print
    key_str = "code"
    a = Database::Data.all name: key_str
    hsh = Hash.new { |hash, key| hash[key] = 0 }
    a.each do |data|
	  hsh[data.value] += 1
    end
    puts
    printf "Counting #{key_str.upcase}s: \n"
    print_kv hsh
    hsh.keys.each do |key|
	  assert_equal Database::Data.all(name: key_str, value: key).size, hsh[key]
    end
  end

  def test_aggregate_column
  	skip unless @test_print
    key = "code"
    printf "Все возможные коды и их частота: \n" if key == "code"
    # a = Database::Data.all(name: "code").aggregate(:all.count, :fields => [ :value ])
    a = Database::Data.all(name: key).aggregate(:value, :all.count)
    print_kv a.to_h
    #puts Database::Data.count value: "/robots.txt"
    #printf "#{Database::Data.aggregate(:name => "code", :value)}\n"
  end

  def test_saving
    @db = Database::Database.new filename: "archive/test.sqlite3", drop: true
    @p = Parser::Parser.new filename: "logs/access.log"
    @p.parse!
    @db.save(@p.table)
  end
end
