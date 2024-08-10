--A net extension which allows sending large streams of data without overflowing the reliable channel
--Keep it in lua/autorun so it will be shared between addons
AddCSLuaFile()

net.Stream = {}
net.Stream.SendSize = 20000 --This is the size of each packet to send
net.Stream.Timeout = 30 --How long to wait for client response before cleaning up
net.Stream.MaxWriteStreams = 1024 --The maximum number of write data items to store
net.Stream.MaxReadStreams = 128 --The maximum number of queued read data items to store
net.Stream.MaxChunks = 3200 --Maximum number of pieces the stream can send to the server. 64 MB
net.Stream.MaxSize = net.Stream.SendSize*net.Stream.MaxChunks
net.Stream.MaxTries = 3 --Maximum times the client may retry downloading the whole data

local WriteStreamQueue = {
	__index = {
		Add = function(self, stream)
			local identifier = self.curidentifier
			local startid = identifier
			while self.queue[identifier] do
				identifier = identifier % net.Stream.MaxWriteStreams + 1
				if identifier == startid then
					ErrorNoHalt("Netstream is full of WriteStreams!")
					net.WriteUInt(0, 32)
					return
				end
			end
			self.curidentifier = identifier % net.Stream.MaxWriteStreams + 1

			if next(self.queue)==nil then
				self.activitytimeout = CurTime()+net.Stream.Timeout
				timer.Create("netstream_queueclean", 5, 0, function() self:Clean() end)
			end
			self.queue[identifier] = stream
			stream.identifier = identifier
			return stream
		end,

		Write = function(self, ply)
			local identifier = net.ReadUInt(32)
			local chunkidx = net.ReadUInt(32)
			local stream = self.queue[identifier]
			--print("Got request", identifier, chunkidx, stream)
			if stream then
				if stream:Write(ply, chunkidx) then
					self.activitytimeout = CurTime()+net.Stream.Timeout
					stream.timeout = CurTime()+net.Stream.Timeout
				end
			else
				-- Tell them the stream doesn't exist
				net.Start("NetStreamRead")
				net.WriteUInt(identifier, 32)
				net.WriteUInt(0, 32)
				if SERVER then net.Send(ply) else net.SendToServer() end
			end
		end,

		Clean = function(self)
			local t = CurTime()
			for k, stream in pairs(self.queue) do
				if (next(stream.clients)~=nil and t >= stream.timeout) or t >= self.activitytimeout then
					stream:Remove()
					self.queue[k] = nil
				end
			end
			if next(self.queue)==nil then
				timer.Remove("netstream_queueclean")
			end
		end,
	},
	__call = function(t)
		return setmetatable({
			activitytimeout = CurTime()+net.Stream.Timeout,
			curidentifier = 1,
			queue = {}
		}, t)
	end
}
setmetatable(WriteStreamQueue, WriteStreamQueue)
net.Stream.WriteStreams = WriteStreamQueue()

