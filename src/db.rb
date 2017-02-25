gem 'dm-sqlite-adapter'
require 'data_mapper'
require 'dm-core'
require  'dm-migrations'
require  'dm-aggregates'
require 'dm-transactions'

require_relative 'tools'
require_relative 'config'


class Logline
  include DataMapper::Resource

  property :id, Serial
  property :server, String, :required => true
  property :service, String, :required => true
  property :time, DateTime, :required => true
                            # 2010-11-03T21:33:00-0600; all(:time => start_t..end_t)
                            # Logline.create(:time => DateTime.new(2011,1,1,0,0,4)) 
                            # Logline.all(:time => DateTime.parse('2011-1-1T00:00:04+0100'))
  property :descr, String
  has n, :linedatas  
end                            

#   def [](hsh)
#     if hsh.keys[0] == :data
#       a = self.datas.first(:name => hsh[:data])
#     else
#       Tools.assert false, "No such key #{hsh}"
#     end
#     return a.value if a
#     return nil
#   end

#   def to_a
#     a = []
#     a << self.id
#     a << self.server
#     a << self.service
#     a << self.time
#     data_hash = {}
#     self.datas.each do |data|
#       data_hash.update(data.name => data.value)
#     end
#     a << data_hash
#     return a
#   end
# end

class Linedata
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :value, String, :required => true
  belongs_to :logline
end

class Database
  @@db = nil
  @@filename = nil

  def initialize(hsh = {})
    return self if @@db
    @@db = self
    @@filename = Config["database"]["database_file"]
    drop = Config["database"]["drop"]
    Printer::note(Tools.file_exists?(@@filename), "Database file not found", "Filename":@@filename)
    
    DataMapper.setup(:default, "sqlite3://#{Tools.abs_path(@@filename)}")
    DataMapper.finalize
    drop ? DataMapper.auto_migrate! : DataMapper.auto_upgrade!
  end
public
  def Database.save(table)
    resources = []
    table.each do |hsh|
      # Printer::debug("Got a new Logline request", hsh)
      resources << Logline.new(
        server: hsh[:server],
        service: hsh[:service],
        time: hsh[:time],
        linedatas: hsh[:data_values],
        descr: hsh[:descr]
      )
    end
    Printer::debug("Закончили создание ресурсов, начинаем сохранение")
    Logline.transaction do |t|
      resources.each_with_index do |r, i|
        Printer::debug(r.save!, debug_msg:"Запись ##{i} сохранена")
      end
    end
  end
end

Database.new