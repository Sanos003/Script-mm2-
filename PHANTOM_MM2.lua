
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = workspace
local VIM = game:GetService("VirtualInputManager")

local GUI = nil
pcall(function() GUI = CoreGui end)
if not GUI then pcall(function() GUI = LocalPlayer.PlayerGui end) end
if not GUI then GUI = game:GetService("GuiService") end

local C = {
    BG = Color3.fromRGB(5, 5, 12), Cyan = Color3.fromRGB(0, 212, 255),
    Purple = Color3.fromRGB(179, 71, 234), Red = Color3.fromRGB(255, 0, 76),
    Gold = Color3.fromRGB(255, 215, 0), White = Color3.fromRGB(255, 255, 255),
    Gray = Color3.fromRGB(160, 160, 180), Glass = Color3.fromRGB(14, 14, 26),
    GlassB = Color3.fromRGB(40, 40, 60), Off = Color3.fromRGB(55, 55, 70),
    On = Color3.fromRGB(0, 212, 255), Track = Color3.fromRGB(28, 28, 40),
    Fill = Color3.fromRGB(0, 212, 255), HealthR = Color3.fromRGB(255, 50, 50),
    HealthG = Color3.fromRGB(50, 255, 100), Blue = Color3.fromRGB(40, 140, 255),
    Yellow = Color3.fromRGB(255, 200, 50),
}

local CFG = {
    AimOn = false, AimPart = "Head", AimSmooth = 5, AimFOV = 120,
    TeamCheck = false, WallCheck = false, AutoShoot = false, ShootDelay = 0.3,
    ESPOn = true, ESPName = true, ESPDist = true, ESPHP = true,
    ESPRole = true, ESPChams = false, ESPCoins = true, ESPGuns = false, ESPDistMax = 300,
    Speed = 16, Jump = 50, Fly = false, NoClip = false, InfJump = false,
    MenuOn = true, Tab = 1,
}

function round(n, d) local m = 10^(d or 0) return math.floor(n*m+0.5)/m end
function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p return c end
function stroke(p, c, t, tr) local s = Instance.new("UIStroke") s.Color = c or C.GlassB s.Thickness = t or 1 s.Transparency = tr or 0.3 s.Parent = p return s end

local MM2 = {}
function MM2.players()
    local l = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(l, p)
        end
    end
    return l
end

