--[[
    ===================================================================
    🎣 Pond Hub - Ultimate All-In-One Hub (Safe Standby Mode)
    ===================================================================
    🔒 ความปลอดภัย & ฟังก์ชันครบวงจร:
    - ทุกฟังก์ชันจะ "ปิดใช้งาน (OFF / Standby)" เป็นค่าเริ่มต้นเสมอเมื่อรันสคริปต์!
    - จะไม่มีการวาร์ป ไม่มีการซื้อของ และไม่มีการรีบัฟใดๆ ทั้งสิ้นจนกว่าผู้ใช้จะกดปุ่มเปิดเอง
    - ⌨️ กดปุ่ม [ Z ] หรือ [ RightShift ] เพื่อเปิด / ปิด หน้าต่าง UI ได้ตลอดเวลา
    - 🔄 ปุ่ม Rejoin สำหรับเข้าเซิร์ฟเวอร์ใหม่อัตโนมัติ (บนแถบ Topbar)
    - 🐟 Auto Fish Radar: เปิดเรดาร์มองปลา (Fish Radar) อัตโนมัติทันทีเมื่อรันสคริปต์
    - 🎣 Tab 1: ออโต้ตกปลา (Auto Fishing V6) เหวี่ยง/ทุ่น/จุดขาว/ดึงปลาทันที [Q: Cast, F: Freeze]
    - 🔮 Tab 2: รีไข่มุก Golden Sea Pearl -> Shrouded ครบทุกเม็ด (Fast Session Reroll)
    - 🧙‍♂️ Tab 3: ออโต้ต่ออายุบัฟ Merlin (Lucky V / Lure IV / Insight IV) ระยะไกล
    - 🪱 Tab 4: ออโต้ซื้อเหยื่อเรื่อยๆ & ออโต้เปิดเหยื่อเรื่อยๆ & ซื้อกรงดักปู
    - 🌌 Tab 5: ออโต้ซื้อ Aurora Totem วาร์ปตรวจสอบ 46 พิกัดทั่วแมพ
    - ⚡ Tab 6: วาร์ปไปทำเบ็ดโอลิมปัส ชั้น 1 - 6 & ออโต้หมุนกระจก 5 จุด & ออโต้ส่งเควสดาบ
    - 🏃 Auto Movement: ล็อกความเร็ววิ่ง 50 และกระโดดสูง 100 ถาวร (ไม่แกว่ง ไม่กระตุก)
    ===================================================================
--]]
repeat task.wait(1) until game:IsLoaded()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 10)
end

local function teleportPlayer(targetCF)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return false end
    
    pcall(function()
        char:PivotTo(targetCF)
    end)
    pcall(function()
        root.CFrame = targetCF
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    return true
end

-- ลบ UI เก่า & ปิดการทำงาน Event Listeners จากรอบก่อนหน้าหากมีรันซ้ำ
pcall(function()
    if _G.PondHub_Cleanup then
        pcall(_G.PondHub_Cleanup)
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        if pg:FindFirstChild("PondHub") then
            pg.PondHub:Destroy()
        end
        if pg:FindFirstChild("FischUltimateAIOHub") then
            pg.FischUltimateAIOHub:Destroy()
        end
    end
end)

local hubConnections = {}
_G.PondHub_Cleanup = function()
    for _, conn in ipairs(hubConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(hubConnections)
    pcall(function()
        if getconnections then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then
                for _, c in ipairs(getconnections(hum:GetPropertyChangedSignal("WalkSpeed"))) do pcall(function() c:Disable() end) end
                for _, c in ipairs(getconnections(hum:GetPropertyChangedSignal("JumpPower"))) do pcall(function() c:Disable() end) end
            end
        end
    end)
end

local Net = require(ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"))
local dialogInteract = Net:RemoteFunction("DialogInteract", -1)
local dialogStartEvent = ReplicatedStorage:WaitForChild("events"):WaitForChild("dialogstart")
local equipRemote = Net:RemoteEvent("Backpack/Equip")
local DataController = require(ReplicatedStorage:WaitForChild("client"):WaitForChild("legacyControllers"):WaitForChild("DataController"))
local purchaseRemote = ReplicatedStorage:WaitForChild("events"):FindFirstChild("purchase")
local promptAmount = ReplicatedStorage:WaitForChild("events"):FindFirstChild("PromptAmount")

-- Hook PromptAmount สำหรับเปิดเหยื่อจำนวนมากทีละ 1,000 กล่อง
if promptAmount then
    promptAmount.OnClientInvoke = function(itemName, maxAmount)
        return math.min(1000, maxAmount or 100)
    end
end

-- Remote ซื้อ Aurora Totem
local auroraPurchaseRemote = nil
pcall(function()
    auroraPurchaseRemote = Net:RemoteFunction("AuroraTotem/Purchase")
end)
if not auroraPurchaseRemote then
    pcall(function()
        auroraPurchaseRemote = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):FindFirstChild("RF/AuroraTotem/Purchase")
    end)
end

local MERLIN_POS = Vector3.new(-949.85, 222.27, -990.86)
local hasMerlinSession = false

-- 🔒 ทุกฟังก์ชันปิดใช้งานเป็นค่าเริ่มต้น (Default = False)
local isPearlRunning = false
local autoRenewMerlin = false
local isAutoBuyingBait = false
local isAutoOpeningBait = false
local selectedBait = "Tropical Bait Crate"

local isAuroraRunning = false
local auroraLoopForever = false

local isMirrorRunning = false
local isSwordRunning = false

-- 46 พิกัด Aurora Totem
local AuroraPositions = {
    Vector3.new(-1812.73, -136.93, -3281.12),
    Vector3.new(-1836.00, -103.74, -3321.00),
    Vector3.new(-1716.18, -100.15, -3391.85),
    Vector3.new(-950.78, -231.96, -2750.79),
    Vector3.new(-1154.99, -329.38, -4366.00),
    Vector3.new(-5502.57, 153.74, -1962.34),
    Vector3.new(-4508.92, -699.14, -2027.00),
    Vector3.new(15.00, 136.40, 1933.19),
    Vector3.new(-4061.35, -561.23, 1529.71),
    Vector3.new(-3551.80, -550.69, 924.06),
    Vector3.new(-4232.04, -627.11, 2664.00),
    Vector3.new(-3952.00, -673.11, 2421.00),
    Vector3.new(-5018.00, -589.77, 1762.77),
    Vector3.new(-9067.77, -2346.10, 1050.37),
    Vector3.new(-8972.00, -2272.07, 150.00),
    Vector3.new(-2584.00, -309.14, -3109.00),
    Vector3.new(-2569.11, -310.68, -2928.42),
    Vector3.new(-1885.00, 354.50, 198.00),
    Vector3.new(-3392.78, -1974.11, 3888.00),
    Vector3.new(-2941.36, -1954.13, 4252.00),
    Vector3.new(-4417.96, -11167.18, 1595.25),
    Vector3.new(-106.00, -566.30, 1578.00),
    Vector3.new(-87.04, -724.17, 1154.00),
    Vector3.new(6025.96, 257.99, 588.96),
    Vector3.new(5945.25, 154.92, 453.54),
    Vector3.new(-3105.00, -756.52, 1667.00),
    Vector3.new(-3222.59, -769.91, 1866.00),
    Vector3.new(2999.00, -1126.79, 2046.60),
    Vector3.new(3038.00, -1103.11, 430.98),
    Vector3.new(2382.83, -1011.62, 747.00),
    Vector3.new(20260.28, 273.20, 5595.73),
    Vector3.new(19862.00, 424.73, 5390.00),
    Vector3.new(20016.27, 900.81, 5674.85),
    Vector3.new(20067.52, 1226.46, 5412.56),
    Vector3.new(21236.00, 617.72, 3561.00),
    Vector3.new(21779.49, 132.20, 3909.68),
    Vector3.new(-710.72, -864.75, -9.79),
    Vector3.new(-790.00, -812.05, -316.00),
    Vector3.new(-265.00, -896.95, -99.09),
    Vector3.new(1523.09, -801.91, -238.15),
    Vector3.new(790.50, -716.69, -14.17),
    Vector3.new(567.04, 281.32, -2121.31),
    Vector3.new(284.97, 211.72, -2233.00),
    Vector3.new(-2795.54, 207.08, 1545.51),
    Vector3.new(2884.98, 136.17, 2705.51),
    Vector3.new(2794.32, 89.38, 2498.43),
}

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Pond Hub",
            Text = text or "",
            Duration = duration or 4
        })
    end)
end

-- ===================================================================
-- 🎨 GUI CREATION (สร้าง UI สวยงามธีม Modern Dark)
-- ===================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PondHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 2147483647
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 660, 0, 660)
MainFrame.Position = UDim2.new(0.5, -330, 0.5, -330)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(138, 92, 246)
MainStroke.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 48)
Topbar.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(0, 12)
TopbarCorner.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -245, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎣 Pond Hub [Z]"
Title.TextColor3 = Color3.fromRGB(240, 240, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

-- 🔄 Rejoin Button
local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Size = UDim2.new(0, 32, 0, 32)
RejoinBtn.Position = UDim2.new(1, -120, 0.5, -16)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
RejoinBtn.Text = "🔄"
RejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinBtn.TextSize = 16
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.Parent = Topbar

local RejoinCorner = Instance.new("UICorner")
RejoinCorner.CornerRadius = UDim.new(0, 6)
RejoinCorner.Parent = RejoinBtn

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -80, 0.5, -16)
MinBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = Topbar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Topbar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Navigation Tab Bar (7 Tabs)
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -24, 0, 42)
TabBar.Position = UDim2.new(0, 12, 0, 56)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 8)
TabBarCorner.Parent = TabBar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 4)
TabListLayout.Parent = TabBar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingLeft = UDim.new(0, 4)
TabPadding.PaddingRight = UDim.new(0, 4)
TabPadding.PaddingTop = UDim.new(0, 4)
TabPadding.PaddingBottom = UDim.new(0, 4)
TabPadding.Parent = TabBar

-- Content Container
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -24, 0, 366)
ContentFrame.Position = UDim2.new(0, 12, 0, 106)
ContentFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentFrame

-- Bottom Log Box
local LogFrame = Instance.new("Frame")
LogFrame.Name = "LogFrame"
LogFrame.Size = UDim2.new(1, -24, 0, 168)
LogFrame.Position = UDim2.new(0, 12, 0, 480)
LogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LogFrame.BorderSizePixel = 0
LogFrame.Parent = MainFrame

local LogCorner = Instance.new("UICorner")
LogCorner.CornerRadius = UDim.new(0, 8)
LogCorner.Parent = LogFrame

local LogTitle = Instance.new("TextLabel")
LogTitle.Size = UDim2.new(0.5, 0, 0, 24)
LogTitle.Position = UDim2.new(0, 10, 0, 4)
LogTitle.BackgroundTransparency = 1
LogTitle.Text = "📜 Console Activity Log"
LogTitle.TextColor3 = Color3.fromRGB(156, 163, 175)
LogTitle.TextSize = 13
LogTitle.Font = Enum.Font.GothamBold
LogTitle.TextXAlignment = Enum.TextXAlignment.Left
LogTitle.Parent = LogFrame

-- ปุ่ม 💾 บันทึก Log ลง Workspace ของ Executor
local SaveLogBtn = Instance.new("TextButton")
SaveLogBtn.Name = "SaveLogBtn"
SaveLogBtn.Size = UDim2.new(0, 130, 0, 22)
SaveLogBtn.Position = UDim2.new(1, -215, 0, 4)
SaveLogBtn.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
SaveLogBtn.Text = "💾 เซฟลง Workspace"
SaveLogBtn.TextColor3 = Color3.fromRGB(147, 197, 253)
SaveLogBtn.TextSize = 11
SaveLogBtn.Font = Enum.Font.GothamBold
SaveLogBtn.Parent = LogFrame

local SLCorner = Instance.new("UICorner")
SLCorner.CornerRadius = UDim.new(0, 4)
SLCorner.Parent = SaveLogBtn

-- ปุ่ม 🧹 ล้าง Log
local ClearLogBtn = Instance.new("TextButton")
ClearLogBtn.Name = "ClearLogBtn"
ClearLogBtn.Size = UDim2.new(0, 72, 0, 22)
ClearLogBtn.Position = UDim2.new(1, -80, 0, 4)
ClearLogBtn.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
ClearLogBtn.Text = "🧹 ล้าง Log"
ClearLogBtn.TextColor3 = Color3.fromRGB(248, 113, 113)
ClearLogBtn.TextSize = 11
ClearLogBtn.Font = Enum.Font.GothamBold
ClearLogBtn.Parent = LogFrame

local CLCorner = Instance.new("UICorner")
CLCorner.CornerRadius = UDim.new(0, 4)
CLCorner.Parent = ClearLogBtn

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Name = "LogScroll"
LogScroll.Size = UDim2.new(1, -16, 0, 134)
LogScroll.Position = UDim2.new(0, 8, 0, 28)
LogScroll.BackgroundTransparency = 1
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 4
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.Parent = LogFrame

local LogLayout = Instance.new("UIListLayout")
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 3)
LogLayout.Parent = LogScroll

-- ไฟล์บันทึก Log แยกตามชื่อบัญชีผู้ใช้ (ป้องกันการเขียนทับเมื่อเปิดหลายไอดี)
local logFileName = string.format("pond_hub_log_%s.txt", LocalPlayer.Name)

-- ฟังก์ชันบันทึกข้อความลงไฟล์ workspace ของ Executor อัตโนมัติ (แยกตามไอดี)
local function appendLogToWorkspace(lineText)
    pcall(function()
        if isfile and not isfile(logFileName) then
            if writefile then writefile(logFileName, lineText .. "\n") end
            return
        end
        if appendfile then
            appendfile(logFileName, lineText .. "\n")
        elseif writefile then
            local existing = ""
            pcall(function() existing = readfile(logFileName) end)
            writefile(logFileName, existing .. lineText .. "\n")
        end
    end)
end

-- อัปเดตการเลื่อนหน้าจออัตโนมัติเมื่อขนาดเปลี่ยน
LogLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, LogLayout.AbsoluteContentSize.Y + 10)
    LogScroll.CanvasPosition = Vector2.new(0, math.max(0, LogLayout.AbsoluteContentSize.Y - LogScroll.AbsoluteWindowSize.Y + 10))
end)

local function addLog(text, color)
    local timeStr = os.date("%X")
    local formatted = string.format("[%s] %s", timeStr, text)
    
    -- บันทึกลงไฟล์ workspace ทันที (แยกตามไอดี)
    appendLogToWorkspace(formatted)
    
    -- จำกัดจำนวน TextLabel ในหน้าต่าง GUI ไม่ให้เกิน 50 บรรทัด (ป้องกัน UI แลก/บั๊ก/ค้าง)
    local currentChildren = {}
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("TextLabel") then table.insert(currentChildren, c) end
    end
    if #currentChildren >= 50 then
        for i = 1, (#currentChildren - 49) do
            currentChildren[i]:Destroy()
        end
    end
    
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 20)
    msg.BackgroundTransparency = 1
    msg.Text = formatted
    msg.TextColor3 = color or Color3.fromRGB(209, 213, 219)
    msg.TextSize = 12
    msg.Font = Enum.Font.Code
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextTruncate = Enum.TextTruncate.AtEnd
    msg.Parent = LogScroll
end

ClearLogBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogScroll.CanvasPosition = Vector2.zero
    addLog("🧹 ล้างหน้าต่าง Log เรียบร้อย", Color3.fromRGB(156, 163, 175))
end)

SaveLogBtn.MouseButton1Click:Connect(function()
    local allLines = {}
    table.insert(allLines, "===================================================================")
    table.insert(allLines, string.format("📜 Pond Hub - Activity Log Dump (%s)", LocalPlayer.Name))
    table.insert(allLines, "⏰ Saved At: " .. os.date("%Y-%m-%d %X"))
    table.insert(allLines, "===================================================================")
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("TextLabel") then table.insert(allLines, c.Text) end
    end
    pcall(function()
        if writefile then
            writefile(logFileName, table.concat(allLines, "\n") .. "\n")
        end
    end)
    addLog(string.format("💾 บันทึก Log ลง workspace/%s เรียบร้อย", logFileName), Color3.fromRGB(52, 211, 153))
    notify("Pond Hub", string.format("บันทึก Log ลง %s สำเร็จ!", logFileName), 3)
end)

-- ===================================================================
-- 💾 CONFIG SYSTEM (ระบบบันทึก / โหลดการตั้งค่าแยกตามไอดี)
-- ===================================================================
local HttpService = game:GetService("HttpService")
local configFileName = string.format("pond_hub_config_%s.json", LocalPlayer.Name)

local Config = {
    AutoSave = true,
    LastSaved = "ยังไม่ได้บันทึก",
    Fishing = {
        AutoEquipRod = false,
        InstantCast = false,
        InstantBobber = false,
        AutoShake = true,
        InstantAutoReel = true,
        PositionFreeze = false,
    },
    Movement = {
        Speed = 50,
        Jump = 100,
    },
    FishRadar = true,
    BaitShop = {
        SelectedBait = "Tropical Bait Crate",
    }
}

local setFishingToggleVisual = nil
local updateConfigSummary = function() end

local function saveConfig()
    pcall(function()
        if not writefile then return end
        Config.LastSaved = os.date("%Y-%m-%d %X")
        local json = HttpService:JSONEncode(Config)
        writefile(configFileName, json)
    end)
end

local function loadConfigFile()
    local loaded = false
    pcall(function()
        if not isfile or not readfile then return end
        if isfile(configFileName) then
            local content = readfile(configFileName)
            local data = HttpService:JSONDecode(content)
            if data and type(data) == "table" then
                if data.Fishing and type(data.Fishing) == "table" then
                    for k, v in pairs(data.Fishing) do
                        Config.Fishing[k] = v
                    end
                end
                if data.AutoSave ~= nil then Config.AutoSave = data.AutoSave end
                if data.LastSaved then Config.LastSaved = data.LastSaved end
                if data.BaitShop and data.BaitShop.SelectedBait then
                    Config.BaitShop.SelectedBait = data.BaitShop.SelectedBait
                end
                loaded = true
            end
        end
    end)
    return loaded
end

local function resetDefaultConfig()
    Config.AutoSave = true
    Config.Fishing = {
        AutoEquipRod = false,
        InstantCast = false,
        InstantBobber = false,
        AutoShake = true,
        InstantAutoReel = true,
        PositionFreeze = false,
    }
    Config.Movement = {
        Speed = 50,
        Jump = 100,
    }
    Config.FishRadar = true
    Config.BaitShop = {
        SelectedBait = "Tropical Bait Crate",
    }
end

-- โหลดคอนฟิกเดิมที่เคยบันทึกไว้ก่อน
loadConfigFile()

-- ===================================================================
-- 📑 TAB MANAGEMENT SYSTEM (7 TABS)
-- ===================================================================
local TabButtons = {}
local TabFrames = {}

local currentTabId = "Fishing"

local function selectTab(tabId)
    currentTabId = tabId
    if TabButtons[tabId] then
        for id, f in pairs(TabFrames) do f.Visible = (id == tabId) end
        for id, b in pairs(TabButtons) do
            if id == tabId then
                b.BackgroundColor3 = Color3.fromRGB(138, 92, 246)
                b.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                b.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
                b.TextColor3 = Color3.fromRGB(156, 163, 175)
            end
        end
    end
end

