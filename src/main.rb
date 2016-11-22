$:.unshift(File.expand_path("../", __FILE__))

require 'config'
require 'parser'
require 'db'
require 'aggregator'

Dir.chdir(File.expand_path("../../", __FILE__))
Config.load! "default.conf/config.yml"

# Подготовка данных для парсера
p = Parser::Parser.new filename: "logs/access.log"
p.parse!

# Выгружаем распарсенный лог в базу данных
database_file = "archive/test.sqlite3"
db = Database::Database.new filename: database_file, drop: true
db.save(p.table)

# Создаем отчеты по базе данных
a = Aggregator::Aggregator.new filename: database_file
a.aggregate_by_keys("ip", "path").save("report/report.yml")
