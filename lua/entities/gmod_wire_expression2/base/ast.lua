-- The E2 source code is parsed into a tree structure, known as an 'abstract
-- syntax tree' or AST. This file provides utilities for operating on nodes of
-- this tree generically.

AddCSLuaFile()

E2Lib.AST = {}

local function genericChildVisitor(node, action)
    for i = 3, #node do
        local child = node[i]
        if istable(child) and child.__instruction then
            node[i] = action(child) or child
        end
    end
end
local childVisitors = {}
function childVisitors.call(node, action)
    local arguments = node[4]
    for i, argument in ipairs(arguments) do
        arguments[i] = action(argument) or argument
    end
end
function childVisitors.methodcall(node, action)
    local this, arguments = node[4], node[5]
    node[4] = action(this) or this
    for i, argument in ipairs(arguments) do
        arguments[i] = action(argument) or argument
    end
end
function childVisitors.stringcall(node, action)
    local name, arguments = node[3], node[4]
    node[3] = action(name) or name
    for i, argument in ipairs(arguments) do
        arguments[i] = action(argument) or argument
    end
end
function childVisitors.kvtable(node, action)
    local entries = node[3]
    local additions = {}
    for key, value in pairs(entries) do
        local newKey, newValue = action(key) or key, action(value) or value
        if key ~= newKey then
            entries[key] = nil
            additions[newKey] = newValue
        else
            entries[key] = newValue
        end
    end
    for key, value in pairs(additions) do entries[key] = value end
end
childVisitors.kvarray = childVisitors.kvtable
function childVisitors.switch(node, action)
    local expression = node[3]
    node[3] = action(expression) or expression
    for _, case in pairs(node[4]) do
        local condition, result = case[1], case[2]
        case[1] = condition and action(condition) or condition
        case[2] = action(result) or result
    end
end

--- Call `action` on every child of `node`.
-- If it returns a value, then that value will replace the node.
-- For example:
-- E2Lib.AST.visitChildren(node, function(child)
--     print(string.format("Node has a child of type %s", child[1]))
--     -- replace (sub x x) → 0
--     if child[1] == "sub" and child[3] == child[4] then
--         return { "literal", child[2], 0, "n" }
--     end
-- end)
function E2Lib.AST.visitChildren(node, action)
    local visitor = childVisitors[node[1]] or genericChildVisitor
    return visitor(node, action)
end

--- Return a string representation of the tree.
function E2Lib.AST.dump(tree, indentation)
    indentation = indentation or ""
    local str = indentation .. tree[1]

    local summary = {}
    for i = 3, #tree do
        local v = tree[i]
        if isstring(v) then
            table.insert(summary, string.format("%q", v))
        elseif isnumber(v) then
            table.insert(summary, tostring(v))
        end
    end
    if next(summary) then
        str = str .. " [" .. table.concat(summary, ", ") .. "]"
    end

    str = str .. " (" .. tree[2][1] .. ":" .. tree[2][2] .. ")"
    local childIndentation = indentation .. "|    "

    E2Lib.AST.visitChildren(tree, function(child)
        str = str .. "\n" .. E2Lib.AST.dump(child, childIndentation)
    end)

    return str
end
