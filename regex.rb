class Record < Hash
public
	def add(hsh)
		self.update(hsh) {|k,o,n| n}
	end
	def values=(hsh)
		raise "Can't assign value to Record" unless hsh.class == {}.class
		self.clear.update(hsh)
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
add_to = 0
table = Table.new
IO.readlines("./logs/auth.log").each{ |s|
	s =~ /^[\w]+\s+\d+\s+\d{2}:\d{2}:\d{2}\s+(?<server>\w+)\s+(?<service>[\w-]+)(?<pid>\[\d+\])?:\s+(?<msg>.*)?/
	# puts "Server = #{$~[:server]}, process = #{$~[:process]}, pid = #{$~[:pid]}, msg = #{$~[:msg]}"
	hsh = $~
	msg = $~[:msg]
	ip = /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/
	port = /\b\d+\b/
	username = /\b[a-zA-Z0-9]+\b/
	word = username
	data = Record.new
	meta = Record.new
	if hsh[:service] == "sshd"
		cnt += 1
		add_to = 1
		inc = 1
		if msg =~ /Connection from (?<user-ip>#{ip}) port (?<user-port>#{port}) on (?<server-ip>#{ip}) port (?<server-port>#{port})/
			data.values = $~.to_h
			meta.values = {type: "New connection"}
		elsif msg =~ /Connection closed by (?<user-ip>#{ip})/
			data.values = $~.to_h
			meta.values = {type: "Closed connection"}
			meta.add(login: "preauth") if msg =~ /\[preauth\]/
		elsif msg =~ /Received disconnect from (?<user-ip>#{ip}): \d+:\s+(?:disconnected by (?<username>#{username})|\[preauth\])/
			if $~["username"]
				data.values = $~.to_h
				meta.values = {type: "Disconnect"}
			else 
				data.values = {"user-ip" => $~["user-ip"]}
				meta.values = {type: "Disconnect", login: "preauth"}
				if msg !~ /\[preauth\]/
					puts "ERROR!"
				end
			end
		elsif msg =~ /Accepted publickey for (?<username>#{username}) from (?<user-ip>#{ip}) port (?<user-port>#{port}) #{word}: (?<protocol>#{word}) (?<hashing-alg>#{word}):(?<publickey>#{word})/
			data.values = $~.to_h
			meta.values = {type: "Accepted publickey"}
		elsif msg =~ /Starting session: command for (?<username>#{username}) from (?<user-ip>#{ip}) port (?<user-port>#{port})/
			data.values = $~.to_h
			meta.values = {type: "Starting session"}
		elsif msg =~ /Disconnected from (?<user-ip>#{ip})/
			data.values = $~.to_h
			meta.values = {type: "Disconnected"}
			meta.add(login: "preauth") if msg =~ /\[preauth\]/
		elsif msg =~ /User child is on pid \d+/
			add_to = 0
		elsif msg =~ /pam_unix(sshd:session): session closed for user (?<username>#{username})/
			data.values = $~.to_h
			meta.values = {type: "Session closed"}
		else
			puts "sshd = #{msg}"
			add_to = 0
			inc = 0
			#data.values = {"msg" => msg}
			#meta.values = {"type" => "unidentified"}
		end
		success += inc
		table.add(id: cnt, service: hsh[:service], data: data, meta: meta) if add_to != 0
	end
}
puts "Success #{success}/#{cnt}"
puts "Table = #{table.size}"
