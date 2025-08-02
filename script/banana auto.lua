local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local sellPos = Vector3.new(2841.57, 14.14, 2081.41)
local bananaJobPos = Vector3.new(68.93, 13.98, -357.19)
local buyPos = Vector3.new(3044.65, 14.41, 1912.99)

local ui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ui.Name = "BananaTracker"

-- Label แสดงกล้วย + เงิน
local label = Instance.new("TextLabel", ui)
label.Size = UDim2.new(0, 280, 0, 30)
label.Position = UDim2.new(0.5, -140, 1, -45)
label.BackgroundTransparency = 0.2
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BorderSizePixel = 1
label.BorderColor3 = Color3.fromRGB(255, 255, 0)
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.Text = "🍌 กำลังโหลด..."

-- ปุ่มเริ่มทำงาน
local startBtn = Instance.new("TextButton", ui)
startBtn.Size = UDim2.new(0, 140, 0, 30)
startBtn.Position = UDim2.new(0, 10, 1, -40)
startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
startBtn.TextColor3 = Color3.new(1, 1, 1)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14
startBtn.Text = "▶️ เริ่มทำงาน 🍌"

-- ปุ่มซื้ออุปกรณ์
local buyBtn = Instance.new("TextButton", ui)
buyBtn.Size = UDim2.new(0, 140, 0, 30)
buyBtn.Position = UDim2.new(0, 160, 1, -40) -- ข้างๆ ปุ่มเริ่มทำงาน
buyBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
buyBtn.TextColor3 = Color3.new(1, 1, 1)
buyBtn.Font = Enum.Font.GothamBold
buyBtn.TextSize = 14
buyBtn.Text = "🛒 ซื้ออุปกรณ์"

local flying = false
local stopWorking = false

-- ฟังก์ชันบินแบบมุดดิน
local function flyUnderground(destination, onReached)
    if flying then return end
    flying = true

    local hrp = player.Character and player.Character:WaitForChild("HumanoidRootPart")
    if not hrp then flying = false return end

    local function noclip()
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    local undergroundStart = Vector3.new(hrp.Position.X, hrp.Position.Y - 10, hrp.Position.Z)
    local undergroundEnd = Vector3.new(destination.X, destination.Y - 10, destination.Z)

    hrp.CFrame = CFrame.new(undergroundStart)

    local conn
    conn = runService.Heartbeat:Connect(function()
        if not hrp then return end
        noclip()

        local dir = (undergroundEnd - hrp.Position).Unit
        local dist = (undergroundEnd - hrp.Position).Magnitude
        if dist > 5 then
            hrp.Velocity = dir * 200
        else
            hrp.Velocity = Vector3.zero
            conn:Disconnect()

            task.wait(0.1)
            hrp.CFrame = CFrame.new(destination)
            flying = false
            if onReached then onReached() end
        end
    end)
end

-- ฟังก์ชันยิง RemoteEvent เพื่อซื้อของ
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function fireRemote(action, item, amount)
    local event = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NetworkFramework"):WaitForChild("NetworkEvent")
    if event then
        local args = { [1] = "fire", [3] = action, [4] = item, [5] = amount }
        event:FireServer(unpack(args))
        print(string.format("ส่งคำสั่งซื้อ: %s %s x%s", action, item, tostring(amount)))
    else
        warn("ไม่พบ NetworkEvent!")
    end
end

local function buyItem(itemName, amount)
    fireRemote("Supermarket", itemName, amount)
end

-- ขายกล้วย
local function sellBananas()
    local args = {
        [1] = "fire",
        [3] = "Economy",
        [4] = "Banana",
        [5] = 60
    }
    replicated:WaitForChild("Modules"):WaitForChild("NetworkFramework"):WaitForChild("NetworkEvent"):FireServer(unpack(args))
    print(">> กล้วยถูกขายแล้ว")
end

