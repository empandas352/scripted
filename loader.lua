-- ==================== ARTICALL HUB v2 | RESIDENCE MASSACRE (Night 1) ====================
-- Monochrome UI | Solara + Delta | sin librerías externas

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.ArticallUnload then pcall(env.ArticallUnload) end

-- ==================== CONFIG (ajusta nombres aquí si el juego usa otros) ====================
local CFG = {
   Coords = {
      FuseBox = Vector3.new(-1.73, 4.50, -91.37),
      PuertaPrincipal = Vector3.new(-11.56, 7.80, -35.79),
      ZonaSegura = Vector3.new(-15.22, 23.80, -54.14),
   },
   PromptPatterns = {
      Fireplace = { "fireplace", "chimney", "furnace" },
      Wood = { "wood", "log", "barricade" },
      Doors = { "door" },
   },
   ItemNames = { "Wood", "Battery", "Fuse", "Key", "Tablet", "Flashlight", "JerryCan" },
   StamNames = { "Overdrive", "Stam", "Stamina" },   -- Character.Sprint.Overdrive
   OxygenNames = { "Breath", "Oxygen", "O2" },       -- Character.Breath
   ExtraTPs = { -- coords de scripts de 2023, verifícalas
      { "Dormitorio", Vector3.new(-26.48, 25.30, -70.11) },
      { "Baño", Vector3.new(-30.76, 25.27, -52.87) },
      { "Escalera", Vector3.new(-0.17, 9.30, -81.32) },
      { "Sala", Vector3.new(-30.46, 9.54, -48.74) },
      { "Consola de energía", Vector3.new(-2.42, 6.20, -92.56) },
      { "Safe 1", Vector3.new(-79.71, 21.27, -124.94) },
      { "Safe 2", Vector3.new(-15.41, 25.29, -53.18) },
   },
}

-- ==================== UTILIDADES ====================
local Maid = { items = {} }
function Maid:Add(x) table.insert(self.items, x) return x end
function Maid:Clean()
   for _, x in ipairs(self.items) do
      pcall(function()
         local t = typeof(x)
         if t == "RBXScriptConnection" then x:Disconnect()
         elseif t == "Instance" then x:Destroy()
         elseif t == "function" then x()
         elseif t == "thread" then task.cancel(x) end
      end)
   end
   self.items = {}
end

local unloaded = false
local S = { walk = 12, sprint = 17, fov = 70 } -- estado general

local function tween(obj, props, t)
   TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function safeSetClipboard(text)
   pcall(function()
      if setclipboard then setclipboard(text) elseif toclipboard then toclipboard(text) end
   end)
end

local function getRoot()
   local c = LocalPlayer.Character
   return c and c:FindFirstChild("HumanoidRootPart")
end

local function getGuiParent()
   local ok, h = pcall(function() return gethui and gethui() end)
   if ok and h then return h end
   return CoreGui
end

-- ==================== GUI BASE ====================
for _, parent in ipairs({ CoreGui, getGuiParent() }) do
   pcall(function()
      local old = parent:FindFirstChild("ArticallCustomHub")
      if old then old:Destroy() end
   end)
end

local C = {
   white = Color3.fromRGB(255, 255, 255),
   panel = Color3.fromRGB(245, 245, 245),
   hover = Color3.fromRGB(240, 240, 240),
   down = Color3.fromRGB(224, 224, 224),
   line = Color3.fromRGB(210, 210, 210),
   mid = Color3.fromRGB(200, 200, 200),
   dim = Color3.fromRGB(100, 100, 100),
   dark = Color3.fromRGB(20, 20, 20),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ArticallCustomHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = getGuiParent()
Maid:Add(ScreenGui)

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP"
ESPFolder.Parent = ScreenGui

-- Notificaciones
local NotifHolder = Instance.new("Frame")
NotifHolder.BackgroundTransparency = 1
NotifHolder.Position = UDim2.new(1, -270, 0, 10)
NotifHolder.Size = UDim2.new(0, 260, 1, -20)
NotifHolder.Parent = ScreenGui
local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 6)
notifLayout.Parent = NotifHolder

local function notify(text, dur)
   if unloaded then return end
   local f = Instance.new("Frame")
   f.BackgroundColor3 = C.dark
   f.BackgroundTransparency = 1
   f.Size = UDim2.new(1, 0, 0, 36)
   f.Parent = NotifHolder
   local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 8); fc.Parent = f
   local l = Instance.new("TextLabel")
   l.BackgroundTransparency = 1
   l.Position = UDim2.new(0, 12, 0, 0)
   l.Size = UDim2.new(1, -24, 1, 0)
   l.Font = Enum.Font.GothamSemibold
   l.Text = text
   l.TextColor3 = C.white
   l.TextTransparency = 1
   l.TextSize = 12
   l.TextWrapped = true
   l.TextXAlignment = Enum.TextXAlignment.Left
   l.Parent = f
   tween(f, { BackgroundTransparency = 0.05 }, 0.2)
   tween(l, { TextTransparency = 0 }, 0.2)
   task.delay(dur or 3, function()
      if f.Parent then
         tween(f, { BackgroundTransparency = 1 }, 0.25)
         tween(l, { TextTransparency = 1 }, 0.25)
         task.wait(0.3)
         f:Destroy()
      end
   end)
end

-- Arrastre propio (mouse + táctil)
local function makeDraggable(frame, handle, onClick, getScale)
   local dragging, startMouse, startPos, moved = false, nil, nil, 0
   handle.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
         dragging, moved = true, 0
         startMouse, startPos = input.Position, frame.Position
         input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
               dragging = false
               if onClick and moved < 6 then onClick() end
            end
         end)
      end
   end)
   Maid:Add(UserInputService.InputChanged:Connect(function(input)
      if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
         local d = input.Position - startMouse
         moved = math.max(moved, d.Magnitude)
         local s = getScale and getScale() or 1
         frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / s, startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
      end
   end))
end

local function hoverFx(btn, base, over, down)
   btn.AutoButtonColor = false
   btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = over }) end)
   btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = base }) end)
   btn.MouseButton1Down:Connect(function() tween(btn, { BackgroundColor3 = down }, 0.06) end)
   btn.MouseButton1Up:Connect(function() tween(btn, { BackgroundColor3 = over }) end)
end

-- Tap seguro: ignora el toque si el dedo/mouse se movió (scroll o arrastre accidental)
local function onTap(btn, fn)
   btn.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
         local start = input.Position
         local conn
         conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
               conn:Disconnect()
               if (input.Position - start).Magnitude < 10 then fn() end
            end
         end)
      end
   end)
end

-- Botón flotante
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.BackgroundColor3 = C.white
ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
ToggleBtn.Size = UDim2.new(0, 130, 0, 40)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "Articall Hub"
ToggleBtn.TextColor3 = C.dark
ToggleBtn.TextSize = 13
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ScreenGui
do
   local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = ToggleBtn
   local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180, 180, 180); s.Thickness = 1.5; s.Parent = ToggleBtn
end

-- Ventana principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = C.white
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 700, 0, 450)
MainFrame.Active = true
MainFrame.Parent = ScreenGui
do
   local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = MainFrame
   local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(40, 40, 40); s.Thickness = 2; s.Parent = MainFrame
end

local UIScaleObj = Instance.new("UIScale")
UIScaleObj.Parent = MainFrame
local function updateScale()
   local cam = Workspace.CurrentCamera
   local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
   UIScaleObj.Scale = math.clamp(math.min(vp.X / 760, vp.Y / 500), 0.5, 1)
