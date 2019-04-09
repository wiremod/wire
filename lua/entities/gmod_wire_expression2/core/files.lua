--[[
	File Extension
	By: Dan (McLovin)
]]--

local cv_transfer_delay    = CreateConVar( "wire_expression2_file_delay", "5", { FCVAR_ARCHIVE } )
local cv_max_transfer_size = CreateConVar( "wire_expression2_file_max_size", "300", { FCVAR_REPLICATED, FCVAR_ARCHIVE } ) -- in kib

local download_chunk_size = 20000 -- Our overhead is pretty small so lets send it in moderate sized pieces, no need to max out the buffer

E2Lib.RegisterExtension( "file", true, "Allows reading and writing of files in the player's local data directory." )

local FILE_UNKNOWN = 0
local FILE_OK = 1
local FILE_TIMEOUT = 2
local FILE_404 = 3
local FILE_TRANSFER_ERROR = 4

E2Lib.registerConstant( "FILE_UNKNOWN", FILE_UNKNOWN )
E2Lib.registerConstant( "FILE_OK", FILE_OK )
E2Lib.registerConstant( "FILE_TIMEOUT", FILE_TIMEOUT )
E2Lib.registerConstant( "FILE_404", FILE_404 )
E2Lib.registerConstant( "FILE_TRANSFER_ERROR", FILE_TRANSFER_ERROR )

local delays = {}
local uploads = {}
local downloads = {}
local lists = {}
local run_on = {
	file = {
		run = 0,
		name = "",
		ents = {},
		status = FILE_UNKNOWN
	},
	list = {
		run = 0,
		dir = "",
		ents = {}
	}
}

local function file_canUpload( ply )
	local pfile = uploads[ply]
	local pdel = (delays[ply] or {}).upload

	if (pfile and (pfile.uploading or pfile.sp_wait)) or
		(pdel and not ply:IsListenServerHost() and (CurTime() - pdel) < cv_transfer_delay:GetInt()) then return false end

	return true
end

util.AddNetworkString("wire_expression2_request_file_sp")
util.AddNetworkString("wire_expression2_request_file")
local function file_Upload( ply, entity, filename )
	if !file_canUpload( ply ) or !IsValid( entity ) or !IsValid( ply ) or !ply:IsPlayer() or string.Right( filename, 4 ) != ".txt" then return false end

	uploads[ply] = {
		name = filename,
		uploading = false, --don't halt other uploads incase file does not exist
		uploaded = false,
		data = "",
		ent = entity,
		sp_wait = ply:IsListenServerHost()
	}
	net.Start(uploads[ply].sp_wait and "wire_expression2_request_file_sp" or "wire_expression2_request_file")
		net.WriteString( filename )
	net.Send(ply)

	delays[ply].upload = CurTime()
end


local function file_canDownload( ply )
	local pfile = downloads[ply]
	local pdel = (delays[ply] or {}).download

	if (pfile and pfile.downloading) or
		(pdel and (CurTime() - pdel) < cv_transfer_delay:GetInt()) then return false end

	return true
end

local function file_Download( ply, filename, data, append )
	if !file_canDownload( ply ) or !IsValid( ply ) or !ply:IsPlayer() or string.Right( filename, 4 ) != ".txt" then return false end
	if string.len( data ) > (cv_max_transfer_size:GetInt() * 1024) then return false end

	-- if we're trying to append an empty string then we don't need to queue up
	-- a download to consider the operation completed
	if append and string.len(data) == 0 then return true end

	downloads[ply] = {
		name = filename,
		data = data,
		started = false,
		downloading = true,
		downloaded = false,
		append = append
	}
end


local function file_canList( ply )
	local plist = lists[ply]
	local pdel = (delays[ply] or {}).list

	if (plist and plist.uploading) or
		(pdel and (CurTime() - pdel) < cv_transfer_delay:GetInt()) then return false end

	return true
end

util.AddNetworkString("wire_expression2_request_list")
local function file_List( ply, entity, dir )
	if !file_canList( ply ) or !IsValid( ply ) or !ply:IsPlayer() then return false end

	lists[ply] = {
		dir = dir,
		data = {},
		uploading = true,
		uploaded = false,
		ent = entity
	}
	net.Start("wire_expression2_request_list")
		net.WriteString( dir or "" )
	net.Send(ply)

	delays[ply].list = CurTime()
end

--- File loading ---

__e2setcost( 20 )

e2function void fileLoad( string filename )
	file_Upload( self.player, self.entity, filename )
