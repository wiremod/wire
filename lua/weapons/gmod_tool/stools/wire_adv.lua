
-- Load wiremod tools in /lua/wire/stools/
-- Note: If this tool is ever removed, be sure to put this in another stool!
local OLD_TOOL = TOOL
TOOL = nil
include( "wire/tool_loader.lua" )
TOOL = OLD_TOOL

TOOL.Category	= "Tools"
TOOL.Name		= "Wire"
TOOL.Tab		= "Wire"

if CLIENT then
	language.Add( "Tool.wire_adv.name", "Wiring Tool" )
	language.Add( "Tool.wire_adv.desc", "Connect things with wires. (Press Shift+F to switch to the debugger tool)" )
	language.Add( "Tool.wire_adv.desc2", "Used to connect wirable props." )
	language.Add( "WireTool_width", "Width:" )
	language.Add( "WireTool_material", "Material:" )
	language.Add( "WireTool_colour", "Colour:" )
	language.Add( "WireTool_stick", "Stick to surfaces" )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Select input (Shift: Select multiple; Alt: Select all)" },
		{ name = "right_0", stage = 0, text = "Next" },
		{ name = "reload_0", stage = 0, text = "Unlink (Alt: Unlink all)" },
		{ name = "mwheel_0", stage = 0, text = "Mouse wheel: Next" },
		{ name = "left_1", stage = 1, text = "Select entity" },
		{ name = "right_1", stage = 1, text = "Add wirepoint" },
		{ name = "f_0", stage = 1, text = "F: Undo wirepoint" },
		{ name = "reload_1", stage = 1, text = "Cancel" },
		{ name = "left_2", stage = 2, text = "Select output (Alt: Auto-connect matching input/outputs)" },
		{ name = "right_2", stage = 2, text = "Next" },
		{ name = "mwheel_2", stage = 2, text = "Mouse wheel: Next" },
		{ name = "shift_reload", stage = 0, text = "Shift + Reload: Remove wirelink and entity outputs" }
	}
	for _, info in pairs(TOOL.Information) do
		language.Add("Tool.wire_adv." .. info.name, info.text)
	end

	TOOL.Wire_ToolMenuIcon = "icon16/connect.png"
end

TOOL.ClientConVar = {
	width = 2,
	material = "cable/cable2",
	r = 255,
	g = 255,
	b = 255,
	stick = 1
}

util.PrecacheSound("weapons/pistol/pistol_empty.wav")
util.PrecacheSound("buttons/lightswitch2.wav")
util.PrecacheSound("buttons/button16.wav")

-- check that the table exists and isn't empty at the same time
local function isTableEmpty(t) return t ~= nil and next(t) ~= nil end

if SERVER then
	-----------------------------------------------------------------
	-- Duplicator modifiers
	-----------------------------------------------------------------
	function WireLib.CreateWirelinkOutput( ply, ent, data )
		duplicator.StoreEntityModifier(ent, "CreateWirelinkOutput", data)
		if data[1] == true then
			if ent.Outputs then
				local names = {}
				local types = {}
				local descs = {}
				local x = 0
				for _,v in pairs( ent.Outputs ) do
					x = x + 1
					local num = v.Num
					names[num] = v.Name
					if v.Name == "wirelink" then return end -- we already have a wirelink output, abort
					types[num] = v.Type
					descs[num] = v.Desc
				end

				WireLib.AdjustSpecialOutputs(ent, names, types, descs)
			else
				WireLib.CreateSpecialOutputs( ent, { "wirelink" }, { "WIRELINK" } )
			end

			ent.extended = true
			WireLib.TriggerOutput( ent, "wirelink", ent )
		end
	end
	duplicator.RegisterEntityModifier( "CreateWirelinkOutput", WireLib.CreateWirelinkOutput )

	function WireLib.CreateEntityOutput( ply, ent, data )
		duplicator.StoreEntityModifier(ent, "CreateEntityOutput", data)
		if data[1] == true then
			if ent.Outputs then
				local names = {}
				local types = {}
				local descs = {}
				local x = 0
				for _,v in pairs( ent.Outputs ) do
					x = x + 1
					local num = v.Num
					names[num] = v.Name
					if v.Name == "entity" then return end -- we already have an entity output, abort
					types[num] = v.Type
					descs[num] = v.Desc
				end

				WireLib.AdjustSpecialOutputs( ent, names, types, descs )
			else
				WireLib.CreateSpecialOutputs( ent, { "entity" }, { "ENTITY" } )
			end

			WireLib.TriggerOutput( ent, "entity", ent )
		end
	end
	duplicator.RegisterEntityModifier( "CreateEntityOutput", WireLib.CreateEntityOutput )

	local function removeWirelinkOutput(ent)
		if ent.EntityMods and ent.EntityMods.CreateWirelinkOutput and ent.Outputs and ent.Outputs.wirelink then
			WireLib.DisconnectOutput(ent, "wirelink")
			ent.Outputs.wirelink = nil
			WireLib.RemoveOutPort(ent, "wirelink")
			duplicator.ClearEntityModifier(ent, "CreateWirelinkOutput")
			WireLib._SetOutputs(ent)
		end
	end

	local function removeEntityOutput(ent)
		if ent.EntityMods and ent.EntityMods.CreateEntityOutput and ent.Outputs and ent.Outputs.entity then
			WireLib.DisconnectOutput(ent, "entity")
			ent.Outputs.entity = nil
			WireLib.RemoveOutPort(ent, "entity")
			duplicator.ClearEntityModifier(ent, "CreateEntityOutput")
			WireLib._SetOutputs(ent)
		end
	end

	-----------------------------------------------------------------
	-- Receving data from client
	-----------------------------------------------------------------

	local function wireAdvUpload(ply, wirings)
		local tool = WireToolHelpers.GetActiveTOOL("wire_adv",ply)
		if not tool then return end

		local material = tool:GetClientInfo("material")
		local width    = tool:GetClientNumber("width")
		local color    = Color(tool:GetClientNumber("r"), tool:GetClientNumber("g"), tool:GetClientNumber("b"))

		local uid = ply:UniqueID()

		for i=1,#wirings do
			local wiring = wirings[i]

			local inputentity = wiring[3]
			local outputentity = wiring[5]

			if IsValid( inputentity ) and IsValid( outputentity ) and
				WireLib.CanTool(ply, inputentity, "wire_adv" ) and
				WireLib.CanTool(ply, outputentity, "wire_adv" ) then

				local inputname = wiring[1]
				local inputpos = wiring[2]
				if WireLib.Link_Start( uid, inputentity, inputpos, inputname, material, color, width ) then
					for i=1,#wiring[4] do
						local node = wiring[4][i]
						WireLib.Link_Node( uid, node[1], node[2] )
					end
					local outputpos = wiring[6]
					local outputname = wiring[7]

					if outputname == "Create Wirelink" and (not outputentity.Outputs or not outputentity.Outputs["wirelink"]) then
						WireLib.CreateWirelinkOutput( ply, outputentity, {true} )
						outputname = "wirelink"
					elseif outputname == "Create Wirelink" and outputentity.Outputs and outputentity.Outputs["wirelink"] then
						outputname = "wirelink"
					elseif outputname == "Create Entity" and (not outputentity.Outputs or not outputentity.Outputs["entity"]) then
						WireLib.CreateEntityOutput( ply, outputentity, {true} )
						outputname = "entity"
					elseif outputname == "Create Entity" and outputentity.Outputs and outputentity.Outputs["entity"] then
						outputname = "entity"
					end

					WireLib.Link_End( uid, outputentity, outputpos, outputname, ply )
				end
			end
		end
	end

	local function wireAdvUnwire(ply, ent, tbl)
		if WireLib.CanTool(ply, ent, "wire_adv") then
			for i=1,#tbl do
				WireLib.Link_Clear( ent, tbl[i] )
			end
		end
	end

	local function wireAdvRemoveUGLinks(ply, ent)
		if WireLib.CanTool(ply, ent, "wire_adv") then
			if ent:IsValid() then
				removeEntityOutput(ent)
				removeWirelinkOutput(ent)
			end
		end
	end

	util.AddNetworkString("wire_adv_upload")
	local function wireAdvReceiver(_, ply)
		local flag = net.ReadUInt(8)

		if flag == 1 then
			wireAdvUpload(ply, net.ReadTable())
		elseif flag == 2 then
			wireAdvUnwire(ply, net.ReadEntity(), net.ReadTable())
		elseif flag == 3 then
			wireAdvRemoveUGLinks(ply, net.ReadEntity())
		else
			ErrorNoHalt("Tried to call wire_adv_upload without a proper message flag")
		end
	end
	net.Receive("wire_adv_upload", wireAdvReceiver)

	util.AddNetworkString("wire_adv_unwire")
	net.Receive( "wire_adv_unwire", function(ply)
		ErrorNoHalt("wire_adv_unwire is deprecated, use wire_adv_upload with an unsigned byte 2 at the start")

		wireAdvUnwire(ply, net.ReadEntity(), net.ReadTable())
	end)

	WireToolHelpers.SetupSingleplayerClickHacks(TOOL)