end
updateScale()
pcall(function()
   Maid:Add(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
end)

local TopBar = Instance.new("Frame")
TopBar.BackgroundColor3 = C.panel
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
do
   local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = TopBar
   local fix = Instance.new("Frame")
   fix.BackgroundColor3 = C.panel
   fix.Position = UDim2.new(0, 0, 0.5, 0)
   fix.Size = UDim2.new(1, 0, 0.5, 0)
   fix.BorderSizePixel = 0
   fix.Parent = TopBar
end

local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 18, 0, 0)
TitleLabel.Size = UDim2.new(0, 400, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Articall Hub v2.2  |  Residence Massacre"
TitleLabel.TextColor3 = C.dark
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local TopSeparator = Instance.new("Frame")
TopSeparator.BackgroundColor3 = C.mid
TopSeparator.Position = UDim2.new(0, 0, 0, 48)
TopSeparator.Size = UDim2.new(1, 0, 0, 1)
TopSeparator.BorderSizePixel = 0
TopSeparator.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
CloseBtn.Position = UDim2.new(1, -40, 0, 11)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = C.dark
CloseBtn.TextSize = 16
CloseBtn.Parent = TopBar
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = CloseBtn end
hoverFx(CloseBtn, Color3.fromRGB(235, 235, 235), Color3.fromRGB(220, 220, 220), Color3.fromRGB(200, 200, 200))

local function toggleMenu() MainFrame.Visible = not MainFrame.Visible end
do
   local armed = false
   onTap(CloseBtn, function()
      if not armed then
         armed = true
         CloseBtn.Text = "?"
         task.delay(2, function()
            if armed then armed = false; CloseBtn.Text = "×" end
         end)
         return
      end
      armed = false
      CloseBtn.Text = "×"
      MainFrame.Visible = false
   end)
end
makeDraggable(MainFrame, TopBar, nil, function() return UIScaleObj.Scale end)
makeDraggable(ToggleBtn, ToggleBtn, toggleMenu, nil)

Maid:Add(UserInputService.InputBegan:Connect(function(input, gp)
   if not gp and input.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end))

-- Pestañas
local TabBar = Instance.new("ScrollingFrame")
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.Position = UDim2.new(0, 15, 0, 62)
TabBar.Size = UDim2.new(0, 160, 0, 372)
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabBar.ScrollBarThickness = 2
TabBar.Parent = MainFrame
do
   local l = Instance.new("UIListLayout"); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 6); l.Parent = TabBar
end

local VSep = Instance.new("Frame")
VSep.BackgroundColor3 = C.mid
VSep.Position = UDim2.new(0, 185, 0, 62)
VSep.Size = UDim2.new(0, 1, 0, 372)
VSep.BorderSizePixel = 0
VSep.Parent = MainFrame

local PagesContainer = Instance.new("Frame")
PagesContainer.BackgroundTransparency = 1
PagesContainer.Position = UDim2.new(0, 200, 0, 62)
PagesContainer.Size = UDim2.new(0, 485, 0, 372)
PagesContainer.Active = true
PagesContainer.Parent = MainFrame

local tabs, pages = {}, {}

local function selectTab(idx)
   for i, p in ipairs(pages) do p.Visible = (i == idx) end
   for i, t in ipairs(tabs) do
      t.BackgroundColor3 = (i == idx) and C.dark or C.hover
      t.TextColor3 = (i == idx) and C.white or Color3.fromRGB(80, 80, 80)
   end
end

local function createTab(name)
   local idx = #tabs + 1
   local tabBtn = Instance.new("TextButton")
   tabBtn.BackgroundColor3 = C.hover
   tabBtn.Size = UDim2.new(1, -4, 0, 40)
   tabBtn.Font = Enum.Font.GothamSemibold
   tabBtn.Text = "  " .. name
   tabBtn.TextColor3 = Color3.fromRGB(80, 80, 80)
   tabBtn.TextSize = 13
   tabBtn.TextXAlignment = Enum.TextXAlignment.Left
   tabBtn.AutoButtonColor = false
   tabBtn.Parent = TabBar
   local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = tabBtn

   local page = Instance.new("ScrollingFrame")
   page.BackgroundTransparency = 1
   page.BorderSizePixel = 0
   page.Size = UDim2.new(1, 0, 1, 0)
   page.CanvasSize = UDim2.new(0, 0, 0, 0)
   page.AutomaticCanvasSize = Enum.AutomaticSize.Y
   page.ScrollBarThickness = 4
   page.Visible = false
   page.Parent = PagesContainer
   local layout = Instance.new("UIListLayout"); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 8); layout.Parent = page
   local pad = Instance.new("UIPadding"); pad.PaddingBottom = UDim.new(0, 10); pad.PaddingTop = UDim.new(0, 2); pad.Parent = page

   onTap(tabBtn, function() selectTab(idx) end)
   table.insert(tabs, tabBtn)
   table.insert(pages, page)
   return page
end

local DashboardPage = createTab("Dashboard")
local AutoPage = createTab("Auto")
local ESPPage = createTab("ESPs")
local TPsPage = createTab("TPs")
local PlayerPage = createTab("Jugador")
local MiscPage = createTab("Misc")
selectTab(1)

-- Componentes
local function addSection(page, titleText)
   local container = Instance.new("Frame")
   container.BackgroundTransparency = 1
   container.Size = UDim2.new(1, -10, 0, 32)
   container.Parent = page
   local sec = Instance.new("TextLabel")
   sec.BackgroundTransparency = 1
   sec.Position = UDim2.new(0, 4, 0, 6)
   sec.Size = UDim2.new(0, 300, 0, 20)
   sec.Font = Enum.Font.GothamBold
   sec.Text = titleText:upper()
   sec.TextColor3 = C.dim
   sec.TextSize = 11
   sec.TextXAlignment = Enum.TextXAlignment.Left
   sec.Parent = container
   local line = Instance.new("Frame")
   line.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
   line.Position = UDim2.new(0, 4, 1, -2)
   line.Size = UDim2.new(1, -8, 0, 1)
   line.BorderSizePixel = 0
   line.Parent = container
end

local function baseRow(page, name)
   local btn = Instance.new("TextButton")
   btn.BackgroundColor3 = C.white
   btn.Size = UDim2.new(1, -10, 0, 42)
   btn.Font = Enum.Font.GothamSemibold
   btn.Text = "  " .. name
   btn.TextColor3 = Color3.fromRGB(30, 30, 30)
   btn.TextSize = 13
   btn.TextXAlignment = Enum.TextXAlignment.Left
   btn.Parent = page
   local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn
   local s = Instance.new("UIStroke"); s.Color = C.line; s.Thickness = 1.2; s.Parent = btn
   hoverFx(btn, C.white, C.hover, C.down)
   return btn
end

local function addButton(page, name, a, b)
   local callback, confirm = a, b
   if type(a) == "boolean" then confirm, callback = a, b end
   local btn = baseRow(page, name)
   local armed = false
   onTap(btn, function()
      if confirm and not armed then
         armed = true
         btn.Text = "  ¿Seguro? Toca de nuevo para confirmar"
         task.delay(2.5, function()
            if armed then armed = false; btn.Text = "  " .. name end
         end)
         return
      end
      armed = false
      btn.Text = "  " .. name
      local ok, err = pcall(callback)
      if not ok then notify("Error: " .. tostring(err), 4) end
   end)
end

