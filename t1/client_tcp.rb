require 'socket'
require 'io/console'

PORT        = 8081
HOSTNAME    = 'localhost'.freeze
MSG_LENGHT  = 1024
ID          = 1
TYPE_READ   = 0
TYPE_WRITE  = 1

hash = {}

loop do
  puts 'Digite sua mensagem (press [0] para parar):'
  $stdin.iflush
  message = gets
  break if '0'.include? message.chomp

  hash = { tp: 1, remetente: ID, destinatario: 0, message: message }

  TCPSocket.open(HOSTNAME, PORT) do |server|
    server.write [
      Marshal.dump(hash)
    ].pack('A*')
  end
end
