include("shared.lua")

function ENT:Initialize()
  self.Memory1 = {}
  self.Memory2 = {}
  for i = 0, 1023 do
    self.Memory1[i] = 0
  end
  
  -- Screen control:
  -- [1003] - Background red
  -- [1004] - Background green
  -- [1005] - Background blue
  -- [1006] - Text red
  -- [1007] - Text green
  -- [1008] - Text blue
  -- [1009] - Width 
  -- [1010] - Height

  -- Character control:
  -- [1011] - Write char at cursor (Writing puts character and shifts)
  --
  -- Caching control:
  -- [1012] - Force cache refresh
  -- [1013] - Cached blocks size (up to 28, 0 if disabled)
  --
  --
  -- Shifting control:
  -- [1014] - Shift cursor 1:backwards 0:forwards
  -- [1015] - Shift screen with cursor
  --
  -- Character output control:
  -- [1016] - Contrast
  --
  -- Control registers:
  -- [1017] - Hardware Clear Row (Writing clears row)
  -- [1018] - Hardware Clear Screen
  --
  -- Cursor control:
  -- [1019] - Cursor Blink Rate (0.50)
  -- [1020] - Cursor Size (0.25)
  -- [1021] - Cursor Address
  -- [1022] - Cursor Enabled
  --
  -- [1023] - Clk
  self.Memory1[1003] = 148
  self.Memory1[1004] = 178
  self.Memory1[1005] = 15
  self.Memory1[1006] = 45
  self.Memory1[1007] = 91
  self.Memory1[1008] = 45
  self.Memory1[1012] = 0
  self.Memory1[1013] = 0
  self.Memory1[1014] = 0
  self.Memory1[1015] = 0
  self.Memory1[1016] = 1
  self.Memory1[1017] = 0
  self.Memory1[1018] = 0
  self.Memory1[1019] = 0.5
  self.Memory1[1020] = 0.25
  self.Memory1[1021] = 0
  self.Memory1[1022] = 1

  for i = 0, 1023 do
    self.Memory2[i] = self.Memory1[i]
  end

  self.LastClk = false

  self.PrevTime = CurTime()
  self.IntTimer = 0

  self.NeedRefresh = true
  self.Flash = false
  self.FrameNeedsFlash = false

  self.FramesSinceRedraw = 0
  self.NewClk = true

  self.GPU = WireGPU(self)
  self.ScreenWidth = 16
  self.ScreenHeight = 2

  -- Setup caching
  GPULib.ClientCacheCallback(self,function(Address,Value)
    self:WriteCell(Address,Value)
  end)

  WireLib.netRegister(self)
  
end

function ENT:OnRemove()
  self.GPU:Finalize()
  self.NeedRefresh = true
end

function ENT:ReadCell(Address,value)
  Address = math.floor(Address)
  if Address < 0 then return nil end
  if Address >= 1024 then return nil end

  return self.Memory2[Address]
end



function ENT:ShiftScreenRight()
  if self.NewClk then
    for y=0,self.ScreenHeight-1 do
      for x=self.ScreenWidth-1,1,-1 do
        self.Memory1[x+y*self.ScreenWidth] = self.Memory1[x+y*self.ScreenWidth-1]
      end
      self.Memory1[y*self.ScreenWidth] = 0
    end
  end
  for y=0,self.ScreenHeight-1 do
    for x=self.ScreenWidth-1,1,-1 do
      self.Memory2[x+y*self.ScreenWidth] = self.Memory2[x+y*self.ScreenWidth-1]
    end
    self.Memory2[y*self.ScreenWidth] = 0
  end
end

function ENT:ShiftScreenLeft()
  if self.NewClk then
    for y=0,self.ScreenHeight-1 do
      for x=0,self.ScreenWidth-2 do
      self.Memory1[x+y*self.ScreenWidth] = self.Memory1[x+y*self.ScreenWidth+1]
      end
    self.Memory1[y*self.ScreenWidth+self.ScreenWidth-1] = 0
    end
  end
  for y=0,self.ScreenHeight-1 do
    for x=0,self.ScreenWidth-2 do
    self.Memory2[x+y*self.ScreenWidth] = self.Memory2[x+y*self.ScreenWidth+1]
    end
  self.Memory2[y*self.ScreenWidth+self.ScreenWidth-1] = 0
  end
