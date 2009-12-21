--------------------------------------------------------------------------------
--                    File extension by {iG} I_am_McLovin                     --
--------------------------------------------------------------------------------

E2Lib.RegisterExtension("file", true)

if not datastream then require( "datastream" ) end

local uploaded = {
	files = {},
	lists = {}
}

local run_on = {
	file = {
		run = 0,
		name = "",
		ents = {}
	},
	list = {
		run = 0,
		ents = {}
	}
}

/******************************** File loading ********************************/

e2function void fileLoad(string filename)

	local pl_files = uploaded.files[self.player]

	if !timer.IsTimer( "wire_expression2_file_delay_" .. self.player:EntIndex() ) and ( pl_files and ( pl_files.amt > 100 or ( uploaded.files[self.player][filename] and pl_files[filename].uploaded ) ) ) then return end

	pl_files[filename] = {
		uploaded = false,
		data = "",
		ent = self.entity
	}

	umsg.Start( "wire_expression2_fileload", self.player )
		umsg.String( filename )
	umsg.End()

	timer.Create( "wire_expression2_file_delay_" .. self.player:EntIndex(), 1, 5, function( ply )
		timer.Remove( "wire_expression2_file_delay_" .. ply:EntIndex() )
	end, self.player )

end

e2function number fileLoaded(string filename)

	local pl_files = uploaded.files[self.player]

	if pl_files and pl_files[filename] and pl_files[filename].uploaded == true then
		return 1
	end

	return 0

end

e2function number fileCanLoad()

	if !timer.IsTimer( "wire_expression2_file_delay_" .. self.player:EntIndex() ) then
		return 1
	end

	return 0

end

/**************************** File reading/writing ****************************/

e2function string fileRead(string filename)

	local pl_files = uploaded.files[self.player]

	if pl_files and pl_files[filename] and pl_files[filename].uploaded == true then
		return pl_files[filename].data
	end

	return ""

end

e2function void fileWrite(string filename, string data)

	local pl_files = uploaded.files[self.player]

	if pl_files and pl_files.amt < 100 then
		pl_files[filename] = {
			uploaded = true,
			data = data,
			ent = self.entity
		}
	end

	datastream.StreamToClients( self.player, "wire_expression2_filewrite", { ["name"] = filename, ["data"] = data, ["append"] = false } )

end

e2function void fileAppend(string filename, string data)

	local pl_files = uploaded.files[self.player]

	if pl_files and pl_files.amt <= 100 then
		local old_file = ""

		if pl_files[filename] and pl_files[filename].uploaded == true then
			old_file = pl_files[filename].data
		end

		pl_files[filename] = {
			uploaded = true,
			data = old_file .. data,
			ent = self.entity
		}
	end

	datastream.StreamToClients( self.player, "wire_expression2_filewrite", { ["name"] = filename, ["data"] = data, ["append"] = true } )

end

e2function void fileRemove(string filename)

	local pl_files = uploaded.files[self.player]

	if pl_files and pl_files[filename] then
		pl_files[filename] = nil
		pl_files.amt = pl_files.amt - 1
	end
end


/**************************** File lists ****************************/

e2function void fileLoadList()

	uploaded.lists[self.player] = { ent = self.entity }

	umsg.Start( "wire_expression2_filerequestlist", self.player )
	umsg.End()

end

e2function number fileListLoaded()

	if uploaded.lists[self.player] and uploaded.lists[self.player].loaded then
		uploaded.lists[self.player].loaded = false
		return 1
	end

	return 0

end

e2function table fileListTable()

	if !uploaded.lists[self.player] or !uploaded.lists[self.player].list then return end

	local tbl = {}

	for _,v in pairs( uploaded.lists[self.player].list ) do
		tbl[v] = v
	end

	return tbl

end

e2function array fileList()

	if !uploaded.lists[self.player] or !uploaded.lists[self.player].list then return end

	return uploaded.lists[self.player].list

end

/****************************** runOnFile event *******************************/

e2function void runOnFile(active)

	if active == 1 then
		run_on.file.ents[self.entity] = true
	else
		run_on.file.ents[self.entity] = nil
	end

end

e2function number fileClk()

	return run_on.file.run

end

e2function number fileClk(string filename)

	if run_on.file.run == 1 and run_on.file.name == filename then
		return 1
	else
		return 0
	end

end

/****************************** runOnList event *******************************/

e2function void runOnList(active)

	if active == 1 then
		run_on.list.ents[self.entity] = true
	else
		run_on.list.ents[self.entity] = nil
	end

end

e2function number fileListClk()
	return run_on.list.run
end

/******************************** Hooks'n'shit ********************************/

local function e2_loop_execute( tbl, ent )

	for e,_ in pairs( tbl ) do
		if ent == e then
			e:Execute()
			break
		end
	end

end

registerCallback( "construct", function( self )

	if !uploaded.files[self.player] then
		uploaded.files[self.player] = { amt = 0 }
		uploaded.lists[self.player] = {}
	end

end )

hook.Add( "EntityRemoved", "wire_expression2_filedata_delete", function( ply )

	if ply and ply:IsPlayer() and ( uploaded.files[ply] or uploaded.lists[ply] ) then
		uploaded.files[ply] = nil
		uploaded.lists[ply] = nil
	end

end )

hook.Add( "AcceptStream", "wire_expression2_filedata", function( ply, handler, id )
	if handler == "wire_expression2_filedata" or handler == "wire_expression2_filelist" then return true end
end )

datastream.Hook( "wire_expression2_filedata", function( ply, handler, id, encoded, decoded )

	if not decoded.filename then return end
	if not decoded.filedata then return end

	local plfiles = uploaded.files[ply]
	if not plfiles then return end

	local fileentry = plfiles[decoded.filename]
	if not fileentry then return end

	fileentry.uploaded = true
	fileentry.data = decoded.filedata

	plfiles.amt = plfiles.amt + 1

	run_on.file.run = 1
	run_on.file.name = decoded.filename

	e2_loop_execute( run_on.file.ents, fileentry.ent )

	run_on.file.run = 0
	run_on.file.name = ""

end )

datastream.Hook( "wire_expression2_filelist", function( ply, handler, id, encoded, decoded )

	if not decoded then return end

	uploaded.lists[ply].loaded = true
	uploaded.lists[ply].list = decoded

	run_on.list.run = 1

	e2_loop_execute( run_on.list.ents, uploaded.lists[ply].ent )

	run_on.list.run = 0

end )
