//INTERRUPTS TABLE
//Value | Meaning
//---------------------------------------------------------------------
//2	| End of program execution
//3	| Division by zero
//4	| Unknown opcode
//5	| Internal processor error
//6	| Stack error (overflow/underflow)
//7	| Memory read/write fault
//8	| MemBus fault
//9	| Write access violation (page protection)
//10	| Port read/write fault
//11	| Page acccess violation (page protection)
//12	| Read access violation (page protection)
//13	| General processor fault
//14	| Execute access violation (page protection)
//15	| Address space violation
//31	| Debug trap
//----------------------------------------------------------------------

function ENT:NMIInterrupt(intnumber)
	if ((self.IF == 1) &&
	     self:Push(self.LS) &&
	     self:Push(self.KS) &&
	     self:Push(self.ES) &&
	     self:Push(self.GS) &&
	     self:Push(self.FS) &&
	     self:Push(self.DS) &&
	     self:Push(self.SS) &&
	     self:Push(self.CS) &&

	     self:Push(self.EDI) &&
	     self:Push(self.ESI) &&
	     self:Push(self.ESP) &&
	     self:Push(self.EBP) &&
	     self:Push(self.EDX) &&
	     self:Push(self.ECX) &&
	     self:Push(self.EBX) &&
	     self:Push(self.EAX) &&

	     self:Push(self.CMPR) &&
	     self:Push(self.IP)) then
			self:Interrupt(intnumber,0,1)
	end
end

function ENT:Interrupt(intnumber,intparam,isNMI)
	if (self.Compiling) then
		self.FatalError = true
		return
	end
	if (self.AuxIO == 1) then
		if (self.Debug) then
			self:DebugMessage("EXTERNAL INTERRUPT: #"..intnumber.."\nADDRESS: "..self.XEIP.."\nPARAM="..intparam.."\nLastReadAddress="..self.LADD)
		end
		return
	end
	if (self.Debug) then
		if (self.INTR == 0) then
			self:DebugMessage("INTERRUPT: #"..intnumber.."\nADDRESS: "..self.XEIP.."\nPARAM="..intparam.."\nLastReadAddress="..self.LADD)
		else
			self:DebugMessage("CASCADE INTERRUPT: #"..intnumber.."\nADDRESS: "..self.XEIP.."\nLastReadAddress="..self.LADD)
		end
	end


	if (self.INTR == 1) then return end
	self.INTR = 1
	self.BusLock = 1
	self.LINT = intnumber
	if (intparam) then self.LADD = intparam else self.LADD = self.XEIP end

	local fracparam = intparam
	if (intparam ~= 0) then
		while (math.floor(fracparam) >= 1) do
			fracparam = fracparam / 10
		end
	end
	Wire_TriggerOutput(self, "Error", intnumber+fracparam)

	if (self.IF == 1) then
		if (self.PF == 0) && (self.EF == 0) then
			if (intnumber < 0) or (intnumber > 255) or (intnumber > self.NIDT-1) then
				//Not handled
				return
			end
			if (intnumber == 0) then
				self:Reset()
				return
			end

			if (intnumber ~= 31) then //Don't die on debug trap
				self.Clk = 0
			end
			return
		else
			if (self.EF == 1) then	//4 bytes interrupt table
				if (intnumber < 0) or (intnumber > 255) then
					self.INTR = 0
					self:Interrupt(13,3)
					return
				end

				if (intnumber > self.NIDT-1) then
					if (intnumber == 0) then
						self:Reset()
					end
					if (intnumber == 1) then
						self.Clk = 0
					end
					return
				end

				local intaddress = self.IDTR + intnumber*4

				self.BusLock = 0
				self:SetCurrentPage(intaddress)
				local int_ip    =                      self:ReadCell(intaddress+0)
				local int_cs    =                      self:ReadCell(intaddress+1)
				local int_      =                      self:ReadCell(intaddress+2)
				local int_flags = self:IntegerToBinary(self:ReadCell(intaddress+3))
				self:SetCurrentPage(self.XEIP)
				self:SetPrevPage(intaddress) //set interrupt page as previous one
				self.BusLock = 1

				//WARNING:
				//if you use runlevel protection, then interrupts can be called from
				//user program even if its not runlevel 0 UNLESS you will set
				//runlevel of pages where interrupt table is located to non-zero
				//
				//When interrupt table runlevel is non-zero, you will only be able
				//to call those interrupts, which handlers are also located on pages
				//with non-zero runlevel

				//Flags:
				//3  [8 ] = CMPR shows if interrupt occured
				//4  [16] = Interrupt does not set CS
				//5  [32] = Interrupt enabled
				//6  [64] = NMI interrupt

				if ((isNMI) and (int_flags[6] ~= 1)) then
					self.INTR = 0
					self:Interrupt(13,4)
					return
				end

				if (int_flags[5] == 1) then
					if (self.Debug) then self:DebugMessage("INTERRUPT: #"..intnumber.." HANDLED\nJumpOffset="..int_ip..":"..int_cs.."\n") end

					self.BusLock = 0
					self:Push(self.IP)
					self:Push(self.CS)
					self.BusLock = 1

					self.IP = int_ip
					if (int_flags[4] == 0) then
						self.CS = int_cs
					end

					if (int_flags[3] == 1) then
						self.CMPR = 1
					end
				else
					if (intnumber == 0) then
						self:Reset()
					end
					if (intnumber == 1) then
						self.Clk = 0
					end
					if (int_flags[3] == 1) then
						self.CMPR = -1
					end
				end
			else //2 bytes interrupt table
				if (intnumber < 0) or (intnumber > 255) then
					self.INTR = 0
					self:Interrupt(13,3)
					return
				end

				local intaddress = self.IDTR + intnumber*2
				if (intaddress > 65535) then intaddress = 65535 end
				if (intaddress < 0) then intaddress = 0 end
				local intoffset = self.Memory[intaddress]
				local intprops = self.Memory[intaddress+1]
				if ((intprops == 32) || (intprops == 96)) then //Interrupt active, temp fix
					if (self.Debug) then
						self:DebugMessage("INTERRUPT: #"..intnumber.." HANDLED\nJumpOffset="..intoffset.."\n")
					end

					self.BusLock = 0
					if (intnumber == 4 ) ||
					   (intnumber == 7 ) ||
					   (intnumber == 9 ) ||
					   (intnumber == 10) then
						self:Push(self.LADD)
					end
					if (intnumber == 4 ) ||
					   (intnumber == 31) then //If wrong opcode or debug trap, then store
						self:Push(self.ILTC)
					end
					if self:Push(self.IP) then //Store IRET
						self:Push(self.XEIP)
						self.IP = intoffset
					end
					self.CMPR = 0
					self.BusLock = 1
				else
					if (intnumber == 1) then
						self.Clk = 0
					end
					self.CMPR = 1
				end
			end
		end
	end
	self.BusLock = 0
end

