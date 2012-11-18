--------------------------------------------------------
-- Custom umsg System
--------------------------------------------------------
local EGP = EGP

local InProgress = false
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

-- Start
function EGP.umsg.Start( name )
	if InProgress then
		if (LastErrorTime + 1 < CurTime()) then
			ErrorNoHalt("[EGP] Umsg error. It seems another umsg is already sending, but it occured over 1 second ago. Ending umsg.")
			net.Broadcast()
		else
			ErrorNoHalt("[EGP] Umsg error. Another umsg is already sending!")
			if (LastErrorTime + 2 < CurTime()) then
				LastErrorTime = CurTime()
			end
			return false
		end
	end
	InProgress = true

	net.Start( name )
	return true
end
-- End
function EGP.umsg.End()
	net.Broadcast()
	InProgress = false
end