--------------------------------------------------------
-- Custom umsg System
--------------------------------------------------------
local EGP = EGP

local CurrentCost = 0
local LastErrorTime = 0
--[[ Transmit Sizes:
	Angle = 12
	Bool = 1
	Char = 1
	Entity = 2
	Float = 4
	Long = 4
	Short = 2
	String = string length
	Vector = 12
	VectorNormal = 12
]]



EGP.umsg = {}

-- Allow others to get the current cost
function EGP.umsg.CurrentCost() return CurrentCost end

-- Start
function EGP.umsg.Start( name, recipient )
	if (CurrentCost != 0) then
		if (LastErrorTime + 1 < CurTime()) then
			ErrorNoHalt("[EGP] Umsg error. It seems another umsg is already sending, but it occured over 1 second ago. Ending umsg.")
			umsg.End()
		else
			ErrorNoHalt("[EGP] Umsg error. Another umsg is already sending!")
			if (LastErrorTime + 2 < CurTime()) then
				LastErrorTime = CurTime()
			end
			return false
		end
	end
	CurrentCost = 0

	umsg.Start( name, recipient )
	return true
end
-- End
function EGP.umsg.End()
	CurrentCost = 0
	umsg.End()
end
-- Angle
function EGP.umsg.Angle( data )
	CurrentCost = CurrentCost + 12
	umsg.Angle( data )
end
-- Boolean
function EGP.umsg.Bool( data )
	CurrentCost = CurrentCost + 1
	umsg.Bool( data )
end
-- Char
function EGP.umsg.Char( data )
	CurrentCost = CurrentCost + 1
	umsg.Char( data )
end
-- Entity
function EGP.umsg.Entity( data )
	CurrentCost = CurrentCost + 2
	umsg.Entity( data )
end
-- Float
function EGP.umsg.Float( data )
	CurrentCost = CurrentCost + 4
	umsg.Float( data )
end
-- Long
function EGP.umsg.Long( data )
	CurrentCost = CurrentCost + 4
	umsg.Long( data )
end
-- Short
function EGP.umsg.Short( data )
	CurrentCost = CurrentCost + 2
	umsg.Short( data )
end
-- String
function EGP.umsg.String( data )
	CurrentCost = CurrentCost + #(data or " ")
	umsg.String( data )
end
-- Vector
function EGP.umsg.Vector( data )
	CurrentCost = CurrentCost + 12
	umsg.Vector( data )
end
-- VectorNormal
function EGP.umsg.VectorNormal( data )
	CurrentCost = CurrentCost + 12
	umsg.VectorNormal( data )
end
