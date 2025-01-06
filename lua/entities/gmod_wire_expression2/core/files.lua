--[[
	File Extension
	By: Dan (McLovin)
]]--

local cv_max_transfer_size = CreateConVar("wire_expression2_file_max_size", "1024", { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum file size in kibibytes.")
local cv_transfer_max      = CreateConVar("wire_expression2_file_max_queue", "5", { FCVAR_ARCHIVE }, "Maximum number of files that can be queued at once.")

E2Lib.RegisterExtension( "file", true, "Allows reading and writing of files in the player's local data directory." )

local ent_IsValid = FindMetaTable("Entity").IsValid

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

---@type table<Player, { name: string, uploading: boolean, uploaded: boolean, data: string, ent: Entity, Stream: table? }[]>
local uploads = WireLib.RegisterPlayerTable()
---@type table<Player, { name: string, data: string, started: boolean, downloading: boolean, downloaded: boolean, append: boolean, ent: Entity }[]>
local downloads = WireLib.RegisterPlayerTable()
---@type table<Player, { dir: string, data: string[], started: boolean, uploading: boolean, uploaded: boolean, ent: Entity }[]>
local lists = WireLib.RegisterPlayerTable()
local run_on = {
	file = {
		name = "",
		ents = {},
		status = FILE_UNKNOWN
	},
	list = {
		dir = "",
		ents = {}
	}
}

local flushFileBuffer

local function file_canUpload(ply)
	return #uploads[ply] < cv_transfer_max:GetInt()
end

util.AddNetworkString("wire_expression2_request_file")
local function file_Upload(self, ply, entity, filename)
	if not file_canUpload(ply) then return self:throw("You've reached the file upload limit!") end
	if not E2Lib.isValidFileWritePath(filename) then return self:throw("Invalid file name/path: ".. filename) end

	local queue = uploads[ply]
	queue[#queue + 1] = {
		name = filename,
		uploading = false,
		uploaded = false,
		data = "",
		ent = entity,
		Stream = nil
	}

	if #queue == 1 then
		net.Start("wire_expression2_request_file")
			net.WriteString(filename)
		net.Send(ply)
	end

	return true
end

local function file_canDownload(ply)
	return #downloads[ply] < cv_transfer_max:GetInt()
end

local function file_Download(self, ply, filename, data, append)
	if not file_canDownload(ply) then return self:throw("You've reached the file write limit!") end
	if not E2Lib.isValidFileWritePath(filename) then return self:throw("Invalid file name/path: " .. filename) end
	if #data > cv_max_transfer_size:GetInt() * 1024 then return self:throw("File is too large to send!") end

	-- if we're trying to append an empty string then we don't need to queue up
	-- a download to consider the operation completed
	if append and #data == 0 then return 0 end

	local queue = downloads[ply]

	queue[#queue + 1] = {
		name = filename,
		data = data,
		started = false,
		downloading = true,
		downloaded = false,
		append = append,
		ent = self.entity
	}

	flushFileBuffer()

	return #data
end

local function file_canList(ply)
	return #lists[ply] < cv_transfer_max:GetInt()
end

util.AddNetworkString("wire_expression2_request_list")
local function file_List(self, ply, entity, dir)
	if not file_canList(ply) then return self:throw("You've reached the file list download limit!") end

	local queue = lists[ply]
	queue[#queue + 1] = {
		dir = dir,
		data = {},
		uploading = true,
		uploaded = false,
		ent = entity
	}
	net.Start("wire_expression2_request_list")
		net.WriteString(dir or "")
	net.Send(ply)

	return true
end

--- File loading ---

__e2setcost(100)

e2function number fileLoad(string filename)
	return file_Upload(self, self.player, self.entity, filename) and 1 or 0
end

__e2setcost(3)

[nodiscard]
e2function number fileCanLoad()
	return file_canUpload(self.player) and 1 or 0
end

[nodiscard]
e2function number fileLoadQueued()
	return #(uploads[self.player] or {})
end

__e2setcost(5)

[deprecated = "Use the file events instead"]
e2function number fileLoaded()
	local pfile = uploads[self.player].last

	return not pfile.uploading and pfile.uploaded and 1 or 0
end

[deprecated = "Use the file events instead"]
e2function number fileLoading()
	return uploads[self.player].last.uploading and 1 or 0
end

[deprecated = "Use the file events instead"]
e2function number fileStatus()
	return run_on.file.status or FILE_UNKNOWN
end

--- File reading/writing ---

[deprecated]
e2function string fileName()
	local pfile = uploads[self.player].last

	return pfile.uploaded and not pfile.uploading and pfile.name or ""
end

__e2setcost( 10 )

[deprecated = "Use the file events instead", nodiscard]
e2function string fileRead()
	local pfile = uploads[self.player].last

	return pfile.uploaded and not pfile.uploading and pfile.data or ""
end

__e2setcost(3)

e2function number fileMaxSize()
	return cv_max_transfer_size:GetInt()
end

e2function number fileCanWrite()
	return file_canDownload(self.player) and 1 or 0
end

[nodiscard]
e2function number fileWriteQueued()
	return #(downloads[self.player] or {})
end

__e2setcost(100)

e2function number fileWrite( string filename, string data )
	return file_Download(self, self.player, filename, data, false) or -1
end

e2function number fileAppend( string filename, string data )
	return file_Download(self, self.player, filename, data, true) or -1
end

--- File Listing ---

__e2setcost(100)

e2function number fileList( string dir )
	return file_List(self, self.player, self.entity, dir) and 1 or 0
end

__e2setcost(3)

[nodiscard]
e2function number fileCanList()
	return file_canList( self.player ) and 1 or 0
end

[nodiscard]
e2function number fileListQueued()
	return #(lists[self.player] or {})
end

__e2setcost(5)

[deprecated = "Use the file events instead", nodiscard]
e2function number fileLoadedList()
	local plist = lists[self.player].last

	return not plist.uploading and plist.uploaded and 1 or 0
end

[deprecated = "Use the file events instead", nodiscard]
e2function number fileLoadingList()
	return lists[self.player].last.uploading and 1 or 0
end

[deprecated = "Use the file events instead", nodiscard]
e2function array fileReadList()
	local plist = lists[self.player]

	return (plist.uploaded and not plist.uploading and plist.data) and plist.data or {}
end

--- runOnFile event ---

__e2setcost( 5 )

[deprecated = "Use the file events instead"]
e2function void runOnFile( active )
	run_on.file.ents[self.entity] = (active ~= 0)
end

[deprecated = "Use the file events instead"]
e2function number fileClk()
	return self.data.runOnFile and 1 or 0
end

[deprecated = "Use the file events instead"]
e2function number fileClk( string filename )
	return (self.data.runOnFile and run_on.file.name == filename) and 1 or 0
end

-- runOnList event ---

__e2setcost( 5 )

[deprecated = "Use the file events instead"]
e2function void runOnList(active)
	run_on.list.ents[self.entity] = active ~= 0
end

[deprecated = "Use the file events instead"]
e2function number fileListClk()
	return self.data.runOnFileList and 1 or 0
end

[deprecated = "Use the file events instead"]
e2function number fileListClk( string dir )
	return (self.data.runOnFileList and run_on.list.dir == dir) and 1 or 0
end

--- Hooks 'n' Shit ---

registerCallback("construct", function(self)
	local player = self.player
	downloads[player] = downloads[player] or { last = {} }
	uploads[player] = uploads[player] or { last = {} }
	lists[player] = lists[player] or { last = {} }
end )

registerCallback("destruct", function(self)
	local player, entity = self.player, self.entity

	local iterable = { uploads[player], lists[player] } -- Ignore downloads in case the user is backing up data on removed

	if iterable[1][1] and iterable[1][1].ent == entity and iterable[1][1].Stream then
		iterable[1][1].Stream:Remove() -- Special case for uploading files and only uploading files
	end
	for _, tab in ipairs(iterable) do
		local k = 2
		local v = tab[k]
		while v do
			if v.ent == entity then
				table.remove(tab, k)
			else
				k = k + 1
			end
			v = tab[k]
		end
	end
end)

--- Downloading ---
-- Server -> Client
util.AddNetworkString("wire_expression2_file_download")

-- File transfer flags:
-- 0 - Abort
-- 1 - Begin
-- 2 - Upload
-- 3 - End

timer.Remove("wire_expression2_flush_file_buffer") -- Remove this timer in case it exists from reloading
flushFileBuffer = function()
	for ply, queue in pairs(downloads) do
		if ent_IsValid(ply) then
			local fdata = queue[1]
			if fdata and not fdata.started then
				fdata.started = true -- These extra flags are still needed for the old file functions

				local name, data = fdata.name, fdata.data

				net.Start("wire_expression2_file_download")
					net.WriteString(name or "")
					net.WriteBool(fdata.append)
					net.WriteStream(data, function()
						fdata.downloaded = true
						fdata.downloading = false

						queue.last = fdata

						local ent = fdata.ent
						timer.Simple(0, function() -- Trigger one tick ahead so the client has time to write the file
							if ent_IsValid(ent) and ent.ExecuteEvent then ent:ExecuteEvent("fileWritten", { name, data }) end
						end)

						table.remove(queue, 1)

						if #queue ~= 0 then -- Queue the next file
							timer.Create("wire_expression2_flush_file_buffer", 0.2, 2, flushFileBuffer)
						end
					end)
				net.Send(ply)
			end
		end
	end
end

--- Uploading ---
-- Client -> Server

local function file_execute(ply, file, status)

	local queue = uploads[ply]
	local ent = file.ent

	if ent_IsValid(ent) then
		local filename = file.name
		run_on.file.name = filename
		run_on.file.status = status

		queue.last = file

		if status == FILE_OK then
			ent:ExecuteEvent("fileLoaded", {filename, file.data})
		else
			ent:ExecuteEvent("fileErrored", {filename, status})
		end

		if run_on.file.ents[ent] then
			ent.context.data.runOnFile = true
			ent:Execute()
			ent.context.data.runOnFile = nil
		end

		run_on.file.name = ""
		run_on.file.status = FILE_UNKNOWN
	end

	table.remove(queue, 1)
	if #queue ~= 0 then
		net.Start("wire_expression2_request_file")
			net.WriteString(queue[1].name)
		net.Send(ply)
	end
end

util.AddNetworkString("wire_expression2_file_upload")
net.Receive("wire_expression2_file_upload", function(_, ply)
	local pfile = uploads[ply][1]
	if pfile then
		if net.ReadBool() and not pfile.uploading and not pfile.uploaded then
			local len = net.ReadUInt(32)
			if len / 1024 > cv_max_transfer_size:GetInt() then
				pfile.uploading = false
				pfile.uploaded = false
				file_execute(ply, pfile, FILE_TRANSFER_ERROR)
			else
				pfile.uploading = true
				pfile.Stream = net.ReadStream(ply, function(data)
					pfile.data = data
					pfile.uploading = false
					pfile.uploaded = true

					file_execute(ply, pfile, FILE_OK)
				end)
			end
		else
			file_execute(ply, pfile, FILE_404)
		end
	end
end)

--- Listing ---
util.AddNetworkString("wire_expression2_file_list")
net.Receive("wire_expression2_file_list", function(_, ply)
	local queue = lists[ply]
	local plist = queue[1]
	if not plist then return end

	timer.Remove("wire_expression2_filelist_check_timeout_" .. ply:EntIndex())

	for i=1, net.ReadUInt(16) do
		table.insert(plist.data, net.ReadData(net.ReadUInt(16)))
	end

	plist.uploaded = true
	plist.uploading = false

	local ent = plist.ent
	if ent:IsValid() then

		run_on.list.dir = plist.dir

		ent:ExecuteEvent("fileList", { plist.dir, plist.data })

		if run_on.list.ents[plist.ent] then
			ent.context.data.runOnFileList = true
			ent:Execute()
			ent.context.data.runOnFileList = nil
		end

		run_on.list.dir = ""
	end

	table.remove(queue, 1)
	if #queue ~= 0 then
		net.Start("wire_expression2_request_list")
			net.WriteString(queue[1].dir)
		net.Send(ply)
	end
end )

E2Lib.registerEvent("fileErrored", {
	{ "FilePath", "s" },
	{ "Status", "n" }
})
E2Lib.registerEvent("fileLoaded", {
	{ "FilePath", "s" },
	{ "Data", "s" }
})
E2Lib.registerEvent("fileWritten", {
	{ "FilePath", "s" },
	{ "Data", "s" }
})
E2Lib.registerEvent("fileList", {
	{ "Path", "s"},
	{ "Contents", "r" }
})