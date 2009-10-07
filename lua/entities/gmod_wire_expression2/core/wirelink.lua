/******************************************************************************\
  Wire link support
\******************************************************************************/

registerCallback("construct", function(self)
	self.triggercache = {}
end)

registerCallback("postexecute", function(self)
	for _,ent,portname,value in pairs_map(self.triggercache, unpack) do
		WireLib.TriggerInput(ent, portname, value)
	end

	self.triggercache = {}
end)

local function TriggerInput(self,ent, portname, value, typename)
	if not ent.Inputs[portname] then return value end
	if ent.Inputs[portname].Type ~= typename then return value end

	self.triggercache[ent:EntIndex().."__"..portname] = { ent, portname, value }

	return value
end

/******************************************************************************/

local function WriteStringZero(entity, address, string)
	if not entity:WriteCell(address+#string, 0) then return 0 end

	for index = 1,#string do
		local byte = string.byte(string,index)
		if not entity:WriteCell(address+index-1, byte) then return 0 end
	end
	return address+#string+1
end

local function ReadStringZero(entity, address)
	local byte
	local tbl = {}
	for index = address,address+16384 do
		byte = entity:ReadCell(index, byte)
		if not byte then return "" end
		if byte < 1 then break end
		if byte >= 256 then byte = 32 end
		table.insert(tbl,string.char(math.floor(byte)))
	end
	return table.concat(tbl)
end

local wa_lookup -- lookup table for tables that were already serialized.
local function WriteArray(entity, address, data)
	-- check if enough space is available
	if not entity:WriteCell(address+#data-1, 0) then return 0 end

	-- write the trailing 0 byte.
	entity:WriteCell(address+#data, 0)
	local free_address = address+#data+1

	for index, value in ipairs(data) do
		local tp = type(value)
		if tp == "number" then
			if not entity:WriteCell(address+index-1, value) then return 0 end
		elseif tp == "string" then
			if not entity:WriteCell(address+index-1, free_address) then return 0 end
			free_address = WriteStringZero(entity, free_address, value)
			if free_address == 0 then return 0 end
		elseif tp == "table" then
			if wa_lookup[value] then
				if not entity:WriteCell(address+index-1, wa_lookup[value]) then return 0 end
			else
				wa_lookup[value] = free_address
				if not entity:WriteCell(address+index-1, free_address) then return 0 end
				free_address = WriteArray(entity, free_address, value)
			end
		elseif tp == "Vector" then
			if not entity:WriteCell(address+index-1, free_address) then return 0 end
			free_address = WriteArray(entity, free_address, { value[1], value[2], value[3] })
		end
	end
	return free_address
end

/******************************************************************************/

registerType("wirelink", "xwl", nil,
	nil,
	nil,
	function(retval)
		if validEntity(retval) then return end
		if retval ~= nil and retval.EntIndex then error("Return value is neither nil nor an Entity, but a "..type(retval).."!",0) end
	end
)

/******************************************************************************/

__e2setcost(2) -- temporary

e2function wirelink operator=(wirelink lhs, wirelink rhs)
	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

/******************************************************************************/

e2function number operator_is(wirelink value)
	if not validEntity(value) then return 0 end
	if value.extended then return 1 else return 0 end
end

e2function number operator==(wirelink lhs, wirelink rhs)
	if lhs == rhs then return 1 else return 0 end
end

e2function number operator!=(wirelink lhs, wirelink rhs)
	if lhs ~= rhs then return 1 else return 0 end
end

/******************************************************************************/

e2function number wirelink:isHiSpeed()
	if not validEntity(this) then return 0 end
	if not this.extended then return 0 end
	if this.WriteCell or this.ReadCell then return 1 else return 0 end
end

e2function entity wirelink:entity()
	return this
end

/******************************************************************************/

e2function number wirelink:hasInput(string portname)
	if not validEntity(this) then return 0 end
	if not this.extended then return 0 end

	if not this.Inputs[portname] then return 0 end
	return 1
end

e2function number wirelink:hasOutput(string portname)
	if not validEntity(this) then return 0 end
	if not this.extended then return 0 end

	if not this.Outputs[portname] then return 0 end
	return 1
end

/******************************************************************************/
// THESE NEED TO USE THE INPUT/OUTPUT SERIALIZERS! (not numbers)
// THE VALUES SHOULD BE SAVED AND PUSHED ON POST EXECUTION

-- n v a e s
-- x - - ~ x
registerCallback("postinit", function()

	local getf, setf
	-- generate getters and setters for all types
	-- <input serializer>, <output serializer>, <type checker>
	for typename,id,zero,input_serializer,output_serializer,type_checker in pairs_map(wire_expression_types, unpack) do
		print(typename,id,zero,input_serializer,output_serializer,type_checker)
		local fname = typename == "NORMAL" and "NUMBER" or typename

		-- for T:number() etc
		local getter = fname:lower()

		-- for T:setNumber() etc
		local setter = "set"..fname:sub(1,1):upper()..fname:sub(2):lower()

		if input_serializer then
			--TODO {}
			function getf(self, args)
				local this, portname = args[2], args[3]
				this, portname = this[1](self, this), portname[1](self, portname)

				if not validEntity(this) then return zero end
				if not this.extended then return zero end

				if not this.Outputs[portname] then return zero end
				if this.Outputs[portname].Type ~= typename then return zero end

				return input_serializer(self, this.Outputs[portname].Value)
			end
		else
			function getf(self, args)
				local this, portname = args[2], args[3]
				this, portname = this[1](self, this), portname[1](self, portname)

				if not validEntity(this) then return zero end
				if not this.extended then return zero end

				if not this.Outputs[portname] then return zero end
				if this.Outputs[portname].Type ~= typename then return zero end

				return this.Outputs[portname].Value
			end
		end

		if output_serializer then
			function setf(self, args)
				local this, portname, value = args[2], args[3], args[4]
				this, portname, value = this[1](self, this), portname[1](self, portname), value[1](self, value)

				if not validEntity(this) then return value end
				if not this.extended then return value end

				TriggerInput(self, this, portname, output_serializer(self, value), typename)
				return value
			end
		else
			function setf(self, args)
				local this, portname, value = args[2], args[3], args[4]
				this, portname, value = this[1](self, this), portname[1](self, portname), value[1](self, value)

				if not validEntity(this) then return value end
				if not this.extended then return value end

				TriggerInput(self, this, portname, value, typename)
				return value
			end
		end

		registerFunction(getter, "xwl:s", id, getf, 5)
		registerOperator("idx", id.."=xwls", id, getf, 5)
		registerFunction(setter, "xwl:s"..id, id, setf, 5)
		registerOperator("idx", id.."=xwls"..id, id, setf, 5)
	end
end)

__e2setcost(15) -- temporary

e2function void wirelink:setXyz(vector value)
	if not validEntity(this) then return end
	if not this.extended then return end

	TriggerInput(self, this, "X", value[1], "NORMAL")
	TriggerInput(self, this, "Y", value[2], "NORMAL")
	TriggerInput(self, this, "Z", value[3], "NORMAL")
end

e2function vector wirelink:xyz()
	if not validEntity(this) then return { 0, 0, 0 } end
	if not this.extended then return { 0, 0, 0 } end

	local x, y, z = this.Outputs["X"], this.Outputs["Y"], this.Outputs["Z"]

	if not x or not y or not z then return { 0, 0, 0 } end
	if x.Type ~= "NORMAL" or y.Type ~= "NORMAL" or z.Type ~= "NORMAL" then return { 0, 0, 0 } end
	return { x.Value, y.Value, z.Value }
end

/******************************************************************************/
-- XWL:inputs/outputs/inputType/outputType by jeremydeath

--- Returns an array of all the inputs that <this> has without their types. Returns an empty array if it has none
e2function array wirelink:inputs()
	if(!validEntity(this)) then return {} end
	if(!this.extended) then return {} end
	if(!this.Inputs) then return {} end

	local InputNames = {}
	for k,v in pairs_sortvalues(this.Inputs, WireLib.PortComparator) do
		table.insert(InputNames,k)
	end
	return InputNames
end

--- Returns an array of all the outputs that <this> has without their types. Returns an empty array if it has none
e2function array wirelink:outputs()
	if(!validEntity(this)) then return {} end
	if(!this.extended) then return {} end
	if(!this.Outputs) then return {} end

	local OutputNames = {}
	for k,v in pairs_sortvalues(this.Outputs, WireLib.PortComparator) do
		table.insert(OutputNames,k)
	end
	return OutputNames
end

--- Returns the type of input that <Input> is in lowercase. ( "NORMAL"  is changed to "number" )
e2function string wirelink:inputType(string Input)
	if(!validEntity(this)) then return "" end
	if(!this.extended) then return "" end
	if(!this.Inputs or !this.Inputs[Input]) then return "" end

	local Type = this.Inputs[Input].Type or ""
	if Type == "NORMAL" then Type = "number" end
	return string.lower(Type)
end

--- Returns the type of output that <Output> is in lowercase. ( "NORMAL"  is changed to "number" )
e2function string wirelink:outputType(string Output)
	if(!validEntity(this)) then return "" end
	if(!this.extended) then return "" end
	if(!this.Outputs or !this.Outputs[Output]) then return "" end

	local Type = this.Outputs[Output].Type or ""
	if Type == "NORMAL" then Type = "number" end
	return string.lower(Type)
end

/******************************************************************************/

__e2setcost(5) -- temporary

e2function number wirelink:writeCell(address, value)
	if not validEntity(this) then return 0 end
	if not this.extended then return 0 end

	if not this.WriteCell then return 0 end
	if this:WriteCell(address, value) then return 1 else return 0 end
end

e2function number wirelink:readCell(address)
	if not validEntity(this) then return 0 end
	if not this.extended then return 0 end

	if not this.ReadCell then return 0 end
	return this:ReadCell(address) or 0
end

e2function number wirelink:operator[](address, value)
	if not validEntity(this) then return value end
	if not this.extended then return value end

	if not this.WriteCell then return value end
	this:WriteCell(address, value)
	return value
end
e2function number wirelink:operator[](address) = e2function number wirelink:readCell(address)

/******************************************************************************/

__e2setcost(20) -- temporary

--- XWL[N,vector]=V
e2function vector wirelink:operator[T](address, vector value)
	if not validEntity(this) then return value end
	if not this.extended then return value end

	if not this.WriteCell then return value end
	this:WriteCell(address, value[1])
	this:WriteCell(address+1, value[2])
	this:WriteCell(address+2, value[3])
	return value
end

--- V=XWL[N,vector]
e2function vector wirelink:operator[T](address)
	if not validEntity(this) then return { 0, 0, 0 } end
	if not this.extended then return { 0, 0, 0 } end

	if not this.ReadCell then return 0 end
	return {
		this:ReadCell(address) or 0,
		this:ReadCell(address+1) or 0,
		this:ReadCell(address+2) or 0,
	}
end

--- XWL[N,string]=S
e2function string wirelink:operator[T](address, string value)
	if not validEntity(this) or not this.extended or not this.WriteCell then return "" end
	WriteStringZero(this, address, value)
	return value
end

--- S=XWL[N,string]
e2function string wirelink:operator[T](address)
	if not validEntity(this) or not this.extended or not this.ReadCell then return "" end
	return ReadStringZero(this, address)
end

/******************************************************************************/

__e2setcost(20) -- temporary

local function WriteString(entity, string, X, Y, Tcolour, Bgcolour, Flash)
	if not validEntity(entity) then return end
	if not entity.extended or not entity.WriteCell then return end

	Tcolour = math.Clamp(math.floor(Tcolour), 0, 999)
	Bgcolour = math.Clamp(math.floor(Bgcolour), 0, 999)
	Flash = (Flash ~= 0) and 1 or 0
	local Params = Flash*1000000 + Bgcolour*1000 + Tcolour

	for N = 1,#string do
		local Address = 2*(X+N-1+30*Y)
		if (Address>1080 or Address<0) then return end
		local Byte = string.byte(string,N)
		entity:WriteCell(Address, Byte)
		entity:WriteCell(Address+1, Params)
	end
end

e2function void wirelink:writeString(string text, x, y, textcolor, bgcolor, flash)
	WriteString(this,text,x,y,textcolor,bgcolor,flash)
end

e2function void wirelink:writeString(string text, x, y, textcolor, bgcolor)
	WriteString(this,text,x,y,textcolor,bgcolor,0)
end

e2function void wirelink:writeString(string text, x, y, textcolor)
	WriteString(this,text,x,y,textcolor,0,0)
end

e2function void wirelink:writeString(string text, x, y)
	WriteString(this,text,x,y,999,0,0)
end

/******************************************************************************/

--- Writes a null-terminated string to the given address. Returns the next free address or 0 on failure.
e2function number wirelink:writeString(address, string data)
	if not validEntity(this) or not this.extended or not this.WriteCell then return 0 end
	return WriteStringZero(this, address, data)
end

--- Reads a null-terminated string from the given address. Returns an empty string on failure.
e2function string wirelink:readString(address)
	if not validEntity(this) or not this.extended or not this.ReadCell then return "" end
	return ReadStringZero(this, address)
end

/******************************************************************************/

--- Writes an array's elements into a piece of memory. Strings and sub-tables (angles, vectors, matrices) are written as pointers to the actual data. Strings are written null-terminated.
e2function number wirelink:writeArray(address, array data)
	if not validEntity(this) or not this.extended or not this.WriteCell then return 0 end
	wa_lookup = {}
	local ret = WriteArray(this,address,data)
	wa_lookup = nil
	return ret
end

__e2setcost(nil) -- temporary
