# Trabalho Final
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require './routing_table'

class Server
  attr_reader :id, :routing_table
  def initialize(id)
    @id = id
    @routing_table = Table::RoutingTable.new(id)

    @thr_receive = receive_msg
    @thr_receive.join
  end

  def send_msg(send_router, controller, key, value)
    TCPSocket.open(ip, port) do |server|
      server.write [
        send_router,
        controller,
        key.ljust(10),
        value.ljust(30)
      ].pack('LLA10A30')
    end
  rescue Errno::ECONNREFUSED
    puts 'Impossível se conectar com o servidor!'
  end

  def receive_msg
    @thr1 = Thread.new do
      ip = @config.routers[@id][0]
      port = @config.routers[@id][1]
      TCPServer.open(ip, port) do |server|
        loop do
          con = server.accept
          rst = con.recv(1024).unpack('LLA10A30')
          send_router = rst[0]
          controller = rst[1]
          key = rst[2]
          value = rst[3]
          unpack_message(send_router, controller, key, value)
          con.close
        end
      end
    end
  end

  def kill_threads
    Thread.kill(@thr1)
  end
end

if ARGV.length != 1
  puts 'Informe o ID do roteador!'
  exit
end

id = ARGV[0].to_i

# Instancia o cliente com seu id
Router::Server.new(id)
