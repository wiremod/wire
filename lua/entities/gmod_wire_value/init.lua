
ParseType = {}

function ParseType.NORMAL(v)
	return tonumber(v) or 0
end

function ParseType.STRING(v)
	return v
end

local pat = {}

do
	local patstart = "^ *[([]? *"
	local patelement = "([^()[%],; /]+)"
	local patsep = " *[,; /] *"
	local patend = " *[)%]]? *$"

	local cur = patelement
	pat[1] = patstart..cur..patend
	for i=2,16 do
		cur = cur..patsep..patelement
		pat[i] = patstart..cur..patend
	end
end

function ParseType.VECTOR2(v)
	local x,y = string.match(v, pat[2])
	if not x then return { 0, 0 } end
	return { tonumber(x) or 0, tonumber(y) or 0}
end

function ParseType.VECTOR(v)
	local x,y,z = string.match(v, pat[3])
	if not x then return Vector(0, 0, 0) end
	return Vector(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
end

function ParseType.VECTOR4(v)
	local x,y,z,w = string.match(v, pat[4])
	if not x then return { 0, 0, 0, 0 } end
	return { tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0, tonumber(w) or 0 }
end

function ParseType.ANGLE(v)
	local p,y,r = string.match(v, pat[3])
	if not p then return Angle(0, 0, 0) end
	return Angle(tonumber(p) or 0, tonumber(y) or 0, tonumber(r) or 0)
end



AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Value"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

function ENT:Setup(values)
	self.value = values -- for advdupe
	values = table.Copy(values)

	local adjoutputs, adjtypes = {}, {}
	for k,v in pairs(values) do
		local tp,value = string.match(v, "^ *([^: ]+) *:(.*)$")

		if tp then
			tp = tp:upper()
			v = value
			if not ParseType[tp] then
				tp = "STRING"
				v = "Invalid type \""..tp.."\"."
			end
		else
			tp = "NORMAL"
		end
		--print(k,v,tp)

		values[k] = v
		adjoutputs[k] = "Value"..tostring(k)
		adjtypes[k] = tp
	end

	// this is where storing the values as strings comes in: they are the descriptions for the inputs.
	WireLib.AdjustSpecialOutputs(self, adjoutputs, adjtypes, values)

	local txt = ""
	self.Memory = {}

	for k,v in pairs(values) do
		//line break after 4 values
		//if (k == 5) or (k == 9) then txt = txt.."\n" end
		txt = txt .. k .. ": " .. v
		if (k < #values) then txt = txt .. "\n" end

		local tp = adjtypes[k]
		v = ParseType[tp](v)

		if tp == "NORMAL" then self.Memory[k] = v end
		Wire_TriggerOutput(self, adjoutputs[k], v)
	end

	self:SetOverlayText(txt)

end


function ENT:ReadCell( Address )
	return self.value[Address+1]
end
