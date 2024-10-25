include('shared.lua')

local Trace, Error = E2Lib.Debug.Trace, E2Lib.Debug.Error

---@param e2 string
---@param directives PPDirectives
---@param includes table<string, string>
---@param scripts table<string, { [1]: Node, [2]: boolean?, [3]: table<string, boolean> }>
---@return Error[]?
local function Include(e2, directives, includes, scripts)
	if scripts[e2] then
		return
	end

	local errors = {}
	local code = file.Read("expression2/" .. e2 .. ".txt")

	if not code then
		return { Error.new("Could not find include '" .. e2 .. ".txt'") }
	end

	local status, err, buffer = E2Lib.PreProcessor.Execute(code, directives)
	if not status then
		table.Add(errors, err)
	end

	local status, tokens = E2Lib.Tokenizer.Execute(buffer)
	if not status then
		table.Add(errors, tokens)
	end

	local status, tree, dvars, files = E2Lib.Parser.Execute(tokens)
	if not status then
		table.insert(errors, tree)
		return errors
	end

	includes[e2] = code

	scripts[e2] = { tree, nil, dvars }

	for i, file in ipairs(files) do
		local ierrors = Include(file, directives, includes, scripts)
		if ierrors then table.Add(errors, ierrors) end
	end

	if #errors ~= 0 then return errors end
end

---@param buffer string
---@return Error[]?, table[]?, Warning[]?
function E2Lib.Validate(buffer)
	if not e2_function_data_received then return { Error.new("Loading extensions. Please try again in a few seconds...") } end

	---@type Warning[], Error[]
	local warnings, errors = {}, {}

	-- invoke preprocessor
	local status, directives, buffer, preprocessor = E2Lib.PreProcessor.Execute(buffer)
	if not status then table.Add(errors, directives) return errors end
	---@cast directives PPDirectives
	table.Add(warnings, preprocessor.warnings)

	-- decompose directives
	RunConsoleCommand("wire_expression2_scriptmodel", directives.model or "")

	-- invoke tokenizer (=lexer)
	local status, tokens, tokenizer = E2Lib.Tokenizer.Execute(buffer)
	if not status then table.Add(errors, tokenizer.errors) return errors end
	table.Add(warnings, tokenizer.warnings)

	-- invoke parser
	local status, tree, dvars, files, parser = E2Lib.Parser.Execute(tokens)
	if not status then table.insert(errors, tree) return errors end
	table.Add(warnings, parser.warnings)

	-- prepare includes
	local includes, scripts = {}, {} ---@type table<string, string>, Node[]
	for i, file in ipairs(files) do
		local ierrors = Include(file, directives, includes, scripts)
		if ierrors then table.Add(errors, ierrors) end
	end

	if not table.IsEmpty(errors) then return errors end

	-- invoke compiler
	local status, script, compiler = E2Lib.Compiler.Execute(tree, directives, dvars, scripts)
	if not status then table.insert(errors, script) return errors end

	-- Need to do this manually since table.Add loses its mind with non-numeric keys (and compiler can emit warnings per include file) (should be refactored out at some point to just having warnings separated per include)
	local nwarnings = #warnings
	for k, warning in ipairs(compiler.warnings) do
		warnings[nwarnings + k] = warning
	end

	return nil, includes, #warnings ~= 0 and warnings, compiler
end

-- string.GetTextSize shits itself if the string is both wide and tall,
-- so we have to explode it around \n and add the sizes together
-- since it works fine for strings that are wide but not tall
local function wtfgarry( str )
	local w, h = 0, 0
	local expl = string.Explode( "\n", str )
	for i=1,#expl do
		local _w, _h = surface.GetTextSize( expl[i] )
		w = math.max(w,_w)
		h = h + _h
	end
	return math.max(w, 24), math.max(h, 24)
end

function ENT:GetGateName()
    return self:GetNWString("name", self.name)
end