function MM2.role(p)
    local c = p.Character
    if not c then return "Innocent" end
    local function has(w)
        for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find(w) then return true end end
        local bp = p:FindFirstChild("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find(w) then return true end end end
        return false
    end
    if has("knife") or has("murder") then return "Murderer" end
    if has("gun") or has("sheriff") or has("pistol") or has("revolver") then return "Sheriff" end
    if has("hero") or has("sword") then return "Hero" end
    return "Innocent"
end

function MM2.roleColor(r)
    if r == "Murderer" then return C.HealthR elseif r == "Sheriff" then return C.Blue elseif r == "Hero" then return C.Yellow else return C.HealthG end
end

function MM2.coins()
    local l = {}
    pcall(function() for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") and o.Transparency < 0.6 and (o.Name == "Coin" or o.Name:lower():find("coin")) then table.insert(l, o) end end end)
    return l
end

function MM2.guns()
    local l = {}
    pcall(function() for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") and o.Transparency < 0.5 and (o.Name:lower():find("gun") or o.Name:lower():find("knife")) then table.insert(l, o) end end end)
    return l
end

function MM2.closest(fov, tc, wc)
    local best, bestD = nil, fov or 9999
    local ctr = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(MM2.players()) do
        local prt = p.Character:FindFirstChild(CFG.AimPart) or p.Character:FindFirstChild("Head")
        if prt then
            local pos, on = Camera:WorldToViewportPoint(prt.Position)
            if on then
                local d = (Vector2.new(pos.X, pos.Y) - ctr).Magnitude
                if d < bestD then
                    if tc and MM2.role(LocalPlayer) == MM2.role(p) then continue end
                    if wc then
                        local ray = Ray.new(Camera.CFrame.Position, (prt.Position - Camera.CFrame.Position).Unit * 1000)
                        local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
                        if hit then
                            local vis = false
                            for _, a in ipairs(hit:GetAncestors()) do if a == p.Character then vis = true break end end
                            if not vis then continue end
                        end
                    end
                    best, bestD = p, d
                end
            end
        end
    end
    return best
end

local ESP = {items = {}}
function ESP.bb(p, txt, clr, sz)
    local b = Instance.new("BillboardGui") b.Name = "PH" b.Size = UDim2.new(0, 200, 0, 30) b.StudsOffset = Vector3.new(0, 3, 0) b.AlwaysOnTop = true b.MaxDistance = CFG.ESPDistMax b.Parent = p
    local l = Instance.new("TextLabel") l.Size = UDim2.new(1, 0, 1, 0) l.BackgroundTransparency = 1 l.Font = Enum.Font.GothamBold l.TextSize = sz or 12 l.TextColor3 = clr or C.White l.TextStrokeTransparency = 0.5 l.Text = txt l.Parent = b
    return b
end
function ESP.clear() for _, o in ipairs(ESP.items) do pcall(function() o:Destroy() end) end ESP.items = {} end
function ESP.update()
    ESP.clear()
    if not CFG.ESPOn then return end
    for _, p in ipairs(MM2.players()) do
        local c = p.Character if not c then continue end
        local hd, hr, hu = c:FindFirstChild("Head"), c:FindFirstChild("HumanoidRootPart"), c:FindFirstChild("Humanoid")
        if not (hd and hr and hu) then continue end
        local rl = MM2.role(p) local rc = MM2.roleColor(rl)
        if CFG.ESPChams then
            local hl = Instance.new("Highlight") hl.FillColor = rc hl.FillTransparency = 0.7 hl.OutlineColor = rc hl.OutlineTransparency = 0.3 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop hl.Parent = c table.insert(ESP.items, hl)
        end
        if CFG.ESPName then
            local t = p.Name
            if CFG.ESPRole then t = t.." ["..rl.."]" end
            if CFG.ESPDist then t = t.." "..round((hr.Position - Camera.CFrame.Position).Magnitude, 0).."m" end
            table.insert(ESP.items, ESP.bb(hd, t, rc, 11))
        end
        if CFG.ESPHP then
            local hp = hu.Health/hu.MaxHealth local hc = Color3.fromRGB(255*(1-hp), 255*hp, 50)
            local hb = Instance.new("BillboardGui") hb.Size = UDim2.new(0, 40, 0, 4) hb.StudsOffset = Vector3.new(0, 2.2, 0) hb.AlwaysOnTop = true hb.MaxDistance = CFG.ESPDistMax hb.Parent = hd
            local bg = Instance.new("Frame") bg.Size = UDim2.new(1, 0, 1, 0) bg.BackgroundColor3 = Color3.new(0,0,0) bg.BackgroundTransparency = 0.4 bg.BorderSizePixel = 0 bg.Parent = hb
            local fl = Instance.new("Frame") fl.Size = UDim2.new(hp, 0, 1, 0) fl.BackgroundColor3 = hc fl.BorderSizePixel = 0 fl.Parent = bg
            table.insert(ESP.items, hb)
        end
    end
    if CFG.ESPCoins then for _, o in ipairs(MM2.coins()) do table.insert(ESP.items, ESP.bb(o, "💰", C.Gold, 16)) end end
    if CFG.ESPGuns then for _, o in ipairs(MM2.guns()) do table.insert(ESP.items, ESP.bb(o, "🔫", C.Red, 14)) end end
end
local MOVE = {fc = nil, bg = nil, bv = nil}
function MOVE.flyOn()
    if MOVE.fc then MOVE.flyOff() end
    local c = LocalPlayer.Character if not c or not c:FindFirstChild("HumanoidRootPart") then return end
    local hr = c.HumanoidRootPart
    MOVE.bg = Instance.new("BodyGyro") MOVE.bg.MaxTorque = Vector3.new(400000,400000,400000) MOVE.bg.P = 30000 MOVE.bg.CFrame = Camera.CFrame MOVE.bg.Parent = hr
    MOVE.bv = Instance.new("BodyVelocity") MOVE.bv.MaxForce = Vector3.new(400000,400000,400000) MOVE.bv.Velocity = Vector3.new(0,0,0) MOVE.bv.Parent = hr
    MOVE.fc = RunService.Heartbeat:Connect(function()
        if not CFG.Fly then return end
        if MOVE.bg and MOVE.bg.Parent then MOVE.bg.CFrame = Camera.CFrame end
        local v = Vector3.new(0,0,0) local s = 50
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then v = v + Camera.CFrame.LookVector * s end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then v = v - Camera.CFrame.LookVector * s end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then v = v - Camera.CFrame.RightVector * s end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then v = v + Camera.CFrame.RightVector * s end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then v = v + Vector3.new(0,s,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then v = v - Vector3.new(0,s,0) end
        if MOVE.bv and MOVE.bv.Parent then MOVE.bv.Velocity = v end
    end)
end
function MOVE.flyOff() if MOVE.fc then MOVE.fc:Disconnect() MOVE.fc = nil end if MOVE.bg then pcall(function() MOVE.bg:Destroy() end) MOVE.bg = nil end if MOVE.bv then pcall(function() MOVE.bv:Destroy() end) MOVE.bv = nil end end
function MOVE.speed(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end end
function MOVE.jump(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower = v end end
function MOVE.noclipOn() if LocalPlayer.Character then for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end
function MOVE.noclipOff() if LocalPlayer.Character then for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end

local AIM = {loop = nil}
function AIM.start()
    if AIM.loop then AIM.stop() end
    AIM.loop = RunService.Heartbeat:Connect(function()
        if not CFG.AimOn then return end
        local t = MM2.closest(CFG.AimFOV, CFG.TeamCheck, CFG.WallCheck)
        if not t then return end
        local p = t.Character:FindFirstChild(CFG.AimPart) or t.Character:FindFirstChild("Head")
        if not p then return end
        local la = CFrame.new(Camera.CFrame.Position, p.Position)
        if CFG.AimSmooth > 1 then Camera.CFrame = Camera.CFrame:Lerp(la, 1/CFG.AimSmooth) else Camera.CFrame = la end
        if CFG.AutoShoot and (p.Position - Camera.CFrame.Position).Magnitude < 150 then
            pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,nil,0) task.wait(0.05) VIM:SendMouseButtonEvent(0,0,0,false,nil,0) end)
        end
    end)
end
function AIM.stop() if AIM.loop then AIM.loop:Disconnect() AIM.loop = nil end end

local function tgl(par, y, txt, def, cb)
    local f = Instance.new("Frame") f.Size = UDim2.new(1, -16, 0, 40) f.Position = UDim2.new(0, 8, 0, y) f.BackgroundTransparency = 1 f.BorderSizePixel = 0 f.Parent = par f.ZIndex = 12
    local lb = Instance.new("TextLabel") lb.Size = UDim2.new(0.6, 0, 1, 0) lb.BackgroundTransparency = 1 lb.Font = Enum.Font.Gotham lb.TextSize = 12 lb.TextColor3 = C.White lb.Text = txt lb.TextXAlignment = Enum.TextXAlignment.Left lb.Parent = f
    local tr = Instance.new("Frame") tr.Size = UDim2.new(0, 44, 0, 24) tr.Position = UDim2.new(1, -48, 0.5, -12) tr.BackgroundColor3 = C.Off tr.BorderSizePixel = 0 tr.Parent = f tr.ZIndex = 13 corner(tr, 12)
    local bl = Instance.new("Frame") bl.Size = UDim2.new(0, 18, 0, 18) bl.Position = UDim2.new(0, 3, 0.5, -9) bl.BackgroundColor3 = C.White bl.BorderSizePixel = 0 bl.Parent = tr bl.ZIndex = 14 corner(bl, 9)
    local gw = Instance.new("Frame") gw.Size = UDim2.new(0, 28, 0, 28) gw.Position = UDim2.new(0.5, -14, 0.5, -14) gw.BackgroundColor3 = C.Cyan gw.BackgroundTransparency = 1 gw.BorderSizePixel = 0 gw.Parent = bl gw.ZIndex = 13 corner(gw, 14)
    local st = def or false
    local function set(v, ins)
        st = v local bp = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) local tc = v and C.On or C.Off local gt = v and 0.55 or 1
        if ins then bl.Position = bp tr.BackgroundColor3 = tc gw.BackgroundTransparency = gt
        else TweenService:Create(bl, TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = bp}):Play() TweenService:Create(tr, TweenInfo.new(0.3), {BackgroundColor3 = tc}):Play() TweenService:Create(gw, TweenInfo.new(0.3), {BackgroundTransparency = gt}):Play() end
        if cb then cb(v) end
    end
    local hb = Instance.new("TextButton") hb.Size = UDim2.new(0, 64, 0, 40) hb.Position = UDim2.new(1, -56, 0.5, -20) hb.BackgroundTransparency = 1 hb.Text = "" hb.Parent = f hb.ZIndex = 15
    hb.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then set(not st) end end)
    set(st, true) return {set = set, get = function() return st end}
end

local function sld(par, y, txt, mn, mx, df, dc, sf, cb)
    local f = Instance.new("Frame") f.Size = UDim2.new(1, -16, 0, 55) f.Position = UDim2.new(0, 8, 0, y) f.BackgroundTransparency = 1 f.BorderSizePixel = 0 f.Parent = par f.ZIndex = 12
    local tr = Instance.new("Frame") tr.Size = UDim2.new(1, 0, 0, 18) tr.BackgroundTransparency = 1 tr.BorderSizePixel = 0 tr.Parent = f
    local lb = Instance.new("TextLabel") lb.Size = UDim2.new(0.5, 0, 1, 0) lb.BackgroundTransparency = 1 lb.Font = Enum.Font.Gotham lb.TextSize = 11 lb.TextColor3 = C.White lb.Text = txt lb.TextXAlignment = Enum.TextXAlignment.Left lb.Parent = tr
    local vl = Instance.new("TextLabel") vl.Size = UDim2.new(0.5, 0, 1, 0) vl.BackgroundTransparency = 1 vl.Font = Enum.Font.GothamBold vl.TextSize = 11 vl.TextColor3 = C.Cyan vl.Text = tostring(df)..(sf or "") vl.TextXAlignment = Enum.TextXAlignment.Right vl.Parent = tr
    local ta = Instance.new("Frame") ta.Size = UDim2.new(1, 0, 0, 28) ta.Position = UDim2.new(0, 0, 0, 22) ta.BackgroundTransparency = 1 ta.BorderSizePixel = 0 ta.Parent = f
    local tk = Instance.new("Frame") tk.Size = UDim2.new(1, 0, 0, 4) tk.Position = UDim2.new(0, 0, 0.5, -2) tk.BackgroundColor3 = C.Track tk.BorderSizePixel = 0 tk.Parent = ta corner(tk, 2)
    local fl = Instance.new("Frame") fl.Size = UDim2.new((df-mn)/(mx-mn), 0, 1, 0) fl.BackgroundColor3 = C.Fill fl.BorderSizePixel = 0 fl.Parent = tk corner(fl, 2)
    local kn = Instance.new("Frame") kn.Size = UDim2.new(0, 16, 0, 16) kn.Position = UDim2.new((df-mn)/(mx-mn), -8, 0.5, -8) kn.BackgroundColor3 = C.White kn.BorderSizePixel = 0 kn.Parent = tk kn.ZIndex = 14 corner(kn, 8)
    local kg = Instance.new("Frame") kg.Size = UDim2.new(0, 24, 0, 24) kg.Position = UDim2.new(0.5, -12, 0.5, -12) kg.BackgroundColor3 = C.Cyan kg.BackgroundTransparency = 0.5 kg.BorderSizePixel = 0 kg.Parent = kn kg.ZIndex = 13 corner(kg, 12)
    local val, drg = df, false
    local function upd(inp)
        local taA = tk.AbsolutePosition.X local taW = tk.AbsoluteSize.X local rx = math.clamp(inp.Position.X - taA, 0, taW) local rt = rx/taW
        val = mn + (mx-mn)*rt if dc then val = round(val, dc) else val = math.floor(val) end
        fl.Size = UDim2.new(rt, 0, 1, 0) kn.Position = UDim2.new(rt, -8, 0.5, -8) vl.Text = tostring(val)..(sf or "")
        if cb then cb(val) end
    end
    ta.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drg = true upd(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drg = false end end)
    UserInputService.InputChanged:Connect(function(i) if drg and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then upd(i) end end)
    return {get = function() return val end}
end

local function btn(par, y, txt, clr, cb)
    local b = Instance.new("TextButton") b.Size = UDim2.new(1, -16, 0, 38) b.Position = UDim2.new(0, 8, 0, y) b.BackgroundColor3 = clr or C.Cyan b.BackgroundTransparency = 0.6 b.BorderSizePixel = 0 b.Font = Enum.Font.GothamBold b.TextSize = 13 b.TextColor3 = C.White b.Text = txt b.Parent = par b.ZIndex = 12 corner(b, 10) stroke(b, clr or C.Cyan, 1, 0.3)
    b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency = 0.35}):Play() end end)
    b.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play() if cb then cb() end end end)
    return b
