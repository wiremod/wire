
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
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Select input (Shift: Select multiple; Alt: Select all)" },
		{ name = "right_0", stage = 0, text = "Next" },
		{ name = "reload_0", stage = 0, text = "Unlink (Alt: Unlink all)" },
		{ name = "mwheel_0", stage = 0, text = "Mouse wheel: Next" },
		{ name = "left_1", stage = 1, text = "Select entity" },
		{ name = "right_1", stage = 1, text = "Add wirepoint" },
		{ name = "reload_1", stage = 1, text = "Cancel" },
		{ name = "left_2", stage = 2, text = "Select output (Alt: Auto-connect matching input/outputs)" },
		{ name = "right_2", stage = 2, text = "Next" },
		{ name = "mwheel_2", stage = 2, text = "Mouse wheel: Next" },
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
}

util.PrecacheSound("weapons/pistol/pistol_empty.wav")

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
	-----------------------------------------------------------------
	-- Duplicator modifiers
	-----------------------------------------------------------------
	function WireLib.CreateWirelinkOutput( ply, ent, data )
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
					if v.Name == "wirelink" then return end -- we already have a wirelink output, abort
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
			
			ent.extended = true
			WireLib.TriggerOutput( ent, "wirelink", ent )
		end
		duplicator.StoreEntityModifier( ent, "CreateWirelinkOutput", data )
	end
	duplicator.RegisterEntityModifier( "CreateWirelinkOutput", WireLib.CreateWirelinkOutput )
	
	function WireLib.CreateEntityOutput( ply, ent, data )
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
					if v.Name == "entity" then return end -- we already have an entity output, abort
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
	duplicator.RegisterEntityModifier( "CreateEntityOutput", WireLib.CreateEntityOutput )
	
	
	-----------------------------------------------------------------
	-- Receving data from client
	-----------------------------------------------------------------
	
	util.AddNetworkString( "wire_adv_upload" )
	net.Receive( "wire_adv_upload", function( len, ply )
		local wirings = net.ReadTable()
		
		local tool = get_active_tool(ply,"wire_adv")
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
				hook.Run( "CanTool", ply, WireLib.dummytrace( inputentity ), "wire_adv" ) and
				hook.Run( "CanTool", ply, WireLib.dummytrace( outputentity ), "wire_adv" ) then
					
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
	end)
	
	util.AddNetworkString( "wire_adv_unwire" )
	net.Receive( "wire_adv_unwire", function( len, ply )
		local ent = net.ReadEntity()
		local tbl = net.ReadTable()
		
		if hook.Run( "CanTool", ply, WireLib.dummytrace( ent ), "wire_adv" ) then
			for i=1,#tbl do
				WireLib.Link_Clear( ent, tbl[i] )
			end
		end
	end)
	
	
	if game.SinglePlayer() then -- wtfgarry (these functions don't get called clientside in single player so we need this hack to fix it)
		util.AddNetworkString( "wire_adv_wtfgarry" )
		local function send( ply, funcname )
			net.Start( "wire_adv_wtfgarry" )
				net.WriteString( funcname )
			net.Send( ply )
		end
		
		function TOOL:LeftClick() send( self:GetOwner(), "LeftClick" ) end
		function TOOL:RightClick() send( self:GetOwner(), "RightClick" ) end
		function TOOL:Reload() send( self:GetOwner(), "Reload" ) end
	end
elseif CLIENT then
	if game.SinglePlayer() then -- wtfgarry
		net.Receive( "wire_adv_wtfgarry", function( len )
			local funcname = net.ReadString()
			local tool = get_active_tool( LocalPlayer(), "wire_adv" )
			if not tool then return end
			tool[funcname]( tool, LocalPlayer():GetEyeTrace() )
		end)
	end

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
	
		net.Start( "wire_adv_upload" )
			net.WriteTable( self.Wiring )
		net.SendToServer()
		
		self:Holster()
	end
	function TOOL:Unwire( ent, names )
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
		
		local copied = false
		
		if self.ShowWirelink then
			if outputs then
				local found = false
				for i=1,#outputs do
					if outputs[i][2] == "WIRELINK" then found = true break end
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
	
	-----------------------------------------------------------------
	-- Mouse buttons
	-----------------------------------------------------------------

	TOOL.wtfgarry = 0
	function TOOL:LeftClick(trace)
		if self.wtfgarry > CurTime() then return end
		self.wtfgarry = CurTime() + 0.1
		
		local shift = self:GetOwner():KeyDown(IN_SPEED)
		local alt = self:GetOwner():KeyDown(IN_WALK)
		
		if IsValid( trace.Entity ) then
			if self:GetStage() == 0 then
				local inputs, _ = self:GetPorts( trace.Entity )
				if not inputs then return end
				
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
				local _, outputs = self:GetPorts( trace.Entity )
				if not outputs then return end
				
				self.CurrentEntity = trace.Entity
				self:AutoWiringTypeLookup( self.CurrentEntity )
				
				self:SetStage(2)
				
				for i=1,#self.Wiring do
					self:WireEndEntityPos( self.Wiring[i], self.CurrentEntity, trace.HitPos )
				end
				
				if next(outputs,next(outputs)) == nil then -- there's only one element in the table
					self.wtfgarry = 0
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
		end
	end
	
	function TOOL:RightClick(trace)
		if self.wtfgarry > CurTime() then return end
		self.wtfgarry = CurTime() + 0.1
		
		if self:GetStage() == 0 or self:GetStage() == 2 then
			self:ScrollDown(trace)
		elseif IsValid(trace.Entity) and self:GetStage() == 1 then
			for i=1,#self.Wiring do
				self:WireNode( self.Wiring[i], trace.Entity, trace.HitPos + trace.HitNormal*(self:GetClientNumber("width")/2) )
			end
		end
	end

	function TOOL:Reload(trace)
		if self.wtfgarry > CurTime() then return end
		self.wtfgarry = CurTime() + 0.1
		
		if self:GetStage() == 0 and IsValid( trace.Entity ) and WireLib.HasPorts( trace.Entity ) then
			local inputs, outputs = self:GetPorts( trace.Entity )
			if not inputs then return end
			if self:GetOwner():KeyDown( IN_WALK ) then
				local t = {}
				for i=1,#inputs do
					t[i] = inputs[i][1]
				end
				self:Unwire( trace.Entity, t )
			else
				self:Unwire( trace.Entity, { inputs[self.CurrentWireIndex][1] } )
			end
		else
			self:Holster()
		end

		self:GetOwner():EmitSound( "weapons/airboat/airboat_gun_lastshot" .. math.random(1,2) .. ".wav" )
	end
	
	function TOOL:Scroll(trace,dir)
		local ent = self:GetStage() == 0 and trace.Entity or self.CurrentEntity
		if IsValid(ent) then
			local inputs, outputs = self:GetPorts( ent )
			if not inputs and not outputs then return end
			local check = self:GetStage() == 0 and inputs or outputs
			if #check == 0 then return end
			
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
	
	local function hookfunc( ply, bind, pressed )
		if not pressed then return end
	
		if bind == "invnext" then
			local self = get_active_tool(ply, "wire_adv")
			if not self then return end
			
			return self:ScrollDown(ply:GetEyeTraceNoCursor())
		elseif bind == "invprev" then
			local self = get_active_tool(ply, "wire_adv")
			if not self then return end
			
			return self:ScrollUp(ply:GetEyeTraceNoCursor())
		elseif bind == "impulse 100" and ply:KeyDown( IN_SPEED ) then
			local self = get_active_tool(ply, "wire_adv")
			if not self then
				self = get_active_tool(ply, "wire_debugger")
				if not self then return end
				
				spawnmenu.ActivateTool( "wire_adv") -- switch back to wire adv
				return true
			end
			
			spawnmenu.ActivateTool("wire_debugger") -- switch to debugger
			return true
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
				self.AimingEnt:SetNetworkedBeamString("BlinkWire", "")
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
						ent:SetNetworkedBeamString("BlinkWire", check[self.CurrentWireIndex][1])
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
			local inputs, outputs = self:GetPorts( ent )
			
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
			if self:GetOwner():KeyDown( IN_WALK ) then -- Gray out the ones that won't be able to be wired to any input
				local inputs, outputs = self:GetPorts( ent )
				if not outputs then return false end
				for i=1,#outputs do
					if tbl[idx][2] == outputs[i][2] then return false end
				end
				return true
			else -- Gray out the ones that won't be able to be wired to the selected output
				local inputs, outputs = self:GetPorts( ent )
				if not outputs then return false end
				return tbl[idx][2] ~= outputs[self.CurrentWireIndex][2]
			end
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
		surface.SetTextColor( Color(255,255,255,255) )
		surface.SetTextPos( x-temp/2+w/2, y )
		surface.DrawText( name .. ":" )
		surface.SetDrawColor( Color(255,255,255,255) )
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
				draw.RoundedBox( 4, x-4,y, w+8,fonth+2, clr )
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
			return (outputname == inputname and outputtype == inputtype)
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
	end

end
