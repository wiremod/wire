include("shared.lua")
include("huddraw.lua")

ENT.gmod_wire_egp_hud = true

function ENT:GetEGPMatrix()
	return Matrix()
end


function ENT:Initialize()
	self.RenderTable = {}
end

function ENT:GetEGPMatrix()
	return Matrix()
end

local makeArray
local makeTable
if EGP then -- If the table has been loaded
	makeArray = EGP.ParentingFuncs.makeArray
	makeTable = EGP.ParentingFuncs.makeTable
else -- If the table hasn't been loaded
	hook.Add("Initialize",function()
		makeArray = EGP.ParentingFuncs.makeArray
		makeTable = EGP.ParentingFuncs.makeTable
	end)
end

local function scaleObject(bool, v)
	local xMin, xMax, yMin, yMax, _xMul, _yMul
	if (bool) then -- 512 -> screen
		xMin = 0
		xMax = 512
		yMin = 0
		yMax = 512
		_xMul = ScrW()
		_yMul = ScrH()
	else -- screen -> 512
		xMin = 0
		xMax = ScrW()
		yMin = 0
		yMax = ScrH()
		_xMul = 512
		_yMul = 512
	end

	local xMul = _xMul/(xMax-xMin)
	local yMul = _yMul/(yMax-yMin)

	if v.verticesindex then
		local r = makeArray(v, true)
		for i=1,#r,2 do
			r[i] = (r[i] - xMin) * xMul
			r[i+1] = (r[i+1]- yMin) * yMul
		end
		local settings = {}
		if isstring(v.verticesindex) then settings = { [v.verticesindex] = makeTable( v, r ) } else settings = makeTable( v, r ) end
		EGP:EditObject(v, settings)
	else
		if v.x then
			v.x = (v.x - xMin) * xMul
		end
		if v.y then
			v.y = (v.y - yMin) * yMul
		end
		if v.w then
			v.w = v.w * xMul
		end
		if v.h then
			v.h = v.h * yMul
		end
	end

	v.res = bool
end

function ENT:EGP_Update()
	for _, v in ipairs(self.RenderTable) do
		if v.res ~= self:GetNWBool("Resolution", false) then
			scaleObject(not v.res, v)
		end
	end
end

function ENT:DrawEntityOutline() end

function ENT:Draw()
	self:DrawModel()
	Wire_Render(self)
end
