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

  def send_msg(send_router, controller, key, value)
    id = if controller == 2
           send_router.to_i
         else
           @routing_table.foresee_router(assemble_index(key).to_s)
         end
    ip = @config.routers[id.to_s.to_i][0]
    port = @config.routers[id.to_s.to_i][1]
    TCPSocket.open(ip, port) do |server|
      server.write [
        send_router,
        controller,
        key.ljust(10),
        value.ljust(30)
      ].pack('LLA10A30')
    end
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

  def unpack_message(send_router, controller, key, value)
    if controller.to_i.zero?
      assemble_hash(key, value)
    elsif controller == 1
      find_key(send_router, key)
    elsif controller == 2
      show_key_value(send_router, value)
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
        read_msg
      when '2'
        read_key
      when '3'
        show_hash
      when '4'
        @routing_table.print_table(@id)
      when '5'
        pry
      else
        puts 'Informe apenas uma das opções acima!'
      end
    end
  end

  def read_msg
    puts 'Informe a chave: '
    key = $stdin.gets.chomp
    puts 'Informe a mensagem:'
    msg = $stdin.gets.chomp
    assemble_hash(key, msg)
  end

  def assemble_index(key)
    (key.to_i % (@config.routers.size * @config.hash_size)).to_s.to_sym
  end

  def assemble_hash(key, msg)
    index = assemble_index(key)

    if @hash.key? index
      @hash[index][key.to_s.to_sym] = msg
    else
      send_msg(@id, 0, key, msg)
    end
  end

  def read_key
    puts 'Informe a chave: '
    key = $stdin.gets.chomp
    find_key(@id, key)
  end

  def find_key(send_router, key)
    index = assemble_index(key)

    if @hash.key? index
      if @hash[index].key? key.to_s.to_sym
        msg = 'Chave: ' + key.to_s + '    Valor: ' + @hash[index][key.to_s.to_sym].to_s
        show_key_value(send_router, msg)
      else
        show_key_value(send_router, 'Está chave não existe!')
      end
    else
      # Mandar buscar em outros hashs
      send_msg(send_router, 1, key, '')
    end
  end

  def show_key_value(send_router, msg)
    if send_router.to_i == @id
      puts msg
    else
      puts 'send back to: ' + send_router.to_s
      send_msg(send_router, 2, '', msg)
    end
  end

  def menu
    puts "Cliente [#{@id}]"
    puts '-------------- OPÇÕES --------------'
    puts '[1] Escrever mensagem'
    puts '[2] Procurar chave'
    puts '[3] Mostar Hash'
    puts '[4] Mostar tabela de roteamento'
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
