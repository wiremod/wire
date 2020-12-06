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
	if not self:ValidEGP(ent) or not x or not y then return end
	ent.xScale = { x[1], x[2] }
	ent.yScale = { y[1], y[2] }
	if x[1] ~= 0 or x[2] ~= 512 or y[1] ~= 0 or y[2] ~= 512 then
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
	if not self:ValidEGP(ent) then return end
	local xScale = ent.xScale
	local yScale = ent.yScale
	if not xScale or not yScale then return end

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
	if not self:ValidEGP(ent) then return end

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
	if self:Table_IsEmpty(tbl1) ~= self:Table_IsEmpty(tbl2) then return true end -- One is empty, the other is not

	for k,v in ipairs( tbl1 ) do
		if not tbl2[k] or tbl2[k].ID ~= v.ID then -- Different ID?
			return true
		else
			for k2,v2 in pairs( v ) do
				if k2 ~= "BaseClass" then
					if tbl2[k][k2] or tbl2[k][k2] ~= v2 then -- Is any setting different?
						return true
					end
				end
			end
		end
	end

	for k, _ in ipairs( tbl2 ) do -- Were any objects removed?
		if not tbl1[k] then
			return true
		end
	end

	return false
end


----------------------------
-- IsAllowed check
----------------------------
function EGP:IsAllowed( E2, Ent )
	if not EGP:ValidEGP(Ent) then return false end
	if (E2 and E2.entity and E2.entity:IsValid()) then
		local owner = Ent:GetEGPOwner()
		if E2.player ~= owner then
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
	if (obj.a) then net.WriteUInt( math.Clamp( obj.a, 0, 255 ) , 8) end
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

	EGP.ScrHW = WireLib.RegisterPlayerTable()

	concommand.Add("EGP_ScrWH",function(ply,cmd,args)
		if (args and tonumber(args[1]) and tonumber(args[2])) then
			EGP.ScrHW[ply] = { tonumber(args[1]), tonumber(args[2]) }
		end
	end)
end

-- Used to check if the cached vertices of egpCircle etc are still valid, and if not update to the current values
function EGP:CacheNeedsUpdate(obj, keys)
	if not obj.vert_cache then obj.vert_cache = {} end
	local cache = obj.vert_cache
	local update = false
	for _,k in pairs(keys) do
		if cache[k] ~= obj[k] then
			update = true
			cache[k] = obj[k]
		end
	end
	return update
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

