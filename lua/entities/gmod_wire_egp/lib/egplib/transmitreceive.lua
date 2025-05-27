--------------------------------------------------------
-- Queue Functions
--------------------------------------------------------
local EGP = E2Lib.EGP

local hasObject
EGP.HookPostInit(function()
	hasObject = EGP.HasObject
end)

if (SERVER) then
	util.AddNetworkString( "EGP_Transmit_Data" )

	----------------------------
	-- Umsgs per second check
	----------------------------
	EGP.IntervalCheck = WireLib.RegisterPlayerTable()

	function EGP:CheckInterval( ply )
		if not self.IntervalCheck[ply] then self.IntervalCheck[ply] = { bytes = 0, time = 0 } end

		local maxcount = self.ConVars.MaxPerSec:GetInt()

		local tbl = self.IntervalCheck[ply]
		tbl.bytes = math.max(0, tbl.bytes - (CurTime() - tbl.time) * maxcount)
		tbl.time = CurTime()
		return tbl.bytes < maxcount
	end

	----------------------------
	-- Queue functions
	----------------------------

	util.AddNetworkString( "ClearScreen" )
	local function ClearScreen( Ent, ply )
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueue( Ent, ply, ClearScreen, "ClearScreen" )
			return
		end

		if not EGP.umsg.Start( "EGP_Transmit_Data", ply ) then return end
			net.WriteEntity( Ent )
			net.WriteString( "ClearScreen" )
		EGP.umsg.End( Ent )

		EGP:SendQueueItem( ply )
	end

	util.AddNetworkString( "SaveFrame" )
	local function SaveFrame( Ent, ply, FrameName )
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueue( Ent, ply, SaveFrame, "SaveFrame", FrameName )
			return
		end

		util.AddNetworkString( FrameName )
		if not EGP.umsg.Start( "EGP_Transmit_Data", ply ) then return end
			net.WriteEntity( Ent )
			net.WriteString( "SaveFrame" )
			net.WriteEntity( ply )
			net.WriteString( FrameName )
		EGP.umsg.End( Ent )

		EGP:SendQueueItem( ply )
	end

	util.AddNetworkString( "LoadFrame" )
	local function LoadFrame( Ent, ply, FrameName )
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueue( Ent, ply, LoadFrame, "LoadFrame", FrameName )
			return
		end

		local bool, _ = EGP:LoadFrame( ply, Ent, FrameName )
		if not bool then return end

		if not EGP.umsg.Start( "EGP_Transmit_Data", ply ) then return end
			net.WriteEntity( Ent )
			net.WriteString( "LoadFrame" )
			net.WriteEntity( ply )
			net.WriteString( FrameName )
		EGP.umsg.End( Ent )

		EGP:SendQueueItem( ply )
	end

	-- Extra Add Poly queue item, used by poly objects with a lot of vertices in them
	util.AddNetworkString( "AddVertex" )
	local function AddVertex( Ent, ply, index, vertices )
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueue( Ent, ply, AddVertex, "AddVertex", index, vertices )
			return
		end

		local bool, _, v = hasObject(Ent, index)
		if (bool) then
			if not EGP.umsg.Start("EGP_Transmit_Data", ply) then return end
				net.WriteEntity( Ent )
				net.WriteString( "AddVertex" )
				net.WriteInt( index, 16 )
				net.WriteUInt( #vertices, 8 )
				for i=1,#vertices do
					local vert = vertices[i]
					net.WriteInt( vert.x, 16 )
					net.WriteInt( vert.y, 16 )
					if (v.HasUV) then
						net.WriteFloat( vert.u or 0 )
						net.WriteFloat( vert.v or 0 )
					end
				end
			EGP.umsg.End( Ent )
		end

		EGP:SendQueueItem( ply )
	end

	-- Extra Set Poly queue item, used by poly objects with a lot of vertices in them
	util.AddNetworkString( "SetVertex" )
	function EGP._SetVertex( Ent, ply, index, vertices, skiptoadd )

		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueue( Ent, ply, EGP._SetVertex, "SetVertex", index, vertices, skiptoadd )
			return
		end

		local bool, _, v = hasObject(Ent, index)
		if (bool) then
			if not EGP.umsg.Start("EGP_Transmit_Data", ply) then return end
				net.WriteEntity( Ent )
				net.WriteString( "SetVertex" )
				net.WriteInt( index, 16 )
				net.WriteUInt( #vertices, 8 )
				for i=1,#vertices do
					local vert = vertices[i]
					net.WriteInt( vert.x, 16 )
					net.WriteInt( vert.y, 16 )
					if (v.HasUV) then
						net.WriteFloat( vert.u or 0 )
						net.WriteFloat( vert.v or 0 )
					end
				end
			EGP.umsg.End( Ent )
		end

		EGP:SendQueueItem( ply )
	end

	-- Extra Add Text queue item, used by text objects with a lot of text in them
	util.AddNetworkString( "AddText" )
	local function AddText( Ent, ply, index, text )
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if EGP:CheckInterval( ply ) == false then
			EGP:InsertQueue( Ent, ply, AddText, "AddText", index, text )
			return
		end

		if hasObject(Ent, index) then
			if not EGP.umsg.Start("EGP_Transmit_Data", ply) then return end
				net.WriteEntity( Ent )
				net.WriteString( "AddText" )
				net.WriteInt( index, 16 )
				net.WriteString( text )
			EGP.umsg.End( Ent )
		end

		EGP:SendQueueItem( ply )
	end

	-- Extra Set Text queue item, used by text objects with a lot of text in them
	util.AddNetworkString( "SetText" )
	function EGP._SetText( Ent, ply, index, text )
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueue( Ent, ply, EGP._SetText, "SetText", index, text )
			return
		end

		if hasObject(Ent, index) then
			if not EGP.umsg.Start("EGP_Transmit_Data", ply) then return end
				net.WriteEntity( Ent )
				net.WriteString( "SetText" )
				net.WriteInt( index, 16 )
				net.WriteString( text )
			EGP.umsg.End( Ent )
		end

		EGP:SendQueueItem( ply )
	end

	local function SetScale( ent, ply, x, y )
		EGP:SetScale( ent, x, y )
		EGP:SendQueueItem( ply )
	end

	local function MoveTopLeft( ent, ply, bool )
		ent.TopLeft = bool
		EGP:SendQueueItem( ply )
	end

	util.AddNetworkString( "EditFiltering" )
	local function EditFiltering( Ent, ply, filtering )
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueue( Ent, ply, EditFiltering, "EditFiltering", filtering )
			return
		end
		if not EGP.umsg.Start("EGP_Transmit_Data", ply) then return end
			net.WriteEntity( Ent )
			net.WriteString( "EditFiltering" )
			net.WriteUInt( filtering, 2 )
		EGP.umsg.End( Ent )

		EGP:SendQueueItem( ply )
	end

	util.AddNetworkString( "ReceiveObjects" )
	local function SendObjects( Ent, ply, DataToSend )
		if not Ent or not Ent:IsValid() or not ply or not ply:IsValid() or not DataToSend then return end

		-- Check duped
		if (Ent.EGP_Duplicated) then
			EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
			return
		end

		-- Check interval
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if (EGP:CheckInterval( ply ) == false) then
			EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
			return
		end

		local order_was_changed = false

		if not EGP.umsg.Start( "EGP_Transmit_Data", ply ) then return end
			net.WriteEntity( Ent )
			net.WriteString( "ReceiveObjects" )

			net.WriteUInt( #DataToSend, 16 ) -- Send estimated number of objects to be sent
			for k,v in ipairs( DataToSend ) do

				net.WriteInt( v.index, 16 ) -- Send index of object

				if (v.remove == true) then
					net.WriteUInt(0, 8) -- Object is to be removed, send a 0
				else
					net.WriteUInt(v.ID, 8) -- Else send the ID of the object
					if (Ent.Scaling or Ent.TopLeft) then
						local original = v
						v = table.Copy(v) -- Make a copy of the table so it doesn't overwrite the serverside object
						-- Todo: Make transmit only used for server join/leave/"newframes"/etc, not every time it updates
						if original.VerticesUpdate then original.VerticesUpdate = false end
					end

					-- Scale the positions and size
					if (Ent.Scaling) then
						EGP:ScaleObject( Ent, v )
					end

					-- Move the object to draw from the top left
					if (Ent.TopLeft) then
						EGP.MoveTopLeft( Ent, v )
					end

					if v.ChangeOrder then -- We want to change the order of this object, send the index to where we wish to move it
						net.WriteInt( v.ChangeOrder.target, 16 )
						net.WriteInt( v.ChangeOrder.dir, 3 )
						order_was_changed = true
					else
						net.WriteInt( 0, 16 ) -- Don't change order
					end

					v:Transmit( Ent, ply )
				end
			end
		EGP.umsg.End( Ent )

		-- Change order now
		if order_was_changed then
			EGP.PerformReorder(Ent)
		end

		EGP:SendQueueItem( ply )
	end

	----------------------------
	-- DoAction
	----------------------------

	function EGP:DoAction( Ent, E2, Action, ... )
		if (Action == "SendObject") then
			local Data = {...}
			local obj = Data[1]
			if not obj or obj._nodraw then return end

			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 30
			end

			self:AddQueueObject( Ent, E2.player, SendObjects, obj)
		elseif (Action == "RemoveObject") then
			local Data = {...}
			local obj = Data[1]

			local remove_index
			for i, v in ipairs(Ent.RenderTable) do
				E2.prf = E2.prf + 0.3
				if v.index == obj then
					remove_index = i
				elseif v.parent and v.parent == obj then
					EGP:UnParent(Ent, v)
				end
			end

			if remove_index then
				table.remove(Ent.RenderTable, remove_index)
			end

			self:AddQueueObject( Ent, E2.player, SendObjects, { index = Data[1], remove = true } )
		elseif (Action == "ClearScreen") then
			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 20
			end

			-- Remove all queued actions for this screen
			local queue = self.Queue[E2.player] or {}
			local i = 1
			while i<=#queue do
				if queue[i].Ent == Ent then
					E2.prf = E2.prf + 0.3
					table.remove(queue, i)
				else
					i = i + 1
				end
			end

			Ent.RenderTable = {}

			self:AddQueue( Ent, E2.player, ClearScreen, "ClearScreen" )
		elseif (Action == "SaveFrame") then
			local Data = {...}
			if not Data[1] then return end

			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 10
			end

			if EGP:SaveFrame( E2.player, Ent, Data[1] ) then
				self:AddQueue( Ent, E2.player, SaveFrame, "SaveFrame", Data[1] )
			end
		elseif (Action == "LoadFrame") then
			local Data = {...}
			if not Data[1] then return end

			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 10
			end

			local bool, frame = EGP:LoadFrame( E2.player, Ent, Data[1] )
			if (bool) then
				Ent.RenderTable = frame
			end

			self:AddQueue( Ent, E2.player, LoadFrame, "LoadFrame", Data[1] )
		elseif (Action == "SetScale") then
			local Data = {...}
			self:AddQueue( Ent, E2.player, SetScale, "SetScale", Data[1], Data[2] )
		elseif (Action == "MoveTopLeft") then
			local Data = {...}
			self:AddQueue( Ent, E2.player, MoveTopLeft, "MoveTopLeft", Data[1] )
		elseif (Action == "EditFiltering") then
			local Data = {...}
			self:AddQueue( Ent, E2.player, EditFiltering, "EditFiltering", Data[1] )
		end
	end
else -- SERVER/CLIENT
	function EGP:Receive( netlen )
		local Ent = net.ReadEntity()
		if not self:ValidEGP(Ent) or not Ent.RenderTable then return end

		local Action = net.ReadString()
		if (Action == "ClearScreen") then
			Ent.RenderTable = {}
			Ent:EGP_Update()
		elseif (Action == "SaveFrame") then
			local ply = net.ReadEntity()
			local FrameName = net.ReadString()
			EGP:SaveFrame( ply, Ent, FrameName )
		elseif (Action == "LoadFrame") then
			local ply = net.ReadEntity()
			local FrameName = net.ReadString()
			EGP:LoadFrame( ply, Ent, FrameName )
			Ent:EGP_Update()
		elseif (Action == "SetText") then
			local index = net.ReadInt(16)
			local text = net.ReadString()
			local bool,_,v = hasObject(Ent, index)
			if (bool) then
				if (EGP:EditObject( v, { text = text } )) then Ent:EGP_Update() end
			end
		elseif (Action == "AddText") then
			local index = net.ReadInt(16)
			local text = net.ReadString()
			local bool,_,v = hasObject(Ent, index)
			if (bool) then
				if (EGP:EditObject( v, { text = v.text .. text } )) then Ent:EGP_Update() end
			end
		elseif (Action == "SetVertex") then
			local index = net.ReadInt(16)
			local bool, _, v = hasObject(Ent, index)
			if (bool) then
				local vertices = {}

				if (v.HasUV) then
					for i=1,net.ReadUInt(8) do
						local x, y, u, _v = net.ReadInt(16), net.ReadInt(16), net.ReadFloat(), net.ReadFloat()
						vertices[i] = { x=x, y=y, u=u, v=_v }
					end
				else
					for i=1,net.ReadUInt(8) do
						local x, y = net.ReadInt(16), net.ReadInt(16)
						vertices[i] = { x=x, y=y }
					end
				end

				if v:EditObject({ vertices = vertices }) then Ent:EGP_Update() end
			end
		elseif (Action == "AddVertex") then
			local index = net.ReadInt(16)
			local bool, _, v = hasObject(Ent, index)
			if (bool) then
				local vertices = table.Copy(v.vertices)

				if (v.HasUV) then
					for i=1,net.ReadUInt(8) do
						local x, y, u, _v = net.ReadInt(16), net.ReadInt(16), net.ReadFloat(), net.ReadFloat()
						vertices[#vertices+1] = { x=x, y=y, u=u, v=_v }
					end
				else
					for i=1,net.ReadUInt(8) do
						local x, y = net.ReadInt(16), net.ReadInt(16)
						vertices[#vertices+1] = { x=x, y=y }
					end
				end

				if (EGP:EditObject( v, { vertices = vertices })) then Ent:EGP_Update() end
			end
		elseif (Action == "EditFiltering") then
			if Ent.GPU then -- Only Screens use GPULib
				Ent.GPU.texture_filtering = net.ReadUInt(2) or TEXFILTER.ANISOTROPIC
			end
		elseif (Action == "ReceiveObjects") then
			local order_was_changed = false

			for i=1,net.ReadUInt(16) do
				local index = net.ReadInt(16)
				if (index == 0) then break end -- In case the umsg had to abort early

				local ID = net.ReadUInt(8)

				if (ID == 0) then -- Remove object
					local bool, k, v = hasObject(Ent, index)
					if (bool) then
						if (v.OnRemove) then v:OnRemove() end

						-- Unparent all objects parented to this object
						for k2,v2 in pairs( Ent.RenderTable ) do
							if (v2.parent and v.index and v2.parent == v.index) then
								EGP:UnParent( Ent, v2 )
							end
						end

						table.remove( Ent.RenderTable, k )
					end
				else

					-- Change Order
					local ChangeOrder_To = net.ReadInt(16)
					local ChangeOrder_Dir
					if ChangeOrder_To ~= 0 then
						ChangeOrder_Dir = net.ReadInt(3)
					end

					local current_obj
					local bool, k, v = hasObject(Ent, index)
					if (bool) then -- Object already exists
						if (v.ID ~= ID) then -- Not the same kind of object, create new
							if (v.OnRemove) then v:OnRemove() end
							local Obj = table.Copy(EGP.Objects[ID])
							local data = Obj:Receive()
							Obj:Initialize(data)
							Obj.index = index
							Ent.RenderTable[k] = Obj
							if (Obj.OnCreate) then Obj:OnCreate() end

							current_obj = Obj
						else -- Edit
							v:EditObject(v:Receive())

							-- If parented, reset the parent indexes
							if (v.parent and v.parent ~= 0) then
								EGP:AddParentIndexes( v )
							end

							current_obj = v
						end
						-- For EGP HUD
						v.res = nil
					else -- Object does not exist. Create new
						local Obj = table.Copy(EGP.Objects[ID])
						Obj:Initialize(Obj:Receive())
						Obj.index = index
						if (Obj.OnCreate) then Obj:OnCreate() end
						Ent.RenderTable[#Ent.RenderTable+1] = Obj--table.insert( Ent.RenderTable, Obj )

						current_obj = Obj
					end

					-- Change Order (later)
					if ChangeOrder_To ~= 0 then
						order_was_changed = true
						current_obj.ChangeOrder = {target=ChangeOrder_To,dir=ChangeOrder_Dir}
					end
				end
			end


			-- Change order now
			if order_was_changed then
				EGP.PerformReorder(Ent)
			end

			Ent:EGP_Update()
		end
	end
	net.Receive( "EGP_Transmit_Data", function(netlen) EGP:Receive( netlen ) end )

end

if (SERVER) then
	util.AddNetworkString("EGP_Request_Transmit")

	EGP.DataStream = {}

	concommand.Add("EGP_Request_Reload",function(ply,cmd,args)
		if not EGP.DataStream[ply] then EGP.DataStream[ply] = {} end
		local tbl = EGP.DataStream[ply]
		if not tbl.SingleTime then tbl.SingleTime = 0 end
		if not tbl.AllTime then tbl.AllTime = 0 end
		if (args[1]) then
			if (tbl.SingleTime > CurTime()) then
				ply:ChatPrint("[EGP] This command has anti-spam protection. Try again after 10 seconds.")
			else
				tbl.SingleTime = CurTime() + 10
				ply:ChatPrint("[EGP] Request accepted for single screen. Sending...")
				EGP:SendDataStream( ply, args[1] )
			end
		else
			if (tbl.AllTime > CurTime()) then
				ply:ChatPrint("[EGP] This command has anti-spam protection. Try again after 30 seconds.")
			else
				tbl.AllTime = CurTime() + 30
				ply:ChatPrint("[EGP] Request accepted for all screens. Sending...")
				local bool, msg = EGP:SendDataStream( ply, args[1] )
				if (bool == false) then
					ply:ChatPrint("[EGP] " .. msg )
				end
			end
		end
	end)

	function EGP:SendDataStream( ply, entid, silent )
		if not ply or not ply:IsValid() then return false, "ERROR: Invalid ply." end
		local targets
		if (entid) then
			local tempent = Entity(entid)
			if (self:ValidEGP( tempent )) then
				targets = { tempent }
			else
				return false, "ERROR: Invalid screen."
			end
		end
		if not targets then
			targets = ents.FindByClass("gmod_wire_egp")
			table.Add( targets, ents.FindByClass("gmod_wire_egp_emitter") )

			if (#targets == 0) then return false, "There are no EGP screens on the map." end
		end

		local sent
		for k,v in ipairs( targets ) do
			if (v.RenderTable and #v.RenderTable>0) then
				local DataToSend = {}
				for k2, v2 in pairs( v.RenderTable ) do
					local obj = v2

					if (v.Scaling or v.TopLeft) then
						obj = table.Copy(v2) -- Make a copy of the table so it doesn't overwrite the serverside object
					else
						obj = v2
					end

					-- Scale the positions and size
					if (v.Scaling) then
						EGP:ScaleObject( v, obj )
					end

					-- Move the object to draw from the top left
					if (v.TopLeft) then
						EGP.MoveTopLeft( v, obj )
					end

					DataToSend[#DataToSend+1] = { ID = obj.ID, index = obj.index, Settings = obj:DataStreamInfo() }
				end

				timer.Simple( k - 1, function() -- send 1 second apart, send the first one instantly
					local isLastScreen = ((k == #targets) and #targets or nil)
					if silent then
						isLastScreen = nil
					end

					local data = {
						Ent = v,
						Objects = DataToSend,
						Filtering = v.GPU_texture_filtering,
						IsLastScreen = isLastScreen -- Doubles as notifying the client that no more data will arrive, and tells them how many did arrive
					}

					local von = WireLib.von.serialize(data)
					if #von > 60000 then
						ply:ChatPrint("[EGP] Error: Data too large to send to client. (" .. math.Round( #von / 1024, 2 ) .. " kb)")
						return
					end

					local compressed = util.Compress(von)
					local compressedLength = #compressed

					if compressedLength > 60000 then
						ply:ChatPrint("[EGP] Error: Compressed data too large to send to client. (" .. math.Round( compressedLength / 1024, 2 ) .. " kb)")
						return
					end

					net.Start("EGP_Request_Transmit")
					net.WriteUInt( compressedLength, 16 )
					net.WriteData( compressed, compressedLength )
					net.Send(ply)
				end)
				sent = true
			end
		end
		if not sent then
			return false, "None of the screens have any objects drawn on them."
		else
			return true, #targets
		end
	end

	local function initspawn(ply)
		timer.Simple(10,function()
			if (ply and ply:IsValid()) then
				local bool, msg = EGP:SendDataStream( ply )
				if (bool == true) then
					ply:ChatPrint("[EGP] " .. tostring(msg) .. " EGP Screens found on the server. Sending objects now...")
				end
			end
		end)
	end

	hook.Add("PlayerInitialSpawn","EGP_SpawnFunc",initspawn)
else
	function EGP:ReceiveDataStream( decoded )
		local Ent = decoded.Ent
		local Objects = decoded.Objects

		if (self:ValidEGP( Ent )) then
			Ent.RenderTable = {}
			if Ent.GPU then -- Only Screens use GPULib
				Ent.GPU.texture_filtering = decoded.Filtering or TEXFILTER.ANISOTROPIC
			end
			for _,v in pairs( Objects ) do
				local Obj = table.Copy(EGP.Objects[v.ID])
				Obj:Initialize(v.Settings)
				-- If parented, reset the parent indexes
				if (Obj.parent and Obj.parent ~= 0) then
					self:AddParentIndexes( Obj )
				end
				Obj.index = v.index
				table.insert( Ent.RenderTable, Obj )
			end
			Ent:EGP_Update()
		end

		if decoded.IsLastScreen then
			LocalPlayer():ChatPrint("[EGP] Received EGP object reload. " .. decoded.IsLastScreen .. " screens' objects were reloaded.")
		end
	end

	net.Receive("EGP_Request_Transmit", function(len,ply)
		local amount = net.ReadUInt(16)
		local data = net.ReadData(amount)
		local tbl = WireLib.von.deserialize(util.Decompress(data, 60000))
		EGP:ReceiveDataStream(tbl)
	end)
end