end

__e2setcost( 5 )

e2function number fileCanLoad()
	return file_canUpload( self.player ) and 1 or 0
end

e2function number fileLoaded()
	local pfile = uploads[self.player]

	return (!pfile.uploading and pfile.uploaded) and 1 or 0
end

e2function number fileLoading()
	local pfile = uploads[self.player]

	return pfile.uploading and 1 or 0
end

e2function number fileStatus()
	return run_on.file.status or FILE_UNKNOWN
end

--- File reading/writing ---

e2function string fileName()
	local pfile = uploads[self.player]

	if pfile.uploaded and !pfile.uploading then
		return pfile.name
	end

	return ""
end

__e2setcost( 10 )

e2function string fileRead()
	local pfile = uploads[self.player]

	return (pfile.uploaded and !pfile.uploading) and pfile.data or ""
end

__e2setcost( 5 )

e2function number fileMaxSize()
	return cv_max_transfer_size:GetInt()
end

e2function number fileCanWrite()
	return file_canDownload( self.player ) and 1 or 0
end

__e2setcost( 20 )

e2function void fileWrite( string filename, string data )
	file_Download( self.player, filename, data, false )
end

e2function void fileAppend( string filename, string data )
	file_Download( self.player, filename, data, true )
end

--- File Listing ---

__e2setcost( 20 )

e2function void fileList( string dir )
	file_List( self.player, self.entity, dir )
end

__e2setcost( 5 )

e2function number fileCanList()
	return file_canList( self.player ) and 1 or 0
end

e2function number fileLoadedList()
	local plist = lists[self.player]

	return (!plist.uploading and plist.uploaded) and 1 or 0
end

e2function number fileLoadingList()
	local plist = lists[self.player]

	return plist.uploading and 1 or 0
end

e2function array fileReadList()
	local plist = lists[self.player]

	return (plist.uploaded and !plist.uploading and plist.data) and plist.data or {}
end

--- runOnFile event ---

__e2setcost( 5 )

e2function void runOnFile( active )
	run_on.file.ents[self.entity] = (active != 0)
end

e2function number fileClk()
	return self.data.runOnFile and 1 or 0
end

e2function number fileClk( string filename )
	return (self.data.runOnFile and run_on.file.name == filename) and 1 or 0
end

-- runOnList event ---

__e2setcost( 5 )

e2function void runOnList( active )
	run_on.list.ents[self.entity] = (active != 0)
end

e2function number fileListClk()
	return self.data.runOnFileList and 1 or 0
end

e2function number fileListClk( string dir )
	return (self.data.runOnFileList and run_on.list.dir == dir) and 1 or 0
end

--- Hooks 'n' Shit ---

registerCallback( "construct", function( self )
	uploads[self.player] = uploads[self.player] or {
		uploading = false,
		uploaded = false
	}
	downloads[self.player] = downloads[self.player] or {
		downloading = false,
		downloaded = false
	}
	lists[self.player] = lists[self.player] or {
		uploading = false,
		uploaded = false
	}
	delays[self.player] = delays[self.player] or {
		upload = 0,
		download = 0,
		list = 0
	}
end )

--- Downloading ---
util.AddNetworkString("wire_expression2_file_download_begin")
util.AddNetworkString("wire_expression2_file_download_chunk")
util.AddNetworkString("wire_expresison2_file_download_finish")
timer.Create("wire_expression2_flush_file_buffer", 0.2, 0, function()
	for ply,fdata in pairs( downloads ) do
		if IsValid( ply ) and ply:IsPlayer() and fdata.downloading then
			if !fdata.started then
				net.Start("wire_expression2_file_download_begin")
					net.WriteString(fdata.name or "")
				net.Send(ply)

				fdata.started = true
			end

			local strlen = math.Clamp( string.len( fdata.data ), 0, download_chunk_size )

			if strlen > 0 then
				net.Start("wire_expression2_file_download_chunk")
				net.WriteUInt(strlen, 32)
				net.WriteData(fdata.data, strlen)
				net.Send(ply)

				fdata.data = string.sub( fdata.data, strlen + 1 )
			end

			if string.len( fdata.data ) < 1 then
				net.Start("wire_expresison2_file_download_finish")
					net.WriteBit(fdata.append or false)
				net.Send(ply)

				fdata.downloaded = true
				fdata.downloading = false
			end
		end
	end
end)

--- Uploading ---

