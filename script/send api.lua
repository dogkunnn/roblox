local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- ข้อมูล Supabase
local supabaseUrl = "https://inlrteqmzgrnhzibkymh.supabase.co"
local supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlubHJ0ZXFtemdybmh6aWJreW1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NDMwNjUsImV4cCI6MjA2MDQxOTA2NX0.fHKi5Cy0RfO65OVedadzCTUi26MTSPN5nKs92zNyYFU"
local endpoint = supabaseUrl .. "/rest/v1/players"

-- ฟังก์ชันแสดงแจ้งเตือน
local function showNotification(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 3
		})
	end)
end

-- ดึงข้อมูลผู้เล่น
local function getData()
	local success, result = pcall(function()
		local gui = player:WaitForChild("PlayerGui", 5)
		local inventory = gui:WaitForChild("Inventory", 5):WaitForChild("CanvasGroup", 5)
		local amountLabel = inventory.Main.Body.Cash.Main.Amount

		local rawText = amountLabel.Text or "0"
		rawText = rawText:gsub(",", ""):gsub("%s+", "") -- ลบ , และช่องว่าง
		local cash = tonumber(rawText) or 0

		local playerCount = #Players:GetPlayers()
		local username = player.Name
		local isoTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") -- เวลาปัจจุบัน (UTC ISO 8601)

		return {
			username = username,
			cash = cash,
			playercount = playerCount,
			status = "online",
			last_online = isoTimestamp
		}
	end)

	if not success then
		warn("❌ ไม่สามารถดึงข้อมูลผู้เล่น:", result)
		showNotification("❌ ดึงข้อมูลล้มเหลว", tostring(result))
		return nil
	end

	return result
end

-- ส่งข้อมูลไปยัง Supabase
local function sendData()
	local rawData = getData()
	if not rawData then return end

	local jsonData = HttpService:JSONEncode(rawData)
	print("📤 กำลังส่งข้อมูล:", jsonData)

	local success, response = pcall(function()
		return http_request({
			Url = endpoint,
			Method = "POST",
			Headers = {
				["apikey"] = supabaseKey,
				["Authorization"] = "Bearer " .. supabaseKey,
				["Content-Type"] = "application/json",
				["Prefer"] = "resolution=merge-duplicates"
			},
			Body = jsonData
		})
	end)

	if success and response and (response.StatusCode == 200 or response.StatusCode == 201) then
		print("✅ ส่งข้อมูลสำเร็จ")
		showNotification("✅ สำเร็จ", "ส่งข้อมูลผู้เล่นเรียบร้อย")
	else
		local status = response and response.StatusCode or "unknown"
		local body = response and response.Body or "no response"
		warn("❌ ส่งข้อมูลล้มเหลว:", status, body)
		showNotification("❌ ล้มเหลว", "ส่งข้อมูลไม่สำเร็จ: " .. tostring(status))
	end
end

-- เริ่มส่งข้อมูลทุก 5 วินาที
task.spawn(function()
	wait(1)
	sendData()
	while true do
		wait(40)
		sendData()
	end
end)