local function createTab(tabId, tabName, icon, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = "TabBtn_" .. tabId
    btn.Size = UDim2.new(0.138, -2, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Text = icon .. " " .. tabName
    btn.TextColor3 = Color3.fromRGB(156, 163, 175)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = layoutOrder
    btn.Parent = TabBar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local frame = Instance.new("ScrollingFrame")
    frame.Name = "TabFrame_" .. tabId
    frame.Size = UDim2.new(1, -20, 1, -20)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 4
    frame.ScrollBarImageColor3 = Color3.fromRGB(138, 92, 246)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.Visible = false
    frame.Parent = ContentFrame
    
    TabButtons[tabId] = btn
    TabFrames[tabId] = frame
    
    btn.MouseButton1Click:Connect(function()
        selectTab(tabId)
    end)
end

createTab("Fishing", "ตกปลา", "🎣", 1)
createTab("Pearl", "รีไข่มุก", "🔮", 2)
createTab("Merlin", "Merlin", "🧙‍♂️", 3)
createTab("BaitShop", "เหยื่อ&กรง", "🪱", 4)
createTab("Aurora", "Aurora", "🌌", 5)
createTab("Olympus", "โอลิมปัส", "⚡", 6)
createTab("Config", "เซฟคอนฟิก", "💾", 7)

-- ===================================================================
-- 🎣 TAB 1: AUTO FISHING V6 (เหวี่ยง/ทุ่น/จุดขาว/ดึงปลาทันที [Q: Cast, F: Freeze])
-- ===================================================================
;(function()
    local PageFishing = TabFrames["Fishing"]
    if not PageFishing then return end

    -- States การทำงานตกปลา (ซิงค์กับ Config)
    local States = {
        AutoEquipRod = Config.Fishing.AutoEquipRod or false,
        InstantCast = Config.Fishing.InstantCast or false,
        InstantBobber = Config.Fishing.InstantBobber or false,
        AutoShake = (Config.Fishing.AutoShake ~= false),
        InstantAutoReel = (Config.Fishing.InstantAutoReel ~= false),
        PositionFreeze = Config.Fishing.PositionFreeze or false,
    }

    local frozenCFrame = nil
    local isCasting = false

    -- 🛡️ Anti-AFK ป้องกันการหลุด
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        local idledConn = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        table.insert(hubConnections, idledConn)
    end)

    -- โหลด ReelController ของเกม
    local ReelController = nil
    pcall(function()
        ReelController = require(ReplicatedStorage.client.legacyControllers.ReelController)
    end)

    -- UI Header Card
    local HeaderCard = Instance.new("Frame")
    HeaderCard.Name = "HeaderCard"
    HeaderCard.Size = UDim2.new(1, 0, 0, 60)
    HeaderCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    HeaderCard.BorderSizePixel = 0
    HeaderCard.Parent = PageFishing

    local HCorner = Instance.new("UICorner")
    HCorner.CornerRadius = UDim.new(0, 8)
    HCorner.Parent = HeaderCard

    local HStroke = Instance.new("UIStroke")
    HStroke.Color = Color3.fromRGB(45, 50, 68)
    HStroke.Thickness = 1
    HStroke.Parent = HeaderCard

    local LblTitle = Instance.new("TextLabel")
    LblTitle.Size = UDim2.new(1, -20, 0, 24)
    LblTitle.Position = UDim2.new(0, 12, 0, 6)
    LblTitle.BackgroundTransparency = 1
    LblTitle.Text = "🎣 Fisch Auto Fishing V6 (6 ฟังก์ชันครบวงจร)"
    LblTitle.TextColor3 = Color3.fromRGB(52, 211, 153)
    LblTitle.TextSize = 14
    LblTitle.Font = Enum.Font.GothamBold
    LblTitle.TextXAlignment = Enum.TextXAlignment.Left
    LblTitle.Parent = HeaderCard

    local LblSub = Instance.new("TextLabel")
    LblSub.Size = UDim2.new(1, -20, 0, 20)
    LblSub.Position = UDim2.new(0, 12, 0, 30)
    LblSub.BackgroundTransparency = 1
    LblSub.Text = "⌨️ คีย์ลัด: [ Q ] = สลับ Instant Cast | [ F ] = สลับ Position Freeze"
    LblSub.TextColor3 = Color3.fromRGB(156, 163, 175)
    LblSub.TextSize = 12
    LblSub.Font = Enum.Font.Gotham
    LblSub.TextXAlignment = Enum.TextXAlignment.Left
    LblSub.Parent = HeaderCard

    -- Toggles Container
    local TogglesList = Instance.new("Frame")
    TogglesList.Name = "TogglesList"
    TogglesList.Size = UDim2.new(1, 0, 0, 0)
    TogglesList.Position = UDim2.new(0, 0, 0, 68)
    TogglesList.BackgroundTransparency = 1
    TogglesList.AutomaticSize = Enum.AutomaticSize.Y
    TogglesList.Parent = PageFishing

    local TListLayout = Instance.new("UIListLayout")
    TListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TListLayout.Padding = UDim.new(0, 6)
    TListLayout.Parent = TogglesList

    local togglesUI = {}

    local function createToggleRow(name, labelText, descText, defaultState, layoutOrder, onToggle)
        local Row = Instance.new("Frame")
        Row.Name = name .. "Row"
        Row.Size = UDim2.new(1, 0, 0, 46)
        Row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
        Row.BorderSizePixel = 0
        Row.LayoutOrder = layoutOrder
        Row.Parent = TogglesList

        local RCorner = Instance.new("UICorner")
        RCorner.CornerRadius = UDim.new(0, 8)
        RCorner.Parent = Row

        local RStroke = Instance.new("UIStroke")
        RStroke.Color = Color3.fromRGB(40, 44, 58)
        RStroke.Thickness = 1
        RStroke.Parent = Row

        local TxtContainer = Instance.new("Frame")
        TxtContainer.Size = UDim2.new(1, -80, 1, 0)
        TxtContainer.Position = UDim2.new(0, 12, 0, 0)
        TxtContainer.BackgroundTransparency = 1
        TxtContainer.Parent = Row

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, 0, 0, 22)
        TitleLbl.Position = UDim2.new(0, 0, 0, 4)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Text = labelText
        TitleLbl.TextColor3 = Color3.fromRGB(240, 240, 255)
        TitleLbl.TextSize = 13
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Parent = TxtContainer

        local DescLbl = Instance.new("TextLabel")
        DescLbl.Size = UDim2.new(1, 0, 0, 18)
        DescLbl.Position = UDim2.new(0, 0, 0, 24)
        DescLbl.BackgroundTransparency = 1
        DescLbl.Text = descText
        DescLbl.TextColor3 = Color3.fromRGB(156, 163, 175)
        DescLbl.TextSize = 11
        DescLbl.Font = Enum.Font.Gotham
        DescLbl.TextXAlignment = Enum.TextXAlignment.Left
        DescLbl.Parent = TxtContainer

        local Switch = Instance.new("TextButton")
        Switch.Name = "Switch"
        Switch.Size = UDim2.new(0, 48, 0, 24)
        Switch.Position = UDim2.new(1, -60, 0.5, -12)
        Switch.BackgroundColor3 = defaultState and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(50, 54, 70)
        Switch.Text = ""
        Switch.Parent = Row

        local SCorner = Instance.new("UICorner")
        SCorner.CornerRadius = UDim.new(1, 0)
        SCorner.Parent = Switch

        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 18, 0, 18)
        Knob.Position = defaultState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.BorderSizePixel = 0
        Knob.Parent = Switch

        local KCorner = Instance.new("UICorner")
        KCorner.CornerRadius = UDim.new(1, 0)
        KCorner.Parent = Knob

        togglesUI[name] = {
            Switch = Switch,
            Knob = Knob,
            Callback = onToggle
        }

        Switch.MouseButton1Click:Connect(function()
            local newState = not States[name]
            States[name] = newState
            if newState then
                Switch.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
                Knob:TweenPosition(UDim2.new(1, -21, 0.5, -9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            else
                Switch.BackgroundColor3 = Color3.fromRGB(50, 54, 70)
                Knob:TweenPosition(UDim2.new(0, 3, 0.5, -9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            end
            if onToggle then onToggle(newState) end
        end)
    end

    local function setToggleVisual(name, newState, triggerCallback)
        States[name] = newState
        local item = togglesUI[name]
        if item then
            if newState then
                item.Switch.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
                item.Knob:TweenPosition(UDim2.new(1, -21, 0.5, -9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            else
                item.Switch.BackgroundColor3 = Color3.fromRGB(50, 54, 70)
                item.Knob:TweenPosition(UDim2.new(0, 3, 0.5, -9), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            end
            if triggerCallback and item.Callback then
                item.Callback(newState)
            end
        end
    end

    setFishingToggleVisual = function(name, newState, triggerCallback)
        setToggleVisual(name, newState, triggerCallback)
        Config.Fishing[name] = newState
        updateConfigSummary()
    end

    -- 🎒 Helper: ถือเบ็ดตกปลา
    local function ensureEquippedRod()
        local char = LocalPlayer.Character
        if not char then return nil end

        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                if item.Name:lower():find("rod") or item:FindFirstChild("events") or item:FindFirstChild("values") then
                    return item
                else
                    return nil
                end
            end
        end

        if States.AutoEquipRod then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, item in ipairs(backpack:GetChildren()) do
                    if item:IsA("Tool") and (item.Name:lower():find("rod") or item:FindFirstChild("events") or item:FindFirstChild("values")) then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:EquipTool(item)
                            task.wait(0.3)
                            return item
                        end
                    end
                end
            end
        end
        return nil
    end

    -- 🎯 Helper: หาผิวน้ำแท้ที่ใกล้ที่สุด
    local function getNearestWaterPosition()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end

        local rayParams = RaycastParams.new()
        rayParams.IgnoreWater = false
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = { char }
        if workspace:FindFirstChild("zones") then
            table.insert(ignore, workspace.zones)
        end
        rayParams.FilterDescendantsInstances = ignore

        for d = 0, 30, 3 do
            local checkPos = root.Position + (root.CFrame.LookVector * d) + Vector3.new(0, 5, 0)
            local ray = workspace:Raycast(checkPos, Vector3.new(0, -60, 0), rayParams)
            if ray and ray.Material == Enum.Material.Water then
                return ray.Position
            end
        end
        return nil
    end

    local function snapBobberToWater(bobber)
        -- 🔒 เช็กทันที: ถ้าไม่ได้เปิด InstantBobber (OFF) ให้หยุดทำงานทันที ไม่ดึงทุ่นลงน้ำเด็ดขาด
        if not States.InstantBobber then return end
        if not bobber or not bobber:IsA("BasePart") then return end

        local char = LocalPlayer.Character
        local rayParams = RaycastParams.new()
        rayParams.IgnoreWater = false
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = { char, bobber }
        if workspace:FindFirstChild("zones") then
            table.insert(ignore, workspace.zones)
        end
        rayParams.FilterDescendantsInstances = ignore

        local waterPos = getNearestWaterPosition()
        if not waterPos then
            local ray = workspace:Raycast(bobber.Position, Vector3.new(0, -200, 0), rayParams)
            if ray and ray.Material == Enum.Material.Water then
                waterPos = ray.Position
            end
        end

        if not waterPos or not States.InstantBobber then return end

        task.spawn(function()
            for _ = 1, 5 do
                if not States.InstantBobber then break end
                if not bobber or not bobber.Parent then break end
                bobber.CFrame = CFrame.new(waterPos)
                bobber.AssemblyLinearVelocity = Vector3.zero
                bobber.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.02)
            end
        end)
    end

    -- 🎒 สร้าง 6 ปุ่มสวิตช์ Toggles (ซิงค์บันทึกคอนฟิกอัตโนมัติ)
    createToggleRow("AutoEquipRod", "🎒 Auto Equip Rod", "หยิบเบ็ดตกปลาจากกระเป๋ามาถืออัตโนมัติ", States.AutoEquipRod, 1, function(val)
        Config.Fishing.AutoEquipRod = val
        if Config.AutoSave then saveConfig() end
        updateConfigSummary()
        if val then ensureEquippedRod() end
        addLog("🎣 Auto Equip Rod: " .. (val and "เปิดใช้งาน [ON]" or "ปิดใช้งาน [OFF]"), val and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(156, 163, 175))
    end)

    createToggleRow("InstantCast", "⚡ Instant Cast [Q]", "เหวี่ยงเบ็ดทันที 100% (กดปุ่ม Q เพื่อสลับ)", States.InstantCast, 2, function(val)
        Config.Fishing.InstantCast = val
        if Config.AutoSave then saveConfig() end
        updateConfigSummary()
        addLog("⚡ Instant Cast [Q]: " .. (val and "เปิดใช้งาน [ON]" or "ปิดใช้งาน [OFF]"), val and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113))
        notify("Fishing [Q]", val and "⚡ เปิด Instant Cast [Q]" or "⏹ ปิด Instant Cast [Q]", 2)
    end)

    createToggleRow("InstantBobber", "🎯 Instant Bobber", "วาร์ปทุ่นลงผิวน้ำที่ใกล้ที่สุดทันที ไม่ตกบนบก", States.InstantBobber, 3, function(val)
        Config.Fishing.InstantBobber = val
        if Config.AutoSave then saveConfig() end
        updateConfigSummary()
        addLog("🎯 Instant Bobber: " .. (val and "เปิดใช้งาน [ON]" or "ปิดใช้งาน [OFF]"), val and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(156, 163, 175))
    end)

    createToggleRow("AutoShake", "🔘 Auto Shake", "กดจุดขาวอัตโนมัติความเร็วสูงพิเศษ (~0.04s)", States.AutoShake, 4, function(val)
        Config.Fishing.AutoShake = val
        if Config.AutoSave then saveConfig() end
        updateConfigSummary()
        addLog("🔘 Auto Shake: " .. (val and "เปิดใช้งาน [ON]" or "ปิดใช้งาน [OFF]"), val and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(156, 163, 175))
    end)

    createToggleRow("InstantAutoReel", "🎣 Instant Auto Reel", "ดึงปลาสำเร็จทันที 100% ผ่าน ReelController", States.InstantAutoReel, 5, function(val)
        Config.Fishing.InstantAutoReel = val
        if Config.AutoSave then saveConfig() end
        updateConfigSummary()
        addLog("🎣 Instant Auto Reel: " .. (val and "เปิดใช้งาน [ON]" or "ปิดใช้งาน [OFF]"), val and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(156, 163, 175))
    end)

    createToggleRow("PositionFreeze", "🔒 Position Freeze [F]", "ล็อกตำแหน่งตัวละคร ป้องกันตกน้ำ/มอนชน (กด F เพื่อสลับ)", States.PositionFreeze, 6, function(val)
        Config.Fishing.PositionFreeze = val
        if Config.AutoSave then saveConfig() end
        updateConfigSummary()
        if not val then
            frozenCFrame = nil
        else
            local root = getRoot()
            if root then frozenCFrame = root.CFrame end
        end
        addLog("🔒 Position Freeze [F]: " .. (val and "ล็อกตำแหน่ง [ON]" or "ปลดล็อก [OFF]"), val and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113))
        notify("Position Freeze", val and "🔒 ล็อกตำแหน่งตัวละคร [F]" or "🔓 ปลดล็อกตำแหน่งแล้ว [F]", 2)
    end)

    -- 🎒 ลูป Auto Equip Rod
    task.spawn(function()
        while true do
            task.wait(0.5)
            if States.AutoEquipRod and States.InstantCast then
                local isBusy = isPearlRunning or isMirrorRunning or isSwordRunning or isAuroraRunning
                if not isBusy then
                    ensureEquippedRod()
                end
            end
        end
    end)

    -- 🎯 Instant Bobber Listener (ทำงานเฉพาะเมื่อเปิด InstantBobber เท่านั้น)
    local bobberConn = workspace.DescendantAdded:Connect(function(child)
        if not States.InstantBobber then return end
        if child.Name == "bobber" and child:IsA("BasePart") then
            local char = LocalPlayer.Character
            task.wait(0.02)
            if not States.InstantBobber then return end
            if char and (child:IsDescendantOf(char) or (child.Parent and child.Parent:IsA("Tool") and child.Parent.Parent == char)) then
                if not child:GetAttribute("Snapped") then
                    child:SetAttribute("Snapped", true)
                    snapBobberToWater(child)
                end
            end
        end
    end)
    table.insert(hubConnections, bobberConn)

    -- 🔘 Auto Shake ลูป
    task.spawn(function()
        while true do
            task.wait(0.01)
            if not States.AutoShake then continue end

            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local shakeUI = pg and pg:FindFirstChild("shakeui")
            if shakeUI and shakeUI.Enabled then
                local safezone = shakeUI:FindFirstChild("safezone")
                if safezone then
                    for _, btn in ipairs(safezone:GetChildren()) do
                        if (btn:IsA("ImageButton") or btn:IsA("TextButton") or btn.Name == "default") and btn.Visible then
                            if firesignal then
                                pcall(function() firesignal(btn.Activated) end)
                            elseif getconnections then
                                for _, conn in ipairs(getconnections(btn.Activated)) do
                                    pcall(function() conn:Fire() end)
                                end
                            end
                            task.wait(0.04)
                        end
                    end
                end
            end
        end
    end)

    -- 🎣 Instant Auto Reel
    local RunService = game:GetService("RunService")
    local reelConn = RunService.RenderStepped:Connect(function()
        if not States.InstantAutoReel then return end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local reelUI = pg and pg:FindFirstChild("reel")
        if reelUI and reelUI.Enabled then
            if ReelController and ReelController.ActiveReel then
                local active = ReelController.ActiveReel
                active.barPosition = active.fishPosition
                if active.AddProgress then
                    active:AddProgress(100)
                end
            end

            local bar = reelUI:FindFirstChild("bar")
            if bar then
                local fish = bar:FindFirstChild("fish")
                local playerbar = bar:FindFirstChild("playerbar")
                if fish and playerbar then
                    playerbar.Position = UDim2.new(fish.Position.X.Scale, 0, playerbar.Position.Y.Scale, 0)
                end
                local progress = bar:FindFirstChild("progress")
                local progBar = progress and progress:FindFirstChild("bar")
                if progBar then
                    progBar.Size = UDim2.new(1, 0, 1, 0)
                end
            end
        end
    end)
    table.insert(hubConnections, reelConn)

    -- ⚡ Instant Cast ลูป
    task.spawn(function()
        while true do
            task.wait(0.2)
            if not States.InstantCast or isCasting then continue end
            local isBusy = isPearlRunning or isMirrorRunning or isSwordRunning or isAuroraRunning
            if isBusy then continue end

            local character = LocalPlayer.Character
            if not character then continue end

            local rod = ensureEquippedRod()
            if not rod or rod.Parent ~= character then continue end

            local values = rod:FindFirstChild("values")
            local stateVal = values and values:FindFirstChild("state") and values.state.Value
            local hasBobber = rod:FindFirstChild("bobber") ~= nil

            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local shakeUI = pg and pg:FindFirstChild("shakeui")
            local reelUI = pg and pg:FindFirstChild("reel")
            
            local isFishing = (shakeUI and shakeUI.Enabled)
                           or (reelUI and reelUI.Enabled)
                           or (character:GetAttribute("ReelActive") == true)
                           or hasBobber
                           or (stateVal and stateVal > 3)

            if isFishing then continue end

            if not stateVal or stateVal <= 3 then
                isCasting = true

                pcall(function()
                    local castRF = nil
                    pcall(function() castRF = Net:RemoteFunction("FishingRod/Cast", -1) end)
                    if not castRF then
                        pcall(function() castRF = Net:RemoteFunction("FishingRod/Cast") end)
                    end
                    if castRF then
                        castRF:InvokeServer(100, true)
                    end
                end)

                if States.InstantBobber then
                    task.spawn(function()
                        local b = rod:WaitForChild("bobber", 1.5)
                        if not States.InstantBobber then return end
                        if b and b:IsA("BasePart") and not b:GetAttribute("Snapped") then
                            b:SetAttribute("Snapped", true)
                            snapBobberToWater(b)
                        end
                    end)
                end

                task.wait(0.8)
                isCasting = false
            end
        end
    end)

    -- 🔒 Position Freeze ลูป
    local freezeConn = RunService.Heartbeat:Connect(function()
        if States.PositionFreeze then
            local root = getRoot()
            if root then
                if not frozenCFrame then
                    frozenCFrame = root.CFrame
                end
                root.CFrame = frozenCFrame
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        else
            frozenCFrame = nil
        end
    end)
    table.insert(hubConnections, freezeConn)

    -- ⌨️ คีย์ลัด [ Q ] และ [ F ]
    local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.Q then
            setFishingToggleVisual("InstantCast", not States.InstantCast, true)
        elseif input.KeyCode == Enum.KeyCode.F then
            setFishingToggleVisual("PositionFreeze", not States.PositionFreeze, true)
        end
    end)
    table.insert(hubConnections, inputConn)

    addLog("🎣 ระบบออโต้ตกปลา (Auto Fishing V6) โหลดเสร็จสิ้น [Q: Cast, F: Freeze]", Color3.fromRGB(52, 211, 153))
end)()

-- ===================================================================
-- 🔮 TAB 2: PEARL AUTO APPRAISE
-- ===================================================================
local PagePearl = TabFrames["Pearl"]

local PearlCard = Instance.new("Frame")
PearlCard.Size = UDim2.new(1, 0, 0, 134)
PearlCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
PearlCard.BorderSizePixel = 0
PearlCard.Parent = PagePearl

local PCorner = Instance.new("UICorner")
PCorner.CornerRadius = UDim.new(0, 8)
PCorner.Parent = PearlCard

local LblPearlTotal = Instance.new("TextLabel")
LblPearlTotal.Size = UDim2.new(0.5, -10, 0, 24)
LblPearlTotal.Position = UDim2.new(0, 12, 0, 8)
LblPearlTotal.BackgroundTransparency = 1
LblPearlTotal.Text = "📦 ไข่มุกในตัว: 0 เม็ด"
LblPearlTotal.TextColor3 = Color3.fromRGB(220, 220, 235)
LblPearlTotal.TextSize = 14
LblPearlTotal.Font = Enum.Font.GothamSemibold
LblPearlTotal.TextXAlignment = Enum.TextXAlignment.Left
LblPearlTotal.Parent = PearlCard

local LblPearlShrouded = Instance.new("TextLabel")
LblPearlShrouded.Size = UDim2.new(0.5, -10, 0, 24)
LblPearlShrouded.Position = UDim2.new(0.5, 6, 0, 8)
LblPearlShrouded.BackgroundTransparency = 1
LblPearlShrouded.Text = "✨ ติด Shrouded: 0 เม็ด"
LblPearlShrouded.TextColor3 = Color3.fromRGB(167, 139, 250)
LblPearlShrouded.TextSize = 14
LblPearlShrouded.Font = Enum.Font.GothamSemibold
LblPearlShrouded.TextXAlignment = Enum.TextXAlignment.Left
LblPearlShrouded.Parent = PearlCard

local LblPearlPending = Instance.new("TextLabel")
LblPearlPending.Size = UDim2.new(1, -24, 0, 24)
LblPearlPending.Position = UDim2.new(0, 12, 0, 36)
LblPearlPending.BackgroundTransparency = 1
LblPearlPending.Text = "⏳ ต้องรีเพิ่ม: 0 เม็ด"
LblPearlPending.TextColor3 = Color3.fromRGB(251, 191, 36)
LblPearlPending.TextSize = 14
LblPearlPending.Font = Enum.Font.GothamSemibold
LblPearlPending.TextXAlignment = Enum.TextXAlignment.Left
LblPearlPending.Parent = PearlCard

local LblPearlProgress = Instance.new("TextLabel")
LblPearlProgress.Size = UDim2.new(1, -24, 0, 24)
LblPearlProgress.Position = UDim2.new(0, 12, 0, 66)
LblPearlProgress.BackgroundTransparency = 1
LblPearlProgress.Text = "🎯 สถานะ: ปิดอยู่ (Standby)"
LblPearlProgress.TextColor3 = Color3.fromRGB(156, 163, 175)
LblPearlProgress.TextSize = 14
LblPearlProgress.Font = Enum.Font.GothamBold
LblPearlProgress.TextXAlignment = Enum.TextXAlignment.Left
LblPearlProgress.Parent = PearlCard

local LblPearlCurMut = Instance.new("TextLabel")
LblPearlCurMut.Size = UDim2.new(1, -24, 0, 24)
LblPearlCurMut.Position = UDim2.new(0, 12, 0, 96)
LblPearlCurMut.BackgroundTransparency = 1
LblPearlCurMut.Text = "🔮 มิวเทชันล่าสุด: - (รอบที่ 0)"
LblPearlCurMut.TextColor3 = Color3.fromRGB(192, 132, 252)
LblPearlCurMut.TextSize = 13
LblPearlCurMut.Font = Enum.Font.Gotham
LblPearlCurMut.TextXAlignment = Enum.TextXAlignment.Left
LblPearlCurMut.Parent = PearlCard

local StartPearlBtn = Instance.new("TextButton")
StartPearlBtn.Size = UDim2.new(0.48, 0, 0, 42)
StartPearlBtn.Position = UDim2.new(0, 0, 0, 146)
StartPearlBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
StartPearlBtn.Text = "▶ เริ่มรีไข่มุก (Start)"
StartPearlBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartPearlBtn.TextSize = 14
StartPearlBtn.Font = Enum.Font.GothamBold
StartPearlBtn.Parent = PagePearl

local SPearlCorner = Instance.new("UICorner")
SPearlCorner.CornerRadius = UDim.new(0, 8)
SPearlCorner.Parent = StartPearlBtn

local StopPearlBtn = Instance.new("TextButton")
StopPearlBtn.Size = UDim2.new(0.48, 0, 0, 42)
StopPearlBtn.Position = UDim2.new(0.52, 0, 0, 146)
StopPearlBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
StopPearlBtn.Text = "⏹ หยุด (Stop)"
StopPearlBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopPearlBtn.TextSize = 14
StopPearlBtn.Font = Enum.Font.GothamBold
StopPearlBtn.Parent = PagePearl

local StopPCorner = Instance.new("UICorner")
StopPCorner.CornerRadius = UDim.new(0, 8)
StopPCorner.Parent = StopPearlBtn

local RefreshPearlBtn = Instance.new("TextButton")
RefreshPearlBtn.Size = UDim2.new(1, 0, 0, 36)
RefreshPearlBtn.Position = UDim2.new(0, 0, 0, 196)
RefreshPearlBtn.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
RefreshPearlBtn.Text = "🔄 สแกนกระเป๋าหาไข่มุก (Refresh)"
RefreshPearlBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
RefreshPearlBtn.TextSize = 13
RefreshPearlBtn.Font = Enum.Font.GothamSemibold
RefreshPearlBtn.Parent = PagePearl

local RPCorner = Instance.new("UICorner")
RPCorner.CornerRadius = UDim.new(0, 6)
RPCorner.Parent = RefreshPearlBtn

-- ===================================================================
-- 🧙‍♂️ TAB 3: MERLIN AUTO BUFFS
-- ===================================================================
local PageMerlin = TabFrames["Merlin"]

local MerlinCard = Instance.new("Frame")
MerlinCard.Size = UDim2.new(1, 0, 0, 142)
MerlinCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
MerlinCard.BorderSizePixel = 0
MerlinCard.Parent = PageMerlin

local MCorner = Instance.new("UICorner")
MCorner.CornerRadius = UDim.new(0, 8)
MCorner.Parent = MerlinCard

local LblMerlinLucky = Instance.new("TextLabel")
LblMerlinLucky.Size = UDim2.new(1, -24, 0, 26)
LblMerlinLucky.Position = UDim2.new(0, 12, 0, 8)
LblMerlinLucky.BackgroundTransparency = 1
LblMerlinLucky.Text = "🍀 Lucky V (+25%): กำลังตรวจ..."
LblMerlinLucky.TextColor3 = Color3.fromRGB(52, 211, 153)
LblMerlinLucky.TextSize = 14
LblMerlinLucky.Font = Enum.Font.GothamSemibold
LblMerlinLucky.TextXAlignment = Enum.TextXAlignment.Left
LblMerlinLucky.Parent = MerlinCard

local LblMerlinLure = Instance.new("TextLabel")
LblMerlinLure.Size = UDim2.new(1, -24, 0, 26)
LblMerlinLure.Position = UDim2.new(0, 12, 0, 38)
LblMerlinLure.BackgroundTransparency = 1
LblMerlinLure.Text = "⏱️ Lure IV (+20%): กำลังตรวจ..."
LblMerlinLure.TextColor3 = Color3.fromRGB(96, 165, 250)
LblMerlinLure.TextSize = 14
LblMerlinLure.Font = Enum.Font.GothamSemibold
LblMerlinLure.TextXAlignment = Enum.TextXAlignment.Left
LblMerlinLure.Parent = MerlinCard

local LblMerlinInsight = Instance.new("TextLabel")
LblMerlinInsight.Size = UDim2.new(1, -24, 0, 26)
LblMerlinInsight.Position = UDim2.new(0, 12, 0, 68)
LblMerlinInsight.BackgroundTransparency = 1
LblMerlinInsight.Text = "⚡ Insight IV (+20%): กำลังตรวจ..."
LblMerlinInsight.TextColor3 = Color3.fromRGB(251, 191, 36)
LblMerlinInsight.TextSize = 14
LblMerlinInsight.Font = Enum.Font.GothamSemibold
LblMerlinInsight.TextXAlignment = Enum.TextXAlignment.Left
LblMerlinInsight.Parent = MerlinCard

local LblMerlinMode = Instance.new("TextLabel")
LblMerlinMode.Size = UDim2.new(1, -24, 0, 26)
LblMerlinMode.Position = UDim2.new(0, 12, 0, 100)
LblMerlinMode.BackgroundTransparency = 1
LblMerlinMode.Text = "🌐 สถานะ Auto-Renew: ปิดอยู่ (คลิกปุ่มด้านล่างเพื่อเปิด)"
LblMerlinMode.TextColor3 = Color3.fromRGB(156, 163, 175)
LblMerlinMode.TextSize = 13
LblMerlinMode.Font = Enum.Font.Gotham
LblMerlinMode.TextXAlignment = Enum.TextXAlignment.Left
LblMerlinMode.Parent = MerlinCard

local BuyAllMerlinBtn = Instance.new("TextButton")
BuyAllMerlinBtn.Size = UDim2.new(1, 0, 0, 44)
BuyAllMerlinBtn.Position = UDim2.new(0, 0, 0, 154)
BuyAllMerlinBtn.BackgroundColor3 = Color3.fromRGB(138, 92, 246)
BuyAllMerlinBtn.Text = "⚡ ซื้อบัฟทั้ง 3 ตัวทันที (Buy All 3 Buffs)"
BuyAllMerlinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BuyAllMerlinBtn.TextSize = 14
BuyAllMerlinBtn.Font = Enum.Font.GothamBold
BuyAllMerlinBtn.Parent = PageMerlin

local BAMCorner = Instance.new("UICorner")
BAMCorner.CornerRadius = UDim.new(0, 8)
BAMCorner.Parent = BuyAllMerlinBtn

-- 🔒 ปุ่ม Toggle Auto-Renew บัฟ (ค่าเริ่มต้น = สีเทา / ปิดอยู่)
local ToggleMerlinAuto = Instance.new("TextButton")
ToggleMerlinAuto.Size = UDim2.new(1, 0, 0, 40)
ToggleMerlinAuto.Position = UDim2.new(0, 0, 0, 206)
ToggleMerlinAuto.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
ToggleMerlinAuto.Text = "⚪ [OFF] Auto-Renew ปิดอยู่ (คลิกเพื่อเปิด)"
ToggleMerlinAuto.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleMerlinAuto.TextSize = 13
ToggleMerlinAuto.Font = Enum.Font.GothamBold
ToggleMerlinAuto.Parent = PageMerlin

local TMACorner = Instance.new("UICorner")
TMACorner.CornerRadius = UDim.new(0, 6)
TMACorner.Parent = ToggleMerlinAuto

-- ===================================================================
-- 🪱 TAB 4: BAIT & CRATES (ซื้อเหยื่อ & กรง)
-- ===================================================================
local PageBaitShop = TabFrames["BaitShop"]

local BaitSelectLabel = Instance.new("TextLabel")
BaitSelectLabel.Size = UDim2.new(1, 0, 0, 24)
BaitSelectLabel.Position = UDim2.new(0, 0, 0, 0)
BaitSelectLabel.BackgroundTransparency = 1
BaitSelectLabel.Text = "🎯 เลือกชนิดกล่องเหยื่อ (Selected Bait):"
BaitSelectLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BaitSelectLabel.TextSize = 14
BaitSelectLabel.Font = Enum.Font.GothamBold
BaitSelectLabel.TextXAlignment = Enum.TextXAlignment.Left
BaitSelectLabel.Parent = PageBaitShop

local BaitList = {
    "Tropical Bait Crate",
    "Quality Bait Crate",
    "Coral Bait Crate",
    "Bait Crate",
    "Volcano Bait Crate"
}

local BaitBtnContainer = Instance.new("Frame")
BaitBtnContainer.Size = UDim2.new(1, 0, 0, 36)
BaitBtnContainer.Position = UDim2.new(0, 0, 0, 26)
BaitBtnContainer.BackgroundTransparency = 1
BaitBtnContainer.Parent = PageBaitShop

local BaitButtons = {}
for idx, bName in ipairs(BaitList) do
    local bBtn = Instance.new("TextButton")
    bBtn.Size = UDim2.new(1 / #BaitList, -4, 1, 0)
    bBtn.Position = UDim2.new((idx - 1) / #BaitList, 2, 0, 0)
    bBtn.BackgroundColor3 = (bName == selectedBait) and Color3.fromRGB(138, 92, 246) or Color3.fromRGB(39, 39, 52)
    bBtn.Text = bName:gsub(" Bait Crate", ""):gsub(" Crate", "")
    bBtn.TextColor3 = (bName == selectedBait) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 200)
    bBtn.TextSize = 12
    bBtn.Font = Enum.Font.GothamBold
    bBtn.Parent = BaitBtnContainer
    
    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = bBtn
    
    BaitButtons[bName] = bBtn
    
    bBtn.MouseButton1Click:Connect(function()
        selectedBait = bName
        for name, btnObj in pairs(BaitButtons) do
            local isSel = (name == selectedBait)
            btnObj.BackgroundColor3 = isSel and Color3.fromRGB(138, 92, 246) or Color3.fromRGB(39, 39, 52)
            btnObj.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 200)
        end
        addLog("🎯 เลือกเหยื่อ: " .. selectedBait, Color3.fromRGB(192, 132, 252))
    end)
end

-- 🔒 ปุ่ม Toggle Auto Buy เหยื่อ (Default: OFF)
local ToggleAutoBuyBait = Instance.new("TextButton")
ToggleAutoBuyBait.Size = UDim2.new(1, 0, 0, 40)
ToggleAutoBuyBait.Position = UDim2.new(0, 0, 0, 70)
ToggleAutoBuyBait.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
ToggleAutoBuyBait.Text = "⚪ [OFF] Auto Buy เหยื่อ (คลิกเพื่อเริ่มซื้อเรื่อยๆ)"
ToggleAutoBuyBait.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleAutoBuyBait.TextSize = 13
ToggleAutoBuyBait.Font = Enum.Font.GothamBold
ToggleAutoBuyBait.Parent = PageBaitShop

local TABBCorner = Instance.new("UICorner")
TABBCorner.CornerRadius = UDim.new(0, 6)
TABBCorner.Parent = ToggleAutoBuyBait

-- 🔒 ปุ่ม Toggle Auto Open เหยื่อ (Default: OFF)
local ToggleAutoOpenBait = Instance.new("TextButton")
ToggleAutoOpenBait.Size = UDim2.new(1, 0, 0, 40)
ToggleAutoOpenBait.Position = UDim2.new(0, 0, 0, 118)
ToggleAutoOpenBait.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
ToggleAutoOpenBait.Text = "⚪ [OFF] Auto Open เหยื่อ (คลิกเพื่อเริ่มเปิดเรื่อยๆ)"
ToggleAutoOpenBait.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleAutoOpenBait.TextSize = 13
ToggleAutoOpenBait.Font = Enum.Font.GothamBold
ToggleAutoOpenBait.Parent = PageBaitShop

local TAOBCorner = Instance.new("UICorner")
TAOBCorner.CornerRadius = UDim.new(0, 6)
TAOBCorner.Parent = ToggleAutoOpenBait

-- หมวดซื้อกรงดักปู
local CageLabel = Instance.new("TextLabel")
CageLabel.Size = UDim2.new(1, 0, 0, 24)
CageLabel.Position = UDim2.new(0, 0, 0, 168)
CageLabel.BackgroundTransparency = 1
CageLabel.Text = "🪤 ซื้อกรงดักปู (Crab Traps):"
CageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CageLabel.TextSize = 14
CageLabel.Font = Enum.Font.GothamBold
CageLabel.TextXAlignment = Enum.TextXAlignment.Left
CageLabel.Parent = PageBaitShop

local BuyCrabTrapBtn = Instance.new("TextButton")
BuyCrabTrapBtn.Size = UDim2.new(0.48, 0, 0, 38)
BuyCrabTrapBtn.Position = UDim2.new(0, 0, 0, 196)
BuyCrabTrapBtn.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
BuyCrabTrapBtn.Text = "🦀 Crab Trap (C$ 220)"
BuyCrabTrapBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
BuyCrabTrapBtn.TextSize = 13
BuyCrabTrapBtn.Font = Enum.Font.GothamSemibold
BuyCrabTrapBtn.Parent = PageBaitShop

local BCTCorner = Instance.new("UICorner")
BCTCorner.CornerRadius = UDim.new(0, 6)
BCTCorner.Parent = BuyCrabTrapBtn

local BuyReinforcedTrapBtn = Instance.new("TextButton")
BuyReinforcedTrapBtn.Size = UDim2.new(0.48, 0, 0, 38)
BuyReinforcedTrapBtn.Position = UDim2.new(0.52, 0, 0, 196)
BuyReinforcedTrapBtn.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
BuyReinforcedTrapBtn.Text = "🛡️ Reinforced (C$ 950)"
BuyReinforcedTrapBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
BuyReinforcedTrapBtn.TextSize = 13
BuyReinforcedTrapBtn.Font = Enum.Font.GothamSemibold
BuyReinforcedTrapBtn.Parent = PageBaitShop

local BRTCorner = Instance.new("UICorner")
BRTCorner.CornerRadius = UDim.new(0, 6)
BRTCorner.Parent = BuyReinforcedTrapBtn

-- ===================================================================
-- 🌌 TAB 5: AURORA TOTEM (46 พิกัด)
-- ===================================================================
local PageAurora = TabFrames["Aurora"]

local AuroraCard = Instance.new("Frame")
AuroraCard.Size = UDim2.new(1, 0, 0, 112)
AuroraCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
AuroraCard.BorderSizePixel = 0
AuroraCard.Parent = PageAurora

local ACorner = Instance.new("UICorner")
ACorner.CornerRadius = UDim.new(0, 8)
ACorner.Parent = AuroraCard

local LblAuroraStatus = Instance.new("TextLabel")
LblAuroraStatus.Size = UDim2.new(1, -24, 0, 26)
LblAuroraStatus.Position = UDim2.new(0, 12, 0, 8)
LblAuroraStatus.BackgroundTransparency = 1
LblAuroraStatus.Text = "🎯 สถานะ: ปิดอยู่ (Standby)"
LblAuroraStatus.TextColor3 = Color3.fromRGB(156, 163, 175)
LblAuroraStatus.TextSize = 14
LblAuroraStatus.Font = Enum.Font.GothamBold
LblAuroraStatus.TextXAlignment = Enum.TextXAlignment.Left
LblAuroraStatus.Parent = AuroraCard

local LblAuroraWaypoint = Instance.new("TextLabel")
LblAuroraWaypoint.Size = UDim2.new(1, -24, 0, 26)
LblAuroraWaypoint.Position = UDim2.new(0, 12, 0, 38)
LblAuroraWaypoint.BackgroundTransparency = 1
LblAuroraWaypoint.Text = "📍 จุดปัจจุบัน: - (ทั้งหมด 46 พิกัด)"
LblAuroraWaypoint.TextColor3 = Color3.fromRGB(147, 197, 253)
LblAuroraWaypoint.TextSize = 13
LblAuroraWaypoint.Font = Enum.Font.GothamSemibold
LblAuroraWaypoint.TextXAlignment = Enum.TextXAlignment.Left
LblAuroraWaypoint.Parent = AuroraCard

local LblAuroraBought = Instance.new("TextLabel")
LblAuroraBought.Size = UDim2.new(1, -24, 0, 26)
LblAuroraBought.Position = UDim2.new(0, 12, 0, 68)
LblAuroraBought.BackgroundTransparency = 1
LblAuroraBought.Text = "💰 ซื้อสำเร็จแล้ว: 0 อัน"
LblAuroraBought.TextColor3 = Color3.fromRGB(52, 211, 153)
LblAuroraBought.TextSize = 14
LblAuroraBought.Font = Enum.Font.GothamSemibold
LblAuroraBought.TextXAlignment = Enum.TextXAlignment.Left
LblAuroraBought.Parent = AuroraCard

-- 🔒 ปุ่ม Toggle Auto Buy Aurora Totem (Default: OFF)
local ToggleAuroraBtn = Instance.new("TextButton")
ToggleAuroraBtn.Size = UDim2.new(1, 0, 0, 42)
ToggleAuroraBtn.Position = UDim2.new(0, 0, 0, 124)
ToggleAuroraBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
ToggleAuroraBtn.Text = "⚪ [OFF] Auto Buy Aurora (คลิกเพื่อเริ่มค้นหา 46 จุด)"
ToggleAuroraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleAuroraBtn.TextSize = 13
ToggleAuroraBtn.Font = Enum.Font.GothamBold
ToggleAuroraBtn.Parent = PageAurora

local TABCorner = Instance.new("UICorner")
TABCorner.CornerRadius = UDim.new(0, 6)
TABCorner.Parent = ToggleAuroraBtn

-- ปุ่ม Toggle วนซ้ำต่อเนื่อง (Loop Forever)
local ToggleAuroraLoopBtn = Instance.new("TextButton")
ToggleAuroraLoopBtn.Size = UDim2.new(1, 0, 0, 38)
ToggleAuroraLoopBtn.Position = UDim2.new(0, 0, 0, 174)
ToggleAuroraLoopBtn.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
ToggleAuroraLoopBtn.Text = "🔁 โหมดวนซ้ำรอบใหม่: ปิดอยู่ (วิ่งรอบเดียวจบ)"
ToggleAuroraLoopBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
ToggleAuroraLoopBtn.TextSize = 13
ToggleAuroraLoopBtn.Font = Enum.Font.GothamSemibold
ToggleAuroraLoopBtn.Parent = PageAurora

local TALBCorner = Instance.new("UICorner")
TALBCorner.CornerRadius = UDim.new(0, 6)
TALBCorner.Parent = ToggleAuroraLoopBtn

-- ===================================================================
-- ⚡ TAB 6: OLYMPUS ROD TELEPORT (วาร์ปทำเบ็ดโอลิมปัส ชั้น 1 - 6)
-- ===================================================================
local PageOlympus = TabFrames["Olympus"]

local OlympusCard = Instance.new("Frame")
OlympusCard.Size = UDim2.new(1, 0, 0, 64)
OlympusCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
OlympusCard.BorderSizePixel = 0
OlympusCard.Parent = PageOlympus

local OCorner = Instance.new("UICorner")
OCorner.CornerRadius = UDim.new(0, 8)
OCorner.Parent = OlympusCard

local LblOlympusTitle = Instance.new("TextLabel")
LblOlympusTitle.Size = UDim2.new(1, -20, 0, 24)
LblOlympusTitle.Position = UDim2.new(0, 12, 0, 8)
LblOlympusTitle.BackgroundTransparency = 1
LblOlympusTitle.Text = "⚡ วาร์ปไปทำเบ็ดโอลิมปัส (Olympus Rod)"
LblOlympusTitle.TextColor3 = Color3.fromRGB(251, 191, 36)
LblOlympusTitle.TextSize = 15
LblOlympusTitle.Font = Enum.Font.GothamBold
LblOlympusTitle.TextXAlignment = Enum.TextXAlignment.Left
LblOlympusTitle.Parent = OlympusCard

local LblOlympusDesc = Instance.new("TextLabel")
LblOlympusDesc.Size = UDim2.new(1, -20, 0, 22)
LblOlympusDesc.Position = UDim2.new(0, 12, 0, 34)
LblOlympusDesc.BackgroundTransparency = 1
LblOlympusDesc.Text = "🏛️ กดคลิกชั้นที่ต้องการเพื่อวาร์ปทันที (บันทึกจุดเดิมให้อัตโนมัติ)"
LblOlympusDesc.TextColor3 = Color3.fromRGB(156, 163, 175)
LblOlympusDesc.TextSize = 13
LblOlympusDesc.Font = Enum.Font.Gotham
LblOlympusDesc.TextXAlignment = Enum.TextXAlignment.Left
LblOlympusDesc.Parent = OlympusCard

local OlympusFloors = {
    { id = 1, name = "ชั้น 1", pos = Vector3.new(-8965.1, -2308.0, 367.0), coords = "-8965.1, -2308.0, 367.0" },
    { id = 2, name = "ชั้น 2", pos = Vector3.new(-8831.5, -2906.3, 585.8), coords = "-8831.5, -2906.3, 585.8" },
    { id = 3, name = "ชั้น 3", pos = Vector3.new(-8962.3, -3118.4, 645.6), coords = "-8962.3, -3118.4, 645.6" },
    { id = 4, name = "ชั้น 4", pos = Vector3.new(-8590.3, -3531.8, 695.9), coords = "-8590.3, -3531.8, 695.9" },
    { id = 5, name = "ชั้น 5", pos = Vector3.new(-9144.2, -4232.8, 292.8), coords = "-9144.2, -4232.8, 292.8" },
    { id = 6, name = "ชั้น 6", pos = Vector3.new(-8804.2, -4243.6, -288.7), coords = "-8804.2, -4243.6, -288.7" },
}

local lastSavedOlympusPos = nil

local function teleportToFloor(floorData)
    local root = getRoot()
    if not root then
        addLog("❌ ไม่พบตัวละคร ไม่สามารถวาร์ปได้", Color3.fromRGB(248, 113, 113))
        return
    end
    
    lastSavedOlympusPos = root.CFrame
    local targetCF = CFrame.new(floorData.pos + Vector3.new(0, 3, 0))
    teleportPlayer(targetCF)
    
    addLog(string.format("⚡ วาร์ปไปเบ็ดโอลิมปัส [%s] สำเร็จ! (พิกัด: %s)", floorData.name, floorData.coords), Color3.fromRGB(251, 191, 36))
    notify("Olympus Teleport", string.format("⚡ วาร์ปไป %s เรียบร้อย!", floorData.name), 3)
end

local floorPositions = {
    { x = 0, y = 74 },
    { x = 0.52, y = 74 },
    { x = 0, y = 128 },
    { x = 0.52, y = 128 },
    { x = 0, y = 182 },
    { x = 0.52, y = 182 },
}

for idx, fData in ipairs(OlympusFloors) do
    local fBtn = Instance.new("TextButton")
    fBtn.Name = "Btn_Olympus_" .. fData.id
    fBtn.Size = UDim2.new(0.48, 0, 0, 46)
    fBtn.Position = UDim2.new(floorPositions[idx].x, 0, 0, floorPositions[idx].y)
    fBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    fBtn.Text = string.format("⚡ วาร์ปไป %s\n(คลิกเพื่อวาร์ปทันที)", fData.name)
    fBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
    fBtn.TextSize = 13
    fBtn.Font = Enum.Font.GothamBold
    fBtn.Parent = PageOlympus
    
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 6)
    fCorner.Parent = fBtn
    
    local fStroke = Instance.new("UIStroke")
    fStroke.Thickness = 1
    fStroke.Color = Color3.fromRGB(60, 60, 80)
    fStroke.Parent = fBtn
    
    fBtn.MouseEnter:Connect(function()
        fBtn.BackgroundColor3 = Color3.fromRGB(138, 92, 246)
        fBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        fStroke.Color = Color3.fromRGB(167, 139, 250)
    end)
    fBtn.MouseLeave:Connect(function()
        fBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        fBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
        fStroke.Color = Color3.fromRGB(60, 60, 80)
    end)
    
    fBtn.MouseButton1Click:Connect(function()
        teleportToFloor(fData)
    end)
end

-- ปุ่มวาร์ปกลับจุดเดิม
local ReturnOlympusBtn = Instance.new("TextButton")
ReturnOlympusBtn.Name = "ReturnOlympusBtn"
ReturnOlympusBtn.Size = UDim2.new(1, 0, 0, 40)
ReturnOlympusBtn.Position = UDim2.new(0, 0, 0, 238)
ReturnOlympusBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
ReturnOlympusBtn.Text = "🔄 วาร์ปกลับจุดเดิมก่อนหน้า (Return)"
ReturnOlympusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnOlympusBtn.TextSize = 13
ReturnOlympusBtn.Font = Enum.Font.GothamBold
ReturnOlympusBtn.Parent = PageOlympus

local ROB_Corner = Instance.new("UICorner")
ROB_Corner.CornerRadius = UDim.new(0, 6)
ROB_Corner.Parent = ReturnOlympusBtn

ReturnOlympusBtn.MouseButton1Click:Connect(function()
    if not lastSavedOlympusPos then
        addLog("⚠️ ยังไม่มีตำแหน่งจุดเดิมที่บันทึกไว้", Color3.fromRGB(251, 191, 36))
        notify("Teleport", "ยังไม่มีจุดเดิมที่บันทึกไว้", 3)
        return
    end
    teleportPlayer(lastSavedOlympusPos)
    addLog("📍 วาร์ปกลับจุดเดิมก่อนหน้าเรียบร้อย", Color3.fromRGB(96, 165, 250))
    notify("Teleport", "วาร์ปกลับจุดเดิมเรียบร้อย!", 3)
end)

-- ===================================================================
-- 🪞 OLYMPUS QUEST UI (หมุนกระจก 5 จุด & เควสดาบ)
-- ===================================================================
local QuestHeaderCard = Instance.new("Frame")
QuestHeaderCard.Size = UDim2.new(1, 0, 0, 56)
QuestHeaderCard.Position = UDim2.new(0, 0, 0, 290)
QuestHeaderCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
QuestHeaderCard.BorderSizePixel = 0
QuestHeaderCard.Parent = PageOlympus

local QCorner = Instance.new("UICorner")
QCorner.CornerRadius = UDim.new(0, 8)
QCorner.Parent = QuestHeaderCard

local LblQuestTitle = Instance.new("TextLabel")
LblQuestTitle.Size = UDim2.new(1, -20, 0, 22)
LblQuestTitle.Position = UDim2.new(0, 12, 0, 6)
LblQuestTitle.BackgroundTransparency = 1
LblQuestTitle.Text = "🪞 เควสหมุนกระจก & เควสดาบโอลิมปัส"
LblQuestTitle.TextColor3 = Color3.fromRGB(251, 191, 36)
LblQuestTitle.TextSize = 14
LblQuestTitle.Font = Enum.Font.GothamBold
LblQuestTitle.TextXAlignment = Enum.TextXAlignment.Left
LblQuestTitle.Parent = QuestHeaderCard

local LblQuestDesc = Instance.new("TextLabel")
LblQuestDesc.Size = UDim2.new(1, -20, 0, 20)
LblQuestDesc.Position = UDim2.new(0, 12, 0, 28)
LblQuestDesc.BackgroundTransparency = 1
LblQuestDesc.Text = "⚡ กดปุ่มเดียวเพื่อหมุนกระจกครบ 5 จุด หรือส่งเควสดาบอัตโนมัติ"
LblQuestDesc.TextColor3 = Color3.fromRGB(156, 163, 175)
LblQuestDesc.TextSize = 12
LblQuestDesc.Font = Enum.Font.Gotham
LblQuestDesc.TextXAlignment = Enum.TextXAlignment.Left
LblQuestDesc.Parent = QuestHeaderCard

-- ปุ่มหมุนกระจก (Auto Mirror 5 จุด)
local MirrorQuestBtn = Instance.new("TextButton")
MirrorQuestBtn.Name = "MirrorQuestBtn"
MirrorQuestBtn.Size = UDim2.new(1, 0, 0, 44)
MirrorQuestBtn.Position = UDim2.new(0, 0, 0, 356)
MirrorQuestBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
MirrorQuestBtn.Text = "🪞 [เริ่ม] ออโต้หมุนกระจก 5 จุด (Auto Rotate Mirrors)"
MirrorQuestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MirrorQuestBtn.TextSize = 13
MirrorQuestBtn.Font = Enum.Font.GothamBold
MirrorQuestBtn.Parent = PageOlympus

local MQCorner = Instance.new("UICorner")
MQCorner.CornerRadius = UDim.new(0, 6)
MQCorner.Parent = MirrorQuestBtn

local LblMirrorStatus = Instance.new("TextLabel")
LblMirrorStatus.Size = UDim2.new(1, 0, 0, 22)
LblMirrorStatus.Position = UDim2.new(0, 4, 0, 404)
LblMirrorStatus.BackgroundTransparency = 1
LblMirrorStatus.Text = "📍 กระจก: พร้อมทำงาน (5 จุด: 5, 7, 3, 3, 7 ครั้ง)"
LblMirrorStatus.TextColor3 = Color3.fromRGB(156, 163, 175)
LblMirrorStatus.TextSize = 12
LblMirrorStatus.Font = Enum.Font.Gotham
LblMirrorStatus.TextXAlignment = Enum.TextXAlignment.Left
LblMirrorStatus.Parent = PageOlympus

-- ปุ่มส่งเควสดาบ (Auto Sword Quest)
local SwordQuestBtn = Instance.new("TextButton")
SwordQuestBtn.Name = "SwordQuestBtn"
SwordQuestBtn.Size = UDim2.new(1, 0, 0, 44)
SwordQuestBtn.Position = UDim2.new(0, 0, 0, 432)
SwordQuestBtn.BackgroundColor3 = Color3.fromRGB(138, 92, 246)
SwordQuestBtn.Text = "⚔️ [เริ่ม] ออโต้ส่งเควสดาบ (Auto Sword Quest)"
SwordQuestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SwordQuestBtn.TextSize = 13
SwordQuestBtn.Font = Enum.Font.GothamBold
SwordQuestBtn.Parent = PageOlympus

local SQCorner = Instance.new("UICorner")
SQCorner.CornerRadius = UDim.new(0, 6)
SQCorner.Parent = SwordQuestBtn

local LblSwordStatus = Instance.new("TextLabel")
LblSwordStatus.Size = UDim2.new(1, 0, 0, 22)
LblSwordStatus.Position = UDim2.new(0, 4, 0, 480)
LblSwordStatus.BackgroundTransparency = 1
LblSwordStatus.Text = "📍 เควสดาบ: พร้อมทำงาน (เก็บ 9 จุด + สวมดาบ/หมวก)"
LblSwordStatus.TextColor3 = Color3.fromRGB(156, 163, 175)
LblSwordStatus.TextSize = 12
LblSwordStatus.Font = Enum.Font.Gotham
LblSwordStatus.TextXAlignment = Enum.TextXAlignment.Left
LblSwordStatus.Parent = PageOlympus

-- ปุ่มสั่งหยุดเควส
local StopOlympusQuestBtn = Instance.new("TextButton")
StopOlympusQuestBtn.Name = "StopOlympusQuestBtn"
StopOlympusQuestBtn.Size = UDim2.new(1, 0, 0, 38)
StopOlympusQuestBtn.Position = UDim2.new(0, 0, 0, 508)
StopOlympusQuestBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
StopOlympusQuestBtn.Text = "⏹ หยุดการทำงานเควส (Stop Quest)"
StopOlympusQuestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopOlympusQuestBtn.TextSize = 13
StopOlympusQuestBtn.Font = Enum.Font.GothamBold
StopOlympusQuestBtn.Parent = PageOlympus

local SOQCorner = Instance.new("UICorner")
SOQCorner.CornerRadius = UDim.new(0, 6)
SOQCorner.Parent = StopOlympusQuestBtn

-- เว้นระยะด้านล่างสำหรับการเลื่อน Scroll
local BottomSpacer = Instance.new("Frame")
BottomSpacer.Size = UDim2.new(1, 0, 0, 30)
BottomSpacer.Position = UDim2.new(0, 0, 0, 552)
BottomSpacer.BackgroundTransparency = 1
BottomSpacer.Parent = PageOlympus

-- ===================================================================
-- 💾 TAB 7: CONFIG MANAGER (ระบบเซฟคอนฟิกแยกตามชื่อไอดี)
-- ===================================================================
;(function()
    local PageConfig = TabFrames["Config"]
    if not PageConfig then return end

    local ConfigLayout = Instance.new("UIListLayout")
    ConfigLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ConfigLayout.Padding = UDim.new(0, 8)
    ConfigLayout.Parent = PageConfig

    -- Card 1: ข้อมูลไฟล์คอนฟิก & สถานะ
    local InfoCard = Instance.new("Frame")
    InfoCard.Name = "InfoCard"
    InfoCard.Size = UDim2.new(1, 0, 0, 95)
    InfoCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    InfoCard.BorderSizePixel = 0
    InfoCard.LayoutOrder = 1
    InfoCard.Parent = PageConfig

    local ICorner = Instance.new("UICorner")
    ICorner.CornerRadius = UDim.new(0, 8)
    ICorner.Parent = InfoCard

    local IStroke = Instance.new("UIStroke")
    IStroke.Color = Color3.fromRGB(45, 50, 68)
    IStroke.Thickness = 1
    IStroke.Parent = InfoCard

    local LblConfigTitle = Instance.new("TextLabel")
    LblConfigTitle.Size = UDim2.new(1, -24, 0, 22)
    LblConfigTitle.Position = UDim2.new(0, 12, 0, 8)
    LblConfigTitle.BackgroundTransparency = 1
    LblConfigTitle.Text = "📁 ระบบเซฟคอนฟิก (Pond Hub Config System)"
    LblConfigTitle.TextColor3 = Color3.fromRGB(147, 197, 253)
    LblConfigTitle.TextSize = 14
    LblConfigTitle.Font = Enum.Font.GothamBold
    LblConfigTitle.TextXAlignment = Enum.TextXAlignment.Left
    LblConfigTitle.Parent = InfoCard

    local LblConfigFile = Instance.new("TextLabel")
    LblConfigFile.Name = "LblConfigFile"
    LblConfigFile.Size = UDim2.new(1, -24, 0, 18)
    LblConfigFile.Position = UDim2.new(0, 12, 0, 32)
    LblConfigFile.BackgroundTransparency = 1
    LblConfigFile.Text = "📄 ไฟล์: workspace/" .. configFileName
    LblConfigFile.TextColor3 = Color3.fromRGB(209, 213, 219)
    LblConfigFile.TextSize = 12
    LblConfigFile.Font = Enum.Font.Code
    LblConfigFile.TextXAlignment = Enum.TextXAlignment.Left
    LblConfigFile.Parent = InfoCard

    local LblLastSaved = Instance.new("TextLabel")
    LblLastSaved.Name = "LblLastSaved"
    LblLastSaved.Size = UDim2.new(1, -24, 0, 18)
    LblLastSaved.Position = UDim2.new(0, 12, 0, 52)
    LblLastSaved.BackgroundTransparency = 1
    LblLastSaved.Text = "⏰ บันทึกล่าสุด: " .. tostring(Config.LastSaved)
    LblLastSaved.TextColor3 = Color3.fromRGB(156, 163, 175)
    LblLastSaved.TextSize = 11
    LblLastSaved.Font = Enum.Font.Gotham
    LblLastSaved.TextXAlignment = Enum.TextXAlignment.Left
    LblLastSaved.Parent = InfoCard

    local LblStatus = Instance.new("TextLabel")
    LblStatus.Name = "LblStatus"
    LblStatus.Size = UDim2.new(1, -24, 0, 18)
    LblStatus.Position = UDim2.new(0, 12, 0, 72)
    LblStatus.BackgroundTransparency = 1
    LblStatus.Text = "🟢 สถานะ: ซิงค์พร้อมใช้งาน (Synced)"
    LblStatus.TextColor3 = Color3.fromRGB(52, 211, 153)
    LblStatus.TextSize = 11
    LblStatus.Font = Enum.Font.GothamSemibold
    LblStatus.TextXAlignment = Enum.TextXAlignment.Left
    LblStatus.Parent = InfoCard

    -- Card 2: ปุ่มจัดการคอนฟิก
    local ActionCard = Instance.new("Frame")
    ActionCard.Name = "ActionCard"
    ActionCard.Size = UDim2.new(1, 0, 0, 96)
    ActionCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    ActionCard.BorderSizePixel = 0
    ActionCard.LayoutOrder = 2
    ActionCard.Parent = PageConfig

    local ACorner = Instance.new("UICorner")
    ACorner.CornerRadius = UDim.new(0, 8)
    ACorner.Parent = ActionCard

    local AStroke = Instance.new("UIStroke")
    AStroke.Color = Color3.fromRGB(45, 50, 68)
    AStroke.Thickness = 1
    AStroke.Parent = ActionCard

    -- ปุ่มบันทึกคอนฟิก
    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Name = "SaveBtn"
    SaveBtn.Size = UDim2.new(0.48, -4, 0, 36)
    SaveBtn.Position = UDim2.new(0, 12, 0, 10)
    SaveBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    SaveBtn.Text = "💾 บันทึกคอนฟิก (Save Now)"
    SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveBtn.TextSize = 12
    SaveBtn.Font = Enum.Font.GothamBold
    SaveBtn.Parent = ActionCard

    local SCorner = Instance.new("UICorner")
    SCorner.CornerRadius = UDim.new(0, 6)
    SCorner.Parent = SaveBtn

    -- ปุ่มโหลดคอนฟิกใหม่
    local LoadBtn = Instance.new("TextButton")
    LoadBtn.Name = "LoadBtn"
    LoadBtn.Size = UDim2.new(0.48, -4, 0, 36)
    LoadBtn.Position = UDim2.new(0.52, -8, 0, 10)
    LoadBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    LoadBtn.Text = "🔄 โหลดคอนฟิก (Reload)"
    LoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadBtn.TextSize = 12
    LoadBtn.Font = Enum.Font.GothamBold
    LoadBtn.Parent = ActionCard

    local LCorner = Instance.new("UICorner")
    LCorner.CornerRadius = UDim.new(0, 6)
    LCorner.Parent = LoadBtn

    -- ปุ่มรีเซ็ตค่าเริ่มต้น
    local ResetBtn = Instance.new("TextButton")
    ResetBtn.Name = "ResetBtn"
    ResetBtn.Size = UDim2.new(1, -24, 0, 34)
    ResetBtn.Position = UDim2.new(0, 12, 0, 52)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    ResetBtn.Text = "🗑️ รีเซ็ตเป็นค่าเริ่มต้น (Reset Defaults)"
    ResetBtn.TextColor3 = Color3.fromRGB(248, 113, 113)
    ResetBtn.TextSize = 12
    ResetBtn.Font = Enum.Font.GothamBold
    ResetBtn.Parent = ActionCard

    local RCorner = Instance.new("UICorner")
    RCorner.CornerRadius = UDim.new(0, 6)
    RCorner.Parent = ResetBtn

    -- Card 3: สวิตช์ออโต้เซฟ (Auto-Save on Change)
    local AutoSaveCard = Instance.new("Frame")
    AutoSaveCard.Name = "AutoSaveCard"
    AutoSaveCard.Size = UDim2.new(1, 0, 0, 48)
    AutoSaveCard.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    AutoSaveCard.BorderSizePixel = 0
    AutoSaveCard.LayoutOrder = 3
    AutoSaveCard.Parent = PageConfig

    local ASCorner = Instance.new("UICorner")
    ASCorner.CornerRadius = UDim.new(0, 8)
    ASCorner.Parent = AutoSaveCard

    local ASStroke = Instance.new("UIStroke")
    ASStroke.Color = Color3.fromRGB(45, 50, 68)
    ASStroke.Thickness = 1
    ASStroke.Parent = AutoSaveCard

    local LblASTitle = Instance.new("TextLabel")
    LblASTitle.Size = UDim2.new(1, -80, 0, 20)
    LblASTitle.Position = UDim2.new(0, 12, 0, 5)
    LblASTitle.BackgroundTransparency = 1
    LblASTitle.Text = "🔁 บันทึกอัตโนมัติ (Auto-Save on Toggle)"
    LblASTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
    LblASTitle.TextSize = 13
    LblASTitle.Font = Enum.Font.GothamBold
    LblASTitle.TextXAlignment = Enum.TextXAlignment.Left
    LblASTitle.Parent = AutoSaveCard

    local LblASDesc = Instance.new("TextLabel")
    LblASDesc.Size = UDim2.new(1, -80, 0, 16)
    LblASDesc.Position = UDim2.new(0, 12, 0, 26)
    LblASDesc.BackgroundTransparency = 1
    LblASDesc.Text = "บันทึกลงไฟล์ทันทีเมื่อมีการกดเปลี่ยนสวิตช์หรือกดคีย์ลัด Q / F"
    LblASDesc.TextColor3 = Color3.fromRGB(156, 163, 175)
    LblASDesc.TextSize = 11
    LblASDesc.Font = Enum.Font.Gotham
    LblASDesc.TextXAlignment = Enum.TextXAlignment.Left
    LblASDesc.Parent = AutoSaveCard

    local SwitchAS = Instance.new("TextButton")
    SwitchAS.Name = "SwitchAS"
    SwitchAS.Size = UDim2.new(0, 48, 0, 24)
    SwitchAS.Position = UDim2.new(1, -60, 0.5, -12)
    SwitchAS.BackgroundColor3 = Config.AutoSave and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(50, 54, 70)
    SwitchAS.Text = ""
    SwitchAS.Parent = AutoSaveCard

    local SASCorner = Instance.new("UICorner")
    SASCorner.CornerRadius = UDim.new(1, 0)
    SASCorner.Parent = SwitchAS

    local KnobAS = Instance.new("Frame")
    KnobAS.Name = "KnobAS"
    KnobAS.Size = UDim2.new(0, 18, 0, 18)
    KnobAS.Position = Config.AutoSave and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    KnobAS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KnobAS.BorderSizePixel = 0
    KnobAS.Parent = SwitchAS

    local KASCorner = Instance.new("UICorner")
    KASCorner.CornerRadius = UDim.new(1, 0)
    KASCorner.Parent = KnobAS

    -- Card 4: สรุปค่าคอนฟิกปัจจุบัน
    local SummaryCard = Instance.new("Frame")
    SummaryCard.Name = "SummaryCard"
    SummaryCard.Size = UDim2.new(1, 0, 0, 88)
    SummaryCard.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    SummaryCard.BorderSizePixel = 0
    SummaryCard.LayoutOrder = 4
    SummaryCard.Parent = PageConfig

    local SCardCorner = Instance.new("UICorner")
    SCardCorner.CornerRadius = UDim.new(0, 8)
    SCardCorner.Parent = SummaryCard

    local SCardStroke = Instance.new("UIStroke")
    SCardStroke.Color = Color3.fromRGB(40, 44, 58)
    SCardStroke.Thickness = 1
    SCardStroke.Parent = SummaryCard

    local LblSumTitle = Instance.new("TextLabel")
    LblSumTitle.Size = UDim2.new(1, -24, 0, 20)
    LblSumTitle.Position = UDim2.new(0, 12, 0, 6)
    LblSumTitle.BackgroundTransparency = 1
    LblSumTitle.Text = "📋 ค่าคอนฟิกตกปลาที่บันทึกไว้ปัจจุบัน (Current Saved Config):"
    LblSumTitle.TextColor3 = Color3.fromRGB(167, 139, 250)
    LblSumTitle.TextSize = 12
    LblSumTitle.Font = Enum.Font.GothamBold
    LblSumTitle.TextXAlignment = Enum.TextXAlignment.Left
    LblSumTitle.Parent = SummaryCard

    local LblSummary = Instance.new("TextLabel")
    LblSummary.Name = "LblSummary"
    LblSummary.Size = UDim2.new(1, -24, 0, 54)
    LblSummary.Position = UDim2.new(0, 12, 0, 26)
    LblSummary.BackgroundTransparency = 1
    LblSummary.TextColor3 = Color3.fromRGB(209, 213, 219)
    LblSummary.TextSize = 11
    LblSummary.Font = Enum.Font.Code
    LblSummary.TextXAlignment = Enum.TextXAlignment.Left
    LblSummary.TextYAlignment = Enum.TextYAlignment.Top
    LblSummary.Parent = SummaryCard

    -- ฟังก์ชันอัปเดตการแสดงผลในหน้าคอนฟิก
    updateConfigSummary = function()
        pcall(function()
            if LblLastSaved then
                LblLastSaved.Text = "⏰ บันทึกล่าสุด: " .. tostring(Config.LastSaved)
            end
            if LblSummary then
                local f = Config.Fishing
                local text = string.format(
                    "🎒 AutoEquip: %s  |  ⚡ InstantCast [Q]: %s\n🎯 InstantBobber: %s  |  🔘 AutoShake: %s\n🎣 AutoReel: %s  |  🔒 Freeze [F]: %s",
                    f.AutoEquipRod and "🟢 ON" or "⚪ OFF",
                    f.InstantCast and "🟢 ON" or "⚪ OFF",
                    f.InstantBobber and "🟢 ON" or "⚪ OFF",
                    f.AutoShake and "🟢 ON" or "⚪ OFF",
                    f.InstantAutoReel and "🟢 ON" or "⚪ OFF",
                    f.PositionFreeze and "🟢 ON" or "⚪ OFF"
                )
                LblSummary.Text = text
            end
            if SwitchAS and KnobAS then
                SwitchAS.BackgroundColor3 = Config.AutoSave and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(50, 54, 70)
                KnobAS.Position = Config.AutoSave and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            end
        end)
    end

    SwitchAS.MouseButton1Click:Connect(function()
        Config.AutoSave = not Config.AutoSave
        updateConfigSummary()
        if Config.AutoSave then
            addLog("🔁 เปิดใช้งานบันทึกคอนฟิกอัตโนมัติ (Auto-Save ON)", Color3.fromRGB(52, 211, 153))
        else
            addLog("🔁 ปิดใช้งานบันทึกคอนฟิกอัตโนมัติ (Auto-Save OFF)", Color3.fromRGB(156, 163, 175))
        end
        saveConfig()
    end)

    SaveBtn.MouseButton1Click:Connect(function()
        saveConfig()
        updateConfigSummary()
        addLog(string.format("💾 บันทึกคอนฟิกลง workspace/%s สำเร็จ", configFileName), Color3.fromRGB(52, 211, 153))
        notify("Save Config", "บันทึกคอนฟิกสำเร็จเรียบร้อย!", 2)
    end)

    LoadBtn.MouseButton1Click:Connect(function()
        if loadConfigFile() then
            if Config.Fishing and setFishingToggleVisual then
                for name, val in pairs(Config.Fishing) do
                    setFishingToggleVisual(name, val, false)
                end
            end
            updateConfigSummary()
            addLog(string.format("🔄 โหลดคอนฟิกจาก workspace/%s สำเร็จ", configFileName), Color3.fromRGB(96, 165, 250))
            notify("Load Config", "โหลดคอนฟิกสำเร็จเรียบร้อย!", 2)
        else
            addLog("⚠️ ไม่พบไฟล์คอนฟิกเดิม กำลังสร้างใหม่...", Color3.fromRGB(251, 191, 36))
            saveConfig()
            updateConfigSummary()
        end
    end)

    ResetBtn.MouseButton1Click:Connect(function()
        resetDefaultConfig()
        if Config.Fishing and setFishingToggleVisual then
            for name, val in pairs(Config.Fishing) do
                setFishingToggleVisual(name, val, false)
            end
        end
        saveConfig()
        updateConfigSummary()
        addLog("🗑️ รีเซ็ตคอนฟิกกลับเป็นค่าเริ่มต้นเรียบร้อย", Color3.fromRGB(248, 113, 113))
        notify("Reset Config", "รีเซ็ตคอนฟิกเป็นค่าเริ่มต้นแล้ว", 2)
    end)

    -- อัปเดตข้อความสรุปค่าคอนฟิกครั้งแรก
    updateConfigSummary()
end)()

selectTab("Fishing")

-- ===================================================================
-- 🖱️ DRAGGABLE & KEYBIND [ Z ]
-- ===================================================================
local isDragging = false
local dragStart, startPos

Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then isDragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- 🎣 ปุ่มเปิด/ปิดเมนูลอยบนหน้าจอ (กดคลิกได้ตลอดเวลา / ลากย้ายตำแหน่งได้)
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.new(0, 56, 0, 56)
FloatingToggle.Position = UDim2.new(0, 16, 0.45, 0)
FloatingToggle.BackgroundColor3 = Color3.fromRGB(138, 92, 246)
FloatingToggle.Text = "🎣"
FloatingToggle.TextSize = 28
FloatingToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingToggle.Font = Enum.Font.GothamBold
FloatingToggle.Parent = ScreenGui

local FTC_Corner = Instance.new("UICorner")
FTC_Corner.CornerRadius = UDim.new(1, 0)
FTC_Corner.Parent = FloatingToggle

local FTC_Stroke = Instance.new("UIStroke")
FTC_Stroke.Thickness = 2
FTC_Stroke.Color = Color3.fromRGB(255, 255, 255)
FTC_Stroke.Parent = FloatingToggle

local ftDragging, ftStart, ftPos = false, nil, nil
FloatingToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ftDragging = true
        ftStart = input.Position
        ftPos = FloatingToggle.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then ftDragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if ftDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - ftStart
        FloatingToggle.Position = UDim2.new(ftPos.X.Scale, ftPos.X.Offset + delta.X, ftPos.Y.Scale, ftPos.Y.Offset + delta.Y)
    end
end)

FloatingToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ⌨️ กดปุ่ม [ Z ] หรือ [ RightShift ] เพื่อเปิด / ปิด เมนู (ไม่โดนบล็อก)
UserInputService.InputBegan:Connect(function(input)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    notify("Pond Hub", "กดปุ่ม 🎣 บนหน้าจอ หรือกดปุ่ม [ Z ] เพื่อเปิดเมนูกลับมา", 3)
end)

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    TabBar.Visible = not isMinimized
    for id, f in pairs(TabFrames) do f.Visible = (not isMinimized and id == currentTabId) end
    LogFrame.Visible = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 660, 0, 48) or UDim2.new(0, 660, 0, 660)
end)

-- 🔄 Rejoin Button Event
RejoinBtn.MouseButton1Click:Connect(function()
    addLog("🔄 กำลังเชื่อมต่อเข้าเซิร์ฟเวอร์ใหม่อัตโนมัติ...", Color3.fromRGB(96, 165, 250))
    notify("Rejoin Server", "กำลังเชื่อมต่อเข้าเซิร์ฟเวอร์ใหม่...", 3)
    task.wait(0.5)
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\n[Rejoin] กำลังเข้าเซิร์ฟเวอร์ใหม่...")
            task.wait(0.2)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
end)

-- ===================================================================
-- 🔍 CORE HELPER FUNCTIONS
-- ===================================================================

