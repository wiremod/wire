-- Timedpairs by Grocel. (Rewrite by Divran)
-- It allows you to go through long tables, but without game freezing.
-- Its like a for-pairs loop.
--
-- How to use:
-- WireLib.Timedpairs(string unique name, table, number ticks done at once, function tickcallback[, function endcallback, ...])
--
-- tickcallback is called every tick, it ticks for each KeyValue of the table.
-- Its arguments are the current key and value.
-- Return false in the tickcallback function to break the loop.
-- tickcallback(key, value, ...)
--
-- endcallback is called after the last tickcallback has been called.
-- Its arguments are the same as the last arguments of WireLib.Timedpairs
-- endcallback(lastkey, lastvalue, ...)

if (not WireLib) then return end

local next = next
local pairs = pairs
local unpack = unpack
local pcall = pcall

local functions = {}
function WireLib.TimedpairsGetTable()
	return functions
end

function WireLib.TimedpairsStop(name)
	functions[name] = nil
end

local function copy( t ) -- custom table copy function to convert to numerically indexed table
	local ret = {}
	for k,v in pairs( t ) do
		ret[#ret+1] = { key = k, value = v }
	end
	return ret
end

local function Timedpairs()
	if not next(functions) then return end

	local toremove = {}

	for name, data in pairs( functions ) do
		for i=1,data.step do
			data.currentindex = data.currentindex + 1 -- increment index counter
			local lookup = data.lookup or {}
			if data.currentindex <= #lookup then -- If there are any more values..
				local kv = lookup[data.currentindex] or {} -- Get the current key and value
				local ok, err = xpcall( data.callback, debug.traceback, kv.key, kv.value, unpack(data.args) ) -- DO EET

				if not ok then -- oh noes
					WireLib.ErrorNoHalt( "Error in Timedpairs '" .. name .. "': " .. err )
					toremove[#toremove+1] = name
					break
				elseif err == false then -- They returned false inside the function
					toremove[#toremove+1] = name
					break
				end
			else -- Out of keys. Entire table looped
				if data.endcallback then -- If we had any end callback function
					local kv = lookup[data.currentindex-1] or {} -- get previous key & value
					local ok, err = xpcall( data.endcallback, debug.traceback, kv.key, kv.value, unpack(data.args) )

					if not ok then
						WireLib.ErrorNoHalt( "Error in Timedpairs '" .. name .. "' (in end function): " .. err )
					end
				end
				toremove[#toremove+1] = name
				break
			end
		end
	end

	for i=1,#toremove do -- Remove all that were flagged for removal
		functions[toremove[i]] = nil
	end
end
if (CLIENT) then
	hook.Add("PostRenderVGUI", "WireLib_Timedpairs", Timedpairs) // Doesn't get paused in single player. Can be important for vguis.
else
	hook.Add("Think", "WireLib_Timedpairs", Timedpairs) // Servers still uses Think.
end

function WireLib.Timedpairs(name,tab,step,callback,endcallback,...)
	functions[name] = { lookup = copy(tab), step = step, currentindex = 0, callback = callback, endcallback = endcallback, args = {...} }
end

function WireLib.Timedcall(callback,...) // calls the given function like simple timer, but isn't affected by game pausing.
	local dummytab = {true}
	WireLib.Timedpairs("Timedcall_"..tostring(dummytab),dummytab,1,function(k, v, ...) callback(...) end,nil,...)
end
