require 'socket'
require 'io/console'

PORT        = 3001
HOSTNAME    = 'localhost'.freeze
MSG_LENGHT  = 1024

client = UDPSocket.open
client.connect(HOSTNAME, PORT)

loop do
  message = ''
  loop do
    puts 'Digite sua mensagem (press [0] para parar):'

    $stdin.iflush
    message = gets
    break if message.length <= MSG_LENGHT
  end

  # O argumento 0 é uma flag que pode ser usada com uma combinação T> de constantes.
  client.sendmsg(message, 0)
  break if '0'.include? message.chomp
end

puts 'Conexão encerrada!'
client.close
