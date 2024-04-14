--------------------------------------------------------
-- EGP Queue System
--------------------------------------------------------
local EGP = E2Lib.EGP

EGP.Queue = WireLib.RegisterPlayerTable()

function EGP:AddQueueObject( Ent, ply, Function, Object )
	if not self.Queue[ply] then self.Queue[ply] = {} end
	local n = #self.Queue[ply]
	if (n > 0) then
		local LastItem = self.Queue[ply][n]
		if (LastItem.Ent == Ent and LastItem.Action == "Object") then
			for k,v in ipairs( LastItem.Args[1] ) do
				if v.index == Object.index and not v.remove then
					if (Object.remove) then -- The object has been removed
						LastItem.Args[1][k] = Object
					elseif (v.ID ~= Object.ID) then -- Not the same kind of object, create new
						if (v.OnRemove) then v:OnRemove() end
						local Obj = table.Copy(EGP.Objects[Object.ID])
						Obj:Initialize(Object:DataStreamInfo())
						Obj.index = v.index
						LastItem.Args[1][k] = Obj
					else -- Edit
						v:EditObject(Object:DataStreamInfo())
					end
					return
				end
			end
			-- Not found, add it to queue
			LastItem.Args[1][#LastItem.Args[1]+1] = Object
		else
			self:AddQueue( Ent, ply, Function, "Object", { Object } )
		end
	else
		self:AddQueue( Ent, ply, Function, "Object", { Object } )
	end
end

function EGP:AddQueue( Ent, ply, Function, Action, ... )
	if not self.Queue[ply] then self.Queue[ply] = {} end
	local n = #self.Queue[ply]
	if (n > 0) then
		local LastItem = self.Queue[ply][n]
		if (LastItem.Ent == Ent and LastItem.Action == Action) then -- Same item, no point in sending it again
			return
		end
	end
	self.Queue[ply][n+1] = { Action = Action, Function = Function, Ent = Ent, Args = {...} }
end

function EGP:InsertQueueObjects( Ent, ply, Function, Objects )
	if not self.Queue[ply] then self.Queue[ply] = {} end
	local n = #self.Queue[ply]
	if (n > 0) then
		local FirstItem = self.Queue[ply][1]
		if (FirstItem.Ent == Ent and FirstItem.Action == "Object") then
			local Args = FirstItem.Args
			for k,v in ipairs( Objects ) do
				table.insert( Args, v )
			end
		else
			self:InsertQueue( Ent, ply, Function, "Object", Objects )
		end
	else
		self:InsertQueue( Ent, ply, Function, "Object", Objects )
	end
end

function EGP:InsertQueue( Ent, ply, Function, Action, ... )
	if not self.Queue[ply] then self.Queue[ply] = {} end
	table.insert( self.Queue[ply], 1, { Action = Action, Function = Function, Ent = Ent, Args = {...} } )
end

function EGP:GetNextItem( ply )
	if not self.Queue[ply] then return false end
	if (#self.Queue[ply] <= 0) then return false end
	return table.remove( self.Queue[ply], 1 )
end

local AlreadyChecking = 0

function EGP:SendQueueItem( ply )
	local NextAction = self:GetNextItem( ply )
	if (NextAction ~= false) then
		local Func = NextAction.Function
		local Ent = NextAction.Ent
		local Args = NextAction.Args
		if (Args and #Args>0) then
			Func( Ent, ply, unpack(Args) )
		else
			Func( Ent, ply )
		end

		if (CurTime() ~= AlreadyChecking) then -- Had to use this hacky way of checking, because the E2 triggered 4 times for some strange reason. If anyone can figure out why, go ahead and tell me.
			AlreadyChecking = CurTime()

			-- Check if the queue has no more items for this screen
			local Items = self:GetQueueItemsForScreen( ply, Ent )
			if (Items and #Items == 0) then
				EGP.RunByEGPQueue = 1
				EGP.RunByEGPQueue_Ent = Ent
				EGP.RunByEGPQueue_ply = ply
				for k,v in ipairs( ents.FindByClass( "gmod_wire_expression2" ) ) do -- Find all E2s
					local context = v.context
					if (context) then
						local owner = context.player
						 -- Check if friends, whether or not the E2 is already executing, and if the E2 wants to be triggered by the queue system regarding the screen in question.
						if (E2Lib.isFriend( ply, owner ) and context.data and context.data.EGP and context.data.EGP.RunOnEGP and context.data.EGP.RunOnEGP[Ent] == true) then
							v:Execute()
						end
					end
				end
				EGP.RunByEGPQueue_ply = nil
				EGP.RunByEGPQueue_Ent = nil
				EGP.RunByEGPQueue = nil
			end
		end
	end
end

timer.Create("EGP_Queue_Process", 1, 0, function()
	local removetab = {}
	for ply, tab in pairs(EGP.Queue) do
		if IsValid(ply) then
			EGP:SendQueueItem(ply)
		else
			removetab[ply] = true
		end
	end
	for ply in pairs(removetab) do EGP.Queue[ply] = nil end
end)

function EGP:GetQueueItemsForScreen( ply, Ent )
	if not self.Queue[ply] then return {} end
	local ret = {}
	for k,v in ipairs( self.Queue[ply] ) do
		if (v.Ent == Ent) then
			table.insert( ret, v )
		end
	end
	return ret
end
