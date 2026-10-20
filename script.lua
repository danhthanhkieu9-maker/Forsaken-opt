local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- 1. BYPASS ANTI-CHEAT CƠ BẢN
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

-- 2. ÉP ĐỒ HỌA MỨC ĐÁY & TẮT TÍNH TOÁN VẬT LÝ THỪA
pcall(function()
    settings().Rendering.QualityLevel = 1
    UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    Workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
    Lighting.GlobalShadows = false
end)

-- 3. HÀM DỌN RÁC 1 CHẠM (Không phân biệt nhân vật vì chỉ xóa texture/chất liệu)
local function oneShotClean(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") or obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Explosion") or obj:IsA("Smoke") or obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
            obj:Destroy()
        end
    end)
end

-- 4. QUÉT SẠCH MAP HIỆN TẠI (CHỈ CHẠY 1 LẦN RỒI DỪNG)
for _, v in ipairs(Workspace:GetDescendants()) do oneShotClean(v) end
for _, v in ipairs(Lighting:GetChildren()) do oneShotClean(v) end

-- 5. BẮT HIỆU ỨNG KHI KILLER XÀI CHIÊU (Chỉ xóa, không tính toán)
Workspace.DescendantAdded:Connect(function(obj)
    pcall(function()
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Explosion") then
            obj.Enabled = false
            obj:Destroy()
        end
    end)
end)

print("One-Shot Optimized: Đã trả lại 100% CPU cho máy!")
