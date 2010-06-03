-- $Rev: 1621 $
-- $LastChangedDate: 2009-09-03 15:24:56 -0700 (Thu, 03 Sep 2009) $
-- $LastChangedBy: TomyLobo $


local rss_url = "http://www.wiremod.com:8060/changelog/~rss,feedmax=1/Wiremod/wire/rss.xml"


WireVersion = "2137" --manual revision, change this value to the revision-to-be once changes are committed
WireVersion = WireVersion .. " (exported)" -- leave this alone, it's to differentiate SVN checkouts from SVN Exported or downloaded versions of wire when a player types "wire_PrintVersion"

// This function is broken, as gmod now prevents file.Read for .svn file type
-- if file.Exists("../lua/wire/.svn/entries") then
	-- WireVersion = tonumber(string.Explode("\n", file.Read( "../lua/wire/.svn/entries"))[4]) --get svn revision, stolen from ULX
	-- SVNver = WireVersion -- this is for the sv_tags changing function at the bottom of WireLib.lua
-- end
WireLib.Version = WireVersion


if SERVER then
	local function initplayer(pl)
		umsg.Start("wire_rev", pl)
			umsg.Short(WireVersion)
		umsg.End()
	end
	hook.Add( "PlayerInitialSpawn", "WirePlayerInitSpawn", initplayer )

	local function PrintWireVersion(pl,cmd,args)
		if (pl and pl:IsValid()) then
			pl:PrintMessage(HUD_PRINTTALK, "Wire revision: "..WireVersion)
		else
			print("Wire revision: "..WireVersion)
		end
	end
	concommand.Add( "Wire_PrintVersion", PrintWireVersion )

	MsgN("================================\n===  Wire  "..WireVersion.."   Installed  ===\n================================")
end

if CLIENT then
	WireVersionLocal = WireVersion
	local function initplayer(um)
		WIRE_SERVER_INSTALLED = true
		WireVersion = um:ReadShort()
		MsgN("================================\n===  Wire revision: "..WireVersion.."     ===\n=== Local Wire revision:"..WireVersion.." ===\n================================")
	end
	usermessage.Hook( "wire_rev", initplayer )
end


--[[ Doesn't work, and nobody seems to know how to fix. Also, do not enable without uncommenting administration menu option in wiremenus.lua!
local update_check_lbl

-- http.Get Callback
local function CheckForUpdateCallback(contents, size)
	local rev = string.match(contents, "http://www%.wiremod%.com:8060/changelog/Wiremod%?cs=(%d+)&amp;csize=1")
	if rev then
		if tonumber(rev) > WireVersion then
			update_check_lbl:SetText("There's a newer rev of wire!\nYou have: "..WireVersion.."\n"..rev.." is current.")
		else
			update_check_lbl:SetText("You have: "..WireVersion.."\nYour Wire is up to date!")
		end
	else
		update_check_lbl:SetText("Unable to contact SVN server.\nD:")
	end
	update_check_lbl:GetParent():PerformLayout()
end

local function CheckForUpdateCP(Panel)
	local update_check_btn = vgui.Create("DButton")
	update_check_btn:SetText("Check for Update")
	update_check_btn.DoClick = function(button)
		http.Get(rss_url, "", CheckForUpdateCallback)
		button:SetDisabled(true)
		button:SetText("Checking....")
	end
	Panel:AddItem(update_check_btn)

	update_check_lbl = vgui.Create("DLabel")
	update_check_lbl:SetText("")
	update_check_lbl:SetAutoStretchVertical(true)
	Panel:AddItem(update_check_lbl)
end

hook.Add("PopulateToolMenu", "AddWireAdminUpdateCheck", function()
	spawnmenu.AddToolMenuOption("Wire", "Administration", "WireAdminUpdateCheck", "Check For Update", "", "", CheckForUpdateCP, {})
end)
]]
