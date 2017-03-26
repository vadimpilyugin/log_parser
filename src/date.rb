# CreateDate.create(hsh):
# hsh - хэш, содержащий поля year,month,day,hour,minute,second,timezone
# Возвращает объект Ruby Time, представляющий это время. Если в хэше
# какие-то из параметров равны nil, они берутся из текущего времени

class CreateDate
  def self.create(hsh)
  	default_time = Time.now
  	return Time.new(
  	  hsh[:year] ? hsh[:year] : default_time.year,
  	  hsh[:month] ? hsh[:month] : default_time.month,
  	  hsh[:day] ? hsh[:day] : default_time.day,
  	  hsh[:hour] ? hsh[:hour] : default_time.hour,
  	  hsh[:minute] ? hsh[:minute] : default_time.min,
  	  hsh[:second] ? hsh[:second] : default_time.sec,
  	)
  end
end