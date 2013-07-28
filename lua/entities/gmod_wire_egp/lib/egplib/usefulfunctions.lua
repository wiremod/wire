--------------------------------------------------------
-- e2function Helper functions
--------------------------------------------------------
local EGP = EGP

----------------------------
-- Table IsEmpty
----------------------------

function EGP:Table_IsEmpty( tbl ) return next(tbl) == nil end

----------------------------
-- SetScale
----------------------------

function EGP:SetScale( ent, x, y )
	if (!self:ValidEGP( ent ) or !x or !y) then return end
	ent.xScale = { x[1], x[2] }
	ent.yScale = { y[1], y[2] }
	if (x[1] != 0 or x[2] != 512 or y[1] != 0 or y[2] != 512) then
		ent.Scaling = true
	else
		ent.Scaling = false
	end
end

--------------------------------------------------------
-- Scaling functions
--------------------------------------------------------

local makeArray
local makeTable
local addUV
hook.Add("Initialize","EGP_WaitForParentingFile",function()
	makeArray = EGP.ParentingFuncs.makeArray
	makeTable = EGP.ParentingFuncs.makeTable
	addUV	  = EGP.ParentingFuncs.addUV
end)

function EGP:ScaleObject( ent, v )
	if (!self:ValidEGP( ent )) then return end
	local xScale = ent.xScale
	local yScale = ent.yScale
	if (!xScale or !yScale) then return end

	local xMin = xScale[1]
	local xMax = xScale[2]
	local yMin = yScale[1]
	local yMax = yScale[2]

	local xMul = 512/(xMax-xMin)
	local yMul = 512/(yMax-yMin)

	if (v.verticesindex) then -- Object has vertices
		local r = makeArray( v, true )
		for i=1,#r,2 do
			r[i] = (r[i] - xMin) * xMul
			r[i+1] = (r[i+1]- yMin) * yMul
		end
		local settings = makeTable(v, r)
		addUV(v, settings)
		if isstring(v.verticesindex) then settings = { [v.verticesindex] = settings } end
		self:EditObject( v, settings )
	else
		if (v.x) then
			v.x = (v.x - xMin) * xMul
		end
		if (v.y) then
			v.y = (v.y - yMin) * yMul
		end
		if (v.w) then
			v.w = math.abs(v.w * xMul)
		end
		if (v.h) then
			v.h = math.abs(v.h * yMul)
		end
	end
end

--------------------------------------------------------
-- Draw from top left
--------------------------------------------------------

function EGP:MoveTopLeft( ent, v )
	if (!self:ValidEGP( ent )) then return end

	if (v.CanTopLeft and v.x and v.y and v.w and v.h) then
		local vec, ang = LocalToWorld( Vector( v.w/2, v.h/2, 0 ), Angle(0,0,0), Vector( v.x, v.y, 0 ), Angle( 0, -v.angle or 0, 0 ) )
		local t = { x = vec.x, y = vec.y }
		if (v.angle) then t.angle = -ang.yaw end
		self:EditObject( v, t )
	end
end

----------------------------
-- IsDifferent check
----------------------------
function EGP:IsDifferent( tbl1, tbl2 )
	if (self:Table_IsEmpty( tbl1 ) != self:Table_IsEmpty( tbl2 )) then return true end -- One is empty, the other is not

	for k,v in ipairs( tbl1 ) do
		if (!tbl2[k] or tbl2[k].ID != v.ID) then -- Different ID?
			return true
		else
			for k2,v2 in pairs( v ) do
				if (k2 != "BaseClass") then
					if (tbl2[k][k2] or tbl2[k][k2] != v2) then -- Is any setting different?
						return true
					end
				end
			end
		end
	end

	for k,v in ipairs( tbl2 ) do -- Were any objects removed?
		if (!tbl1[k]) then
			return true
		end
	end

	return false
end


----------------------------
-- IsAllowed check
----------------------------
function EGP:IsAllowed( E2, Ent )
	if (!EGP:ValidEGP( Ent )) then return false end
	if (E2 and E2.entity and E2.entity:IsValid()) then
		local owner = Ent:GetEGPOwner()
		if (E2.player != owner) then
			return E2Lib.isFriend(E2.player,Ent:GetEGPOwner())
		else
			return true
		end
	end
	return false
end

--------------------------------------------------------
-- Transmitting / Receiving helper functions
--------------------------------------------------------
-----------------------
-- Material
-----------------------

function EGP:SendMaterial( obj ) -- ALWAYS use this when sending material
	local mat = obj.material
	if isstring(mat) then
		util.AddNetworkString( "0" .. mat )
		net.WriteString( "0" .. mat ) -- 0 for string
	elseif isentity(mat) then
		net.WriteString( "1" .. mat:EntIndex() ) -- 1 for entity
	end
end

function EGP:ReceiveMaterial( tbl ) -- ALWAYS use this when receiving material
	local temp = net.ReadString()
	local what, mat = temp:sub(1,1), temp:sub(2)
	if what == "0" then
		if mat == "" then
			tbl.material = false
		else
			tbl.material = Material(mat)
		end
	elseif what == "1" then
		local num = tonumber(mat)
		if not num or not IsValid(Entity(num)) then
			tbl.material = false
		else
			tbl.material = Entity(num)
		end
	end
end

-----------------------
-- Other
-----------------------
function EGP:SendPosSize( obj )
	net.WriteInt( obj.w, 16 )
	net.WriteInt( obj.h, 16 )
	net.WriteInt( obj.x, 16 )
	net.WriteInt( obj.y, 16 )
