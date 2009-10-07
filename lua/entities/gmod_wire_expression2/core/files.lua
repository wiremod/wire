--------------------------------------------------------------------------------
--                    File extension by {iG} I_am_McLovin                     --
--------------------------------------------------------------------------------

if not datastream then require( "datastream" ) end

local uploaded_files = {}
local uploads = {}
local run_on_load = { 0, "" }

/******************************** File loading ********************************/

e2function void fileLoad(string filename)
	if timer.IsTimer( "file_load_delay" .. self.player:EntIndex() ) or ( uploaded_files[self.player] and ( uploaded_files[self.player].amt > 100 or ( uploaded_files[self.player][filename] and uploaded_files[self.player][filename].uploaded and uploaded_files[self.player][filename].uploaded == true ) ) ) then return end

	uploaded_files[self.player][filename] = {
		uploaded = false,
		data = "",
		ent = self.entity
	}

	umsg.Start( "wire_expression2_fileload", self.player )
		umsg.String( filename )
	umsg.End()

	-- TODO: replace by an entry in a local table.
	timer.Create( "file_load_delay"..self.player:EntIndex(), 10, 1, function( ply )
		timer.Remove( "file_load_delay" .. ply:EntIndex() )
	end, self.player )
end

e2function number fileLoaded(string filename)
	if uploaded_files[self.player] and uploaded_files[self.player][filename] and uploaded_files[self.player][filename].uploaded == true then
		return 1
	end

	return 0
end

e2function number fileCanLoad()
	if timer.IsTimer( "file_load_delay" .. self.player:EntIndex() ) then
		return 0
	end

	return 1
end

/**************************** File reading/writing ****************************/

e2function string fileRead(string filename)
	if uploaded_files[self.player] and uploaded_files[self.player][filename] and uploaded_files[self.player][filename].uploaded == true then
		return uploaded_files[self.player][filename].data
	else
		return ""
	end
end

e2function void fileWrite(string filename, string data)

	if uploaded_files[self.player] and uploaded_files[self.player].amt <= 100 then
		uploaded_files[self.player][filename] = {}
		uploaded_files[self.player][filename].uploaded = true
		uploaded_files[self.player][filename].data = data
		uploaded_files[self.player][filename].ent = self.entity
	end

	datastream.StreamToClients( self.player, "wire_expression2_filewrite", { ["name"] = filename, ["data"] = data, ["append"] = false } )
end

e2function void fileAppend(string filename, string data)

	if uploaded_files[self.player] and uploaded_files[self.player].amt <= 100 then
		local old_file = ""

		if uploaded_files[self.player][filename] and uploaded_files[self.player][filename].uploaded == true then
			old_file = uploaded_files[self.player][filename].data
		end

		uploaded_files[self.player][filename] = {}
		uploaded_files[self.player][filename].uploaded = true
		uploaded_files[self.player][filename].data = old_file .. data
		uploaded_files[self.player][filename].ent = self.entity
	end

	datastream.StreamToClients( self.player, "wire_expression2_filewrite", { ["name"] = filename, ["data"] = data, ["append"] = true } )
end

e2function void fileRemove(string filename)

	if uploaded_files[self.player] and uploaded_files[self.player][filename] then
		uploaded_files[self.player][filename] = nil
		uploaded_files[self.player].amt = uploaded_files[self.player].amt - 1
	end
end

/****************************** runOnFile event *******************************/

e2function void runOnFile(active)

	if active == 1 then
		uploads[self.entity] = true
	else
		uploads[self.entity] = nil
	end
end

e2function number fileClk()
	return run_on_load[1]
end

e2function number fileClk(string filename)

	if run_on_load[1] == 1 and run_on_load[2] == filename then
		return 1
	else
		return 0
	end
end

/******************************** Hooks'n'shit ********************************/

registerCallback( "construct", function( self )
	if !uploaded_files[self.player] then
		uploaded_files[self.player] = {}
		uploaded_files[self.player].amt = 0
	end
end )

hook.Add( "EntityRemoved", "wire_expression2_filedata_delete", function( ply )
	uploaded_files[ply] = nil
end )

hook.Add( "AcceptStream", "wire_expression2_filedata", function( ply, handler, id )
	if handler == "wire_expression2_filedata" then return true end
end )

datastream.Hook( "wire_expression2_filedata", function( ply, handler, id, encoded, decoded )
	if not decoded.filename then return end
	if not decoded.filedata then return end

	local plfiles = uploaded_files[ply]
	if not plfiles then return end

	local fileentry = plfiles[decoded.filename]
	if not fileentry then return end


	fileentry.uploaded = true
	fileentry.data = decoded.filedata
	plfiles.amt = plfiles.amt + 1

	run_on_load[1] = 1
	run_on_load[2] = decoded.filename

	for e,_ in pairs( uploads ) do
		if fileentry.ent == e then
			e:Execute()
			break
		end
	end

	run_on_load[1] = 0
	run_on_load[2] = ""
end )
