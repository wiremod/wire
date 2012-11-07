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
	language.Add( "Tool.wire_spawner.0", "Click a prop to turn it into a prop spawner." )
	language.Add( "Undone_gmod_wire_spawner", "Undone Wire Spawner" )
	language.Add( "Cleanup_gmod_wire_spawner", "Wire Spawners" )
	language.Add( "Cleaned_gmod_wire_spawner", "Cleaned up Wire Spawners" )
end

if SERVER then
	CreateConVar("sbox_maxwire_spawners",10)
end

cleanup.Register("gmod_wire_spawner")

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if !ent or !ent:IsValid() then return false end
	if ent:GetClass() != "prop_physics" && ent:GetClass() != "gmod_wire_spawner" then return false end
	if CLIENT then return true end

	local pl			= self:GetOwner()
	local delay			= self:GetClientNumber("delay", 0)
	local undo_delay	= self:GetClientNumber("undo_delay", 0)
	local spawn_effect  = self:GetClientNumber("spawn_effect", 0)

	if ent:GetClass() == "gmod_wire_spawner" && ent.pl == pl then
		local spawner = ent

		// In multiplayer we clamp the delay to help prevent people being idiots
		if !game.SinglePlayer() and delay < 0.1 then
			delay = 0.1
		end

		spawner:Setup(delay, undo_delay, spawn_effect)
		return true
	end

	if !self:GetSWEP():CheckLimit("wire_spawners") then return false end

	local phys			= ent:GetPhysicsObject()
	if !phys:IsValid() then return false end

	local model 		= ent:GetModel()
	local frozen		= not phys:IsMoveable()
	local Pos			= ent:GetPos()
	local Ang			= ent:GetAngles()
	local mat			= ent:GetMaterial()
	local c		        = ent:GetColor()
	local skin			= ent:GetSkin() or 0

	local wire_spawner = MakeWireSpawner( pl, Pos, Ang, model, delay, undo_delay, spawn_effect, mat, c.r, c.g, c.b, c.a, skin, frozen )
	if !wire_spawner:IsValid() then return end

	ent:Remove()

	undo.Create("gmod_wire_spawner")
		undo.AddEntity( wire_spawner )
		undo.SetPlayer( pl )
	undo.Finish()

	return true
end

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakePresetControl(panel, "wire_spawner")
	panel:NumSlider("#Spawn Delay", "wire_spawner_delay", 0.1, 100, 2)
	panel:NumSlider("#Automatic Undo Delay", "wire_spawner_undo_delay", 0.1, 100, 2)
	panel:CheckBox("#Prop spawn effect", "wire_spawner_spawn_effect")
end
