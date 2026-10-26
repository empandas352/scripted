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

-- ==================== CONFIGURACIÓN GUARDADA ====================
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "ArticallHub_config.json"
local SAVE_KEYS = { "lang", "uiMul", "menuKey", "notifs", "confirmDanger", "lockPanel", "coldName", "coldMode" }
S.lang, S.uiMul, S.menuKey = "es", 1, "RightShift"
S.notifs, S.confirmDanger, S.lockPanel = true, true, false
S.coldName, S.coldMode = "", "high"

local function saveConfig()
   pcall(function()
      if not writefile then return end
      local t = {}
      for _, k in ipairs(SAVE_KEYS) do t[k] = S[k] end
      writefile(CONFIG_FILE, HttpService:JSONEncode(t))
   end)
end
pcall(function()
   if isfile and readfile and isfile(CONFIG_FILE) then
      local t = HttpService:JSONDecode(readfile(CONFIG_FILE))
      for _, k in ipairs(SAVE_KEYS) do
         if t[k] ~= nil then S[k] = t[k] end
      end
   end
end)
local savePending = false
local function scheduleSave()
   if savePending then return end
   savePending = true
   task.delay(1, function()
      savePending = false
      saveConfig()
   end)
end

-- ==================== IDIOMAS (ES / EN) ====================
-- Los textos del código están en español; en inglés se reemplazan por frases de este diccionario.
local DICT = {
   -- pestañas y secciones
   { "Configuración", "Settings" }, { "Jugador", "Player" },
   { "Acciones Rápidas", "Quick Actions" },
   { "Debug (para ajustar nombres del juego)", "Debug (to fix game names)" },
   { "Generador (sin TP, debes estar cerca)", "Generator (no TP, stay close)" },
   { "Luz / FuseBox (TP corto y vuelve)", "Power / FuseBox (short TP and back)" },
   { "Puertas e Items", "Doors & Items" },
   { "Chimenea / Madera (TP, nombres aproximados)", "Fireplace / Wood (TP, approximate names)" },
   { "Enemigos", "Enemies" }, { "Jugadores y Objetos", "Players & Objects" },
   { "Teleportaciones Clave", "Key Teleports" },
   { "Más TPs (coords antiguas, verifica)", "More TPs (old coords, verify)" },
   { "Posiciones Guardadas", "Saved Positions" }, { "Recursos", "Resources" },
   { "Velocidad (caminar 12 / correr 17 por defecto)", "Speed (walk 12 / run 17 default)" },
   { "Iluminación", "Lighting" }, { "Mapa", "Map" }, { "Sistema", "System" },
   { "Anti-congelación", "Anti-Freeze" }, { "Idioma", "Language" },
   { "Configuración guardada", "Saved settings" },
   -- dashboard
   { "Copiar mi Posición actual (Vector3)", "Copy my current position (Vector3)" },
   { "Suicidarse / Resetear", "Reset character" }, { "Reconectar Servidor", "Rejoin server" },
   { "Copiar lista de Prompts del mapa", "Copy map Prompts list" },
   { "Copiar lista de ClickDetectors del mapa", "Copy map ClickDetectors list" },
   { "Copiar valores/atributos del personaje (temperatura)", "Copy character values/attributes (temperature)" },
   { "Copiar estructura de Workspace", "Copy Workspace structure" },
   -- auto
   { "Auto Gen: JerryCan -> Generador hasta 100%", "Auto Gen: JerryCan -> Generator to 100%" },
   { "Solo agarrar JerryCan", "Only grab JerryCan" },
   { "Solo usar JerryCan en el Generador", "Only use JerryCan on Generator" },
   { "Auto combustible (cuando baje del umbral)", "Auto fuel (when below threshold)" },
   { "Aviso de combustible bajo", "Low fuel warning" },
   { "Umbral de combustible (%)", "Fuel threshold (%)" },
   { "Reparar luz ahora", "Repair power now" },
   { "Auto reparar luz (cuando se apague)", "Auto repair power (when it goes out)" },
   { "Auto Abrir Puertas (cerca)", "Auto open doors (nearby)" },
   { "Rango auto-puertas", "Auto-door range" },
   { "Aura de Items (agarra los cercanos)", "Item aura (grabs nearby items)" },
   { "Radio del aura", "Aura radius" },
   { "Interacción Instantánea (solo prompts)", "Instant interaction (prompts only)" },
   { "Rellenar Chimenea", "Refill fireplace" },
   { "Agarrar Madera / Barricadas", "Grab wood / barricades" },
   -- esp / tps
   { "ESP Jugadores", "ESP Players" }, { "ESP Generador", "ESP Generator" },
   { "ESP Interruptores de luz", "ESP Light switches" },
   { "Aviso cuando aparece Larry", "Alert when Larry spawns" },
   { "Teleport a Puerta Principal", "Teleport to Main Door" },
   { "Teleport a Zona Segura (con Noclip)", "Teleport to Safe Zone (with Noclip)" },
   { "Guardar posición en Slot ", "Save position in Slot " }, { "Ir a Slot ", "Go to Slot " },
   { "Dormitorio", "Bedroom" }, { "Baño", "Bathroom" }, { "Escalera", "Stairs" },
   { "Sala", "Living room" }, { "Consola de energía", "Power console" },
   -- jugador
   { "Linterna: batería y cargas infinitas", "Flashlight: infinite battery & charges" },
   { "Anti-congelación (mantener valores de temperatura)", "Anti-freeze (hold temperature values)" },
   { "Nombre exacto del valor (opcional)", "Exact value name (optional)" },
   { "Temperatura: mantener alto (apagado = bajo)", "Temperature: hold HIGH (off = hold low)" },
   { "Ocultar overlay de frío/escarcha", "Hide cold/frost overlay" },
   { "Desactivar scripts de frío (agresivo)", "Disable cold scripts (aggressive)" },
   { "Detectar variable de temperatura (10 s)", "Detect temperature variable (10 s)" },
   { "Activar velocidades personalizadas", "Enable custom speeds" },
   { "Velocidad al caminar", "Walk speed" }, { "Velocidad al correr", "Run speed" },
   { "Cámara: Libre", "Camera: Free" }, { "Cámara: Tercera Persona", "Camera: Third Person" },
   { "Cámara: Primera Persona", "Camera: First Person" }, { "Cámara", "Camera" },
   { "Liberar Mouse / Cursor", "Release mouse / cursor" },
   { "Forzar 3ra persona (anti-reset del juego)", "Force 3rd person (anti game reset)" },
   { "FOV personalizado", "Custom FOV" }, { "Campo de visión (FOV)", "Field of view (FOV)" },
   -- misc
   { "Fullbright (quitar oscuridad)", "Fullbright (remove darkness)" },
   { "Quitar Niebla", "Remove fog" }, { "Quitar efecto de Estática", "Remove static effect" },
   { "Quitar barreras de closets (mejor esfuerzo)", "Remove closet barriers (best effort)" },
   { "Destruir UI (pide confirmación)", "Destroy UI (asks to confirm)" },
   -- config
   { "Cambiar tecla del menú", "Change menu key" }, { "Tamaño del panel (%)", "Panel size (%)" },
   { "Notificaciones", "Notifications" },
   { "Confirmar acciones peligrosas", "Confirm dangerous actions" },
   { "Bloquear arrastre del panel", "Lock panel dragging" },
   { "Restablecer posición del panel", "Reset panel position" },
   { "Guardar configuración ahora", "Save settings now" },
   -- mensajes
   { "¿Seguro? Toca de nuevo para confirmar", "Sure? Tap again to confirm" },
   { "Articall Hub v2.2 cargado. Tecla del menú: ", "Articall Hub v2.2 loaded. Menu key: " },
   { "Espera, hay otra acción en curso", "Wait, another action is running" },
   { "JerryCan en mano", "JerryCan in hand" }, { "JerryCan usado", "JerryCan used" },
   { "Necesitas la llave (Wrench) en el inventario", "You need the Wrench in your inventory" },
   { "No encontré el WarningSign del FuseBox", "FuseBox WarningSign not found" },
   { "No encontré el FuseBox", "FuseBox not found" },
   { "No pude agarrar el JerryCan: acércate al generador", "Couldn't grab the JerryCan: get closer to the generator" },
   { "No pude usar el JerryCan: acércate al generador", "Couldn't use the JerryCan: get closer to the generator" },
   { "No pude agarrarlo: acércate", "Couldn't grab it: get closer" },
   { "No pude usarlo: acércate al generador", "Couldn't use it: get closer to the generator" },
   { "No encontré Shack/JerryCan/Generator (usa Debug)", "Shack/JerryCan/Generator not found (use Debug)" },
   { "Posición copiada al portapapeles", "Position copied to clipboard" },
   { "[!] Generador al ", "[!] Generator at " },
   { "[!] Larry apareció en el mapa", "[!] Larry spawned on the map" },
   { "Generador al 100%", "Generator at 100%" }, { "Generador: ", "Generator: " },
   { "Secuencia ejecutada", "Sequence executed" },
   { " ClickDetectors copiados", " ClickDetectors copied" }, { " prompts copiados", " prompts copied" },
   { " líneas copiadas", " lines copied" }, { " valores copiados", " values copied" },
   { " barreras desactivadas", " barriers disabled" },
   { " activado(s)", " activated" }, { " activado", " activated" },
   { "Chimenea", "Fireplace" }, { "Madera", "Wood" },
   { ": no encontré objetos (usa Debug)", ": no objects found (use Debug)" },
   { ": no encontrado (usa Debug)", ": not found (use Debug)" },
   { "cable(s) reparado(s)", "wire(s) repaired" }, { "Luz: ", "Power: " },
   { "Detección iniciada: quédate en la zona fría 10 s", "Detection started: stay in the cold area for 10 s" },
   { "Ya hay una detección en curso", "Detection already running" },
   { "Detección lista: ", "Detection done: " }, { " cambios copiados", " changes copied" },
   { "Presiona una tecla para el menú...", "Press a key for the menu..." },
   { "Tecla del menú: ", "Menu key: " }, { "Ajustes guardados", "Settings saved" },
   { "Nombre guardado: ", "Name saved: " }, { "Nombre borrado (modo automático)", "Name cleared (automatic mode)" },
}
table.sort(DICT, function(a, b) return #a[1] > #b[1] end)

local function plainReplace(str, a, b)
   local out, i = {}, 1
   while true do
      local st, en = string.find(str, a, i, true)
      if not st then
         table.insert(out, str:sub(i))
         break
      end
      table.insert(out, str:sub(i, st - 1))
      table.insert(out, b)
      i = en + 1
   end
   return table.concat(out)
end

local function tr(text)
   if S.lang ~= "en" then return text end
   for _, pair in ipairs(DICT) do
      if string.find(text, pair[1], 1, true) then text = plainReplace(text, pair[1], pair[2]) end
   end
   return text
end

local i18nReg = {}
local function regText(inst, es, prefix, mode)
   local e = { inst = inst, es = es, prefix = prefix or "", upper = (mode == "upper") }
   table.insert(i18nReg, e)
   local t = tr(es)
   if e.upper then t = t:upper() end
   inst.Text = e.prefix .. t
end
local function setLang(l)
   S.lang = l
   for _, e in ipairs(i18nReg) do
      pcall(function()
         local t = tr(e.es)
         if e.upper then t = t:upper() end
         e.inst.Text = e.prefix .. t
      end)
   end
end

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
   if unloaded or S.notifs == false then return end
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
   l.Text = tr(text)
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
local function makeDraggable(frame, handle, onClick, getScale, isLocked)
   local dragging, startInput, startMouse, startPos, moved = false, nil, nil, nil, 0
   handle.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
         if isLocked and isLocked() and not onClick then return end
         dragging, moved = true, 0
         startInput, startMouse, startPos = input, input.Position, frame.Position
      end
   end)
   -- un solo InputEnded global: no deja conexiones colgadas entre toques
   Maid:Add(UserInputService.InputEnded:Connect(function(input)
      if not dragging or not startInput then return end
      local sameTouch = (startInput.UserInputType == Enum.UserInputType.Touch and input == startInput)
      local sameMouse = (startInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
      if sameTouch or sameMouse then
         dragging, startInput = false, nil
         if onClick and moved < 6 then onClick() end
      end
   end))
   Maid:Add(UserInputService.InputChanged:Connect(function(input)
      if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
         local d = input.Position - startMouse
         moved = math.max(moved, d.Magnitude)
         if isLocked and isLocked() then return end
         local sc = getScale and getScale() or 1
         frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / sc, startPos.Y.Scale, startPos.Y.Offset + d.Y / sc)
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
   UIScaleObj.Scale = math.clamp(math.min(vp.X / 760, vp.Y / 500), 0.5, 1) * (S.uiMul or 1)
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

local lastToggle = 0
local function toggleMenu()
   if os.clock() - lastToggle < 0.25 then return end
   lastToggle = os.clock()
   MainFrame.Visible = not MainFrame.Visible
end
do
   local armed = false
   onTap(CloseBtn, function()
      if S.confirmDanger ~= false and not armed then
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
makeDraggable(MainFrame, TopBar, nil, function() return UIScaleObj.Scale end, function() return S.lockPanel end)
makeDraggable(ToggleBtn, ToggleBtn, toggleMenu, nil)

Maid:Add(UserInputService.InputBegan:Connect(function(input, gp)
   if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
   if S.waitingKey then
      S.waitingKey = false
      S.menuKey = input.KeyCode.Name
      scheduleSave()
      notify("Tecla del menú: " .. S.menuKey)
      return
   end
   if not gp and input.KeyCode.Name == S.menuKey then toggleMenu() end
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
   regText(tabBtn, name, "  ")
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
local ConfigPage = createTab("Configuración")
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
   regText(sec, titleText, "", "upper")
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
   regText(btn, name, "  ")
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
      if confirm and S.confirmDanger ~= false and not armed then
         armed = true
         btn.Text = "  " .. tr("¿Seguro? Toca de nuevo para confirmar")
         task.delay(2.5, function()
            if armed then armed = false; btn.Text = "  " .. tr(name) end
         end)
         return
      end
      armed = false
      btn.Text = "  " .. tr(name)
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
   regText(label, name)
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

local function addTextBox(page, name, placeholder, default, callback)
   local frame = Instance.new("Frame")
   frame.BackgroundColor3 = C.white
   frame.Size = UDim2.new(1, -10, 0, 46)
   frame.Parent = page
   local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = frame
   local st = Instance.new("UIStroke"); st.Color = C.line; st.Thickness = 1.2; st.Parent = frame

   local label = Instance.new("TextLabel")
   label.BackgroundTransparency = 1
   label.Position = UDim2.new(0, 12, 0, 0)
   label.Size = UDim2.new(0.5, -12, 1, 0)
   label.Font = Enum.Font.GothamSemibold
   label.TextColor3 = Color3.fromRGB(30, 30, 30)
   label.TextSize = 12
   label.TextWrapped = true
   label.TextXAlignment = Enum.TextXAlignment.Left
   label.Parent = frame
   regText(label, name)

   local box = Instance.new("TextBox")
   box.BackgroundColor3 = C.hover
   box.Position = UDim2.new(0.5, 0, 0.5, -15)
   box.Size = UDim2.new(0.5, -12, 0, 30)
   box.Font = Enum.Font.Gotham
   box.TextSize = 13
   box.TextColor3 = C.dark
   box.PlaceholderText = placeholder
   box.Text = default or ""
   box.ClearTextOnFocus = false
   box.Parent = frame
   local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = box
   box.FocusLost:Connect(function() pcall(callback, box.Text) end)
   return box
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

-- Anti-congelación: mantiene valores de temperatura/frío (por nombre exacto o heurístico)
local TEMP_BAD = { "cold", "freez", "chill", "frost", "hypo" }
local TEMP_GOOD = { "temp", "warm", "heat" }
local COLD_GUI = { "frost", "freez", "blizzard", "snow", "cold" }
local COLD_SCRIPT = { "cold", "freez", "temp", "frost" }
local tempList, coldGuiList, coldScriptList, tempScan = {}, {}, {}, 0
local coldGuiOrig, coldScriptOrig = {}, {}
local refStore = setmetatable({}, { __mode = "k" })
local customEntry, customLast = nil, 0

local function matchAny(name, list)
   local n = name:lower()
   for _, pat in ipairs(list) do
      if n:find(pat, 1, true) then return true end
   end
   return false
end

local function resetTempRefs()
   refStore = setmetatable({}, { __mode = "k" })
   customEntry, customLast = nil, 0
   tempScan = 0
end

local function classifyTemp(name)
   if matchAny(name, TEMP_BAD) then return "bad" end
   if matchAny(name, TEMP_GOOD) then return "good" end
   return nil
end

local function scanTemp()
   tempScan = os.clock()
   tempList, coldGuiList, coldScriptList = {}, {}, {}
   local custom = S.coldName
   local heuristic = not (custom and custom ~= "")
   local roots = { LocalPlayer.Character, LocalPlayer, Workspace:FindFirstChild(LocalPlayer.Name) }
   local seen = {}
   local function addAttrs(inst)
      for name, val in pairs(inst:GetAttributes()) do
         if type(val) == "number" then
            local k = classifyTemp(name)
            if k then table.insert(tempList, { inst = inst, attr = name, kind = k }) end
         end
      end
   end
   for _, root in ipairs(roots) do
      if root and not seen[root] then
         seen[root] = true
         if heuristic then addAttrs(root) end
         for _, d in ipairs(root:GetDescendants()) do
            if not seen[d] and not d:IsDescendantOf(ScreenGui) then
               seen[d] = true
               if heuristic then
                  if d:IsA("NumberValue") or d:IsA("IntValue") then
                     local k = classifyTemp(d.Name)
                     if k then table.insert(tempList, { inst = d, kind = k }) end
                  end
                  if not d:IsA("GuiObject") and not d:IsA("BasePart") then addAttrs(d) end
               end
               if (d:IsA("GuiObject") or d:IsA("ScreenGui")) and matchAny(d.Name, COLD_GUI) then
                  table.insert(coldGuiList, d)
               elseif d:IsA("LocalScript") and matchAny(d.Name, COLD_SCRIPT) then
                  table.insert(coldScriptList, d)
               end
            end
         end
      end
   end
end

local function holdEntry(e, kind)
   local cur
   if e.attr then cur = e.inst:GetAttribute(e.attr) else cur = e.inst.Value end
   if type(cur) ~= "number" then return end
   local function set(v)
      if e.attr then e.inst:SetAttribute(e.attr, v) else e.inst.Value = v end
   end
   local store = refStore[e.inst]
   if not store then store = {}; refStore[e.inst] = store end
   local k = e.attr or "__value"
   if kind == "bad" then
      store[k] = math.min(store[k] or cur, cur)   -- "frío": no debe subir
      if cur > store[k] then set(store[k]) end
   else
      store[k] = math.max(store[k] or cur, cur)   -- "temperatura": no debe bajar
      if cur < store[k] then set(store[k]) end
   end
end

local function findCustom(name)
   local roots = { LocalPlayer.Character, LocalPlayer, Workspace:FindFirstChild(LocalPlayer.Name), ReplicatedStorage, Lighting, Workspace }
   for _, r in ipairs(roots) do
      if r then
         if type(r:GetAttribute(name)) == "number" then return { inst = r, attr = name } end
         local v = r:FindFirstChild(name, true)
         if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then return { inst = v } end
      end
   end
   local c = LocalPlayer.Character
   local h = c and c:FindFirstChildOfClass("Humanoid")
   if h and type(h:GetAttribute(name)) == "number" then return { inst = h, attr = name } end
   return nil
end

local function restoreColdGui()
   for g, v in pairs(coldGuiOrig) do
      pcall(function() if g:IsA("ScreenGui") then g.Enabled = v else g.Visible = v end end)
   end
   coldGuiOrig = {}
end
local function restoreColdScripts()
   for sc, v in pairs(coldScriptOrig) do pcall(function() sc.Disabled = v end) end
   coldScriptOrig = {}
end

local function applyTemp()
   if os.clock() - tempScan > 4 then scanTemp() end
   if S.antiCold then
      local custom = S.coldName
      if custom and custom ~= "" then
         local stale = (not customEntry) or customEntry.name ~= custom or (not customEntry.e)
            or (customEntry.e.inst.Parent == nil)
         if stale and os.clock() - customLast > 2 then
            customLast = os.clock()
            customEntry = { name = custom, e = findCustom(custom) }
         end
         local e = customEntry and customEntry.e
         if e then pcall(holdEntry, e, (S.coldMode == "low") and "bad" or "good") end
      else
         for _, e in ipairs(tempList) do pcall(holdEntry, e, e.kind) end
      end
   end
   if S.coldGui then
      for _, g in ipairs(coldGuiList) do
         pcall(function()
            if not g.Parent then return end
            if g:IsA("ScreenGui") then
               if coldGuiOrig[g] == nil then coldGuiOrig[g] = g.Enabled end
               g.Enabled = false
            else
               if coldGuiOrig[g] == nil then coldGuiOrig[g] = g.Visible end
               g.Visible = false
            end
         end)
      end
   end
   if S.coldScripts then
      for _, sc in ipairs(coldScriptList) do
         pcall(function()
            if coldScriptOrig[sc] == nil then coldScriptOrig[sc] = sc.Disabled end
            sc.Disabled = true
         end)
      end
   end
end

-- Detector: compara valores antes/después de 10 s en la zona fría para encontrar la variable real
local detecting = false
local function snapshotNumbers()
   local snap, texts, n = {}, {}, 0
   local function addInst(d)
      if d:IsA("NumberValue") or d:IsA("IntValue") then snap[d:GetFullName()] = d.Value end
      if not d:IsA("GuiObject") and not d:IsA("BasePart") then
         for name, val in pairs(d:GetAttributes()) do
            if type(val) == "number" then snap[d:GetFullName() .. " [attr] " .. name] = val end
         end
      end
   end
   for _, root in ipairs({ LocalPlayer.Character, LocalPlayer, ReplicatedStorage, Lighting, Workspace }) do
      if root then
         addInst(root)
         for _, d in ipairs(root:GetDescendants()) do
            n += 1
            if n % 2500 == 0 then task.wait() end
            if not d:IsDescendantOf(ScreenGui) then addInst(d) end
         end
      end
   end
   local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
   if pg then
      for _, d in ipairs(pg:GetDescendants()) do
         if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and not d:IsDescendantOf(ScreenGui) then
            texts[d:GetFullName()] = d.Text
         end
      end
   end
   return snap, texts
end

local function detectTemperature()
   if detecting then notify("Ya hay una detección en curso", 3) return end
   detecting = true
   task.spawn(function()
      local ok, err = pcall(function()
         notify("Detección iniciada: quédate en la zona fría 10 s", 5)
         local a, ta = snapshotNumbers()
         task.wait(10)
         local b, tb = snapshotNumbers()
         local diffs = {}
         for k, v1 in pairs(a) do
            local v2 = b[k]
            if v2 and v2 ~= v1 then table.insert(diffs, { k = k, a = v1, b = v2, d = math.abs(v2 - v1) }) end
         end
         table.sort(diffs, function(x, y) return x.d > y.d end)
         local lines = { "== Valores numéricos que cambiaron en 10 s (mayor cambio primero) ==" }
         for i = 1, math.min(#diffs, 60) do
            local e = diffs[i]
            table.insert(lines, string.format("%s: %s -> %s", e.k, tostring(e.a), tostring(e.b)))
         end
         table.insert(lines, "")
         table.insert(lines, "== Textos de HUD que cambiaron ==")
         local tl = {}
         for k, t1 in pairs(ta) do
            local t2 = tb[k]
            if t2 and t2 ~= t1 then table.insert(tl, k .. ': "' .. t1 .. '" -> "' .. t2 .. '"') end
         end
         table.sort(tl)
         for i = 1, math.min(#tl, 30) do table.insert(lines, tl[i]) end
         safeSetClipboard(table.concat(lines, "\n"))
         notify("Detección lista: " .. (#diffs + #tl) .. " cambios copiados", 5)
      end)
      detecting = false
      if not ok then notify("Error: " .. tostring(err), 4) end
   end)
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
         if S.antiCold or S.coldGui or S.coldScripts then applyTemp() end
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
addSection(PlayerPage, "Anti-congelación")
addToggle(PlayerPage, "Anti-congelación (mantener valores de temperatura)", function(v)
   S.antiCold = v
   resetTempRefs()
end)
addTextBox(PlayerPage, "Nombre exacto del valor (opcional)", "ej: Temperature", S.coldName or "", function(t)
   t = (t or ""):gsub("^%s+", "")
   t = t:gsub("%s+$", "")
   S.coldName = t
   resetTempRefs()
   scheduleSave()
   notify(t ~= "" and ("Nombre guardado: " .. t) or "Nombre borrado (modo automático)")
end)
do
   local modeToggle = addToggle(PlayerPage, "Temperatura: mantener alto (apagado = bajo)", function(v)
      S.coldMode = v and "high" or "low"
      resetTempRefs()
      scheduleSave()
   end)
   modeToggle.Set(S.coldMode ~= "low", true)
end
addToggle(PlayerPage, "Ocultar overlay de frío/escarcha", function(v)
   S.coldGui = v
   if not v then restoreColdGui() end
end)
addToggle(PlayerPage, "Desactivar scripts de frío (agresivo)", function(v)
   S.coldScripts = v
   if not v then restoreColdScripts() end
end)
addButton(PlayerPage, "Detectar variable de temperatura (10 s)", detectTemperature)
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

-- ==================== CONTENIDO: CONFIGURACIÓN ====================
addSection(ConfigPage, "Idioma")
addButton(ConfigPage, "Español", function()
   setLang("es")
   scheduleSave()
   notify("Idioma: Español")
end)
addButton(ConfigPage, "English", function()
   setLang("en")
   scheduleSave()
   notify("Language: English")
end)

addSection(ConfigPage, "Panel")
addButton(ConfigPage, "Cambiar tecla del menú", function()
   S.waitingKey = true
   notify("Presiona una tecla para el menú...", 4)
end)
addSlider(ConfigPage, "Tamaño del panel (%)", 60, 130, math.floor((S.uiMul or 1) * 100 + 0.5), function(v)
   local nv = v / 100
   if math.abs(nv - (S.uiMul or 1)) > 0.001 then
      S.uiMul = nv
      updateScale()
      scheduleSave()
   end
end)
do
   local t1 = addToggle(ConfigPage, "Notificaciones", function(v) S.notifs = v; scheduleSave() end)
   t1.Set(S.notifs ~= false, true)
   local t2 = addToggle(ConfigPage, "Confirmar acciones peligrosas", function(v) S.confirmDanger = v; scheduleSave() end)
   t2.Set(S.confirmDanger ~= false, true)
   local t3 = addToggle(ConfigPage, "Bloquear arrastre del panel", function(v) S.lockPanel = v; scheduleSave() end)
   t3.Set(S.lockPanel == true, true)
end
addButton(ConfigPage, "Restablecer posición del panel", function()
   MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
   ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
end)

addSection(ConfigPage, "Configuración guardada")
addButton(ConfigPage, "Guardar configuración ahora", function()
   saveConfig()
   notify("Ajustes guardados")
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
      restoreColdGui()
      restoreColdScripts()
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

notify("Articall Hub v2.2 cargado. Tecla del menú: " .. S.menuKey, 4)
