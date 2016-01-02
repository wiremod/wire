AddCSLuaFile()

local does_return_value = {}

-- DoesReturnValue returns whether the instruction node returns a value.
local function DoesReturnValue(node)
  local node_type = node[1]
  if not does_return_value[node_type] then return false end
  return does_return_value[node_type](node)
end

does_return_value["seq"] = function(node)
  -- a sequence statement returns a value if any of the statements in it do
  for i = 3, #node do
    if DoesReturnValue(node[i]) then return true end
  end
  return false
end

does_return_value["if"] = function(node)
  -- an if statement returns a value if it has an else and both its branches do
  if not node[5] then return false end
  return DoesReturnValue(node[4]) and DoesReturnValue(node[5])
end

does_return_value["switch"] = function(node)
  -- a switch statement returns a value if all its cases return a value, and
  -- one of the cases is a default
  local has_default = false
  for _, case in pairs(node[4]) do
    if not DoesReturnValue(case) then return false end
    local condition, block = case[1], case[2]
    if condition == nil then has_default = true end
  end
  return has_default
end

-- trivially, non-void return statements return. (void return statements use a
-- different instruction type, "returnvoid".)
does_return_value["return"] = function(node) return true end

Analyzer = { DoesReturnValue = DoesReturnValue }
