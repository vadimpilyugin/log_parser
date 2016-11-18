require 'rubygems' # Нужно ли?
require 'data_mapper'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require  'dm-migrations'

class LogLine
include DataMapper::Resource

property :id, Serial
property :service, String

has n, :params

# property :filename, String, :nullable => false
# property :created_at, DateTime

end

class Param
include DataMapper::Resource

property :id, Serial
property :key, String
property :value, String

belongs_to :logline
end

class Type
include DataMapper::Resource

property :id, Serial
property :key, String
property :value, String

belongs_to :logline
end

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/archive/mydb.sqlite3")
DataMapper.finalize
DataMapper.auto_migrate!

param1 = Param.create(
	key: "user-ip", 
	value: "216.92.1.102"
)
param2 = Param.create(
	key: "server-ip", 
	value: "192.168.1.102"
)
logline = LogLine.create(
	service: "sshd"
)
type = Type.create(
	key: "type"
	value: "New connection"
)