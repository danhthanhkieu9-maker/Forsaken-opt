local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- 1. BYPASS ANTI-CHEAT & ÉP ĐỒ HỌA XUỐNG ĐÁY
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
    
    settings().Rendering.QualityLevel = 1
    UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    Workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
    Lighting.GlobalShadows = false
end)

-- 2. DỌN SẠCH MAP (CHỈ CHẠY 1 LẦN ONE-SHOT)
local function cleanMap(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") or obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("PostEffect") then
            obj:Destroy()
        end
    end)
end
for _, v in ipairs(Workspace:GetDescendants()) do cleanMap(v) end
for _, v in ipairs(Lighting:GetChildren()) do cleanMap(v) end

-- 3. HỆ THỐNG ANTI-KILLER (HỦY DIỆT HIỆU ỨNG CHIÊU THỨC)
local function destroyKillerEffects(obj)
    pcall(function()
        -- Tắt các hạt bụi, lửa, vệt kiếm chém, tia sáng làm khựng GPU
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Explosion") or obj:IsA("Smoke") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Sparkles") then
            obj.Enabled = false
            obj:Destroy()
            
        -- Xóa nguồn sáng phát ra từ skill
        elseif obj:IsA("PointLight") or obj:IsA("SurfaceLight") or obj:IsA("SpotLight") then
            obj.Enabled = false
            obj:Destroy()
            
        -- Ép các chiêu thức phát sáng (Neon, ForceField) thành nhựa nhám chống tụt FPS
        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
            if obj.Material == Enum.Material.Neon or obj.Material == Enum.Material.ForceField or obj.Material == Enum.Material.Glass then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Transparency = 0.5 -- Làm mờ chiêu thức đi để bạn vẫn thấy đường né
            end
            
        -- Tắt âm thanh chiêu (Chip Tab A7 Lite xử lý âm thanh 3D dồn dập rất dễ bị đơ máy)
        elseif obj:IsA("Sound") then
            obj:Stop()
            obj:Destroy()
        end
    end)
end

-- Bắt ngay lập tức khi Killer văng chiêu ra ngoài môi trường
Workspace.DescendantAdded:Connect(function(obj)
    -- Chỉ lọc đúng hiệu ứng, không bắt CPU phải quét các khối gạch đá tĩnh để chống giật
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Sound") or obj:IsA("Light") then
        destroyKillerEffects(obj)
    end
end)

-- Quét âm thầm vũ khí và hào quang trên người Killer/Player (Mỗi 1.5 giây - Rất nhẹ CPU)
task.spawn(function()
    while task.wait(1.5) do
        -- Quét người chơi khác
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, obj in ipairs(p.Character:GetDescendants()) do
                    destroyKillerEffects(obj)
                end
            end
        end
        -- Quét NPC/Killer (Forsaken spawn Killer dưới dạng Model có Humanoid trong Workspace)
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                for _, child in ipairs(obj:GetDescendants()) do
                    destroyKillerEffects(child)
                end
            end
        end
    end
end)

print("Đã bật Anti-Killer: Loại bỏ mọi hiệu ứng skill gây drop FPS!")
