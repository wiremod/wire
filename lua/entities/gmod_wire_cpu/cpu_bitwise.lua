// Previously LuaBit v0.4, by hanzhao (abrash_han@hotmail.com)
// Rewrote most of operations to be at least a little bit faster, and work with custom amount of bits

function ENT:ForceInteger(n)
	return math.floor(n or 0)
end

function ENT:Is48bitInteger(n)
	if ((math.floor(n) == n) and (n <= 140737488355328) and (n >= -140737488355327)) then
		return true
	else
		return false
	end
end

function ENT:IntegerToBinary(n)
	n = self:ForceInteger(n)
	if (n < 0) then
		local tbl = self:IntegerToBinary(-n-1)
		tbl[self.IPREC] = 1
		return tbl
	end

	local tbl = {}
	local cnt = 0
	while ((n > 0) and (cnt < self.IPREC)) do
		local last = math.fmod(n,2)
		if(last == 1) then
			tbl[cnt] = 1
		else
			tbl[cnt] = 0
		end
		n = (n-last)/2
		cnt = cnt + 1
	end
	while (cnt < self.IPREC) do
		tbl[cnt] = 0
		cnt = cnt + 1
	end

	return tbl
end

function ENT:BinaryToInteger(tbl)
	local n = #tbl
	local sign = 0
	if (n > self.IPREC-1) then
		sign = tbl[self.IPREC-1]
		n = self.IPREC
	end

	local rslt = 0
	local power = 1
	for i = 0, n-1 do
		rslt = rslt + tbl[i]*power
		power = power*2
	end

	if (sign == 1) then
		return -rslt-1
	else
		return rslt
	end
end

function ENT:BinaryOr(m,n)
	local tbl_m = self:IntegerToBinary(m)
	local tbl_n = self:IntegerToBinary(n)
	local tbl = {}

	local rslt = math.max(#tbl_m, #tbl_n)
	for i = 0, rslt-1 do
		tbl[i] = math.min(1,tbl_m[i]+tbl_n[i])
	end

	return self:BinaryToInteger(tbl)
end

function ENT:BinaryAnd(m,n)
	local tbl_m = self:IntegerToBinary(m)
	local tbl_n = self:IntegerToBinary(n)
	local tbl = {}

	local rslt = math.max(#tbl_m, #tbl_n)
	for i = 0, rslt-1 do
		tbl[i] = tbl_m[i]*tbl_n[i]
	end

	return self:BinaryToInteger(tbl)
end

function ENT:BinaryNot(n)
	local tbl_n = self:IntegerToBinary(n)
	local tbl = {}

	local rslt = #tbl_n
	for i = 0, rslt-1 do
		tbl[i] = 1-tbl_n[i]
	end
	return self:BinaryToInteger(tbl)
end

function ENT:BinaryXor(m,n)
	local tbl_m = self:IntegerToBinary(m)
	local tbl_n = self:IntegerToBinary(n)
	local tbl = {}

	local rslt = math.max(#tbl_m, #tbl_n)
	for i = 0, rslt-1 do
		tbl[i] = (tbl_m[i]+tbl_n[i]) % 2
	end

	return self:BinaryToInteger(tbl)
end

function ENT:BinarySHR(n,bits)
	local tbl_n = self:IntegerToBinary(n)
	local tbl = {}

	local rslt = #tbl_n
	for i = 0, self.IPREC-bits-1 do
		tbl[i] = tbl_n[i+bits]
	end
	for i = self.IPREC-bits,rslt-1 do
		tbl[i] = 0
	end

	return self:BinaryToInteger(tbl)
end

function ENT:BinarySHL(n,bits)
	local tbl_n = self:IntegerToBinary(n)
	local tbl = {}

	for i = bits,self.IPREC-1 do
		tbl[i] = tbl_n[i-bits]
	end
	for i = 0,bits-1 do
		tbl[i] = 0
	end

	return self:BinaryToInteger(tbl)
end