end

function ENT:WriteCell(Address,value)
  Address = math.floor(Address)
  if Address < 0 then return false end
  if Address >= 1024 then return false end

  if Address == 1023 then self.NewClk = value ~= 0 end
  if Address == 1009 and (value*self.Memory2[1010] > 1003 or value*18 > 1024) then return false end
  if Address == 1010 and (value*self.Memory2[1009] > 1003 or value*24 > 1024) then return false end
  if self.NewClk then
    self.Memory1[Address] = value -- Vis mem
    self.NeedRefresh = true
  end
  self.Memory2[Address] = value -- Invis mem

  if Address == 1011 then
    
    if self.Memory1[1015] >= 1 then
      if self.Memory1[1014] >= 1 then
        self:ShiftScreenRight()
      else
        self:ShiftScreenLeft()
      end
      self.Memory1[self.Memory1[1021]] = value
      self.Memory2[self.Memory1[1021]] = value
    else
      self.Memory1[self.Memory1[1021]] = value
      self.Memory2[self.Memory1[1021]] = value
      if self.Memory1[1014] >= 1 then
        self.Memory1[1021] = (self.Memory1[1021] - 1)%(self.ScreenHeight*self.ScreenWidth)
      else
        self.Memory1[1021] = (self.Memory1[1021] + 1)%(self.ScreenHeight*self.ScreenWidth)
      end
      self.Memory2[1021] = self.Memory1[1021]
    end
    
  end
  if Address == 1017 then
    for i = 0, self.ScreenWidth-1 do
      self.Memory1[value*self.ScreenWidth+i] = 0
      self.Memory2[value*self.ScreenWidth+i] = 0
    end
    self.NeedRefresh = true
  end
  if Address == 1018 then
    for i = 0, self.ScreenWidth*self.ScreenHeight-1 do
      self.Memory1[i] = 0
      self.Memory2[i] = 0
    end
    self.NeedRefresh = true
  end
  if Address == 1009 then
    self.ScreenWidth = value
  end
  if Address == 1010 then
    self.ScreenHeight = value
  end
  
  if self.LastClk ~= self.NewClk then
    self.LastClk = self.NewClk
    self.Memory1 = table.Copy(self.Memory2) -- swap the memory if clock changes
    self.NeedRefresh = true
  end
  return true
end

