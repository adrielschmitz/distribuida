require 'socket'

TCPServer.open('localhost', 8081) do |server|
  puts 'servidor iniciado'

  loop do
    puts 'aguardando conexão ...'
    con = server.accept
    rst = con.recv(1024).unpack('A*')

    hash = Marshal.load(rst[0])
    puts "#{hash.class}\t: #{hash}"
    con.close
  end
end
