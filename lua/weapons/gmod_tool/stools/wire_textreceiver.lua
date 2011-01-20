
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "TextReceiver"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_textreceiver_name", "TextReceiver Tool (Wire)" )
    language.Add( "Tool_wire_textreceiver_desc", "Spawns a TextReceiver for use with the wire system." )
    language.Add( "Tool_wire_textreceiver_0", "Primary: Create/Update TextReceiver	Secondary: Copy Settings" )
    language.Add( "WiretextreceiverTool_global", "Global" )
	language.Add("Tool_wire_textreceiver_text1", "Text 1:")
	language.Add("Tool_wire_textreceiver_text2", "Text 2:")
	language.Add("Tool_wire_textreceiver_text3", "Text 3:")
	language.Add("Tool_wire_textreceiver_text4", "Text 4:")
	language.Add("Tool_wire_textreceiver_text5", "Text 5:")
	language.Add("Tool_wire_textreceiver_text6", "Text 6:")
	language.Add("Tool_wire_textreceiver_text7", "Text 7:")
	language.Add("Tool_wire_textreceiver_text8", "Text 8:")
	language.Add("Tool_wire_textreceiver_text9", "Text 9:")
	language.Add("Tool_wire_textreceiver_text10", "Text 10:")
	language.Add("Tool_wire_textreceiver_text11", "Text 12:")
	language.Add("Tool_wire_textreceiver_text12", "Text 12:")
	language.Add("WiretextreceiverTool_trigger","Trigger:")
	language.Add("Tool_wire_textreceiver_parsetext","Parser Text:")
	language.Add("WiretextreceiverTool_utrigger","Default:")
	language.Add("WiretextreceiverTool_hold","Trigger Hold Length:")
	language.Add("WiretextreceiverTool_outputtext", "Display Output Text")
	language.Add("WiretextreceiverTool_SELF", "Include Self")
	language.Add("WiretextreceiverTool_toggle", "Toggle")
	language.Add("WiretextreceiverTool_sensitivity", "Sensitivity:")
	language.Add("exact","Exact")
	language.Add("case_insensitive","Case Insensitive")
	language.Add("anywhere_exact","Anywhere Exact")
	language.Add("anywhere_case_insensitive","Anywhere Case Insensitive")
	language.Add( "sboxlimit_wire_textreceivers", "You've hit TextReceiver limit!" )
	language.Add( "Undone_TextReceiver", "Undone Wire TextReceiver" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_textreceivers', 10)
end

TOOL.ClientConVar[ "global" ] = "0"
TOOL.ClientConVar[ "hold" ] = ".1"
TOOL.ClientConVar[ "trigger" ] = "1"
TOOL.ClientConVar[ "secure" ] = "0"
for i = 1, 12 do
	TOOL.ClientConVar["text"..i] = ""
end
TOOL.ClientConVar[ "outputtext" ] = "1"
TOOL.ClientConVar["SELF"] = "1"
TOOL.ClientConVar["sensitivity"] = "1"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["utrigger"] = "0"
TOOL.ClientConVar["parsetext"] = ""
TOOL.ClientConVar["playerout"] = "0"

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_range.mdl"

local MaxTextLength = 500

cleanup.Register( "wire_textreceivers" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local global	= (self:GetClientNumber("global") ~= 0)
	local hold = self:GetClientNumber("hold")
	local trigger = self:GetClientNumber("trigger")
	local lines = {}
	for i = 1,12 do
		if (self:GetClientInfo("text"..i) != "") then
			table.insert(lines,self:GetClientInfo("text"..i))
		end
	end
	local outputtext = (self:GetClientNumber("outputtext") ~= 0)
	local SELF = (self:GetClientNumber("SELF") ~= 0)
	local sensitivity = self:GetClientNumber("sensitivity")
	local toggle = (self:GetClientNumber("toggle") ~= 0)
	local secure = (self:GetClientNumber("secure") ~= 0)
	local utrigger = self:GetClientNumber("utrigger")
	local parsetext = self:GetClientInfo("parsetext")
	local playerout = (self:GetClientNumber("playerout") ~= 0)

	if (parsetext == "") then parsetext = '""' end

	if (string.len(parsetext) == 1) then parsetext = parsetext .. parsetext end

	if (string.len(parsetext) > 2) then WireLib.AddNotify(self:GetOwner(), "Parse text cannot be more than 2 characters!", NOTIFY_GENERIC, 7) return false end

	if (table.Count(lines)==0) then return false end

	if (sensitivity <1 || sensitivity > 4) then WireLib.AddNotify(self:GetOwner(), "Invalid Sensitivity!", NOTIFY_GENERIC, 7) return false end

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_textreceiver" && trace.Entity.pl == ply ) then

		trace.Entity:Setup( lines,global,outputtext,hold,trigger,SELF,sensitivity,toggle,utrigger,parsetext,secure,playerout)
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_textreceivers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	text_receiver = MakeWireReceiver( ply, trace.HitPos, Ang, self:GetModel(), lines, global, outputtext, hold, trigger, SELF, sensitivity, toggle, utrigger, parsetext, secure, playerout)

	local min = text_receiver:OBBMins()
	text_receiver:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(text_receiver, trace.Entity, trace.PhysicsBone, true)

	undo.Create("TextReceiver")
		undo.AddEntity( text_receiver )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "text_receivers", text_receiver )
	ply:AddCleanup( "text_receivers", const )
	ply:AddCleanup( "text_receivers", nocollide )

	return true
end

local function BtoI(bool)
	if (bool == nil) then return 0 end
	if (bool == true) then return 1 end
	if (bool == false) then return 0 end
end

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_textreceiver" ) then
		local Receiver = trace.Entity
		if (Receiver.CLines == nil) then WireLib.AddNotify(self:GetOwner(), "No Lines", NOTIFY_GENERIC, 7) return true end
		for i = 1,12 do
			self:GetOwner():ConCommand("wire_textreceiver_text"..i.." "..(Receiver.CLines[i] or '""'))
		end
		self:GetOwner():ConCommand("wire_textreceiver_sensitivity "..(Receiver.Sensitivity or 1))
		self:GetOwner():ConCommand("wire_textreceiver_SELF "..BtoI(Receiver.Iself))
		self:GetOwner():ConCommand("wire_textreceiver_toggle "..BtoI(Receiver.Toggle))
		self:GetOwner():ConCommand("wire_textreceiver_outputtext "..BtoI(Receiver.OutputText))
		self:GetOwner():ConCommand("wire_textreceiver_global "..BtoI(Receiver.global))
		self:GetOwner():ConCommand("wire_textreceiver_secure "..BtoI(Receiver.secure))
		self:GetOwner():ConCommand("wire_textreceiver_parsetext "..'"' .. (Receiver.char1 or "") .. (Receiver.char2 or "") .. '"')
		self:GetOwner():ConCommand("wire_textreceiver_hold "..(Receiver.Hold or 0.1))
		self:GetOwner():ConCommand("wire_textreceiver_trigger "..(Receiver.Trig or 1))
		self:GetOwner():ConCommand("wire_textreceiver_utrigger "..(Receiver.UTrig or 0))
		self:GetOwner():ConCommand("wire_textreceiver_secure "..(Receiver.secure or 0))
		self:GetOwner():ConCommand("wire_textreceiver_playerout "..(Receiver.playerout or 0))
		return true
	end
	return false
end

if (SERVER) then

	function MakeWireReceiver( pl, Pos, Ang, model, liness, globall, outputtextt, holdd, triggerr, SELFF, sensitivityy, togglee, utriggerr, parsetextt, secure, playerout)
		if ( !pl:CheckLimit( "wire_textreceivers" ) ) then return false end

		local text_receiver = ents.Create( "gmod_wire_textreceiver" )
		if (!text_receiver:IsValid()) then return false end
		text_receiver:SetAngles( Ang )
		text_receiver:SetPos( Pos )
		text_receiver:SetModel( Model(model or "models/jaanus/wiretool/wiretool_range.mdl") )
		text_receiver:Spawn()

		text_receiver:Setup(liness, globall,outputtextt,holdd,triggerr,SELFF,sensitivityy,togglee,utriggerr,parsetextt,secure,playerout)
		text_receiver:SetPlayer( pl )

		local ttable = {
			pl = pl,
			liness = liness,
			globall = globall,
			outputtextt = outputtextt,
			holdd = holdd,
			triggerr = triggerr,
			SELFF = SELFF,
			sensitivityy = sensitivityy,
			togglee = togglee,
			utriggerr = utriggerr,
			parsetextt = parsetextt,
		}

		table.Merge(text_receiver:GetTable(), ttable )

		pl:AddCount( "wire_textreceivers", text_receiver )

		return text_receiver
	end

	duplicator.RegisterEntityClass("gmod_wire_textreceiver", MakeWireReceiver, "Pos", "Ang", "Model", "liness", "globall", "outputtextt", "holdd", "triggerr", "SELFF", "sensitivityy", "togglee", "utriggerr", "parsetextt", "secure", "playerout")

end

function TOOL:UpdateGhostWireTextReceiver( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_textreceiver" || trace.Entity:IsPlayer()) then

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
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireTextReceiver( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_range.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_textreceiver_name", Description = "#Tool_wire_textreceiver_desc" })

	//preset chooser
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_textreceiver",

		Options = {
			Default = {
				wire_textreceiver_model = "models/jaanus/wiretool/wiretool_range.mdl",
				wire_textreceiver_parsetext = "",
				wire_textreceiver_utrigger = "0",
				wire_textreceiver_trigger = "1",
				wire_textreceiver_hold = "0.1",
				wire_textreceiver_global = "0",
				wire_textreceiver_toggle = "0",
				wire_textreceiver_outputtext = "1",
				wire_textreceiver_SELF = "1",
				wire_textreceiver_secure = "0",
				wire_textreceiver_playerout = "0",
				wire_textreceiver_sensitivity = "1",
				wire_textreceiver_text1 = "",
				wire_textreceiver_text2 = "",
				wire_textreceiver_text3 = "",
				wire_textreceiver_text4 = "",
				wire_textreceiver_text5 = "",
				wire_textreceiver_text6 = "",
				wire_textreceiver_text7 = "",
				wire_textreceiver_text8 = "",
				wire_textreceiver_text9 = "",
				wire_textreceiver_text10 = "",
				wire_textreceiver_text11 = "",
				wire_textreceiver_text12 = ""
			}
		},

		CVars = {
			[0] = "wire_textreceiver_model",
			[1] = "wire_textreceiver_parsetext",
			[2] = "wire_textreceiver_utrigger",
			[3] = "wire_textreceiver_trigger",
			[4] = "wire_textreceiver_hold",
			[5] = "wire_textreceiver_global",
			[6] = "wire_textreceiver_toggle",
			[7] = "wire_textreceiver_outputtext",
			[8] = "wire_textreceiver_SELF",
			[9] = "wire_textreceiver_secure",
			[10] = "wire_textreceiver_playerout",
			[11] = "wire_textreceiver_sensitivity",
			[12] = "wire_textreceiver_text1",
			[13] = "wire_textreceiver_text2",
			[14] = "wire_textreceiver_text3",
			[15] = "wire_textreceiver_text4",
			[16] = "wire_textreceiver_text5",
			[17] = "wire_textreceiver_text6",
			[18] = "wire_textreceiver_text7",
			[19] = "wire_textreceiver_text8",
			[20] = "wire_textreceiver_text9",
			[21] = "wire_textreceiver_text10",
			[22] = "wire_textreceiver_text11",
			[23] = "wire_textreceiver_text12"
		}
	})

	WireDermaExts.ModelSelect(panel, "wire_textreceiver_model", list.Get( "Wire_Misc_Tools_Models" ), 1)

	panel:AddControl("Slider", {
		Label = "#WiretextreceiverTool_utrigger",
		Type = "Float",
		Min = "0",
		Max = "10",
		Command = "wire_textreceiver_utrigger"
	})

	panel:AddControl("Slider", {
		Label = "#WiretextreceiverTool_trigger",
		Type = "Float",
		Min = "1",
		Max = "10",
		Command = "wire_textreceiver_trigger"
	})

	panel:AddControl("Slider", {
		Label = "#WiretextreceiverTool_hold",
		Type = "Float",
		Min = "0.1",
		Max = "10",
		Command = "wire_textreceiver_hold"
	})

	panel:AddControl("TextBox", {Label = "#Tool_wire_textreceiver_parsetext", MaxLength = tostring(2), Command = "wire_textreceiver_parsetext"})

	panel:AddControl("CheckBox", {
		Label = "#WiretextreceiverTool_global",
		Command = "wire_textreceiver_global"
	})

	panel:AddControl("CheckBox", {
		Label = "#WiretextreceiverTool_toggle",
		Command = "wire_textreceiver_toggle"
	})

	panel:AddControl("CheckBox", {
		Label = "#WiretextreceiverTool_outputtext",
		Command = "wire_textreceiver_outputtext"
	})

	panel:AddControl("CheckBox", {
		Label = "#WiretextreceiverTool_SELF",
		Command = "wire_textreceiver_SELF"
	})

	panel:AddControl("CheckBox", {
		Label = "Secure Args",
		Command = "wire_textreceiver_secure"
	})

	panel:AddControl("CheckBox", {
		Label = "Player Outputs",
		Command = "wire_textreceiver_playerout"
	})

	panel:AddControl("ComboBox", {
		Label = "#WiretextreceiverTool_sensitivity",
		MenuButton = "0",
		Options = {
			["#exact"] = { wire_textreceiver_sensitivity = "1" },
			["#case_insensitive"] = { wire_textreceiver_sensitivity = "2" },
			["#anywhere_exact"] = { wire_textreceiver_sensitivity = "3" },
			["#anywhere_case_insensitive"] = { wire_textreceiver_sensitivity = "4" },
		}
	})
	for i = 1,12 do
		panel:AddControl("TextBox", {Label = "#Tool_wire_textreceiver_text"..i, MaxLength = tostring(MaxTextLength), Command = "wire_textreceiver_text"..i})
	end

end
