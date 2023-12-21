WireLib.RTFix = {}
local RTFix = WireLib.RTFix

---------------------------------------------------------------------
-- RTFix Lib
---------------------------------------------------------------------
RTFix.List = {}

function RTFix:Add( ClassName, NiceName, Function )
	RTFix.List[ClassName] = { NiceName, Function }
end

function RTFix:GetAll()
	return RTFix.List
end

function RTFix:Get( ClassName )
	return RTFix.List[ClassName]
end

function RTFix:ReloadAll()
	for k,v in pairs( RTFix.List ) do
		local func = v[2]
		for k2,v2 in ipairs( ents.FindByClass( k ) ) do
			func( v2 )
		end
	end
end

function RTFix:Reload( ClassName )
	local func = RTFix.List[ClassName][2]
	for k, v in ipairs( ents.FindByClass( ClassName ) ) do
		func( v )
	end
end

---------------------------------------------------------------------
-- Console Command
---------------------------------------------------------------------

concommand.Add("wire_rt_fix",function()
	RTFix:ReloadAll()
end)

---------------------------------------------------------------------
-- Tool Menu
---------------------------------------------------------------------

local function CreateCPanel( Panel )
	Panel:ClearControls()

	Panel:Help( [[Here you can fix screens that use
rendertargets if they break due to lag.
If a screen is not on this list, it means
that either its author has not added it to
this list, the screen has its own fix, or
that no fix is necessary.
You can also use the console command
"wire_rt_fix", which does the same thing
as pressing the "All" button.]] )

	local btn = vgui.Create("DButton")
	btn:SetText("All")
	function btn:DoClick()
		RTFix:ReloadAll()
	end
	btn:SetToolTip( "Fix all RTs on the map." )
	Panel:AddItem( btn )

	for k,v in pairs( RTFix.List ) do
		local btn = vgui.Create("DButton")
		btn:SetText( v[1] )
		btn:SetToolTip( "Fix all " .. v[1] .. "s on the map\n("..k..")" )
		function btn:DoClick()
			RTFix:Reload( k )
		end
		Panel:AddItem( btn )
	end
end

hook.Add("PopulateToolMenu","WireLib_RenderTarget_Fix",function()
	spawnmenu.AddToolMenuOption( "Wire", "Options", "RTFix", "Fix RenderTargets", "", "", CreateCPanel, nil )
end)

---------------------------------------------------------------------
-- Add all default wire components
-- credits to sk89q for making this: http://www.wiremod.com/forum/bug-reports/19921-cs-egp-gpu-etc-issue-when-rejoin-lag-out.html#post193242
---------------------------------------------------------------------

-- Helper function
local function def( ent, redrawkey )
	if (ent.GPU or ent.GPU.RT) then
		ent.GPU:FreeRT()
	end

	ent.GPU:Initialize()

	if (redrawkey) then
		ent[redrawkey] = true
	end
end

RTFix:Add("gmod_wire_consolescreen","Console Screen", function( ent ) def( ent, "NeedRefresh" ) end)
RTFix:Add("gmod_wire_digitalscreen","Digital Screen", function( ent ) def( ent, "NeedRefresh" ) end)
--RTFix:Add("gmod_wire_graphics_tablet","Graphics Tablet", function( ent ) def( ent, nil, true ) end) No fix is needed for this
RTFix:Add("gmod_wire_oscilloscope","Oscilloscope", def)
--RTFix:Add("gmod_wire_panel","Control Panel", function( ent ) def( ent, nil, true ) end) No fix is needed for this
--RTFix:Add("gmod_wire_screen","Screen", function( ent ) def( ent, nil, true ) end) No fix is needed for this
RTFix:Add("gmod_wire_textscreen","Text Screen", function( ent ) def( ent, "NeedRefresh" ) end)
RTFix:Add("gmod_wire_egp","EGP",function( ent ) def( ent, "NeedsUpdate" ) end)

-- EGP Emitter needs a check because it can optionally not use RTs
RTFix:Add("gmod_wire_egp_emitter","EGP Emitter",function( ent )
	if ent:GetUseRT() then
		def( ent, "NeedsUpdate" )
	end
end)
