-- AURORA.lua — Самое красивое меню для Murder Mystery 2
-- Delta Executor • Полностью кастомный рендер • Никаких библиотек

--//////////////////////////////////////--
-- SECTION 1: ENVIRONMENT & UTILITIES
--//////////////////////////////////////--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Drawing support check
local Drawing = nil
pcall(function()
    Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/linlinx/DrawingLib/main/Drawing.lua"))()
end)
if not Drawing then
    -- Fallback: use basic Drawing if available in executor
    pcall(function()
        Drawing = {
            new = function(type) 
                local d = Instance.new("Frame")
                d.BackgroundTransparency = 1
                return d
            end
        }
    end)
end

--//////////////////////////////////////--
-- SECTION 2: MATH & EASING LIBRARY
--//////////////////////////////////////--

local Easing = {}

function Easing.Linear(t) return t end
function Easing.InQuad(t) return t * t end
function Easing.OutQuad(t) return 1 - (1 - t) * (1 - t) end
function Easing.InOutQuad(t) return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2 end
function Easing.InCubic(t) return t * t * t end
function Easing.OutCubic(t) return 1 - (1 - t) ^ 3 end
function Easing.InOutCubic(t) return t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2) ^ 3 / 2 end
function Easing.InQuart(t) return t * t * t * t end
function Easing.OutQuart(t) return 1 - (1 - t) ^ 4 end
function Easing.InOutQuart(t) return t < 0.5 and 8 * t * t * t * t or 1 - (-2 * t + 2) ^ 4 / 2 end
function Easing.InQuint(t) return t * t * t * t * t end
function Easing.OutQuint(t) return 1 - (1 - t) ^ 5 end
function Easing.InOutQuint(t) return t < 0.5 and 16 * t * t * t * t * t or 1 - (-2 * t + 2) ^ 5 / 2 end
function Easing.InSine(t) return 1 - math.cos(t * math.pi / 2) end
function Easing.OutSine(t) return math.sin(t * math.pi / 2) end
function Easing.InOutSine(t) return -(math.cos(math.pi * t) - 1) / 2 end
function Easing.InExpo(t) return t == 0 and 0 or 2 ^ (10 * (t - 1)) end
function Easing.OutExpo(t) return t == 1 and 1 or 1 - 2 ^ (-10 * t) end
function Easing.InOutExpo(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return t < 0.5 and 2 ^ (20 * t - 10) / 2 or (2 - 2 ^ (-20 * t + 10)) / 2
end
function Easing.InCirc(t) return 1 - math.sqrt(1 - t * t) end
function Easing.OutCirc(t) return math.sqrt(1 - (t - 1) * (t - 1)) end
function Easing.InOutCirc(t)
    return t < 0.5 and (1 - math.sqrt(1 - 4 * t * t)) / 2 or (math.sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2
end
function Easing.InElastic(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return -2 ^ (10 * (t - 1)) * math.sin((t - 1.075) * (2 * math.pi) / 0.3)
end
function Easing.OutElastic(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return 2 ^ (-10 * t) * math.sin((t - 0.075) * (2 * math.pi) / 0.3) + 1
end
function Easing.InOutElastic(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    if t < 0.5 then
        return -(2 ^ (20 * t - 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2
    else
        return (2 ^ (-20 * t + 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)) / 2 + 1
    end
end
function Easing.OutBounce(t)
    local n1 = 7.5625
    local d1 = 2.75
    if t < 1 / d1 then
        return n1 * t * t
    elseif t < 2 / d1 then
        return n1 * (t - 1.5 / d1) * (t - 1.5 / d1) + 0.75
    elseif t < 2.5 / d1 then
        return n1 * (t - 2.25 / d1) * (t - 2.25 / d1) + 0.9375
    else
        return n1 * (t - 2.625 / d1) * (t - 2.625 / d1) + 0.984375
    end
end
function Easing.InBounce(t) return 1 - Easing.OutBounce(1 - t) end
function Easing.InOutBounce(t)
    return t < 0.5 and (1 - Easing.OutBounce(1 - 2 * t)) / 2 or (1 + Easing.OutBounce(2 * t - 1)) / 2
end

-- Spring physics solver
local Spring = {}
Spring.__index = Spring

function Spring.new(target, stiffness, damping)
    local self = setmetatable({}, Spring)
    self.value = target or 0
    self.target = target or 0
    self.velocity = 0
    self.stiffness = stiffness or 150
    self.damping = damping or 12
    return self
end

function Spring:update(dt)
    local force = (self.target - self.value) * self.stiffness
    self.velocity = self.velocity + force * dt
    self.velocity = self.velocity * math.exp(-self.damping * dt)
    self.value = self.value + self.velocity * dt
    return self.value
end

function Spring:setTarget(target)
    self.target = target
end

-- Vector2 utilities
local Vec2 = {}
function Vec2.Lerp(a, b, t) return a + (b - a) * t end
function Vec2.Dist(a, b) return (a - b).Magnitude end
function Vec2.Clamp(val, min, max) return math.min(math.max(val, min), max) end

-- Color utilities
local ColorUtil = {}
function ColorUtil.HSBtoRGB(h, s, b)
    h = h % 360
    local c = b * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = b - c
    local r, g, bl
    if h < 60 then r, g, bl = c, x, 0
    elseif h < 120 then r, g, bl = x, c, 0
    elseif h < 180 then r, g, bl = 0, c, x
    elseif h < 240 then r, g, bl = 0, x, c
    elseif h < 300 then r, g, bl = x, 0, c
    else r, g, bl = c, 0, x
    end
    return Color3.new(r + m, g + m, bl + m)
end

function ColorUtil.Lerp(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

--//////////////////////////////////////--
-- SECTION 3: TWEEN MANAGER
--//////////////////////////////////////--

local TweenManager = {}
TweenManager.activeTweens = {}

local Tween = {}
Tween.__index = Tween

function Tween.new(obj, props, duration, easing, callback)
    local self = setmetatable({}, Tween)
    self.obj = obj
    self.startProps = {}
    self.endProps = props
    self.duration = duration or 0.5
    self.elapsed = 0
    self.easing = easing or Easing.OutQuad
    self.callback = callback
    self.completed = false
    self.cancelled = false
    
    for k, v in pairs(props) do
        self.startProps[k] = obj[k] or 0
    end
    
    table.insert(TweenManager.activeTweens, self)
    return self
end

function Tween:cancel()
    self.cancelled = true
end

function Tween:update(dt)
    if self.cancelled or self.completed then return end
    self.elapsed = self.elapsed + dt
    local t = math.min(self.elapsed / self.duration, 1)
    local easedT = self.easing(t)
    
    for k, v in pairs(self.endProps) do
        local startVal = self.startProps[k]
        if type(v) == "number" then
            self.obj[k] = startVal + (v - startVal) * easedT
        elseif typeof(v) == "Color3" and typeof(startVal) == "Color3" then
            self.obj[k] = ColorUtil.Lerp(startVal, v, easedT)
        elseif typeof(v) == "Vector2" and typeof(startVal) == "Vector2" then
            self.obj[k] = Vector2.new(
                Vec2.Lerp(startVal.X, v.X, easedT),
                Vec2.Lerp(startVal.Y, v.Y, easedT)
            )
        end
    end
    
    if t >= 1 then
        self.completed = true
        if self.callback then self.callback() end
    end
end

function TweenManager.update(dt)
    for i = #TweenManager.activeTweens, 1, -1 do
        local tween = TweenManager.activeTweens[i]
        tween:update(dt)
        if tween.completed or tween.cancelled then
            table.remove(TweenManager.activeTweens, i)
        end
    end
end

--//////////////////////////////////////--
-- SECTION 4: PARTICLE SYSTEM
--//////////////////////////////////////--

local ParticleSystem = {}
ParticleSystem.particles = {}
ParticleSystem.pool = {}
ParticleSystem.MAX_PARTICLES = 50

local Particle = {}
Particle.__index = Particle

function Particle.new(x, y, vx, vy, size, color, life)
    local self = setmetatable({}, Particle)
    self.x = x or 0
    self.y = y or 0
    self.vx = vx or 0
    self.vy = vy or 0
    self.size = size or 4
    self.color = color or Color3.new(1, 1, 1)
    self.life = life or 2
    self.maxLife = self.life
    self.alpha = 1
    self.trail = {}
    self.drawObj = nil
    
    pcall(function()
        self.drawObj = Drawing.new("Circle")
        if self.drawObj then
            self.drawObj.Radius = self.size
            self.drawObj.Filled = true
            self.drawObj.Color = self.color
            self.drawObj.Transparency = 0
            self.drawObj.Visible = true
        end
    end)
    
    return self
end

function Particle:update(dt)
    self.life = self.life - dt
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.vx = self.vx * 0.99
    self.vy = self.vy * 0.99
    self.alpha = math.max(0, self.life / self.maxLife)
    self.size = self.size * 0.998
    
    -- Trail
    table.insert(self.trail, {x = self.x, y = self.y, alpha = self.alpha, life = 0.3})
    for i = #self.trail, 1, -1 do
        self.trail[i].life = self.trail[i].life - dt
        if self.trail[i].life <= 0 then
            table.remove(self.trail, i)
        end
    end
    
    if self.drawObj then
        pcall(function()
            self.drawObj.Position = Vector2.new(self.x, self.y)
            self.drawObj.Radius = self.size
            self.drawObj.Transparency = 1 - self.alpha
        end)
    end
    
    return self.life > 0
end

function Particle:destroy()
    for _, t in ipairs(self.trail) do
        -- trail particles cleaned up automatically
    end
    if self.drawObj then
        pcall(function() self.drawObj:Remove() end)
    end
end

function ParticleSystem.spawn(x, y, count, config)
    config = config or {}
    local spread = config.spread or 100
    local speed = config.speed or 200
    local size = config.size or 3
    local color = config.color or Color3.new(0, 0.83, 1)
    local life = config.life or 1.5
    
    for i = 1, (count or 10) do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.5 + math.random())
        local vx = math.cos(angle) * spd + (math.random() - 0.5) * spread
        local vy = math.sin(angle) * spd + (math.random() - 0.5) * spread
        local p = Particle.new(x, y, vx, vy, size * (0.5 + math.random()), color, life * (0.5 + math.random()))
        table.insert(ParticleSystem.particles, p)
    end
    
    -- Limit particles
    while #ParticleSystem.particles > ParticleSystem.MAX_PARTICLES do
        local oldest = table.remove(ParticleSystem.particles, 1)
        oldest:destroy()
    end
end

function ParticleSystem.update(dt)
    for i = #ParticleSystem.particles, 1, -1 do
        local alive = ParticleSystem.particles[i]:update(dt)
        if not alive then
            ParticleSystem.particles[i]:destroy()
            table.remove(ParticleSystem.particles, i)
        end
    end
end

function ParticleSystem.clear()
    for _, p in ipairs(ParticleSystem.particles) do
        p:destroy()
    end
    ParticleSystem.particles = {}
end

--//////////////////////////////////////--
-- SECTION 5: DRAWING UTILITIES
--//////////////////////////////////////--

local DrawUtil = {}
DrawUtil.drawings = {}

function DrawUtil.createCircle(x, y, radius, color, filled, thickness)
    local obj = nil
    pcall(function()
        obj = Drawing.new("Circle")
        if obj then
            obj.Position = Vector2.new(x, y)
            obj.Radius = radius
            obj.Color = color or Color3.new(1, 1, 1)
            obj.Filled = filled ~= false
            obj.Thickness = thickness or 1
            obj.Transparency = 0
            obj.Visible = true
            obj.ZIndex = 10
            table.insert(DrawUtil.drawings, obj)
        end
    end)
    return obj
end

function DrawUtil.createLine(x1, y1, x2, y2, color, thickness)
    local obj = nil
    pcall(function()
        obj = Drawing.new("Line")
        if obj then
            obj.From = Vector2.new(x1, y1)
            obj.To = Vector2.new(x2, y2)
            obj.Color = color or Color3.new(1, 1, 1)
            obj.Thickness = thickness or 1
            obj.Transparency = 0
            obj.Visible = true
            obj.ZIndex = 10
            table.insert(DrawUtil.drawings, obj)
        end
    end)
    return obj
end

function DrawUtil.createText(x, y, text, color, size, center)
    local obj = nil
    pcall(function()
        obj = Drawing.new("Text")
        if obj then
            obj.Position = Vector2.new(x, y)
            obj.Text = text or ""
            obj.Color = color or Color3.new(1, 1, 1)
            obj.Size = size or 16
            obj.Center = center or true
            obj.Transparency = 0
            obj.Visible = true
            obj.ZIndex = 10
            obj.Outline = true
            obj.OutlineColor = Color3.new(0, 0, 0)
            table.insert(DrawUtil.drawings, obj)
        end
    end)
    return obj
end

function DrawUtil.createQuad(x, y, w, h, color, thickness)
    local obj = nil
    pcall(function()
        obj = Drawing.new("Square")
        if obj then
            obj.Position = Vector2.new(x, y)
            obj.Size = Vector2.new(w, h)
            obj.Color = color or Color3.new(1, 1, 1)
            obj.Thickness = thickness or 1
            obj.Filled = false
            obj.Transparency = 0
            obj.Visible = true
            obj.ZIndex = 10
            table.insert(DrawUtil.drawings, obj)
        end
    end)
    return obj
end

function DrawUtil.clearAll()
    for _, d in ipairs(DrawUtil.drawings) do
        pcall(function() d:Remove() end)
    end
    DrawUtil.drawings = {}
end

--//////////////////////////////////////--
-- SECTION 6: COLOR THEME
--//////////////////////////////////////--

local Theme = {
    Background = Color3.fromRGB(6, 6, 12),
    BackgroundAlpha = 0.92,
    Accent1 = Color3.fromRGB(0, 212, 255),     -- Cyan
    Accent2 = Color3.fromRGB(179, 71, 234),     -- Purple
    Accent3 = Color3.fromRGB(255, 0, 76),       -- Red
    Gold = Color3.fromRGB(255, 215, 0),
    White = Color3.fromRGB(255, 255, 255),
    TextPrimary = Color3.fromRGB(240, 240, 250),
    TextSecondary = Color3.fromRGB(160, 160, 180),
    GlassBg = Color3.fromRGB(14, 14, 24),
    GlassBorder = Color3.fromRGB(40, 40, 60),
    ToggleOff = Color3.fromRGB(60, 60, 70),
    ToggleOn = Color3.fromRGB(0, 212, 255),
    SliderTrack = Color3.fromRGB(30, 30, 40),
    SliderFill = Color3.fromRGB(0, 212, 255),
    HealthGreen = Color3.fromRGB(0, 255, 100),
    HealthRed = Color3.fromRGB(255, 50, 50),
    RoleMurderer = Color3.fromRGB(255, 30, 30),
    RoleSheriff = Color3.fromRGB(30, 130, 255),
    RoleInnocent = Color3.fromRGB(50, 255, 100),
    RoleHero = Color3.fromRGB(255, 200, 50),
}

-- Animated hue offset
Theme.hueOffset = 0

--//////////////////////////////////////--
-- SECTION 7: GUI FRAMEWORK
--//////////////////////////////////////--

local GUI = {}
GUI.elements = {}
GUI.container = nil
GUI.visible = true
GUI.dragging = false
GUI.dragStart = nil
GUI.containerPos = Vector2.new(100, 100)
GUI.containerSize = Vector2.new(620, 420)
GUI.springX = Spring.new(100, 120, 10)
GUI.springY = Spring.new(100, 120, 10)
GUI.activeTab = 1
GUI.tabButtons = {}
GUI.tabIndicator = Spring.new(0, 80, 8)
GUI.tabIndicatorTarget = 0
GUI.contentPanels = {}
GUI.parallaxOffset = Vector2.new(0, 0)
GUI.idleTimer = 0
GUI.idleBreathing = 1

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AURORA"
ScreenGui.Parent = CoreGui
syn.protect_gui and syn.protect_gui(ScreenGui)

-- Create main container
GUI.container = Instance.new("Frame")
GUI.container.Name = "MainContainer"
GUI.container.Size = UDim2.new(0, GUI.containerSize.X, 0, GUI.containerSize.Y)
GUI.container.Position = UDim2.new(0, GUI.containerPos.X, 0, GUI.containerPos.Y)
GUI.container.BackgroundColor3 = Theme.GlassBg
GUI.container.BackgroundTransparency = 1 - Theme.BackgroundAlpha
GUI.container.BorderSizePixel = 0
GUI.container.Parent = ScreenGui
GUI.container.ZIndex = 100

-- Glassmorphism blur background
local blurBg = Instance.new("Frame")
blurBg.Name = "BlurBg"
blurBg.Size = UDim2.new(1, 0, 1, 0)
blurBg.BackgroundColor3 = Theme.Background
blurBg.BackgroundTransparency = 0.94
blurBg.BorderSizePixel = 0
blurBg.Parent = GUI.container
blurBg.ZIndex = 1

-- Border frame (for animated gradient border)
local borderFrame = Instance.new("Frame")
borderFrame.Name = "Border"
borderFrame.Size = UDim2.new(1, 4, 1, 4)
borderFrame.Position = UDim2.new(0, -2, 0, -2)
borderFrame.BackgroundTransparency = 1
borderFrame.BorderSizePixel = 0
borderFrame.Parent = GUI.container
borderFrame.ZIndex = 0

-- Inner content area
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -50, 1, -30)
contentArea.Position = UDim2.new(0, 45, 0, 15)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = GUI.container
contentArea.ZIndex = 10

-- Corner smoothing
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = GUI.container

-- Shadow effect (simulated with multiple frames)
for i = 1, 3 do
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow" .. i
    shadow.Size = UDim2.new(1, 8 * i, 1, 8 * i)
    shadow.Position = UDim2.new(0, -4 * i, 0, 2 * i)
    shadow.BackgroundColor3 = Theme.Accent1
    shadow.BackgroundTransparency = 0.85 + (i * 0.05)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -i
    shadow.Parent = GUI.container
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16 + i * 2)
    corner.Parent = shadow
end

-- Title bar (drag handle)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = GUI.container
titleBar.ZIndex = 20

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 14, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextColor3 = Theme.TextPrimary
titleText.Text = "A U R O R A"
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -24, 0, 4)
closeBtn.BackgroundColor3 = Theme.Accent3
closeBtn.BackgroundTransparency = 0.7
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Theme.White
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
closeBtn.ZIndex = 25
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    GUI.visible = false
    ScreenGui.Enabled = false
end)

--//////////////////////////////////////--
-- SECTION 8: TAB SYSTEM
--//////////////////////////////////////--

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(0, 42, 1, -20)
tabBar.Position = UDim2.new(0, 4, 0, 28)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.Parent = GUI.container
tabBar.ZIndex = 15

local tabNames = {"PRECISION", "OMNISCIENCE", "TRANSCEND", "INFINITY", "GENESIS"}
local tabIcons = {"⌖", "◉", "☁", "∞", "⚙"}

for i, name in ipairs(tabNames) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab" .. i
    tabBtn.Size = UDim2.new(0, 34, 0, 34)
    tabBtn.Position = UDim2.new(0, 4, 0, 10 + (i - 1) * 44)
    tabBtn.BackgroundColor3 = Theme.GlassBg
    tabBtn.BackgroundTransparency = 0.8
    tabBtn.Text = tabIcons[i]
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 16
    tabBtn.TextColor3 = Theme.TextSecondary
    tabBtn.BorderSiz