local allToggles = {}
local function addToggle(page, name, callback)
   local state = false
   local btn = baseRow(page, name)

   local indicator = Instance.new("Frame")
   indicator.BackgroundColor3 = C.mid
   indicator.Position = UDim2.new(1, -48, 0.5, -10)
   indicator.Size = UDim2.new(0, 38, 0, 20)
   indicator.Parent = btn
   local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(1, 0); ic.Parent = indicator

   local circle = Instance.new("Frame")
   circle.BackgroundColor3 = C.white
   circle.Position = UDim2.new(0, 2, 0.5, -8)
   circle.Size = UDim2.new(0, 16, 0, 16)
   circle.Parent = indicator
   local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = circle

   local obj = {}
   function obj.Set(v, silent)
      state = v
      tween(indicator, { BackgroundColor3 = v and C.dark or C.mid })
      circle:TweenPosition(v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
      if not silent then
         local ok, err = pcall(callback, v)
         if not ok then notify("Error: " .. tostring(err), 4) end
      end
   end
   function obj.Get() return state end
   onTap(btn, function() obj.Set(not state) end)
   table.insert(allToggles, obj)
   return obj
end

local function addSlider(page, name, min, max, default, callback)
   local frame = Instance.new("Frame")
   frame.BackgroundColor3 = C.white
   frame.Size = UDim2.new(1, -10, 0, 54)
   frame.Parent = page
   local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = frame
   local s = Instance.new("UIStroke"); s.Color = C.line; s.Thickness = 1.2; s.Parent = frame

   local label = Instance.new("TextLabel")
   label.BackgroundTransparency = 1
   label.Position = UDim2.new(0, 12, 0, 6)
   label.Size = UDim2.new(0.6, 0, 0, 18)
   label.Font = Enum.Font.GothamSemibold
   label.Text = name
   label.TextColor3 = Color3.fromRGB(30, 30, 30)
   label.TextSize = 13
   label.TextXAlignment = Enum.TextXAlignment.Left
   label.Parent = frame

   local valueLabel = Instance.new("TextLabel")
   valueLabel.BackgroundTransparency = 1
   valueLabel.Position = UDim2.new(1, -72, 0, 6)
   valueLabel.Size = UDim2.new(0, 60, 0, 18)
   valueLabel.Font = Enum.Font.GothamBold
   valueLabel.TextColor3 = C.dim
   valueLabel.TextSize = 12
   valueLabel.TextXAlignment = Enum.TextXAlignment.Right
   valueLabel.Parent = frame

   local track = Instance.new("Frame")
   track.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
   track.Position = UDim2.new(0, 12, 0, 36)
   track.Size = UDim2.new(1, -24, 0, 6)
   track.BorderSizePixel = 0
   track.Parent = frame
   local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = track

   local fill = Instance.new("Frame")
   fill.BackgroundColor3 = C.dark
   fill.BorderSizePixel = 0
   fill.Parent = track
   local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

   local hit = Instance.new("TextButton")
   hit.BackgroundTransparency = 1
   hit.Text = ""
   hit.Position = UDim2.new(0, 0, 0, 28)
   hit.Size = UDim2.new(1, 0, 0, 26)
   hit.Parent = frame

   local function setValue(v)
      v = math.clamp(math.floor(v + 0.5), min, max)
      fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
      valueLabel.Text = tostring(v)
      pcall(callback, v)
   end
   setValue(default)

   local dragging = false
   local function fromInput(input)
      local rel = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
      setValue(min + math.clamp(rel, 0, 1) * (max - min))
   end
   hit.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
         dragging = true
         fromInput(input)
      end
   end)
   Maid:Add(UserInputService.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
   end))
   Maid:Add(UserInputService.InputChanged:Connect(function(input)
      if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
         fromInput(input)
      end
   end))
end

-- ==================== PROMPTS / INTERACCIÓN ====================
local prompts = {}      -- [ProximityPrompt] = true
local detectors = {}    -- [ClickDetector] = true
local holdOrig = {}     -- [ProximityPrompt] = HoldDuration original
local cooldown = {}     -- [ProximityPrompt] = os.clock()

local function ancestorMatches(inst, patterns)
   local p, depth = inst, 0
   while p and p ~= Workspace and depth < 7 do
      local n = p.Name:lower()
      for _, pat in ipairs(patterns) do
         if n:find(pat, 1, true) then return true end
      end
      p = p.Parent
      depth += 1
   end
   return false
end

local function posOf(inst)
   local cur = inst
   for _ = 1, 6 do
      if not cur or cur == Workspace then break end
      if cur:IsA("BasePart") then return cur.Position end
      if cur:IsA("Attachment") then return cur.WorldPosition end
      if cur:IsA("Model") then return cur:GetPivot().Position end
      cur = cur.Parent
   end
   return nil
end
local promptPosition = posOf

local function firePrompt(prompt)
   local f = fireproximityprompt or fireprompt
   if not f then return false end
   local d, los = prompt.MaxActivationDistance, prompt.RequiresLineOfSight
   pcall(function()
      prompt.MaxActivationDistance = 10000
      prompt.RequiresLineOfSight = false
      f(prompt)
   end)
   pcall(function()
      prompt.MaxActivationDistance = d
      prompt.RequiresLineOfSight = los
   end)
   return true
end

local function setInstant(v)
   S.instant = v
   for p in pairs(prompts) do
      pcall(function()
         if v then
            if holdOrig[p] == nil then holdOrig[p] = p.HoldDuration end
            p.HoldDuration = 0
         elseif holdOrig[p] ~= nil then
            p.HoldDuration = holdOrig[p]
            holdOrig[p] = nil
         end
      end)
   end
end

local function safeFireClick(detector)
   pcall(function()
      if fireclickdetector then fireclickdetector(detector) elseif clickdetector then clickdetector(detector) end
   end)
end

-- ==================== INTERACCIÓN (ClickDetector + Prompt, con TP) ====================
local function getDetector(inst)
   if not inst then return nil end
   if inst:IsA("ClickDetector") or inst:IsA("ProximityPrompt") then return inst end
   return inst:FindFirstChildWhichIsA("ClickDetector", true) or inst:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function fireAny(d)
   if not d then return false end
   if d:IsA("ClickDetector") then
      safeFireClick(d)
      return true
   end
   if d:IsA("ProximityPrompt") then return firePrompt(d) end
   return false
end

local busy = false
local function runTask(name, fn)
   if busy then notify("Espera, hay otra acción en curso", 2) return end
   busy = true
   task.spawn(function()
      local ok, err = pcall(fn)
      busy = false
      if not ok then notify("Error " .. name .. ": " .. tostring(err), 4) end
   end)
end

local function tpNear(pos)
   local root = getRoot()
   if not root then return nil end
   local back = root.CFrame
   root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
   root.AssemblyLinearVelocity = Vector3.zero
   return back
end

-- TP al objetivo, activar, volver
local function tpInteract(inst)
   local d = getDetector(inst)
   local pos = d and posOf(d)
   if not pos or not getRoot() then return false end
   local back = tpNear(pos)
   task.wait(0.25)
   fireAny(d)
   task.wait(0.2)
   local r = getRoot()
   if r and back then r.CFrame = back end
   return true
end

local function findByPatterns(patterns)
   local root = getRoot()
   local list = {}
   local function consider(d)
      local pos = posOf(d)
      local dist = (pos and root) and (pos - root.Position).Magnitude or math.huge
      table.insert(list, { d = d, dist = dist })
   end
   for d in pairs(detectors) do
      if d.Parent and ancestorMatches(d, patterns) then consider(d) end
   end
   for d in pairs(prompts) do
      if d.Parent and d.Enabled and ancestorMatches(d, patterns) then consider(d) end
   end
   table.sort(list, function(a, b) return a.dist < b.dist end)
   return list
end

