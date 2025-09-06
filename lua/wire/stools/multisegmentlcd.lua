WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "multisegmentlcd", "Multi-segment LCD", "gmod_wire_multisegmentlcd", nil, "Multi-segment LCDs" )

GROUP = -1
UNION = 0
SEGMENT = 1
TEXT = 2
MATRIX = 3

WireLib.SegmentLCD_Tree = {
		Type=GROUP,
		X=0,
		Y=0,
		Children=
		{
		
		}
	}


if CLIENT then
	language.Add( "tool.wire_multisegmentlcd.name", "Multi-segment LCD Tool (Wire)" )
	language.Add( "tool.wire_multisegmentlcd.desc", "Spawns a Multi-segment LCD, which can be used to display numbers and miscellaneous graphics" )
	language.Add( "tool.wire_multisegmentlcd.interactive", "Interactive (if available):" )
	language.Add( "tool.wire_multisegmentlcd.resw", "Canvas Width:" )
	language.Add( "tool.wire_multisegmentlcd.resh", "Canvas Height:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon("icon16/application_xp_terminal.png")
	
	
	
	net.Receive("wire_multisegmentlcd_tool_upload_request", function(len, ply)
		local ent = net.ReadUInt(16)
		local serialized = WireLib.von.serialize(WireLib.SegmentLCD_Tree)
		if #serialized > 65535 then
			return
		end
		net.Start("wire_multisegmentlcd_tool_upload")
			net.WriteUInt(ent,16)
			net.WriteUInt(#serialized,16)
			net.WriteData(serialized)
		net.SendToServer()
		--ent.Tree = table.Copy(WireLib.SegmentLCD_Tree)
	end)
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	
	function TOOL:GetConVars()
		return self:GetClientNumber("interactive"), math.Clamp(self:GetClientNumber("resw"),0,1024), math.Clamp(self:GetClientNumber("resh"),0,1024)
	end
	
	util.AddNetworkString("wire_multisegmentlcd_tool_upload_request")
	util.AddNetworkString("wire_multisegmentlcd_tool_upload")
	
	
	function TOOL:LeftClick_Update( trace )
		net.Start("wire_multisegmentlcd_tool_upload_request")
			net.WriteUInt(trace.Entity:EntIndex(),16)
		net.Send(self:GetOwner())
		trace.Entity:Setup(self:GetConVars())
	end
	
	net.Receive("wire_multisegmentlcd_tool_upload", function(len, ply)
		local ent = ents.GetByIndex(net.ReadUInt(16))
		local sz = net.ReadUInt(16)
		ent.Tree = WireLib.von.deserialize(net.ReadData(sz))
		ent:Retransmit()
	end)
	
	function TOOL:MakeEnt( ply, model, Ang, trace )
		local ent = WireLib.MakeWireEnt( ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model}, self:GetConVars() )
		if ent and ent.RestoreNetworkVars then ent:RestoreNetworkVars(self:GetDataTables()) end
		net.Start("wire_multisegmentlcd_tool_upload_request")
			net.WriteUInt(ent:EntIndex(),16)
		net.Send(ply)
		return ent
	end
end

TOOL.ClientConVar = {
	model		= "models/props_lab/monitor01b.mdl",
	createflat	= 0,
	interactive = 1,
	resw = 1024,
	resh = 1024,
}


function BuildNode(v,node,group)
	local new = nil
	if v.Type == GROUP then
		new = node:AddNode( "Group", "icon16/text_list_numbers.png" )
		BuildNodes(new,v)
	elseif v.Type == UNION then
		new = node:AddNode( "Union", "icon16/text_list_bullets.png" )
		BuildNodes(new,v)
	elseif v.Type == TEXT then
		new = node:AddNode( "Text", "icon16/bullet_yellow.png" )
	elseif v.Type == MATRIX then
		new = node:AddNode( "Matrix", "icon16/bullet_red.png" )
	else
		new = node:AddNode( "Segment", "icon16/bullet_green.png" )
	end
	new.group = v
	new.parentgroup = group
end

function BuildNodes(node,group)
	for i,v in ipairs(group.Children) do
		BuildNode(v,node,group)
	end
end

local invalid_filename_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["|"] = "",
	["\\"] = "",
	['"'] = "",
	[" "] = "_",
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_multisegmentlcd_model", list.Get( "WireScreenModels" ), 5)
	panel:CheckBox("#tool.wire_multisegmentlcd.interactive", "wire_multisegmentlcd_interactive")
	panel:CheckBox("#Create Flat to Surface", "wire_multisegmentlcd_createflat")
	panel:TextEntry("#tool.wire_multisegmentlcd.resw", "wire_multisegmentlcd_resw")
	panel:TextEntry("#tool.wire_multisegmentlcd.resh", "wire_multisegmentlcd_resh")
	TreeDataHolder = vgui.Create("DPanel", panel)
	panel:AddPanel(TreeDataHolder)
	TreeDataHolder:DockMargin(0, 0, 0, 0)
	TreeDataHolder:Dock(TOP)
	TreeDataHolder:SetHeight(480)
	DisplayData = vgui.Create("DTree", TreeDataHolder)
	DisplayData:Dock(FILL)
	DisplayData:DockMargin(0, 0, 0, 0)
	--DisplayData.RootNode:AddNode( "Root", "icon16/monitor.png" )
	DisplayData.RootNode.group = WireLib.SegmentLCD_Tree
	BuildNodes(DisplayData.RootNode,WireLib.SegmentLCD_Tree)
	ButtonsHolder = TreeDataHolder:Add( "DPanel" )
	ButtonsHolder:Dock(TOP)
	ButtonsHolder:DockMargin(0, 0, 0, 0)
	ButtonsHolder.buttons = {}
	ButtonsHolder:SetHeight(60)
	
	AddSegment =  ButtonsHolder:Add( "DButton" )
	AddSegment:SetText( "Add Segment" )
	ButtonsHolder.buttons[1] = AddSegment
	function AddSegment:DoClick()
		local node = DisplayData:GetSelectedItem()
		if node == nil then
			node = DisplayData.RootNode
		end
		local group = node.group
		local children = nil
		if group ~= nil then
			children = group.Children
		end
		
		if children == nil then
			node = DisplayData.RootNode
			children = WireLib.SegmentLCD_Tree.Children
			group = WireLib.SegmentLCD_Tree
		end
		local newgroup = {Type=SEGMENT, X=30,Y=0,W=10,H=20}
		children[#children+1] = newgroup
		local new = node:AddNode( "Segment", "icon16/bullet_green.png" )
		new.group = newgroup
		new.parentgroup = group
	end
	
	AddText =  ButtonsHolder:Add( "DButton" )
	AddText:SetText( "Add Text" )
	ButtonsHolder.buttons[2] = AddText
	function AddText:DoClick()
		local node = DisplayData:GetSelectedItem()
		if node == nil then
			node = DisplayData.RootNode
		end
		local group = node.group
		local children = nil
		if group ~= nil then
			children = group.Children
		end
		
		if children == nil then
			node = DisplayData.RootNode
			children = WireLib.SegmentLCD_Tree.Children
			group = WireLib.SegmentLCD_Tree
		end
		local newgroup = {Type=TEXT, X=30, Y=0, Text="Hello"}
		children[#children+1] = newgroup
		local new = node:AddNode( "Text", "icon16/bullet_yellow.png" )
		new.group = newgroup
		new.parentgroup = group
	end
	
	AddMatrix =  ButtonsHolder:Add( "DButton" )
	AddMatrix:SetText( "Add Matrix" )
	ButtonsHolder.buttons[3] = AddMatrix
	function AddMatrix:DoClick()
		local node = DisplayData:GetSelectedItem()
		if node == nil then
			node = DisplayData.RootNode
		end
		local group = node.group
		local children = nil
		if group ~= nil then
			children = group.Children
		end
		
		if children == nil then
			node = DisplayData.RootNode
			children = WireLib.SegmentLCD_Tree.Children
			group = WireLib.SegmentLCD_Tree
		end
		local newgroup = {Type=MATRIX, X=0, Y=0, W=6, H=8, ScaleW=5, ScaleH=5, OffsetX=6, OffsetY=6}
		children[#children+1] = newgroup
		local new = node:AddNode( "Matrix", "icon16/bullet_red.png" )
		new.group = newgroup
		new.parentgroup = group
	end
	
	AddGroup =  ButtonsHolder:Add( "DButton" )
	AddGroup:SetText( "Add Group" )
	ButtonsHolder.buttons[4] = AddGroup
	function AddGroup:DoClick()
		local node = DisplayData:GetSelectedItem()
		if node == nil then
			node = DisplayData.RootNode
		end
		local group = node.group
		local children = nil
		if group ~= nil then
			children = group.Children
		end
		if children == nil then
			node = DisplayData.RootNode
			children = WireLib.SegmentLCD_Tree.Children
			group = WireLib.SegmentLCD_Tree
		end
		local newgroup = {Type=GROUP,Children={},X=0,Y=0}
		children[#children+1] = newgroup
		local new = node:AddNode( "Group", "icon16/text_list_numbers.png" )
		new.group = newgroup
		new.parentgroup = group
	end
	
	AddUnion =  ButtonsHolder:Add( "DButton" )
	AddUnion:SetText( "Add Union" )
	ButtonsHolder.buttons[5] = AddUnion
	function AddUnion:DoClick()
		local node = DisplayData:GetSelectedItem()
		if node == nil then
			node = DisplayData.RootNode
		end
		local group = node.group
		local children = nil
		if group ~= nil then
			children = group.Children
		end
		if children == nil then
			node = DisplayData.RootNode
			children = WireLib.SegmentLCD_Tree.Children
			group = WireLib.SegmentLCD_Tree
		end
		local newgroup = {Type=UNION,Children={},X=0,Y=0}
		children[#children+1] = newgroup
		local new = node:AddNode( "Union", "icon16/text_list_bullets.png" )
		new.group = newgroup
		new.parentgroup = group
	end
	
	Remove =  ButtonsHolder:Add( "DButton" )
	Remove:SetText( "Remove" )
	ButtonsHolder.buttons[6] = Remove
	function Remove:DoClick()
		local node = DisplayData:GetSelectedItem()
		if node == nil then
			return
		end
		local parentgroup = node.parentgroup
		if parentgroup == nil then
			return
		end
		for i,v in pairs(parentgroup.Children) do
			if v == node.group then
				table.remove(parentgroup.Children,i)
				node:Remove()
				return
			end
		end
	end
	ButtonsHolder.textboxes = {}
	WangX = ButtonsHolder:Add( "DNumberWang" )
	function WangX:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.X = value
	end
	ButtonsHolder.textboxes[1] = WangX
	WangY = ButtonsHolder:Add( "DNumberWang" )
	function WangY:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.Y = value
	end
	ButtonsHolder.textboxes[2] = WangY
	WangW = ButtonsHolder:Add( "DNumberWang" )
	function WangW:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= SEGMENT then
			return
		end
		node.group.W = value
	end
	ButtonsHolder.textboxes[3] = WangW
	WangH = ButtonsHolder:Add( "DNumberWang" )
	function WangH:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= SEGMENT then
			return
		end
		node.group.H = value
	end
	ButtonsHolder.textboxes[4] = WangH
	
	TextSetter = ButtonsHolder:Add( "DTextEntry" )
	function TextSetter:OnValueChange(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= TEXT then
			return
		end
		node.group.Text = value
	end
	
	WangScaleW = ButtonsHolder:Add( "DNumberWang" )
	function WangScaleW:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.ScaleW = value
	end
	
	WangScaleH = ButtonsHolder:Add( "DNumberWang" )
	function WangScaleH:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.ScaleH = value
	end
	
	WangOffsetX = ButtonsHolder:Add( "DNumberWang" )
	function WangOffsetX:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.OffsetX = value
	end
	
	WangOffsetY = ButtonsHolder:Add( "DNumberWang" )
	function WangOffsetY:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.OffsetY = value
	end
	
	function ButtonsHolder:PerformLayout(w, h)
		for i,v in ipairs(self.buttons) do
			v:SetPos((i-1)*w/#self.buttons,0)
			v:SetSize(w/#self.buttons,h/3)
		end
		for i,v in ipairs(self.textboxes) do
			v:SetPos((i-1)*w/#self.textboxes,h/3)
			v:SetSize(w/#self.textboxes,h/3)
		end
		TextSetter:SetPos(0,h/3*2)
		TextSetter:SetSize(w,h/3)
		WangScaleW:SetPos(0,h/3*2)
		WangScaleW:SetSize(w/4,h/3)
		WangScaleH:SetPos(w/4,h/3*2)
		WangScaleH:SetSize(w/4,h/3)
		WangOffsetX:SetPos(w/4*2,h/3*2)
		WangOffsetX:SetSize(w/4,h/3)
		WangOffsetY:SetPos(w/4*3,h/3*2)
		WangOffsetY:SetSize(w/4,h/3)
	end
	WangW:SetVisible(false)
	WangH:SetVisible(false)
	TextSetter:SetVisible(false)
	WangScaleW:SetVisible(false)
	WangScaleH:SetVisible(false)
	WangOffsetX:SetVisible(false)
	WangOffsetY:SetVisible(false)
	
	
	function DisplayData:DoClick(node)
		group = node.group
		if group.Type == SEGMENT then
			WangX:SetValue(group.X)
			WangY:SetValue(group.Y)
			WangW:SetValue(group.W)
			WangH:SetValue(group.H)
			WangW:SetVisible(true)
			WangH:SetVisible(true)
			TextSetter:SetVisible(false)
			WangScaleW:SetVisible(false)
			WangScaleH:SetVisible(false)
			WangOffsetX:SetVisible(false)
			WangOffsetY:SetVisible(false)
		elseif group.Type == MATRIX then
			WangX:SetValue(group.X)
			WangY:SetValue(group.Y)
			WangW:SetValue(group.W)
			WangH:SetValue(group.H)
			TextSetter:SetVisible(false)
			WangScaleW:SetVisible(true)
			WangScaleH:SetVisible(true)
			WangOffsetX:SetVisible(true)
			WangOffsetY:SetVisible(true)
			WangW:SetVisible(true)
			WangH:SetVisible(true)
			WangScaleW:SetValue(group.ScaleW)
			WangScaleH:SetValue(group.ScaleH)
			WangOffsetX:SetValue(group.OffsetX)
			WangOffsetY:SetValue(group.OffsetY)
		elseif group.Type == TEXT then
			WangX:SetValue(group.X)
			WangY:SetValue(group.Y)
			WangW:SetVisible(false)
			WangH:SetVisible(false)
			TextSetter:SetVisible(true)
			TextSetter:SetValue(group.Text)
			WangScaleW:SetVisible(false)
			WangScaleH:SetVisible(false)
			WangOffsetX:SetVisible(false)
			WangOffsetY:SetVisible(false)
		else
			WangX:SetValue(group.X)
			WangY:SetValue(group.Y)
			WangW:SetVisible(false)
			WangH:SetVisible(false)
			WangScaleW:SetVisible(false)
			WangScaleH:SetVisible(false)
			WangOffsetX:SetVisible(false)
			WangOffsetY:SetVisible(false)
			TextSetter:SetVisible(false)
		end
		return true
	end
	
	function DisplayData:DoRightClick(node)
		local Menu = DermaMenu()
		Menu:AddOption( "Copy" )
		Menu:AddOption( "Paste" )
		Menu:Open()
		function Menu:OptionSelected(option, optionText)
			if optionText == "Copy" then
				SegmentLCD_Clipboard = table.Copy(node.group)
			elseif optionText == "Paste" then
				if node.group.Children then
					local newgroup = table.Copy(SegmentLCD_Clipboard)
					node.group.Children[#node.group.Children+1] = newgroup
					BuildNode(newgroup,node,node.group)
				else
					local newgroup = table.Copy(SegmentLCD_Clipboard)
					WireLib.SegmentLCD_Tree.Children[#WireLib.SegmentLCD_Tree.Children+1] = newgroup
					BuildNode(newgroup,DisplayData.RootNode,WireLib.SegmentLCD_Tree)
				end
			end
		end
		return true
	end
	
	local FileBrowser = vgui.Create("wire_expression2_browser", panel)
	panel:AddPanel(FileBrowser)
	FileBrowser:Setup("multisegmentlcd")
	FileBrowser:SetSize(w, 320)
	FileBrowser:DockMargin(0, 0, 0, 0)
	FileBrowser:DockPadding(0, 0, 0, 0)
	FileBrowser:Dock(TOP)
	FileBrowser:RemoveRightClick("New File")
	
	for k, v in pairs(FileBrowser.foldermenu) do
		if (v[1] == "New File..") then
			FileBrowser.foldermenu[k] = nil
			break
		end
	end
	
	function SaveFile(curloc,path)
		file.CreateDir(curloc)
		file.Write(path, util.TableToJSON(WireLib.SegmentLCD_Tree))
		FileBrowser:UpdateFolders()
	end
	
	function FileBrowser:OnFileOpen(filepath, newtab)
		local newgroup = util.JSONToTable(file.Read(filepath))
		local node = DisplayData:GetSelectedItem()
		if node == nil then
			node = DisplayData.RootNode
		end
		local group = node.group
		local children = nil
		if group ~= nil then
			children = group.Children
		end
		if children == nil then
			node = DisplayData.RootNode
			children = WireLib.SegmentLCD_Tree.Children
			group = WireLib.SegmentLCD_Tree
		end
		node.group.Children[#node.group.Children+1] = newgroup
		BuildNode(newgroup,node,node.group)
	end
	
	local Save = panel:Button("Save")
	function Save:DoClick()
		Derma_StringRequestNoBlur("Save to file", "", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			local curlocation = "multisegmentlcd"
			if FileBrowser.File then
				local newcurloc = FileBrowser.File:GetFolder()
				curlocation = newcurloc or curlocation
			end
			local save_location = curlocation .. "/" .. strTextOut .. ".txt"
			if file.Exists(save_location, "DATA") then
				Derma_QueryNoBlur("The file '" .. strTextOut .. "' already exists. Do you want to overwrite it?", "File already exists",
				"Yes", function() SaveFile(curlocation,save_location) end,
				"No", function() end)
			else
				SaveFile(curlocation,save_location)
			end
		end)
	end
end
