WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "eyepod", "Eye Pod", "gmod_wire_eyepod", nil, "Eye Pods" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

/* If we're running on the client, setup the description strings */
if ( CLIENT ) then
	//tool hud lang
    language.Add( "Tool.wire_eyepod.name", "Eye Pod Tool (Wire)" )
    language.Add( "Tool.wire_eyepod.desc", "Spawns an Eye Pod Mouse Controller." )
    language.Add( "Tool.wire_eyepod.0", "Primary: Create/Update Controller  Secondary: Link controller  Reload: Unlink EyePod/Cancel Current Link" )
	language.Add("Tool_wire_eyepod_1", "Now select the pod to link to.")

	//panel control lang
	language.Add( "WireEyePod_DefaultToZero", "Default Outputs To Zero When Inactive" )
	language.Add( "WireEyePod_CumulativeOutput", "Output Cumulative Mouse Position" )

	//management lang
    language.Add( "undone_Wire Eye Pod", "Undone Wire Eye Pod" )
elseif (SERVER) then
	CreateConVar('sbox_maxwire_eyepods', 15)
end

//console varibles
TOOL.ClientConVar[ "DefaultToZero" ] = "1"
TOOL.ClientConVar[ "CumulativeOutput" ] = "0"

//clamps
TOOL.ClientConVar[ "XMin" ] = "0"
TOOL.ClientConVar[ "XMax" ] = "0"
TOOL.ClientConVar[ "YMin" ] = "0"
TOOL.ClientConVar[ "YMax" ] = "0"