elseif CLIENT then

	-----------------------------------------------------------------
	-- Tool helper functions
	-----------------------------------------------------------------
	TOOL._stage = 0
	function TOOL:SetStage(stage) -- Garry's stage functions didn't work, had to make my own
		self._stage = stage
	end
	function TOOL:GetStage()
		return self._stage
	end
	function TOOL:SanitizeUpload() -- Removes any wirings that are no longer valid
		for i=#self.Wiring,1,-1 do
			local wiring = self.Wiring[i]
			local inputentity = wiring[3]
			local outputentity = wiring[5]
			local outputname = wiring[7]

			if 	not IsValid(inputentity) or
				not IsValid(outputentity) or
				not outputname then -- we don't need to check everything because only these things can possibly be invalid

				table.remove(self.Wiring,i)
			end
		end
	end
	function TOOL:Upload()
		self:SanitizeUpload() -- Remove all invalid wirings before sending

		net.Start("wire_adv_upload")
			net.WriteUInt(1, 8)
			net.WriteTable( self.Wiring )
		net.SendToServer()

		self:Holster()
	end
	function TOOL:Unwire( ent, names )
		net.Start("wire_adv_upload")
			net.WriteUInt(2, 8)
			net.WriteEntity( ent )
			net.WriteTable( names )
		net.SendToServer()
	end


	-----------------------------------------------------------------
	-- GetPorts
	-----------------------------------------------------------------
	TOOL.AimingEnt2 = nil
	TOOL.CurrentInputs = nil
	TOOL.CurrentOutputs = nil
	function TOOL:CachePorts( ent )
		local inputs, outputs = WireLib.GetPorts( ent )

		local copied = false

		if self.ShowWirelink then
			if outputs then
				local found = false
				for i=1,#outputs do
					if outputs[i] and outputs[i][2] == "WIRELINK" then found = true break end
				end
				if not found then
					outputs = table.Copy(outputs) -- we don't want to modify the original table
					copied = true
					outputs[#outputs+1] = { "Create Wirelink", "WIRELINK" }
				end
			else
				outputs = { { "Create Wirelink", "WIRELINK" } }
			end
		end

		if self.ShowEntity then
			if outputs then
				local found = false
				for i=1,#outputs do
					if (outputs[i][1] == "entity" and outputs[i][2] == "ENTITY") or
						(outputs[i][1] == "Create Entity" and outputs[i][2] == "ENTITY") then found = true break end
				end
				if not found then
					if not copied then -- we don't want to copy it twice
						outputs = table.Copy(outputs)
					end
					outputs[#outputs+1] = { "Create Entity", "ENTITY" }
				end
			else
				outputs = { { "Create Entity", "ENTITY" } }
			end
		end
		self.CurrentInputs = inputs
		self.CurrentOutputs = outputs
	end

	local next_recache = 0
	function TOOL:GetPorts( ent )
		if IsValid( ent ) then
			if ent ~= self.AimingEnt2 or next_recache < CurTime() then
				next_recache = CurTime() + 1
				self.AimingEnt2 = ent
				self:CachePorts( ent )
			end
			return self.CurrentInputs, self.CurrentOutputs
		else
			self.CurrentInputs = nil
			self.CurrentOutputs = nil
			self.AimingEnt2 = nil
		end
	end

	TOOL.CurrentWireIndex = 1
	TOOL.CurrentEntity = nil -- entity which was selected in mode 1
	TOOL.Wiring = {} -- all wires
	TOOL.WiringRender = {} -- table for rendering inputs nicely
	TOOL.NeedsUpload = false -- bool for sending all wires to server
	TOOL.ShowWirelink = false -- bool for showing "Create Wirelink" output
	TOOL.ShowEntity = false -- bool for showing "Create Entity" output

	function TOOL:Holster()
		if IsValid(self.CurrentEntity) then self.CurrentEntity:SetNWString("BlinkWire", "") end
		if IsValid(self.AimingEnt) then self.AimingEnt:SetNWString("BlinkWire", "") end
		self.CurrentEntity = nil
		self.Wiring = {}
		self.WiringRender = {}
		self.ShowWirelink = false
		self.ShowEntity = false
		self:SetStage(0)
		WireLib.WiringToolRenderAvoid = nil
	end

	-----------------------------------------------------------------
	-- Wiring helper functions
	-----------------------------------------------------------------

	--[[ Wirings table format:
		self.Wiring[x] = wiring

		where

		wiring = {
			[1] = inputname,
			[2] = inputpos,
			[3] = inputentity,
			[4] = nodes,
			[5] = outputentity,
			[6] = outputpos,
			[7] = outputname,
			[8] = inputtype,
		}

		where

		nodes = {
			[1] = entity,
			[2] = pos,
		}
	]]


	function TOOL:FindWiring( entity, inputname, inputtype )
		for i=1,#self.Wiring do
			local wiring = self.Wiring[i]
			if wiring[1] == inputname  and wiring[3] == entity and wiring[8] == inputtype then return wiring, i end
		end
	end

	function TOOL:WireStart( entity, pos, inputname, inputtype )
		local wiring, id = self:FindWiring( entity, inputname, inputtype )
		if wiring then -- wiring is already started, user wants to cancel it
			table.remove( self.Wiring, id )
			self:WiringRenderRemove( inputname, inputtype )
			return
		end

		local t = { inputname, entity:WorldToLocal( pos ), entity, {} }
		t[8] = inputtype
		self.Wiring[#self.Wiring+1] = t

		if inputtype == "WIRELINK" then
			self.ShowWirelink = true
		elseif inputtype == "ENTITY" then
			self.ShowEntity = true
		end

		-- Add info to the wiringrender table, which is used to render the "x2" "x3" etc
		self:WiringRenderAdd( inputname, inputtype )

		return t
	end
	function TOOL:WireNode( wiring, entity, pos )
		wiring[4][#wiring[4]+1] = { entity, entity:WorldToLocal( pos ) }
	end
	function TOOL:WireEndEntityPos( wiring, entity, pos )
		wiring[5] = entity
		wiring[6] = entity:WorldToLocal( pos )
	end
	function TOOL:WireEndOutputName( wiring, outputname )
		wiring[7] = outputname
		wiring[8] = nil -- we don't need to send the type to the server; wasted net message space. Delete it
		self.NeedsUpload = true -- We want to upload next tick. We don't upload immediately because the client may call this function more this tick (for multi wiring)
	end


	-- This function will help when using ALT to wire, when a single output's type matches but the name does not
	-- it will allow us to check if only a single output of matching types exist on the entity without looping
	-- through the entity's outputs several times per frame
	TOOL.AutoWiringTypeLookup_t = {}
	function TOOL:AutoWiringTypeLookup( ent )
		if not IsValid( ent ) then
			self.AutoWiringTypeLookup_t = {}
		else
			self.AutoWiringTypeLookup_t = {}
			local _, outputs = self:GetPorts( ent )
			for i=1,#outputs do
				local outputtype = outputs[i][2]
				if self.AutoWiringTypeLookup_t[outputtype] == nil then -- if we haven't found any outputs of this type yet,
					self.AutoWiringTypeLookup_t[outputtype] = i -- set the index
				elseif self.AutoWiringTypeLookup_t[outputtype] ~= nil then -- if we've already found outputs of this type,
					self.AutoWiringTypeLookup_t[outputtype] = false -- set to false
				end
			end
		end
	end
	function TOOL:AutoWiringTypeLookup_Check( inputtype )
		return self.AutoWiringTypeLookup_t[inputtype]
	end

	-- Updates the trace hit position and normal to the surface of the parent, perpendicular to the originally hit entity.
	-- As not all models have the same forward, up, etc. it checks all directions perpendicular to the hit entity, until it finds the parent.
	-- If the parent is not found in any perpendicular direction, it traces the parent in the direction of the tool gun.
	function TOOL:UpdateTraceForSurface(trace, parent)
		if self:GetClientNumber("stick") == 0 then return end
		if not WireLib.HasPorts(trace.Entity) then return end

		local hitParentPos
		local hitParentNormal
		local foundParent
		local closestDistanceSquared

		local entityUp = trace.Entity:GetUp() * 1000
		local entityForward = trace.Entity:GetForward() * 1000
		local entityRight = trace.Entity:GetRight() * 1000
		local traceVectors =
		{
			entityUp,
			entityForward,
			entityRight,
			-entityUp,
			-entityForward,
			-entityRight
		}

		-- Looks for the parent on all local axes, and returns the closest hit surface on the parent.
		local function findParent()
			foundParent = false
			closestDistanceSquared = math.huge

			for i = 1, 6 do
				local traceVector = traceVectors[i]

				local traceData = util.GetPlayerTrace(LocalPlayer())
				traceData.start = trace.HitPos -- Start from the original trace.

				traceData.endpos = trace.HitPos + traceVector
				traceData.filter = { LocalPlayer(), trace.Entity }
				traceData.collisiongroup = LAST_SHARED_COLLISION_GROUP
				local newTrace = util.TraceLine(traceData)

				if newTrace.Hit and newTrace.Entity == parent then
					local distanceSquared = newTrace.HitPos:DistToSqr(trace.HitPos)
					if distanceSquared <= 75 * 75 and distanceSquared < closestDistanceSquared then
						closestDistanceSquared = distanceSquared
						hitParentPos = newTrace.HitPos
						hitParentNormal = newTrace.HitNormal
						foundParent = true
					end
				end
			end
		end

		if IsValid(parent) then
			findParent()
		end

		if not foundParent then
			-- Didn't find the parent in any direction, treat whichever entity can be traced behind the entity as the parent.
			-- This can happen if eg. the component is not directly on the parent (or if the entity just never had an actual parent).
			local traceData = util.GetPlayerTrace(LocalPlayer())
			traceData.filter = { LocalPlayer(), trace.Entity }
			traceData.collisiongroup = LAST_SHARED_COLLISION_GROUP
			newTrace = util.TraceLine(traceData)
			parent = newTrace.Entity
			if not IsValid(parent) or parent == game.GetWorld() then
				-- Hit the world, don't update the trace.
				return
			end

			findParent() -- Try again with the new assumed parent.
		end

		if foundParent then
			trace.HitPos = hitParentPos
			trace.HitNormal = hitParentNormal
		end
	end

	-----------------------------------------------------------------
	-- Mouse buttons
	-----------------------------------------------------------------

	function TOOL:LeftClick(trace)
		if not game.SinglePlayer() and not IsFirstTimePredicted() then return end

		local shift = self:GetOwner():KeyDown(IN_SPEED)
		local alt = self:GetOwner():KeyDown(IN_WALK)

		if IsValid( trace.Entity ) then
			if self:GetStage() == 0 then
				self:UpdateTraceForSurface(trace, trace.Entity:GetParent())
				self:BeginRenderingCurrentWire()

				local inputs, _ = self:GetPorts( trace.Entity )
				if not isTableEmpty(inputs) then return end

				if alt then -- Select everything
					for i=1,#inputs do
						self:WireStart( trace.Entity, trace.HitPos, inputs[i][1], inputs[i][2] )
					end
				else
					-- Single input selection
					if not inputs[self.CurrentWireIndex] then return end -- Can happen if theres no inputs, only outputs
					self:WireStart( trace.Entity, trace.HitPos, inputs[self.CurrentWireIndex][1], inputs[self.CurrentWireIndex][2] )
				end

				self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )

				if not shift then
					self:SetStage(1) -- Set this immediately so the HUD doesn't glitch
				end

				return
			elseif self:GetStage() == 1 then
				self:UpdateTraceForSurface(trace, trace.Entity:GetParent())
				local _, outputs = self:GetPorts( trace.Entity )
				if not isTableEmpty(outputs) then return end

				self.CurrentEntity = trace.Entity
				self:AutoWiringTypeLookup( self.CurrentEntity )

				self:SetStage(2)

				for i=1,#self.Wiring do
					self:WireEndEntityPos( self.Wiring[i], self.CurrentEntity, trace.HitPos )
				end

				if next(outputs,next(outputs)) == nil then -- there's only one element in the table
					self:LeftClick( trace ) -- wire it right away
					return
				end

				self:LoadMemorizedIndex( self.CurrentEntity, true )

				-- find first matching output by name or type
				local oldport = self.CurrentWireIndex
				local port = self.CurrentWireIndex
				local matchingByType
				local matchingByName
				repeat
					if outputs[port][1] == self.Wiring[1][1] and outputs[port][2] == self.Wiring[1][8] and not matchingByName then
						matchingByName = port
					end
					if outputs[port][2] == self.Wiring[1][8] and not matchingByType then
						matchingByType = port
					end

					port = port + 1
					if port > #outputs then
						port = 1
					end
				until port == oldport or (matchingByName and matchingByType)

				if matchingByName then
					self.CurrentWireIndex = matchingByName
				elseif matchingByType then
					self.CurrentWireIndex = matchingByType
				end

				self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )
				return
			end
		end

		if self:GetStage() == 2 then
			if not IsValid( self.CurrentEntity ) then
				self:SetStage(0)
				return
			end

			local _, outputs = self:GetPorts( self.CurrentEntity )

			if alt then -- Auto wiring
				local notwired = 0
				local typematched = 0
				for i=1,#self.Wiring do
					local wiring = self.Wiring[i]
					local inputname = wiring[1]
					local inputtype = wiring[8]
					local found = false
					for j=1,#outputs do
						local outputname = outputs[j][1]
						local outputtype = outputs[j][2]

						if self:IsMatch( inputname, inputtype, outputname, outputtype, true ) then
							self:WireEndOutputName( wiring, outputname )
							found = true
							break
						end
					end

					if not found then -- if we didn't find a matching name & type, check if there's only one matching type (ignoring name)
						local idx = self:AutoWiringTypeLookup_Check( inputtype )
						if idx then
							self:WireEndOutputName( wiring, outputs[idx][1] )
							typematched = typematched + 1
						else
							notwired = notwired + 1
						end
					end
				end

				if notwired > 0 then
					WireLib.AddNotify( "Could not find a matching name/type for " .. notwired .. " inputs. They were not wired.", NOTIFY_HINT, 10, NOTIFYSOUND_DRIP1 )
				end
				if typematched > 0 then
					WireLib.AddNotify( "Could not find a matching name/type for " .. typematched .. " inputs. However, a single output of that type was found, which was used instead.", NOTIFY_HINT, 10, NOTIFYSOUND_DRIP1 )
				end
			else -- Normal wiring
				local notwired = 0
				for i=1,#self.Wiring do
					if outputs[self.CurrentWireIndex][2] == self.Wiring[i][8] then
						self:WireEndOutputName( self.Wiring[i], outputs[self.CurrentWireIndex][1] )
					else
						notwired = notwired + 1
					end
				end

				if notwired > 0 then
					WireLib.AddNotify( "The type did not match for " .. notwired .. " inputs. They were not wired.", NOTIFY_HINT, 5, NOTIFYSOUND_DRIP1 )
				end
			end

			self:SetStage(0)
			self.WiringRender = {} -- Empty this now so the HUD doesn't glitch
			self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )
			self:StopRenderingCurrentWire()
		end
	end

	function TOOL:RightClick(trace)
		if not game.SinglePlayer() and not IsFirstTimePredicted() then return end

		self:UpdateTraceForSurface(trace, trace.Entity:GetParent())
		if self:GetStage() == 0 or self:GetStage() == 2 then
			self:ScrollDown(trace)
		elseif IsValid(trace.Entity) and self:GetStage() == 1 then
			for i=1,#self.Wiring do
				self:WireNode( self.Wiring[i], trace.Entity, trace.HitPos + trace.HitNormal*(self:GetClientNumber("width")/2) )
			end
			self:GetOwner():EmitSound("buttons/lightswitch2.wav")
		end
	end

	function TOOL:Reload(trace)
		if not game.SinglePlayer() and not IsFirstTimePredicted() then return end

		local ent = trace.Entity

		if self:GetStage() == 0 and ent:IsValid() and WireLib.HasPorts(ent) then
			if self:GetOwner():KeyDown(IN_SPEED) then
				net.Start("wire_adv_upload")
					net.WriteUInt(3, 8)
					net.WriteEntity(ent)
				net.SendToServer()
			else
				local inputs = self:GetPorts(ent)
				if not isTableEmpty(inputs) then return end
				if self:GetOwner():KeyDown( IN_WALK ) then
					local t = {}
					for i=1,#inputs do
						t[i] = inputs[i][1]
					end
					self:Unwire(ent, t)
				else
					self:Unwire(ent, { inputs[self.CurrentWireIndex][1] })
				end
			end
		else
			self:Holster()
		end

		self:StopRenderingCurrentWire()
		self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )
	end

	function TOOL:Scroll(trace,dir)
		local ent = self:GetStage() == 0 and trace.Entity or self.CurrentEntity
		if IsValid(ent) then
			local inputs, outputs = self:GetPorts( ent )
			if not isTableEmpty(inputs) and not isTableEmpty(outputs) then return end
			local check = self:GetStage() == 0 and inputs or outputs
			if #check == 0 then return end

			local oldport = self.CurrentWireIndex

			if self:GetStage() == 2 then
				repeat
					self.CurrentWireIndex = self.CurrentWireIndex + dir
					if self.CurrentWireIndex > #check then
						self.CurrentWireIndex = 1
					elseif self.CurrentWireIndex < 1 then
						self.CurrentWireIndex = #check
					end
				until not self:IsBlocked( "Outputs", outputs, ent, self.CurrentWireIndex ) or self.CurrentWireIndex == oldport
			else
				self.CurrentWireIndex = self.CurrentWireIndex + dir

				if self.CurrentWireIndex > #check then
					self.CurrentWireIndex = 1
				elseif self.CurrentWireIndex < 1 then
					self.CurrentWireIndex = #check
				end
			end

			if oldport ~= self.CurrentWireIndex then
				ent:SetNWString("BlinkWire", check[self.CurrentWireIndex][1])
				self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")
			end
			return true
		end
	end

	function TOOL:ScrollUp(trace) return self:Scroll(trace,-1) end
	function TOOL:ScrollDown(trace) return self:Scroll(trace,1) end

	local function hookfunc( ply, bind, pressed )
		if not pressed then return end

		if bind == "invnext" then
			local self = WireToolHelpers.GetActiveTOOL("wire_adv",ply)
			if not self then return end
			return self:ScrollDown(ply:GetEyeTraceNoCursor())
		elseif bind == "invprev" then
			local self = WireToolHelpers.GetActiveTOOL("wire_adv",ply)
			if not self then return end
			return self:ScrollUp(ply:GetEyeTraceNoCursor())
		elseif bind == "impulse 100" then
			if ply:KeyDown( IN_SPEED ) then
				local self = WireToolHelpers.GetActiveTOOL("wire_adv",ply)
				if not self then
					self = WireToolHelpers.GetActiveTOOL("wire_debugger",ply)
					if not self then return end

					spawnmenu.ActivateTool( "wire_adv") -- switch back to wire adv
					return true
				end

				spawnmenu.ActivateTool("wire_debugger") -- switch to debugger
				return true
			else
				local self = WireToolHelpers.GetActiveTOOL("wire_adv",ply)
				if self and self:GetStage() == 1 then
					local len = #self.Wiring
					if len > 0 then
						local nodesCount = 0
						for i=1,len do
							nodesCount = nodesCount + #self.Wiring[i][4]
							if #self.Wiring[i][4] > 0 then
								table.remove(self.Wiring[i][4])
							end
						end

						if nodesCount > 0 then
							self:GetOwner():EmitSound( "buttons/button16.wav" )
						end
					end
					return true
				end
			end
		end
	end

	if game.SinglePlayer() then -- wtfgarry (have to have a delay in single player or the hook won't get added)
		timer.Simple(5,function() hook.Add( "PlayerBindPress", "wire_adv_playerbindpress", hookfunc ) end)
	else
		hook.Add( "PlayerBindPress", "wire_adv_playerbindpress", hookfunc )
	end

	-----------------------------------------------------------------
	-- Remember wire indexes
	-----------------------------------------------------------------

	-- Remember wire index positions for entities
	TOOL.WireIndexMemory = {}
	TOOL.AimingEnt = nil
	TOOL.AimingStage = 0
	function TOOL:LoadMemorizedIndex( ent, forceload )
		if ent ~= self.AimingEnt or self:GetStage() ~= self.AimingStage or forceload then
			if self:GetStage() == 2 and self.CurrentEntity ~= ent then -- if you aim away during stage 2, don't change CurrentWireIndex
				return
			end

			-- Memorize selected input
			if IsValid(self.AimingEnt) and not forceload then
				if not self.WireIndexMemory[self.AimingEnt] then
					self.WireIndexMemory[self.AimingEnt] = {}
				end
				if not self.WireIndexMemory[self.AimingEnt:GetClass()] then
					self.WireIndexMemory[self.AimingEnt:GetClass()] = {} -- save to class as well
				end
				self.WireIndexMemory[self.AimingEnt][self.AimingStage] = self.CurrentWireIndex
				self.WireIndexMemory[self.AimingEnt:GetClass()][self.AimingStage] = self.CurrentWireIndex -- save to class as well
			end

			-- Clear blinking wire
			if IsValid( self.AimingEnt ) then
				self.AimingEnt:SetNWString("BlinkWire", "")
			end

			if IsValid( ent ) then
				-- Retrieve memorized selected input
				if self.WireIndexMemory[ent] and self.WireIndexMemory[ent][self:GetStage()] then
					self.CurrentWireIndex = self.WireIndexMemory[ent][self:GetStage()]
				elseif self.WireIndexMemory[ent:GetClass()] and self.WireIndexMemory[ent:GetClass()][self:GetStage()] then -- if this entity doesn't have a stored position, get it from the class instead
					self.CurrentWireIndex = self.WireIndexMemory[ent:GetClass()][self:GetStage()]
				else
					self.CurrentWireIndex = 1
				end

				-- Clamp index
				local inputs, outputs = self:GetPorts( ent )
				local check = self:GetStage() == 0 and inputs or outputs
				if check then
					self.CurrentWireIndex = math.Clamp(	self.CurrentWireIndex, 1, #check )

					-- Set blinking wire
					if check[self.CurrentWireIndex] then
						ent:SetNWString("BlinkWire", check[self.CurrentWireIndex][1])
					end
				end
			end

			self.AimingEnt = ent
			self.AimingStage = self:GetStage()
		end
	end

	-----------------------------------------------------------------
	-- Think
	-----------------------------------------------------------------
	function TOOL:Think()
		local ent = self:GetOwner():GetEyeTrace().Entity
		self:LoadMemorizedIndex( ent )

		-- Check for holding shift etc
		local shift = self:GetOwner():KeyDown( IN_SPEED )

		if #self.Wiring > 0 and self:GetStage() == 0 and not shift then
			self:SetStage(1)
		elseif #self.Wiring > 0 and self:GetStage() == 1 and shift then
			self:SetStage(0)
		end

		-- Check if we need to upload
		if self.NeedsUpload then
			self.NeedsUpload = false
			self:Upload()
		end
	end

	-----------------------------------------------------------------
	-- HUD Stuff
	-----------------------------------------------------------------
	function TOOL:IsHighlighted( name, tbl, ent, idx )
		local alt = self:GetOwner():KeyDown( IN_WALK )
		if name == "Outputs" and self:GetStage() == 2 then
			if alt then -- if we're holding alt, highlight all outputs that will be wired to
				local outputname = tbl[idx][1]
				local outputtype = tbl[idx][2]

				for i=1,#self.WiringRender do
					local inputname = self.WiringRender[i][1]
					local inputtype = self.WiringRender[i][2]

					if self:IsMatch( inputname, inputtype, outputname, outputtype, true ) then
						return true
					end

					local _idx = self:AutoWiringTypeLookup_Check( inputtype )
					if _idx then
						local _outputtype = tbl[_idx][2]
						if outputtype == _outputtype then
							return true
						end
					end
				end
			else
				return self.CurrentWireIndex == idx -- Highlight selected output
			end
		elseif name == "Selected" and self:GetStage() == 2 and alt then -- highlight all selected inputs that will be wired
			local _, outputs = self:GetPorts( ent )

			local inputname = tbl[idx][1]
			local inputtype = tbl[idx][2]

			for i=1,#outputs do
				local outputname = outputs[i][1]
				local outputtype = outputs[i][2]
				if self:IsMatch( inputname, inputtype, outputname, outputtype, true ) then
					return true
				end
			end

			local _idx = self:AutoWiringTypeLookup_Check( inputtype )
			if _idx then
				return true
			end
		elseif name == "Inputs" and self:GetStage() == 0 then
			local wiring, _ = self:FindWiring( ent, tbl[idx][1], tbl[idx][2] )
			if wiring then return true, true end -- Highlight with a different color
			return self.CurrentWireIndex == idx or alt
		end
		return false
	end

	function TOOL:IsBlocked( name, tbl, ent, idx )
		if name == "Outputs" and self:GetStage() > 0 then -- Gray out the ones that we can't wire any of the selected inputs to
			for i=1,#self.WiringRender do
				local inputtype = self.WiringRender[i][2]
				if tbl[idx][2] == inputtype then
					return false
				end
			end
			return true
		elseif name == "Selected" and self:GetStage() == 2 then
			local _, outputs = self:GetPorts( ent )
			if not isTableEmpty(outputs) then return false end
			if self:GetOwner():KeyDown( IN_WALK ) then -- Gray out the ones that won't be able to be wired to any input
				for i=1,#outputs do
					if tbl[idx][2] == outputs[i][2] then return false end
				end
				return true
			else -- Gray out the ones that won't be able to be wired to the selected output
				return tbl[idx][2] ~= outputs[self.CurrentWireIndex][2]
			end
		end
		return false
	end

	local function getName( input )
		local name = input[1]
		local tp = input[8] or (type(input[2]) == "string" and input[2] or "")
		local desc = (IsEntity(input[3]) and "" or input[3]) or ""
		return name .. (tp ~= "NORMAL" and " [" .. tp.. "]" or ""), desc
	end

	local function getWidthHeight( inputs )
		local width, height = 0, 0
		for i=1,#inputs do
			local input = inputs[i]
			local name = getName( input )
			local w,h = surface.GetTextSize( name )
			if w > width then
				if input[9] and input[9] > 1 then w = w + 14 end
				width = w
			end
			height = height + h
		end
		return width, height
	end

	local fontData = {font = "Trebuchet MS"} -- 24 and 18 are stock
	for _,size in pairs({22,20,16,14}) do
		fontData.size = size
		surface.CreateFont("Trebuchet"..size, fontData)
	end

	local fontheights

	local function getFontSizes()
		fontheights = {}
		for i=14,24,2 do
			local fontname = "Trebuchet" .. i
			local h = draw.GetFontHeight( fontname )
			fontheights[fontname] = h
		end
	end

	TOOL.CurrentFont = "Trebuchet24"
	-- Find the largest font that can fit `lines` lines of text into a box `maxsize`
	-- tall. Set that font as current, and return the size of one line of text.
	-- If no fonts would fit, then the smallest font possible will be returned.
	function TOOL:fitFont( lines, maxsize )
		if not fontheights then
			getFontSizes()
		end

		local minFontSize = 14

		for i=24, minFontSize, -2 do
			local fontname = "Trebuchet" .. i
			local height = fontheights[fontname]
			if height * lines <= maxsize or i == minFontSize then
				self.CurrentFont = fontname
				surface.SetFont( fontname )
				local w, _ = surface.GetTextSize( "Selected:" )
				return w, height
			end
		end
	end

	function TOOL:DrawList( name, tbl, ent, x, y, w, h, fonth )
		draw.RoundedBox( 6, x, y, w+16, h+14, Color(50,50,75,192) )

		x = x + 8
		y = y + 2

		local temp,_ = surface.GetTextSize( name .. ":" )
		surface.SetTextColor( 255, 255, 255 )
		surface.SetTextPos( x-temp/2+w/2, y )
		surface.DrawText( name .. ":" )
		surface.SetDrawColor( 255, 255, 255 )
		surface.DrawLine( x, y + fonth+2, x+w, y + fonth+2 )

		y = y + 6

		-- Draw inputs
		for i=1,#tbl do
			y = y + fonth

			local highlighted, diffcolor = self:IsHighlighted( name, tbl, ent, i )
			if highlighted then
				local clr = Color(0,150,0,192)
				if diffcolor and (self.CurrentWireIndex == i or self:GetOwner():KeyDown( IN_WALK )) then clr = Color(100,100,175,192)
				elseif diffcolor then clr = Color(0,0,150,192) end
				draw.RoundedBox( 4, x-4, y, w+8,fonth+2, clr )
			end

			if tbl[i][4] == true then
				surface.SetTextColor(255, 0, 0, 255)
			elseif self:IsBlocked( name, tbl, ent, i ) then
				surface.SetTextColor(255, 255, 255, 32)
			else
				surface.SetTextColor(255, 255, 255)
			end

			if tbl[i][9] and tbl[i][9] > 1 then
				surface.SetFont( "Trebuchet14" )
				local tempw, temph = surface.GetTextSize( "x" .. tbl[i][9] )
				surface.SetTextPos( x+w-tempw+2, y+fonth/2-temph/2 )
				surface.DrawText( "x" .. tbl[i][9] )
				surface.SetFont( self.CurrentFont )
			end

			local name, desc = getName( tbl[i] )
			surface.SetTextPos( x, y )
			surface.DrawText( name )

			-- special case for constant value to force render all descriptions at all times
			-- and doesn't draw \n on separate lines,
			-- and also doesn't automatically wrap too long lines
			local isconstvalue = ent:GetClass() == "gmod_wire_value"

			-- draw description
			if desc ~= "" and (self:GetStage() == 0 or self:GetStage() == 2 or isconstvalue) then
				if self.CurrentWireIndex == i and not self:GetOwner():KeyDown( IN_WALK ) or isconstvalue then
					local descx = x + w + 16
					local descy = y

					local function getTextSize(lines)
						local w = 0
						local h = 0
						for i=1,#lines do
							lines[i] = string.Trim(lines[i])
							local ww, hh = surface.GetTextSize( lines[i] )
							w = math.max(w,ww)
							h = h + hh + 2
						end

						return w, h
					end

					local lines = isconstvalue and {desc} or string.Explode("\n", desc)
					local descw, desch = getTextSize(lines)

					local inf = 0
					while not isconstvalue and descx + descw + 16 > ScrW() and inf < 10 do
						inf = inf + 1
						-- if it would've gone beyond the edge of the screen
						-- break up the lines in the middle and hope for the best
						-- while this code is a bit inefficient, most of the time it won't need to be used
						local new = {}
						local idx = 1
						for i=1,#lines do
							local line = lines[i]
							new[idx] = string.sub(line,1,#line/2)
							new[idx+1] = string.sub(line,#line/2+1,#line)
							idx = idx + 2
						end
						lines = new

						descw, desch = getTextSize(lines)
					end

					descy = descy - (desch-fonth) / 2
					draw.RoundedBox( 4, descx, descy+1, descw+12, desch-2, Color(50,50,75,192) )

					for i=1,#lines do
						surface.SetTextPos( descx+6, descy )
						surface.DrawText( lines[i] )
						descy = descy + fonth + 2
					end
				end
			end
		end
	end

	function TOOL:DrawHUD()
		local centerx, centery = ScrW()/2, ScrH()/2

		local minx, miny, maxx, maxy = centerx, centery, centerx, centery

		local ent = self:GetStage() == 2 and self.CurrentEntity or self:GetOwner():GetEyeTrace().Entity
		local maxwidth = 0
		if IsValid( ent ) then
			local inputs, outputs = self:GetPorts( ent )
			if inputs and #inputs > 0 and self:GetStage() == 0 then
				local w, h = self:fitFont( #inputs, ScrH() - 32 )
				local ww, hh = getWidthHeight( inputs )
				ww = math.max(ww,w)
				hh = math.max(hh,h) + h
				maxwidth = ww + 22
				local x = centerx-ww-38
				local y = centery-hh/2-16
				self:DrawList( "Inputs", inputs, ent, x, y, ww, hh, h )

				minx = math.min(minx,x)
				miny = math.min(miny,y)
				maxx = math.max(maxx,x+ww)
				maxy = math.max(maxy,y+hh+h)
			end

			if outputs and #outputs > 0 and self:GetStage() > 0 then
				local w, h = self:fitFont( #outputs, ScrH() - 32 )
				local ww, hh = getWidthHeight( outputs )
				ww = math.max(ww,w)
				hh = math.max(hh,h) + h
				local x = centerx+22
				local y = centery-hh/2-16
				self:DrawList( "Outputs", outputs, ent, x, y, ww, hh, h )

				minx = math.min(minx,x)
				miny = math.min(miny,y)
				maxx = math.max(maxx,x+ww)
				maxy = math.max(maxy,y+hh+h)
			end

			if #self.WiringRender > 0 then
				local w, h = self:fitFont( #self.WiringRender, ScrH() - 32 )
				local ww, hh = getWidthHeight( self.WiringRender )
				local ww = math.max(ww,w)
				local hh = math.max(hh,h) + h
				local x = centerx-maxwidth-ww-38
				local y = centery-hh/2-16
				self:DrawList( "Selected", self.WiringRender, ent, x, y, ww, hh, h )

				minx = math.min(minx,x)
				miny = math.min(miny,y)
				maxx = math.max(maxx,x+ww)
				maxy = math.max(maxy,y+hh+h)
			end
		end

		if minx < centerx - 1 then
			WireLib.WiringToolRenderAvoid = {minx,miny, maxx,maxy}
		else
			WireLib.WiringToolRenderAvoid = nil
		end
	end

	function TOOL:StopRenderingCurrentWire()
		hook.Remove("PostDrawOpaqueRenderables", "Wire.ToolWireRenderHook")
		self.IsRenderingCurrentWire = false;
		WireLib.Wire_GrayOutWires = false
	end

	function TOOL:BeginRenderingCurrentWire()
		if self.IsRenderingCurrentWire then return end
		self.IsRenderingCurrentWire = true
		WireLib.Wire_GrayOutWires = true
		hook.Add("PostDrawOpaqueRenderables", "Wire.ToolWireRenderHook", function()
			-- Draw the wire path
			render.SetColorMaterial()
			for i=1, #self.Wiring do
				local wiring = self.Wiring[i]
				local nodes = wiring[4]
				local outputEntity = wiring[5]

				local color = Color(self:GetClientNumber("r"), self:GetClientNumber("g"), self:GetClientNumber("b"))
				local matName = self:GetClientInfo("material")
				local width = self:GetClientInfo("width")
				local mat = Material(matName)
				local theEnt = wiring[3]
				if not theEnt:IsValid() then
					self:StopRenderingCurrentWire()
					break
				end
				-- Prune invalid nodes
				for j=#nodes, 1, -1 do
					if not nodes[j][1]:IsValid() then
						table.remove(nodes, j)
					end
				end

				local start = theEnt:LocalToWorld(wiring[2])

				local scroll = 0.5
				render.SetMaterial(mat)
				render.StartBeam((#nodes*2)+1+1+1) -- + startpoint + same as last node (to not have transition to aiming point) +point where player is aiming
				render.AddBeam(start, width, scroll, color)

				for j=1, #nodes do
					local node = nodes[j]

					local nodeEnt = node[1]
					local nodeOffset = node[2]
					local nodePosition = nodeEnt:LocalToWorld(nodeOffset)

					scroll = scroll+(nodePosition-start):Length()/10
					render.AddBeam(nodePosition, width, scroll, color)
					render.AddBeam(nodePosition, width, scroll, color)

					start = nodePosition
				end

				render.AddBeam(start, width, scroll, Color(255,255,255,255))

				if not IsValid(outputEntity) then
					local traceData = util.GetPlayerTrace(LocalPlayer())
					traceData.filter = { LocalPlayer() }

					traceData.collisiongroup = LAST_SHARED_COLLISION_GROUP
					local traceResult = util.TraceLine(traceData)
					if IsValid(traceResult.Entity) and WireLib.HasPorts(traceResult.Entity) then
						self:UpdateTraceForSurface(traceResult, traceResult.Entity:GetParent())
					end
					render.AddBeam(traceResult.HitPos, width, scroll+(traceResult.HitPos-start):Length()/10, Color(100,100,100,255))
				else
					local outputPos = wiring[6]
					outputPos = outputEntity:LocalToWorld(outputPos)
					render.AddBeam(outputPos, width, scroll+(outputPos-start):Length()/10, Color(100,100,100,255))
				end
				render.EndBeam()
			end
		end)
	end


	-----------------------------------------------------------------
	-- Wiring Render
	-- This table is almost the same as TOOL.Wiring,
	-- but is organized differently and is used to
	-- render the "Selected" box on screen properly.
	-----------------------------------------------------------------
	function TOOL:IsMatch( inputname, inputtype, outputname, outputtype, checkcreated )
		if checkcreated then
			return (outputname == inputname and outputtype == inputtype) or (inputtype == "WIRELINK" and (outputname == "wirelink" or outputname == "Create Wirelink") and outputtype == "WIRELINK") or
																			(inputtype == "ENTITY" and (outputname == "entity" or outputname == "Create Entity") and outputtype == "ENTITY")
		else
			return outputname == inputname and outputtype == inputtype
		end
	end

	function TOOL:WiringRenderFind( inputname, inputtype )
		for i=1,#self.WiringRender do
			local wiringrender = self.WiringRender[i]
			if self:IsMatch( wiringrender[1], wiringrender[2], inputname, inputtype ) then
				return wiringrender, i
			end
		end
	end

	function TOOL:WiringRenderRemove( inputname, inputtype )
		local wiringrender, idx = self:WiringRenderFind( inputname, inputtype )

		if wiringrender then
			wiringrender[9] = wiringrender[9] - 1
			if wiringrender[9] == 0 then
				table.remove( self.WiringRender, idx )
			end
		end
	end

	function TOOL:WiringRenderAdd( inputname, inputtype )
		local wiringrender = self:WiringRenderFind( inputname, inputtype )

		if wiringrender then
			wiringrender[9] = wiringrender[9] + 1
		else
			local wiringrender = { inputname, inputtype }
			--wiringrender[8] = inputtype
			wiringrender[9] = 1
			self.WiringRender[#self.WiringRender+1] = wiringrender
		end
	end

	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire_adv.name", Description = "#Tool.wire_adv.desc2" })
		WireToolHelpers.MakePresetControl(panel, "wire_adv")

		panel:NumSlider("#WireTool_width", "wire_adv_width", 0, 5, 2)
		local matselect = panel:AddControl( "RopeMaterial", { Label = "#WireTool_material", convar = "wire_adv_material" } )
		matselect:AddMaterial("Arrowire", "arrowire/arrowire")
		matselect:AddMaterial("Arrowire2", "arrowire/arrowire2")

		panel:AddControl("Color", {
			Label = "#WireTool_colour",
			Red = "wire_adv_r",
			Green = "wire_adv_g",
			Blue = "wire_adv_b"
		})

		panel:CheckBox("#WireTool_stick", "wire_adv_stick")
	end

end
