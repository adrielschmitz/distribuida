# Trabalho parcial sobre modelo de comunicação
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computação Distribuída

require 'socket'
require './read_config'

class Client
  def initialize(server, id)
    @server = server
    @id = id

    @hash = { '0': {}, '1': {} }

    print 'Inicializando ..'
    @thr_recive = recive_msg
    input

    @thr_recive.join
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
    hash = { um: 1, dois: 2, tres: 3 }
    TCPSocket.open('localhost', 8081) do |server|
      server.write [
        1,
        'teste'.ljust(10),
        Marshal.dump(hash)
      ].pack('LA10A*')
    end
  end

  def recive_msg
    @thr1 = Thread.new do
      TCPServer.open('localhost', 8081) do |server|
        loop do
          con = server.accept
          rst = con.recv(1024).unpack('LA10A*')
          fix = rst[0]
          str = rst[1]

          hash = Marshal.load(rst[2])
          puts "#{fix.class}\t: #{fix}"
          puts "#{str.class}\t: #{str}"
          puts "#{hash.class}\t: #{hash}"
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
        show
      else
        puts 'Informe apenas uma das opções acima!'
      end
    end
  end

  def assemble_hash(key, msg)
    index = (key.to_i % 2)
    
    @hash[index.to_s.to_sym][key.to_s.to_sym] = msg
    
    puts @hash
  end

  def menu
    puts "Cliente [#{@id}]"
    puts '-------------- OPÇÕES --------------'
    puts '[1] Escrever mensagem'
    puts '[2] Listar mensagens'
    puts '[0] Sair'
    print '-> '
  end

  def kill_threads
    Thread.kill(@thr1)
  end
end

if ARGV.length != 1
  puts 'Informe o ID do roteador!'
  exit
end

# Lê o aquivo de configuração
read = ReadConfig.new

# Lê o argumento informado pelo usuário
id = ARGV[0].to_i
config = read.get_config(id)

# Inicia um servidor com os paramentros de ip e porta
server = TCPServer.open(config[0], config[1])

# Instancia o cliente com seu id
Client.new(server, id)
