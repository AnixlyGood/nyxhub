-- ================================================================
-- LOAD FOXY UI
-- ================================================================
local Foxy = loadstring(game:HttpGet("https://raw.githubusercontent.com/AnixlyGood/Asut/main/FoxyUI/main.lua", true))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIS = UserInputService

-- ================================================================
-- CONFIG
-- ================================================================
local STUDS_OFFSET = 3
local PLOT_ATTRIBUTE = "NestsOwnerLoaded"
local ESP_MAX_DISTANCE = 9999

_G.FarmSpeed = 200
_G.TweenTP_Speed = 200
_G.FarmTarget = "Legendary"
_G.AutoFarmEgg_V1_Running = false
_G.AutoFarmEgg_V2_Running = false

-- State tween toggle
_G.TweenBase_Running = false
_G.TweenPlayerBase_Running = false
_G.TweenStall_Running = false
_G.TweenEgg_Running = false

-- Thread references
local tweenBaseThread = nil
local tweenPlayerBaseThread = nil
local tweenStallThread = nil
local tweenEggThread = nil

-- Remotes
local EggTrackerRemote = nil
local StockShopRemote = nil
pcall(function()
    EggTrackerRemote = ReplicatedStorage:WaitForChild("Remotes", 10)
        and ReplicatedStorage.Remotes:WaitForChild("Game", 10)
        and ReplicatedStorage.Remotes.Game:WaitForChild("OpenEggTracker", 10)
    StockShopRemote = ReplicatedStorage.Remotes.Game:WaitForChild("OpenStockShop", 10)
end)

-- ================================================================
-- EGG DATA
-- ================================================================
local EGG_DATA = {
    ["White Egg"]      = { Tier = "Common",    Luck = "1",      LuckValue = 1,      Color = Color3.fromRGB(220, 220, 220) },
    ["Brown Egg"]      = { Tier = "Common",    Luck = "5",      LuckValue = 5,      Color = Color3.fromRGB(150, 90, 40) },
    ["Cracked Egg"]    = { Tier = "Rare",      Luck = "30",     LuckValue = 30,     Color = Color3.fromRGB(200, 180, 150) },
    ["Easter Egg"]     = { Tier = "Rare",      Luck = "50",     LuckValue = 50,     Color = Color3.fromRGB(255, 180, 220) },
    ["Stone Egg"]      = { Tier = "Rare",      Luck = "100",    LuckValue = 100,    Color = Color3.fromRGB(140, 140, 140) },
    ["Leaf Egg"]       = { Tier = "Rare",      Luck = "200",    LuckValue = 200,    Color = Color3.fromRGB(120, 200, 80) },
    ["Mushroom Egg"]   = { Tier = "Epic",      Luck = "500",    LuckValue = 500,    Color = Color3.fromRGB(200, 80, 80) },
    ["Flower Egg"]     = { Tier = "Epic",      Luck = "750",    LuckValue = 750,    Color = Color3.fromRGB(255, 150, 200) },
    ["Slime Egg"]      = { Tier = "Epic",      Luck = "1.000",  LuckValue = 1000,   Color = Color3.fromRGB(80, 220, 100) },
    ["Ice Egg"]        = { Tier = "Epic",      Luck = "3.000",  LuckValue = 3000,   Color = Color3.fromRGB(120, 220, 255) },
    ["Glass Egg"]      = { Tier = "Legendary", Luck = "10.000", LuckValue = 10000,  Color = Color3.fromRGB(180, 240, 255) },
    ["Golden Egg"]     = { Tier = "Legendary", Luck = "30.000", LuckValue = 30000,  Color = Color3.fromRGB(255, 215, 0) },
    ["Crystal Egg"]    = { Tier = "Mythic",    Luck = "150K",   LuckValue = 150000, Color = Color3.fromRGB(180, 220, 255) },
    ["Skull Egg"]      = { Tier = "Mythic",    Luck = "250K",   LuckValue = 250000, Color = Color3.fromRGB(200, 200, 200) },
    ["Asteroid Egg"]   = { Tier = "Mythic",    Luck = "500K",   LuckValue = 500000, Color = Color3.fromRGB(160, 130, 100) },
    ["Dominus Egg"]    = { Tier = "Mythic",    Luck = "700K",   LuckValue = 700000, Color = Color3.fromRGB(80, 40, 120) },
    ["Flaming Egg"]    = { Tier = "Mythic",    Luck = "1M",     LuckValue = 1e6,    Color = Color3.fromRGB(255, 100, 30) },
    ["Sinister Egg"]   = { Tier = "Mythic",    Luck = "3M",     LuckValue = 3e6,    Color = Color3.fromRGB(150, 0, 0) },
    ["Soul Egg"]       = { Tier = "Mythic",    Luck = "7M",     LuckValue = 7e6,    Color = Color3.fromRGB(120, 200, 255) },
    ["Tidal Egg"]      = { Tier = "Mythic",    Luck = "8M",     LuckValue = 8e6,    Color = Color3.fromRGB(255, 130, 200) },
    ["Aurora Egg"]     = { Tier = "Divine",    Luck = "300M",   LuckValue = 3e8,    Color = Color3.fromRGB(100, 255, 200) },
    ["Galaxy Egg"]     = { Tier = "Divine",    Luck = "1.5B",   LuckValue = 1.5e9,  Color = Color3.fromRGB(120, 80, 255) },
    ["Bloom Egg"]      = { Tier = "Divine",    Luck = "2B",     LuckValue = 2e9,    Color = Color3.fromRGB(60, 160, 255) },
    ["Blackhole Egg"]  = { Tier = "Ethereal",  Luck = "100B",   LuckValue = 1e11,   Color = Color3.fromRGB(40, 0, 60) },
    ["Solaris Egg"]    = { Tier = "Ethereal",  Luck = "300B",   LuckValue = 3e11,   Color = Color3.fromRGB(255, 180, 50) },
    ["Cherub Egg"]     = { Tier = "Ethereal",  Luck = "1T",     LuckValue = 1e12,   Color = Color3.fromRGB(255, 240, 180) },
    ["Volcanic Egg"]   = { Tier = "Ethereal",  Luck = "2.5T",   LuckValue = 2.5e12, Color = Color3.fromRGB(200, 60, 20) },
}

local DEFAULT_DATA = { Tier = "Unknown", Luck = "?", LuckValue = 0, Color = Color3.fromRGB(255, 255, 0) }

local TIER_LIST = {
    "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal"
}

local EGG_LIST = {
    "White Egg", "Brown Egg",
    "Cracked Egg", "Easter Egg", "Stone Egg", "Leaf Egg",
    "Mushroom Egg", "Flower Egg", "Slime Egg", "Ice Egg",
    "Glass Egg", "Golden Egg",
    "Crystal Egg", "Skull Egg", "Asteroid Egg", "Dominus Egg",
    "Flaming Egg", "Sinister Egg", "Soul Egg", "Tidal Egg",
    "Aurora Egg", "Galaxy Egg", "Bloom Egg",
    "Blackhole Egg", "Solaris Egg", "Cherub Egg", "Volcanic Egg",
}

local STALL_LIST = { "Gears", "EggTracker", "Food", "Sell" }

