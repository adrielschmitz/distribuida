# Trabalho Final
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require './routing_table'
require './package'

module Server
  # Classe responsavel por enviar, reveber e reencaminhar as mensagens
  class Router
    attr_reader :id, :routing_table
    def initialize(id)
      @id = id
      @routing_table = Server::RoutingTable.new(id)

      @thr_receive = receive_msg
      @thr_multicast = multicast
      @thr_receive.join
      @thr_multicast.join
    end

    def send_message(id, ip, port, type, message)
      TCPSocket.open(ip, port) do |server|
        @routing_table.alive(id) if type == 1

        server.write(
          Server::Package.pack(type, @id, id, message, @routing_table.table)
        )
      end
    rescue Errno::ECONNREFUSED
      # puts "Impossível se conectar com o servidor! Server id: #{id} ip: #{ip} port: #{port}"
      @routing_table.kill(id)
      @routing_table.print_table
    end

    def receive_msg
      Thread.new do
        ip, port = @routing_table.find_router(@id)
        TCPServer.open(ip, port) do |server|
          loop do
            con = server.accept
            Server::Package.unpack(con.recv(1024))
            con.close
          end
        end
      end
    end

    def multicast
      Thread.new do
        loop do
          @routing_table.connections.each do |connection|
            ip, port = @routing_table.find_router(connection)
            send_message(connection, ip, port, 1, '')
          end
          sleep(10)
        end
      end
    end
  end
end

if ARGV.length != 1
  puts 'Informe o ID do roteador!'
  exit
end

id = ARGV[0].to_i

# Instancia o servidor com seu id
Server::Router.new(id)