local function file_execute( ent, filename, status )
	if !IsValid( ent ) or !run_on.file.ents[ent] then return end

	run_on.file.run = 1
	run_on.file.name = filename
	run_on.file.status = status

	ent.context.data.runOnFile = true
	ent:Execute()
	ent.context.data.runOnFile = nil

	run_on.file.run = 0
	run_on.file.name = ""
	run_on.file.status = FILE_UNKNOWN
end

util.AddNetworkString("wire_expression2_file_begin")
net.Receive("wire_expression2_file_begin", function(netlen, ply)
	local pfile = uploads[ply]
	if !pfile then return end

	local len = net.ReadUInt(32)

	if len == 0 then -- file not found
		file_execute( pfile.ent, pfile.name, FILE_404 )
		return
	end
	if (len / 1024) > cv_max_transfer_size:GetInt() then return end

	pfile.buffer = ""
	pfile.len = len
	pfile.uploading = true
	pfile.uploaded = false

	timer.Create( "wire_expression2_file_check_timeout_" .. ply:EntIndex(), 5, 1, function()
		local pfile = uploads[ply]
		if !pfile then return end
		pfile.uploading = false
		pfile.uploaded = false
		file_execute( pfile.ent, pfile.name, FILE_TIMEOUT )
	end)
end )

util.AddNetworkString("wire_expression2_file_chunk")
net.Receive("wire_expression2_file_chunk", function(netlen, ply)
	local pfile = uploads[ply]
	if !pfile or !pfile.buffer then return end
	if !pfile.uploading then
		file_execute( pfile.ent, pfile.name, FILE_TRANSFER_ERROR )
	end

	local len = net.ReadUInt(32)
	pfile.buffer = pfile.buffer .. net.ReadData(len)

	local timername = "wire_expression2_file_check_timeout_" .. ply:EntIndex()
	if timer.Exists( timername ) then
		timer.Create( timername, 5, 1, function()
			local pfile = uploads[ply]
			if !pfile then return end
			pfile.uploading = false
			pfile.uploaded = false
			file_execute( pfile.ent, pfile.name, FILE_TIMEOUT )
		end)
	end
end )

util.AddNetworkString("wire_expression2_file_finish")
net.Receive("wire_expression2_file_finish", function(netlen, ply)
	local timername = "wire_expression2_file_check_timeout_" .. ply:EntIndex()

	if timer.Exists( timername ) then
		timer.Remove( timername )
	end

	local pfile = uploads[ply]
	if !pfile then return end

	pfile.uploading = false
	pfile.data = E2Lib.decode( pfile.buffer )
	pfile.buffer = ""

	if string.len( pfile.data ) != pfile.len then -- transfer error
		pfile.data = ""
		file_execute( pfile.ent, pfile.name, FILE_TRANSFER_ERROR )
		return
	end
	pfile.uploaded = true

	file_execute( pfile.ent, pfile.name, FILE_OK )
end )

concommand.Add("wire_expression2_file_singleplayer", function(ply, cmd, args)
	if not ply:IsListenServerHost() then ply:Kick("Do not use wire_expression2_file_singleplayer in multiplayer, unless you're the host!") end
	local pfile = uploads[ply]
	if !pfile then return end

	local path = args[1]
	if not file.Exists(path, "DATA") then
		pfile.sp_wait = false
		file_execute( pfile.ent, pfile.name, FILE_404 )
		return
	end

	local timername = "wire_expression2_file_check_timeout_" .. ply:EntIndex()

	if timer.Exists(timername) then timer.Remove(timername) end


	pfile.uploading = false
	pfile.data = file.Read(path)
	pfile.buffer = ""
	pfile.uploaded = true
	pfile.sp_wait = false

	file_execute(pfile.ent, pfile.name, FILE_OK)
end)

--- Listing ---
util.AddNetworkString("wire_expression2_file_list")
net.Receive("wire_expression2_file_list", function(netlen, ply)
	local plist = lists[ply]
	if !plist then return end

	local timername = "wire_expression2_filelist_check_timeout_" .. ply:EntIndex()
	if timer.Exists( timername ) then timer.Remove( timername ) end

	for i=1, net.ReadUInt(16) do
		table.insert( plist.data, ( E2Lib.decode( net.ReadString() ) ) )
	end

	plist.uploaded = true
	plist.uploading = false

	run_on.list.run = 1
	run_on.list.dir = plist.dir

	plist.ent.context.data.runOnFileList = true
	plist.ent:Execute()
	plist.ent.context.data.runOnFileList = nil

	run_on.list.run = 0
	run_on.list.dir = ""
end )
