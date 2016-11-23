WireToolSetup.setCategory( "Input, Output" )
WireToolSetup.open( "lever", "Lever", "gmod_wire_lever", nil, "Levers" )

if CLIENT then
	language.Add( "tool.wire_lever.name", "Lever Tool (Wire)" )
	language.Add( "tool.wire_lever.desc", "Spawns a Lever for use with the wire system." )
	language.Add( "tool.wire_lever.minvalue", "Max Value:" )
	language.Add( "tool.wire_lever.maxvalue", "Min Value:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientNumber( "min" ), self:GetClientNumber( "max" )
	end
	
	function TOOL:MakeEnt( ply, model, Ang, trace )
		//return WireLib.MakeWireEnt( ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model}, self:GetConVars() )
		
		local ent = WireLib.MakeWireEnt(ply, {Class = self.WireClass, Pos=(trace.HitPos + trace.HitNormal*22), Angle=Ang, Model=model}, self:GetConVars()) // +trace.HitNormal*46
		
		local ent2 = ents.Create( "prop_physics" )
		ent2:SetModel("models/props_wasteland/tram_leverbase01.mdl") 
		ent2:SetPos(trace.HitPos) // +trace.HitNormal*26
		ent2:SetAngles(Ang)
		ent2:Spawn()
		ent2:Activate()
		ent.BaseEnt = ent2
		
		constraint.Weld(ent, ent2, 0, 0, 0, true)
		ent:SetParent(ent2)
		
		-- Parented + Weld seems more stable than a physical axis
		--local LPos = ent:WorldToLocal(ent:GetPos() + ent:GetUp() * 10)
		--local Cons = constraint.Ballsocket( ent2, ent, 0, 0, LPos, 0, 0, 1)
		--LPos = ent:WorldToLocal(ent:GetPos() + ent:GetUp() * -10)
		--Cons = constraint.Ballsocket( ent2, ent, 0, 0, LPos, 0, 0, 1)
		--constraint.Axis(ent, ent2, 0, 0, ent:WorldToLocal(ent2:GetPos()), ent2:GetRight()*0.15)
		
		return ent2
	end
	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	model = "models/props_wasteland/tram_lever01.mdl",
	min = 0,
	max = 1
}

function TOOL.BuildCPanel(panel)
	panel:NumSlider("#Tool.wire_lever.minvalue", "wire_lever_min", -10, 10, 2 )
	panel:NumSlider("#Tool.wire_lever.maxvalue", "wire_lever_max", -10, 10, 2 )
end
