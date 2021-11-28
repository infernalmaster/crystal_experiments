require "socket"
require "json"

class Request
  @io : TCPSocket
  @parsed = false
  @method = ""
  @path = ""
  @headers = Hash(String, String).new
  @body : String?

  getter :parsed, :method, :path, :headers, :body

  def initialize(@io)
    @parsed = (
      read_start_line &&
      read_headers &&
      read_body
    )
  end

  def read_start_line
    start_line = @io.gets
    return false if !start_line
    @method, @path, _protocol = start_line.split(" ")

    true
  end

  def read_headers
    loop do
      line = @io.gets
      return false if !line
      break if line == "" # end of headers section

      header, value = line.split(": ")
      @headers[header] = value
    end

    true
  end

  def read_body
    return true if !@headers.has_key?("Content-Length")

    body_length = @headers["Content-Length"].to_i
    @body = @io.gets(body_length)

    true
  end

  def keep_alive?
    @headers["Connection"]? == "keep-alive"
  end
end

class Response
  @io : TCPSocket
  @headers = Hash(String, String).new

  PHRASES = {
    100 => "Continue",
    101 => "Switching Protocols",
    200 => "OK",
    201 => "Created",
    202 => "Accepted",
    203 => "Non-Authoritative Information",
    204 => "No Content",
    205 => "Reset Content",
    206 => "Partial Content",
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See Other",
    304 => "Not Modified",
    305 => "Use Proxy",
    307 => "Temporary Redirect",
    400 => "Bad Request",
    401 => "Unauthorized",
    402 => "Payment Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    407 => "Proxy Authentication Required",
    408 => "Request Timeout",
    409 => "Conflict",
    410 => "Gone",
    411 => "Length Required",
    412 => "Precondition Failed",
    413 => "Payload Too Large",
    414 => "URI Too Long",
    415 => "Unsupported Media Type",
    416 => "Range Not Satisfiable",
    417 => "Expectation Failed",
    426 => "Upgrade Required",
    500 => "Internal Server Error",
    501 => "Not Implemented",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Timeout",
    505 => "HTTP Version Not Supported",
  }

  getter :headers

  def initialize(@io)
  end

  def send_start_line_and_headers(code : Int)
    @io << "HTTP/1.1 #{code} #{PHRASES[code]}\r\n"
    @headers.each do |key, value|
      @io << "#{key}: #{value}\r\n"
    end
    @io << "\r\n"
  end

  def send(code : Int, body : String?, content_type : String?)
    if body && content_type
      @headers["Content-Type"] = content_type
      @headers["Content-Length"] = body.to_slice.size.to_s
    end

    send_start_line_and_headers(code)

    if body && content_type
      @io << body
    end
  end

  def send_as_text(code : Int, body : String)
    send(code, body, "text/plain")
  end

  def send_as_html(code : Int, body : String)
    send(code, body, "text/html")
  end

  def send_as_json(code : Int, body : Hash)
    send(code, body.to_json, "application/json")
  end
end

def handle_request(io)
  request = Request.new(io)
  p request

  if !request.parsed
    Response.new(io).send_as_text(400, "Error 400")
    io.close
    return
  end

  response = Response.new(io)
  if request.keep_alive?
    response.headers["Connection"] = "keep-alive"
    response.headers["Keep-Alive"] = "timeout=60, max=1000"
  end
  # response.send_as_text(200, "Hello World")
  # response.send_as_json(201, {"foo" => "bar"})
  response.send_as_html(200, "<h1>Such much fun</h1><img src='/1.png' /><img src='/2.png' /><img src='/3.png' /><img src='/4.png' /><img src='/5.png' /><img src='/6.png' /><img src='/7.png' /><img src='/8.png' /><img src='/9.png' /><img src='/10.png' />")

  io.close if !request.keep_alive?
end

def handle_client(io)
  puts "OPEN connection #{io.object_id}"

  # try to reuse connection for many requsets to support "keep-alive" option
  loop do
    handle_request(io)

    break if io.closed?
  end

  puts "CLOSED connection #{io.object_id}"
rescue IO::Error
  puts "Error IO"
  io.close if !io.closed?
end

server = TCPServer.new("localhost", 1234)

while io = server.accept?
  spawn handle_client(io)
end
