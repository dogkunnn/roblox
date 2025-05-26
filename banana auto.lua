local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local sellPos = Vector3.new(2841.57, 14.14, 2081.41)
local bananaJobPos = Vector3.new(68.93, 13.98, -357.19)

-- UI แสดงกล้วยแบบเรียลไทม์
local ui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ui.Name = "BananaTracker"

local label = Instance.new("TextLabel", ui)
label.Size = UDim2.new(0, 180, 0, 35)
label.Position = UDim2.new(0, 10, 0, 60)
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
label.TextColor3 = Color3.new(1, 1, 0)
label.Font = Enum.Font.GothamBold
label.TextSize = 16
label.Text = "กำลังโหลด..."

local flying = false

-- บินแบบมุดดิน จากตำแหน่ง A ไปตำแหน่ง B โดยเอา Y - 10 ระหว่างทาง แล้วโผล่กลับขึ้นที่ B จริง
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

	-- ย้ายตัวละครลงใต้ดินทันที
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
			-- ถึงใต้ดินปลายทางแล้ว
			hrp.Velocity = Vector3.zero
			conn:Disconnect()

			-- โผล่ขึ้นพื้น
			task.wait(0.1)
			hrp.CFrame = CFrame.new(destination)
			flying = false
			if onReached then onReached() end
		end
	end)
end

-- ฟังก์ชันขายกล้วย
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

-- ฟังก์ชันกด E เพื่อทำงานกล้วย
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

-- เช็คกล้วยแบบเรียลไทม์
task.spawn(function()
	while true do
		local guiBanana = player.PlayerGui:FindFirstChild("Inventory") and player.PlayerGui.Inventory:FindFirstChild("CanvasGroup") and
			player.PlayerGui.Inventory.CanvasGroup:FindFirstChild("Main") and player.PlayerGui.Inventory.CanvasGroup.Main:FindFirstChild("Body") and
			player.PlayerGui.Inventory.CanvasGroup.Main.Body:FindFirstChild("Banana") and player.PlayerGui.Inventory.CanvasGroup.Main.Body.Banana:FindFirstChild("Main") and
			player.PlayerGui.Inventory.CanvasGroup.Main.Body.Banana.Main:FindFirstChild("Amount")

		if guiBanana and guiBanana:IsA("TextLabel") then
			local bananaText = guiBanana.Text
			label.Text = "กล้วย: " .. bananaText

			if string.match(bananaText, "^%s*60%s*/%s*60%s*$") and not flying then
				flyUnderground(sellPos, function()
					sellBananas()
					task.wait(1)
					flyUnderground(bananaJobPos, function()
						task.wait(0.5)
						firePrompt()
					end)
				end)
			end
		else
			label.Text = "ไม่พบข้อมูลกล้วย"
		end
		task.wait(1)
	end
end)