local TIER_COLOR = {
    Common    = Color3.fromRGB(200, 200, 200),
    Rare      = Color3.fromRGB(100, 180, 255),
    Epic      = Color3.fromRGB(80, 220, 100),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic    = Color3.fromRGB(200, 80, 255),
    Divine    = Color3.fromRGB(100, 255, 200),
    Ethereal  = Color3.fromRGB(255, 100, 200),
    Unknown   = Color3.fromRGB(255, 255, 0),
}

local function GetEggData(name)
    if not name then return DEFAULT_DATA end
    if EGG_DATA[name] then return EGG_DATA[name] end
    local lowerName = string.lower(name)
    for key, data in pairs(EGG_DATA) do
        if string.lower(key) == lowerName then return data end
    end
    for key, data in pairs(EGG_DATA) do
        if string.find(lowerName, string.lower(key), 1, true) then return data end
    end
    return DEFAULT_DATA
end

-- ================================================================
-- WINDOW
-- ================================================================
local Window = Foxy:CreateWindow({
    Name = "NyxHub V1.00",
    Subtitle = "Made By CrayxGremory",
    LogoID = "115873462157507",
    LoadingEnabled = true,
    LoadingTitle = "NyxHub",
    LoadingSubtitle = "by CrayxGremory",
    KeySystem = false,

    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "NyxHub"
    },
})

Foxy:Notification({
    Title = "NyxHub Loaded",
    Icon = "sparkle",
    ImageSource = "Material",
    Content = "Egg ESP + TP + Utility + AutoFarm + Fly ready!"
})

-- ================================================================
-- ANTI-KICK BYPASS
-- ================================================================
local oldKick
oldKick = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "kick" or method == "Kick" then
        warn("[BYPASS] Kick blocked!")
        return nil
    end
    return oldKick(self, ...)
end)

-- ================================================================
-- GLOBAL
-- ================================================================
_G.EggESP_Enabled = false
_G.InfJump_Enabled = false
_G.WalkSpeed_Value = 16
_G.WalkSpeed_Enabled = false
_G.Noclip_Enabled = false
_G.AntiStaff_Enabled = false

local RenderedEggs = workspace:WaitForChild("RenderedEggs", 15)
local Plots = workspace:WaitForChild("Plots", 15)
local ESP_FOLDER_NAME = "EggESP_Light"
local espFolder = nil
local espEnabled = false
local refreshLoopRunning = false
local eggTrackers = {}
local espConnections = {}

-- ================================================================
-- UTIL
-- ================================================================
local function cleanupESP()
    if espFolder then
        espFolder:Destroy()
        espFolder = nil
    end
    for _, c in ipairs(espConnections) do
        if c.Disconnect then c:Disconnect() end
    end
    espConnections = {}
    eggTrackers = {}
    espEnabled = false
end

local function getTargetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function getObjectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot().Position end)
        if ok and pivot then return pivot end
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
    end
    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

-- ================================================================
-- PLAYER LIST
-- ================================================================
local function getPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr.Name)
        end
    end
    table.sort(list)
    return list
end

-- ================================================================
-- ESP
-- ================================================================
local function addEggToESP(egg)
    if not egg or eggTrackers[egg] then return end
    local part = getTargetPart(egg)
    if not part then return end

    local data = GetEggData(egg.Name)
    local tierColor = TIER_COLOR[data.Tier] or TIER_COLOR.Unknown

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_HL"
    highlight.Adornee = egg
    highlight.FillColor = data.Color
    highlight.OutlineColor = tierColor
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_BB"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 160, 0, 44)
    billboard.StudsOffset = Vector3.new(0, STUDS_OFFSET, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = ESP_MAX_DISTANCE
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = egg.Name .. "\n" .. data.Tier .. " • " .. data.Luck
    label.TextColor3 = tierColor
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    eggTrackers[egg] = {
        highlight = highlight,
        billboard = billboard,
    }

    local conn
    conn = egg.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if eggTrackers[egg] then
                pcall(function() eggTrackers[egg].highlight:Destroy() end)
                pcall(function() eggTrackers[egg].billboard:Destroy() end)
                eggTrackers[egg] = nil
            end
            if conn then conn:Disconnect() end
        end
    end)
end

local function removeEggFromESP(egg)
    if eggTrackers[egg] then
        pcall(function() eggTrackers[egg].highlight:Destroy() end)
        pcall(function() eggTrackers[egg].billboard:Destroy() end)
        eggTrackers[egg] = nil
    end
end

local function syncEggs()
    if not RenderedEggs then return end
    local current = {}
    for _, egg in ipairs(RenderedEggs:GetChildren()) do
        current[egg] = true
    end
    for egg, _ in pairs(current) do
        if not eggTrackers[egg] then
            addEggToESP(egg)
        end
    end
    for egg, _ in pairs(eggTrackers) do
        if not current[egg] then
            removeEggFromESP(egg)
        end
    end
end

local function startESP()
    if espEnabled then return end
    if not RenderedEggs then return end

    local old = workspace:FindFirstChild(ESP_FOLDER_NAME)
    if old then old:Destroy() end

    espFolder = Instance.new("Folder")
    espFolder.Name = ESP_FOLDER_NAME
    espFolder.Parent = workspace

    espEnabled = true
    syncEggs()

    table.insert(espConnections, RenderedEggs.ChildAdded:Connect(function()
        task.wait(0.15)
        if espEnabled then syncEggs() end
    end))
    table.insert(espConnections, RenderedEggs.ChildRemoved:Connect(function()
        task.wait(0.15)
        if espEnabled then syncEggs() end
    end))

    if not refreshLoopRunning then
        refreshLoopRunning = true
        task.spawn(function()
            while espEnabled do
                task.wait(5)
                syncEggs()
            end
            refreshLoopRunning = false
        end)
    end
end

-- ================================================================
-- EGG TRACKER & STOCK SHOP OPENER
-- ================================================================
local function OpenEggTracker()
    if not EggTrackerRemote then
        Foxy:Notification({
            Title = "ERROR",
            Content = "OpenEggTracker remote tidak ditemukan",
            Icon = "error",
            ImageSource = "Material",
        })
        return
    end

    local ok = pcall(function()
        firesignal(EggTrackerRemote.OnClientEvent)
    end)

    if ok then
        Foxy:Notification({
            Title = "EGG TRACKER",
            Content = "Opened!",
            Icon = "check_circle",
            ImageSource = "Material",
        })
    else
        Foxy:Notification({
            Title = "ERROR",
            Content = "Gagal buka Egg Tracker (firesignal gagal)",
            Icon = "error",
            ImageSource = "Material",
        })
    end
end

local function OpenStockShop(category)
    if not StockShopRemote then
        Foxy:Notification({
            Title = "ERROR",
            Content = "OpenStockShop remote tidak ditemukan",
            Icon = "error",
            ImageSource = "Material",
        })
        return
    end

    local ok = pcall(function()
        firesignal(StockShopRemote.OnClientEvent, category)
    end)

    if ok then
        Foxy:Notification({
            Title = "STOCK SHOP",
            Content = "Opened: " .. tostring(category),
            Icon = "check_circle",
            ImageSource = "Material",
        })
    else
        Foxy:Notification({
            Title = "ERROR",
            Content = "Gagal buka Stock Shop (" .. tostring(category) .. ")",
            Icon = "error",
            ImageSource = "Material",
        })
    end
