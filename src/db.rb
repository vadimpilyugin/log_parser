require 'rubygems' # Нужно ли?
gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require  'dm-migrations'

module Database

class Logline
include DataMapper::Resource

property :filename, String, :key => true			# имя файла лога
property :line, Integer, :key => true				# и номер строки в файле однозначно идентифицируют содержимое

has n, :datas
has n, :metas
end

class Data
include DataMapper::Resource

property :id, Serial
property :key_string, String
property :value, String

belongs_to :logline
end

class Meta
include DataMapper::Resource

property :id, Serial
property :key_string, String
property :value, String

belongs_to :logline
end

class Database
	def initialize(hsh = {})
		Dir.chdir(File.expand_path("../../", __FILE__))								# корневая директория проекта
		@filename = hsh[:filename] ? hsh[:filename] : "archive/mydb.sqlite3"		# это имя базы данных по умолчанию
		@dbname = "sqlite3://#{Dir.pwd}/#{@filename}"
		DataMapper.setup(:default, @dbname)
		DataMapper.finalize
		DataMapper.auto_migrate!
	end
public
	def drop
		DataMapper.setup(:default, @dbname)
		DataMapper.auto_migrate!
	end

	def save(table)
		resources = []
		table.each do |ar|
			data = []
			meta = []
			ar[2].each_pair do |k, v|
				data << Hash.new(key_string: k, value: v)
			end
			ar[3].each_pair do |k, v|
				meta << Hash.new(key_string: k, value: v)
			end 
			resources << Logline.new(
				filename: ar[0],
				line: ar[1], 
				datas: data, 
				metas: meta
			)
		end
		puts "hello"
		resources.each_with_index do |r, i|
			puts "##{i}: #{r.save}"
		end
	end

end
end