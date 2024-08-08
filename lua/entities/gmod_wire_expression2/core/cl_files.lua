--[[
	File Extension
	By: Dan (McLovin)
]]--

local cv_max_transfer_size = CreateConVar("wire_expression2_file_max_size", "1024", { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum file size in kibibytes.")

local allowed_directories = { --prefix with >(allowed directory)/file.txt for files outside of e2files/ directory
	["e2files"] = "e2files",
	["e2shared"] = "expression2/e2shared",
	["cpushared"] = "cpuchip/e2shared",
	["gpushared"] = "gpuchip/e2shared",
	["spushared"] = "spuchip/e2shared",
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

--- File Read ---

net.Receive("wire_expression2_request_file", function()
	local fpath,fname = process_filepath(net.ReadString())
	local fullpath = fpath .. fname

	if file.Exists( fullpath,"DATA" ) and file.Size( fullpath, "DATA" ) <= (cv_max_transfer_size:GetInt() * 1024) then
		local data = file.Read(fullpath, "DATA") or ""
		net.Start("wire_expression2_file_upload")
			net.WriteBool(true)
			net.WriteUInt(#data, 32)
			net.WriteStream(data)
		net.SendToServer()

	else
		net.Start("wire_expression2_file_upload")
			net.WriteBool(false)
		net.SendToServer()
	end
end)

--- File Write ---
net.Receive("wire_expression2_file_download", function()
	local path, name = process_filepath(net.ReadString())
	local append = net.ReadBool()
	if not E2Lib.isValidFileWritePath(name) then
		local stream = net.ReadStream(nil, function() end)
		if stream then
			stream:Remove()
		else
			ErrorNoHaltWithStack("Warning! Looks like the server uses an outdated version of Expression2's file module! Please update to the latest Wiremod version.")
		end

		return
	end
	if not file.Exists(path, "DATA") then file.CreateDir(path) end
	net.ReadStream(nil, function(data)
		if append then
			file.Append(path .. name, data)
		else
			file.Write(path .. name, data)
		end
	end)
end)

--- File List ---

net.Receive( "wire_expression2_request_list", function()
	local dir = process_filepath(net.ReadString())

	net.Start("wire_expression2_file_list")
		local files, folders = file.Find( dir .. "*","DATA" )
		net.WriteUInt(#files + #folders, 16)
		for _,fop in pairs(files) do
			if string.GetExtensionFromFilename( fop ) == "txt" then
				net.WriteUInt(#fop, 16)
				net.WriteData(fop)
			end
		end
		for _,fop in pairs(folders) do
			net.WriteUInt(#fop, 16)
			net.WriteData(fop .. "/")
		end
	net.SendToServer()
end)
