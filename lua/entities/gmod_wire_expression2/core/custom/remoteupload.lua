E2Lib.RegisterExtension("remoteupload", false, "Allows the E2 to remotely change the source code of other E2s.")

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

local function checkE2Chip(self, this)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if this:GetClass() ~= "gmod_wire_expression2" then return self:throw("Cannot remoteSetCode non-expression2 chips!", nil) end
	if E2Lib.getOwner(self, this) ~= self.player then return self:throw("You do not own this chip!", nil) end
	return true
end

__e2setcost(1000)
e2function void entity:remoteUpload( string filepath )
	if not checkE2Chip(self, this) then return end
	if not check(self.player) then return end

	umsg.Start( "e2_remoteupload_request", self.player )
		umsg.Entity( this )
		umsg.String( filepath )
	umsg.End()
end

__e2setcost(250)
e2function void entity:remoteSetCode( string code )
	if not checkE2Chip(self, this) then return end
	if not check(self.player) then return end

	timer.Simple( 0, function()
		this:Setup( code, {}, nil, nil, "remoteSetCode" )
	end )
end

e2function void entity:remoteSetCode( string main, table includes )
	if not checkE2Chip(self, this) then return end
	if not check(self.player) then return end

	local luatable = {}

	for k,v in pairs( includes.s ) do
		self.prf = self.prf + 0.3
		if includes.stypes[k] == "s" then
			luatable[k] = v
		else
			error( "Non-string value given to remoteSetCode", 2 )
		end
	end

	timer.Simple( 0, function()
		this:Setup( main, luatable, nil, nil, "remoteSetCode" )
	end )
end

__e2setcost(20)

e2function string getCode()
	local main, _ = self.entity:GetCode()
	return main
end

e2function table getCodeIncludes()
	local _, includes = self.entity:GetCode()
	local e2table = E2Lib.newE2Table()
	local size = 0

	for k,v in pairs( includes ) do
		size = size + 1
		e2table.s[k] = v
		e2table.stypes[k] = "s"
	end

	self.prf = self.prf + size * 0.3
	e2table.size = size

	return e2table
end
