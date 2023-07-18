CreateConVar("cl_showmodeltextbox", "0")


--[[
-- 3/25/2023: I have no idea what this code does, but it looks important, so I'm leaving it.
-- Loads and converts model lists from the old WireModelPacks format
do
	local converted = {}

	MsgN("WM: Loading models...")
	for _,filename in ipairs( file.Find("WireModelPacks/*", "DATA") ) do
	--for _,filename in ipairs{"bull_buttons.txt","bull_modelpack.txt","cheeze_buttons2.txt","default.txt","expression2.txt","wire_model_pack_1.txt","wire_model_pack_1plus.txt"} do
		filename = "WireModelPacks/"..filename
		print("Loading from WireModelPacks/"..filename)
		local f = file.Read(filename, "DATA")
		if f then
			converted[#converted+1] = "-- Converted from "..filename
			local packtbl = util.KeyValuesToTable(f)
			for name,entry in pairs(packtbl) do
				print(string.format("\tLoaded model %s => %s", name, entry.model))
				local categorytable = string.Explode(",", entry.categories or "none") or { "none" }
				for _,cat in pairs(categorytable) do
					list.Set( "Wire_"..cat.."_Models", entry.model, true )
					converted[#converted+1] = string.format('"%s"
				end
			end
			converted[#converted+1] = ""
		else
			print("Error opening "..filename)
		end
	end
	MsgN("End loading models")

	file.Write("converted.txt", table.concat(converted, "\n"))
end
]]

-- These models are not packaged as part of Wire or base Garry's Mod, so they need special handling:
local externalModels = {
	{"WireScreenModels",			"models/props/cs_office/tv_plasma.mdl"},
	{"WireScreenModels",			"models/props/cs_office/computer_monitor.mdl"},
	{"WireScreenModels",			"models/props/cs_assault/Billboard.mdl"},
	{"WireScreenModels",			"models/props/cs_militia/reload_bullet_tray.mdl"},
	{"WireScreenModels",			"models/props_mining/billboard001.mdl"},
	{"WireScreenModels",			"models/props_mining/billboard002.mdl"},
	{"WireNoGPULibScreenModels",	"models/props/cs_office/tv_plasma.mdl"},
	{"WireNoGPULibScreenModels",	"models/props/cs_office/computer_monitor.mdl"},
	{"Wire_button_Models",			"models/props/switch001.mdl"},
	{"Wire_button_Models",			"models/props_mining/control_lever01.mdl"},
	{"Wire_button_Models",			"models/props_mining/freightelevatorbutton01.mdl"},
	{"Wire_button_Models",			"models/props_mining/freightelevatorbutton02.mdl"},
	{"Wire_button_Models",			"models/props_mining/switch01.mdl"},
	{"Wire_button_Models",			"models/props_mining/switch_updown01.mdl"},
	-- These seem to be missing from wire itself.  Where are they?  Who knows?!
	-- {"ThrusterModels",				"models/jaanus/thruster_invisi.mdl"},
	-- {"ThrusterModels",				"models/jaanus/thruster_shoop.mdl"},
	-- {"ThrusterModels",				"models/jaanus/thruster_smile.mdl"},
	-- {"ThrusterModels",				"models/jaanus/thruster_muff.mdl"},
	-- {"ThrusterModels",				"models/jaanus/thruster_rocket.mdl"},
	-- {"ThrusterModels",				"models/jaanus/thruster_megaphn.mdl"},
	-- {"ThrusterModels",				"models/jaanus/thruster_stun.mdl"},
	-- {"Wire_Value_Models",			"models/cheeze/wires/chip.mdl"},
	{"WireTeleporterModels",		"models/props_c17/pottery03a.mdl"},
	{"Wire_Keyboard_Models",		"models/props/kb_mouse/keyboard.mdl"},
}
for k, v in ipairs(externalModels) do
	if file.Exists(v[2], "GAME") then
		list.Set(v[1], v[2], true)
	end
end

-- Everything else can just be added without checking if it exists

-- first we'll handle these weird singleton lists
list.Set("Wire_waypoint_Models","models/jaanus/wiretool/wiretool_waypoint.mdl")
list.Set("Wire_control_Models","models/jaanus/wiretool/wiretool_controlchip.mdl")
list.Set("Wire_beamcasting_Models", "models/jaanus/wiretool/wiretool_beamcaster.mdl")

--screens with a GPULib setup
ModelPlug.ListAddModels("WireScreenModels", {
	"models/props_lab/monitor01b.mdl",
	"models/props_c17/tv_monitor01.mdl",
	"models/blacknecro/tv_plasma_4_3.mdl",
	"models/kobilica/wiremonitorbig.mdl",
	"models/kobilica/wiremonitorsmall.mdl",
	"models/cheeze/pcb/pcb0.mdl",
	"models/cheeze/pcb/pcb1.mdl",
	"models/cheeze/pcb/pcb2.mdl",
	"models/cheeze/pcb/pcb3.mdl",
	"models/cheeze/pcb/pcb4.mdl",
	"models/cheeze/pcb/pcb6.mdl",
	"models/cheeze/pcb/pcb5.mdl",
	"models/cheeze/pcb/pcb7.mdl",
	"models/cheeze/pcb/pcb8.mdl",
	"models/cheeze/pcb2/pcb8.mdl",
	"models/cheeze/pcb2/pcb1.mdl",
	"models/cheeze/pcb2/pcb2.mdl",
	"models/cheeze/pcb2/pcb3.mdl",
	"models/cheeze/pcb2/pcb4.mdl",
	"models/cheeze/pcb2/pcb5.mdl",
	"models/cheeze/pcb2/pcb6.mdl",
	"models/cheeze/pcb2/pcb7.mdl",
	"models/props_lab/monitor01a.mdl",
	"models/props_lab/monitor02.mdl",
	"models/props_lab/workspace002.mdl",
	"models/props_lab/reciever01b.mdl",
	"models/props_c17/consolebox05a.mdl",
	"models/props_lab/reciever01c.mdl",
	"models/props_lab/reciever01d.mdl",
	"models/props_c17/consolebox01a.mdl",
	"models/props_combine/combine_interface001.mdl",
	"models/props_c17/cashregister01a.mdl",
	"models/props_combine/combine_monitorbay.mdl",
	"models/props_lab/workspace001.mdl",
	"models/props_lab/citizenradio.mdl",
	"models/props_lab/securitybank.mdl",
	"models/beer/wiremod/gate_e2.mdl",
	"models/beer/wiremod/targetfinder.mdl",
	"models/bull/gates/microcontroller1.mdl",
	"models/bull/gates/microcontroller2.mdl",
	"models/jaanus/wiretool/wiretool_gate.mdl",
	"models/jaanus/wiretool/wiretool_controlchip.mdl",
	"models/props_lab/keypad.mdl",
	"models/weapons/w_c4_planted.mdl",
	"models/weapons/w_toolgun.mdl",
	"models/xqm/panel1x1.mdl",
	"models/xqm/panel1x2.mdl",
	"models/xqm/box5s.mdl",
	"models/props_lab/miniteleport.mdl",
	"models/props_lab/plotter.mdl",
	"models/props_combine/combine_interface002.mdl",
	"models/props_combine/combine_interface003.mdl",
	"models/props_combine/combine_intmonitor003.mdl",
	"models/props_combine/combine_intmonitor001.mdl",
	"models/props_lab/workspace003.mdl",
	"models/props_lab/workspace004.mdl",
	"models/props_lab/servers.mdl",
	"models/props_phx/rt_screen.mdl",
	"models/props_wasteland/controlroom_monitor001b.mdl",
	"models/hunter/plates/plate025.mdl",
	"models/hunter/plates/plate025x025.mdl",
	"models/hunter/plates/plate025x05.mdl",
	"models/hunter/plates/plate05x075.mdl",
	"models/hunter/plates/plate05x1.mdl",
	"models/hunter/plates/plate1x1.mdl",
	"models/hunter/plates/plate2x2.mdl",
	"models/hunter/plates/plate4x4.mdl",
	"models/hunter/plates/plate8x8.mdl",
	"models/hunter/plates/plate05x05.mdl",
	"models/hunter/blocks/cube1x1x1.mdl",
	"models/props_lab/reciever01b.mdl",
	"models/fasteroid/bull/lcd1.mdl",
	"models/fasteroid/bull/lcd2.mdl",
	"models/fasteroid/bull/lcd3.mdl",
	"models/fasteroid/bull/lcd4.mdl",
	"models/fasteroid/bull/lcd5.mdl",
	"models/props_phx/construct/windows/window1x1.mdl"
})

--screens without a GPULib setup (for the tools wire_panel and wire_screen)
ModelPlug.ListAddModels("WireNoGPULibScreenModels", {
	"models/props_lab/monitor01b.mdl",
	"models/props/cs_office/tv_plasma.mdl",
	"models/props/cs_office/computer_monitor.mdl",
	"models/kobilica/wiremonitorbig.mdl",
	"models/kobilica/wiremonitorsmall.mdl"
})


--sounds
ModelPlug.ListAddGenerics("WireSounds", {
	["Warning"] = "common/warning.wav",
	["Talk"] = "common/talk.wav",
	["Button"] = "buttons/button15.wav",
	["Denied"] = "buttons/weapon_cant_buy.wav",
	["Zap"] = "ambient/energy/zap2.wav",
	["Oh No"] = "vo/npc/male01/ohno.wav",
	["Yeah"] = "vo/npc/male01/yeah02.wav",
	["apc alarm"] = "ambient/alarms/apc_alarm_loop1.wav",
	["Coast Siren"] = "coast.siren_citizen",
	["Bunker Siren"] = "coast.bunker_siren1",
	["Alarm Bell"] = "d1_canals.Floodgate_AlarmBellLoop",
	["Engine Start"] = "ATV_engine_start",
	["Engine Stop"] = "ATV_engine_stop",
	["Zombie Breathe"] = "NPC_PoisonZombie.Moan1",
	["Idle Zombies"] = "Zombie.Idle",
	["Turret Alert"] = "NPC_FloorTurret.Alert",
	["Helicopter Rotor"] = "NPC_CombineGunship.RotorSound",
	["Heartbeat"] = "k_lab.teleport_heartbeat",
	["Breathing"] = "k_lab.teleport_breathing"
})

--some extra wheels that wired wheels have
ModelPlug.ListAddModels("WheelModels", {
	"models/props_wasteland/wheel01a.mdl",
	"models/props_wasteland/wheel02a.mdl",
	"models/props_wasteland/wheel03a.mdl",
	"models/props_wasteland/wheel03b.mdl"
}, { wheel_rx = 90, wheel_ry = 0, wheel_rz = 90} )

ModelPlug.ListAddModels("Wire_button_Models", {
	"models/props_citizen_tech/Firetrap_button01a.mdl",
	"models/props_c17/clock01.mdl",
	"models/dav0r/buttons/switch.mdl",
	"models/dav0r/buttons/button.mdl",
	"models/cheeze/buttons2/air.mdl",
	"models/cheeze/buttons2/go.mdl",
	"models/cheeze/buttons2/3.mdl",
	"models/cheeze/buttons2/right.mdl",
	"models/cheeze/buttons2/alert.mdl",
	"models/cheeze/buttons2/plus.mdl",
	"models/cheeze/buttons2/activate.mdl",
	"models/cheeze/buttons2/coolant.mdl",
	"models/cheeze/buttons2/pwr_blue.mdl",
	"models/cheeze/buttons2/6.mdl",
	"models/cheeze/buttons2/easy.mdl",
	"models/cheeze/buttons2/muffin.mdl",
	"models/cheeze/buttons2/pwr_red.mdl",
	"models/cheeze/buttons2/1.mdl",
	"models/cheeze/buttons2/8.mdl",
	"models/cheeze/buttons2/aim.mdl",
	"models/cheeze/buttons2/compile.mdl",
	"models/cheeze/buttons2/set.mdl",
	"models/cheeze/buttons2/0.mdl",
	"models/cheeze/buttons2/arm.mdl",
	"models/cheeze/buttons2/test.mdl",
	"models/cheeze/buttons2/left.mdl",
	"models/cheeze/buttons2/pwr_green.mdl",
	"models/cheeze/buttons2/clock.mdl",
	"models/cheeze/buttons2/divide.mdl",
	"models/cheeze/buttons2/fire.mdl",
	"models/cheeze/buttons2/cake.mdl",
	"models/cheeze/buttons2/clear.mdl",
	"models/cheeze/buttons2/4.mdl",
	"models/cheeze/buttons2/power.mdl",
	"models/cheeze/buttons2/5.mdl",
	"models/cheeze/buttons2/deactivate.mdl",
	"models/cheeze/buttons2/down.mdl",
	"models/cheeze/buttons2/minus.mdl",
	"models/cheeze/buttons2/stop.mdl",
	"models/cheeze/buttons2/energy.mdl",
	"models/cheeze/buttons2/charge.mdl",
	"models/cheeze/buttons2/overide.mdl",
	"models/cheeze/buttons2/equals.mdl",
	"models/cheeze/buttons2/up.mdl",
	"models/cheeze/buttons2/toggle.mdl",
	"models/cheeze/buttons2/reset.mdl",
	"models/cheeze/buttons2/enter.mdl",
	"models/cheeze/buttons2/2.mdl",
	"models/cheeze/buttons2/start.mdl",
	"models/cheeze/buttons2/multiply.mdl",
	"models/cheeze/buttons2/7.mdl",
	"models/cheeze/buttons2/9.mdl",
	--animated buttons from here
	"models/props_combine/combinebutton.mdl",
	"models/maxofs2d/button_01.mdl",
	"models/maxofs2d/button_02.mdl",
	"models/maxofs2d/button_03.mdl",
	"models/maxofs2d/button_04.mdl",
	"models/maxofs2d/button_05.mdl",
	"models/maxofs2d/button_06.mdl",
	"models/bull/buttons/toggle_switch.mdl",
	"models/bull/buttons/rocker_switch.mdl",
	"models/bull/buttons/key_switch.mdl"
})

ModelPlug.ListAddModels("ThrusterModels", {
	"models/props_junk/garbage_metalcan001a.mdl",
	"models/jaanus/thruster_flat.mdl",
	"models/fasteroid/computerfan.mdl"
})

ModelPlug.ListAddModels("Wire_Explosive_Models", {
	"models/dav0r/tnt/tnt.mdl",
	"models/Combine_Helicopter/helicopter_bomb01.mdl",
	"models/jaanus/thruster_flat.mdl",
	"models/props_c17/oildrum001.mdl",
	"models/props_c17/oildrum001_explosive.mdl",
	"models/props_phx/cannonball.mdl",
	"models/props_phx/facepunch_barrel.mdl",
	"models/props_phx/oildrum001.mdl",
	"models/props_phx/oildrum001_explosive.mdl",
	"models/props_phx/amraam.mdl",
	"models/props_phx/mk-82.mdl",
	"models/props_phx/rocket1.mdl",
	"models/props_phx/torpedo.mdl",
	"models/props_phx/ww2bomb.mdl",
	"models/props_junk/plasticbucket001a.mdl",
	"models/props_junk/PropaneCanister001a.mdl",
	"models/props_junk/propane_tank001a.mdl",
	"models/props_junk/PopCan01a.mdl",
	"models/props_lab/jar01a.mdl",
	"models/props_c17/canister_propane01a.mdl",
	"models/props_c17/canister01a.mdl",
	"models/props_c17/canister02a.mdl",
	"models/props_wasteland/gaspump001a.mdl",
	"models/props_junk/cardboard_box001a.mdl",
	"models/props_junk/cardboard_box001b.mdl",
	"models/props_junk/cardboard_box002a.mdl",
	"models/props_junk/cardboard_box002b.mdl",
	"models/props_junk/cardboard_box003a.mdl",
	"models/props_junk/cardboard_box003b.mdl",
	"models/props_junk/cardboard_box004a.mdl",
	"models/props_junk/CinderBlock01a.mdl",
	"models/props_junk/gascan001a.mdl",
	"models/props_junk/TrafficCone001a.mdl",
	"models/props_junk/metalgascan.mdl",
	"models/props_junk/metal_paintcan001a.mdl",
	"models/props_junk/wood_crate001a.mdl",
	"models/props_junk/wood_crate002a.mdl",
	"models/props_junk/wood_pallet001a.mdl"
})

ModelPlug.ListAddModels("Wire_Gimbal_Models", {
	"models/props_c17/canister01a.mdl",
	"models/props_interiors/Furniture_Lamp01a.mdl",
	"models/props_c17/oildrum001.mdl",
	"models/props_phx/misc/smallcannon.mdl",
	"models/props_c17/fountain_01.mdl",
	"models/fasteroid/pointer.mdl"
})

ModelPlug.ListAddModels("Wire_Value_Models", {
	"models/kobilica/value.mdl",
	"models/bull/gates/resistor.mdl",
	"models/bull/gates/transistor1.mdl",
	"models/bull/gates/transistor2.mdl",
	"models/cheeze/wires/cpu.mdl",
	"models/cheeze/wires/ram.mdl",
	"models/cheeze/wires/nano_value.mdl"
})

ModelPlug.ListAddModels("WireTeleporterModels", {
	"models/props_c17/utilityconducter001.mdl",
	"models/Combine_Helicopter/helicopter_bomb01.mdl",
	"models/props_combine/combine_interface001.mdl",
	"models/props_combine/combine_interface002.mdl",
	"models/props_combine/combine_interface003.mdl",
	"models/props_combine/combine_emitter01.mdl",
	"models/props_junk/sawblade001a.mdl",
	"models/props_combine/health_charger001.mdl",
	"models/props_combine/suit_charger001.mdl",
	"models/props_lab/reciever_cart.mdl",
	"models/props_lab/reciever01a.mdl",
	"models/props_lab/reciever01b.mdl",
	"models/props_lab/reciever01d.mdl",
	"models/props_wasteland/laundry_washer003.mdl"
})

ModelPlug.ListAddModels("WireTurretModels", {
	"models/weapons/w_smg1.mdl",
	"models/weapons/w_smg_mp5.mdl",
	"models/weapons/w_smg_mac10.mdl",
	"models/weapons/w_rif_m4a1.mdl",
	"models/weapons/w_357.mdl",
	"models/weapons/w_shot_m3super90.mdl"
})

ModelPlug.ListAddModels("Wire_satellitedish_Models", {
	"models/props_wasteland/prison_lamp001c.mdl",
	"models/props_rooftop/satellitedish02.mdl"
})

ModelPlug.ListAddModels("Wire_Light_Models", {
	"models/jaanus/wiretool/wiretool_range.mdl",
	"models/jaanus/wiretool/wiretool_siren.mdl",
	"models/MaxOfS2D/light_tubular.mdl",
	"models/fasteroid/led_mini.mdl"
,	"models/fasteroid/led_nano.mdl"
})

ModelPlug.ListAddModels("Wire_Keyboard_Models",{
	"models/beer/wiremod/keyboard.mdl",
	"models/jaanus/wiretool/wiretool_input.mdl",
	"models/props_c17/computer01_keyboard.mdl"
})

ModelPlug.ListAddModels("Wire_Hydraulic_Models",{
	"models/beer/wiremod/hydraulic.mdl",
	"models/jaanus/wiretool/wiretool_siren.mdl",
	"models/xqm/hydcontrolbox.mdl"
})

ModelPlug.ListAddModels("Wire_GPS_Models",{
	"models/beer/wiremod/gps.mdl",
	"models/jaanus/wiretool/wiretool_speed.mdl"
})

ModelPlug.ListAddModels("Wire_Numpad_Models", {
	"models/beer/wiremod/numpad.mdl",
	"models/jaanus/wiretool/wiretool_input.mdl",
	"models/jaanus/wiretool/wiretool_output.mdl"
})

ModelPlug.ListAddModels("Wire_WaterSensor_Models", {
	"models/beer/wiremod/watersensor.mdl",
	"models/jaanus/wiretool/wiretool_range.mdl"
})

ModelPlug.ListAddModels("Wire_TargetFinder_Models", {
	"models/beer/wiremod/targetfinder.mdl",
	"models/props_lab/powerbox02d.mdl"
})

ModelPlug.ListAddModels("Wire_Forcer_Models", {
	"models/jaanus/wiretool/wiretool_grabber_forcer.mdl",
	"models/jaanus/wiretool/wiretool_siren.mdl",
	"models/fasteroid/computerfan.mdl"
})

ModelPlug.ListAddModels("Wire_Misc_Tools_Models", {
	"models/jaanus/wiretool/wiretool_range.mdl",
	"models/jaanus/wiretool/wiretool_siren.mdl",
	"models/props_lab/powerbox02d.mdl"
})

--Laser Tools (Ranger, User, etc)
ModelPlug.ListAddModels("Wire_Laser_Tools_Models", {
	"models/jaanus/wiretool/wiretool_range.mdl",
	"models/jaanus/wiretool/wiretool_siren.mdl",
	"models/jaanus/wiretool/wiretool_beamcaster.mdl",
	"models/fasteroid/led_mini.mdl"
})

ModelPlug.ListAddModels("Wire_button_small_Models", {
	"models/cheeze/buttons2/0_small.mdl",
	"models/cheeze/buttons2/1_small.mdl",
	"models/cheeze/buttons2/2_small.mdl",
	"models/cheeze/buttons2/3_small.mdl",
	"models/cheeze/buttons2/4_small.mdl",
	"models/cheeze/buttons2/5_small.mdl",
	"models/cheeze/buttons2/6_small.mdl",
	"models/cheeze/buttons2/7_small.mdl",
	"models/cheeze/buttons2/8_small.mdl",
	"models/cheeze/buttons2/9_small.mdl",
	"models/cheeze/buttons2/activate_small.mdl",
	"models/cheeze/buttons2/aim_small.mdl",
	"models/cheeze/buttons2/air_small.mdl",
	"models/cheeze/buttons2/alert_small.mdl",
	"models/cheeze/buttons2/arm_small.mdl",
	"models/cheeze/buttons2/cake_small.mdl",
	"models/cheeze/buttons2/charge_small.mdl",
	"models/cheeze/buttons2/clear_small.mdl",
	"models/cheeze/buttons2/clock_small.mdl",
	"models/cheeze/buttons2/compile_small.mdl",
	"models/cheeze/buttons2/coolant_small.mdl",
	"models/cheeze/buttons2/deactivate_small.mdl",
	"models/cheeze/buttons2/divide_small.mdl",
	"models/cheeze/buttons2/down_small.mdl",
	"models/cheeze/buttons2/easy_small.mdl",
	"models/cheeze/buttons2/energy_small.mdl",
	"models/cheeze/buttons2/enter_small.mdl",
	"models/cheeze/buttons2/equals_small.mdl",
	"models/cheeze/buttons2/fire_small.mdl",
	"models/cheeze/buttons2/go_small.mdl",
	"models/cheeze/buttons2/left_small.mdl",
	"models/cheeze/buttons2/minus_small.mdl",
	"models/cheeze/buttons2/muffin_small.mdl",
	"models/cheeze/buttons2/multiply_small.mdl",
	"models/cheeze/buttons2/overide_small.mdl",
	"models/cheeze/buttons2/plus_small.mdl",
	"models/cheeze/buttons2/power_small.mdl",
	"models/cheeze/buttons2/pwr_blue_small.mdl",
	"models/cheeze/buttons2/pwr_green_small.mdl",
	"models/cheeze/buttons2/pwr_red_small.mdl",
	"models/cheeze/buttons2/reset_small.mdl",
	"models/cheeze/buttons2/right_small.mdl",
	"models/cheeze/buttons2/set_small.mdl",
	"models/cheeze/buttons2/start_small.mdl",
	"models/cheeze/buttons2/stop_small.mdl",
	"models/cheeze/buttons2/test_small.mdl",
	"models/cheeze/buttons2/toggle_small.mdl",
	"models/cheeze/buttons2/up_small.mdl"
})

ModelPlug.ListAddModels("Wire_chip_Models", {
	"models/bull/gates/capacitor.mdl",
	"models/bull/gates/capacitor_mini.mdl",
	"models/bull/gates/capacitor_nano.mdl",
	"models/bull/gates/logic.mdl",
	"models/bull/gates/logic_mini.mdl",
	"models/bull/gates/logic_nano.mdl",
	"models/bull/gates/microcontroller1.mdl",
	"models/bull/gates/microcontroller1_mini.mdl",
	"models/bull/gates/microcontroller1_nano.mdl",
	"models/bull/gates/microcontroller2.mdl",
	"models/bull/gates/microcontroller2_mini.mdl",
	"models/bull/gates/microcontroller2_nano.mdl",
	"models/bull/gates/processor.mdl",
	"models/bull/gates/processor_mini.mdl",
	"models/bull/gates/processor_nano.mdl",
	"models/bull/gates/resistor.mdl",
	"models/bull/gates/resistor_mini.mdl",
	"models/bull/gates/resistor_nano.mdl",
	"models/bull/gates/transistor1.mdl",
	"models/bull/gates/transistor1_mini.mdl",
	"models/bull/gates/transistor1_nano.mdl",
	"models/bull/gates/transistor2.mdl",
	"models/bull/gates/transistor2_mini.mdl",
	"models/bull/gates/transistor2_nano.mdl",
	"models/cheeze/wires/amd_test.mdl",
	"models/cheeze/wires/cpu.mdl",
	"models/cheeze/wires/cpu2.mdl",
	"models/cheeze/wires/mini_chip.mdl",
	"models/cheeze/wires/mini_cpu.mdl",
	"models/cheeze/wires/nano_chip.mdl",
	"models/cheeze/wires/nano_compare.mdl",
	"models/cheeze/wires/nano_logic.mdl",
	"models/cheeze/wires/nano_math.mdl",
	"models/cheeze/wires/nano_memory.mdl",
	"models/cheeze/wires/nano_select.mdl",
	"models/cheeze/wires/nano_timer.mdl",
	"models/cheeze/wires/nano_trig.mdl",
	"models/cheeze/wires/ram.mdl",
	"models/cyborgmatt/capacitor_large.mdl",
	"models/cyborgmatt/capacitor_medium.mdl",
	"models/cyborgmatt/capacitor_small.mdl",
	"models/jaanus/wiretool/wiretool_controlchip.mdl",
	"models/jaanus/wiretool/wiretool_gate.mdl",
	"models/kobilica/capacatitor.mdl",
	"models/kobilica/lowpolygate.mdl",
	"models/kobilica/transistor.mdl",
	"models/kobilica/transistorsmall.mdl",
	"models/fasteroid/inductor.mdl"
})

ModelPlug.ListAddModels("Wire_detonator_Models",{
	"models/jaanus/wiretool/wiretool_detonator.mdl",
	"models/props_combine/breenclock.mdl"
})

ModelPlug.ListAddModels("Wire_dynamic_button_Models", {
	"models/bull/dynamicbutton.mdl",
	"models/bull/dynamicbuttonflat.mdl",
	"models/bull/dynamicbuttonmedium.mdl",
	"models/maxofs2d/button_05.mdl"
})

ModelPlug.ListAddModels("Wire_dynamic_button_small_Models", {
	"models/bull/dynamicbutton_small.mdl",
	"models/bull/dynamicbuttonflat_small.mdl",
	"models/bull/dynamicbuttonmedium_small.mdl"
})


ModelPlug.ListAddModels("Wire_expr2_Models", {
	"models/expression 2/cpu_controller.mdl",
	"models/expression 2/cpu_expression.mdl",
	"models/expression 2/cpu_microchip.mdl"
})

ModelPlug.ListAddModels("Wire_gate_Models", {
	"models/bull/gates/capacitor.mdl",
	"models/bull/gates/capacitor_mini.mdl",
	"models/bull/gates/capacitor_nano.mdl",
	"models/bull/gates/logic.mdl",
	"models/bull/gates/logic_mini.mdl",
	"models/bull/gates/logic_nano.mdl",
	"models/bull/gates/microcontroller1.mdl",
	"models/bull/gates/microcontroller1_mini.mdl",
	"models/bull/gates/microcontroller1_nano.mdl",
	"models/bull/gates/microcontroller2.mdl",
	"models/bull/gates/microcontroller2_mini.mdl",
	"models/bull/gates/microcontroller2_nano.mdl",
	"models/bull/gates/processor.mdl",
	"models/bull/gates/processor_mini.mdl",
	"models/bull/gates/processor_nano.mdl",
	"models/bull/gates/resistor.mdl",
	"models/bull/gates/resistor_mini.mdl",
	"models/bull/gates/resistor_nano.mdl",
	"models/bull/gates/transistor1.mdl",
	"models/bull/gates/transistor1_mini.mdl",
	"models/bull/gates/transistor1_nano.mdl",
	"models/bull/gates/transistor2.mdl",
	"models/bull/gates/transistor2_mini.mdl",
	"models/bull/gates/transistor2_nano.mdl",
	"models/cheeze/wires/amd_test.mdl",
	"models/cheeze/wires/cpu.mdl",
	"models/cheeze/wires/cpu2.mdl",
	"models/cheeze/wires/mini_chip.mdl",
	"models/cheeze/wires/mini_cpu.mdl",
	"models/cheeze/wires/nano_chip.mdl",
	"models/cheeze/wires/nano_compare.mdl",
	"models/cheeze/wires/nano_logic.mdl",
	"models/cheeze/wires/nano_math.mdl",
	"models/cheeze/wires/nano_memory.mdl",
	"models/cheeze/wires/nano_select.mdl",
	"models/cheeze/wires/nano_timer.mdl",
	"models/cheeze/wires/nano_trig.mdl",
	"models/cheeze/wires/ram.mdl",
	"models/cyborgmatt/capacitor_large.mdl",
	"models/cyborgmatt/capacitor_medium.mdl",
	"models/cyborgmatt/capacitor_small.mdl",
	"models/jaanus/wiretool/wiretool_controlchip.mdl",
	"models/jaanus/wiretool/wiretool_gate.mdl",
	"models/kobilica/capacatitor.mdl",
	"models/kobilica/lowpolygate.mdl",
	"models/kobilica/transistor.mdl",
	"models/kobilica/transistorsmall.mdl",
	"models/fasteroid/inductor.mdl"
})

ModelPlug.ListAddModels("Wire_gyroscope_Models",{
	"models/bull/various/gyroscope.mdl",
	"models/cheeze/wires/gyroscope.mdl"
})

ModelPlug.ListAddModels("Wire_indicator_Models", {
	"models/jaanus/wiretool/wiretool_pixel_lrg.mdl",
	"models/jaanus/wiretool/wiretool_pixel_med.mdl",
	"models/jaanus/wiretool/wiretool_pixel_sml.mdl",
	"models/jaanus/wiretool/wiretool_range.mdl",
	"models/jaanus/wiretool/wiretool_siren.mdl",
	"models/led.mdl",
	"models/led2.mdl",
	"models/props_borealis/bluebarrel001.mdl",
	"models/props_c17/clock01.mdl",
	"models/props_c17/gravestone004a.mdl",
	"models/props_junk/PopCan01a.mdl",
	"models/props_junk/TrafficCone001a.mdl",
	"models/props_trainstation/trainstation_clock001.mdl",
	"models/segment.mdl",
	"models/segment2.mdl",
	"models/fasteroid/led_mini.mdl"
,	"models/fasteroid/led_nano.mdl"
})

ModelPlug.ListAddModels("Wire_pixel_Models", {
	"models/jaanus/wiretool/wiretool_pixel_lrg.mdl",
	"models/jaanus/wiretool/wiretool_pixel_med.mdl",
	"models/jaanus/wiretool/wiretool_pixel_sml.mdl",
	"models/jaanus/wiretool/wiretool_range.mdl",
	"models/jaanus/wiretool/wiretool_siren.mdl",
	"models/led.mdl",
	"models/led2.mdl",
	"models/props_junk/PopCan01a.mdl",
	"models/segment.mdl",
	"models/segment2.mdl",
	"models/fasteroid/led_mini.mdl"
,	"models/fasteroid/led_nano.mdl"
})

ModelPlug.ListAddModels("Wire_radio_Models", {
	"models/cheeze/wires/router.mdl",
	"models/cheeze/wires/wireless_card.mdl",
	"models/props_lab/binderblue.mdl",
	"models/props_lab/reciever01a.mdl",
	"models/props_lab/reciever01b.mdl",
	"models/props_lab/reciever01c.mdl"
})

ModelPlug.ListAddModels("Wire_speaker_Models",{
	"models/bull/various/speaker.mdl",
	"models/bull/various/subwoofer.mdl",
	"models/cheeze/wires/speaker.mdl",
	"models/killa-x/speakers/speaker_medium.mdl",
	"models/killa-x/speakers/speaker_small.mdl",
	"models/props_junk/garbage_metalcan002a.mdl",
	"models/props_junk/garbage_metalcan002a.mdl"
})

ModelPlug.ListAddModels("Wire_weight_Models", {
	"models/props_interiors/pot01a.mdl",
	"models/props_lab/huladoll.mdl"
})

ModelPlug.ListAddModels("Wire_InteractiveProp_Models", {
	"models/props_lab/reciever01a.mdl",
	"models/props_lab/reciever01b.mdl",
	"models/props_lab/keypad.mdl",
	"models/beer/wiremod/numpad.mdl",
	"models/props_interiors/bathtub01a.mdl",
	"models/props_c17/furnituresink001a.mdl",
	"models/props_interiors/sinkkitchen01a.mdl",
	"models/props_wasteland/prison_sink001a.mdl",
	"models/props_lab/citizenradio.mdl",
	"models/props_c17/furniturewashingmachine001a.mdl",
	"models/props_lab/plotter.mdl",
	"models/props_interiors/vendingmachinesoda01a.mdl",
	"models/props_lab/reciever01c.mdl",
	"models/props_trainstation/payphone001a.mdl"
})

--Dynamic button materials
local WireDynamicButtonMaterials = {
	["No Material"] = "",
	["Clean"] = "bull/dynamic_button_clean",
	["0"]     = "bull/dynamic_button_0",
	["1"]     = "bull/dynamic_button_1",
	["2"]     = "bull/dynamic_button_2",
	["3"]     = "bull/dynamic_button_3",
	["4"]     = "bull/dynamic_button_4",
	["5"]     = "bull/dynamic_button_5",
	["6"]     = "bull/dynamic_button_6",
	["7"]     = "bull/dynamic_button_7",
	["8"]     = "bull/dynamic_button_8",
	["9"]     = "bull/dynamic_button_9"
}
for k,v in pairs(WireDynamicButtonMaterials) do
	list.Set("WireDynamicButtonMaterialsOn" ,k,{wire_dynamic_button_material_on =v});
	list.Set("WireDynamicButtonMaterialsOff",k,{wire_dynamic_button_material_off=v});
end

--Cheeze's Buttons Pack
local CheezesButtons = {
	"models/cheeze/buttons/button_arm.mdl",
	"models/cheeze/buttons/button_clear.mdl",
	"models/cheeze/buttons/button_enter.mdl",
	"models/cheeze/buttons/button_fire.mdl",
	"models/cheeze/buttons/button_minus.mdl",
	"models/cheeze/buttons/button_muffin.mdl",
	"models/cheeze/buttons/button_plus.mdl",
	"models/cheeze/buttons/button_reset.mdl",
	"models/cheeze/buttons/button_set.mdl",
	"models/cheeze/buttons/button_start.mdl",
	"models/cheeze/buttons/button_stop.mdl",
}
for k,v in ipairs(CheezesButtons) do
	list.Set( "ButtonModels", v, {} )
	list.Set( "Wire_button_Models", v, true )
end

local CheezesSmallButtons = {
	"models/cheeze/buttons/button_0.mdl",
	"models/cheeze/buttons/button_1.mdl",
	"models/cheeze/buttons/button_2.mdl",
	"models/cheeze/buttons/button_3.mdl",
	"models/cheeze/buttons/button_4.mdl",
	"models/cheeze/buttons/button_5.mdl",
	"models/cheeze/buttons/button_6.mdl",
	"models/cheeze/buttons/button_7.mdl",
	"models/cheeze/buttons/button_8.mdl",
	"models/cheeze/buttons/button_9.mdl",
}
for k,v in ipairs(CheezesSmallButtons) do
	list.Set( "ButtonModels", v, {} )
	list.Set( "Wire_button_small_Models", v, true )
end