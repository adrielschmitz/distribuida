require 'socket'

PORT        = 3001
HOSTNAME    = "localhost"
MSG_LENGHT  = 1024

message = ''
client = UDPSocket.open
client.connect(HOSTNAME, PORT)