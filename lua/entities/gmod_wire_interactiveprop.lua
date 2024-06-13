AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Interactive Prop (Wire)"
ENT.WireDebugName	= "Interactive Prop"

local InteractiveModels

local function copyPropUI(prop, newName)
	local new = table.Copy( InteractiveModels[prop] )
	new.title = newName
	return new
end

InteractiveModels = {

	["models/props_lab/reciever01a.mdl"] = {
		width=220,
		height=100,
		title="Reciever01a",
		widgets={
			{type="DCheckBox",			x=20,	y=50,name="Switch1"},
			{type="DCheckBox",			x=40,	y=50,name="Switch2"},
			{type="DNumberScratch", x=60,	y=40,name="Knob1"	},
			{type="DNumberScratch", x=80,	y=40,name="Knob2"	},
			{type="DNumberScratch", x=100, y=40,name="Knob3"	},
			{type="DNumberScratch", x=120, y=40,name="Knob4"	},
			{type="DNumberScratch", x=140, y=40,name="Knob5"	},
			{type="DNumberScratch", x=160, y=40,name="Knob6"	},
			{type="DNumberScratch", x=180, y=40,name="Knob7"	},
			{type="DNumberScratch", x=60,	y=60,name="Knob8"	},
			{type="DNumberScratch", x=80,	y=60,name="Knob9"	},
			{type="DNumberScratch", x=100, y=60,name="Knob10" },
			{type="DNumberScratch", x=120, y=60,name="Knob11" },
			{type="DNumberScratch", x=140, y=60,name="Knob12" },
			{type="DNumberScratch", x=160, y=60,name="Knob13" },
			{type="DNumberScratch", x=180, y=60,name="Knob14" }
		}
	},

	["models/props_lab/reciever01b.mdl"] = {
		width=190,
		height=100,
		title="Reciever01b",
		widgets={
			{type="DButton",				x=28,	y=40,name="Button1"},
			{type="DButton",				x=58,	y=40,name="Button2"},
			{type="DButton",				x=88,	y=40,name="Button3"},
			{type="DButton",				x=118, y=40,name="Button4"},
			{type="DNumberScratch", x=30,	y=70,name="Knob1"	},
			{type="DNumberScratch", x=60,	y=70,name="Knob2"	},
			{type="DNumberScratch", x=90,	y=70,name="Knob3"	},
			{type="DNumberScratch", x=120, y=70,name="Knob4"	},
			{type="DNumberScratch", x=150, y=43,name="Knob5"	},
			{type="DNumberScratch", x=150, y=67,name="Knob6"	},
		}
	},

	["models/props_lab/keypad.mdl"] = {
		width=100,
		height=120,
		title="Keypad",
		widgets={
			{type="DButton", x=10, y=30, text="1", name="1"},
			{type="DButton", x=40, y=30, text="2", name="2"},
			{type="DButton", x=70, y=30, text="3", name="3"},
			{type="DButton", x=10, y=60, text="4", name="4"},
			{type="DButton", x=40, y=60, text="5", name="5"},
			{type="DButton", x=70, y=60, text="6", name="6"},
			{type="DButton", x=10, y=90, text="7", name="7"},
			{type="DButton", x=40, y=90, text="8", name="8"},
			{type="DButton", x=70, y=90, text="9", name="9"},
		}
	},

	["models/beer/wiremod/numpad.mdl"] = {
		width=130,
		height=180,
		title="Numpad",
		widgets={
			{type="DButton", x=10, y=150, text="0", name="0", width = 50},
			{type="DButton", x=10, y=120, text="1", name="1"},
			{type="DButton", x=40, y=120, text="2", name="2"},
			{type="DButton", x=70, y=120, text="3", name="3"},
			{type="DButton", x=10, y=90, text="4", name="4"},
			{type="DButton", x=40, y=90, text="5", name="5"},
			{type="DButton", x=70, y=90, text="6", name="6"},
			{type="DButton", x=10, y=60, text="7", name="7"},
			{type="DButton", x=40, y=60, text="8", name="8"},
			{type="DButton", x=70, y=60, text="9", name="9"},
			{type="DButton", x=100, y=120, text="E", name="Enter", height = 50},
			{type="DButton", x=100, y=60, text="+", name="+", height = 50},
			{type="DButton", x=100, y=30, text="-", name="-"},
			{type="DButton", x=70, y=30, text="*", name="*"},
			{type="DButton", x=40, y=30, text="/", name="/"},
			{type="DButton", x=70, y=150, text=".", name="."},
			{type="DButton", x=10, y=30, text="N", name="Numlock"},
		}
	},

	["models/props_interiors/bathtub01a.mdl"] = {
		width=100,
		height=60,
		title="BathTub01a",
		widgets={
			{type="DNumberScratch", x=10, y=32, name="Hot", color=Color(237, 59, 59)},
			{type="DNumberScratch", x=74, y=32, name="Cold", color=Color(59, 79, 235)},
		}
	},
	["models/props_lab/citizenradio.mdl"] = {
		width=160,
		height=90,
		title="citizenradio",
		widgets={
			{type="DNumberScratch", x=10,y=30, name="Knob1"},
			{type="DNumberScratch", x=80,y=30, name="Knob2"},
			{type="DNumberScratch", x=120,y=30, name="Knob3"},
			{type="DNumberScratch", x=10,y=60, name="Knob4"},
			{type="DNumberScratch", x=40,y=60, name="Knob5"},
			{type="DNumberScratch", x=65,y=60, name="Knob6"},
			{type="DNumberScratch", x=90,y=60, name="Knob7"},
			{type="DNumberScratch", x=130,y=60, name="Knob8"},
		}
	},
	["models/props_lab/reciever01c.mdl"] = {
		width = 112,
		height = 80,
		title="reciever01c",
		widgets={
			{type="DNumberScratch", x = 10, y = 30, name="Knob1", color=Color(128,64,64)},
			{type="DNumberScratch", x = 35, y = 30, name="Knob2", color=Color(128,64,64)},
			{type="DNumberScratch", x = 10, y = 55, name="Knob3"},
			{type="DNumberScratch", x = 35, y = 55, name="Knob4"},
			{type="DNumberScratch", x = 60, y = 55, name="Knob5"},
			{type="DNumberScratch", x = 85, y = 55, name="Knob6"},
		}
	},
	["models/props_interiors/vendingmachinesoda01a.mdl"] = {
		width = 60,
		height = 200,
		title = "vendingmachinesoda01a",
		widgets = {
			{type="DButton", x = 10, y = 30, name="1", width = 40, text = "1"},
			{type="DButton", x = 10, y = 50, name="2", width = 40, text = "2"},
			{type="DButton", x = 10, y = 70, name="3", width = 40, text = "3"},
			{type="DButton", x = 10, y = 90, name="4", width = 40, text = "4"},
			{type="DButton", x = 10, y = 110, name="5", width = 40, text = "5"},
			{type="DButton", x = 10, y = 130, name="6", width = 40, text = "6"},
			{type="DButton", x = 10, y = 150, name="7", width = 40, text = "7"},
			{type="DButton", x = 10, y = 170, name="8", width = 40, text = "8"},
		}
	},
	["models/props_c17/furniturewashingmachine001a.mdl"] = {
		width = 36,
		height = 66,
		title="washingmachine001a",
		widgets = {
			{type="DNumberScratch", x=10,y=30,name="Knob"}
		}
	},
	["models/props_trainstation/payphone001a.mdl"] = {
		width = 100,
		height = 150,
		title="payphone001a",
		widgets={
			{type="DButton", x=10, y=30, text="1", name="1"},
			{type="DButton", x=40, y=30, text="2", name="2"},
			{type="DButton", x=70, y=30, text="3", name="3"},
			{type="DButton", x=10, y=60, text="4", name="4"},
			{type="DButton", x=40, y=60, text="5", name="5"},
			{type="DButton", x=70, y=60, text="6", name="6"},
			{type="DButton", x=10, y=90, text="7", name="7"},
			{type="DButton", x=40, y=90, text="8", name="8"},
			{type="DButton", x=70, y=90, text="9", name="9"},
			{type="DButton", x=10, y=120, text="*", name="*"},
			{type="DButton", x=40, y=120, text="0", name="0"},
			{type="DButton", x=70, y=120, text="##", name="#"},
		}
	},
	["models/props_lab/plotter.mdl"] = {
		width = 190,
		height = 90,
		title = "plotter",
		widgets={
			{type="DButton", x=10, y=30, name="Button1"},
			{type="DButton", x=35, y=30, name="Button2"},
			{type="DButton", x=60, y=30, name="Button3"},
			{type="DButton", x=85, y=30, name="Button4"},
			{type="DButton", x=110, y=30, name="Button5"},
			{type="DButton", x=10, y=60, name="Button6"},
			{type="DButton", x=35, y=60, name="Button7"},
			{type="DButton", x=60, y=60, name="Button8"},
			{type="DButton", x=85, y=60, name="Button9"},
			{type="DButton", x=110, y=60, name="Button10"},
			{type="DButton", x=135, y=60, name="Button11"},
			{type="DButton", x=160, y=60, name="Button12"},
		}
	}

}

