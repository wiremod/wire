--   By asiekierka,  2009   --
--Non-luabit XOR by TomyLobo--
e2function number bAnd(a, b)
	return (a & b)
end
e2function number bOr(a, b)
	return (a | b)
end
e2function number bXor(a, b)
	return (a | b) & (-1-(a & b))
end
e2function number bShr(a, b)
	RunString(string.format("garry_sucks = %d >> %d", a, b))
	return garry_sucks
end
e2function number bShl(a, b)
	RunString(string.format("garry_sucks = %d << %d", a, b))
	return garry_sucks
end
e2function number bNot(n)
	return (-1)-n
end
e2function number bNot(n,bits)
	if bits >= 32 || bits < 1 then
		return (-1)-n
	else
		return (math.pow(2,bits)-1)-n
	end
end
