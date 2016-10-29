class Table
	def initialize
		@table = []
	end
public
	def add(hsh)
		@table << {service: hsh[:service], field: hsh[:field], value: hsh[:value], id: hsh[:id]}
	end
	def size
		@table.size
	end
end

success = 0
cnt = 0
table = Table.new
IO.readlines("./logs/auth.log").each{ |s|
	if s =~ /^[\w]+\s+\d+\s+\d{2}:\d{2}:\d{2}\s+(?<server>\w+)\s+(?<service>[\w-]+)(?<pid>\[\d+\])?:\s+(?<msg>.*)?/
		# puts "Server = #{$~[:server]}, process = #{$~[:process]}, pid = #{$~[:pid]}, msg = #{$~[:msg]}"
		success += 1
		hsh = $~
		msg = $~[:msg]
		ip_addr = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
		if hsh[:service] == "sshd"
			if msg =~ /Connection from (#{ip_addr}) port (\d+) on (#{ip_addr}) port (\d+)/
				table.add(service: hsh[:service], field: "user_ip", value: $1, id: cnt)
				table.add(service: hsh[:service], field: "server_ip", value: $3, id: cnt)
				table.add(service: hsh[:service], field: "user_port", value: $2, id: cnt)
				table.add(service: hsh[:service], field: "server_port", value: $4, id: cnt)
				table.add(service: hsh[:service], field: "meta-inf", value: {type: "new connection"}, id: cnt)
			elsif msg =~ /Connection closed by (#{ip_addr}) [preauth]/
				table.add(service: hsh[:service], field: "user_ip", value: $1, id: cnt)
				table.add(service: hsh[:service], field: "meta-inf", value: {type: "closed connection", attr1: "preauth"}, id: cnt)
			elsif msg =~ /Received disconnect from (#{ip_addr}): \d+: disconnected by (\w+)/
				table.add(service: hsh[:service], field: "user_ip", value: $1, id: cnt)
				table.add(service: hsh[:service], field: "username", value: $2, id: cnt)
				table.add(service: hsh[:service], field: "meta-inf", value: {type: "disconnect"}, id: cnt)
			else
				puts "msg = #{hsh[:msg]}"
				success -= 1
			end
		else
			success -= 1
		end
	else
		puts s
	end
	cnt += 1
}
puts "Success #{success}/#{cnt}"
puts "Table = #{table.size}"
