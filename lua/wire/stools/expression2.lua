WireToolSetup.setCategory( "Chips, Gates" )
WireToolSetup.open("expression2", "Expression 2", "gmod_wire_expression2", nil, "Expression2s")

if CLIENT then
	language.Add("Tool.wire_expression2.name", "Expression 2 Tool (Wire)")
	language.Add("Tool.wire_expression2.desc", "Spawns an Expression 2 chip for use with the wire system.")
	language.Add("sboxlimit_wire_expressions", "You've hit the Expression limit!")

	TOOL.Information = {
		{ name = "left", text = "Create " .. TOOL.Name },
		{ name = "right", text = "Open " .. TOOL.Name .. " in Editor" },
	}

	--WireToolSetup.setToolMenuIcon( "beer/wiremod/gate_e2" )
	WireToolSetup.setToolMenuIcon( "vgui/e2logo" )
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/gate_e2.mdl",
	modelsize = "",
	scriptmodel = "",
	select = "",
	autoindent = 1
}

TOOL.MaxLimitName = "wire_expressions"
WireToolSetup.BaseLang()

-- Needed a method for printing to players' chatboxes without the outdated and limited umsg based ChatPrint()
-- Not sure if there's already a framework for this in wire, if so replace this with that
local BetterChatPrint = function() end
if SERVER then
	util.AddNetworkString("WireExpression2_BetterChatPrint")
	BetterChatPrint = function(plr, msg)
		net.Start("WireExpression2_BetterChatPrint")
		net.WriteString(msg)
		net.Send(plr)
	end
else
	-- Netmsg is coming from the server so no need for sanity checks as the server *should* be as expected unlike clients
	net.Receive("WireExpression2_BetterChatPrint", function()
		chat.AddText(net.ReadString())
	end)
end

