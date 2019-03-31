require "socket"

PORT        = 3001
HOSTNAME    = "localhost"
MSG_LENGHT  = 1024

client = UDPSocket.open
client.connect(HOSTNAME, PORT)

loop do
  while true
    puts "Digite sua mensagem (press #{0} para parar):"
    require 'io/console'
    $stdin.iflush
    message = gets
    break if message.length <= MSG_LENGHT
  end
 
  client.send(message, 0) # O argumento 0 é uma flag que pode ser usada com uma combinação T> de constantes.
  break unless !"0".include? message.chomp
end

client.close