local ReadStreamQueue = {
	__index = {
		Add = function(self, stream)
			local queue = self.queues[stream.player]

			if #queue == net.Stream.MaxReadStreams then
				ErrorNoHalt("Receiving too many ReadStream requests!")
				return
			end
			
			for _, v in ipairs(queue) do
				if v.identifier == stream.identifier then
					ErrorNoHalt("Tried to start a new ReadStream for an already existing stream!")
					return
				end
			end

			queue[#queue+1] = stream
			if #queue == 1 then
				stream:Request()
			end
			return stream
		end,

		Remove = function(self, stream)
			local queue = rawget(self.queues, stream.player)
			if queue then
				if stream == queue[1] then
					table.remove(queue, 1)
					local nextInQueue = queue[1]
					if nextInQueue then
						nextInQueue:Request()
					else
						self.queues[stream.player] = nil
					end
				else
					for k, v in ipairs(queue) do
						if v == stream then
							table.remove(queue, k)
							break
						end
					end
				end
			end
		end,

		Read = function(self, ply)
			local identifier = net.ReadUInt(32)
			local queue = rawget(self.queues, ply)
			if queue and queue[1] then
				queue[1]:Read(identifier)
			end
		end
	},
	__call = function(t)
		return setmetatable({
			queues = setmetatable({}, {__index = function(t,k) local r={} t[k]=r return r end})
		}, t)
	end
}
setmetatable(ReadStreamQueue, ReadStreamQueue)
net.Stream.ReadStreams = ReadStreamQueue()


local WritingDataItem = {
	__index = {
		Write = function(self, ply, chunkidx)
			local client = self.clients[ply]
			if client.finished then return false end
			if chunkidx == #self.chunks+1 then self:Finished(ply) return true end

			if client.downloads+#self.chunks-client.progress >= net.Stream.MaxTries * #self.chunks then self:Finished(ply) return false end
			client.downloads = client.downloads + 1

			local chunk = self.chunks[chunkidx]
			if not chunk then return false end

			client.progress = chunkidx

			--print("Sending", "NetStreamRead", self.identifier, #chunk.data, chunkidx, chunk.crc)
			net.Start("NetStreamRead")
			net.WriteUInt(self.identifier, 32)
			net.WriteUInt(#chunk.data, 32)
			net.WriteUInt(chunkidx, 32)
			net.WriteString(chunk.crc)
			net.WriteData(chunk.data, #chunk.data)
			if CLIENT then net.SendToServer() else net.Send(ply) end
			return true
		end,

		Finished = function(self, ply)
			self.clients[ply].finished = true
			if self.callback then
				local ok, err = xpcall(self.callback, debug.traceback, ply)
				if not ok then ErrorNoHalt(err) end
			end
		end,

		GetProgress = function(self, ply)
			return self.clients[ply].progress / #self.chunks
		end,

		Remove = function(self)
			local sendTo = {}
			for ply, client in pairs(self.clients) do
				if not client.finished then
					client.finished = true
					if CLIENT or ply:IsValid() then sendTo[#sendTo+1] = ply end
				end
			end

			if next(sendTo)~=nil then
				--print("Sending", "NetStreamRead", self.identifier, 0)
				net.Start("NetStreamRead")
				net.WriteUInt(self.identifier, 32)
				net.WriteUInt(0, 32)
				if SERVER then net.Send(sendTo) else net.SendToServer() end
			end
		end

	},
	__call = function(t, data, callback)
		local chunks = {}
		for i=1, math.ceil(#data / net.Stream.SendSize) do
			local datachunk = string.sub(data, (i - 1) * net.Stream.SendSize + 1, i * net.Stream.SendSize)
			chunks[i] = { data = datachunk, crc = util.CRC(datachunk) }
		end

		return setmetatable({
			timeout = CurTime()+net.Stream.Timeout,
			chunks = chunks,
			callback = callback,
			lasttouched = 0,
			clients = setmetatable({},{__index = function(t,k)
				local r = {
					finished = false,
					downloads = 0,
					progress = 0,
				} t[k]=r return r
			end})
		}, t)
	end
}
setmetatable(WritingDataItem, WritingDataItem)

local ReadingDataItem = {
	__index = {
		Request = function(self)
			if self.downloads+self.numchunks-#self.chunks >= net.Stream.MaxTries*self.numchunks then self:Remove() return end
			self.downloads = self.downloads + 1
			timer.Create("NetStreamReadTimeout" .. self.identifier, net.Stream.Timeout*0.5, 1, function() self:Request() end)
			self:WriteRequest()
		end,

		WriteRequest = function(self)
			--print("Requesting", self.identifier, #self.chunks)
			net.Start("NetStreamWrite")
			net.WriteUInt(self.identifier, 32)
			net.WriteUInt(#self.chunks+1, 32)
			if CLIENT then net.SendToServer() else net.Send(self.player) end
		end,

		Read = function(self, identifier)
			if self.identifier ~= identifier then self:Request() return end

			local size = net.ReadUInt(32)
			if size == 0 then self:Remove() return end

			local chunkidx = net.ReadUInt(32)
			if chunkidx ~= #self.chunks+1 then self:Request() return end

			local crc = net.ReadString()
			local data = net.ReadData(size)

			if crc ~= util.CRC(data) then self:Request() return end

			self.chunks[chunkidx] = data
			if #self.chunks == self.numchunks then self:Remove(true) return end

			self:Request()
		end,

		GetProgress = function(self)
			return #self.chunks/self.numchunks
		end,

		Remove = function(self, finished)
			timer.Remove("NetStreamReadTimeout" .. self.identifier)

			local data
			if finished then
				data = table.concat(self.chunks)
				if self.compressed then
					data = util.Decompress(data, net.Stream.MaxSize)
				end
				self:WriteRequest() -- Notify we finished
			end

			local ok, err = xpcall(self.callback, debug.traceback, data)
			if not ok then ErrorNoHalt(err) end

			net.Stream.ReadStreams:Remove(self)
		end
	},
	__call = function(t, ply, callback, numchunks, identifier, compressed)
		return setmetatable({
			identifier = identifier,
			chunks = {},
			compressed = compressed,
			numchunks = numchunks,
			callback = callback,
			player = ply,
			downloads = 0
		}, t)
	end
}
setmetatable(ReadingDataItem, ReadingDataItem)


function net.WriteStream(data, callback, dontcompress)
	if not isstring(data) then
		error("bad argument #1 to 'WriteStream' (string expected, got " .. type(data) .. ")", 2)
	end
	if callback ~= nil and not isfunction(callback) then
		error("bad argument #2 to 'WriteStream' (function expected, got " .. type(callback) .. ")", 2)
	end

	local compressed = not dontcompress
	if compressed then
		data = util.Compress(data) or ""
	end

	if #data == 0 then
		net.WriteUInt(0, 32)
		return
	end

	if #data > net.Stream.MaxSize then
		ErrorNoHalt("net.WriteStream request is too large! ", #data/1048576, "MiB")
		net.WriteUInt(0, 32)
		return
	end

	local stream = net.Stream.WriteStreams:Add(WritingDataItem(data, callback, compressed))
	if not stream then return end
	
	--print("WriteStream", #stream.chunks, stream.identifier, compressed)
	net.WriteUInt(#stream.chunks, 32)
	net.WriteUInt(stream.identifier, 32)
	net.WriteBool(compressed)

	return stream
end

--If the receiver is a player then add it to a queue.
--If the receiver is the server then add it to a queue for each individual player
function net.ReadStream(ply, callback)
	if CLIENT then
		ply = NULL
	else
		if type(ply) ~= "Player" then
			error("bad argument #1 to 'ReadStream' (Player expected, got " .. type(ply) .. ")", 2)
		elseif not ply:IsValid() then
			error("bad argument #1 to 'ReadStream' (Tried to use a NULL entity!)", 2)
		end
	end
	if not isfunction(callback) then
		error("bad argument #2 to 'ReadStream' (function expected, got " .. type(callback) .. ")", 2)
	end
	
	local numchunks = net.ReadUInt(32)
	if numchunks == nil then
		return
	elseif numchunks == 0 then
		local ok, err = xpcall(callback, debug.traceback, "")
		if not ok then ErrorNoHalt(err) end
		return
	end

	local identifier = net.ReadUInt(32)
	local compressed = net.ReadBool()

	if numchunks > net.Stream.MaxChunks then
		ErrorNoHalt("ReadStream requests from ", ply, " is too large! ", numchunks * net.Stream.SendSize / 1048576, "MiB")
		return
	end

	--print("ReadStream", numchunks, identifier, compressed)

	return net.Stream.ReadStreams:Add(ReadingDataItem(ply, callback, numchunks, identifier, compressed))
end

if SERVER then
	util.AddNetworkString("NetStreamWrite")
	util.AddNetworkString("NetStreamRead")
end

--Send requested stream data
net.Receive("NetStreamWrite", function(len, ply)
	net.Stream.WriteStreams:Write(ply or NULL)
end)

--Download the sent stream data
net.Receive("NetStreamRead", function(len, ply)
	net.Stream.ReadStreams:Read(ply or NULL)
end)
