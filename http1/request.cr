require "socket"

io = TCPSocket.new("google.com", 80)
io.puts "GET / HTTP/1.1"
io.puts << "User-Agent: Crystal"
io.puts "Accept: text/html"
io.puts ""
