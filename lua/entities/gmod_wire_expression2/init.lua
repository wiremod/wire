-- a variable inside a single if-branch is discarded, even though that type should be forced for any consecutive assignments

AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

CreateConVar("wire_expression2_unlimited", "0")
CreateConVar("wire_expression2_quotasoft", "5000")
CreateConVar("wire_expression2_quotahard", "100000")
CreateConVar("wire_expression2_quotatick", "25000")

timer.Create("e2quota", 1, 0, function()
	local unlimited = GetConVar("wire_expression2_unlimited"):GetInt()
	e2_softquota = GetConVar("wire_expression2_quotasoft"):GetInt()
	e2_hardquota = GetConVar("wire_expression2_quotahard"):GetInt()
	e2_tickquota = GetConVar("wire_expression2_quotatick"):GetInt()

	if unlimited == 0 then
		if e2_softquota < 5000   then e2_softquota = 5000 end
		if e2_hardquota < 100000 then e2_hardquota = 100000 end
		if e2_tickquota < 25000  then e2_tickquota = 25000 end
	else
		e2_softquota = 1000000
		e2_hardquota = 1000000
		e2_tickquota = 100000
	end
end)

ENT.OverlayDelay = 0
ENT.WireDebugName = "Expression 2"

local function copytype(var)
	if type(var) == "table" then
		return table.Copy(var)
	else
		return var
	end
end

function tablekeys(tbl)
	l = {}
	for k,v in pairs(tbl) do
		l[#l + 1] = k
	end
	return l
end

function tablevalues(tbl)
	l = {}
	for k,v in pairs(tbl) do
		l[#l + 1] = v
	end
	return l
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = WireLib.CreateInputs(self, {})
	self.Outputs = WireLib.CreateOutputs(self, {})

	self:SetOverlayText("Expression 2\n(none)")
	local r,g,b,a = self:GetColor()
	self:SetColor(255, 0, 0, a)
end

function ENT:OnRestore()
	self:Setup(self.original,nil,true)
end

function ENT:Execute()
	if self.error then return end
	if self.context.resetting then return end

	for k,v in pairs(self.tvars) do
		self.context.vars[k] = copytype(wire_expression_types2[v][2])
	end

	e2_install_hook_fix()
	self:PCallHook('preexecute')

	local ok, msg = pcall(self.script[1], self.context, self.script)
	if not ok then
		if msg == "exit" then
		elseif msg == "perf" then
			self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "tick quota exceeded")
		else
			self:Error("Expression 2 (" .. self.name .. "): " .. e2_processerror(msg), "script error")
		end
	end

	self.first = false -- if hooks call execute
	self.duped = false -- if hooks call execute
	self.context.triggerinput = nil -- if hooks call execute

	self:PCallHook('postexecute')
	e2_remove_hook_fix()

	self:TriggerOutputs()

	for k,v in pairs(self.inports[3]) do
		if self.context.vclk[k] then
			if wire_expression_types[self.Inputs[k].Type][3] then
				self.context.vars[k] = wire_expression_types[self.Inputs[k].Type][3](self.context, self.Inputs[k].Value)
			else
				self.context.vars[k] = self.Inputs[k].Value
			end
		end
	end

	self.context.vclk = {}

	if self.context.prfcount + self.context.prf - e2_softquota > e2_hardquota then
		self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "hard quota exceeded")
	end

	if self.error then self:PCallHook('destruct') end
end