end

-- ================================================================
-- TELEPORT EGG (by Name)
-- ================================================================
local function findEggByName(nameQuery)
    if not nameQuery or nameQuery == "" then return nil end
    local query = string.lower(nameQuery)
    local children = RenderedEggs:GetChildren()
    for _, obj in ipairs(children) do
        if string.lower(obj.Name) == query then return obj end
    end
    for _, obj in ipairs(children) do
        if string.find(string.lower(obj.Name), query, 1, true) then return obj end
    end
    return nil
end

local function teleportToEgg(nameQuery)
    if not RenderedEggs then
        Foxy:Notification({Title = "ERROR", Content = "RenderedEggs tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end
    if not nameQuery or nameQuery == "" then
        Foxy:Notification({Title = "ERROR", Content = "Nama telur belum diisi", Icon = "error", ImageSource = "Material"})
        return
    end

    local target = findEggByName(nameQuery)
    if not target then
        Foxy:Notification({Title = "ERROR", Content = "Telur \"" .. nameQuery .. "\" tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    local pos = getObjectPosition(target)
    if not pos then
        Foxy:Notification({Title = "ERROR", Content = "Posisi tidak terdeteksi", Icon = "error", ImageSource = "Material"})
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Foxy:Notification({Title = "ERROR", Content = "Character belum spawn", Icon = "error", ImageSource = "Material"})
        return
    end

    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))

    local data = GetEggData(target.Name)
    Foxy:Notification({
        Title = "EGG TP",
        Content = "Ke \"" .. target.Name .. "\" [" .. data.Tier .. "]",
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

-- ================================================================
-- TELEPORT KE BASE
-- ================================================================
local function findMyPlot()
    if not Plots then return nil end
    local myUserId = LocalPlayer.UserId

    for _, plot in ipairs(Plots:GetChildren()) do
        local owner = plot:GetAttribute(PLOT_ATTRIBUTE)
        if owner and tonumber(owner) == myUserId then
            return plot
        end
        for _, attrName in ipairs({"NestsOwnerLoaded", "OwnerUserId", "Owner", "UserId", "OwnerId"}) do
            local v = plot:GetAttribute(attrName)
            if v and tonumber(v) == myUserId then
                return plot
            end
        end
    end
    return nil
end

local function getMyBasePosition()
    local plot = findMyPlot()
    if not plot then return nil end
    local baseplate = plot:FindFirstChild("Baseplate")
        or plot:FindFirstChild("BasePlate")
        or plot:FindFirstChild("Base")
    return getObjectPosition(baseplate or plot)
end

local function teleportToMyPlot()
    if not Plots then
        Foxy:Notification({Title = "ERROR", Content = "Plots tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    local basePos = getMyBasePosition()
    if not basePos then
        Foxy:Notification({Title = "ERROR", Content = "Base kamu tidak terdeteksi", Icon = "error", ImageSource = "Material"})
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Foxy:Notification({Title = "ERROR", Content = "Character belum spawn", Icon = "error", ImageSource = "Material"})
        return
    end

    hrp.CFrame = CFrame.new(basePos + Vector3.new(0, 8, 0))

    Foxy:Notification({
        Title = "BASE TP",
        Content = "Ke Base kamu",
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

-- ================================================================
-- TWEEN TELEPORT (Smooth) — Flag check loop
-- ================================================================
local function tweenToPosition(targetPos, speed, runningFlag)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if runningFlag and not _G[runningFlag] then return false end

    speed = speed or _G.TweenTP_Speed or 200
    local distance = (targetPos - hrp.Position).Magnitude
    if distance < 1 then return true end
    local duration = math.max(distance / speed, 0.1)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(targetPos) }
    )
    tween:Play()

    local completed = false
    local conn = tween.Completed:Connect(function() completed = true end)

    local startTime = tick()
    while not completed do
        if runningFlag and not _G[runningFlag] then
            pcall(function() tween:Cancel() end)
            break
        end

        if tick() - startTime > duration + 1 then break end
        task.wait(0.05)
    end

    if conn then conn:Disconnect() end
    return completed
end

local function tweenToEgg(nameQuery)
    if not RenderedEggs then
        Foxy:Notification({Title = "ERROR", Content = "RenderedEggs tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end
    if not nameQuery or nameQuery == "" then
        Foxy:Notification({Title = "ERROR", Content = "Nama telur belum diisi", Icon = "error", ImageSource = "Material"})
        return
    end

    local target = findEggByName(nameQuery)
    if not target then
        Foxy:Notification({Title = "ERROR", Content = "Telur \"" .. nameQuery .. "\" tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    local pos = getObjectPosition(target)
    if not pos then
        Foxy:Notification({Title = "ERROR", Content = "Posisi tidak terdeteksi", Icon = "error", ImageSource = "Material"})
        return
    end

    tweenToPosition(pos + Vector3.new(0, 3, 0), _G.TweenTP_Speed)

    local data = GetEggData(target.Name)
    Foxy:Notification({
        Title = "TWEEN TP",
        Content = "Ke \"" .. target.Name .. "\" [" .. data.Tier .. "]",
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

local function tweenToBase()
    if not Plots then
        Foxy:Notification({Title = "ERROR", Content = "Plots tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    local basePos = getMyBasePosition()
    if not basePos then
        Foxy:Notification({Title = "ERROR", Content = "Base kamu tidak terdeteksi", Icon = "error", ImageSource = "Material"})
        return
    end

    tweenToPosition(basePos + Vector3.new(0, 8, 0), _G.TweenTP_Speed)

    Foxy:Notification({
        Title = "TWEEN BASE",
        Content = "Ke Base kamu",
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

-- ================================================================
-- TELEPORT KE STALLS
-- ================================================================
local function getStallPosition(stallName)
    local Stalls = workspace:FindFirstChild("Stalls")
    if not Stalls then return nil end
    local stall = Stalls:FindFirstChild(stallName)
    if not stall then return nil end
    return getObjectPosition(stall)
end

local function teleportToStall(stallName)
    local pos = getStallPosition(stallName)
    if not pos then
        Foxy:Notification({Title = "ERROR", Content = "Stall \"" .. tostring(stallName) .. "\" tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Foxy:Notification({Title = "ERROR", Content = "Character belum spawn", Icon = "error", ImageSource = "Material"})
        return
    end

    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))

    Foxy:Notification({
        Title = "STALL TP",
        Content = "Ke " .. stallName,
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

local function tweenToStall(stallName)
    local pos = getStallPosition(stallName)
    if not pos then
        Foxy:Notification({Title = "ERROR", Content = "Stall \"" .. tostring(stallName) .. "\" tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    tweenToPosition(pos + Vector3.new(0, 5, 0), _G.TweenTP_Speed)

    Foxy:Notification({
        Title = "STALL TWEEN",
        Content = "Ke " .. stallName,
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

-- ================================================================
-- TELEPORT KE BASE ORANG LAIN
-- ================================================================
local function findPlotByUsername(username)
    if not Plots then return nil end
    if not username or username == "" then return nil end

    local query = string.lower(username)

    local targetPlayer = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == query or string.lower(plr.DisplayName) == query then
            targetPlayer = plr
            break
        end
    end
    if not targetPlayer then
        for _, plr in ipairs(Players:GetPlayers()) do
            if string.find(string.lower(plr.Name), query, 1, true)
               or string.find(string.lower(plr.DisplayName), query, 1, true) then
                targetPlayer = plr
                break
            end
        end
    end

    if not targetPlayer then return nil, nil end

    local targetUserId = targetPlayer.UserId
    for _, plot in ipairs(Plots:GetChildren()) do
        for _, attrName in ipairs({"NestsOwnerLoaded", "OwnerUserId", "Owner", "UserId", "OwnerId"}) do
            local v = plot:GetAttribute(attrName)
            if v and tonumber(v) == targetUserId then
                return plot, targetPlayer
            end
        end
    end

    return nil, targetPlayer
end

local function getPlotBasePosition(plot)
    if not plot then return nil end
    local baseplate = plot:FindFirstChild("Baseplate")
        or plot:FindFirstChild("BasePlate")
        or plot:FindFirstChild("Base")
    return getObjectPosition(baseplate or plot)
end

local function teleportToPlayerBase(username)
    if not Plots then
        Foxy:Notification({Title = "ERROR", Content = "Plots tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    local plot, plr = findPlotByUsername(username)

    if not plr then
        Foxy:Notification({Title = "ERROR", Content = "Player \"" .. tostring(username) .. "\" tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    if not plot then
        Foxy:Notification({Title = "ERROR", Content = plr.Name .. " tidak punya plot / belum spawn", Icon = "error", ImageSource = "Material"})
        return
    end

    local basePos = getPlotBasePosition(plot)
    if not basePos then
        Foxy:Notification({Title = "ERROR", Content = "Base " .. plr.Name .. " tidak terdeteksi", Icon = "error", ImageSource = "Material"})
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Foxy:Notification({Title = "ERROR", Content = "Character belum spawn", Icon = "error", ImageSource = "Material"})
        return
    end

    hrp.CFrame = CFrame.new(basePos + Vector3.new(0, 8, 0))

    Foxy:Notification({
        Title = "BASE TP",
        Content = "Ke base " .. plr.Name,
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

local function tweenToPlayerBase(username)
    if not Plots then
        Foxy:Notification({Title = "ERROR", Content = "Plots tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    local plot, plr = findPlotByUsername(username)

    if not plr then
        Foxy:Notification({Title = "ERROR", Content = "Player \"" .. tostring(username) .. "\" tidak ditemukan", Icon = "error", ImageSource = "Material"})
        return
    end

    if not plot then
        Foxy:Notification({Title = "ERROR", Content = plr.Name .. " tidak punya plot / belum spawn", Icon = "error", ImageSource = "Material"})
        return
    end

    local basePos = getPlotBasePosition(plot)
    if not basePos then
        Foxy:Notification({Title = "ERROR", Content = "Base " .. plr.Name .. " tidak terdeteksi", Icon = "error", ImageSource = "Material"})
        return
    end

    tweenToPosition(basePos + Vector3.new(0, 8, 0), _G.TweenTP_Speed)

    Foxy:Notification({
        Title = "TWEEN BASE",
        Content = "Ke base " .. plr.Name,
        Icon = "check_circle",
        ImageSource = "Material",
    })
end

-- ================================================================
-- UTILITY: INFINITY JUMP
-- ================================================================
local infJumpConnection = nil

local function startInfJump()
    if infJumpConnection then return end
    infJumpConnection = UserInputService.JumpRequest:Connect(function()
        if _G.InfJump_Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

local function stopInfJump()
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
end

-- ================================================================
-- UTILITY: WALKSPEED
-- ================================================================
local function applyWalkSpeed(speed)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = speed
    end
end

-- ================================================================
-- UTILITY: NOCLIP
-- ================================================================
local noclipConnection = nil

local function startNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if _G.Noclip_Enabled then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if _G.WalkSpeed_Enabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = _G.WalkSpeed_Value end
    end
end)

-- ================================================================
-- UTILITY: FLY
-- ================================================================
local flyActive = false
local flySpeed = 50
local flyGyro = nil
local flyVelocity = nil
local renderConnection = nil
local inputBeganConnection = nil
local inputEndedConnection = nil
local diedConnection = nil

local flyKeys = {
    W = false, A = false, S = false, D = false,
    Up = false, Down = false
}

local function ResetFlyKeys()
    for key in pairs(flyKeys) do
        flyKeys[key] = false
    end
end

local function DisconnectFlyConnections()
    if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
    if inputBeganConnection then inputBeganConnection:Disconnect(); inputBeganConnection = nil end
    if inputEndedConnection then inputEndedConnection:Disconnect(); inputEndedConnection = nil end
    if diedConnection then diedConnection:Disconnect(); diedConnection = nil end
end

local function StopFly(silent)
    flyActive = false
    DisconnectFlyConnections()
    ResetFlyKeys()

    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end

    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if not silent then
        Foxy:Notification({Title = "FLY", Content = "Disabled", Icon = "cancel", ImageSource = "Material"})
    end
end

local function StartFly()
    if flyActive then return end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root then
        Foxy:Notification({Title = "FLY", Content = "Character belum siap!", Icon = "error", ImageSource = "Material"})
        return
    end

    DisconnectFlyConnections()
    ResetFlyKeys()

    flyActive = true
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false

    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "NyxFlyGyro"
    flyGyro.P = 90000
    flyGyro.D = 1000
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.CFrame = root.CFrame
    flyGyro.Parent = root

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "NyxFlyVelocity"
    flyVelocity.P = 1500
    flyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root

    inputBeganConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not flyActive then return end
        local key = input.KeyCode
        if key == Enum.KeyCode.W then flyKeys.W = true
        elseif key == Enum.KeyCode.A then flyKeys.A = true
        elseif key == Enum.KeyCode.S then flyKeys.S = true
        elseif key == Enum.KeyCode.D then flyKeys.D = true
        elseif key == Enum.KeyCode.Space or key == Enum.KeyCode.E then flyKeys.Up = true
        elseif key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl
            or key == Enum.KeyCode.C or key == Enum.KeyCode.Q then flyKeys.Down = true
        end
    end)

    inputEndedConnection = UIS.InputEnded:Connect(function(input)
        local key = input.KeyCode
        if key == Enum.KeyCode.W then flyKeys.W = false
        elseif key == Enum.KeyCode.A then flyKeys.A = false
        elseif key == Enum.KeyCode.S then flyKeys.S = false
        elseif key == Enum.KeyCode.D then flyKeys.D = false
        elseif key == Enum.KeyCode.Space or key == Enum.KeyCode.E then flyKeys.Up = false
        elseif key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl
            or key == Enum.KeyCode.C or key == Enum.KeyCode.Q then flyKeys.Down = false
        end
    end)

    diedConnection = humanoid.Died:Connect(function()
        StopFly(true)
    end)

    renderConnection = RunService.RenderStepped:Connect(function()
        if not flyActive then return end
        if not character.Parent or humanoid.Health <= 0 then
            StopFly(true)
            return
        end

        local camera = workspace.CurrentCamera
        if not camera or not flyGyro or not flyVelocity then return end

        local cameraForward = camera.CFrame.LookVector
        local cameraRight = camera.CFrame.RightVector

        local moveVector = Vector3.zero
        local keyboardMoving = flyKeys.W or flyKeys.A or flyKeys.S or flyKeys.D

        if flyKeys.W then moveVector += cameraForward end
        if flyKeys.S then moveVector -= cameraForward end
        if flyKeys.A then moveVector -= cameraRight end
        if flyKeys.D then moveVector += cameraRight end

        if not keyboardMoving then
            local moveDirection = humanoid.MoveDirection
            if moveDirection.Magnitude > 0.05 then
                local flatForward = Vector3.new(cameraForward.X, 0, cameraForward.Z)
                local flatRight = Vector3.new(cameraRight.X, 0, cameraRight.Z)

                if flatForward.Magnitude > 0.001 then flatForward = flatForward.Unit
                else flatForward = Vector3.new(0, 0, -1) end
                if flatRight.Magnitude > 0.001 then flatRight = flatRight.Unit
                else flatRight = Vector3.new(1, 0, 0) end

                local forwardAmount = moveDirection:Dot(flatForward)
                local rightAmount = moveDirection:Dot(flatRight)

                moveVector += cameraForward * forwardAmount
                moveVector += cameraRight * rightAmount
            end
        end

        if flyKeys.Up then moveVector += Vector3.new(0, 1, 0) end
        if flyKeys.Down then moveVector -= Vector3.new(0, 1, 0) end

        if moveVector.Magnitude > 0.05 then
            flyVelocity.Velocity = moveVector.Unit * flySpeed
        else
            flyVelocity.Velocity = Vector3.zero
        end

        flyGyro.CFrame = CFrame.lookAt(
            root.Position,
            root.Position + cameraForward,
            camera.CFrame.UpVector
        )
    end)

    Foxy:Notification({Title = "FLY", Content = "Enabled", Icon = "check_circle", ImageSource = "Material"})
end

LocalPlayer.CharacterAdded:Connect(function()
    if flyActive then
        StopFly(true)
    end
end)

-- ================================================================
-- UTILITY: ANTI-STAFF
-- ================================================================
local staffKeywords = {
    "admin", "mod", "moderator", "owner", "creator", "dev", "developer",
    "staff", "manager", "super", "helper", "head", "coordinator"
}

local antiStaffEnabled = false
local antiStaffConnection = nil

local function CheckForStaff()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local nameLower = plr.Name:lower()
            local displayLower = plr.DisplayName:lower()
            for _, keyword in ipairs(staffKeywords) do
                if nameLower:find(keyword) or displayLower:find(keyword) then
                    return true, plr.Name, keyword
                end
            end
        end
    end
    return false, nil, nil
end

local function GetAvailableServers()
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then return {} end

    local servers = {}
    for _, v in pairs(result.data) do
        if v.id ~= game.JobId and v.playing and v.maxPlayers
            and v.playing < v.maxPlayers then
            table.insert(servers, {
                id = v.id,
                playing = v.playing,
                maxPlayers = v.maxPlayers,
            })
        end
    end

    table.sort(servers, function(a, b)
        return a.playing < b.playing
    end)

    return servers
end

local function HopServer(reasonName, reasonKeyword)
    Foxy:Notification({
        Title = "⚠️ STAFF DETECTED",
        Content = (reasonName or "?") .. " [" .. (reasonKeyword or "?") .. "] - Hopping...",
        Icon = "warning",
        ImageSource = "Material",
    })

    task.wait(2)

    local servers = GetAvailableServers()

    if #servers == 0 then
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        return
    end

    local maxTry = math.min(8, #servers)
    for i = 1, maxTry do
        local server = servers[i]
        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
        end)
        if ok then
            print("[AntiStaff] Hopping ke server:", server.id, "(" .. server.playing .. "/" .. server.maxPlayers .. ")")
            return
        end
        task.wait(0.3)
    end

    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

local function StartAntiStaff()
    if antiStaffConnection then return end
    antiStaffConnection = RunService.Heartbeat:Connect(function()
        if not antiStaffEnabled then return end
        local found, name, keyword = CheckForStaff()
        if found then
            antiStaffEnabled = false
            _G.AntiStaff_Enabled = false
            HopServer(name, keyword)
        end
    end)
end

local function StopAntiStaff()
    if antiStaffConnection then
        antiStaffConnection:Disconnect()
        antiStaffConnection = nil
    end
end

-- ================================================================
-- AUTO FARM EGG — SEARCH BY TIER
-- ================================================================
local function findTargetEgg()
    if not _G.FarmTarget or _G.FarmTarget == "" then return nil end
    if not RenderedEggs then return nil end

    local targetTier = string.lower(_G.FarmTarget)

    for _, egg in ipairs(RenderedEggs:GetChildren()) do
        local data = GetEggData(egg.Name)
        if string.lower(data.Tier) == targetTier then
            return egg, data.LuckValue
        end
    end
    return nil
end

local function findPrompt(egg)
    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            return d
        end
    end
    return nil
end

local function tweenHRPTo(targetPos, speed)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    speed = speed or _G.FarmSpeed or 200
    local distance = (targetPos - hrp.Position).Magnitude
    if distance < 1 then return true end
    local duration = math.max(distance / speed, 0.1)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(targetPos) }
    )
    tween:Play()

    local completed = false
    local conn = tween.Completed:Connect(function() completed = true end)
    local startTime = tick()
    while not completed and _G.AutoFarmEgg_V1_Running do
        if tick() - startTime > duration + 1 then break end
        task.wait(0.05)
    end
    if conn then conn:Disconnect() end

    if not completed then
        pcall(function() tween:Cancel() end)
    end

    return completed
end

local function instantTP(targetPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = CFrame.new(targetPos)
    return true
end

local function pickupEgg(egg)
    local prompt = findPrompt(egg)
    if not prompt then return false end

    local ok1 = pcall(function() prompt:InputHoldBegin() end)
    if not ok1 then return false end

    task.wait(prompt.HoldDuration + 0.1)

    pcall(function() prompt:InputHoldEnd() end)
    return true
end

-- ================================================================
-- V1 LOOP (TWEEN)
-- ================================================================
function StartAutoFarmEggV1()
    if _G.AutoFarmEgg_V1_Running then return end
    _G.AutoFarmEgg_V1_Running = true

    task.spawn(function()
        while _G.AutoFarmEgg_V1_Running do
            if not _G.AutoFarmEgg_V1_Running then break end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); continue end

            local egg = findTargetEgg()
            if not egg then task.wait(1); continue end

            local eggPos = getObjectPosition(egg)
            if not eggPos then task.wait(0.3); continue end

            local data = GetEggData(egg.Name)
            print("[Farm V1] Target:", egg.Name, "| Tier:", _G.FarmTarget, "| Luck:", data.Luck)

            local reached = tweenHRPTo(eggPos + Vector3.new(0, 3, 0), _G.FarmSpeed)
            if not _G.AutoFarmEgg_V1_Running then break end
            if not reached then
                task.wait(0.3)
                continue
            end

            local charNow = LocalPlayer.Character
            local hrpNow = charNow and charNow:FindFirstChild("HumanoidRootPart")
            if not hrpNow then task.wait(1); continue end
            local dist = (hrpNow.Position - eggPos).Magnitude
            if dist > 15 then
                task.wait(0.2)
                continue
            end

            print("[Farm V1] Sampai di telur, jarak:", math.floor(dist))

            local picked = false
            for attempt = 1, 5 do
                if not _G.AutoFarmEgg_V1_Running then break end
                if not egg.Parent then picked = true; break end

                pickupEgg(egg)

                local t0 = tick()
                while tick() - t0 < 0.5 do
                    if not egg.Parent then picked = true; break end
                    task.wait(0.05)
                end

                if picked then break end
                task.wait(0.2)
            end

            if not _G.AutoFarmEgg_V1_Running then break end

            if not picked then
                print("[Farm V1] Gagal pickup, skip")
                task.wait(0.5)
                continue
            end

            print("[Farm V1] ✓ Pickup sukses, balik ke base...")

            local basePos = getMyBasePosition()
            if basePos then
                tweenHRPTo(basePos + Vector3.new(0, 8, 0), _G.FarmSpeed)
            end

            task.wait(0.5)
        end
        _G.AutoFarmEgg_V1_Running = false
        print("[Farm V1] Stopped")
    end)
end

function StopAutoFarmEggV1()
    _G.AutoFarmEgg_V1_Running = false
end

-- ================================================================
-- V2 LOOP (INSTANT TP)
-- ================================================================
function StartAutoFarmEggV2()
    if _G.AutoFarmEgg_V2_Running then return end
    _G.AutoFarmEgg_V2_Running = true

    task.spawn(function()
        while _G.AutoFarmEgg_V2_Running do
            task.wait(0.15)

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); continue end

            local egg = findTargetEgg()
            if not egg then task.wait(1); continue end

            local eggPos = getObjectPosition(egg)
            if not eggPos then task.wait(0.3); continue end

            local data = GetEggData(egg.Name)
            print("[Farm V2] Target:", egg.Name, "| Tier:", _G.FarmTarget, "| Luck:", data.Luck)

            instantTP(eggPos + Vector3.new(0, 3, 0))
            task.wait(0.15)

            local picked = false
            for attempt = 1, 5 do
                if not _G.AutoFarmEgg_V2_Running then break end
                if not egg.Parent then picked = true; break end

                pickupEgg(egg)

                local t0 = tick()
                while tick() - t0 < 0.5 do
                    if not egg.Parent then picked = true; break end
                    task.wait(0.05)
                end

                if picked then break end
                task.wait(0.2)
            end

            if not _G.AutoFarmEgg_V2_Running then break end

            if not picked then
                print("[Farm V2] Gagal pickup, skip")
                task.wait(0.5)
                continue
            end

            print("[Farm V2] ✓ Pickup sukses, balik ke base...")

            local basePos = getMyBasePosition()
            if basePos then
                instantTP(basePos + Vector3.new(0, 8, 0))
            end

            task.wait(0.4)
        end
        print("[Farm V2] Stopped")
    end)
end

function StopAutoFarmEggV2()
    _G.AutoFarmEgg_V2_Running = false
end

-- ================================================================
-- BUILD UI
-- ================================================================
local Tabs = {
    ESP = Window:CreateTab({Name = "Egg ESP", Icon = "visibility", ImageSource = "Material", ShowTitle = true}),
    Farm = Window:CreateTab({Name = "Auto Farm", Icon = "agriculture", ImageSource = "Material", ShowTitle = true}),
    TP = Window:CreateTab({Name = "Teleport", Icon = "my_location", ImageSource = "Material", ShowTitle = true}),
    Utility = Window:CreateTab({Name = "Utility", Icon = "build", ImageSource = "Material", ShowTitle = true}),
    Settings = Window:CreateTab({Name = "Settings", Icon = "settings", ImageSource = "Material", ShowTitle = true}),
}

Window:CreateHomeTab({
    SupportedExecutors = {},
    DiscordInvite = "https://discord.gg/rUBAUk6VE",
    Icon = 1,
})

-- ================================================================
-- TAB ESP
-- ================================================================
Tabs.ESP:CreateSection("Visual")

Tabs.ESP:CreateToggle({
    Name = "Enable Egg ESP",
    Description = "Nampilin nama, tier, dan luck tiap telur",
    CurrentValue = false,
    Flag = "EggESP_Toggle",
    Callback = function(state)
        _G.EggESP_Enabled = state
        if state then startESP() else cleanupESP() end
    end,
})

-- ===== SECTION EGG TRACKER & STOCK SHOP =====
Tabs.ESP:CreateSection("Egg Tracker & Stock Shop")

Tabs.ESP:CreateButton({
    Name = "Open Egg Tracker",
    Description = "Buka UI Egg Tracker (pakai firesignal)",
    Callback = function()
        OpenEggTracker()
    end,
})

Tabs.ESP:CreateButton({
    Name = "Open Gears Shop",
    Description = "Buka stock shop kategori Gears",
    Callback = function()
        OpenStockShop("Gears")
    end,
})

Tabs.ESP:CreateButton({
    Name = "Open Food Shop",
    Description = "Buka stock shop kategori Food",
    Callback = function()
        OpenStockShop("Food")
    end,
})

-- ================================================================
-- TAB AUTO FARM
-- ================================================================
Tabs.Farm:CreateSection("Farm Target (by Tier)")

Tabs.Farm:CreateDropdown({
    Name = "Pilih Tier Target",
    Description = "Bot akan ambil telur mana pun dalam tier ini",
    Options = TIER_LIST,
    CurrentOption = "Legendary",
    MultipleOptions = false,
    SpecialType = nil,
    Flag = "FarmTier_Dropdown",
    Callback = function(selected)
        if not selected then return end
        local name = type(selected) == "table" and selected[1] or selected
        if name then
            _G.FarmTarget = name
            print("[Farm] Tier target set ke:", name)
        end
    end,
})

Tabs.Farm:CreateSection("Auto Farm V1 — Tween (Smooth)")

Tabs.Farm:CreateToggle({
    Name = "Auto Farm V1",
    Description = "Tween ke telur → pickup (tunggu sukses) → balik base",
    CurrentValue = false,
    Flag = "AutoFarm_V1_Toggle",
    Callback = function(state)
        if state then
            StartAutoFarmEggV1()
            Foxy:Notification({Title = "FARM V1", Content = "Started | Tier: " .. _G.FarmTarget, Icon = "play_arrow", ImageSource = "Material"})
        else
            StopAutoFarmEggV1()
            Foxy:Notification({Title = "FARM V1", Content = "Stopped", Icon = "stop", ImageSource = "Material"})
        end
    end,
})

Tabs.Farm:CreateSlider({
    Name = "V1 Tween Speed",
    Description = "Kecepatan tween (studs/detik)",
    Range = {200, 500},
    Increment = 10,
    CurrentValue = 200,
    Flag = "FarmSpeed_Slider",
    Callback = function(value)
        _G.FarmSpeed = value
    end,
})

Tabs.Farm:CreateSection("Auto Farm V2 — Instant TP (Fast)")

Tabs.Farm:CreateToggle({
    Name = "Auto Farm V2",
    Description = "Instan TP ke telur → pickup (tunggu sukses) → balik base",
    CurrentValue = false,
    Flag = "AutoFarm_V2_Toggle",
    Callback = function(state)
        if state then
            StartAutoFarmEggV2()
            Foxy:Notification({Title = "FARM V2", Content = "Started | Tier: " .. _G.FarmTarget, Icon = "bolt", ImageSource = "Material"})
        else
            StopAutoFarmEggV2()
            Foxy:Notification({Title = "FARM V2", Content = "Stopped", Icon = "stop", ImageSource = "Material"})
        end
    end,
})

-- ================================================================
-- TAB TELEPORT
-- ================================================================
Tabs.TP:CreateSection("Base Teleport")

Tabs.TP:CreateButton({
    Name = "TP to Base Plot",
    Description = "Instan TP ke base kamu",
    Callback = function()
        teleportToMyPlot()
    end,
})

Tabs.TP:CreateToggle({
    Name = "Tween ke Base",
    Description = "Loop tween ke base kamu",
    CurrentValue = false,
    Flag = "TweenBase_Toggle",
    Callback = function(state)
        if state then
            if _G.TweenBase_Running then return end
            _G.TweenBase_Running = true

            Foxy:Notification({Title = "TWEEN BASE", Content = "Started", Icon = "play_arrow", ImageSource = "Material"})

            tweenBaseThread = task.spawn(function()
                while _G.TweenBase_Running do
                    if not _G.TweenBase_Running then break end

                    local basePos = getMyBasePosition()
                    if basePos then
                        tweenToPosition(basePos + Vector3.new(0, 8, 0), _G.TweenTP_Speed, "TweenBase_Running")
                    else
                        task.wait(1)
                    end

                    task.wait(0.3)
                end
                print("[TweenBase] Stopped")
            end)
        else
            _G.TweenBase_Running = false
            tweenBaseThread = nil
            Foxy:Notification({Title = "TWEEN BASE", Content = "Stopped", Icon = "stop", ImageSource = "Material"})
        end
    end,
})

-- ===== SECTION BASE ORANG =====
Tabs.TP:CreateSection("Base Orang Lain")

local currentTargetPlayer = ""
local playerDropdown = nil

playerDropdown = Tabs.TP:CreateDropdown({
    Name = "Pilih Player",
    Description = "Auto-update tiap ada player join/leave",
    Options = getPlayerList(),
    CurrentOption = "",
    MultipleOptions = false,
    SpecialType = "Player",
    Flag = "TargetPlayer_Dropdown",
    Callback = function(selected)
        if not selected then return end
        local name = type(selected) == "table" and selected[1] or selected
        if name then
            currentTargetPlayer = name
            print("[TP] Target player set ke:", name)
        end
    end,
})

-- ================================================================
-- PLAYER DROPDOWN AUTO-REFRESH (Optimized)
-- ================================================================
local lastPlayerListStr = ""
local refreshThread = nil

local function refreshPlayerDropdown(force)
    if not playerDropdown then return end

    local list = getPlayerList()
    local currentStr = table.concat(list, ",")

    if not force and currentStr == lastPlayerListStr then
        return
    end
    lastPlayerListStr = currentStr

    pcall(function()
        playerDropdown:Set({ Options = list })
    end)

    print("[PlayerList] Updated:", #list, "player(s)")
end

local debounceToken = 0
local function debouncedRefresh()
    debounceToken = debounceToken + 1
    local myToken = debounceToken

    task.spawn(function()
        task.wait(0.5)
        if debounceToken == myToken then
            refreshPlayerDropdown()
        end
    end)
end

refreshPlayerDropdown(true)

Players.PlayerAdded:Connect(debouncedRefresh)
Players.PlayerRemoving:Connect(debouncedRefresh)

if refreshThread then
    pcall(function() task.cancel(refreshThread) end)
end

refreshThread = task.spawn(function()
    while playerDropdown do
        task.wait(10)
        refreshPlayerDropdown()
    end
    print("[PlayerList] Refresh loop stopped")
end)

Tabs.TP:CreateButton({
    Name = "TP ke Base Orang",
    Description = "Instan TP ke base player yang dipilih",
    Callback = function()
        if currentTargetPlayer == "" then
            Foxy:Notification({Title = "ERROR", Content = "Pilih player dulu di dropdown!", Icon = "error", ImageSource = "Material"})
            return
        end
        teleportToPlayerBase(currentTargetPlayer)
    end,
})

-- ⬇️ SIMPAN REFERENCE KE TOGGLE
local toggleTweenBasePlayer = Tabs.TP:CreateToggle({
    Name = "Tween ke Base Orang",
    Description = "Loop tween ke base player yang dipilih",
    CurrentValue = false,
    Flag = "TweenBasePlayer_Toggle",
    Callback = function(state)
        if state then
            if _G.TweenPlayerBase_Running then return end

            if currentTargetPlayer == "" then
                Foxy:Notification({Title = "ERROR", Content = "Pilih player dulu di dropdown!", Icon = "error", ImageSource = "Material"})
                task.wait(0.3)
                pcall(function()
                    toggleTweenBasePlayer:UpdateState(false)
                end)
                return
            end

            _G.TweenPlayerBase_Running = true
            Foxy:Notification({Title = "TWEEN BASE", Content = "Started → " .. currentTargetPlayer, Icon = "play_arrow", ImageSource = "Material"})

            tweenPlayerBaseThread = task.spawn(function()
                while _G.TweenPlayerBase_Running do
                    if not _G.TweenPlayerBase_Running then break end
                    if currentTargetPlayer == "" then task.wait(1); continue end

                    local plot, plr = findPlotByUsername(currentTargetPlayer)
                    if plot then
                        local basePos = getPlotBasePosition(plot)
                        if basePos then
                            tweenToPosition(basePos + Vector3.new(0, 8, 0), _G.TweenTP_Speed, "TweenPlayerBase_Running")
                        end
                    end

                    task.wait(0.3)
                end
                print("[TweenPlayerBase] Stopped")
            end)
        else
            _G.TweenPlayerBase_Running = false
            tweenPlayerBaseThread = nil
            Foxy:Notification({Title = "TWEEN BASE", Content = "Stopped", Icon = "stop", ImageSource = "Material"})
        end
    end,
})

-- ===== SECTION STALLS (DROPDOWN) =====
Tabs.TP:CreateSection("Stalls Teleport")

local currentStall = "Gears"

Tabs.TP:CreateDropdown({
    Name = "Pilih Stall",
    Description = "Pilih stall, lalu TP / Tween",
    Options = STALL_LIST,
    CurrentOption = "Gears",
    MultipleOptions = false,
    SpecialType = nil,
    Flag = "Stall_Dropdown",
    Callback = function(selected)
        if not selected then return end
        local name = type(selected) == "table" and selected[1] or selected
        if name then
            currentStall = name
            print("[TP] Stall target set ke:", name)
        end
    end,
})

Tabs.TP:CreateButton({
    Name = "TP ke Stall",
    Description = "Instan TP ke stall yang dipilih",
    Callback = function()
        teleportToStall(currentStall)
    end,
})

Tabs.TP:CreateToggle({
    Name = "Tween ke Stall",
    Description = "Loop tween ke stall yang dipilih",
    CurrentValue = false,
    Flag = "TweenStall_Toggle",
    Callback = function(state)
        if state then
            if _G.TweenStall_Running then return end
            _G.TweenStall_Running = true

            Foxy:Notification({Title = "TWEEN STALL", Content = "Started → " .. currentStall, Icon = "play_arrow", ImageSource = "Material"})

            tweenStallThread = task.spawn(function()
                while _G.TweenStall_Running do
                    if not _G.TweenStall_Running then break end

                    local pos = getStallPosition(currentStall)
                    if pos then
                        tweenToPosition(pos + Vector3.new(0, 5, 0), _G.TweenTP_Speed, "TweenStall_Running")
                    else
                        task.wait(1)
                    end

                    task.wait(0.3)
                end
                print("[TweenStall] Stopped")
            end)
        else
            _G.TweenStall_Running = false
            tweenStallThread = nil
            Foxy:Notification({Title = "TWEEN STALL", Content = "Stopped", Icon = "stop", ImageSource = "Material"})
        end
    end,
})

-- ===== SECTION EGG TELEPORT =====
Tabs.TP:CreateSection("Egg Teleport")

local currentTPName = "Golden Egg"

Tabs.TP:CreateDropdown({
    Name = "Pilih Telur",
    Description = "Pilih telur buat TP / Tween",
    Options = EGG_LIST,
    CurrentOption = "Golden Egg",
    MultipleOptions = false,
    SpecialType = nil,
    Flag = "EggTP_Dropdown",
    Callback = function(selected)
        if not selected then return end
        local name = type(selected) == "table" and selected[1] or selected
        if name then
            currentTPName = name
            print("[TP] Target set ke:", name)
        end
    end,
})

Tabs.TP:CreateButton({
    Name = "TP ke Pilihan Dropdown",
    Description = "Instan TP ke telur yang dipilih",
    Callback = function()
        teleportToEgg(currentTPName)
    end,
})

Tabs.TP:CreateToggle({
    Name = "Tween ke Pilihan Dropdown",
    Description = "Loop tween ke telur yang dipilih",
    CurrentValue = false,
    Flag = "TweenEgg_Toggle",
    Callback = function(state)
        if state then
            if _G.TweenEgg_Running then return end
            _G.TweenEgg_Running = true

            Foxy:Notification({Title = "TWEEN EGG", Content = "Started → " .. currentTPName, Icon = "play_arrow", ImageSource = "Material"})

            tweenEggThread = task.spawn(function()
                while _G.TweenEgg_Running do
                    if not _G.TweenEgg_Running then break end

                    local target = findEggByName(currentTPName)
                    if target then
                        local pos = getObjectPosition(target)
                        if pos then
                            tweenToPosition(pos + Vector3.new(0, 3, 0), _G.TweenTP_Speed, "TweenEgg_Running")
                        end
                    end

                    task.wait(0.3)
                end
                print("[TweenEgg] Stopped")
            end)
        else
            _G.TweenEgg_Running = false
            tweenEggThread = nil
            Foxy:Notification({Title = "TWEEN EGG", Content = "Stopped", Icon = "stop", ImageSource = "Material"})
        end
    end,
})

Tabs.TP:CreateSlider({
    Name = "Tween TP Speed",
    Description = "Kecepatan tween di tab Teleport (studs/detik)",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 200,
    Flag = "TweenTPSpeed_Slider",
    Callback = function(value)
        _G.TweenTP_Speed = value
    end,
})

-- ================================================================
-- TAB UTILITY
-- ================================================================
Tabs.Utility:CreateSection("Movement")

Tabs.Utility:CreateToggle({
    Name = "Infinity Jump",
    Description = "Bisa lompat terus tanpa menyentuh tanah",
    CurrentValue = false,
    Flag = "InfJump_Toggle",
    Callback = function(state)
        _G.InfJump_Enabled = state
        if state then
            startInfJump()
            Foxy:Notification({Title = "INF JUMP", Content = "Enabled", Icon = "check_circle", ImageSource = "Material"})
        else
            stopInfJump()
            Foxy:Notification({Title = "INF JUMP", Content = "Disabled", Icon = "cancel", ImageSource = "Material"})
        end
    end,
})

Tabs.Utility:CreateToggle({
    Name = "Enable WalkSpeed",
    Description = "Aktifin custom walkspeed",
    CurrentValue = false,
    Flag = "WalkSpeed_Toggle",
    Callback = function(state)
        _G.WalkSpeed_Enabled = state
        if state then applyWalkSpeed(_G.WalkSpeed_Value) else applyWalkSpeed(16) end
    end,
})

Tabs.Utility:CreateSlider({
    Name = "WalkSpeed Value",
    Description = "Atur kecepatan jalan (16 = normal)",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed_Slider",
    Callback = function(value)
        _G.WalkSpeed_Value = value
        if _G.WalkSpeed_Enabled then applyWalkSpeed(value) end
    end,
})

Tabs.Utility:CreateToggle({
    Name = "Noclip",
    Description = "Tembus dinding / object",
    CurrentValue = false,
    Flag = "Noclip_Toggle",
    Callback = function(state)
        _G.Noclip_Enabled = state
        if state then
            startNoclip()
            Foxy:Notification({Title = "NOCLIP", Content = "Enabled", Icon = "check_circle", ImageSource = "Material"})
        else
            stopNoclip()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
            Foxy:Notification({Title = "NOCLIP", Content = "Disabled", Icon = "cancel", ImageSource = "Material"})
        end
    end,
})

-- FLY SECTION
Tabs.Utility:CreateSection("Fly")

Tabs.Utility:CreateToggle({
    Name = "Fly",
    Description = "Terbang bebas. W/A/S/D gerak, Space/E naik, Ctrl/Q turun",
    CurrentValue = false,
    Flag = "Fly_Toggle",
    Callback = function(value)
        if value then
            StartFly()
        else
            StopFly()
        end
    end,
})

Tabs.Utility:CreateSlider({
    Name = "Fly Speed",
    Description = "Kecepatan terbang (studs/detik)",
    Range = {5, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "FlySpeed_Slider",
    Callback = function(value)
        flySpeed = tonumber(value) or 50
    end,
})

-- ANTI-STAFF SECTION
Tabs.Utility:CreateSection("Anti-Staff")

Tabs.Utility:CreateToggle({
    Name = "Anti-Staff",
    Description = "Otomatis pindah server jika ada staff",
    CurrentValue = false,
    Flag = "AntiStaff_Toggle",
    Callback = function(v)
        antiStaffEnabled = v
        _G.AntiStaff_Enabled = v
        if v then
            StartAntiStaff()
            Foxy:Notification({Title = "ANTI-STAFF", Content = "Enabled", Icon = "shield", ImageSource = "Material"})
        else
            StopAntiStaff()
            Foxy:Notification({Title = "ANTI-STAFF", Content = "Disabled", Icon = "cancel", ImageSource = "Material"})
        end
    end,
})

-- ================================================================
-- TAB SETTINGS
-- ================================================================
Tabs.Settings:BuildConfigSection()
Tabs.Settings:BuildThemeSection()

-- ================================================================
-- CLEANUP
-- ================================================================
game:BindToClose(function()
    cleanupESP()
    stopInfJump()
    stopNoclip()
    StopAntiStaff()
    StopFly(true)

    _G.AutoFarmEgg_V1_Running = false
    _G.AutoFarmEgg_V2_Running = false

    _G.TweenBase_Running = false
    _G.TweenPlayerBase_Running = false
    _G.TweenStall_Running = false
    _G.TweenEgg_Running = false

    if refreshThread then pcall(function() task.cancel(refreshThread) end) end
end)

print("[NyxHub] Loaded successfully!")