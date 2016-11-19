require 'parser'
require 'db'


log_name = "access-test_log"
p = Parser.new(filename: "logs/#{log_name}")
db = Database::Database.new(filename: "archive/#{log_name}.sqlite3")
db.save(table: p.parse!.table)