-- กด Prompt เพื่อเก็บกล้วย
local function firePrompt()
    local prompt = workspace:FindFirstChild("AutoFarm")
        and workspace.AutoFarm:FindFirstChild("Banana")
        and workspace.AutoFarm.Banana:FindFirstChild("Point")
        and workspace.AutoFarm.Banana.Point:FindFirstChildOfClass("ProximityPrompt")

    if prompt then
        fireproximityprompt(prompt)
        print(">> เริ่มเก็บกล้วย")
    else
        warn("ไม่พบ ProximityPrompt ที่ตำแหน่งงานกล้วย")
    end
end

-- ใส่ลูกน้ำ
local function formatNumber(n)
    local formatted = tostring(n)
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- กดปุ่มเริ่มทำงานกล้วย
startBtn.MouseButton1Click:Connect(function()
    if flying or stopWorking then return end
    startBtn.Text = "⏳ กำลังไป..."
    flyUnderground(bananaJobPos, function()
        task.wait(0.5)
        firePrompt()
        startBtn.Text = "▶️ เริ่มทำงาน 🍌"
    end)
end)

-- กดปุ่มซื้ออุปกรณ์
buyBtn.MouseButton1Click:Connect(function()
    if flying then return end
    buyBtn.Text = "⏳ กำลังไปซื้อ..."
    flyUnderground(buyPos, function()
        -- ซื้อของหลังถึงตำแหน่ง
        buyItem("Fishingrod", 1)
        buyItem("Bait", 150)
        buyBtn.Text = "🛒 ซื้ออุปกรณ์"
    end)
end)

-- ตัวแปรหยุดทำงานเมื่อเงินถึง 30,000
stopWorking = false

-- ตรวจสอบกล้วย + เงิน แบบเรียลไทม์
task.spawn(function()
    while true do
        local gui = player.PlayerGui:FindFirstChild("Inventory")
        local canvas = gui and gui:FindFirstChild("CanvasGroup")
        local main = canvas and canvas:FindFirstChild("Main")
        local body = main and main:FindFirstChild("Body")

        local guiBanana = body and body:FindFirstChild("Banana") and body.Banana:FindFirstChild("Main") and body.Banana.Main:FindFirstChild("Amount")
        local guiCash = body and body:FindFirstChild("Cash") and body.Cash:FindFirstChild("Main") and body.Cash.Main:FindFirstChild("Amount")

        local bananaCount = 0
        local cashAmount = 0
        local bananaText, cashTextRaw

        if guiBanana and guiBanana:IsA("TextLabel") then
            bananaText = guiBanana.Text
            bananaCount = tonumber(string.match(bananaText, "%d+")) or 0
        end
        if guiCash and guiCash:IsA("TextLabel") then
            cashTextRaw = guiCash.Text:gsub(",", "")
            cashAmount = tonumber(cashTextRaw) or 0
        end

        -- อัปเดต UI
        if bananaText and cashTextRaw then
            label.Text = "🍌 กล้วย: " .. formatNumber(bananaCount) .. " / 60  |  💰 เงิน: " .. formatNumber(cashAmount) .. " ฿"
        elseif bananaText then
            label.Text = "🍌 กล้วย: " .. formatNumber(bananaCount) .. " / 60  |  💰 เงิน: ไม่พบข้อมูล"
        elseif cashTextRaw then
            label.Text = "🍌 กล้วย: ไม่พบข้อมูล  |  💰 เงิน: " .. formatNumber(cashAmount) .. " ฿"
        else
            label.Text = "🍌 กล้วย / 💰 เงิน: ไม่พบข้อมูล"
        end

        -- หยุดทำงานและไปตลาดเมื่อเงินถึง 30,000
        if not stopWorking and cashAmount >= 30000 and not flying then
            stopWorking = true
            startBtn.Text = "✅ หยุดทำงานแล้ว"
            flyUnderground(sellPos, function()
                print(">> เงินครบ 30,000 หยุดทำงานและไปตลาดแล้ว")
            end)
        end

        -- เก็บกล้วยถ้าครบ 60 และยังไม่หยุดทำงาน
        if not stopWorking and bananaCount == 60 and not flying then
            flyUnderground(sellPos, function()
                sellBananas()
                task.wait(1)
                flyUnderground(bananaJobPos, function()
                    task.wait(0.5)
                    firePrompt()
                end)
            end)
        end

        task.wait(1)
    end
end)
