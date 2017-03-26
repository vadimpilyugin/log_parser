gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../stats"

class TestReport < Minitest::Test

  def test_stats
	st = Stats::Stats.new(	[["Counter", :cnt, "Число созданных файлов"],
							["HashCounter", :hsh, "Самые частые имена файлов"]])
	30.times do |i|
	  st.hsh.increment("foo")
	end
	60.times do |i|
	  st.hsh.increment("bar")
	end
	10.times do |i|
		st.hsh.increment("foobar")
	end
	100.times do |i|
	  Printer::debug(who:"Создаю файлы",msg:"#{i+1} создано",in_place:true)
	  sleep(0.05)
	  st.cnt.increment
	end
	puts
	st.print
  end
end
