TOOL.Category = "Wire - Tools"
TOOL.Name			= "Wire Advanced 2"
TOOL.Tab      = "Wire"

if CLIENT then
	language.Add( "Tool.wire_adv_2.name", "Advanced Wiring Tool" )
	language.Add( "Tool.wire_adv_2.desc", "Used to connect things with wires." )
	language.Add( "Tool.wire_adv_2.0", "Primary: Attach to selected input (Hold shift to select multiple inputs; Hold alt to select all inputs in the current entity), Secondary: Next input, Reload: Unlink selected input (Hold alt to unlink all in the current entity), Wheel: Scroll up or down." )
	language.Add( "Tool.wire_adv_2.1", "Primary: Select entity, Secondary: Attach wire to point and continue, Reload: Cancel." )
	language.Add( "Tool.wire_adv_2.2", "Primary: Confirm attach to output (Hold alt to auto-wire, matching all input/outputs names with equal names), Secondary: Next output, Reload: Cancel, Wheel: Scroll up or down." )
end

TOOL.ClientConVar = {
	width = 2,
	material = "cable/cable2",
	r = 255,
	g = 255,
	b = 255,
}

util.PrecacheSound("weapons/pistol/pistol_empty.wav")

--[[ TODO

	-- maybe make the selected inputs display nicer (if you've selected many with the same name from the same entity, display as 3xInputName or something)
	-- toolscreen
	
	DONE
	-- find out why wires are invisible
	-- blinking wires
	-- create wirelink
	-- create entity

]]


-----------------------------------------------------------------
-- Helper functions
-----------------------------------------------------------------

local function get_tool(ply, tool)
	-- find toolgun
	local gmod_tool = ply:GetWeapon("gmod_tool")
	if not IsValid(gmod_tool) then return end

	return gmod_tool:GetToolObject(tool)
end

local function get_active_tool(ply, tool)
	-- find toolgun
	local activeWep = ply:GetActiveWeapon()
	if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

	return activeWep:GetToolObject(tool)
end


if SERVER then
	function TOOL:RightClick(trace)
	end

	function TOOL:Reload(trace)

	end

	function TOOL:Holster()
	end
	
	
	-----------------------------------------------------------------
	-- Duplicator modifiers
	-----------------------------------------------------------------
	
	local function CreateWirelinkOutput( ply, ent, data )
		if data[1] == true then
			if ent.Outputs then
				local names = {}
				local types = {}
				local descs = {}
				local x = 0
				for k,v in pairs( ent.Outputs ) do
					x = x + 1
					local num = v.Num
					names[num] = v.Name
					types[num] = v.Type
					descs[num] = v.Desc
				end
				
				names[x+1] = "wirelink"
				types[x+1] = "WIRELINK"
				descs[x+1] = ""
			
				WireLib.AdjustSpecialOutputs( ent, names, types, descs )
			else
				WireLib.CreateSpecialOutputs( ent, { "wirelink" }, { "WIRELINK" } )
			end
			
			WireLib.TriggerOutput( ent, "wirelink", ent )
		end
		duplicator.StoreEntityModifier( ent, "CreateWirelinkOutput", data )
	end
	duplicator.RegisterEntityModifier( "CreateWirelinkOutput", CreateWirelinkOutput )
	
	local function CreateEntityOutput( ply, ent, data )
		if data[1] == true then
			if ent.Outputs then
				local names = {}
				local types = {}
				local descs = {}
				local x = 0
				for k,v in pairs( ent.Outputs ) do
					x = x + 1
					local num = v.Num
					names[num] = v.Name
					types[num] = v.Type
					descs[num] = v.Desc
				end
				
				names[x+1] = "entity"
				types[x+1] = "ENTITY"
				descs[x+1] = ""
			
				WireLib.AdjustSpecialOutputs( ent, names, types, descs )
			else
				WireLib.CreateSpecialOutputs( ent, { "entity" }, { "ENTITY" } )
			end
			
			WireLib.TriggerOutput( ent, "entity", ent )
		end
		duplicator.StoreEntityModifier( ent, "CreateEntityOutput", data )
	end
	duplicator.RegisterEntityModifier( "CreateEntityOutput", CreateEntityOutput )
	
	
	-----------------------------------------------------------------
	-- Receving data from client
	-----------------------------------------------------------------
		
	util.AddNetworkString( "wire_adv_upload" )
	net.Receive( "wire_adv_upload", function( len, ply )
		local wirings = net.ReadTable()
		
		local tool = get_active_tool(ply,"wire_adv_2")
		if not tool then return end
		
		local material = tool:GetClientInfo("material")
		local width    = tool:GetClientNumber("width")
		local color    = Color(tool:GetClientNumber("r"), tool:GetClientNumber("g"), tool:GetClientNumber("b"))
		
		local uid = ply:UniqueID()
		
		for i=1,#wirings do
			local wiring = wirings[i]
			
			local inputentity = wiring[3]
			local outputentity = wiring[5]
			
			if 	IsValid( inputentity ) and IsValid( outputentity ) and
				hook.Run( "CanTool", ply, WireLib.dummytrace( inputentity ), "wire_adv_2" ) and
				hook.Run( "CanTool", ply, WireLib.dummytrace( outputentity ), "wire_adv_2" ) and
				WireLib.HasPorts( inputentity ) and WireLib.HasPorts( outputentity ) then
					
				local inputname = wiring[1]
				local inputpos = wiring[2]
				if WireLib.Link_Start( uid, inputentity, inputpos, inputname, material, color, width ) then
					for i=1,#wiring[4] do
						local node = wiring[4][i]
						WireLib.Link_Node( uid, node[1], node[2] )
					end
					local outputpos = wiring[6]
					local outputname = wiring[7]
					
					local trigger = false
					if outputname == "Create Wirelink" and (not outputentity.Outputs or not outputentity.Outputs["wirelink"]) then
						CreateWirelinkOutput( ply, outputentity, {true} )
						outputname = "wirelink"
						trigger = true
					elseif outputname == "Create Wirelink" and outputentity.Outputs and outputentity.Outputs["wirelink"] then
						outputname = "wirelink"
						trigger = true
					elseif outputname == "Create Entity" and (not outputentity.Outputs or not outputentity.Outputs["entity"]) then
						CreateEntityOutput( ply, outputentity, {true} )
						outputname = "entity"
						trigger = true
					elseif outputname == "Create Entity" and outputentity.Outputs and outputentity.Outputs["entity"] then
						outputname = "entity"
						trigger = true
					--elseif outputname == "wirelink" and outputentity.Outputs and outputentity.Outputs["wirelink"] then
					--	trigger = true
					--elseif outputname == "entity" and outputentity.Outputs and outputentity.Outputs["entity"] then
					--	trigger = true
					end
					

					
					WireLib.Link_End( uid, outputentity, outputpos, outputname, ply )
					
					if trigger then
						--timer.Simple( 1, function()
							--print("triggering output again: '" .. outputname .. "' of entity: '" .. tostring(outputentity) .. "'")
							--WireLib.TriggerOutput( outputentity, outputname, outputentity ) -- Trigger wirelink/entity
						--end )
					end
				end
			end			
		end
	end)
	
	util.AddNetworkString( "wire_adv_setstage" )
	net.Receive( "wire_adv_setstage", function( len, ply )
		local tool = get_active_tool(ply,"wire_adv_2")
		if not tool then return end
		
		tool:SetStage( net.ReadInt(8) )
	end)
	
	util.AddNetworkString( "wire_adv_unwire" )
	net.Receive( "wire_adv_unwire", function( len, ply )
		local ent = net.ReadEntity()
		local tbl = net.ReadTable()
		
		if hook.Run( "CanTool", ply, WireLib.dummytrace( ent ), "wire_adv_2" ) then
			for i=1,#tbl do
				WireLib.Link_Clear( ent, tbl[i] )
			end
		end
	end)
	
elseif CLIENT then
	-----------------------------------------------------------------
	-- Tool helper functions
	-----------------------------------------------------------------
	TOOL._stage = 0
	function TOOL:SetStage(stage) -- wtf garry
		net.Start("wire_adv_setstage")
			net.WriteInt(stage,8)
		net.SendToServer()
		self._stage = stage
	end
	function TOOL:GetStage()
		return self._stage
	end
	function TOOL:Upload()
		net.Start( "wire_adv_upload" )
			net.WriteTable( self.Wiring )
		net.SendToServer()
		
		self:Holster()
	end
	function TOOL:Unwire( ent, names ) -- arguments can be either ( ent, iname ) or ( { {ent,iname}, {ent,iname}, {ent,iname}, ... } )
		net.Start( "wire_adv_unwire" )
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
		if self.ShowWirelink then
			if outputs then
				local found = false
				for i=1,#outputs do
					if (outputs[i][1] == "wirelink" and outputs[i][2] == "WIRELINK") or
						(outputs[i][1] == "Create Wirelink" and outputs[i][2] == "WIRELINK") then found = true break end
				end
				if not found then
					outputs = table.Copy(outputs) -- we don't want to modify the original table
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
					outputs = table.Copy(outputs) -- we don't want to modify the original table
					outputs[#outputs+1] = { "Create Entity", "ENTITY" }
				end
			else
				outputs = { { "Create Entity", "ENTITY" } }
			end
		end
		self.CurrentInputs = inputs
		self.CurrentOutputs = outputs
	end
	
	function TOOL:GetPorts( ent )
		if IsValid( ent ) then
			if ent ~= self.AimingEnt2 then
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
		self.CurrentWireIndex = 1
		if IsValid(self.CurrentEntity) then self.CurrentEntity:SetNetworkedBeamString("BlinkWire", "") end
		self.CurrentEntity = nil
		self.Wiring = {}
		self.WiringRender = {}
		self.ShowWirelink = false
		self.ShowEntity = false
		self:SetStage(0)
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
	
	
	function TOOL:CheckWireStart( entity, inputname )
		for i=1,#self.Wiring do
			local wiring = self.Wiring[i]
			if wiring[1] == inputname  and wiring[3] == entity then return false end
		end
		return true
	end
	
	-- Small helper functions to format the table correctly
	function TOOL:WireStart( entity, pos, inputname, inputtype )
		if not self:CheckWireStart( entity, inputname ) then return end -- wiring is already started
		local t = { inputname, entity:WorldToLocal( pos ), entity, {} }
		t[8] = inputtype
		self.Wiring[#self.Wiring+1] = t
		
		if inputtype == "WIRELINK" then
			self.ShowWirelink = true
		elseif inputtype == "ENTITY" then
			self.ShowEntity = true
		end
		
		-- Add info to the wiringrender table, which is used to render the "x2" "x3" etc
		local wiringrender
		for i=1,#self.WiringRender do
			if self.WiringRender[i][1] == inputname and self.WiringRender[i][2] == inputtype then
				wiringrender = self.WiringRender[i]
				break
			end
		end
		
		if wiringrender then
			wiringrender[9] = wiringrender[9] + 1
		else
			local wiringrender = { inputname, inputtype }
			wiringrender[8] = inputtype
			wiringrender[9] = 1
			self.WiringRender[#self.WiringRender+1] = wiringrender
		end
		
		return t
	end
	function TOOL:WireNode( wiring, entity, pos )
		wiring[4][#wiring[4]+1] = { entity, entity:WorldToLocal( pos ) }
	end
	function TOOL:WireEnd( wiring, entity, pos, outputname )
		wiring[5] = entity
		wiring[6] = entity:WorldToLocal( pos )
		wiring[7] = outputname
		wiring[8] = nil -- we don't need to send the type to the server; wasted net message space. Delete it
		self.NeedsUpload = true
	end
	
	
	-----------------------------------------------------------------
	-- Mouse buttons
	-----------------------------------------------------------------

	TOOL.wtfgarry = 0
	function TOOL:LeftClick(trace)
		if self.wtfgarry > CurTime() then return end
		self.wtfgarry = CurTime() + 0.1
		
		local shift = self:GetOwner():KeyDown(IN_SPEED)
		local alt = self:GetOwner():KeyDown(IN_WALK)
		
		if IsValid( trace.Entity ) and WireLib.HasPorts( trace.Entity ) then
			if self:GetStage() == 0 then
				local inputs, _ = self:GetPorts( trace.Entity )
				
				if alt then -- Select everything
					for i=1,#inputs do
						self:WireStart( trace.Entity, trace.HitPos, inputs[i][1], inputs[i][2] )
					end
				else
					-- Single input selection
					self:WireStart( trace.Entity, trace.HitPos, inputs[self.CurrentWireIndex][1], inputs[self.CurrentWireIndex][2] )
				end
				self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )
				return
			elseif self:GetStage() == 1 then
				local _, outputs = self:GetPorts( trace.Entity )
				if not outputs and not self.ShowWirelink and not self.ShowEntity then return end
				
				self.CurrentEntity = trace.Entity
				
				self:SetStage(2)
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
			local _, outputs = self:GetPorts( self.CurrentEntity )
			
			if alt then -- Auto wiring
				local notwired = 0
				for i=1,#self.Wiring do
					local wiring = self.Wiring[i]
					local inputname = wiring[1]
					local inputtype = wiring[8]
					local found = false
					for j=1,#outputs do
						local outputname = outputs[j][1]
						local outputtype = outputs[j][2]
						
						if self:IsHighlighted( "Outputs", outputs, self.CurrentEntity, j, i ) then
							self:WireEnd( wiring, self.CurrentEntity, trace.HitPos, outputname )
							found = true
							break
						end
					end
					if not found then notwired = notwired + 1 end
				end
				
				if notwired > 0 then
					WireLib.AddNotify( "Could not find a matching name for " .. notwired .. " inputs. They were not wired.", NOTIFY_HINT, 5, NOTIFYSOUND_DRIP1 )
				end
				
				self:SetStage(0)
			else -- Normal wiring
				local notwired = 0
				for i=1,#self.Wiring do
					if outputs[self.CurrentWireIndex][2] == self.Wiring[i][8] then
						self:WireEnd( self.Wiring[i], self.CurrentEntity, trace.HitPos, outputs[self.CurrentWireIndex][1] )
					else
						notwired = notwired + 1
					end
				end
				
				if notwired > 0 then
					WireLib.AddNotify( "The type did not match for " .. notwired .. " inputs. They were not wired.", NOTIFY_HINT, 5, NOTIFYSOUND_DRIP1 )
				end
				
				self:SetStage(0)
			end
			
			self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )
		end
	end
	
	function TOOL:RightClick(trace)
		if self.wtfgarry > CurTime() then return end
		self.wtfgarry = CurTime() + 0.1
		
		if self:GetStage() == 0 or self:GetStage() == 2 then
			self:ScrollDown(trace)
		elseif IsValid(trace.Entity) and self:GetStage() == 1 then
			for i=1,#self.Wiring do
				self:WireNode( self.Wiring[i], trace.Entity, trace.HitPos )
			end
		end
	end

	function TOOL:Reload(trace)
		if self.wtfgarry > CurTime() then return end
		self.wtfgarry = CurTime() + 0.1
		
		if self:GetStage() == 0 and IsValid( trace.Entity ) and WireLib.HasPorts( trace.Entity ) then
			local inputs, outputs = self:GetPorts( trace.Entity )
			if self:GetOwner():KeyDown( IN_WALK ) then
				local t = {}
				for i=1,#inputs do
					t[i] = inputs[i][1]
				end
				self:Unwire( trace.Entity, t )
			else
				self:Unwire( trace.Entity, { inputs[self.CurrentWireIndex][1] } )
			end
		end
		
		self:Holster()
		self:LoadMemorizedIndex( trace.Entity, true )

		self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )
	end
	
	function TOOL:Scroll(trace,dir)
		local ent = self:GetStage() == 0 and trace.Entity or self.CurrentEntity
		if IsValid(ent) and WireLib.HasPorts( ent ) then
			local inputs, outputs = self:GetPorts( ent )			
			local check = self:GetStage() == 0 and inputs or outputs
			
			local b = false
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
				ent:SetNetworkedBeamString("BlinkWire", check[self.CurrentWireIndex][1])
				self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")
			end
			return true
		end
	end
	
	function TOOL:ScrollUp(trace) return self:Scroll(trace,-1) end
	function TOOL:ScrollDown(trace) return self:Scroll(trace,1) end
	
	hook.Add("PlayerBindPress", "wire_adv_2", function(ply, bind, pressed)
		if not pressed then return end
		
		if bind == "invnext" then
			local self = get_active_tool(ply, "wire_adv_2")
			if not self then return end
			
			return self:ScrollDown(ply:GetEyeTraceNoCursor())
		elseif bind == "invprev" then
			local self = get_active_tool(ply, "wire_adv_2")
			if not self then return end
			
			return self:ScrollUp(ply:GetEyeTraceNoCursor())
		end
	end)
	
	-----------------------------------------------------------------
	-- Remember wire indexes
	-----------------------------------------------------------------
	
	-- Remember wire index positions for entities
	TOOL.WireIndexMemory = {}
	TOOL.AimingEnt = nil
	function TOOL:LoadMemorizedIndex( ent, forceload )
		-- Memorize selected input
		if IsValid(self.AimingEnt) and not forceload then
			if not self.WireIndexMemory[self.AimingEnt] then
				self.WireIndexMemory[self.AimingEnt] = {}
			end
			if not self.WireIndexMemory[self.AimingEnt:GetClass()] then
				self.WireIndexMemory[self.AimingEnt:GetClass()] = {} -- save to class as well
			end
			self.WireIndexMemory[self.AimingEnt][self:GetStage()] = self.CurrentWireIndex
			self.WireIndexMemory[self.AimingEnt:GetClass()][self:GetStage()] = self.CurrentWireIndex -- save to class as well
		end
	
		-- Retrieve memorized selected input
		if IsValid(ent) and (ent ~= self.AimingEnt or forceload) then
			if self:GetStage() == 2 and self.CurrentEntity ~= ent then return end
		
			if self.WireIndexMemory[ent] and self.WireIndexMemory[ent][self:GetStage()] then
				self.CurrentWireIndex = self.WireIndexMemory[ent][self:GetStage()]
			elseif self.WireIndexMemory[ent:GetClass()] and self.WireIndexMemory[ent:GetClass()][self:GetStage()] then -- if this entity doesn't have a stored position, get an educated from the class instead
				self.CurrentWireIndex = self.WireIndexMemory[ent:GetClass()][self:GetStage()]
			end
			
			
			if IsValid( self.AimingEnt ) then
				self.AimingEnt:SetNetworkedBeamString("BlinkWire", "")
				local inputs, outputs = self:GetPorts( ent )
				local check = self:GetStage() == 0 and inputs or outputs
				if check then
					self.CurrentWireIndex = math.Clamp(	self.CurrentWireIndex, 1, #check )
					if check[self.CurrentWireIndex] then
						ent:SetNetworkedBeamString("BlinkWire", check[self.CurrentWireIndex][1])
					end
				end
			end
			self.AimingEnt = ent
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
	
	function TOOL:IsHighlighted( name, tbl, ent, idx, optional_idx )
		local alt = self:GetOwner():KeyDown( IN_WALK )
		if name == "Outputs" and self:GetStage() == 2 and alt then -- if we're holding alt, highlight all outputs that will be wired to
			for i=1,(optional_idx ~= nil and 1 or #self.Wiring) do
				local outputname = tbl[idx][1]
				local outputtype = tbl[idx][2]
				local inputname = self.Wiring[optional_idx or i][1]
				local inputtype = self.Wiring[optional_idx or i][8]
				if (outputname == inputname and outputtype == inputtype) or (inputtype == "WIRELINK" and (outputname == "wirelink" or outputname == "Create Wirelink") and outputtype == "WIRELINK") or
																			(inputtype == "ENTITY" and (outputname == "entity" or outputname == "Create Entity") and outputtype == "ENTITY") then
					return true
				end
			end
		elseif name == "Selected" and self:GetStage() == 2 and alt then -- highlight all selected inputs that will be wired
			local inputs, outputs = self:GetPorts( ent )
			
			for i=1,#outputs do
				local outputname = outputs[i][1]
				local outputtype = outputs[i][2]
				local inputname = tbl[idx][1]
				local inputtype = tbl[idx][8]
				if (outputname == inputname and outputtype == inputtype) or (inputtype == "WIRELINK" and (outputname == "wirelink" or outputname == "Create Wirelink") and outputtype == "WIRELINK") or
																			(inputtype == "ENTITY" and (outputname == "entity" or outputname == "Create Entity") and outputtype == "ENTITY") then
					return true
				end
			end		
		elseif name == "Inputs" and self:GetStage() == 0 then
			return self.CurrentWireIndex == idx or alt
		elseif name == "Outputs" and self:GetStage() == 2 then
			return self.CurrentWireIndex == idx
		end
		return false
	end
	
	function TOOL:IsBlocked( name, tbl, ent, idx )
		if name == "Outputs" and self:GetStage() > 0 then -- Gray out the ones that we can't wire any of the selected inputs to
			for i=1,#self.Wiring do
				local inputtype = self.Wiring[i][8]
				if tbl[idx][2] == inputtype then
					return false
				end
			end
			return true
		elseif name == "Selected" and self:GetStage() == 2 and WireLib.HasPorts( ent ) and self:GetOwner():KeyDown( IN_WALK ) then -- Gray out the ones that won't be able to be wired to any input
			local inputs, outputs = self:GetPorts( ent )
			if not outputs then return false end
			for i=1,#outputs do
				if tbl[idx][8] == outputs[i][2] then return false end
			end
			return true
		elseif name == "Selected" and self:GetStage() == 2 and WireLib.HasPorts( ent ) then -- Gray out the ones that won't be able to be wired to the selected output
			local inputs, outputs = self:GetPorts( ent )
			if not outputs then return false end
			return tbl[idx][2] ~= outputs[self.CurrentWireIndex][2]
		end
		return false
	end
	
	local function getName( input )
		local name = input[1]
		local tp = input[8] or (type(input[2]) == "string" and input[2] or "")
		local desc = (IsEntity(input[3]) and "" or input[3]) or ""
		return name .. (desc ~= "" and " (" .. desc .. ")" or "") .. (tp ~= "NORMAL" and " [" .. tp.. "]" or "")
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
	
	local fontData = {font = "Trebuchet24"} -- 24 and 18 are stock
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
	function TOOL:fitFont( lines, maxsize )
		if not fontheights then
			getFontSizes()
		end
		
		for i=24,14,-2 do
			local fontname = "Trebuchet" .. i
			local height = fontheights[fontname]
			if height * lines <= maxsize then
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
		surface.SetTextColor( Color(255,255,255,255) )
		surface.SetTextPos( x-temp/2+w/2, y )
		surface.DrawText( name .. ":" )
		surface.SetDrawColor( Color(255,255,255,255) )
		surface.DrawLine( x, y + fonth+2, x+w, y + fonth+2 )
		
		y = y + 6
		
		-- Draw inputs
		for i=1,#tbl do
			y = y + fonth
			
			if self:IsHighlighted( name, tbl, ent, i ) then
				draw.RoundedBox( 4, x-4,y, w+8,fonth+2, Color(0,150,0,192) )
			end
			
			if tbl[i][4] == true then
				surface.SetTextColor( Color(255,0,0,255) )
			elseif self:IsBlocked( name, tbl, ent, i ) then
				surface.SetTextColor( Color(255,255,255,32) )
			else
				surface.SetTextColor( Color(255,255,255,255) )
			end
			
			if tbl[i][9] and tbl[i][9] > 1 then
				surface.SetFont( "Trebuchet14" )
				local tempw, temph = surface.GetTextSize( "x" .. tbl[i][9] )
				surface.SetTextPos( x+w-tempw+2, y+fonth/2-temph/2 )
				surface.DrawText( "x" .. tbl[i][9] )
				surface.SetFont( self.CurrentFont )
			end
			
			surface.SetTextPos( x, y )
			surface.DrawText( getName( tbl[i] ) )
		end
	end

	function TOOL:DrawHUD()
		local centerx, centery = ScrW()/2, ScrH()/2
		
		local ent = self:GetStage() == 2 and self.CurrentEntity or self:GetOwner():GetEyeTrace().Entity
		local maxwidth = 0
		if IsValid( ent ) and WireLib.HasPorts( ent ) then
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
			end
			
			if outputs and #outputs > 0 and self:GetStage() > 0 then
				local w, h = self:fitFont( #outputs, ScrH() - 32 )
				local ww, hh = getWidthHeight( outputs )
				ww = math.max(ww,w)
				hh = math.max(hh,h) + h
				local x = centerx+38
				local y = centery-hh/2-16
				self:DrawList( "Outputs", outputs, ent, x, y, ww, hh, h )
			end
		end
		
		if #self.WiringRender > 0 then	
			local w, h = self:fitFont( #self.WiringRender, ScrH() - 32 )
			local ww, hh = getWidthHeight( self.WiringRender )
			local ww = math.max(ww,w)
			local hh = math.max(hh,h) + h
			local x = centerx-maxwidth-ww-38
			local y = centery-hh/2-16
			self:DrawList( "Selected", self.WiringRender, ent, x, y, ww, hh, h )
		end
		--[[
		if #self.Wiring> 0 then	
			local w, h = fitFont( #self.Wiring, ScrH() - 32 )
			local ww, hh = getWidthHeight( self.Wiring )
			local ww = math.max(ww,w)
			local hh = math.max(hh,h) + h
			local x = centerx-maxwidth-ww-38
			local y = centery-hh/2-16
			self:DrawList( "Selected", self.Wiring, ent, x, y, ww, hh, h )
		end
		]]
	end
	
	--[[
	local fontTable = {
		font = "Arial",
		size = 34,
		weight = 1000,
		antialias = true,
		additive = false,
	}
	surface.CreateFont("Arial34", fontTable)
	fontTable.size = 28
	surface.CreateFont("Arial28", fontTable)
	
	local black = Color(0, 0, 0, 255)
	local offWhite = Color(224, 224, 224, 255)
	local arrowMat = Material( "icon16/arrow_down.png", "noclamp" )
	local function WriteText(text, y) DrawTextOutline(text, "Arial28", 128, y + 28/2, offWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, black, 4) return y + 26 end
	
	function TOOL:DrawToolScreen(width, height)
		surface.SetDrawColor(Color(32, 32, 32, 255))
		surface.DrawRect(0, 0, 256, 256)
		
		local y = 6
		DrawTextOutline("Advanced Wiring", "Arial34", 128, y + 34/2, offWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, black, 4) y = y + 34
		surface.SetDrawColor(offWhite) 
		surface.DrawRect(0, y + 4, 256, 4) y = y + 14
		if not IsValid(self.target) then
			y = WriteText("Click Input Entity", y)
		else
			if self.MultiInputs then
				y = WriteText("Input Entities: "..#self.MultiInputs, y)
			else
				y = WriteText(string.format("'%s'", self:GetOwner():KeyDown(IN_WALK) and "*All*" or (self.selinput or self.input or {""})[1]), y)
				y = WriteText(self.target.WireDebugName or self.target:GetClass(), y)
				y = WriteText(string.format("[%i]", self.target:EntIndex()), y)
			end
			surface.SetMaterial(arrowMat)
			surface.SetDrawColor(Color(200,255,200,255))
			surface.DrawTexturedRectUV( 128-24, y+8, 48, 48, 0, 0.35, 1, 1 )
			y = y + 58
			if self.source then 
				y = WriteText(string.format("%s", self.source.WireDebugName or self.source:GetClass()), y)
				y = WriteText(string.format("[%i]", self.source:EntIndex()), y)
			end
		end
	end
	]]

	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire.name", Description = "#Tool.wire.desc" })
		WireToolHelpers.MakePresetControl(panel, "wire_adv")

		panel:NumSlider("#WireTool_width", "wire_adv_2_width", 0, 5, 2)
		local matselect = panel:AddControl( "RopeMaterial", { Label = "#WireTool_material", convar = "wire_adv_2_material" } )
		matselect:AddMaterial("Arrowire", "arrowire/arrowire")
		matselect:AddMaterial("Arrowire2", "arrowire/arrowire2")

		panel:AddControl("Color", {
			Label = "#WireTool_colour",
			Red = "wire_adv_2_r",
			Green = "wire_adv_2_g",
			Blue = "wire_adv_2_b"
		})
	end

end