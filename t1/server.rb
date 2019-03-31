require "socket"

PORT            = 3001          
TAM_MSG_PRINT   = 1024          #Tamanho da mensagem que será mostrada no console
HOSTNAME        = "localhost"    
IP              = "127.0.0.1"   

# Cria um servidor do tipo UDP
server = UDPSocket.new
server.bind(HOSTNAME, PORT)

puts "Servidor conectado na porta #{PORT}, aguardando..."

loop do 
  message, sender = server.recvfrom(TAM_MSG_PRINT)
  ip = sender[3]
  puts "Host #{IP} enviou um pacote: #{message}"
  break unless message.chomp != "0"
end

puts "Closing server."
server.close