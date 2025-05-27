-- import some e2lib and math functions
local IsValid  = IsValid
local isOwner      = E2Lib.isOwner
local Clamp        = math.Clamp

--[[******************************************************************************]]

local function checkOwner(self)
	return IsValid(self.player);
end

local function checkVehicle(self, this)
	if not IsValid(this) then return self:throw("Invalid entity!", false) end
	if not this:IsVehicle() then return self:throw("Expected Vehicle, got Entity", false) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", false) end
	return true
end

--[[******************************************************************************]]

-- default delay for printing messages, adds one "charge" after this delay
local defaultPrintDelay = 0.3
-- the amount of "charges" a player has by default
local defaultMaxPrints = 15
-- default max print length
local defaultMaxLength = game.SinglePlayer() and 10000 or 1000

-- Contains the amount of "charges" a player has, i.e. the amount of print-statements can be executed before
-- the messages being omitted. The defaultPrintDelay is the time required to add one additional charge to the
-- player's account. The defaultMaxPrints variable are the charges the player starts with.
local printDelays = {}

-- Returns the table containing the player's charges or creatis if it it does not yet exist
-- @param ply           player to get the table from, not validated
-- @param maxCharges    amount of charges to set it the table has to be created
-- @param chargesDelay  delay until a new charge is given, set it the table has to be created
local function getDelaysOrCreate(ply, maxCharges, chargesDelay)
	local printDelay = printDelays[ply]

	if not printDelay then
		-- if the player does not have an entry yet, add it
		printDelay = { numCharges = maxCharges, lastTime = CurTime() }
		printDelays[ply] = printDelay
	end

	return printDelay
end

-- Returns whether or not a player has "charges" for printing a message
-- Additionally adds all new charges the player might have
-- @param ply  player to check, not validated
local function canPrint(ply)
	-- update the console variables just in case
	local maxCharges = ply:GetInfoNum("wire_expression2_print_max", defaultMaxPrints)
	local chargesDelay = ply:GetInfoNum("wire_expression2_print_delay", defaultPrintDelay)

	local printDelay = getDelaysOrCreate(ply, maxCharges, chargesDelay)

	local currentTime = CurTime()
	if printDelay.numCharges < maxCharges then
		-- check if the player "deserves" new charges
		local timePassed = (currentTime - printDelay.lastTime)
		if timePassed > chargesDelay then
			if chargesDelay == 0 then
				printDelay.lastTime = currentTime
				printDelay.numCharges = maxCharges
			else
				local chargesToAdd = math.floor(timePassed / chargesDelay)
				printDelay.lastTime = (currentTime - (timePassed % chargesDelay))
				-- add "semi" charges the player might already have
				printDelay.numCharges = printDelay.numCharges + chargesToAdd
			end
		end
	end
	-- we should clamp his charges for safety
	if printDelay.numCharges > maxCharges then
		printDelay.numCharges = maxCharges
		-- remove the "semi" charges, otherwise the player has too many
		printDelay.lastTime = currentTime
	end

	return printDelay and printDelay.numCharges > 0
end

-- Returns whether or not a player can currently print a message or if it will be omitted by the antispam
-- Additionally removes one charge from the player's account
-- @param ply  player to check, is not validated
local function checkDelay(ply)
	if canPrint(ply) then
		local maxCharges = ply:GetInfoNum("wire_expression2_print_max", defaultMaxPrints)
		local chargesDelay = ply:GetInfoNum("wire_expression2_print_delay", defaultPrintDelay)
		local printDelay = getDelaysOrCreate(ply, maxCharges, chargesDelay)
		printDelay.numCharges = printDelay.numCharges - 1
		return true
	end
	return false
end

hook.Add("PlayerDisconnected", "e2_print_delays_player_dc", function(ply) printDelays[ply] = nil end)

--[[******************************************************************************]]

__e2setcost(2)

-- Returns whether or not the next print-message will be printed or omitted by antispam
e2function number playerCanPrint()
	if not checkOwner(self) then return end
	return canPrint(self.player) and 1 or 0
end

local function repr(self, value, typeid)
	local fn = wire_expression2_funcs["toString(" .. typeid ..")"] or wire_expression2_funcs["toString(" .. typeid .. ":)"]

	if fn and fn[2] == "s" then
		self.prf = self.prf + (fn[4] or 20)
		if fn.attributes.legacy then
			return fn[3](self, { [2] = { function() return value end } })
		else
			return fn[3](self, { value })
		end
	elseif typeid == "s" then -- special case for string
		return value
	else
		return wire_expression_types2[typeid][1]
	end
end

local maxLength = CreateConVar("wire_expression2_print_max_length", "10000", FCVAR_ARCHIVE, "Hard limit for how much E2 users can print with a single call. Here to avoid extensive net use.", 0, 65532)

