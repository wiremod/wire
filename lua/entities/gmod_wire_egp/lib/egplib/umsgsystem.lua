--------------------------------------------------------
-- Custom umsg System
--------------------------------------------------------
local EGP = EGP

local CurSender
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

function EGP.umsg.Start( name, sender )
	if CurSender then
		if (LastErrorTime + 1 < CurTime()) then
			ErrorNoHalt("[EGP] Umsg error. It seems another umsg is already sending, but it occured over 1 second ago. Ending umsg.")
			EGP.umsg.End()
		else
			ErrorNoHalt("[EGP] Umsg error. Another umsg is already sending!")
			if (LastErrorTime + 2 < CurTime()) then
				LastErrorTime = CurTime()
			end
			return false
		end
	end
	CurSender = sender

	net.Start( name )
	return true
end

function EGP.umsg.End()
	if CurSender then
		if not EGP.IntervalCheck[CurSender] then EGP.IntervalCheck[CurSender] = { bytes = 0, time = 0 } end
		EGP.IntervalCheck[CurSender].bytes = EGP.IntervalCheck[CurSender].bytes + net.BytesWritten()
	end
	net.Broadcast()
	CurSender = nil
end
