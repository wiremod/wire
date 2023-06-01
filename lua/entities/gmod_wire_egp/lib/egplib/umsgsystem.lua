--------------------------------------------------------
-- Custom umsg System
--------------------------------------------------------
local EGP = EGP

local CurSender
local curEnt
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
EGP.Broadcast = 0

function EGP.umsg.Start(name, sender, ent)
	if CurSender then
		if LastErrorTime + 1 < CurTime() then
			ErrorNoHalt("[EGP] Umsg error. It seems another umsg is already sending, but it occured over 1 second ago. Ending umsg.")
			EGP.umsg.End()
		else
			ErrorNoHalt("[EGP] Umsg error. Another umsg is already sending!")
			if LastErrorTime + 2 < CurTime() then
				LastErrorTime = CurTime()
			end
			return false
		end
	end
	CurSender = sender
	curEnt = ent
	
	net.Start(name)
	return true
end

function EGP.umsg.End()
	if CurSender then
		if not EGP.IntervalCheck[CurSender] then EGP.IntervalCheck[CurSender] = { bytes = 0, time = 0 } end
		EGP.IntervalCheck[CurSender].bytes = EGP.IntervalCheck[CurSender].bytes + net.BytesWritten()
	end
	
	if EGP.Broadcast > 0 then
		EGP.Broadcast = EGP.Broadcast - 1
		net.Broadcast()
	elseif curEnt.Users then
		local rf = RecipientFilter()
		
		-- Account for users who added themselves using egpHudToggle()
		if not curEnt.IsEGPHUD then
			rf:AddPVS(curEnt:GetPos())
		end
		
		for _, v in pairs(curEnt.Users) do
			rf:AddPlayer(v)
		end
		
		net.Send(rf)
	else
		net.SendPVS(curEnt:GetPos())
	end
	CurSender = nil
	curEnt = nil
end
