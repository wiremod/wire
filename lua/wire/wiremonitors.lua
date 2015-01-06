WireGPU_Monitors = {}

function WireGPU_AddMonitor(name,model,tof,tou,tor,trs,x1,x2,y1,y2,rot)
	if not rot then
		rot = Angle(0,90,90)
	elseif !isangle(rot) then
		rot = Angle(0,90,0)
	end
	local RatioX = (y2-y1)/(x2-x1)

	local monitor = {
		Name = name,
		offset = Vector(tof, -tor, tou),
		RS = trs,
		RatioX = RatioX,

		x1 = x1,
		x2 = x2,
		y1 = y1,
		y2 = y2,

		z = tof,

		rot = rot,
	}
	WireGPU_Monitors[model] = monitor
end

local function mindimension(vec)
	-- add a bias to make the screen appear on the front face of a cube
	if vec.x-0.002 < vec.y then
		-- x < y
		-- another bit of bias, otherwise it'd appear on the left face.
		if vec.x-0.002 < vec.z then
			-- x < y, x < z
			return Vector(1,0,0)
		else
			-- x < y, z<=x -> z < y
			return Vector(0,0,1)
		end
	else
		-- y <= x
		if vec.y < vec.z then
			-- y <= x, y < z
			return Vector(0,1,0)
		else
			-- y <= x, z <= y -> z <= x
			return Vector(0,0,1)
		end
	end
end

local function maxdimension(vec)
	-- add a small bias, so squared screens draw text in the correct orientation (y+/down = forward axis)
	if vec.x-0.002 > vec.y then
		-- x > y
		if vec.x > vec.z then
			-- x > y, x > z
			return Vector(1,0,0)
		else
			-- x > y, z>=x -> z > y
			return Vector(0,0,1)
		end
	else
		-- y >= x
		-- more bias, this time to give the front face the correct orientation
		if vec.y+0.002 > vec.z then
			-- y >= x, y > z
			return Vector(0,1,0)
		else
			-- y >= x, z >= y -> z >= x
			return Vector(0,0,1)
		end
	end
end

function WireGPU_FromBox(name, model, boxmin, boxmax)
	local dim = boxmax-boxmin
	local mindim, maxdim = mindimension(dim), maxdimension(dim)

	-- get an angle with up=mindim
	local rot = mindim:Angle()+Angle(90,0,0)

	-- make sure forward=maxdim
	if math.abs(maxdim:Dot(rot:Forward())) < 0.01 then
		rot:RotateAroundAxis(mindim, 90)
	end

	-- unrotate boxmin/max
	local box1 = WorldToLocal(boxmin, Angle(0,0,0), Vector(0,0,0), rot)
	local box2 = WorldToLocal(boxmax, Angle(0,0,0), Vector(0,0,0), rot)

	-- sort boxmin/max
	local boxmin = Vector(math.min(box1.x,box2.x), math.min(box1.y,box2.y), math.min(box1.z,box2.z))
	local boxmax = Vector(math.max(box1.x,box2.x), math.max(box1.y,box2.y), math.max(box1.z,box2.z))

	-- make a new gpu screen
	return WireGPU_FromBox_Helper(name, model, boxmin, boxmax, rot)
end

-- boxmin/boxmax have to be already rotated
function WireGPU_FromBox_Helper(name, model, boxmin, boxmax, rot)
	local boxcenter = (boxmin+boxmax)*0.5
	local offset = Vector(boxcenter.x,boxcenter.y,boxmax.z+0.2)

	boxmin = boxmin - offset
	boxmax = boxmax - offset

	local x1, y1 = boxmin.x, boxmin.y
	local x2, y2 = boxmax.x, boxmax.y

	offset:Rotate(rot)

	local monitor = {
		Name = name,
		offset = offset,
		RS = (y2-y1)/512,
		RatioX = (y2-y1)/(x2-x1),

		x1 = x1,
		x2 = x2,
		y1 = y1,
		y2 = y2,

		z = offset.z,

		rot = rot,
	}

	WireGPU_Monitors[model] = monitor
	return monitor
end

function WireGPU_FromRotatedBox(name, model, box1, box2, box3, box4, rot)
	if isvector(rot) then
		rot = Vector:Angle()
	end

	--local boxvectors = { box1, box2, box3, box4 }

	local box1 = WorldToLocal(box1, Angle(0,0,0), Vector(0,0,0), rot)
	local box2 = WorldToLocal(box2, Angle(0,0,0), Vector(0,0,0), rot)
	local box3 = WorldToLocal(box3, Angle(0,0,0), Vector(0,0,0), rot)
	local box4 = WorldToLocal(box4, Angle(0,0,0), Vector(0,0,0), rot)

	local boxmin = Vector(
		math.min(box1.x,box2.x,box3.x,box4.x),
		math.min(box1.y,box2.y,box3.y,box4.y),
		math.min(box1.z,box2.z,box3.z,box4.z)
	)
	local boxmax = Vector(
		math.max(box1.x,box2.x,box3.x,box4.x),
		math.max(box1.y,box2.y,box3.y,box4.y),
		math.max(box1.z,box2.z,box3.z,box4.z)
	)
	print(boxmin, boxmax, rot)
	return WireGPU_FromBox_Helper(name, model, boxmin, boxmax, rot)
