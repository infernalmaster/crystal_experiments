require "socket"

def handle_client(io)
  # START LINE:
  io << "HTTP/1.1 200 OK\r\n"

  # HEADERS:
  io << "Content-Type: text/plain\r\n"
  io << "Transfer-Encoding: chunked\r\n"
  io << "\r\n"

  # BODY:
  # first chank with with 6 bytes length (without ending "\r\n").
  io << "6\r\n"
  io << "Hello \r\n"
  # second chank with with 5 bytes length
  io << "5\r\n"
  io << "World\r\n"
  # terminating 0 length chunk
  io << "0\r\n"
  io << "\r\n"

  io.close
end

server = TCPServer.new("localhost", 1234)
while io = server.accept?
  spawn handle_client(io)
end
