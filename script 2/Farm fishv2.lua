local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Network = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NetworkFramework"))
local UserInputService = game:GetService("UserInputService") -- Added for completeness, though not explicitly used in main logic

math.randomseed(tick())
math.random(); math.random(); math.random()

--- ระบบแจ้งเตือน (Notification System)
local function createNotifySystem()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugNotifySystem"
    screenGui.DisplayOrder = 999 -- ทำให้แน่ใจว่าอยู่บนสุดของ UI อื่นๆ
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "NotifyFrame"
    frame.Size = UDim2.new(0.25, 0, 0.3, 0)
    frame.Position = UDim2.new(0.74, 0, 0.69, 0) -- ตำแหน่งมุมขวาล่าง, มีระยะห่างเล็กน้อย
    frame.AnchorPoint = Vector2.new(0, 1) -- จุดยึดที่มุมล่างซ้ายของเฟรมเอง
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.8
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true -- สำคัญสำหรับการแสดงผลแบบเลื่อนขึ้น
    frame.Parent = screenGui

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Name = "MessageLayout"
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- ข้อความใหม่จะปรากฏเหนือข้อความเก่า
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = frame

    local messages = {}
    local maxMessages = 10 -- จำนวนข้อความสูงสุดที่จะแสดง

    local function notify(message, color)
        -- ล้างข้อความเก่าหากมีจำนวนเกินกำหนด
        while #messages >= maxMessages do
            local oldestMessage = table.remove(messages, 1)
            if oldestMessage and oldestMessage.Parent then
                oldestMessage:Destroy()
            end
        end

        local textLabel = Instance.new("TextLabel")
        textLabel.Text = message
        textLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, 0, 0, 20) -- ปรับขนาดแนวตั้งอัตโนมัติด้วย UIListLayout
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Font = Enum.Font.SourceSans
        textLabel.TextSize = 14
        textLabel.TextWrapped = true
        textLabel.Parent = frame

        table.insert(messages, textLabel)

        -- ทำให้ข้อความจางหายไปหลังจากหน่วงเวลา
        task.delay(5, function()
            if textLabel and textLabel.Parent then
                textLabel:TweenTransparency(Enum.TweenEasingDirection.Out, Enum.TweenEasingStyle.Quad, 1, 0.5, true)
                task.delay(0.5, function()
                    if textLabel and textLabel.Parent then
                        textLabel:Destroy()
                    end
                    for i = 1, #messages do
                        if messages[i] == textLabel then
                            table.remove(messages, i)
                            break
                        end
                    end
                end)
            end
        end)
    end

    return notify
end

local notify = createNotifySystem()

--- ฟังก์ชันหลัก (Core Functions)
local function fireRemote(action, item, amount)
    local args = { [1] = "fire", [3] = action, [4] = item, [5] = amount }
    local event = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NetworkFramework"):WaitForChild("NetworkEvent")
    if event then
        event:FireServer(unpack(args))
        notify(string.format("ส่งคำสั่ง: %s %s x%s", action, item, tostring(amount)), Color3.fromRGB(150, 255, 150))
    end
end

local function noclipCharacter()
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local lowerName = part.Name:lower()
                -- ตรวจสอบว่าเป็นพื้นหรือต่ำกว่าระดับ Y ที่กำหนด เพื่อป้องกันการ noclip พื้น
                local isGround = lowerName:find("ground") or lowerName:find("floor") or part.Position.Y < 5
                if not isGround then
                    part.CanCollide = false
                end
            end
        end
    end
end

local function walkTo(pos)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local human = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")

    human.WalkSpeed = 30
    human:MoveTo(pos)
    notify("กำลังเดินไปที่: " .. tostring(pos), Color3.fromRGB(255, 255, 100))
    -- เดินต่อไปจนกว่าจะถึงเป้าหมาย
    while (root.Position - pos).Magnitude > 4 do
        noclipCharacter() -- ใช้ noclip ระหว่างการเคลื่อนที่เพื่อการเดินทางที่ราบรื่น
        human:MoveTo(pos)
        task.wait(0.2)
    end
    notify("ถึงที่หมายแล้ว: " .. tostring(pos), Color3.fromRGB(100, 255, 255))
    return true
end

local function getAmountFromText(path)
    if path and path:IsA("TextLabel") then
        local current, max = path.Text:match("^(%d+)%s*/%s*(%d+)$")
        return tonumber(current), tonumber(max)
    end
    return nil, nil
end

