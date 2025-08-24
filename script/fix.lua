local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local hrp = player.Character and player.Character:WaitForChild("HumanoidRootPart")
local humanoid = player.Character and player.Character:WaitForChild("Humanoid")

local targetPos = Vector3.new(3552.52, 10.39, 2060.70)
local stopDistance = 5

-- ฟังก์ชันทำให้ตัวละครทะลุวัตถุ
local function noclip()
    for _, v in pairs(player.Character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end

local flying = false

local connection = RunService.Heartbeat:Connect(function()
    if not hrp or not humanoid then return end

    noclip()

    local dist = (hrp.Position - targetPos).Magnitude

    if dist <= stopDistance then
        hrp.Velocity = Vector3.new(0,0,0)
        flying = false
        humanoid.Jump = false
        connection:Disconnect()
        return
    end

    if hrp.Position.Y < -10 then
        humanoid.Jump = true
        flying = true
        local dir = (targetPos - hrp.Position).Unit
        hrp.Velocity = dir * 100 + Vector3.new(0,50,0) -- เพิ่มแรงขึ้นในแกน Y
    elseif flying then
        -- ถ้าเคยบินแต่ตอนนี้ Y ไม่ต่ำกว่า -10 แล้ว ก็แค่บินปกติ
        local dir = (targetPos - hrp.Position).Unit
        hrp.Velocity = dir * 100
    end
end)
