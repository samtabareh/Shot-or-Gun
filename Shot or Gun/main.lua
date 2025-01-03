-- to start with, we need to require the 'socket' lib (which is compiled
-- into love). socket provides low-level networking features.
local socket = require "socket"

-- the address and port of the server
local address, port = "127.0.0.1", 5299

local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update

local t

local gravity = 75

local Player = {
	x = 100,
	y = 50,
	size = { x = 10, y = 20 },
	box = {
		left = 0,
		right = 0,
		bottom = 0,
		top = 0
	},
	jumpv = 750,
	-- velocity
	vx = 0,
	vy = 0
}

-- Bad code lol
function Player:update_player_box(table)
	if table.left or table.x then self.box.left = self.x + self.size.x end
	if table.right or table.x then self.box.right = self.x - self.size.x end
	if table.bottom or table.y then self.box.bottom = self.y + self.size.y end
	if table.top or table.y then self.box.top = self.y - self.size.y end
end

function Player:move_update(dt)
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt
	self:update_player_box{ x = true, y = true }
	self.vx = self.vx - self.vx * dt * 10
	self.vy = self.vy - self.vy * dt * 10
end

function Player:move(x)
	self.vx = self.vx + x
end

function Player:jump(y)
	if self:is_on_floor() then self.vy = self.vy - y end
end

function Player:is_on_floor()
	self:update_player_box{ y = true }
	if self.box.bottom >= love.graphics.getHeight() then
		-- To make it not stuck below the floor
		self.y = love.graphics.getHeight() - self.size.y
		-- To stop it from going
		self.vy = 0
		return true 
	end
end

function love.load()
	print("Starting...")
	udp = socket.udp()
	udp:settimeout(0)
	udp:setpeername(address, port)
	udp:send("cstart")
	
	t = 0
end

function love.draw()
	love.graphics.ellipse("fill", Player.x, Player.y, Player.size.x, Player.size.y)
end

function love.update(dt)
	t = t + dt -- increase t by the deltatime
	
	if t > updaterate then
		local msg
		
		Player:move_update(dt)
		if not Player:is_on_floor() then Player.vy = Player.vy + gravity end

		if love.keyboard.isScancodeDown('w', 'up') then Player:jump(Player.jumpv) end
		if love.keyboard.isScancodeDown('a', 'left') then Player:move(-50) end
		if love.keyboard.isScancodeDown('d', 'right') then Player:move(50) end

		if love.keyboard.isDown("escape") then
			print("Closing...")
			udp:send("cclose")
			udp:close()
			os.exit(0)
		end

		if msg then
			print(msg)
			udp:send(msg)
		end

		t=t-updaterate -- set t for the next round
	end
	
	-- there could well be more than one message waiting for us, so we'll
	-- loop until we run out
	local data, msg
	repeat
		data, msg = udp:receive()

		if data then print(data)
		elseif msg ~= 'timeout' then error("Network error: "..tostring(msg)) end
	until not data 
end

function love.quit()
	print("Closing...")
	udp:send("cclose")
	udp:close()
	os.exit(0)
end

-- And thats the end of the udp client example.