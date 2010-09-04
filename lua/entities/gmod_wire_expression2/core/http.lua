/*
	Simple HTTP Extension
	     (McLovin)
*/

E2Lib.RegisterExtension( "http", true )

local cvar_delay = CreateConVar( "wire_expression2_http_delay", "3", FCVAR_ARCHIVE )
local cvar_timeout = CreateConVar( "wire_expression2_http_timeout", "15", FCVAR_ARCHIVE )

local requests = {}
local run_on = {
	clk = 0,
	ents = {}
}

local function player_can_request( ply )
	local preq = requests[ply]

	return !preq or
		(preq.in_progress and preq.t_start and (CurTime() - preq.t_start) >= cvar_timeout:GetInt()) or
			(!preq.in_progress and preq.t_end and (CurTime() - preq.t_end) >= cvar_delay:GetInt())
end

__e2setcost( 20 )

e2function void httpRequest( string url )
	if !player_can_request( self.player ) or url == "" then return end

	requests[self.player] = {
		in_progress = true,
		t_start = CurTime(),
		t_end = 0,
		url = url
	}

	http.Get(
		url,
		"",
		function( args, contents, size )
			local ply = args[1]

			if !validEntity( ply ) or !ply:IsPlayer() or !requests[ply] then return end

			local preq = requests[ply]

			preq.t_end = CurTime()
			preq.in_progress = false
			preq.data = contents or ""

			run_on.clk = 1

			for ent,eply in pairs( run_on.ents ) do
				if validEntity( ent ) and ent.Execute and eply == ply then
					ent:Execute()
				end
			end

			run_on.clk = 0
		end,
		self.player
	)
end

__e2setcost( 5 )

e2function number httpCanRequest()
	return ( player_can_request( self.player ) ) and 1 or 0
end

e2function number httpClk()
	return run_on.clk
end

e2function string httpData()
	local preq = requests[self.player]

	return preq.data or ""
end

e2function string httpRequestUrl()
	local preq = requests[self.player]

	return preq.url or ""
end

e2function string httpUrlEncode(string url)
	local nurl = string.gsub( url, "[^%w _.~-]", function( str )
		return "%" .. string.format( "%X", string.byte( str ) )
	end )

	return string.gsub( nurl, " ", "+" )
end

e2function void runOnHTTP( number rohttp )
	run_on.ents[self.entity] = ( rohttp != 0 ) and self.player or nil
end

registerCallback( "destruct", function( self )
	run_on.ents[self.entity] = nil
end )
