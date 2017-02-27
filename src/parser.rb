require_relative 'config'
require_relative 'tools'
require_relative '../services/services.rb'


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
    stat = {:unknown_lines => {}, :ignored_services => Hash.new {|hash, key| hash[key] = 0}, 
            :no_template_provided => Hash.new {|hash, key| hash[key] = {}}, 
            :ignored_services_lines => 0, :success => 0}
    total = 0
    ignored_services_num = 0
    no_template_provided_num = 0
    unknown_lines_num = 0
    File.open(@@filename, 'r') do |f|
      Printer::debug("File opened, scanning started")
      f.each_with_index do |logline|
        total += 1
        i = Services.index {|service| service.check(logline)}
        if i == nil
          Printer::note(i == nil, "Found an unknown line at ##{$.}")
          stat[:unknown_lines].update($. => logline)
          unknown_lines_num += 1
        elsif Services[i].ignore?
          Printer::note(true, "Ignored #{Services[i].name} at line ##{$.}")
          stat[:ignored_services][Services[i].name] += 1
          ignored_services_num += 1
        else
          parsed_line = Services[i].parse!(logline)
          if parsed_line[:descr] == "__UNDEFINED__"
            Printer::note(true, "No template was provided from #{parsed_line[:service]} for line ##{$.}")
            stat[:no_template_provided][parsed_line[:service]].update($. => logline)
            no_template_provided_num += 1
          elsif parsed_line[:descr] == "Ignore"
            Printer::debug("Line ##{$.} from #{Services[i].name} was ignored")
            stat[:ignored_services_lines] += 1
          else
            Printer::debug("Line ##{$.} passed")
            @@table << parsed_line
            stat[:success] += 1
          end
        end
      end
    end
    stat[:ignored_services] = stat[:ignored_services].each do |key,value|
      value.to_s + " lines"
    end
    max = 3
    Printer::debug("",debug_msg:"==================")
    Printer::debug("#{total.to_s.red+" lines total".green}",debug_msg:"Parsing finished")
    Printer::debug("",debug_msg:"#{stat[:success].to_s.red+"".green} successfull attempts")
    Printer::debug("",debug_msg:"#{stat[:ignored_services_lines].to_s.red+"".green} lines were explicitly ignored")
    Printer::debug("",stat[:ignored_services].update(debug_msg:"#{ignored_services_num.to_s.red+"".green} services that were explicitly ignored"))
    Printer::debug("",debug_msg:"#{no_template_provided_num.to_s.red+"".green} lines that were not provided with template")
    stat[:no_template_provided].each do |service,hsh|
      size = hsh.values.size
      hsh = hsh.to_a[0..max].to_h
      Printer::debug("#{size.to_s.red+"".green} lines", hsh.update(debug_msg:"#{service}"))
      Printer::debug("",debug_msg:"\tShow #{(size-max).to_s.red+"".green} more") if size > max
    end
    size = stat[:unknown_lines].values.size
    stat[:unknown_lines] = stat[:unknown_lines].to_a[0..max].to_h
    Printer::debug("",stat[:unknown_lines].update(debug_msg:"#{unknown_lines_num.to_s.red+"".green} lines that were not recognized"))
    Printer::debug("",debug_msg:"\tShow #{(size-max).to_s.red+"".green} more") if size > max
    Printer::debug("",debug_msg:"==================")
    Printer::assert(0!=0, "",msg:"Breakpoint")
  end
end

Parser.new