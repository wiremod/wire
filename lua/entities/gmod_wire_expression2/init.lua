AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

DEFINE_BASECLASS("base_wire_entity")

e2_softquota = nil
e2_hardquota = nil
e2_tickquota = nil
e2_timequota = nil

do
	local wire_expression2_unlimited = GetConVar("wire_expression2_unlimited")
	local wire_expression2_quotasoft = GetConVar("wire_expression2_quotasoft")
	local wire_expression2_quotahard = GetConVar("wire_expression2_quotahard")
	local wire_expression2_quotatick = GetConVar("wire_expression2_quotatick")
	local wire_expression2_quotatime = GetConVar("wire_expression2_quotatime")

	local function updateQuotas()
		if wire_expression2_unlimited:GetBool() then
			e2_softquota = 1000000
			e2_hardquota = 1000000
			e2_tickquota = 100000
			e2_timequota = -1
		else
			e2_softquota = wire_expression2_quotasoft:GetInt()
			e2_hardquota = wire_expression2_quotahard:GetInt()
			e2_tickquota = wire_expression2_quotatick:GetInt()
			e2_timequota = wire_expression2_quotatime:GetInt() * 0.001
		end
	end
	cvars.AddChangeCallback("wire_expression2_unlimited", updateQuotas)
	cvars.AddChangeCallback("wire_expression2_quotasoft", updateQuotas)
	cvars.AddChangeCallback("wire_expression2_quotahard", updateQuotas)
	cvars.AddChangeCallback("wire_expression2_quotatick", updateQuotas)
	cvars.AddChangeCallback("wire_expression2_quotatime", updateQuotas)
	updateQuotas()
end

local fixDefault = E2Lib.fixDefault


local ScopeManager = {}
ScopeManager.__index = ScopeManager
E2Lib.ScopeManager = ScopeManager

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

	self.name = "(generic)"
	self.Inputs = WireLib.CreateInputs(self, {})
	self.Outputs = WireLib.CreateOutputs(self, {})

	self.error = true
	self:UpdateOverlay(true)
	self:SetColor(Color(255, 0, 0, self:GetColor().a))
end

function ENT:OnRestore()
	self:Setup(self.original, self.inc_files, nil, true)
end

local SysTime = SysTime

function ENT:Destruct()
	self:PCallHook("destruct")

	for evt in pairs(self.registered_events) do
		if E2Lib.Env.Events[evt].destructor then
			-- If the event has a destructor to run when the E2 is removed and listening to the event.
			E2Lib.Env.Events[evt].destructor(self.context)
		end

		E2Lib.Env.Events[evt].listening[self] = nil
	end
end

function ENT:UpdatePerf()
	if not self.context then return end
	if self.error then return end
	
	self.context.prfbench = self.context.prfbench * 0.95 + self.context.prf * 0.05
	self.context.prfcount = self.context.prfcount + self.context.prf - e2_softquota
	self.context.timebench = self.context.timebench * 0.95 + self.context.time * 0.05 -- Average it over the last 20 ticks

	if self.context.prfcount < 0 then self.context.prfcount = 0 end

	self:UpdateOverlay()

	self.context.prf = 0
	self.context.time = 0

end

function ENT:Execute()
	if self.error or not self.context or self.context.resetting then return end

	self:PCallHook('preexecute')

	self.context:PushScope()

	local bench = SysTime()

	local ok, msg = pcall(self.script[1], self.context, self.script)

	if not ok then
		local _catchable, msg, trace = E2Lib.unpackException(msg)

		if msg == "exit" then
			self:UpdatePerf()
		elseif msg == "perf" then
			self:UpdatePerf()
			self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "tick quota exceeded")
		elseif trace then
			self:Error("Expression 2 (" .. self.name .. "): Runtime error '" .. msg .. "' at line " .. trace[1] .. ", char " .. trace[2], "script error")
		else
			self:Error("Expression 2 (" .. self.name .. "): " .. msg, "script error")
		end
	end

	self.context.time = self.context.time + (SysTime() - bench)

	self.context:PopScope()

	local forceTriggerOutputs = self.first or self.duped
	self.first = false -- if hooks call execute
	self.duped = false -- if hooks call execute
	self.context.triggerinput = nil -- if hooks call execute

	self:PCallHook('postexecute')

	self:TriggerOutputs(forceTriggerOutputs)

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
	for k, var in pairs(self.globvars_mut) do
		self.GlobalScope[k] = fixDefault(wire_expression_types2[var.type][2])
	end

	if self.context.prfcount + self.context.prf - e2_softquota > e2_hardquota then
		self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "hard quota exceeded")
	end

	if self.error then
		self:Destruct()
	end
