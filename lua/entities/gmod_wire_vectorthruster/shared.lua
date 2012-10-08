ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Vector Thruster"
ENT.Author          = "TAD2020"
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetEffect( name )
	self:SetNetworkedString( "Effect", name )
end
function ENT:GetEffect()
	return self:GetNetworkedString( "Effect" )
end


function ENT:SetOn( boolon )
	self:SetNetworkedBool( "vecon", boolon, true )
end
function ENT:IsOn()
	return self:GetNetworkedBool( "vecon" )
end


/*function ENT:SetToWorld( b )
	self:SetNetworkedBool( "vecworld", b, true )
end
function ENT:IsToWorld()
	return self:GetNetworkedBool( "vecworld" )
end*/


function ENT:SetMode( v )
	self:SetNetworkedInt( "vecmode", v, true )
end
function ENT:GetMode()
	return self:GetNetworkedInt( "vecmode" )
end


function ENT:SetOffset( v )
	--self:SetNetworkedBeamVector( "Offset", v, true )
	self:SetNetworkedInt( "vecx", v.x * 100, true )
	self:SetNetworkedInt( "vecy", v.y * 100, true )
	self:SetNetworkedInt( "vecz", v.z * 100, true )
end
function ENT:GetOffset()
	--return self:GetNetworkedBeamVector( "Offset" )
	return Vector(
				self:GetNetworkedInt( "vecx" ) / 100,
				self:GetNetworkedInt( "vecy" ) / 100,
				self:GetNetworkedInt( "vecz" ) / 100
			)
end


function ENT:NetSetForce( force )
	self:SetNetworkedInt("vecforce", math.floor(force*100))
end
function ENT:NetGetForce()
	return self:GetNetworkedInt("vecforce")/100
end


local Limit = .1
local LastTime = 0
function ENT:NetSetMul( mul )
	--self:SetNetworkedBeamInt("vecmul", math.floor(mul*100))
	if (CurTime() > LastTime + Limit) then
		self:SetNetworkedInt("vecmul", math.floor((mul or 0)*100))
		LastTime = CurTime()
	end
end
function ENT:NetGetMul()
	--return self:GetNetworkedBeamInt(5)/100
	return self:GetNetworkedInt("vecmul")/100
end


function ENT:GetOverlayText()

	local txt = "Thrust = "
	local force = self:NetGetForce()
	if (self:IsOn()) then
		txt = txt .. ( force * self:NetGetMul() )
	else
		txt = txt .. "off"
	end
	txt = txt .. "\nMul: " .. force .. "\nMode: "

	local mode = self:GetMode()
	if (self.Mode == 0) then
		txt = txt .. "XYZ Local"
	elseif (self.Mode == 1) then
		txt = txt .. "XYZ World"
	elseif (self.Mode == 2) then
		txt = txt .. "XY Local, Z World"
	end

	if (not game.SinglePlayer()) then
		local PlayerName = self:GetPlayerName()
		txt = txt .. "\n(" .. PlayerName .. ")"
	end

	return txt
end
