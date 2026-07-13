-- AURORA_MOBILE.lua — Самое красивое меню MM2 для телефона
-- Delta Executor Mobile • Fox & Jack Production
-- Версия: 2.0 • Полный рерайт

--//////////////////////////////////////--
-- SECTION 1: ENVIRONMENT
--//////////////////////////////////////--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local Workspace = workspace

-- Safe parent for mobile
local function getSafeParent()
    local success, result = pcall(function() return CoreGui end)
    if success and result then return result end
    success, result = pcall(function() return LocalPlayer:WaitForChild("PlayerGui") end)
    if success and result then return result end
    return game:GetService("GuiService")
end

local safeParent = getSafeParent()

--//////////////////////////////////////--
-- SECTION 2: COLOR THEME
--//////////////////////////////////////--

local C = {
    BG = Color3.fromRGB(6, 6, 14),
    Accent1 = Color3.fromRGB(0, 212, 255),
    Accent2 = Color3.fromRGB(179, 71, 234),
    Accent3 = Color3.fromRGB(255, 0, 76),
    Gold = Color3.fromRGB(255, 215, 0),
    White = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(235, 235, 245),
    Text2 = Color3.fromRGB(150, 150, 170),
    Glass = Color3.fromRGB(14, 14, 26),
    GlassBorder = Color3.fromRGB(40, 40, 60),
    ToggleOff = Color3.fromRGB(55, 55, 70),
    ToggleOn = Color3.fromRGB(0, 212, 255),
    SliderTrack = Color3.fromRGB(28, 28, 40),
    SliderFill = Color3.fromRGB(0, 212, 255),
    Red = Color3.fromRGB(255, 50, 50),
    Green = Color3.fromRGB(50, 255, 100),
    Blue = Color3.fromRGB(40, 140, 255),
    Yellow = Color3.fromRGB(255, 200, 50),
}

--//////////////////////////////////////--
-- SECTION 3: GLOBAL STATE
--//////////////////////////////////////--

local State = {
    -- Aim
    AimEnabled = false,
    AimPart = "Head",
    AimSmooth = 5,
    AimFOV = 120,
    TeamCheck = false,
    WallCheck = false,
    AutoShoot = false,
    AutoShootDelay = 0.3,
    
    -- ESP
    ESPEnabled = true,
    ESPBox = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPRole = true,
    ESPChams = false,
    ESPWeapons = false,
    ESPCoins = true,
    ESPMaxDist = 300,
    
    -- Movement
    SpeedValue = 16,
    JumpValue = 50,
    FlyEnabled = false,
    NoClipEnabled = false,
    InfJumpEnabled = false,
    
    -- Farm
    AutoCoin = false,
    AutoClick = false,
    CPSSpeed = 12,
    AutoClaim = false,
    
    -- UI
    MenuVisible = true,
    ActiveTab = 1,
    
    -- Connections для очистки
    Connections = {},
    Loops = {},
}

--//////////////////////////////////////--
-- SECTION 4: UTILITY FUNCTIONS
--//////////////////////////////////////--

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or C.GlassBorder
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.3
    stroke.Parent = parent
    return stroke
end

local function createGradient(parent, c1, c2, rotation)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    grad.Rotation = rotation or 135
    grad.Parent = parent
    return grad
end

local function createShadow(parent, size, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, size or 12, 1, size or 12)
    shadow.Position = UDim2.new(0, -(size or 12)/2, 0, -(size or 12)/2)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageTransparency = transparency or 0.75
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 49, 49)
    shadow.ZIndex = -1
    shadow.Parent = parent
    return shadow
end

local function round(val, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(val * mult + 0.5) / mult
end

--//////////////////////////////////////--
-- SECTION 5: MM2 CORE LOGIC (Топ-функции)
--//////////////////////////////////////--

local MM2 = {}

function MM2.getAlivePlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(list, p)
        end
    end
    return list
end

function MM2.getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    
    -- Check tools in character
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n:find("knife") or n:find("murder") then return "Murderer" end
            if n:find("gun") or n:find("sheriff") or n:find("pistol") or n:find("revolver") then return "Sheriff" end
            if n:find("hero") or n:find("sword") then return "Hero" end
        end
    end
    
    -- Check backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("murder") then return "Murderer" end
                if n:find("gun") or n:find("sheriff") or n:find("pistol") or n:find("revolver") then return "Sheriff" end
                if n:find("hero") or n:find("sword") then return "Hero" end
            end
        end
    end
    
    return "Innocent"
end

function MM2.getRoleColor(role)
    if role == "Murderer" then return C.Red
    elseif role == "Sheriff" then return C.Blue
    elseif role == "Hero" then return C.Yellow
    else return C.Green end
end

function MM2.getCoins()
    local coins = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 0.6 and not obj.Anchored == false then
                local n = obj.Name:lower()
                if n == "coin" or n == "coinpickup" or n:find("coin_") or n:find("_coin") then
                    table.insert(coins, obj)
                end
            end
        end
    end)
    return coins
