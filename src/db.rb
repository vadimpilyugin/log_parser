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

property :id, Serial
property :server, String
property :service, String
property :time, Datetime  # 2010-11-03T21:33:00-0600; all(:time => start_t..end_t)
                          # Logline.create(:time => DateTime.new(2011,1,1,0,0,4)) 
                          # Logline.all(:time => DateTime.parse('2011-1-1T00:00:04+0100'))
has n, :datas                              

  def [](hsh)
    if hsh.keys[0] == :data
      a = self.datas.first(:name => hsh[:data])
    else
      Tools.assert false, "No such key #{hsh}"
    end
    return a.value if a
    return nil
  end

  def to_a
    a = []
    a << self.id
    a << self.server
    a << self.service
    a << self.time
    data_hash = {}
    self.datas.each do |data|
      data_hash.update(data.name => data.value)
    end
    a << data_hash
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

class Database
  @@db = nil

  def initialize(hsh)
    @@db ? return @@db : @@db = "New database"
    @@filename = Config["database"]["database_file"]
    assert(Tools.file_exists? (@@filename), "Database file not found", "Filename":@@filename)
    drop = hsh[:drop] ? hsh[:drop] : false
    DataMapper.setup(:default, "sqlite3://#{Tools.abs_path(filename)}")
    


  def initialize(drop = false)
    return @@filename if @@filename
    filename = Config["database"]["database_file"]
    # Tools.mkdir("archive")
    DataMapper.finalize
    drop ? DataMapper.auto_migrate! : DataMapper.auto_upgrade!
  end
public
  def Database.save(table)
    # DataMapper.auto_migrate!
    resources = []
    table.each do |ar|
      data = []
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
