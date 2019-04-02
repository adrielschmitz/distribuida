require 'socket'
require 'pry'

HOSTNAME = 'localhost'.freeze
PORT1 = 8080
PORT2 = 8081

class Client
  def initialize(socket, server, id)
    @socket = socket
    @server = server
    @id = id

    puts 'Servidor com id: ' + @id.to_s

    @response_object = recive_msg
    @request_object = send_msg
    @input_keyboard = input
    @entrada = []
    @saida = []

    @response_object.join
    @request_object.join
    @input_keyboard.join
  end

  def new_socket
    if @id.zero?
      TCPSocket.new(HOSTNAME, PORT2)
    else
      TCPSocket.new(HOSTNAME, PORT1)
    end
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
        @socket = nil
        @socket = new_socket while @socket.nil?
        @socket.puts @saida.slice!(0)
        @socket.close
      end
    end
  end

  def recive_msg
    puts 'INICIALIZANDO'
    @thr1 = Thread.new do
      loop do
        conn = @server.accept
        Thread.start(conn) do |c|
          @entrada << c.gets.chomp
          # puts @entrada
        end
      end
    end
  end

  def input
    @thr2 = Thread.new do
      loop do
        menu
        op = $stdin.gets.chomp.to_i
        case op
        when 0
          kill_threads
        when 1
          puts 'Informe a mensagem:'
          @saida << $stdin.gets.chomp
        when 2
          show
        else
          puts 'Informe apenas uma das opções acima!'
        end
      end
    end
  end

  def menu
    puts 'OPÇÃO:'
    puts '[1] Escrever mensagem'
    puts '[2] Listar mensagens'
    puts '[0] Sair'
    print '-> '
  end

  def show
    puts @entrada
  end

  def kill_threads
    Thread.kill(@thr0)
    Thread.kill(@thr1)
    Thread.kill(@thr2)
  end
end

server = TCPServer.open(HOSTNAME, PORT1 + ARGV[0].to_i)
Client.new(nil, server, ARGV[0].to_i)
