# Trabalho 2: Demonstracao de relogio relativo
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require './read_config'
require_relative '../vendor/bundle/gems/tty-spinner-0.9.0/lib/tty-spinner'

class Client
  def initialize(server, id, max_routers)
    run_spinner('Configurando...', 'Configuração completa')
    sleep(0.5)
    @server = server
    @id = id

    @thr_recive   = recive_msg
    @thr_send     = send_msg
    @thr_input    = input

    @entrada = []
    @saida = []
    @roteador = 0
    inicializa_estado(max_routers)

    @thr_recive.join
    @thr_send.join
    @thr_input.join
  end

  def inicializa_estado(max_routers)
    @pack_config = ''
    (0..max_routers - 1).each do
      @pack_config << 'L'
    end
  end

  def new_socket(id)
    r = ReadConfig.new
    config = r.get_config(id.to_i)
    socket = TCPSocket.new(config[0], config[1])
    socket.puts @saida[0][:msg]
    @saida.slice!(0)
    socket.close
  rescue Errno::ECONNREFUSED
    # Recoloca a mensagem na fila se nao conseguiu concetar com o servidor
    temp = @saida.slice!(0)
    @saida << temp
    nil
  end

  def send_msg
    @thr0 = Thread.new do
      loop do
        if @saida.nil? || @saida.empty?
          sleep 2
          next
        end
        new_socket(@saida[0][:router])
      end
    end
  end

  def recive_msg
    @thr1 = Thread.new do
      loop do
        conn = @server.accept
        Thread.start(conn) do |c|
          mensagem = c.gets.chomp
          @entrada << { mensagem: mensagem }
        end
      end
    end
  end

  def get_msg
    system('clear')
    puts 'Informe o roteador: '
    print '-> '
    router = $stdin.gets.chomp
    puts 'Informe a mensagem:'
    print '-> '
    msg = $stdin.gets.chomp
    run_spinner('Salvando mensagem...', 'Mensagem salva! Pressione ENTER para voltar')
    @saida << { router: router, msg: msg }
    $stdin.gets
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
          get_msg
        when '2'
          show_msg
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
    puts '[0] Sair'
    print '-> '
  end

  def show_msg
    run_spinner('Carregando mensagens...', 'Mensagens carregadas!')
    puts '----------------------- MENSAGENS -----------------------'
    @entrada.select { |item| puts item[:mensagem] }
    puts '---------------------------------------------------------'
    print 'Pressione ENTER... '
    $stdin.gets
  end

  def kill_threads
    Thread.kill(@thr0)
    Thread.kill(@thr1)
    Thread.kill(@thr2)
  end

  def run_spinner(msg, success_msg)
    system('clear')
    spinner = TTY::Spinner.new('[:spinner] :message')
    spinner.update(message: msg)
    spinner.auto_spin
    sleep(1)
    spinner.update(message: '')
    spinner.success(success_msg)
    spinner.kill
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
