gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require  'dm-migrations'
require  'dm-aggregates'
require 'dm-transactions'

module Database



class Logline
include DataMapper::Resource

property :filename, String, :key => true   # имя файла лога
property :line, Integer, :key => true      # и номер строки в файле однозначно идентифицируют содержимое
has n, :datas
has n, :metas

  def [](name)
    return self.datas.first(:name => name).value
  end
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
    drop = hsh[:drop] ? hsh[:drop] : false                                              # нужно ли очищать базу
    filename = hsh[:filename] ? hsh[:filename] : Config["database"]["database_file"]   # можно задать файл базы
    raise "Database file does not exist: #{filename}" if !File.exists? filename
    Dir.chdir(File.expand_path("../../", __FILE__))                                     # переход в корень проекта
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/#{filename}")                      # подключаемся к базе
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
    Logline.transaction do |t|
      resources.each_with_index do |r, i|
        puts "##{i}: #{r.save!}"
      end
    end
    puts
  end
end
end
