require "socket"

PORT      = 3001          
MAX_LEN   = 1024          #Número máximo de bits que será recebido do socket
HOSTNAME  = "localhost"    
IP        = "127.0.0.1"   

# Cria um servidor do tipo UDP
server = UDPSocket.new
server.bind(HOSTNAME, PORT)

puts "Servidor conectado na porta #{PORT}, aguardando...\n"

loop do 
  message, sender = server.recvfrom(MAX_LEN)
  break if message.chomp == "0"

  ip = sender[3]
  puts "Host #{IP} enviou um pacote: #{message}"
  puts "Informações do remetende: #{sender}"
end

puts "Encerrando conexão..."
server.close