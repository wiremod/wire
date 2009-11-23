-- $Rev: 1781 $
-- $LastChangedDate: 2009-10-05 04:19:53 -0700 (Mon, 05 Oct 2009) $
-- $LastChangedBy: TomyLobo $

WireLib = {}

-- extra table functions

-- Compacts an array by rejecting entries according to cb.
function table.Compact(tbl, cb, n)
	n = n or table.getn(tbl)
	local cpos = 1
	for i = 1, n do
		if cb(tbl[i]) then
			tbl[cpos] = tbl[i]
			cpos = cpos + 1
		end
	end

	local new_n = cpos-1
	while (cpos <= n) do
		tbl[cpos] = nil
		cpos = cpos + 1
	end
end

-- I don't even know if I need this one.
-- HUD indicator needs this one
function table.MakeSortedKeys(tbl)
	local result = {}

	for k,_ in pairs(tbl) do table.insert(result, k) end
	table.sort(result)

	return result
end

-- works like pairs() except that it iterates sorted by keys.
-- criterion is optional and should be a function(a,b) returning whether a is less than b. (same as table.sort's criterions)
function pairs_sortkeys(tbl, criterion)
	tmp = {}
	for k,v in pairs(tbl) do table.insert(tmp,k) end
	table.sort(tmp, criterion)

	local iter, state, index, k = ipairs(tmp)
	return function()
		index,k = iter(state, index)
		if index == nil then return nil end
		return k,tbl[k]
	end
end

-- sorts by values
function pairs_sortvalues(tbl, criterion)
	local crit = criterion and
		function(a,b)
			return criterion(tbl[a],tbl[b])
		end
	or
		function(a,b)
			return tbl[a] < tbl[b]
		end

	tmp = {}
	for k,v in pairs(tbl) do table.insert(tmp,k) end
	table.sort(tmp, crit)

	local iter, state, index, k = ipairs(tmp)
	return function()
		index,k = iter(state, index)
		if index == nil then return nil end
		return k,tbl[k]
	end
end

-- like ipairs, except it maps the value with mapfunction before returning.
function ipairs_map(tbl, mapfunction)
	local iter, state, k = ipairs(tbl)
	return function(state, k)
		local v
		k,v = iter(state, k)
		if k == nil then return nil end
		return k,mapfunction(v)
	end, state, k
end

-- like pairs, except it maps the value with mapfunction before returning.
function pairs_map(tbl, mapfunction)
	local iter, state, k = pairs(tbl)
	return function(state, k)
		local v
		k,v = iter(state, k)
		if k == nil then return nil end
		return k,mapfunction(v)
	end, state, k
end

/******************************************************************************/

do -- containers
	local function new(metatable, ...)
		local tbl = {}
		setmetatable(tbl, metatable)
		local init = metatable.Initialize
		if init then init(tbl, ...) end
		return tbl
	end

	local function newclass(container_name)
		meta = { new = new }
		meta.__index = meta
		WireLib.containers[container_name] = meta
		return meta
	end

	WireLib.containers = { new = new }

	do -- class deque
		local deque = newclass("deque")

		function deque:Initialize()
			self.offset = 0
		end

		function deque:size()
			return #self-self.offset
		end

		-- Prepends the given element.
		function deque:unshift(value)
			if offset < 1 then
				-- TODO: improve
				table.insert(self, 1, value)
				return
			end
			self.offset = self.offset - 1
			self[self.offset+1] = value
		end

		-- Removes the first element and returns it
		function deque:shift()
			--do return table.remove(self, 1) end
			local offset = self.offset + 1
			local ret = self[offset]
			if not ret then self.offset = offset-1 return nil end
			self.offset = offset
			if offset > 127 then
				for i = offset+1,#self-offset do
					self[i-offset] = self[i]
				end
				for i = #self-offset+1,#self do
					self[i-offset],self[i] = self[i],nil
				end
				self.offset = 0
			end
			return ret
		end

		-- Appends the given element.
		function deque:push(value)
			self[#self+1] = value
		end

		-- Removes the last element and returns it.
		function deque:pop()
			local ret = self[#self]
			self[#self] = nil
			return ret
		end

		-- Returns the last element.
		function deque:top()
			return self[#self]
		end
	end -- class deque

	do -- class autocleanup
		local autocleanup = newclass("autocleanup")

		function autocleanup:Initialize(depth, parent, parentindex)
			rawset(self, "depth", depth or 0)
			rawset(self, "parent", parent)
			rawset(self, "parentindex", parentindex)
			rawset(self, "data", {})
		end

		function autocleanup:__index(index)
			local data  = rawget(self, "data")

			local element = data[index]
			if element then return element end

			local depth = rawget(self, "depth")
			if depth == 0 then return nil end
			element = new(autocleanup, depth-1, self, index)

			data[index] = element
			return element
		end

		function autocleanup:__newindex(index, value)
			local data   = rawget(self, "data")
			local parent = rawget(self, "parent")

			data[index] = value
			if value == nil and not next(data) and parent then
				local parentindex = rawget(self, "parentindex")
				parent[parentindex] = nil
			end
		end

		function autocleanup:pairs()
			local data = rawget(self, "data")

			return pairs(data)
		end

		pairs_ac = autocleanup.pairs
	end -- class autocleanup
end -- containers

/******************************************************************************/

-- end extra table functions

-- WireLib.AddNotify([ply, ]Message, Type, Duration[, Sound])
-- If ply is left out, the notification is sent to everyone. If Sound is left out, no sound is played.
-- On the client, only the local player can be notified.

-- The following sounds can be used:
NOTIFYSOUND_NONE = 0 -- optional
NOTIFYSOUND_DRIP1 = 1
NOTIFYSOUND_DRIP2 = 2
NOTIFYSOUND_DRIP3 = 3
NOTIFYSOUND_DRIP4 = 4
NOTIFYSOUND_DRIP5 = 5
NOTIFYSOUND_ERROR1 = 6
NOTIFYSOUND_CONFIRM1 = 7
NOTIFYSOUND_CONFIRM2 = 8
NOTIFYSOUND_CONFIRM3 = 9
NOTIFYSOUND_CONFIRM4 = 10

if CLIENT then

	local sounds = {
		[NOTIFYSOUND_DRIP1   ] = "ambient/water/drip1.wav",
		[NOTIFYSOUND_DRIP2   ] = "ambient/water/drip2.wav",
		[NOTIFYSOUND_DRIP3   ] = "ambient/water/drip3.wav",
		[NOTIFYSOUND_DRIP4   ] = "ambient/water/drip4.wav",
		[NOTIFYSOUND_DRIP5   ] = "ambient/water/drip5.wav",
		[NOTIFYSOUND_ERROR1  ] = "buttons/button10.wav",
		[NOTIFYSOUND_CONFIRM1] = "buttons/button3.wav",
		[NOTIFYSOUND_CONFIRM2] = "buttons/button14.wav",
		[NOTIFYSOUND_CONFIRM3] = "buttons/button15.wav",
		[NOTIFYSOUND_CONFIRM4] = "buttons/button17.wav",
	}

	function WireLib.AddNotify(ply, Message, Type, Duration, Sound)
		if type(ply) == "string" then
			Message, Type, Duration, Sound = ply, Message, Type, Duration
		elseif ply ~= LocalPlayer() then
			return
		end
		GAMEMODE:AddNotify(Message, Type, Duration)
		if Sound and sounds[Sound] then surface.PlaySound(sounds[Sound]) end
	end

	usermessage.Hook("wl_addnotify", function(um)
		local Message = um:ReadString()
		local Type = um:ReadChar()
		local Duration = um:ReadFloat()
		local Sound = um:ReadChar()

		WireLib.AddNotify(LocalPlayer(), Message, Type, Duration, Sound)
	end)

elseif SERVER then

	NOTIFY_GENERIC = 0
	NOTIFY_ERROR = 1
	NOTIFY_UNDO = 2
	NOTIFY_HINT = 3
	NOTIFY_CLEANUP = 4

	function WireLib.AddNotify(ply, Message, Type, Duration, Sound)
		if type(ply) == "string" then ply, Message, Type, Duration, Sound = nil, ply, Message, Type, Duration end
		umsg.Start("wl_addnotify", ply)
			umsg.String(Message)
			umsg.Char(Type)
			umsg.Float(Duration)
			umsg.Char(Sound or 0)
		umsg.End()
	end

end

if CLIENT then
	usermessage.Hook("wirelib_clienterror", function(um)
		local message = um:ReadString()
		print("sv: "..message)
		local lines = string.Explode("\n", message)
		for i,line in ipairs(lines) do
			if i == 1 then
				WireLib.AddNotify(line, NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			else
				WireLib.AddNotify(line, NOTIFY_ERROR, 7)
			end
		end
	end)
elseif SERVER then
	function WireLib.ClientError(message, player)
		umsg.Start("wirelib_clienterror", player)
			umsg.String(message)
		umsg.End()
	end
end