end

function MM2.getWeapons()
    local weapons = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 0.5 then
                local n = obj.Name:lower()
                if n:find("gun") or n:find("knife") or n:find("pistol") then
                    table.insert(weapons, obj)
                end
            end
        end
    end)
    return weapons
end

function MM2.getClosestPlayerToCenter(fov, teamCheck, wallCheck)
    local closest = nil
    local closestDist = fov or math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, p in ipairs(MM2.getAlivePlayers()) do
        local aimPart = p.Character:FindFirstChild(State.AimPart) or p.Character:FindFirstChild("Head")
        if not aimPart then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
        if not onScreen then continue end
        
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist >= closestDist then continue end
        
        -- Team check
        if teamCheck then
            local myRole = MM2.getRole(LocalPlayer)
            local theirRole = MM2.getRole(p)
            if myRole == "Murderer" and theirRole == "Murderer" then continue end
            if myRole == "Sheriff" and theirRole == "Sheriff" then continue end
            if myRole == "Innocent" and theirRole == "Innocent" then continue end
            if myRole == "Hero" and theirRole == "Hero" then continue end
        end
        
        -- Wall check (raycast)
        if wallCheck then
            local rayOrigin = Camera.CFrame.Position
            local rayDir = (aimPart.Position - rayOrigin).Unit * 1000
            local ray = Ray.new(rayOrigin, rayDir)
            local ignoreList = {LocalPlayer.Character}
            local hit, hitPos = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList, false, true)
            if hit then
                local isVisible = false
                for _, ancestor in ipairs(hit:GetAncestors()) do
                    if ancestor == p.Character then
                        isVisible = true
                        break
                    end
                end
                if not isVisible then continue end
            end
        end
        
        closest = p
        closestDist = dist
    end
    
    return closest
end

function MM2.getMapList()
    local maps = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("Folder") then
                local n = obj.Name:lower()
                if n:find("map") or n == "bank" or n == "hospital" or n == "policestation" or n == "biolab" or n == "research" or n == "lobby" then
                    table.insert(maps, obj.Name)
                end
            end
        end
    end)
    if #maps == 0 then
        maps = {"Lobby", "Bank", "Hospital", "PoliceStation", "BioLab", "ResearchFacility"}
    end
    return maps
end

function MM2.teleportTo(part)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    if part:IsA("BasePart") then
        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
    end
end

--//////////////////////////////////////--
-- SECTION 6: ESP RENDERING (Mobile-Optimized)
--//////////////////////////////////////--

local ESP = {}
ESP.objects = {}
ESP.active = {}