-- To let other parts of code get the valid model, and to prevent write to the table.
function WireLib.IsValidInteractiveModel( model )
	return InteractiveModels[model] ~= nil
end

InteractiveModels["models/props_c17/furnituresink001a.mdl"]		 = copyPropUI( "models/props_interiors/bathtub01a.mdl", "Furniture Sink" )
InteractiveModels["models/props_interiors/sinkkitchen01a.mdl"]	= copyPropUI( "models/props_interiors/bathtub01a.mdl", "Kitchen Sink" )
InteractiveModels["models/props_wasteland/prison_sink001a.mdl"] = copyPropUI( "models/props_interiors/bathtub01a.mdl", "Prison Sink" )

local WidgetBuilders = {

	DCheckBox = function(self, data, body, index)
		local checkbox = vgui.Create("DCheckBox", body)
			checkbox:SetPos(data.x, data.y)
			checkbox:SetValue(self.InteractiveData[index])
			checkbox.OnChange =	function(box,value)
				surface.PlaySound("buttons/lightswitch2.wav")
				self.InteractiveData[index] = value and 1 or 0
				self:SendData()
			end
	end,

	DNumberScratch = function(self, data, body, index)
		local numberscratch = vgui.Create("DNumberScratch", body)
			numberscratch.color = data.color or Color( 128, 128, 128 )
			numberscratch:SetMin(-1)
			numberscratch:SetMax(1)
			numberscratch:SetDecimals(4)
			numberscratch:SetPos(data.x, data.y)
			numberscratch:SetValue(self.InteractiveData[index])
			numberscratch.OnValueChanged =	function(scratch,value)
				self.InteractiveData[index] = value
				self:SendData()
			end
			numberscratch:SetImageVisible( false )
			numberscratch:SetSize( 17, 17 )
			numberscratch.Paint = function( self, w, h )
				draw.RoundedBox( 8.5, 0, 0, w, h, numberscratch.color )
				local value = self:GetFloatValue()
				surface.SetDrawColor(255, 255, 255)
				surface.DrawLine(
					w/2,
					h/2,
					math.sin(value * math.pi*0.75)*w/2+w/2,
					-math.cos(value * math.pi*0.75)*h/2+h/2
				)
			end
	end,

	DButton = function(self, data, body, index)
		local button = vgui.Create("DButton", body)
			button:SetPos(data.x, data.y)
			button:SetText(data.text or "")
			button:SetSize(data.width or 20, data.height or 20)
			self:AddButton(index,button)
	end

}

