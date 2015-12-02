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

-- should we use clientside HTTP requests?
local cvar_useClient = CreateConVar("wire_expression2_http_client","1",FCVAR_ARCHIVE)

E2Lib.clHTTP = {}
local lib = E2Lib.clHTTP

lib.netMsgID = "wire_expression2_cl_http" -- open to change
lib.currentUID = 0

-- number function(void)
-- Internal: Do not call.
local function newUID()
	lib.currentUID = (lib.currentUID + 1) % 255
	return lib.currentUID -- return a number between 0 and 255
end

lib.rawRequest = http.Fetch
lib.requestMaxCompressedSize = 16 * 1024 * 1024 -- 16 megabytes
lib.segmentSize = 4 * 1024-- 4 kilobytes
lib.segmentBits = math.min(math.ceil(math.log(lib.segmentSize,2)) + 2,32)
lib.sendInterval = 0.5-- seconds
lib.sendTimeout = 5-- seconds
lib.HTTP_REQUEST_FAILED = "did not receive HTTP body" -- message for HTTP failure
lib.HTTP_REQUEST_TOO_BIG = "request was too big to handle" -- message for when a request is too large
lib.HTTP_REQUEST_TIMEOUT = "client took too long to report back" -- message for when a client takes too long inbetween messages

-- void function(string id, number interval, function func)
-- Internal: Do not call.
local function timerCoroutine(id,interval,func)
	func = coroutine.wrap(func)
	timer.Create(id,interval,0,function()
		if func() then
			timer.Remove(id)
		end
	end)
end

util.AddNetworkString(lib.netMsgID)

lib.requests = {}

-- void function(entity client, string url, number uid)
-- Internal: Do not call.
local function launchNewRequest(client,url,uid)
	net.Start(lib.netMsgID)
		net.WriteString(url)
		net.WriteUInt(uid,8)
	net.Send(client)
end

-- string, boolean function(void)
-- Internal: Do not call.
local function decodeRequestHeader()
	return net.ReadUInt(8),net.ReadBool()
end

-- boolean function(void)
-- Internal: Do not call.
local function isSendingBody()
	return net.ReadBool()
end

-- string function(void)
-- Internal: Do not call.
local function readSegment()
	return net.ReadData(net.ReadInt(lib.segmentBits))
end

-- table, number function(void)
-- Internal: Do not call.
local function readMetadata()
	return net.ReadTable(),net.ReadInt(12)
end

-- table, number function(void)
-- Internal: Do not call.
local function readError()
	return net.ReadString()
end

-- void function(void)
-- Internal: Do not call.
local function handleIncomingRequest()
	local uid,failure = decodeRequestHeader()

	if lib.requests[uid] then
		local request = lib.requests[uid]
		if (SysTime() - request.lastTouched) > lib.sendTimeout then
			request.failure(lib.HTTP_REQUEST_TIMEOUT)
			lib.requests[uid] = nil

			return
		end

		request.lastTouched = SysTime()
		if not failure then
			request.body_compressed = request.body_compressed or "" -- define the compressed body if it does not already exist
			local isSendingBody = isSendingBody()
			if isSendingBody then
				local segment = readSegment()
				request.body_compressed = request.body_compressed..segment

				if #request.body_compressed > lib.requestMaxCompressedSize then
					request.failure(lib.HTTP_REQUEST_TOO_BIG)
					lib.requests[uid] = nil
				end
			else
				local headers,code = readMetadata()

				local body = ""
				if request.body_compressed ~= "" then
					body = util.Decompress(request.body_compressed)
				end

				if body then
					request.success(body,#body,headers,code)
				elseif request.failure then
					request.failure(lib.HTTP_REQUEST_FAILED)
				end

				lib.requests[uid] = nil
			end
		else
			if request.failure then
				request.failure(readError())
			end
			lib.requests[uid] = nil
		end
	else
		error("Attempt to send a request with an unknown UID "..uid)
	end
end

local function canOverwriteUID(uid)
	if lib.requests[uid] then
		return (SysTime() - lib.requests[uid].lastTouched) > lib.sendTimeout
	end
	
	return true
end

-- void function(entity client, string url, function callback_success[, function callback_failure])
function lib.request(client,url,callback_success,callback_failure)
	-- When the client sends us the data from the request, we need to know which
	-- request it was for, so a UID is used.

	if(cvar_useClient:GetInt() ~= 0) then
		local uid
		repeat
			uid = newUID()
		until canOverwriteUID(uid)

		lib.requests[uid] = {
			success = callback_success,
			failure = callback_failure,
			lastTouched = SysTime(),
		}

		launchNewRequest(client,url,uid)
	else
		lib.rawRequest(url,callback_success,callback_failure)
	end
end

net.Receive(lib.netMsgID,function(_,ply)
	handleIncomingRequest(ply)
end)
