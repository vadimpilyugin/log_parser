require_relative 'config'
require_relative 'tools'


class Loader
	def initialize
		@log_folder = Tools.abs_path Config["parser"]["log_folder"]
		Printer::assert(Dir.exist?(@log_folder), "Directory does not exist", "Directory":@log_folder)
		@logs_tree = Hash.new {|hsh,key| hsh[key] = []}
	end
	def get_logs_names
		Dir.foreach(@log_folder) do |dirname|
			if dirname != "." && dirname != ".." && File.directory?(@log_folder+dirname)
				Dir.foreach(@log_folder+dirname) do |fn|
					if fn != "." && fn != ".." && File.file?(@log_folder+dirname+"/"+fn)
						@logs_tree[dirname] << fn
					end
				end
			end
		end
		return @logs_tree
	end
end

l = Loader.new
pp l.get_logs_names