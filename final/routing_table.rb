require './read_config'

module Server
  # Classe responsavel pela tabela de roteamento
  class RoutingTable
    attr_reader :table, :config, :connections
    def initialize(id)
      @table = Hash.new { |hash, key| hash[key] = {} }
      @config = read_config(id)
    end

    def read_config(id)
      configure_table(id)
      @connections = find_connections(id)
    end

    def print_table(id)
      puts '+-------------------------------+'
      puts "|       Routing Table[#{id}]        |"
      puts '+-------------------------------+'
      puts '|   Routers     |   Next Jump   |'
      puts '+-------------------------------+'
      @table.each do |key, router|
        puts "|       #{key}       |        #{router[:next_jump]}      |"
      end
      puts '+-------------------------------+'
    end

    private

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

    def configure_table(id)
      config = ReadConfig.new
      initialize_table(id, config)
    end

    def initialize_table(id, config)
      config.routers.each do |key, _router|
        if key.to_s == id.to_s
          @table[key.to_s.to_sym][:next_jump] = 0
          next
        end
        @table[key.to_s.to_sym][:next_jump] = -1
        @table[key.to_s.to_sym][:distance] = 4_611_686_018_427_387_902
        # Adicionar o tipo do roteador aqui
      end
    end
  end
end


Server::RoutingTable.new(0).print_table(0)