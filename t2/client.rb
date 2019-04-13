# Trabalho parcial sobre modelo de comunicacao
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require './read_config'

class Client
  def initialize(server, id, max_routers)
    @server = server
    @id = id

    @thr_recive   = recive_msg
    @thr_send     = send_msg
    @thr_input    = input

    @entrada = []
    @saida = []
    inicializa_estado(max_routers)

    @thr_recive.join
    @thr_send.join
    @thr_input.join
  end

  def inicializa_estado(max_routers)
    @estado = []
    @pack_config = ''
    (0..max_routers - 1).each do |i|
      @estado[i] = 0
      @pack_config << 'L'
    end
    puts @pack_config
  end

  def new_socket
    r = ReadConfig.new
    config = if @id.zero?
               r.get_config(1)
             else
               r.get_config(0)
             end
    TCPSocket.new(config[0], config[1])
  rescue Errno::ECONNREFUSED
    nil
  end

  def send_msg
    @thr0 = Thread.new do
      loop do
        if @saida.nil? || @saida.empty?
          sleep 2
          next
        end
        socket = nil
        @estado[@id] += 1
        socket = new_socket while socket.nil?
        socket.puts @saida.slice!(0)
        socket.puts @estado.pack(@pack_config)
        socket.close
      end
    end
  end

  def recive_msg
    @thr1 = Thread.new do
      loop do
        conn = @server.accept
        Thread.start(conn) do |c|
          mensagem = c.gets.chomp
          estado = c.gets.chomp
          @entrada << { mensagem: mensagem, estado: estado.unpack(@pack_config) }
          @estado[@id] += 1
          atualizar_estado
        end
      end
    end
  end

  def input
    @thr2 = Thread.new do
      loop do
        menu
        op = $stdin.gets.chomp
        case op
        when '0'
          kill_threads
        when '1'
          puts 'Informe a mensagem:'
          @saida << $stdin.gets.chomp
          @estado[@id] += 1
        when '2'
          show
        when '3'
          show_states
        else
          puts 'Informe apenas uma das opções acima!'
        end
      end
    end
  end

  def menu
    system('clear')
    puts "Cliente [#{@id}]"
    puts '-------------- OPÇÕES --------------'
    puts '[1] Escrever mensagem'
    puts '[2] Listar mensagens'
    puts '[3] Exibir estado'
    puts '[0] Sair'
    print '-> '
  end

  def show
    system('clear')
    puts '----------------------- MENSAGENS -----------------------'
    puts @entrada
    puts '---------------------------------------------------------'
    print 'Pressione ENTER... '
    $stdin.gets
  end

  def show_states
    system('clear')
    puts '------------------------ ESTADOS ------------------------'
    @estado.each_with_index.map { |e, i| puts "[#{i}]: #{e}" }
    puts '---------------------------------------------------------'
    print 'Pressione ENTER... '
    $stdin.gets
  end

  def kill_threads
    Thread.kill(@thr0)
    Thread.kill(@thr1)
    Thread.kill(@thr2)
  end

  def atualizar_estado
    temp = @entrada.last
    temp = temp[:estado]
    @estado = @estado.each_with_index.map { |v, i| v < temp[i] ? temp[i] : v }
  end
end

if ARGV.length != 1
  puts 'Informe o ID do roteador!'
  exit
end

# Le o aquivo de configuracao
read = ReadConfig.new

# Le o argumento informado pelo usuario
id = ARGV[0].to_i
config = read.get_config(id)

# Inicia um servidor com os paramentros de ip e porta
server = TCPServer.open(config[0], config[1])

# Instancia o cliente com seu id
Client.new(server, id, read.max_routers)
