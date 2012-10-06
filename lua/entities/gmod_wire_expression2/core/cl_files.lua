--[[
	File Extension
	By: Dan (McLovin)
]]--

local cv_max_transfer_size = CreateConVar( "wire_expression2_file_max_size", "100", { FCVAR_REPLICATED, FCVAR_ARCHIVE } ) //in kb

local upload_buffer = {}
local download_buffer = {}

local upload_chunk_size = 229

local allowed_directories = { //prefix with >(allowed directory)/file.txt for files outside of e2files/ directory
	["e1shared"] = "ExpressionGate/e2shared",
	["e2shared"] = "Expression2/e2shared",
	["cpushared"] = "CPUChip/e2shared",
	["gpushared"] = "GPUChip/e2shared",
	["dupeshared"] = "adv_duplicator/e2shared"
}

for _,dir in pairs( allowed_directories ) do
	if not file.IsDir( dir, "DATA" ) then file.CreateDir( dir ) end
end

local function process_filepath( filepath )
	if string.find( filepath, "..", 1, true ) then
		return "e2files/", "noname.txt"
	end

	local fullpath = ""

	if string.Left( filepath, 1 ) == ">" then
		local diresc = string.find( filepath, "/" )

		if diresc then
			local extdir = string.sub( filepath, 2, diresc - 1 )
			local dir = (allowed_directories[extdir] or "e2files") .. "/"

			fullpath = dir .. string.sub( filepath, diresc + 1, string.len( filepath ) )
		else
			fullpath = "e2files/" .. filepath
		end
	else
		fullpath = "e2files/" .. filepath
	end

	return string.GetPathFromFilename( fullpath ) or "e2files/", string.GetFileFromFilename( fullpath ) or "noname.txt"
end

/* --- File Read --- */

local function upload_callback()
	if !upload_buffer or !upload_buffer.data then return end

	local chunk_size = math.Clamp( string.len( upload_buffer.data ), 0, upload_chunk_size )

	RunConsoleCommand( "wire_expression2_file_chunk", string.Left( upload_buffer.data, chunk_size ) )
	upload_buffer.data = string.sub( upload_buffer.data, chunk_size + 1, string.len( upload_buffer.data ) )

	if upload_buffer.chunk >= upload_buffer.chunks then
		RunConsoleCommand( "wire_expression2_file_finish" )

		timer.Remove( "wire_expression2_file_upload" )

		return
	end

	upload_buffer.chunk = upload_buffer.chunk + 1
end

usermessage.Hook("wire_expression2_request_file_sp", function(um)
	local fpath,fname = process_filepath( um:ReadString() )
	local fullpath = fpath .. fname
	RunConsoleCommand("wire_expression2_file_singleplayer", fullpath)
end)

usermessage.Hook( "wire_expression2_request_file", function( um )
	local fpath,fname = process_filepath( um:ReadString() )
	local fullpath = fpath .. fname

	if file.Exists( fullpath ) and file.Size( fullpath, "DATA" ) <= (cv_max_transfer_size:GetInt() * 1024) then
		local filedata = file.Read( fullpath ) or ""

		local encoded = E2Lib.encode( filedata )

		upload_buffer = {
			chunk = 1,
			chunks = math.ceil( string.len( encoded ) / upload_chunk_size ),
			data = encoded
		}

		RunConsoleCommand( "wire_expression2_file_begin", "1", string.len( filedata ) )

		timer.Create( "wire_expression2_file_upload", 1/60, upload_buffer.chunks, upload_callback )
	else
		RunConsoleCommand( "wire_expression2_file_begin", "0" )
	end
end )

/* --- File Write --- */

usermessage.Hook( "wire_expression2_file_download_begin", function( um )
	local fpath,fname = process_filepath( um:ReadString() )
	local fullpath = fpath .. fname

	download_buffer = {
		name = fullpath,
		data = ""
	}
end )

usermessage.Hook( "wire_expression2_file_download_chunk", function( um )
	download_buffer.data = (download_buffer.data or "") .. um:ReadString()
end )

usermessage.Hook( "wire_expresison2_file_download_finish", function( um )
	if !download_buffer.name or string.Right( download_buffer.name, 4 ) != ".txt" then return end

	local ofile = ""

	if um:ReadBool() and file.Exists( download_buffer.name ) then
		ofile = file.Read( download_buffer.name )
	end

	file.Write( (download_buffer.name or "e2files/noname.txt"), ofile .. download_buffer.data )
end )

/* --- File List --- */

usermessage.Hook( "wire_expression2_request_list", function( um )
	local dir = process_filepath( um:ReadString() or "" )

	for _,fop in pairs( file.Find( dir .. "*" ), "DATA" ) do
		local ext = string.GetExtensionFromFilename( fop )

		if (!ext or ext == "txt") and string.len( fop ) < 250 then
			RunConsoleCommand( "wire_expression2_file_list", "1", E2Lib.encode( fop .. ((!ext) and "/" or "") ) )
		end
	end

	RunConsoleCommand( "wire_expression2_file_list", "0" )
end )
