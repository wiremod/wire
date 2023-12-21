WireGPU_Monitors = {}

function WireGPU_AddMonitor(name,model,tof,tou,tor,trs,x1,x2,y1,y2,rot,translucent)
	if not rot then
		rot = Angle(0,90,90)
	elseif not isangle(rot) then
		rot = Angle(0,90,0)
	end
	local RatioX = (y2-y1)/(x2-x1)

	local monitor = {
		Name = name,
		offset = Vector(tof, -tor, tou),
		RS = (trs or (y2 - y1) / 512)/2,
		RatioX = RatioX,

		x1 = x1,
		x2 = x2,
		y1 = y1,
		y2 = y2,

		z = tof,

		rot = rot,

		translucent = translucent,
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

function WireGPU_FromBox(name, model, boxmin, boxmax, translucent)
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
	return WireGPU_FromBox_Helper(name, model, boxmin, boxmax, rot, translucent)
end

-- boxmin/boxmax have to be already rotated
function WireGPU_FromBox_Helper(name, model, boxmin, boxmax, rot, translucent)
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
		RS = (y2-y1)/1024,
		RatioX = (y2-y1)/(x2-x1),

		x1 = x1,
		x2 = x2,
		y1 = y1,
		y2 = y2,

		z = offset.z,

		rot = rot,

		translucent = translucent,
	}

	WireGPU_Monitors[model] = monitor
	return monitor
end

function WireGPU_FromRotatedBox(name, model, box1, box2, box3, box4, rot, translucent)
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
	return WireGPU_FromBox_Helper(name, model, boxmin, boxmax, rot, translucent)
end

WireGPU_FromBox_Helper("Workspace 002", "models/props_lab/workspace002.mdl", Vector(-20, 49, -34), Vector(16.2, 84, -30.5), Angle(0, 133.34, 59.683))

