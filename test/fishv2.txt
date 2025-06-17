local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Network = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NetworkFramework"))

math.randomseed(tick())
math.random(); math.random(); math.random()

local function fireRemote(action, item, amount)
    local args = { [1] = "fire", [3] = action, [4] = item, [5] = amount }
    local event = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NetworkFramework"):WaitForChild("NetworkEvent")
    if event then
        event:FireServer(unpack(args))
        print(string.format("Fired: %s %s x%s", action, item, tostring(amount)))
    end
end

local function noclipCharacter()
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local lowerName = part.Name:lower()
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
    while (root.Position - pos).Magnitude > 4 do
        noclipCharacter()
        human:MoveTo(pos)
        task.wait(0.2)
    end
    print("Reached:", pos)
    return true
end

local function getAmountFromText(path)
    if path and path:IsA("TextLabel") then
        local current, max = path.Text:match("^(%d+)%s*/%s*(%d+)$")
        return tonumber(current), tonumber(max)
    end
    return nil, nil
end

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
end

local fishingSpots = {
    Vector3.new(3020.62, 7.18, 1626.74),
    Vector3.new(3065.16, 7.45, 1639.31),
    Vector3.new(3076.17, 7.84, 1634.31),
    Vector3.new(3036.43, 7.62, 1619.01),
    Vector3.new(3028.00, 6.79, 1624.63),
    Vector3.new(3044.85, 7.23, 1622.85)
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
    walkTo(Vector3.new(2957.82, 14.14, 1917.37)) -- ป้ายวาร์ป

    walkTo(Vector3.new(3017.66, 14.14, 1936.27))
    walkTo(Vector3.new(3025.93, 14.41, 1912.14))
    walkTo(Vector3.new(3044.65, 14.41, 1912.99))

    fireRemote("Supermarket", "Bait", 150)
    fireRemote("Supermarket", "Water", 15)
    fireRemote("Supermarket", "Bread", 15)

    task.wait(4) -- รอ 4 วิหลังซื้อ

    walkTo(Vector3.new(3028.79, 14.41, 1910.04))
    walkTo(Vector3.new(3019.00, 14.14, 1936.90))
    walkTo(Vector3.new(2966.16, 14.14, 1919.93))
    walkTo(Vector3.new(3044.08, 13.36, 1675.23))
end

-- เริ่ม
walkTo(Vector3.new(3045.39, 13.36, 1670.62))
task.wait(1)
startFishingAtRandomSpot()

local lastDisplayTime = 0

while true do
    task.wait(1)

    task.spawn(function()
        local rod = workspace:FindFirstChild("Character") and workspace.Character:FindFirstChild(LocalPlayer.Name) and workspace.Character[LocalPlayer.Name]:FindFirstChild("Fishingrod")
        if not rod then
            fireRemote("Use Tool", "Fishingrod")
        end
    end)

    local hunger = statusGui:WaitForChild("Hunger"):WaitForChild("Bar").Size.Y.Scale
    local thirst = statusGui:WaitForChild("Thirsty"):WaitForChild("Bar").Size.Y.Scale

    if hunger < 0.2 then fireRemote("Use Item", "Bread", 1) end
    if thirst < 0.2 then fireRemote("Use Item", "Water", 1) end

    -- Show inventory every 10s
    if tick() - lastDisplayTime >= 10 then
        print("=== Fish Inventory ===")
        for name, path in pairs(fishList) do
            local obj = findPath(path)
            local amount = getAmountFromText(obj)
            if amount and amount > 0 then
                print(name .. ": " .. amount)
            end
        end
        print("======================")
        lastDisplayTime = tick()
    end

    -- Check if any fish inventory is full
    local full = false
    for _, path in pairs(fishList) do
        local obj = findPath(path)
        local cur, max = getAmountFromText(obj)
        if cur and max and cur >= max then
            full = true
        end
    end

    if full then
        print("Inventory full. Selling all fish...")
        walkTo(Vector3.new(3026.53, 12.95, 1703.87))
        walkTo(Vector3.new(2815.85, 14.14, 1839.71))
        walkTo(Vector3.new(2840.77, 14.14, 2082.19))
        for name, path in pairs(fishList) do
            local obj = findPath(path)
            local amount = getAmountFromText(obj)
            if amount and amount > 0 then
                fireRemote("Economy", name, amount)
                print("Sold", name, "x", amount)
                task.wait(0.1)
            end
        end
        task.wait(4) -- รอ 4 วิหลังขาย
        startFishingAtRandomSpot()
    end

    -- Check bait
    local baitObj = findPath(baitPath)
    local bait, baitMax = getAmountFromText(baitObj)

    if (not bait or bait <= 4) then
        print("Bait not found or low. Buying more...")
        restockItems()
        task.wait(4) -- รอ 4 วิก่อนกลับไปตกปลา
        startFishingAtRandomSpot()
    end
end
