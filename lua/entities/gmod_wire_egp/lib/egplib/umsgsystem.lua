--------------------------------------------------------
-- Custom umsg System
--------------------------------------------------------
local EGP = E2Lib.EGP

local CurSender = NULL
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
	if CurSender:IsValid() then
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

	net.Start(name)
	return true
end

function EGP.umsg.End( ent )
	if CurSender:IsValid() then
		if not EGP.IntervalCheck[CurSender] then EGP.IntervalCheck[CurSender] = { bytes = 0, time = 0 } end
		local bytes = net.BytesWritten()
		if bytes then
			EGP.IntervalCheck[CurSender].bytes = EGP.IntervalCheck[CurSender].bytes + bytes
		else
			ErrorNoHalt("Tried to end EGP net message outside of net context?")
		end

		if ent.Users then
			local sendTbl = {}
			for ply, _ in pairs(ent.Users) do
				if ply:IsValid() then
					table.insert(sendTbl, ply)
				end
			end

			net.Send(sendTbl)
		else
			net.Broadcast()
		end
	else
		net.Send(NULL)
	end
	CurSender = NULL
end
