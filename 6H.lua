repeat task.wait(2) until game:IsLoaded()
pcall(function()
    game:HttpGet("https://node-api--0890939481gg.replit.app/join")
end)

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local vim = game:GetService("VirtualInputManager")

	local player = Players.LocalPlayer

	-- ปิด setting ลดแลค
	local SettingsToggle = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle")

	local settings = {
	"DisablePvP",
	"DisableVFX",
	"DisableOtherVFX",
	"RemoveTexture",
	"RemoveShadows"
	}

	for _,setting in ipairs(settings) do
		local current = player:FindFirstChild("Settings")
		and player.Settings:FindFirstChild(setting)

		if not current or current.Value ~= true then
			SettingsToggle:FireServer(setting, true)
		end
	end

	-- ======================

	


	
	local lastQuest = nil
	local BlackScreen = true

	local function setBlack(state)

		if state then
			game.Lighting.Brightness = 0
			game.Lighting.GlobalShadows = false

			for _,v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then
					v.LocalTransparencyModifier = 1
				end
			end
		else
			for _,v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then
					v.LocalTransparencyModifier = 0
				end
			end
		end

	end

	setBlack(true)

	-- GUI
	local gui = Instance.new("ScreenGui")
	gui.Parent = player.PlayerGui
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.Parent = gui
	button.Size = UDim2.new(0,160,0,45)
	button.Position = UDim2.new(0,20,0.5,-22)
	button.BackgroundColor3 = Color3.fromRGB(25,25,25)
	button.TextColor3 = Color3.fromRGB(255,255,255)
	button.Text = "FpsBoot : ON"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16

	-- มุมโค้ง
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,10)
	corner.Parent = button

	-- เส้นขอบ
	local stroke = Instance.new("UIStroke")
	stroke.Parent = button
	stroke.Color = Color3.fromRGB(0,170,255)
	stroke.Thickness = 2

	-- เงา
	local shadow = Instance.new("ImageLabel")
	shadow.Parent = button
	shadow.BackgroundTransparency = 1
	shadow.Size = UDim2.new(1,20,1,20)
	shadow.Position = UDim2.new(0,-10,0,-10)
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageTransparency = 0.7
	shadow.ZIndex = 0

	button.MouseButton1Click:Connect(function()

	BlackScreen = not BlackScreen
	setBlack(BlackScreen)

	if BlackScreen then
		button.Text = "BlackScreen : ON"
	else
		button.Text = "BlackScreen : OFF"
	end

end)

-- ถ้าตายให้เปิดใหม่ตามสถานะ
player.CharacterAdded:Connect(function()
task.wait(1)
setBlack(BlackScreen)
end)


local hitRemote = ReplicatedStorage.CombatSystem.Remotes.RequestHit
local questRemote = ReplicatedStorage.RemoteEvents.QuestAccept
local abandonRemote = ReplicatedStorage.RemoteEvents.QuestAbandon
local statRemote = ReplicatedStorage.RemoteEvents.AllocateStat
local tpRemote = ReplicatedStorage.Remotes.TeleportToPortal

local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")
	return char,hrp,hum
end

local char,hrp,hum = getChar()
-- ======================
-- Horst Level Display
-- ======================
task.spawn(function()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- รอ LocalPlayer
local player = Players.LocalPlayer
while not player do
	task.wait()
	player = Players.LocalPlayer
end

-- รอ Data
local data = player:WaitForChild("Data",10)
if not data then return end

local levelValue = data:FindFirstChild("Level")
local moneyValue = data:FindFirstChild("Money")

local lastText = ""

while task.wait(1) do

	local level = 0
	local money = 0

	if levelValue then
		level = levelValue.Value
	end

	if moneyValue then
		money = moneyValue.Value
	end

	local message = "⭐ Level "..level.." 💰 Money "..money

	local json = {
	Level = level,
	Money = money
	}

	local encoded = HttpService:JSONEncode(json)

	pcall(function()
	_G.Horst_SetDescription(message, encoded)
end)

end

end)
-- auto hit
task.spawn(function()
while task.wait(0.4) do
	pcall(function()

	hitRemote:FireServer()

	local nearestNPC
	local distance = math.huge

	for _,npc in ipairs(workspace.NPCs:GetChildren()) do
		if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") then
			if npc.Humanoid.Health > 0 then
				local dist = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude

				if dist < distance then
					distance = dist
					nearestNPC = npc
				end
			end
		end
	end

	-- ถ้ามอนอยู่ใกล้ (เช่น 12 studs)
	if nearestNPC and distance <= 12 then
		vim:SendKeyEvent(true,"Z",false,game)
		task.wait(0.1)
		vim:SendKeyEvent(false,"Z",false,game)
	end

end)
end
end)


-- auto stat
task.spawn(function()
while task.wait(1) do
	pcall(function()
	statRemote:FireServer("Melee",2)
	statRemote:FireServer("Defense",1)
end)
end
end)

local function farmNPC(name)

	while task.wait(0.2) do

		if hum.Health <= 0 then break end

		local found = false

		for i = 1,5 do
			local npc = workspace.NPCs:FindFirstChild(name..i)

			if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
				found = true

				local target =
				npc:FindFirstChild("HumanoidRootPart")
				or npc:FindFirstChild("Torso")
				or npc:FindFirstChild("UpperTorso")

				if target then
					hrp.CFrame = target.CFrame * CFrame.new(0,0,7)
					task.wait(0.7)
				end
			end
		end

		if not found then
			break
		end

	end

end


local function farmBoss(name)

	local npc = workspace.NPCs:FindFirstChild(name)

	if npc and npc:FindFirstChild("Humanoid") then

		local target = npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChild("Torso")
		or npc:FindFirstChild("UpperTorso")

		if target then
			while npc.Parent and npc.Humanoid.Health > 0 do
				if hum.Health <= 0 then break end

				hrp.CFrame = target.CFrame * CFrame.new(0,0,7)


				task.wait()

			end
		end
	end
