TOOL.Category		= "Wire - Data"
TOOL.Name			= "CD Disk"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if (CLIENT) then
    language.Add("Tool_wire_cd_disk_name", "CD Disk Tool (Wire)")
    language.Add("Tool_wire_cd_disk_desc", "Spawns a CD Disk.")
    language.Add("Tool_wire_cd_disk_0", "Primary: Create/Update CD Disk, Secondary: Change model")
    language.Add("WireDataTransfererTool_cd_disk", "CD Disk:")
	language.Add("sboxlimit_wire_cd_disks", "You've hit CD Disks limit!")
	language.Add("undone_Wire CD Disk", "Undone Wire CD Disk")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_cd_disks', 20)
end

TOOL.ClientConVar["model"] = "models/venompapa/wirecd_medium.mdl"
TOOL.ClientConVar["skin"] = "0"
TOOL.ClientConVar["precision"] = 4
TOOL.ClientConVar["iradius"] = 10

TOOL.FirstSelected = nil

cleanup.Register("wire_cd_disks")

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cd_disk" && trace.Entity.pl == ply) then
		trace.Entity.Precision = tonumber(self:GetClientInfo("precision"))
		trace.Entity.IRadius = tonumber(self:GetClientInfo("iradius"))
		trace.Entity:Setup()
		return true
	end

	if (!self:GetSWEP():CheckLimit("wire_cd_disks")) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_cd_disk = MakeWireCDDisk(ply, trace.HitPos, Ang , self:GetClientInfo("model"),tonumber(self:GetClientInfo("skin")))
	wire_cd_disk.Precision = tonumber(self:GetClientInfo("precision"))
	wire_cd_disk.IRadius = tonumber(self:GetClientInfo("iradius"))
	wire_cd_disk:Setup()

	local min = wire_cd_disk:OBBMins()
	wire_cd_disk:SetPos(trace.HitPos - trace.HitNormal * min.z)

	local const = WireLib.Weld(wire_cd_disk, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire CD Disk")
		undo.AddEntity(wire_cd_disk)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_cd_disks", wire_cd_disk)
	ply:AddCleanup("wire_cd_disks", const)

	return true
end

function TOOL:RightClick(trace)
	if (CLIENT) then return true end

	if (trace.Entity and trace.Entity:IsValid()) then
		if (trace.Entity:GetClass() == "prop_physics") then
			self:GetOwner():ConCommand('wire_cd_disk_model "'..trace.Entity:GetModel()..'"\n')
			self:GetOwner():ConCommand('wire_cd_disk_skin "'..trace.Entity:GetSkin()..'"\n')
		end
	end

	return true
end

if (SERVER) then

	function MakeWireCDDisk(pl, Pos, Ang, model, skin)
		if (!pl:CheckLimit("wire_cd_disks")) then return false end

		local wire_cd_disk = ents.Create("gmod_wire_cd_disk")
		if (!wire_cd_disk:IsValid()) then return false end

		wire_cd_disk:SetAngles(Ang)
		wire_cd_disk:SetPos(Pos)
		wire_cd_disk:SetSkin(skin)
		wire_cd_disk:SetModel(model)
		wire_cd_disk:Spawn()

		wire_cd_disk:SetPlayer(pl)
		wire_cd_disk.pl = pl

		pl:AddCount("wire_cd_disks", wire_cd_disk)

		return wire_cd_disk
	end

	duplicator.RegisterEntityClass("gmod_wire_cd_disk", MakeWireCDDisk, "Pos", "Ang", "Model", "skin")

end

function TOOL:UpdateGhostWireCDDisk(ent, player)
	if (!ent || !ent:IsValid()) then return end

	local tr 	= utilx.GetPlayerTrace(player, player:GetCursorAimVector())
	local trace 	= util.TraceLine(tr)

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_cd_disk") then
		ent:SetNoDraw(true)
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.model) then
		self:MakeGhostEntity(self:GetClientInfo("model"), Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostWireCDDisk(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cd_disk_name", Description = "#Tool_wire_cd_disk_desc" })

	panel:AddControl("Slider", {
		Label = "Disk density (inches per block, ipb)",
		Type = "Integer",
		Min = "1",
		Max = "16",
		Command = "wire_cd_disk_precision"
	})

	panel:AddControl("Slider", {
		Label = "Inner radius (disk hole radius)",
		Type = "Integer",
		Min = "1",
		Max = "48",
		Command = "wire_cd_disk_iradius"
	})

	panel:AddControl("Slider", {
		Label = "Disk skin (0..8, standard disks only)",
		Type = "Integer",
		Min = "0",
		Max = "8",
		Command = "wire_cd_disk_skin"
	})
end