local specialCharacters = {
  [128] = {
    { x = 0, y = 1 },
    { x = 1, y = 1 },
    { x = 1, y = 0 },
  },
  [129] = {
    { x = 0, y = 1 },
    { x = 0, y = 0 },
    { x = 1, y = 1 },
  },
  [130] = {
    { x = 0, y = 1 },
    { x = 1, y = 0 },
    { x = 0, y = 0 },
  },
  [131] = {
    { x = 0, y = 0 },
    { x = 1, y = 0 },
    { x = 1, y = 1 },
  },
  [132] = {
    { x = 0, y = 0 },
    { x = 0.5, y = 0 },
    { x = 0.5, y = 0.5 },
    { x = 0, y = 0.5 },
  },
  [133] = {
    { x = 0.5, y = 0 },
    { x = 1, y = 0 },
    { x = 1, y = 0.5 },
    { x = 0.5, y = 0.5 },
  },
  [134] = {
    { x = 0, y = 0 },
    { x = 1, y = 0 },
    { x = 1, y = 0.5 },
    { x = 0, y = 0.5 },
  },
  [135] = {
    { x = 0, y = 0.5 },
    { x = 0.5, y = 0.5 },
    { x = 0.5, y = 1 },
    { x = 0, y = 1 },
  },
  
  
  
  
  
  [136] = {
    { x = 0, y = 0 },
    { x = 0.5, y = 0 },
    { x = 0.5, y = 1 },
    { x = 0, y = 1 },
  },
  [137] = {
    { x = 0.5, y = 0.5 },
    { x = 0.5, y = 0 },
    { x = 1, y = 0 },
    { x = 1, y = 0.5 },
    { x = 0.5, y = 0.5 },
    { x = 0.5, y = 1 },
    { x = 0, y = 1 },
    { x = 0, y = 0.5 },
  },
  [138] = {
    { x = 0, y = 0 },
    { x = 1, y = 0 },
    { x = 1, y = 0.5 },
    { x = 0.5, y = 0.5 },
    { x = 0.5, y = 1 },
    { x = 0, y = 1 },
  },
  [139] = {
    { x = 0.5, y = 0.5 },
    { x = 1, y = 0.5 },
    { x = 1, y = 1 },
    { x = 0.5, y = 1 },
  },
  [140] = {
    { x = 0.5, y = 0.5 },
    { x = 1, y = 0.5 },
    { x = 1, y = 1 },
    { x = 0.5, y = 1 },
    { x = 0.5, y = 0.5 },
    { x = 0, y = 0.5 },
    { x = 0, y = 0 },
    { x = 0.5, y = 0 },
  },
  [141] = {
    { x = 0.5, y = 0 },
    { x = 1, y = 0 },
    { x = 1, y = 1 },
    { x = 0.5, y = 1 },
  },
  [142] = {
    
    { x = 1, y = 0 },
    { x = 1, y = 1 },
    { x = 0.5, y = 1 },
    { x = 0.5, y = 0.5 },
    { x = 0, y = 0.5},
    { x = 0, y = 0 },
  },
  
  [143] = {
    { x = 0, y = 0.5 },
    { x = 1, y = 0.5 },
    { x = 1, y = 1 },
    { x = 0, y = 1 },
  },
  [144] = {
    { x = 0, y = 1 },
    { x = 0, y = 0 },
    { x = 0.5, y = 0 },
    { x = 0.5, y = 0.5 },
    { x = 1, y = 0.5 },
    { x = 1, y = 1 },
  },
  [145] = {
    { x = 1, y = 1 },
    { x = 0, y = 1 },
    { x = 0, y = 0.5 },
    { x = 0.5, y = 0.5 },
    { x = 0.5, y = 0 },
    { x = 1, y = 0 },
  },
  [146] = {
    { x = 0, y = 0 },
    { x = 1, y = 0 },
    { x = 1, y = 1 },
    { x = 0, y = 1 },
  },
  [147] = {
    { x = 0.33, y = 0.66 },
    { x = 0.33, y = 0 },
    { x = 0.66, y = 0 },
    { x = 0.66, y = 0.33 },
    { x = 1, y = 0.33 },
    { x = 1, y = 0.66 },
  },
  [148] = {
    { x = 0.33, y = 0},
    { x = 0.66, y = 0},
    { x = 0.66, y = 1},
    { x = 0.33, y = 1},
  },
  [149] = {
    { x = 0.66, y = 0.66 },
    { x = 0, y = 0.66 },
    { x = 0, y = 0.33 },
    { x = 0.33, y = 0.33 },
    { x = 0.33, y = 0 },
    { x = 0.66, y = 0 },
  },
  [150] = {
    { x = 0, y = 0.33},
    { x = 1, y = 0.33},
    { x = 1, y = 0.66},
    { x = 0, y = 0.66},
  },
  [151] = {
    { x = 0.66, y = 0.33 },
    { x = 1, y = 0.33 },
    { x = 1, y = 0.66 },
    { x = 0, y = 0.66 },
    { x = 0, y = 0.33 },
    { x = 0.33, y = 0.33 },
    { x = 0.33, y = 0 },
    { x = 0.66, y = 0 },
  },
  [152] = {
    { x = 0.66, y = 0.33 },
    { x = 1, y = 0.33 },
    { x = 1, y = 0.66 },
    { x = 0.66, y = 0.66 },
    { x = 0.66, y = 1 },
    { x = 0.33, y = 1 },
    { x = 0.33, y = 0 },
    { x = 0.66, y = 0 },
  },
  [153] = {
    { x = 0.66, y = 0.66 },
    { x = 1, y = 0.66 },
    { x = 1, y = 0.33 },
    { x = 0, y = 0.33 },
    { x = 0, y = 0.66 },
    { x = 0.33, y = 0.66 },
    { x = 0.33, y = 1 },
    { x = 0.66, y = 1 },
  },
  [154] = {
    { x = 0.33, y = 0.33 },
    { x = 0, y = 0.33 },
    { x = 0, y = 0.66 },
    { x = 0.33, y = 0.66 },
    { x = 0.33, y = 1 },
    { x = 0.66, y = 1 },
    { x = 0.66, y = 0 },
    { x = 0.33, y = 0 },
  },
  [155] = {
    { x = 0.66, y = 0.33 },
    { x = 1, y = 0.33 },
    { x = 1, y = 0.66 },
    { x = 0.66, y = 0.66 },
    { x = 0.66, y = 1 },
    { x = 0.33, y = 1 },
    { x = 0.33, y = 0.66 },
    { x = 0, y = 0.66 },
    { x = 0, y = 0.33 },
    { x = 0.33, y = 0.33 },
    { x = 0.33, y = 0 },
    { x = 0.66, y = 0 },
  },
  [156] = {
    { x = 0.33, y = 0 },
    { x = 0.66, y = 0 },
    { x = 0.66, y = 0.33 },
    { x = 0.33, y = 0.33 },
  },
  [157] = {
    { x = 0.66, y = 0.33 },
    { x = 1, y = 0.33 },
    { x = 1, y = 0.66 },
    { x = 0.66, y = 0.66 },
  },
  [158] = {
    { x = 0.33, y = 0.66 },
    { x = 0.66, y = 0.66 },
    { x = 0.66, y = 1 },
    { x = 0.33, y = 1 },
  },
  [159] = {
    { x = 0, y = 0.33 },
    { x = 0.33, y = 0.33 },
    { x = 0.33, y = 0.66 },
    { x = 0, y = 0.66 },
  },
  [160] = {
    { x = 0.33, y = 0.33 },
    { x = 0.66, y = 0.33 },
    { x = 0.66, y = 0.66 },
    { x = 0.33, y = 0.66 },
  }
}

