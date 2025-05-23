local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local endpoint = "https://roblox-l5m8.onrender.com/update"

local function safeFindText(base, path, maxWaitTime)
	maxWaitTime = maxWaitTime or 90
	local elapsed = 0
	local obj = base

	for _, part in ipairs(path) do
		local found = nil
		repeat
			found = obj:FindFirstChild(part)
			if not found then
				wait(1)
				elapsed += 1
			end
		until found or elapsed >= maxWaitTime

		if not found then
			return "Unknown"
		end
		obj = found
	end

	if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
		return obj.Text
	end

	return "Unknown"
end

local function getData()
	local gui = player:WaitForChild("PlayerGui")
	local inventory = gui:WaitForChild("Inventory"):WaitForChild("CanvasGroup")
	local amountLabel = inventory.Main.Body.Cash.Main.Amount
	local cash = tonumber(amountLabel.Text) or 0

	local serverName = safeFindText(gui, {
		"TopbarStandard", "Holders", "Left", "Widget",
		"IconButton", "Menu", "IconSpot", "Contents",
		"IconLabelContainer", "IconLabel"
	}, 90)

	local playerCount = #Players:GetPlayers()
	local username = player.Name

	return {
		username = username,
		cash = cash,
		playercount = playerCount,
		servername = serverName
	}
end

local function sendData()
	local data = getData()

	-- ถ้ามีผู้เล่นมากกว่า 15 คน ให้ออกจากเกม
	if data.playercount > 15 then
		warn("พบผู้เล่นมากกว่า 15 คน กำลังออกจากเกม...")
		player:Kick("พบผู้เล่นมากกว่า 15 คน ออกจากเกมเพื่อความปลอดภัย")
		return
	end

	local jsonData = HttpService:JSONEncode(data)
	print("กำลังส่งข้อมูลไปยัง API:", jsonData)

	local success, response = pcall(function()
		request({
			Url = endpoint,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
	end)

	if success then
		print("ส่งข้อมูลสำเร็จ")
	else
		warn("ส่งข้อมูลล้มเหลว:", response)
		wait(2)
		sendData()
	end
end

task.spawn(function()
	wait(1)
	sendData()

	while true do
		wait(1)
		sendData()
	end
end)