local function parseTimerText(timerStr)
    if not timerStr then return 0 end
    local h, m, s = timerStr:match("(%d+):(%d+):(%d+)")
    if h and m and s then return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s) end
    local min, sec = timerStr:match("(%d+):(%d+)")
    if min and sec then return (tonumber(min) * 60) + tonumber(sec) end
    return 0
end

local function checkMerlinBuffs()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local hud = pgui and pgui:FindFirstChild("hud")
    local statuses = hud and hud:FindFirstChild("safezone") and hud.safezone:FindFirstChild("statuses")
    
    local buffStatus = {
        Lucky = { active = false, remaining = 0, text = "ไม่มี" },
        Insight = { active = false, remaining = 0, text = "ไม่มี" },
        Lure = { active = false, remaining = 0, text = "ไม่มี" },
    }
    
    if statuses then
        for _, frame in ipairs(statuses:GetChildren()) do
            if frame:IsA("Frame") and frame.Visible then
                local displayName = frame:FindFirstChild("displayName")
                local timerLabel = frame:FindFirstChild("timer")
                local nameText = displayName and displayName.Text or frame.Name
                local rawTime = timerLabel and timerLabel.Text or "00:00"
                local remainingSec = parseTimerText(rawTime)
                
                if nameText:find("Lucky") or frame.Name:find("Luck") then
                    buffStatus.Lucky.active = true
                    buffStatus.Lucky.remaining = remainingSec
                    buffStatus.Lucky.text = rawTime
                elseif nameText:find("Insight") or frame.Name:find("Xp") then
                    buffStatus.Insight.active = true
                    buffStatus.Insight.remaining = remainingSec
                    buffStatus.Insight.text = rawTime
                elseif nameText:find("Lure") or frame.Name:find("Lure") then
                    buffStatus.Lure.active = true
                    buffStatus.Lure.remaining = remainingSec
                    buffStatus.Lure.text = rawTime
                end
            end
        end
    end
    
    LblMerlinLucky.Text = string.format("🍀 Lucky V (+25%%): %s", buffStatus.Lucky.text)
    LblMerlinLure.Text = string.format("⏱️ Lure IV (+20%%): %s", buffStatus.Lure.text)
    LblMerlinInsight.Text = string.format("⚡ Insight IV (+20%%): %s", buffStatus.Insight.text)
    
    return buffStatus
