local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "TeleportUI"

-- ปุ่มไอคอนเปิด/ปิด
local toggleButton = Instance.new("TextButton", gui)
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "≡"
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 24
toggleButton.ZIndex = 10

-- เฟรมหลักของเมนู
local Frame = Instance.new("Frame", gui)
Frame.Size = UDim2.new(0, 200, 0, 200)
Frame.Position = UDim2.new(0, 20, 0.5, -100)
Frame.BackgroundTransparency = 0.3
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Visible = true

-- ข้อมูลตำแหน่ง
local locations = {
    { name = "ตลาด", position = Vector3.new(2841.57, 14.14, 2081.41) },
    { name = "งานกล้วย", position = Vector3.new(68.93, 13.98, -357.19) },
    { name = "เหมือง", position = Vector3.new(-272.17, -91.58, -2064.60) },
    { name = "แปลหิน", position = Vector3.new(-1896.20, 13.20, 3201.24) },
}

-- สร้างปุ่มเทเลพอร์ต
local function createButton(name, position, order)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, 5 + (35 * (order - 1)))
    btn.Text = "ไปยัง: " .. name
    btn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0

    btn.MouseButton1Click:Connect(function()
        local hrp = player.Character and player.Character:WaitForChild("HumanoidRootPart")
        local RunService = game:GetService("RunService")
        local stopDistance = 5

        -- ฟังก์ชันทำให้ตัวละครทะลุทุกวัตถุ
        local function noclip()
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not hrp then return end
            noclip()  -- เรียกใช้ฟังก์ชัน noclip เพื่อทำให้ตัวละครทะลุวัตถุ

            local dir = (position - hrp.Position).Unit
            local dist = (position - hrp.Position).Magnitude
            if dist > stopDistance then
                hrp.Velocity = dir * 200 -- ความเร็วต่ำลงเพื่อไม่ให้กระเด็น
            else
                hrp.Velocity = Vector3.zero  -- หยุดทันที
                connection:Disconnect()
            end
        end)
    end)
end

-- สร้างปุ่มจาก locations
for i, loc in ipairs(locations) do
    createButton(loc.name, loc.position, i)
end

-- ปุ่มขายกล้วย
local sellButton = Instance.new("TextButton", Frame)
sellButton.Size = UDim2.new(1, -10, 0, 30)
sellButton.Position = UDim2.new(0, 5, 0, 5 + (35 * #locations))
sellButton.Text = "ขายกล้วย"
sellButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
sellButton.TextColor3 = Color3.new(1, 1, 1)
sellButton.Font = Enum.Font.GothamBold
sellButton.TextSize = 14
sellButton.BorderSizePixel = 0

sellButton.MouseButton1Click:Connect(function()
    -- ส่งคำสั่งขายกล้วยไปที่เซิร์ฟเวอร์
    local args = {
        [1] = "fire",
        [3] = "Economy",
        [4] = "Banana",
        [5] = 60
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NetworkFramework"):WaitForChild("NetworkEvent"):FireServer(unpack(args))
    print("Bananas sold!")  -- Debug: ข้อความยืนยันการขายกล้วย
end)

-- ระบบเปิด/ปิด UI
toggleButton.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
end)
