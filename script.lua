local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local player = Players.LocalPlayer
local RENDER_DISTANCE = 100 -- Giảm thêm tầm nhìn xuống 100 studs để máy cực nhẹ

-- ==========================================
-- PHẦN 1: BYPASS & GUI FPS (Cực nhẹ)
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
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(80, 80, 80)

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
-- PHẦN 2: TỐI ƯU HÓA CỰC ĐỘ (DIỆT TEXTURE, RÁC)
-- ==========================================
pcall(function()
    Lighting.GlobalShadows, Lighting.Brightness = false, 1
    if Terrain then Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance, Terrain.Decoration = 0, 0, 0, false end
    sethiddenproperty(Lighting, "Technology", 2) -- Ép xuống đồ họa thấp nhất nếu có thể
end)

local mapParts = {}

-- Kiểm tra xem vật thể có phải của nhân vật/Skin không
local function isCharacter(obj)
    if obj.Name == "Humanoid" or obj.Name == "HumanoidRootPart" or obj:IsA("Accessory") or obj:IsA("Clothing") or obj:IsA("Shirt") or obj:IsA("Pants") then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then return true end
    end
    return false
end

local function brutalOptimize(obj)
    pcall(function()
        if isCharacter(obj) then return end -- BẢO VỆ NHÂN VẬT TUYỆT ĐỐI

        -- Xóa cỏ, lá, rác vụn nhẹ
        local name = obj.Name:lower()
        if name:find("grass") or name:find("bush") or name:find("leaf") or name:find("debris") then obj:Destroy() return end

        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance, obj.CastShadow = 0, false
            if obj:IsA("MeshPart") then obj.TextureID = "" end
            
            -- Đăng ký vào mảng tàng hình nếu là phần tử tĩnh của map
            if obj.Anchored then
                local oT = obj:GetAttribute("OrigTrans")
                if not oT then oT = obj.Transparency obj:SetAttribute("OrigTrans", oT) end
                table.insert(mapParts, { part = obj, origTrans = oT })
            end

        -- Hủy diệt Texture, Decal (Tranh ảnh, vân dán làm nặng RAM)
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        
        -- Hủy diệt mọi loại hiệu ứng
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
            obj.Enabled = false
            obj:Destroy()
            
        -- Xóa sương mù, filter, ánh sáng thừa
        elseif obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
            obj:Destroy()
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled, obj.Shadows = false, false
        end
    end)
end

-- Quét 1 lần toàn bộ Map
for _, v in ipairs(Workspace:GetDescendants()) do brutalOptimize(v) end
for _, v in ipairs(Lighting:GetChildren()) do brutalOptimize(v) end

-- Quét tự động vật thể sinh ra sau (Load map mới, Skill mới)
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.05) -- Đợi xíu để load xong
    if obj and obj.Parent then brutalOptimize(obj) end
end)
Lighting.ChildAdded:Connect(function(obj) task.wait(0.05) if obj and obj.Parent then brutalOptimize(obj) end end)

-- Quét dọn tàn dư ngầm mỗi 10 giây (Tránh rò rỉ bộ nhớ RAM)
task.spawn(function()
    while task.wait(10) do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Explosion") then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end)

-- ==========================================
-- PHẦN 3: CULLING (TÀNG HÌNH Ở XA) - TIẾT KIỆM CPU
-- ==========================================
pcall(function()
    Lighting.FogColor = Color3.fromRGB(12, 12, 12)
    Lighting.FogStart = RENDER_DISTANCE * 0.3
    Lighting.FogEnd = RENDER_DISTANCE
end)

-- Thu dọn mảng map khi đổi map
task.spawn(function()
    while task.wait(15) do
        local newMapParts = {}
        for _, data in ipairs(mapParts) do
            if data.part and data.part.Parent then table.insert(newMapParts, data) end
        end
        mapParts = newMapParts
    end
end)

-- Giới hạn tầm nhìn (Chạy nhẹ nhàng 15 khung hình/giây thay vì 60fps để tiết kiệm CPU cho Tab A7)
task.spawn(function()
    while task.wait(0.06) do -- ~15 FPS vòng lặp (vừa đủ mượt mà cực nhẹ)
        local totalParts = #mapParts
        if totalParts > 0 then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local rootPos = root.Position
                for i = 1, totalParts do
                    local data = mapParts[i]
                    local part = data.part
                    if part and part.Parent then
                        -- Tàng hình ở xa, hiện lại khi gần
                        if (part.Position - rootPos).Magnitude > RENDER_DISTANCE then
                            if part.Transparency ~= 1 then part.Transparency = 1 end
                        else
                            if part.Transparency ~= data.origTrans then part.Transparency = data.origTrans end
                        end
                    end
                end
            end
        end
    end
end)

print("Đã tải chế độ Ultra Potato Max FPS - Bảo vệ 100% Skin & Hitbox!")
