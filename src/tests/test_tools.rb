gem "minitest"     # ensures you"re using the gem, and not the built-in MT
require "minitest/autorun"

require_relative "../tools"

class TestReport < Minitest::Test

  def test_assert
  	begin
  	  Printer::assert(expr:2+2 == 5, msg:"2+2 = 5")
  	rescue RuntimeError
  	  assert true, "Error in Printer::assert"
  	end
  	begin
  	  Printer::assert(expr:2+2 == 5, msg:"2+2 = 5", who:"Printer::assert")
  	rescue RuntimeError
  	  assert true, "Error in Printer::assert"
  	end
  	begin
  	  Printer::fatal(msg:"2+2 = 5 is false!", who:"Printer::fatal")
  	rescue RuntimeError
  	  assert true, "Error in Printer::fatal"
  	end
  	Printer::note(msg:"Файл не существует, создаю...", who:"test_assert")
    Printer::note(msg:"Это не должно быть на экране", expr:false, who:"Printer::note")
  	100.times do |i|
  	  Printer::debug(msg:"#{i+1} файлов создано...", in_place:true)
  	  sleep(0.02)
  	end
  	puts
  	Printer::debug(msg:"Все файлы созданы!",who:"test_assert", params:{"Число файлов" => 100, "Успешно ли созданы" => "Да"})
  end
end