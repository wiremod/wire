WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "spawner", "Prop Spawner", "gmod_wire_spawner", nil, "Prop Spawners" )

TOOL.ClientConVar = {
	delay = 0,
	undo_delay = 0,
	spawn_effect = 0,
}

if CLIENT then
	language.Add( "Tool.wire_spawner.name", "Prop Spawner (Wire)" )
	language.Add( "Tool.wire_spawner.desc", "Spawns a prop at a pre-defined location" )
	TOOL.Information = { { name = "left", text = "Click a prop to turn it into a " .. TOOL.Name } }
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(10)

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if not ent or not ent:IsValid() then return false end
	if ent:GetClass() ~= "prop_physics" and ent:GetClass() ~= "gmod_wire_spawner" then return false end
	if CLIENT then return true end

	local pl			= self:GetOwner()
	local delay			= self:GetClientNumber("delay", 0)
	local undo_delay	= self:GetClientNumber("undo_delay", 0)
	local spawn_effect  = self:GetClientNumber("spawn_effect", 0)
	// In multiplayer we clamp the delay to help prevent people being idiots
	if not game.SinglePlayer() and delay < 0.1 then
		delay = 0.1
	end
	if ent:GetClass() == "gmod_wire_spawner" then
		ent:Setup(delay, undo_delay, spawn_effect)
		return true
	end

	if not self:GetSWEP():CheckLimit("wire_spawners") then return false end

	local phys			= ent:GetPhysicsObject()
	if not phys:IsValid() then return false end

	local model 		= ent:GetModel()
	local frozen		= not phys:IsMoveable()
	local Pos			= ent:GetPos()
	local Ang			= ent:GetAngles()
	local mat			= ent:GetMaterial()
	local c		        = ent:GetColor()
	local skin			= ent:GetSkin() or 0

	local preserveMotion = phys:IsMotionEnabled()

	local wire_spawner = WireLib.MakeWireEnt(pl, {Class = self.WireClass, Pos=Pos, Angle=Ang, Model=model}, delay, undo_delay, spawn_effect, mat, c.r, c.g, c.b, c.a, skin)
	if not wire_spawner:IsValid() then return end

	local physObj = wire_spawner:GetPhysicsObject()
	if IsValid( physObj ) then
		physObj:EnableMotion( preserveMotion )
	end

	ent:Remove()

	undo.Create("gmod_wire_spawner")
		undo.AddEntity( wire_spawner )
		undo.SetPlayer( pl )
	undo.Finish()

	return true
end

function TOOL:Think() end -- Disable ghost

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakePresetControl(panel, "wire_spawner")
	panel:NumSlider("#Spawn Delay", "wire_spawner_delay", 0.1, 100, 2)
	panel:NumSlider("#Automatic Undo Delay", "wire_spawner_undo_delay", 0.1, 100, 2)
	panel:CheckBox("#Prop spawn effect", "wire_spawner_spawn_effect")
end