local function interactPatternsTP(label, patterns, maxCount)
   runTask(label, function()
      local list = findByPatterns(patterns)
      if #list == 0 then notify(label .. ": no encontré objetos (usa Debug)", 4) return end
      local r0 = getRoot()
      local back = r0 and r0.CFrame
      local n = 0
      for i = 1, math.min(maxCount or 1, #list) do
         local d = list[i].d
         local pos = posOf(d)
         if pos then
            tpNear(pos)
            task.wait(0.25)
            fireAny(d)
            task.wait(0.2)
            n += 1
         end
      end
      local r = getRoot()
      if r and back then r.CFrame = back end
      notify(label .. ": " .. n .. " activado(s)")
   end)
end

local function tpInteractNamed(label, getter)
   runTask(label, function()
      local inst = getter()
      if inst and tpInteract(inst) then
         notify(label .. " activado")
      else
         notify(label .. ": no encontrado (usa Debug)", 4)
      end
   end)
end

local function shackPart(name)
   local shack = Workspace:FindFirstChild("Shack")
   return shack and shack:FindFirstChild(name, true)
end

local function genFuel()
   local gen = shackPart("Generator")
   local f = gen and gen:FindFirstChild("Fuel", true)
   if f and f:IsA("ValueBase") and type(f.Value) == "number" then return f.Value end
   return nil
end

local function holdingJerry()
   local c = LocalPlayer.Character
   return c ~= nil and c:FindFirstChild("JerryCan") ~= nil
end

local function grabJerry()
   local t0 = os.clock()
   while not holdingJerry() do
      fireAny(getDetector(shackPart("JerryCan")))
      task.wait(0.1)
      if os.clock() - t0 > 2.5 then return false end
   end
   return true
end

local function useJerry()
   local t0 = os.clock()
   while holdingJerry() do
      fireAny(getDetector(shackPart("Generator")))
      task.wait(0.1)
      if os.clock() - t0 > 2.5 then return false end
   end
   return true
end

-- Secuencia SIN TP: JerryCan -> Generador, repetida hasta 100%
local function genSequence()
   if not (shackPart("JerryCan") or holdingJerry()) or not shackPart("Generator") then
      return false, "No encontré Shack/JerryCan/Generator (usa Debug)"
   end
   for _ = 1, 12 do
      local fuel = genFuel()
      if fuel and fuel >= 100 then return true, "Generador al 100%" end
      if not grabJerry() then return false, "No pude agarrar el JerryCan: acércate al generador" end
      task.wait(0.1)
      if not useJerry() then return false, "No pude usar el JerryCan: acércate al generador" end
      task.wait(0.15)
      if not fuel then return true, "Secuencia ejecutada" end
   end
   local f = genFuel()
   return (f ~= nil and f >= 100), (f and ("Generador: " .. math.floor(f) .. "%") or "Listo")
end

local function runFuel(silentOk)
   runTask("Generador", function()
      local ok, msg = genSequence()
      if ok then
         if not silentOk then notify(msg) end
      else
         notify(msg, 5)
         S.fuelRetry = os.clock() + 20
      end
   end)
end

-- Auto puertas: Workspace.Doors > Door (Main, Status.Open, Detector.ClickDetector)
local function autoDoorsStep(root)
   local now = os.clock()
   local range = S.doorRange or 8
   local folder = Workspace:FindFirstChild("Doors")
   if folder then
      for _, door in ipairs(folder:GetChildren()) do
         local main = door:FindFirstChild("Main") or door:FindFirstChildWhichIsA("BasePart", true)
         local cd = door:FindFirstChildWhichIsA("ClickDetector", true)
         if main and cd and (main.Position - root.Position).Magnitude <= range then
            local open = door:FindFirstChild("Open", true)
            local isOpen = open and open:IsA("BoolValue") and open.Value
            if not isOpen and (not cooldown[door] or now - cooldown[door] > 1.5) then
               cooldown[door] = now
               safeFireClick(cd)
            end
         end
      end
      return
   end
   for cd in pairs(detectors) do
      if cd.Parent and ancestorMatches(cd, CFG.PromptPatterns.Doors) and (not cooldown[cd] or now - cooldown[cd] > 2.5) then
         local pos = posOf(cd)
         if pos and (pos - root.Position).Magnitude <= range then
            local model = cd:FindFirstAncestorOfClass("Model")
            local open = model and model:FindFirstChild("Open", true)
            if not (open and open:IsA("BoolValue") and open.Value) then
               cooldown[cd] = now
               safeFireClick(cd)
            end
         end
      end
   end
end

-- ==================== ESP ====================
local function isOtherPlayerChar(o)
   return o:IsA("Model") and o ~= LocalPlayer.Character and Players:GetPlayerFromCharacter(o) ~= nil
end

local ESPDefs = {
   { key = "larry", label = "Larry", color = Color3.fromRGB(255, 70, 70),
     match = function(o) return o:IsA("Model") and (o.Name == "Larry" or o.Name == "Mutant") end },
   { key = "skeleton", label = "Skeleton", color = Color3.fromRGB(230, 230, 230),
     match = function(o) return o:IsA("Model") and (o.Name:find("Skeleton") or o.Name:find("Zombie")) ~= nil end },
   { key = "stalker", label = "Stalker", color = Color3.fromRGB(255, 160, 40),
     match = function(o) return o:IsA("Model") and o.Name:find("Stalker") ~= nil end },
   { key = "players", label = "Jugador", color = Color3.fromRGB(80, 200, 255), match = isOtherPlayerChar },
   { key = "generator", label = "Generador", color = Color3.fromRGB(255, 230, 60),
     match = function(o) return (o:IsA("Model") or o:IsA("BasePart")) and o.Name == "Generator" end },
   { key = "jerrycan", label = "JerryCan", color = Color3.fromRGB(255, 140, 0),
     match = function(o) return (o:IsA("Model") or o:IsA("BasePart") or o:IsA("Tool")) and o.Name == "JerryCan" end },
   { key = "fusebox", label = "FuseBox", color = Color3.fromRGB(255, 255, 120),
     match = function(o) return (o:IsA("Model") or o:IsA("BasePart")) and o.Name == "FuseBox" end },
   { key = "switches", label = "Interruptor", color = Color3.fromRGB(255, 255, 255),
     match = function(o)
        return (o:IsA("Model") or o:IsA("BasePart")) and o.Name == "Switch" and o:FindFirstAncestor("Lights") ~= nil
     end },
   { key = "items", label = "Item", color = Color3.fromRGB(120, 255, 120),
     match = function(o)
        local spots = Workspace:FindFirstChild("ItemSpots")
        if spots and (o:IsA("Tool") or o:IsA("Model")) and o.Parent and o.Parent.Parent == spots then return true end
        if o:IsA("Tool") then
           return not Players:GetPlayerFromCharacter(o.Parent) and o.Parent ~= LocalPlayer.Character
        end
        if o:IsA("Model") then return table.find(CFG.ItemNames, o.Name) ~= nil end
        return false
     end },
}

local ESP = {}
for _, d in ipairs(ESPDefs) do ESP[d.key] = { def = d, enabled = false, objs = {} } end

local function rootOf(o)
   if o:IsA("BasePart") then return o end
   if o:IsA("Model") and o.PrimaryPart then return o.PrimaryPart end
   return o:FindFirstChildWhichIsA("BasePart", true)
end

local function espRemove(g, o)
   local e = g.objs[o]
   if e then
      pcall(function() e.hl:Destroy() end)
      pcall(function() e.bb:Destroy() end)
      g.objs[o] = nil
   end
end

local function espAdd(g, o)
   if g.objs[o] or o:IsDescendantOf(ESPFolder) then return end
   local ok, res = pcall(g.def.match, o)
   if not ok or not res then return end
   local p = o.Parent
   while p and p ~= Workspace do
      if g.objs[p] then return end
      p = p.Parent
   end
   local root = rootOf(o)
   if not root then return end

   local hl = Instance.new("Highlight")
   hl.Adornee = o
   hl.FillColor = g.def.color
   hl.OutlineColor = Color3.fromRGB(255, 255, 255)
   hl.FillTransparency = 0.75
   hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
   hl.Parent = ESPFolder

   local bb = Instance.new("BillboardGui")
   bb.Adornee = root
   bb.AlwaysOnTop = true
   bb.Size = UDim2.new(0, 140, 0, 20)
   bb.StudsOffset = Vector3.new(0, 3, 0)
   bb.Parent = ESPFolder
   local tl = Instance.new("TextLabel")
   tl.BackgroundTransparency = 1
   tl.Size = UDim2.new(1, 0, 1, 0)
   tl.Font = Enum.Font.GothamBold
   tl.TextSize = 12
   tl.TextColor3 = g.def.color
   tl.TextStrokeTransparency = 0.4
   tl.Text = g.def.label
   tl.Parent = bb

   g.objs[o] = { hl = hl, bb = bb, tl = tl, root = root }
end

local function espScan(g)
   task.spawn(function()
      for i, d in ipairs(Workspace:GetDescendants()) do
         if not g.enabled or unloaded then return end
         espAdd(g, d)
         if i % 1500 == 0 then task.wait() end
      end
   end)
end

local function setESP(key, state)
   local g = ESP[key]
   g.enabled = state
   if state then
      espScan(g)
   else
      for o in pairs(g.objs) do espRemove(g, o) end
   end
end

local function updateESPLabels()
   local root = getRoot()
   for _, g in pairs(ESP) do
      if g.enabled then
         for o, e in pairs(g.objs) do
            if not o:IsDescendantOf(Workspace) then
               espRemove(g, o)
            else
               if not e.root.Parent then
                  e.root = rootOf(o) or e.root
                  e.bb.Adornee = e.root
               end
               local dist = root and math.floor((e.root.Position - root.Position).Magnitude) or 0
               e.tl.Text = string.format("%s [%dm]", g.def.label, dist)
            end
         end
      end
   end
end

-- Escaneo inicial de prompts
task.spawn(function()
   for i, d in ipairs(Workspace:GetDescendants()) do
      if unloaded then return end
      if d:IsA("ProximityPrompt") then prompts[d] = true
      elseif d:IsA("ClickDetector") then detectors[d] = true end
      if i % 2000 == 0 then task.wait() end
   end
end)

Maid:Add(Workspace.DescendantAdded:Connect(function(o)
   if o:IsA("ClickDetector") then detectors[o] = true return end
   if o:IsA("ProximityPrompt") then
      prompts[o] = true
      if S.instant then holdOrig[o] = o.HoldDuration; pcall(function() o.HoldDuration = 0 end) end
      return
   end
   if S.larryNotify and (o.Name == "Larry" or o.Name == "Mutant") and o:IsA("Model") then
      notify("[!] Larry apareció en el mapa", 5)
   end
   for _, g in pairs(ESP) do
      if g.enabled then espAdd(g, o) end
   end
end))

Maid:Add(Workspace.DescendantRemoving:Connect(function(o)
   prompts[o] = nil
   detectors[o] = nil
   holdOrig[o] = nil
   cooldown[o] = nil
   for _, g in pairs(ESP) do
      if g.objs[o] then espRemove(g, o) end
   end
end))

local function hookPlayer(p)
   Maid:Add(p.CharacterAdded:Connect(function(c)
      task.wait(1)
      if ESP.players.enabled and not unloaded then espAdd(ESP.players, c) end
   end))
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then hookPlayer(p) end end
Maid:Add(Players.PlayerAdded:Connect(hookPlayer))

-- ==================== FUNCIONES DE JUGADOR ====================
local valueCache, valueMiss = {}, {}
local function findValue(key, names)
   local c = valueCache[key]
   if c and c.Parent then return c end
   valueCache[key] = nil
   if valueMiss[key] and os.clock() - valueMiss[key] < 2 then return nil end
   valueMiss[key] = os.clock()
   local roots = { LocalPlayer.Character, Workspace:FindFirstChild(LocalPlayer.Name), LocalPlayer }
   for _, r in ipairs(roots) do
      if r then
         for _, n in ipairs(names) do
            local v = r:FindFirstChild(n, true)
            if v and v:IsA("ValueBase") then valueCache[key] = v; return v end
         end
      end
   end
   return nil
end

local noclipOn, noclipParts, noclipRefresh = false, {}, 0
local function rebuildNoclip()
   noclipParts = {}
   local c = LocalPlayer.Character
   if c then
      for _, p in ipairs(c:GetDescendants()) do
         if p:IsA("BasePart") then table.insert(noclipParts, p) end
      end
   end
   noclipRefresh = os.clock()
end

Maid:Add(RunService.Stepped:Connect(function()
   if noclipOn then
      if os.clock() - noclipRefresh > 1.5 then rebuildNoclip() end
      for _, p in ipairs(noclipParts) do
         if p.Parent and p.CanCollide then p.CanCollide = false end
      end
   end
end))

local function setNoclip(v)
   noclipOn = v
   if v then rebuildNoclip() end
end

local function updateCameraMode(mode)
   LocalPlayer.CameraMode = Enum.CameraMode.Classic
   if mode == "Primera Persona" then
      LocalPlayer.CameraMaxZoomDistance, LocalPlayer.CameraMinZoomDistance = 0.5, 0.5
   elseif mode == "Tercera Persona" then
      LocalPlayer.CameraMaxZoomDistance, LocalPlayer.CameraMinZoomDistance = 20, 10
   else
      LocalPlayer.CameraMaxZoomDistance, LocalPlayer.CameraMinZoomDistance = 400, 0.5
   end
end

-- Iluminación (guarda y restaura valores originales)
local lightOrig, atmosOrig = nil, {}
local FB_KEYS = { "Brightness", "ClockTime", "GlobalShadows", "OutdoorAmbient", "Ambient" }
local FOG_KEYS = { "FogEnd", "FogStart" }
local function saveLighting()
   if lightOrig then return end
   lightOrig = {}
   for _, k in ipairs(FB_KEYS) do lightOrig[k] = Lighting[k] end
   for _, k in ipairs(FOG_KEYS) do lightOrig[k] = Lighting[k] end
end
local function restoreKeys(keys)
   if not lightOrig then return end
   for _, k in ipairs(keys) do pcall(function() Lighting[k] = lightOrig[k] end) end
end
local function applyFullbright()
   Lighting.Brightness = 2
   Lighting.ClockTime = 14
   Lighting.GlobalShadows = false
   Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
   Lighting.Ambient = Color3.fromRGB(150, 150, 150)
end
local function applyNoFog()
   Lighting.FogEnd = 1e6
   Lighting.FogStart = 1e6
   for _, a in ipairs(Lighting:GetChildren()) do
      if a:IsA("Atmosphere") then
         if atmosOrig[a] == nil then atmosOrig[a] = a.Density end
         a.Density = 0
      end
   end
end
local function restoreAtmos()
   for a, d in pairs(atmosOrig) do pcall(function() a.Density = d end) end
   atmosOrig = {}
end

-- Quitar estática (mejor esfuerzo)
local staticList, staticOrig, staticScan = {}, {}, 0
local function refreshStatic()
   staticScan = os.clock()
   staticList = {}
   local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
   if not pg then return end
   for _, d in ipairs(pg:GetDescendants()) do
      if d ~= ScreenGui and not d:IsDescendantOf(ScreenGui) then
         local n = d.Name:lower()
         if (n:find("static") or n:find("noise")) and (d:IsA("GuiObject") or d:IsA("ScreenGui")) then
            table.insert(staticList, d)
         end
      end
   end
end
local function applyStatic()
   if os.clock() - staticScan > 3 then refreshStatic() end
   for _, d in ipairs(staticList) do
      pcall(function()
         if d:IsA("ScreenGui") then
            if staticOrig[d] == nil then staticOrig[d] = d.Enabled end
            d.Enabled = false
         else
            if staticOrig[d] == nil then staticOrig[d] = d.Visible end
            d.Visible = false
         end
      end)
   end
end
local function restoreStatic()
   for d, v in pairs(staticOrig) do
      pcall(function() if d:IsA("ScreenGui") then d.Enabled = v else d.Visible = v end end)
   end
   staticOrig = {}
end

-- Anti-AFK
pcall(function()
   local VU = game:GetService("VirtualUser")
   Maid:Add(LocalPlayer.Idled:Connect(function()
      VU:CaptureController()
      VU:ClickButton2(Vector2.new())
   end))
end)

-- ==================== NUEVAS FUNCIONES ====================
-- Mantener valores al máximo visto (stamina / oxígeno)
local maxSeen = setmetatable({}, { __mode = "k" })
local KNOWN_CAP = { Stam = 5, Overdrive = 9999, Breath = 20 }
local function holdMax(v)
   if not (v:IsA("NumberValue") or v:IsA("IntValue")) then return end
   local m = math.max(KNOWN_CAP[v.Name] or 0, maxSeen[v] or v.Value, v.Value)
   maxSeen[v] = m
   if v.Value < m then v.Value = m end
end

-- Linterna: batería y cargas ilimitadas (personaje y mochila)
local function applyFlashlight()
   local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }
   for _, c in ipairs(containers) do
      local f = c and c:FindFirstChild("Flashlight")
      if f then
         for _, d in ipairs(f:GetDescendants()) do
            if d:IsA("NumberValue") or d:IsA("IntValue") then
               local n = d.Name:lower()
               if (n:find("batter") or n:find("charge")) and d.Value < 999999 then d.Value = 999999 end
            end
         end
         for name, val in pairs(f:GetAttributes()) do
            local n = name:lower()
            if type(val) == "number" and (n:find("batter") or n:find("charge")) and val < 999999 then
               f:SetAttribute(name, 999999)
            end
         end
      end
   end
