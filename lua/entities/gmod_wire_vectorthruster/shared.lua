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

function ENT:SetMode( v )
	self:SetNetworkedInt( "vecmode", v, true )
end
function ENT:GetMode()
	return self:GetNetworkedInt( "vecmode" )
end

function ENT:SetOffset( v )
	self:SetNetworkedVector( "Offset", v, true )
end
function ENT:GetOffset( name )
	return self:GetNetworkedVector( "Offset" )
end

function ENT:SetNormal( v )
	self:SetNetworkedInt( "vecx", v.x * 100, true )
	self:SetNetworkedInt( "vecy", v.y * 100, true )
	self:SetNetworkedInt( "vecz", v.z * 100, true )
end
function ENT:GetNormal()
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
	local mode = self:GetMode()
	return string.format("Force Mul: %.2f\nInput: %.2f\nForce Applied: %.2f\nMode: %s",
		self:NetGetForce(),
		self:NetGetMul(),
		self:NetGetForce() * self:NetGetMul(),
		(mode == 0 and "XYZ Local") or (mode == 1 and "XYZ World") or (mode == 2 and "XY Local, Z World")
	)
end
