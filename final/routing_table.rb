require './read_config'
require 'pry'

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
      killed = false
      @table.each do |key, router|
        next if router[:next_hop] != id

        @table[key.to_s.to_sym][:next_hop] = -1
        @table[key.to_s.to_sym][:distance] = 4_611_686_018_427_387_902
        @table[key.to_s.to_sym][:type] = -1
        killed = true
      end
      killed
    end

    def print_table
      puts '+-----------------------------------------------------------+'
      puts "|                      Routing Table[#{@id}]                     |"
      puts '+-----------+-----------+-----------+-----------+-----------+'
      puts '|  Routers  | Next Hop  | Distance  |   Type    |   Count   |'
      puts '+-----------+-----------+-----------+-----------+-----------+'
      @table.each do |key, router|
        next if key.to_s == @id.to_s || router[:next_hop] == -1

        print "|#{key.to_s.center(11)}|"
        print "#{router[:next_hop].to_s.center(11)}|"
        print "#{router[:distance].to_s.center(11)}|"
        print "#{router[:type].to_s.center(11)}|"
        puts  "#{router[:count].to_s.center(11)}|"
      end
      puts '+-----------+-----------+-----------+-----------+-----------+'
    end

    def find_router(router_id)
      router = @config.routers[router_id.to_s.to_sym]
      [router[:ip], router[:port]]
    end

    def find_next_hop(router_id)
      next_hop = @table[router_id.to_s.to_sym][:next_hop]
      find_router(next_hop)
    end

    def bellman_ford(id, table)
      table.each do |key, router|
        @table[key.to_s.to_sym][:type] = router[:type] if router[:type] != -1 && router[:next_hop] != @id
        next if @connections.include? key.to_s.to_i

        if @table[key.to_s.to_sym][:count] < router[:count]
          @table[key.to_s.to_sym][:count] = router[:count]
        end

        if @table[key.to_s.to_sym][:distance] > (router[:distance] + 1) &&
           (@table[router[:next_hop].to_s.to_sym][:next_hop] != -1 ||
            router[:next_hop] == key.to_s.to_i) &&
           router[:next_hop] != @id
          set_value(key, id, router[:distance] + 1)
          next
        end

        if @table[key.to_s.to_sym][:next_hop] == id && router[:next_hop] == -1
          set_value(key, -1, 4_611_686_018_427_387_902)
          @table[key.to_s.to_sym][:type] = -1
        end
      end
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
          @table[key.to_s.to_sym][:next_hop] = @id
          @table[key.to_s.to_sym][:distance] = 0
          @table[key.to_s.to_sym][:type] = @id
          @table[key.to_s.to_sym][:count] = 0
          next
        end
        @table[key.to_s.to_sym][:next_hop] = -1
        @table[key.to_s.to_sym][:distance] = 4_611_686_018_427_387_902
        @table[key.to_s.to_sym][:type] = -1
        @table[key.to_s.to_sym][:count] = 0
      end
    end

    def set_value(id, next_hop, distance)
      @table[id.to_s.to_sym][:next_hop] = next_hop
      @table[id.to_s.to_sym][:distance] = distance
    end
  end
end