-- Prints <...> like lua's print(...), except to the chat area
__e2setcost(40)
e2function void print(...args)
	if not checkOwner(self) then return end
	if not checkDelay( self.player ) then return end

	local nargs = #args
	self.prf = self.prf + nargs

	if nargs > 0 then
		local max_len = math.min(maxLength:GetInt(), self.player:GetInfoNum("wire_expression2_print_max_length", defaultMaxLength))
		for i = 1, nargs do
			local v, ty = args[i], typeids[i]
			args[i] = E2Lib.limitString(repr(self, v, ty), max_len / nargs)
		end

		local text = table.concat(args, "\t")
		if #text > 0 then
			local limited = E2Lib.limitString(text, max_len)
			self.prf = self.prf + #limited / 5

			net.Start("wire_expression2_print")
				net.WriteString(limited)
			net.Send(self.player)
		end
	end
end

__e2setcost(30)

--- Posts a string to the chat of <this>'s driver. Returns 1 if the text was printed, 0 if not.
e2function number entity:printDriver(string text)
	if not checkVehicle(self, this) then return 0 end
	if text:find('"', 1, true) then return 0 end

	local driver = this:GetDriver()
	if not IsValid(driver) then return 0 end

	if not checkDelay( driver ) then return 0 end

	driver:ChatPrint(string.Left(text,249))
	return 1
end

--[[******************************************************************************]]

__e2setcost(30)

--- Displays a hint popup with message <text> for <duration> seconds (<duration> being clamped between 0.7 and 7).
e2function void hint(string text, duration)
	if not IsValid(self.player) then return end
	if not checkDelay( self.player ) then return end
	WireLib.AddNotify(self.player, string.Left(text,249), NOTIFY_GENERIC, Clamp(duration,0.7,7))
end

--- Displays a hint popup to the driver of vehicle E, with message <text> for <duration> seconds (<duration> being clamped between 0.7 and 7). Same return value as printDriver.
e2function number entity:hintDriver(string text, duration)
	if not checkVehicle(self, this) then return 0 end

	local driver = this:GetDriver()
	if not IsValid(driver) then return 0 end

	if not checkDelay( driver ) then return 0 end

	WireLib.AddNotify(driver, string.Left(text,249), NOTIFY_GENERIC, Clamp(duration,0.7,7))
	return 1
end

--[[******************************************************************************]]

local valid_print_types = {
	[HUD_PRINTNOTIFY] = "HUD_PRINTNOTIFY",
	[HUD_PRINTCONSOLE] = "HUD_PRINTCONSOLE",
	[HUD_PRINTTALK] = "HUD_PRINTTALK",
	[HUD_PRINTCENTER] = "HUD_PRINTCENTER"
}
for value, name in pairs(valid_print_types) do
	E2Lib.registerConstant(name, value)
end

__e2setcost(30)

--- Same as print(<text>), but can make the text show up in different places. <print_type> can be one of the following: _HUD_PRINTCENTER, _HUD_PRINTCONSOLE, _HUD_PRINTNOTIFY, _HUD_PRINTTALK.
e2function void print(print_type, string text)
	if not checkOwner(self) then return end
	if not valid_print_types[print_type] then return end
	if not checkDelay(self.player) then return end

	self.player:PrintMessage(print_type, string.Left(text,249))
end

--- Same as <this>E:printDriver(<text>), but can make the text show up in different places. <print_type> can be one of the following: _HUD_PRINTCENTER, _HUD_PRINTCONSOLE, _HUD_PRINTNOTIFY, _HUD_PRINTTALK.
e2function number entity:printDriver(print_type, string text)
	if not checkVehicle(self, this) then return 0 end
	if not valid_print_types[print_type] then return self:throw("Invalid print type " .. print_type) end
	if text:find('"', 1, true) then return 0 end

	local driver = this:GetDriver()
	if not IsValid(driver) then return 0 end

	if not checkDelay( driver ) then return 0 end

	driver:PrintMessage(print_type, string.Left(text,249))
	return 1
end

--[[******************************************************************************]]

