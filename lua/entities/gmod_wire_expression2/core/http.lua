/*
	Simple HTTP Extension
	     (McLovin)
*/

E2Lib.RegisterExtension( "http", false, "Lets E2 chips make web requests to the real internet.", "Allows any E2 to make your server make arbitrary HTTP GET requests to any site. It can use this to make HTTP requests to any IP address inside your local network." )

local cvar_delay = CreateConVar( "wire_expression2_http_delay", "3", FCVAR_ARCHIVE )
local cvar_timeout = CreateConVar( "wire_expression2_http_timeout", "15", FCVAR_ARCHIVE )

local requests = WireLib.RegisterPlayerTable()
local run_on = {
	ents = {}
}

local function player_can_request( ply )
	local preq = requests[ply]

	return !preq or
		(preq.in_progress and preq.t_start and (CurTime() - preq.t_start) >= cvar_timeout:GetFloat()) or
			(!preq.in_progress and preq.t_end and (CurTime() - preq.t_end) >= cvar_delay:GetFloat())
end

__e2setcost( 20 )

e2function void httpRequest( string url )
	local ply = self.player
	if !player_can_request( ply ) or url == "" then return self:throw("httpRequest cooldown!", nil) end

	requests[ply] = {
		in_progress = true,
		t_start = CurTime(),
		t_end = 0,
		url = url
	}

	http.Fetch(url, function( contents, size, headers, code )
		if !IsValid( ply ) or !ply:IsPlayer() or !requests[ply] then return end

		local preq = requests[ply]

		preq.t_end = CurTime()
		preq.in_progress = false
		preq.data = contents or ""
		preq.success = 1

		local ent = self.entity
		if IsValid(ent) then
			if run_on.ents[ent] then
				self.data.httpClk = preq
				ent:Execute()
				self.data.httpClk = nil
			else
				ent:ExecuteEvent("httpLoaded", { contents or "", size, preq.url })
			end
		end

	end, function( err )
		if !IsValid( ply ) or !ply:IsPlayer() or !requests[ply] then return end

		local preq = requests[ply]

		preq.t_end = CurTime()
		preq.in_progress = false
		preq.data = ""
		preq.success = 0

		local ent = self.entity
		if IsValid(ent) then
			if run_on.ents[ent] then
				self.data.httpClk = preq
				ent:Execute()
				self.data.httpClk = nil
			else
				ent:ExecuteEvent("httpErrored", { err, preq.url })
			end
		end
	end)
end

__e2setcost( 5 )

e2function number httpCanRequest()
	return ( player_can_request( self.player ) ) and 1 or 0
end

e2function number httpClk()
	return self.data.httpClk and 1 or 0
end

e2function string httpData()
	local preq = requests[self.player]

	return preq and preq.data or ""
end

e2function number httpSuccess()
	local preq = requests[self.player]

	return preq and preq.success or 0
end

e2function string httpRequestUrl()
	local preq = requests[self.player]

	return preq and preq.url or ""
end

e2function string httpUrlEncode(string data)
	local ndata = string.gsub( data, "[^%w _~%.%-]", function( str )
		local nstr = string.format( "%X", string.byte( str ) )

		return "%" .. ( ( string.len( nstr ) == 1 ) and "0" or "" ) .. nstr
	end )

	return string.gsub( ndata, " ", "+" )
end

e2function string httpUrlDecode(string data)
	local ndata = string.gsub( data, "+", " " )

	return string.gsub( ndata, "(%%%x%x)", function( str )
		return string.char( tonumber( string.Right( str, 2 ), 16 ) )
	end )
end

e2function void runOnHTTP( number rohttp )
	run_on.ents[self.entity] = rohttp ~= 0 and true or nil
end

registerCallback( "destruct", function( self )
	run_on.ents[self.entity] = nil
end )

-- error: string, url: string
E2Lib.registerEvent("httpErrored", {
	{ "Error", "s" },
	{ "Url", "s" }
})

-- body: string, size: number, url: string
E2Lib.registerEvent("httpLoaded", {
	{ "Body", "s" },
	{ "Size", "n" },
	{ "Url", "s" }
})