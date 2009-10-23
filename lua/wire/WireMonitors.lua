-- $Rev: 1303 $
-- $LastChangedDate: 2009-07-08 19:10:33 -0700 (Wed, 08 Jul 2009) $
-- $LastChangedBy: tad2020 $

WireGPU_Monitors = {}

function WireGPU_AddMonitor(name,model,tof,tou,tor,trs,x1,x2,y1,y2,rot90)
	WireGPU_Monitors[model] = {
		Name = name,
		offset = Vector(tof, -tor, tou),
		RS = trs,
		RatioX = math.abs((y1-y2)/(x2-x1)),

		x1 = x1,
		x2 = x2,
		y1 = y1,
		y2 = y2,

		z = tof,

		rot90 = rot90,
	}
end

-- Offset front, offset up, offset right, resolution/scale                              OF      OU      OR      SCALE   LOWX      HIGHX    LOWY      HIGHY   ROTATE90
WireGPU_AddMonitor("Small TV",          "models/props_lab/monitor01b.mdl",              6.4,    0.45,   1.00,   0.018,  -5.535,   3.5,     5.091,    -4.1)
WireGPU_AddMonitor("Monitor Small",     "models/kobilica/wiremonitorsmall.mdl",         0.3,    5.0,    0.0,    0.0175, -4.4,     4.5,     9.5,      0.6)
WireGPU_AddMonitor("LCD Monitor (4:3)", "models/props/cs_office/computer_monitor.mdl",  3.7,    16.7,   2.4,    0.031,  -10.5,    10.5,    24.7,     8.6)
WireGPU_AddMonitor("Monitor Big",       "models/kobilica/wiremonitorbig.mdl",           0.2,    13,     0.0,    0.045,  -11.5,    11.6,    24.5,     1.6)
WireGPU_AddMonitor("Plasma TV (4:3)",   "models/blacknecro/tv_plasma_4_3.mdl",          0.1,    -0.5,   6.5,    0.082,  -27.87,   27.87,   20.93,    -20.93)
WireGPU_AddMonitor("Plasma TV (16:10)", "models/props/cs_office/tv_plasma.mdl",         6.1,    18.93,  11.0,   0.065,  -28.5,    28.5,    36,       2)
WireGPU_AddMonitor("Billboard",         "models/props/cs_assault/billboard.mdl",        1,      0,      52,     0.23,   -110.512, 110.512, 57.647,   -57.647)

WireGPU_AddMonitor("LED Board (1:1)",   "models/blacknecro/ledboard60.mdl",             6.1,    18.5,   11.0,   0.065,  -60,      60,      -60,      60)
WireGPU_AddMonitor("Cube 1x1x1",        "models/hunter/blocks/cube1x1x1.mdl",           24,     0,      0,      0.09,   -48,      48,      -48,      48)
WireGPU_AddMonitor("Panel 1x1",         "models/hunter/plates/plate1x1.mdl",            0,      1.7,    0,      0.09,   -48,      48,      -48,      48,     true)
WireGPU_AddMonitor("Panel 2x2",         "models/hunter/plates/plate2x2.mdl",            0,      1.7,    0,      0.182,  -48,      48,      -48,      48,     true)
WireGPU_AddMonitor("Panel 0.5x0.5",     "models/hunter/plates/plate05x05.mdl",          0,      1.7,    0,      0.045,  -48,      48,      -48,      48,     true)

WireGPU_AddMonitor("Tray",      "models\props\cs_militia\reload_bullet_tray.mdl",       0,      0.8,    1.6,    0.009,  0,        100,     0,        60,     true)
-- Offset front, offset up, offset right, resolution/scale                              OF      OU      OR      SCALE   LOWX     HIGHX     LOWY      HIGHY   ROTATE90

local function fallback(self, model)
	local ent
	for _,e in ipairs(ents.GetAll()) do
		if e:GetModel() == model then
			ent = e
			break
		end
	end
	if not ent then return nil end

	local gap = Vector(0.25,0.25,0.05)
	local obbmin = ent:OBBMins()+gap
	local obbmax = ent:OBBMaxs()-gap

	local obbcenter = ent:OBBCenter()
	local offset = Vector(obbcenter.x,obbcenter.y,obbmax.z)

	obbmin = obbmin - offset
	obbmax = obbmax - offset

	local x1, y1 = obbmin.y, obbmin.x
	local x2, y2 = obbmax.y, obbmax.x

	local monitor = {
		Name = "Auto: "..model:match("([^/]*)$"),
		offset = offset,
		RS = (y2-y1)/512,
		RatioX = math.abs((y2-y1)/(x2-x1)),

		x1 = x1,
		x2 = x2,
		y1 = y1,
		y2 = y2,

		z = offset.x,

		rot90 = true,
	}
	monitor.offset.y = monitor.offset.y+y1*(1/monitor.RatioX-1) -- silly...,

	self[model] = monitor
	return monitor
end

setmetatable(WireGPU_Monitors, { __index = fallback })
