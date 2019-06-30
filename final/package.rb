require 'json'

module Server
  # Classe responsavel pelo controle dos pacotes
  class Package
    attr_accessor :pack_id, :counter

    def initialize
      @pack_id = 0
      @counter = 0
    end

    def pack(type, sender, reciver, message, hash)
      @pack_id += 1
      @counter += 1 if type.zero?
      [
        type,
        @pack_id,
        @counter,
        sender,
        reciver,
        message.ljust(50),
        hash.to_json.ljust(400)
      ].pack('LLLLLA50A400')
    end

    def unpack(package)
      pack = package.unpack('LLLLLA50A400')
      {
        message_type: pack[0],
        pack_id: pack[1],
        counter: pack[2],
        sender: pack[3],
        reciver: pack[4],
        message: pack[5],
        hash: JSON.parse(pack[6], symbolize_names: true)
      }
    end
  end
end
