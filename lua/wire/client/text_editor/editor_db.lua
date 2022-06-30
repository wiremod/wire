local utf8_len_checked = utf8.len_checked
local string_Explode = string.Explode
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat

-----------------------

local META = {}
META.__index = META
--[[
    type RenderContext = <userdata>
    type RenderContextFn = fn(line: string, prev_ctx: RenderContext|nil) -> RenderContext, changed: bool
    type RenderLineFn = fn(
        font: string, font_bold: string, 
        line: string, line_i: nonzero_uint, contexts: array(RenderContext)) -> array(LineRenderData)
    
    -- Called after `contexts[changed_i]` was changed
    -- Users are supposed to modify `render_status` contents
    type RenderInvalidationFn = fn(
        contexts: array(RenderContext|false), render_status: array(RenderStatus),
        prev_contexts: array(RenderContext|nil), -- If nil, take value from `contexts[i]` 
        changed_i: nonzero_uint)

    type LineRenderData = {
        text: string,
        is_bold: bool,
        color: Color,
        abs_end_pos: number, -- in pixels, from start of line
    }
    type RenderStatus = {
        IsValid: bool,
        Removed: nil|true
    }

    type META;

    META._lines: array(string)
    META._lineLens: array(uint) -- utf8.len of corresponding elements of ._lines
    META._lineRenders: array(array(LineRenderData))
    META._lineRenderContexts: array(RenderContext) -- Syntax highlighting context
    META._lineRenderStatus: array(RenderStatus)
    META._font: string
    META._fontBold: string
    META._fnContext: RenderContextFn
    META._fnRender: RenderLineFn
    META._fnInval: RenderInvalidationFn

    -- Creates instance of text editor database
    pub fn WireTextEditorDB() -> META

    -- Replaces all the text with given `text`
    pub fn META:SetText(text: string)

    pub fn META:SetFont(font_normal: string, font_bold: string)
    pub fn META:SetRenderFns(render_ctx: RenderContextFn, render: RenderLineFn, render_inval: RenderInvalidationFn)    

    pub fn META:GetRenderInfo(line_i: nonzero_uint) -> array(LineRenderData)|nil
    pub fn META:GetLine(line_i: nonzero_uint) -> string|nil
    pub fn META:GetLineLen(line_i: nonzero_uint) -> uint|nil
    pub fn META:GetLineCount() -> uint

    pub fn META:GetText() -> string
    pub fn META:SetText(text: string)
    
    -- Replaces lines from `first_i` to `first_i + #lines - 1` with corresponding elements of `lines`
    pub fn META:LinesReplace(first_i: nonzero_uint, lines: array(string))
    -- Inserts `lines` after `first_i` 
    pub fn META:LinesInsert(first_i: nonzero_uint, lines: array(string))
    -- Removes lines at indices in `idxs`
    -- WARNING: `idxs` should be sorted ascending!
    pub fn META:LinesRemove(idxs: array(nonzero_uint))

]]

local function DefaultRenderContext(line, prev_ctx)
    return {}, prev_ctx == nil
end

local function DefaultRenderInvalidation(contexts, render_status, changed_i)
    render_status[changed_i].IsValid = false
end

local DEFAULT_COLOR = Color(200,200,200,255)

local function DefaultLineRender(font, font_bold, line, line_i, contexts)
    surface_SetFont(font)
    local text_w = surface_GetTextSize(line)

    return {{
        text = line,
        is_bold = false,
        color = DEFAULT_COLOR,
        abs_end_pos = text_w
    }}
end

function WireTextEditorDB()
    local editor_db = setmetatable({}, META)
    editor_db._lines = {}
    editor_db._lineLens = {}
    editor_db._lineRenders = {}
    editor_db._lineRenderContexts = {}
    editor_db._lineRenderStatus = {}

    editor_db._font = "CloseCaption_Normal"
    editor_db._fontBold = "CloseCaption_Bold"

    editor_db._fnContext = DefaultRenderContext
    editor_db._fnRender = DefaultLineRender
    editor_db._fnInval = DefaultRenderInvalidation

    return editor_db
end

