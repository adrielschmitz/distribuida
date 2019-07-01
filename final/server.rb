# Trabalho Final
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require './routing_table'
require './package'
require 'pry'

module Server
  # Classe responsavel por enviar, reveber e reencaminhar as mensagens
  class Router
    attr_reader :id, :routing_table, :package, :types
    def initialize(id)
      @id = id
      @routing_table = Server::RoutingTable.new(id)
      @package = Server::Package.new
      @types = [0, 1, 2]
      @vote_queue = []
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
    rescue Errno::ECONNREFUSED#, SocketError
      start_election_server(id) if @routing_table.kill(id)
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
      puts pack[:reciver]
      if pack[:reciver].to_s != @id.to_s
        redirect_message(pack, package_recived)
        return
      end

      if pack[:message_type].zero?
        # Pacote de mensagem
      elsif pack[:message_type] == 1
        @routing_table.bellman_ford(pack[:sender], pack[:hash])
      elsif pack[:message_type] == 2
        election_server(pack[:hash][:id], pack[:hash][:captain]) # Eleição iniciada
      elsif pack[:message_type] == 3
        @vote_queue << pack[:hash]
      end
    end

    def redirect_message(pack, package_recived)
      ip, port = @routing_table.find_next_hop(pack[:reciver])

      TCPSocket.open(ip, port) do |server|
        server.write(package_recived)
      end
    rescue Errno::ECONNREFUSED
      nil
    end

    def multicast
      Thread.new do
        @routing_table.connections.each do |router_id|
          ip, port = @routing_table.find_router(router_id)
          send_message(router_id, ip, port, 1, '', @routing_table.table)
        end
        star_election_type(@id)

        loop do
          @routing_table.connections.each do |router_id|
            ip, port = @routing_table.find_router(router_id)
            send_message(router_id.to_s, ip, port, 1, '', @routing_table.table)
          end
          @routing_table.print_table
          sleep(1)
        end
      end
    end

    def star_election_type(id)
      sleep(4)
      type = find_type(id)
      @routing_table.table[@id.to_s.to_sym][:type] = type
    end

    def start_election_server(id)
      return if captain?

      @vote_queue = []
      Thread.new do
        @routing_table.table[@id.to_s.to_sym][:captain] = 1
        @routing_table.table.each do |key, router| # Envia para todos os roteadores
          next if router[:next_hop] == -1 && key.to_s.to_i == id.to_i || key.to_s.to_i == @id

          ip, port = @routing_table.find_next_hop(key.to_s.to_i)
          send_message(key, ip, port, 2, '', { id: id, captain: @id })
        end
        election_server(id, @id)
        calculate_votes
      end
    end

    def election_server(id, captain_id)
      type = find_type(id)
      router = find_less_requested_server(id)

      return @vote_queue << { id: router, type: type } if captain_id.to_s == @id.to_s

      ip, port = @routing_table.find_next_hop(captain_id.to_s.to_i)
      send_message(captain_id, ip, port, 3, '', { id: router, type: type })
    end

    def calculate_votes
      Thread.new do
        sleep(4)
        ids = []
        @vote_queue.each do |v|
          ids << v[:id]
        end
        types = [0, 0, 0]
        bigg = -1
        id = -1
        @routing_table.table.each do |router_id, router|
          next if router[:next_hop] == -1

          types[router[:type].to_s.to_i]

          if bigg < ids.count(router_id.to_s.to_i)
            bigg = ids.count(router_id.to_s.to_i)
            id = router_id.to_s.to_i
          end
        end
        type = types.find_index(types.max)

        @routing_table.table[id.to_s.to_sym][:type] = type
        @routing_table.table[@id.to_s.to_sym][:captain] = 0
      end
    end

    def find_type(id)
      table = {}
      @routing_table.table.each do |router_id, router|
        table[router_id] = router if router[:next_hop] != -1 && router_id.to_s != id.to_s
      end
      types = search_type_missing(table)

      return find_most_requested(table) if types.empty? # Busca o maior requisições

      types[rand(0..types.size - 1)] # Encontra um tipo ainda não atendido
    end

    def search_type_missing(table)
      types = [0, 1, 2]
      table.each do |_, router|
        break if types.empty?

        types.delete(router[:type])
      end
      types
    end

    # Encontra o tipo do mais requisitado
    def find_most_requested(table)
      types_counter = [1, 1, 1]
      counter = [0, 0, 0]
      table.each do |_, router|
        next if router[:type].to_i == -1

        types_counter[router[:type].to_i] += 1
        counter[router[:type].to_i] += router[:count].to_i
      end
      temp = []
      counter.each_with_index { |value, key| temp << value / types_counter[key] }
      temp.find_index(temp.max)
    end

    def captain?
      captain = false
      @routing_table.table.each do |_, router|
        if router[:captain] == 1
          captain = true
          break
        end
      end
      captain
    end

    def find_less_requested_server(id)
      table = {}
      @routing_table.table.each do |router_id, router|
        table[router_id] = router if router[:next_hop] != -1 && router_id.to_s != id.to_s
      end
      ids = []
      count = []
      table.each do |router_id, router|
        next if router[:type].to_i != -1

        ids << router_id.to_s.to_i
        count << router[:count]
      end
      ids.find_index(count.min)
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
