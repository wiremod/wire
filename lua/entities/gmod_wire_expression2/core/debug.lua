-- import some e2lib and math functions
local IsValid  = IsValid
local isOwner      = E2Lib.isOwner
local Clamp        = math.Clamp
local seq = table.IsSequential

/******************************************************************************/

local function checkOwner(self)
	return IsValid(self.player);
end

/******************************************************************************/

-- default delay for printing messages, adds one "charge" after this delay
local defaultPrintDelay = 0.3
-- the amount of "charges" a player has by default
local defaultMaxPrints = 15

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
		local chargesToAdd = math.floor(timePassed / chargesDelay)
		printDelay.numCharges = printDelay.numCharges + chargesToAdd
		-- add "semi" charges the player might already have
		printDelay.lastTime = (currentTime - (timePassed % chargesDelay))
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

/******************************************************************************/

-- Returns whether or not the next print-message will be printed or omitted by antispam
e2function number playerCanPrint()
	if not checkOwner(self) then return end
	return (canPrint(self.player) and 1 or 0)
end

local function SpecialCase( arg )
	if istable(arg) then
		if (arg.isfunction) then
			return "function " .. arg[3] .. " = (" .. arg[2] .. ")"
		elseif (seq(arg)) then -- A table with only numerical indexes
			local str = "["
			for k,v in ipairs( arg ) do
				if istable(v) then
					if (k != #arg) then
						str = str .. SpecialCase( v ) .. ","
					else
						str = str .. SpecialCase( v ) .. "]"
					end
				else
					if (k != #arg) then
						str = str .. tostring(v) .. ","
					else
						str = str .. tostring(v) .. "]"
					end
				end
			end
			return str
		else -- Else it's a table with string indexes (which this function can't handle)
			return "[table]"
		end
	end
end

-- Prints <...> like lua's print(...), except to the chat area
e2function void print(...)
	if not checkOwner(self) then return end
	if not checkDelay( self.player ) then return end
	local args = {...}
	local nargs = select("#", ...)
	if nargs>0 then
		for i=1, math.min(nargs, 256) do
			local v = args[i]
			args[i] = string.Left(SpecialCase( v ) or tostring(v), 249)
		end
		local text = table.concat(args, "\t")
		if #text>0 then
			self.player:ChatPrint(string.Left(text,249)) -- Should we switch to net messages? We probably don't want to print more than 249 chars at once anyway
		end
	end
end

--- Posts <text> to the chat area. (deprecated due to print(...))
--e2 function void print(string text)
--	self.player:ChatPrint(text)
--end

--- Posts a string to the chat of <this>'s driver. Returns 1 if the text was printed, 0 if not.
e2function number entity:printDriver(string text)
	if not IsValid(this) then return 0 end
	if not this:IsVehicle() then return 0 end
	if not isOwner(self, this) then return 0 end
	if text:find('"', 1, true) then return 0 end

	local driver = this:GetDriver()
	if not IsValid(driver) then return 0 end

	if not checkDelay( driver ) then return 0 end

	driver:ChatPrint(string.Left(text,249))
	return 1
end

/******************************************************************************/

--- Displays a hint popup with message <text> for <duration> seconds (<duration> being clamped between 0.7 and 7).
e2function void hint(string text, duration)
	if not IsValid(self.player) then return end
	if not checkDelay( self.player ) then return end
	WireLib.AddNotify(self.player, string.Left(text,249), NOTIFY_GENERIC, Clamp(duration,0.7,7))
end

--- Displays a hint popup to the driver of vehicle E, with message <text> for <duration> seconds (<duration> being clamped between 0.7 and 7). Same return value as printDriver.
e2function number entity:hintDriver(string text, duration)
	if not IsValid(this) then return 0 end
	if not this:IsVehicle() then return 0 end
	if not isOwner(self, this) then return 0 end

	local driver = this:GetDriver()
	if not IsValid(driver) then return 0 end

	if not checkDelay( driver ) then return 0 end

	WireLib.AddNotify(driver, string.Left(text,249), NOTIFY_GENERIC, Clamp(duration,0.7,7))
	return 1
end

/******************************************************************************/

local valid_print_types = {}
for _,cname in ipairs({ "HUD_PRINTCENTER", "HUD_PRINTCONSOLE", "HUD_PRINTNOTIFY", "HUD_PRINTTALK" }) do
	local value = _G[cname]
	valid_print_types[value] = true
	E2Lib.registerConstant(cname, value)
end

--- Same as print(<text>), but can make the text show up in different places. <print_type> can be one of the following: _HUD_PRINTCENTER, _HUD_PRINTCONSOLE, _HUD_PRINTNOTIFY, _HUD_PRINTTALK.
e2function void print(print_type, string text)
	if (not checkOwner(self)) then return; end
	if not valid_print_types[print_type] then return end
	if not checkDelay( self.player ) then return end

	self.player:PrintMessage(print_type, string.Left(text,249))
end

--- Same as <this>E:printDriver(<text>), but can make the text show up in different places. <print_type> can be one of the following: _HUD_PRINTCENTER, _HUD_PRINTCONSOLE, _HUD_PRINTNOTIFY, _HUD_PRINTTALK.
e2function number entity:printDriver(print_type, string text)
	if not IsValid(this) then return 0 end
	if not this:IsVehicle() then return 0 end
	if not isOwner(self, this) then return 0 end
	if not valid_print_types[print_type] then return 0 end
	if text:find('"', 1, true) then return 0 end

	local driver = this:GetDriver()
	if not IsValid(driver) then return 0 end

	if not checkDelay( driver ) then return 0 end

	driver:PrintMessage(print_type, string.Left(text,249))
	return 1
end

/******************************************************************************/

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
			if ( isnumber( a ) && isnumber( b ) ) then return a < b end
			return tostring( a ) < tostring( b )
		end )

		for i = 1, #keys do
			local key = keys[ i ]
			local value = t[ key ]
			Msg( string.rep( "\t", indent ) )

			if  ( istable( value ) && !done[ value ] ) then

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