end

-- Anti-congelación (heurístico: busca valores con nombres de temperatura/frío)
local tempList, tempScan = {}, 0
local function classifyTemp(name)
   local n = name:lower()
   for _, pat in ipairs({ "cold", "freez", "chill", "frost" }) do
      if n:find(pat, 1, true) then return "bad" end
   end
   for _, pat in ipairs({ "temp", "warm", "heat" }) do
      if n:find(pat, 1, true) then return "good" end
   end
   return nil
end
local function scanTemp()
   tempScan = os.clock()
   tempList = {}
   for _, root in ipairs({ LocalPlayer.Character, LocalPlayer }) do
      if root then
         for _, d in ipairs(root:GetDescendants()) do
            if (d:IsA("NumberValue") or d:IsA("IntValue")) and not d:IsDescendantOf(ScreenGui) then
               local k = classifyTemp(d.Name)
               if k then table.insert(tempList, { inst = d, kind = k }) end
            end
         end
         for name, val in pairs(root:GetAttributes()) do
            if type(val) == "number" then
               local k = classifyTemp(name)
               if k then table.insert(tempList, { inst = root, attr = name, kind = k }) end
            end
         end
      end
   end
end
local function applyTemp()
   if os.clock() - tempScan > 4 then scanTemp() end
   for _, e in ipairs(tempList) do
      pcall(function()
         local cur
         if e.attr then cur = e.inst:GetAttribute(e.attr) else cur = e.inst.Value end
         if type(cur) ~= "number" then return end
         if e.kind == "bad" then
            e.ref = math.min(e.ref or cur, cur)   -- "frío" no debe subir
            if cur > e.ref then
               if e.attr then e.inst:SetAttribute(e.attr, e.ref) else e.inst.Value = e.ref end
            end
         else
            e.ref = math.max(e.ref or cur, cur)   -- "temperatura" no debe bajar
            if cur < e.ref then
               if e.attr then e.inst:SetAttribute(e.attr, e.ref) else e.inst.Value = e.ref end
            end
         end
      end)
   end