if SERVER then
	CreateConVar("sbox_maxwire_expressions", 20)

	function TOOL:MakeEnt(ply, model, Ang, trace)
		return MakeWireExpression2(ply, trace.HitPos, Ang, model)
	end

	function TOOL:PostMake(ent)
		WireLib.Expression2Upload( self:GetOwner(), ent )
	end

	function TOOL:LeftClick_Update( trace )
		WireLib.Expression2Upload( self:GetOwner(), trace.Entity )
	end

	function TOOL:Reload(trace)
		if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_expression2" and trace.Entity.context then
			trace.Entity:Reset()
			return true
		else
			return false
		end
	end

	-- Simple serverside only local table for storing view requests to make handling them not spaghetti code
	local viewRequests = {}

	util.AddNetworkString("WireExpression2_ViewRequest")
	util.AddNetworkString("WireExpression2_AnswerRequest")

	-- Validates a single request using the initiator and chip (handles cleanup and expiry message)
	local function ValidateRequest(initiator, chip)
		if not viewRequests[initiator] or not viewRequests[initiator][chip] then return false end -- Initiator either has no data in viewRequests or has no request for this chip
		if not IsValid(initiator) then -- Invalid initiator in request table
			viewRequests[initiator] = nil
			return false
		end
		if not IsValid(chip) or chip:GetClass() ~= "gmod_wire_expression2" then -- Invalid chip in request table
			viewRequests[initiator][chip] = nil
			return false
		end
		if CurTime() > viewRequests[initiator][chip].expiry then -- Expiry point passed
			BetterChatPrint(initiator, "Your request to view "..chip.player:Nick().."'s chip, '"..chip.name.."', has expired")
			viewRequests[initiator][chip] = nil
			return false
		end
		return true
	end

	local function InvalidateRequests()
		local count = 0
		for initiator, _ in pairs(viewRequests) do
			for chip, _ in pairs(viewRequests[initiator]) do
				if ValidateRequest(initiator, chip) then count = count + 1
				elseif not viewRequests[initiator] then break end -- If that validation removed the entire initiating player, stop trying to enumerate their requests
			end
		end

		-- If the count is 0 then there's no requests to invalidate, so remove the hook
		if count == 0 then hook.Remove("Tick", "WireExpression2_InvalidateRequests") end
	end

	local function RequestView(chip, initiator)
		local truncName = string.sub(chip.name, 1, 256) -- In case someone starts making cursed names

		-- Make sure this isn't creating a request for a chip with an outstanding valid request
		if ValidateRequest(initiator, chip) then -- Note that ValidateRequest also deletes the invalid request and handles the expiry notif
			BetterChatPrint(initiator, "Request to view '"..truncName.."' already sent")
			return
		end

		-- Otherwise, print to the tool user's chat that a view request was sent
		-- and send a view request to the chip's owner (also print a message to their chat to tell them they received a request)
		BetterChatPrint(initiator, "E2 view request sent for '"..truncName.."' owned by "..chip.player:Nick())
		BetterChatPrint(chip.player, "You just received a request to view your E2 '"..truncName.."' from "..initiator:Nick()..", which you can view in your context menu at the top left ('C' by default)")

		-- Add the request data to the local requests table for when the request from the client comes in
		if not viewRequests[initiator] then viewRequests[initiator] = {} end -- Initialise this user in the viewRequests table if not in there already
		viewRequests[initiator][chip] = {
			name = truncName,
			expiry = CurTime() + 60 -- 1 minute for the request before it's invalidated (could make this a convar)
		}

		-- Invalidate expired requests
		hook.Add("Tick", "WireExpression2_InvalidateRequests", InvalidateRequests)

		net.Start("WireExpression2_ViewRequest")
			net.WriteEntity(initiator)                           -- The player attempting to view the E2
			net.WriteEntity(chip)                                -- Chip entity for validation clientside
			net.WriteString(truncName)                           -- Name of the E2 so the owner knows what they're agreeing to
			net.WriteFloat(viewRequests[initiator][chip].expiry) -- For making requests expire on time clientside
		net.Send(chip.player)
	end

	util.AddNetworkString("WireExpression2_OpenEditor")
	hook.Add("KeyPress","gmod_expression2_tool_rightclick",function(ply,key)
		--[[
			TOOL:RightClick had to be replaced with KeyPress as prop protection was preventing
			the view requests system from functioning as intended

			So this manually handles right click meaning people don't need to give each other
			full prop protection permissions in order to share a chip
		]]
		if key == IN_ATTACK2 then
			local t = WireToolHelpers.GetActiveTOOL("wire_expression2",ply)
			if t then
				t:Do_RightClick()
			end
		end
	end)
	function TOOL:Do_RightClick()
		local player = self:GetOwner()
		local chip = player:GetEyeTrace().Entity
		if chip:IsPlayer() then return end

		if IsValid(chip) and chip:GetClass() == "gmod_wire_expression2" then
			if chip.player == player then -- Just download if the toolgun user owns this chip
				self:Download(player, chip)
				player:SetAnimation(PLAYER_ATTACK1)
			elseif WireLib.CanTool(player, chip, "wire_expression2") then -- The player has prop protection perms on the chip
				self:Download(player, chip)
				player:SetAnimation(PLAYER_ATTACK1)

				local playerType = "player"
				if player:IsAdmin() then
					playerType = player:IsSuperAdmin() and "superadmin" or "admin"
				end
				BetterChatPrint(
					chip.player,
					string.format("The %s '%s' just accessed your chip '%s' via prop protection", playerType, player:Nick(), chip.name)
				)
			elseif (chip.alwaysAllow and chip.alwaysAllow[player]) then -- The player doesnt have prop protection perms, however the owner always allows for this chip (or they're invalid)
				self:Download(player, chip)
				player:SetAnimation(PLAYER_ATTACK1)
			else -- The player doesn't have prop protection perms on the chip, ask the owner to give contents
				if IsValid(chip.player) then
					RequestView(chip, player)
				end
				player:SetAnimation(PLAYER_ATTACK1)
			end
		else
			net.Start("WireExpression2_OpenEditor") net.Send(player)
		end
	end
	net.Receive("WireExpression2_AnswerRequest", function(len, plr)
		local accept, initiator, chip = net.ReadUInt(8), net.ReadEntity(), net.ReadEntity()

		-- Check that this message is for a valid view request
		if ValidateRequest(initiator, chip) then
			-- Check that the sending player actually owns the chip they're allowing access to
			if chip.player ~= plr then return end

			if accept ~= 0 then
				WireLib.Expression2Download(initiator, chip, nil, true)
				BetterChatPrint(initiator, "Your request to view "..plr:Nick().."'s chip, '"..viewRequests[initiator][chip].name.."', was accepted!")

				-- If the player chose "Always Allow", then mark the initiator as always being able to access this entity on the chip
				if accept == 2 then
					if not chip.alwaysAllow then chip.alwaysAllow = {} end
					chip.alwaysAllow[initiator] = true
				end
			else
				BetterChatPrint(initiator, "Your request to view "..plr:Nick().."'s chip, '"..viewRequests[initiator][chip].name.."', was declined")
			end
			viewRequests[initiator][chip] = nil
		end
	end)

	function WireLib.Expression2Upload( ply, target, filepath )
		if not IsValid( target ) then
			error( "Invalid entity specified" )
		end

		if target.Uploading then return end

		net.Start("wire_expression2_tool_upload")
			net.WriteUInt(target:EntIndex(), 16)
			net.WriteString( filepath or "" )
		net.Send(ply)
	end

	function TOOL:Download(ply, ent)
		WireLib.Expression2Download(ply, ent, nil, true)
	end

	-- --------------------------------------------------------------------------------------------------------------------------
	-- --------------------------------------------------------------------------------------------------------------------------
	-- --------------------------------------------------------------------------------------------------------------------------
	-- ---------------------------------------------------- UPLOAD/DOWNLOAD -----------------------------------------------------
	-- --------------------------------------------------------------------------------------------------------------------------
	-- --------------------------------------------------------------------------------------------------------------------------
	-- --------------------------------------------------------------------------------------------------------------------------
	util.AddNetworkString("wire_expression2_tool_upload")
	util.AddNetworkString("wire_expression2_editor_status")
	util.AddNetworkString("wire_expression2_download")
	util.AddNetworkString("wire_expression2_download_wantedfiles")
	util.AddNetworkString("wire_expression2_download_wantedfiles_list")
	util.AddNetworkString("wire_expression2_upload")
	util.AddNetworkString("wire_expression2_progress")

	-- ------------------------------------------------------------
	-- Serverside Send
	-- ------------------------------------------------------------
	function WireLib.Expression2Download(ply, targetEnt, wantedfiles, uploadandexit)
		if not IsValid(targetEnt) or targetEnt:GetClass() ~= "gmod_wire_expression2" then
			WireLib.AddNotify(ply, "Invalid Expression chip specified.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		if not IsValid(ply) or not ply:IsPlayer() then
			error("Invalid player entity (wtf??). This should never happen. " .. tostring(ply), 0)
		end

		local main, includes = targetEnt:GetCode()
		if (not includes or not next(includes)) and not wantedfiles then
			local data = { { targetEnt.name, main } }
			local datastr = WireLib.von.serialize(data)

			net.Start("wire_expression2_download")
				net.WriteEntity(targetEnt)
				net.WriteBit(uploadandexit or false)
				net.WriteStream(datastr)
			net.Send(ply)
			return
		end

		if not wantedfiles then
			local fileList = {}
			for filename, _ in pairs(includes) do
				fileList[#fileList + 1] = filename
			end

			local datastr = WireLib.von.serialize(fileList)
			net.Start("wire_expression2_download_wantedfiles_list")
				net.WriteEntity(targetEnt)
				net.WriteBit(uploadandexit or false)
				net.WriteStream(datastr)
			net.Send(ply)

			targetEnt.DownloadAllowedPlayers = targetEnt.DownloadAllowedPlayers or {}
			targetEnt.DownloadAllowedPlayers[ply] = CurTime() + 60
			return
		end

		local data = { {}, {} }
		if wantedfiles.main then
			data[1] = { targetEnt.name, main }
			wantedfiles.main = nil
		end

		for i = 1, #wantedfiles do
			local filepath = wantedfiles[i]
			if includes[filepath] then
				data[2][filepath] = includes[filepath]
			else
				WireLib.AddNotify(ply, "Nonexistant file requested ('" .. tostring(filepath) .. "'). File skipped.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			end
		end

		local datastr = WireLib.von.serialize(data)
		net.Start("wire_expression2_download")
			net.WriteEntity(targetEnt)
			net.WriteBit(uploadandexit or false)
			net.WriteStream(datastr)
		net.Send(ply)
	end

	net.Receive("wire_expression2_download_wantedfiles", function(len, ply)
		local toent = net.ReadEntity()

		if not toent.DownloadAllowedPlayers or not toent.DownloadAllowedPlayers[ply] or toent.DownloadAllowedPlayers[ply] < CurTime() then return end
		toent.DownloadAllowedPlayers[ply] = nil

		local uploadandexit = net.ReadBit() ~= 0

		if not IsValid(toent) or toent:GetClass() ~= "gmod_wire_expression2" then
			WireLib.AddNotify(ply, "Invalid entity specified to wire_expression2_download_wantedfiles. Download aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		net.ReadStream(ply, function(data)
			if not IsValid(toent) then return end

			local ok, ret = pcall(WireLib.von.deserialize, data)
			if not ok then
				WireLib.AddNotify(ply, "Expression 2 download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				print("Expression 2 download failed! Error message:\n" .. ret)
				return
			end

			WireLib.Expression2Download(ply, toent, ret, uploadandexit)
		end)
	end)

	-- ------------------------------------------------------------
	-- Serverside Receive
	-- ------------------------------------------------------------
	net.Receive("wire_expression2_upload", function(len, ply)
		local toentID = net.ReadUInt(16)
		local toent = Entity(toentID)

		if (not IsValid(toent) or toent:GetClass() ~= "gmod_wire_expression2") then
			WireLib.AddNotify(ply, "Invalid Expression chip specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		if not WireLib.CanTool(ply, toent, "wire_expression2") then
			WireLib.AddNotify(ply, "You are not allowed to upload to the target Expression chip. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		if toent.Uploading then
			WireLib.AddNotify(ply, "This Expression chip is already uploading. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end
		toent.Uploading = true

		net.ReadStream(ply, function(data)
			if not IsValid(toent) then return end
			toent.Uploading = nil

			local ok, ret = pcall(WireLib.von.deserialize, data)
			if not ok then
				WireLib.AddNotify(ply, "Expression 2 upload failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				print("Expression 2 upload failed! Error message:\n" .. ret)
				return
			end

			local code = ret[1]

			local includes = {}
			for k, v in pairs(ret[2]) do
				includes[k] = v
			end

			local filepath = ret[3]

			if ply ~= toent.player then
				toent.player = ply
				toent:SetPlayer(ply)
				toent:SetNWEntity("player", ply)

				-- Note that the SENT and CPPI owners aren't set here to allow the original owner to still access their chip
			end

			-- This is needed when formatting the #error directive on dupe
			toent.code_author = {
				name = ply:GetName(),
				steamID = ply:SteamID()
			}

			toent:Setup(code, includes, nil, nil, filepath)
		end )
	end)

	-- ------------------------------------------------------------
	-- Stuff for the remote updater
	-- ------------------------------------------------------------

	local antispam = WireLib.RegisterPlayerTable()
	-- Returns true if they are spamming, false if they can go ahead and use it
	local function canhas(ply)
		if not antispam[ply] then antispam[ply] = 0 end
		if antispam[ply] < CurTime() then
			antispam[ply] = CurTime() + 1
			return false
		else
			WireLib.ClientError("This command has a 1 second anti spam protection. Try again in " .. math.Round(antispam[ply] - CurTime(), 2) .. " seconds.", ply)
			return true
		end
	end

	concommand.Add("wire_expression_forcehalt", function(player, command, args)
		local E2 = tonumber(args[1])
		if not E2 then return end
		E2 = Entity(E2)
		if not IsValid(E2) or E2:GetClass() ~= "gmod_wire_expression2" then return end
		if canhas(player) then return end
		if E2.error then return end
		if WireLib.CanTool(player, E2, "wire_expression2") then
			E2:Destruct()
			E2:Error("Execution halted (Triggered by: " .. player:Nick() .. ")", "Execution halted")
			if E2.player ~= player then
				WireLib.AddNotify(player, "Expression halted.", NOTIFY_GENERIC, 5, math.random(1, 5))
				player:PrintMessage(HUD_PRINTCONSOLE, "Expression halted.")
			end
		else
			WireLib.ClientError("You do not have permission to halt this E2.", player)
		end
	end)

	concommand.Add("wire_expression_requestcode", function(player, command, args)
		local E2 = tonumber(args[1])
		if not E2 then return end
		E2 = Entity(E2)
		if canhas(player) then return end
		if not IsValid(E2) or E2:GetClass() ~= "gmod_wire_expression2" then return end

		-- Same check as tool code
		if E2.player == player then
			WireLib.Expression2Download(player, E2)
		elseif WireLib.CanTool(player, E2, "wire_expression2") then
			WireLib.Expression2Download(player, E2)

			local playerType = "player"
			if player:IsAdmin() then
				playerType = player:IsSuperAdmin() and "superadmin" or "admin"
			end
			BetterChatPrint(
				E2.player,
				string.format("The %s '%s' just accessed your chip '%s' via prop protection", playerType, player:Nick(), E2.name)
			)
		elseif (E2.alwaysAllow and E2.alwaysAllow[player]) then
			WireLib.Expression2Download(player, E2)
		else
			if IsValid(E2.player) then
				RequestView(E2, player)
			end
		end
	end)

	concommand.Add("wire_expression_reset", function(player, command, args)
		local E2 = tonumber(args[1])
		if not E2 then return end
		E2 = Entity(E2)
		if not IsValid(E2) or E2:GetClass() ~= "gmod_wire_expression2" then return end
		if canhas(player) then return end
		if WireLib.CanTool(player, E2, "wire_expression2") then
			if E2.context.data.last or E2.first then return end

			E2:Reset()

			WireLib.AddNotify(player, "Expression reset.", NOTIFY_GENERIC, 5, math.random(1, 4))
			player:PrintMessage(HUD_PRINTCONSOLE, "Expression reset.")
			if E2.player ~= player then
				WireLib.AddNotify(E2.player, player:Nick() .. " reset your E2 '" .. E2.name .. "' using remote updater.", NOTIFY_GENERIC, 5, math.random(1, 4))
				E2.player:PrintMessage(HUD_PRINTCONSOLE, player:Nick() .. " reset your E2 '" .. E2.name .. "' using remote updater.")
			end
		else
			WireLib.ClientError("You do not have permission to reset this E2.", player)
		end
	end)

	------------------------------------------------------
	-- Syncing ops for remote uploader (admin only)
	-- Server part
	------------------------------------------------------

	local players_synced = WireLib.RegisterPlayerTable()
	util.AddNetworkString( "wire_expression_sync_ops" )
	concommand.Add("wire_expression_ops_sync", function(player,command,args)
		if not player:IsAdmin() then return end

		local bool = args[1] ~= "0"

		if bool then
			players_synced[player] = true
		else
			players_synced[player] = nil
		end

		if next( players_synced ) and not timer.Exists( "wire_expression_ops_sync" ) then

			timer.Create( "wire_expression_ops_sync",0.2,0,function()
				local plys = {}
				for ply,_ in pairs( players_synced ) do
					if not IsValid( ply ) then
						players_synced[ply] = nil
					else
						plys[#plys+1] = ply
					end
				end
				if not next( players_synced ) then
					timer.Remove( "wire_expression_ops_sync" )
				end

				local E2s = ents.FindByClass("gmod_wire_expression2")

				net.Start( "wire_expression_sync_ops" )
					net.WriteInt( #E2s, 16 )
					for i=1,#E2s do
						net.WriteEntity( E2s[i] )
						local data = E2s[i]:GetOverlayData()
						net.WriteDouble( data.prfbench )
						net.WriteDouble( data.prfcount )
						net.WriteDouble( data.timebench )
					end
				net.Send( plys )
			end)
		elseif not next( players_synced ) and timer.Exists( "wire_expression_ops_sync" ) then
			timer.Remove( "wire_expression_ops_sync" )
		end

	end)
end

if CLIENT then
	------------------------------------------------------
	-- Syncing ops for remote uploader (admin only)
	-- Client part
	------------------------------------------------------
	net.Receive( "wire_expression_sync_ops", function( len )
		local num = net.ReadInt( 16 )
		for i=1,num do
			local E2 = net.ReadEntity()
			if E2.GetOverlayData and E2.SetOverlayData then
				local prfbench = net.ReadDouble()
				local prfcount = net.ReadDouble()
				local timebench = net.ReadDouble()

				local data = E2:GetOverlayData() or {}

				E2:SetOverlayData( {
					txt = data.txt or "(generic)",
					error = data.error or false,
					prfbench = prfbench,
					prfcount = prfcount,
					timebench = timebench
				} )
			end
		end
	end )

	-- Clientside Send
	local uploadQueue = {}
	local uploading = false
	local function uploadNext(targetEntID, datastr)
		if targetEntID then
			if uploading then table.insert(uploadQueue, {targetEntID, datastr}) return end
		elseif uploadQueue[1] then
			if uploading then return end
			targetEntID, datastr = unpack(table.remove(uploadQueue, 1))
		else
			return
		end

		uploading = true
		net.Start( "wire_expression2_upload" )
			net.WriteUInt( targetEntID, 16 )
			net.WriteStream( datastr, function()
				uploading = false
				uploadNext()
			end )
		net.SendToServer()
	end

	function WireLib.Expression2Upload(targetEntID, code, filepath)
		if isentity( targetEntID ) then
			targetEntID = targetEntID:EntIndex()
		end

		if not targetEntID then
			local aimEnt = LocalPlayer():GetEyeTrace().Entity
			if IsValid( aimEnt ) then
				targetEntID = aimEnt:EntIndex()
			else
				WireLib.AddNotify("No target Expression 2 chip specified.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				return
			end
		end

		if uploadQueue[targetEntID] then
			WireLib.AddNotify("You're already uploading that E2!", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			return
		end

		if filepath then
			code = file.Read(filepath)
			if not code then
				WireLib.AddNotify("Unable to read requested filepath! "..tostring(filepath), NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
				return
			end
		end

		if not code and not wire_expression2_editor then return end -- If the player leftclicks without opening the editor or cpanel (first spawn)
		code = code or wire_expression2_editor:GetCode()
		filepath = filepath or wire_expression2_editor:GetChosenFile()
		local err, includes, _warnings

		if e2_function_data_received then
			err, includes, _warnings = E2Lib.Validate(code)
			if err and err[1] then
				WireLib.AddNotify(err[1].message, NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
				return
			end
		else
			WireLib.AddNotify("The Expression 2 function data has not been transferred to the client yet;\n uploading the E2 to the server for validation.\nNote that any includes will not be sent. You must wait for the function data to finish\n transmitting before you are able to use includes.", NOTIFY_ERROR, 14, NOTIFYSOUND_DRIP3)

			-- This message is so long, the user might not be able to read it fast enough. Printing it to the console so they can read it there, too.
			Msg("The Expression 2 function data has not been transferred to the client yet; uploading the E2 to the server for validation.\nNote that any includes will not be sent. You must wait for the function data to finish transmitting before you are able to use includes.\n")
		end

		local datastr
		if includes then
			local newincludes = {}
			for k, v in pairs(includes) do
				newincludes[k] = v
			end

			datastr = WireLib.von.serialize({ code, newincludes, filepath })
		else
			datastr = WireLib.von.serialize({ code, {}, filepath })
		end

		uploadNext(targetEntID, datastr)
	end

	net.Receive("wire_expression2_tool_upload", function(len, ply)
		local entIndex = net.ReadUInt(16)
		local filepath = net.ReadString()
		WireLib.Expression2Upload(entIndex, nil, filepath ~= "" and filepath or nil)
	end)

	--------------------------------------------------------------
	-- Clientside Receive
	--------------------------------------------------------------
	net.Receive("wire_expression2_download", function(len)
		local ent = net.ReadEntity()
		local uploadandexit = net.ReadBit() ~= 0

		Expression2SetProgress(nil, nil, "Downloading")

		net.ReadStream(nil, function(data)
			local ok, ret = pcall(WireLib.von.deserialize, data)
			if not ok then
				WireLib.AddNotify("Expression 2 download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				return
			end

			local files = ret
			local name, main
			if files[1] then
				name = files[1][1]
				main = files[1][2]
			end

			if not wire_expression2_editor then initE2Editor() end

			if uploadandexit then
				wire_expression2_editor.chip = ent
			end

			if files[2] and next(files[2]) then
				for k, v in pairs(files[2]) do
					wire_expression2_editor:Open(k, v)
				end
			end

			wire_expression2_editor:Open(name, main)
			timer.Create("wire_expression2_reset_progress", 0.75, 1, Expression2SetProgress)
		end)
	end)

	net.Receive("wire_expression2_download_wantedfiles_list", function(len)
		local ent = net.ReadEntity()
		local uploadandexit = net.ReadBit() ~= 0

		net.ReadStream(nil, function(data)
			local ok, ret = pcall(WireLib.von.deserialize, data)
			if not ok then
				WireLib.AddNotify("Expression 2 file list download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				print("Expression 2 file list download failed! Error message:\n" .. ret)
				return
			end

			local files = ret
			local height = 23

			local pnl = vgui.Create("DFrame")
			pnl:SetSize(200, 100)
			pnl:Center()
			pnl:SetTitle("Select files to download")

			local lst = vgui.Create("DPanelList", pnl)
			lst.Paint = function() end
			lst:SetSpacing(2)

			local selectedfiles = { main = true }
			local checkboxes = {}

			local check = vgui.Create("DCheckBoxLabel")
			check:SetText("Main")
			check:Toggle()
			lst:AddItem(check)
			function check:OnChange(val)
				selectedfiles.main = val or nil
			end

			checkboxes[#checkboxes + 1] = check
			height = height + check:GetTall() + 2

			for i = 1, #files do
				local path = files[i]
				local check = vgui.Create("DCheckBoxLabel")
				check:SetText(path)
				lst:AddItem(check)
				function check:OnChange(val)
					if val then
						selectedfiles[i] = path
					else
						selectedfiles[i] = nil
					end
				end

				checkboxes[#checkboxes + 1] = check
				height = height + check:GetTall() + 2
			end

			local selectall = vgui.Create("DButton")
			selectall:SetText("Select all")
			lst:AddItem(selectall)
			function selectall:DoClick()
				selectedfiles = { main = true }
				for k, v in pairs(files) do
					selectedfiles[#selectedfiles + 1] = v
				end

				for i = 1, #checkboxes do
					if not checkboxes[i]:GetChecked() then checkboxes[i]:Toggle() end
				end
			end

			height = height + selectall:GetTall() + 2

			local selectnone = vgui.Create("DButton")
			selectnone:SetText("Select none")
			lst:AddItem(selectnone)
			function selectnone:DoClick()
				selectedfiles = {}
				for i = 1, #checkboxes do
					if checkboxes[i]:GetChecked() then checkboxes[i]:Toggle() end
				end
			end

			height = height + selectnone:GetTall() + 2

			local ok = vgui.Create("DButton")
			ok:SetText("Ok")
			ok:SetTooltip("Shortcut for this button: Right click anywhere")
			lst:AddItem(ok)
			function ok:DoClick()
				local haschoice = next(selectedfiles) ~= nil
				if not haschoice then pnl:Close() return end

				local datastr = WireLib.von.serialize(selectedfiles)
				net.Start("wire_expression2_download_wantedfiles")
					net.WriteEntity(ent)
					net.WriteBit(uploadandexit)
					net.WriteStream(datastr)
				net.SendToServer()

				pnl:Close()
			end

			height = height + ok:GetTall()

			local down = input.IsMouseDown(MOUSE_RIGHT)
			function pnl:Think()
				if not down and input.IsMouseDown(MOUSE_RIGHT) then
					ok:DoClick()
				end
				down = input.IsMouseDown(MOUSE_RIGHT)
			end

			pnl:SetTall(math.min(height + 2, ScrH() / 2))
			lst:EnableVerticalScrollbar(true)
			lst:StretchToParent(2, 23, 2, 2)
			pnl:MakePopup()
			pnl:SetVisible(true)
		end)
	end)

	--------------------------------------------------------------
	function TOOL.BuildCPanel(panel)
		local w, _h = panel:GetSize()

		WireToolHelpers.MakeModelSizer(panel, "wire_expression2_modelsize")
		--[[
		local ParentPanel = vgui.Create( "DPanel", panel )
		ParentPanel:SetSize(w,h-40)
		ParentPanel:Dock(TOP)
		]]
		--[[
		local MaterialGallery = vgui.Create( "DCollapsibleCategory", ParentPanel )
		MaterialGallery:SetSize(w,100)
		]]
		-- lazy.. lazy.. lazy.. deprecated..
		panel:AddControl("MaterialGallery", {
			Height = "100",
			Width = "100",
			Rows = 2,
			Stretch = false,
			ConVar = "wire_expression2_select",
			Options = {
				["Modern"] = { wire_expression2_select = "Modern", Value = "Modern", Material = "beer/wiremod/gate_e2", wire_expression2_model = "models/beer/wiremod/gate_e2.mdl" },
				["Expression"] = { wire_expression2_select = "Expression", Value = "Expression", Material = "models/expression 2/exprssn", wire_expression2_model = "models/expression 2/cpu_expression.mdl" },
				["Microchip"] = { wire_expression2_select = "Microchip", Value = "Microchip", Material = "models/expression 2/mcrochp", wire_expression2_model = "models/expression 2/cpu_microchip.mdl" },
				["Interface"] = { wire_expression2_select = "Interface", Value = "Interface", Material = "models/expression 2/intrfce", wire_expression2_model = "models/expression 2/cpu_interface.mdl" },
				["Controller"] = { wire_expression2_select = "Controller", Value = "Controller", Material = "models/expression 2/cntrllr", wire_expression2_model = "models/expression 2/cpu_controller.mdl" },
				["Processor"] = { wire_expression2_select = "Processor", Value = "Processor", Material = "models/expression 2/prcssor", wire_expression2_model = "models/expression 2/cpu_processor.mdl" },
			}
		})

		if (wire_expression2_editor == nil) then initE2Editor() end

		local FileBrowser = vgui.Create("wire_expression2_browser", panel)
		FileBrowser.OpenOnSingleClick = wire_expression2_editor
		panel:AddPanel(FileBrowser)
		FileBrowser:Setup("expression2")
		FileBrowser:SetSize(w, 300)
		FileBrowser:DockMargin(5, 5, 5, 5)
		FileBrowser:DockPadding(5, 5, 5, 5)
		FileBrowser:Dock(TOP)
		function FileBrowser:OnFileOpen(filepath, newtab)
			wire_expression2_editor:Open(filepath, nil, newtab)
		end

		local OpenEditor = panel:Button("Open Editor")
		OpenEditor.DoClick = function(button)
			wire_expression2_editor:Open()
		end

		local NewExpression = panel:Button("New Expression")
		NewExpression.DoClick = function(button)
			wire_expression2_editor:Open()
			wire_expression2_editor:NewScript()
		end
	end

	function initE2Editor()
		wire_expression2_editor = vgui.Create("Expression2EditorFrame")
		wire_expression2_editor:Setup("Expression 2 Editor", "expression2", "E2")
	end

	function openE2Editor()
		if (wire_expression2_editor == nil) then initE2Editor() end
		wire_expression2_editor:Open()
	end

	net.Receive("WireExpression2_OpenEditor", openE2Editor)

	--[[
	  Expression 2 Tool Screen for Garry's Mod
	  Andreas "Syranide" Svensson, me@syranide.com
	]] --

	local fontTable = {
		font = "Arial",
		size = 40,
		weight = 1000,
		antialias = true,
		additive = false,
	}
	surface.CreateFont("Expression2ToolScreenFont", fontTable)
	fontTable.size = 30
	surface.CreateFont("Expression2ToolScreenSubFont", fontTable)

	local percent = nil
	local percent2 = nil
	local name = "Unnamed"
	local what = "Uploading"

	function Expression2SetName(n)
		name = n
		if not name then
			name = "Unnamed"
			return
		end

		surface.SetFont("Expression2ToolScreenSubFont")
		local ww = surface.GetTextSize("...")

		local w = surface.GetTextSize(name)
		if w < 240 then return end

		while true do
			local w = surface.GetTextSize(name)
			if w < 240 - ww then break end
			name = string.sub(name, 1, -2)
		end

		name = string.Trim(name) .. "..."
	end

	function Expression2SetProgress(p, p2, w)
		what = w or "Uploading"
		percent = p and math.Clamp(p,0,100) or nil
		percent2 = p2 and math.Clamp(p2,0,100) or nil
	end

	function DrawTextOutline(text, font, x, y, color, xalign, yalign, bordercolor, border)
		for i = 0, 8 do
			draw.SimpleText(text, font, x + border * math.sin(i * math.pi / 4), y + border * math.cos(i * math.pi / 4), bordercolor, xalign, yalign)
		end

		draw.SimpleText(text, font, x, y, color, xalign, yalign)
	end

	local CogColor = Color(150, 34, 34, 255)
	local CogTexture = surface.GetTextureID("expression 2/cog")
	if CogTexture == surface.GetTextureID("texturemissing") then CogTexture = nil end

	function TOOL:DrawToolScreen(width, height)
		surface.SetDrawColor(32, 32, 32, 255)
		surface.DrawRect(0, 0, 256, 256)

		if CogTexture then
			local ToColor = Color(150, 34, 34, 255)
			if percent then
				ToColor = Color(34, 150, 34, 255)
			end

			local CogDelta = 750 * FrameTime()

			CogColor.r = CogColor.r + math.max(-CogDelta, math.min(CogDelta, ToColor.r - CogColor.r))
			CogColor.g = CogColor.g + math.max(-CogDelta, math.min(CogDelta, ToColor.g - CogColor.g))
			CogColor.b = CogColor.b + math.max(-CogDelta, math.min(CogDelta, ToColor.b - CogColor.b))

			surface.SetTexture(CogTexture)
			surface.SetDrawColor(CogColor.r, CogColor.g, CogColor.b, 255)
			surface.DrawTexturedRectRotated(256, 256, 455, 455, RealTime() * 10)
			surface.DrawTexturedRectRotated(30, 30, 227.5, 227.5, RealTime() * -20 + 12.5)
		end

		surface.SetFont("Expression2ToolScreenFont")
		local _, h = surface.GetTextSize(" ")
		surface.SetFont("Expression2ToolScreenSubFont")
		local _, h2 = surface.GetTextSize(" ")

		if percent or percent2 then
			surface.SetFont("Expression2ToolScreenFont")
			local w, h = surface.GetTextSize(what)
			DrawTextOutline(what, "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)

			if percent then
				draw.RoundedBox(4, 128 - w / 2 - 2, 128 + h / 2 - 0, ((w+4) * percent) / 100, h2 - 4, Color(0, 0, 0, 255))
				draw.RoundedBox(2, 128 - w / 2 + 2, 128 + h / 2 + 4, ((w-4) * percent) / 100, h2 - 12, Color(224, 224, 224, 255))
			end

			if percent2 then
				draw.RoundedBox(4, 128 - w / 2 - 2, 128 + h / 2 + 24, ((w+4) * percent2) / 100, h2 - 4, Color(0, 0, 0, 255))
				draw.RoundedBox(2, 128 - w / 2 + 2, 128 + h / 2 + 28, ((w-4) * percent2) / 100, h2 - 12, Color(224, 224, 224, 255))
			end
		elseif name then
			DrawTextOutline("Expression 2", "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
			DrawTextOutline(name, "Expression2ToolScreenSubFont", 128, 128 + (h + h2) / 2 - 4, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
		end
	end
end

-- -------- 'in editor' animation ------------------------

if SERVER then

	-- -------------- client-side event handling ------------------
	-- this might fit better elsewhere

	local wire_expression2_event = {}

	concommand.Add("wire_expression2_event", function(ply, command, args)
		local handler = wire_expression2_event[args[1]]
		if not handler then return end
		return handler(ply, args)
	end)

	-- actual editor open/close handlers

	function wire_expression2_event.editor_open(ply, args)
		net.Start("wire_expression2_editor_status")
		net.WriteEntity(ply)
		net.WriteBit(true)
		net.Broadcast()
	end

	function wire_expression2_event.editor_close(ply, args)
		net.Start("wire_expression2_editor_status")
		net.WriteEntity(ply)
		net.WriteBit(false)
		net.Broadcast()
	end

elseif CLIENT then

	local busy_players = WireLib.RegisterPlayerTable()
	hook.Add("EntityRemoved", "wire_expression2_busy_animation", function(ply)
		busy_players[ply] = nil
	end)

	local emitter = ParticleEmitter(vector_origin)

	net.Receive("wire_expression2_editor_status", function(len)
		local ply = net.ReadEntity()
		local status = net.ReadBit() ~= 0 -- net.ReadBit returns 0 or 1, despite net.WriteBit taking a boolean
		if not IsValid(ply) or ply == LocalPlayer() then return end

		busy_players[ply] = status or nil
	end)

	local rolldelta = math.rad(80)
	timer.Create("wire_expression2_editor_status", 1, 0, function()
		rolldelta = -rolldelta
		for ply, _ in pairs(busy_players) do
			local BoneIndx = ply:LookupBone("ValveBiped.Bip01_Head1") or ply:LookupBone("ValveBiped.HC_Head_Bone") or 0
			local BonePos, _BoneAng = ply:GetBonePosition(BoneIndx)
			local particle = emitter:Add("expression 2/cog_world", BonePos + Vector(0, 0, 16))
			if particle then
				particle:SetColor(150, 34, 34)
				particle:SetVelocity(Vector(0, 0, 17))

				particle:SetDieTime(3)
				particle:SetLifeTime(0)

				particle:SetStartSize(10)
				particle:SetEndSize(10)

				particle:SetStartAlpha(255)
				particle:SetEndAlpha(0)

				particle:SetRollDelta(rolldelta)
			end
		end
	end)
end

local prevmodel, prevvalid
function validModelCached(model)
	if model ~= prevmodel then
		prevmodel = model
		prevvalid = util.IsValidModel(model)
	end
	return prevvalid
end

TOOL.Model = "models/beer/wiremod/gate_e2.mdl"
function TOOL:GetModel()
	local scriptmodel = self:GetClientInfo("scriptmodel")
	if scriptmodel and scriptmodel ~= "" and validModelCached(scriptmodel) then return Model(scriptmodel) end
	return WireToolObj.GetModel(self)
end
