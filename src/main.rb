require 'yaml'
require 'yaml/store'

$:.unshift(File.expand_path("../", __FILE__))

require 'parser'
require 'db'
require 'aggregator'

Dir.chdir(File.expand_path("../../", __FILE__))							# переходим в корень проекта
config = YAML.load_file('default.conf/parser.cfg')						# загружаем конфиг

# Подготовка данных для парсера
log_file = config["log_file"] ? config["log_file"] : "logs/access-test_log"
services_dir = config["services_dir"] ? config["services_dir"] : "default.conf/services"
error_log = config["error_log"] ? config["error_log"] : "/tmp/parser.log"
p = Parser::Parser.new filename: log_file, error_log: error_log, services_dir: services_dir
p.parse!

# Выгружаем распарсенный лог в базу данных
database_file = config["database_file"] ? config["database_file"] : "archive/test.sqlite3"
db = Database::Database.new filename: database_file, drop: true
db.save(p.table)

# Создаем отчеты по базе данных
a = Aggregator::Aggregator.new db
a.aggregate_by_keys("ip", "path").save("report/ip-path-distrib.yaml")