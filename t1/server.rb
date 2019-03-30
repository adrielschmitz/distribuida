require 'socket'

server = TCPServer.new 2000 # Server bound to port 2000

while true do
  client = server.accept    # Wait for a client to connect
  client.puts "Mensagem vinda do servidor !"
  client.puts "Time is #{Time.now}"
  # client.close
end
