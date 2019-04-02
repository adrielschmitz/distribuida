class ReadConfig
  def initialize
    file = File.read('config.txt')
    @data = file.split(/\n/).map { |x| x.split(' ') }
  end

  def get_config(id)
    @data[id]
  end
end
