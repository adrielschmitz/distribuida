require './read_config'
require 'socket'
require 'json'

class Client
  attr_reader :ip, :port, :config, :responses
  def initialize
    @ip = '127.0.0.1'
    @port = 8010
    @config = ReadConfig.new
    @responses = []
    @thr_receive = receive_msg
    teste
    @thr_receive.join
  end

  def teste
    op = 1
    while op != 0
      menu
      op = $stdin.gets.chomp.to_i
      case op
      when 0
        kill
        break
      when 1
        input
      when 2
        show_responses
      else
        puts 'Opção inválida'
        print '→ '
      end
    end
  end

  def input
    print 'Message: '
    message = $stdin.gets.chomp
    print 'Roteador: '
    reciver_router = $stdin.gets.chomp.to_i
    print 'Tipo: '
    final_router = $stdin.gets.chomp.to_i
    send_message(message, reciver_router, final_router)
  end

  def send_message(message, reciver_router, final_router)
    ip, port = find_router(reciver_router)
    pack = assemble_message(0, final_router, message, {})

    TCPSocket.open(ip, port) do |server|
      server.write(pack)
    end
  rescue Errno::ECONNREFUSED
    puts 'Roteador não inicializado!'
  end

  def find_router(router_id)
    router = @config.routers[router_id.to_s.to_sym]
    [router[:ip], router[:port]]
  end

  def assemble_message(message_type, reciver, message, hash)
    [
      message_type,
      4_294_967_293,
      reciver,
      message.ljust(50),
      hash.to_json.ljust(400)
    ].pack('LLLA50A400')
  end

  def receive_msg
    Thread.new do
      TCPServer.open(@ip, @port) do |server|
        loop do
          con = server.accept
          pack = unpack(con.recv(2048))
          @responses << pack
          con.close
        end
      end
    end
  end

  def unpack(package)
    pack = package.unpack('LLLA50A400')
    {
      message_type: pack[0],
      sender: pack[1],
      reciver: pack[2],
      message: pack[3],
      hash: JSON.parse(pack[4], symbolize_names: true)
    }
  end

  def menu
    puts '[0] Sair'
    puts '[1] Enviar mensagem'
    puts '[2] Mostart log'
    print '→ '
  end

  def show_responses
    puts '+-------------+----------+---------------------------------------------------+'
    puts '|  Router ID  | Success? |                      Message                      |'
    puts '+-------------+----------+---------------------------------------------------+'
    @responses.each do |response|
      print "|#{response[:sender].to_s.center(13)}|"
      print "#{response[:hash][:success].to_s.center(10)}|"
      puts "#{response[:message].to_s.ljust(51)}|"
    end
    puts '+-------------+----------+---------------------------------------------------+'    
  end

  def kill
    Thread.kill(@thr_receive)
  end
end

Client.new