end

WireGPU_FromBox_Helper("Workspace 002", "models/props_lab/workspace002.mdl", Vector(-20, 49, -34), Vector(16.2, 84, -30.5), Angle(0, 133.34, 59.683))

-- Offset front, offset up, offset right, resolution/scale                                OF    OU     OR   SCALE   LOWX      HIGHX    LOWY     HIGHY   ROTATE90
WireGPU_AddMonitor("Small TV",          "models/props_lab/monitor01b.mdl",                6.53, 0.45 , 1.0, 0.0185, -5.535  , 3.5    , -4.1   , 5.091 )
WireGPU_AddMonitor("Monitor Small",     "models/kobilica/wiremonitorsmall.mdl",           0.3 , 5.0  , 0  , 0.0175, -4.4    , 4.5    , 0.6    , 9.5   )
WireGPU_AddMonitor("LCD Monitor (4:3)", "models/props/cs_office/computer_monitor.mdl",    3.3 , 16.7 , 0  , 0.031 , -10.5   , 10.5   , 8.6    , 24.7  )
WireGPU_AddMonitor("Monitor Big",       "models/kobilica/wiremonitorbig.mdl",             0.2 , 13   , 0  , 0.045 , -11.5   , 11.6   , 1.6    , 24.5  )
WireGPU_AddMonitor("Plasma TV (4:3)",   "models/blacknecro/tv_plasma_4_3.mdl",            0.1 , -0.5 , 0  , 0.082 , -27.87  , 27.87  , -20.93 , 20.93 )
WireGPU_AddMonitor("Plasma TV (16:10)", "models/props/cs_office/tv_plasma.mdl",           6.1 , 18.93, 0  , 0.065 , -28.5   , 28.5   , 2      , 36    )
WireGPU_AddMonitor("Billboard",         "models/props/cs_assault/billboard.mdl",          1   , 0    , 0  , 0.23  , -110.512, 110.512, -57.647, 57.647)

WireGPU_AddMonitor("Cube 1x1x1",        "models/hunter/blocks/cube1x1x1.mdl",             24  , 0    , 0  , 0.09  , -48     , 48     , -48    , 48    )
WireGPU_AddMonitor("Panel 1x1",         "models/hunter/plates/plate1x1.mdl",              0   , 1.7  , 0  , 0.09  , -48     , 48     , -48    , 48    , true)
WireGPU_AddMonitor("Panel 2x2",         "models/hunter/plates/plate2x2.mdl",              0   , 1.7  , 0  , 0.182 , -48     , 48     , -48    , 48    , true)
WireGPU_AddMonitor("Panel 0.5x0.5",     "models/hunter/plates/plate05x05.mdl",            0   , 1.7  , 0  , 0.045 , -48     , 48     , -48    , 48    , true)

WireGPU_AddMonitor("Tray",              "models/props/cs_militia/reload_bullet_tray.mdl", 0   , 0.8  , 0  , 0.009 , 0       , 100    , 0      , 60    , true)
-- Offset front, offset up, offset right, resolution/scale                                OF    OU     OR   SCALE   LOWX      HIGHX    LOWY     HIGHY   ROTATE90
--WireGPU_AddMonitor("LED Board (1:1)",   "models/blacknecro/ledboard60.mdl",               6.1, 18.5 , 11 , 0.065 , -60     , 60     , -60    , 60    ) -- broken

WireGPU_FromBox("TF2 Red billboard", "models/props_mining/billboard001.mdl", Vector(0,-168,0), Vector(3,168,192), false)
WireGPU_FromBox("TF2 Red vs Blue billboard", "models/props_mining/billboard002.mdl", Vector(0,-306,96), Vector(3,306,288), false)

--[[
models/props_c17/tv_monitor01.mdl
models/props_wasteland/controlroom_monitor001b.mdl
models/props/cs_militia/television_console01.mdl
models/props/cs_militia/tv_console.mdl
models/props_silo/silo_launchroom_monitor.mdl
models/props_bts/glados_screenborder_curve.mdl
models/props_spytech/tv001.mdl
models/props_lab/monitor02.mdl
models/props_lab/monitor01a.mdl

workspaces:
models/props_lab/workspace003.mdl
models/props_lab/securitybank.mdl

too curvy?
models/props_spytech/computer_screen_bank.mdl
]]

local function fallback(self, model)
	local ent
	local entities = ents.GetAll() -- tried to use FindByModel, but it didn't work - don't know why
	for i=1,#entities do
		local e = entities[i]
		if 	e:GetModel() == model and
			e:GetClass() ~= "class C_BaseFlex" and -- don't include adv dupe 2 ghosts
			e:GetClass() ~= "gmod_ghost" then -- don't include adv dupe 1 ghosts
			ent = e
			break
		end
	end
	if not ent then return nil end

	local gap = Vector(0.25,0.25,0.25)
	local boxmin = ent:OBBMins()+gap
	local boxmax = ent:OBBMaxs()-gap

	return WireGPU_FromBox("Auto: "..model:match("([^/]*)$"), model, boxmin, boxmax, true)
end

setmetatable(WireGPU_Monitors, { __index = fallback })
