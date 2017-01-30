gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require  'dm-migrations'
require  'dm-aggregates'
require 'dm-transactions'

require_relative 'tools'

module Database



class Logline
include DataMapper::Resource

property :filename, String, :key => true   # имя файла лога
property :line, Integer, :key => true      # и номер строки в файле однозначно идентифицируют содержимое
has n, :datas
has n, :metas

  def [](hsh)
    if hsh.keys[0] == :data
      a = self.datas.first(:name => hsh[:data])
    elsif hsh.keys[0] == :meta
      a = self.metas.first(:name => hsh[:meta])
    else
      Tools.assert false, "No such key #{hsh}"
    end
    return a.value if a
    return nil
  end

  def to_a
    a = []
    a << self.filename
    a << self.line
    data_hash = {}
    self.datas.each do |data|
      data_hash.update(data.name => data.value)
    end
    a << data_hash
    meta_hash = {}
    self.metas.each do |meta|
      meta_hash.update(meta.name => meta.value)
    end
    a << meta_hash
    return a
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
  @@filename = nil

  def initialize(hsh = {})
    Config.new
    drop = hsh[:drop] ? hsh[:drop] : false                                              # нужно ли очищать базу
    filename = hsh[:filename] ? hsh[:filename] : Config["database"]["database_file"]    # можно задать файл базы
    @@filename == filename ? return : @@filename = filename
    Chdir.chdir
    Dir.mkdir("archive") if !Dir.exists? "archive"
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/#{filename}")                      # подключаемся к базе
    DataMapper.finalize
    drop ? DataMapper.auto_migrate! : DataMapper.auto_upgrade!
  end
public
  def Database.save(table)
    # DataMapper.auto_migrate!
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
        puts "Запись ##{i} сохранена: #{r.save!}"
      end
    end
    puts
  end
end
end
