TOOL.Category       = "Wire - Advanced"
TOOL.Name           = "Data - Address Bus"
TOOL.Command        = nil
TOOL.ConfigName     = ""
TOOL.Tab            = "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_addressbus_name", "Address bus tool (Wire)" )
	language12.Add( "Tool_wire_addressbus_desc", "Spawns an address bus. Address spaces may overlap!" )
	language12.Add( "Tool_wire_addressbus_0", "Primary: Create/Update address bus" )
	language12.Add( "sboxlimit_wire_addressbuss", "You've hit address buses limit!" )
	language12.Add( "undone_wiredatarate", "Undone Address Bus" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_addressbuss', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar[ "addrspace1sz" ] = 0
TOOL.ClientConVar[ "addrspace2sz" ] = 0
TOOL.ClientConVar[ "addrspace3sz" ] = 0
TOOL.ClientConVar[ "addrspace4sz" ] = 0
TOOL.ClientConVar[ "addrspace1st" ] = 0
TOOL.ClientConVar[ "addrspace2st" ] = 0
TOOL.ClientConVar[ "addrspace3st" ] = 0
TOOL.ClientConVar[ "addrspace4st" ] = 0

cleanup.Register( "wire_addressbuss" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_addressbus" && trace.Entity.ply == ply ) then
		trace.Entity.MemStart[1] = self:GetClientNumber( "addrspace1st" )
		trace.Entity.MemStart[2] = self:GetClientNumber( "addrspace2st" )
		trace.Entity.MemStart[3] = self:GetClientNumber( "addrspace3st" )
		trace.Entity.MemStart[4] = self:GetClientNumber( "addrspace4st" )
		trace.Entity.MemEnd[1] = trace.Entity.MemStart[1] + self:GetClientNumber( "addrspace1sz" ) - 1
		trace.Entity.MemEnd[2] = trace.Entity.MemStart[2] + self:GetClientNumber( "addrspace2sz" ) - 1
		trace.Entity.MemEnd[3] = trace.Entity.MemStart[3] + self:GetClientNumber( "addrspace3sz" ) - 1
		trace.Entity.MemEnd[4] = trace.Entity.MemStart[4] + self:GetClientNumber( "addrspace4sz" ) - 1
		for i = 1,4 do
			trace.Entity["Mem"..i.."st"] = trace.Entity.MemStart[i]
			trace.Entity["Mem"..i.."sz"] = self:GetClientNumber( "addrspace"..i.."sz" )
		end
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_addressbuss" ) ) then return false end

	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90

	wire_addressbus = MakeWireAddressBus( ply, trace.HitPos, Ang, model,
		self:GetClientNumber( "addrspace1st" ),
		self:GetClientNumber( "addrspace2st" ),
		self:GetClientNumber( "addrspace3st" ),
		self:GetClientNumber( "addrspace4st" ),
		self:GetClientNumber( "addrspace1sz" ),
		self:GetClientNumber( "addrspace2sz" ),
		self:GetClientNumber( "addrspace3sz" ),
		self:GetClientNumber( "addrspace4sz" )
	)
	local min = wire_addressbus:OBBMins()
	wire_addressbus:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_addressbus, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireAddressBus")
		undo.AddEntity( wire_addressbus )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_addressbuss", wire_addressbus )

	return true
end

function TOOL:RightClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_addressbus" && trace.Entity.ply == ply ) then
		ply:ConCommand("wire_addressbus_addrspace1sz "..(trace.Entity.MemEnd[1]-trace.Entity.MemStart[1]+1))
		ply:ConCommand("wire_addressbus_addrspace1st "..(trace.Entity.MemStart[1]))
		ply:ConCommand("wire_addressbus_addrspace2sz "..(trace.Entity.MemEnd[2]-trace.Entity.MemStart[2]+1))
		ply:ConCommand("wire_addressbus_addrspace2st "..(trace.Entity.MemStart[2]))
		ply:ConCommand("wire_addressbus_addrspace3sz "..(trace.Entity.MemEnd[3]-trace.Entity.MemStart[3]+1))
		ply:ConCommand("wire_addressbus_addrspace3st "..(trace.Entity.MemStart[3]))
		ply:ConCommand("wire_addressbus_addrspace4sz "..(trace.Entity.MemEnd[4]-trace.Entity.MemStart[4]+1))
		ply:ConCommand("wire_addressbus_addrspace4st "..(trace.Entity.MemStart[4]))
	end
	return true
end

if (SERVER) then

	function MakeWireAddressBus( ply, Pos, Ang, model, Mem1st, Mem2st, Mem3st, Mem4st, Mem1sz, Mem2sz, Mem3sz, Mem4sz )

		if ( !ply:CheckLimit( "wire_addressbuss" ) ) then return false end

		local wire_addressbus = ents.Create( "gmod_wire_addressbus" )
		if (!wire_addressbus:IsValid()) then return false end
		wire_addressbus:SetModel(model)

		wire_addressbus:SetAngles( Ang )
		wire_addressbus:SetPos( Pos )
		wire_addressbus:Spawn()

		if (!Mem1st or Mem1st == "") then Mem1st = "0" end
		if (!Mem2st or Mem2st == "") then Mem2st = "0" end
		if (!Mem3st or Mem3st == "") then Mem3st = "0" end
		if (!Mem4st or Mem4st == "") then Mem4st = "0" end
		if (!Mem1sz or Mem1sz == "") then Mem1sz = "0" end
		if (!Mem2sz or Mem2sz == "") then Mem2sz = "0" end
		if (!Mem3sz or Mem3sz == "") then Mem3sz = "0" end
		if (!Mem4sz or Mem4sz == "") then Mem4sz = "0" end

		wire_addressbus.MemStart[1] = tonumber(Mem1st)
		wire_addressbus.MemStart[2] = tonumber(Mem2st)
		wire_addressbus.MemStart[3] = tonumber(Mem3st)
		wire_addressbus.MemStart[4] = tonumber(Mem4st)
		wire_addressbus.MemEnd[1] = wire_addressbus.MemStart[1] + tonumber(Mem1sz) - 1
		wire_addressbus.MemEnd[2] = wire_addressbus.MemStart[2] + tonumber(Mem2sz) - 1
		wire_addressbus.MemEnd[3] = wire_addressbus.MemStart[3] + tonumber(Mem3sz) - 1
		wire_addressbus.MemEnd[4] = wire_addressbus.MemStart[4] + tonumber(Mem4sz) - 1

		wire_addressbus:SetPlayer(ply)

		//KTNX TAD!

		local ttable = {
			ply = ply,
			model = model,
			Mem1st = Mem1st,
			Mem2st = Mem2st,
			Mem3st = Mem3st,
			Mem4st = Mem4st,
			Mem1sz = Mem1sz,
			Mem2sz = Mem2sz,
			Mem3sz = Mem3sz,
			Mem4sz = Mem4sz,
		}
		table.Merge(wire_addressbus:GetTable(), ttable )

		ply:AddCount( "wire_addressbuss", wire_addressbus )

		return wire_addressbus

	end

	duplicator.RegisterEntityClass("gmod_wire_addressbus", MakeWireAddressBus, "Pos", "Ang", "Model", "Mem1st", "Mem2st", "Mem3st", "Mem4st", "Mem1sz", "Mem2sz", "Mem3sz", "Mem4sz")

end

function TOOL:UpdateGhostWireAddressBus( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_addressbus" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireAddressBus( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_addressbus_name", Description = "#Tool_wire_addressbus_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_addressbus",

		Options = {
			Default = {
				wire_addressbus_addrspace1st = "0",
				wire_addressbus_addrspace1sz = "0",
				wire_addressbus_addrspace2st = "0",
				wire_addressbus_addrspace2sz = "0",
				wire_addressbus_addrspace3st = "0",
				wire_addressbus_addrspace3sz = "0",
				wire_addressbus_addrspace4st = "0",
				wire_addressbus_addrspace4sz = "0",
			}
		},

		CVars = {
			[0] = "wire_addressbus_addrspace1st",
			[1] = "wire_addressbus_addrspace1sz",
			[2] = "wire_addressbus_addrspace2st",
			[3] = "wire_addressbus_addrspace2sz",
			[4] = "wire_addressbus_addrspace3st",
			[5] = "wire_addressbus_addrspace3sz",
			[6] = "wire_addressbus_addrspace4st",
			[7] = "wire_addressbus_addrspace4sz",
		}
	})

        local modelPanel = WireDermaExts.ModelSelect(panel, "wire_addressbus_model", list.Get("Wire_gate_Models"), 2)

	panel:AddControl("Slider", {
		Label = "Address space 1 offset",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace1st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 1 size",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace1sz"
	})

	panel:AddControl("Slider", {
		Label = "Address space 2 offset",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace2st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 2 size",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace2sz"
	})

	panel:AddControl("Slider", {
		Label = "Address space 3 offset",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace3st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 3 size",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace3sz"
	})

	panel:AddControl("Slider", {
		Label = "Address space 4 offset",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace4st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 4 size",
		Type = "Integer",
		Min = "0",
		Max = "16777216",
		Command = "wire_addressbus_addrspace4sz"
	})
end

