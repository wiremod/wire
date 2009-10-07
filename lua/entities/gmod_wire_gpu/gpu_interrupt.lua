//INTERRUPTS TABLE
//Value | Meaning
//---------------------------------------------------------------------
//2	| End of program
//3	| Division by zero
//4	| Unknown opcode
//5	| Internal processor error
//6	| Stack error (overflow/underflow)
//7	| Memory read/write fault
//13	| General processor fault
//15	| Address space violation
//------|---------------------------------------------------------------
//16	| Pants integrity violation
//17	|
//18	|
//19	|
//20	|
//21	|
//22	|
//23	| String read error
//24	|
//25	|
//----------------------------------------------------------------------

function ENT:InitializeErrors()
	self.ErrorText = {}
	//                   |                      |
	self.ErrorText[2]  = "unexpected program end"
	self.ErrorText[3]  = "division by zero"
	self.ErrorText[4]  = "unknown opcode"
	//                   |                      |
	self.ErrorText[5]  = "internal gpu error"
	//                   |                      |
	self.ErrorText[6]  = "stack error"
	self.ErrorText[7]  = "memory read/write fault"
	self.ErrorText[13] = "general processor fault"
	self.ErrorText[15] = "addr space violation"
	self.ErrorText[16] = "pants violation!!!"
	self.ErrorText[23] = "string read error"
	//                   |                      |
end

function ENT:Interrupt(intnumber,intparam)
	if (self.INTR == 1) then return end
	self.INTR = 1
	self.HandleError = 1
	if (not self.EntryPoint[3]) then
		self:OutputError(intnumber,intparam)
	end
end
