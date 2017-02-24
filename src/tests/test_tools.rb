gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../tools"

class TestReport < Minitest::Test

  def test_assertions
    Printer::note(0==0, "Пифагоровы штаны во все стороны равны", "Штаны.х": 5, "Штаны.у": 5, "Штаны.х ==? Штаны.у":5==5)
    Printer::assert(0==1, "Пифагоровы штаны во все стороны равны", "Штаны.х": 5, "Штаны.у": 5, "Штаны.х ==? Штаны.у":5==5)

    # Tools::assert(0==1, "Пифагоровы штаны во все стороны равны")
  end

  def test_non_existent
    Printer::debug("Пифагоровы штаны во все стороны равны", "Штаны.х": 5, "Штаны.у": 5, "Штаны.х ==? Штаны.у":5==5)
    Printer::refute(0==0, "Пифагоровы штаны во все стороны равны", "Штаны.х": 5, "Штаны.у": 5, "Штаны.х ==? Штаны.у":5==5)

  end
end