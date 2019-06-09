module Server
  # Classe responsavel por compactar e descompactar os pacotes
  class Package
    class << self
      def pack(type, sender, reciver, message, table)
        [
          type,
          sender,
          reciver,
          message.ljust(50),
          Marshal.dump(table)
        ].pack('LLLA50A*')
      end

      def unpack(package)
        pack = package.unpack('LLLA50A*')
        puts "Tipo: #{pack[0]} S: #{pack[1]} R: #{pack[2]} M: #{pack[3]}"
        puts Marshal.load(pack[4])
      end
    end
  end
end
