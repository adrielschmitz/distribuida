# Responsavel por ler os dados do arquivo de configuracao
class ReadConfig
  PATH = 'config.txt'.freeze
  def initialize
    file = File.read(PATH)
    @data = file.split(/\n/).map { |x| x.split(' ') }
  end

  def get_config(id)
    @data[id]
  end

  def max_routers
    @data.size
  end
end
