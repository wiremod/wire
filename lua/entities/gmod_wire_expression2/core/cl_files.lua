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
	["gpushared"] = "GPUChip/e2shared"
}

for _,dir in pairs( allowed_directories ) do
	if !file.IsDir( dir ) then file.CreateDir( dir ) end
end

local function process_filename( filename )
	if string.find( filename, "..", 1, true ) then return "e2files/noname.txt" end

	if string.Left( filename, 1 ) == ">" then
		local diresc = string.find( filename, "/" )
		local extdir = string.sub( filename, 2, diresc - 1 )

		filename = (allowed_directories[extdir] or "e2files") .. string.sub( filename, diresc, string.len( filename ) )
	else
		filename = "e2files/" .. filename
	end

	return filename or "e2files/noname.txt"
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

usermessage.Hook( "wire_expression2_request_file", function( um )
	local filename = process_filename( um:ReadString() )

	if file.Exists( filename ) and file.Size( filename ) <= (cv_max_transfer_size:GetInt() * 1024) then
		local filedata = file.Read( filename ) or ""

		local encoded = E2Lib.encode( filedata )

		upload_buffer = {
			chunk = 1,
			chunks = math.ceil( string.len( encoded ) / upload_chunk_size ),
			data = encoded
		}

		RunConsoleCommand( "wire_expression2_file_begin", string.len( filedata ) )

		timer.Create( "wire_expression2_file_upload", 1/60, upload_buffer.chunks, upload_callback )
	end
end )

/* --- File Write --- */

usermessage.Hook( "wire_expression2_file_download_begin", function( um )
	download_buffer = {
		name = process_filename( um:ReadString() ),
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
		local ofile = file.Read( download_buffer.name ) or ""
	end

	file.Write( (download_buffer.name or "e2files/noname.txt"), ofile .. download_buffer.data )
end )
