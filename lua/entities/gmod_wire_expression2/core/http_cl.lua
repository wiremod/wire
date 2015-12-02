--[[

	Clientside HTTP library
	 - swadical 🍌

]]

--	Clientside HTTP is separate from serverside HTTP:
--		Serverside HTTP allows greater speeds than clientside HTTP and it is
--		up to the server owner to decide which extension should be enabled
--		through a convar (found in core/http.lua)

--	This library will mirror the functionality of core/http.lua as best as
--	possible, making sure any existing e2s which make use of the http library
--	are not broken by this extension

E2Lib.clHTTP = {}
local lib = E2Lib.clHTTP

lib.netMsgID = "wire_expression2_cl_http" -- open to change

-- string function(void)
function lib:newUID()
	return ("0x%08xf"):format(math.random(1,0xD4A51000))-- return 0x(hex) between 0 and 10^12
end

lib.rawRequest = http.Fetch
lib.segmentSize = 4 * 1024-- 4 kilobytes
lib.segmentBits = math.min(math.ceil(math.log(lib.segmentSize+2,2)),32)
lib.sendInterval = 0.5-- seconds
lib.HTTP_REQUEST_FAILED = 1024--enum for HTTP failure

-- void function(string id, number interval, function func)
-- Internal: Do not call.
function lib.timerCoroutine(id,interval,func)
	func = coroutine.wrap(func)
	timer.Create(id,interval,0,function()
		if func() then
			timer.Remove(id)
		end
	end)
end

util.AddNetworkString(lib.netMsgID)

lib.requests = {}

-- void function(entity client, string url, function callback_success[, function callback_failure])
function lib:request(client,url,callback_success,callback_failure)
	-- When the client sends us the data from the request, we need to know which
	-- request it was for, so a UID is used.
	local uid = self:newUID()

	self.requests[uid] = {
		success = callback_success,
		failure = callback_failure
	}
	self:launchNewRequest(client,url,uid)
end

-- void function(entity client, string url, string uid)
-- Internal: Do not call.
function lib:launchNewRequest(client,url,uid)
	net.Start(self.netMsgID)
		net.WriteString(url)
		net.WriteString(uid)
	net.Send(client)
end

-- string, boolean function(void)
-- Internal: Do not call.
function lib:decodeRequestHeader()
	return net.ReadString(),net.ReadBool()
end

-- boolean function(void)
-- Internal: Do not call.
function lib:isSendingBody()
	return net.ReadBool()
end

-- string function(void)
-- Internal: Do not call.
function lib:readSegment()
	return net.ReadData(net.ReadInt(self.segmentBits))
end

-- table, number function(void)
-- Internal: Do not call.
function lib:readMetadata()
	return net.ReadTable(),net.ReadInt(12)
end

-- table, number function(void)
-- Internal: Do not call.
function lib:readError()
	return net.ReadString()
end

-- void function(void)
-- Internal: Do not call.
function lib:handleIncomingRequest()
	local uid,failure = self:decodeRequestHeader()

	if self.requests[uid] then
		local request = self.requests[uid]
		if not failure then
			request.body_compressed = request.body_compressed or "" -- define the compressed body if it does not already exist
			local isSendingBody = self:isSendingBody()
			if isSendingBody then
				local segment = self:readSegment()
				request.body_compressed = request.body_compressed..segment
			else
				local headers,code = self:readMetadata()

				local body = ""
				if request.body_compressed ~= "" then
					body = util.Decompress(request.body_compressed)
				end

				if body then
					request.success(body,#body,headers,code)
				else
					request.failure(self.HTTP_REQUEST_FAILED)
				end
			end
		else
			if request.failure then
				request.failure(self:readError())
			end
			self.requests[uid] = nil
		end
	else
		error("Attempt to send a request with an unknown UID "..uid)
	end
end

net.Receive(lib.netMsgID,function(_,ply)
	lib:handleIncomingRequest(ply)
end)
