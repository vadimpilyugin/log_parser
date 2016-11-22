$:.unshift(File.expand_path("../", __FILE__))

require 'config'
require 'parser'
require 'db'
require 'aggregator'

Dir.chdir(File.expand_path("../../", __FILE__))
Config.new

#database_file = "archive/access.sqlite3"
#log_file = "logs/access.log"
report_only = false

if !report_only
  # Подготовка данных для парсера
  p = Parser::Parser.new #filename: log_file
  p.parse!
  
  # Выгружаем распарсенный лог в базу данных
  db = Database::Database.new #filename: database_file, drop: true
  db.save(p.table)
end

# Создаем отчеты по базе данных
a = Aggregator::Aggregator.new #database_file
# a.select(:datas => {"user-ip" => "91.224.161.69"})
a.aggregate_by_keys("user_ip", "user_port")
a.save("report/ip-port-distrib.yml")
