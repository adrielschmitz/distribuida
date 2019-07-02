require 'json'
require 'yaml'

module Server
  # Classe responsavel pelo controle dos pacotes
  class Package
    def pack(type, sender, reciver, message, hash)
      [
        type,
        sender,
        reciver,
        message.ljust(50),
        hash.to_json.ljust(400)
      ].pack('LLLA50A400')
    end

    def unpack(package)
      pack = package.unpack('LLLA50A400')
      {
        message_type: pack[0],
        sender: pack[1],
        reciver: pack[2],
        message: pack[3],
        hash: JSON.parse(pack[4], symbolize_names: true)
      }
    end

    def update_log(pack, id, success)
      pack[:success] = success
      pack[:time] = Time.now.strftime('%m/%d/%Y %H:%M:%S:%L')
      File.open("log/router_#{id}.yml", 'a') { |file| file.write(pack.to_yaml) }
    rescue Errno::ENOENT
      Dir.mkdir('log/') unless File.exist?('log/')
      File.open("log/router_#{id}.yml", 'w') { |file| file.write(pack.to_yaml) }
    end
  end
end