-- helper stuff for printTable
local PrintTableToString
do
	local msgbuf = {}
	local function Msg(s)
		table.insert(msgbuf, s)
	end

	-- From: https://raw.githubusercontent.com/garrynewman/garrysmod/ced7ae207d60af3f77779b30630cce91029e1981/garrysmod/lua/includes/util.lua
	local PrintTable
	PrintTable = function( t, indent, done )

		done = done or {}
		indent = indent or 0
		local keys = table.GetKeys( t )

		table.sort( keys, function( a, b )
			if ( isnumber( a ) and isnumber( b ) ) then return a < b end
			return tostring( a ) < tostring( b )
		end )

		for i = 1, #keys do
			local key = keys[ i ]
			local value = t[ key ]
			Msg( string.rep( "\t", indent ) )

			if  ( istable( value ) and not done[ value ] ) then

				done[ value ] = true
				Msg( tostring( key ) .. ":" .. "\n" )
				PrintTable ( value, indent + 2, done )
				done[ value ] = nil

			else

				Msg( tostring( key ) .. "\t=\t" )
				Msg( tostring( value ) .. "\n" )

			end

		end

	end
	PrintTableToString = function(...)
		msgbuf = {}
		PrintTable(...)
		return table.concat(msgbuf)
	end
end

__e2setcost(150)

--- Prints an array like the lua function [[G.PrintTable|PrintTable]] does, except to the chat area.
e2function void printTable(array arr)
	if not checkOwner(self) then return end
	if not checkDelay( self.player ) then return end

	for _,line in ipairs(string.Explode("\n",PrintTableToString(arr))) do
		self.player:ChatPrint(line)
	end
end

-- The printTable(T) function is in table.lua because it uses a local function

--[[******************************************************************************]]

__e2setcost(150)

util.AddNetworkString("wire_expression2_printColor")
util.AddNetworkString("wire_expression2_print")

local bytes = 0
local max_len = 0

-- Proprietary type IDs just for placebo network saving:
-- 0 - EOF
-- 1 - number
-- 2 - string
-- 3 - color
-- 4 - entity
local function pc_number_writer(n)
	bytes = bytes + 8
	net.WriteUInt(1, 4)
	net.WriteDouble(n)
end

local function pc_string_writer(text)
	local len = bytes + #text
	net.WriteUInt(2, 4)
	if len >= max_len then
		net.WriteString(string.sub(text, 1, max_len - bytes))
	else
		net.WriteString(text)
	end
	bytes = len + 1
end

local function pc_entity_writer(e)
	bytes = bytes + 2 -- edict is 13 bits oh well
	net.WriteUInt(4, 4)
	net.WriteEntity(e)
end

local function pc_vector_writer(v)
	bytes = bytes + 24
	net.WriteUInt(3, 4)
	net.WriteUInt(v[1], 8)
	net.WriteUInt(v[2], 8)
	net.WriteUInt(v[3], 8)
end

local printcolor_writers = {
	[TYPE_NUMBER] = pc_number_writer,
	[TYPE_STRING] = pc_string_writer,
	[TYPE_VECTOR] = pc_vector_writer,
	[TYPE_TABLE] = function(t)
		if IsColor(t) then
			bytes = bytes + 24
			net.WriteUInt(3, 4)
			net.WriteColor(t, false)
		else
			for i, v in pairs(t) do
				if not isnumber(i) then return end
				if not isnumber(v) then return end
				if i < 1 or i > 4 then return end
			end
			bytes = bytes + 24
			net.WriteUInt(3, 4)
			net.WriteUInt(t[1], 8)
			net.WriteUInt(t[2], 8)
			net.WriteUInt(t[3], 8)
		end
	end,
	[TYPE_ENTITY] = pc_entity_writer,

	n = pc_number_writer,
	s = pc_string_writer,
	v = pc_vector_writer,
	e = pc_entity_writer,
	xv4 = function(t)
		bytes = bytes + 24
		net.WriteUInt(3, 4)
		net.WriteUInt(t[1], 8)
		net.WriteUInt(t[2], 8)
		net.WriteUInt(t[3], 8)
	end,
}

local function printColorVarArg(self, ply, console, typeids, vararg)
	if not IsValid(ply) then return end
	if not checkDelay(ply) then return end
	bytes = 0

	max_len = math.min(maxLength:GetInt(), self.player:GetInfoNum("wire_expression2_print_max_length", defaultMaxLength))
	max_len = math.min(max_len + math.floor(max_len / 3), 65532) -- Add a third just to be nice

	net.Start("wire_expression2_printColor")
		net.WritePlayer(self.entity:GetPlayer())
		net.WriteBool(console)

		for i, tp in ipairs(typeids) do
			local fn = printcolor_writers[tp]
			if fn then
				fn(vararg[i])
			else
				pc_string_writer(repr(self, vararg[i], tp))
			end
			if bytes >= max_len then break end
		end

		net.WriteUInt(0, 4)

	net.Send(ply)

	self.prf = self.prf + bytes / 8
end