function EGP:DrawPath( vertices, size, closed )
	if size < 1 then size = 1 end
	local num = #vertices


	if size == 1 then -- size 1 => just normal lines
		local last = vertices[1]
		for i=2, num do
			local v = vertices[i]
			surface.DrawLine( last.x, last.y, v.x, v.y )
			last = v
		end
		if closed then
			surface.DrawLine( last.x, last.y, vertices[1].x, vertices[1].y )
		end
	else
		size = size/2 -- simplify calculations
		local corners = vertices.outline_cache
		if vertices.outline_cache_size ~= size then -- check if the outline was cached already
			corners = {}
			local lastdir = {x=0, y=0}
			if closed then
				local x1 = vertices[num].x
				local y1 = vertices[num].y
				local x2 = vertices[1].x
				local y2 = vertices[1].y
				local len = math.sqrt( (x2-x1) ^ 2 + (y2-y1) ^ 2 )
				lastdir = {x=(x2-x1)/len, y=(y2-y1)/len} -- initialize lastdir so first segment can be drawn normally
			end
			for i=1, (closed and num+1 or num) do
				local v1 = i==num+1 and vertices[1] or vertices[i]
				local x1 = v1.x
				local y1 = v1.y

				if not closed and i==num then -- very last segment, just end perpendicular (TODO: maybe move after the loop)
					corners[#corners+1] = { r={x=x1-lastdir.y*size, y=y1+lastdir.x*size}, l={x=x1+lastdir.y*size, y=y1-lastdir.x*size}}
				else
					local v2 = i<num and vertices[i+1] or vertices[i+1-num]
					local x2 = v2.x
					local y2 = v2.y

					local len = math.sqrt( (x2-x1) ^ 2 + (y2-y1) ^ 2 )
					local dir = {x=(x2-x1)/len, y=(y2-y1)/len}
					if x1 ~= x2 or y1 ~= y2 then -- cannot get direction between identical points, just skip it
						if not closed and i==1 then -- very first segment, just start perpendicular (TODO: maybe move before the loop)
							corners[#corners+1] = { r={x=x1-dir.y*size, y=y1+dir.x*size}, l={x=x1+dir.y*size, y=y1-dir.x*size} }
						else
							local dot = dir.x*lastdir.x + dir.y*lastdir.y
							local scaling = size*math.tan(math.acos(dot)/2) -- complicated math, could be also be `size*sqrt(1-dot)/sqrt(dot+1)` (no idea what is faster)
							if dot > 0.999 then -- also account for rounding errors, somehow the dot product can be >1, which makes scaling nan
								-- direction stays the same, no need for a corner, just skip this point, unless it is the last segment of a closed path (last segment of a open path is handled explicitly above)
								if i == num+1 then
									corners[#corners+1] = { r={x=x1-dir.y*size, y=y1+dir.x*size}, l={x=x1+dir.y*size, y=y1-dir.x*size} }
								end
							elseif dot < -0.999 then -- new direction is inverse, just add perpendicular nodes
								corners[#corners+1] = { r={x=x1-dir.y*size, y=y1+dir.x*size}, l={x=x1+dir.y*size, y=y1-dir.x*size} }
							elseif dir.x*-lastdir.y + dir.y*lastdir.x > 0 then -- right bend, checked by getting the dot product between dir and lastDir:rotate(90)
								local offsetx = -lastdir.y*size-lastdir.x*scaling
								local offsety = lastdir.x*size-lastdir.y*scaling
								if dot < 0 then -- sharp corner, add two points to the outer edge to not have insanely long spikes
									corners[#corners+1] = { r={x=x1+offsetx, y=y1+offsety}, l={x=x1+(lastdir.x+lastdir.y)*size, y=y1+(lastdir.y-lastdir.x)*size} }
									corners[#corners+1] = { r={x=x1+offsetx, y=y1+offsety}, l={x=x1-(dir.x-dir.y)*size, y=y1-(dir.y+dir.x)*size} }
								else
									corners[#corners+1] = { r={x=x1+offsetx, y=y1+offsety}, l={x=x1-offsetx, y=y1-offsety} }
								end
							else -- left bend
								local offsetx = lastdir.y*size-lastdir.x*scaling
								local offsety = -lastdir.x*size-lastdir.y*scaling
								if dot < 0 then
									corners[#corners+1] = { l={x=x1+offsetx, y=y1+offsety}, r={x=x1+(lastdir.x-lastdir.y)*size, y=y1+(lastdir.y+lastdir.x)*size} }
									corners[#corners+1] = { l={x=x1+offsetx, y=y1+offsety}, r={x=x1-(dir.x+dir.y)*size, y=y1-(dir.y-dir.x)*size} }
								else
									corners[#corners+1] = { l={x=x1+offsetx, y=y1+offsety}, r={x=x1-offsetx, y=y1-offsety} }
								end
							end
						end
						lastdir = dir
					end
				end
			end
			vertices.outline_cache = corners
			vertices.outline_cache_size = size
		end
		for i=2, #corners, 2 do
			local verts
			if i==#corners then -- last corner, only one segment missing
				verts = {corners[i].r, corners[i-1].r, corners[i-1].l, corners[i].l}
			else -- draw this and next segment as a single polygon
				verts = {corners[i].r, corners[i-1].r, corners[i-1].l, corners[i].l, corners[i+1].l, corners[i+1].r}
			end
			surface.DrawPoly(verts)
		end
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
	if not EGP:ValidEGP(this) then return {-1,-1} end
	if not IsValid(ply) or not ply:IsPlayer() then return ReturnFailure( this ) end

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
		if not monitor then return {-1,-1} end

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

function EGP.ScreenSpaceToObjectSpace(object, point)
	point = { x = point.x - object.x, y = point.y - object.y }

	if object.angle and object.angle ~= 0 then
		local theta = math.rad(object.angle)
		local cos_theta, sin_theta = math.cos(theta), math.sin(theta)
		point.x, point.y =
			point.x * cos_theta - point.y * sin_theta,
			point.y * cos_theta + point.x * sin_theta
	end

	return point
end