end

local function sec(par, y, txt)
    local f = Instance.new("Frame") f.Size = UDim2.new(1, -16, 0, 20) f.Position = UDim2.new(0, 8, 0, y) f.BackgroundTransparency = 1 f.BorderSizePixel = 0 f.Parent = par f.ZIndex = 12
    local l = Instance.new("TextLabel") l.Size = UDim2.new(0, 0, 1, 0) l.BackgroundTransparency = 1 l.Font = Enum.Font.GothamBold l.TextSize = 10 l.TextColor3 = C.Cyan l.Text = txt:upper() l.TextXAlignment = Enum.TextXAlignment.Left l.AutomaticSize = Enum.AutomaticSize.X l.Parent = f
    return f
end
local SG = Instance.new("ScreenGui") SG.Name = "PHANTOM" SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling SG.Parent = GUI
syn.protect_gui and syn.protect_gui(SG)

local Main = Instance.new("Frame") Main.Size = UDim2.new(0, 330, 0, 480) Main.Position = UDim2.new(0.5, -165, 0.5, -240) Main.BackgroundColor3 = C.Glass Main.BackgroundTransparency = 0.3 Main.BorderSizePixel = 0 Main.Parent = SG Main.ZIndex = 100 corner(Main, 16) stroke(Main, C.GlassB, 1.5, 0.35)
local blur = Instance.new("Frame") blur.Size = UDim2.new(1, 0, 1, 0) blur.BackgroundColor3 = C.BG blur.BackgroundTransparency = 0.85 blur.BorderSizePixel = 0 blur.Parent = Main blur.ZIndex = 1 corner(blur, 16)
local Title = Instance.new("Frame") Title.Size = UDim2.new(1, 0, 0, 40) Title.BackgroundTransparency = 1 Title.BorderSizePixel = 0 Title.Parent = Main Title.ZIndex = 110
local Tt = Instance.new("TextLabel") Tt.Size = UDim2.new(1, -36, 1, 0) Tt.Position = UDim2.new(0, 14, 0, 0) Tt.BackgroundTransparency = 1 Tt.Font = Enum.Font.GothamBlack Tt.TextSize = 15 Tt.TextColor3 = C.White Tt.Text = "PHANTOM" Tt.TextXAlignment = Enum.TextXAlignment.Left Tt.Parent = Title

