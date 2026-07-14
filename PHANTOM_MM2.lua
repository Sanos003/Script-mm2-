local SG = Instance.new("ScreenGui")
SG.Name = "TEST"
SG.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 400)
Main.Position = UDim2.new(0.5, -150, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
Main.BorderSizePixel = 0
Main.Parent = SG

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = Main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "PHANTOM TEST"
title.Parent = Main

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -40, 0, 40)
btn.Position = UDim2.new(0, 20, 0, 60)
btn.BackgroundColor3 = Color3.fromRGB(0, 212, 255)
btn.Text = "CLOSE"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.BorderSizePixel = 0
btn.Parent = Main
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 10)
bc.Parent = btn

btn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        Main.Visible = false
    end
end)

print("TEST MENU LOADED")
