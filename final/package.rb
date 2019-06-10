require 'json'

module Server
  # Classe responsavel pelo controle dos pacotes
  class Package
    attr_accessor :package_counter

    def initialize
      @package_counter = 0
    end

    def pack(type, sender, reciver, message, table)
      @package_counter += 1
      [
        type,
        @package_counter,
        sender,
        reciver,
        message.ljust(50),
        table.to_json.ljust(300)
      ].pack('LLLLA50A300')
    end

    def unpack(package)
      pack = package.unpack('LLLLA50A300')
      {
        type: pack[0],
        conter: pack[1],
        sender: pack[2],
        reciver: pack[3],
        message: pack[4],
        table: JSON.parse(pack[5], symbolize_names: true)
      }
    end
  end
end
