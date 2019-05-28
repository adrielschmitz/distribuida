# Trabalho 04 | Distributed Hash Table
# Alunos: Adriel Schmitz, Leonardo Werlang
# Professor: Braulio Adriano de Melo
# Disciplina: Computacao Distribuida

require 'socket'
require './read_config'
require './routing_table'

module Router
  # Classe responsavel por toda configuracao do cliente
  class Client
    attr_reader :id, :hash, :config, :routing_table
    def initialize(id)
      @id = id
      @config = ReadConfig.new
      @routing_table = Table::RoutingTable.new(id)
      initialize_hash

      @thr_receive = receive_msg
      input
      @thr_receive.join
    end

    # Inicializa a hash
    # Ex:
    # {
    #   '0': {}
    #   '1': {}
    # }
    def initialize_hash
      @hash = {}
      hash_range = (@config.hash_size * @id)..(@config.hash_size * @id + @config.hash_size - 1)
      hash_range.each do |key|
        @hash[key.to_s.to_sym] = {}
      end
    end

    # Responsavel por enviar as mensagens, exibe mensagem de erro de conexao
    # se nao encontrar o servidor
    # send_router: roteador de onde partiu a mensagem
    # controller: variavel resposavel pelo tipo de mensagem
    # key: chave para ser salva ou buscada
    # value: mensagem a ser salva ou mensagem de retorno de uma busca
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
    rescue Errno::ECONNREFUSED
      puts 'Impossível se conectar com o servidor!'
    end

    # Responsavel por receber as mensagens
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

    # Verifica se a mensagem e de busca, armazenamento ou exibicao
    # 0: salvar mensagem
    # 1: buscar por chave
    # 2: exibir/enviar mensagem buscada
    def unpack_message(send_router, controller, key, value)
      if controller.to_i.zero?
        assemble_hash(key, value)
      elsif controller == 1
        find_key(send_router, key)
      elsif controller == 2
        show_key_value(send_router, value)
      end
    end

    # Fica esperando o usuario escolher uma opcao
    # Menu
    # [1] Escrever mensagem
    # [2] Procurar chave
    # [3] Mostar Hash
    # [0] Sair
    def input
      loop do
        menu
        op = $stdin.gets.chomp
        case op
        when '0'
          kill_threads
          break
        when '1'
          read_msg
        when '2'
          read_key
        when '3'
          show_hash
        when '4'
          @routing_table.print_table(@id)
        else
          puts 'Informe apenas uma das opções acima!'
        end
      end
    end

    # Le a chave e a mensagem que sera salva
    def read_msg
      puts 'Informe a chave: '
      key = $stdin.gets.chomp
      puts 'Informe a mensagem:'
      msg = $stdin.gets.chomp
      assemble_hash(key, msg)
    end

    # Encontra o hash para a chave
    def assemble_index(key)
      (key.to_i % (@config.routers.size * @config.hash_size)).to_s.to_sym
    end

    # Armazena os dados se a chave faz parte da hash do cliente
    # senao manda os dados para outro cliente
    def assemble_hash(key, msg)
      index = assemble_index(key)

      if @hash.key? index
        @hash[index][key.to_s.to_sym] = msg
      else
        send_msg(@id, 0, key, msg)
      end
    end

    # Le a chave que sera buscada
    def read_key
      puts 'Informe a chave: '
      key = $stdin.gets.chomp
      find_key(@id, key)
    end

    # Procura a chave no proprio hash
    # senao encontrar busca em outros clientes
    def find_key(send_router, key)
      index = assemble_index(key)

      if @hash.key? index
        if @hash[index].key? key.to_s.to_sym
          msg = "Chave: " + key.to_s + '    Valor: ' + @hash[index][key.to_s.to_sym].to_s
          show_key_value(send_router, msg)
        else
          show_key_value(send_router, 'Está chave não existe!')
        end
      else
        # Mandar buscar em outros hashs
        send_msg(send_router, 1, key, '')
      end
    end

    # Exibe a mensagem se ele mesmo requisitou a chave
    # senao manda para o cliente que a requisitou
    def show_key_value(send_router, msg)
      if send_router.to_i == @id
        print "\n" + msg
      else
        send_msg(send_router, 2, '', msg)
      end
    end

    def menu
      sleep(1)
      puts "\nCliente [#{@id}]"
      puts '-------------- OPÇÕES --------------'
      puts '[1] Escrever mensagem'
      puts '[2] Procurar chave'
      puts '[3] Mostar Hash'
      puts '[4] Tabela de Roteamento'
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
end

if ARGV.length != 1
  puts 'Informe o ID do roteador!'
  exit
end

id = ARGV[0].to_i

# Instancia o cliente com seu id
Router::Client.new(id)
