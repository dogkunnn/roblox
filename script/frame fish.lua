local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Network = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NetworkFramework"))
local UserInputService = game:GetService("UserInputService")

math.randomseed(tick())
math.random(); math.random(); math.random()

--- Notification System
local function createNotifySystem()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugNotifySystem"
    screenGui.DisplayOrder = 999 -- Ensure it's on top
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "NotifyFrame"
    frame.Size = UDim2.new(0.25, 0, 0.3, 0)
    frame.Position = UDim2.new(0.74, 0, 0.69, 0) -- Bottom-right, with some padding
    frame.AnchorPoint = Vector2.new(0, 1) -- Anchor to bottom-left of the frame itself
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.8
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true -- Crucial for scrolling effect
    frame.Parent = screenGui

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Name = "MessageLayout"
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- New messages appear above old
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = frame

    local messages = {}
    local maxMessages = 10 -- Maximum number of messages to display

    local function notify(message, color)
        -- Clear old messages if the list is too long
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
        textLabel.Size = UDim2.new(1, 0, 0, 20) -- Auto size vertically is handled by UIListLayout
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Font = Enum.Font.SourceSans
        textLabel.TextSize = 14
        textLabel.TextWrapped = true
        textLabel.Parent = frame

        table.insert(messages, textLabel)

        -- Animate message fading out after a delay
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

--- Core Functions
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
                -- Check if it's ground or below a certain Y level to avoid nocliping the ground
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
    -- Keep moving until close to the target
    while (root.Position - pos).Magnitude > 4 do
        noclipCharacter() -- Apply noclip during movement for smoother travel
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

--- Game-Specific Configurations
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
    Vector3.new(3584.87, 6.73, 2015.37),
    Vector3.new(3620.27, 6.31, 2007.61),
    Vector3.new(3632.07, 5.76, 2006.26),
    Vector3.new(3628.15, 6.01, 2018.22)
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
    walkTo(Vector3.new(3576.40, 9.16, 2051.19)) -- Warp sign
    walkTo(Vector3.new(3251.38, 15.13, 2184.02))
    walkTo(Vector3.new(2996.73, 14.72, 2280.26))

    fireRemote("Supermarket", "Bait", 150)
    fireRemote("Supermarket", "Water", 15)
    fireRemote("Supermarket", "Bread", 15)

    task.wait(4) -- Wait 4 seconds after buying

    walkTo(Vector3.new(3243.65, 15.13, 2184.93))
    walkTo(Vector3.new(3563.53, 10.11, 2052.73))
    notify("เติมเสบียงเสร็จสิ้น.", Color3.fromRGB(150, 255, 200))
end

--- Main Script Logic
local function mainLoop()
    notify("เริ่มการทำงานสคริปต์.", Color3.fromRGB(200, 200, 255))

    -- Initial setup
    walkTo(Vector3.new(3552.52, 10.39, 2060.70))
    task.wait(1)
    startFishingAtRandomSpot()

    local lastDisplayTime = 0
    local startTime = tick()

    while true do
        task.wait(1)

        -- Check for AutoFarmFishing.CanvasGroup.Frame with timeout
        local autoFarmFrame = playerGui:FindFirstChild("AutoFarmFishing")
            and playerGui.AutoFarmFishing:FindFirstChild("CanvasGroup")
            and playerGui.AutoFarmFishing.CanvasGroup:FindFirstChild("Frame")

        if autoFarmFrame then
            -- Reset timer if found, as it's no longer an issue
            startTime = tick()
        else
            local elapsedTime = tick() - startTime
            notify(string.format("ไม่พบเฟรม AutoFarmFishing. ผ่านไปแล้ว: %.1f วินาที", elapsedTime), Color3.fromRGB(255, 150, 150))
            if elapsedTime >= 180 then
                notify("ไม่พบเฟรม AutoFarmFishing ภายใน 180 วินาที. กำลังรีสตาร์ทสคริปต์...", Color3.fromRGB(255, 50, 50))
                break -- Exit the current loop to re-call mainLoop
            end
        end

        -- Ensure fishing rod is equipped
        task.spawn(function()
            local rod = workspace:FindFirstChild("Character") and workspace.Character:FindFirstChild(LocalPlayer.Name) and workspace.Character[LocalPlayer.Name]:FindFirstChild("Fishingrod")
            if not rod then
                fireRemote("Use Tool", "Fishingrod")
            end
        end)

        -- Check hunger and thirst
        local hunger = statusGui:WaitForChild("Hunger"):WaitForChild("Bar").Size.Y.Scale
        local thirst = statusGui:WaitForChild("Thirsty"):WaitForChild("Bar").Size.Y.Scale

        if hunger < 0.2 then fireRemote("Use Item", "Bread", 1) end
        if thirst < 0.2 then fireRemote("Use Item", "Water", 1) end

        -- Show inventory every 10 seconds
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

        -- Check if any fish inventory is full
        local full = false
        for _, path in pairs(fishList) do
            local obj = findPath(path)
            local cur, max = getAmountFromText(obj)
            if cur and max and cur >= max then
                full = true
                break -- No need to check others if one is full
            end
        end

        if full then
            notify("ช่องเก็บของเต็ม! กำลังขายปลาทั้งหมด...", Color3.fromRGB(255, 100, 100))
            walkTo(Vector3.new(3556.22, 10.31, 2054.88)) -- Warp sign
            walkTo(Vector3.new(3093.04, 14.31, 2117.39))
            walkTo(Vector3.new(2856.27, 14.29, 2096.71))
            walkTo(Vector3.new(2856.40, 17.45, 2110.29)) -- Fish selling spot
            for name, path in pairs(fishList) do
                local obj = findPath(path)
                local amount = getAmountFromText(obj)
                if amount and amount > 0 then
                    fireRemote("Economy", name, amount)
                    notify("ขาย " .. name .. " x" .. amount, Color3.fromRGB(150, 255, 150))
                    task.wait(0.1) -- Small delay between sales
                end
            end
            task.wait(4) -- Wait 4 seconds after selling

            -- Added walkTo calls after selling
            walkTo(Vector3.new(2858.22, 14.29, 2100.14))
            walkTo(Vector3.new(3124.72, 14.72, 2116.67))
            walkTo(Vector3.new(3566.46, 10.10, 2062.65))

            startFishingAtRandomSpot()
        end

        -- Check bait
        local baitObj = findPath(baitPath)
        local bait, baitMax = getAmountFromText(baitObj)

        if (not bait or bait <= 4) then
            notify("เหยื่อไม่พบหรือเหลือน้อย. กำลังซื้อเพิ่ม...", Color3.fromRGB(255, 100, 100))
            restockItems()
            task.wait(4) -- Wait 4 seconds before returning to fishing
            startFishingAtRandomSpot()
        end
    end
    -- If the loop breaks, it will re-call mainLoop to restart
    mainLoop()
end

-- Initial call to start the main loop
mainLoop()