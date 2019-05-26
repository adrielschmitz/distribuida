require './read_config'

class RoutingTable
  attr_reader :table, :connections
  def initialize(id)
    @table = {}
    @connections = [(id + 1) % 2]
    configure_table
  end

  def foresee_router(index)
    router = find_bigger(index)
    return router unless router.nil?

    find_lower
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

  def find_bigger(index)
    bigger = -1
    router = nil
    @table.each do |key, value|
      if (value.to_i > bigger) && value.to_i <= index.to_i
        bigger = value.to_i
        router = key
      end
    end
    router
  end

  def find_lower
    lower = 9_999_999_999
    router = nil
    @table.each do |key, value|
      if lower > value
        lower = value
        router = key
      end
    end
    router
  end

  def configure_table
    config = ReadConfig.new
    @connections.each do |connection|
      hash_max_range = (config.hash_size * connection + config.hash_size - 1)
      @table[connection.to_s.to_sym] = hash_max_range
    end
  end
end
