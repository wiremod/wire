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

e2function void entity:remoteSetCode( string main, table includes )
	if not this or not this:IsValid() or this:GetClass() ~= "gmod_wire_expression2" then return end
	if not E2Lib.isOwner( self, this ) then return end

	local luatable = {}
	
	for k,v in pairs( includes.s ) do
		if includes.stypes[k] == "s" and k ~= "main" then
			luatable[k] = v
		else
			error( "Non-string value given to remoteSetCode", 2 )
		end
	end
	
	this:Setup( main, luatable )
end

e2function string getCode()
	local main, _ = self.entity:GetCode()
	return main
end

e2function table getCodeIncludes()
	local _, includes = self.entity:GetCode()
	local e2table = {n={},ntypes={},s={},stypes={},size=0}
	
	for k,v in pairs( includes ) do
		e2table.s[k] = v
		e2table.stypes[k] = "s"
	end
	
	return e2table
end
