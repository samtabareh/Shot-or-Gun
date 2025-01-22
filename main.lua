-- to start with, we need to require the 'socket' lib (which is compiled
-- into love). socket provides low-level networking features.
local socket = require "socket"

-- the address and port of the server
local address, port = "127.0.0.1", 5299

local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update

local tick

local gravity = 75

local players = {}
local Player = {
	-- identification
	name = "",
	id = 0,
	-- Is the player ours or another clients (aka, can we control it?)
	controllable = false,
	-- pos
	x = 100,
	y = 50,
	-- collision stuff
	size = { x = 10, y = 20 },
	box = {
		left = 0,
		right = 0,
		bottom = 0,
		top = 0
	},
	-- velocity
	jumpv = 750,
	vx = 0,
	vy = 0,
	-- table for extra values the server needs but doesnt have (like love.graphics.getHeight)
	extra = {},
	-- functions
	update_box = function (self, table)
		if table.left or table.x then self.box.left = self.x + self.size.x end
		if table.right or table.x then self.box.right = self.x - self.size.x end
		if table.bottom or table.y then self.box.bottom = self.y + self.size.y end
		if table.top or table.y then self.box.top = self.y - self.size.y end
	end,
	apply_velocity = function (self, dt)
		self.x = self.x + self.vx * dt
		self.y = self.y + self.vy * dt
		self:update_box{ x = true, y = true }
		self.vx = self.vx - self.vx * dt * 10
		self.vy = self.vy - self.vy * dt * 10
	end,
	move = function (self, table)
		if table.x then self.vx = self.vx + table.x end
		if table.y then self.vy = self.vy + table.y end
	end,
	jump = function (self, y)
		-- If we are on the floor, then jump
		if self:is_on_floor() then self.vy = self.vy - y end
	end,
	is_on_floor = function (self)
		self:update_box{ y = true }
		if self.box.bottom >= love.graphics.getHeight() then
			-- To make it not stuck below the floor
			self.y = love.graphics.getHeight() - self.size.y
			-- To stop it from going
			self.vy = 0
			return true 
		end
	end
}
function Player:new(t)
	local player = {}
	setmetatable(player, self)
	self.__index = self

	-- If there are custom settings (like pos or functions), apply them 
	if t then
		-- Add id and name if it wasnt provided
		if not t.id then t.id = #players + 1 end
		if not t.name then t.name = "Client"..t.id end
		-- Add screenHeight for server collision detection
		if love.graphics and t.extra and not t.extra.screenHeight then t.extra.screenHeight = love.graphics.getHeight() end
		
		for tk, tv in pairs(t) do
			for pk, pv in pairs(player) do
				print(pk, pv)
				print(tk, tv)
				if pk == tk then player[pk] = tv end
			end
		end
	end
	return player
end

local main_player

function love.load()
	client = socket.udp()
	client:settimeout(0)
	client:setpeername(address, port)
	client:send("cstart")
	main_player = Player:new{ y = 5000, controllable = true }
	table.insert(players, main_player)
	print("Client started")

	tick = 0
end

function love.draw()
	for _, player in ipairs(players) do
		love.graphics.ellipse("fill", player.x, player.y, player.size.x, player.size.y)
	end
end

function love.update(dt)
	tick = tick + dt -- increase t by the deltatime
	
	if tick > updaterate then
		local msg
		
		main_player:apply_velocity(dt)
		if not main_player:is_on_floor() then main_player:move{ y = gravity } end

		if love.keyboard.isScancodeDown('w', 'up') then main_player:jump(Player.jumpv) end
		if love.keyboard.isScancodeDown('a', 'left') then main_player:move{ x = -50 } end
		if love.keyboard.isScancodeDown('d', 'right') then main_player:move{ x = 50 } end

		if love.keyboard.isDown("escape") then
			print("Closing...")
			client:send("cclose")
			client:close()
			os.exit(0)
		end

		if msg then
			print(msg)
			client:send(msg)
		end

		tick=tick-updaterate -- set t for the next round
	end
	
	-- there could well be more than one message waiting for us, so we'll
	-- loop until we run out
	local data, msg
	repeat
		data, msg = client:receive()

		if data then print(data)
		elseif msg ~= 'timeout' then error("Network error: "..tostring(msg)) end
	until not data 
end

function love.quit()
	print("Closing...")
	client:send("cclose")
	client:close()
	os.exit(0)
end

-- And thats the end of the client client example.