local function printColorArray(self, ply, console, arr)
	if not IsValid(ply) then return end
	if not checkDelay(ply) then return end
	bytes = 0

	max_len = math.min(maxLength:GetInt(), self.player:GetInfoNum("wire_expression2_print_max_length", defaultMaxLength))
	max_len = math.min(max_len + math.floor(max_len / 3), 65532)

	net.Start("wire_expression2_printColor")
		net.WritePlayer(self.entity:GetPlayer())
		net.WriteBool(console)

		for _, v in ipairs(arr) do
			local fn = printcolor_writers[TypeID(v)]
			if fn then
				fn(v)
			else
				pc_string_writer(tostring(v))
			end
			if bytes >= max_len then break end
		end

		net.WriteUInt(0, 4)

	net.Send(ply)

	self.prf = self.prf + bytes / 8
end


--- Works like [[chat.AddText]](...). Parameters can be any amount and combination of numbers, strings, player entities, color vectors (both 3D and 4D).
e2function void printColor(...args)
	printColorVarArg(self, self.player, false, typeids, args)
end

--- Like printColor(...), except taking an array containing all the parameters.
e2function void printColor(array arr)
	printColorArray(self, self.player, false, arr)
end

--- Works like MsgC(...). Parameters can be any amount and combination of numbers, strings, player entities, color vectors (both 3D and 4D).
e2function void printColorC(...args)
	printColorVarArg(self, self.player, true, typeids, args)
end

--- Like printColorC(...), except taking an array containing all the parameters.
e2function void printColorC(array arr)
	printColorArray(self, self.player, true, arr)
end

--- Like printColor(...), except printing in <this>'s driver's chat area instead of yours.
e2function void entity:printColorDriver(...args)
	if not checkVehicle(self, this) then return end

	local driver = this:GetDriver()
	if not IsValid(driver) then return end

	if not checkDelay( driver ) then return end

	printColorVarArg(self, driver, false, typeids, args)
end

--- Like printColor(R), except printing in <this>'s driver's chat area instead of yours.
e2function void entity:printColorDriver(array arr)
	if not checkVehicle(self, this) then return end

	local driver = this:GetDriver()
	if not IsValid(driver) then return end

	if not checkDelay( driver ) then return end

	printColorArray(self, driver, false, arr)
end

util.AddNetworkString( "wire_expression2_set_clipboard_text" )
local clipboard_character_limit = CreateConVar("wire_expression2_clipboard_character_limit", 512, FCVAR_ARCHIVE, "Maximum character that can be copied into a players clipboard", 0, 65532)
local clipboard_cooldown = CreateConVar("wire_expression2_clipboard_cooldown", 1, FCVAR_ARCHIVE, "Cooldown for setClipboardText in seconds", 0, nil)


-- TODO: Make an E2Lib.RegisterChipTable function that is essentially WireLib.RegisterPlayerTable, but handles chips.
local ClipboardCooldown = {}
registerCallback("destruct",function(self)
	ClipboardCooldown[self.entity] = nil
end)

__e2setcost(100)
e2function void setClipboardText(string text)
	if self.player:GetInfoNum("wire_expression2_clipboard_allow", 0) == 0 then
		return self:throw("setClipboardText is not enabled. You need to change the convar \"wire_expression2_clipboard_allow\" to enable it", nil)
	end

	if #text > clipboard_character_limit:GetInt() then
		return self:throw("setClipboardText exceeding string limit of " .. clipboard_character_limit:GetInt() .. " characters", nil)
	end

	local cooldown, now = ClipboardCooldown[self.entity], CurTime()
	if cooldown and now < cooldown then
		return self:throw("You must wait " .. clipboard_cooldown:GetInt() .. " second(s) before calling setClipboardText again.", nil)
	end

	ClipboardCooldown[self.entity] = now + clipboard_cooldown:GetInt()

	net.Start("wire_expression2_set_clipboard_text")
		net.WriteString(text)
	net.Send(self.player)
end


-- Closed Captions

util.AddNetworkString("wire_expression2_caption")

-- Maximum seconds a caption can be displayed for
local MAX_CAPTION_DURATION = 7

local function send_caption(self, text, duration, fromPlayer)
	if duration < 0 then return end -- <0 duration doesn't display normally
	local ply = self.player
	if not checkDelay(ply) then return end

	local max_len = math.min(maxLength:GetInt(), ply:GetInfoNum("wire_expression2_print_max_length", defaultMaxLength))

	text = string.sub(text, 1, max_len)
	duration = math.min(duration, MAX_CAPTION_DURATION)

	local len = #text

	self.prf = self.prf + len / 8

	net.Start("wire_expression2_caption")
		net.WriteUInt(len, 16)
		net.WriteData(text)
		net.WriteDouble(duration)
		net.WriteBool(fromPlayer)
	net.Send(ply)
end

__e2setcost(100)

e2function void printCaption(string text, number duration, number fromPlayer)
	send_caption(self, text, duration, fromPlayer)
end

e2function void printCaption(string text, number duration)
	send_caption(self, text, duration, false)
end