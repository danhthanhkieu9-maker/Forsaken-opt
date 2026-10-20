local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local RENDER_DISTANCE = 90 -- Ép tầm nhìn xuống 90 để cứu FPS

-- ==========================================
-- PHẦN 1: ÉP XUNG ENGINE & ĐỒ HỌA MỨC TỐI THIỂU
-- ==========================================
pcall(function()
    -- Ép Setting của Roblox về mức thấp nhất bằng script
    local userSettings = UserSettings():GetService("UserGameSettings")
    userSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    settings().Rendering.QualityLevel = 1
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 -- Lưới 3D vỡ hạt nhẹ nhất
    
    -- Tối ưu hóa tính toán vật lý (Chống Drop FPS khi Killer di chuyển)
    Workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
    if sethiddenproperty then
        sethiddenproperty(Lighting, "Technology", 2)
        sethiddenproperty(Workspace, "StreamingEnabled", true)
    end
end)

-- ==========================================
-- PHẦN 2: GUI FPS & BYPASS
-- ==========================================
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldIndex = mt.__index
    mt.__index = newcclosure(function(self, k)
        if tostring(self) == "Lighting" and (k == "FogEnd" or k == "FogStart") then return 100000 end
        if tostring(self) == "Lighting" and k == "GlobalShadows" then return true end
        return oldIndex(self, k)
    end)
    setreadonly(mt, true)
end)

local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild("ForsakenFPSGui") then parentGui.ForsakenFPSGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui", parentGui)
ScreenGui.Name = "ForsakenFPSGui"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size, MainFrame.Position = UDim2.new(0, 140, 0, 35), UDim2.new(0.02, 0, 0.12, 0)
MainFrame.BackgroundColor3, MainFrame.BackgroundTransparency = Color3.fromRGB(15, 15, 15), 0.3
MainFrame.BorderSizePixel, MainFrame.Active = 0, true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

local UIScale = Instance.new("UIScale", MainFrame)
local FPSLabel = Instance.new("TextLabel", MainFrame)
FPSLabel.Size, FPSLabel.Position = UDim2.new(1, -55, 1, 0), UDim2.new(0, 10, 0, 0)
FPSLabel.BackgroundTransparency, FPSLabel.Font = 1, Enum.Font.GothamBold
FPSLabel.Text, FPSLabel.TextColor3, FPSLabel.TextSize = "FPS: ...", Color3.fromRGB(85, 255, 127), 14
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

local function createBtn(txt, xOffset, isPlus)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size, btn.Position = UDim2.new(0, 22, 0, 22), UDim2.new(1, xOffset, 0.5, -11)
    btn.BackgroundColor3, btn.TextColor3 = Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 255, 255)
    btn.Font, btn.Text, btn.TextSize = Enum.Font.GothamBold, txt, 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function() UIScale.Scale = math.clamp(UIScale.Scale + (isPlus and 0.15 or -0.15), 0.5, 2.5) end)
end
createBtn("-", -50, false)
createBtn("+", -25, true)

-- Kéo thả GUI
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, inp.Position, MainFrame.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

local fc, lu = 0, os.clock()
RunService.RenderStepped:Connect(function()
    fc = fc + 1
    local now = os.clock()
    if now - lu >= 0.25 then
        local fps = math.floor(fc / (now - lu))
        FPSLabel.Text, FPSLabel.TextColor3 = "FPS: " .. fps, fps >= 45 and Color3.fromRGB(85, 255, 127) or (fps >= 25 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 80, 80))
        fc, lu = 0, now
    end
end)

-- ==========================================
-- PHẦN 3: DIỆT RÁC & TẮT BÓNG ĐỔ NHÂN VẬT
-- ==========================================
Lighting.GlobalShadows = false

local function isCharacter(obj)
    if obj.Name == "Humanoid" or obj.Name == "HumanoidRootPart" or obj:IsA("Accessory") or obj:IsA("Clothing") or obj:IsA("Shirt") or obj:IsA("Pants") then return true end
    if obj.Parent and obj.Parent:FindFirstChild("Humanoid") then return true end
    return false
end

-- Dọn rác 3 giây 1 lần + Tắt luôn bóng đổ của NGƯỜI CHƠI
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Explosion") then
                    obj.Enabled = false
                    obj:Destroy()
                elseif (obj:IsA("Decal") or obj:IsA("Texture")) and not isCharacter(obj) then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    -- Tắt luôn bóng đổ của nhân vật (Skin vẫn đẹp nhưng không đổ bóng xuống đất)
                    if obj.CastShadow then obj.CastShadow = false end
                end
            end
            
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
                    obj:Destroy()
                end
            end
        end)
    end
end)

-- ==========================================
-- PHẦN 4: TÀNG HÌNH Ở XA (CỰC NHẸ CHỐNG DROP)
-- ==========================================
pcall(function()
    Lighting.FogColor = Color3.fromRGB(10, 10, 10)
    Lighting.FogStart = RENDER_DISTANCE * 0.3
    Lighting.FogEnd = RENDER_DISTANCE
end)

local mapParts = {}

local function refreshMapCache()
    local newParts = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Anchored and not isCharacter(obj) then
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
            
            local oT = obj:GetAttribute("OrigTrans")
            if not oT then 
                oT = obj.Transparency 
                obj:SetAttribute("OrigTrans", oT) 
            end
            table.insert(newParts, { part = obj, origTrans = oT })
        end
    end
    mapParts = newParts
end

refreshMapCache()
task.spawn(function() while task.wait(10) do refreshMapCache() end end)

-- CHỈ 30 VẬT THỂ MỖI KHUNG HÌNH (Chống Drop FPS triệt để)
local currentIndex = 1
local PARTS_PER_FRAME = 30 

RunService.Heartbeat:Connect(function()
    local totalParts = #mapParts
    if totalParts == 0 then return end
    
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local rootPos = root.Position
    local endIdx = math.min(currentIndex + PARTS_PER_FRAME - 1, totalParts)
    
    for i = currentIndex, endIdx do
        local data = mapParts[i]
        local p = data.part
        if p and p.Parent then
            if (p.Position - rootPos).Magnitude > RENDER_DISTANCE then
                if p.Transparency ~= 1 then p.Transparency = 1 end
            else
                if p.Transparency ~= data.origTrans then p.Transparency = data.origTrans end
            end
        end
    end
    
    currentIndex = endIdx + 1
    if currentIndex > totalParts then currentIndex = 1 end
end)

print("Đã tải: Can thiệp Engine Roblox - Mức độ họa siêu nhẹ!")
