WireToolSetup.setCategory( "Chips, Gates" )
WireToolSetup.open("expression2", "Expression 2", "gmod_wire_expression2", nil, "Expression2s")

if CLIENT then
	language.Add("Tool.wire_expression2.name", "Expression 2 Tool (Wire)")
	language.Add("Tool.wire_expression2.desc", "Spawns an Expression 2 chip for use with the wire system.")
	language.Add("Tool.wire_expression2.0", "Primary: Create/Update Expression, Secondary: Open Expression in Editor")
	language.Add("sboxlimit_wire_expressions", "You've hit the Expression limit!")

	--WireToolSetup.setToolMenuIcon( "beer/wiremod/gate_e2" )
	WireToolSetup.setToolMenuIcon( "vgui/e2logo" )
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/gate_e2.mdl",
	modelsize = "",
	scriptmodel = "",
	select = "",
	autoindent = 1,
}

TOOL.MaxLimitName = "wire_expressions"
WireToolSetup.BaseLang()

if SERVER then
	CreateConVar('sbox_maxwire_expressions', 20)
	
	function TOOL:MakeEnt(ply, model, Ang, trace)
		return MakeWireExpression2(ply, trace.HitPos, Ang, model)
	end
	
	function TOOL:PostMake(ent)
		self:Upload(ent)
	end

	function TOOL:LeftClick_Update( trace )
		self:Upload(trace.Entity)
	end

	function TOOL:Reload(trace)
		if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		local player = self:GetOwner()

		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_expression2" then
			trace.Entity:Reset()
			return true
		else
			return false
		end
	end

	util.AddNetworkString("WireExpression2_OpenEditor")
	function TOOL:RightClick(trace)
		if trace.Entity:IsPlayer() then return false end

		local player = self:GetOwner()

		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_expression2" then
			self:Download(player, trace.Entity)
			return true
		end

		net.Start("WireExpression2_OpenEditor") net.Send(player)
		return false
	end

	function TOOL:Upload(ent)
		WireLib.Expression2Upload( self:GetOwner(), ent )
	end
	
	function WireLib.Expression2Upload( ply, target, filepath )
		if not IsValid( target ) then error( "Invalid entity specified" ) end
		net.Start("wire_expression2_tool_upload")
			net.WriteUInt(target:EntIndex(), 16)
			net.WriteString( filepath or "" )
			net.WriteInt( target.buffer and tonumber(util.CRC( target.buffer )) or -1, 32 ) -- send the hash so we know if there's any difference
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

		if not IsValid(ply) or not ply:IsPlayer() then -- wtf
			error("Invalid player entity (wtf??). This should never happen. " .. tostring(ply), 0)
		end

		if not hook.Run( "CanTool", ply, WireLib.dummytrace(targetEnt), "wire_expression2") then
			WireLib.AddNotify(ply, "You're not allowed to download from this Expression (ent index: " .. targetEnt:EntIndex() .. ").", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		local main, includes = targetEnt:GetCode()
		if not includes or not next(includes) then -- There are no includes
			local datastr = WireLib.von.serialize({ { targetEnt.name, main } })
			local numpackets = math.ceil(#datastr / 64000)
			
			local n = 0
			for i = 1, #datastr, 64000 do
				timer.Simple( n, function()
					if not IsValid( targetEnt ) then return end
					net.Start("wire_expression2_download")
						net.WriteEntity(targetEnt)
						net.WriteBit(uploadandexit or false)
						net.WriteUInt(numpackets, 16)
						net.WriteString(datastr:sub(i, i + 63999))
					net.Send(ply)
				end)
				n = n + 1
			end
		elseif not wantedfiles then
			local data = {}
			for k, v in pairs(includes) do
				data[#data + 1] = k
			end

			local datastr = WireLib.von.serialize(data)
			net.Start("wire_expression2_download_wantedfiles_list")
			net.WriteEntity(targetEnt)
			net.WriteBit(uploadandexit or false)
			net.WriteString(datastr)
			net.Send(ply)
		else
			local data = { {}, {} }
			if wantedfiles.main then
				data[1] = { targetEnt.name, main }
				wantedfiles.main = nil
			end

			for i = 1, #wantedfiles do
				local path = wantedfiles[i]
				if includes[path] then
					data[2][path] = includes[path]
				else
					WireLib.AddNotify(ply, "Nonexistant file requested ('" .. tostring(path) .. "'). File skipped.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				end
			end

			local datastr = WireLib.von.serialize(data)
			local numpackets = math.ceil(#datastr / 64000)
			local n = 0
			for i = 1, #datastr, 64000 do
				timer.Simple( n, function()
					if not IsValid( targetEnt ) then return end
					net.Start("wire_expression2_download")
						net.WriteEntity(targetEnt)
						net.WriteBit(uploadandexit or false)
						net.WriteUInt(numpackets, 16)
						net.WriteString(datastr:sub(i, i + 63999))
					net.Send(ply)
				end)
				n = n + 1
			end
		end
	end

	local wantedfiles = {}
	net.Receive("wire_expression2_download_wantedfiles", function(len, ply)
		local toent = net.ReadEntity()
		local uploadandexit = net.ReadBit() ~= 0
		local numpackets = net.ReadUInt(16)

		if not IsValid(toent) or toent:GetClass() ~= "gmod_wire_expression2" then
			WireLib.AddNotify(ply, "Invalid entity specified to wire_expression2_download_wantedfiles. Download aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		if not wantedfiles[ply] then wantedfiles[ply] = {} end
		table.insert(wantedfiles[ply], net.ReadString())
		if numpackets <= #wantedfiles[ply] then
			local ok, ret = pcall(WireLib.von.deserialize, E2Lib.decode(table.concat(wantedfiles[ply])))
			wantedfiles[ply] = nil
			if not ok then
				WireLib.AddNotify(ply, "Expression 2 download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				print("Expression 2 download failed! Error message:\n" .. ret)
				return
			end

			WireLib.Expression2Download(ply, toent, ret, uploadandexit)
		end
	end)

	-- ------------------------------------------------------------
	-- Serverside Receive
	-- ------------------------------------------------------------
	local uploads = {}
	local upload_ents = {}
	net.Receive("wire_expression2_upload", function(len, ply)
		local toent = Entity(net.ReadUInt(16))
		local numpackets = net.ReadUInt(16)

		if not IsValid(toent) or toent:GetClass() ~= "gmod_wire_expression2" then
			if uploads[ply] then -- this is to prevent notification spam due to the net library automatically limiting its own transfer rate so that the messages arrive late
				uploads[ply] = nil
				upload_ents[ply] = nil
				WireLib.AddNotify(ply, "Invalid Expression chip specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			end
			return
		end

		if not hook.Run( "CanTool", ply, WireLib.dummytrace( toent ), "wire_expression2" ) then
			WireLib.AddNotify(ply, "You are not allowed to upload to the target Expression chip. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end
		
		if upload_ents[ply] ~= toent then -- a new upload was started, abort previous
			uploads[ply] = nil
		end
		
		upload_ents[ply] = toent

		if not uploads[ply] then uploads[ply] = {} end
		uploads[ply][#uploads[ply]+1] = net.ReadString()
		if numpackets <= #uploads[ply] then
			local datastr = E2Lib.decode(table.concat(uploads[ply]))
			uploads[ply] = nil
			local ok, ret = pcall(WireLib.von.deserialize, datastr)

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

			toent:Setup(code, includes, nil, nil, filepath)
		end
	end)

	-- ------------------------------------------------------------
	-- Stuff for the remote updater
	-- ------------------------------------------------------------

	local antispam = {}
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
		if hook.Run( "CanTool", player, WireLib.dummytrace( E2 ), "wire_expression2", "halt execution" ) then
			E2:PCallHook("destruct")
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
		if hook.Run( "CanTool", player, WireLib.dummytrace( E2 ), "wire_expression2", "request code" ) then
			WireLib.Expression2Download(player, E2)
			WireLib.AddNotify(player, "Downloading code...", NOTIFY_GENERIC, 5, math.random(1, 4))
			player:PrintMessage(HUD_PRINTCONSOLE, "Downloading code...")
			if E2.player ~= player then
				WireLib.AddNotify(E2.player, player:Nick() .. " is reading your E2 '" .. E2.name .. "' using remote updater.", NOTIFY_GENERIC, 5, math.random(1, 4))
				E2.player:PrintMessage(HUD_PRINTCONSOLE, player:Nick() .. " is reading your E2 '" .. E2.name .. "' using remote updater.")
			end
		else
			WireLib.ClientError("You do not have permission to read this E2.", player)
		end
	end)

	concommand.Add("wire_expression_reset", function(player, command, args)
		local E2 = tonumber(args[1])
		if not E2 then return end
		E2 = Entity(E2)
		if not IsValid(E2) or E2:GetClass() ~= "gmod_wire_expression2" then return end
		if canhas(player) then return end
		if hook.Run( "CanTool", player, WireLib.dummytrace( E2 ), "wire_expression2", "reset" ) then
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
	
	local players_synced = {}
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
elseif CLIENT then
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

	--------------------------------------------------------------
	-- Clientside Send
	--------------------------------------------------------------
	
	local queue_max = 0
	local queue = {}
	local sending = false
	
	local upload_queue
	
	-- send next E2
	local function next_queue()
		local queue_progress = (queue_max > 1 and (1-((#queue-1) / queue_max)) * 100 or nil)
		Expression2SetProgress( nil, queue_progress )
		table.remove( queue, 1 )
		
		-- Clear away all removed E2s from the queue
		while true do
			if #queue == 0 then break end
			if queue[1].timeStarted + 2 < CurTime() -- only clear it if more than 2 seconds has passed since the upload was requested (if the user has high ping)
				and not IsValid( Entity(queue[1].targetEnt) ) then
				table.remove( queue, 1 )
			else
				break
			end
		end
		
		timer.Simple( 1, function() -- wait a while before doing anything so stuff doesn't lag
			if #queue == 0 then
				Expression2SetProgress()
				sending = false -- done sending
				queue_max = 0
			else
				upload_queue() -- send next
			end
		end)
	end
	
	upload_queue = function(first)
		local q = queue[1]
		
		local targetEnt = q.targetEnt
		local datastr = q.datastr
		local timeStarted = q.timeStarted
	
		local queue_progress = (queue_max > 1 and (1-((#queue-1) / queue_max)) * 100 or nil)
		Expression2SetProgress(1, queue_progress)

		local numpackets = math.ceil(#datastr / 64000)
		local delay = first and 0.01 or 1
		local packet = 0
		local exited = false
		for i = 1, #datastr, 64000 do
			timer.Simple( delay, function()
				packet = packet + 1
				if timeStarted + 2 < CurTime() and -- only remove the E2 from the queue if more than 2 seconds has passed since the upload was requested (if the user has high ping)
					not IsValid(Entity( targetEnt )) then
					if exited then
						return
					else
						exited = true
						next_queue()
						return
					end
				end
				
				if packet == numpackets then
					next_queue()
				end
				
				local queue_progress = (queue_max > 1 and (1-((#queue-1) / queue_max)) * 100 or nil)
				Expression2SetProgress( packet / numpackets * 100, queue_progress )
				
				net.Start("wire_expression2_upload")
					net.WriteUInt(targetEnt, 16)
					net.WriteUInt(numpackets, 16)
					net.WriteString(datastr:sub(i, i + 63999))
				net.SendToServer()
			end)
			delay = delay + 1
		end
	end

	function WireLib.Expression2Upload(targetEnt, code, filepath)
		if not targetEnt then targetEnt = LocalPlayer():GetEyeTrace().Entity or NULL end
		if isentity(targetEnt) then
			if not IsValid(targetEnt) then return end -- We don't know what entity its going to
			targetEnt = targetEnt:EntIndex()
		end
		
		for i=1,#queue do
			if queue[i].targetEnt == targetEnt then
				WireLib.AddNotify("You're already uploading that E2!", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
				return
			end
		end

		if not code and not wire_expression2_editor then return end -- If the player leftclicks without opening the editor or cpanel (first spawn)
		code = code or wire_expression2_editor:GetCode()
		filepath = filepath or wire_expression2_editor:GetChosenFile()
		local err, includes

		if e2_function_data_received then
			err, includes = wire_expression2_validate(code)
			if err then
				WireLib.AddNotify(err, NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
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

			datastr = E2Lib.encode(WireLib.von.serialize({ code, newincludes, filepath }))
		else
			datastr = E2Lib.encode(WireLib.von.serialize({ code, {}, filepath }))
		end
		
		queue[#queue+1] = {
			targetEnt = targetEnt,
			datastr = datastr,
			timeStarted = CurTime()
		}
		
		queue_max = queue_max + 1
		
		if sending then return end
		sending = true
		upload_queue(true) -- true means its the first packet, suppressing the delay
	end

	net.Receive("wire_expression2_tool_upload", function(len, ply)
		local ent = net.ReadUInt(16)
		local filepath = net.ReadString()
		local hash = net.ReadInt(32)
		if filepath ~= "" then
			if filepath and file.Exists(filepath, "DATA") then
				local str = file.Read(filepath)
				local strhash = tonumber(util.CRC(str))
				if hash ~= strhash then -- Only upload if we need to
					WireLib.Expression2Upload(ent,str,filepath)
				end
			end
		else
			WireLib.Expression2Upload(ent)
		end
	end)

	--------------------------------------------------------------
	-- Clientside Receive
	--------------------------------------------------------------
	local buffer, count = "", 0
	local current_ent
	net.Receive("wire_expression2_download", function(len)
		local ent = net.ReadEntity()
		
		if IsValid( current_ent ) and IsValid( ent ) and ent ~= current_ent then
			-- different E2, reset buffer
			buffer = ""
			count = 0
		end
		
		local uploadandexit = net.ReadBit() ~= 0
		local numpackets = net.ReadUInt(16)

		buffer = buffer .. net.ReadString()
		count = count + 1

		Expression2SetProgress(count / numpackets * 100, nil, "Downloading")
		if numpackets <= count then
			local ok, ret = pcall(WireLib.von.deserialize, buffer)
			buffer, count = "", 0
			if not ok then
				WireLib.AddNotify(ply, "Expression 2 download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
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
		end
	end)

	net.Receive("wire_expression2_download_wantedfiles_list", function(len)
		local ent = net.ReadEntity()
		local uploadandexit = net.ReadBit() ~= 0
		local buffer = net.ReadString()

		local ok, ret = pcall(WireLib.von.deserialize, buffer)
		if not ok then
			WireLib.AddNotify(ply, "Expression 2 file list download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
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
			if val then
				selectedfiles.main = true
			else
				selectedfiles.main = nil
			end
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
					table.remove(selectedfiles, i)
				end
			end

			checkboxes[#checkboxes + 1] = check
			height = height + check:GetTall() + 2
		end

		local selectall = vgui.Create("DButton")
		selectall:SetText("Select all")
		lst:AddItem(selectall)
		function selectall:DoClick()
			selectedfiles = {}
			for k, v in pairs(files) do
				selectedfiles[#selectedfiles + 1] = v
			end
			selectedfiles.main = true

			for i = 1, #checkboxes do
				if not checkboxes[i]:GetChecked() then checkboxes[i]:Toggle() end -- checkboxes[i]:SetChecked( true )
			end
		end

		height = height + selectall:GetTall() + 2

		local selectnone = vgui.Create("DButton")
		selectnone:SetText("Select none")
		lst:AddItem(selectnone)
		function selectnone:DoClick()
			selectedfiles = {}

			for i = 1, #checkboxes do
				if checkboxes[i]:GetChecked() then checkboxes[i]:Toggle() end -- checkboxes[i]:SetChecked( false )
			end
		end

		height = height + selectnone:GetTall() + 2

		local ok = vgui.Create("DButton")
		ok:SetText("Ok")
		ok:SetToolTip("Shortcut for this button: Right click anywhere")
		lst:AddItem(ok)
		function ok:DoClick()
			local haschoice = false
			for k, v in pairs(selectedfiles) do haschoice = true break end
			if not haschoice then pnl:Close() return end

			local datastr = E2Lib.encode(WireLib.von.serialize(selectedfiles))
			local numpackets = math.ceil(#datastr / 64000)
			for i = 1, #datastr, 64000 do
				net.Start("wire_expression2_download_wantedfiles")
				net.WriteEntity(ent)
				net.WriteBit(uploadandexit)
				net.WriteUInt(numpackets, 16)
				net.WriteString(datastr:sub(i, i + 63999))
				net.SendToServer()
			end

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

	--------------------------------------------------------------
	function TOOL.BuildCPanel(panel)
		local w, h = panel:GetSize()

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

		if wire_expression2_editor == nil then initE2Editor() end

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
		if wire_expression2_editor == nil then initE2Editor() end
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

		local w, h = surface.GetTextSize(name)
		if w < 240 then return end

		while true do
			local w, h = surface.GetTextSize(name)
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
		local w, h = surface.GetTextSize(" ")
		surface.SetFont("Expression2ToolScreenSubFont")
		local w2, h2 = surface.GetTextSize(" ")

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

---------- 'in editor' animation ------------------------

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

	local busy_players = {}
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
			local BonePos, BoneAng = ply:GetBonePosition(BoneIndx)
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