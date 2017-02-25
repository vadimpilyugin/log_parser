require_relative 'services'
require_relative 'config'
require_relative 'tools'


class Parser
  @@parser = nil
  @@filename = nil
  @@table = nil

  def initialize()
    return @@parser if @@parser
    @@parser = "New parser"
    @@filename = Config["parser"]["log_file"]	# отсюда читаем лог
    Printer::assert(Tools.file_exists?(@@filename), "Файл лога не найден", "Path":@@filename)
    @@table = []
  end
  def self.table
    @@table
  end
  def self.parse!()
    File.open(@@filename, 'r') do |f|
      Printer::debug("File opened, starting scanning")
      f.each_with_index do |logline, i|
        i = Services.index {|service| service.check(logline)}
        if i == nil
          Printer::note(i == nil, "Для данной строки не найдено совпадений: она не подходит ни под один сервис", "Services":Services, "Line":logline)
        else
          Printer::debug("Line ##{$.} passed")
          @@table << Services[i].parse!(logline)
        end
      end
    end
  end
end

Parser.new