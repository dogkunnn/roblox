local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local func = ReplicatedStorage:WaitForChild("func")
local serversFolder = ReplicatedStorage:WaitForChild("Servers")

-- UI แจ้งเตือน
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "TeleportNotifier"

local textLabel = Instance.new("TextLabel", screenGui)
textLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
textLabel.Position = UDim2.new(0.25, 0, 0.05, 0)
textLabel.BackgroundTransparency = 0.3
textLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.SourceSansBold
textLabel.Text = "กำลังค้นหาเซิร์ฟเวอร์..."

-- หาฟังก์ชันหาเซิร์ฟเวอร์
local function findBestServer()
    local lowestPlayers = math.huge
    local bestServerCode = nil
    local bestServerName = nil

    for i = 1, 47 do
        local server = serversFolder:FindFirstChild("SERVER " .. i)
        if server and server:IsA("StringValue") then
            local playerCount = server:GetAttribute("Players")
            if playerCount and type(playerCount) == "number" then
                if playerCount < lowestPlayers then
                    lowestPlayers = playerCount
                    bestServerCode = string.split(server.Value, " ")[1]
                    bestServerName = "SERVER " .. i
                end
            end
        end
    end

    return bestServerCode, bestServerName, lowestPlayers
end

-- เทเลพอร์ตซ้ำหากยังไม่เข้า
task.spawn(function()
    while true do
        local code, name, count = findBestServer()
        if code and LocalPlayer:GetAttribute("ServerCode") ~= code then
            textLabel.Text = "กำลังเทเลพอร์ตไปยัง " .. name .. " (" .. count .. " ผู้เล่น)"
            func:InvokeServer("teleport", code)
        end
        task.wait(2)
    end
end)
