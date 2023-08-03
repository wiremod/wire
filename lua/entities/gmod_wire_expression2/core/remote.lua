-- New event based version of gtables/datasignals.
-- Allows passing tables to other Expression 2 chips, triggering an event.
-- So it is like datasignals in terms of being able to trigger actions, but also like gTables in sharing data (since the table is not copied).

E2Lib.registerEvent("remote", {
	{ "Sender", "e" },
	{ "Player", "e" },
	{ "Payload", "t" }
})

__e2setcost(100)
e2function void entity:sendRemoteEvent(table payload)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if this:GetClass() ~= "gmod_wire_expression2" then return self:throw("Expected an E2 chip, got Entity", nil) end

	this:ExecuteEvent("remote", {
		self.entity,
		self.player,
		payload
	})
end

__e2setcost(200)
e2function void broadcastRemoteEvent(table payload)
	E2Lib.triggerEventOmit("remote", {
		self.entity,
		self.player,
		payload
	}, { [self.entity] = true })
end