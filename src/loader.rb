require_relative 'config'
require_relative 'tools'
require_relative 'parser'
require_relative 'db'

class Loader
  def Loader.get_logs_names
    @log_folder = Tools.abs_path Config["parser"]["log_folder"]
    Printer::assert(expr:Dir.exist?(@log_folder), msg:"Directory #{@log_folder} does not exist")
    @logs_tree = Hash.new {|hsh,key| hsh[key] = []}
    Dir.foreach(@log_folder) do |dirname|
      if dirname != "." && dirname != ".." && File.directory?(@log_folder+dirname)
        Dir.foreach(@log_folder+dirname) do |fn|
          if fn != "." && fn != ".." && File.file?(@log_folder+dirname+"/"+fn)
            @logs_tree[dirname] << (@log_folder + dirname + "/" + fn)
          end
        end
      end
    end
  return @logs_tree
  end
end

# pp Loader.get_logs_names