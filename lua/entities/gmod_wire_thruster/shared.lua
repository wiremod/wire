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
	self:SetNetworkedString( "Effect", name )
end
function ENT:GetEffect( name )
	return self:GetNetworkedString( "Effect" )
end


function ENT:SetOn( boolon )
	self:SetNetworkedBool( "On", boolon, true )
end
function ENT:IsOn( name )
	return self:GetNetworkedBool( "On" )
end


function ENT:SetOffset( v )
	self:SetNetworkedVector( "Offset", v, true )
end
function ENT:GetOffset( name )
	return self:GetNetworkedVector( "Offset" )
end


function ENT:NetSetForce( force )
	self:SetNetworkedInt(4, math.floor(force*100))
end
function ENT:NetGetForce()
	return self:GetNetworkedInt(4)/100
end


local Limit = .1
local LastTime = 0
local LastTimeA = 0
function ENT:NetSetMul( mul )
	--self:SetNetworkedBeamInt(5, math.floor(mul*100))
	if (CurTime() < LastTimeA + .05) then
		LastTimeA = CurTime()
		return
	end
	LastTimeA = CurTime()

	if (CurTime() > LastTime + Limit) then
		self:SetNetworkedInt(5, math.floor(mul*100))
		LastTime = CurTime()
	end
end
function ENT:NetGetMul()
	--return self:GetNetworkedBeamInt(5)/100
	return self:GetNetworkedInt(5)/100
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
