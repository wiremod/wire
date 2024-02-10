
ModelPlug = ModelPlug or {}
local list_set = list.Set

function ModelPlug.ListAddModels( listName, models, value )
	value = value or {}
	for k, v in ipairs(models) do
		list_set(listName, v, value)
	end
end

function ModelPlug.ListAddGenerics( listName, tbl )
	for k, v in pairs(tbl) do
		list_set(listName, k, v)
	end
end

ModelPlug.ListAddGenerics("Wire_Socket_Models", {
	["models/bull/various/usb_socket.mdl"] = {
		ang = Angle(0, 0, 0),
		plug = "models/bull/various/usb_stick.mdl",
		pos = Vector(8, 0, 0)
	},
	["models/hammy/pci_slot.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/hammy/pci_card.mdl",
		pos = Vector(0, 0, 0)
	},
	["models/props_lab/tpplugholder_single.mdl"] = {
		ang = Angle(0, 0, 0),
		plug = "models/props_lab/tpplug.mdl",
		pos = Vector(5, 13, 10)
	},
	["models/wingf0x/altisasocket.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/wingf0x/isaplug.mdl",
		pos = Vector(0, 0, 2.6)
	},
	["models/wingf0x/ethernetsocket.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/wingf0x/ethernetplug.mdl",
		pos = Vector(0, 0, 0)
	},
	["models/wingf0x/hdmisocket.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/wingf0x/hdmiplug.mdl",
		pos = Vector(0, 0, 0)
	},
	["models/wingf0x/isasocket.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/wingf0x/isaplug.mdl",
		pos = Vector(0, 0, 0)
	},
	["models/fasteroid/plugs/usb_c_socket.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/fasteroid/plugs/usb_c_plug.mdl",
		pos = Vector(0, 0, 0)
	},
	["models/fasteroid/plugs/sd_card_socket.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/fasteroid/plugs/sd_card.mdl",
		pos = Vector(0, 0, 0)
	},
	["models/fasteroid/plugs/microusb_socket.mdl"] = {
		ang = Angle(90, 0, 0),
		plug = "models/fasteroid/plugs/microusb_plug.mdl",
		pos = Vector(0, 0, 0)
	},
})

hook.Run("ModelPlugLuaRefresh")
