E2Lib.RegisterExtension("remoteupload", false)

local antispam = {}

local function check(ply)
	if antispam[ply] and antispam[ply] > CurTime() then
		return false
	else
		antispam[ply] = CurTime() + 1
		return true
	end
end

umsg.PoolString("e2_remoteupload_request")

__e2setcost(1000)
e2function void entity:remoteUpload( string filepath )
	if not this or not this:IsValid() or this:GetClass() ~= "gmod_wire_expression2" then return end
	if not E2Lib.isOwner( self, this ) then return end
	if not check(self.player) then return end

	umsg.Start( "e2_remoteupload_request", self.player )
		umsg.Entity( this )
		umsg.String( filepath )
	umsg.End()
end

__e2setcost(250)
e2function void entity:remoteSetCode( string code )
	if not this or not this:IsValid() or this:GetClass() ~= "gmod_wire_expression2" then return end
	if not E2Lib.isOwner( self, this ) then return end
	
	this:Setup( code, {} )
end
