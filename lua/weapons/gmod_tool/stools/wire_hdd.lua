TOOL.Category		= "Wire - Advanced"
TOOL.Name			= "Flash (EEPROM)"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_hdd_name", "Flash (EEPROM) tool (Wire)" )
    language.Add( "Tool_wire_hdd_desc", "Spawns flash memory. It is used for permanent storage of data (carried over sessions)" )
    language.Add( "Tool_wire_hdd_0", "Primary: Create/Update flash memory" )
	language.Add( "sboxlimit_wire_hdds", "You've hit flash memory limit!" )
	language.Add( "undone_wiredigitalscreen", "Undone Flash (EEPROM)" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_hdds', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar[ "driveid" ] = 0
TOOL.ClientConVar[ "client_driveid" ] = 0
TOOL.ClientConVar[ "drivecap" ] = 128

TOOL.ClientConVar[ "packet_bandwidth" ] = 100
TOOL.ClientConVar[ "packet_rate" ] = 0.4

cleanup.Register( "wire_hdds" )

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )
	if (!util.IsValidModel( model ) or !util.IsValidProp( model )) then return "models/jaanus/wiretool/wiretool_gate.mdl" end
	return model
end

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hdd" && trace.Entity.pl == ply ) then
		trace.Entity.DriveID = tonumber(self:GetClientInfo( "driveid" ))
		trace.Entity.DriveCap = tonumber(self:GetClientInfo( "drivecap" ))
		trace.Entity:UpdateCap()
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_hdds" ) ) then return false end

	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetModel()
	Ang.pitch = Ang.pitch + 90

	local wire_hdd = MakeWirehdd( ply, trace.HitPos, Ang, model, self:GetClientInfo( "driveid" ), self:GetClientInfo( "drivecap" ) )
	local min = wire_hdd:OBBMins()
	wire_hdd:SetPos( trace.HitPos - trace.HitNormal * min.z )

	wire_hdd.DriveID = tonumber(self:GetClientInfo( "driveid" ))
	wire_hdd.DriveCap = tonumber(self:GetClientInfo( "drivecap" ))

	local const = WireLib.Weld(wire_hdd, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wirehdd")
		undo.AddEntity( wire_hdd )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_hdds", wire_hdd )

	return true
end

if (SERVER) then

	function MakeWirehdd( pl, Pos, Ang, model, DriveID, DriveCap)

		if ( !pl:CheckLimit( "wire_hdds" ) ) then return false end

		local wire_hdd = ents.Create( "gmod_wire_hdd" )
		if (!wire_hdd:IsValid()) then return false end
		wire_hdd:SetModel(model)

		wire_hdd:SetAngles( Ang )
		wire_hdd:SetPos( Pos )
		wire_hdd:Spawn()

		wire_hdd:SetPlayer(pl)

		local ttable = {
			pl = pl,
			model = model,
			DriveID = DriveID,
			DriveCap = DriveCap,
		}

		table.Merge(wire_hdd:GetTable(), ttable )

		pl:AddCount( "wire_hdds", wire_hdd )

		return wire_hdd

	end

	duplicator.RegisterEntityClass("gmod_wire_hdd", MakeWirehdd, "Pos", "Ang", "Model", "DriveID", "DriveCap")

end

function TOOL:UpdateGhostWirehdd( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_hdd" || trace.Entity:IsPlayer()) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetModel() || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetModel(), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWirehdd( self.GhostEntity, self:GetOwner() )
end

/*"wire_hdd_driveid"
"wire_hdd_client_driveid"
"wire_hdd_downloadhdd"
"wire_hdd_uploadhdd"
"wire_hdd_clearhdd"
"wire_hdd_clearhdd_client"

local function UploadHDDData(pl, command, args)
	//Send drive cap
		//SP only:
		//SourceCode = string.Explode("\n", file.Read(fname) )

		pl:ConCommand('wire_cpu_clearsrc')

		local filedata = file.Read(fname)
		SourceLines = string.Explode("\n", filedata )
		SourceLinesSent = 0
		SourceTotalChars = string.len(filedata)

		SourcePrevCharRate = string.len(SourceLines[1])
		SourceLoadedChars = 0

		pl:ConCommand('wire_cpu_vgui_open')
		pl:ConCommand('wire_cpu_vgui_title "CPU - Uploading program"')
		pl:ConCommand('wire_cpu_vgui_status "Initializing"')
		pl:ConCommand('wire_cpu_vgui_progress "0"')

		//Send 50 lines
		if (SinglePlayer()) then
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_sp"),0,UploadProgram,pl,true)
		else
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_mp"),0,UploadProgram,pl,true)
		end
	end
	concommand.Add( "wire_cpu_loadcompile", LoadCompileProgram )

	local function StoreProgram(pl, command, args)
		Msg("Storing program is disabled - its readonly!\n")
	end
	concommand.Add("wire_cpu_store", StoreProgram)

if (SERVER) then
	local function Send_DriveCap(pl, command, args)

	end
	concommand.Add("wire_hdd_send_drivecap", Send_DriveCap )
end*/

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_hdd_name", Description = "#Tool_wire_hdd_desc" })

	local mdl = vgui.Create("DWireModelSelect")
	mdl:SetModelList( list.Get("Wire_gate_Models"), "wire_hdd_model" )
	mdl:SetHeight( 5 )
	panel:AddItem( mdl )

	panel:AddControl("Slider", {
		Label = "Drive ID",
		Type = "Integer",
		Min = "0",
		Max = "3",
		Command = "wire_hdd_driveid"
	})

	panel:AddControl("Slider", {
		Label = "Capacity (KB)",
		Type = "Integer",
		Min = "0",
		Max = "128",
		Command = "wire_hdd_drivecap"
	})

/*	panel:AddControl("Label", {
		Text = "Hard drive manager:"
	})

	panel:AddControl("Slider", {
		Label = "Server drive ID",
		Type = "Integer",
		Min = "0",
		Max = "3",
		Command = "wire_hdd_driveid"
	})

	panel:AddControl("Slider", {
		Label = "Client drive ID",
		Type = "Integer",
		Min = "0",
		Max = "3",
		Command = "wire_hdd_client_driveid"
	})

	panel:AddControl("Button", {
		Text = "Download server drive to client drive",
		Name = "Clear",
		Command = "wire_hdd_downloadhdd"
	})

	panel:AddControl("Button", {
		Text = "Upload client drive to server drive",
		Name = "Clear",
		Command = "wire_hdd_uploadhdd"
	})

	panel:AddControl("Button", {
		Text = "Clear server drive",
		Name = "Clear",
		Command = "wire_hdd_clearhdd"
	})

	panel:AddControl("Button", {
		Text = "Clear client drive",
		Name = "Clear",
		Command = "wire_hdd_clearhdd_client"
	})*/

end

