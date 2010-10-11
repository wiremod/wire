--[[
	File Extension
	By: Dan (McLovin)
]]--

local cv_transfer_delay    = CreateConVar( "wire_expression2_file_delay", "5", { FCVAR_ARCHIVE } )
local cv_max_transfer_size = CreateConVar( "wire_expression2_file_max_size", "100", { FCVAR_REPLICATED, FCVAR_ARCHIVE } ) //in kb

E2Lib.RegisterExtension( "file", true )

local delays = {}
local uploads = {}
local downloads = {}
local run_on = {
	file = {
		run = 0,
		name = "",
		ents = {}
	}
}

local function file_canUpload( ply )
	local pfile = uploads[ply]
	local pdel = (delays[ply] or {}).upload

	if (pfile and pfile.uploading) or
		(pdel and (CurTime() - pdel) < cv_transfer_delay:GetInt()) then return false end

	return true
end

local function file_Upload( ply, entity, filename )
	if !file_canUpload( ply ) or !IsValid( entity ) or !IsValid( ply ) or !ply:IsPlayer() or string.Right( filename, 4 ) != ".txt" then return false end

	uploads[ply] = {
		name = filename,
		uploading = false, //don't halt other uploads incase file does not exist
		uploaded = false,
		data = "",
		ent = entity
	}

	umsg.Start( "wire_expression2_request_file", ply )
		umsg.String( filename )
	umsg.End()

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

	downloads[ply] = {
		name = filename,
		data = data,
		started = false,
		downloading = true,
		downloaded = false,
		append = append
	}
end

/* --- File loading --- */
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

/* --- File reading/writing --- */

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

	if pfile.uploaded and !pfile.uploading then
		return pfile.data
	end

	return ""
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

/* --- runOnFile event --- */

__e2setcost( 5 )

e2function void runOnFile( active )
	run_on.file.ents[self.entity] = (active != 0)
end

e2function number fileClk()
	return run_on.file.run
end

e2function number fileClk( string filename )
	if run_on.file.run == 1 and run_on.file.name == filename then
		return 1
	else
		return 0
	end
end

/* --- Hooks 'n' Shit --- */

registerCallback( "construct", function( self )
	uploads[self.player] = uploads[self.player] or {
		uploading = false,
		uploaded = false
	}
	downloads[self.player] = downloads[self.player] or {
		downloading = false,
		downloaded = false
	}
	delays[self.player] = delays[self.player] or {
		upload = 0,
		download = 0
	}
end )

timer.Create(
	"wire_expression2_flush_file_buffer",
	1/60,
	0,
	function()
		for ply,fdata in pairs( downloads ) do
			if IsValid( ply ) and ply:IsPlayer() and fdata.downloading then
				local chunks = 5

				if !fdata.started then
					umsg.Start( "wire_expression2_file_download_begin", ply )
						umsg.String( fdata.name or "" )
					umsg.End()

					fdata.started = true
				end

				for chunk = 1, chunks do
					local strlen = math.Clamp( string.len( fdata.data ), 0, 100 )

					if strlen < 1 then break end

					umsg.Start( "wire_expression2_file_download_chunk", ply )
						umsg.String( string.sub( fdata.data, 1, strlen ) )
					umsg.End()

					fdata.data = string.sub( fdata.data, strlen + 1, string.len( fdata.data ) )
				end

				if string.len( fdata.data ) < 1 then
					umsg.Start( "wire_expresison2_file_download_finish", ply )
						umsg.Bool( fdata.append or false )
					umsg.End()

					fdata.downloaded = true
					fdata.downloading = false
				end
			end
		end
	end
)

local function timeout_callback( ply )
	local pfile = uploads[ply]

	if !pfile then return end

	pfile.uploading = false
	pfile.uploaded = false
end

concommand.Add( "wire_expression2_file_begin", function( ply, com, args )
	local len = tonumber( args[1] )

	if (len / 1024) > cv_max_transfer_size:GetInt() then return end

	local pfile = uploads[ply]

	if !pfile then return end

	pfile.buffer = ""
	pfile.len = len
	pfile.uploading = true
	pfile.uploaded = false

	timer.Create( "wire_expression2_file_check_timeout_" .. ply:EntIndex(), 5, 1, timeout_callback, ply )
end )

concommand.Add( "wire_expression2_file_chunk", function( ply, com, args )
	local pfile = uploads[ply]

	if !pfile or !pfile.uploading then return end

	pfile.buffer = pfile.buffer .. args[1]

	local timername = "wire_expression2_file_check_timeout_" .. ply:EntIndex()

	if timer.IsTimer( timername ) then
		timer.Remove( timername )
		timer.Create( timername, 5, 1, timeout_callback, ply )
	end
end )

concommand.Add( "wire_expression2_file_finish", function( ply, com, args )
	local timername = "wire_expression2_file_check_timeout_" .. ply:EntIndex()

	if timer.IsTimer( timername ) then
		timer.Remove( timername )
	end

	local pfile = uploads[ply]

	if !pfile then return end

	pfile.uploading = false
	pfile.data = E2Lib.decode( pfile.buffer )
	pfile.buffer = ""

	if string.len( pfile.data ) != pfile.len then //transfer error
		pfile.data = ""
		return
	end

	pfile.uploaded = true

	run_on.file.run = 1
	run_on.file.name = pfile.name

	if IsValid( pfile.ent )  and run_on.file.ents[pfile.ent] then
		pfile.ent:Execute()
	end

	run_on.file.run = 0
	run_on.file.name = ""
end )
