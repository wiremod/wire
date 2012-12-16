-- Originally by Jeremydeath, updated by Nebual + Natrim's wirelink
E2Lib.RegisterExtension("wiring", false)

__e2setcost(30)

--- Creates an invisible wire between the input <inputname> of <this> and the output <outputname> of <ent2> 
e2function number entity:createWire(entity ent2, string inputname, string outputname)
	if not IsValid(this) or not IsValid(ent2) then return 0 end
	if not isOwner(self, this) or not isOwner(self, ent2) then return 0 end

	if not this.Inputs or not ent2.Outputs then return 0 end
	if inputname == "" or outputname == "" then return 0 end
	if not this.Inputs[inputname] or not ent2.Outputs[outputname] then return 0 end
	if this.Inputs[inputname].Src then
		local CheckInput = this.Inputs[inputname]
		if CheckInput.SrcId == outputname and CheckInput.Src == ent2 then return 0 end -- Already wired
	end
	
	local trigger = self.entity.trigger
	self.entity.trigger = { false, {} } -- So the wire creation doesn't execute the E2 immediately because an input changed
	Wire_Link_Start(self.player:UniqueID(), this, this:WorldToLocal(this:GetPos()), inputname, "cable/rope", Vector(255,255,255), 0)
	Wire_Link_End(self.player:UniqueID(), ent2, ent2:WorldToLocal(ent2:GetPos()), outputname, self.player)
	self.entity.trigger = trigger
	
	return 1
end

local ValidWireMat = {"cable/rope", "cable/cable2", "cable/xbeam", "cable/redlaser", "cable/blue_elec", "cable/physbeam", "cable/hydra", "arrowire/arrowire", "arrowire/arrowire2"}
--- Creates a wire between the input <input> of <this> and the output <outputname> of <ent2>, using the <width>, <color>, <mat>
e2function number entity:createWire(entity ent2, string inputname, string outputname, width, vector color, string mat)
	if not IsValid(this) or not IsValid(ent2) then return 0 end
	if not isOwner(self, this) or not isOwner(self, ent2) then return 0 end

	if not this.Inputs or not ent2.Outputs then return 0 end
	if inputname == "" or outputname == "" then return 0 end
	if not this.Inputs[inputname] or not ent2.Outputs[outputname] then return 0 end
	if this.Inputs[inputname].Src then
		local CheckInput = this.Inputs[inputname]
		if CheckInput.SrcId == outputname and CheckInput.Src == ent2 then return 0 end -- Already wired
	end
	
	if(!table.HasValue(ValidWireMat,mat)) then
		if(table.HasValue(ValidWireMat,"cable/"..mat)) then
			mat = "cable/"..mat
		elseif(table.HasValue(ValidWireMat,"arrowire/"..mat)) then
			mat = "arrowire/"..mat
		else
			return 0
		end
	end
	
	local trigger = self.entity.trigger
	self.entity.trigger = { false, {} } -- So the wire creation doesn't execute the E2 immediately because an input changed
	Wire_Link_Start(self.player:UniqueID(), this, this:WorldToLocal(this:GetPos()), input, mat, Vector(color[1],color[2],color[3]), width or 1)
	Wire_Link_End(self.player:UniqueID(), ent2, ent2:WorldToLocal(ent2:GetPos()), outputname, self.player)
	self.entity.trigger = trigger
	
	return 1
end

--- Deletes wire leading to <this>'s input <input>
e2function number entity:deleteWire(string inputname)
	if not IsValid(this) or not isOwner(self, this) or inputname == "" then return 0 end

	if not this.Inputs or not this.Inputs[inputname] or not this.Inputs[inputname].Src then return 0 end
	local trigger = self.entity.trigger
	self.entity.trigger = { false, {} } -- So the wire deletion doesn't execute the E2 immediately because an input zero'd
	Wire_Link_Clear(this, inputname)
	self.entity.trigger = trigger
	return 1
end

__e2setcost(10)
--- Returns an array of <this>'s wire input names
e2function array entity:getWireInputs()
	if not IsValid(this) or not isOwner(self, this) or not this.Inputs then return {} end
	local ret = {}
	for k,v in pairs(this.Inputs) do
		if k != "" then
			table.insert(ret, k)
		end
	end
	return ret
end

--- Returns an array of <this>'s wire output names
e2function array entity:getWireOutputs()
	if not IsValid(this) or not isOwner(self, this) or not this.Outputs then return {} end
	local ret = {}
	for k,v in pairs(this.Outputs) do
		if k != "" then
			table.insert(ret, k)
		end
	end
	return ret
end

__e2setcost(25)

--- Returns <this>'s entity wirelink
e2function wirelink entity:wirelink()
	if not IsValid(this) then return nil end
	if not isOwner(self, this) then return nil end
	if not this.Inputs and not this.Outputs then return nil end
	if !this.extended then
		this.extended = true
		RefreshSpecialOutputs(this)
	end
	return this
end

--- Removes <this>'s entity wirelink
e2function number entity:removeWirelink()
	if not IsValid(this) then return 0 end
	if not isOwner(self, this) then return 0 end
	if !this.extended then return 0 end
	this.extended = false
	RefreshSpecialOutputs(this)
	return 1
end

__e2setcost(nil)
