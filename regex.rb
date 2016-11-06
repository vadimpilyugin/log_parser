class LogRegex
	Word = "\\b[a-zA-Z0-9]+\\b"
	Ip = "\\b[.\d]+\\b"
	Path = "[^\\s?]+"
	Code = "\\b\\d+\\b"
	Pid = Code
	Port = Pid
	Username = "\\b[a-zA-Z0-9]+\\b"
	Date = "\\b\\w{3}\\s+\\d{1,2}\\s+[\\d:]+\\b"
	Config = {
		:apache => {
			:main => /^(?<ip>#{Ip})[^"]+"(?<method>#{Word}) (?<path>#{Path})[^"]*" (?<code>#{Code})/, 
			
		}
		:syslog => {
			:main => /^#{Date}\s+(?<server>#{Word})\s+(?<service>#{Word})(\[(?<pid>#{Pid})\])?:\s+(?<msg>.*)/
			:
	}