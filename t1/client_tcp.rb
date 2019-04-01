require 'socket'

class Client
  def initialize(socket)
    puts 'HAH'
    @socket = socket

    @request_object = send_msg
    @response_object = listen_response

    @request_object.join
    @response_object.join
  end

  def send_msg
    @thr = Thread.new do
      @socket.puts '2'
      message = $stdin.gets.chomp
      @socket.puts message
    end
  end

  def listen_response
    Thread.new do
      response = @socket.gets.chomp
      puts "Resposta: #{response}"
      @socket.close
      Thread.kill(@thr)
      Thread.kill(Thread.current)
    end
  end
end

socket = TCPSocket.open('localhost', 8080)
Client.new(socket)
