include('shared.lua')

local function Include(e2, directives, includes, scripts)
	if scripts[e2] then
		return
	end

	local code = file.Read("expression2/" .. e2 .. ".txt")
	-- removed CLIENT as this is client file
	-- local code
	-- if CLIENT the code = file.Read("expression2/" .. e2 .. ".txt")

	if not code then
		return false, "Could not find include '" .. e2 .. ".txt'"
	end

	local status, err, buffer = E2Lib.PreProcessor.Execute(code, directives)
	if not status then
		return "include '" .. e2 .. "' -> " .. err
	end

	local status, tokens = E2Lib.Tokenizer.Execute(buffer)
	if not status then
		return "include '" .. e2 .. "' -> " .. tokens
	end

	local status, tree, dvars, files = E2Lib.Parser.Execute(tokens)
	if not status then
		return "include '" .. e2 .. "' -> " .. tree
	end

	includes[e2] = code

	scripts[e2] = { tree }

	for i = 1, #files do
		local error = Include(files[i], directives, includes, scripts)
		if error then return error end
	end
end

function wire_expression2_validate(buffer)
	-- removed CLIENT as this is client file
	-- if CLIENT and
	if not e2_function_data_received then return "Loading extensions. Please try again in a few seconds..." end

	-- invoke preprocessor
	local status, directives, buffer = E2Lib.PreProcessor.Execute(buffer)
	if not status then return directives end

	-- decompose directives
	local inports, outports, persists = directives.inputs, directives.outputs, directives.persist
	-- removed CLIENT as this is client file
	-- if CLIENT then
	RunConsoleCommand("wire_expression2_scriptmodel", directives.model or "")
	-- end

	-- invoke tokenizer (=lexer)
	local status, tokens = E2Lib.Tokenizer.Execute(buffer)
	if not status then return tokens end

	-- invoke parser
	local status, tree, dvars, files = E2Lib.Parser.Execute(tokens)
	if not status then return tree end

	-- prepare includes
	local includes, scripts = {}, {}
	for i = 1, #files do
		local error = Include(files[i], directives, includes, scripts)
		if error then return error end
	end

	-- invoke compiler
	local status, script, instance = E2Lib.Compiler.Execute(tree, inports[3], outports[3], persists[3], dvars, scripts)
	if not status then return script end

	return nil, includes
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
	return w, h
end

local h_of_lower = 100 -- height of the lower section (the prfbench/percent bar section)
function ENT:GetWorldTipBodySize()
	local data = self:GetOverlayData()
	if not data then return 100, 20 end
	
	local w_total,h_total = wtfgarry( data.txt )
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
	
	local txt = data.txt
	local err = data.error -- this isn't used (yet), might do something with it later
	
	local white = Color(255,255,255,255)
	local black = Color(0,0,0,255)
	
	local w_total, yoffset = 0, pos.min.y
		
	-------------------
	-- Name
	-------------------
	local w,h = wtfgarry( txt )
	h = h + pos.edgesize
	h = math.min(h,pos.size.h - (h_of_lower+pos.footersize.h))
	
	render.SetScissorRect( pos.min.x + 16, pos.min.y, pos.max.x - 16, pos.min.y + h, true )
	draw.DrawText( txt, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, white, TEXT_ALIGN_CENTER )
	render.SetScissorRect( 0, 0, ScrW(), ScrH(), false )
	
	w_total = math.max( w_total, w )
	yoffset = yoffset + h
	
	surface.SetDrawColor( black )
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
	draw.DrawText( str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, white, TEXT_ALIGN_CENTER )
	
	local _,h = surface.GetTextSize( str )
	yoffset = yoffset + h + pos.edgesize

	-- fancy percent bar
	
	local softquota_width = w * 0.7
	local quota_width = softquota_width * math.min(prfbench/e2_softquota,1) + (w - softquota_width + 1) * (prfcount/e2_hardquota)
	
	local y = yoffset
	surface.SetDrawColor( Color(0,170,0,255) )
	surface.DrawRect( pos.min.x + pos.edgesize, y, softquota_width, 20 )
	
	surface.SetDrawColor( Color(170,0,0,255) )
	surface.DrawRect( pos.min.x + pos.edgesize + softquota_width - 1, y, w - softquota_width + 2, 20 )
	
	surface.SetDrawColor( Color(0,0,0,200) )
	surface.DrawRect( pos.min.x + pos.edgesize, y, quota_width, 20 )
	
	surface.SetDrawColor( black )
	surface.DrawLine( pos.min.x + pos.edgesize, y, pos.min.x + pos.edgesize + w, y )
	surface.DrawLine( pos.min.x + pos.edgesize + w, y, pos.min.x + pos.edgesize + w, y + 20 )
	surface.DrawLine( pos.min.x + pos.edgesize + w, y + 20, pos.min.x + pos.edgesize, y + 20 )
	surface.DrawLine( pos.min.x + pos.edgesize, y + 20, pos.min.x + pos.edgesize, y )
	
	yoffset = yoffset + 20
	
	-- cpu time text
	local str = string.format("cpu time: %ius", timebench*1000000)
	draw.DrawText( str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, white, TEXT_ALIGN_CENTER )
end
