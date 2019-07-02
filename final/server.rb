# Trabalho Final
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require './routing_table'
require './package'
require './queue'

module Server
  # Classe responsavel por enviar, reveber e reencaminhar as mensagens
  class Router
    attr_reader :id, :routing_table, :package, :queue
    def initialize(id)
      @id = id
      @routing_table = Server::RoutingTable.new(id)
      @package = Server::Package.new
      @queue = Server::Queue.new(@id)
      @thr_receive = receive_msg
      @thr_multicast = multicast
      @thr_queue = wating_queue
      @thr_receive.join
      @thr_multicast.join
      @thr_queue.join
    end

    def send_message(id, ip, port, message_type, message, hash)
      TCPSocket.open(ip, port) do |server|
        @routing_table.alive(id) if message_type == 1

        server.write(
          @package.pack(message_type, @id, id, message, hash)
        )
      end
    rescue Errno::ECONNREFUSED
      @routing_table.kill(id)
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
      return resend(pack, package_recived) if pack[:reciver].to_s != @id.to_s

      if pack[:message_type].zero?
        @queue.add(pack)
        show_data
      elsif pack[:message_type] == 1
        @routing_table.bellman_ford(pack[:sender], pack[:hash])
      end
    end

    def wating_queue
      Thread.new do
        loop do
          sleep(5)
          next if @queue.empty?

          pack = @queue.first
          @queue.pop
          send_to_client(pack, true)
        end
      end
    end

    def send_to_client(pack, success)
      TCPSocket.open('127.0.0.1', 8010) do |server|
        server.write(
          @package.pack(
            pack[:message_type],
            @id, pack[:sender],
            pack[:message],
            { success: success }
          )
        )
      end
      @package.update_log(pack, id, true)
    rescue Errno::ECONNREFUSED
      @queue.add(pack)
      @package.update_log(pack, id, false)
    end

    def resend(pack, package_recived)
      ip, port = @routing_table.find_next_hop(pack[:reciver])
      raise Errno::ECONNREFUSED if ip.nil? || port.nil?

      TCPSocket.open(ip, port) do |server|
        server.write(package_recived)
      end
    rescue Errno::ECONNREFUSED
      send_to_client(pack, false)
      @package.update_log(pack, id, false)
    end

    def multicast
      Thread.new do
        loop do
          @routing_table.connections.each do |router_id|
            ip, port = @routing_table.find_router(router_id)
            send_message(router_id, ip, port, 1, '', @routing_table.table)
          end
          show_data
          sleep(3)
        end
      end
    end

    def show_data
      (system 'clear')
      @routing_table.print_table
      @queue.print
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
