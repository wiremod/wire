AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

-- This makes E2s not save using garry's workshop save
-- Until someone can find the cause of the crashes, leave this in here
local old = gmsave.ShouldSaveEntity
function gmsave.ShouldSaveEntity( ent, ... )
	if ent:GetClass() == "gmod_wire_expression2" then return false end
	return old( ent, ... )
end

local wire_expression2_unlimited = GetConVar("wire_expression2_unlimited")
local wire_expression2_quotasoft = GetConVar("wire_expression2_quotasoft")
local wire_expression2_quotahard = GetConVar("wire_expression2_quotahard")
local wire_expression2_quotatick = GetConVar("wire_expression2_quotatick")

timer.Create("e2quota", 1, 0, function()
	if wire_expression2_unlimited:GetBool() then
		e2_softquota = 1000000
		e2_hardquota = 1000000
		e2_tickquota = 100000
	else
		e2_softquota = wire_expression2_quotasoft:GetInt()
		e2_hardquota = wire_expression2_quotahard:GetInt()
		e2_tickquota = wire_expression2_quotatick:GetInt()
	end
end)

local function copytype(var)
	return istable(var) and table.Copy(var) or var
end


local ScopeManager = {}
ScopeManager.__index = ScopeManager

function ScopeManager:InitScope()
	self.Scopes = {}
	self.ScopeID = 0
	self.Scopes[0] = self.GlobalScope or { vclk = {} } -- for creating new enviroments
	self.Scope = self.Scopes[0]
	self.GlobalScope = self.Scope
end

function ScopeManager:PushScope()
	self.Scope = { vclk = {} }
	self.ScopeID = self.ScopeID + 1
	self.Scopes[self.ScopeID] = self.Scope
end

function ScopeManager:PopScope()
	self.ScopeID = self.ScopeID - 1
	self.Scope = self.Scopes[self.ScopeID]
	self.Scopes[self.ScopeID] = self.Scope
	return table.remove(self.Scopes, self.ScopeID + 1)
end

function ScopeManager:SaveScopes()
	return { self.Scopes, self.ScopeID, self.Scope }
end

function ScopeManager:LoadScopes(Scopes)
	self.Scopes = Scopes[1]
	self.ScopeID = Scopes[2]
	self.Scope = Scopes[3]
end

function ENT:UpdateOverlay(clear)
	if clear then
		self:SetOverlayData( {
								txt = "(none)",
								error = self.error,
								prfbench = 0,
								prfcount = 0,
								timebench = 0
							})
	else
		self:SetOverlayData( {
								txt = self.name, -- name/error
								error = self.error, -- error bool
								prfbench = self.context.prfbench,
								prfcount = self.context.prfcount,
								timebench = self.context.timebench
							})
	end	
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = WireLib.CreateInputs(self, {})
	self.Outputs = WireLib.CreateOutputs(self, {})

	self:UpdateOverlay(true)
	self:SetColor(Color(255, 0, 0, self:GetColor().a))
end

function ENT:OnRestore()
	self:Setup(self.original, self.inc_files, nil, true)
end

local SysTime = SysTime

function ENT:Execute()
	if self.error then return end
	if self.context.resetting then return end

	for k, v in pairs(self.tvars) do
		self.GlobalScope[k] = copytype(wire_expression_types2[v][2])
	end

	self:PCallHook('preexecute')

	self.context:PushScope()

	local bench = SysTime()

	local ok, msg = pcall(self.script[1], self.context, self.script)
	if not ok then
		if msg == "exit" then
		elseif msg == "perf" then
			self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "tick quota exceeded")
		else
			self:Error("Expression 2 (" .. self.name .. "): " .. msg, "script error")
		end
	end

	self.context.time = self.context.time + (SysTime() - bench)

	self.context:PopScope()

	self.first = false -- if hooks call execute
	self.duped = false -- if hooks call execute
	self.context.triggerinput = nil -- if hooks call execute

	self:PCallHook('postexecute')

	self:TriggerOutputs()

	for k, v in pairs(self.inports[3]) do
		if self.GlobalScope[k] then
			if wire_expression_types[self.Inputs[k].Type][3] then
				self.GlobalScope[k] = wire_expression_types[self.Inputs[k].Type][3](self.context, self.Inputs[k].Value)
			else
				self.GlobalScope[k] = self.Inputs[k].Value
			end
		end
	end

	self.GlobalScope.vclk = {}
	for k, v in pairs(self.globvars) do
		self.GlobalScope[k] = copytype(wire_expression_types2[v][2])
	end

	if self.context.prfcount + self.context.prf - e2_softquota > e2_hardquota then
		self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "hard quota exceeded")
	end

	if self.error then self:PCallHook('destruct') end
end

