require './read_config'

class RoutingTable
  attr_reader :table, :connections
  def initialize(id)
    @table = {}
    @connections = find_connections(id)
    configure_table
  end

  def foresee_router(index)
    bigger = -1
    router = nil
    @table.each do |key, value|
      if (value.to_i > bigger) && index.to_i <= value.to_i
        bigger = value.to_i
        router = key
      end
    end
    puts router
    router
  end

  def print_table(id)
    puts '+-------------------------------+'
    puts "|       Ruting Table[#{id}]         |"
    puts '+-------------------------------+'
    puts '|   Routers     |   Max Index   |'
    puts '+-------------------------------+'
    @table.each do |router, index|
      puts '|       ' + router.to_s + '       |         ' + index.to_s + '     |'
    end
    puts '+-------------------------------+'
  end

  private

  def configure_table
    config = ReadConfig.new
    @connections.each do |connection|
      hash_max_range = (config.hash_size * connection + config.hash_size - 1)
      @table[connection.to_s.to_sym] = hash_max_range
    end
  end

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