end

while task.wait(0.3) do

	if hum.Health <=0 or not char.Parent then
		char,hrp,hum = getChar()
	end

	local tool = player.Backpack:FindFirstChild("Combat")

	if tool and not char:FindFirstChild("Combat") then
		hum:EquipTool(tool)
	end

	local level = player.Data.Level.Value

	-- 0-250
	if level <=250 then
		questRemote:FireServer("QuestNPC1")
		farmNPC("Thief")

		-- 250-500
	elseif level <=500 then

		tpRemote:FireServer("Jungle")
		task.wait(1)
		if lastQuest ~= "QuestNPC3" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC3")
			lastQuest = "QuestNPC3"
		end
		questRemote:FireServer("QuestNPC3")
		farmNPC("Monkey")

		-- 500-750
	elseif level <=750 then

		tpRemote:FireServer("Jungle")
		task.wait(1)
		if lastQuest ~= "QuestNPC4" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC4")
			lastQuest = "QuestNPC4"
		end
		questRemote:FireServer("QuestNPC4")
		farmBoss("MonkeyBoss")

		-- 750-1000
	elseif level <=1000 then

		tpRemote:FireServer("Desert")
		task.wait(1)
		if lastQuest ~= "QuestNPC5" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC5")
			lastQuest = "QuestNPC5"
		end
		questRemote:FireServer("QuestNPC5")
		farmNPC("DesertBandit")

		-- 1000-1500
	elseif level <=1500 then

		tpRemote:FireServer("Desert")
		task.wait(1)
		if lastQuest ~= "QuestNPC6" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC6")
			lastQuest = "QuestNPC6"
		end
		questRemote:FireServer("QuestNPC6")
		farmBoss("DesertBoss")

		-- 1500-2000
	elseif level <=2000 then

		tpRemote:FireServer("Snow")
		task.wait(1)
		if lastQuest ~= "QuestNPC7" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC7")
			lastQuest = "QuestNPC7"
		end
		questRemote:FireServer("QuestNPC7")
		farmNPC("FrostRogue")

		-- 2000-3000
	elseif level <=3000 then

		tpRemote:FireServer("Snow")
		task.wait(1)
		if lastQuest ~= "QuestNPC8" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC8")
			lastQuest = "QuestNPC8"
		end
		questRemote:FireServer("QuestNPC8")
		farmBoss("SnowBoss")

		-- 3000-4000
	elseif level <=4000 then

		tpRemote:FireServer("Shibuya")
		task.wait(1)
		if lastQuest ~= "QuestNPC9" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC9")
			lastQuest = "QuestNPC9"
		end
		questRemote:FireServer("QuestNPC9")
		farmNPC("Sorcerer")

		-- 4000-5000
	elseif level <=5000 then

		tpRemote:FireServer("Shibuya")
		task.wait(1)
		if lastQuest ~= "QuestNPC10" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC10")
			lastQuest = "QuestNPC10"
		end
		questRemote:FireServer("QuestNPC10")
		farmBoss("PandaMiniBoss")

		-- 5000-6251
	elseif level <=6251 then

		tpRemote:FireServer("HuecoMundo")
		task.wait(1)
		if lastQuest ~= "QuestNPC11" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC11")
			lastQuest = "QuestNPC11"
		end
		questRemote:FireServer("QuestNPC11")
		farmNPC("Hollow")

		-- 6251-7001
	elseif level <=7001 then

		tpRemote:FireServer("Shinjuku")
		task.wait(1)
		if lastQuest ~= "QuestNPC12" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC12")
			lastQuest = "QuestNPC12"
		end
		questRemote:FireServer("QuestNPC12")
		farmNPC("StrongSorcerer")

		-- 7001-8001
	elseif level <=8001 then

		tpRemote:FireServer("Shinjuku")
		task.wait(1)
		if lastQuest ~= "QuestNPC13" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC13")
			lastQuest = "QuestNPC13"
		end
		questRemote:FireServer("QuestNPC13")
		farmNPC("Curse")

		-- 8001-9001
	elseif level <=9001 then

		tpRemote:FireServer("Slime")
		task.wait(1)
		if lastQuest ~= "QuestNPC14" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC14")
			lastQuest = "QuestNPC14"
		end
		questRemote:FireServer("QuestNPC14")
		farmNPC("Slime")

		-- 9001-10001
	elseif level <=10001 then

		tpRemote:FireServer("Academy")
		task.wait(1)
		if lastQuest ~= "QuestNPC15" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC15")
			lastQuest = "QuestNPC15"
		end
		questRemote:FireServer("QuestNPC15")
		farmNPC("AcademyTeacher")

		-- 10001-10751
	elseif level <=10751 then

		tpRemote:FireServer("Judgement")
		task.wait(1)
		if lastQuest ~= "QuestNPC16" then
			if player.PlayerGui:FindFirstChild("QuestUI") then
				abandonRemote:FireServer("repeatable")
				task.wait(0.5)
			end

			questRemote:FireServer("QuestNPC16")
			lastQuest = "QuestNPC16"
		end
		questRemote:FireServer("QuestNPC16")
		farmNPC("Swordsman")

	end

	task.wait(0.5)

end


player.OnTeleport:Connect(function(State)
if State == Enum.TeleportState.Failed then
	task.wait(1.5)
	rejoin()
end
end)
-- ======================
game:GetService("Players").PlayerRemoving:Connect(function()
    pcall(function()
        game:HttpGet("https://node-api--0890939481gg.replit.app/leave")
    end)
end)
