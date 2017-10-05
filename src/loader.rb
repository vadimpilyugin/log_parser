require_relative 'config'
require_relative 'tools'
# require_relative 'parser'

# Class that creates the hash containing the names of the servers and the names of the log files
# class Loader
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
#   def Loader.get_logs_names
#     @log_folder = Tools.abs_path Config["parser"]["log_folder"]
#     Printer::assert(expr:Dir.exist?(@log_folder), msg:"Directory #{@log_folder} does not exist")
#     @logs_tree = Hash.new {|hsh,key| hsh[key] = []}
#     Dir.foreach(@log_folder) do |dirname|
#       if dirname != "." && dirname != ".." && File.directory?(@log_folder+dirname)
#         Dir.foreach(@log_folder+dirname) do |filename|
#           if filename != "." && filename != ".." && File.file?(@log_folder+dirname+"/"+filename)
#             @logs_tree[dirname] << (@log_folder + dirname + "/" + filename)
#           end
#         end
#       end
#     end
#   return @logs_tree
#   end
# end

class LoglineStream
  
  DEFAULT_LOG_FOLDER = Tools.abs_path Config["parser"]["log_folder"]
  DEFAULT_SERVER = "undefined"
  SLASH = '/'
  # чтобы обязательно последним стоял слэш
  DEFAULT_LOG_FOLDER << SLASH unless DEFAULT_LOG_FOLDER[-1] == SLASH

  def self.from_directory(log_folder:DEFAULT_LOG_FOLDER)
    # возвращается итератор по строкам логов
    Enumerator.new do |yielder|
      # для каждого имени файла внутри директории с логами
      Dir.foreach(log_folder) do |server_name|
        # папка сервера это папка логов плюс имя сервера
        server_folder = log_folder+server_name
        # если это папка и не . или ..
        if File.directory?(server_folder) && server_name != '.' && server_name != '..'
          # для каждого имени файла внутри папки сервера
          Dir.foreach(server_folder) do |filename|
            # получаем полное имя файла
            full_path = server_folder+SLASH+filename
            # проверяем, что файл не является . или .. или директорией
            if File.file? full_path
              # открываем файл
              File.open(full_path, 'r') do |file|
                # каждую строку файла отдаем как результат
                file.each do |line| 
                  yielder.yield(
                    logline:line, 
                    filename:"/#{server_name}/#{filename}", 
                    server:server_name
                  )
                end
              end
            end
          end
        end
      end
    end
  end

  def self.open
    self.from_directory
  end

  def self.load_from_file(fn)
    # возвращается итератор по строкам логов
    Enumerator.new do |yielder|
      # открываем файл
      File.open(fn, 'r') do |file|
        # каждую строку файла отдаем как результат
        file.each do |line| 
          yielder.yield(
            logline: line, 
            filename: fn, 
            server: DEFAULT_SERVER
          )
        end
      end
    end
  end
end