WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "multisegmentlcd", "Multi-segment LCD", "gmod_wire_multisegmentlcd", nil, "Multi-segment LCDs" )

GROUP = -1
UNION = 0
SEGMENT = 1
TEXT = 2
MATRIX = 3
SegmentTypeNames = {
[GROUP] = "Group",
[UNION] = "Union",
[SEGMENT] = "Segment",
[TEXT] = "Text",
[MATRIX] = "Matrix",
}

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
	language.Add( "tool.wire_multisegmentlcd.resw", "Canvas width:" )
	language.Add( "tool.wire_multisegmentlcd.resh", "Canvas height:" )
	language.Add( "tool.wire_multisegmentlcd.xormask", "Xor segment order mask:" )
	language.Add( "tool.wire_multisegmentlcd.fgcolor", "Segment color:" )
	language.Add( "tool.wire_multisegmentlcd.bgcolor", "Background color:" )
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
		return self:GetClientNumber("interactive") == 1, math.Clamp(self:GetClientNumber("resw"),0,1024), math.Clamp(self:GetClientNumber("resh"),0,1024),
			math.Clamp(self:GetClientNumber("bgred"), 0, 255),
			math.Clamp(self:GetClientNumber("bggreen"), 0, 255),
			math.Clamp(self:GetClientNumber("bgblue"), 0, 255),
			math.Clamp(self:GetClientNumber("bgalpha"), 0, 255),
			math.Clamp(self:GetClientNumber("fgred"), 0, 255),
			math.Clamp(self:GetClientNumber("fggreen"), 0, 255),
			math.Clamp(self:GetClientNumber("fgblue"), 0, 255),
			math.Clamp(self:GetClientNumber("fgalpha"), 0, 255),
			math.Clamp(self:GetClientNumber("xormask"), 0, 255)
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
	resw		= 1024,
	resh		= 1024,
	bgred		= 148,
	bggreen		= 178,
	bgblue		= 15,
	bgalpha		= 255,
	fgred		= 45,
	fggreen		= 91,
	fgblue		= 45,
	fgalpha		= 255,
	xormask		= 0
}


