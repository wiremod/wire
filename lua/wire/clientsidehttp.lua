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

clHTTP = {}

clHTTP.netMsgID = "wire_expression2_cl_http" -- open to change
clHTTP.whitelistSyncNetMsgID = "wire_expression2_cl_http_whitelist" -- open to change
clHTTP.currentUID = 0

-- number function(void)
local function newUID()
	clHTTP.currentUID = (clHTTP.currentUID + 1) % 255
	return clHTTP.currentUID -- return a number between 0 and 254
end

-- void function(string id, number interval, function func); Internal: Do not call.
local function timerCoroutine(id,interval,func)
    func = coroutine.wrap(func)
    timer.Create(id,interval,0,function()
        if func() then
            timer.Remove(id)
        end
    end)
end

clHTTP.rawRequest = http.Fetch
clHTTP.requestMaxCompressedSize = 16 * 1024 * 1024 -- 16 megabytes
clHTTP.segmentSize = 4 * 1024-- 4 kilobytes
clHTTP.segmentBits = math.min(math.ceil(math.log(clHTTP.segmentSize,2)) + 2,32)
clHTTP.sendInterval = 0.5-- seconds
clHTTP.sendTimeout = 5-- seconds
clHTTP.HTTP_REQUEST_FAILED = "did not receive HTTP body" -- message for HTTP failure
clHTTP.HTTP_REQUEST_TOO_BIG = "request was too big to handle" -- message for when a request is too large
clHTTP.HTTP_REQUEST_TIMEOUT = "client took too long to report back" -- message for when a client takes too long inbetween messages

clHTTP.defaultWhitelistData = ([[#
#	The Wiremod Expression 2 %s-side HTTP request whitelist
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
]]):format(SERVER and "server" or "client")