end

---@param evt string
---@param args table?
function ENT:ExecuteEvent(evt, args)
	assert(evt, "Expected event name, got nil (or false)")
	if self.error or not self.context or self.context.resetting then return end

	local handlers = self.registered_events[evt]
	if not handlers then return end

	self:PCallHook("preexecute")

	for name, handler in pairs(handlers) do
		self.context:PushScope()

		local bench = SysTime()
		local ok, msg = pcall(handler, self.context, args)

	if not ok then
		local _catchable, msg, trace = E2Lib.unpackException(msg)

		if msg == "exit" then
			self:UpdatePerf()
		elseif msg == "perf" then
			self:UpdatePerf()
			self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "tick quota exceeded")
		elseif trace then
			self:Error("Expression 2 (" .. self.name .. "): Runtime error '" .. msg .. "' at line " .. trace[1] .. ", char " .. trace[2], "script error")
		else
			self:Error("Expression 2 (" .. self.name .. "): " .. msg, "script error")
		end
	end
		self.context.time = self.context.time + (SysTime() - bench)

		self.context:PopScope()
	end


	self.context.triggerinput = nil -- if hooks call execute

	self:PCallHook("postexecute")
	self:TriggerOutputs()

	self.GlobalScope.vclk = {}
	for k, var in pairs(self.globvars_mut) do
		self.GlobalScope[k] = fixDefault(wire_expression_types2[var.type][2])
	end

	if self.context.prfcount + self.context.prf - e2_softquota > e2_hardquota then
		self:Error("Expression 2 (" .. self.name .. "): tick quota exceeded", "hard quota exceeded")
	end

	if self.error then
		self:Destruct()
	end
end

function ENT:Think()
	BaseClass.Think(self)
	self:NextThink(CurTime() + 0.030303)
	
	if not self.context then return true end
	if self.error then return true end
	
	self:UpdatePerf()

	if self.context.prfcount < 0 then self.context.prfcount = 0 end

	self:UpdateOverlay()

	self.context.prf = 0
	self.context.time = 0

	if e2_timequota > 0 and self.context.timebench > e2_timequota then
		self:Error("Expression 2 (" .. self.name .. "): time quota exceeded", "time quota exceeded")
		self:PCallHook('destruct')
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
		self:Destruct()
	end

	BaseClass.OnRemove(self)
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
	self.lastResetOrError = CurTime()
	-- ErrorNoHalt(message .. "\n")
	WireLib.ClientError(message, self.player)
end

function ENT:CompileCode(buffer, files, filepath)
	self.original = buffer
	if filepath then -- filepath may have already been set from the dupe function
		self.filepath = filepath
	end

	local status, directives, buffer = E2Lib.PreProcessor.Execute(buffer,nil,self)
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

	local status, tokens = E2Lib.Tokenizer.Execute(self.buffer)
	if not status then self:Error(tokens) return end

	local status, tree, dvars = E2Lib.Parser.Execute(tokens)
	if not status then self:Error(tree) return end

	if not self:PrepareIncludes(files) then return end

	status,tree = E2Lib.Optimizer.Execute(tree)
	if not status then self:Error(tree) return end

	local status, script, inst = E2Lib.Compiler.Execute(tree, self.inports, self.outports, self.persists, dvars, self.includes)
	if not status then self:Error(script) return end

	self.script = script
	self.registered_events = inst.registered_events

	self.dvars = inst.dvars
	self.funcs = inst.funcs
	self.funcs_ret = inst.funcs_ret
	self.globvars_mut = table.Copy(inst.GlobalScope) -- table.Copy because we will mutate this
	self.globvars = inst.GlobalScope

	self:ResetContext()
end

function ENT:GetGateName()
	return self.name
end

function ENT:GetCode()
	return self.original, self.inc_files
end

function ENT:PrepareIncludes(files)

	self.inc_files = files

	self.includes = {}

	for file, buffer in pairs(files) do
		local status, directives, buffer = E2Lib.PreProcessor.Execute(buffer, self.directives)
		if not status then
			self:Error("(" .. file .. ")" .. directives)
			return
		end

		local status, tokens = E2Lib.Tokenizer.Execute(buffer)
		if not status then
			self:Error("(" .. file .. ")" .. tokens)
			return
		end

		local status, tree, dvars = E2Lib.Parser.Execute(tokens)
		if not status then
			self:Error("(" .. file .. ")" .. tree)
			return
		end

		status, tree = E2Lib.Optimizer.Execute(tree)
		if not status then
			self:Error("(" .. file .. ")" .. tree)
			return
		end

		self.includes[file] = { tree }
	end

	return true
