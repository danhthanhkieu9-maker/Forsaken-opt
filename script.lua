local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ==========================================
-- PHẦN 1: GUI FPS (KÉO THẢ & PHÓNG TO THU NHỎ)
-- ==========================================
local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild("ForsakenFPSGui") then
    parentGui.ForsakenFPSGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", parentGui)
ScreenGui.Name = "ForsakenFPSGui"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 140, 0, 35)
MainFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(100, 100, 100)

local UIScale = Instance.new("UIScale", MainFrame)

local FPSLabel = Instance.new("TextLabel", MainFrame)
FPSLabel.Size = UDim2.new(1, -55, 1, 0)
FPSLabel.Position = UDim2.new(0, 10, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.Text = "FPS: 60"
FPSLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
FPSLabel.TextSize = 14
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Nút phóng to / thu nhỏ GUI
local function createButton(text, xOffset, isPlus)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.Position = UDim2.new(1, xOffset, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        UIScale.Scale = math.clamp(UIScale.Scale + (isPlus and 0.15 or -0.15), 0.5, 2.5)
    end)
end
createButton("-", -50, false)
createButton("+", -25, true)

-- Logic Kéo Thả GUI
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Cập nhật FPS
local frameCount, lastUpdate = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastUpdate >= 0.25 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSLabel.Text = "FPS: " .. fps
        FPSLabel.TextColor3 = fps >= 45 and Color3.fromRGB(85, 255, 127) or (fps >= 25 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 80, 80))
        frameCount, lastUpdate = 0, now
    end
end)

-- ==========================================
-- PHẦN 2: DIỆT HIỆU ỨNG SKILL, LỬA & BÓNG ĐỔ
-- ==========================================
Lighting.GlobalShadows = false -- Tắt toàn bộ bóng đổ mặt trời

local function killEffects(obj)
    pcall(function()
        -- Xóa mọi loại hiệu ứng hạt, chiêu thức, ngọn lửa, vụ nổ, khói
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
            obj.Enabled = false
            obj:Destroy()
        
        -- Tắt bóng đổ của từng khối vật thể
        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
        
        -- Xóa các lớp filter hậu kỳ làm nặng máy
        elseif obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
            obj:Destroy()
        end
    end)
end

-- Quét toàn bộ map hiện tại
for _, v in ipairs(Workspace:GetDescendants()) do killEffects(v) end
for _, v in ipairs(Lighting:GetChildren()) do killEffects(v) end

-- Quét tự động: Bất cứ khi nào Killer tung chiêu tạo hiệu ứng mới, lập tức xóa sổ
Workspace.DescendantAdded:Connect(function(obj)
    killEffects(obj)
end)

-- ==========================================
-- PHẦN 3: GIỚI HẠN TẦM NHÌN (CHỐNG LAG MAP)
-- ==========================================
local RENDER_DISTANCE = 110 -- Giới hạn tầm nhìn (studs)
pcall(function()
    Lighting.FogColor = Color3.fromRGB(15, 15, 15)
    Lighting.FogStart = RENDER_DISTANCE * 0.4
    Lighting.FogEnd = RENDER_DISTANCE
end)

local mapParts = {}

-- Lưu dữ liệu map tĩnh, BỎ QUA nhân vật/skin
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Anchored then
        local isCharacter = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and obj:IsDescendantOf(p.Character) then
                isCharacter = true
                break
            end
        end
        if not isCharacter then
            table.insert(mapParts, { part = obj, origTrans = obj.Transparency })
        end
    end
end

local totalParts = #mapParts
local partsPerFrame = 200
local currentIndex = 1

RunService.Heartbeat:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or totalParts == 0 then return end
    
    local rootPos = root.Position
    
    for i = currentIndex, math.min(currentIndex + partsPerFrame - 1, totalParts) do
        local data = mapParts[i]
        local part = data.part
        
        if part and part.Parent then
            if (part.Position - rootPos).Magnitude > RENDER_DISTANCE then
                part.Transparency = 1 -- Ẩn tàng hình khi ở xa
            else
                part.Transparency = data.origTrans -- Hiện lại khi tới gần
            end
        end
    end
    
    currentIndex = currentIndex + partsPerFrame
    if currentIndex > totalParts then currentIndex = 1 end
end)

print("Đã tải: GUI FPS + Xóa Hiệu Ứng/Bóng Đổ + Render Distance!")
