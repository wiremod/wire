TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Expression 2"
TOOL.Command 		= nil
TOOL.ConfigName 	= ""
TOOL.Tab			= "Wire"

TOOL.ClientConVar = {
	model       = "models/beer/wiremod/gate_e2.mdl",
	scriptmodel = "",
	size        = "",
	select      = "",
	autoindent  = 1,
	friendwrite = 0,
}

if CLIENT then
	language12.Add("Tool_wire_expression2_name", "Expression 2 Tool (Wire)")
	language12.Add("Tool_wire_expression2_desc", "Spawns an Expression 2 chip for use with the wire system.")
	language12.Add("Tool_wire_expression2_0",    "Primary: Create/Update Expression, Secondary: Open Expression in Editor")
	language12.Add("sboxlimit_wire_expression",  "You've hit the Expression limit!")
	language12.Add("Undone_wire_expression2",    "Undone Expression 2")
	language12.Add("Cleanup_wire_expressions",   "Expression 1+2" )
	language12.Add("Cleaned_wire_expressions",   "Cleaned up all Wire Expressions" )
end

cleanup.Register("wire_expressions")

if SERVER then
	CreateConVar('sbox_maxwire_expressions', 20)

	function TOOL:LeftClick(trace)
		if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

		local player = self:GetOwner()

		local model = self:GetModel()
		local pos = trace.HitPos
		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90

		if  trace.Entity:IsValid()
		    && trace.Entity:GetClass() == "gmod_wire_expression2"
			&& (trace.Entity.player == player || trace.Entity.player:GetInfoNum("wire_expression2_friendwrite") != 0)
			&& E2Lib.isFriend(trace.Entity.player, player)
		then
			self:Upload( trace.Entity )
			return true
		end

		if !self:GetSWEP():CheckLimit("wire_expressions") then return false end

		local entity = ents.Create("gmod_wire_expression2")
		if not entity or not entity:IsValid() then return false end

		player:AddCount("wire_expressions", entity)

		entity:SetModel(model)
		entity:SetAngles(ang)
		entity:SetPos(pos)
		entity:Spawn()
		entity:SetPlayer(player)
		entity.player = player
		entity:SetNWEntity( "_player", player )

		entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
		local constraint = WireLib.Weld(entity, trace.Entity, trace.PhysicsBone, true)

		undo.Create("wire_expression2")
			undo.AddEntity(entity)
			undo.SetPlayer(player)
			undo.AddEntity(constraint)
		undo.Finish()

		player:AddCleanup("wire_expressions", entity)

		self:Upload( entity )
		return true
	end

	function TOOL:Reload(trace)
		if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		local player = self:GetOwner()

		if  trace.Entity:IsValid()
		    && trace.Entity:GetClass() == "gmod_wire_expression2"
			&& (trace.Entity.player == player || trace.Entity.player:GetInfoNum("wire_expression2_friendwrite") != 0)
			&& E2Lib.isFriend(trace.Entity.player, player)
		then
			trace.Entity:Reset()
			return true
		else
			return false
		end
	end

	function MakeWireExpression2(player, Pos, Ang, model, buffer, name, inputs, outputs, vars, inc_files )
		if !player:CheckLimit("wire_expressions") then return false end

		local self = ents.Create("gmod_wire_expression2")
		if !self:IsValid() then return false end

		self:SetModel(model)
		self:SetAngles(Ang)
		self:SetPos(Pos)
		self:Spawn()
		self:SetPlayer(player)
		self.player = player
		self:SetNWEntity( "player", player )

		buffer = string.Replace(string.Replace(buffer,"£","\""),"€","\n")

		self:SetOverlayText("Expression 2\n" .. name)
		self.buffer = buffer
		self.inc_files = inc_files or {}

		self.Inputs = WireLib.AdjustSpecialInputs(self, inputs[1], inputs[2])
		self.Outputs = WireLib.AdjustSpecialOutputs(self, outputs[1], outputs[2])

		self.dupevars = vars

		player:AddCount("wire_expressions", self)
		player:AddCleanup("wire_expressions", self)
		return self
	end

	duplicator.RegisterEntityClass("gmod_wire_expression2", MakeWireExpression2, "Pos", "Ang", "Model", "_original", "_name", "_inputs", "_outputs", "_vars", "inc_files" )

	function TOOL:RightClick(trace)
		if trace.Entity:IsPlayer() then return false end

		local player = self:GetOwner()

		if  trace.Entity:IsValid()
		    && trace.Entity:GetClass() == "gmod_wire_expression2"
			&& E2Lib.isFriend(trace.Entity.player, player)
		then
			self:Download( player, trace.Entity )
			return true
		end

		player:SendLua("openE2Editor()")
		return false
	end
	
	function TOOL:Upload( ent )
		umsg.Start( "wire_expression2_tool_upload", self:GetOwner() )
			umsg.Short( ent:EntIndex() )
		umsg.End()
	end
	
	function TOOL:Download( ply, ent )
		WireLib.Expression2Download( ply, ent, nil, true )
	end
	
	----------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------ UPLOAD/DOWNLOAD -----------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------
	
	umsg.PoolString( "wire_expression2_upload_confirm" )
	umsg.PoolString( "wire_expression2_tool_upload" )
	umsg.PoolString( "wire_expression2_download_begin" )
	umsg.PoolString( "wire_expression2_download_chunk" )
	umsg.PoolString( "wire_expression2_download_wantedfiles_list_begin" )
	umsg.PoolString( "wire_expression2_download_wantedfiles_list_chunk" )

	--------------------------------------------------------------
	-- Serverside Send
	--------------------------------------------------------------
	
	local hookon = false
	local downloads = {}	
	local function transfer()
		local unhook = true
		for ply,download in pairs( downloads ) do
			if not IsValid( ply ) or not IsValid( download.entity ) then
				downloads[ply] = nil
			else
				if download.state == 0 then
					umsg.Start( "wire_expression2_download_begin", ply )
						umsg.Entity( download.entity )
						umsg.Short( #download.data )
						umsg.Bool( download.uploadandexit )
					umsg.End()
					download.state = 1
					unhook = false
				else
					umsg.Start( "wire_expression2_download_chunk", ply )
						umsg.String( download.data[download.state] )
					umsg.End()
					
					if download.state >= #download.data then
						downloads[ply] = nil
					else
						download.state = download.state + 1
						unhook = false
					end
				end
			end
		end
	
		if unhook then
			hookon = false
			hook.Remove( "Think", "Expression2Download_Think" )
		end
	end
	
	
	function WireLib.Expression2Download( ply, targetEnt, wantedfiles, uploadandexit )
		if not IsValid(targetEnt) or targetEnt:GetClass() ~= "gmod_wire_expression2" then
			WireLib.AddNotify( ply, "Invalid Expression chip specified.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			return
		end
		
		if not IsValid(ply) or not ply:IsPlayer() then -- wtf
			WireLib.AddNotify( ply, "Invalid player entity (wtf??). This should never happen.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			return
		end
		
		if downloads[ply] then
			WireLib.AddNotify( ply, "You're already downloading. Please wait until your current download is finished.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			return
		end
		
		if not E2Lib.isFriend( targetEnt.player, ply ) then
			WireLib.AddNotify( ply, "You're not allowed to download from this Expression (ent index: " .. targetEnt:EntIndex() .. ").", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			return
		end
		
		local main, includes = targetEnt:GetCode()
		if not includes or not next(includes) then -- There are no includes
			local datastr = von.serialize({ { targetEnt.name, main } })
			local data = {}
			for i=1,#datastr,240 do
				data[#data+1] = datastr:sub(i,i+239)
			end
			downloads[ply] = { state = 0, entity = targetEnt, data = data, uploadandexit = uploadandexit or false }
		elseif not wantedfiles then
			local data = {}
			for k,v in pairs( includes ) do
				data[#data+1] = k
			end
			
			local datastr = von.serialize( data )
			data = {}
			for i=1,#datastr, 240 do
				data[#data+1] = datastr:sub(i,i+239)
			end
			
			umsg.Start( "wire_expression2_download_wantedfiles_list_begin", ply )
				umsg.Entity( targetEnt )
				umsg.Short( #data )
				umsg.Bool( uploadandexit or false )
			umsg.End()
			
			local n = 0
			timer.Create( "wire_expression2_download_wantedfiles_list_"..ply:UniqueID(), 0, #data, function()
				if not IsValid( ply ) then
					timer.Destroy( "wire_expression2_download_wantedfiles_list_"..ply:UniqueID() )
					return
				end
				
				n = n + 1
				umsg.Start( "wire_expression2_download_wantedfiles_list_chunk", ply )
					umsg.String( data[n] )
				umsg.End()
			end)
		else
			local data = { {}, {} }
			if wantedfiles.main then
				data[1] = { targetEnt.name, main }
				wantedfiles.main = nil
			end
			
			for i=1,#wantedfiles do
				local path = wantedfiles[i]
				if includes[path] then
					data[2][path] = includes[path]
				else
					WireLib.AddNotify( ply, "Nonexistant file requested ('" .. tostring(path) .. "'). File skipped.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
				end
			end
			
			local datastr = von.serialize( data )
			data = {}
			for i=1,#datastr, 240 do
				data[#data+1] = datastr:sub(i,i+239)
			end
			
			downloads[ply] = { state = 0, entity = targetEnt, data = data, uploadandexit = uploadandexit or false }
		end
		
		if not hookon and downloads[ply] ~= nil then
			hookon = true
			hook.Add( "Think", "Expression2Download_Think", transfer )
		end
	end
	
	local wantedfiles = {}
	concommand.Add( "wire_expression2_download_wantedfiles_list_begin", function(ply,cmd,args)
		if not wantedfiles[ply] then wantedfiles[ply] = {} end
		wantedfiles[ply].buffer = ""
		wantedfiles[ply].count = 0
		wantedfiles[ply].ent = tonumber(args[1])
		if not wantedfiles[ply].ent then
			WireLib.AddNotify( ply, "Invalid entity specified to wire_expression2_download_wantedfiles_list_begin. Download aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			wantedfiles[ply] = nil
			return
		end
		
		wantedfiles[ply].ent = Entity(tonumber(args[1]))
		if not IsValid(wantedfiles[ply].ent) then
			WireLib.AddNotify( ply, "Invalid entity specified to wire_expression2_download_wantedfiles_list_begin. Download aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			wantedfiles[ply] = nil
			return
		end
		
		wantedfiles[ply].maxcount = tonumber(args[2])
		if not wantedfiles[ply].maxcount then
			WireLib.AddNotify( ply, "Invalid maxcount specified to wire_expression2_download_wantedfiles_list_begin. Download aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			wantedfiles[ply] = nil
			return
		end
		
		wantedfiles[ply].uploadandexit = false
		
		local uploadandexit = args[3]
		if uploadandexit and uploadandexit ~= "" and uploadandexit == "1" then
			wantedfiles[ply].uploadandexit = true
		end
	end)
	
	concommand.Add( "wire_expression2_download_wantedfiles_list_chunk", function(ply,cmd,args)
		if not wantedfiles[ply] then return end
		
		wantedfiles[ply].buffer = wantedfiles[ply].buffer .. args[1]
		wantedfiles[ply].count = wantedfiles[ply].count + 1
		
		if wantedfiles[ply].count >= wantedfiles[ply].maxcount then
			local ok, ret = pcall( von.deserialize, E2Lib.decode( wantedfiles[ply].buffer ) )
			if not ok then
				WireLib.AddNotify( ply, "Expression 2 download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
				print( "Expression 2 download failed! Error message:\n" .. ret )
				return
			end
			
			WireLib.Expression2Download( ply, wantedfiles[ply].ent, ret, wantedfiles[ply].uploadandexit )
		end
	end)
	
	--------------------------------------------------------------
	-- Serverside Receive
	--------------------------------------------------------------
	
	local uploads = {}
	concommand.Add( "wire_expression2_upload_begin", function( ply, cmd, args )
		local id = ply:UniqueID()
		if not uploads[id] then uploads[id] = {} end

		local upload = {}
		
		local to = tonumber(args[1])
		if not to then return end
		local toent = Entity(to)
		if not IsValid(toent) or toent:GetClass() ~= "gmod_wire_expression2" then
			WireLib.AddNotify( ply, "Invalid Expression chip specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			umsg.Start( "wire_expression2_upload_confirm", ply ) umsg.Long( to ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "wire_expression2_upload_timeout"..to )
			return
		end

		if not E2Lib.isFriend(ply,toent.player) then
			WireLib.AddNotify( ply, "You are not allowed to upload to the target Expression chip. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			umsg.Start( "wire_expression2_upload_confirm", ply ) umsg.Long( to ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "wire_expression2_upload_timeout"..to )
			return
		end
		
		upload.to = toent		
		
		upload.chunks = tonumber(args[2])
		if not upload.chunks then
			WireLib.AddNotify( ply, "Error: No chunk number specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			umsg.Start( "wire_expression2_upload_confirm", ply ) umsg.Long( to ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "wire_expression2_upload_timeout"..to )
			return
		end
		
		upload.data = {}
		
		uploads[id][to] = upload
		
		timer.Create( "wire_expression2_upload_timeout"..to, 5, 1, function()
			if ply and ply:IsValid() then WireLib.AddNotify( ply, "Expression 2 upload timed out!", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 ) end
			uploads[id][to] = nil
		end)
		
		umsg.Start( "wire_expression2_upload_confirm", ply ) umsg.Long( to ) umsg.Bool( true ) umsg.End()
	end)
	
	concommand.Add( "wire_expression2_upload_chunk", function( ply, cmd, args )
		local id = ply:UniqueID()
		if not uploads[id] then return end
	
		local to = tonumber(args[1])
		if not to or not uploads[id][to] then return end
		toent = Entity(to)
		if not IsValid(toent) or toent:GetClass() ~= "gmod_wire_expression2" then
			WireLib.AddNotify( ply, "Invalid Expression chip specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			uploads[id][to] = nil
			umsg.Start( "wire_expression2_upload_confirm", ply ) umsg.Long( to ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "wire_expression2_upload_timeout"..to )
			return
		end
		
		local upload = uploads[id][to]
		
		if not IsValid( upload.to ) then
			WireLib.AddNotify( ply, "Target Expression chip has been removed since the start of the upload. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			uploads[id][to] = nil
			umsg.Start( "wire_expression2_upload_confirm", ply ) umsg.Long( to ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "wire_expression2_upload_timeout"..to )
			return
		end
		
		if upload.to ~= toent then
			WireLib.AddNotify( ply, "Target Expression chips do not match. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
			uploads[id][to] = nil
			umsg.Start( "wire_expression2_upload_confirm", ply ) umsg.Long( to ) umsg.Bool( false ) umsg.End()
			timer.Destroy( "wire_expression2_upload_timeout"..to )
			return
		end
	
		upload.data[#upload.data+1] = args[2]
		
		timer.Start( "wire_expression2_upload_timeout"..to )

		if #upload.data == upload.chunks then
			local datastr = E2Lib.decode( table.concat( upload.data, "" ) )
			local ok, ret = pcall( von.deserialize, datastr )
			
			if not ok then
				WireLib.AddNotify( ply, "Expression 2 upload failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
				print( "Expression 2 upload failed! Error message:\n" .. ret )
				timer.Destroy( "wire_expression2_upload_timeout"..to )
				return
			end
			
			local code = ret[1]
		
			local includes = {}
			for k,v in pairs( ret[2] ) do
				includes[k] = v
			end
			
			upload.to:Setup( code, includes )
			
			timer.Destroy( "wire_expression2_upload_timeout"..to )
			uploads[id][to] = nil
		end
	end)
	
	
	--------------------------------------------------------------
	-- Stuff for the remote updater
	--------------------------------------------------------------
	
	local antispam = {}
	-- Returns true if they are spamming, false if they can go ahead and use it
	local function canhas( ply ) -- cheezeburger!
		if (!antispam[ply]) then antispam[ply] = 0 end
		if (antispam[ply] < CurTime()) then
			antispam[ply] = CurTime() + 1
			return false
		else
			WireLib.ClientError( "This command has a 1 second anti spam protection. Try again in " .. math.Round(antispam[ply] - CurTime(),2) .. " seconds.", ply )
			return true
		end
	end
	
	concommand.Add("wire_expression_forcehalt", function(player, command, args) -- this is for the "E2 remote updater"
		local E2 = tonumber(args[1])
		if (!E2) then return end
		E2 = Entity(E2)
		if (!E2 or !E2:IsValid() or E2:GetClass() != "gmod_wire_expression2") then return end
		if (canhas( player )) then return end
		if (E2.error) then return end
		if (E2.player == player or (E2Lib.isFriend(E2.player,player) and E2.player:GetInfoNum("wire_expression2_friendwrite") == 1)) then
			E2:PCallHook( "destruct" )
			E2:Error( "Execution halted (Triggered by: " .. player:Nick() .. ")", "Execution halted" )
			if (E2.player != player) then
				WireLib.AddNotify( player, "Expression halted.", NOTIFY_GENERIC, 5, math.random(1,5) )
				player:PrintMessage( HUD_PRINTCONSOLE, "Expression halted." )
			end
		else
			WireLib.ClientError( "You do not have premission to halt this E2.", player )
		end
	end)

	concommand.Add("wire_expression_requestcode", function(player, command, args)  -- this is for the "E2 remote updater"
		local E2 = tonumber(args[1])
		if (!E2) then return end
		E2 = Entity(E2)
		if (canhas( player )) then return end
		if (!E2 or !E2:IsValid() or E2:GetClass() != "gmod_wire_expression2") then return end
		if (E2.player == player or (E2Lib.isFriend(E2.player,player) and E2.player:GetInfoNum("wire_expression2_friendwrite") == 1)) then
			WireLib.Expression2Download( player, E2 )
			WireLib.AddNotify( player, "Downloading code...", NOTIFY_GENERIC, 5, math.random(1,4) )
			player:PrintMessage( HUD_PRINTCONSOLE, "Downloading code..." )
			if (E2.player != player) then
				WireLib.AddNotify(E2.player, player:Nick() .. " is reading your E2 '" .. E2.name .. "' using remote updater.", NOTIFY_GENERIC, 5, math.random(1,4) )
				E2.player:PrintMessage( HUD_PRINTCONSOLE, player:Nick() .. " is reading your E2 '" .. E2.name .. "' using remote updater." )
			end
		else
			WireLib.ClientError( "You do not have permission to read this E2.", player )
		end
	end)

	concommand.Add("wire_expression_reset", function(player, command, args) -- this is for the "E2 remote updater"
		local E2 = tonumber(args[1])
		if (!E2) then return end
		E2 = Entity(E2)
		if (!E2 or !E2:IsValid() or E2:GetClass() != "gmod_wire_expression2") then return end
		if (canhas( player )) then return end
		if (E2.player == player or (E2Lib.isFriend(E2.player,player) and E2.player:GetInfoNum("wire_expression2_friendwrite") == 1)) then
			if E2.context.data.last or E2.first then return end

			E2:Reset()

			WireLib.AddNotify( player, "Expression reset.", NOTIFY_GENERIC, 5, math.random(1,4) )
			player:PrintMessage( HUD_PRINTCONSOLE, "Expression reset." )
			if (E2.player != player) then
				WireLib.AddNotify( E2.player, player:Nick() .. " reset your E2 '" .. E2.name .. "' using remote updater.", NOTIFY_GENERIC, 5, math.random(1,4) )
				E2.player:PrintMessage( HUD_PRINTCONSOLE, player:Nick() .. " reset your E2 '" .. E2.name .. "' using remote updater." )
			end
		else
			WireLib.ClientError( "You do not have premission to halt this E2.", player )
		end
	end)
	
elseif CLIENT then

	--------------------------------------------------------------
	-- Clientside Send
	--------------------------------------------------------------
	
	local transferrate = CreateClientConVar( "wire_expression2_upload_sleep_time", 0, true, false )
	local prev = 0

	local uploads = {}
	local totalchunks = 0
	local currentchunk = 0
	
	local function transfer()
		if prev > CurTime() then return end
		prev = CurTime() + transferrate:GetFloat()
	
		if #uploads == 0 then
			totalchunks = 0
			currentchunk = 0
			Expression2SetProgress()
			hook.Remove( "Think", "Expression2Upload_Think" )
			return
		end
		
		
		local upload = uploads[1]
		if upload.state > 0 then
			RunConsoleCommand( "wire_expression2_upload_chunk", upload.to, upload.data[upload.state] )
			if upload.state >= #upload.data then
				table.remove( uploads, 1 )
				return
			else
				currentchunk = currentchunk + 1
				upload.state = upload.state + 1
			end
		elseif upload.state == -1 then
			RunConsoleCommand( "wire_expression2_upload_begin", upload.to, #upload.data )
			upload.state = 0
			currentchunk = currentchunk + 1
			timer.Create("wire_expression2_upload_confirm_timeout_" .. upload.to,5,1,function()
				WireLib.AddNotify("Upload handshake timeout. Server did not respond. Upload aborted.",NOTIFY_ERROR,7,NOTIFYSOUND_DRIP3)
				table.remove( uploads, 1 )
			end)
		end
		
		local current
		if totalchunks ~= #upload.data then current = math.floor(upload.state/#upload.data*100) end
		Expression2SetProgress(math.floor(currentchunk/totalchunks*100),current)
		
		--[[
		Infinite simultaneous upload
		Commented out because the above one-at-a-time queued upload puts less strain on the client and server
		
		local totalchunks = 0
		local chunkssent = 0
		
		for i=#uploads,1,-1 do
			local upload = uploads[i]
			
			if upload.state > 0 then
				RunConsoleCommand( "wire_expression2_upload_chunk", upload.to, upload.data[upload.state] )
				if upload.state >= #upload.data then
					table.remove( uploads, i )
					continue
				else
					upload.state = upload.state + 1
				end
			elseif upload.state == 0 then
				RunConsoleCommand( "wire_expression2_upload_begin", upload.to, #upload.data )
				upload.state = 1
			end
			
			totalchunks = totalchunks + #upload.data
			chunkssent = chunkssent + upload.state
		end
		
		
		if #uploads == 0 then
			Expression2SetProgress(nil)
		else
			Expression2SetProgress(chunkssent/totalchunks*100)
		end
		]]
	end
	
	usermessage.Hook( "wire_expression2_upload_confirm", function( um )
		local to = um:ReadLong()
		local bool = um:ReadBool()
		for i=1,#uploads do
			if uploads[i].to == to then
				
				if uploads[i].state == 0 then
					uploads[i].state = 1
					timer.Remove("wire_expression2_upload_confirm_timeout_" .. uploads[i].to)
				end
				
				if bool == false then
					table.remove(uploads,i)
				end
				
				return
			end
		end
	end)
	
	function WireLib.Expression2Upload( targetEnt, code )
		targetEnt = targetEnt or LocalPlayer():GetEyeTrace().Entity
		if type(targetEnt) == "Entity" then
			if (not IsValid(targetEnt) or targetEnt:GetClass() ~= "gmod_wire_expression2") then
				WireLib.AddNotify("Invalid Expression entity specified!", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				return
			end
			targetEnt = targetEnt:EntIndex()
		end
		
		for i=1,#uploads do
			if uploads[i].to == targetEnt then
				WireLib.AddNotify("You're already uploading to that Expression chip. Slow down!", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				return
			end
		end
		
		code = code or wire_expression2_editor:GetCode()
		local err, includes
		
		if e2_function_data_received then
			err, includes = wire_expression2_validate(code)
			if err then
				WireLib.AddNotify(result, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
				return
			end
		else
			WireLib.AddNotify( "The Expression 2 function data has not been transferred to the client yet; uploading the E2 to the server for validation.\nNote that any includes will not be sent. You must wait for the function data to finish transmitting before you are able to use includes.", NOTIFY_ERROR, 14, NOTIFYSOUND_DRIP3 )
			
			-- This message is so long, the user might not be able to read it fast enough. Printing it to the console so they can read it there, too.
			Msg( "The Expression 2 function data has not been transferred to the client yet; uploading the E2 to the server for validation.\nNote that any includes will not be sent. You must wait for the function data to finish transmitting before you are able to use includes.\n" )
		end
		
		local upload = {}
		upload.state = -1
		upload.to = targetEnt
		
		local datastr
		if includes then
			local newincludes = {}
			for k,v in pairs( includes ) do
				newincludes[k] = v
			end
			
			datastr = E2Lib.encode( von.serialize( { code, newincludes } ) )
		else
			datastr = E2Lib.encode( von.serialize( { code, {} } ) )
		end
		
		local data = {}
		for i=1,#datastr,460 do
			data[#data+1] = datastr:sub(i,i+459)
		end
		upload.data = data	
		
		if #uploads == 0 then
			hook.Add( "Think", "Expression2Upload_Think", transfer )
		end
		
		uploads[#uploads+1] = upload
		totalchunks = totalchunks + #upload.data
		
		Expression2SetProgress(0,0)
	end
	
	usermessage.Hook( "wire_expression2_tool_upload", function( um )
		WireLib.Expression2Upload( um:ReadShort() )
	end)
	
	--------------------------------------------------------------
	-- Clientside Receive
	--------------------------------------------------------------
	
	local buffer, count, maxbuf, ent, uploadandexit = "", 0, 0, nil, false
	usermessage.Hook( "wire_expression2_download_begin", function( um )
		buffer = ""
		count = 0
		ent = um:ReadEntity()
		maxbuf = um:ReadShort()
		uploadandexit = um:ReadBool()
		
		Expression2SetProgress()
	end)
	
	
	usermessage.Hook( "wire_expression2_download_chunk", function( um )
		buffer = buffer .. um:ReadString()
		count = count + 1
		
		Expression2SetProgress(count/maxbuf*100)
		
		if count == maxbuf then
			Expression2SetProgress()
			
			local ok, ret = pcall( von.deserialize, buffer )
			if not ok then
				WireLib.AddNotify( ply, "Expression 2 download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
				return
			end
			local files = ret
			
			local name, main
			if files[1] then
				name = files[1][1]
				main = files[1][2]
			end
			
			if uploadandexit then
				wire_expression2_editor.chip = ent
			end
			
			if files[2] and next(files[2]) ~= nil then
				for k,v in pairs( files[2] ) do
					wire_expression2_editor:Open( k, v )
				end
			end
			
			wire_expression2_editor:Open( name, main )
		end
	end)
	
	local buffer2, count2, maxbuf2, ent2, uploadandexit2 = "", 0, 0, nil, false
	usermessage.Hook( "wire_expression2_download_wantedfiles_list_begin", function( um )
		buffer2 = ""
		count2 = 0
		ent2 = um:ReadEntity()
		maxbuf2 = um:ReadShort()
		uploadandexit2 = um:ReadBool()
	end)
	

	usermessage.Hook( "wire_expression2_download_wantedfiles_list_chunk", function( um )
		buffer2 = buffer2 .. um:ReadString()
		count2 = count2 + 1
		
		Expression2SetProgress(count2/maxbuf2*100)
		
		if count2 == maxbuf2 then
			Expression2SetProgress()
			
			local ok, ret = pcall( von.deserialize, buffer2 )
			if not ok then
				WireLib.AddNotify( ply, "Expression 2 file list download failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3 )
				print( "Expression 2 file list download failed! Error message:\n" .. ret )
				return
			end
			local files = ret
			local height = 23
			
			local pnl = vgui.Create("DFrame")
			pnl:SetSize( 200, 100 )
			pnl:Center()
			pnl:SetTitle( "Select files to download" )
			
			local lst = vgui.Create( "DPanelList", pnl )
			lst.Paint = function() end
			lst:SetSpacing( 2 )
			
			local selectedfiles = { main = true }
			
			local checkboxes = {}
			
			local check = vgui.Create( "DCheckBoxLabel" )
			check:SetText( "Main" )
			check:Toggle()
			lst:AddItem( check )
			function check:OnChange( val )
				if val then
					selectedfiles.main = true
				else
					selectedfiles.main = nil
				end
			end
			checkboxes[#checkboxes+1] = check
			height = height + check:GetTall() + 2
			
			for i=1,#files do
				local path = files[i]
				local check = vgui.Create( "DCheckBoxLabel" )
				check:SetText( path )
				lst:AddItem( check )
				function check:OnChange( val )
					if val then
						selectedfiles[i] = path
					else
						table.remove( selectedfiles, i )
					end
				end
				checkboxes[#checkboxes+1] = check
				height = height + check:GetTall() + 2
			end
			
			local selectall = vgui.Create( "DButton" )
			selectall:SetText( "Select all" )
			lst:AddItem( selectall )
			function selectall:DoClick()
				selectedfiles = {}
				for k,v in pairs( files ) do
					selectedfiles[#selectedfiles+1] = v
				end
				selectedfiles.main = true
				
				for i=1,#checkboxes do
					if not checkboxes[i]:GetChecked() then checkboxes[i]:Toggle() end -- checkboxes[i]:SetChecked( true )
				end
			end
			height = height + selectall:GetTall() + 2
			
			local selectnone = vgui.Create( "DButton" )
			selectnone:SetText( "Select none" )
			lst:AddItem( selectnone )
			function selectnone:DoClick()
				selectedfiles = {}
				
				for i=1,#checkboxes do
					if checkboxes[i]:GetChecked() then checkboxes[i]:Toggle() end -- checkboxes[i]:SetChecked( false )
				end
			end
			height = height + selectnone:GetTall() + 2
			
			local ok = vgui.Create( "DButton" )
			ok:SetText( "Ok" )
			ok:SetToolTip( "Shortcut for this button: Right click anywhere" )
			lst:AddItem( ok )
			function ok:DoClick()
				local haschoice = false
				for k,v in pairs( selectedfiles ) do haschoice = true break end
				if not haschoice then pnl:Close() return end
				
				local datastr = E2Lib.encode( von.serialize( selectedfiles ) )
				local data = {}
				for i=1,#datastr,460 do
					data[#data+1] = datastr:sub(i,i+459)
				end
			
				RunConsoleCommand( "wire_expression2_download_wantedfiles_list_begin", ent2:EntIndex(), #data, uploadandexit2 and "1" or "0" )

				local n = 0
				timer.Create( "wire_expression2_download_wantedfiles_list", 0, #data, function()
					n = n + 1
					RunConsoleCommand( "wire_expression2_download_wantedfiles_list_chunk", data[n] )
				end)
				
				pnl:Close()
			end
			height = height + ok:GetTall()
			
			local down = input.IsMouseDown( MOUSE_RIGHT )
			function pnl:Think()
				if not down and input.IsMouseDown( MOUSE_RIGHT ) then
					ok:DoClick()
				end
				down = input.IsMouseDown( MOUSE_RIGHT )
			end
			
			pnl:SetTall( math.min(height + 2,ScrH()/2) )
			lst:EnableVerticalScrollbar( true )
			lst:StretchToParent( 2, 23, 2, 2 )
			pnl:MakePopup()
			pnl:SetVisible( true )			
		end
	end)
	
	--------------------------------------------------------------

	function TOOL.BuildCPanel(panel)
		panel:ClearControls()
		panel:AddControl("Header", { Text = "#Tool_wire_expression2_name", Description = "#Tool_wire_expression2_desc" })

		//ModelPlug_AddToCPanel(panel, "expr2", "wire_expression2", nil, nil, nil, 2)

		panel:AddControl("ComboBox", {
			MenuButton = "0",
			Options = {
				["Normal"] = { wire_expression2_size = "" },
				["Mini"] = { wire_expression2_size = "_mini" },
				["Nano"] = { wire_expression2_size = "_nano" },
			}
		})

		panel:AddControl("MaterialGallery", {
			Height = "100",
			Width = "100",
			Rows = 2,
			Stretch = false,
			ConVar = "wire_expression2_select",
			Options = {
				["Modern"] =     { wire_expression2_select = "Modern",     Value = "Modern",     Material = "beer/wiremod/gate_e2",        wire_expression2_model = "models/beer/wiremod/gate_e2.mdl" },
				["Expression"] = { wire_expression2_select = "Expression", Value = "Expression", Material = "models/expression 2/exprssn", wire_expression2_model = "models/expression 2/cpu_expression.mdl" },
				["Microchip"] =  { wire_expression2_select = "Microchip",  Value = "Microchip",  Material = "models/expression 2/mcrochp", wire_expression2_model = "models/expression 2/cpu_microchip.mdl" },
				["Interface"] =  { wire_expression2_select = "Interface",  Value = "Interface",  Material = "models/expression 2/intrfce", wire_expression2_model = "models/expression 2/cpu_interface.mdl" },
				["Controller"] = { wire_expression2_select = "Controller", Value = "Controller", Material = "models/expression 2/cntrllr", wire_expression2_model = "models/expression 2/cpu_controller.mdl" },
				["Processor"] =  { wire_expression2_select = "Processor",  Value = "Processor",  Material = "models/expression 2/prcssor", wire_expression2_model = "models/expression 2/cpu_processor.mdl" },
			}
		})

		if( wire_expression2_editor == nil ) then initE2Editor() end

		local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
		panel:AddPanel(FileBrowser)
		FileBrowser:Setup("Expression2")
		FileBrowser:SetSize(235,400)
		function FileBrowser:OnFileClick()
			if( wire_expression2_editor == nil ) then initE2Editor() end

			if(dir == self.File.FileDir and CurTime() - lastclick < 1) then
				wire_expression2_editor:Open(dir)
			else
				lastclick = CurTime()
				dir = self.File.FileDir
				wire_expression2_editor:LoadFile(dir)
				Validation:Validate()
			end
		end

		Validation = vgui.Create("Label" , panel)
		panel:AddPanel(Validation)
		Validation.OnMousePressed = function(panel) panel:Validate() end
		Validation.Validate = function(panel)
			local errors = wire_expression2_validate(wire_expression2_editor:GetCode())
			if(!errors) then
				panel:SetText("Validation Successful")
			else
				panel:SetText("Error in file")
			end
		end
		Validation:SetText("Click to validate...")
		local OpenEditor = vgui.Create("DButton" , panel)
		panel:AddPanel(OpenEditor)
		OpenEditor:SetTall(30)
		OpenEditor:SetText("Open Editor")
		OpenEditor.DoClick = function(button)
			wire_expression2_editor:Open()
		end

		local NewExpression = vgui.Create("DButton" , panel)
		panel:AddPanel(NewExpression)
		NewExpression:SetTall(30)
		NewExpression:SetText("New Expression")
		NewExpression.DoClick = function(button)
			wire_expression2_editor:Open()
			wire_expression2_editor:NewScript()
		end

	end

	function initE2Editor()
		wire_expression2_editor = vgui.Create( "Expression2EditorFrame")
		wire_expression2_editor:Setup("Expression 2 Editor","Expression2","E2")
	end

	function openE2Editor()
		if( wire_expression2_editor == nil ) then initE2Editor() end
		wire_expression2_editor:Open()
	end

	/******************************************************************************\
	  Expression 2 Tool Screen for Garry's Mod
	  Andreas "Syranide" Svensson, me@syranide.com
	\******************************************************************************/

	surface.CreateFont("Arial", 40, 1000, true, false, "Expression2ToolScreenFont")
	surface.CreateFont("Arial", 30, 1000, true, false, "Expression2ToolScreenSubFont")

	local percent = nil
	local percent2 = nil
	local name = "Unnamed"

	function Expression2SetName(n)
		name = n
		if !name then
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

	function Expression2SetProgress(p,p2)
		percent = p
		percent2 = p2
	end

	function DrawTextOutline(text, font, x, y, color, xalign, yalign, bordercolor, border)
		for i=0,8 do
			draw.SimpleText(text, font, x + border * math.sin(i * math.pi / 4), y + border * math.cos(i * math.pi / 4), bordercolor, xalign, yalign)
		end

		draw.SimpleText(text, font, x, y, color, xalign, yalign)
	end

	local CogColor = Color(150, 34, 34, 255)
	local CogTexture = surface.GetTextureID("expression 2/cog")
	if CogTexture == surface.GetTextureID("texturemissing") then CogTexture = nil end

	local function RenderScreen()
		cam.Start2D()

			surface.SetDrawColor(32, 32, 32, 255)
			surface.DrawRect(0, 0, 256, 256)

			if CogTexture then
				if percent then
					ToColor = Color(34, 150, 34, 255)
				else
					ToColor = Color(150, 34, 34, 255)
				end

				CogDelta = 750 * FrameTime()

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

			if percent then
				surface.SetFont("Expression2ToolScreenFont")
				local w, h = surface.GetTextSize("Uploading")
				DrawTextOutline("Uploading", "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
				
				draw.RoundedBox(4, 128 - w/2 - 2, 128 + h / 2 - 0, (w*percent)/100 + 4, h2 - 4, Color(0, 0, 0, 255))
				draw.RoundedBox(2, 128 - w/2 + 2, 128 + h / 2 + 4, (w*percent)/100 - 4, h2 - 12, Color(224, 224, 224, 255))
				
				if percent2 then
					draw.RoundedBox(4, 128 - w/2 - 2, 128 + h / 2 + 24, (w*percent2)/100 + 4, h2 - 4, Color(0, 0, 0, 255))
					draw.RoundedBox(2, 128 - w/2 + 2, 128 + h / 2 + 28, (w*percent2)/100 - 4, h2 - 12, Color(224, 224, 224, 255))
				end
			elseif name then
				DrawTextOutline("Expression 2", "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
				DrawTextOutline(name, "Expression2ToolScreenSubFont", 128, 128 + (h+h2) / 2 - 4, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
			end

		cam.End2D()
	end
	if VERSION >= 150 then
		function TOOL:DrawToolScreen(width, height)
			RenderScreen()
		end
	else
		function TOOL:RenderToolScreen()
			RenderScreen()
		end
	end
end

/*************************** 'in editor' animation ****************************/

if SERVER then

	/************************* client-side event handling *************************/
	-- this might fit better elsewhere

	local wire_expression2_event = {}

	concommand.Add("wire_expression2_event", function(ply, command, args)
		local handler = wire_expression2_event[args[1]]
		if not handler then return end
		return handler(ply, args)
	end)

	-- actual editor open/close handlers

	function wire_expression2_event.editor_open(ply, args)
		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("wire_expression2_editor_status", rp)
			umsg.Entity(ply)
			umsg.Bool(true)
		umsg.End()
	end

	function wire_expression2_event.editor_close(ply, args)
		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("wire_expression2_editor_status", rp)
			umsg.Entity(ply)
			umsg.Bool(false)
		umsg.End()
	end

elseif CLIENT then

	local busy_players = {}
	hook.Add("EntityRemoved", "wire_expression2_busy_animation", function(ply)
		busy_players[ply] = nil
	end)

	local emitter = ParticleEmitter(Vector(0,0,0))

	usermessage.Hook("wire_expression2_editor_status", function(um)
		local ply = um:ReadEntity()
		local status = um:ReadBool()

		if not ply:IsValid() then return end
		if ply == LocalPlayer() then return end

		busy_players[ply] = status or nil
	end)

	local rolldelta = math.rad(80)
	timer.Create("wire_expression2_editor_status", 1, 0, function()
		rolldelta = -rolldelta
		for ply,_ in pairs(busy_players) do
			local BoneIndx = ply:LookupBone("ValveBiped.Bip01_Head1")
			local BonePos, BoneAng = ply:GetBonePosition( BoneIndx )
			local particle = emitter:Add("expression 2/cog_world", BonePos+Vector(0,0,16))
			if particle then
				particle:SetColor(150,34,34)
				particle:SetVelocity(Vector(0,0,17))

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


function TOOL:UpdateGhostWireExpression2( ent, player )

		if ( !ent ) then return end
		if ( !ent:IsValid() ) then return end

		local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
		local trace 	= util.TraceLine( tr )
		if (!trace.Hit) then return end

		if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_expression2" || trace.Entity:IsPlayer()) then
			ent:SetNoDraw( true )
			return
		end

		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90

		local min = ent:OBBMins()
		ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
		ent:SetAngles( Ang )

		ent:SetNoDraw( false )

	end

	function TOOL:Think()
		local model = self:GetModel()

		if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model || (not self.GhostEntity:GetModel()) ) then
			self:MakeGhostEntity( model, Vector(0,0,0), Angle(0,0,0) )
		end

		self:UpdateGhostWireExpression2( self.GhostEntity, self:GetOwner() )
	end



	local prevmodel,prevvalid
	function validModelCached(model)
		if model ~= prevmodel then
			prevmodel = model
			prevvalid = util.IsValidModel(model)
		end
		return prevvalid
	end

	function TOOL:GetModel()
		local scriptmodel = self:GetClientInfo("scriptmodel")
		if scriptmodel and scriptmodel ~= "" and validModelCached(scriptmodel) then return Model(scriptmodel) end

		local model = self:GetClientInfo("model")
		local size = self:GetClientInfo("size")

		if model and size then
			local modelname, modelext = model:match("(.*)(%..*)")
			if not modelext then
				if validModelCached( model ) then
					return model
				else
					return "models/beer/wiremod/gate_e2.mdl"
				end
			end
			local newmodel = modelname .. size .. modelext
			if validModelCached(newmodel) then
				return Model(newmodel)
			end
		end

		return "models/beer/wiremod/gate_e2.mdl"
	end

