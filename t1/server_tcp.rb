require 'socket'
require 'pry'

class Server
  def initialize(address, port)
    @server_socket = TCPServer.open(port, address)

    @dados_con = {}
    @dados_client = {}

    @dados_con[:server] = @server_socket
    @dados_con[:clients] = @dados_client

    puts 'Iniciando servidor .......'
    run
  end

  def run
    loop do
      client_connection = @server_socket.accept
      Thread.start(client_connection) do |conn|
        conn_id = conn.gets.chomp.to_sym
        if @dados_con[:clients][conn_id] != nil
          conn.puts 'Já existe uma conexão com esse cliente'
          Thread.kill(Thread.current)
        else
          puts "Estabelecendo conexão com cliente #{conn_id} => #{conn}"
          @dados_con[:clients][conn_id] = conn

          send_msg(conn_id, conn)
        end
      end
    end
  end

  def send_msg(client_id, connection)
    message = connection.gets.chomp
    puts message
    @dados_con[:clients][client_id].puts "#{client_id} : #{message}"
    @dados_con[:clients][client_id] = nil
  end
end

Server.new(8080, 'localhost')
