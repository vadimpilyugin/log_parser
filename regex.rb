class Record < Hash
public
	def add(hsh)
		self.update(hsh) {|k,o,n| n}
	end
end
class Table < Array
public
	def add(hsh)
		self << {id: hsh[:id], service: hsh[:service], data: hsh[:data], meta: hsh[:meta]}
	end
end
class MatchData
public
	def to_h
		self.names.zip(self.captures).to_h
	end
end

success = 0
cnt = 0
table = Table.new
IO.readlines("./logs/auth.log").each{ |s|
	s =~ /^[\w]+\s+\d+\s+\d{2}:\d{2}:\d{2}\s+(?<server>\w+)\s+(?<service>[\w-]+)(?<pid>\[\d+\])?:\s+(?<msg>.*)?/
	# puts "Server = #{$~[:server]}, process = #{$~[:process]}, pid = #{$~[:pid]}, msg = #{$~[:msg]}"
	hsh = $~
	msg = $~[:msg]
	ip_addr = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
	data = Record.new
	meta = Record.new
	if hsh[:service] == "sshd"
		cnt += 1
		success += 1
		if msg =~ /Connection from (?<user-ip>#{ip_addr}) port (?<user-port>\d+) on (?<server-ip>#{ip_addr}) port (?<server-port>\d+)/
			data = $~.to_h
			meta = {type: "New connection"}
		elsif msg =~ /Connection closed by (?<user-ip>#{ip_addr}) [preauth]/
			data = $~.to_h
			meta = {type: "Closed connection", attr1: "preauth"}
		elsif msg =~ /Received disconnect from (?<user-ip>#{ip_addr}): \d+: disconnected by (?<username>\w+)/
			data = $~.to_h
			meta = {type: "Disconnect"}
		else
			#puts "msg = #{msg}"
			success -= 1
			data = {"msg" => msg}
			meta = {"type" => "unidentified"}
		end
		table.add(id: cnt, service: hsh[:service], data: data, meta: meta)
	end
}
puts "Success #{success}/#{cnt}"
puts "Table = #{table.size}"
