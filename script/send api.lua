local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Supabase configuration
local supabaseUrl = "https://inlrteqmzgrnhzibkymh.supabase.co"
local supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlubHJ0ZXFtemdybmh6aWJreW1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NDMwNjUsImV4cCI6MjA2MDQxOTA2NX0.fHKi5Cy0RfO65OVedadzCTUi26MTSPN5nKs92zNyYFU"
local playersEndpoint = supabaseUrl .. "/rest/v1/players"

--- NEW: Device Configuration ---
-- You can change this value for each instance of the client running.
-- For example, if you have multiple instances, set this to "Device_1", "Device_2", etc.
local DEVICE_IDENTIFIER = "Device_1" -- Default value
---------------------------------

-- Global variable to track farming status and last check time
local isPlayerFarming = false
local lastFarmGuiFoundTime = tick() -- Time when farming GUI was last confirmed present

-- NEW: Variable to track how long farming GUI has been missing
local farmGuiMissingDuration = 0

-- Function to show notifications in Roblox (and print to console)
local function showNotification(title, text)
	print(string.format("[NOTIFY] %s: %s", title, text)) -- Also print notification to console
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 3
		})
	end)
end

-- Function to get player data (including farming status from GUI)
local function getData()
	local success, result = pcall(function()
		local gui = player:WaitForChild("PlayerGui", 5)
		if not gui then
			warn("⚠️ [DEBUG] PlayerGui ไม่พร้อมใช้งาน")
			showNotification("ข้อผิดพลาด", "UI ของเกมไม่โหลด กรุณารอสักครู่")
			return nil
		end

		local inventory = gui:FindFirstChild("Inventory", true)
		local amountLabel
		if inventory then
			local canvasGroup = inventory:FindFirstChild("CanvasGroup", true)
			if canvasGroup then
				local main = canvasGroup:FindFirstChild("Main", true)
				if main then
					local body = main:FindFirstChild("Body", true)
					if body then
						local cash = body:FindFirstChild("Cash", true)
						if cash then
							local mainCash = cash:FindFirstChild("Main", true)
							if mainCash then
								amountLabel = mainCash:FindFirstChild("Amount", true)
							end
						end
					end
				end
			end
		end

		local cash = 0
		if amountLabel and amountLabel:IsA("TextLabel") then
			local rawText = amountLabel.Text or "0"
			rawText = rawText:gsub(",", ""):gsub("%s+", "")
			cash = tonumber(rawText) or 0
		else
			-- If amountLabel is not found or not a TextLabel, return nil to prevent sending data
			warn("⚠️ [DEBUG] ไม่พบ UI แสดงเงินหรือไม่ใช่ TextLabel. ไม่สามารถดึงข้อมูลได้.")
			showNotification("ข้อผิดพลาด", "ไม่พบ UI แสดงเงิน. ไม่สามารถอัปเดตข้อมูลได้.")
			return nil -- Important: Return nil here to indicate data is not ready
		end

		local playerCount = #Players:GetPlayers()
		local username = player.Name
		local isoTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") -- Current UTC ISO 8601 time

		-- Check for farming GUI
		local autoFarmGui = gui:FindFirstChild("AutoFarmFishing", true)
		local farmFrameFound = false
		if autoFarmGui then
			local canvasGroup = autoFarmGui:FindFirstChild("CanvasGroup", true)
			if canvasGroup then
				local frame = canvasGroup:FindFirstChild("Frame", true)
				if frame and frame.Parent == canvasGroup then
					farmFrameFound = true
				end
			end
		end

		local currentTime = tick()
		if farmFrameFound then
			-- If farming GUI is found, player is farming
			if not isPlayerFarming then
				print("🎣 [DEBUG] พบ GUI ฟาร์ม: เปลี่ยนสถานะเป็น 'กำลังฟาร์ม'")
				showNotification("สถานะฟาร์ม", "คุณกำลังฟาร์มอยู่!")
			end
			isPlayerFarming = true
			lastFarmGuiFoundTime = currentTime -- Reset timer if GUI is found
			farmGuiMissingDuration = 0 -- Reset missing duration
		else
			-- If farming GUI is NOT found
			farmGuiMissingDuration = currentTime - lastFarmGuiFoundTime
			if isPlayerFarming and farmGuiMissingDuration > 120 then -- Changed from 60 to 120 seconds
				-- If farming GUI not found for more than 120 seconds AND player was previously farming
				print(string.format("🚫 [DEBUG] ไม่พบ GUI ฟาร์มเป็นเวลา %.1f วินาที: เปลี่ยนสถานะเป็น 'ไม่ฟาร์ม'", farmGuiMissingDuration))
				showNotification("สถานะเปลี่ยน", "คุณไม่ได้ฟาร์มแล้ว! (ไม่พบ UI ฟาร์ม)")
				isPlayerFarming = false
			elseif not isPlayerFarming and farmGuiMissingDuration > 10 then -- For debugging when not farming and GUI is missing
				print(string.format("ℹ️ [DEBUG] ไม่พบ GUI ฟาร์มเป็นเวลา %.1f วินาที. สถานะฟาร์มปัจจุบัน: ไม่ฟาร์ม", farmGuiMissingDuration))
				-- Show notification after a few seconds of GUI missing if not already farming
				if math.fmod(math.floor(farmGuiMissingDuration), 30) == 0 and farmGuiMissingDuration > 0 then -- Notify every 30 seconds
                    showNotification("UI ฟาร์มหาย", string.format("ไม่พบ UI ฟาร์มมาแล้ว %d วินาที", math.floor(farmGuiMissingDuration)))
                end
			else
				-- If GUI not found but within 120s grace period, maintain current farming status
				-- This prevents flickering if GUI briefly disappears.
				print(string.format("ℹ️ [DEBUG] ไม่พบ GUI ฟาร์ม แต่ยังอยู่ในช่วงผ่อนผัน (%.1f วินาที). สถานะฟาร์มปัจจุบัน: %s", farmGuiMissingDuration, tostring(isPlayerFarming)))
			end
		end

		return {
			username = username,
			device_id = DEVICE_IDENTIFIER, -- NEW: Include the device ID
			cash = cash,
			playercount = playerCount,
			status = "online", -- Always report as online if script is running
			last_online = isoTimestamp,
			is_farming = isPlayerFarming -- Send the determined farming status
		}
	end)

	if not success then
		warn("❌ [ERROR] Failed to retrieve player data (pcall error):", result)
		showNotification("❌ Fetch Failed", "เกิดข้อผิดพลาดในการดึงข้อมูลเกม: " .. tostring(result))
		return nil
	end

	return result