function ESP.createBillboard(parent, text, color, size)
    local bb = Instance.new("BillboardGui")
    bb.Name = "AURORA_ESP"
    bb.Size = UDim2.new(0, 200, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = State.ESPMaxDist
    bb.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = size or 12
    label.TextColor3 = color or C.White
    label.TextStrokeTransparency = 0.5
    label.Text = text
    label.Parent = bb
    
    return bb
end

function ESP.createHighlight(parent, color)
    local highlight = Instance.new("Highlight")
    highlight.Name = "AURORA_ESP"
    highlight.FillColor = color or C.White
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = color or C.White
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = parent
    return highlight
end

function ESP.clearAll()
    for _, obj in ipairs(ESP.objects) do
        pcall(function() obj:Destroy() end)
    end
    ESP.objects = {}
end

function ESP.update()
    ESP.clearAll()
    if not State.ESPEnabled then return end
    
    -- Player ESP
    for _, p in ipairs(MM2.getAlivePlayers()) do
        local char = p.Character
        if not char then continue end
        
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not head or not hrp or not hum then continue end
        
        local role = MM2.getRole(p)
        local roleColor = MM2.getRoleColor(role)
        
        -- Chams (Highlight)
        if State.ESPChams then
            local hl = ESP.createHighlight(char, roleColor)
            table.insert(ESP.objects, hl)
        end
        
        -- Name ESP
        if State.ESPName then
            local text = p.Name
            if State.ESPRole then text = text .. " [" .. role .. "]" end
            if State.ESPDistance then
                local dist = round((hrp.Position - Camera.CFrame.Position).Magnitude, 0)
                text = text .. " (" .. dist .. "m)"
            end
            local bb = ESP.createBillboard(head, text, roleColor, 11)
            table.insert(ESP.objects, bb)
        end
        
        -- Health bar (using BillboardGui)
        if State.ESPHealth then
            local healthPercent = hum.Health / hum.MaxHealth
            local healthColor = Color3.fromRGB(
                255 * (1 - healthPercent),
                255 * healthPercent,
                50
            )
            local healthBB = Instance.new("BillboardGui")
            healthBB.Name = "AURORA_ESP"
            healthBB.Size = UDim2.new(0, 40, 0, 4)
            healthBB.StudsOffset = Vector3.new(0, 2.2, 0)
            healthBB.AlwaysOnTop = true
            healthBB.MaxDistance = State.ESPMaxDist
            healthBB.Parent = head
            
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            bg.BackgroundTransparency = 0.4
            bg.BorderSizePixel = 0
            bg.Parent = healthBB
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(healthPercent, 0, 1, 0)
            fill.BackgroundColor3 = healthColor
            fill.BorderSizePixel = 0
            fill.Parent = bg
            
            table.insert(ESP.objects, healthBB)
        end
    end
    
    -- Coin ESP
    if State.ESPCoins then
        for _, coin in ipairs(MM2.getCoins()) do
            local bb = ESP.createBillboard(coin, "💰", C.Gold, 16)
            table.insert(ESP.objects, bb)
        end
    end
    
    -- Weapon ESP
    if State.ESPWeapons then
        for _, weapon in ipairs(MM2.getWeapons()) do
            local bb = ESP.createBillboard(weapon, "🔫", C.Accent3, 14)
            table.insert(ESP.objects, bb)
        end
    end
end

--//////////////////////////////////////--
-- SECTION 7: MOVEMENT FUNCTIONS
--//////////////////////////////////////--

local Movement = {}
Movement.flyConnection = nil
Movement.flyBodyGyro = nil
Movement.flyBodyVel = nil

function Movement.setSpeed(value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
end

function Movement.setJump(value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = value
    end
end

function Movement.enableFly()
    if Movement.flyConnection then Movement.disableFly() end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = LocalPlayer.Character.HumanoidRootPart
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(400000, 400000, 400000)
    bg.P = 30000
    bg.CFrame = Camera.CFrame
    bg.Parent = hrp
    Movement.flyBodyGyro = bg
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(400000, 400000, 400000)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    Movement.flyBodyVel = bv
    
    Movement.flyConnection = RunService.Heartbeat:Connect(function()
        if not State.FlyEnabled then return end
        if not Movement.flyBodyGyro or not Movement.flyBodyGyro.Parent then
            Movement.disableFly()
            return
        end
        Movement.flyBodyGyro.CFrame = Camera.CFrame
        
        local speed = 50
        local vel = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, speed, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, speed, 0) end
        if Movement.flyBodyVel and Movement.flyBodyVel.Parent then
            Movement.flyBodyVel.Velocity = vel
        end
    end)
end

function Movement.disableFly()
    if Movement.flyConnection then
        Movement.flyConnection:Disconnect()
        Movement.flyConnection = nil
    end
    if Movement.flyBodyGyro then
        pcall(function() Movement.flyBodyGyro:Destroy() end)
        Movement.flyBodyGyro = nil
    end
    if Movement.flyBodyVel then
        pcall(function() Movement.flyBodyVel:Destroy() end)
        Movement.flyBodyVel = nil
    end
end

function Movement.enableNoClip()
    if not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

function Movement.disableNoClip()
    if not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

--//////////////////////////////////////--
-- SECTION 8: FARMING FUNCTIONS
--//////////////////////////////////////--

local Farming = {}
Farming.coinLoop = nil
Farming.clickLoop = nil
Farming.claimLoop = nil

function Farming.startCoinFarm()
    if Farming.coinLoop then Farming.stopCoinFarm() end
    Farming.coinLoop = RunService.Heartbeat:Connect(function()
        if not State.AutoCoin then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = LocalPlayer.Character.HumanoidRootPart
        
        for _, coin in ipairs(MM2.getCoins()) do
            local dist = (coin.Position - hrp.Position).Magnitude
            if dist < 50 then
                pcall(function()
                    firetouchinterest(hrp, coin, 0)
                    firetouchinterest(hrp, coin, 1)
                end)
            end
        end
    end)
end

function Farming.stopCoinFarm()
    if Farming.coinLoop then
        Farming.coinLoop:Disconnect()
        Farming.coinLoop = nil
    end
end

function Farming.startAutoClick()
    if Farming.clickLoop then Farming.stopAutoClick() end
    Farming.clickLoop = RunService.Heartbeat:Connect(function()
        if not State.AutoClick then return end
        local interval = 1 / State.CPSSpeed
        task.wait(interval)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
            vim:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
        end)
    end)
end

function Farming.stopAutoClick()
    if Farming.clickLoop then
        Farming.clickLoop:Disconnect()
        Farming.clickLoop = nil
    end
end

function Farming.startAutoClaim()
    if Farming.claimLoop then Farming.stopAutoClaim() end
    Farming.claimLoop = RunService.Heartbeat:Connect(function()
        if not State.AutoClaim then return end
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    if obj:FindFirstAncestorOfClass("Part") then
           