function META:SetRenderFns(render_ctx, render, render_inval)
    self._fnContext = render_ctx
    self._fnRender = render
    self._fnInval = render_inval

    for i, line in ipairs(self._lines) do
        local new_ctx, _changed = render_ctx(line, nil)
        self._lineRenderContexts[i] = new_ctx
        self._lineRenderStatus[i].IsValid = false
    end
end

function META:SetFont(font_normal, font_bold)
    self._font = font_normal
    self._fontBold = font_bold

    for _, status in ipairs(self._lineRenderStatus) do
        status.IsValid = false -- Almost certainly needs re-rendering to recompute text size in pixels
    end
end

function META:SetText(text)
    self._lines = string_Explode("\n", text)
    self._lineLens = {}
    self._lineRenders = {}
    self._lineRenderContexts = {}
    self._lineRenderStatus = {}

    for i, line in ipairs(self._lines) do
        self._lineLens[i] = utf8_len_checked(line)
        self._lineRenderStatus[i] = { IsValid = false }
        local ctx, _changed = self._fnContext(line, nil)
        self._lineRenderContexts[i] = ctx
    end
end

function META:GetText()
    return table_concat(self._lines, "\n")
end

function META:GetRenderInfo(line_i)
    local status = self._lineRenderStatus[line_i]

    if status == nil then return nil end

    if not status.IsValid then
        self._lineRenders[line_i] = self._fnRender(
            self._font, self._fontBold,
            self._lines[line_i], line_i,
            self._lineRenderContexts
        )

        status.IsValid = true
    end

    return self._lineRenders[line_i]
end

function META:GetLine(line_i)
    return self._lines[line_i]
end

function META:GetLineLen(line_i)
    return self._lineLens[line_i]
end

function META:GetLineCount() return #self._lines end

function META:_LinesChanged(changed, old_ctxs)
    for _, line_i in ipairs(changed) do
        self._fnInval(self._lineRenderContexts, self._lineRenderStatus, old_ctxs, line_i)
    end
end

function META:LinesReplace(first_i, lines)
    local changed_lines = {}
    local old_ctxs = {}

    for i, line in ipairs(lines) do
        local line_i = first_i + i - 1

        self._lines[line_i] = line
        self._lineLens[line_i] = utf8_len_checked(line)

        local prev_ctx = self._lineRenderContexts[line_i]
        local new_ctx, changed = self._fnContext(line, prev_ctx)
        if changed then
            self._lineRenderContexts[line_i] = new_ctx
            table_insert(changed_lines, line_i)
            old_ctxs[line_i] = prev_ctx
        end
    end

    self:_LinesChanged(changed_lines, old_ctxs)
end

function META:LinesInsert(first_i, lines)
    local changed_lines = {}

    for i, line in ipairs(lines) do
        local insert_i = first_i + i

        table_insert(self._lines, insert_i, line)
        table_insert(self._lineLens, insert_i, utf8_len_checked(line))

        local ctx, changed = self._fnContext(line, nil)
        assert(changed)

        table_insert(self._lineRenderContexts, insert_i, ctx)
        table_insert(self._lineRenderStatus, insert_i, {IsValid = false})
        table_insert(changed_lines, insert_i)
    end

    self:_LinesChanged(changed_lines, {})
end

-- Assumes `idxs` are sorted ascending
function META:LinesRemove(idxs)
    local changed_lines = {}
    local old_ctxs = {}

    local remove_idxs = {}

    for i, line_i in ipairs(idxs) do
        self._lines[line_i] = false
        self._lineLens[line_i] = false
        old_ctxs[line_i] = self._lineRenderContexts[line_i]
        self._lineRenderContexts[line_i] = false
        self._lineRenderStatus[line_i].Removed = true

        table_insert(changed_lines, line_i)
        table_insert(remove_idxs, line_i - (i-1))
    end

    self:_LinesChanged(changed_lines, old_ctxs)

    for _, line_i in ipairs(remove_idxs) do
        table_remove(self._lines, line_i)
        table_remove(self._lineLens, line_i)
        table_remove(self._lineRenderContexts, line_i)
        table_remove(self._lineRenderStatus, line_i)
        table_remove(self._lineRenders, line_i)
    end
end