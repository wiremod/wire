-- a variable inside a single if-branch is discarded, even though that type should be forced for any consecutive assignments

resource.AddFile("materials/expression 2/cog.vmt")
resource.AddFile("materials/expression 2/cog.vtf")

AddCSLuaFile('init.lua')
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
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Inputs = WireLib.CreateInputs(self.Entity, {})
	self.Outputs = WireLib.CreateOutputs(self.Entity, {})

	self:SetOverlayText("Expression 2\n(none)")
	self:SetColor(255, 0, 0, 255)
end

function ENT:OnRestore()
	self:Setup(self.original)
end

function ENT:Execute()
	if self.error then return end
	if self.context.resetting then return end

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
	self.Entity:NextThink(CurTime())

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
	if not self.error then -- make sure destruct hooks aren't called twice (once on error, once on remove)
		self.error = true
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
	self:SetColor(255, 0, 0, 255)

	self.error = true
	ErrorNoHalt(message .. "\n")
	WireLib.ClientError(message, self.player)
end

local function copytype(var)
	if type(var) == "table" then
		return table.Copy(var)
	else
		return var
	end
end

function ENT:Setup(buffer, restore)
	if self.script then
		self:PCallHook('destruct')
	end

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

	self.inports = directives.inputs
	self.outports = directives.outputs
	self.persists = directives.persist
	self.trigger = directives.trigger

	local status, tokens = Tokenizer.Execute(self.buffer)
	if not status then self:Error(tokens) return end

	local status, tree, dvars = Parser.Execute(tokens)
	if not status then self:Error(tree) return end

	local status, script, dvars = Compiler.Execute(tree, self.inports[3], self.outports[3], self.persists[3], dvars)
	if not status then self:Error(script) return end

	self:SetOverlayText("Expression 2\n" .. self.name)
	self:SetColor(255, 255, 255, 255)



	self.Inputs = WireLib.AdjustSpecialInputs(self.Entity, self.inports[1], self.inports[2])
	self.Outputs = WireLib.AdjustSpecialOutputs(self.Entity, self.outports[1], self.outports[2])

	self.script = script

	self.context = {
		vars = {},
		vclk = {},
		data = {},
		entity = self,
		player = self.player,
		prf = 0,
		prfcount = 0,
		prfbench = 0,
	}

	self._original = string.Replace(string.Replace(self.original,"\"","£"),"\n","€")
	self._buffer = self.original -- TODO: is that really intended?

	self._name = self.name
	self._inputs = { {}, {} }
	self._outputs = { {}, {} }
	self._vars = self.context.vars

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

	for k,v in pairs(dvars) do
		self.context.vars["$" .. k] = self.context.vars[k]
	end

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

	self.Entity:NextThink(CurTime())
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
				WireLib.TriggerOutput(self.Entity, key, wire_expression_types[t][4](self.context, self.context.vars[key]))
			else
				WireLib.TriggerOutput(self.Entity, key, self.context.vars[key])
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
	if self:GetPlayer() ~= ply and wire_expression2_protected:GetFloat() ~= 0 and wire_expression2_protected:GetFloat() ~= 2 then return end
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

local buffer = {}

function ENT:Prepare(player)
	local ID = player:UserID()
	buffer[ID] = {}
	buffer[ID].ent = self
end

concommand.Add("wire_expression_upload_begin", function(player, command, args)
	local ID = player:UserID()
	buffer[ID].text = ""
	buffer[ID].len = tonumber(args[1])
	buffer[ID].chunk = 0
	buffer[ID].chunks = tonumber(args[2])
	buffer[ID].ent:SetOverlayText("Expression 2\n(transferring)")
	buffer[ID].ent:SetColor(0, 255, 0, 255)
end)

concommand.Add("wire_expression_upload_data", function(player, command, args)
	local ID = player:UserID()

	if not buffer[ID].text or not buffer[ID].chunk then
		--Msg("buffer does not exist! Player="..tostring(player).." chunk="..args[1].."\n")
		return
	end

	buffer[ID].text = buffer[ID].text .. args[1]
	buffer[ID].chunk = buffer[ID].chunk + 1

	local percent = math.Round((buffer[ID].chunk / buffer[ID].chunks) * 100)
end)

concommand.Add("wire_expression_upload_end", function(player, command, args)
	local ID = player:UserID()

	local buf = buffer[ID]
	buffer[ID] = nil

	local ent = buf.ent
	if not ValidEntity(ent) then return end

	if not buf.text then
		-- caused by concurrent download from the same chip
		ent:SetOverlayText("Expression 2\n(transfer error)")
		ent:SetColor(255, 0, 0, 255)
	end

	local decoded = E2Lib.decode(buf.text or "")
	if(decoded:len() != buf.len) then
		ent:SetOverlayText("Expression 2\n(transfer error)")
		ent:SetColor(255, 0, 0, 255)
	else
		ent:Setup(decoded)
		ent.player = player
	end
end)
