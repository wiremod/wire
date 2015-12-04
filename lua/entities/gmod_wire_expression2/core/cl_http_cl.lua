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
lib.whitelistSyncNetMsgID = "wire_expression2_cl_http_whitelist" -- open to change
lib.currentUID = 0
lib.defaultWhitelistData = [[#
#	The Wiremod Expression 2 client-side HTTP request whitelist
#
#	Hints:
#	- One entry per line!
#	- Entries are also lua string patterns
#	- Anything after a # in an entry is ignored and treated as a comment
#	- You do not have to have a new line at the end of this file.
#	- Empty lines are ignored
#
#	Have fun!

#^https?://www.github.com/.*$
#^https?://www.github.com/.*$
]]

-- number function(void)
local function newUID()
	lib.currentUID = (lib.currentUID + 1) % 255
	return lib.currentUID -- return a number between 0 and 254
end

lib.rawRequest = http.Fetch
lib.requestMaxCompressedSize = 16 * 1024 * 1024 -- 16 megabytes
lib.segmentSize = 4 * 1024-- 4 kilobytes
lib.segmentBits = math.min(math.ceil(math.log(lib.segmentSize,2)) + 2,32)
lib.sendInterval = 0.5-- seconds
lib.HTTP_REQUEST_FAILED = "did not receive HTTP body" -- message for HTTP failure
lib.HTTP_REQUEST_TOO_BIG = "request was too big to handle" -- message for when a request is too large

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

-- void function(number uid, string body_compressed, number length)
-- Internal: Do not call.
local function writeHTTPBody(uid,body,length)
	local segments = math.ceil(length/lib.segmentSize)

	-- reliable netmessages are always sent in order
	for i=1,segments do
		local segment = body:sub(lib.segmentSize * (i-1) + 1,lib.segmentSize * i)
		net.Start(lib.netMsgID)
			net.WriteUInt(uid,8)						-- this is who we are
			net.WriteBool(false)						-- No; the request did not error
			net.WriteBool(true)							-- yes we are writing a body
			net.WriteUInt(#segment,lib.segmentBits)	-- the body is this much long
			net.WriteData(segment,#segment)				-- and here is the body
		net.SendToServer()

		coroutine.yield()
	end
end

-- void function(number uid, number length, table headers, number code)
-- Internal: Do not call.
local function writeMetadata(uid,length,headers,code)
	net.Start(lib.netMsgID)
		net.WriteUInt(uid,8)						-- this is who we are
		net.WriteBool(false)						-- No; the request did not error
		net.WriteBool(false)						-- we are ready to finalise the message
		-- CAPITAL SIN: net.WriteTable is horribly
		-- unoptimised; but there is no other
		-- elegant solution to write in a variable
		-- table
		net.WriteTable(headers)						-- these are the headers
		net.WriteUInt(code,12)						-- and this is the code
	net.SendToServer()
end

-- void function(number uid, string err)
-- Internal: Do not call.
local function returnFailure(uid,err)
	net.Start(lib.netMsgID)
		net.WriteUInt(uid,8)	-- this is who we are
		net.WriteBool(true)		-- unfortunately, the request caused an error
		net.WriteString(err)	-- and this is the code
	net.SendToServer()
end

-- void function(number uid, string body, number length, table headers, number code)
-- Internal: Do not call.
local function returnData(uid,body,length,headers,code)
	local body_compressed = util.Compress(body) or ""

	writeHTTPBody(uid,body_compressed,#body_compressed)
	writeMetadata(uid,length,headers,code)

	return true
end

-- void function(string url, number uid)
-- Internal: Do not call.
local function performRequest(url,uid)
	lib.rawRequest(url,function(body,length,headers,code)
		timerCoroutine("wire_e2_cl_http_"..uid,lib.sendInterval,function()
			return returnData(uid,body,length,headers,code)
		end)
	end,function(err)
		returnFailure(uid,err)
	end)
end

-- string, string function(void)
-- Internal: Do not call.
local function decodeRequest()
	return net.ReadString(),net.ReadUInt(8)
end

-- void function(void)
-- Internal: Do not call.
local function handleIncomingRequest()
	local url,uid = decodeRequest()

	performRequest(url,uid)
end

net.Receive(lib.netMsgID,function(_,ply)
	handleIncomingRequest(ply)
end)

-- void function(void)
local function reloadWhitelist()
	local whitelistText = file.Read("wire_http_whitelist_cl.txt","DATA")
	local whitelistData = {}
	if whitelistText and (whitelistText ~= "") then
		for entry,comment in whitelistText:gmatch("([^#\n\r]*)[^\n\r]*[\n\r]*") do
			if entry ~= "" then
				whitelistData[#whitelistData+1] = entry
			end
		end
	else
		file.Write("wire_http_whitelist_cl.txt",lib.defaultWhitelistData)
	end

	net.Start(lib.whitelistSyncNetMsgID)
	-- CAPITAL SIN: net.WriteTable is horribly
	-- unoptimised; but there is no other
	-- elegant solution to write in a variable
	-- table
		net.WriteTable(whitelistData)
	net.SendToServer()

	print("Client-side HTTP whitelist reloaded")
end

-- Send, to the server, our request whitelist
reloadWhitelist()
concommand.Add("wire_expression2_http_reloadwhitelist",reloadWhitelist)
