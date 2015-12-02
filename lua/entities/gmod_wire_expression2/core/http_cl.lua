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
lib.requests = {}

-- string function(void)
function lib:newUID()
	return ("0x%08xf"):format(math.random(1,0xD4A51000))-- return 0x(hex) between 0 and 10^12
end

if SERVER then
	util.AddNetworkString(lib.netMsgID)

	-- void function(entity client, string url, function callback)
	function lib:request(client,url,callback)
		-- When the client sends us the data from the request, we need to know which
		-- request it was for, so a UID is used.
		local uid = self:newUID()

		self.requests[uid] = callback
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
else

end

net.Receive(lib.netMsgID,function(_,ply)
	lib:handleIncomingRequest(ply)
end)