end

function ENT:ResetContext()
	local resetPrfMult = 1
	if self.lastResetOrError then
		-- reduces all the opcounters based on the time passed since 
		-- the last time the chip was reset or errored
		-- waiting up to 30s before resetting results in a 0.1 multiplier 
		local passed = CurTime() - self.lastResetOrError
		resetPrfMult = math.max(0.1, (30 - passed) / 30)
	end
	self.lastResetOrError = CurTime()

	local context = {
		data = {},
		vclk = {},
		funcs = self.funcs,
		funcs_ret = self.funcs_ret,
		entity = self,
		player = self.player,
		uid = self.uid,
		prf = (self.context and (self.context.prf * resetPrfMult)) or 0,
		prfcount = (self.context and (self.context.prfcount * resetPrfMult)) or 0,
		prfbench = (self.context and (self.context.prfbench * resetPrfMult)) or 0,
		time = (self.context and (self.context.time * resetPrfMult)) or 0,
		timebench = (self.context and (self.context.timebench * resetPrfMult)) or 0,
		includes = self.includes
	}

	-- '@strict' try/catch Error handling.
	if self.directives.strict then
		local err = E2Lib.raiseException
		function context:throw(msg)
			err(msg, 2, self.trace)
		end
	else
		-- '@strict' is not enabled, pass the default variable.
		function context:throw(_msg, variable)
			return variable
		end
	end

	setmetatable(context, ScopeManager)
	context:InitScope()

	self.context = context
	self.GlobalScope = context.GlobalScope
	self._vars = self.GlobalScope -- Dupevars

	self.Inputs = WireLib.AdjustSpecialInputs(self, self.inports[1], self.inports[2], self.inports[4])
	self.Outputs = WireLib.AdjustSpecialOutputs(self, self.outports[1], self.outports[2], self.outports[4])

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
		self.GlobalScope[k] = fixDefault(wire_expression_types[v][2])
		self.globvars_mut[k] = nil
	end

	for k, v in pairs(self.outports[3]) do
		self._outputs[1][#self._outputs[1] + 1] = k
		self._outputs[2][#self._outputs[2] + 1] = v
		self.GlobalScope[k] = fixDefault(wire_expression_types[v][2])
		self.GlobalScope.vclk[k] = true
		self.globvars_mut[k] = nil
	end

	for k, v in pairs(self.persists[3]) do
		self.GlobalScope[k] = fixDefault(wire_expression_types[v][2])
		self.globvars_mut[k] = nil
	end

	for k, var in pairs(self.globvars_mut) do
		self.GlobalScope[k] = fixDefault(wire_expression_types2[var.type][2])
	end

	for k, v in pairs(self.Inputs) do
		if wire_expression_types[v.Type][3] then
			self.GlobalScope[k] = wire_expression_types[v.Type][3](self.context, v.Value)
		else
			self.GlobalScope[k] = v.Value
		end
	end

	for k, _ in pairs(self.dvars) do
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
		self:Destruct()
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
		self:Think()
	end

	-- Register events only after E2 has executed once
	for evt, _ in pairs(self.registered_events) do
		if E2Lib.Env.Events[evt].constructor then
			-- If the event has a constructor to run when the E2 is made and listening to the event.
			E2Lib.Env.Events[evt].constructor(self.context)
		end
		E2Lib.Env.Events[evt].listening[self] = true
	end

	self:NextThink(CurTime())
end

function ENT:Reset()
	-- prevent E2 from executing anything
	self.context.resetting = true

	-- reset the chip in the next tick
	timer.Simple(0, function()
		if IsValid(self) then
			self:Setup(self.original, self.inc_files)
		end
	end)
end

function ENT:TriggerInput(key, value)
	if self.error then return end
	if key and self.inports and self.inports[3][key] then
		local t = self.inports[3][key]

		self.GlobalScope["$" .. key] = self.GlobalScope[key]
		if wire_expression_types[t][3] then
			self.GlobalScope[key] = wire_expression_types[t][3](self.context, value)
		else
			self.GlobalScope[key] = value
		end

		self.context.triggerinput = key
		if self.trigger[1] or self.trigger[2][key] then
			self:Execute()
			self:ExecuteEvent("input", { key })
		end
		self.context.triggerinput = nil
	end
end

function ENT:TriggerOutputs(force)
	for key, t in pairs(self.outports[3]) do
		if self.GlobalScope.vclk[key] or force then
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
			-- Backwards compatibility to fix dupes with the old {n, n, n} angle and vector types
			local vartype = self.globvars[k] and self.globvars[k].type
			if vartype == "a" then
				self.GlobalScope[k] = istable(v) and Angle(v[1], v[2], v[3]) or v
			elseif vartype == "v" then
				self.GlobalScope[k] = istable(v) and Vector(v[1], v[2], v[3]) or v
			else
				self.GlobalScope[k] = v
			end
		end
		self.dupevars = nil

		self.duped = true
		self:Execute()
		self:Think()
		self.duped = false
	end

	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID, GetConstByID)
end

-- -------------------------------- Transfer ----------------------------------

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
	for _, v in ipairs(ents.FindByClass("gmod_wire_expression2")) do
		if (v.player == ent) then
			v:SetOverlayText(v.name .. "\n(Owner disconnected.)")
			local oldColor = v:GetColor()
			v:SetColor(Color(255, 0, 0, v:GetColor().a))
			v.disconnectPaused = oldColor
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
			ent:SetPlayer(ply)

			if ent.disconnectPaused then
				ent:SetColor(ent.disconnectPaused)
				ent:SetRenderMode(ent:GetColor().a == 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSALPHA)
				ent.error = false
				ent.disconnectPaused = nil
				ent:SetOverlayText(ent.name)
			end
		end
	end
	for _, ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
		if ent.steamid == sid then
			ent:SetPlayer(ply)
		end
	end
end)