end

-- Function to send data to Supabase
local function sendData()
	local rawData = getData()
	if not rawData then
		-- If getData returns nil, it means the cash UI was not ready, so we don't send data.
		print("🚫 [HTTP] ไม่ส่งข้อมูลไปยัง Supabase เนื่องจาก UI แสดงเงินไม่พร้อม.")
		return
	end

	-- 🔒 Kick if more than 15 players in server (Client-side kick)
	if rawData.playercount > 15 then
		print(string.format("👥 [WARNING] ผู้เล่นในเซิร์ฟเวอร์เยอะเกินไป (%d คน). กำลังออกจากเซิร์ฟเวอร์...", rawData.playercount))
		showNotification("👥 ผู้เล่นเยอะเกินไป", "ออกจากเซิร์ฟเวอร์เนื่องจากคนเยอะเกินไป!")
		wait(1)
		player:Kick("👥 เซิร์ฟเวอร์เต็ม (ผู้เล่นเกิน 15 คน)")
		return
	end

	local jsonData = HttpService:JSONEncode(rawData)
	print("📤 [HTTP] กำลังส่งข้อมูลไปยัง Supabase...")
	print("    ข้อมูลที่จะส่ง: " .. jsonData) -- Added "ข้อมูลที่จะส่ง" for clarity in output

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = playersEndpoint,
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

	if success and response then
		if (response.StatusCode >= 200 and response.StatusCode < 300) then -- Check for 2xx success codes
			print(string.format("✅ [HTTP] ส่งข้อมูลสำเร็จ! สถานะ HTTP: %d", response.StatusCode))
			showNotification("✅ ส่งข้อมูลสำเร็จ", "อัปเดตข้อมูลผู้เล่นเรียบร้อย!") -- New notification for successful send
		else
			local status = response.StatusCode
			local body = response.Body
			warn(string.format("❌ [HTTP ERROR] ส่งข้อมูลล้มเหลว! สถานะ: %d, ข้อความ: %s", status, body))
			showNotification("❌ ส่งข้อมูลล้มเหลว", "ข้อผิดพลาด HTTP: " .. tostring(status) .. " " .. body)
		end
	else
		warn("❌ [HTTP ERROR] การส่งข้อมูลล้มเหลว (pcall error):", response)
		showNotification("❌ ส่งข้อมูลล้มเหลว", "เกิดข้อผิดพลาดในการเชื่อมต่อ: " .. tostring(response))
	end
