
if SERVER then
	resource.AddFile("materials/gui/silkicons/emoticon_smile.vtf")
	resource.AddFile("materials/gui/silkicons/newspaper.vtf")
	resource.AddFile("materials/gui/silkicons/wrench.vtf")
	resource.AddFile("materials/vgui/spawnmenu/save.vtf")
else
	local fontTable = 
	{
		font = "defaultbold",
		size = 12,
		weight = 700,
		antialias = true,
		additive = false,
	}
	surface.CreateFont("DefaultBold", fontTable)
end
