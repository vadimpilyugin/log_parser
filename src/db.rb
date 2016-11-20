require 'rubygems' # Нужно ли?
gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require  'dm-migrations'
require  'dm-aggregates'

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
property :name, String
property :value, String

belongs_to :logline
end

class Meta
include DataMapper::Resource

property :id, Serial
property :name, String
property :value, String

belongs_to :logline
end

class Database
	def initialize(hsh = {})
		drop = hsh[:drop]														# нужно ли очищать базу
		filename = hsh[:filename] ? hsh[:filename] : "archive/mydb.sqlite3"		# это имя базы данных по умолчанию
		Dir.chdir(File.expand_path("../../", __FILE__))							# переход в корень проекта
		DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/#{filename}")			# подключаемся к базе
		DataMapper.finalize
		drop ? DataMapper.auto_migrate! : DataMapper.auto_upgrade!
	end
public
	def save(table)
		resources = []
		table.each do |ar|
			data = []
			meta = []
			ar[2].each_pair do |k, v|
				data << {:name => k, :value => v}
			end
			ar[3].each_pair do |k, v|
				meta << {:name => k, :value => v}
			end
			resources << Logline.new(
				filename: ar[0],
				line: ar[1], 
				datas: data, 
				metas: meta
			)
		end
		puts
		puts "Закончили создание ресурсов, начинаем сохранение:"
		resources.each_with_index do |r, i|
			puts "##{i}: #{r.save!}"
		end
		puts
	end

end
end