local h_of_lower = 100 -- height of the lower section (the prfbench/percent bar section)
function ENT:GetWorldTipBodySize()
	local data = self:GetOverlayData()
	if not data then return 100, 20 end

	local txt = data.txt .. "\nauthor: " .. self:GetPlayerName()
	local w_total,h_total = wtfgarry(txt)
	h_total = h_total + 18

	local prfbench = data.prfbench
	local prfcount = data.prfcount
	local timebench = data.timebench

	local e2_hardquota = GetConVar("wire_expression2_quotahard"):GetInt()
	local e2_softquota = GetConVar("wire_expression2_quotasoft"):GetInt()

	-- ops text
	local hardtext = (prfcount / e2_hardquota > 0.33) and "(+" .. tostring(math.Round(prfcount / e2_hardquota * 100)) .. "%)" or ""
	local str = string.format("%i ops, %i%% %s", prfbench, prfbench / e2_softquota * 100, hardtext)

	h_of_lower = 0
	local w,h = surface.GetTextSize( str )
	w_total = math.max(w_total,w)
	h_total = h_total + h + 18
	h_of_lower = h_of_lower + h + 18

	-- cpu time text
	local str = string.format("cpu time: %ius", timebench*1000000)

	local w,h = surface.GetTextSize( str )
	w_total = math.max(w_total,w)
	h_total = h_total + h + 20
	h_of_lower = h_of_lower + h + 20 + 18

	return w_total, math.min(h_total,ScrH() - (h_of_lower + 32*2))
end

function ENT:DrawWorldTipBody( pos )
	local data = self:GetOverlayData()
	if not data then return end

	local txt = data.txt .. "\nauthor: " .. self:GetPlayerName()
	local err = data.error -- this isn't used (yet), might do something with it later
	local w_total, yoffset = 0, pos.min.y

	-------------------
	-- Name
	-------------------
	local w,h = wtfgarry( txt )
	h = h + pos.edgesize
	h = math.min(h,pos.size.h - (h_of_lower+pos.footersize.h))

	render.SetScissorRect( pos.min.x + 16, pos.min.y, pos.max.x - 16, pos.min.y + h, true )
	draw.DrawText( txt, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, color_white, TEXT_ALIGN_CENTER )
	render.SetScissorRect( 0, 0, ScrW(), ScrH(), false )

	w_total = math.max( w_total, w )
	yoffset = yoffset + h

	surface.SetDrawColor(0, 0, 0)
	surface.DrawLine( pos.min.x, yoffset, pos.max.x, yoffset )

	-------------------
	-- prfcount/benchmarking/etc
	-------------------
	local prfbench = data.prfbench
	local prfcount = data.prfcount
	local timebench = data.timebench

	local e2_hardquota = GetConVar("wire_expression2_quotahard"):GetInt()
	local e2_softquota = GetConVar("wire_expression2_quotasoft"):GetInt()

	-- fancy percent bar
	local w = pos.size.w - pos.edgesize * 2

	-- ops text
	local hardtext = (prfcount / e2_hardquota > 0.33) and "(+" .. tostring(math.Round(prfcount / e2_hardquota * 100)) .. "%)" or ""
	local str = string.format("%i ops, %i%% %s", prfbench, prfbench / e2_softquota * 100, hardtext)
	draw.DrawText( str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, color_white, TEXT_ALIGN_CENTER )

	local _,h = surface.GetTextSize( str )
	yoffset = yoffset + h + pos.edgesize

	-- fancy percent bar

	local softquota_width = w * 0.7
	local quota_width = softquota_width * math.min(prfbench/e2_softquota,1) + (w - softquota_width + 1) * (prfcount/e2_hardquota)

	local y = yoffset
	surface.SetDrawColor(0, 170, 0, 255)
	surface.DrawRect( pos.min.x + pos.edgesize, y, softquota_width, 20 )

	surface.SetDrawColor(170, 0, 0, 255)
	surface.DrawRect( pos.min.x + pos.edgesize + softquota_width - 1, y, w - softquota_width + 2, 20 )

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect( pos.min.x + pos.edgesize, y, quota_width, 20 )

	surface.SetDrawColor(0, 0, 0)
	surface.DrawLine( pos.min.x + pos.edgesize, y, pos.min.x + pos.edgesize + w, y )
	surface.DrawLine( pos.min.x + pos.edgesize + w, y, pos.min.x + pos.edgesize + w, y + 20 )
	surface.DrawLine( pos.min.x + pos.edgesize + w, y + 20, pos.min.x + pos.edgesize, y + 20 )
	surface.DrawLine( pos.min.x + pos.edgesize, y + 20, pos.min.x + pos.edgesize, y )

	yoffset = yoffset + 20

	-- cpu time text
	local str = string.format("cpu time: %ius", timebench*1000000)
	draw.DrawText( str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, color_white, TEXT_ALIGN_CENTER )
end