function ENT:GetPanel()
	local data	= InteractiveModels[ self:GetModel() ]
	local body = vgui.Create("DFrame")
		body:SetTitle(data.title)
		body:SetSize(data.width, data.height)
		body:SetVisible(true)
		body.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
			-- surface.SetDrawColor(255,255,255)
			-- surface.DrawOutlinedRect(0, 0, w, h)
			-- surface.SetDrawColor(0,0,0)
			-- surface.DrawOutlinedRect(1, 1, w-2, h-2)
			draw.RoundedBox( 4, 0, 0, w, h, Color( 255, 255, 255 ) )
			draw.RoundedBox( 4, 1, 1, w-2, h-2, Color( 64, 64, 64 ) )
		end
		body:SetDraggable(false)
		body:Center()
		body:ShowCloseButton(true)
		body:MakePopup()
		for id, widget in ipairs( data.widgets ) do
			WidgetBuilders[widget.type](self, widget, body, id)
		end
	return body
end


function ENT:AddButton(id,button)
	self.Buttons[id] = button
end

function ENT:SendData()
	net.Start("wire_interactiveprop_action")
	local data = InteractiveModels[self:GetModel()].widgets
	net.WriteEntity(self)
	for i=1, #data do
		net.WriteFloat(self.InteractiveData[i])
	end
	net.SendToServer()
end

