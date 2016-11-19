module Regexes
	Word = "\\b[a-zA-Z0-9]+\\b"
	Ip = "\\b[.\d]+\\b"
	Path = "[^\\s\\?]+"
	Code = "\\d+"
	Pid = Code
	Port = Pid
	Username = "\\b[a-zA-Z0-9]+\\b"
	#Date = "\\b\\w{3}\\s+\\d{1,2}\\s+[\\d:]+\\b"
	Date = "(\\S+\\s+){3}"
	Apache = %r{
		^(?<ip>\S+)									# 141.8.142.23
		[^"]+"										# - - [09/Oct/2016:06:35:46 +0300]"
		(?<method>\S+)\s (?<path>#{Path})			# GET /images/logos/russia/vmk.gif
		[^"]+"\s (?<code>\S+)						# HTTP/1.0" 404
	}x
	Syslog = %r{
		^#{Date}	 								# Oct  9 06:36:12 - три первых слова
		(?<server>\S+)\s+ 							# newserv
		(?<service>[^\[:]+)							# systemd-logind - все, вплоть до квадратной скобки или :
		(\[(?<pid>#{Pid})\])?						# [10405] - может идти, а может и не идти за именем сервиса
		:\s+(?<msg>.*)								# : Accepted publickey for autocheck
	}x
	Unidentified = %r{.*}
end