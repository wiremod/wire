-- Originally by Jeremydeath, updated by Nebual + Natrim's wirelink
E2Lib.RegisterExtension("wiring", false, "Allows the creation and deletion of wires between entities and getting wirelinks.")

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
	WireLib.Link_Start(self.player:UniqueID(), this, this:WorldToLocal(this:GetPos()), inputname, "cable/rope", Vector(255,255,255), 0)
	WireLib.Link_End(self.player:UniqueID(), ent2, ent2:WorldToLocal(ent2:GetPos()), outputname, self.player)
	self.entity.trigger = trigger

	return 1
end

local ValidWireMat = {"cable/rope", "cable/cable2", "cable/xbeam", "cable/redlaser", "cable/blue_elec", "cable/physbeam", "cable/hydra", "arrowire/arrowire", "arrowire/arrowire2"}
--- Creates a wire between the input <input> of <this> and the output <outputname> of <ent2>, using the <width>, <color>, <mat>
e2function number entity:createWire(entity ent2, string inputname, string outputname, width, vector color, string mat)
	if not IsValid(this) or not IsValid(ent2) then return self:throw("One or more invalid entities in createWire!", 0) end
	if not isOwner(self, this) or not isOwner(self, ent2) then return self:throw("You do not own one or more of these entities!", 0) end

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
	WireLib.Link_Start(self.player:UniqueID(), this, this:WorldToLocal(this:GetPos()), inputname, mat, Vector(color[1],color[2],color[3]), width or 1)
	WireLib.Link_End(self.player:UniqueID(), ent2, ent2:WorldToLocal(ent2:GetPos()), outputname, self.player)
	self.entity.trigger = trigger

	return 1
end

--- Deletes wire leading to <this>'s input <input>
e2function number entity:deleteWire(string inputname)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", 0) end

	if inputname=="" or not this.Inputs or not this.Inputs[inputname] or not this.Inputs[inputname].Src then return self:throw("Invalid inputname!", 0) end
	local trigger = self.entity.trigger
	self.entity.trigger = { false, {} } -- So the wire deletion doesn't execute the E2 immediately because an input zero'd
	WireLib.Link_Clear(this, inputname)
	self.entity.trigger = trigger
	return 1
end

__e2setcost(10)
--- Returns an array of <this>'s wire input names
e2function array entity:getWireInputs()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", {}) end

	local ret = {}
	if not this.Inputs then return ret end
	for k,v in pairs(this.Inputs) do
		if k ~= "" then
			table.insert(ret, k)
		end
	end
	return ret
end

--- Returns an array of <this>'s wire output names
e2function array entity:getWireOutputs()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", {}) end

	local ret = {}
	if not this.Outputs then return ret end
	for k,v in pairs(this.Outputs) do
		if k ~= "" then
			table.insert(ret, k)
		end
	end
	return ret
end

__e2setcost(5)

--- Returns <this>'s entity wirelink
e2function wirelink entity:wirelink()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	return this
end

e2function wirelink entity:createWirelink()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	if not this.extended then
		WireLib.CreateWirelinkOutput(self.player, this, { true })
	end
	return this
end

__e2setcost(10)

--- Links <this> to <ent2> if applicable
e2function number entity:linkTo(entity ent2)
	if not IsValid(this) or not IsValid(ent2) then return self:throw("Invalid Entity!", 0) end
	if not isOwner(self, this) or not isOwner(self, ent2) then return self:throw("You do not own this entity", 0) end

	if not this.LinkEnt then return self:throw("Entity can't be linked", 0) end
	return this:LinkEnt(ent2) and 1 or 0
end

--- Unlinks <this> from <ent2> if applicable
e2function number entity:unlinkFrom(entity ent2)
	if not IsValid(this) or not IsValid(ent2) then return self:throw("Invalid Entity!", 0) end
	if not isOwner(self, this) or not isOwner(self, ent2) then return self:throw("You do not own this entity", 0) end

	if not this.UnlinkEnt then return self:throw("Entity can't be unlinked", 0) end
	return this:UnlinkEnt(ent2) and 1 or 0
end

--- Clears <this>'s links if applicable
e2function void entity:clearLinks()
	if not IsValid(this) then return self:throw("Invalid Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	if this.ClearEntities then
		this:ClearEntities()
	elseif this.UnlinkEnt then
		this:UnlinkEnt()
	else
		self:throw("Entity links cannot be cleared!")
	end
end