end

local isBuyingMerlin = false

local function buySingleBuff(nodeId)
    local s, res = pcall(function()
        return dialogInteract:InvokeServer(nodeId, 1)
    end)
    return s, res
end

local function initMerlinSessionAndBuy(needLucky, needLure, needInsight, isManual)
    local root = getRoot()
    if not root then
        isBuyingMerlin = false
        return false
    end
    
    if isPearlRunning or isMirrorRunning or isSwordRunning or isAuroraRunning then
        addLog("⚠️ มีฟังก์ชันอื่นกำลังทำงานอยู่ ไม่สามารถวาร์ปไปหา Merlin ได้ในขณะนี้", Color3.fromRGB(251, 191, 36))
        if isManual then notify("Merlin Buffs", "มีงานอื่นทำงานอยู่ กรุณารอหรือหยุดงานเดิมก่อน", 3) end
        isBuyingMerlin = false
        return false
    end
    
    local char = LocalPlayer.Character
    local origCFrame = root.CFrame
    
    addLog("🧙‍♂️ กำลังวาร์ปไปคุยและซื้อบัฟกับ Merlin (Sunstone Island)...", Color3.fromRGB(251, 191, 36))
    if isManual then notify("Merlin Buffs", "กำลังวาร์ปไปหา Merlin...", 3) end
    
    ProximityPromptService.Enabled = true
    if char and char:FindFirstChild("dialoglink") then char.dialoglink:Destroy() end
    
    -- วาร์ปไปที่พิกัด Merlin บน Sunstone Island
    root.CFrame = CFrame.new(MERLIN_POS + Vector3.new(0, 2, 3), MERLIN_POS)
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    
    -- รอ StreamingEnabled โหลด NPC Merlin (สูงสุด 3.5 วินาที)
    local merlin = nil
    local t0 = tick()
    while tick() - t0 < 3.5 do
        merlin = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs") and workspace.world.npcs:FindFirstChild("Merlin")
        if not merlin then merlin = workspace:FindFirstChild("Merlin", true) end
        if merlin and (merlin:FindFirstChild("ProximityPrompt") or merlin:FindFirstChildWhichIsA("ProximityPrompt", true)) then
            break
        end
        task.wait(0.2)
    end
    
    if not merlin then
        addLog("❌ ไม่พบ NPC Merlin หรือโหลดแมพไม่ทัน (กรุณาลองใหม่อีกครั้ง)", Color3.fromRGB(248, 113, 113))
        if origCFrame then
            task.wait(0.2)
            root.CFrame = origCFrame
            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero
        end
        isBuyingMerlin = false
        return false
    end
    
    local prompt = merlin:FindFirstChild("ProximityPrompt") or merlin:FindFirstChildWhichIsA("ProximityPrompt", true)
    local head = merlin and (merlin:FindFirstChild("Head") or merlin.PrimaryPart or merlin:FindFirstChildWhichIsA("BasePart"))
    
    if head then
        root.CFrame = CFrame.new(head.Position + Vector3.new(0, 0, 2), head.Position)
        root.Velocity = Vector3.zero
        task.wait(0.2)
    end
    
    -- รอรับ OnClientEvent ยืนยันว่า Session เปิดจริง
    local dialogStarted = false
    local conn = dialogStartEvent.OnClientEvent:Connect(function()
        dialogStarted = true
    end)
    
    if prompt then
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
        if fireproximityprompt then fireproximityprompt(prompt, 0) end
    end
    
    local t1 = tick()
    while tick() - t1 < 2.5 do
        if dialogStarted then break end
        task.wait(0.05)
    end
    conn:Disconnect()
    
    if dialogStarted then
        hasMerlinSession = true
        task.wait(0.1)
        
        -- กดซื้อทันทีตามคำสั่งโดยไม่ต้องเช็คบัฟก่อน
        buySingleBuff(30)
        task.wait(0.15)
        buySingleBuff(31)
        task.wait(0.15)
        buySingleBuff(32)
        task.wait(0.15)
        
        addLog("✅ สั่งซื้อบัฟ Merlin ทั้ง 3 ตัวเรียบร้อย! (Lucky V 🍀, Lure IV ⏱️, Insight IV ⚡)", Color3.fromRGB(52, 211, 153))
        notify("Merlin Buffs", "✅ ซื้อบัฟทั้ง 3 ตัวสำเร็จ!", 4)
    else
        addLog("❌ กดคุยกับ Merlin ไม่สำเร็จ (Prompt ไม่ตอบสนอง)", Color3.fromRGB(248, 113, 113))
    end
    
    if char and char:FindFirstChild("dialoglink") then char.dialoglink:Destroy() end
    ProximityPromptService.Enabled = true
    
    -- วาร์ปกลับจุดเดิมทันที
    if origCFrame then
        task.wait(0.3)
        root.CFrame = origCFrame
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
        addLog("📍 วาร์ปกลับมาจุดฟาร์มเดิมเรียบร้อย", Color3.fromRGB(96, 165, 250))
    end
    
    task.wait(0.5)
    checkMerlinBuffs()
    isBuyingMerlin = false
    return dialogStarted