function ENT:DrawSpecialCharacter(c,x,y,w,h,r,g,b)
  surface.SetDrawColor(r,g,b,255)
  surface.SetTexture(0)

  local vertices = table.Copy(specialCharacters[c])
  if vertices then
    --[[local vertexData = {
      { x = vertices[1].x*w+x, y = vertices[1].y*h+y },
      { x = vertices[2].x*w+x, y = vertices[2].y*h+y },
      { x = vertices[3].x*w+x, y = vertices[3].y*h+y },
    }]]
    for i=1,#vertices do
      vertices[i].x = vertices[i].x*w+x
      vertices[i].y = vertices[i].y*h+y
    end
    surface.DrawPoly(vertices)
  end
end

function ENT:Draw()
  self:DrawModel()

  local curtime = CurTime()
  local DeltaTime = curtime - self.PrevTime
  self.PrevTime = curtime
  self.IntTimer = self.IntTimer + DeltaTime
  self.FramesSinceRedraw = self.FramesSinceRedraw + 1
  local szx = 18
  local szy = 24
  if self.NeedRefresh == true then
    self.FramesSinceRedraw = 0
    self.NeedRefresh = false
    self.FrameNeedsFlash = false

    if self.Memory1[1022] >= 1 then self.FrameNeedsFlash = true end
 
    self.GPU:RenderToGPU(function()
      -- Draw terminal here
      -- W/H = 16
      

      local bc = math.min(1,math.max(0,self.Memory2[1016]-1.8))
      local br = (1-bc)*self.Memory2[1003]+bc*self.Memory2[1006]
      local bg = (1-bc)*self.Memory2[1004]+bc*self.Memory2[1007]
      local bb = (1-bc)*self.Memory2[1005]+bc*self.Memory2[1008]
      
      local sqc = math.min(1,math.max(0,self.Memory2[1016]-0.9))
      local sqr = (1-sqc)*self.Memory2[1003]+sqc*self.Memory2[1006]
      local sqg = (1-sqc)*self.Memory2[1004]+sqc*self.Memory2[1007]
      local sqb = (1-sqc)*self.Memory2[1005]+sqc*self.Memory2[1008]
      
      local fc = math.min(1,math.max(sqc,self.Memory2[1016]))
      local fr = (1-fc)*self.Memory2[1003]+fc*self.Memory2[1006]
      local fg = (1-fc)*self.Memory2[1004]+fc*self.Memory2[1007]
      local fb = (1-fc)*self.Memory2[1005]+fc*self.Memory2[1008]
      surface.SetDrawColor(br,bg,bb,255)
      surface.DrawRect(0,0,1024,1024)

      for ty = 0, self.ScreenHeight-1 do
        for tx = 0, self.ScreenWidth-1 do
          local a = tx + ty*self.ScreenWidth

          --if (self.Flash == true) then
          --  fb,bb = bb,fb
          --  fg,bg = bg,fg
          --  fr,br = br,fr
          --end
          local c1 = self.Memory1[a]

          if c1 >= 2097152 then c1 = 0 end
          if c1 < 0 then c1 = 0 end
       
          surface.SetDrawColor(sqr,sqg,sqb,255)
          surface.DrawRect((tx)*szx+1,(ty)*szy+1,szx-2,szy-2)
          surface.SetDrawColor(sqr,sqg,sqb,127)
          surface.DrawRect((tx)*szx+2,(ty)*szy+2,szx-2,szy-2)
          
          if (c1 ~= 0) then
            -- Note: the source engine does not handle unicode characters above 65535 properly.
            local utf8 = ""
            if c1 <= 127 then
              utf8 = string.char (c1)
            elseif c1 < 2048 then
              utf8 = string.format("%c%c", 192 + math.floor (c1 / 64), 128 + (c1 % 64))
            elseif c1 < 65536 then
              utf8 = string.format("%c%c%c", 224 + math.floor (c1 / 4096), 128 + (math.floor (c1 / 64) % 64), 128 + (c1 % 64))
            elseif c1 < 2097152 then
              utf8 = string.format("%c%c%c%c", 240 + math.floor (c1 / 262144), 128 + (math.floor (c1 / 4096) % 64), 128 + (math.floor (c1 / 64) % 64), 128 + (c1 % 64))
            end

            if specialCharacters[c1] then
              self:DrawSpecialCharacter(
                c1, (tx)*szx+1, (ty)*szy+1, szx-1, szy-1,
                fr,fg,fb
              )
            else
              draw.DrawText(
                utf8,
                "LCDFontBlur",
                tx * szx + 2, ty * szy,
                Color(fr,fg,fb,255),0
              )
              draw.DrawText(
                utf8,
                "LCDFont",
                tx * szx + 1, ty * szy -1 ,
                Color(fr,fg,fb,255),0
              )
            end
          end
        end
      end


      if self.Memory1[1022] >= 1 then
        if self.Flash == true then
          local a = math.floor(self.Memory1[1021])

          local tx = a - math.floor(a / self.ScreenWidth)*self.ScreenWidth
          local ty = math.floor(a / self.ScreenWidth)


          surface.SetDrawColor(
            fr,
            fg,
            fb,
            255
          )
          surface.DrawRect(
            (tx)*szx+1,
            (ty)*szy+szy*(1-self.Memory1[1020]),
            szx-2,
            szy*self.Memory1[1020]
          )
        end
      end
     end)
  end

  if self.FrameNeedsFlash == true then
    if self.IntTimer < self.Memory1[1019] then
      if (self.Flash == false) then
        self.NeedRefresh = true
      end
      self.Flash = true
    end

    if self.IntTimer >= self.Memory1[1019] then
      if self.Flash == true then
        self.NeedRefresh = true
      end
      self.Flash = false
    end

    if self.IntTimer >= self.Memory1[1019]*2 then
      self.IntTimer = 0
    end
  end

  self.GPU:Render(0,0,1024,1024,nil,-(1024-self.ScreenWidth*szx)/1024,-(1024-self.ScreenHeight*szy)/1024)
  Wire_Render(self)
end

function ENT:IsTranslucent()
  return true
end
