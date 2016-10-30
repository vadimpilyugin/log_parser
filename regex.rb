require 'yaml/store'

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
		self << {pid: hsh[:pid], service: hsh[:service], data: hsh[:data], meta: hsh[:meta]}
	end
end
class MatchData
public
	def to_h
		self.names.zip(self.captures).to_h
	end
end
class Parser
	def initialize(filename)
		@table = Table.new
		@log_type = case filename
					when /auth\d*\.log/ then "syslog"
					when /access-/ then "apache"
					else "unidentified"
					end
		@filename = filename
		@misses = []
	end
public
	def parse!()
		cnt = 0
		case @log_type
		when "apache"
			word = /\b[a-zA-Z0-9]+\b/
			ip = /\b[.\d]+\b/
			path = /[^\s?]+/
			code = /\b\d+\b/
			IO.readlines(@filename).each{ |s|
				cnt += 1
				data = Record.new
				if s =~ /^(?<ip>#{ip})[^"]+"(?<method>#{word}) (?<path>#{path})[^"]*" (?<code>#{code})/
					data.values = $~.to_h
					@table.add(service: "apache", data: data)
				else
					@misses << {file: filename, service: "apache", line: cnt, content: s}
				end
			}
		when "syslog"
			word = /\b[a-zA-Z0-9\-]+\b/
			pid = /\b\d+\b/
			port = pid
			ip = /\b[.\d]+\b/
			username = /\b[a-zA-Z0-9*]+\b/
			date = /\b\w{3}\s+\d{1,2}\s+[\d:]+\b/
			IO.readlines(@filename).each{ |s|
				cnt += 1
				data = Record.new
				meta = Record.new
				case s
				when /^#{date}\s+(?<server>#{word})\s+(?<service>#{word})(\[(?<pid>#{pid})\])?:\s+(?<msg>.*)/
					hsh = $~
					msg = $~[:msg]
					data.clear
					meta.clear
					add_to = 1
					case hsh[:service]
					when "sshd"
						case msg
						when /Connection from (?<user-ip>#{ip}) port (?<user-port>#{port}) on (?<server-ip>#{ip}) port (?<server-port>#{port})/
							data.values = $~.to_h
							meta.values = {type: "New connection"}
						when 	/Received disconnect from (?<user-ip>#{ip})/, 
								/Disconnected from (?<user-ip>#{ip})/, 
								/Connection closed by (?<user-ip>#{ip})/, 
								/Connection reset by (?<user-ip>#{ip})/
							data.values = {"user-ip" => $~["user-ip"]}
							meta.values = {type: "Disconnect"}
							if msg =~ /Auth fail/
								meta.add(reason: "Auth fail")
							elsif msg =~ /disconnected by (?<username>#{username})/
								data.add("username" => $~["username"])
								meta.add(reason: "by user")
							end
							meta.add(login: "preauth") if msg =~ /\[preauth\]/
						when /Accepted publickey for (?<username>#{username}) from (?<user-ip>#{ip}) port (?<user-port>#{port}) #{word}: (?<protocol>#{word}) (?<hashing-alg>#{word}):(?<publickey>#{word})/
							data.values = $~.to_h
							meta.values = {type: "Accepted publickey"}
						when /pam_unix\(sshd:session\): session (?<action>#{word}) for user (?<username>#{username})/
							data.values = {"username" => $~["username"]}
							meta.values = {type: "pam_unix", action: "Session #{$~[:action]}", father: "sshd"}
						when /^Failed (?<what>#{word})/
							data.values = {"type" => $~["what"]}
							meta.values = {type: "Auth fail"}
							case msg
							when 	/for invalid user (?<username>#{username})/, 
									/for (?<username>#{username})/
								data.add("username" => $~["username"])
							end
							if msg =~ /from (?<user-ip>#{ip}) port (?<user-port>#{port})/
								data.add($~.to_h)
							end
						when /Invalid user (?<username>#{username}) from (?<user-ip>#{ip})/
							data.values = $~.to_h
							meta.values = {type: "Invalid user"}
						when /Postponed publickey for (?<username>#{username}) from (?<user-ip>#{ip}) port (?<user-port>#{port})/
							data.values = $~.to_h
							meta.values = {type: "Postponed publickey"}
						when 	/pam_unix\(sshd:auth\): check pass; user unknown/,
								/pam_unix\(sshd:auth\): authentication failure|PAM \d+ more authentication failures|PAM: Authentication failure/,
								/PAM 1 more authentication failure/,
								/(Failed|Postponed) keyboard-interactive\b/,
								/User child is on pid \d+/,
								/input_userauth_request:/ ,
								/Did not receive identification string/,
								/Too many authentication failures/,
								/ignoring max retries/,
								/maximum authentication attempts exceeded/,
								/Unable to negotiate with/,
								/^Starting session/,
								/Server listening|Received SIGHUP|Bad protocol version/
							add_to = 0
						else
							add_to = 0
							puts "#{hsh[:service]} = #{msg}"
							@misses << {file: @filename, service: hsh[:service], line: cnt, content: msg}
						end
					when "CRON"
						case msg
						when /pam_unix\(cron:session\): session (?<action>#{word}) for user (?<username>#{username})/
							data.values = {"username" => $~["username"]}
							meta.values = {type: "pam_unix", action: "Session #{$~[:action]}", father: "CRON"}
						else
							add_to = 0
							puts "#{hsh[:service]} = #{msg}"
							@misses << {file: filename, service: hsh[:service], line: cnt, content: msg}
						end
					when "systemd", "systemd-logind"
						case msg
						when /New session (?<pid>\d+) of user (?<username>#{username})/
							data.values = $~.to_h
							meta.values = {type: "Session", action: "new"}
						when /pam_unix\(systemd-user:session\): session (?<action>#{word}) for user (?<username>#{username})/
							data.values = $~.to_h
							meta.values = {type: "Session", action: $~[:action]}
						when /Removed session (?<pid>\d+)/
							data.values = $~.to_h
							meta.values = {type: "Session", action: "removed"}
						else
							add_to = 0
							puts "#{hsh[:service]} = #{msg}"
							@misses << {file: filename, service: hsh[:service], line: cnt, content: msg}
						end
					end
					@table.add(pid: cnt, service: hsh[:service], data: data, meta: meta) if add_to != 0
				else
					puts "syslog = #{s}"
					@misses << {file: @filename, service: "syslog", line: cnt, content: s}
				end
			}
		when "unidentified"
			puts "Warning! Log type is unknown"
		end
		puts "Success #{@table.size}/#{@misses.size+@table.size}"
		puts "Table = #{@table.size} elements"
		puts "Misses = #{@misses.size} elements"
	end
	def store(filename)
		storage = YAML::Store.new filename
		storage.transaction do
	  		storage["Hits"] = @table
	  		storage["Misses"] = @misses
	  	end
	end
end	

p = Parser.new("logs/access-parallel_ru_log")
p.parse!
p.store("archive/access_log.store")