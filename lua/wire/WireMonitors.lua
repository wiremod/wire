-- $Rev: 1303 $
-- $LastChangedDate: 2009-07-08 19:10:33 -0700 (Wed, 08 Jul 2009) $
-- $LastChangedBy: tad2020 $

WireGPU_Monitors = {}

function WireGPU_AddMonitor(name,model,tof,tou,tor,trs,x1,x2,y1,y2,rot90)
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

		rot = rot90 and Angle(0,90,0) or Angle(0,90,90),
	}
	WireGPU_Monitors[model] = monitor
end

function WireGPU_FromBox(name, model, boxmin, boxmax, rot90)
	local obbcenter = (boxmin+boxmax)*0.5
	local offset, rot
	if rot90 then
		offset = Vector(obbcenter.x,obbcenter.y,boxmax.z+0.2)
		rot = Angle(0, 90, 0)
	else
		offset = Vector(boxmax.x+0.2,obbcenter.y,obbcenter.z)
		rot = Angle(0, 90, 90)
	end

	boxmin = boxmin - offset
	boxmax = boxmax - offset
	local box1 = WorldToLocal(boxmin, Angle(0,0,0), Vector(0,0,0), rot)
	local box2 = WorldToLocal(boxmax, Angle(0,0,0), Vector(0,0,0), rot)
	local boxmin = Vector(math.min(box1.x,box2.x), math.min(box1.y,box2.y), math.min(box1.z,box2.z))
	local boxmax = Vector(math.max(box1.x,box2.x), math.max(box1.y,box2.y), math.max(box1.z,box2.z))

	local x1, y1 = boxmin.x, boxmin.y
	local x2, y2 = boxmax.x, boxmax.y

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
	--monitor.offset.y = monitor.offset.y-y1*(1/monitor.RatioX-1) -- silly...,

	WireGPU_Monitors[model] = monitor
	return monitor
end

-- Offset front, offset up, offset right, resolution/scale                              OF   OU     OR   SCALE   LOWX      HIGHX    LOWY    HIGHY    ROTATE90
WireGPU_AddMonitor("Small TV",          "models/props_lab/monitor01b.mdl",              6.4, 0.45 , 1.0, 0.018 , -5.535  , 3.5    , -4.1   , 5.091 )
WireGPU_AddMonitor("Monitor Small",     "models/kobilica/wiremonitorsmall.mdl",         0.3, 5.0  , 0  , 0.0175, -4.4    , 4.5    , 0.6    , 9.5   )
WireGPU_AddMonitor("LCD Monitor (4:3)", "models/props/cs_office/computer_monitor.mdl",  3.3, 16.7 , 0  , 0.031 , -10.5   , 10.5   , 8.6    , 24.7  )
WireGPU_AddMonitor("Monitor Big",       "models/kobilica/wiremonitorbig.mdl",           0.2, 13   , 0  , 0.045 , -11.5   , 11.6   , 1.6    , 24.5  )
WireGPU_AddMonitor("Plasma TV (4:3)",   "models/blacknecro/tv_plasma_4_3.mdl",          0.1, -0.5 , 0  , 0.082 , -27.87  , 27.87  , -20.93 , 20.93 )
WireGPU_AddMonitor("Plasma TV (16:10)", "models/props/cs_office/tv_plasma.mdl",         6.1, 18.93, 0  , 0.065 , -28.5   , 28.5   , 2      , 36    )
WireGPU_AddMonitor("Billboard",         "models/props/cs_assault/billboard.mdl",        1  , 0    , 0  , 0.23  , -110.512, 110.512, -57.647, 57.647)

WireGPU_AddMonitor("Cube 1x1x1",        "models/hunter/blocks/cube1x1x1.mdl",           24 , 0    , 0  , 0.09  , -48     , 48     , -48   , 48     )
WireGPU_AddMonitor("Panel 1x1",         "models/hunter/plates/plate1x1.mdl",            0  , 1.7  , 0  , 0.09  , -48     , 48     , -48   , 48     , true)
WireGPU_AddMonitor("Panel 2x2",         "models/hunter/plates/plate2x2.mdl",            0  , 1.7  , 0  , 0.182 , -48     , 48     , -48   , 48     , true)
WireGPU_AddMonitor("Panel 0.5x0.5",     "models/hunter/plates/plate05x05.mdl",          0  , 1.7  , 0  , 0.045 , -48     , 48     , -48   , 48     , true)

WireGPU_AddMonitor("Tray",      "models/props/cs_militia/reload_bullet_tray.mdl",       0  , 0.8  , 0  , 0.009 , 0       , 100    , 0     , 60     , true)
--WireGPU_AddMonitor("LED Board (1:1)",   "models/blacknecro/ledboard60.mdl",             6.1, 18.5 , 11.0, 0.065 , -60     , 60     , -60   , 60     ) -- broken
-- Offset front, offset up, offset right, resolution/scale                              OF   OU     OR    SCALE   LOWX      HIGHX    LOWY    HIGHY    ROTATE90

WireGPU_FromBox("TF2 Red billboard", "models/props_mining/billboard001.mdl", Vector(0,-168,0), Vector(3,168,192), false)
WireGPU_FromBox("TF2 Red vs Blue billboard", "models/props_mining/billboard002.mdl", Vector(0,-306,96), Vector(3,306,288), false)

local function fallback(self, model)
	local ent
	for _,e in ipairs(ents.GetAll()) do
		if e:GetModel() == model then
			ent = e
			break
		end
	end
	if not ent then return nil end

	local gap = Vector(0.25,0.25,0.25)
	local obbmin = ent:OBBMins()+gap
	local obbmax = ent:OBBMaxs()-gap

	return WireGPU_FromBox("Auto: "..model:match("([^/]*)$"), model, obbmin, obbmax, true)
end

setmetatable(WireGPU_Monitors, { __index = fallback })