local HideBtn = Instance.new("TextButton") HideBtn.Size = UDim2.new(0, 30, 0, 30) HideBtn.Position = UDim2.new(1, -36, 0, 5) HideBtn.BackgroundColor3 = C.Glass HideBtn.BackgroundTransparency = 0.5 HideBtn.Text = "▲" HideBtn.Font = Enum.Font.GothamBold HideBtn.TextSize = 12 HideBtn.TextColor3 = C.White HideBtn.BorderSizePixel = 0 HideBtn.Parent = Title HideBtn.ZIndex = 111 corner(HideBtn, 15) stroke(HideBtn, C.Cyan, 1, 0.3)

local ToggleBtn = Instance.new("TextButton") ToggleBtn.Size = UDim2.new(0, 44, 0, 44) ToggleBtn.Position = UDim2.new(0, 10, 0.5, -20) ToggleBtn.BackgroundColor3 = C.Cyan ToggleBtn.BackgroundTransparency = 0.35 ToggleBtn.Text = "☰" ToggleBtn.Font = Enum.Font.GothamBlack ToggleBtn.TextSize = 18 ToggleBtn.TextColor3 = C.White ToggleBtn.BorderSizePixel = 0 ToggleBtn.Parent = SG ToggleBtn.ZIndex = 999 ToggleBtn.Visible = false corner(ToggleBtn, 22) stroke(ToggleBtn, C.White, 2, 0.2)

HideBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then CFG.MenuOn = false Main.Visible = false ToggleBtn.Visible = true TweenService:Create(ToggleBtn, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0, 10, 0.5, -20), Size = UDim2.new(0, 44, 0, 44)}):Play() end end)
ToggleBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then CFG.MenuOn = true Main.Visible = true ToggleBtn.Visible = false Main.Position = UDim2.new(0.5, -165, 0.5, -240) end end)

local Tabs = Instance.new("Frame") Tabs.Size = UDim2.new(1, 0, 0, 44) Tabs.Position = UDim2.new(0, 0, 1, -44) Tabs.BackgroundColor3 = C.Glass Tabs.BackgroundTransparency = 0.5 Tabs.BorderSizePixel = 0 Tabs.Parent = Main Tabs.ZIndex = 105 corner(Tabs, 16)
local TabNames = {"AIM", "ESP", "MOVE", "CFG"} local TabIcons = {"⌖", "◉", "☁", "⚙"}
local TabBtns, Pages = {}, {}
local Content = Instance.new("Frame") Content.Size = UDim2.new(1, 0, 1, -84) Content.Position = UDim2.new(0, 0, 0, 40) Content.BackgroundTransparency = 1 Content.BorderSizePixel = 0 Content.Parent = Main Content.ZIndex = 102