function ENT:Think()
	self.BaseClass.Think(self)
	self:NextThink(CurTime()+0.030303)

	if self.context and not self.error then
		self.context.prfbench = self.context.prfbench * 0.95 + self.context.prf * 0.05
		self.context.prfcount = self.context.prfcount + self.context.prf - e2_softquota
		self.context.timebench = self.context.timebench * 0.95 + self.context.time * 0.05 -- Average it over the last 20 ticks
		if self.context.prfcount < 0 then self.context.prfcount = 0 end

		self:UpdateOverlay()

		self.context.prf = 0
		self.context.time = 0
	end

	return true
end

local CallHook = wire_expression2_CallHook
function ENT:CallHook(hookname, ...)
	if not self.context then return end
	return CallHook(hookname, self.context, ...)
end

function ENT:OnRemove()
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
		self:Error("Expression 2 (" .. self.name .. "): " .. ret)
	end
end

function ENT:Error(message, overlaytext)
	self:SetOverlayText(self.name .. "\n(" .. (overlaytext or "script error") .. ")")
	self:SetColor(Color(255, 0, 0, self:GetColor().a))

	self.error = true
	-- ErrorNoHalt(message .. "\n")
	WireLib.ClientError(message, self.player)
end

function ENT:CompileCode(buffer, files, filepath)
	self.original = buffer
	if filepath then -- filepath may have already been set from the dupe function
		self.filepath = filepath
	end

	local status, directives, buffer = PreProcessor.Execute(buffer,nil,self)
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
	self:SetNWString("name", self.name)

	self.directives = directives
	self.inports = directives.inputs
	self.outports = directives.outputs
	self.persists = directives.persist
	self.trigger = directives.trigger

	local status, tokens = Tokenizer.Execute(self.buffer)
	if not status then self:Error(tokens) return end

	local status, tree, dvars = Parser.Execute(tokens)
	if not status then self:Error(tree) return end

	if not self:PrepareIncludes(files) then return end

	local status, script, inst = Compiler.Execute(tree, self.inports[3], self.outports[3], self.persists[3], dvars, self.includes)
	if not status then self:Error(script) return end

	self.script = script
	self.dvars = inst.dvars
	self.tvars = inst.tvars
	self.funcs = inst.funcs
	self.funcs_ret = inst.funcs_ret
	self.globvars = inst.GlobalScope

	self:ResetContext()
end

function ENT:GetCode()
	return self.original, self.inc_files
end

function ENT:PrepareIncludes(files)

	self.inc_files = files

	self.includes = {}

	for file, buffer in pairs(files) do
		local status, directives, buffer = PreProcessor.Execute(buffer, self.directives)
		if not status then
			self:Error("(" .. file .. ")" .. directives)
			return
		end

		local status, tokens = Tokenizer.Execute(buffer)
		if not status then
			self:Error("(" .. file .. ")" .. tokens)
			return
		end

		local status, tree, dvars = Parser.Execute(tokens)
		if not status then
			self:Error("(" .. file .. ")" .. tree)
			return
		end

		self.includes[file] = { tree }
	end

	return true
end

