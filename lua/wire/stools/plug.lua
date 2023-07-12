WireToolSetup.setCategory( "Input, Output/Data Transfer" )
WireToolSetup.open( "plug", "Plug", "gmod_wire_socket", nil, "Plugs" )

if (SERVER) then

	CreateConVar("sbox_maxwire_plugs",20)
	CreateConVar("sbox_maxwire_sockets",20)

else
	language.Add( "Tool.wire_plug.name", "Plug & Socket Tool (Wire)" )
	language.Add( "Tool.wire_plug.desc", "Spawns plugs and sockets for use with the wire system." )
	language.Add( "sboxlimit_wire_plugs", "You've hit the Wire Plugs limit!" )
	language.Add( "sboxlimit_wire_sockets", "You've hit the Wire Sockets limit!" )
	language.Add( "undone_wireplug", "Undone Wire Plug" )
	language.Add( "undone_wiresocket", "Undone Wire Socket" )

	language.Add( "Tool_wire_plug_freeze", "Freeze the socket." )
	language.Add( "Tool_wire_plug_array", "Use array inputs/outputs instead." )
	language.Add( "Tool_wire_plug_weldforce", "Plug weld force:" )
	language.Add( "Tool_wire_plug_attachrange", "Plug attachment detection range:" )
	language.Add( "Tool_wire_plug_drawoutline", "Draw the white outline on plugs and sockets." )
	language.Add( "Tool_wire_plug_drawoutline_tooltip", "Disabling this helps you see inside the USB plug model when you set its material to wireframe." )
	language.Add( "Tool_wire_plug_angleoffset", "Spawn angle offset" )
	TOOL.Information = {
		{ name = "left", text = "Create/Update Socket" },
		{ name = "right", text = "Create/Update " .. TOOL.Name },
		{ name = "reload", text = "Increase angle offset by 45 degrees" },
	}
end

WireToolSetup.BaseLang()

TOOL.ClientConVar["model"] = "models/props_lab/tpplugholder_single.mdl"
TOOL.ClientConVar["array"] = 0
TOOL.ClientConVar["weldforce"] = 5000
TOOL.ClientConVar["attachrange"] = 5
TOOL.ClientConVar["drawoutline"] = 1
TOOL.ClientConVar["angleoffset"] = 0

local SocketData = list.Get("Wire_Socket_Models")

hook.Add("ModelPlugLuaRefresh","wire_plug_updatemodels",function()
	SocketData = list.Get("Wire_Socket_Models")
end)

cleanup.Register( "wire_plugs" )

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )
	if (not util.IsValidModel( model ) or not util.IsValidProp( model ) or not SocketData[ model ]) then return "models/props_lab/tpplugholder_single.mdl" end
	return model
end

function TOOL:GetAngle( trace )
	local ang
	if math.abs(trace.HitNormal.x) < 0.001 and math.abs(trace.HitNormal.y) < 0.001 then
		ang = Vector(0,0,trace.HitNormal.z):Angle() + (SocketData[self:GetModel()].ang or Angle(0,0,0))
	else
		ang = trace.HitNormal:Angle() + (SocketData[self:GetModel()].ang or Angle(0,0,0))
	end
	ang:RotateAroundAxis( trace.HitNormal, self:GetClientNumber( "angleoffset" ) )
	return ang
end

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("array") ~= 0, self:GetClientNumber("weldforce"), math.Clamp(self:GetClientNumber("attachrange"), 1, 100)
	end

	-- Socket creation handled by WireToolObj
end

-- Create Plug
function TOOL:RightClick( trace )
	if (not trace) then return false end
	if (trace.Entity) then
		if (trace.Entity:IsPlayer()) then return false end
		if (trace.Entity:GetClass() == "gmod_wire_plug") then
			if (CLIENT) then return true end
			trace.Entity:Setup( self:GetClientNumber( "array" ) ~= 0 )
			return true
		end
	end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local plugmodel = SocketData[ self:GetModel() ].plug

	local plug = WireLib.MakeWireEnt(ply, {Class = "gmod_wire_plug", Pos=trace.HitPos, Angle=self:GetAngle(trace), Model=plugmodel}, self:GetClientNumber( "array" ) ~= 0)
	if not IsValid(plug) then return false end

	plug:SetPos( trace.HitPos - trace.HitNormal * plug:OBBMins().x )

	undo.Create("wireplug")
		undo.AddEntity( plug )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_plugs", plug )

	return true
end

--------------------
-- Reload
-- Increase angle offset by 45 degrees
--------------------
function TOOL:Reload( trace )
	if game.SinglePlayer() and SERVER then
		self:GetOwner():ConCommand( "wire_plug_angleoffset " .. (self:GetClientNumber( "angleoffset" ) + 45) % 360 )
	elseif CLIENT then
		RunConsoleCommand( "wire_plug_angleoffset", (self:GetClientNumber( "angleoffset" ) + 45) % 360 )
	end

	return false
end

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakePresetControl(panel, "wire_plug")
	ModelPlug_AddToCPanel(panel, "Socket", "wire_plug")
	panel:CheckBox("#Tool_wire_plug_array", "wire_plug_array")
	panel:NumSlider("#Tool_wire_plug_weldforce", "wire_plug_weldforce", 0, 100000)
	panel:NumSlider("#Tool_wire_plug_attachrange", "wire_plug_attachrange", 1, 100)
	panel:CheckBox("#Tool_wire_plug_drawoutline", "wire_plug_drawoutline")
	panel:NumSlider( "#Tool_wire_plug_angleoffset","wire_plug_angleoffset", 0, 360, 0 )
end
