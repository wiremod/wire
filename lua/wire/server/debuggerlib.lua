local formatPort = setmetatable({}, { __index = function(_, k)
	return function() return k end
end
})

WireLib.Debugger = { formatPort = formatPort } -- Make it global
function formatPort.NORMAL(value)
	return string.format("%.3f",value)
end

function formatPort.STRING(value)
	return '"' .. value .. '"'
end

function formatPort.VECTOR(value)
	return string.format("(%.1f,%.1f,%.1f)", value[1], value[2], value[3])
end

function formatPort.ANGLE(value)
	return string.format("(%.1f,%.1f,%.1f)", value[1], value[2], value[3])
end

formatPort.ENTITY = function(ent)
	if not IsValid(ent) then return "(null)" end
	return tostring(ent)
end
formatPort.BONE = e2_tostring_bone

function formatPort.MATRIX(value)
	local RetText = "[11="..value[1]..",12="..value[2]..",13="..value[3]
		  RetText = RetText..",21="..value[4]..",22="..value[5]..",23="..value[6]
		  RetText = RetText..",31="..value[7]..",32="..value[8]..",33="..value[9].."]"
	return RetText
end

function formatPort.MATRIX2(value)
	local RetText = "[11="..value[1]..",12="..value[2]
		  RetText = RetText..",21="..value[3]..",22="..value[4].."]"
	return RetText
end

function formatPort.MATRIX4(value)
	local RetText = "[11="..value[1]..",12="..value[2]..",13="..value[3]..",14="..value[4]
		  RetText = RetText..",21="..value[5]..",22="..value[6]..",23="..value[7]..",24="..value[8]
		  RetText = RetText..",31="..value[9]..",32="..value[10]..",33="..value[11]..",34="..value[12]
		  RetText = RetText..",41="..value[13]..",42="..value[14]..",43="..value[15]..",44="..value[16].."]"
	return RetText
end

function formatPort.ARRAY(value, OrientVertical)
	local RetText = ""
	local ElementCount = 0
	for Index, Element in ipairs(value) do
		ElementCount = ElementCount+1
		if(ElementCount > 10) then
			break
		end
		RetText = RetText..Index.."="
		--Check for array element type
		if isnumber(Element) then --number
			RetText = RetText..formatPort.NORMAL(Element)
		elseif((istable(Element) and #Element == 3) or isvector(Element)) then --vector
			RetText = RetText..formatPort.VECTOR(Element)
		elseif(istable(Element) and #Element == 2) then --vector2
			RetText = RetText..formatPort.VECTOR2(Element)
		elseif(istable(Element) and #Element == 4) then --vector4
			RetText = RetText..formatPort.VECTOR4(Element)
		elseif((istable(Element) and #Element == 3) or isangle(Element)) then --angle
			if(isangle(Element)) then
				RetText = RetText..formatPort.ANGLE(Element)
			else
				RetText = RetText.."(" .. math.Round(Element[1],1) .. "," .. math.Round(Element[2],1) .. "," .. math.Round(Element[3],1) .. ")"
			end
		elseif(istable(Element) and #Element == 9) then --matrix
			RetText = RetText..formatPort.MATRIX(Element)
		elseif(istable(Element) and #Element == 16) then --matrix4
			RetText = RetText..formatPort.MATRIX4(Element)
		elseif(isstring(Element)) then --string
			RetText = RetText..formatPort.STRING(Element)
		elseif(isentity(Element)) then --entity
			RetText = RetText..formatPort.ENTITY(Element)
		elseif(type(Element) == "Player") then --player
			RetText = RetText..tostring(Element)
		elseif(type(Element) == "Weapon") then --weapon
			RetText = RetText..tostring(Element)..Element:GetClass()
		elseif(type(Element) == "PhysObj" and e2_tostring_bone(Element) ~= "(null)") then --Bone
			RetText = RetText..formatPort.BONE(Element)
		else
			RetText = RetText.."No Display for "..type(Element)
		end
		--TODO: add matrix 2
		if OrientVertical then
			RetText = RetText..",\n"
		else
			RetText = RetText..", "
		end
	end
	RetText = string.sub(RetText,1,-3)
	return "{"..RetText.."}"
end

function formatPort.TABLE(value, OrientVertical)
	local RetText = ""
	local ElementCount = 0
	for Index, Element in pairs(value) do
		ElementCount = ElementCount+1
		if(ElementCount > 7) then
			break
		end

		local long_typeid = string.sub(Index,1,1) == "x"
		local typeid = string.sub(Index,1,long_typeid and 3 or 1)
		local IdxID = string.sub(Index,(long_typeid and 3 or 1)+1)

		RetText = RetText..IdxID.."="
		--Check for array element type
		if(typeid == "n") then --number
			RetText = RetText..formatPort.NORMAL(Element)
		elseif(istable(Element) and #Element == 3) or isvector(Element) then --vector
			RetText = RetText..formatPort.VECTOR(Element)
		elseif(istable(Element) and #Element == 2) then --vector2
			RetText = RetText..formatPort.VECTOR2(Element)
		elseif(istable(Element) and #Element == 4 and typeid == "v4") then --vector4
			RetText = RetText..formatPort.VECTOR4(Element)
		elseif(istable(Element) and #Element == 3) or isangle(Element) then --angle
			if isangle(Element) then
				RetText = RetText..formatPort.ANGLE(Element)
			else
				RetText = RetText.."(" .. math.Round(Element[1]*10)/10 .. "," .. math.Round(Element[2]*10)/10 .. "," .. math.Round(Element[3]*10)/10 .. ")"
			end
		elseif(istable(Element) and #Element == 9) then --matrix
			RetText = RetText..formatPort.MATRIX(Element)
		elseif(istable(Element) and #Element == 16) then --matrix4
			RetText = RetText..formatPort.MATRIX4(Element)
		elseif(typeid == "s") then --string
			RetText = RetText..formatPort.STRING(Element)
		elseif(isentity(Element) and typeid == "e") then --entity
			RetText = RetText..formatPort.ENTITY(Element)
		elseif(type(Element) == "Player") then --player
			RetText = RetText..tostring(Element)
		elseif(type(Element) == "Weapon") then --weapon
			RetText = RetText..tostring(Element)..Element:GetClass()
		elseif(typeid == "b") then
			RetText = RetText..formatPort.BONE(Element)
		else
			RetText = RetText.."No Display for "..type(Element)
		end
		--TODO: add matrix 2
		if OrientVertical then
			RetText = RetText..",\n"
		else
			RetText = RetText..", "
		end
	end
	RetText = string.sub(RetText,1,-3)
	return "{"..RetText.."}"
end

function WireLib.registerDebuggerFormat(typename, func)
	formatPort[typename:upper()] = func
end
