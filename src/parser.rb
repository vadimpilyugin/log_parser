require_relative 'services'
require_relative 'config'

class Parser
  @@parser = nil
  @@filename = nil
  @@table = nil

  def initialize()
    @@parser ? return @@parser : @@parser = "New parser"
    @@filename = Config["parser"]["log_file"]	# отсюда читаем лог
    Printer::assert(Tools.file_exists? (@@filename), "Файл лога не найден", "Path":@@filename)
    @@table = []
  end

  def parse!()
    File.open(@@filename, 'r') do |logline|
      i = Services.index {|Service| Service.check(logline)}
      if i == nil
        Printer::note(i != nil, "Для данной строки не найдено совпадений: она не подходит ни под один сервис", "Services":Services, "Line":logline)
      else
        @@table << Services[i].parse!(logline)
      end
    end
  end
end