end

local function executeMerlinBuffs(needLucky, needLure, needInsight, isManual)
    if isBuyingMerlin then return end
    isBuyingMerlin = true
    
    task.spawn(function()
        local root = getRoot()
        if not root then
            isBuyingMerlin = false
            return
        end
        
        -- ถ้ามี Session สั่งซื้อระยะไกลทันที
        if hasMerlinSession then
            addLog("⚡ กำลังส่งคำสั่งซื้อบัฟ Merlin ทั้ง 3 ตัว (ระยะไกล)...", Color3.fromRGB(147, 197, 253))
            local s1, r1 = buySingleBuff(30)
            task.wait(0.12)
            local s2, r2 = buySingleBuff(31)
            task.wait(0.12)
            local s3, r3 = buySingleBuff(32)
            task.wait(0.12)
            
            if s1 and r1 ~= nil then
                task.wait(0.4)
                checkMerlinBuffs()
                addLog("✅ สั่งซื้อบัฟ Merlin ทั้ง 3 ตัวเรียบร้อย! (Lucky V 🍀, Lure IV ⏱️, Insight IV ⚡)", Color3.fromRGB(52, 211, 153))
                if isManual then notify("Merlin Buffs", "✅ ซื้อบัฟทั้ง 3 ตัวสำเร็จ!", 4) end
                isBuyingMerlin = false
                return
            else
                addLog("⚠️ Session ระยะไกลไม่ตอบสนอง กำลังวาร์ปไปคุยตรงกับ Merlin...", Color3.fromRGB(251, 191, 36))
                hasMerlinSession = false
            end
        end
        
        -- ถ้ายังไม่มี Session หรือยิงระยะไกลไม่ผ่าน ให้วาร์ปไปคุยตรงๆ
        initMerlinSessionAndBuy(true, true, true, isManual)
    end)
end

local function buyMerlinBuffs(force)
    executeMerlinBuffs(true, true, true, true)
end

local function buyItem(itemName, category, amount)
    amount = amount or 1
    if purchaseRemote then
        pcall(function() purchaseRemote:FireServer(itemName, category or "Item", amount) end)
        addLog(string.format("🛒 สั่งซื้อ %s (x%d) สำเร็จ!", itemName, amount), Color3.fromRGB(96, 165, 250))
        notify("Shop", string.format("ซื้อ %s สำเร็จ!", itemName), 3)
    end
end

-- ===================================================================
-- 🪱 AUTO BUY & AUTO OPEN BAIT FUNCTIONS
-- ===================================================================
local function getCrateInfo(crateName)
    local inv = DataController.InventoryReplicator and DataController.InventoryReplicator.Data and DataController.InventoryReplicator.Data.Inventory
    if inv then
        for k, v in pairs(inv) do
            local vName = v.name or (v.sub and v.sub.Name) or ""
            if vName == crateName or vName:lower():find(crateName:lower()) then
                local stack = (v.sub and v.sub.Stack) or 1
                return stack, k
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t.Name == crateName or t.Name:lower():find(crateName:lower())) then
                return 1, t.Name, t
            end
        end
    end
    return 0, nil
end

local function startAutoBuyBaitLoop()
    task.spawn(function()
        addLog("🛒 เริ่มระบบ Auto Buy: " .. selectedBait .. " (ซื้อเรื่อยๆ)...", Color3.fromRGB(96, 165, 250))
        while isAutoBuyingBait do
            if purchaseRemote then
                pcall(function()
                    purchaseRemote:FireServer(selectedBait, "Fish", nil, 100)
                end)
                addLog(string.format("📦 สั่งซื้อ %s (x100 กล่อง)...", selectedBait), Color3.fromRGB(52, 211, 153))
            end
            task.wait(1.5)
        end
        addLog("⏹ หยุดระบบ Auto Buy เหยื่อเรียบร้อย", Color3.fromRGB(156, 163, 175))
    end)
end

local function startAutoOpenBaitLoop()
    task.spawn(function()
        addLog("🪱 เริ่มระบบ Auto Open: " .. selectedBait .. " (เปิดเรื่อยๆ)...", Color3.fromRGB(167, 139, 250))
        while isAutoOpeningBait do
            local count, key, toolObj = getCrateInfo(selectedBait)
            if count <= 0 and not key and not toolObj then
                addLog("⚠️ ยังไม่พบ " .. selectedBait .. " ในตัว (รอของเข้า...)", Color3.fromRGB(251, 191, 36))
                task.wait(1)
            else
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local tool = char:FindFirstChild(selectedBait) or (toolObj and toolObj.Parent == char and toolObj)
                
                if not tool then
                    if key and equipRemote then
                        pcall(function() equipRemote:FireServer(key) end)
                    elseif toolObj then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum:EquipTool(toolObj) end
                    end
                    task.wait(0.3)
                    tool = char:FindFirstChild(selectedBait)
                end
                
                if tool then
                    tool:Activate()
                    addLog(string.format("✨ เปิด %s เรียบร้อย! (เหลือประมาณ %d)", selectedBait, count), Color3.fromRGB(52, 211, 153))
                    task.wait(0.6)
                else
                    task.wait(0.3)
                end
            end
        end
        addLog("⏹ หยุดระบบ Auto Open เหยื่อเรียบร้อย", Color3.fromRGB(156, 163, 175))
    end)
end

-- ===================================================================
-- 🌌 AUTO BUY AURORA TOTEM FUNCTIONS
-- ===================================================================
local function getActiveAuroraTotems()
    local list = {}
    local interactables = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("interactables")
    local candidates = interactables and interactables:GetChildren() or {}
    
    for _, obj in ipairs(candidates) do
        if obj.Name == "Aurora Totem" and obj:IsA("Model") then
            local handle = obj:FindFirstChild("handle") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if handle then
                table.insert(list, { model = obj, handle = handle, pos = handle.Position })
            end
        end
    end
    
    -- ค้นหาเพิ่มเติมใน workspace หากไม่อยู่ใน interactables
    if #list == 0 then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "Aurora Totem" and obj:IsA("Model") then
                local handle = obj:FindFirstChild("handle") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if handle then
                    table.insert(list, { model = obj, handle = handle, pos = handle.Position })
                end
            end
        end
    end
    
    return list
end

local function findNearbyAuroraTotem(pos, maxDist)
    local interactables = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("interactables")
    local candidates = interactables and interactables:GetChildren() or workspace:GetChildren()
    local nearest = nil
    local minDist = maxDist or 50
    
    for _, obj in ipairs(candidates) do
        if obj.Name == "Aurora Totem" and obj:IsA("Model") then
            local handle = obj:FindFirstChild("handle") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if handle then
                local dist = (pos - handle.Position).Magnitude
                if dist <= minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest, minDist
end

local function buyTotem(totemModel)
    local root = getRoot()
    if not root or not totemModel then return false end
    local handle = totemModel:FindFirstChild("handle") or totemModel.PrimaryPart or totemModel:FindFirstChildWhichIsA("BasePart")
    if not handle then return false end
    
    -- วาร์ปเข้าประชิดแท่น Totem ในระยะ 1.5-2 studs
    root.CFrame = CFrame.new(handle.Position + Vector3.new(0, 1.2, 1.8), handle.Position)
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    task.wait(0.35)
    
    -- 1. กด ProximityPrompt หากมี
    local prompt = totemModel:FindFirstChildOfClass("ProximityPrompt") or totemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt, 0)
            else
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end
        end)
    end
    
    -- 2. ยิง RemoteFunction สั่งซื้อตรงผ่านเซิร์ฟเวอร์
    if not auroraPurchaseRemote then
        pcall(function()
            auroraPurchaseRemote = Net:RemoteFunction("AuroraTotem/Purchase")
        end)
    end
    
    local boughtSuccess = false
    if auroraPurchaseRemote then
        local success, res1, res2 = pcall(function()
            return auroraPurchaseRemote:InvokeServer(totemModel)
        end)
        if success and res1 == true then
            addLog("💰 ซื้อ Aurora Totem สำเร็จเรียบร้อย!", Color3.fromRGB(52, 211, 153))
            notify("Aurora Totem", "ซื้อ Aurora Totem สำเร็จ!", 3)
            boughtSuccess = true
        elseif success and res1 == false and res2 then
            addLog("⚠️ เซิร์ฟเวอร์แจ้งเตือน: " .. tostring(res2), Color3.fromRGB(251, 191, 36))
        end
    end
    
    -- 3. Fallback ยิง purchase event
    if not boughtSuccess and purchaseRemote then
        pcall(function()
            purchaseRemote:FireServer("Aurora Totem", "Item", nil, 1)
        end)
    end
    
    return boughtSuccess
end

local function startAuroraLoop()
    task.spawn(function()
        local root = getRoot()
        local origCFrame = root and root.CFrame
        local totalBought = 0
        
        LblAuroraStatus.Text = "🎯 สถานะ: กำลังค้นหา..."
        LblAuroraStatus.TextColor3 = Color3.fromRGB(96, 165, 250)
        addLog("🚀 เริ่มระบบ Auto Buy Aurora Totem...", Color3.fromRGB(96, 165, 250))
        
        repeat
            -- ขั้นตอนที่ 1: ตรวจสอบแท่น Totem ที่เกิดอยู่ในแมพแบบ Real-time ทันที
            local activeTotems = getActiveAuroraTotems()
            if #activeTotems > 0 then
                addLog(string.format("🔍 ตรวจพบ Aurora Totem ในแมพ %d จุด! กำลังวาร์ปไปซื้อ...", #activeTotems), Color3.fromRGB(147, 197, 253))
                for idx, tData in ipairs(activeTotems) do
                    if not isAuroraRunning then break end
                    root = getRoot()
                    if not root then break end
                    
                    LblAuroraWaypoint.Text = string.format("📍 วาร์ปไปแท่นสด: [%d/%d]", idx, #activeTotems)
                    local bought = buyTotem(tData.model)
                    if bought then
                        totalBought = totalBought + 1
                        LblAuroraBought.Text = string.format("💰 ซื้อสำเร็จแล้ว: %d อัน", totalBought)
                    end
                    task.wait(1.0)
                end
            end
            
            -- ขั้นตอนที่ 2: วาร์ปสแกนตามพิกัด 46 จุดเพื่อค้นหาจุดที่อาจยังโหลดไม่เสร็จ
            if isAuroraRunning then
                addLog("📍 เริ่มการสแกนค้นหาตามพิกัด 46 จุดทั่วแมพ...", Color3.fromRGB(192, 132, 252))
                for index, pos in ipairs(AuroraPositions) do
                    if not isAuroraRunning then break end
                    root = getRoot()
                    if not root then break end
                    
                    LblAuroraWaypoint.Text = string.format("📍 กำลังตรวจจุดที่: [%d/46]", index)
                    root.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                    root.Velocity = Vector3.zero
                    root.RotVelocity = Vector3.zero
                    task.wait(0.35)
                    
                    local totem, dist = findNearbyAuroraTotem(pos, 50)
                    if totem then
                        addLog(string.format("🎯 [%d/46] พบ Aurora Totem (ระยะ %.1f studs)! กำลังซื้อ...", index, dist), Color3.fromRGB(251, 191, 36))
                        local bought = buyTotem(totem)
                        if bought then
                            totalBought = totalBought + 1
                            LblAuroraBought.Text = string.format("💰 ซื้อสำเร็จแล้ว: %d อัน", totalBought)
                        end
                    end
                    
                    task.wait(1.0)
                end
            end
            
            if isAuroraRunning and auroraLoopForever then
                addLog("⏳ วาร์ปครบทุกจุดแล้ว รอ 30 วินาทีก่อนเริ่มรอบใหม่...", Color3.fromRGB(156, 163, 175))
                task.wait(30)
            else
                break
            end
        until not isAuroraRunning or not auroraLoopForever
        
        isAuroraRunning = false
        ToggleAuroraBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
        ToggleAuroraBtn.Text = "⚪ [OFF] Auto Buy Aurora (คลิกเพื่อเริ่มค้นหา 46 จุด)"
        LblAuroraStatus.Text = "🎯 สถานะ: ปิดอยู่ (Standby)"
        LblAuroraStatus.TextColor3 = Color3.fromRGB(156, 163, 175)
        
        if origCFrame and root then
            task.wait(0.3)
            root.CFrame = origCFrame
            root.Velocity = Vector3.zero
            addLog("📍 วาร์ปกลับจุดเดิมเรียบร้อย", Color3.fromRGB(96, 165, 250))
        end
        addLog(string.format("⏹ ระบบ Auto Aurora สิ้นสุดการทำงาน (ซื้อได้ %d อัน)", totalBought), Color3.fromRGB(167, 139, 250))
    end)
end

-- ===================================================================
-- 🔮 SHROUDED PEARL AUTO APPRAISE (MULTI-LAYER SAFETY & INSTANT HALT)
-- ===================================================================
local function getInventoryData()
    return DataController.InventoryReplicator and DataController.InventoryReplicator.Data and DataController.InventoryReplicator.Data.Inventory
end

local function getAllPearls()
    local inv = getInventoryData()
    local pearls = {}
    if inv then
        for id, item in pairs(inv) do
            if item.name == "Golden Sea Pearl" or (item.name and item.name:lower():find("golden sea pearl")) then
                local mut = (item.sub and (item.sub.Mutation or item.sub.mutation)) or "None"
                local isShrouded = (type(mut) == "string" and mut:lower():find("shrouded") ~= nil)
                table.insert(pearls, { id = id, name = item.name, mutation = mut, isShrouded = isShrouded, sub = item.sub })
            end
        end
    end
    return pearls
end

local function countShroudedInInventory()
    local inv = getInventoryData()
    local count = 0
    if inv then
        for _, item in pairs(inv) do
            if item.name and item.name:lower():find("pearl") then
                local mut = item.sub and (item.sub.Mutation or item.sub.mutation)
                if mut and type(mut) == "string" and mut:lower():find("shrouded") then
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function updatePearlUI()
    local pearls = getAllPearls()
    local total, shrouded, pending = #pearls, 0, 0
    for _, p in ipairs(pearls) do
        if p.isShrouded then shrouded = shrouded + 1 else pending = pending + 1 end
    end
    LblPearlTotal.Text = string.format("📦 ไข่มุกในตัว: %d เม็ด", total)
    LblPearlShrouded.Text = string.format("✨ ติด Shrouded: %d เม็ด", shrouded)
    LblPearlPending.Text = string.format("⏳ ต้องรีเพิ่ม: %d เม็ด", pending)
    return pearls
end

-- ดึงข้อมูล Tool ที่กำลังถืออยู่ในมือจริง ณ วินาทีนั้น
local function getHeldPearlInfo()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildWhichIsA("Tool")
    if not tool then return nil, nil, nil end
    
    local linkObj = tool:FindFirstChild("link")
    local linkId = linkObj and linkObj.Value
    
    local attrMut = tool:GetAttribute("Mutation") or tool:GetAttribute("mutation")
    local valMut = tool:FindFirstChild("values") and tool.values:FindFirstChild("Mutation") and tool.values.Mutation.Value
    
    return tool, linkId, (attrMut or valMut)
end

-- ตรวจสอบอย่างละเอียดรอบด้านทุกช่องทาง (Tool จริงในมือ + Link ID + Target ID + Attribute + Replicator)
-- ตรวจสอบอย่างละเอียดรอบด้านทุกช่องทาง (Tool จริงในมือ + Link ID + Target ID + Attribute + Replicator)
local function checkPearlHeldStatus(targetId)
    local inv = getInventoryData()
    local heldTool, heldLinkId, toolMut = getHeldPearlInfo()
    
    -- 1. ตรวจสอบ Tool ที่ถืออยู่ในมือจริงก่อนเป็นอันดับแรก (Priority 1)
    if heldTool then
        -- 1.1 ชื่อ Tool มีคำว่า shrouded หรือไม่
        if heldTool.Name:lower():find("shrouded") then
            return true, "Shrouded (Tool Name)", heldLinkId or targetId
        end
        -- 1.2 Tool Attribute หรือ Values
        if toolMut and type(toolMut) == "string" and toolMut:lower():find("shrouded") then
            return true, tostring(toolMut), heldLinkId or targetId
        end
        -- 1.3 ข้อมูลจาก Inventory ของเม็ดที่ถืออยู่ในมือจริง (นี่คือเม็ดที่ NPC กำลังรีจริง 100%)
        if inv and heldLinkId and inv[heldLinkId] and inv[heldLinkId].sub then
            local m = inv[heldLinkId].sub.Mutation or inv[heldLinkId].sub.mutation
            local isShrouded = (type(m) == "string" and m:lower():find("shrouded") ~= nil)
            return isShrouded, tostring(m or "None"), heldLinkId
        end
    end
    
    -- 2. หากยังไม่ได้ถือหรือหา Tool ในมือไม่เจอ จึงตรวจสอบจาก targetId ใน Inventory
    if inv and targetId and inv[targetId] and inv[targetId].sub then
        local m = inv[targetId].sub.Mutation or inv[targetId].sub.mutation
        local isShrouded = (type(m) == "string" and m:lower():find("shrouded") ~= nil)
        return isShrouded, tostring(m or "None"), targetId
    end
    
    return false, "None", heldLinkId or targetId
end

-- 🛡️ ระบบเซฟตี้หยุดฉุกเฉิน (Instant Safety Interlock) ป้องกันรีทับ 100%
local function emergencyStopPearlProtection()
    -- 1. เก็บไอเทมกลับกระเป๋าทันที เพื่อไม่ให้ NPC รีทับได้
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:UnequipTools()
        end
    end)
    
    -- 2. ตัดการเชื่อมต่อ Dialog ทันที
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("dialoglink") then
            char.dialoglink:Destroy()
        end
    end)
    
    -- 3. เล่นเสียงแจ้งเตือนความสำเร็จ
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://9069609200"
        sound.Volume = 1.2
        sound.Parent = workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)
    end)