if SERVER then
    AddCSLuaFile()

    -- should we use clientside HTTP requests?
    local cvar_useClient = CreateConVar("wire_expression2_http_client","1",FCVAR_ARCHIVE)

    -- hardcoded entries: these are always preserved and are (ideally) for developer use only
    clHTTP.requestWhitelist = {
    	shared = { -- ordered list of whitelisted patterns

    	},
    	serverside = { -- ordered list of whitelisted patterns

    	},
    	clientside = { -- a table indexed by a player entity object, holding a set of ordered sub-table whitelist patterns
    		default = { -- ordered list of default whitelisted patterns: add entries here.

    		},
    	},
    }

    util.AddNetworkString(clHTTP.netMsgID)
    util.AddNetworkString(clHTTP.whitelistSyncNetMsgID)

    clHTTP.requests = {}

    -- void function(entity client, string url, number uid); Internal: Do not call.
    local function launchNewRequest(client,url,uid)
    	net.Start(clHTTP.netMsgID)
    		net.WriteString(url)
    		net.WriteUInt(uid,8)
    	net.Send(client)
    end

    -- void function(void); Internal: Do not call.
    local function handleIncomingRequest()
    	local uid,failure = net.ReadUInt(8),net.ReadBool()

    	if clHTTP.requests[uid] then
    		local request = clHTTP.requests[uid]
    		if (SysTime() - request.lastTouched) > clHTTP.sendTimeout then
    			if request.failure then
    				request.failure(clHTTP.HTTP_REQUEST_TIMEOUT)
    			end
    			clHTTP.requests[uid] = nil

    			return
    		end

    		request.lastTouched = SysTime()
    		if not failure then
    			request.body_compressed = request.body_compressed or "" -- define the compressed body if it does not already exist
    			local isSendingBody = net.ReadBool()
    			if isSendingBody then
    				local segment = net.ReadData(net.ReadInt(clHTTP.segmentBits))
    				request.body_compressed = request.body_compressed..segment

    				if #request.body_compressed > clHTTP.requestMaxCompressedSize then
    					request.failure(clHTTP.HTTP_REQUEST_TOO_BIG)
    					clHTTP.requests[uid] = nil
    				end
    			else
    				local headers,code = net.ReadTable(),net.ReadInt(12)

    				local body = ""
    				if request.body_compressed ~= "" then
    					body = util.Decompress(request.body_compressed)
    				end

    				if body then
    					request.success(body,#body,headers,code)
    				elseif request.failure then
    					request.failure(clHTTP.HTTP_REQUEST_FAILED)
    				end

    				clHTTP.requests[uid] = nil
    			end
    		else
    			if request.failure then
    				request.failure(net.ReadString())
    			end
    			clHTTP.requests[uid] = nil
    		end
    	else
    		error("Attempt to send a request with an unknown UID "..uid)
    	end
    end

    local function canOverwriteUID(uid)
    	if clHTTP.requests[uid] then
    		return (SysTime() - clHTTP.requests[uid].lastTouched) > clHTTP.sendTimeout
    	end

    	return true
    end

    -- bool,string function(entity/bool client, string url)
    function clHTTP.canRequest(client,url)
    	for i,entry in ipairs(clHTTP.requestWhitelist.shared) do
    		if url:match(entry) then
    			return true,"shared"
    		end
    	end

    	if client and clHTTP.requestWhitelist.clientside[client] then
    		for i,entry in ipairs(clHTTP.requestWhitelist.clientside[client]) do
    			if url:match(entry) then
    				return true,"clientside"
    			end
    		end
    	end

    	for i,entry in ipairs(clHTTP.requestWhitelist.serverside) do
    		if url:match(entry) then
    			return true,"serverside"
    		end
    	end

    	return false
    end

    -- void function(entity client, string url, function callback_success[, function callback_failure])
    function clHTTP.request(client,url,callback_success,callback_failure)
    	-- When the client sends us the data from the request, we need to know which
    	-- request it was for, so a UID is used.

    	if not clHTTP.canRequest(client,url) then return end

    	if client and (cvar_useClient:GetInt() ~= 0) then
    		local uid
    		repeat
    			uid = newUID()
    		until canOverwriteUID(uid)

    		clHTTP.requests[uid] = {
    			success = callback_success,
    			failure = callback_failure,
    			lastTouched = SysTime(),
    		}

    		launchNewRequest(client,url,uid)
    	else
    		clHTTP.rawRequest(url,callback_success,callback_failure)
    	end
    end

    -- The serverside whitelist reloading function
    -- void function(entity ply)
    local function reloadWhitelist(ply)
    	if IsValid(ply) then return end

    	local whitelistText = file.Read("wire_http_whitelist_sv.txt","DATA")
    	if whitelistText and (whitelistText ~= "") then
    		for entry,comment in whitelistText:gmatch("([^#\n\r]*)[^\n\r]*[\n\r]*") do
    			if entry ~= "" then
    				clHTTP.requestWhitelist.serverside[#clHTTP.requestWhitelist.serverside+1] = entry
    			end
    		end
    	else
    		file.Write("wire_http_whitelist_sv.txt",clHTTP.defaultWhitelistData)
    	end

    	print("Server-side HTTP whitelist reloaded")
    end
    concommand.Add("wire_expression2_http_reloadwhitelist",reloadWhitelist)

    reloadWhitelist()

    net.Receive(clHTTP.netMsgID,function(_,ply)
    	handleIncomingRequest(ply)
    end)

    net.Receive(clHTTP.whitelistSyncNetMsgID,function(_,ply)
    	local whitelistData = net.ReadTable()

    	local whitelist = {} -- create (and reset) the table

    	for i,entry in ipairs(clHTTP.requestWhitelist.clientside.default) do
    		whitelist[#whitelist+1] = entry
    	end

    	for i,entry in ipairs(whitelistData) do
    		whitelist[#whitelist+1] = entry
    	end

    	clHTTP.requestWhitelist.clientside[ply] = whitelist
    end)
else
    -- void function(string id, number interval, function func); Internal: Do not call.
    local function timerCoroutine(id,interval,func)
    	func = coroutine.wrap(func)
    	timer.Create(id,interval,0,function()
    		if func() then
    			timer.Remove(id)
    		end
    	end)
    end

    -- void function(number uid, string body_compressed, number length); Internal: Do not call.
    local function writeHTTPBody(uid,body,length)
    	local segments = math.ceil(length/clHTTP.segmentSize)

    	-- reliable netmessages are always sent in order
    	for i=1,segments do
    		local segment = body:sub(clHTTP.segmentSize * (i-1) + 1,clHTTP.segmentSize * i)
    		net.Start(clHTTP.netMsgID)
    			net.WriteUInt(uid,8)						-- this is who we are
    			net.WriteBool(false)						-- No; the request did not error
    			net.WriteBool(true)							-- yes we are writing a body
    			net.WriteUInt(#segment,clHTTP.segmentBits)	-- the body is this much long
    			net.WriteData(segment,#segment)				-- and here is the body
    		net.SendToServer()

    		coroutine.yield()
    	end
    end

    -- void function(number uid, number length, table headers, number code); Internal: Do not call.
    local function writeMetadata(uid,length,headers,code)
    	net.Start(clHTTP.netMsgID)
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

    -- void function(number uid, string err); Internal: Do not call.
    local function returnFailure(uid,err)
    	net.Start(clHTTP.netMsgID)
    		net.WriteUInt(uid,8)	-- this is who we are
    		net.WriteBool(true)		-- unfortunately, the request caused an error
    		net.WriteString(err)	-- and this is the code
    	net.SendToServer()
    end

    -- void function(number uid, string body, number length, table headers, number code); Internal: Do not call.
    local function returnData(uid,body,length,headers,code)
    	local body_compressed = util.Compress(body) or ""

    	writeHTTPBody(uid,body_compressed,#body_compressed)
    	writeMetadata(uid,length,headers,code)

    	return true
    end

    -- void function(string url, number uid); Internal: Do not call.
    local function performRequest(url,uid)
    	clHTTP.rawRequest(url,function(body,length,headers,code)
    		timerCoroutine("wire_e2_cl_http_"..uid,clHTTP.sendInterval,function()
    			return returnData(uid,body,length,headers,code)
    		end)
    	end,function(err)
    		returnFailure(uid,err)
    	end)
    end

    -- void function(void); Internal: Do not call.
    local function handleIncomingRequest()
    	local url,uid = net.ReadString(),net.ReadUInt(8)

    	performRequest(url,uid)
    end

    net.Receive(clHTTP.netMsgID,function(_,ply)
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
    		file.Write("wire_http_whitelist_cl.txt",clHTTP.defaultWhitelistData)
    	end

    	net.Start(clHTTP.whitelistSyncNetMsgID)
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
end
