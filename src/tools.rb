require 'fileutils'

class Tools
  def initialize
    Config.new
    Chdir.chdir
  end
public
  def Tools.clean
  	`mkdir tmp`
    FileUtils.rm_rf(Dir.glob('./tmp/*'))
  end
end