end

-- Reparar luz: abre el FuseBox, usa la llave y repara los cables con chispas
local function restorePowerBody()
   local fb = Workspace:FindFirstChild("FuseBox")
   local char = LocalPlayer.Character
   local root = getRoot()
   if not (fb and char and root) then notify("No encontré el FuseBox", 4) return end
   local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
   local wrench = (backpack and backpack:FindFirstChild("Wrench")) or char:FindFirstChild("Wrench")
   if not wrench then notify("Necesitas la llave (Wrench) en el inventario", 4) return end
   local wasInBackpack = backpack ~= nil and wrench.Parent == backpack
   local back = root.CFrame
   root.CFrame = CFrame.new(CFG.Coords.FuseBox)
   root.AssemblyLinearVelocity = Vector3.zero
   task.wait(0.15)

   local status = fb:FindFirstChild("Status")
   local open = status and status:FindFirstChild("Open")
   local det = getDetector(fb:FindFirstChild("Model") or fb)
   if open and open.Value == false then
      local t0 = os.clock()
      repeat
         fireAny(det)
         task.wait(0.05)
      until open.Value == true or os.clock() - t0 > 3
   end

   wrench.Parent = char
   local n = 0
   pcall(function()
      local remotes = ReplicatedStorage:FindFirstChild("Remotes")
      local cw = remotes and remotes:FindFirstChild("ClickWire")
      local wires = fb:FindFirstChild("Wires")
      if cw and wires then
         for _, wire in ipairs(wires:GetChildren()) do
            local sp = wire:FindFirstChild("Sparkles")
            if sp and sp.Enabled then
               cw:FireServer(wire)
               n += 1
               task.wait(0.05)
            end
         end
      end
   end)
   task.wait(0.1)
   if wasInBackpack and backpack then wrench.Parent = backpack end
   local r = getRoot()
   if r then r.CFrame = back end
   notify("Luz: " .. n .. " cable(s) reparado(s)")
end

local powerConn
local function setAutoPower(v)
   if powerConn then powerConn:Disconnect(); powerConn = nil end
   if not v then return end
   local fb = Workspace:FindFirstChild("FuseBox")
   local ws = fb and fb:FindFirstChild("WarningSign")
   local gui = ws and ((ws:IsA("BillboardGui") and ws) or ws:FindFirstChildWhichIsA("BillboardGui", true))
   if not gui then notify("No encontré el WarningSign del FuseBox", 4) return end
   powerConn = Maid:Add(gui:GetPropertyChangedSignal("Enabled"):Connect(function()
      if gui.Enabled and not busy then runTask("Luz", restorePowerBody) end
   end))
   if gui.Enabled then runTask("Luz", restorePowerBody) end
end

-- Aura de items (agarra los que estén cerca, en Workspace.ItemSpots)
local function auraStep(root)
   local spots = Workspace:FindFirstChild("ItemSpots")
   if not spots then return end
   local now, range = os.clock(), S.auraRange or 12
   for _, spot in ipairs(spots:GetChildren()) do
      for _, item in ipairs(spot:GetChildren()) do
         if item:IsA("Tool") or item:IsA("Model") then
            local part = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart", true)
            if part and (part.Position - root.Position).Magnitude <= range and (not cooldown[item] or now - cooldown[item] > 1.5) then
               local d = getDetector(item)
               if d then
                  cooldown[item] = now
                  fireAny(d)
               end
            end
         end
      end
   end
end

-- Velocidad (caminar 12 / correr 17 son los valores del juego)
local function speedStep()
   local c = LocalPlayer.Character
   local h = c and c:FindFirstChildOfClass("Humanoid")
   if not h then return end
   local ws = h.WalkSpeed
   if ws == S.walk or ws == S.sprint then return end
   if ws < 10 or ws > 20 then return end   -- no tocar estados especiales (closet, stun)
   if ws >= 15 then h.WalkSpeed = S.sprint else h.WalkSpeed = S.walk end
end

