-- $Rev: 2289 $
-- $LastChangedDate: 2010-11-13 01:20am +0100 (Sat, 13 Nov 2010) $
-- $LastChangedBy: Divran $

-- Get version
function WireLib.GetWireVersion()
	local version = "2288 (OLD VERSION)"
	local plainversion = 2288
	local exported = true

	-- Try getting the version using the .svn files:
	if (file.Exists("lua/wire/client/.svn/entries", true)) then
		version = string.Explode("\n", file.Read( "lua/wire/client/.svn/entries", true) or "")[4]
		exported = false
		plainversion = version
	elseif (file.Exists("wire_version.txt")) then -- Try getting the version by reading the text file:
		plainversion = file.Read("wire_version.txt")
		version = plainversion .. " (EXPORTED)"
	end

	return version, plainversion, exported
end

-- Get online version
function WireLib.GetOnlineWireVersion( callback )
	http.Get("http://wiremod.svn.sourceforge.net/svnroot/wiremod/trunk/","",function(contents,size)
		local rev = tonumber(string.match( contents, "Revision ([0-9]+)" ))
		callback(rev,contents,size)
	end)
end

if (SERVER) then
	------------------------------------------------------------------
	-- Get the version
	------------------------------------------------------------------
	WireLib.Version = WireLib.GetWireVersion()
	WireVersion = WireLib.Version -- Backwards compatibility

	-- Print the version to the console on load:
	MsgN("WireMod Installed. Version: "..tostring(WireLib.Version))

	------------------------------------------------------------------
	-- Send the version to the client
	------------------------------------------------------------------
	local function recheck( ply, tries )
		timer.Simple(5,function(ply)
			if (ply and ply:IsValid()) then -- Success!
				umsg.Start("wire_rev",ply)
					umsg.String( WireLib.Version )
				umsg.End()
			else
				if (tries and tries > 3) then return end -- several failures.. stop trying
				recheck(ply, (tries or 0) + 1) -- Try again
			end
		end)
	end
	hook.Add("PlayerInitialSpawn","WirePlayerInitSpawn",recheck)


	-- Send the version to the client ON REQUEST
	local antispam = {}
	concommand.Add("Wire_RequestVersion",function(ply,cmd,args)
		if (!antispam[ply]) then antispam[ply] = 0 end
		if (antispam[ply] < CurTime()) then
			antispam[ply] = CurTime() + 0.5
			umsg.Start("wire_rev",ply)
				umsg.String( WireLib.Version )
			umsg.End()
		end
	end)

	------------------------------------------------------------------
	-- Wire_PrintVersion
	-- prints the server's version on the client
	-- This doesn't use the above sending-to-client because it's meant to work even if the above code fails.
	------------------------------------------------------------------
	concommand.Add("Wire_PrintVersion",function(ply,cmd,args)
		if (ply and ply:IsValid()) then
			ply:ChatPrint("Server's Wire Version: " .. WireLib.Version)
		else
			print("Server's Wire Version: " .. WireLib.Version)
		end
	end)

	------------------------------------------------------------------
	-- Tags
	-- Adds "wireexport####" or "wiresvn####" to tags
	------------------------------------------------------------------

	local cvar = GetConVar("sv_tags")
	timer.Create("Wire_Tags",1,0,function()
		local tags = cvar:GetString()
		if (!tags:find( "wire" )) then
			local version, plainversion, exported = WireLib.GetWireVersion()
			local tag = "wire" .. ( exported and "exported" or "svn" ) .. plainversion
			RunConsoleCommand( "sv_tags", tags .. "," .. tag )
		end
	end)

else -- CLIENT

	------------------------------------------------------------------
	-- Get the version
	------------------------------------------------------------------
	WireLib.LocalVersion = WireLib.GetWireVersion()
	WireVersionLocal = WireLib.LocalVersion -- Backwards compatibility

	-- Print the version to the console on load:
	MsgN("WireMod Installed. Version: "..tostring(WireLib.LocalVersion))

	------------------------------------------------------------------
	-- Receive the version from the server
	------------------------------------------------------------------

	WireLib.Version = "-unknown-" -- We don't know the server's version yet
	WireVersion = "-unknown-" -- Backwards compatibility

	usermessage.Hook("wire_rev",function(um)
		WireLib.Version = um:ReadString()
		WireVersion = WireLib.Version
	end)
end