end

-- Function to check for kick signal from Supabase
local function checkForKickSignal()
    local username = player.Name
    print(string.format("👂 [CHECK] กำลังตรวจสอบสัญญาณเตะสำหรับผู้เล่น %s...", username))

    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = playersEndpoint .. "?username=eq." .. HttpService:UrlEncode(username) .. "&select=kick_player",
            Method = "GET",
            Headers = {
                ["apikey"] = supabaseKey,
                ["Authorization"] = "Bearer " .. supabaseKey,
                ["Accept"] = "application/json"
            }
        })
    end)

    if success and response then
        if response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and #data > 0 then
                local playerRow = data[1]
                if playerRow.kick_player == true then
                    print(string.format("🦶 [KICK] ได้รับสัญญาณเตะสำหรับผู้เล่น %s! กำลังทำการเตะ...", username))
                    showNotification("ถูกเตะออกจากเกม", "คุณถูกเตะออกจากเซิร์ฟเวอร์โดยผู้ดูแล!")
                    wait(2) -- Give time for the notification to show
                    player:Kick("คุณถูกเตะออกจากเซิร์ฟเวอร์โดยผู้ดูแล!")

                    -- Attempt to reset kick_player status in Supabase AFTER successful kick
                    local patchSuccess, patchResponse = pcall(function()
                        return HttpService:RequestAsync({
                            Url = playersEndpoint .. "?username=eq." .. HttpService:UrlEncode(username),
                            Method = "PATCH",
                            Headers = {
                                ["apikey"] = supabaseKey,
                                ["Authorization"] = "Bearer " .. supabaseKey,
                                ["Content-Type"] = "application/json"
                            },
                            Body = HttpService:JSONEncode({ kick_player = false })
                        })
                    end)
                    if not patchSuccess then
                        warn("❌ [KICK ERROR] ไม่สามารถรีเซ็ตสัญญาณเตะใน Supabase ได้:", patchResponse)
                        showNotification("❌ เตะล้มเหลว", "รีเซ็ตสถานะเตะในฐานข้อมูลไม่ได้")
                    elseif patchResponse and (patchResponse.StatusCode == 200 or patchResponse.StatusCode == 204) then
                        print("✅ [KICK] รีเซ็ต kick_player ใน Supabase สำเร็จ.")
                    else
                        warn(string.format("❌ [KICK ERROR] รีเซ็ต kick_player ใน Supabase ล้มเหลว (HTTP Status: %d)", patchResponse.StatusCode))
                        showNotification("❌ เตะล้มเหลว", "รีเซ็ตสถานะเตะในฐานข้อมูลล้มเหลว: " .. tostring(patchResponse.StatusCode))
                    end
                end
            else
                print(string.format("ℹ️ [DEBUG] ไม่พบข้อมูลผู้เล่น %s ในฐานข้อมูล (อาจถูกลบไปแล้ว หรือไม่มีข้อมูล)", username))
            end
        else
            local status = response.StatusCode
            local body = response.Body
            warn(string.format("❌ [HTTP ERROR] ตรวจสอบสัญญาณเตะล้มเหลว (HTTP Status: %d), ข้อความ: %s", status, body))
            showNotification("❌ ตรวจสอบเตะล้มเหลว", "ข้อผิดพลาด HTTP: " .. tostring(status))
        end
    else
        warn("❌ [HTTP ERROR] ตรวจสอบสัญญาณเตะล้มเหลว (pcall error):", response)
        showNotification("❌ ตรวจสอบเตะล้มเหลว", "เกิดข้อผิดพลาดในการเชื่อมต่อ: " .. tostring(response))
    end
end

-- Start tasks concurrently
task.spawn(function()
	wait(1) -- Initial delay before first send
	sendData()
	while true do
		wait(40) -- Send data every 40 seconds
		sendData()
	end
end)

task.spawn(function()
    wait(5) -- Initial delay before first check
    while true do
        checkForKickSignal()
        wait(5) -- Check for kick signal every 5 seconds
    end
end)