-- ==================== LOOP CENTRAL (un solo Heartbeat) ====================
local accFast, accMid = 0, 0
Maid:Add(RunService.Heartbeat:Connect(function(dt)
   if unloaded then return end
   accFast += dt
   accMid += dt

   if S.speedOn then pcall(speedStep) end
   if S.fovOn then
      local cam = Workspace.CurrentCamera
      if cam then cam.FieldOfView = S.fov end
   end

   if accFast >= 0.1 then
      accFast = 0
      pcall(function()
         if S.stam then
            local v = findValue("stam", CFG.StamNames)
            if v then holdMax(v) end
            local c = LocalPlayer.Character
            local a = c and c:GetAttribute("Stam")
            if type(a) == "number" then
               local m = math.max(S.stamAttrMax or 0, a, 5)
               S.stamAttrMax = m
               if a < m then c:SetAttribute("Stam", m) end
            end
         end
         if S.oxygen then
            local v = findValue("oxygen", CFG.OxygenNames)
            if v then holdMax(v) end
         end
      end)
   end

   if accMid >= 0.3 then
      accMid = 0
      pcall(updateESPLabels)
      pcall(function()
         if not ScreenGui.Parent then ScreenGui.Parent = getGuiParent() end
         ScreenGui.Enabled = true
         ToggleBtn.Visible = true
      end)
      pcall(function()
         local root = getRoot()
         if root and S.autoDoors then autoDoorsStep(root) end
         if root and S.aura then auraStep(root) end
         if S.flash then applyFlashlight() end
         if S.antiCold then applyTemp() end
         if S.cam3 then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = 1000
            LocalPlayer.CameraMinZoomDistance = 0.5
         end
         if S.autoFuel and not busy and os.clock() >= (S.fuelRetry or 0) then
            local f = genFuel()
            if f and f <= (S.fuelMin or 40) then
               S.fuelRetry = os.clock() + 8
               runFuel(true)
            end
         end
         if S.fuelAlert then
            local f = genFuel()
            if f and f <= (S.fuelMin or 40) and os.clock() - (S.fuelAlertT or 0) > 30 then
               S.fuelAlertT = os.clock()
               notify("[!] Generador al " .. math.floor(f) .. "%", 4)
            end
         end
         if S.fullbright then applyFullbright() end
         if S.nofog then applyNoFog() end
         if S.nostatic then applyStatic() end
      end)
   end
end))

