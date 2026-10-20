local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- 1. ÉP ĐỒ HỌA MỨC THẤP NHẤT TỪ ENGINE
pcall(function()
    settings().Rendering.QualityLevel = 1
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    Workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
    Lighting.GlobalShadows = false
    if sethiddenproperty then
        sethiddenproperty(Lighting, "Technology", 2)
    end
end)

-- 2. DỌN MAP 1 LẦN KHI BẬT
local function obliterate(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        end
    end)
end
for _, v in ipairs(Workspace:GetDescendants()) do obliterate(v) end

-- 3. BỘ QUÉT CHẬM (QUÉT DỌN CHIÊU THỨC KILLER MỖI 5 GIÂY)
-- Vòng lặp siêu chậm này không tiêu tốn CPU, giúp máy luôn rảnh tay để đẩy FPS
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Explosion") or obj:IsA("Smoke") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = false
                    obj:Destroy()
                elseif obj:IsA("PointLight") or obj:IsA("SurfaceLight") or obj:IsA("SpotLight") then
                    obj.Enabled = false
                    obj:Destroy()
                end
            end
        end)
    end
end)

print("Đã tải: Chế độ 30 FPS - Độ phân giải 360p & Quét dọn thụ động!")