function ENT:ResetContext()
	local context = {
		data = {},
		vclk = {}, -- Used only by arrays and tables!
		funcs = self.funcs,
		funcs_ret = self.funcs_ret,
		entity = self,
		player = self.player,
		uid = self.uid,
		prf = 0,
		prfcount = 0,
		prfbench = 0,
		time = 0,
		timebench = 0,
		includes = self.includes
	}

	setmetatable(context, ScopeManager)
	context:InitScope()

	self.context = context
	self.GlobalScope = context.GlobalScope
	self._vars = self.GlobalScope -- Dupevars

	self.Inputs = WireLib.AdjustSpecialInputs(self, self.inports[1], self.inports[2])
	self.Outputs = WireLib.AdjustSpecialOutputs(self, self.outports[1], self.outports[2])
	
	if self.extended then -- It was extended before the adjustment, recreate the wirelink
		WireLib.CreateWirelinkOutput( self.player, self, {true} )
	end
	
	self._original = string.Replace(string.Replace(self.original, "\"", string.char(163)), "\n", string.char(128))

	self._name = self.name
	self._inputs = { {}, {} }
	self._outputs = { {}, {} }

	for k, v in pairs(self.inports[3]) do
		self._inputs[1][#self._inputs[1] + 1] = k
		self._inputs[2][#self._inputs[2] + 1] = v
		self.GlobalScope[k] = copytype(wire_expression_types[v][2])
		self.globvars[k] = nil
	end

	for k, v in pairs(self.outports[3]) do
		self._outputs[1][#self._outputs[1] + 1] = k
		self._outputs[2][#self._outputs[2] + 1] = v
		self.GlobalScope[k] = copytype(wire_expression_types[v][2])
		self.GlobalScope.vclk[k] = true
		self.globvars[k] = nil
	end

	for k, v in pairs(self.persists[3]) do
		self.GlobalScope[k] = copytype(wire_expression_types[v][2])
		self.globvars[k] = nil
	end

	for k, v in pairs(self.globvars) do
		self.GlobalScope[k] = copytype(wire_expression_types2[v][2])
	end

	for k, v in pairs(self.Inputs) do
		if wire_expression_types[v.Type][3] then
			self.GlobalScope[k] = wire_expression_types[v.Type][3](self.context, v.Value)
		else
			self.GlobalScope[k] = v.Value
		end
	end

	for k, v in pairs(self.dvars) do
		self.GlobalScope["$" .. k] = self.GlobalScope[k]
	end

	self.error = false
end

function ENT:IsCodeDifferent(buffer, includes)
	-- First check the main file
	if self.original ~= buffer then return true end

	-- First compare one way
	for k, v in pairs(self.inc_files) do
		if includes[k] ~= v then return true end
	end

	-- Then compare the other way, too
	for k, v in pairs(includes) do
		if self.inc_files[k] ~= v then return true end
	end

	-- All code is identical.
	return false
end

function ENT:Setup(buffer, includes, restore, forcecompile, filepath)
	if self.script then
		self:PCallHook('destruct')
	end

	self.uid = IsValid(self.player) and self.player:UniqueID() or "World"
	self:SetColor(Color(255, 255, 255, self:GetColor().a))

	if forcecompile or self:IsCodeDifferent(buffer, includes) then
		self:CompileCode(buffer, includes, filepath)
		if self.error then
			self._original = string.Replace(string.Replace(self.original, "\"", string.char(163)), "\n", string.char(128))
			self._name = self.name
			self._inputs = { {}, {} }
			self._outputs = { {}, {} }
		end
	else
		self:ResetContext()
	end

	self:SetOverlayText(self.name)

	local ok, msg = pcall(self.CallHook, self, 'construct')
	if not ok then
		Msg("Construct hook(s) failed, executing destruct hooks...\n")
		local ok2, msg2 = pcall(self.CallHook, self, 'destruct')
		if ok2 then
			self:Error(msg .. "\nDestruct hooks succeeded.")
		else
			self:Error(msg .. "\n" .. msg2)
		end
		return
	end

	self.duped = false

	if not restore then
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
	timer.Simple(0, function() self.Setup(self, self.original, self.inc_files) end)
end

function ENT:TriggerInput(key, value)
	if self.error then return end
	if key and self.inports[3][key] then
		local t = self.inports[3][key]

		self.GlobalScope["$" .. key] = self.GlobalScope[key]
		if wire_expression_types[t][3] then
			self.GlobalScope[key] = wire_expression_types[t][3](self.context, value)
		else
			self.GlobalScope[key] = value
		end

		self.context.triggerinput = key
		if self.trigger[1] or self.trigger[2][key] then self:Execute() end
		self.context.triggerinput = nil
	end
end

function ENT:TriggerOutputs()
	for key, t in pairs(self.outports[3]) do
		if self.GlobalScope.vclk[key] or self.first then
			if wire_expression_types[t][4] then
				WireLib.TriggerOutput(self, key, wire_expression_types[t][4](self.context, self.GlobalScope[key]))
			else
				WireLib.TriggerOutput(self, key, self.GlobalScope[key])
			end
		end
	end
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	self:Setup(self.buffer, self.inc_files, true)

	if not self.error then
		for k, v in pairs(self.dupevars) do
			self.GlobalScope[k] = v
		end -- Rusketh Broke this :(
		--table.Merge(self.context.vars, self.dupevars)
		self.dupevars = nil

		self.duped = true
		self:Execute()
		self.duped = false
	end

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID, GetConstByID)
end

---------------------------------- Transfer ----------------------------------

--[[
	Player Disconnection Magic
--]]
local cvar = CreateConVar("wire_expression2_pause_on_disconnect", 0, 0, "Decides if chips should pause execution on their owner's disconnect.\n0 = no, 1 = yes, 2 = non-admins only.")
-- This is a global function so it can be overwritten for greater control over whose chips are frozenated
function wire_expression2_ShouldFreezeChip(ply)
	return not ply:IsAdmin()
end

-- It uses EntityRemoved because PlayerDisconnected doesn't catch all disconnects.
hook.Add("EntityRemoved", "Wire_Expression2_Player_Disconnected", function(ent)
	if (not (ent and ent:IsPlayer())) then
		return
	end
	local ret = cvar:GetInt()
	if (ret == 0 or (ret == 2 and not wire_expression2_ShouldFreezeChip(ent))) then
		return
	end
	for k, v in ipairs(ents.FindByClass("gmod_wire_expression2")) do
		if (v.player == ent) then
			v:SetOverlayText(v.name .. "\n(Owner disconnected.)")
			v:SetColor(Color(255, 0, 0, v:GetColor().a))
			v.disconnectPaused = { r, g, b, a }
			v.error = true
		end
	end
end)

hook.Add("PlayerAuthed", "Wire_Expression2_Player_Authed", function(ply, sid, uid)
	local c
	for _, ent in ipairs(ents.FindByClass("gmod_wire_expression2")) do
		if (ent.uid == uid) then
			ent.context.player = ply
			ent.player = ply
			ent:SetNWEntity("player", ply)
			if (ent.disconnectPaused) then
				c = ent.disconnectPaused
				ent:SetColor(Color(c[1], c[2], c[3], c[4]))
				ent:SetRenderMode(ent:GetColor().a == 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSALPHA)
				ent.error = false
				ent.disconnectPaused = false
				ent:SetOverlayText(ent.name)
			end
		end
	end
end)

function MakeWireExpression2(player, Pos, Ang, model, buffer, name, inputs, outputs, vars, inc_files, filepath)
	if not player then player = game.GetWorld() end -- For Garry's Map Saver
	if IsValid(player) and not player:CheckLimit("wire_expressions") then return false end

	local self = ents.Create("gmod_wire_expression2")
	if not self:IsValid() then return false end
	
	if buffer then self.duped = true end

	self:SetModel(model)
	self:SetAngles(Ang)
	self:SetPos(Pos)
	self:Spawn()
	self:SetPlayer(player)
	self.player = player
	self:SetNWEntity("player", player)

	if isstring( buffer ) then -- if someone dupes an E2 with compile errors, then all these values will be invalid
		buffer = string.Replace(string.Replace(buffer, string.char(163), "\""), string.char(128), "\n")
		self.buffer = buffer
		self:SetOverlayText(name)
		
		self.inc_files = inc_files or {}

		self.Inputs = WireLib.AdjustSpecialInputs(self, inputs[1], inputs[2])
		self.Outputs = WireLib.AdjustSpecialOutputs(self, outputs[1], outputs[2])

		self.dupevars = vars
		
		self.filepath = filepath
	else
		self.buffer = "error(\"You tried to dupe an E2 with compile errors!\")\n#Unfortunately, no code can be saved when duping an E2 with compile errors.\n#Fix your errors and try again."
		
		self.inc_files = {}
		self.dupevars = {}
		
		self.name = "generic"
	end

	if IsValid(player) then
		player:AddCount("wire_expressions", self)
		player:AddCleanup("wire_expressions", self)
	end
	return self
end
duplicator.RegisterEntityClass("gmod_wire_expression2", MakeWireExpression2, "Pos", "Ang", "Model", "_original", "_name", "_inputs", "_outputs", "_vars", "inc_files", "filepath")

--------------------------------------------------
-- Emergency shutdown (beta testing so far)
--------------------------------------------------
local average_ram = 0
local enable = CreateConVar( 
	"wire_expression2_ram_emergency_shutdown_enable", "0", {FCVAR_ARCHIVE}, 
	"Enable/disable the emergency shutdown feature. Requires map reload after change." )

local average_halt_multiplier = CreateConVar( 
	"wire_expression2_ram_emergency_shutdown_spike", "4", {FCVAR_ARCHIVE}, 
	"if (current_ram > average_ram * spike_convar) then shut down all E2s" )

local halt_max_amount = CreateConVar( 
	"wire_expression2_ram_emergency_shutdown_total", "512", {FCVAR_ARCHIVE}, 
	"This is in kilobytes, if (current_ram > total_convar) then shut down all E2s" )

if enable:GetBool() then
	hook.Remove( "Think", "wire_expression2_emergency_shutdown" ) -- remove old hook
	hook.Add( "Think", "wire_expression2_emergency_shutdown", function()
		local current_ram = collectgarbage("count")
		if average_ram == 0 then -- set up initial value
			average_ram = current_ram
		else
			-- calculate average
			average_ram = average_ram * 0.95 + current_ram * 0.05

			if current_ram > average_ram * average_halt_multiplier:GetFloat() or -- if the current ram spikes
				current_ram > halt_max_amount:GetInt() * 1000 then -- or if the current ram goes over a set limit

				local e2s = ents.FindByClass("gmod_wire_expression2") -- find all E2s and halt them
				for k,v in pairs( e2s ) do
					if not v.error then
						-- immediately clear any memory the E2 may be holding
						v:PCallHook("destruct")
						v:ResetContext()
						v:PCallHook("construct")

						-- Notify the user why we shut down
						v:Error( "High server RAM usage detected! Emergency E2 shutdown!" )
					end
				end
				collectgarbage() -- collect the garbage now
				average_ram = collectgarbage("count") -- reset average ram when we're done
			end
		end
	end)
end
