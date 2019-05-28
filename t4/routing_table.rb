require './read_config'

module Table
  # Classe responsavel pela tabela de roteamento
  class RoutingTable
    attr_reader :table, :connections
    def initialize(id)
      @table = {}
      @connections = find_connections(id)
      configure_table
    end

    # Encontra o roteador responsavel pela chave
    def foresee_router(index)
      lower = 4_611_686_018_427_387_902
      router = nil
      @table.each do |key, value|
        if (value.to_i < lower) && index.to_i <= value.to_i
          lower = value.to_i
          router = key
        end
      end
      router
    end

    # Mostra a tabela de roteamento
    def print_table(id)
      puts '+-------------------------------+'
      puts "|       Routing Table[#{id}]        |"
      puts '+-------------------------------+'
      puts '|   Routers     |   Max Index   |'
      puts '+-------------------------------+'
      @table.each do |router, index|
        puts '|       ' + router.to_s + '       |         ' + index.to_s + '     |'
      end
      puts '+-------------------------------+'
    end

    private

    # Configura a tabela de roteamento
    def configure_table
      config = ReadConfig.new
      @connections.each do |connection|
        hash_max_range = (config.hash_size * connection + config.hash_size - 1)
        @table[connection.to_s.to_sym] = hash_max_range
      end
    end

    # Busca as conexoes dos roteadores no arquivo
    def find_connections(id)
      connections = []
      file = File.read('connections.txt')
      con = file.split(/\n/).map { |x| x.split(':') }
      con.each do |_c0, c1|
        connections << c1.split(',')
      end
      connections = connections[id]
      connections.map(&:to_i)
    end
  end
end
