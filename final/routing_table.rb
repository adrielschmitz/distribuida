require './read_config'

module Server
  # Classe responsavel pela tabela de roteamento
  class RoutingTable
    attr_reader :id, :table, :config, :connections
    def initialize(id)
      @table = Hash.new { |hash, key| hash[key] = {} }
      @id = id
      read_config
    end

    def read_config
      @config = ReadConfig.new
      configure_table
      @connections = find_connections
    end

    def alive(id)
      @table[id.to_s.to_sym][:next_hop] = id
      @table[id.to_s.to_sym][:distance] = 1
    end

    def kill(id)
      @table[id.to_s.to_sym][:next_hop] = -1
      @table[id.to_s.to_sym][:distance] = 4_611_686_018_427_387_902
    end

    def print_table
      puts '+-------------------------------+'
      puts "|       Routing Table[#{@id}]        |"
      puts '+-------------------------------+'
      puts '|   Routers     |   Next Jump   |'
      puts '+-------------------------------+'
      @table.each do |key, router|
        next if key.to_s == @id.to_s || router[:next_hop] == -1

        puts "|       #{key}       |        #{router[:next_hop]}      |"
      end
      puts '+-------------------------------+'
    end

    def find_router(router_id)
      router = @config.routers[router_id.to_s.to_sym]
      [router[:ip], router[:port]]
    end

    def find_next_hop(router_id)
      next_hop = @table[router_id.to_s.to_sym][:next_hop]
      find_router(next_hop)
    end

    private

    def find_connections
      connections = []
      file = File.read('connections.txt')
      con = file.split(/\n/).map { |x| x.split(':') }
      con.each do |_c0, c1|
        connections << c1.split(',')
      end
      connections = connections[@id]
      connections.map(&:to_i)
    end

    def configure_table
      @config.routers.each do |key, _router|
        if key.to_s == @id.to_s
          @table[key.to_s.to_sym][:next_hop] = 0
          next
        end
        @table[key.to_s.to_sym][:next_hop] = -1
        @table[key.to_s.to_sym][:distance] = 4_611_686_018_427_387_902
        # Adicionar o tipo do roteador aqui
      end
    end
  end
end