function BuildNode(v,node,group)
	local new = nil
	if v.Type == GROUP then
		new = node:AddNode( v.Text or "Group", "icon16/text_list_numbers.png" )
		BuildNodes(new,v)
	elseif v.Type == UNION then
		new = node:AddNode( v.Text or "Union", "icon16/text_list_bullets.png" )
		BuildNodes(new,v)
	elseif v.Type == TEXT then
		new = node:AddNode( v.Text or "Text", "icon16/bullet_yellow.png" )
	elseif v.Type == MATRIX then
		new = node:AddNode( v.Text or "Matrix", "icon16/bullet_red.png" )
	else
		new = node:AddNode( v.Text or "Segment", "icon16/bullet_green.png" )
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
	panel:TextEntry("#tool.wire_multisegmentlcd.xormask", "wire_multisegmentlcd_xormask")
	TreeDataHolder = vgui.Create("DPanel", panel)
	panel:AddPanel(TreeDataHolder)
	TreeDataHolder:DockMargin(0, 0, 0, 0)
	TreeDataHolder:Dock(TOP)
	TreeDataHolder:SetHeight(480)
	DisplayData = vgui.Create("DTree", TreeDataHolder)
	DisplayData:Dock(FILL)
	DisplayData:SetClickOnDragHover( true )
	DisplayData:DockMargin(0, 0, 0, 0)
	--DisplayData.RootNode:AddNode( "Root", "icon16/monitor.png" )
	DisplayData.RootNode.group = WireLib.SegmentLCD_Tree
	BuildNodes(DisplayData.RootNode,WireLib.SegmentLCD_Tree)
	ButtonsHolder = TreeDataHolder:Add( "DPanel" )
	ButtonsHolder:Dock(TOP)
	ButtonsHolder:DockMargin(0, 0, 0, 0)
	ButtonsHolder.buttons = {}
	ButtonsHolder:SetHeight(72)
	
	AddSegment =  ButtonsHolder:Add( "DButton" )
	AddSegment:SetText( "Add Segment" )
	ButtonsHolder.buttons[1] = AddSegment
	function AddSegmentI(node)
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
	function AddSegment:DoClick()
		local node = DisplayData:GetSelectedItem()
		AddSegmentI(node)
	end
	
	AddText =  ButtonsHolder:Add( "DButton" )
	AddText:SetText( "Add Text" )
	ButtonsHolder.buttons[2] = AddText
	function AddTextI(node)
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
		local newgroup = {Type=TEXT, X=30, Y=0, Text="Text"}
		children[#children+1] = newgroup
		local new = node:AddNode( "Text", "icon16/bullet_yellow.png" )
		new.group = newgroup
		new.parentgroup = group
	end
	function AddText:DoClick()
		local node = DisplayData:GetSelectedItem()
		AddTextI(node)
	end
	
	AddMatrix =  ButtonsHolder:Add( "DButton" )
	AddMatrix:SetText( "Add Matrix" )
	ButtonsHolder.buttons[3] = AddMatrix
	function AddMatrixI(node)
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
	function AddMatrix:DoClick()
		local node = DisplayData:GetSelectedItem()
		AddMatrixI(node)
	end
	
	AddGroup =  ButtonsHolder:Add( "DButton" )
	AddGroup:SetText( "Add Group" )
	ButtonsHolder.buttons[4] = AddGroup
	function AddGroupI(node)
		
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
		local newgroup = {Type=GROUP,Children={},X=0,Y=0,HasColor=false,R=255,G=255,B=255}
		children[#children+1] = newgroup
		local new = node:AddNode( "Group", "icon16/text_list_numbers.png" )
		new:SetExpanded(true);
		new.group = newgroup
		new.parentgroup = group
	end
	function AddGroup:DoClick()
		local node = DisplayData:GetSelectedItem()
		AddGroupI(node)
	end
	
	AddUnion =  ButtonsHolder:Add( "DButton" )
	AddUnion:SetText( "Add Union" )
	ButtonsHolder.buttons[5] = AddUnion
	function AddUnionI(node)
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
		local newgroup = {Type=UNION,Children={},X=0,Y=0,HasColor=false,R=255,G=255,B=255}
		children[#children+1] = newgroup
		local new = node:AddNode( "Union", "icon16/text_list_bullets.png" )
		new:SetExpanded(true);
		new.group = newgroup
		new.parentgroup = group
	end
	function AddUnion:DoClick()
		local node = DisplayData:GetSelectedItem()
		AddUnionI(node)
	end
	
	Remove =  ButtonsHolder:Add( "DButton" )
	Remove:SetText( "Remove" )
	ButtonsHolder.buttons[6] = Remove
	function RemoveI(node)
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
	WangX:SetMin(-1024)
	WangX:SetMax(1024)
	function WangX:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.X = value
	end
	ButtonsHolder.textboxes[1] = WangX
	WangY = ButtonsHolder:Add( "DNumberWang" )
	WangY:SetMin(-1024)
	WangY:SetMax(1024)
	function WangY:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.Y = value
	end
	ButtonsHolder.textboxes[2] = WangY
	WangW = ButtonsHolder:Add( "DNumberWang" )
	WangW:SetMax(1024)
	function WangW:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.W = value
	end
	ButtonsHolder.textboxes[3] = WangW
	WangH = ButtonsHolder:Add( "DNumberWang" )
	WangH:SetMax(1024)
	function WangH:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.H = value
	end
	ButtonsHolder.textboxes[4] = WangH
	
	TextSetter = ButtonsHolder:Add( "DTextEntry" )
	function TextSetter:OnChange()
		local value = TextSetter:GetText()
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		if  value == "" then
			node:SetText(SegmentTypeNames[node.group.Type])
			node.group.Text = nil
		else
			node:SetText(value)
			node.group.Text = value
		end
		
	end
	
	WangScaleW = ButtonsHolder:Add( "DNumberWang" )
	WangScaleW:SetMax(1024)
	function WangScaleW:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.ScaleW = value
	end
	
	WangScaleH = ButtonsHolder:Add( "DNumberWang" )
	WangScaleH:SetMax(1024)
	function WangScaleH:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.ScaleH = value
	end
	
	WangOffsetX = ButtonsHolder:Add( "DNumberWang" )
	WangOffsetX:SetMax(1024)
	function WangOffsetX:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.OffsetX = value
	end
	
	WangOffsetY = ButtonsHolder:Add( "DNumberWang" )
	WangOffsetY:SetMax(1024)
	function WangOffsetY:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil or node.group.Type ~= MATRIX then
			return
		end
		node.group.OffsetY = value
	end
	
	CheckHasColor = ButtonsHolder:Add( "DCheckBox" )
	function CheckHasColor:OnChange(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.HasColor = value
	end
	CheckLabel = ButtonsHolder:Add( "DLabel" )
	CheckLabel:SetText("Has color")
	CheckLabel:SetTextColor(Color(0,0,0,255))
	
	WangColorR = ButtonsHolder:Add( "DNumberWang" )
	WangColorR:SetMax(255)
	function WangColorR:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.R = value
	end
	
	WangColorG = ButtonsHolder:Add( "DNumberWang" )
	WangColorG:SetMax(255)
	function WangColorG:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.G = value
	end
	
	WangColorB = ButtonsHolder:Add( "DNumberWang" )
	WangColorB:SetMax(255)
	function WangColorB:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.B = value
	end
	
	WangColorA = ButtonsHolder:Add( "DNumberWang" )
	WangColorA:SetMax(255)
	function WangColorA:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.A = value
	end
	
	WangRotation = ButtonsHolder:Add( "DNumberWang" )
	WangRotation:SetMax(360)
	WangRotation:SetMin(-360)
	function WangRotation:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.Rotation = value
	end
	
	WangSkewX = ButtonsHolder:Add( "DNumberWang" )
	WangSkewX:SetMin(-4096)
	WangSkewX:SetMax(4096)
	function WangSkewX:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.SkewX = value
	end
	
	WangSkewY = ButtonsHolder:Add( "DNumberWang" )
	WangSkewY:SetMin(-4096)
	WangSkewY:SetMax(4096)
	function WangSkewY:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.SkewY = value
	end
	
	WangBevel = ButtonsHolder:Add( "DNumberWang" )
	WangBevel:SetMin(-1024)
	WangBevel:SetMax(1024)
	function WangBevel:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.Bevel = value
	end
	
	WangBevelSkew = ButtonsHolder:Add( "DNumberWang" )
	WangBevelSkew:SetMax(1024)
	WangBevelSkew:SetMin(-1024)
	function WangBevelSkew:OnValueChanged(value)
		local node = DisplayData:GetSelectedItem()
		if node == nil or node.group == nil then
			return
		end
		node.group.BevelSkew = value
	end
	
	function ButtonsHolder:PerformLayout(w, h)
		local roww = w/8
		local rowh = h/4
		for i,v in ipairs(self.buttons) do
			v:SetPos((i-1)*w/#self.buttons,0)
			v:SetSize(w/#self.buttons,rowh)
		end
		for i,v in ipairs(self.textboxes) do
			v:SetPos((i-1)*w/#self.textboxes,rowh)
			v:SetSize(w/#self.textboxes,rowh)
		end
		TextSetter:SetPos(0,rowh*3)
		TextSetter:SetSize(w,rowh)
		WangScaleW:SetPos(0,rowh*2)
		WangScaleW:SetSize(roww,rowh)
		WangScaleH:SetPos(roww,rowh*2)
		WangScaleH:SetSize(roww,rowh)
		WangOffsetX:SetPos(roww*2,rowh*2)
		WangOffsetX:SetSize(roww,rowh)
		WangOffsetY:SetPos(roww*3,rowh*2)
		WangOffsetY:SetSize(roww,rowh)
		
		CheckHasColor:SetPos(1,rowh*2+3)
		CheckLabel:SetPos(18,rowh*2)
		CheckLabel:SetSize(roww-18,rowh)
		WangColorR:SetPos(roww,rowh*2)
		WangColorR:SetSize(roww,rowh)
		WangColorG:SetPos(roww*2,rowh*2)
		WangColorG:SetSize(roww,rowh)
		WangColorB:SetPos(roww*3,rowh*2)
		WangColorB:SetSize(roww,rowh)
		WangColorA:SetPos(roww*4,rowh*2)
		WangColorA:SetSize(roww,rowh)
		
		WangRotation:SetPos(roww*4,rowh*2)
		WangRotation:SetSize(roww,rowh)
		WangSkewX:SetPos(roww*5,rowh*2)
		WangSkewX:SetSize(roww,rowh)
		WangSkewY:SetPos(roww*6,rowh*2)
		WangSkewY:SetSize(roww,rowh)
		
		WangBevel:SetPos(0,rowh*2)
		WangBevel:SetSize(roww,rowh)
		WangBevelSkew:SetPos(roww,rowh*2)
		WangBevelSkew:SetSize(roww,rowh)
	end
	WangW:SetVisible(false)
	WangH:SetVisible(false)
	WangScaleW:SetVisible(false)
	WangScaleH:SetVisible(false)
	WangOffsetX:SetVisible(false)
	WangOffsetY:SetVisible(false)
	WangColorR:SetVisible(false)
	WangColorG:SetVisible(false)
	WangColorB:SetVisible(false)
	WangColorA:SetVisible(false)
	CheckHasColor:SetVisible(false)
	CheckLabel:SetVisible(false)
	WangRotation:SetVisible(false)
	WangSkewX:SetVisible(false)
	WangSkewY:SetVisible(false)
	WangBevel:SetVisible(false)
	WangBevelSkew:SetVisible(false)
	
	function DisplayData:DoClick(node)
		group = node.group
		WangScaleW:SetVisible(false)
		WangScaleH:SetVisible(false)
		WangOffsetX:SetVisible(false)
		WangOffsetY:SetVisible(false)
		WangW:SetVisible(false)
		WangH:SetVisible(false)
		WangColorR:SetVisible(false)
		WangColorG:SetVisible(false)
		WangColorB:SetVisible(false)
		WangColorA:SetVisible(false)
		CheckHasColor:SetVisible(false)
		CheckLabel:SetVisible(false)
		WangRotation:SetVisible(false)
		WangSkewX:SetVisible(false)
		WangSkewY:SetVisible(false)
		WangBevel:SetVisible(false)
		WangBevelSkew:SetVisible(false)
		if group.Type == SEGMENT then
			WangW:SetValue(group.W)
			WangH:SetValue(group.H)
			WangW:SetVisible(true)
			WangH:SetVisible(true)
			WangRotation:SetVisible(true)
			WangSkewX:SetVisible(true)
			WangSkewY:SetVisible(true)
			WangBevel:SetVisible(true)
			WangBevelSkew:SetVisible(true)
			
			WangRotation:SetValue(group.Rotation or 0)
			WangSkewX:SetValue(group.SkewX or 0)
			WangSkewY:SetValue(group.SkewY or 0)
			WangBevel:SetValue(group.Bevel or 0)
			WangBevelSkew:SetValue(group.BevelSkew or 0)
		elseif group.Type == MATRIX then
			WangW:SetValue(group.W)
			WangH:SetValue(group.H)
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
		elseif group.Type == GROUP or group.Type == UNION then
			WangColorR:SetVisible(true)
			WangColorG:SetVisible(true)
			WangColorB:SetVisible(true)
			WangColorA:SetVisible(true)
			CheckHasColor:SetVisible(true)
			CheckLabel:SetVisible(true)
			WangColorR:SetValue(group.R)
			WangColorG:SetValue(group.G)
			WangColorB:SetValue(group.B)
			WangColorA:SetValue(group.A)
			CheckHasColor:SetValue(group.HasColor)
			WangRotation:SetVisible(true)
			WangSkewX:SetVisible(true)
			WangSkewY:SetVisible(true)
			WangRotation:SetValue(group.Rotation or 0)
			WangSkewX:SetValue(group.SkewX or 0)
			WangSkewY:SetValue(group.SkewY or 0)
			WangBevel:SetValue(group.Bevel or 0)
			WangBevelSkew:SetValue(group.BevelSkew or 0)
		end
		WangX:SetValue(group.X)
		WangY:SetValue(group.Y)
		TextSetter:SetValue(group.Text or "")
		return true
	end
	
	function DisplayData:DoRightClick(node)
		local Menu = DermaMenu()
		Menu:AddOption( "Rename" )
		Menu:AddOption( "Copy" )
		Menu:AddOption( "Paste" )
		local InsertM, MMOption = Menu:AddSubMenu( "Insert" )
		InsertM:AddOption( "Union", function() AddUnionI(node) end )
		InsertM:AddOption( "Group", function() AddGroupI(node) end )
		InsertM:AddOption( "Segment", function() AddSegmentI(node) end )
		InsertM:AddOption( "Matrix", function() AddMatrixI(node) end )
		InsertM:AddOption( "Text", function() AddTextI(node) end )
		Menu:AddSpacer()
		Menu:AddOption( "Remove" )
		Menu:Open()
		print("AAA")
		function Menu:OptionSelected(option, optionText)
			if optionText == "Rename" then
				
			elseif optionText == "Copy" then
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
			elseif optionText == "Remove" then
				RemoveI(node)
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
	
	panel:AddControl("Color", {
		Label = "#tool.wire_multisegmentlcd.bgcolor",
		Red = "wire_multisegmentlcd_bgred",
		Green = "wire_multisegmentlcd_bggreen",
		Blue = "wire_multisegmentlcd_bgblue",
		Alpha = "wire_multisegmentlcd_bgalpha",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	panel:AddControl("Color", {
		Label = "#tool.wire_multisegmentlcd.fgcolor",
		Red = "wire_multisegmentlcd_fgred",
		Green = "wire_multisegmentlcd_fggreen",
		Blue = "wire_multisegmentlcd_fgblue",
		Alpha = "wire_multisegmentlcd_fgalpha",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end