for i = 1, 4 do
    local tb = Instance.new("TextButton") tb.Size = UDim2.new(0.25, -4, 1, -6) tb.Position = UDim2.new((i-1)*0.25, 2, 0, 3) tb.BackgroundColor3 = i==1 and C.Cyan or C.Glass tb.BackgroundTransparency = i==1 and 0.5 or 0.7 tb.Text = TabIcons[i].."\n"..TabNames[i] tb.Font = Enum.Font.GothamBold tb.TextSize = 9 tb.TextColor3 = i==1 and C.White or C.Gray tb.BorderSizePixel = 0 tb.Parent = Tabs tb.ZIndex = 106 corner(tb, 10) TabBtns[i] = tb
    local pg = Instance.new("ScrollingFrame") pg.Size = UDim2.new(1, 0, 1, 0) pg.BackgroundTransparency = 1 pg.BorderSizePixel = 0 pg.ScrollBarThickness = 2 pg.ScrollBarImageColor3 = C.Cyan pg.ScrollBarImageTransparency = 0.5 pg.Visible = (i==1) pg.Parent = Content pg.ZIndex = 103 pg.CanvasSize = UDim2.new(0, 0, 0, 600) Pages[i] = pg
    local idx = i
    tb.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then CFG.Tab = idx for j = 1, 4 do Pages[j].Visible = (j==idx) TabBtns[j].BackgroundColor3 = j==idx and C.Cyan or C.Glass TabBtns[j].BackgroundTransparency = j==idx and 0.5 or 0.7 TabBtns[j].TextColor3 = j==idx and C.White or C.Gray pcall(function() TabBtns[j]:FindFirstChildOfClass("UIStroke"):Destroy() end) if j==idx then stroke(TabBtns[j], C.Cyan, 1, 0.3) end end end end)
end

local p1, y1 = Pages[1], 8
sec(p1, y1, "Aimbot") y1 = y1 + 24
tgl(p1, y1, "Enable Aimbot", false, function(v) CFG.AimOn = v if v then AIM.start() else AIM.stop() end end) y1 = y1 + 44
sld(p1, y1, "Smoothness", 1, 20, 5, 0, "", function(v) CFG.AimSmooth = v end) y1 = y1 + 58
sld(p1, y1, "FOV Radius", 30, 360, 120, 0, "px", function(v) CFG.AimFOV = v end) y1 = y1 + 58
sec(p1, y1, "Filters") y1 = y1 + 24
tgl(p1, y1, "Team Check", false, function(v) CFG.TeamCheck = v end) y1 = y1 + 44
tgl(p1, y1, "Wall Check", false, function(v) CFG.WallCheck = v end) y1 = y1 + 44
tgl(p1, y1, "Auto Shoot", false, function(v) CFG.AutoShoot = v end) y1 = y1 + 44
sld(p1, y1, "Shoot Delay", 0.1, 2, 0.3, 1, "s", function(v) CFG.ShootDelay = v end) y1 = y1 + 58
Pages[1].CanvasSize = UDim2.new(0, 0, 0, y1 + 60)