end

function EGP:SendColor( obj )
	net.WriteUInt(obj.r, 8)
	net.WriteUInt(obj.g, 8)
	net.WriteUInt(obj.b, 8)
	if (obj.a) then net.WriteUInt(obj.a, 8) end
end

function EGP:ReceivePosSize( tbl ) -- Used with SendPosSize
	tbl.w = net.ReadInt(16)
	tbl.h = net.ReadInt(16)
	tbl.x = net.ReadInt(16)
	tbl.y = net.ReadInt(16)
end

function EGP:ReceiveColor( tbl, obj ) -- Used with SendColor
	tbl.r = net.ReadUInt(8)
	tbl.g = net.ReadUInt(8)
	tbl.b = net.ReadUInt(8)
	if (obj.a) then tbl.a = net.ReadUInt(8) end
end

--------------------------------------------------------
-- Other
--------------------------------------------------------
function EGP:ValidEGP( Ent )
	return (IsValid( Ent ) and (Ent:GetClass() == "gmod_wire_egp" or Ent:GetClass() == "gmod_wire_egp_hud" or Ent:GetClass() == "gmod_wire_egp_emitter"))
end


-- Saving Screen width and height
if (CLIENT) then
	usermessage.Hook("EGP_ScrWH_Request",function(um)
		RunConsoleCommand("EGP_ScrWH",ScrW(),ScrH())
	end)
else
	hook.Add("PlayerInitialSpawn","EGP_ScrHW_Request",function(ply)
		timer.Simple(1,function()
			if (ply and ply:IsValid() and ply:IsPlayer()) then
				umsg.Start("EGP_ScrWH_Request",ply) umsg.End()
			end
		end)
	end)

	EGP.ScrHW = {}

	concommand.Add("EGP_ScrWH",function(ply,cmd,args)
		if (args and tonumber(args[1]) and tonumber(args[2])) then
			EGP.ScrHW[ply] = { tonumber(args[1]), tonumber(args[2]) }
		end
	end)
end

-- Line drawing helper function
function EGP:DrawLine( x, y, x2, y2, size )
	if (size < 1) then size = 1 end
	if (size == 1) then
		surface.DrawLine( x, y, x2, y2 )
	else
		-- Calculate position
		local x3 = (x + x2) / 2
		local y3 = (y + y2) / 2

		-- calculate height
		local w = math.sqrt( (x2-x) ^ 2 + (y2-y) ^ 2 )

		-- Calculate angle (Thanks to Fizyk)
		local angle = math.deg(math.atan2(y-y2,x2-x))
		
		-- if the rectangle's less than a pixel wide, nothing will get drawn.
		if w < 1 then w = 1 end
		
		surface.DrawTexturedRectRotated( x3, y3, w, size, angle )
	end
end

local function ScaleCursor( this, x, y )
	if (this.Scaling) then
		local xMin = this.xScale[1]
		local xMax = this.xScale[2]
		local yMin = this.yScale[1]
		local yMax = this.yScale[2]

		x = (x * (xMax-xMin)) / 512 + xMin
		y = (y * (yMax-yMin)) / 512 + yMin
	end

	return x, y
end

local function ReturnFailure( this )
	if (this.Scaling) then
		return {this.xScale[1]-1,this.yScale[1]-1}
	end
	return {-1,-1}
end

function EGP:EGPCursor( this, ply )
	if (!EGP:ValidEGP( this )) then return {-1,-1} end
	if (!ply or !ply:IsValid() or !ply:IsPlayer()) then return ReturnFailure( this ) end

	local Normal, Pos, monitor, Ang
	-- If it's an emitter, set custom normal and pos
	if (this:GetClass() == "gmod_wire_egp_emitter") then
		Normal = this:GetRight()
		Pos = this:LocalToWorld( Vector( -64, 0, 135 ) )

		monitor = { Emitter = true }
	else
		-- Get monitor screen pos & size
		monitor = WireGPU_Monitors[ this:GetModel() ]

		-- Monitor does not have a valid screen point
		if (!monitor) then return {-1,-1} end

		Ang = this:LocalToWorldAngles( monitor.rot )
		Pos = this:LocalToWorld( monitor.offset )

		Normal = Ang:Up()
	end

	local Start = ply:GetShootPos()
	local Dir = ply:GetAimVector()

	local A = Normal:Dot(Dir)

	-- If ray is parallel or behind the screen
	if (A == 0 or A > 0) then return ReturnFailure( this ) end

	local B = Normal:Dot(Pos-Start) / A

	if (B >= 0) then
		if (monitor.Emitter) then
			local HitPos = Start + Dir * B
			HitPos = this:WorldToLocal( HitPos ) - Vector( -64, 0, 135 )
			local x = HitPos.x*(512/128)
			local y = HitPos.z*-(512/128)
			x, y = ScaleCursor( this, x, y )
			return {x,y}
		else
			local HitPos = WorldToLocal( Start + Dir * B, Angle(), Pos, Ang )
			local x = (0.5+HitPos.x/(monitor.RS*512/monitor.RatioX)) * 512
			local y = (0.5-HitPos.y/(monitor.RS*512)) * 512
			if (x < 0 or x > 512 or y < 0 or y > 512) then return ReturnFailure( this ) end -- Aiming off the screen
			x, y = ScaleCursor( this, x, y )
			return {x,y}
		end
	end

	return ReturnFailure( this )
end