--- การตั้งค่าเฉพาะเกม (Game-Specific Configurations)
local fishList = {
    Fish = { "Inventory", "CanvasGroup", "Main", "Body", "Fish", "Main", "Amount" },
    Crab = { "Inventory", "CanvasGroup", "Main", "Body", "Crab", "Main", "Amount" },
    Dolphin = { "Inventory", "CanvasGroup", "Main", "Body", "Dolphin", "Main", "Amount" },
    Shark = { "Inventory", "CanvasGroup", "Main", "Body", "Shark", "Main", "Amount" },
    Shrimp = { "Inventory", "CanvasGroup", "Main", "Body", "Shrimp", "Main", "Amount" },
    Squid = { "Inventory", "CanvasGroup", "Main", "Body", "Squid", "Main", "Amount" },
    Stingray = { "Inventory", "CanvasGroup", "Main", "Body", "Stingray", "Main", "Amount" },
}

local baitPath = { "Inventory", "CanvasGroup", "Main", "Body", "Bait", "Main", "Amount" }
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local statusGui = playerGui:WaitForChild("Status"):WaitForChild("Main"):WaitForChild("Status")

local function findPath(pathTable)
    local current = playerGui
    for _, name in ipairs(pathTable) do
        current = current and current:FindFirstChild(name)
    end
    return current
end

local function startFishing()
    local rod = workspace:FindFirstChild("Character") and workspace.Character:FindFirstChild(LocalPlayer.Name) and workspace.Character[LocalPlayer.Name]:FindFirstChild("Fishingrod")
    if not rod then
        fireRemote("Use Tool", "Fishingrod")
    end
    wait(1)
    Network.fireServer("AutoFishing")
    notify("เริ่มตกปลาอัตโนมัติแล้ว.", Color3.fromRGB(150, 200, 255))
end

local fishingSpots = {
    Vector3.new(3035.84, 6.19, 1614.85),
    Vector3.new(3022.35, 5.78, 1620.28),
    Vector3.new(3065.29, 6.08, 1632.97),
    Vector3.new(3010.83, 5.77, 1627.09)
}

