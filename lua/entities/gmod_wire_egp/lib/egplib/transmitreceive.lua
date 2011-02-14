--------------------------------------------------------
-- Queue Functions
--------------------------------------------------------
local EGP = EGP


if (SERVER) then
	umsg.PoolString( "EGP_Transmit_Data" ) -- Don't know if this helps, but I'll do it anyway just in case.

	----------------------------
	-- Umsgs per second check
	----------------------------
	EGP.IntervalCheck = {}

	function EGP:PlayerDisconnect( ply ) EGP.IntervalCheck[ply] = nil EGP.Queue[ply] = nil EGP:StopQueueTimer( ply ) end
	hook.Add("PlayerDisconnect","EGP_PlayerDisconnect",function( ply ) EGP:PlayerDisconnect( ply ) end)


	function EGP:CheckInterval( ply, bool )
		if (!self.IntervalCheck[ply]) then self.IntervalCheck[ply] = { umsgs = 0, time = 0 } end

		local maxcount = self.ConVars.MaxPerSec:GetInt()

		local tbl = self.IntervalCheck[ply]

		if (bool==true) then
			return (tbl.umsgs <= maxcount or tbl.time < CurTime())
		else
			if (tbl.time < CurTime()) then
				tbl.umsgs = 1
				tbl.time = CurTime() + 1
			else
				tbl.umsgs = tbl.umsgs + 1
				if (tbl.umsgs > maxcount) then
					return false
				end
			end

		end

		return true
	end

	----------------------------
	-- Queue functions
	----------------------------

	umsg.PoolString( "ClearScreen" )
	local function ClearScreen( Ent, ply )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueue( Ent, ply, ClearScreen, "ClearScreen" )
				return
			end
		else return end

		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "ClearScreen" )
		EGP.umsg.End()

		EGP:SendQueueItem( ply )
	end

	umsg.PoolString( "SaveFrame" )
	local function SaveFrame( Ent, ply, FrameName )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueue( Ent, ply, SaveFrame, "SaveFrame", FrameName )
				return
			end
		else return end

		umsg.PoolString( FrameName )
		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "SaveFrame" )
			EGP.umsg.Entity( ply )
			EGP.umsg.String( FrameName )
		EGP.umsg.End()

		EGP:SendQueueItem( ply )
	end

	umsg.PoolString( "LoadFrame" )
	local function LoadFrame( Ent, ply, FrameName )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueue( Ent, ply, LoadFrame, "LoadFrame", FrameName )
				return
			end
		else return end

		local bool, _ = EGP:LoadFrame( ply, Ent, FrameName )
		if (!bool) then return end

		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "LoadFrame" )
			EGP.umsg.Entity( ply )
			EGP.umsg.String( FrameName )
		EGP.umsg.End()

		EGP:SendQueueItem( ply )
	end

	-- Extra Add Poly queue item, used by poly objects with a lot of vertices in them
	umsg.PoolString( "AddVertex" )
	local function AddVertex( Ent, ply, index, vertices )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueue( Ent, ply, AddVertex, "AddVertex", index, vertices )
				return
			end
		else return end

		local bool, k, v = EGP:HasObject( Ent, index )
		if (bool) then
			if (!EGP.umsg.Start("EGP_Transmit_Data")) then return end
				EGP.umsg.Entity( Ent )
				EGP.umsg.String( "AddVertex" )
				EGP.umsg.Short( index )
				EGP.umsg.Char( #vertices )
				for i=1,#vertices do
					local vert = vertices[i]
					EGP.umsg.Short( vert.x )
					EGP.umsg.Short( vert.y )
					if (v.HasUV) then
						EGP.umsg.Short( (vert.u or 0) * 100 )
						EGP.umsg.Short( (vert.v or 0) * 100 )
					end
				end
			EGP.umsg.End()
		end

		EGP:SendQueueItem( ply )
	end

	-- Extra Set Poly queue item, used by poly objects with a lot of vertices in them
	umsg.PoolString( "SetVertex" )
	function EGP._SetVertex( Ent, ply, index, vertices, skiptoadd )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueue( Ent, ply, EGP._SetVertex, "SetVertex", index, vertices, skiptoadd )
				return
			end
		else return end

		local bool, k, v = EGP:HasObject( Ent, index )
		if (bool) then
			local limit = 60
			if (v.HasUV) then limit = 30 end
			if (#vertices > limit or skiptoadd == true) then
				local DataToSend = {}
				local temp = {}
				for i=1,#vertices do
					temp[#temp+1] = vertices[i]
					if (#temp >= limit) then
						table.insert( DataToSend, 1, {index, table.Copy(temp)} )
						temp = {}
					end
				end
				if (#temp > 0) then
					table.insert( DataToSend, 1, {index, table.Copy(temp)} )
				end

				-- This step is required because otherwise it adds the vertices backwards to the queue.
				for i=1,#DataToSend do
					EGP:InsertQueue( Ent, ply, AddVertex, "AddVertex", unpack(DataToSend[i]) )
				end
			else
				if (!EGP.umsg.Start("EGP_Transmit_Data")) then return end
					EGP.umsg.Entity( Ent )
					EGP.umsg.String( "SetVertex" )
					EGP.umsg.Short( index )
					EGP.umsg.Char( #vertices )
					for i=1,#vertices do
						local vert = vertices[i]
						EGP.umsg.Short( vert.x )
						EGP.umsg.Short( vert.y )
						if (v.HasUV) then
							EGP.umsg.Short( (vert.u or 0) * 100 )
							EGP.umsg.Short( (vert.v or 0) * 100 )
						end
					end
				EGP.umsg.End()
			end
		end

		EGP:SendQueueItem( ply )
	end

	-- Extra Add Text queue item, used by text objects with a lot of text in them
	umsg.PoolString( "AddText" )
	local function AddText( Ent, ply, index, text )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueue( Ent, ply, AddText, "AddText", index, text )
				return
			end
		else return end

		local bool, k, v = EGP:HasObject( Ent, index )
		if (bool) then
			if (!EGP.umsg.Start("EGP_Transmit_Data")) then return end
				EGP.umsg.Entity( Ent )
				EGP.umsg.String( "AddText" )
				EGP.umsg.Short( index )
				EGP.umsg.String( text )
			EGP.umsg.End()
		end

		EGP:SendQueueItem( ply )
	end

	-- Extra Set Text queue item, used by text objects with a lot of text in them
	umsg.PoolString( "SetText" )
	function EGP._SetText( Ent, ply, index, text )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueue( Ent, ply, EGP._SetText, "SetText", index, text )
				return
			end
		else return end

		local bool, k, v = EGP:HasObject( Ent, index )
		if (bool) then
			if (#text > 220) then
				local DataToSend = {}
				local temp = ""
				for i=1,#text do
					temp = temp .. text:sub(i,i)
					if (#temp >= 220) then
						table.insert( DataToSend, 1, {index, temp} )
						temp = ""
					end
				end
				if (temp != "") then
					table.insert( DataToSend, 1, {index, temp} )
				end

				-- This step is required because otherwise it adds the strings backwards to the queue.
				for i=1,#DataToSend do
					EGP:InsertQueue( Ent, ply, AddText, "AddText", unpack(DataToSend[i]) )
				end
			else
				if (!EGP.umsg.Start("EGP_Transmit_Data")) then return end
					EGP.umsg.Entity( Ent )
					EGP.umsg.String( "SetText" )
					EGP.umsg.Short( index )
					EGP.umsg.String( text )
				EGP.umsg.End()
			end
		end

		EGP:SendQueueItem( ply )
	end

	local function removetbl( tbl, Ent )
		for k,v in ipairs( tbl ) do
			if (Ent.RenderTable[v]) then

				-- Unparent all objects parented to this object
				for k2,v2 in pairs( Ent.RenderTable ) do
					if (v2.parent and Ent.RenderTable[v].index and v2.parent == Ent.RenderTable[v].index) then
						EGP:UnParent( Ent, v2 )
					end
				end

				table.remove( Ent.RenderTable, v )
			end
		end
	end

	local function SetScale( ent, ply, x, y )
		EGP:SetScale( ent, x, y )
		EGP:SendQueueItem( ply )
	end

	local function MoveTopLeft( ent, ply, bool )
		ent.TopLeft = bool
		EGP:SendQueueItem( ply )
	end

	umsg.PoolString( "ReceiveObjects" )
	local function SendObjects( Ent, ply, DataToSend )
		if (!Ent or !Ent:IsValid() or !ply or !ply:IsValid() or !DataToSend) then return end

		local Done = 0

		-- Check duped
		if (Ent.EGP_Duplicated) then
			EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
			return
		end

		-- Check interval
		if (ply:IsValid() and ply:IsPlayer()) then
			if (EGP:CheckInterval( ply ) == false) then
				EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
				return
			end
		else return end

		local removetable = {}

		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "ReceiveObjects" )

			EGP.umsg.Short( #DataToSend ) -- Send estimated number of objects to be sent
			for k,v in ipairs( DataToSend ) do

				-- Check if the object doesn't exist serverside anymore (It may have been removed by a command in the queue before this, like egpClear or egpRemove)
				--if (!EGP:HasObject( Ent, v.index )) then
				--	EGP:CreateObject( Ent, v.ID, v )
				--end

				EGP.umsg.Short( v.index ) -- Send index of object

				if (v.remove == true) then
					EGP.umsg.Char( -128 ) -- Object is to be removed, send a 0
					if (Ent.RenderTable[k]) then
						removetable[#removetable+1] = k
					end
				else
					EGP.umsg.Char( v.ID - 128 ) -- Else send the ID of the object

					if (Ent.Scaling or Ent.TopLeft) then
						v = table.Copy(v) -- Make a copy of the table so it doesn't overwrite the serverside object
					end

					-- Scale the positions and size
					if (Ent.Scaling) then
						EGP:ScaleObject( Ent, v )
					end

					-- Move the object to draw from the top left
					if (Ent.TopLeft) then
						EGP:MoveTopLeft( Ent, v )
					end

					if (v.ChangeOrder) then -- We want to change the order of this object, send the index to where we wish to move it
						local from = v.ChangeOrder[1]
						local to = v.ChangeOrder[2]
						if (Ent.RenderTable[to]) then
							Ent.RenderTable[to].ChangeOrder = nil
						end
						EGP.umsg.Short( from )
						EGP.umsg.Short( to )
					else
						EGP.umsg.Short( 0 ) -- Don't change order
					end

					v:Transmit( Ent, ply )
				end

				Done = Done + 1
				if (EGP.umsg.CurrentCost() > 200) then -- Getting close to the max size! Start over
					if (Done == 1 and EGP.umsg.CurrentCost() > 256) then -- The object was too big
						ErrorNoHalt("[EGP] Umsg error. An object was too big to send!")
						--table.remove( DataToSend, 1 )
					end
					EGP.umsg.End()
					for i=1,Done do table.remove( DataToSend, 1 ) end
					removetbl( removetable, Ent )
					EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
					EGP:SendQueueItem( ply )
					return
				end
			end
		EGP.umsg.End()

		removetbl( removetable, Ent )

		EGP:SendQueueItem( ply )
	end

	----------------------------
	-- DoAction
	----------------------------

	function EGP:DoAction( Ent, E2, Action, ... )
		if (Action == "SendObject") then
			local Data = {...}
			if (!Data[1]) then return end

			if (E1 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end

			self:AddQueueObject( Ent, E2.player, SendObjects, Data[1] )
		elseif (Action == "RemoveObject") then
			local Data = {...}
			if (!Data[1]) then return end

			if (E1 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end

			self:AddQueueObject( Ent, E2.player, SendObjects, { index = Data[1], remove = true } )
		elseif (Action == "ClearScreen") then
			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end

			Ent.RenderTable = {}

			self:AddQueue( Ent, E2.player, ClearScreen, "ClearScreen" )
		elseif (Action == "SaveFrame") then
			local Data = {...}
			if (!Data[1]) then return end

			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end

			EGP:SaveFrame( E2.player, Ent, Data[1] )
			self:AddQueue( Ent, E2.player, SaveFrame, "SaveFrame", Data[1] )
		elseif (Action == "LoadFrame") then
			local Data = {...}
			if (!Data[1]) then return end

			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
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
		end
	end
else -- SERVER/CLIENT
	function EGP:Receive( um )
		local Ent = um:ReadEntity()
		if (!self:ValidEGP( Ent ) or !Ent.RenderTable) then return end

		local Action = um:ReadString()
		if (Action == "ClearScreen") then
			Ent.RenderTable = {}
			Ent:EGP_Update()
		elseif (Action == "SaveFrame") then
			local ply = um:ReadEntity()
			local FrameName = um:ReadString()
			EGP:SaveFrame( ply, Ent, FrameName )
		elseif (Action == "LoadFrame") then
			local ply = um:ReadEntity()
			local FrameName = um:ReadString()
			EGP:LoadFrame( ply, Ent, FrameName )
			Ent:EGP_Update()
		elseif (Action == "SetText") then
			local index = um:ReadShort()
			local text = um:ReadString()
			local bool,k,v = EGP:HasObject( Ent, index )
			if (bool) then
				if (EGP:EditObject( v, { text = text } )) then Ent:EGP_Update() end
			end
		elseif (Action == "AddText") then
			local index = um:ReadShort()
			local text = um:ReadString()
			local bool,k,v = EGP:HasObject( Ent, index )
			if (bool) then
				if (EGP:EditObject( v, { text = v.text .. text } )) then Ent:EGP_Update() end
			end
		elseif (Action == "SetVertex") then
			local index = um:ReadShort()
			local bool, k,v = EGP:HasObject( Ent, index )
			if (bool) then
				local vertices = {}

				if (v.HasUV) then
					local n = 0
					for i=1,um:ReadShort() do
						local x, y, u, _v = um:ReadShort(), um:ReadShort(), um:ReadShort() / 100, um:ReadShort() / 100
						vertices[i] = { x=x, y=y, u=u, v=_v }
					end
				else
					local n = 0
					for i=1,um:ReadShort() do
						local x, y = um:ReadShort(), um:ReadShort()
						vertices[i] = { x=x, y=y }
					end
				end

				if (EGP:EditObject( v, { vertices = vertices })) then Ent:EGP_Update() end
			end
		elseif (Action == "AddVertex") then
			local index = um:ReadShort()
			local bool, k, v = EGP:HasObject( Ent, index )
			if (bool) then
				local vertices = table.Copy(v.vertices)

				if (v.HasUV) then
					local n = 0
					for i=1,um:ReadChar() do
						local x, y, u, _v = um:ReadShort(), um:ReadShort(), um:ReadShort() / 100, um:ReadShort() / 100
						vertices[#vertices+1] = { x=x, y=y, u=u, v=_v }
					end
				else
					local n = 0
					for i=1,um:ReadChar() do
						local x, y = um:ReadShort(), um:ReadShort()
						vertices[#vertices+1] = { x=x, y=y }
					end
				end

				if (EGP:EditObject( v, { vertices = vertices })) then Ent:EGP_Update() end
			end
		elseif (Action == "ReceiveObjects") then
			local Nr = um:ReadShort() -- Estimated amount
			for i=1,Nr do
				local index = um:ReadShort()
				if (index == 0) then break end -- In case the umsg had to abort early

				local ID = um:ReadChar()

				if (ID == -128) then -- Remove object
					local bool, k, v = EGP:HasObject( Ent, index )
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
					local ChangeOrder_From = um:ReadShort()
					local ChangeOrder_To
					if (ChangeOrder_From != 0) then
						ChangeOrder_To = um:ReadShort()
					end

					ID = ID + 128
					local bool, k, v = self:HasObject( Ent, index )
					if (bool) then -- Object already exists
						if (v.ID != ID) then -- Not the same kind of object, create new
							if (v.OnRemove) then v:OnRemove() end
							local Obj = self:GetObjectByID( ID )
							local data = Obj:Receive( um )
							self:EditObject( Obj, data )
							Obj.index = index
							Ent.RenderTable[k] = Obj
							if (Obj.OnCreate) then Obj:OnCreate() end

							-- For EGP HUD
							if (Obj.res) then Obj.res = nil end
						else -- Edit
							self:EditObject( v, v:Receive( um ) )

							-- If parented, reset the parent indexes
							if (v.parent and v.parent != 0) then
								EGP:AddParentIndexes( v )
							end

							-- For EGP HUD
							if (v.res) then v.res = nil end
						end
					else -- Object does not exist. Create new
						local Obj = self:GetObjectByID( ID )
						self:EditObject( Obj, Obj:Receive( um ) )
						Obj.index = index
						if (Obj.OnCreate) then Obj:OnCreate() end
						Ent.RenderTable[#Ent.RenderTable+1] = Obj--table.insert( Ent.RenderTable, Obj )
					end

					-- Change Order
					if (ChangeOrder_From and ChangeOrder_To) then
						local b = self:SetOrder( Ent, ChangeOrder_From, ChangeOrder_To )
					end
				end
			end

			Ent:EGP_Update()
		end
	end
	usermessage.Hook( "EGP_Transmit_Data", function(um) EGP:Receive( um ) end )

end

require("datastream")

if (SERVER) then

	EGP.DataStream = {}

	concommand.Add("EGP_Request_Reload",function(ply,cmd,args)
		if (!EGP.DataStream[ply]) then EGP.DataStream[ply] = {} end
		local tbl = EGP.DataStream[ply]
		if (!tbl.SingleTime) then tbl.SingleTime = 0 end
		if (!tbl.AllTime) then tbl.AllTime = 0 end
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

	function EGP:SendDataStream( ply, entid )
		if (!ply or !ply:IsValid()) then return false, "ERROR: Invalid ply." end
		local targets
		if (entid) then
			local tempent = Entity(entid)
			if (self:ValidEGP( tempent )) then
				targets = { tempent }
			else
				return false, "ERROR: Invalid screen."
			end
		end
		if (!targets) then
			targets = ents.FindByClass("gmod_wire_egp")
			table.Add( targets, ents.FindByClass("gmod_wire_egp_hud") )
			table.Add( targets, ents.FindByClass("gmod_wire_egp_emitter") )

			if (#targets == 0) then return false, "There are no EGP screens on the map." end
		end

		local DataToSend = {}
		for k,v in ipairs( targets ) do
			if (v.RenderTable and #v.RenderTable>0) then
				local DataToSend2 = {}
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
						EGP:MoveTopLeft( v, obj )
					end

					DataToSend2[#DataToSend2+1] = { ID = obj.ID, index = obj.index, Settings = obj:DataStreamInfo() }
				end
				DataToSend[#DataToSend+1] = { Ent = v, Objects = DataToSend2 }
			end
		end
		if (DataToSend and #DataToSend>0) then
			datastream.StreamToClients( ply, "EGP_Request_Transmit", DataToSend )
			return true, #DataToSend
		end
		return false, "None of the screens have any objects drawn on them."
	end

	local function initspawn(ply)
		timer.Simple(10,function(ply)
			if (ply and ply:IsValid()) then
				local bool, msg = EGP:SendDataStream( ply )
				if (bool == true) then
					ply:ChatPrint("[EGP] " .. tostring(msg) .. " EGP Screens found on the server. Sending objects now...")
				end
			end
		end,ply)
	end

	hook.Add("PlayerInitialSpawn","EGP_SpawnFunc",initspawn)
else

	function EGP:ReceiveDataStream( decoded )
		for k,v in pairs( decoded ) do
			local Ent = v.Ent
			if (self:ValidEGP( Ent )) then
				Ent.RenderTable = {}
				for k2,v2 in pairs( v.Objects ) do
					local Obj = self:GetObjectByID(v2.ID)
					self:EditObject( Obj, v2.Settings )
					-- If parented, reset the parent indexes
					if (Obj.parent and Obj.parent != 0) then
						self:AddParentIndexes( Obj )
					end
					Obj.index = v2.index
					table.insert( Ent.RenderTable, Obj )
				end
				Ent:EGP_Update()
			end
		end
		LocalPlayer():ChatPrint("[EGP] Received EGP object reload. " .. #decoded .. " screens' objects were reloaded.")
	end
	datastream.Hook("EGP_Request_Transmit", function(_,_,_,decoded) EGP:ReceiveDataStream( decoded ) end )

end