-- Offset front, offset up, offset right, resolution/scale                                OF    OU     OR   SCALE   LOWX      HIGHX    LOWY     HIGHY   ROTATE90
WireGPU_AddMonitor("Small TV",          "models/props_lab/monitor01b.mdl",                6.53, 0.45 , 1.0, 0.0185, -5.535  , 3.5    , -4.1   , 5.091 )
WireGPU_FromBox_Helper("Old TV", "models/props_c17/tv_monitor01.mdl", Vector(-9.1,-4.6,-3), Vector(5.5,5.8,6), Angle(0, 90, 90))
WireGPU_AddMonitor("Monitor Small",     "models/kobilica/wiremonitorsmall.mdl",           0.3 , 5.0  , 0  , 0.0175, -4.4    , 4.5    , 0.6    , 9.5   )
WireGPU_AddMonitor("LCD Monitor (4:3)", "models/props/cs_office/computer_monitor.mdl",    3.3 , 16.7 , 0  , 0.031 , -10.5   , 10.5   , 8.6    , 24.7  )
WireGPU_AddMonitor("Monitor Big",       "models/kobilica/wiremonitorbig.mdl",             0.2 , 13   , 0  , 0.045 , -11.5   , 11.6   , 1.6    , 24.5  )
WireGPU_AddMonitor("Plasma TV (4:3)",   "models/blacknecro/tv_plasma_4_3.mdl",            0.1 , -0.5 , 0  , 0.082 , -27.87  , 27.87  , -20.93 , 20.93 )
WireGPU_AddMonitor("Plasma TV (16:10)", "models/props/cs_office/tv_plasma.mdl",           6.1 , 18.93, 0  , 0.065 , -28.5   , 28.5   , 2      , 36    )
WireGPU_AddMonitor("Billboard",         "models/props/cs_assault/billboard.mdl",          1   , 0    , 0  , 0.23  , -110.512, 110.512, -57.647, 57.647)
WireGPU_FromBox_Helper("Beige CRT Monitor", "models/props_lab/monitor01a.mdl", Vector(-9.3,-4.9,-3), Vector(9.3,10.4,12.45), Angle(0, 90, 85))
WireGPU_FromBox_Helper("White CRT Monitor", "models/props_lab/monitor02.mdl", Vector(-9.0,6.3,-3), Vector(9.0,21.2,12.8), Angle(0, 90, 82.5))
WireGPU_AddMonitor("Cube 1x1x1",        "models/hunter/blocks/cube1x1x1.mdl",             24  , 0    , 0  , nil   , -23.275 , 23.275 , -23.275, 23.275)
WireGPU_AddMonitor("Panel 1x1",         "models/hunter/plates/plate1x1.mdl",              0   , 1.7  , 0  , nil   , -23.275 , 23.275 , -23.275, 23.275, true)
WireGPU_AddMonitor("Panel 2x2",         "models/hunter/plates/plate2x2.mdl",              0   , 1.7  , 0  , nil   , -47.45  , 47.45  , -47.45 , 47.45 , true)
WireGPU_AddMonitor("Panel 0.5x0.5",     "models/hunter/plates/plate05x05.mdl",            0   , 1.7  , 0  , nil   , -11.8265, 11.8265, -11.8265,11.8265,true)
WireGPU_AddMonitor("Tray",              "models/props/cs_militia/reload_bullet_tray.mdl", 0   , 0.8  , 0  , nil   ,  0      , 7.68   ,  0     , 4.608 , true)
WireGPU_FromBox_Helper("Wall-mounted TV", "models/props_wasteland/controlroom_monitor001b.mdl", Vector(-10.2,-12.6,-3), Vector(10.7,4.7,15.38), Angle(0, 90, 103.2))
WireGPU_FromBox_Helper("Oscilloscope", "models/props_lab/reciever01b.mdl", Vector(-5.93,-2,-3), Vector(-1.74,2.1,6.225), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Oscilloscope 2", "models/props_c17/consolebox03a.mdl", Vector(4,2,-10), Vector(10.6,7.1,10), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Oscilloscope 3", "models/props_c17/consolebox05a.mdl", Vector(-6,0,-10), Vector(0.9,5.1,11), Angle(0, 90, 87))
WireGPU_FromBox_Helper("Receiver", "models/props_lab/reciever01c.mdl", Vector(-5.2,-1.7,-3), Vector(-0.2,0.8,5.5), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Receiver 2", "models/props_lab/reciever01d.mdl", Vector(-5.2,-1.7,-3), Vector(-0.2,0.8,5.5), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Oscilloscope 4", "models/props_c17/consolebox01a.mdl", Vector(8.5,7.2,-10), Vector(15,9.4,16.4), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Combine Console", "models/props_combine/combine_interface001.mdl", Vector(-9.9,25.6,-10), Vector(5.7,33.5,34.2), Angle(0, 90, 41.5))
WireGPU_FromBox_Helper("Cash Register", "models/props_c17/cashregister01a.mdl", Vector(-9.2,8.5,-10), Vector(4.4,11.6,-5.9), Angle(0, 180, 90))
WireGPU_FromBox_Helper("Combine Monitor", "models/props_combine/combine_monitorbay.mdl", Vector(-30.7,-26,-10), Vector(38,34.7,-2), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Workspace 001", "models/props_lab/workspace001.mdl", Vector(4,37,0), Vector(21.2,52,11.1), Angle(0, 15, 83))
WireGPU_FromBox_Helper("Radio", "models/props_lab/citizenradio.mdl", Vector(-5.8,11.7,-3), Vector(11.3,15.3,8.2), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Security Bank", "models/props_lab/securitybank.mdl", Vector(-4.6,66,-3), Vector(25,86.5,12), Angle(0, 90, 90))
WireGPU_FromBox_Helper("GPS", "models/beer/wiremod/gps.mdl", Vector(-2.9,-2.1,-3), Vector(2.9,2.9,1.18), Angle(0, 90, 0))

WireGPU_FromBox_Helper("E2",                "models/beer/wiremod/gate_e2.mdl",                Vector(-2.8,-2.8,-3), Vector(2.8,2.8,0.55), Angle(0, 90, 0))
WireGPU_FromBox_Helper("Target Finder",     "models/beer/wiremod/targetfinder.mdl",           Vector(-3.2,-2.3,-3), Vector(3.2,1.2,1.5), Angle(0, 90, 0))
WireGPU_FromBox_Helper("4-pin DIP",         "models/bull/gates/microcontroller1.mdl",         Vector(-2.3,-1.2,-3), Vector(2.3,1.2,0.96), Angle(0, 90, 0))
WireGPU_FromBox_Helper("8-pin DIP",         "models/bull/gates/microcontroller2.mdl",         Vector(-4.3,-1.2,-3), Vector(4.3,1.2,0.96), Angle(0, 90, 0))
WireGPU_FromBox_Helper("Gate",              "models/jaanus/wiretool/wiretool_gate.mdl",       Vector(-2.9,-2.9,-3), Vector(2.9,2.9,0.82), Angle(0, 90, 0))
WireGPU_FromBox_Helper("Controller",        "models/jaanus/wiretool/wiretool_controlchip.mdl",Vector(-3.4,-1.5,-3), Vector(3.4,1.5,0.82), Angle(0, 90, 0))
WireGPU_FromBox_Helper("Keypad",            "models/props_lab/keypad.mdl",                    Vector(-1.7,2,-3), Vector(1.7,4,0.68), Angle(0, 90, 90))
WireGPU_FromBox_Helper("C4",                "models/weapons/w_c4_planted.mdl",                Vector(1.5,1.35,-3), Vector(7.8,4.6,8.65), Angle(0, -90, 0))
WireGPU_FromBox_Helper("Toolgun",           "models/weapons/w_toolgun.mdl",                   Vector(-1.4,4.7,-3), Vector(1.05,7.16,-0.14), Angle(0, -90, 45))
WireGPU_FromBox_Helper("Blue Panel 1x1",    "models/xqm/panel1x1.mdl",                        Vector(-9.2,-9.2,-3), Vector(9.2,9.2,-0.3), Angle(0, -90, 0))
WireGPU_FromBox_Helper("Blue Panel 1x2",    "models/xqm/panel1x2.mdl",                        Vector(-9.2,-31.2,-3), Vector(9.2,9.2,-0.3), Angle(0, -90, 0))
WireGPU_FromBox_Helper("Blue Box",          "models/xqm/box5s.mdl",                           Vector(-9.2,-9.2,-3), Vector(9.2,9.2,9.3), Angle(0, -90, 90))
WireGPU_FromBox_Helper("Teleporter",        "models/props_lab/miniteleport.mdl",              Vector(20.8,-8.1,-3), Vector(30.2,-3.7,17.8), Angle(0, 90, 55))
WireGPU_FromBox_Helper("Printer",           "models/props_lab/plotter.mdl",                   Vector(-10.2,-19.5,-3), Vector(-6.7,-18.3,39.6), Angle(0, 90, 0))
WireGPU_FromBox_Helper("Combine Console 2", "models/props_combine/combine_interface002.mdl",  Vector(-14.15,27.5,-10), Vector(11.5,32.3,34.2), Angle(0, 90, 41.5))
WireGPU_FromBox_Helper("Combine Console 3", "models/props_combine/combine_interface003.mdl",  Vector(-20.3,48.7,-10), Vector(19.9,50.9,13), Angle(0.5, 91, 70))
WireGPU_FromBox_Helper("Combine Monitor 2", "models/props_combine/combine_intmonitor003.mdl", Vector(-17,0,-10), Vector(15,48.5,22.8), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Combine Monitor 3", "models/props_combine/combine_intmonitor001.mdl", Vector(-16,3,-10), Vector(10,48.5,-4.1), Angle(0, 90, 90))
WireGPU_FromBox_Helper("Workspace 003",     "models/props_lab/workspace003.mdl",              Vector(110,73.3,-3), Vector(149,96,-1), Angle(0, 90, 101))
WireGPU_FromBox_Helper("Workspace 004",     "models/props_lab/workspace004.mdl",              Vector(4.2,37,0), Vector(21.4,52,11.1), Angle(0, 15, 83))
WireGPU_FromBox_Helper("Servers",           "models/props_lab/servers.mdl",                   Vector(-18.2,7.8,0), Vector(-4.7,19.1,12.1), Angle(0, 90, 82))
WireGPU_AddMonitor("Plasma TV (16:10) 2",   "models/props_phx/rt_screen.mdl",                 6.1 , 18.93, 0  , 0.065 , -28.5   , 28.5   , 2      , 36    )
WireGPU_FromBox_Helper("8x2 LCD",         "models/fasteroid/bull/lcd1.mdl",         Vector(-4.91,-1.02,-3), Vector(1.31,1.02,0.8), Angle(0, 90, 0))
WireGPU_FromBox_Helper("16x2 LCD",         "models/fasteroid/bull/lcd2.mdl",         Vector(-4.91,-1.02,-3), Vector(7.52,1.02,0.8), Angle(0, 90, 0))
WireGPU_FromBox_Helper("16x4 LCD",         "models/fasteroid/bull/lcd3.mdl",         Vector(-4.91,-3.11,-3), Vector(7.52,1.02,0.8), Angle(0, 90, 0))
WireGPU_FromBox_Helper("40x4 LCD",         "models/fasteroid/bull/lcd4.mdl",         Vector(-4.91,-3.11,-3), Vector(26.22,1.02,0.8), Angle(0, 90, 0))
WireGPU_FromBox_Helper("20x4 LCD",         "models/fasteroid/bull/lcd5.mdl",         Vector(-4.91,-3.11,-3), Vector(10.65,1.02,0.8), Angle(0, 90, 0))

-- Offset front, offset up, offset right, resolution/scale                                OF    OU     OR   SCALE   LOWX      HIGHX    LOWY     HIGHY   ROTATE90
--WireGPU_AddMonitor("LED Board (1:1)",   "models/blacknecro/ledboard60.mdl",               6.1, 18.5 , 11 , 0.065 , -60     , 60     , -60    , 60    ) -- broken

WireGPU_FromBox("TF2 Red billboard", "models/props_mining/billboard001.mdl", Vector(0,-168,0), Vector(3,168,192), false)
WireGPU_FromBox("TF2 Red vs Blue billboard", "models/props_mining/billboard002.mdl", Vector(0,-306,96), Vector(3,306,288), false)


-- transparent screens
WireGPU_AddMonitor("Window", "models/props_phx/construct/windows/window1x1.mdl", 0, 1.7, 0, nil, -17.3, 17.3, -17.3, 17.3, true, true)

--[[
models/props/cs_militia/television_console01.mdl
models/props/cs_militia/tv_console.mdl
models/props_silo/silo_launchroom_monitor.mdl
models/props_bts/glados_screenborder_curve.mdl
models/props_spytech/tv001.mdl
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

	return WireGPU_FromBox("Auto: "..model:match("([^/]*)$"), model, boxmin, boxmax, false)
end

setmetatable(WireGPU_Monitors, { __index = fallback })

