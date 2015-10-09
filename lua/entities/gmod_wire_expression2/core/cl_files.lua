--[[
	File Extension
	By: Dan (McLovin)
]]--

local cv_max_transfer_size = CreateConVar( "wire_expression2_file_max_size", "100", { FCVAR_REPLICATED, FCVAR_ARCHIVE } ) //in kb

local upload_buffer = {}
local download_buffer = {}

local upload_chunk_size = 20000 //Our overhead is pretty small so lets send it in moderate sized pieces, no need to max out the buffer

local allowed_directories = { //prefix with >(allowed directory)/file.txt for files outside of e2files/ directory
	["e2files"] = "e2files",
	["e2shared"] = "expression2/e2shared",
	["cpushared"] = "cpuchip/e2shared",
	["gpushared"] = "gpuchip/e2shared",
	["spushared"] = "spuchip/e2shared",
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

	net.Start("wire_expression2_file_chunk")
		net.WriteString(string.Left( upload_buffer.data, chunk_size ))
	net.SendToServer()
	upload_buffer.data = string.sub( upload_buffer.data, chunk_size + 1, string.len( upload_buffer.data ) )

	if upload_buffer.chunk >= upload_buffer.chunks then
		net.Start("wire_expression2_file_finish") net.SendToServer()
		timer.Remove( "wire_expression2_file_upload" )
		return
	end

	upload_buffer.chunk = upload_buffer.chunk + 1
end

net.Receive("wire_expression2_request_file_sp", function(netlen)
	local fpath,fname = process_filepath(net.ReadString())
	RunConsoleCommand("wire_expression2_file_singleplayer", fpath .. fname)
end)

net.Receive("wire_expression2_request_file", function(netlen)
	local fpath,fname = process_filepath(net.ReadString())
	local fullpath = fpath .. fname

	if file.Exists( fullpath,"DATA" ) and file.Size( fullpath, "DATA" ) <= (cv_max_transfer_size:GetInt() * 1024) then
		local filedata = file.Read( fullpath,"DATA" ) or ""

		local encoded = E2Lib.encode( filedata )

		upload_buffer = {
			chunk = 1,
			chunks = math.ceil( string.len( encoded ) / upload_chunk_size ),
			data = encoded
		}

		net.Start("wire_expression2_file_begin")
			net.WriteUInt(string.len(filedata), 32)
		net.SendToServer()

		timer.Create( "wire_expression2_file_upload", 1/60, upload_buffer.chunks, upload_callback )
	else
		net.Start("wire_expression2_file_begin")
			net.WriteUInt(0, 32) // 404 file not found, send len of 0
		net.SendToServer()
	end
end )

/* --- File Write --- */
net.Receive("wire_expression2_file_download_begin", function( netlen )
	local fpath,fname = process_filepath( net.ReadString() )
	if string.GetExtensionFromFilename( string.lower(fname) ) != "txt" then return end
	if not file.Exists(fpath, "DATA") then file.CreateDir(fpath) end
	download_buffer = {
		name = fpath .. fname,
		data = ""
	}
end )

net.Receive("wire_expression2_file_download_chunk", function( netlen )
	if not download_buffer.name then return end
	download_buffer.data = (download_buffer.data or "") .. net.ReadString()
end )

net.Receive("wire_expresison2_file_download_finish", function( netlen )
	if not download_buffer.name then return end

	if net.ReadBit() ~= 0 then
		file.Append( download_buffer.name, download_buffer.data )
	else
		file.Write( download_buffer.name, download_buffer.data )
	end
end )

/* --- File List --- */

net.Receive( "wire_expression2_request_list", function( netlen )
	local dir = process_filepath(net.ReadString())

	net.Start("wire_expression2_file_list")
		local files, folders = file.Find( dir .. "*","DATA" )
		net.WriteUInt(#files + #folders, 16)
		for _,fop in pairs(files) do
			if string.GetExtensionFromFilename( fop ) == "txt" then
				net.WriteString(E2Lib.encode( fop ))
			end
		end
		for _,fop in pairs(folders) do
			net.WriteString(E2Lib.encode( fop.."/" ))
		end
	net.SendToServer()
end )
