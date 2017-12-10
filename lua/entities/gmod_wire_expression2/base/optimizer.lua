--[[
An optimizer for E2 abstract syntax trees, as produced by the parser and
consumed by the compiler.

Currently it only performs some simple peephole optimizations and constant
propagation. Ideally, we'd do type inference as much as possible before
optimizing, which would give us more useful information throughout.
--]]

E2Lib.Optimizer = {}
local Optimizer = E2Lib.Optimizer
Optimizer.__index = Optimizer

local optimizerDebug = CreateConVar("wire_expression2_optimizer_debug", 0,
    "Print an E2's abstract syntax tree after optimization"
)

function Optimizer.Execute(root)
    local ok, result = xpcall(Optimizer.Process, E2Lib.errorHandler, root)
    if ok and optimizerDebug:GetBool() then
        print(E2Lib.Parser.DumpTree(result))
    end
    return ok, result
end

Optimizer.Passes = {}

function Optimizer.Process(tree)
    for i = 3, #tree do
        local child = tree[i]
        if type(child) == "table" and child.__instruction then
            tree[i] = Optimizer.Process(child)
        end
    end
    for _, pass in ipairs(Optimizer.Passes) do
        local action = pass[tree[1]]
        if action then
            tree = assert(action(tree))
        end
    end
    tree.__instruction = true
    return tree
end

local constantPropagation = {}

local function evaluateBinary(instruction)
    -- this is a little sneaky: we use the operators previously registered with getOperator
    -- to do compile-time evaluation, even though it really wasn't designed for it.
    local op = wire_expression2_funcs["op:" .. instruction[1] .. "(" .. instruction[3][4] .. instruction[4][4] .. ")"]
    local x, y = instruction[3][3], instruction[4][3]

    local value = op[3](nil, {nil, {function() return x end}, {function() return y end}})
    local type = op[2]
    return {"literal", instruction[2], value, type}
end

local function evaluateUnary(instruction)
    local op = wire_expression2_funcs["op:" .. instruction[1] .. "(" .. instruction[3][4] .. ")"]
    local x = instruction[3][3]

    local value = op[3](nil, {nil, {function() return x end}})
    local type = op[2]
    return {"literal", instruction[2], value, type}
end

for _, operator in pairs({ "add", "sub", "mul", "div", "mod", "exp", "eq", "neq", "geq", "leq",
                           "gth", "lth", "band", "band", "bor", "bxor", "bshl", "bshr" }) do
    constantPropagation[operator] = function(instruction)
        if instruction[3][1] ~= "literal" or instruction[4][1] ~= "literal" then return instruction end
        return evaluateBinary(instruction)
    end
end

function constantPropagation.neg(instruction)
    if instruction[3][1] ~= "literal" then return instruction end
    return evaluateUnary(instruction)
end

constantPropagation["not"] = function(instruction)
    if instruction[3][1] ~= "literal" then return instruction end
    instruction[3] = evaluateUnary({"is", instruction[2], instruction[3]})
    return evaluateUnary(instruction)
end

for _, operator in pairs({ "and", "or" }) do
    constantPropagation[operator] = function(instruction)
        if instruction[3][1] ~= "literal" then return instruction end
        instruction[3] = evaluateUnary({"is", instruction[2], instruction[3]})
        instruction[4] = evaluateUnary({"is", instruction[2], instruction[4]})
        return evaluateBinary(instruction)
    end
end

table.insert(Optimizer.Passes, constantPropagation)


local peephole = {}
function peephole.add(instruction)
    -- (add 0 x) → x
    if instruction[3][1] == "literal" and instruction[3][3] == 0 then return instruction[4] end
    -- (add x 0) → x
    if instruction[4][1] == "literal" and instruction[4][3] == 0 then return instruction[3] end
    -- (add (neg x) (neg y)) → (neg (add x y))
    if instruction[3][1] == "neg" and instruction[4][1] == "neg" then
        return {"neg", instruction[2], {"add", instruction[2], instruction[3][3], instruction[4][3],
                __instruction = true}}
    end
    -- (add x (neg y)) → (sub x y)
    if instruction[4][1] == "neg" then
        return {"sub", instruction[2], instruction[3], instruction[4][3]}
    end
    -- (add (neg x) y) → (sub y x)
    if instruction[3][1] == "neg" then
        return {"sub", instruction[2], instruction[4], instruction[3][3]}
    end
    return instruction
end

function peephole.sub(instruction)
    -- (sub 0 x) → (neg x)
    if instruction[3][1] == "literal" and instruction[3][3] == 0 then
        return {"neg", instruction[2], instruction[4]}
    end
    -- (sub x 0) → x
    if instruction[4][1] == "literal" and instruction[4][3] == 0 then return instruction[3] end
    -- (sub (neg x) (neg y)) → (sub y x)
    if instruction[3][1] == "neg" and instruction[4][1] == "neg" then
        return {"sub", instruction[2], instruction[4][3], instruction[3][3]}
    end
    -- (sub x (neg y) → (add x y))
    if instruction[4][1] == "neg" then
        return {"add", instruction[2], instruction[3], instruction[4][3]}
    end
    -- (sub (neg x) y) → (neg (add x y))
    if instruction[3][1] == "neg" then
        return {"neg", instruction[2], {"add", instruction[2], instruction[3][3], instruction[4],
                __instruction = true }}
    end
    return instruction
end

function peephole.mul(instruction)
    if instruction[4][1] == "literal" and instruction[3][1] ~= "literal" then
        instruction[3], instruction[4] = instruction[4], instruction[3]
    end
    -- (mul 1 x) → x
    if instruction[3][1] == "literal" and instruction[3][3] == 1 then return instruction[4] end
    -- (mul 0 x) → 0
    if instruction[3][1] == "literal" and instruction[3][3] == 0 then return instruction[3] end
    -- (mul -1 x) → (neg x)
    if instruction[3][1] == "literal" and instruction[3][3] == -1 then
        return {"neg", instruction[2], instruction[4]}
    end
    return instruction
end

function peephole.neg(instruction)
    -- (neg (neg x)) → x
    if instruction[3][1] == "neg" then return instruction[3][3] end
    return instruction
end

peephole["if"] = function(instruction)
    -- (if 1 x y) → x
    -- (if 0 x y) → y
    if instruction[3][1] == "literal" then
        instruction[3] = evaluateUnary({"is", instruction[2], instruction[3]})
        if instruction[3][3] == 1 then return instruction[4] end
        if instruction[3][3] == 0 then return instruction[5] end
        assert(false, "unreachable: `is` evaluation didn't return a boolean")
    end
    return instruction
end

function peephole.whl(instruction)
    -- (while 0 x) → (seq)
    if instruction[3][1] == "literal" then
        instruction[3] = evaluateUnary({"is", instruction[2], instruction[3]})
        if instruction[3][3] == 0 then return {"seq", instruction[2]} end
    end
    return instruction
end

table.insert(Optimizer.Passes, peephole)
