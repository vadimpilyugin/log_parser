require_relative 'config'
require_relative 'tools'
require_relative 'parser'
require_relative 'db'

# Class that creates the hash containing the names of the servers and the names of the log files
class Loader
  # @return [Hash] log file tree
  # {
  #   Hash.new(
  #     "<server_name_1>" => {
  #       "<abs_path_to_log_1>",
  #       "<abs_path_to_log_2>",
  #     },
  #     "<server_name_2>" => {
  #       "<abs_path_to_log_3>",
  #       "<abs_path_to_log_4>",
  #     }, 
  #     ...
  #   )
  # }
  # @raise [Error::AssertError] if directory with log files does not exist
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