function ENT:Think()
	self.BaseClass.Think(self)
	self:NextThink(CurTime())

	if self.context and not self.error then
		self.context.prfbench = self.context.prfbench * 0.95 + self.context.prf * 0.05
		self.context.prfcount = self.context.prfcount + self.context.prf - e2_softquota
		if self.context.prfcount < 0 then self.context.prfcount = 0 end

		self.context.prf = 0

		if self.context.prfcount / e2_hardquota > 0.33 then
			self:SetOverlayText("Expression 2\n" .. self.name .. "\n" .. tostring(math.Round(self.context.prfbench)) .. " ops, " .. tostring(math.Round(self.context.prfbench / e2_softquota * 100)) .. "% (+" .. tostring(math.Round(self.context.prfcount / e2_hardquota * 100)) .. "%)")
		else
			self:SetOverlayText("Expression 2\n" .. self.name .. "\n" .. tostring(math.Round(self.context.prfbench)) .. " ops, " .. tostring(math.Round(self.context.prfbench / e2_softquota * 100)) .. "%")
		end
	end

	return true
end

local CallHook = wire_expression2_CallHook
function ENT:CallHook(hookname, ...)
	if not self.context then return end
	return CallHook(hookname, self.context, ...)
end

function ENT:OnRemove( )
	if not self.error and not self.removing then -- make sure destruct hooks aren't called twice (once on error, once on remove)
		self.removing = true
		self:PCallHook('destruct')
	end
end

function ENT:PCallHook(...)
	local ok, ret = pcall(self.CallHook, self, ...)
	if ok then
		return ret
	else
		self:Error("Expression 2 (" .. self.name .. "): "..ret)
	end
end

function ENT:Error(message, overlaytext)
	self:SetOverlayText("Expression 2\n" .. self.name .. "\n("..(overlaytext or "script error")..")")
	local r,g,b,a = self:GetColor()
	self:SetColor(255, 0, 0, a)

	self.error = true
	ErrorNoHalt(message .. "\n")
	WireLib.ClientError(message, self.player)
end

function ENT:CompileCode( buffer )
	self.original = buffer
	local status, directives, buffer = PreProcessor.Execute(buffer)
	if not status then self:Error(directives) return end
	self.buffer = buffer
	self.error = false

	self.name = directives.name
	if directives.name == "" then
		self.name = "generic"
		self.WireDebugName = "Expression 2"
	else
		self.WireDebugName = "E2 - " .. self.name
	end
	self:SetNWString( "name", self.name )

	self.inports = directives.inputs
	self.outports = directives.outputs
	self.persists = directives.persist
	self.trigger = directives.trigger

	local status, tokens = Tokenizer.Execute(self.buffer)
	if not status then self:Error(tokens) return end

	local status, tree, dvars = Parser.Execute(tokens)
	if not status then self:Error(tree) return end

	local status, script, dvars, tvars = Compiler.Execute(tree, self.inports[3], self.outports[3], self.persists[3], dvars)
	if not status then self:Error(script) return end
	self.tvars = tvars

	self.script = script
	self.dvars = dvars
	self:ResetContext()
end

