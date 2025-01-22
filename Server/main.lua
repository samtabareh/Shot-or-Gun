local socket = require "socket"

-- begin
local ip, port = "*", 5299
local udp = socket.udp()
udp:settimeout(0)
udp:setsockname(ip, port)
local data, msg_or_ip, port_or_nil

local running = true

-- the beginning of the loop proper...
print "Beginning server loop."
while running do
	data, msg_or_ip, port_or_nil = udp:receivefrom()
    
	if data then
        if data == "cstart" then print("New client connected")
        elseif data == "cclose" then print("A client closed")
        elseif data == "click" then print("Client: ".. data)
        elseif data == "up" then print("Client: ".. data)
        elseif data == 'kys' then
            local msg = "Server stopping..."
            print(msg)
            udp:sendto(msg, msg_or_ip, port_or_nil)
            running = false
        end
    end
	socket.sleep(0.01)
end