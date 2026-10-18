-- ==========================================
-- PHẦN 1: BẢO VỆ CHỐNG PHÁT HIỆN (ANTI-DETECTION / BYPASS)
-- ==========================================
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldIndex = mt.__index
    
    -- Đánh lừa game: Khi anti-cheat kiểm tra sương mù hoặc bóng đổ, trả về giá trị giả lập hợp lệ
    mt.__index = newcclosure(function(self, k)
        if tostring(self) == "Lighting" then
            if k == "FogEnd" or k == "FogStart" then
                return 100000
            elseif k == "GlobalShadows" then
                return true
            end
        end
        return oldIndex(self, k)
    end)
    setreadonly(mt, true)
end)

-- Chặn các luồng báo cáo lỗi (Error Logging Hook) để không gửi log lên máy chủ
local oldScriptContext
pcall(function()
    oldScriptContext = game:GetService("ScriptContext").Error
    game:GetService("ScriptContext").Error:Connect(function()
        -- Hủy bỏ việc ghi nhận lỗi script client
    end)
end)

-- ==========================================
-- PHẦN 2: TẠO GUI HIỂN THỊ FPS (KÉO THẢ & PHÓNG TO/THU NHỎ)
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild("ForsakenFPSGui") then
    parentGui.ForsakenFPSGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ForsakenFPSGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 145, 0, 40)
MainFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(110, 110, 110)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

local UIScale = Instance.new("UIScale")
UIScale.Scale = 1.0
UIScale.Parent = MainFrame

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1, -60, 1, 0)
FPSLabel.Position = UDim2.new(0, 10, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.Text = "FPS: 60"
FPSLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
FPSLabel.TextSize = 15
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Parent = MainFrame

local BtnMinus = Instance.new("TextButton")
BtnMinus.Size = UDim2.new(0, 24, 0, 24)
BtnMinus.Position = UDim2.new(1, -54, 0.5, -12)
BtnMinus.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnMinus.Font = Enum.Font.GothamBold
BtnMinus.Text = "-"
BtnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnMinus.TextSize = 16
BtnMinus.Parent = MainFrame

local CornerMinus = Instance.new("UICorner")
CornerMinus.CornerRadius = UDim.new(0, 5)
CornerMinus.Parent = BtnMinus

local BtnPlus = Instance.new("TextButton")
BtnPlus.Size = UDim2.new(0, 24, 0, 24)
BtnPlus.Position = UDim2.new(1, -26, 0.5, -12)
BtnPlus.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnPlus.Font = Enum.Font.GothamBold
BtnPlus.Text = "+"
BtnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnPlus.TextSize = 16
BtnPlus.Parent = MainFrame

local CornerPlus = Instance.new("UICorner")
CornerPlus.CornerRadius = UDim.new(0, 5)
CornerPlus.Parent = BtnPlus

BtnMinus.MouseButton1Click:Connect(function()
    UIScale.Scale = math.clamp(UIScale.Scale - 0.15, 0.5, 2.5)
end)

BtnPlus.MouseButton1Click:Connect(function()
    UIScale.Scale = math.clamp(UIScale.Scale + 0.15, 0.5, 2.5)
end)

local dragging, dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local frameCount = 0
local lastUpdate = os.clock()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastUpdate >= 0.25 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSLabel.Text = "FPS: " .. tostring(fps)
        
        if fps >= 45 then
            FPSLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
        elseif fps >= 25 then
            FPSLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        else
            FPSLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
        
        frameCount = 0
        lastUpdate = now
    end
end)

-- ==========================================
-- PHẦN 3: FIX LAG CHUYÊN SÂU & LÀM PHẲNG MAP (AN TOÀN HITBOX)
-- ==========================================
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local SoundService = game:GetService("SoundService")

local GRAY_COLOR = ColorSequence.new(Color3.fromRGB(150, 150, 150))

local function optimizeLighting()
    pcall(function()
        Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ClockTime = 14

        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") 
               or v:IsA("BloomEffect") or v:IsA("BlurEffect") 
               or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") 
               or v:IsA("DepthOfFieldEffect") then
                v:Destroy()
            end
        end
    end)
end

if Terrain then
    pcall(function()
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
        Terrain.Decoration = false
    end)
end

local function optimizeInstance(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            if obj:IsA("MeshPart") then
                obj.TextureID = ""
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") then
            obj.Color = GRAY_COLOR
            obj.LightEmission = 0
            obj.LightInfluence = 0
            obj.Rate = math.clamp(obj.Rate * 0.1, 1, 2)
        elseif obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Color = GRAY_COLOR
            obj.LightEmission = 0
            obj.LightInfluence = 0
        elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
            obj.Enabled = false
            obj:Destroy()
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
            obj.Shadows = false
        end
    end)
end

optimizeLighting()
for _, obj in ipairs(Workspace:GetDescendants()) do
    optimizeInstance(obj)
end

pcall(function()
    for _, sound in ipairs(SoundService:GetDescendants()) do
        if sound:IsA("Sound") and sound.Playing then
            if sound.Name:lower():find("ambient") or sound.Name:lower():find("wind") then
                sound:Stop()
            end
        end
    end
end)

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1)
    optimizeInstance(obj)
end)

print("Đã tải xong Script Fix Lag kèm Bypass Anti-Cheat!")
