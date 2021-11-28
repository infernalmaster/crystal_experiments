require "socket"

def handle_client(io)
  #  read request
  loop do
    line = io.gets
    puts line
    break if line == "" # end of headers section
  end
  # we don't read request body for now

  io << "HTTP/1.1 200 OK\r\n"
  io << "Content-Length: 0\r\n"
  io << "\r\n"

  io.close
end

server = TCPServer.new("localhost", 1234)
while io = server.accept?
  spawn handle_client(io)
end