end

-- ฟังก์ชันดึงไข่มุกมาถือให้ตรงเม็ดเป้าหมายจริง 100%
local function equipTargetPearl(targetId)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    
    -- 1. ถ้าในมือถือเม็ดที่มี link ตรงกับ targetId อยู่แล้ว
    local currentTool = char:FindFirstChildWhichIsA("Tool")
    if currentTool and currentTool:FindFirstChild("link") and currentTool.link.Value == targetId then
        return currentTool
    end
    
    -- 2. ค้นหาใน Backpack ตาม link.Value ให้ตรงกับ targetId
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("pearl") then
                local link = t:FindFirstChild("link")
                if link and link.Value == targetId then
                    hum:EquipTool(t)
                    task.wait(0.3)
                    return t
                end
            end
        end
    end
    
    -- 3. ขอ Server สวมใส่ผ่าน Remote
    pcall(function() equipRemote:FireServer(targetId) end)
    task.wait(0.35)
    
    -- 4. ตรวจสอบว่ามีอะไรในมือหรือยัง หากยังไม่มีให้ถือ Pearl เม็ดใดก็ได้ที่มี
    local afterTool = char:FindFirstChildWhichIsA("Tool")
    if not afterTool and bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("pearl") then
                hum:EquipTool(t)
                task.wait(0.3)
                return t
            end
        end
    end
    
    return afterTool
end

local function startPearlLoop()
    if isPearlRunning then return end
    isPearlRunning = true
    StartPearlBtn.Text = "⚡ กำลังทำงาน..."
    StartPearlBtn.BackgroundColor3 = Color3.fromRGB(100, 116, 139)
    LblPearlProgress.Text = "🎯 สถานะ: กำลังทำงาน..."
    LblPearlProgress.TextColor3 = Color3.fromRGB(52, 211, 153)
    
    local appraiser = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs") and workspace.world.npcs:FindFirstChild("Appraiser")
    if not appraiser then appraiser = workspace:FindFirstChild("Appraiser", true) end
    local prompt = appraiser and (appraiser:FindFirstChildOfClass("ProximityPrompt") or appraiser:FindFirstChildWhichIsA("ProximityPrompt", true))
    
    local root = getRoot()
    if not root or not appraiser or not prompt then
        addLog("❌ ไม่พบ NPC Appraiser", Color3.fromRGB(248, 113, 113))
        isPearlRunning = false
        StartPearlBtn.Text = "▶ เริ่มรีไข่มุก (Start)"
        StartPearlBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        LblPearlProgress.Text = "🎯 สถานะ: ปิดอยู่ (Standby)"
        LblPearlProgress.TextColor3 = Color3.fromRGB(156, 163, 175)
        return
    end
    
    local origPos = root.CFrame
    
    -- กระจายตำแหน่งยืนรอบตัว NPC เล็กน้อยตาม UserId (ป้องกันตัวละคร 4 ไอดีชนกัน/ผลักกันตกแท่น)
    local appraiserPos = (appraiser.PrimaryPart or appraiser:FindFirstChildWhichIsA("BasePart") or appraiser:GetPivot()).Position
    local userOffsetAngle = ((LocalPlayer.UserId or 0) % 8) * (math.pi / 4)
    local standPos = appraiserPos + Vector3.new(math.cos(userOffsetAngle) * 4.2, 0, math.sin(userOffsetAngle) * 4.2)
    root.CFrame = CFrame.new(standPos, appraiserPos)
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    task.wait(0.4)
    
    -- ฟังก์ชันเปิด Session พูดคุยกับ Appraiser (เปิดแค่ครั้งแรกต่อเม็ด ไม่ต้องกด Prompt ซ้ำทุกรอบ)
    local function ensureDialogSession()
        local char = LocalPlayer.Character
        if not char then return false end
        if char:FindFirstChild("dialoglink") then return true end
        
        ProximityPromptService.Enabled = true
        local dialogStarted = false
        local conn = dialogStartEvent.OnClientEvent:Connect(function() dialogStarted = true end)
        
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.02)
            prompt:InputHoldEnd()
            if fireproximityprompt then fireproximityprompt(prompt, 0) end
        end)
        
        local t0 = tick()
        while tick() - t0 < 1.0 do
            if dialogStarted or (char and char:FindFirstChild("dialoglink")) then break end
            task.wait(0.03)
        end
        conn:Disconnect()
        
        if char:FindFirstChild("dialoglink") or dialogStarted then
            task.wait(0.05)
            pcall(function() dialogInteract:InvokeServer(1, 1) end) -- Node 1: "Can you appraise this fish?"
            task.wait(0.08)
            pcall(function() dialogInteract:InvokeServer(3, 1) end) -- Node 3: "Yes!"
            task.wait(0.08)
            return true
        end
        return false
    end
    
    while isPearlRunning do
        local pearls = updatePearlUI()
        local pending = {}
        for _, p in ipairs(pearls) do if not p.isShrouded then table.insert(pending, p) end end
        
        if #pending == 0 then
            addLog("🎉 ไข่มุกทุกเม็ดติด Shrouded ครบ 100% แล้ว!", Color3.fromRGB(52, 211, 153))
            notify("🎉 Shrouded Hub", "ไข่มุกทุกเม็ดติด Shrouded ครบแล้ว!", 6)
            break
        end
        
        local currentTarget = pending[1]
        equipTargetPearl(currentTarget.id)
        task.wait(0.25)
        
        -- หา ID จริงของเม็ดที่กำลังถืออยู่ในมือ
        local _, activeHeldId = getHeldPearlInfo()
        local activePearlId = activeHeldId or currentTarget.id
        
        -- ตรวจสอบก่อนเริ่ม: เม็ดนี้ติด Shrouded อยู่แล้วหรือไม่
        local initShrouded, initMut = checkPearlHeldStatus(activePearlId)
        if initShrouded then
            emergencyStopPearlProtection()
            addLog(string.format("✨ เม็ดนี้ติด Shrouded อยู่แล้ว! (ข้าม)", tostring(activePearlId)), Color3.fromRGB(52, 211, 153))
            updatePearlUI()
            task.wait(0.4)
            continue
        end
        
        local baselineShroudedCount = countShroudedInInventory()
        local lastLoggedMut = ""
        local attempts = 0
        LblPearlProgress.Text = string.format("🎯 กำลังรีเม็ดที่เหลือ (เหลือ %d เม็ด)", #pending)
        addLog(string.format("🔮 เริ่มรีไข่มุก ID: ...%s", tostring(activePearlId):sub(-6)), Color3.fromRGB(192, 132, 252))
        
        -- เปิด Dialog Session กับ Appraiser สำหรับเม็ดนี้
        local sessionReady = ensureDialogSession()
        if not sessionReady then
            addLog("⚠️ กำลังรอคิวเปิดบทสนทนากับ Appraiser...", Color3.fromRGB(251, 191, 36))
            task.wait(0.3)
        end
        
        while isPearlRunning and attempts < 2000 do
            -- ตรวจสอบ ID ล่าสุดในมือเสมอ (เผื่อเซิร์ฟเวอร์เปลี่ยน ID หลังรี)
            local _, curHeldId = getHeldPearlInfo()
            if curHeldId then activePearlId = curHeldId end
            
            -- 🛡️ ตรวจสอบความปลอดภัยสูงสุดก่อนเริ่มทุกรอบ
            local isShrouded, curMut = checkPearlHeldStatus(activePearlId)
            local currentShroudedCount = countShroudedInInventory()
            LblPearlCurMut.Text = string.format("🔮 มิวเทชันล่าสุด: %s (รอบที่ %d)", tostring(curMut), attempts)
            
            if isShrouded or currentShroudedCount > baselineShroudedCount then
                emergencyStopPearlProtection()
                addLog(string.format("🎉 สำเร็จ! ได้รับ Shrouded เรียบร้อยแล้ว! (ใช้ไป %d รอบ)", attempts), Color3.fromRGB(52, 211, 153))
                notify("Shrouded Hub", "✅ ติด Shrouded แล้ว 1 เม็ด! (เก็บเข้ากระเป๋าทันที)", 4)
                updatePearlUI()
                break
            end
            
            -- ตรวจสอบว่ายังมี Dialog Session อยู่หรือไม่ (หากหลุดให้ต่อใหม่)
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("dialoglink") then
                local ok = ensureDialogSession()
                if not ok then
                    task.wait(0.2)
                    continue
                end
            end
            
            attempts = attempts + 1
            
            -- ⚡ ส่งคำสั่งรีซ้ำทันที (Node 7 Choice 1: "Can you appraise it again?")
            -- วิธีนี้ไม่ต้องปิด-เปิดบทสนทนาใหม่ ไม่ต้องแย่ง ProximityPrompt กับไอดีอื่น
            local s7, r7 = pcall(function()
                return dialogInteract:InvokeServer(7, 1)
            end)
            
            if not s7 or r7 == false then
                -- หากเซิร์ฟเวอร์ปฏิเสธ ให้ตัด Session แล้วต่อใหม่รอบถัดไป
                if char and char:FindFirstChild("dialoglink") then
                    pcall(function() char.dialoglink:Destroy() end)
                end
                task.wait(0.15)
                continue
            end
            
            -- 🛡️ ACTIVE POLLING (รอผลลัพธ์มิวเทชันแบบกระชับ รวดเร็ว ไม่ถ่วงเวลา)
            local gotShrouded = false
            local pollStart = tick()
            local pollMut = curMut
            
            while tick() - pollStart < 0.35 do
                local _, liveHeldId = getHeldPearlInfo()
                if liveHeldId then activePearlId = liveHeldId end
                local sCheck, sMut = checkPearlHeldStatus(activePearlId)
                pollMut = sMut
                if sCheck or countShroudedInInventory() > baselineShroudedCount then
                    gotShrouded = true
                    break
                end
                task.wait(0.04)
            end
            
            -- บันทึก Log ทุก 10 รอบ หรือเมื่อมิวเทชันเปลี่ยนใหม่
            local shouldLog = (attempts % 10 == 0) or (pollMut ~= "None" and pollMut ~= lastLoggedMut)
            if shouldLog then
                lastLoggedMut = pollMut
                addLog(string.format("รอบที่ #%d -> %s", attempts, tostring(pollMut)), Color3.fromRGB(156, 163, 175))
            end
            
            -- 🛡️ หากติด Shrouded ให้หยุดรอบและเก็บเข้ากระเป๋าทันทีในวินาทีนี้!
            if gotShrouded then
                emergencyStopPearlProtection()
                addLog(string.format("🎉 สำเร็จ! ได้รับ Shrouded เรียบร้อยแล้ว! (ใช้ไป %d รอบ)", attempts), Color3.fromRGB(52, 211, 153))
                notify("Shrouded Hub", "✅ ติด Shrouded แล้ว 1 เม็ด! (เก็บเข้ากระเป๋าทันที)", 4)
                updatePearlUI()
                break
            end
            
            task.wait(0.05)
        end
        
        -- จบเม็ดนี้ เคลียร์ dialoglink เตรียมใส่เม็ดถัดไป
        emergencyStopPearlProtection()
        task.wait(0.4)
    end
    
    isPearlRunning = false
    StartPearlBtn.Text = "▶ เริ่มรีไข่มุก (Start)"
    StartPearlBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    LblPearlProgress.Text = "🎯 สถานะ: ปิดอยู่ (Standby)"
    LblPearlProgress.TextColor3 = Color3.fromRGB(156, 163, 175)
    
    if origPos then
        task.wait(0.4)
        root.CFrame = origPos
        root.Velocity = Vector3.zero
        addLog("📍 วาร์ปกลับจุดฟาร์มเดิมเรียบร้อย", Color3.fromRGB(96, 165, 250))
    end
end

-- ===================================================================
-- 🔘 BUTTON EVENTS
-- ===================================================================
StartPearlBtn.MouseButton1Click:Connect(function() task.spawn(startPearlLoop) end)
StopPearlBtn.MouseButton1Click:Connect(function()
    isPearlRunning = false
    emergencyStopPearlProtection()
    addLog("⏹ สั่งหยุดรีไข่มุกเรียบร้อย", Color3.fromRGB(248, 113, 113))
end)
RefreshPearlBtn.MouseButton1Click:Connect(function()
    updatePearlUI()
    addLog("🔄 อัปเดตข้อมูลไข่มุกในกระเป๋าเรียบร้อย", Color3.fromRGB(147, 197, 253))
end)

BuyAllMerlinBtn.MouseButton1Click:Connect(function() buyMerlinBuffs(true) end)

-- ปุ่มคลิกสลับสถานะเปิด / ปิด Auto-Renew Merlin
ToggleMerlinAuto.MouseButton1Click:Connect(function()
    autoRenewMerlin = not autoRenewMerlin
    ToggleMerlinAuto.BackgroundColor3 = autoRenewMerlin and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(55, 65, 81)
    ToggleMerlinAuto.Text = autoRenewMerlin and "🟢 [ON] Auto-Renew ทำงานอยู่ (คลิกเพื่อปิด)" or "⚪ [OFF] Auto-Renew ปิดอยู่ (คลิกเพื่อเปิด)"
    LblMerlinMode.Text = "🌐 สถานะ Auto-Renew: " .. (autoRenewMerlin and "เปิดทำงาน (Active)" or "ปิดอยู่ (Disabled)")
    LblMerlinMode.TextColor3 = autoRenewMerlin and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(156, 163, 175)
    addLog("🧙‍♂️ Auto-Renew Merlin: " .. (autoRenewMerlin and "เปิดใช้งาน" or "ปิดใช้งาน"), Color3.fromRGB(167, 139, 250))
end)

-- ปุ่มคลิกสลับสถานะเปิด / ปิด Auto Buy เหยื่อ
ToggleAutoBuyBait.MouseButton1Click:Connect(function()
    isAutoBuyingBait = not isAutoBuyingBait
    ToggleAutoBuyBait.BackgroundColor3 = isAutoBuyingBait and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(55, 65, 81)
    ToggleAutoBuyBait.Text = isAutoBuyingBait and "🟢 [ON] Auto Buy ทำงานอยู่ (คลิกเพื่อหยุด)" or "⚪ [OFF] Auto Buy เหยื่อ (คลิกเพื่อเริ่มซื้อเรื่อยๆ)"
    if isAutoBuyingBait then
        startAutoBuyBaitLoop()
    end
end)

-- ปุ่มคลิกสลับสถานะเปิด / ปิด Auto Open เหยื่อ
ToggleAutoOpenBait.MouseButton1Click:Connect(function()
    isAutoOpeningBait = not isAutoOpeningBait
    ToggleAutoOpenBait.BackgroundColor3 = isAutoOpeningBait and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(55, 65, 81)
    ToggleAutoOpenBait.Text = isAutoOpeningBait and "🟢 [ON] Auto Open ทำงานอยู่ (คลิกเพื่อหยุด)" or "⚪ [OFF] Auto Open เหยื่อ (คลิกเพื่อเริ่มเปิดเรื่อยๆ)"
    if isAutoOpeningBait then
        startAutoOpenBaitLoop()
    end
end)

BuyCrabTrapBtn.MouseButton1Click:Connect(function() buyItem("Crab Trap", "Item", 1) end)
BuyReinforcedTrapBtn.MouseButton1Click:Connect(function() buyItem("Reinforced Crab Trap", "Item", 1) end)

-- ปุ่มคลิกสลับสถานะเปิด / ปิด Auto Buy Aurora Totem
ToggleAuroraBtn.MouseButton1Click:Connect(function()
    isAuroraRunning = not isAuroraRunning
    ToggleAuroraBtn.BackgroundColor3 = isAuroraRunning and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(55, 65, 81)
    ToggleAuroraBtn.Text = isAuroraRunning and "🟢 [ON] Auto Aurora กำลังทำงาน... (คลิกเพื่อหยุด)" or "⚪ [OFF] Auto Buy Aurora (คลิกเพื่อเริ่มค้นหา 46 จุด)"
    if isAuroraRunning then
        startAuroraLoop()
    end
end)

-- ปุ่มคลิกเปิด / ปิด Loop วนซ้ำรอบใหม่
ToggleAuroraLoopBtn.MouseButton1Click:Connect(function()
    auroraLoopForever = not auroraLoopForever
    ToggleAuroraLoopBtn.BackgroundColor3 = auroraLoopForever and Color3.fromRGB(138, 92, 246) or Color3.fromRGB(39, 39, 52)
    ToggleAuroraLoopBtn.Text = auroraLoopForever and "🔁 โหมดวนซ้ำรอบใหม่: เปิดอยู่ (วนซ้ำเรื่อยๆ)" or "🔁 โหมดวนซ้ำรอบใหม่: ปิดอยู่ (วิ่งรอบเดียวจบ)"
    addLog("🌌 Aurora Loop Mode: " .. (auroraLoopForever and "เปิดวนซ้ำเรื่อยๆ" or "วิ่งรอบเดียวจบ"), Color3.fromRGB(192, 132, 252))
end)

-- ===================================================================
-- ⚡ OLYMPUS QUEST FUNCTIONS (หมุนกระจก 5 จุด & ส่งเควสดาบ)
-- ===================================================================
local mirrorPoints = {
    { pos = Vector3.new(-8771, -2900.13, 731.17), times = 5 },
    { pos = Vector3.new(-8890.45, -2887.56, 799.18), times = 7 },
    { pos = Vector3.new(-8852.26, -2877.19, 705.93), times = 3 },
    { pos = Vector3.new(-8799.24, -2854.69, 695.57), times = 3 },
    { pos = Vector3.new(-8809.42, -2802.7, 786.34), times = 7 }
}

local MIRROR_WAIT_WARP = 1.5
local MIRROR_WAIT_E = 1.0
local PROMPT_RADIUS = 25

local swordPoints = {
    Vector3.new(-8631.29, -2344.54, 623.95),
    Vector3.new(-8935.8, -2351.45, 799.07),
    Vector3.new(-8923.28, -2319.5, 962.54),
    Vector3.new(-8741.68, -2360.79, 688.97),
    Vector3.new(-8989.56, -2292.09, 218.77),
    Vector3.new(-9040.5, -2345.4, 1044.24),
    Vector3.new(-8704.65, -2344.42, 907.28),
    Vector3.new(-8484.81, -2360.91, 542.16),
    Vector3.new(-8951.5, -2288.49, 105.18)
}

local FINAL_SWORD_POINT = Vector3.new(-8568.52, -2345.85, 692.92)
local EXTRA_SWORD_POINT = Vector3.new(-8472.97, -2361.36, 726.87)
local HELMET_SWORD_POINT = Vector3.new(-8631.29, -2344.54, 623.95)
local SWORD_WAIT_WARP = 1.5
local SWORD_WAIT_COLLECT = 1.0

local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
        else
            prompt:InputHoldBegin()
            task.wait(0.08)
            prompt:InputHoldEnd()
        end
    end)
    return true
end

