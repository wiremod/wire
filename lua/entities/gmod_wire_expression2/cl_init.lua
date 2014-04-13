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

	local status, err, buffer = PreProcessor.Execute(code, directives)
	if not status then
		return "include '" .. e2 .. "' -> " .. err
	end

	local status, tokens = Tokenizer.Execute(buffer)
	if not status then
		return "include '" .. e2 .. "' -> " .. tokens
	end

	local status, tree, dvars, files = Parser.Execute(tokens)
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
	local status, directives, buffer = PreProcessor.Execute(buffer)
	if not status then return directives end

	-- decompose directives
	local inports, outports, persists = directives.inputs, directives.outputs, directives.persist
	-- removed CLIENT as this is client file
	-- if CLIENT then
	RunConsoleCommand("wire_expression2_scriptmodel", directives.model or "")
	-- end

	-- invoke tokenizer (=lexer)
	local status, tokens = Tokenizer.Execute(buffer)
	if not status then return tokens end

	-- invoke parser
	local status, tree, dvars, files = Parser.Execute(tokens)
	if not status then return tree end

	-- prepare includes
	local includes, scripts = {}, {}
	for i = 1, #files do
		local error = Include(files[i], directives, includes, scripts)
		if error then return error end
	end

	-- invoke compiler
	local status, script, instance = Compiler.Execute(tree, inports[3], outports[3], persists[3], dvars, scripts)
	if not status then return script end

	return nil, includes
end

function ENT:GetWorldTipBodySize()
	return self:DrawWorldTipBody( {min={x=0,y=0}}, true ) -- this is a bit of a hack, but it's the only way to get the true size of what we're about to draw
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

function ENT:DrawWorldTipBody( pos, dontdraw )
	local data = self:GetOverlayData()
	if not data then return end
	
	local txt = data.txt
	local err = data.error -- this isn't used (yet), might do something with it later
	
	local white = Color(255,255,255,255)
	local black = Color(0,0,0,255)
	
	local h_of_lower = 210 -- height of the lower section (the prfbench/percent bar section)
	
	local w_total, yoffset = 0, pos.min.y
	
	-------------------
	-- Name
	-------------------
	local w,h = wtfgarry( txt )
	h = math.min(h,ScrH()-h_of_lower)
	
	if not dontdraw then
		render.SetScissorRect( pos.min.x + 16, pos.min.y, pos.max.x - 16, pos.max.y - (pos.size.h - h) + 9, true )
		draw.DrawText( txt, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, white, TEXT_ALIGN_CENTER )
		render.SetScissorRect( 0, 0, ScrW(), ScrH(), false )
	end
	
	w_total = math.max( w_total, w )
	yoffset = yoffset + h + 18
	
	if not dontdraw then
		surface.SetDrawColor( black )
		surface.DrawLine( pos.min.x, yoffset, pos.max.x, yoffset )
	end
	
	-------------------
	-- prfcount/benchmarking/etc
	-------------------
	local prfbench = data.prfbench
	local prfcount = data.prfcount
	local timebench = data.timebench

	local e2_hardquota = GetConVar("wire_expression2_quotahard"):GetInt()
	local e2_softquota = GetConVar("wire_expression2_quotasoft"):GetInt()
		
	local hardtext = (prfcount / e2_hardquota > 0.33) and "(+" .. tostring(math.Round(prfcount / e2_hardquota * 100)) .. "%)" or ""
	local str = string.format("%i ops, %i%% %s\n\n\ncpu time: %ius", prfbench, prfbench / e2_softquota * 100, hardtext, timebench*1000000)
	
	if not dontdraw then
		local w = pos.size.w - 18 * 2
		
		local softquota_width = w * 0.7
		local quota_width = softquota_width * (prfbench/e2_softquota) + (w - softquota_width) * (prfcount/e2_hardquota)
	
		local y = yoffset + 36
		surface.SetDrawColor( Color(0,170,0,255) )
		surface.DrawRect( pos.min.x + 18, y, softquota_width, 20 )
		
		surface.SetDrawColor( Color(170,0,0,255) )
		surface.DrawRect( pos.min.x + 18 + softquota_width - 1, y, w - softquota_width + 2, 20 )
		
		surface.SetDrawColor( Color(0,0,0,200) )
		surface.DrawRect( pos.min.x + 18, y, quota_width, 20 )
		
		surface.SetDrawColor( black )
		surface.DrawLine( pos.min.x + 18, y, pos.min.x + 18 + w, y )
		surface.DrawLine( pos.min.x + 18 + w, y, pos.min.x + 18 + w, y + 20 )
		surface.DrawLine( pos.min.x + 18 + w, y + 20, pos.min.x + 18, y + 20 )
		surface.DrawLine( pos.min.x + 18, y + 20, pos.min.x + 18, y )
	
		draw.DrawText( str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 9, white, TEXT_ALIGN_CENTER )
	end
	
	local w,h = surface.GetTextSize( str )
	w_total = math.max( w_total, w )
	yoffset = yoffset + h	
	
	return w_total, yoffset - pos.min.y
end
