--Msg("=== Loading Wire Model Packs ===\n")

CreateConVar("cl_showmodeltextbox", "0")

--[[
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
					converted[#converted+1] = string.format('list.Set("Wire_%s_Models", "%s", true)', cat, entry.model)
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

--
--	Add some more options to the stools
--

--screens with a GPULib setup
list.Set( "WireScreenModels", "models/props_lab/monitor01b.mdl", true )
list.Set( "WireScreenModels", "models/props/cs_office/tv_plasma.mdl", true )
list.Set( "WireScreenModels", "models/blacknecro/tv_plasma_4_3.mdl", true )
list.Set( "WireScreenModels", "models/props/cs_office/computer_monitor.mdl", true )
list.Set( "WireScreenModels", "models/kobilica/wiremonitorbig.mdl", true )
list.Set( "WireScreenModels", "models/kobilica/wiremonitorsmall.mdl", true )
list.Set( "WireScreenModels", "models/props/cs_assault/Billboard.mdl", true )
list.Set( "WireScreenModels", "models/cheeze/pcb/pcb4.mdl", true )
list.Set( "WireScreenModels", "models/cheeze/pcb/pcb6.mdl", true )
list.Set( "WireScreenModels", "models/cheeze/pcb/pcb5.mdl", true )
list.Set( "WireScreenModels", "models/cheeze/pcb/pcb7.mdl", true )
list.Set( "WireScreenModels", "models/cheeze/pcb/pcb8.mdl", true )
list.Set( "WireScreenModels", "models/cheeze/pcb2/pcb8.mdl", true )
list.Set( "WireScreenModels", "models/props/cs_militia/reload_bullet_tray.mdl", true )
list.Set( "WireScreenModels", "models/props_lab/workspace002.mdl", true )
--list.Set( "WireScreenModels", "models/blacknecro/ledboard60.mdl", true ) --broken

--TF2 Billboards
list.Set( "WireScreenModels", "models/props_mining/billboard001.mdl", true )
list.Set( "WireScreenModels", "models/props_mining/billboard002.mdl", true )

--PHX3
list.Set( "WireScreenModels", "models/hunter/plates/plate1x1.mdl", true )
list.Set( "WireScreenModels", "models/hunter/plates/plate2x2.mdl", true )
list.Set( "WireScreenModels", "models/hunter/plates/plate4x4.mdl", true )
list.Set( "WireScreenModels", "models/hunter/plates/plate8x8.mdl", true )
list.Set( "WireScreenModels", "models/hunter/plates/plate05x05.mdl", true )
list.Set( "WireScreenModels", "models/hunter/blocks/cube1x1x1.mdl", true )

--screens with out a GPULib setup (for the tools wire_panel and wire_screen)
list.Set( "WireNoGPULibScreenModels", "models/props_lab/monitor01b.mdl", true )
list.Set( "WireNoGPULibScreenModels", "models/props/cs_office/tv_plasma.mdl", true )
list.Set( "WireNoGPULibScreenModels", "models/props/cs_office/computer_monitor.mdl", true )
list.Set( "WireNoGPULibScreenModels", "models/kobilica/wiremonitorbig.mdl", true )
list.Set( "WireNoGPULibScreenModels", "models/kobilica/wiremonitorsmall.mdl", true )

--sounds
local WireSounds = {
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
	["Breathing"] = "k_lab.teleport_breathing",
}
for k,v in pairs(WireSounds) do
	list.Set("WireSounds",k,{wire_soundemitter_sound=v});
end


--some extra wheels that wired wheels have
local wastelandwheels = {
	"models/props_wasteland/wheel01a.mdl",
	"models/props_wasteland/wheel02a.mdl",
	"models/props_wasteland/wheel03a.mdl",
	"models/props_wasteland/wheel03b.mdl"
}
for k,v in pairs(wastelandwheels) do
	if file.Exists(v,"GAME") then
	list.Set( "WheelModels", v, { wheel_rx = 90, wheel_ry = 0, wheel_rz = 90} )
	end
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
	if file.Exists(v,"GAME") then
		list.Set( "ButtonModels", v, {} )
		list.Set( "Wire_button_Models", v, true )
	end
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
	if file.Exists(v,"GAME") then
		list.Set( "ButtonModels", v, {} )
		list.Set( "Wire_button_small_Models", v, true )
	end
end

local Buttons = {
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
	"models/props_lab/freightelevatorbutton.mdl",
	"models/props/switch001.mdl",
	"models/props_combine/combinebutton.mdl",
	"models/props_mining/control_lever01.mdl",
	"models/props_mining/freightelevatorbutton01.mdl",
	"models/props_mining/freightelevatorbutton02.mdl",
	"models/props_mining/switch01.mdl",
	"models/props_mining/switch_updown01.mdl",
	"models/maxofs2d/button_01.mdl",
	"models/maxofs2d/button_02.mdl",
	"models/maxofs2d/button_03.mdl",
	"models/maxofs2d/button_04.mdl",
	"models/maxofs2d/button_05.mdl",
	"models/maxofs2d/button_06.mdl",
	"models/bull/buttons/toggle_switch.mdl",
	"models/bull/buttons/rocker_switch.mdl",
	"models/bull/buttons/key_switch.mdl",
}
for k,v in ipairs(Buttons) do
	if file.Exists(v,"GAME") then
		list.Set( "Wire_button_Models", v, true )
	end
end

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

--Thrusters
--Jaanus Thruster Pack
--MsgN("\tJaanus' Thruster Pack")
local JaanusThrusters = {
	"models/props_junk/garbage_metalcan001a.mdl",
	"models/jaanus/thruster_flat.mdl",
	"models/jaanus/thruster_invisi.mdl",
	"models/jaanus/thruster_shoop.mdl",
	"models/jaanus/thruster_smile.mdl",
	"models/jaanus/thruster_muff.mdl",
	"models/jaanus/thruster_rocket.mdl",
	"models/jaanus/thruster_megaphn.mdl",
	"models/jaanus/thruster_stun.mdl"
}
for k,v in pairs(JaanusThrusters) do
	if file.Exists(v,"GAME") then
		list.Set( "ThrusterModels", v, true )
	end
end

local explosivemodels = {
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
	"models/props_junk/wood_pallet001a.mdl",
}
for k,v in pairs(explosivemodels) do
	if file.Exists(v,"GAME") then list.Set( "Wire_Explosive_Models", v, true ) end
end

for k,v in pairs({
		"models/props_c17/canister01a.mdl",
		"models/props_interiors/Furniture_Lamp01a.mdl",
		"models/props_c17/oildrum001.mdl",
		"models/props_phx/misc/smallcannon.mdl",
		"models/props_c17/fountain_01.mdl"
	}) do
	if file.Exists(v,"GAME") then
		list.Set( "Wire_Gimbal_Models", v, true )
	end
end

local valuemodels = {
	"models/kobilica/value.mdl",
	"models/bull/gates/resistor.mdl",
	"models/bull/gates/transistor1.mdl",
	"models/bull/gates/transistor2.mdl",
	"models/cheeze/wires/cpu.mdl",
	"models/cheeze/wires/chip.mdl",
	"models/cheeze/wires/ram.mdl",
	"models/cheeze/wires/nano_value.mdl", -- This guy doesn't have a normal sized one in that folder
}
for k,v in pairs(valuemodels) do
	if file.Exists(v,"GAME") then list.Set( "Wire_Value_Models", v, true ) end
end

local teleportermodels = {
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
	"models/props_c17/pottery03a.mdl",
	"models/props_wasteland/laundry_washer003.mdl"
}
for k,v in pairs(teleportermodels) do
	if file.Exists(v,"GAME") then list.Set( "WireTeleporterModels", v, true ) end
end

local turretmodels = {
	"models/weapons/w_smg1.mdl",
	"models/weapons/w_smg_mp5.mdl",
	"models/weapons/w_smg_mac10.mdl",
	"models/weapons/w_rif_m4a1.mdl",
	"models/weapons/w_357.mdl",
	"models/weapons/w_shot_m3super90.mdl"
}
for k,v in pairs(turretmodels) do
	if file.Exists(v,"GAME") then list.Set( "WireTurretModels", v, true ) end
end

local satellitedish_models = {
	"models/props_wasteland/prison_lamp001c.mdl",
	"models/props_rooftop/satellitedish02.mdl", -- EP2, but its perfect
}
for k,v in pairs(satellitedish_models) do
	if file.Exists(v,"GAME") then
		list.Set( "Wire_satellitedish_Models", v, true )
	end
end

--Beer's models
--MsgN("\tBeer's Model pack")

--Keyboard
list.Set( "Wire_Keyboard_Models", "models/beer/wiremod/keyboard.mdl", true )
list.Set( "Wire_Keyboard_Models", "models/jaanus/wiretool/wiretool_input.mdl", true )
list.Set( "Wire_Keyboard_Models", "models/props/kb_mouse/keyboard.mdl", true )
list.Set( "Wire_Keyboard_Models", "models/props_c17/computer01_keyboard.mdl", true )

--Hydraulic
list.Set( "Wire_Hydraulic_Models", "models/beer/wiremod/hydraulic.mdl", true )
list.Set( "Wire_Hydraulic_Models", "models/jaanus/wiretool/wiretool_siren.mdl", true )

--GPS
list.Set( "Wire_GPS_Models", "models/beer/wiremod/gps.mdl", true )
list.Set( "Wire_GPS_Models", "models/jaanus/wiretool/wiretool_speed.mdl", true )

--Numpad
list.Set( "Wire_Numpad_Models", "models/beer/wiremod/numpad.mdl", true )
list.Set( "Wire_Numpad_Models", "models/jaanus/wiretool/wiretool_input.mdl", true )
list.Set( "Wire_Numpad_Models", "models/jaanus/wiretool/wiretool_output.mdl", true )

--Water Sensor
list.Set( "Wire_WaterSensor_Models", "models/beer/wiremod/watersensor.mdl", true )
list.Set( "Wire_WaterSensor_Models", "models/jaanus/wiretool/wiretool_range.mdl", true )

--Target Finder
list.Set( "Wire_TargetFinder_Models", "models/beer/wiremod/targetfinder.mdl", true )
list.Set( "Wire_TargetFinder_Models", "models/props_lab/powerbox02d.mdl", true )

list.Set( "Wire_Forcer_Models", "models/jaanus/wiretool/wiretool_grabber_forcer.mdl", true )
list.Set( "Wire_Forcer_Models", "models/jaanus/wiretool/wiretool_siren.mdl", true )

--Misc Tools (Entity Marker, Eye Pod, GpuLib Switcher, ect...)
list.Set( "Wire_Misc_Tools_Models", "models/jaanus/wiretool/wiretool_range.mdl", true )
list.Set( "Wire_Misc_Tools_Models", "models/jaanus/wiretool/wiretool_siren.mdl", true )
list.Set( "Wire_Misc_Tools_Models", "models/props_lab/powerbox02d.mdl", true )

--Laser Tools (Ranger, User, etc)
list.Set( "Wire_Laser_Tools_Models", "models/jaanus/wiretool/wiretool_range.mdl", true )
list.Set( "Wire_Laser_Tools_Models", "models/jaanus/wiretool/wiretool_siren.mdl", true )
list.Set( "Wire_Laser_Tools_Models", "models/jaanus/wiretool/wiretool_beamcaster.mdl", true )

list.Set( "Wire_Socket_Models", "models/props_lab/tpplugholder_single.mdl", true )
list.Set( "Wire_Socket_Models", "models/bull/various/usb_socket.mdl", true )
list.Set( "Wire_Socket_Models", "models/hammy/pci_slot.mdl", true )
list.Set( "Wire_Socket_Models", "models/wingf0x/isasocket.mdl", true )
list.Set( "Wire_Socket_Models", "models/wingf0x/altisasocket.mdl", true )
list.Set( "Wire_Socket_Models", "models/wingf0x/ethernetsocket.mdl", true )
list.Set( "Wire_Socket_Models", "models/wingf0x/hdmisocket.mdl", true )

-- Converted from WireModelPacks/wire_model_pack_1plus.txt
list.Set("Wire_radio_Models", "models/props_lab/reciever01b.mdl", true)
list.Set("Wire_pixel_Models", "models/jaanus/wiretool/wiretool_pixel_med.mdl", true)
list.Set("Wire_indicator_Models", "models/jaanus/wiretool/wiretool_pixel_med.mdl", true)
list.Set("Wire_waypoint_Models", "models/jaanus/wiretool/wiretool_waypoint.mdl", true)
list.Set("Wire_pixel_Models", "models/jaanus/wiretool/wiretool_pixel_sml.mdl", true)
list.Set("Wire_indicator_Models", "models/jaanus/wiretool/wiretool_pixel_sml.mdl", true)
list.Set("Wire_radio_Models", "models/props_lab/reciever01a.mdl", true)
list.Set("Wire_gate_Models", "models/jaanus/wiretool/wiretool_controlchip.mdl", true)
list.Set("Wire_chip_Models", "models/jaanus/wiretool/wiretool_controlchip.mdl", true)
list.Set("Wire_control_Models", "models/jaanus/wiretool/wiretool_controlchip.mdl", true)
list.Set("Wire_detonator_Models", "models/jaanus/wiretool/wiretool_detonator.mdl", true)
list.Set("Wire_beamcasting_Models", "models/jaanus/wiretool/wiretool_beamcaster.mdl", true)
list.Set("Wire_radio_Models", "models/props_lab/reciever01c.mdl", true)
list.Set("Wire_pixel_Models", "models/jaanus/wiretool/wiretool_pixel_lrg.mdl", true)
list.Set("Wire_indicator_Models", "models/jaanus/wiretool/wiretool_pixel_lrg.mdl", true)

-- Converted from WireModelPacks/wire_model_pack_1.txt
list.Set("Wire_gate_Models", "models/cheeze/wires/amd_test.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/amd_test.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/mini_cpu.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/mini_cpu.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/ram.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/ram.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_logic.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_logic.mdl", true)
list.Set("Wire_gate_Models", "models/kobilica/transistorsmall.mdl", true)
list.Set("Wire_chip_Models", "models/kobilica/transistorsmall.mdl", true)
list.Set("Wire_gate_Models", "models/kobilica/transistor.mdl", true)
list.Set("Wire_chip_Models", "models/kobilica/transistor.mdl", true)
list.Set("Wire_radio_Models", "models/cheeze/wires/wireless_card.mdl", true)
list.Set("Wire_gate_Models", "models/cyborgmatt/capacitor_large.mdl", true)
list.Set("Wire_chip_Models", "models/cyborgmatt/capacitor_large.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_memory.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_memory.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_trig.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_trig.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_chip.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_chip.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/cpu2.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/cpu2.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_math.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_math.mdl", true)
list.Set("Wire_radio_Models", "models/cheeze/wires/router.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_select.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_select.mdl", true)
list.Set("Wire_gate_Models", "models/cyborgmatt/capacitor_medium.mdl", true)
list.Set("Wire_chip_Models", "models/cyborgmatt/capacitor_medium.mdl", true)
list.Set("Wire_gate_Models", "models/cyborgmatt/capacitor_small.mdl", true)
list.Set("Wire_chip_Models", "models/cyborgmatt/capacitor_small.mdl", true)
list.Set("Wire_speaker_Models", "models/killa-x/speakers/speaker_small.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_compare.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_compare.mdl", true)
list.Set("Wire_speaker_Models", "models/killa-x/speakers/speaker_medium.mdl", true)
list.Set("Wire_speaker_Models", "models/props_junk/garbage_metalcan002a.mdl", true)
list.Set("Wire_gate_Models", "models/kobilica/capacatitor.mdl", true)
list.Set("Wire_chip_Models", "models/kobilica/capacatitor.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/cpu.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/cpu.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/mini_chip.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/mini_chip.mdl", true)
list.Set("Wire_gate_Models", "models/kobilica/lowpolygate.mdl", true)
list.Set("Wire_chip_Models", "models/kobilica/lowpolygate.mdl", true)
list.Set("Wire_gate_Models", "models/cheeze/wires/nano_timer.mdl", true)
list.Set("Wire_chip_Models", "models/cheeze/wires/nano_timer.mdl", true)

-- Converted from WireModelPacks/expression2.txt
list.Set("Wire_expr2_Models", "models/expression 2/cpu_controller.mdl", true)
list.Set("Wire_expr2_Models", "models/expression 2/cpu_microchip.mdl", true)
list.Set("Wire_expr2_Models", "models/expression 2/cpu_expression.mdl", true)

-- Converted from WireModelPacks/default.txt
list.Set("Wire_pixel_Models", "models/segment2.mdl", true)
list.Set("Wire_indicator_Models", "models/segment2.mdl", true)
list.Set("Wire_indicator_Models", "models/props_trainstation/trainstation_clock001.mdl", true)
list.Set("Wire_pixel_Models", "models/segment.mdl", true)
list.Set("Wire_indicator_Models", "models/segment.mdl", true)
list.Set("Wire_gyroscope_Models", "models/bull/various/gyroscope.mdl", true)
list.Set("Wire_weight_Models", "models/props_interiors/pot01a.mdl", true)
list.Set("Wire_pixel_Models", "models/jaanus/wiretool/wiretool_siren.mdl", true)
list.Set("Wire_indicator_Models", "models/jaanus/wiretool/wiretool_siren.mdl", true)
list.Set("Wire_indicator_Models", "models/props_borealis/bluebarrel001.mdl", true)
list.Set("Wire_indicator_Models", "models/props_junk/TrafficCone001a.mdl", true)
list.Set("Wire_speaker_Models", "models/props_junk/garbage_metalcan002a.mdl", true)
list.Set("Wire_pixel_Models", "models/led2.mdl", true)
list.Set("Wire_indicator_Models", "models/led2.mdl", true)
list.Set("Wire_weight_Models", "models/props_lab/huladoll.mdl", true)
list.Set("Wire_radio_Models", "models/props_lab/binderblue.mdl", true)
list.Set("Wire_pixel_Models", "models/led.mdl", true)
list.Set("Wire_indicator_Models", "models/led.mdl", true)
list.Set("Wire_gyroscope_Models", "models/cheeze/wires/gyroscope.mdl", true)
list.Set("Wire_pixel_Models", "models/jaanus/wiretool/wiretool_range.mdl", true)
list.Set("Wire_indicator_Models", "models/jaanus/wiretool/wiretool_range.mdl", true)
list.Set("Wire_pixel_Models", "models/props_junk/PopCan01a.mdl", true)
list.Set("Wire_indicator_Models", "models/props_junk/PopCan01a.mdl", true)
list.Set("Wire_gate_Models", "models/jaanus/wiretool/wiretool_gate.mdl", true)
list.Set("Wire_chip_Models", "models/jaanus/wiretool/wiretool_gate.mdl", true)
list.Set("Wire_detonator_Models", "models/props_combine/breenclock.mdl", true)
list.Set("Wire_speaker_Models", "models/cheeze/wires/speaker.mdl", true)
list.Set("Wire_indicator_Models", "models/props_c17/clock01.mdl", true)
list.Set("Wire_indicator_Models", "models/props_c17/gravestone004a.mdl", true)

-- Converted from WireModelPacks/cheeze_buttons2.txt
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/compile_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/arm_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/fire_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/left_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/clear_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/aim_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/1_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/up_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/plus_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/stop_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/minus_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/6_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/coolant_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/power_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/toggle_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/activate_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/overide_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/pwr_red_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/go_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/pwr_blue_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/test_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/equals_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/energy_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/divide_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/clock_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/charge_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/alert_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/enter_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/5_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/2_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/deactivate_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/7_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/0_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/cake_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/reset_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/multiply_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/down_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/pwr_green_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/3_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/4_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/set_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/start_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/right_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/easy_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/8_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/muffin_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/air_small.mdl", true)
list.Set("Wire_button_small_Models", "models/cheeze/buttons2/9_small.mdl", true)

-- Converted from WireModelPacks/bull_modelpack.txt
list.Set("Wire_gate_Models", "models/bull/gates/processor.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/processor.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/resistor_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/resistor_mini.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/microcontroller2_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/microcontroller2_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/transistor2_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/transistor2_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/transistor1.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/transistor1.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/logic_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/logic_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/resistor_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/resistor_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/microcontroller2.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/microcontroller2.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/logic.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/logic.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/processor_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/processor_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/microcontroller1_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/microcontroller1_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/capacitor_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/capacitor_mini.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/capacitor_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/capacitor_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/transistor1_nano.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/transistor1_nano.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/microcontroller2_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/microcontroller2_mini.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/microcontroller1_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/microcontroller1_mini.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/resistor.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/resistor.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/transistor2.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/transistor2.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/capacitor.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/capacitor.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/transistor1_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/transistor1_mini.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/microcontroller1.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/microcontroller1.mdl", true)
list.Set("Wire_speaker_Models", "models/bull/various/speaker.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/logic_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/logic_mini.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/processor_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/processor_mini.mdl", true)
list.Set("Wire_gate_Models", "models/bull/gates/transistor2_mini.mdl", true)
list.Set("Wire_chip_Models", "models/bull/gates/transistor2_mini.mdl", true)
list.Set("Wire_speaker_Models", "models/bull/various/subwoofer.mdl", true)

-- Converted from WireModelPacks/bull_buttons.txt
list.Set("Wire_dynamic_button_Models", "models/bull/dynamicbuttonmedium.mdl", true)
list.Set("Wire_dynamic_button_Models", "models/bull/dynamicbuttonflat.mdl", true)
list.Set("Wire_dynamic_button_Models", "models/bull/dynamicbutton.mdl", true)
list.Set("Wire_dynamic_button_small_Models", "models/bull/dynamicbuttonmedium_small.mdl", true)
list.Set("Wire_dynamic_button_small_Models", "models/bull/dynamicbutton_small.mdl", true)
list.Set("Wire_dynamic_button_small_Models", "models/bull/dynamicbuttonflat_small.mdl", true)
list.Set("Wire_dynamic_button_Models", "models/maxofs2d/button_05.mdl", true)