function MakeWireExpression2(player, Pos, Ang, model, buffer, name, inputs, outputs, vars, inc_files, filepath, codeAuthor)
	if not player then player = game.GetWorld() end -- For Garry's Map Saver
	if IsValid(player) and not player:CheckLimit("wire_expressions") then return false end
	if not WireLib.CanModel(player, model) then return false end

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

		-- Check codeAuthor actually exists, it wont be present on old dupes
		-- No need to check if buffer already has a dupe related #error directive, as chips with compiler errors can't be duped
		--[[
		if codeAuthor and player:SteamID() ~= codeAuthor.steamID then
			buffer = string.format(
				"#error Dupe pasted with code authored by %s (%s). Please review the contents of the E2 before removing this directive\n\n",
				codeAuthor.name, codeAuthor.steamID
			) .. buffer
		end
		--]]

		self.buffer = buffer
		self:SetOverlayText(name)

		self.Inputs = WireLib.AdjustSpecialInputs(self, inputs[1], inputs[2])
		self.Outputs = WireLib.AdjustSpecialOutputs(self, outputs[1], outputs[2])

		self.inc_files = inc_files or {}
		self.dupevars = vars or {}

		self.filepath = filepath
	else
		self.buffer = "#error You tried to dupe an E2 with compile errors!\n#Unfortunately, no code can be saved when duping an E2 with compile errors.\n#Fix your errors and try again."

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
duplicator.RegisterEntityClass("gmod_wire_expression2", MakeWireExpression2, "Pos", "Ang", "Model", "_original", "_name", "_inputs", "_outputs", "_vars", "inc_files", "filepath", "code_author")

--------------------------------------------------
-- Emergency shutdown (beta testing so far)
--------------------------------------------------
local average_ram = 0
local enable = CreateConVar(
	"wire_expression2_ram_emergency_shutdown_enable", "0", {FCVAR_ARCHIVE},
	"Enable/disable the emergency shutdown feature." )

local average_halt_multiplier = CreateConVar(
	"wire_expression2_ram_emergency_shutdown_spike", "4", {FCVAR_ARCHIVE},
	"if (current_ram > average_ram * spike_convar) then shut down all E2s" )

local halt_max_amount = CreateConVar(
	"wire_expression2_ram_emergency_shutdown_total", "512", {FCVAR_ARCHIVE},
	"This is in kilobytes, if (current_ram > total_convar) then shut down all E2s" )

local function enableEmergencyShutdown()
	hook.Remove( "Think", "wire_expression2_emergency_shutdown" ) -- remove old hook
	if enable:GetBool() then
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
					for _,v in ipairs( e2s ) do
						if not v.error then
							-- immediately clear any memory the E2 may be holding
							hook.Run("Wire_EmergencyRamClear")
							v:Destruct()
							v:ResetContext()
							v:PCallHook("construct")

							-- Notify the user why we shut down
							v:Error( "High server RAM usage detected! Emergency E2 shutdown!" )
						end
					end
					collectgarbage() -- collect the garbage now
					timer.Simple(0,collectgarbage) -- timers fix everything
					average_ram = collectgarbage("count") -- reset average ram when we're done
				end
			end
		end)
	end
end

enableEmergencyShutdown()
cvars.AddChangeCallback( "wire_expression2_ram_emergency_shutdown_enable", enableEmergencyShutdown )