cleanup.Register( "wire_eyepods" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	if ( !self:GetSWEP():CheckLimit( "wire_eyepods" ) ) then return false end

	/* Setup all of our local variables */
	local ply = self:GetOwner()

	//get numbers from client
	local DefaultToZero = self:GetClientNumber("DefaultToZero")
	local CumulativeOutput = self:GetClientNumber("CumulativeOutput")
	local ShowRateOfChange = 1
	if (CumulativeOutput == 1) then
		ShowRateOfChange = 0
	else
		ShowRateOfChange = 1
	end
	//set the default to zero to one if you are showing the mouse position instead
	if (ShowRateOfChange == 1) then DefaultToZero = 1 end
	//get clamp
	local ClampXMin = self:GetClientNumber("XMin")
	local ClampXMax = self:GetClientNumber("XMax")
	local ClampYMin = self:GetClientNumber("YMin")
	local ClampYMax = self:GetClientNumber("YMax")
	local ClampX = 0
	local ClampY = 0
	//test clamp
	if ( (ClampXMin != 0 or ClampXMax != 0) and (ClampYMin != 0 or ClampYMax != 0) and
		ClampXMin != ClampXMax and ClampYMin != ClampYMax and
		ClampXMin < ClampXMax and ClampYMin < ClampYMax ) then

		ClampXMin = self:GetClientNumber("XMin")
		ClampXMax = self:GetClientNumber("XMax")
		ClampYMin = self:GetClientNumber("YMin")
		ClampYMax = self:GetClientNumber("YMax")

		ClampX = 1
		ClampY = 1
	elseif( (ClampXMin == 0 and ClampXMax == 0) or (ClampYMin == 0 or ClampYMax == 0) )then
		if(ClampXMin == 0 and ClampXMax == 0 and (ClampYMin != 0 or ClampYMax != 0)) then
			ClampX = 0
			ClampY = 1
			ClampYMin = self:GetClientNumber("YMin")
			ClampYMax = self:GetClientNumber("YMax")
		elseif(ClampYMin == 0 and ClampYMax == 0 and (ClampXMin != 0 or ClampXMax != 0)) then
			ClampX = 1
			ClampY = 0
			ClampXMin = self:GetClientNumber("XMin")
			ClampXMax = self:GetClientNumber("XMax")
		else
			ClampX = 0
			ClampY = 0
		end
	else
		WireLib.AddNotify(ply, "Invalid Clamping of Wire EyePod Values!", NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP1)
		return false
	end


	//update the eyepod
	if (trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_eyepod") then
		trace.Entity:Setup(DefaultToZero,ShowRateOfChange, ClampXMin, ClampXMax, ClampYMin, ClampYMax, ClampX, ClampY)
		return true
	end

	/* Normal to hit surface */
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	/* Make the EyePod */
	local ent = MakeWireEyePod(ply, trace.HitPos, Ang, self:GetModel(), DefaultToZero, ShowRateOfChange, ClampXMin, ClampXMax, ClampYMin, ClampYMax, ClampX, ClampY)

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/* Weld it to the surface, as long as it isn't the ground */
	if (!trace.HitWorld) then
		local const = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true)
	end

	/* Add it to the undo list */
	undo.Create("Wire Eye Pod")
		undo.AddEntity(ent)
		if (!(const == nil)) then
			undo.AddEntity(const)
		end
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup( "wire_eyepods", ent )

	return true
end

//link the eyepod to the vehicle
function TOOL:RightClick(trace)
	if ( CLIENT ) then return true end
	local entity = trace.Entity
	if self:GetStage() == 0 and entity:GetClass() == "gmod_wire_eyepod" then
		self.PodCont = entity
		if self.PodCont.pod and self.PodCont.pod:IsValid() and self.PodCont.pod.AttachedWireEyePod then
			self.PodCont.pod.AttachedWireEyePod = nil
			self.PodCont.pod = nil
		end
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and entity.GetPassenger then
		if entity.AttachedWireEyePod then
			self:GetOwner():ChatPrint("Pod Already Has An EyePod Linked To It!")
			return false
		end
		local Success = self.PodCont:PodLink(entity)
		if (Success == false) then
			self:GetOwner():ChatPrint("Error: Cannot Link Eye Pod!")
			return false
		end
		self:SetStage(0)
		self.PodCont = nil
		self:GetOwner():ChatPrint("Wire Eye Pod Linked")
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	if ( CLIENT ) then return true end

	if self:GetStage() == 1 then
		self:SetStage(0)
		self.PodCont = nil
		return false
	elseif self:GetStage() == 0 and trace.Entity and trace.Entity:GetClass() == "gmod_wire_eyepod" then
		self:SetStage(0)
		self.PodCont = nil
		trace.Entity:PodLink(nil)
		self:GetOwner():ChatPrint("Wire Eye Pod Unlinked")
		return true
	end
end

if (SERVER) then
	/* Makes an EyePod */
	function MakeWireEyePod(pl, Pos, Ang, model, DefaultToZero, ShowRateOfChange, ClampXMin, ClampXMax, ClampYMin, ClampYMax, ClampX, ClampY)
		if !pl:CheckLimit( "wire_eyepods" ) then return false end
		local ent = ents.Create("gmod_wire_eyepod")
		if !ent:IsValid() then return false end
		ent:SetAngles(Ang)
		ent:SetPos(Pos)
		ent:SetModel(model)
		ent:Spawn()
		ent:SetPlayer(pl)
		ent:Setup(DefaultToZero,ShowRateOfChange,ClampXMin,ClampXMax,ClampYMin,ClampYMax, ClampX, ClampY)

		ent:SetPlayer( pl )

		local ttable = {
		    DefaultToZero = DefaultToZero,
			ShowRateOfChange = ShowRateOfChange,
			ClampXMin = ClampXMin,
			ClampXMax = ClampXMax,
			ClampYMin = ClampYMin,
			ClampYMax = ClampYMax,
			ClampX = ClampX,
			ClampY = ClampY,
			pl = pl
		}
		table.Merge(ent:GetTable(), ttable )

		pl:AddCount( "wire_eyepods", ent )

		return ent
	end
	duplicator.RegisterEntityClass("gmod_wire_eyepod", MakeWireEyePod, "Pos", "Ang", "Model", "DefaultToZero", "ShowRateOfChange" , "ClampXMin" , "ClampXMax" , "ClampYMin" , "ClampYMax" , "ClampX", "ClampY")
end

-------------------------------------- TOOL Menu ---------------------------------------------------
//TODO:  Figure out a way for dynamic panels to work with check boxes (check boxes that use concommands instead of convars default to 1 allways)
//check for client
if (CLIENT) then

	function Wire_EyePod_Menu(panel)
		panel:ClearControls()

		panel:AddControl("Header", {
			Text = "#Tool.wire_eyepod.name",
			Description = "#Tool.wire_eyepod.desc"
		})

		//preset chooser
		panel:AddControl("ComboBox", {
			Label = "#Presets",
			MenuButton = "1",
			Folder = "wire_eyepod",

			Options = {
				Default = {
					wire_eyepod_DefaultToZero = "1",
					wire_eyepod_CumulativeOutput = "0",
					wire_eyepod_XMin = "0",
					wire_eyepod_XMax = "0",
					wire_eyepod_YMin = "0",
					wire_eyepod_YMax = "0"
				}
			},

			CVars = {
				[0] = "wire_eyepod_DefaultToZero",
				[1] = "wire_eyepod_CumulativeOutput",
				[2] = "wire_eyepod_XMin",
				[3] = "wire_eyepod_XMax",
				[4] = "wire_eyepod_YMin",
				[5] = "wire_eyepod_YMax"
			}
		})

		WireDermaExts.ModelSelect(panel, "wire_eyepod_model", list.Get( "Wire_Misc_Tools_Models" ), 1)

		panel:AddControl("CheckBox", {
			Label = "#WireEyePod_CumulativeOutput",
			Command = "wire_eyepod_CumulativeOutput"
		})

		panel:AddControl("CheckBox", {
			Label = "#WireEyePod_DefaultToZero",
			Command = "wire_eyepod_DefaultToZero"
		})

		//clamps
		panel:AddControl( "Label",  {
					Text = "\nClamp the output of the EyePod. \nSet both sliders to 0 to remove the clamp in that axis.",
					Description = "Clamps the outputs of the EyePod. Set to 0 not to clamp in that axis"}    )

		panel:AddControl( "Slider",  {
					Label	= "X Min",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_XMin",
					Description = "Clamps the output of the EyePod's X to this minimum"}	 )

		panel:AddControl( "Slider",  {
					Label	= "X Max",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_XMax",
					Description = "Clamps the output of the EyePod's X to this maximum"}	 )
		panel:AddControl( "Slider",  {
					Label	= "Y Min",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_YMin",
					Description = "Clamps the output of the EyePod's Y to this minimum"}	 )

		panel:AddControl( "Slider",  {
					Label	= "Y Max",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_YMax",
					Description = "Clamps the output of the EyePod's Y to this maximum"}	 )
	end

	function TOOL.BuildCPanel( panel )
		Wire_EyePod_Menu(panel)
	end

end
