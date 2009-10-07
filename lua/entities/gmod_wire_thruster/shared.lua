ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Thruster"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetEffect( name )
	self.Entity:SetNetworkedString( "Effect", name )
end
function ENT:GetEffect( name )
	return self.Entity:GetNetworkedString( "Effect" )
end


function ENT:SetOn( boolon )
	self.Entity:SetNetworkedBool( "On", boolon, true )
end
function ENT:IsOn( name )
	return self.Entity:GetNetworkedBool( "On" )
end


function ENT:SetOffset( v )
	self.Entity:SetNetworkedVector( "Offset", v, true )
end
function ENT:GetOffset( name )
	return self.Entity:GetNetworkedVector( "Offset" )
end


function ENT:NetSetForce( force )
	self.Entity:SetNetworkedInt(4, math.floor(force*100))
end
function ENT:NetGetForce()
	return self.Entity:GetNetworkedInt(4)/100
end


local Limit = .1
local LastTime = 0
local LastTimeA = 0
function ENT:NetSetMul( mul )
	--self.Entity:SetNetworkedBeamInt(5, math.floor(mul*100))
	if (CurTime() < LastTimeA + .05) then
		LastTimeA = CurTime()
		return
	end
	LastTimeA = CurTime()

	if (CurTime() > LastTime + Limit) then
		self.Entity:SetNetworkedInt(5, math.floor(mul*100))
		LastTime = CurTime()
	end
end
function ENT:NetGetMul()
	--return self.Entity:GetNetworkedBeamInt(5)/100
	return self.Entity:GetNetworkedInt(5)/100
end


function ENT:GetOverlayText()
	local force = self:NetGetForce()
	local txt = "Thrust = "
	if (self:IsOn()) then
		txt = txt .. ( force * self:NetGetMul() )
	else
		txt = txt .. "off"
	end
	txt = txt .. "\nMul: " ..force
	local PlayerName = self:GetPlayerName()
	if (not SinglePlayer()) then
		txt = txt .. "\n(" .. PlayerName .. ")"
	end
	if(PlayerName and PlayerName ~= "") then
		if (txt == "") then
			return "- "..PlayerName.." -"
		end
		return "- "..PlayerName.." -\n"..txt
	end
	return txt
end
