include('shared.lua')
include("HUDDraw.lua")

--------------------------------------------------------
-- 0-512 to screen res & back
--------------------------------------------------------

local makeArray = EGP.ParentingFuncs.makeArray
local makeTable = EGP.ParentingFuncs.makeTable

function ENT:ScaleObject( bool, v )
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
	--print("bool " .. tostring(bool))
	--print("-------------------------------")
	--PrintTable(v)
	--print("-------------------------------")

	local xMul = _xMul/(xMax-xMin)
	local yMul = _yMul/(yMax-yMin)

	if (v.verticesindex) then -- Object has vertices
		local r = makeArray( v, true )
		for i=1,#r,2 do
			r[i] = (r[i] - xMin) * xMul
			r[i+1] = (r[i+1]- yMin) * yMul
		end
		local settings = {}
		if (type(v.verticesindex) == "string") then settings = { [v.verticesindex] = makeTable( v, r ) } else settings = makeTable( v, r ) end
		EGP:EditObject( v, settings )
	else
		if (v.x) then
			v.x = (v.x - xMin) * xMul
		end
		if (v.y) then
			v.y = (v.y - yMin) * yMul
		end
		if (v.w) then
			v.w = v.w * xMul
		end
		if (v.h) then
			v.h = v.h * yMul
		end
	end

	v.res = bool


	--print("-------------------------------")
	--PrintTable(v)
	--print("-------------------------------")
end

--------------------------------------------------------
-- screen res to 0-512
--------------------------------------------------------


--[[
local function to512( n, n2 )
	return n / n2 * 512--n / 512 * n2
end

local function toScreenRes( n, n2 )
	return n / 512 * n2--n / n2 * 512
end

function ENT:ChangePositions( Obj, bool )
	local w, h = ScrW(), ScrH()

	local func
	if (bool) then
		func = to512
	else
		func = toScreenRes
	end

	if (Obj.x) then Obj.x = func(Obj.x,w) end
	if (Obj.y) then Obj.y = func(Obj.y,h) end
	if (Obj.x2) then Obj.x2 = func(Obj.x2,w) end
	if (Obj.y2) then Obj.y2 = func(Obj.y2,h) end
	if (Obj.x3) then Obj.x3 = func(Obj.x3,w) end
	if (Obj.y3) then Obj.y3 = func(Obj.y3,h) end
	if (Obj.vertices) then
		for k,v in ipairs( Obj.vertices ) do
			v.x = func(v.x,w)
			v.y = func(v.y,h)
		end
	end
	if (Obj.size and Obj.ID != EGP.Objects.Names["Text"] and Obj.ID != EGP.Objects.Names["TextLayout"]) then
		if (bool) then
			Obj.size = Obj.size/512*math.sqrt(w^2+h^2)
		else
			Obj.size = Obj.size/math.sqrt(w^2+h^2)*512
		end
	end

	if (Obj.w) then Obj.w = func(Obj.w,w) end
	if (Obj.h) then Obj.h = func(Obj.h,h) end

	Obj.res = bool
end
]]

function ENT:Initialize()
	self.RenderTable = {}
	self.Resolution = false -- False = Use screen res. True = 0-512 res.
	self.OldResolution = false

	EGP:AddHUDEGP( self )
end

function ENT:EGP_Update()
	for k,v in ipairs( self.RenderTable ) do
		if (v.res == nil) then v.res = false end
		if (v.res != self.Resolution) then
			self:ScaleObject( !v.res, v )
		end
		if (v.parent and v.parent != 0) then
			if (!v.IsParented) then EGP:SetParent( self, v.index, v.parentindex ) end
			local _, data = EGP:GetGlobalPos( self, v.index )
			EGP:EditObject( v, data )
		elseif (!v.parent or v.parent == 0 and v.IsParented) then
			EGP:UnParent( self, v.index )
		end
	end
	self.OldResolution = self.Resolution
end

function ENT:OnRemove()
	EGP:RemoveHUDEGP( self )
end

function ENT:Draw()
	self.Resolution = self:GetNWBool("Resolution",false)
	if (self.Resolution != self.OldResolution) then
		self:EGP_Update()
	end
	self.Entity.DrawEntityOutline = function() end
	self.Entity:DrawModel()
	Wire_Render(self.Entity)
end
