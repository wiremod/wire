include('shared.lua')
include('huddraw.lua')

ENT.gmod_wire_egp_hud = true

--------------------------------------------------------
-- 0-512 to screen res & back
--------------------------------------------------------

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

function ENT:GetEGPMatrix()
	return Matrix()
end

function ENT:ScaleObject(bool, obj)
	local xMin, xMax, yMin, yMax, _xMul, _yMul
	if bool then -- 512 -> screen
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

	local xMul = _xMul / (xMax - xMin)
	local yMul = _yMul / (yMax - yMin)

	if obj.verticesindex then -- Object has vertices
		local r = makeArray(obj, true)
		for i = 1, #r, 2 do
			r[i] = (r[i] - xMin) * xMul
			r[i + 1] = (r[i + 1]- yMin) * yMul
		end
		local settings = {}
		if isstring(obj.verticesindex) then settings = { [obj.verticesindex] = makeTable(obj, r) } else settings = makeTable(obj, r) end
		EGP:EditObject(obj, settings)
	else
		if (obj.x) then
			obj.x = (obj.x - xMin) * xMul
		end
		if (obj.y) then
			obj.y = (obj.y - yMin) * yMul
		end
		if (obj.w) then
			obj.w = obj.w * xMul
		end
		if (obj.h) then
			obj.h = obj.h * yMul
		end
	end

	obj.res = bool
end

function ENT:Initialize()
	self.RenderTable = {}
	self.RenderTable_Indices = {}
	self.Resolution = false -- False = Use screen res. True = 0-512 res.
	self.OldResolution = false

	EGP:AddHUDEGP(self)
end

function ENT:EGP_Update()
	for k, v in ipairs(self.RenderTable) do
		if (v.res == nil) then v.res = false end
		if (v.res ~= self.Resolution) then
			self:ScaleObject(not v.res, v)
		end
		if v.parent ~= 0 then
			if not v.IsParented then EGP:SetParent(self, v.index, v.parent) end
			local _, data = EGP:GetGlobalPos(self, v.index)
			EGP:EditObject(v, data)
		elseif v.IsParented then -- IsParented but no parent
			EGP:UnParent(self, v)
		end
	end
	self.OldResolution = self.Resolution
end

function ENT:DrawEntityOutline() end

function ENT:Draw()
	self.Resolution = self:GetNWBool("Resolution", false)
	if self.Resolution ~= self.OldResolution then
		self:EGP_Update()
	end
	self:DrawModel()
	Wire_Render(self)
end