--- Prints an array like the lua function [[G.PrintTable|PrintTable]] does, except to the chat area.
e2function void printTable(array arr)
	if not checkOwner(self) then return end
	if not checkDelay( self.player ) then return end

	for _,line in ipairs(string.Explode("\n",PrintTableToString(arr))) do
		self.player:ChatPrint(line)
	end
end

-- The printTable(T) function is in table.lua because it uses a local function

/******************************************************************************/

__e2setcost(100)

util.AddNetworkString("wire_expression2_printColor")

local printColor_typeids = {
	n = tostring,
	s = function(text) return string.Left(text,249) end,
	v = function(v) return Color(v[1],v[2],v[3]) end,
	xv4 = function(v) return Color(v[1],v[2],v[3],v[4]) end,
	e = function(e) return IsValid(e) and e:IsPlayer() and e or "" end,
}

local function printColorVarArg(chip, ply, console, typeids, ...)
	if not IsValid(ply) then return end
	if not checkDelay(ply) then return end
	local send_array = { ... }

	local i = 1
	for i,tp in ipairs(typeids) do
		if printColor_typeids[tp] then
			send_array[i] = printColor_typeids[tp](send_array[i])
		else
			send_array[i] = ""
		end
		if i == 256 then break end
		i = i + 1
	end

	net.Start("wire_expression2_printColor")
		net.WriteEntity(chip)
		net.WriteBool(console)
		net.WriteTable(send_array)
	net.Send(ply)
end

local printColor_types = {
	number = tostring,
	string = function(text) return string.Left(text,249) end,
	Vector = function(v) return Color(v[1],v[2],v[3]) end,
	table = function(tbl)
		for i,v in pairs(tbl) do
			if !isnumber(i) then return "" end
			if !isnumber(v) then return "" end
			if i < 1 or i > 4 then return "" end
		end
		return Color(tbl[1] or 0, tbl[2] or 0,tbl[3] or 0,tbl[4])
	end,
	Player = function(e) return IsValid(e) and e:IsPlayer() and e or "" end,
}

local function printColorArray(chip, ply, console, arr)
	if (not IsValid(ply)) then return; end
	if not checkDelay( ply ) then return end

	local send_array = {}

	local i = 1
	for i,tp in ipairs_map(arr,type) do
		if printColor_types[tp] then
			send_array[i] = printColor_types[tp](arr[i])
		else
			send_array[i] = ""
		end
		if i == 256 then break end
		i = i + 1
	end

	net.Start("wire_expression2_printColor")
		net.WriteEntity(chip)
		net.WriteBool(console)
		net.WriteTable(send_array)
	net.Send(ply)
end


--- Works like [[chat.AddText]](...). Parameters can be any amount and combination of numbers, strings, player entities, color vectors (both 3D and 4D).
e2function void printColor(...)
	printColorVarArg(nil, self.player, false, typeids, ...)
end

--- Like printColor(...), except taking an array containing all the parameters.
e2function void printColor(array arr)
	printColorArray(nil, self.player, false, arr)
end

--- Works like MsgC(...). Parameters can be any amount and combination of numbers, strings, player entities, color vectors (both 3D and 4D).
e2function void printColorC(...)
	printColorVarArg(nil, self.player, true, typeids, ...)
end

--- Like printColorC(...), except taking an array containing all the parameters.
e2function void printColorC(array arr)
	printColorArray(nil, self.player, true, arr)
end

--- Like printColor(...), except printing in <this>'s driver's chat area instead of yours.
e2function void entity:printColorDriver(...)
	if not IsValid(this) then return end
	if not this:IsVehicle() then return end
	if not isOwner(self, this) then return end

	local driver = this:GetDriver()
	if not IsValid(driver) then return end

	if not checkDelay( driver ) then return end

	printColorVarArg(self.entity, driver, false, typeids, ...)
end

--- Like printColor(R), except printing in <this>'s driver's chat area instead of yours.
e2function void entity:printColorDriver(array arr)
	if not IsValid(this) then return end
	if not this:IsVehicle() then return end
	if not isOwner(self, this) then return end

	local driver = this:GetDriver()
	if not IsValid(driver) then return end

	if not checkDelay( driver ) then return end

	printColorArray(self.entity, driver, false, arr)
end
