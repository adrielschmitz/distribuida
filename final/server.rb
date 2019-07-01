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
    attr_reader :id, :routing_table, :package
    def initialize(id)
      @id = id
      @routing_table = Server::RoutingTable.new(id)
      @package = Server::Package.new
      @thr_receive = receive_msg
      @thr_multicast = multicast
      @thr_receive.join
      @thr_multicast.join
    end

    def send_message(id, ip, port, message_type, message, hash)
      TCPSocket.open(ip, port) do |server|
        @routing_table.alive(id) if message_type == 1

        server.write(
          package.pack(message_type, @id, id, message, hash)
        )
      end
    rescue Errno::ECONNREFUSED
      election(id) if @routing_table.kill(id)
    end

    def receive_msg
      Thread.new do
        ip, port = @routing_table.find_router(@id)
        TCPServer.open(ip, port) do |server|
          loop do
            con = server.accept
            treat_package(con.recv(2048))
            con.close
          end
        end
      end
    end

    def treat_package(package_recived)
      pack = @package.unpack(package_recived)
      if pack[:message_type].zero?
        # Pacote de mensagem
      elsif pack[:message_type] == 1
        @routing_table.bellman_ford(pack[:sender], pack[:hash])
      elsif pack[:message_type] == 2
        # Eleição iniciada
      end
    end

    def multicast
      Thread.new do
        loop do
          @routing_table.connections.each do |router_id|
            ip, port = @routing_table.find_router(router_id)
            send_message(router_id, ip, port, 1, '', @routing_table.table)
          end
          (system 'clear')
          @routing_table.print_table
          sleep(3)
        end
      end
    end

    def start_election(id)
      Thread.new do
        @routing_table.table.each do |key, router|
          next if router[:next_hop] == -1 && key.to_s.to_i == id.to_i

          ip, port = find_router(key.to_s.to_i)
          send_message(connection, ip, port, 2, '', @routing_table.table)
        end
      end
    end

    def election(id)
      table = {}
      @routing_table.table.each do |k, v|
        table[k] = v if v[:next_hop] != -1 && k.to_s != id.to_s
      end

      table = table.group_by { |_, value| value[:type] }

      lowersts = []
      table.each do |_, type|
        table_ordered = type.sort_by { |_, router| router[:count] }
        lowersts << table_ordered.first if table_ordered.size > 1
      end
      puts "L: #{lowersts}"
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