local function getRandomFishingSpot()
    return fishingSpots[math.random(1, #fishingSpots)]
end

local function startFishingAtRandomSpot()
    local spot = getRandomFishingSpot()
    walkTo(spot)
    startFishing()
end

local function restockItems()
    notify("กำลังเติมเสบียง...", Color3.fromRGB(255, 150, 255))
    walkTo(Vector3.new(2957.82, 14.14, 1917.37)) -- ป้ายวาร์ป

    walkTo(Vector3.new(3017.66, 14.14, 1936.27))
    walkTo(Vector3.new(3025.93, 14.41, 1912.14))
    walkTo(Vector3.new(3044.65, 14.41, 1912.99))

    fireRemote("Supermarket", "Bait", 150)
    fireRemote("Supermarket", "Water", 15)
    fireRemote("Supermarket", "Bread", 15)

    task.wait(4) -- รอ 4 วินาทีหลังซื้อ

    walkTo(Vector3.new(3028.79, 14.41, 1910.04))
    walkTo(Vector3.new(3019.00, 14.14, 1936.90))
    walkTo(Vector3.new(2966.16, 14.14, 1919.93))
    walkTo(Vector3.new(3044.08, 13.36, 1675.23))
    notify("เติมเสบียงเสร็จสิ้น.", Color3.fromRGB(150, 255, 200))
end

--- ส่วนหลักของสคริปต์ (Main Script Logic)
local function mainLoop()
    notify("เริ่มการทำงานสคริปต์.", Color3.fromRGB(200, 200, 255))

    -- การตั้งค่าเริ่มต้น
    walkTo(Vector3.new(3045.39, 13.36, 1670.62))
    task.wait(1)
    startFishingAtRandomSpot()

    local lastDisplayTime = 0
    local startTime = tick()

    while true do
        task.wait(1)

        -- ตรวจสอบเฟรม AutoFarmFishing.CanvasGroup.Frame พร้อม Timeout
        local autoFarmFrame = playerGui:FindFirstChild("AutoFarmFishing")
            and playerGui.AutoFarmFishing:FindFirstChild("CanvasGroup")
            and playerGui.AutoFarmFishing.CanvasGroup:FindFirstChild("Frame")

        if autoFarmFrame then
            -- รีเซ็ตตัวจับเวลาหากพบเฟรม เพราะปัญหาได้รับการแก้ไขแล้ว
            startTime = tick()
        else
            local elapsedTime = tick() - startTime
            notify(string.format("ไม่พบเฟรม AutoFarmFishing. ผ่านไปแล้ว: %.1f วินาที", elapsedTime), Color3.fromRGB(255, 150, 150))
            if elapsedTime >= 180 then
                notify("ไม่พบเฟรม AutoFarmFishing ภายใน 180 วินาที. กำลังรีสตาร์ทสคริปต์...", Color3.fromRGB(255, 50, 50))
                break -- ออกจากลูปปัจจุบันเพื่อเรียก mainLoop ใหม่
            end
        end

        -- ตรวจสอบให้แน่ใจว่าได้สวมใส่เบ็ดตกปลา
        task.spawn(function()
            local rod = workspace:FindFirstChild("Character") and workspace.Character:FindFirstChild(LocalPlayer.Name) and workspace.Character[LocalPlayer.Name]:FindFirstChild("Fishingrod")
            if not rod then
                fireRemote("Use Tool", "Fishingrod")
            end
        end)

        -- ตรวจสอบความหิวและกระหาย
        local hunger = statusGui:WaitForChild("Hunger"):WaitForChild("Bar").Size.Y.Scale
        local thirst = statusGui:WaitForChild("Thirsty"):WaitForChild("Bar").Size.Y.Scale

        if hunger < 0.2 then fireRemote("Use Item", "Bread", 1) end
        if thirst < 0.2 then fireRemote("Use Item", "Water", 1) end

        -- แสดงรายการในกระเป๋าทุกๆ 10 วินาที
        if tick() - lastDisplayTime >= 10 then
            notify("=== ตรวจสอบไอเท็มในกระเป๋า ===", Color3.fromRGB(200, 200, 200))
            local hasFish = false
            for name, path in pairs(fishList) do
                local obj = findPath(path)
                local amount = getAmountFromText(obj)
                if amount and amount > 0 then
                    notify(name .. ": " .. amount, Color3.fromRGB(200, 200, 200))
                    hasFish = true
                end
            end
            if not hasFish then
                notify("ไม่มีปลาในกระเป๋า.", Color3.fromRGB(200, 200, 200))
            end
            notify("============================", Color3.fromRGB(200, 200, 200))
            lastDisplayTime = tick()
        end

        -- ตรวจสอบว่าช่องเก็บปลาเต็มหรือไม่
        local full = false
        for _, path in pairs(fishList) do
            local obj = findPath(path)
            local cur, max = getAmountFromText(obj)
            if cur and max and cur >= max then
                full = true
                break -- ไม่จำเป็นต้องตรวจสอบรายการอื่นถ้ามีรายการใดรายการหนึ่งเต็มแล้ว
            end
        end

        if full then
            notify("ช่องเก็บของเต็ม! กำลังขายปลาทั้งหมด...", Color3.fromRGB(255, 100, 100))
            walkTo(Vector3.new(3026.53, 12.95, 1703.87)) -- จุดเดินไปขายปลาจุดแรก
            walkTo(Vector3.new(2815.85, 14.14, 1839.71)) -- จุดเดินไปขายปลาจุดที่สอง
            walkTo(Vector3.new(2840.77, 14.14, 2082.19)) -- จุดขายปลาจริง
            for name, path in pairs(fishList) do
                local obj = findPath(path)
                local amount = getAmountFromText(obj)
                if amount and amount > 0 then
                    fireRemote("Economy", name, amount)
                    notify("ขาย " .. name .. " x" .. amount, Color3.fromRGB(150, 255, 150))
                    task.wait(0.1) -- หน่วงเวลาเล็กน้อยระหว่างการขาย
                end
            end
            task.wait(4) -- รอ 4 วินาทีหลังขาย

            -- เพิ่มจุดเดินใหม่หลังจากขายเสร็จ
            walkTo(Vector3.new(2843.12, 14.37, 1993.33))
            walkTo(Vector3.new(2967.07, 14.37, 1796.68))
            walkTo(Vector3.new(3085.42, 13.75, 1742.42))
            
            startFishingAtRandomSpot()
        end

        -- ตรวจสอบเหยื่อ
        local baitObj = findPath(baitPath)
        local bait, baitMax = getAmountFromText(baitObj)

        if (not bait or bait <= 4) then
            notify("เหยื่อไม่พบหรือเหลือน้อย. กำลังซื้อเพิ่ม...", Color3.fromRGB(255, 100, 100))
            restockItems()
            task.wait(4) -- รอ 4 วินาทีก่อนกลับไปตกปลา
            startFishingAtRandomSpot()
        end
    end
    -- หากลูปหยุดลง สคริปต์จะเรียก mainLoop ใหม่เพื่อรีสตาร์ท
    mainLoop()
end

-- เริ่มเรียกฟังก์ชัน mainLoop
mainLoop()
