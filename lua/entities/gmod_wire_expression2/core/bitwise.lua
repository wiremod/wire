__e2setcost(2)

local bit = bit

e2function number bAnd(a, b)
	return bit.band(a, b)
end

e2function number bOr(a, b)
	return bit.bor(a, b)
end

e2function number bXor(a, b)
	return bit.bxor(a, b)
end

e2function number bShar(a, b)
	return bit.arshift(a, b)
end

e2function number bShr(a, b)
	return bit.rshift(a, b)
end

e2function number bShl(a, b)
	return bit.lshift(a, b)
end

e2function number bRol(a, b)
	return bit.rol(a, b)
end

e2function number bRor(a, b)
	return bit.ror(a, b)
end

e2function number bSwap(n)
	return bit.bswap(n)
end

e2function number bToBit(n)
	return bit.tobit(n)
end

e2function number bNot(n)
	return bit.bnot(n)
end

e2function number bNot(n, bits)
	if bits >= 32 or bits < 1 then
		return -1 - n
	else
		return 2 ^ bits - 1 - n
	end
end

e2function string bToHex(n)
	return bit.tohex(n)
end

e2function string bToHex(n, chars)
	return bit.tohex(n, chars)
end

e2function number operator_band(a, b)
	return bit.band(a, b)
end

e2function number operator_bor(a, b)
	return bit.bor(a, b)
end

e2function number operator_bxor(a, b)
	return bit.bxor(a, b)
end

e2function number operator_bshr(a, b)
	return bit.rshift(a, b)
end

e2function number operator_bshl(a, b)
	return bit.lshift(a, b)
end
