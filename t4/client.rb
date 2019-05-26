# Trabalho 04 | Distribuid Hash Table
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require 'pry'
require './read_config'
require './routing_table'

class Client
  attr_reader :id, :hash, :config, :routing_table
  def initialize(id)
    @id = id
    @config = ReadConfig.new
    @routing_table = RoutingTable.new(id)
    initialize_hash

    @thr_receive = receive_msg
    input
    @thr_receive.join
  end

  def initialize_hash
    @hash = {}
    hash_range = (@config.hash_size * @id)..(@config.hash_size * @id + @config.hash_size - 1)
    hash_range.each do |key|
      @hash[key.to_s.to_sym] = {}
    end
  end

  def send_msg(key, value)
    id = @routing_table.foresee_router(key)
    ip = @config.routers[id.to_s.to_i][0]
    port = @config.routers[id.to_s.to_i][1]
    TCPSocket.open(ip, port) do |server|
      server.write [
        key.ljust(10),
        value.ljust(30)
      ].pack('A10A30')
    end
  end

  def receive_msg
    @thr1 = Thread.new do
      ip = @config.routers[@id][0]
      port = @config.routers[@id][1]
      TCPServer.open(ip, port) do |server|
        loop do
          con = server.accept
          rst = con.recv(1024).unpack('A10A30')
          key = rst[0]
          value = rst[1]
          assemble_hash(key, value)
          con.close
        end
      end
    end
  end

  def input
    loop do
      menu
      op = $stdin.gets.chomp
      case op
      when '0'
        kill_threads
      when '1'
        puts 'Informe a chave: '
        key = $stdin.gets.chomp
        puts 'Informe a mensagem:'
        msg = $stdin.gets.chomp
        assemble_hash(key, msg)
      when '2'
        show_hash
      when '3'
      when '4'
        @routing_table.print_table(@id)
      else
        puts 'Informe apenas uma das opções acima!'
      end
    end
  end

  def assemble_index(key)
    (key.to_i % 6).to_s.to_sym
  end

  def assemble_hash(key, msg)
    index = assemble_index(key)

    if @hash.key? index
      @hash[index][key.to_s.to_sym] = msg
    else
      send_msg(key, msg)
    end
  end

  def menu
    puts "Cliente [#{@id}]"
    puts '-------------- OPÇÕES --------------'
    puts '[1] Escrever mensagem'
    puts '[2] Mostar Hash'
    puts '[0] Sair'
    print '-> '
  end

  def kill_threads
    Thread.kill(@thr1)
  end

  def show_hash
    puts '------------------------------------'
    @hash.each do |key, sub_hash|
      puts key.to_s + ':'
      sub_hash.each do |sub_key, value|
        puts '  ' + sub_key.to_s + ': ' + value.to_s
      end
      puts ''
    end
    puts '------------------------------------'
  end
end

if ARGV.length != 1
  puts 'Informe o ID do roteador!'
  exit
end

id = ARGV[0].to_i

# Instancia o cliente com seu id
Client.new(id)
