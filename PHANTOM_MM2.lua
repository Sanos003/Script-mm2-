print("PHANTOM: START")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = workspace
local VIM = game:GetService("VirtualInputManager")

print("PHANTOM: Services loaded")

local GUI = nil
pcall(function() GUI = CoreGui end)
if not GUI then pcall(function() GUI = LocalPlayer.PlayerGui end) end
if not GUI then GUI = game:GetService("GuiService") end

print("PHANTOM: GUI parent = " .. GUI.ClassName)

-- Простое меню для проверки
local SG = Instance.new("ScreenGui")
SG.Name = "PHANTOM"
SG.Parent = GUI

print("PHANTOM: ScreenGui created")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 330, 0, 480)
Main.Position = UDim2.new(0.5, -165, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
Main.BackgroundTransparency = 0.3
Main.BorderSizePixel = 0
Main.Parent = SG

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = Main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "PHANTOM MM2"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Main

print("PHANTOM: MENU CREATED ✓")

-- ESP Test
local function updateESP()
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 200, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true
                bb.Parent = p.Character.Head
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 1, 0)
                l.BackgroundTransparency = 1
                l.Font = Enum.Font.GothamBold
                l.TextSize = 12
                l.TextColor3 = Color3.fromRGB(255, 255, 255)
                l.TextStrokeTransparency = 0.5
                l.Text = p.Name
                l.Parent = bb
            end
        end
    end)
end

updateESP()
print("PHANTOM: ESP UPDATED ✓")
print("PHANTOM: ALL DONE ✓✓✓")
