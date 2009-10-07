include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

CreateClientConVar("cl_wire_holoemitter_minfaderate",10,true,false)

-- mats
local matbeam = Material( "tripmine_laser" )
local matpoint = Material( "sprites/gmdm_pickups/light" )

local render_SetMaterial = render.SetMaterial
local render_DrawBeam = render.DrawBeam
local render_DrawSprite = render.DrawSprite


function ENT:Initialize()
	-- self.PointList[i] = { pos, alpha, faderate }
	self.PointList = {}
	self.LastClear = self.Entity:GetNetworkedInt("Clear")

	-- active point
	self.ActivePoint = Vector( 0, 0, 0 )

	-- make the hologram visible even when not looking at it
	self.Entity:SetRenderBounds( Vector(-8192,-8192,-8192), Vector(8192,8192,8192) )

	self.nextremove = 0 -- the next time the point list is cleaned up (ENT:Think)
	self.lastfade = 0 -- the last time the alphas were calculated (ENT:Think, ENT:Draw)
end


function ENT:Think()
	local emitter = self.Entity

	-- read point.
	local point = Vector(
		emitter:GetNetworkedFloat( "X" ),
		emitter:GetNetworkedFloat( "Y" ),
		emitter:GetNetworkedFloat( "Z" )+64 -- who came up with this offset?
	)

	lastclear = emitter:GetNetworkedInt("Clear")
	if lastclear ~= self.LastClear then
		self.PointList = {}
		self.LastClear = lastclear
	end

	-- did the point differ from active point?
	if point ~= self.ActivePoint && emitter:GetNetworkedBool( "Active" ) then
		-- fetch color.
		local _, _, _, a = emitter:GetColor()

		-- determine fade rate
		local minfaderate = 0.1
		if not SinglePlayer() then
			-- Due to a request, in Multiplayer, the people can control this with a client-side cvar (aVoN)
			minfaderate = GetConVarNumber("cl_wire_holoemitter_minfaderate") or 10
		end

		local tempfaderate = math.Clamp( emitter:GetNetworkedFloat( "FadeRate" ),minfaderate, 255 )

		-- store this point inside the point list
		table.insert( self.PointList, { self.ActivePoint, a, tempfaderate } )

		-- store new active point
		self.ActivePoint = point

	end

	-- This is repeated here, so the client doesn't lag and die when not looking at a holo.
	if self.nextremove <= CurTime() then
		local t = CurTime()
		local frametime = t-self.lastfade
		self.lastfade = t
		self.nextremove = t+0.5
		for i = #self.PointList,1,-1 do
			-- easy access
			local point = self.PointList[i]
			-- alpha -= faderate*frametime
			point[2] = point[2] - point[3] * frametime

			-- if the point is no longer visible, remove it
			if( point[2] <= 0 ) then -- [2] = alpha
				table.remove( self.PointList, i )
			end
		end
	end
end

function ENT:Draw()
	local emitter = self.Entity

	-- render model
	emitter:DrawModel()

	-- are we rendering?
	if not emitter:GetNetworkedBool( "Active" ) then return end

	-- read HoloGrid.
	local hologrid = emitter:GetNetworkedEntity( "grid" )
	if not hologrid or not hologrid:IsValid() then return end

	local reference_entity = hologrid:GetNetworkedEntity( "reference" )
	local LocalToWorld
	if ValidEntity(reference_entity) then
		LocalToWorld = reference_entity.LocalToWorld
	else
		-- LocalToWorld(reference_entity, pos) <=> Vector.__add(Vector(0,0,-64), pos) <=> pos - Vector(0,0,64)
		reference_entity = Vector(0,0,-64)
		LocalToWorld = reference_entity.__add
	end

	-- draw beam?
	local drawbeam = emitter:GetNetworkedBool( "ShowBeam" )
	local groundbeam = emitter:GetNetworkedBool( "GroundBeam" )

	-- read point size
	local size = emitter:GetNetworkedFloat( "PointSize" )
	local beamsize = 2
	if size > 8 then beamsize = size * 0.25 end
	local pointbeamsize = beamsize * 2

	-- read color
	local r,g,b,a = emitter:GetColor()
	local color = Color(r,g,b,a)

	-- calculate pixel point.
	local emitterpos = emitter:GetPos()
	local pixelpos

	--------------------------------------------------------------------------------
	-- draw ActivePoint
	pixelpos = LocalToWorld(reference_entity, self.ActivePoint)

	-- draw emitter-ActivePoint beam
	if groundbeam then
		render_SetMaterial( matbeam )
		render_DrawBeam(
			emitterpos,
			pixelpos,
			beamsize,
			0, 1,
			color
		)
	end

	local drawpoints = size > 0
	if drawpoints then
		-- draw Active Point sprite
		render_SetMaterial( matpoint )
		render_DrawSprite(
			pixelpos,
			size, size,
			color
		)
	end

	--------------------------------------------------------------------------------
	-- draw fading points.
	local lastpos = pixelpos

	local t = CurTime()
	local frametime = t-self.lastfade
	self.lastfade = t

	local PointList = self.PointList -- easy access
	for i = #PointList, 1, -1 do
		-- easy access
		local point = PointList[i]


		-- fade away
		-- alpha -= faderate*frametime
		local a = point[2] - point[3] * frametime
		point[2] = a

		-- if the point is no longer visible, remove it
		if a <= 0 then
			table.remove( PointList, i )
		else
			-- calculate pixel point.
			pixelpos = LocalToWorld(reference_entity, point[1])

			-- calculate color.
			color = Color( r, g, b, alpha ) -- [2] = alpha

			-- draw emitter-point beam
			if groundbeam then
				render_SetMaterial( matbeam )
				render_DrawBeam(
					emitterpos,
					pixelpos,
					beamsize,
					0, 1,
					color
				)
			end

			-- draw point-point beam
			if drawbeam then
				render_SetMaterial( matbeam )
				render_DrawBeam(
					lastpos,
					pixelpos,
					pointbeamsize,
					0, 1,
					color
				)
				lastpos = pixelpos
			end

			if drawpoints then
				-- draw active point - sprite
				render_SetMaterial( matpoint )
				render_DrawSprite(
					pixelpos,
					size, size,
					color
				)
			end -- if drawpoints
		end -- if alpha > 0
	end -- for PointList
end -- ENT:Draw
