require "socket"

def handle_client(io)
  response_body = "Hello World"

  # https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html
  # Request and Response messages use the generic message format of RFC 822 for transferring entities.
  # Both types of message consist of a start-line, zero or more header fields (also known as "headers"),
  # an empty line (i.e., a line with nothing preceding the CRLF) indicating the end of the header fields,
  # and possibly a message-body.
  #     generic-message = start-line
  #                       *(message-header CRLF)
  #                       CRLF
  #                       [ message-body ]

  # START LINE
  io << "HTTP/1.1 200 OK\r\n"
  # HTTP/1.1 - protocol and verions
  # 200      - status code
  # OK       - reason phrase, it could be anything
  # https://datatracker.ietf.org/doc/html/rfc7231#section-6.1 :
  # The reason phrases listed here are only recommendations
  #  -- they can be replaced by local equivalents without affecting the protocol.

  # HEADERS
  io << "Content-Type: text/plain\r\n"
  io << "Content-Length: #{response_body.to_slice.size}\r\n"

  # CRLF
  io << "\r\n"

  # BODY
  io << response_body

  # we are closing connection but we could keep it and reuse for new requets
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Connection_management_in_HTTP_1.x#short-lived_connections
  io.close
end

# Open in browser http://localhost:1234
server = TCPServer.new("localhost", 1234)

while io = server.accept?
  spawn handle_client(io)
end
