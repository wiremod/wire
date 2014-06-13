WireToolSetup.setCategory("I/O")
WireToolSetup.open("textentry","Text Entry","gmod_wire_textentry",nil,"Text Entries")
if CLIENT then
	local lang=function(x,y)
		language.Add("Tool.textentry."..x,y)
	end
	lang("name","Wire Text Entry")
	lang("desc","Input strings on a keyboard to be used with the wire system.")
	lang("0","Primary: Create/Update a Text Entry keyboard.")
	language.Add( "sboxlimit_wire_textentrys", "You've hit the Text Entries limit!" )
	language.Add("Undone_gmod_wire_textentry","Undone Wire Text Entry")
end
TOOL.ClientConVar["model"] = "models/beer/wiremod/keyboard.mdl"
TOOL.ClientConVar["delay"] = "0.1"
if SERVER then
	CreateConVar("sbox_maxwire_textentrys",20)
end
function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if !trace.HitPos then return end
	if IsValid(trace.Entity) then
		local ent=trace.Entity
		if ent:GetClass()=="gmod_wire_textentry" then
			//update
			local dlay=self:GetClientNumber("delay")
			if dlay<0.1 then
				dlay=0.1
			end
			ent:SetDelay(dlay)
			return
		end
	end
	local ang=trace.HitNormal:Angle()
	ang:RotateAroundAxis(ang:Right(),-90)
	local ent=WireLib.MakeWireEnt(self:GetOwner(),{Class="gmod_wire_textentry",Pos=trace.HitPos,Angle=ang,Model=self:GetModel()})
	local const=WireLib.Weld(ent,trace.Entity,trace.PhysicsBone,true,false,false)
	undo.Create("Wire Text Entry")
		undo.AddEntity(ent)
		undo.AddEntity(const)
		undo.SetPlayer(self:GetOwner())
	undo.Finish()
	return true
end
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header",{Description="Input strings on a keyboard to be used with the wire system."})
	panel:NumSlider("Hold Length","textentry_delay",0.1,100,1)
	panel:ControlHelp("Sets how long the string output is set to the inputted text in seconds.")
end