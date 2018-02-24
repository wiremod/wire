--[[
A semantic analyzer for E2 abstract syntax trees.
Currently, the analyzer resolves the scope of variables, and assigns a unique
number to every local variable in the program. These numbers are then used to
reference local variables in the current stack frame.

After the Analyzer pass, each AST node that references a variable will have been
annotated with its ID.
--]]

AddCSLuaFile()

local analyzerDebug = CreateConVar("wire_expression2_analyzer_debug", 0,
    "Print an E2's abstract syntax tree after analyzing"
)

local Analyzer = {}

E2Lib.Analyzer = {}

--- Analyze the E2 abstract syntax tree.
-- @return true and the tree annotated with extra information, or false and an
--         error message.
function E2Lib.Analyzer.Execute(root, includes)
    local analyzer = setmetatable({
        Locals = {}, -- a mappings from local name to ID
        NextLocalId = 1, -- a counter to assign each local variable a unique ID

        Includes = includes, -- a mapping from filename to AST root
    }, { __index = Analyzer })
    local ok, message = xpcall(Analyzer.Process, E2Lib.errorHandler, analyzer, root)
    if ok and analyzerDebug:GetBool() then
        print(E2Lib.Parser.DumpTree(root))
    end
    return ok, message
end

function Analyzer:Error(tree, message, ...)
    error(string.format(message, ...) ..
        string.format(" at line %i, char %i", tree[2][1], tree[2][2]))
end

--- Define the given name in the current scope.
-- If the name exists in a parent scope, this new definition will shadow the
-- old one, and the old variable will be accessible when this scope is exited.
-- If the name exists in the current scope, this new definition will entirely
-- replace the old one, and the old definition will no longer be accessible.
-- @return a unique ID corresponding to this definition.
function Analyzer:DefineLocal(name)
    local id = self.NextLocalId
    self.NextLocalId = self.NextLocalId + 1
    self.Locals[name] = id
    return id
end

--- Lookup the given name in the current scope.
-- If the name isn't found in a local scope, then it refers to a global variable
-- @return a number corresponding to the local variable, or name if it's a global variable.
function Analyzer:Resolve(name)
    local id = self.Locals[name]
    if id then
        return id
    end

    return name
end


--- Execute function `func` in with a scope that's a child of the current scope.
function Analyzer:WithChildScope(func)
    local oldScope = self.Locals
    self.Locals = setmetatable({}, { __index = oldScope })
    func()
    self.Locals = oldScope
end

--- Execute function `func` in with a scope that's unrelated to the current scope.
function Analyzer:WithFreshScope(func)
    local oldScope = self.Locals
    self.Locals = {}
    func()
    self.Locals = oldScope
end

--- Analyze an AST node and all its descendents.
function Analyzer:Process(tree)
    local action = self.Actions[tree[1]] or self.Actions.__generic
    action(self, tree)
    return tree
end

Analyzer.Actions = {}

function Analyzer.Actions.__generic(self, tree)
    for i = 3, #tree do
        local child = tree[i]
        if type(child) == "table" and child.__instruction then
            self:Process(tree[i])
        end
    end
end

function Analyzer.Actions.assl(self, tree)
    local name, expression = tree[3], tree[4]
    self:Process(expression)
    tree.Id = self:DefineLocal(name)
end

function Analyzer.Actions.var(self, tree)
    local name = tree[3]
    tree.Id = self:Resolve(name)
end

function Analyzer.Actions.ass(self, tree)
    self.Actions.var(self, tree)
    local expression = tree[4]
    self:Process(expression)
end

Analyzer.Actions.inc = Analyzer.Actions.var
Analyzer.Actions.dec = Analyzer.Actions.var
Analyzer.Actions.trg = Analyzer.Actions.var
Analyzer.Actions.dlt = Analyzer.Actions.var
Analyzer.Actions.iwc = Analyzer.Actions.var

Analyzer.Actions["for"] = function(self, tree)
    local var, start, stop, step, block = tree[3], tree[4], tree[5], tree[6], tree[7]
    self:Process(start)
    self:Process(stop)
    if step then
        self:Process(step)
    end
    self:WithChildScope(function()
        tree.Id = self:DefineLocal(var)
        self:Process(block)
    end)
end

function Analyzer.Actions.whl(self, tree)
    local condition, block = tree[3], tree[4]
    self:Process(condition)
    self:WithChildScope(function()
        self:Process(block)
    end)
end

Analyzer.Actions["if"] = function(self, tree)
    local condition, thenBlock, elseBlock = tree[3], tree[4], tree[5]
    self:Process(condition)
    self:WithChildScope(function()
        self:Process(thenBlock)
    end)
    self:WithChildScope(function()
        self:Process(elseBlock)
    end)
end

function Analyzer.Actions.fea(self, tree)
    local key, value, table, block = tree[3], tree[5], tree[7], tree[8]
    self:Process(table)
    self:WithChildScope(function()
        tree.KeyId = self:DefineLocal(key)
        tree.ValueId = self:DefineLocal(value)
        self:Process(block)
    end)
end

Analyzer.Actions["function"] = function(self, tree)
    local args, block = tree[6], tree[7]
    self:WithFreshScope(function()
        for _, arg in pairs(args) do
            local name = arg[1]
            arg.Id = self:DefineLocal(name)
        end
        self:Process(block)
    end)
end

function Analyzer.Actions.switch(self, tree)
    local expression, cases = tree[3], tree[4]
    self:Process(expression)
    for _, case in pairs(cases) do
        local value = case[1]
        if value then self:Process(value) end
    end
    self:WithChildScope(function()
    for _, case in pairs(cases) do
        local block = case[2]
        self:Process(block)
    end
    end)
end

function Analyzer.Actions.inclu(self, tree)
    local filename = tree[3]

    local include = self.Includes[filename]

    if not include or not include[1] then
        self:Error(tree, "Problem including file '%s'", filename)
    end

    local root = include[1]

    if not include.Analyzed then
        include.Analyzed = true
        self:WithFreshScope(function()
            self:Process(root)
        end)
    end
end
