require 'socket'
require './read_config'

class Client
  def initialize(server, id)
    @server = server
    @id = id

    print 'Inicializando ..'
    @thr_recive   = recive_msg
    @thr_send     = send_msg
    @thr_input    = input

    @entrada = []
    @saida = []

    @thr_recive.join
    @thr_send.join
    @thr_input.join
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
    print '.'
    @thr0 = Thread.new do
      loop do
        if @saida.nil? || @saida.empty?
          sleep 2
          next
        end
        socket = nil
        socket = new_socket while socket.nil?
        socket.puts @saida.slice!(0)
        socket.close
      end
    end
  end

  def recive_msg
    print '.'
    @thr1 = Thread.new do
      loop do
        conn = @server.accept
        Thread.start(conn) do |c|
          @entrada << c.gets.chomp
        end
      end
    end
  end

  def input
    puts ''
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
        when '2'
          show
        else
          puts 'Informe apenas uma das opções acima!'
        end
      end
    end
  end

  def menu
    puts '------------------------- OPÇÕES ------------------------'
    puts '[1] Escrever mensagem'
    puts '[2] Listar mensagens'
    puts '[0] Sair'
    print '-> '
  end

  def show
    puts '----------------------- MENSAGENS -----------------------'
    puts @entrada
    puts '---------------------------------------------------------'
  end

  def kill_threads
    Thread.kill(@thr0)
    Thread.kill(@thr1)
    Thread.kill(@thr2)
  end
end

if ARGV.length != 1
  puts 'Informe o ID do roteador!'
  exit
end

read = ReadConfig.new
id = ARGV[0].to_i
config = read.get_config(id)

server = TCPServer.open(config[0], config[1])
Client.new(server, id)
