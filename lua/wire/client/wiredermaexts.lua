WireDermaExts = {}
language.Add("wire_model", "Model:")

-- Shortcut functions for Wire tools to make their model select controls
-- TODO: redo category system
function ModelPlug_AddToCPanel(panel, category, toolname, textbox_label, height)
	local list = list.Get("Wire_"..category.."_Models")
	if table.Count(list) > 1 then
		local ModelSelect = vgui.Create("DWireModelSelect", panel)
		ModelSelect:SetModelList(list, toolname .. "_model")
		ModelSelect:SetHeight(height)
		panel:AddPanel(ModelSelect)
	end
	if textbox_label and GetConVarNumber("cl_showmodeltextbox") > 0 then
		panel:TextEntry("#wire_model", toolname .. "_model")
	end
end

function ModelPlug_AddToCPanel_Multi(panel, categories, toolname, textbox_label, height)
	local ModelSelect = vgui.Create("DWireModelSelectMulti", panel)
		ModelSelect:SetHeight(height)
	panel:AddPanel(ModelSelect)
	local cvar = toolname .. "_model"
	for category, name in pairs_sortkeys(categories) do
		local list = list.Get("Wire_"..category.."_Models")
		if list then
			ModelSelect:AddModelList(name, list, cvar)
		end
	end
	if textbox_label and GetConVarNumber("cl_showmodeltextbox") > 0 then
		panel:TextEntry(textbox_label, toolname .. "_model")
	end
end


function WireDermaExts.ModelSelect(panel, convar, list, height, show_textbox)
	if table.Count(list) > 1 then
		local ModelSelect = vgui.Create("DWireModelSelect", panel)
		ModelSelect:SetModelList(list, convar)
		ModelSelect:SetHeight(height)
		panel:AddPanel(ModelSelect)
		if show_textbox and GetConVarNumber("cl_showmodeltextbox") > 0 then
			panel:TextEntry("#wire_model", convar)
		end
		return ModelSelect
	end
end


--
--	Additional Derma controls
--
--		This are under testing
--		I will try to have them included in to GMod when they are stable
--


--
-- DWireModelSelect
--	sexy model select
local PANEL = {}

function PANEL:Init()
	self:EnableVerticalScrollbar()
	self:SetTall(66 * 2 + 2)
end

function PANEL:SetHeight(height)
	self:SetTall(66 * (height or 2) + 2)
end

function PANEL:SetModelList( list, cvar )
	for model,v in pairs(list) do
		local icon = vgui.Create("SpawnIcon")
		icon:SetModel(model)
		icon.Model = model
		icon:SetSize(64, 64)
		icon:SetTooltip(model)
		self:AddPanel(icon, {[cvar] = model})
	end
	self:SortByMember("Model", false)
end

derma.DefineControl( "DWireModelSelect", "", PANEL, "DPanelSelect" )

--
-- DWireModelSelectMulti
--	sexy tabbed model select with categories
local PANEL = {}

function PANEL:Init()
	self.ModelPanels = {}
	self:SetTall(66 * 2 + 26)
end

function PANEL:SetHeight(height)
	self:SetTall(66 * (height or 2) + 26)
end

function PANEL:AddModelList( Name, list, cvar )
	local PanelSelect = vgui.Create("DWireModelSelect", self)
	PanelSelect:SetModelList(list, cvar)
	self:AddSheet(Name, PanelSelect)
	self.ModelPanels[Name] = PanelSelect
end

derma.DefineControl( "DWireModelSelectMulti", "", PANEL, "DPropertySheet" )
