ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Screen"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetDisplayA( float )
	self.Entity:SetNetworkedBeamFloat( 1, float, true )
end

function ENT:SetDisplayB( float )
	self.Entity:SetNetworkedBeamFloat( 2, float, true )
end

function ENT:GetDisplayA( )
	return self.Entity:GetNetworkedBeamFloat( 1 )
end

function ENT:GetDisplayB( )
	return self.Entity:GetNetworkedBeamFloat( 2 )
end


// Extra stuff for Wire Screen (TheApathetic)
function ENT:SetSingleValue(singlevalue)
	self.Entity:SetNetworkedBool("SingleValue",singlevalue)

	// Change inputs if necessary
	if (singlevalue) then
		Wire_AdjustInputs(self.Entity, {"A"})
	else
		Wire_AdjustInputs(self.Entity, {"A","B"})
	end
end

function ENT:GetSingleValue()
	return self.Entity:GetNetworkedBool("SingleValue")
end


function ENT:SetSingleBigFont(singlebigfont)
	self.Entity:SetNetworkedBool("SingleBigFont",singlebigfont)
end

function ENT:GetSingleBigFont()
	return self.Entity:GetNetworkedBool("SingleBigFont")
end


function ENT:SetTextA(text)
	self.Entity:SetNetworkedString("TextA",text)
end

function ENT:GetTextA()
	return self.Entity:GetNetworkedString("TextA")
end

function ENT:SetTextB(text)
	self.Entity:SetNetworkedString("TextB",text)
end

function ENT:GetTextB()
	return self.Entity:GetNetworkedString("TextB")
end


//LeftAlign (TAD2020)
function ENT:SetLeftAlign(leftalign)
	self.Entity:SetNetworkedBool("LeftAlign",leftalign)
end

function ENT:GetLeftAlign()
	return self.Entity:GetNetworkedBool("LeftAlign")
end


//Floor (TAD2020)
function ENT:SetFloor(Floor)
	self.Entity:SetNetworkedBool("Floor",Floor)
end

function ENT:GetFloor()
	return self.Entity:GetNetworkedBool("Floor")
end
