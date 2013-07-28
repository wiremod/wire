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
	self:SetNetworkedBeamFloat( 1, float, true )
end

function ENT:SetDisplayB( float )
	self:SetNetworkedBeamFloat( 2, float, true )
end

function ENT:GetDisplayA( )
	return self:GetNetworkedBeamFloat( 1 )
end

function ENT:GetDisplayB( )
	return self:GetNetworkedBeamFloat( 2 )
end


// Extra stuff for Wire Screen (TheApathetic)
function ENT:SetSingleValue(singlevalue)
	self:SetNetworkedBool("SingleValue",singlevalue)

	// Change inputs if necessary
	if (singlevalue) then
		Wire_AdjustInputs(self, {"A"})
	else
		Wire_AdjustInputs(self, {"A","B"})
	end
end

function ENT:GetSingleValue()
	return self:GetNetworkedBool("SingleValue")
end


function ENT:SetSingleBigFont(singlebigfont)
	self:SetNetworkedBool("SingleBigFont",singlebigfont)
end

function ENT:GetSingleBigFont()
	return self:GetNetworkedBool("SingleBigFont")
end


function ENT:SetTextA(text)
	self:SetNetworkedString("TextA",text)
end

function ENT:GetTextA()
	return self:GetNetworkedString("TextA")
end

function ENT:SetTextB(text)
	self:SetNetworkedString("TextB",text)
end

function ENT:GetTextB()
	return self:GetNetworkedString("TextB")
end


//LeftAlign (TAD2020)
function ENT:SetLeftAlign(leftalign)
	self:SetNetworkedBool("LeftAlign",leftalign)
end

function ENT:GetLeftAlign()
	return self:GetNetworkedBool("LeftAlign")
end


//Floor (TAD2020)
function ENT:SetFloor(Floor)
	self:SetNetworkedBool("Floor",Floor)
end

function ENT:GetFloor()
	return self:GetNetworkedBool("Floor")
end