local function getNearestPrompt(radius)
    radius = radius or PROMPT_RADIUS
    local root = getRoot()
    if not root then return nil, 9999 end
    
    local nearest = nil
    local nearestDistance = radius
    
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local parent = prompt.Parent
            local position = nil
            if parent:IsA("BasePart") then
                position = parent.Position
            elseif parent:IsA("Attachment") then
                position = parent.WorldPosition
            elseif parent:IsA("Model") then
                position = parent:GetPivot().Position
            end
            
            if position then
                local distance = (position - root.Position).Magnitude
                if distance <= nearestDistance then
                    nearest = prompt
                    nearestDistance = distance
                end
            end
        end
    end
    return nearest, nearestDistance
end

local function collectNearbyPrompts(radius, times)
    radius = radius or PROMPT_RADIUS
    times = times or 1
    local root = getRoot()
    if not root then return end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parent = obj.Parent
            local pos = nil
            if parent:IsA("BasePart") then
                pos = parent.Position
            elseif parent:IsA("Attachment") then
                pos = parent.WorldPosition
            elseif parent:IsA("Model") then
                pos = parent:GetPivot().Position
            end
            
            if pos and (pos - root.Position).Magnitude <= radius then
                for i = 1, times do
                    triggerPrompt(obj)
                    task.wait(0.15)
                end
            end
        end
    end
end

local function equipBackpackTool(toolName)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if char:FindFirstChild(toolName) then return true end
    
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local tool = bp:FindFirstChild(toolName)
        if tool then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:EquipTool(tool)
                task.wait(0.3)
                return true
            end
        end
    end
    
    pcall(function()
        if equipRemote then
            equipRemote:FireServer(toolName)
        end
    end)
    return false
end

local function runMirror()
    if isMirrorRunning then
        isMirrorRunning = false
        addLog("⏹ สั่งหยุดระบบหมุนกระจกเรียบร้อย", Color3.fromRGB(248, 113, 113))
        return
    end
    if isSwordRunning then
        notify("เควส", "กำลังทำงานเควสดาบอยู่ กรุณารอให้เสร็จก่อน", 3)
        return
    end
    
    local root = getRoot()
    if not root then
        addLog("❌ ไม่พบตัวละคร ไม่สามารถเริ่มหมุนกระจกได้", Color3.fromRGB(248, 113, 113))
        return
    end
    
    isMirrorRunning = true
    lastSavedOlympusPos = root.CFrame
    MirrorQuestBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
    MirrorQuestBtn.Text = "⏳ กำลังหมุนกระจก... (คลิกเพื่อยกเลิก)"
    LblMirrorStatus.TextColor3 = Color3.fromRGB(251, 191, 36)
    LblMirrorStatus.Text = "🎯 เริ่มหมุนกระจก (ทั้งหมด 5 จุด)..."
    addLog("🪞 เริ่มระบบ Auto หมุนกระจกโอลิมปัส (5 จุด)...", Color3.fromRGB(251, 191, 36))
    notify("Olympus", "🪞 เริ่มต้นระบบหมุนกระจก 5 จุด!", 3)
    
    task.spawn(function()
        for idx, data in ipairs(mirrorPoints) do
            if not isMirrorRunning then break end
            
            MirrorQuestBtn.Text = string.format("🪞 หมุนกระจกจุดที่ [%d/5]...", idx)
            LblMirrorStatus.Text = string.format("📍 กำลังวาร์ปไปจุดที่ [%d/5] (หมุน %d ครั้ง)", idx, data.times)
            addLog(string.format("📍 วาร์ปไปจุดกระจก [%d/5]: หมุน %d ครั้ง", idx, data.times), Color3.fromRGB(147, 197, 253))
            
            teleportPlayer(CFrame.new(data.pos))
            task.wait(MIRROR_WAIT_WARP)
            
            for i = 1, data.times do
                if not isMirrorRunning then break end
                
                local prompt, dist = getNearestPrompt(PROMPT_RADIUS)
                if prompt then
                    triggerPrompt(prompt)
                    addLog(string.format("🪞 จุดที่ %d: หมุนรอบที่ %d/%d (ระยะ %.1f studs)", idx, i, data.times, dist), Color3.fromRGB(52, 211, 153))
                else
                    addLog(string.format("⚠️ จุดที่ %d: ไม่พบ Prompt กระจกในระยะ %d studs (รอบ %d/%d)", idx, PROMPT_RADIUS, i, data.times), Color3.fromRGB(251, 191, 36))
                end
                task.wait(MIRROR_WAIT_E)
            end
            
            task.wait(0.5)
        end
        
        if isMirrorRunning then
            addLog("🎉 หมุนกระจกโอลิมปัสครบทั้ง 5 จุดเรียบร้อยแล้ว!", Color3.fromRGB(52, 211, 153))
            notify("Olympus", "🎉 หมุนกระจกเสร็จสมบูรณ์!", 5)
            LblMirrorStatus.Text = "✅ หมุนกระจกเสร็จสิ้นครบ 5 จุด!"
            LblMirrorStatus.TextColor3 = Color3.fromRGB(52, 211, 153)
        else
            LblMirrorStatus.Text = "⏹ ยกเลิกการหมุนกระจกแล้ว"
            LblMirrorStatus.TextColor3 = Color3.fromRGB(248, 113, 113)
        end
        
        isMirrorRunning = false
        MirrorQuestBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        MirrorQuestBtn.Text = "🪞 [เริ่ม] ออโต้หมุนกระจก 5 จุด (Auto Rotate Mirrors)"
    end)
end

local function runSwordQuest()
    if isSwordRunning then
        isSwordRunning = false
        addLog("⏹ สั่งหยุดส่งเควสดาบเรียบร้อย", Color3.fromRGB(248, 113, 113))
        return
    end
    if isMirrorRunning then
        notify("เควส", "กำลังทำงานหมุนกระจกอยู่ กรุณารอให้เสร็จก่อน", 3)
        return
    end
    
    local root = getRoot()
    if not root then
        addLog("❌ ไม่พบตัวละคร ไม่สามารถเริ่มเควสดาบได้", Color3.fromRGB(248, 113, 113))
        return
    end
    
    isSwordRunning = true
    lastSavedOlympusPos = root.CFrame
    SwordQuestBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
    SwordQuestBtn.Text = "⏳ กำลังส่งเควสดาบ... (คลิกเพื่อยกเลิก)"
    LblSwordStatus.TextColor3 = Color3.fromRGB(251, 191, 36)
    LblSwordStatus.Text = "🎯 กำลังเริ่มส่งเควสดาบโอลิมปัส..."
    addLog("⚔️ เริ่มต้นเควสดาบโอลิมปัส (เก็บ 9 จุด + สวมดาบ/หมวก)...", Color3.fromRGB(251, 191, 36))
    notify("Olympus", "⚔️ เริ่มต้นเควสดาบโอลิมปัส!", 3)
    
    task.spawn(function()
        -- 1. วาร์ปเก็บดาบ 9 จุด
        for idx, pos in ipairs(swordPoints) do
            if not isSwordRunning then break end
            SwordQuestBtn.Text = string.format("⚔️ เก็บดาบจุดที่ [%d/9]...", idx)
            LblSwordStatus.Text = string.format("📍 กำลังเก็บดาบจุดที่ [%d/9]", idx)
            teleportPlayer(CFrame.new(pos))
            task.wait(SWORD_WAIT_WARP)
            collectNearbyPrompts(PROMPT_RADIUS, 1)
            addLog(string.format("⚔️ เก็บดาบจุดที่ [%d/9] เรียบร้อย", idx), Color3.fromRGB(147, 197, 253))
            task.wait(SWORD_WAIT_COLLECT)
        end
        
        -- 2. วาร์ปส่งเควสจุดสุดท้าย (สวม Bellona Sword + กด 5 ครั้ง)
        if isSwordRunning then
            SwordQuestBtn.Text = "⚔️ กำลังส่งเควส Bellona Sword..."
            LblSwordStatus.Text = "📍 วาร์ปไปแท่นดาบ & สวม Bellona Sword"
            teleportPlayer(CFrame.new(FINAL_SWORD_POINT))
            task.wait(SWORD_WAIT_WARP)
            
            equipBackpackTool("Bellona Sword")
            task.wait(1.0)
            collectNearbyPrompts(PROMPT_RADIUS, 5)
            addLog("⚔️ ส่งเควส Bellona Sword (กด 5 ครั้ง) สำเร็จ!", Color3.fromRGB(52, 211, 153))
            task.wait(5.0)
        end
        
        -- 3. วาร์ปจุดเสริม Extra Point (กด 1 ครั้ง)
        if isSwordRunning then
            SwordQuestBtn.Text = "⚔️ กำลังส่งเควสจุดเสริม..."
            LblSwordStatus.Text = "📍 วาร์ปไปจุดเสริม Extra Point"
            teleportPlayer(CFrame.new(EXTRA_SWORD_POINT))
            task.wait(SWORD_WAIT_WARP)
            collectNearbyPrompts(PROMPT_RADIUS, 1)
            addLog("⚔️ ส่งเควสจุดเสริม (กด 1 ครั้ง) สำเร็จ!", Color3.fromRGB(147, 197, 253))
            task.wait(SWORD_WAIT_COLLECT)
        end
        
        -- 4. วาร์ปจุด Helmet (สวม Royal Helmet + กด 3 ครั้ง)
        if isSwordRunning then
            SwordQuestBtn.Text = "⚔️ กำลังส่งเควส Royal Helmet..."
            LblSwordStatus.Text = "📍 วาร์ปไปจุด Helmet & สวม Royal Helmet"
            teleportPlayer(CFrame.new(HELMET_SWORD_POINT))
            task.wait(SWORD_WAIT_WARP)
            
            equipBackpackTool("Royal Helmet")
            task.wait(1.0)
            collectNearbyPrompts(PROMPT_RADIUS, 3)
            addLog("⚔️ ส่งเควส Royal Helmet (กด 3 ครั้ง) สำเร็จ!", Color3.fromRGB(52, 211, 153))
        end
        
        if isSwordRunning then
            addLog("🎉 ส่งเควสดาบโอลิมปัสเสร็จสิ้นสมบูรณ์!", Color3.fromRGB(52, 211, 153))
            notify("Olympus", "🎉 ส่งเควสดาบเสร็จสมบูรณ์!", 5)
            LblSwordStatus.Text = "✅ ส่งเควสดาบเสร็จสิ้นสมบูรณ์!"
            LblSwordStatus.TextColor3 = Color3.fromRGB(52, 211, 153)
        else
            LblSwordStatus.Text = "⏹ ยกเลิกเควสดาบแล้ว"
            LblSwordStatus.TextColor3 = Color3.fromRGB(248, 113, 113)
        end
        
        isSwordRunning = false
        SwordQuestBtn.BackgroundColor3 = Color3.fromRGB(138, 92, 246)
        SwordQuestBtn.Text = "⚔️ [เริ่ม] ออโต้ส่งเควสดาบ (Auto Sword Quest)"
    end)
end

-- ผูกปุ่มเควสโอลิมปัส
MirrorQuestBtn.MouseButton1Click:Connect(runMirror)
SwordQuestBtn.MouseButton1Click:Connect(runSwordQuest)

StopOlympusQuestBtn.MouseButton1Click:Connect(function()
    if isMirrorRunning or isSwordRunning then
        isMirrorRunning = false
        isSwordRunning = false
        addLog("⏹ สั่งยกเลิกเควสโอลิมปัสทั้งหมดเรียบร้อย", Color3.fromRGB(248, 113, 113))
        notify("Olympus", "สั่งหยุดเควสเรียบร้อย", 3)
    else
        addLog("ℹ️ ไม่มีการทำงานเควสใดที่เปิดอยู่", Color3.fromRGB(156, 163, 175))
    end
end)

-- ===================================================================
-- 🏃 AUTO MOVEMENT (วิ่งเร็ว 50 & กระโดดสูง 100 แบบล็อกนิ่ง ไม่กระตุก ไม่ช้าสลับเร็ว)
-- ===================================================================
local function startAutoMovement()
    local RunService = game:GetService("RunService")
    local TARGET_SPEED = 50
    local TARGET_JUMP = 100

    local currentConnWS, currentConnJP, currentConnSim

    local function setupCharacter(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end

        if currentConnWS then pcall(function() currentConnWS:Disconnect() end) end
        if currentConnJP then pcall(function() currentConnJP:Disconnect() end) end
        if currentConnSim then pcall(function() currentConnSim:Disconnect() end) end

        -- 1. เชื่อมต่อระบบคำนวณความเร็วของตัวเกม Fisch (WalkSpeedController)
        -- ทำให้ระบบเกมคำนวณความเร็วปกติออกมาเป็น 50 และกระโดด 100 ทันที โดยไม่รีเซ็ตกลับเป็น 16/50
        char:SetAttribute("SpeedCoil", TARGET_SPEED - 16)
        char:SetAttribute("FreezingWaterJump", TARGET_JUMP - 50)

        local function enforce()
            pcall(function()
                if hum.WalkSpeed ~= TARGET_SPEED then
                    hum.WalkSpeed = TARGET_SPEED
                end
                if hum.UseJumpPower then
                    if hum.JumpPower ~= TARGET_JUMP then
                        hum.JumpPower = TARGET_JUMP
                    end
                else
                    if hum.JumpHeight ~= TARGET_JUMP then
                        hum.JumpHeight = TARGET_JUMP
                    end
                end
            end)
        end

        enforce()

        -- 2. ไม่ใช้ GetPropertyChangedSignal เพื่อป้องกัน exponential deferred event growth
        -- ให้ PreSimulation ด้านล่างคอยล็อกค่าทุกเฟรมแทนอย่างปลอดภัย

        -- 3. ล็อกค่าต่อเนื่องทุก Frame ก่อน Physics ทำงาน (PreSimulation)
        currentConnSim = RunService.PreSimulation:Connect(function()
            if not hum.Parent or not char.Parent then
                if currentConnSim then currentConnSim:Disconnect() end
                return
            end
            if hum.WalkSpeed ~= TARGET_SPEED then
                hum.WalkSpeed = TARGET_SPEED
            end
            if hum.UseJumpPower then
                if hum.JumpPower ~= TARGET_JUMP then
                    hum.JumpPower = TARGET_JUMP
                end
            else
                if hum.JumpHeight ~= TARGET_JUMP then
                    hum.JumpHeight = TARGET_JUMP
                end
            end
        end)
        table.insert(hubConnections, currentConnSim)
    end

    if LocalPlayer.Character then
        task.spawn(function() setupCharacter(LocalPlayer.Character) end)
    end

    table.insert(hubConnections, LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        setupCharacter(char)
    end))

    addLog("🏃‍♂️ ล็อกความเร็ววิ่ง 50 และกระโดดสูง 100 ถาวร (แก้ปัญหาวิ่งช้าสลับเร็วเรียบร้อย)", Color3.fromRGB(52, 211, 153))
end
-- ===================================================================
local function startAutoFishRadar()
    local CollectionService = game:GetService("CollectionService")
    
    local function ToTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = os.date("%M", seconds)
        local s = os.date("%S", seconds)
        return (tonumber(h) or 0) >= 1 and string.format("%d:%s:%s", h, m, s) or string.format("%s:%s", m, s)
    end

    local function applyRadar(v)
        pcall(function()
            if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
                local name = v.Name:lower()
                if string.find(name, "radar") or CollectionService:HasTag(v, "radarTag") or CollectionService:HasTag(v, "radarTagWithTimer") then
                    if v:FindFirstChild("abundanceName") and v.abundanceName.Text == "Ancient Depth Serpent" then
                        v.Enabled = false
                    else
                        v.Enabled = true
                    end
                end
            end
        end)
    end

    -- กำหนด Attribute RadarEnabled ให้ตัวละคร
    pcall(function()
        LocalPlayer:SetAttribute("RadarEnabled", true)
    end)

    -- เปิดการแสดงผลเรดาร์ที่มีอยู่ในเซิร์ฟเวอร์ทันที
    pcall(function()
        for _, v in pairs(CollectionService:GetTagged("radarTag")) do
            applyRadar(v)
        end
        for _, v in pairs(CollectionService:GetTagged("radarTagWithTimer")) do
            applyRadar(v)
        end
    end)

    -- เปิดเรดาร์ในทุกโซนตกปลา (workspace.zones.fishing)
    pcall(function()
        local zones = workspace:FindFirstChild("zones")
        local fishing = zones and zones:FindFirstChild("fishing")
        if fishing then
            for _, p in ipairs(fishing:GetChildren()) do
                for _, g in ipairs(p:GetChildren()) do
                    if g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
                        applyRadar(g)
                    end
                end
            end
        end
    end)

    -- ดักจับเมื่อมี Tag เรดาร์ใหม่ถูกเพิ่มเข้ามา
    pcall(function()
        CollectionService:GetInstanceAddedSignal("radarTag"):Connect(function(v)
            applyRadar(v)
        end)
        CollectionService:GetInstanceAddedSignal("radarTagWithTimer"):Connect(function(v)
            applyRadar(v)
        end)
    end)

    -- ลูปอัปเดตตัวจับเวลาสำหรับโซนแบบมีเวลา และคงสถานะเปิดเรดาร์ต่อเนื่อง
    task.spawn(function()
        while true do
            pcall(function()
                LocalPlayer:SetAttribute("RadarEnabled", true)
                local serverTime = workspace:GetServerTimeNow()

                for _, v in pairs(CollectionService:GetTagged("radarTagWithTimer")) do
                    if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
                        v.Enabled = true
                        local parent = v.Parent
                        if parent and v:FindFirstChild("abundanceName") then
                            local textAttr = parent:GetAttribute("Text")
                            local endClock = parent:GetAttribute("EndClock")
                            if textAttr and endClock then
                                local remaining = math.max(0, endClock - serverTime)
                                if remaining <= 0 then
                                    v.abundanceName.Text = "Disappearing Soon"
                                else
                                    v.abundanceName.Text = string.format(textAttr, ToTime(remaining))
                                end
                            end
                        end
                    end
                end

                for _, v in pairs(CollectionService:GetTagged("radarTag")) do
                    if (v:IsA("BillboardGui") or v:IsA("SurfaceGui")) and not v.Enabled then
                        if not (v:FindFirstChild("abundanceName") and v.abundanceName.Text == "Ancient Depth Serpent") then
                            v.Enabled = true
                        end
                    end
                end
            end)
            task.wait(2)
        end
    end)

    addLog("🐟 เปิดใช้งานเรดาร์มองปลา (Fish Radar) อัตโนมัติเรียบร้อย", Color3.fromRGB(56, 189, 248))
end

-- ===================================================================
-- 🔄 BACKGROUND MONITOR (ตรวจแสดงผล UI อย่างเดียว ไม่ซื้อ/ไม่วาร์ปเอง)
-- ===================================================================
task.spawn(function()
    selectTab("Fishing")
    updatePearlUI()
    checkMerlinBuffs()
    startAutoFishRadar()
    startAutoMovement()
    addLog("🔒 Pond Hub โหลดสำเร็จ! (🎣 ตกปลา [Q/F] | 🔮 รีไข่มุก | 🏃‍♂️ วิ่ง 50/โดด 100)", Color3.fromRGB(167, 139, 250))
    notify("Pond Hub", "โหลดสำเร็จ! กด [ Z ] เปิด/ปิด UI | [ Q ] สลับตกปลา | [ F ] สลับล็อกตำแหน่ง", 4)
    
    while true do
        task.wait(10)
        local buffs = checkMerlinBuffs()
        if autoRenewMerlin and not isBuyingMerlin then
            local isOtherBusy = isPearlRunning or isMirrorRunning or isSwordRunning or isAuroraRunning
            if not isOtherBusy or hasMerlinSession then
                local needLucky = not buffs.Lucky.active or buffs.Lucky.remaining <= 120
                local needInsight = not buffs.Insight.active or buffs.Insight.remaining <= 120
                local needLure = not buffs.Lure.active or buffs.Lure.remaining <= 120
                if needLucky or needInsight or needLure then
                    executeMerlinBuffs(needLucky, needLure, needInsight, false)
                end
            end
        end
    end
end)
