--   By asiekierka,  2009   --
--Non-luabit XOR by TomyLobo--

__e2setcost(2)

e2function number bAnd(a, b)
	return bit.band(a, b)
end
e2function number bOr(a, b)
	return bit.bor(a, b)
end
e2function number bXor(a, b)
	return bit.bxor(a, b)
end
e2function number bShr(a, b)
	return bit.rshift(a, b)
end
e2function number bShl(a, b)
	return bit.lshift(a, b)
end
e2function number bNot(n)
	return bit.bnot(n)
end
e2function number bNot(n,bits)
	if bits >= 32 or bits < 1 then
		return (-1)-n
	else
		return (math.pow(2,bits)-1)-n
	end
end


e2function number operator_band( a, b )
	return bit.band(a, b)
end
e2function number operator_bor( a, b )
	return bit.bor(a, b)
end
e2function number operator_bxor( a, b )
	return bit.bxor(a, b)
end
e2function number operator_bshr( a, b )
	return bit.rshift(a, b)
end
e2function number operator_bshl( a, b )
	return bit.lshift(a, b)
end