-- ==================== CONTENIDO: DASHBOARD ====================
addSection(DashboardPage, "Acciones Rápidas")
addButton(DashboardPage, "Copiar mi Posición actual (Vector3)", function()
   local r = getRoot()
   if r then
      local p = r.Position
      safeSetClipboard(string.format("Vector3.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z))
      notify("Posición copiada al portapapeles")
   end
end)
addButton(DashboardPage, "Suicidarse / Resetear", true, function()
   local c = LocalPlayer.Character
   if c and c:FindFirstChildOfClass("Humanoid") then c:FindFirstChildOfClass("Humanoid").Health = 0 end
end)
addButton(DashboardPage, "Reconectar Servidor", true, function()
   game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

addSection(DashboardPage, "Debug (para ajustar nombres del juego)")
addButton(DashboardPage, "Copiar lista de Prompts del mapa", function()
   local seen, lines = {}, {}
   for p in pairs(prompts) do
      if p.Parent then
         local parts, a, d = {}, p, 0
         while a and a ~= Workspace and d < 4 do table.insert(parts, 1, a.Name); a = a.Parent; d += 1 end
         local line = table.concat(parts, "/") .. " | " .. p.ActionText .. " | " .. p.ObjectText
         if not seen[line] then seen[line] = true; table.insert(lines, line) end
      end
   end
   table.sort(lines)
   if #lines > 200 then for i = #lines, 201, -1 do lines[i] = nil end end
   safeSetClipboard(table.concat(lines, "\n"))
   notify(#lines .. " prompts copiados")
end)
addButton(DashboardPage, "Copiar lista de ClickDetectors del mapa", function()
   local seen, lines = {}, {}
   for cd in pairs(detectors) do
      if cd.Parent then
         local parts, a, k = {}, cd, 0
         while a and a ~= Workspace and k < 5 do table.insert(parts, 1, a.Name); a = a.Parent; k += 1 end
         local line = table.concat(parts, "/")
         if not seen[line] then seen[line] = true; table.insert(lines, line) end
      end
   end
   table.sort(lines)
   for i = #lines, 301, -1 do lines[i] = nil end
   safeSetClipboard(table.concat(lines, "\n"))
   notify(#lines .. " ClickDetectors copiados")
end)
addButton(DashboardPage, "Copiar valores/atributos del personaje (temperatura)", function()
   local lines = {}
   local function dump(root, label)
      if not root then return end
      for name, val in pairs(root:GetAttributes()) do
         table.insert(lines, label .. " [attr] " .. name .. " = " .. tostring(val))
      end
      for _, d in ipairs(root:GetDescendants()) do
         if not d:IsDescendantOf(ScreenGui) then
            if d:IsA("ValueBase") then
               table.insert(lines, label .. "/" .. d:GetFullName():gsub("^.-" .. root.Name .. "%.", "") .. " = " .. tostring(d.Value))
            end
            for name, val in pairs(d:GetAttributes()) do
               table.insert(lines, label .. "/" .. d.Name .. " [attr] " .. name .. " = " .. tostring(val))
            end
         end
      end
   end
   dump(LocalPlayer.Character, "Character")
   dump(LocalPlayer:FindFirstChildOfClass("Backpack"), "Backpack")
   dump(LocalPlayer, "Player")
   for i = #lines, 351, -1 do lines[i] = nil end
   safeSetClipboard(table.concat(lines, "\n"))
   notify(#lines .. " valores copiados")
end)
addButton(DashboardPage, "Copiar estructura de Workspace", function()
   local lines = {}
   for _, ch in ipairs(Workspace:GetChildren()) do
      table.insert(lines, ch.Name .. " (" .. ch.ClassName .. ")")
      if ch:IsA("Folder") or ch:IsA("Model") then
         for _, sub in ipairs(ch:GetChildren()) do
            if #lines < 300 then table.insert(lines, "   - " .. sub.Name .. " (" .. sub.ClassName .. ")") end
         end
      end
   end
   safeSetClipboard(table.concat(lines, "\n"))
   notify(#lines .. " líneas copiadas")
end)

-- ==================== CONTENIDO: AUTO ====================
addSection(AutoPage, "Generador (sin TP, debes estar cerca)")
addButton(AutoPage, "Auto Gen: JerryCan -> Generador hasta 100%", function() runFuel(false) end)
addButton(AutoPage, "Solo agarrar JerryCan", function()
   runTask("JerryCan", function()
      if grabJerry() then notify("JerryCan en mano") else notify("No pude agarrarlo: acércate", 4) end
   end)
end)
addButton(AutoPage, "Solo usar JerryCan en el Generador", function()
   runTask("Generador", function()
      if useJerry() then notify("JerryCan usado") else notify("No pude usarlo: acércate al generador", 4) end
   end)
end)
addToggle(AutoPage, "Auto combustible (cuando baje del umbral)", function(v) S.autoFuel = v end)
addToggle(AutoPage, "Aviso de combustible bajo", function(v) S.fuelAlert = v end)
addSlider(AutoPage, "Umbral de combustible (%)", 10, 90, 40, function(v) S.fuelMin = v end)

addSection(AutoPage, "Luz / FuseBox (TP corto y vuelve)")
addButton(AutoPage, "Reparar luz ahora", function() runTask("Luz", restorePowerBody) end)
addToggle(AutoPage, "Auto reparar luz (cuando se apague)", function(v) setAutoPower(v) end)

addSection(AutoPage, "Puertas e Items")
addToggle(AutoPage, "Auto Abrir Puertas (cerca)", function(v) S.autoDoors = v end)
addSlider(AutoPage, "Rango auto-puertas", 4, 12, 8, function(v) S.doorRange = v end)
addToggle(AutoPage, "Aura de Items (agarra los cercanos)", function(v) S.aura = v end)
addSlider(AutoPage, "Radio del aura", 6, 25, 12, function(v) S.auraRange = v end)
addToggle(AutoPage, "Interacción Instantánea (solo prompts)", function(v) setInstant(v) end)

addSection(AutoPage, "Chimenea / Madera (TP, nombres aproximados)")
addButton(AutoPage, "Rellenar Chimenea", function()
   interactPatternsTP("Chimenea", CFG.PromptPatterns.Fireplace, 1)
end)
addButton(AutoPage, "Agarrar Madera / Barricadas", function()
   interactPatternsTP("Madera", CFG.PromptPatterns.Wood, 1)
end)

-- ==================== CONTENIDO: ESP ====================
addSection(ESPPage, "Enemigos")
addToggle(ESPPage, "ESP Larry", function(v) setESP("larry", v) end)
addToggle(ESPPage, "ESP Skeletons / Zombies", function(v) setESP("skeleton", v) end)
addToggle(ESPPage, "ESP Stalker", function(v) setESP("stalker", v) end)
addToggle(ESPPage, "Aviso cuando aparece Larry", function(v) S.larryNotify = v end)
addSection(ESPPage, "Jugadores y Objetos")
addToggle(ESPPage, "ESP Jugadores", function(v) setESP("players", v) end)
addToggle(ESPPage, "ESP Generador", function(v) setESP("generator", v) end)
addToggle(ESPPage, "ESP JerryCans", function(v) setESP("jerrycan", v) end)
addToggle(ESPPage, "ESP FuseBox", function(v) setESP("fusebox", v) end)
addToggle(ESPPage, "ESP Interruptores de luz", function(v) setESP("switches", v) end)
addToggle(ESPPage, "ESP Items", function(v) setESP("items", v) end)

-- ==================== CONTENIDO: TPs ====================
local function tpTo(cf)
   local r = getRoot()
   if r then r.CFrame = cf end
end

local noclipToggle
addSection(TPsPage, "Teleportaciones Clave")
addButton(TPsPage, "Teleport a Puerta Principal", function() tpTo(CFrame.new(CFG.Coords.PuertaPrincipal)) end)
addButton(TPsPage, "Teleport a Zona Segura (con Noclip)", function()
   if noclipToggle then noclipToggle.Set(true) end
   tpTo(CFrame.new(CFG.Coords.ZonaSegura))
end)
noclipToggle = addToggle(TPsPage, "Noclip", function(v) setNoclip(v) end)

addSection(TPsPage, "Más TPs (coords antiguas, verifica)")
for _, t in ipairs(CFG.ExtraTPs) do
   addButton(TPsPage, "Teleport: " .. t[1], function() tpTo(CFrame.new(t[2])) end)
end

addSection(TPsPage, "Posiciones Guardadas")
local slots = {}
for i = 1, 3 do
   addButton(TPsPage, "Guardar posición en Slot " .. i, function()
      local r = getRoot()
      if r then slots[i] = r.CFrame; notify("Slot " .. i .. " guardado") end
   end)
   addButton(TPsPage, "Ir a Slot " .. i, function()
      if slots[i] then tpTo(slots[i]) else notify("Slot " .. i .. " vacío") end
   end)
end

-- ==================== CONTENIDO: JUGADOR ====================
addSection(PlayerPage, "Recursos")
addToggle(PlayerPage, "Infinite Stamina", function(v) S.stam = v end)
addToggle(PlayerPage, "Infinite Oxygen", function(v) S.oxygen = v end)
addToggle(PlayerPage, "Linterna: batería y cargas infinitas", function(v) S.flash = v end)
addToggle(PlayerPage, "Anti-congelación (heurístico)", function(v)
   S.antiCold = v
   tempScan = 0
end)
addSection(PlayerPage, "Velocidad (caminar 12 / correr 17 por defecto)")
addToggle(PlayerPage, "Activar velocidades personalizadas", function(v)
   S.speedOn = v
   if not v then
      local c = LocalPlayer.Character
      local h = c and c:FindFirstChildOfClass("Humanoid")
      if h then
         if h.WalkSpeed == S.sprint then h.WalkSpeed = 17 elseif h.WalkSpeed == S.walk then h.WalkSpeed = 12 end
      end
   end
end)
addSlider(PlayerPage, "Velocidad al caminar", 12, 100, 12, function(v) S.walk = v end)
addSlider(PlayerPage, "Velocidad al correr", 17, 100, 17, function(v) S.sprint = v end)
addSection(PlayerPage, "Cámara")
addButton(PlayerPage, "Cámara: Libre", function() updateCameraMode("Libre") end)
addButton(PlayerPage, "Cámara: Tercera Persona", function() updateCameraMode("Tercera Persona") end)
addButton(PlayerPage, "Cámara: Primera Persona", function() updateCameraMode("Primera Persona") end)
addButton(PlayerPage, "Liberar Mouse / Cursor", function()
   UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end)

-- ==================== CONTENIDO: MISC ====================
addToggle(PlayerPage, "Forzar 3ra persona (anti-reset del juego)", function(v)
   S.cam3 = v
   if v then
      S.camMaxOrig = S.camMaxOrig or LocalPlayer.CameraMaxZoomDistance
   else
      pcall(function() LocalPlayer.CameraMaxZoomDistance = S.camMaxOrig or 16 end)
      S.camMaxOrig = nil
   end
end)
addToggle(PlayerPage, "FOV personalizado", function(v)
   S.fovOn = v
   local cam = Workspace.CurrentCamera
   if v then
      S.fovOrig = S.fovOrig or (cam and cam.FieldOfView) or 70
   elseif cam then
      cam.FieldOfView = S.fovOrig or 70
      S.fovOrig = nil
   end
end)
addSlider(PlayerPage, "Campo de visión (FOV)", 40, 120, 70, function(v) S.fov = v end)

addSection(MiscPage, "Iluminación")
addToggle(MiscPage, "Fullbright (quitar oscuridad)", function(v)
   if v then saveLighting() end
   S.fullbright = v
   if v then applyFullbright() else restoreKeys(FB_KEYS) end
end)
addToggle(MiscPage, "Quitar Niebla", function(v)
   if v then saveLighting() end
   S.nofog = v
   if v then applyNoFog() else restoreKeys(FOG_KEYS); restoreAtmos() end
end)
addToggle(MiscPage, "Quitar efecto de Estática", function(v)
   S.nostatic = v
   if v then applyStatic() else restoreStatic() end
end)

addSection(MiscPage, "Mapa")
addButton(MiscPage, "Quitar barreras de closets (mejor esfuerzo)", function()
   local n = 0
   for _, d in ipairs(Workspace:GetDescendants()) do
      if d:IsA("BasePart") and d.Name:lower():find("barrier") and ancestorMatches(d, { "closet", "wardrobe" }) then
         d.CanCollide = false
         d.CanQuery = false
         n += 1
      end
   end
   notify(n .. " barreras desactivadas")
end)

addSection(MiscPage, "Sistema")
addButton(MiscPage, "Destruir UI (pide confirmación)", true, function()
   if env.ArticallUnload then env.ArticallUnload() end
end)

-- ==================== DESCARGA LIMPIA ====================
local function unload()
   if unloaded then return end
   unloaded = true
   pcall(function()
      noclipOn = false
      setInstant(false)
      restoreKeys(FB_KEYS)
      restoreKeys(FOG_KEYS)
      restoreAtmos()
      restoreStatic()
      if S.speedOn then
         local c = LocalPlayer.Character
         local h = c and c:FindFirstChildOfClass("Humanoid")
         if h then
            if h.WalkSpeed == S.sprint then h.WalkSpeed = 17 elseif h.WalkSpeed == S.walk then h.WalkSpeed = 12 end
         end
      end
      if S.fovOn and Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = S.fovOrig or 70 end
      if S.cam3 then LocalPlayer.CameraMaxZoomDistance = S.camMaxOrig or 16 end
      UserInputService.MouseBehavior = Enum.MouseBehavior.Default
      for _, g in pairs(ESP) do
         g.enabled = false
         for o in pairs(g.objs) do espRemove(g, o) end
      end
   end)
   env.ArticallUnload = nil
   Maid:Clean()
end
env.ArticallUnload = unload

notify("Articall Hub v2.2 cargado. RightShift = mostrar/ocultar", 4)
