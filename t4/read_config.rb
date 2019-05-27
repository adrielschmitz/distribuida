# Classe responsavel pela configuracao do sistema
class ReadConfig
  attr_reader :routers_number, :routers, :hash_size
  def initialize
    file = File.read('config.txt')
    @routers = file.split(/\n/).map { |x| x.split(' ') }
    @routers_number = @routers.length
    @hash_size = 2
  end
end
