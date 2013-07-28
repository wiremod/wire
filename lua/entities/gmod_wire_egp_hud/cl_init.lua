include('shared.lua')
include("HUDDraw.lua")

ENT.gmod_wire_egp_hud = true

--------------------------------------------------------
-- 0-512 to screen res & back
--------------------------------------------------------

local makeArray
local makeTable
if (EGP) then -- If the table has been loaded
	makeArray = EGP.ParentingFuncs.makeArray
	makeTable = EGP.ParentingFuncs.makeTable
else -- If the table hasn't been loaded
	hook.Add("Initialize",function()
		makeArray = EGP.ParentingFuncs.makeArray
		makeTable = EGP.ParentingFuncs.makeTable
	end)
end

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

	local xMul = _xMul/(xMax-xMin)
	local yMul = _yMul/(yMax-yMin)

	if (v.verticesindex) then -- Object has vertices
		local r = makeArray( v, true )
		for i=1,#r,2 do
			r[i] = (r[i] - xMin) * xMul
			r[i+1] = (r[i+1]- yMin) * yMul
		end
		local settings = {}
		if isstring(v.verticesindex) then settings = { [v.verticesindex] = makeTable( v, r ) } else settings = makeTable( v, r ) end
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
end

function ENT:Initialize()
	self.RenderTable = {}
	self.Resolution = false -- False = Use screen res. True = 0-512 res.
	self.OldResolution = false

	EGP:AddHUDEGP( self )
end

function ENT:EGP_Update()
	for k,v in pairs( self.RenderTable ) do
		if (v.res == nil) then v.res = false end
		if (v.res != self.Resolution) then
			self:ScaleObject( !v.res, v )
		end
		if (v.parent and v.parent != 0) then
			if (!v.IsParented) then EGP:SetParent( self, v.index, v.parent ) end
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

function ENT:DrawEntityOutline() end

function ENT:Draw()
	self.Resolution = self:GetNWBool("Resolution",false)
	if (self.Resolution != self.OldResolution) then
		self:EGP_Update()
	end
	self:DrawModel()
	Wire_Render(self)
end