function ENT:ResetContext()
	self.context = {
		vars = {},
		vclk = {},
		data = {},
		entity = self,
		player = self.player,
		uid = self.uid,
		prf = 0,
		prfcount = 0,
		prfbench = 0,
	}
	self._vars = self.context.vars

	self.Inputs = WireLib.AdjustSpecialInputs(self, self.inports[1], self.inports[2])
	self.Outputs = WireLib.AdjustSpecialOutputs(self, self.outports[1], self.outports[2])

	self._original = string.Replace(string.Replace(self.original,"\"","£"),"\n","€")
	self._buffer = self.original -- TODO: is that really intended?

	self._name = self.name
	self._inputs = { {}, {} }
	self._outputs = { {}, {} }

	for k,v in pairs(self.inports[3]) do
		self._inputs[1][#self._inputs[1] + 1] = k
		self._inputs[2][#self._inputs[2] + 1] = v
		self.context.vars[k] = copytype(wire_expression_types[v][2])
	end

	for k,v in pairs(self.outports[3]) do
		self._outputs[1][#self._outputs[1] + 1] = k
		self._outputs[2][#self._outputs[2] + 1] = v
		self.context.vars[k] = copytype(wire_expression_types[v][2])
		self.context.vclk[k] = true
	end

	for k,v in pairs(self.persists[3]) do
		self.context.vars[k] = copytype(wire_expression_types[v][2])
	end

	for k,v in pairs(self.Inputs) do
		if wire_expression_types[v.Type][3] then
			self.context.vars[k] = wire_expression_types[v.Type][3](self.context, v.Value)
		else
			self.context.vars[k] = v.Value
		end
	end

	for k,v in pairs(self.dvars) do
		self.context.vars["$" .. k] = self.context.vars[k]
	end

	self.error = false
end

function ENT:Setup(buffer, restore, forcecompile)
	if self.script then
		self:PCallHook('destruct')
	end

	self.uid = self.player:UniqueID()

	if (self.original != buffer or forcecompile) then
		self:CompileCode( buffer )
	else
		self:ResetContext()
	end

	self:SetOverlayText("Expression 2\n" .. self.name)
	local r,g,b,a = self:GetColor()
	self:SetColor(255, 255, 255, a)

	local ok, msg = pcall(self.CallHook, self, 'construct')
	if not ok then
		Msg("Construct hook(s) failed, executing destruct hooks...\n")
		local ok2, msg2 = pcall(self.CallHook, self, 'destruct')
		if ok2 then
			self:Error(msg.."\nDestruct hooks succeeded.")
		else
			self:Error(msg.."\n"..msg2)
		end
		return
	end

	self.duped = false

	if !restore then
		self.first = true
		self:Execute()
	end

	self:NextThink(CurTime())
	self:Think()
end

function ENT:Reset()
	-- prevent E2 from executing anything
	self.context.resetting = true

	-- reset the chip in the next tick
	timer.Simple(0, self.Setup, self, self.original)
end

function ENT:TriggerInput(key, value)
	if self.error then return end
	if key and self.inports[3][key] then
		t = self.inports[3][key]

		self.context.vars["$" .. key] = self.context.vars[key]
		if wire_expression_types[t][3] then
			self.context.vars[key] = wire_expression_types[t][3](self.context, value)
		else
			self.context.vars[key] = value
		end

		self.context.triggerinput = key
		if self.trigger[1] || self.trigger[2][key] then self:Execute() end
		self.context.triggerinput = nil
	end
end

function ENT:TriggerOutputs()
	for key,t in pairs(self.outports[3]) do
		if self.context.vclk[key] or self.first then
			if wire_expression_types[t][4] then
				WireLib.TriggerOutput(self, key, wire_expression_types[t][4](self.context, self.context.vars[key]))
			else
				WireLib.TriggerOutput(self, key, self.context.vars[key])
			end
		end
	end
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	self:Setup(self.buffer, true)

	if not self.error then
		for k,v in pairs(self.dupevars) do
			self.context.vars[k] = v
		end
		--table.Merge(self.context.vars, self.dupevars)
		self.dupevars = nil

		self.duped = true
		self:Execute()
		self.duped = false
	end

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID, GetConstByID)
end

/********************************** Transfer **********************************/

function ENT:SendCode(ply)
	if (E2Lib.isFriend(self.player, ply)) then
		local chunksize = 200
		if(!self.original || !ply) then return end
		local code = self.original
		local chunks = math.ceil(code:len() / chunksize)
		umsg.Start("wire_expression2_download", ply)
			umsg.Short(chunks)
			umsg.String(self.name)
		umsg.End()

		for i=0,chunks do
			umsg.Start("wire_expression2_download", ply)
				umsg.Short(i)
				umsg.String(code:sub(i * chunksize + 1, (i + 1) * chunksize))
			umsg.End()
		end
	end
end

local buffer = {}

function ENT:Prepare(player)
	local ID = player:UserID()
	buffer[ID] = {}
	buffer[ID].ent = self

	--if !(E2Lib.isFriend(buffer[ID].ent.player, player)
	--     && (buffer[ID].ent.player == player || buffer[ID].ent.player:GetInfoNum("wire_expression2_friendwrite") != 0)) then return end
end

local antispam = {}
-- Returns true if they are spamming, false if they can go ahead and use it
local function canhas( ply ) -- cheezeburger!
	if (!antispam[ply]) then antispam[ply] = 0 end
	if (antispam[ply] < CurTime()) then
		antispam[ply] = CurTime() + 3
		return false
	else
		WireLib.ClientError( "This command has a 3 second anti spam protection. Try again in " .. math.ceil(antispam[ply] - CurTime()) .. " seconds.", ply )
		return true
	end
end

concommand.Add("wire_expression_prepare", function(player, command, args) -- this is for the "E2 remote updater"
	local E2 = tonumber(args[1])
	if (!E2) then return end
	E2 = Entity(E2)
	if (!E2 or !E2:IsValid() or E2:GetClass() != "gmod_wire_expression2") then return end
	if (E2.player != player and canhas( player )) then return end
	if (E2.player == player or (E2Lib.isFriend(E2.player,player) and E2.player:GetInfoNum("wire_expression2_friendwrite") == 1)) then
		E2:Prepare( player )
		WireLib.AddNotify( player, "Uploading code...", NOTIFY_GENERIC, 5, math.random(1,5) )
		player:PrintMessage( HUD_PRINTCONSOLE, "Uploading code..." )
		if (E2.player != player) then
			WireLib.AddNotify(E2.player, player:Nick() .. " is writing to your E2 '" .. E2.name .. "' using remote updater.", NOTIFY_GENERIC, 5, math.random(1,5) )
			E2.player:PrintMessage( HUD_PRINTCONSOLE, player:Nick() .. " is writing to your E2 '" .. E2.name .. "' using remote updater." )
		end
	else
		WireLib.ClientError( "You do not have premission to write to this E2.", player )
	end
end)
concommand.Add("wire_expression_forcehalt", function(player, command, args) -- this is for the "E2 remote updater"
	local E2 = tonumber(args[1])
	if (!E2) then return end
	E2 = Entity(E2)
	if (!E2 or !E2:IsValid() or E2:GetClass() != "gmod_wire_expression2") then return end
	if (E2.player != player and canhas( player )) then return end
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
	if (E2.player != player and canhas( player )) then return end
	if (!E2 or !E2:IsValid() or E2:GetClass() != "gmod_wire_expression2") then return end
	if (E2.player == player or (E2Lib.isFriend(E2.player,player) and E2.player:GetInfoNum("wire_expression2_friendwrite") == 1)) then
		E2:SendCode( player )
		E2:Prepare( player )
		WireLib.AddNotify( player, "Downloading code...", NOTIFY_GENERIC, 5, math.random(1,5) )
		player:PrintMessage( HUD_PRINTCONSOLE, "Downloading code..." )
		if (E2.player != player) then
			WireLib.AddNotify(E2.player, player:Nick() .. " is reading your E2 '" .. E2.name .. "' using remote updater.", NOTIFY_GENERIC, 5, math.random(1,5) )
			E2.player:PrintMessage( HUD_PRINTCONSOLE, player:Nick() .. " is reading your E2 '" .. E2.name .. "' using remote updater." )
		end
	else
		WireLib.ClientError( "You do not have permission to read this E2.", player )
	end
end)

concommand.Add("wire_expression_upload_begin", function(player, command, args)
	local ID = player:UserID()
	if !buffer[ID] or (!(E2Lib.isFriend(buffer[ID].ent.player, player)
	     && (buffer[ID].ent.player == player || buffer[ID].ent.player:GetInfoNum("wire_expression2_friendwrite") != 0))) then return end

	buffer[ID].text = ""
	buffer[ID].len = tonumber(args[1])
	buffer[ID].chunk = 0
	buffer[ID].chunks = tonumber(args[2])
	buffer[ID].ent:SetOverlayText("Expression 2\n(transferring)")
	buffer[ID].ent:SetColor(0, 255, 0, 255)
end)

concommand.Add("wire_expression_upload_data", function(player, command, args)
	local ID = player:UserID()

	if not buffer[ID] or not buffer[ID].text or not buffer[ID].chunk then
		--Msg("buffer does not exist! Player="..tostring(player).." chunk="..args[1].."\n")
		return
	end

	if !(E2Lib.isFriend(buffer[ID].ent.player, player)
	     && (buffer[ID].ent.player == player || buffer[ID].ent.player:GetInfoNum("wire_expression2_friendwrite") != 0)) then return end

	buffer[ID].text = buffer[ID].text .. args[1]
	buffer[ID].chunk = buffer[ID].chunk + 1

	local percent = math.Round((buffer[ID].chunk / buffer[ID].chunks) * 100)
end)

concommand.Add("wire_expression_upload_end", function(player, command, args)
	local ID = player:UserID()
	if !buffer[ID] or (!(E2Lib.isFriend(buffer[ID].ent.player, player)
	     && (buffer[ID].ent.player == player || buffer[ID].ent.player:GetInfoNum("wire_expression2_friendwrite") != 0))) then return end

	local buf = buffer[ID]
	buffer[ID] = nil

	local ent = buf.ent
	if not ValidEntity(ent) then return end

	if not buf.text then
		-- caused by concurrent download from the same chip
		ent:SetOverlayText("Expression 2\n(transfer error)")
		local r,g,b,a = ent:GetColor()
		ent:SetColor(255, 0, 0, a)
	end

	local decoded = E2Lib.decode(buf.text or "")
	if(decoded:len() != buf.len) then
		ent:SetOverlayText("Expression 2\n(transfer error)")
		local r,g,b,a = ent:GetColor()
		ent:SetColor(255, 0, 0, a)
	else
		ent:Setup(decoded)
		--ent.player = player
	end
end)


--[[
	Player Disconnection Magic
--]]
local cvar = CreateConVar("wire_expression2_pause_on_disconnect", 0, 0, "Decides if chips should pause execution on their owner's disconnect.\n0 = no, 1 = yes, 2 = non-admins only.");
-- This is a global function so it can be overwritten for greater control over whose chips are frozenated
function wire_expression2_ShouldFreezeChip(ply)
	return not ply:IsAdmin();
end

-- It uses EntityRemoved because PlayerDisconnected doesn't catch all disconnects.
hook.Add("EntityRemoved","Wire_Expression2_Player_Disconnected",function(ent)
	if (not (ent and ent:IsPlayer())) then
		return;
	end
	local ret = cvar:GetInt();
	if (ret == 0 or (ret == 2 and not wire_expression2_ShouldFreezeChip(ent))) then
		return;
	end
	for k,v in ipairs( ents.FindByClass("gmod_wire_expression2") ) do
		if (v.player == ent) then
			v:SetOverlayText("Expression 2\n" .. v.name .. "\n(Owner disconnected.)")
			local r,g,b,a = v:GetColor()
			v:SetColor(255, 0, 0, a)
			v.disconnectPaused = {r,g,b,a};
			v.error = true
		end
	end
end)

hook.Add("PlayerAuthed", "Wire_Expression2_Player_Authed", function(ply, sid, uid)
	local c;
	for _,ent in pairs(ents.FindByClass("gmod_wire_expression2")) do
		if (ent.uid == uid) then
			ent.context.player = ply;
			ent.player = ply;
			ent:SetNWEntity( "player", ply )
			if (ent.disconnectPaused) then
				c = ent.disconnectPaused;
				ent:SetColor(c[1],c[2],c[3],c[4]);
				ent.error = false;
				ent.disconnectPaused = false;
				ent:SetOverlayText("Expression 2\n" .. ent.name);
			end
		end
	end
end);
