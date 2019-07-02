# Classe responsavel pela configuracao dos servidores
class ReadConfig
  attr_reader :routers_number, :routers
  def initialize
    file = File.read('config.txt')
    routers = file.split(/\n/).map { |x| x.split(' ') }
    to_hash(routers)
    @routers_number = @routers.length
  end

  def to_hash(routers)
    @routers = Hash.new { |hash, key| hash[key] = {} }
    (0..routers.length - 1).each do |i|
      @routers[i.to_s.to_sym][:ip] = routers[i][0]
      @routers[i.to_s.to_sym][:port] = routers[i][1]
    end
  end
end