if CLIENT then

	local panel

	----------------------------------------------------
	-- Show the prompt
	----------------------------------------------------
	function ENT:Initialize()
		self.InteractiveData = {}
		self.LastButtons = {}
		self.Buttons = {}
		for i=1, #InteractiveModels[ self:GetModel() ].widgets do
			self.InteractiveData[i] = 0
		end
	end

	function ENT:Think()
		if IsValid( panel ) and #self.Buttons ~= 0 then
			local needToUpdate = false
			for k,v in pairs(self.Buttons) do
				self.LastButtons[k] = self.InteractiveData[k]
				self.InteractiveData[k] = v:IsDown() and 1 or 0
				if self.InteractiveData[k] ~= self.LastButtons[k] then
					needToUpdate = true
				end
			end
			if needToUpdate then
				self:SendData()
			end
		end
	end

	net.Receive("wire_interactiveprop_show",function()
		local self = net.ReadEntity()
		if not IsValid(self) then return end
		panel = self:GetPanel()
		panel.OnClose = function(panel)
			net.Start("wire_interactiveprop_close")
			self.Buttons = {}
			self.LastButtons = {}
			net.WriteEntity(self)
			net.SendToServer()
		end
	end)

	net.Receive( "wire_interactiveprop_kick", function()
		self.Buttons = {}
		self.LastButtons = {}
		if IsValid( panel ) then
			panel:Remove()
		end
	end)

	return
end

function ENT:InitData()
	local model = self:GetModel()
	local outputs = {}
	for i=1, #InteractiveModels[model].widgets do
		outputs[i] = InteractiveModels[model].widgets[i].name
	end
	self.Outputs=WireLib.CreateOutputs(self,outputs)
end


----------------------------------------------------
-- UpdateOverlay
----------------------------------------------------
function ENT:UpdateOverlay()
	txt = ""
	if IsValid(self.User) then
		txt = "In use by: " .. self.User:Nick()
	end

	self:SetOverlayText(txt)
end







----------------------------------------------------
-- Initialize
----------------------------------------------------
function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self.InteractiveData = {}

	self:InitData()


	self.BlockInput=false
	self.NextPrompt = 0

	self:UpdateOverlay()


end



function ENT:OnRemove()
	self:Unprompt( true )
end


function ENT:ReceiveData()
	local data = InteractiveModels[self:GetModel()].widgets
	for i = 1, #data do
		WireLib.TriggerOutput(self, data[i].name, net.ReadFloat())
	end
end
----------------------------------------------------
-- Receiving data from client
----------------------------------------------------
util.AddNetworkString("wire_interactiveprop_action")
net.Receive("wire_interactiveprop_action",function(len,ply)
	local ent = net.ReadEntity()
	if not ent:IsValid() or ent:GetClass() ~= "gmod_wire_interactiveprop" or ply ~= ent.User then return end

	ent:ReceiveData()
	ent:UpdateOverlay()
end)

----------------------------------------------------
-- Prompt
-- Sends prompt to user etc
----------------------------------------------------
util.AddNetworkString("wire_interactiveprop_show")
function ENT:Prompt( ply )
	if ply then
		if CurTime() < self.NextPrompt then return end -- anti spam
		self.NextPrompt = CurTime() + 0.1

		if IsValid( self.User ) then
			WireLib.AddNotify(ply,"That interactive prop is in use by another player!",NOTIFY_ERROR,5,6)
			return
		end

		self.User = ply

		net.Start( "wire_interactiveprop_show" )
			net.WriteEntity( self )
		net.Send( ply )

		self:UpdateOverlay()
	else
		self:Prompt( self:GetPlayer() ) -- prompt for owner
	end
end

util.AddNetworkString("wire_interactiveprop_close")
net.Receive("wire_interactiveprop_close",function(len,ply)
    local ent = net.ReadEntity()
    if not ent:IsValid() or ent:GetClass() ~= "gmod_wire_interactiveprop" or ply ~= ent.User then return end
    ent:Unprompt()
end)

util.AddNetworkString("wire_interactiveprop_kick")
function ENT:Unprompt()
	self.User = nil
	self:UpdateOverlay()
end


----------------------------------------------------
-- Use
----------------------------------------------------
function ENT:Use(ply)
	if not IsValid( ply ) then return end

	self:Prompt( ply )
end

duplicator.RegisterEntityClass("gmod_wire_interactiveprop",WireLib.MakeWireEnt,"Data")