local p2, y2 = Pages[2], 8
sec(p2, y2, "Player ESP") y2 = y2 + 24
tgl(p2, y2, "Enable ESP", true, function(v) CFG.ESPOn = v ESP.update() end) y2 = y2 + 44
tgl(p2, y2, "Name", true, function(v) CFG.ESPName = v ESP.update() end) y2 = y2 + 44
tgl(p2, y2, "Distance", true, function(v) CFG.ESPDist = v ESP.update() end) y2 = y2 + 44
tgl(p2, y2, "Health Bar", true, function(v) CFG.ESPHP = v ESP.update() end) y2 = y2 + 44
tgl(p2, y2, "Role", true, function(v) CFG.ESPRole = v ESP.update() end) y2 = y2 + 44
tgl(p2, y2, "Chams", false, function(v) CFG.ESPChams = v ESP.update() end) y2 = y2 + 48
sec(p2, y2, "Item ESP") y2 = y2 + 24
tgl(p2, y2, "Coins", true, function(v) CFG.ESPCoins = v ESP.update() end) y2 = y2 + 44
tgl(p2, y2, "Weapons", false, function(v) CFG.ESPGuns = v ESP.update() end) y2 = y2 + 44
sld(p2, y2, "Max Distance", 50, 500, 300, 0, "m", function(v) CFG.ESPDistMax = v ESP.update() end) y2 = y2 + 58
Pages[2].CanvasSize = UDim2.new(0, 0, 0, y2 + 60)

local p3, y3 = Pages[3], 8
sec(p3, y3, "Speed & Jump") y3 = y3 + 24
sld(p3, y3, "Walk Speed", 16, 200, 16, 0, "", function(v) CFG.Speed = v MOVE.speed(v) end) y3 = y3 + 58
sld(p3, y3, "Jump Power", 50, 500, 50, 0, "", function(v) CFG.Jump = v MOVE.jump(v) end) y3 = y3 + 58
sec(p3, y3, "Hacks") y3 = y3 + 24
tgl(p3, y3, "Fly", false, function(v) CFG.Fly = v if v then MOVE.flyOn() else MOVE.flyOff() end end) y3 = y3 + 44
tgl(p3, y3, "NoClip", false, function(v) CFG.NoClip = v if v then MOVE.noclipOn() else MOVE.noclipOff() end end) y3 = y3 + 44
tgl(p3, y3, "Infinite Jump", false, function(v) CFG.InfJump = v end) y3 = y3 + 48
Pages[3].CanvasSize = UDim2.new(0, 0, 0, y3 + 60)

local p4, y4 = Pages[4], 8
sec(p4, y4, "Settings") y4 = y4 + 24
btn(p4, y4, "Refresh ESP", C.Cyan, function() ESP.clear() ESP.update() end) y4 = y4 + 46
btn(p4, y4, "Reset All", C.Purple, function() CFG.AimOn = false AIM.stop() CFG.Fly = false MOVE.flyOff() CFG.NoClip = false MOVE.noclipOff() ESP.clear() ESP.update() MOVE.speed(16) MOVE.jump(50) end) y4 = y4 + 46
sec(p4, y4, "Unload") y4 = y4 + 24
btn(p4, y4, "UNLOAD PHANTOM", C.Red, function() CFG.AimOn = false AIM.stop() CFG.Fly = false MOVE.flyOff() CFG.NoClip = false MOVE.noclipOff() ESP.clear() MOVE.speed(16) MOVE.jump(50) MOVE.noclipOff() SG:Destroy() end) y4 = y4 + 46
Pages[4].CanvasSize = UDim2.new(0, 0, 0, y4 + 60)

local drg, ds, sp = false, nil, nil
Title.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drg = true ds = i.Position sp = Main.Position end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then drg = false end end)
UserInputService.InputChanged:Connect(function(i) if drg and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then local d = i.Position - ds Main.Position = UDim2.new(0, sp.X.Offset + d.X, 0, sp.Y.Offset + d.Y) end end)

ESP.update() MOVE.speed(16) MOVE.jump(50)
RunService.Heartbeat:Connect(function() ESP.update() end)
RunService.Heartbeat:Connect(function() if CFG.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and UserInputService:IsKeyDown(Enum.KeyCode.Space) then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
RunService.Stepped:Connect(function() if CFG.NoClip and LocalPlayer.Character then for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)

Main.Visible = true
Main.Position = UDim2.new(0.5, -165, 0.5, -240)
ToggleBtn.Visible = false
CFG.MenuOn = true

print("PHANTOM MM2 • Loaded • Tap ▲ to hide, tap ☰ to show")
