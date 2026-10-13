--[[
    ═══════════════════════════════════════════════════════════════
      EXO UNIFIED  —  build 1.0
    ═══════════════════════════════════════════════════════════════

    features:
      • legit aimbot / silent aim (air bypass)
      • wallbang (GunHandler detour)
      • forcehit / target strafe / kill aura
      • knifebot + glue
      • desync / fake position
      • movement (walkspeed, cframe, fly, spinbot)
      • visuals (esp, tracers, chams, crosshair, fov circle)
      • skinchanger / morphs
      • misc automation
      • keybind HUD

    loadstring:
      loadstring(game:HttpGet("YOUR_RAW_URL"))()
--]]

-- ═══════════════════════════════════════════════════════════════
--  SERVICES / GENV
-- ═══════════════════════════════════════════════════════════════
local cloneref = cloneref or function(o) return o end
local p = game
local _genv = {}
local getgenv = getgenv or function() return _genv end
local tick = tick or os.clock

local Services = {
    Players           = cloneref(p:GetService("Players")),
    RunService        = cloneref(p:GetService("RunService")),
    UserInputService  = cloneref(p:GetService("UserInputService")),
    ReplicatedStorage = cloneref(p:GetService("ReplicatedStorage")),
    SoundService      = cloneref(p:GetService("SoundService")),
    TweenService      = cloneref(p:GetService("TweenService")),
    Lighting          = cloneref(p:GetService("Lighting")),
    GuiService        = cloneref(p:GetService("GuiService")),
    HttpService       = cloneref(p:GetService("HttpService")),
    TeleportService   = cloneref(p:GetService("TeleportService")),
    TextChatService   = cloneref(p:GetService("TextChatService"))
}

for k, v in pairs(Services) do
    if typeof(getgenv()[k]) ~= "Instance" then
        getgenv()[k] = v
    end
end

getgenv().LocalPlayer       = Services.Players.LocalPlayer
getgenv().Players           = Services.Players
getgenv().RunService        = Services.RunService
getgenv().UserInputService  = Services.UserInputService
getgenv().ReplicatedStorage = Services.ReplicatedStorage
getgenv().SoundService      = Services.SoundService
getgenv().TweenService      = Services.TweenService
getgenv().Lighting          = Services.Lighting

local LocalPlayer       = Services.Players.LocalPlayer
local Players           = Services.Players
local RunService        = Services.RunService
local UIS               = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage
local Camera            = workspace.CurrentCamera
local Mouse             = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════
--  ADONIS ANTI-CHEAT BYPASS
-- ═══════════════════════════════════════════════════════════════
pcall(function()
    local getinfo = getinfo or debug.getinfo
    local DEBUG = false
    local Hooked = {}

    local Detected, Kill

    setthreadidentity(2)

    for i, v in getgc(true) do
        if typeof(v) == "table" then
            local DetectFunc = rawget(v, "Detected")
            local KillFunc = rawget(v, "Kill")

            if typeof(DetectFunc) == "function" and not Detected then
                Detected = DetectFunc

                local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
                    if Action ~= "_" then
                        if DEBUG then
                            warn("Adonis AntiCheat flagged\nMethod: "
                                .. tostring(Action)
                                .. "\nInfo: " .. tostring(Info))
                        end
                    end

                    return true
                end)

                table.insert(Hooked, Detected)
            end

            if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
                Kill = KillFunc
                local Old; Old = hookfunction(Kill, function(Info)
                    if DEBUG then
                        warn("Adonis AntiCheat tried to kill (fallback): "
                            .. tostring(Info))
                    end
                end)

                table.insert(Hooked, Kill)
            end
        end
    end

    local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
        local LevelOrFunc, Info = ...

        if Detected and LevelOrFunc == Detected then
            if DEBUG then
                warn("zins | adonis bypassed")
            end

            return coroutine.yield(coroutine.running())
        end

        return Old(...)
    end))

    setthreadidentity(7)

    print("[EXO UNIFIED] Adonis bypass active.")
end)

-- ═══════════════════════════════════════════════════════════════
--  KEY PARSER  (used by AddKeybind callbacks all over)
-- ═══════════════════════════════════════════════════════════════
getgenv().parseKey = function(s)
    if typeof(s) == "EnumItem" then return s end
    if typeof(s) ~= "string" then return nil end

    local lower = s:lower()
    local mouseAlias = {
        m1 = "MouseButton1", m2 = "MouseButton2", m3 = "MouseButton3",
        mb1 = "MouseButton1", mb2 = "MouseButton2", mb3 = "MouseButton3",
        m1b = "MouseButton1", m2b = "MouseButton2",
        rclick = "MouseButton2", lclick = "MouseButton1"
    }
    if mouseAlias[lower] then
        return Enum.UserInputType[mouseAlias[lower]]
    end

    local cleaned = s:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")

    local ok, kc = pcall(function() return Enum.KeyCode[cleaned] end)
    if ok and kc then return kc end

    local ok2, uit = pcall(function() return Enum.UserInputType[cleaned] end)
    if ok2 and uit then return uit end

    return nil
end

-- ═══════════════════════════════════════════════════════════════
--  AUTO-BUY ARMOR  (keybind → teleport-buy-teleport)
-- ═══════════════════════════════════════════════════════════════
local ArmorShopPath = { "Ignored", "Shop", "[Full Armor] - $3639" }

local function getArmorShopModel()
    local obj = workspace
    for _, name in ipairs(ArmorShopPath) do
        obj = obj:FindFirstChild(name)
        if not obj then return nil end
    end
    return obj
end

local function fireArmorClick(cd)
    if not cd then return end
    local ok = pcall(fireclickdetector, cd)
    if not ok then
        pcall(fireclickdetector, cd, 0)
    end
end

local ArmorLastBuy = 0

local function buyArmor()
    if os.clock() - ArmorLastBuy < 1.5 then return false end

    local model = getArmorShopModel()
    if not model then
        warn("[BUY] armor shop not found")
        return false
    end

    local cd = model:FindFirstChildOfClass("ClickDetector")
    if not cd then
        warn("[BUY] no ClickDetector on armor shop")
        return false
    end

    local hrp = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local shopPos = model:GetPivot().Position
    local dist = (hrp.Position - shopPos).Magnitude
    local maxDist = cd.MaxActivationDistance or 32

    if dist <= maxDist then
        fireArmorClick(cd)
        task.wait(0.05)
        fireArmorClick(cd)
        ArmorLastBuy = os.clock()
        return true
    end

    local savedCF  = hrp.CFrame
    local savedVel = hrp.AssemblyLinearVelocity
    hrp.CFrame = CFrame.new(shopPos + Vector3.new(0, 3, 0))
    hrp.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.12)
    fireArmorClick(cd)
    task.wait(0.05)
    fireArmorClick(cd)
    task.wait(0.05)
    fireArmorClick(cd)
    task.wait(0.15)
    hrp.CFrame = savedCF
    hrp.AssemblyLinearVelocity = savedVel
    ArmorLastBuy = os.clock()
    return true
end

getgenv().BuyArmor = buyArmor

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
    if UIS:GetFocusedTextBox() then return end
    if getgenv().ArmorAutoBuyEnabled and input.KeyCode == getgenv().ArmorBuyKey then
        buyArmor()
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  ANTI-AIM VIEWER  (real mouse position vs server-reported)
-- ═══════════════════════════════════════════════════════════════
local DeepFakePosition = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Nosssa/NossLock/main/GetRealMousePosition"
))()
task.wait()

local AALocal    = Players.LocalPlayer
local AAMouse    = AALocal:GetMouse()
local AAMainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
local AAConn     = nil
local AAEnabled  = false

local function AABindEntity(entity)
    entity.ChildAdded:Connect(function(child)
        if not child:IsA("Tool") then return end
        child.Activated:Connect(function()
            if AAMainEvent and AAEnabled then
                AAMainEvent:FireServer("UpdateMousePos", _G.FetchPosition())
            end
        end)
    end)
end

local function AAAlive(plr)
    return plr
        and plr.Character
        and plr.Character:FindFirstChild("Humanoid")
        and plr.Character:FindFirstChild("Head")
        or false
end

AALocal.CharacterAdded:Connect(AABindEntity)
if AAAlive(AALocal) then
    AALocal.Character.Humanoid:UnequipTools()
    AABindEntity(AALocal.Character)
end

local AAOldNamecall
AAOldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args   = { ... }
    local method = getnamecallmethod()

    if AAEnabled
       and not checkcaller()
       and method == "FireServer"
       and self.Name == "MainEvent"
       and args[1] == "UpdateMousePos"
    then
        args[2] = _G.FetchPosition()
        return self.FireServer(self, unpack(args))
    end

    return AAOldNamecall(self, ...)
end)

getgenv().AntiAimViewer = {
    Enabled = false,
    Toggle  = function(state) AAEnabled = state end,
}

-- ═══════════════════════════════════════════════════════════════
--  NEVERLOSE UI LOADER
-- ═══════════════════════════════════════════════════════════════
do
    local ok, err = pcall(function()
        getgenv().NeverLose = loadstring(game:HttpGet("https://files.catbox.moe/rit3mp.luau"))()
    end)
    if not ok or not getgenv().NeverLose then
        warn("[EXO UNIFIED] NeverLose loader failed: " .. tostring(err))
        return
    end
end

local NeverLose = getgenv().NeverLose
getgenv().Notification = NeverLose:CreateNotification()
getgenv().Logging      = NeverLose:CreateLogger()
getgenv().Indicator    = NeverLose:CreateIndicator()

-- ═══════════════════════════════════════════════════════════════
--  EXO UNIFIED — GLOBAL CONFIG
--  (mirrors larptic's shape so everything downstream keeps working)
-- ═══════════════════════════════════════════════════════════════
local Config = {
    Unloaded        = false,
    LastRespawnTime = tick(),
    Services        = Services,

    Legit  = {
        CamLockEnabled   = false,
        TargetLockActive = false
    },
    ForceHit = {},
    Desync = {},
    Misc   = {},
    UI     = {},

    -- exo additions
    Wallbang = {
        Enabled       = false,
        UsePrediction = false,
        Prediction    = 0.135,
        HitPart       = "Head",
        TeamCheck     = true,
        VisibleCheck  = false,
        MaxDistance   = 500
    },

    Spread = {
        Enabled = false,
        Amount  = 0    -- 0..100 (%)
    },

    -- ecco additions
    SilentAim = {
        Enabled         = false,
        HitPart         = "Head",
        ClosestPart     = false,
        FovRadius       = 200,
        MaxDistance     = 500,
        TeamCheck       = true,
        VisibleCheck    = false,
        UsePrediction   = false,
        Prediction      = 0.135,

        Keybind         = Enum.KeyCode.X,
        KeybindMode     = "Toggle",
        KeybindActive   = false
    },
    Hitbox = {
        Enabled = false,
        Size    = 3
    },
    RapidFire = {
        Enabled = false,
        Delay   = 0.01
    },
    SuperJump = {
        Enabled = false,
        Key     = Enum.KeyCode.Z,
        Power   = 500
    },
    InfiniteJump = {
        Enabled = false
    },
    Speed = {
        Enabled    = false,
        Base       = 16,
        Multiplier = 35,
        Key        = Enum.KeyCode.C,
        Active     = false
    },

    Esp = {
        Enabled     = false,
        Color       = Color3.fromRGB(255, 255, 255),
        LockedColor = Color3.fromRGB(255, 60, 60)
    },
    FovCircle = {
        Enabled      = true,
        Radius       = 200,
        Color        = Color3.fromRGB(160, 32, 240),
        Thickness    = 1,
        Transparency = 1,
        NumSides     = 64,
        Filled       = false
    },
    Crosshair = {
        Enabled     = false,
        Size        = 10,
        Thickness   = 1.5,
        Color       = Color3.fromRGB(160, 32, 240),
        Gap         = 4
    }
}
getgenv().Config = Config

getgenv().ArmorBuyKey         = Enum.KeyCode.H
getgenv().ArmorAutoBuyEnabled = false
-- ═══════════════════════════════════════════════════════════════
--  KEYBIND HUD  (larptic-style card, Exo Unified branding)
-- ═══════════════════════════════════════════════════════════════
getgenv().KeybindHUDVisible = getgenv().KeybindHUDVisible ~= false
getgenv().SetKeybindHUDVisible = function(state)
    getgenv().KeybindHUDVisible = state
    if getgenv().KB_MainCard then
        getgenv().KB_MainCard.Visible = state
    end
end

if getgenv().KB_ScreenGui then
    pcall(function() getgenv().KB_ScreenGui:Destroy() end)
    getgenv().KB_ScreenGui = nil
end

do
    local sg = Instance.new("ScreenGui")
    sg.Name = "EXO_KeybindHUD"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Enabled = getgenv().KeybindHUDVisible

    local mounted = false
    pcall(function()
        local gethui_ok, hui = pcall(function() return gethui() end)
        if gethui_ok and hui then
            sg.Parent = hui
            mounted = true
        end
    end)
    if not mounted then
        pcall(function()
            sg.Parent = game:GetService("CoreGui")
            mounted = true
        end)
    end
    if not mounted then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    getgenv().KB_ScreenGui = sg

    local card = Instance.new("Frame")
    card.Name  = "ExoKeybindsCard"
    card.Size  = UDim2.new(0, 190, 0, 28)
    card.Position = UDim2.new(0.04, 0, 0.45, 0)
    card.BackgroundColor3   = Color3.fromRGB(11, 12, 16)
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel    = 0
    card.ClipsDescendants   = true
    card.Parent = sg
    getgenv().KB_MainCard = card

    local corner = Instance.new("UICorner", card)
    corner.CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(32, 34, 44)
    stroke.Thickness = 1.1
    stroke.Transparency = 0.3

    local header = Instance.new("Frame", card)
    header.Name = "HeaderBar"
    header.Size = UDim2.new(1, 0, 0, 27)
    header.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "exo unified — keybinds"
    title.TextColor3 = Color3.fromRGB(220, 222, 230)
    title.TextSize = 11
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local sep = Instance.new("Frame", card)
    sep.Name = "WhiteSeparator"
    sep.Size = UDim2.new(1, -16, 0, 1)
    sep.Position = UDim2.new(0, 8, 0, 27)
    sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sep.BackgroundTransparency = 0.9
    sep.BorderSizePixel = 0

    local rowsHolder = Instance.new("Frame", card)
    rowsHolder.Name = "RowsHolder"
    rowsHolder.Size = UDim2.new(1, 0, 1, -29)
    rowsHolder.Position = UDim2.new(0, 0, 0, 29)
    rowsHolder.BackgroundTransparency = 1
    getgenv().KB_RowsHolder = rowsHolder

    local pad = Instance.new("UIPadding", rowsHolder)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingTop    = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 5)

    local layout = Instance.new("UIListLayout", rowsHolder)
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    getgenv().KB_RowsLayout = layout

    getgenv().KB_IsDragging = false
    getgenv().KB_DragStart  = nil
    getgenv().KB_StartPos   = nil
    getgenv().KB_DragInput  = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            getgenv().KB_IsDragging = true
            getgenv().KB_DragStart  = input.Position
            getgenv().KB_StartPos   = card.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    getgenv().KB_IsDragging = false
                end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            getgenv().KB_DragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == getgenv().KB_DragInput and getgenv().KB_IsDragging then
            local delta = input.Position - getgenv().KB_DragStart
            card.Position = UDim2.new(
                getgenv().KB_StartPos.X.Scale,
                getgenv().KB_StartPos.X.Offset + delta.X,
                getgenv().KB_StartPos.Y.Scale,
                getgenv().KB_StartPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  TRACKED KEYBINDS  (rows show up in the HUD when active)
-- ═══════════════════════════════════════════════════════════════
Config.TrackedKeybinds = {}
getgenv().KB_RowInstances = {}

local function addTrackedKeybind(entry)
    table.insert(Config.TrackedKeybinds, entry)
end

addTrackedKeybind({
    Name = "Silent Aim",
    GetKey = function()
        return Config.SilentAim.Keybind
            and Config.SilentAim.Keybind.Name or "None"
    end,
    IsActive = function()
        return Config.SilentAim.Enabled and (
            Config.SilentAim.KeybindMode == "Always"
            or Config.SilentAim.KeybindActive
        )
    end
})
addTrackedKeybind({
    Name = "Wallbang",
    GetKey = function() return "None" end,
    IsActive = function() return Config.Wallbang.Enabled end
})
addTrackedKeybind({
    Name = "Speed",
    GetKey = function()
        return Config.Speed.Key and Config.Speed.Key.Name or "None"
    end,
    IsActive = function() return Config.Speed.Enabled and Config.Speed.Active end
})
addTrackedKeybind({
    Name = "Super Jump",
    GetKey = function()
        return Config.SuperJump.Key and Config.SuperJump.Key.Name or "None"
    end,
    IsActive = function() return Config.SuperJump.Enabled end
})
addTrackedKeybind({
    Name = "Rapid Fire",
    GetKey = function() return "LMB" end,
    IsActive = function() return Config.RapidFire.Enabled end
})
addTrackedKeybind({
    Name = "Hitbox",
    GetKey = function() return "None" end,
    IsActive = function() return Config.Hitbox.Enabled end
})
addTrackedKeybind({
    Name = "ESP",
    GetKey = function() return "None" end,
    IsActive = function() return Config.Esp.Enabled end
})

addTrackedKeybind({
    Name = "Auto-Buy Armor",
    GetKey = function()
        return getgenv().ArmorBuyKey and getgenv().ArmorBuyKey.Name or "H"
    end,
    IsActive = function()
        return getgenv().ArmorAutoBuyEnabled == true
    end
})
addTrackedKeybind({
    Name = "Anti-Aim Viewer",
    GetKey = function() return "Passive" end,
    IsActive = function()
        return getgenv().AntiAimViewer and getgenv().AntiAimViewer.Enabled
    end
})

local function createKeybindRow(entry)
    local row = Instance.new("Frame")
    row.Name = "Row_" .. entry.Name
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1
    row.Visible = false
    row.Parent = getgenv().KB_RowsHolder

    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(0.65, 0, 1, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = entry.Name
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 11
    nameLbl.TextColor3 = Color3.fromRGB(200, 202, 212)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local statusLbl = Instance.new("TextLabel", row)
    statusLbl.Size = UDim2.new(0.35, 0, 1, 0)
    statusLbl.Position = UDim2.new(0.65, 0, 0, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.GothamMedium
    statusLbl.TextSize = 11
    statusLbl.Text = "[" .. entry.GetKey() .. "]"
    statusLbl.TextColor3 = Color3.fromRGB(130, 134, 146)
    statusLbl.TextXAlignment = Enum.TextXAlignment.Right

    getgenv().KB_RowInstances[entry.Name] = {
        Frame = row, NameLabel = nameLbl, StatusLabel = statusLbl
    }
end

for _, entry in ipairs(Config.TrackedKeybinds) do
    createKeybindRow(entry)
end

task.spawn(function()
    local lastHeight = -1
    local lastTextCache = {}

    while task.wait(0.1) do
        if Config.Unloaded then
            if getgenv().KB_ScreenGui then
                pcall(function() getgenv().KB_ScreenGui:Destroy() end)
            end
            break
        end

        local visibleCount = 0
        for _, entry in ipairs(Config.TrackedKeybinds) do
            local inst = getgenv().KB_RowInstances[entry.Name]
            if inst then
                local ok, active = pcall(entry.IsActive)
                if not ok then active = false end

                if active then
                    visibleCount += 1

                    local newKey = entry.GetKey()
                    if lastTextCache[entry.Name] ~= newKey then
                        inst.StatusLabel.Text = "[" .. newKey .. "]"
                        lastTextCache[entry.Name] = newKey
                    end

                    if not inst.Frame.Visible then
                        inst.Frame.Visible = true
                    end
                else
                    if inst.Frame.Visible then
                        inst.Frame.Visible = false
                    end
                end
            end
        end

        local targetHeight = (visibleCount == 0) and 28 or (34 + visibleCount * 19)
        if targetHeight ~= lastHeight and getgenv().KB_MainCard then
            lastHeight = targetHeight
            pcall(function()
                TweenService:Create(
                    getgenv().KB_MainCard,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Size = UDim2.new(0, 190, 0, targetHeight) }
                ):Play()
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  UNLOAD CONTAINER
-- ═══════════════════════════════════════════════════════════════
getgenv().ScriptConnections = {}

getgenv().Unload = function()
    Config.Unloaded = true

    for _, conn in pairs(getgenv().ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end
    getgenv().ScriptConnections = {}

    if getgenv().KB_ScreenGui then
        pcall(function() getgenv().KB_ScreenGui:Destroy() end)
    end

    if getgenv().window and getgenv().window.Destroy then
        pcall(function() getgenv().window:Destroy() end)
    end
    if getgenv().NeverLose and getgenv().NeverLose.ScreenGui then
        pcall(function() getgenv().NeverLose.ScreenGui:Destroy() end)
    end

    print("[EXO UNIFIED] unloaded.")
end

-- ═══════════════════════════════════════════════════════════════
--  EXO UNIFIED — WATERMARK
-- ═══════════════════════════════════════════════════════════════
do
    local ok, wm = pcall(function()
        return NeverLose:CreateWindow({
            Name             = "Exo Unified",
            Logo             = "https://files.catbox.moe/h80mc4.png",
            Size             = NeverLose.Scales.Large,
            Keybind          = "RightShift",
            Enable3DRenderer = false
        })
    end)
    if ok and wm then
        getgenv().window = wm
        pcall(function() getgenv().Watermark = wm:Watermark() end)

        pcall(function()
            if wm.Content ~= nil then
                wm.Content = "Made by @kp3g"
            end
        end)

        pcall(function()
            if wm.SetSubtitle then
                wm:SetSubtitle("Made by @kp3g")
            end
        end)

        pcall(function()
            local MarketplaceService = game:GetService("MarketplaceService")
            local oldGetProductInfo = MarketplaceService.GetProductInfo
            MarketplaceService.GetProductInfo = newcclosure(function(self, ...)
                local info = oldGetProductInfo(self, ...)
                if info and type(info) == "table" then
                    info = setmetatable({}, { __index = info })
                    info.Name = "Made by @kp3g"
                end
                return info
            end)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  [EXO] WALLBANG  +  [ECCO] SILENT AIM  — target pipeline
-- ═══════════════════════════════════════════════════════════════

local function isPlayerKnocked(plr)
    if not plr or not plr.Character then return false end
    local be = plr.Character:FindFirstChild("BodyEffects")
    if not be then return false end
    local ko = be:FindFirstChild("K.O") or be:FindFirstChild("KO")
    if ko and ko.Value == true then return true end
    local dead = be:FindFirstChild("Dead")
    if dead and dead.Value == true then return true end
    return false
end

local function isSelfKnocked()
    if not LocalPlayer.Character then return false end
    local be = LocalPlayer.Character:FindFirstChild("BodyEffects")
    if not be then return false end
    local ko = be:FindFirstChild("K.O") or be:FindFirstChild("KO")
    return ko and ko.Value == true or false
end

local BODY_PARTS = {
    "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"
}

local function getClosestBodyPart(character)
    local closest, shortest = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, name in ipairs(BODY_PARTS) do
        local part = character:FindFirstChild(name)
        if part then
            local pos, on = Camera:WorldToViewportPoint(part.Position)
            if on then
                local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if d < shortest then
                    shortest = d
                    closest = part
                end
            end
        end
    end
    return closest
end

local function canSeeTarget(part, isLocking)
    if not part or not part.Parent then return false end
    local character = part.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local state = humanoid:GetState()
    local airborne = state == Enum.HumanoidStateType.Jumping
                  or state == Enum.HumanoidStateType.Freefall
                  or state == Enum.HumanoidStateType.FallingDown

    local root = character:FindFirstChild("HumanoidRootPart")
    local velY = root
        and math.abs((root.AssemblyLinearVelocity or root.Velocity or Vector3.new()).Y)
        or 0

    if (airborne or velY > 8) and isLocking then
        return true
    end

    local origin = Camera.CFrame.Position
    local dir = part.Position - origin

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { LocalPlayer.Character, character }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.IgnoreWater = true

    local result = workspace:Raycast(origin, dir, rp)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function findSilentAimTarget()
    local sa = Config.SilentAim
    local best, bestDist = nil, math.huge

    local camlockActive = Config.Legit
        and Config.Legit.CamLockEnabled == true

    local center = camlockActive
        and Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        or Vector2.new(Mouse.X, Mouse.Y)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer
           and plr.Character
           and plr.Character:FindFirstChild("HumanoidRootPart") then

            if not isPlayerKnocked(plr) then
                local part = sa.ClosestPart
                    and getClosestBodyPart(plr.Character)
                    or plr.Character:FindFirstChild(sa.HitPart)

                if part then
                    local visible = (not sa.VisibleCheck)
                        or canSeeTarget(part, true)

                    if visible then
                        local hrp = plr.Character.HumanoidRootPart
                        if (hrp.Position - Camera.CFrame.Position).Magnitude <= sa.MaxDistance then
                            local pos, on = Camera:WorldToViewportPoint(part.Position)
                            if on then
                                local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                                local fovR = getgenv().GetSharedFovRadius()
                                if d < bestDist and d <= fovR then
                                    bestDist = d
                                    best = { player = plr, part = part }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

getgenv().ExoInternal = getgenv().ExoInternal or {}
getgenv().ExoInternal.findSilentAimTarget = findSilentAimTarget
getgenv().ExoInternal.getClosestBodyPart  = getClosestBodyPart
getgenv().ExoInternal.canSeeTarget        = canSeeTarget
getgenv().ExoInternal.isPlayerKnocked     = isPlayerKnocked
getgenv().ExoInternal.isSelfKnocked       = isSelfKnocked

do
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt and type(mt) == "table" then
        local oldIndex = mt.__index
        setreadonly(mt, false)
        mt.__index = function(self, key)
            local sa = Config.SilentAim
            local saActive = sa.Enabled and (
                sa.KeybindMode == "Always"
                or (sa.KeybindMode == "Toggle" and sa.KeybindActive)
                or (sa.KeybindMode == "Hold" and sa.KeybindActive)
            )

            if saActive
               and self == Mouse
               and key == "Hit" then
                local target = findSilentAimTarget()
                if target then
                    local pos = target.part.Position
                    if Config.SilentAim.UsePrediction then
                        local vel = target.part.AssemblyLinearVelocity
                            or target.part.Velocity
                            or Vector3.new()
                        pos = pos + vel * Config.SilentAim.Prediction
                    end
                    return CFrame.new(pos)
                end
            end
            return oldIndex(self, key)
        end
        setreadonly(mt, true)
    end
end

local GunHandler = nil
pcall(function()
    GunHandler = require(
        ReplicatedStorage:WaitForChild("Modules", 2)
            :WaitForChild("GunHandler", 2)
    )
end)

if GunHandler and GunHandler.GetAim then
    local originalGetAim = GunHandler.GetAim
    GunHandler.GetAim = function(origin)
        local sa = Config.SilentAim
        local saActive = sa and sa.Enabled and (
            sa.KeybindMode == "Always"
            or (sa.KeybindMode == "Toggle" and sa.KeybindActive)
            or (sa.KeybindMode == "Hold" and sa.KeybindActive)
        )

        if Config.ForceHit and Config.ForceHit.TargetLocked and Config.ForceHit.LockedTarget then
            local tplr  = Config.ForceHit.LockedTarget
            local tchar = tplr.Character
            if tchar then
                local tpart = tchar:FindFirstChild(sa.HitPart)
                    or tchar:FindFirstChild("Head")
                    or tchar:FindFirstChild("HumanoidRootPart")
                if tpart and origin then
                    local aimPos = tpart.Position
                    if sa.UsePrediction then
                        local vel = tpart.AssemblyLinearVelocity
                            or tpart.Velocity
                            or Vector3.new()
                        aimPos = aimPos + vel * sa.Prediction
                    end
                    return (aimPos - origin).Unit
                end
            end
        end

        if saActive and findSilentAimTarget then
            local target = findSilentAimTarget()
            if target and target.part and origin then
                local aimPos = target.part.Position
                if sa.UsePrediction then
                    local vel = target.part.AssemblyLinearVelocity
                        or target.part.Velocity
                        or Vector3.new()
                    aimPos = aimPos + vel * sa.Prediction
                end
                return (aimPos - origin).Unit
            end
        end

        return originalGetAim(origin)
    end
end

if GunHandler then
    local originalShoot = GunHandler.Shoot
    GunHandler.Shoot = function(params)
        if Config.Wallbang.Enabled then
            local target = findSilentAimTarget()
            if target and target.player.Character then
                local head = target.player.Character:FindFirstChild(Config.Wallbang.HitPart)
                    or target.player.Character:FindFirstChild("Head")
                if head then
                    local hitPos = head.Position
                    if Config.Wallbang.UsePrediction then
                        local vel = head.AssemblyLinearVelocity
                            or head.Velocity
                            or Vector3.new()
                        hitPos = hitPos + vel * Config.Wallbang.Prediction
                    end
                    params.AimPosition = hitPos
                    params.Hit         = head
                    params.Normal      = Vector3.new(0, 1, 0)
                    if params.BeamTarget then params.BeamTarget = head end
                end
            end
        end

        if Config.Spread and Config.Spread.Enabled then
            local pct = math.clamp(Config.Spread.Amount or 0, 0, 100) / 100
            if pct > 0 and params.AimPosition then
                local amt = pct * 8
                local r = math.random() * 2 - 1
                local p = math.random() * 2 - 1
                local y = math.random() * 2 - 1
                params.AimPosition = params.AimPosition
                    + Vector3.new(r * amt, p * amt, y * amt)
            end
        end

        return originalShoot(params)
    end
end

getgenv().ExoInternal.GunHandler = GunHandler

task.spawn(function()
    while task.wait(0.1) do
        if Config.Unloaded then break end
        if not Config.Wallbang.Enabled then continue end
        if not GunHandler then continue end
        if isSelfKnocked() then continue end

        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then continue end

        local target = findSilentAimTarget()
        if not target then continue end

        local head = target.player.Character:FindFirstChild(Config.Wallbang.HitPart)
            or target.player.Character:FindFirstChild("Head")
        if not head then continue end

        local hitPos = head.Position
        if Config.Wallbang.UsePrediction then
            local vel = head.AssemblyLinearVelocity or head.Velocity or Vector3.new()
            hitPos = hitPos + vel * Config.Wallbang.Prediction
        end

        pcall(function()
            GunHandler.Shoot({
                AimPosition = hitPos,
                Hit         = head,
                Normal      = Vector3.new(0, 1, 0)
            })
        end)
    end
end)

print("[EXO UNIFIED]  Combat — wallbang + silent aim.")
-- ═══════════════════════════════════════════════════════════════
--  LEGIT TAB  — aimbot / silent aim / fov / target lock
-- ═══════════════════════════════════════════════════════════════
local window = getgenv().window
if not window then
    warn("[EXO UNIFIED] no window — skipped")
    return
end

-- ─── Legit aimbot state ───────────────────────────────────────
Config.Legit = {
    AimbotEnabled     = false,
    AimbotActive      = false,
    AimbotKey         = Enum.KeyCode.F,
    KeyMode           = "Hold",
    SilentAimEnabled  = false,
    HitPart           = "Head",
    Smoothness        = 5,
    Prediction        = 0.135,
    WallCheck         = true,
    ForceFieldCheck   = true,
    DeathCheck        = true,
    MaxDistance       = 250,
    FovRadius         = 200,
    FovVisible        = false,
    FovColor          = Color3.fromRGB(255, 255, 255),
    FovFilled         = false,
    FovTransparency   = 0.5,

    CurrentTarget     = nil,
    StickyAimEnabled  = false,
    StickyAimMode     = "Toggle",
    StickyAimKey      = Enum.KeyCode.Q,
    StickyAimActive   = false,
    StickyAimTarget   = nil,

    -- camera lock
    CamLockEnabled    = false,
    CamLockSmoothing  = 40,
    CamLockPart       = "Head",
    CamLockPrediction = 0.133,
    CamLockKey        = Enum.KeyCode.C,
    CamLockKeyMode    = "Toggle",
    CamLockKeyActive  = false,
    CamLockInstant    = false
}

-- ─── FOV circle drawing ───────────────────────────────────────
local fovCircleDrawing = Drawing.new("Circle")
Config.FovCircle = fovCircleDrawing
Config.FovCircle.Thickness    = 1
Config.FovCircle.NumSides     = 64
Config.FovCircle.Filled       = false
Config.FovCircle.Transparency = 0.7
Config.FovCircle.Radius       = 200
Config.FovCircle.Visible      = false

getgenv().GetSharedFovRadius = function()
    return Config.FovCircle.Radius or 200
end

-- ─── wall-check helper (blocked by anything not in the char) ──
local function wallCheck(targetPos, character)
    local origin = Camera.CFrame.Position
    local dir    = targetPos - origin

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { LocalPlayer.Character, character }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.IgnoreWater = true

    local result = workspace:Raycast(origin, dir, rp)
    return result == nil
end

-- ─── find target — closest to mouse, within FOV ───────────────
local function getLegitTarget()
    local L = Config.Legit
    local best, bestDist = nil, math.huge
    local mousePos = UIS:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if not (L.DeathCheck and isPlayerKnocked(plr)) then
                local ff = plr.Character:FindFirstChildOfClass("ForceField")
                local ffOk = not (L.ForceFieldCheck and ff)

                if ffOk then
                    local part = L.HitPart == "Closest Part"
                        and getClosestBodyPart(plr.Character)
                        or plr.Character:FindFirstChild(L.HitPart)

                    if part then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - Camera.CFrame.Position).Magnitude <= L.MaxDistance then
                            if (not L.WallCheck) or wallCheck(part.Position, plr.Character) then
                                local pos, on = Camera:WorldToViewportPoint(part.Position)
                                if on then
                                    local d = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                                    if d < bestDist and d <= L.FovRadius then
                                        bestDist = d
                                        best = { player = plr, part = part }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

getgenv().ExoInternal.getLegitTarget = getLegitTarget

-- ─── elastic / sine easing for camera lock ────────────────────
local function elasticOut(t)
    local p_ = 0.3
    return math.pow(2, -10 * t) * math.sin((t - p_ / 4) * (2 * math.pi) / p_) + 1
end
local function sineInOut(t)
    return -(math.cos(math.pi * t) - 1) / 2
end

-- ─── per-frame aimbot + camera lock + fov ─────────────────────
RunService.RenderStepped:Connect(function()
    if Config.Unloaded then return end

    local L = Config.Legit

    local inset = Services.GuiService:GetGuiInset()
    -- fov circle now drawn by the visuals chunk (single source)

    if L.AimbotEnabled and L.AimbotActive then
        local tgt = getLegitTarget()
        if tgt then
            local part = tgt.part
            local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
            local aimPos = part.Position + vel * L.Prediction

            local desired = CFrame.new(Camera.CFrame.Position, aimPos)
            Camera.CFrame = Camera.CFrame:Lerp(desired, 1 / L.Smoothness)
        end
    end

    if L.CamLockEnabled and (L.CamLockKeyMode == "Always" or L.CamLockKeyActive) then
        local tgt = L.StickyAimTarget
        if not tgt or not tgt.Character then
            local scan = getLegitTarget()
            tgt = scan and scan.player
        end
        if tgt and tgt.Character then
            local part = tgt.Character:FindFirstChild(L.CamLockPart)
                or tgt.Character:FindFirstChild("Head")
            if part then
                if L.CamLockInstant then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                else
                    local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
                    local aimPos = part.Position + vel * L.CamLockPrediction
                    local desired = CFrame.new(Camera.CFrame.Position, aimPos)

                    local baseAlpha = 1 / L.CamLockSmoothing
                    local smoothCF = Camera.CFrame:Lerp(
                        desired,
                        elasticOut(math.min(baseAlpha, 1)) * baseAlpha
                    )
                    Camera.CFrame = smoothCF:Lerp(
                        desired,
                        sineInOut(math.min(baseAlpha, 1)) * baseAlpha
                    )
                end
            end
        end
    end
end)

-- sticky aim — keeps the same target until death/respawn/out-of-range
task.spawn(function()
    while task.wait(0.05) do
        if Config.Unloaded then break end
        local L = Config.Legit

        if not L.StickyAimActive then
            L.StickyAimTarget = nil
            continue
        end

        local tgt = L.StickyAimTarget
        local valid = tgt
            and tgt.Character
            and tgt.Character:FindFirstChild("HumanoidRootPart")
            and not isPlayerKnocked(tgt)

        if valid then
            local hum = tgt.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = tgt.Character.HumanoidRootPart
                local myChar = LocalPlayer.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local dist = (hrp.Position - myHrp.Position).Magnitude
                    if dist > L.MaxDistance then
                        valid = false
                    end
                end
            else
                valid = false
            end
        end

        if not valid then
            local t = getLegitTarget()
            L.StickyAimTarget = t and t.player
        end

        L.CurrentTarget = L.StickyAimTarget
    end
end)

-- ─── input for aimbot keybind ─────────────────────────────────
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end

    local L = Config.Legit

    if input.KeyCode == L.AimbotKey then
        if L.AimbotEnabled then
            if L.KeyMode == "Toggle" then
                L.AimbotActive = not L.AimbotActive
            else
                L.AimbotActive = true
            end
        end
    end

    if input.KeyCode == L.CamLockKey then
        if L.CamLockEnabled then
            if L.CamLockKeyMode == "Toggle" then
                L.CamLockKeyActive = not L.CamLockKeyActive
            else
                L.CamLockKeyActive = true
            end
        end
    end

    if input.KeyCode == L.StickyAimKey then
        if L.StickyAimMode == "Toggle" then
            L.StickyAimActive = not L.StickyAimActive
            if L.StickyAimActive then
                local t = getLegitTarget()
                L.StickyAimTarget = t and t.player
            else
                L.StickyAimTarget = nil
            end
        else
            L.StickyAimActive = true
            local t = getLegitTarget()
            L.StickyAimTarget = t and t.player
        end
    end

    local sa = Config.SilentAim
    if input.KeyCode == sa.Keybind then
        if sa.KeybindMode == "Toggle" then
            sa.KeybindActive = not sa.KeybindActive
        elseif sa.KeybindMode == "Hold" then
            sa.KeybindActive = true
        end
    end
end)

UIS.InputEnded:Connect(function(input, gp)
    if gp then return end
    if not input.KeyCode then return end
    local L = Config.Legit
    if input.KeyCode == L.AimbotKey and L.KeyMode == "Hold" then
        L.AimbotActive = false
    end
    if input.KeyCode == L.CamLockKey and L.CamLockKeyMode == "Hold" then
        L.CamLockKeyActive = false
    end
    if input.KeyCode == L.StickyAimKey and L.StickyAimMode == "Hold" then
        L.StickyAimActive = false
        L.StickyAimTarget = nil
    end

    local sa = Config.SilentAim
    if input.KeyCode == sa.Keybind and sa.KeybindMode == "Hold" then
        sa.KeybindActive = false
    end
end)

-- ─── UI — Legit tab ───────────────────────────────────────────
local legitTab = window:AddTab({ Name = "Legit", Icon = "crosshairs" })

-- column 1: aimbot
local aimSec = legitTab:AddSection({ Name = "aimbot & silent", Position = "left" })
aimSec:AddLabel("aimbot"):AddToggle({
    Default = false, Flag = "Legit_AimbotEnabled",
    Callback = function(v)
        Config.Legit.AimbotEnabled = v
        if not v then Config.Legit.AimbotActive = false end
    end
})
aimSec:AddLabel("keybind"):AddKeybind({
    Default = "F", Flag = "Legit_AimbotKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Legit.AimbotKey = parsed end
    end
})
aimSec:AddLabel("mode"):AddDropdown({
    Default = "Hold", Values = { "Hold", "Toggle" },
    Flag = "Legit_KeyMode",
    Callback = function(v)
        Config.Legit.KeyMode = v
        Config.Legit.AimbotActive = false
    end
})
aimSec:AddLabel("hitpart"):AddDropdown({
    Default = "Head",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest Part" },
    Flag = "Legit_HitPart",
    Callback = function(v) Config.Legit.HitPart = v end
})
aimSec:AddLabel("smoothness"):AddSlider({
    Min = 1, Max = 30, Rounding = 0,
    Default = 5, Flag = "Legit_Smoothness",
    Callback = function(v) Config.Legit.Smoothness = v end
})
aimSec:AddLabel("prediction"):AddSlider({
    Min = 0.01, Max = 0.3, Rounding = 3,
    Default = 0.135, Flag = "Legit_Prediction",
    Callback = function(v) Config.Legit.Prediction = v end
})

-- column 2: checks
local checkSec = legitTab:AddSection({ Name = "checks", Position = "left" })
checkSec:AddLabel("wall check"):AddToggle({
    Default = true, Flag = "Legit_WallCheck",
    Callback = function(v) Config.Legit.WallCheck = v end
})
checkSec:AddLabel("forcefield check"):AddToggle({
    Default = true, Flag = "Legit_FFCheck",
    Callback = function(v) Config.Legit.ForceFieldCheck = v end
})
checkSec:AddLabel("death check"):AddToggle({
    Default = true, Flag = "Legit_DeathCheck",
    Callback = function(v) Config.Legit.DeathCheck = v end
})
checkSec:AddLabel("max range"):AddSlider({
    Min = 50, Max = 1000, Rounding = 0,
    Default = 250, Flag = "Legit_MaxDistance",
    Callback = function(v) Config.Legit.MaxDistance = v end
})

-- column 3: fov (shared — controls the single FOV circle)
local fovSec = legitTab:AddSection({ Name = "fov visualizer", Position = "right" })
fovSec:AddLabel("show fov circle"):AddToggle({
    Default = false, Flag = "Legit_FovVisible",
    Callback = function(v) Config.FovCircle.Visible = v end
})
fovSec:AddLabel("fov color"):AddColorPicker({
    Default = Color3.fromRGB(160, 32, 240),
    Flag = "Legit_FovColor",
    Callback = function(c) Config.FovCircle.Color = c end
})
fovSec:AddLabel("fov radius"):AddSlider({
    Min = 10, Max = 800, Rounding = 0,
    Default = 200, Flag = "Legit_FovRadius",
    Callback = function(v) Config.FovCircle.Radius = v end
})
fovSec:AddLabel("filled"):AddToggle({
    Default = false, Flag = "Legit_FovFilled",
    Callback = function(v) Config.FovCircle.Filled = v end
})
fovSec:AddLabel("opacity"):AddSlider({
    Min = 0.05, Max = 1, Rounding = 2,
    Default = 0.7, Flag = "Legit_FovTransparency",
    Callback = function(v) Config.FovCircle.Transparency = v end
})

-- column 4: sticky aim
local stickySec = legitTab:AddSection({ Name = "sticky aim", Position = "right" })
stickySec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "Legit_StickyEnabled",
    Callback = function(v)
        Config.Legit.StickyAimEnabled = v
        if not v then
            Config.Legit.StickyAimActive = false
            Config.Legit.StickyAimTarget = nil
        end
    end
})
stickySec:AddLabel("keybind"):AddKeybind({
    Default = "Q", Flag = "Legit_StickyKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Legit.StickyAimKey = parsed end
    end
})
stickySec:AddLabel("mode"):AddDropdown({
    Default = "Toggle", Values = { "Toggle", "Hold" },
    Flag = "Legit_StickyMode",
    Callback = function(v) Config.Legit.StickyAimMode = v end
})

-- column 5: camlock
local camSec = legitTab:AddSection({ Name = "camera lock", Position = "right" })
camSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "Legit_CamLockEnabled",
    Callback = function(v) Config.Legit.CamLockEnabled = v end
})
camSec:AddLabel("keybind"):AddKeybind({
    Default = "C", Flag = "Legit_CamLockKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Legit.CamLockKey = parsed end
    end
})
camSec:AddLabel("key mode"):AddDropdown({
    Default = "Toggle", Values = { "Toggle", "Hold", "Always" },
    Flag = "Legit_CamLockKeyMode",
    Callback = function(v) Config.Legit.CamLockKeyMode = v end
})
camSec:AddLabel("camlock part"):AddDropdown({
    Default = "Head",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Flag = "Legit_CamLockPart",
    Callback = function(v) Config.Legit.CamLockPart = v end
})
camSec:AddLabel("camlock smoothing"):AddSlider({
    Min = 1, Max = 50, Rounding = 0,
    Default = 40, Flag = "Legit_CamLockSmoothing",
    Callback = function(v) Config.Legit.CamLockSmoothing = v end
})
camSec:AddLabel("instant (no smoothing/pred)"):AddToggle({
    Default = false, Flag = "Legit_CamLockInstant",
    Callback = function(v) Config.Legit.CamLockInstant = v end
})

-- column 6: silent aim
local silentSec = legitTab:AddSection({ Name = "silent aim", Position = "right" })
silentSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "Ecco_SilentEnabled",
    Callback = function(v) Config.SilentAim.Enabled = v end
})
silentSec:AddLabel("hitpart"):AddDropdown({
    Default = "Head",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Flag = "Ecco_HitPart",
    Callback = function(v) Config.SilentAim.HitPart = v end
})
silentSec:AddLabel("closest part"):AddToggle({
    Default = false, Flag = "Ecco_ClosestPart",
    Callback = function(v) Config.SilentAim.ClosestPart = v end
})

silentSec:AddLabel("visible check (air bypass)"):AddToggle({
    Default = false, Flag = "Ecco_VisibleCheck",
    Callback = function(v) Config.SilentAim.VisibleCheck = v end
})
silentSec:AddLabel("max distance"):AddSlider({
    Min = 50, Max = 1000, Rounding = 0,
    Default = 500, Flag = "Ecco_MaxDistance",
    Callback = function(v) Config.SilentAim.MaxDistance = v end
})
silentSec:AddLabel("use prediction"):AddToggle({
    Default = true, Flag = "Ecco_UsePrediction",
    Callback = function(v) Config.SilentAim.UsePrediction = v end
})
silentSec:AddLabel("prediction"):AddSlider({
    Min = 0.01, Max = 0.4, Rounding = 3,
    Default = 0.135, Flag = "Ecco_Prediction",
    Callback = function(v) Config.SilentAim.Prediction = v end
})
silentSec:AddLabel("keybind"):AddKeybind({
    Default = "X", Flag = "Ecco_SilentKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.SilentAim.Keybind = parsed end
    end
})
silentSec:AddLabel("key mode"):AddDropdown({
    Default = "Toggle", Values = { "Toggle", "Hold", "Always" },
    Flag = "Ecco_SilentKeyMode",
    Callback = function(v) Config.SilentAim.KeybindMode = v end
})

-- column 7: wallbang
local wbSec = legitTab:AddSection({ Name = "wallbang", Position = "right" })
wbSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "Exo_Wallbang",
    Callback = function(v) Config.Wallbang.Enabled = v end
})
wbSec:AddLabel("hitpart"):AddDropdown({
    Default = "Head",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Flag = "Exo_WallbangHitPart",
    Callback = function(v) Config.Wallbang.HitPart = v end
})
wbSec:AddLabel("use prediction"):AddToggle({
    Default = true, Flag = "Exo_WallbangPred",
    Callback = function(v) Config.Wallbang.UsePrediction = v end
})
wbSec:AddLabel("prediction"):AddSlider({
    Min = 0.01, Max = 0.4, Rounding = 3,
    Default = 0.135, Flag = "Exo_WallbangPredAmount",
    Callback = function(v) Config.Wallbang.Prediction = v end
})
wbSec:AddLabel("spread enabled"):AddToggle({
    Default = false, Flag = "Exo_SpreadEnabled",
    Callback = function(v) Config.Spread.Enabled = v end
})
wbSec:AddLabel("spread %"):AddSlider({
    Min = 0, Max = 100, Rounding = 0,
    Default = 0, Flag = "Exo_SpreadAmount",
    Callback = function(v) Config.Spread.Amount = math.clamp(v, 0, 100) end
})

-- (spread moved into the wallbang section spread)
print("[EXO UNIFIED] loaded — legit tab.")
-- ═══════════════════════════════════════════════════════════════
--  COMBAT TAB  — forcehit / target strafe / kill aura
-- ═══════════════════════════════════════════════════════════════
window = getgenv().window
if not window then
    warn("[EXO UNIFIED] no window — chunk 4 skipped")
    return
end

-- ─── ForceHit state ───────────────────────────────────────────
Config.ForceHit = {
    Enabled            = false,
    Active             = false,
    Key                = Enum.KeyCode.C,
    UseMaxDistance     = true,
    MaxDistance        = 250,
    HitPart            = "Head",
    Whitelist          = {},
    WallCheck          = false,
    ForceFieldCheck    = true,
    DeathCheck         = true,
    AutoClosestTarget  = false,
    ClosestMaxDistance = 50,
    ShowTargetLine     = true,
    LineColor          = Color3.fromRGB(255, 255, 255),
    LineThickness      = 2,
    LineTransparency   = 0,
    Target             = nil,
    LastShotTime       = 0,
    ShotCooldown       = 0,

    -- rage camlock
    RageCamLock            = false,
    RageCamLockInstant     = false,
    RageCamLockPart        = "Head",
    RageCamLockSmoothing   = 40,
    RageCamLockPrediction  = 0.135,

    -- strafe (larptic full port)
    StrafeArmed       = false,
    StrafeEnabled     = false,
    StrafeKey         = Enum.KeyCode.N,
    StrafeSpeed       = 5,
    StrafeDistance    = 8,
    StrafeHeight      = 0,
    StrafeMode        = "Orbit",
    StrafeSpoof       = false,
    VisualizeStrafe   = false,
    StrafeConnection  = nil,
    CurrentStrafeCF   = nil,

    -- larptic extras
    LookAtTarget       = false,
    SpectateTarget     = false,
    SpectateStrafe     = false,
    VoidTime           = 0.4,
    GroundTime         = 0.133,
    StompTargetEnabled = false,

    -- strafe visualizer state
    StrafeVisConnection = nil,
    StrafeVisParts      = nil,

    -- auto fire (rapid-fire pattern)
    AutoFireEnabled = false,
    AutoFireHeld    = true,

    -- target lock — when set, every ragebot subsystem rides this player
    LockedTarget = nil,
    TargetLocked = false
}

-- desync backdrop part used by strafe-spoof and glue
Config.DesyncPart = Instance.new("Part")
Config.DesyncPart.Name = "desyncvisual"
Config.DesyncPart.Size = Vector3.new(2, 2, 1)
Config.DesyncPart.Transparency = 1
Config.DesyncPart.CanCollide = false
Config.DesyncPart.Anchored = true
Config.DesyncPart.Parent = workspace

-- ─── Kill Aura state ──────────────────────────────────────────
Config.KillAura = {
    Enabled   = false,
    Range     = 50,
    HitPart   = "Head",
    Delay     = 0.1,
    WallCheck = false,
    FFCheck   = true,
    DeathCheck = true,
    Whitelist = {},
    StrafeWithAura  = false,
    ApplyForceHitVisuals = false,
    CurrentTarget = nil
}

-- ─── wallbang fire helper (used by forcehit and kill aura) ───
local function fireGunHandler(targetPlayer)
    local GH = getgenv().ExoInternal and getgenv().ExoInternal.GunHandler
    if not GH then return false end
    if not targetPlayer or not targetPlayer.Character then return false end

    local part = targetPlayer.Character:FindFirstChild(Config.ForceHit.HitPart)
        or targetPlayer.Character:FindFirstChild("Head")
    if not part then return false end

    local hitPos = part.Position
    local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
    if Config.SilentAim.UsePrediction then
        hitPos = hitPos + vel * Config.SilentAim.Prediction
    end

    pcall(function()
        GH.Shoot({
            AimPosition = hitPos,
            Hit         = part,
            Normal      = Vector3.new(0, 1, 0)
        })
    end)
    return true
end

-- ─── whitelist check ──────────────────────────────────────────
local function isWhitelisted(plr, list)
    if not list then return false end
    if list[plr.Name] then return true end
    for k, v in pairs(list) do
        if v and tostring(k):find("@" .. plr.Name) then return true end
    end
    return false
end

-- ─── closest-to-character target finder ───────────────────────
local function getClosestToCharacter()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local maxDist = Config.ForceHit.ClosestMaxDistance or 50
    local best, bestDist = nil, maxDist

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer
           and plr.Character
           and not isWhitelisted(plr, Config.ForceHit.Whitelist)
           and not isPlayerKnocked(plr) then

            local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if thrp then
                local d = (hrp.Position - thrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = plr
                end
            end
        end
    end
    return best
end

getgenv().ExoInternal.getClosestToCharacter = getClosestToCharacter

-- ─── forcehit auto-fire loop ──────────────────────────────────
task.spawn(function()
    while task.wait(0.05) do
        if Config.Unloaded then break end
        if not Config.ForceHit.Enabled or not Config.ForceHit.Active then
            continue
        end

        local FH = Config.ForceHit
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then continue end

        if FH.AutoClosestTarget then
            FH.Target = getClosestToCharacter()
        end

        local target = FH.Target
        if not target or not target.Character then continue end
        if isWhitelisted(target, FH.Whitelist) then
            FH.Target = nil
            continue
        end
        if FH.DeathCheck and isPlayerKnocked(target) then continue end

        local ff = target.Character:FindFirstChildOfClass("ForceField")
        if FH.ForceFieldCheck and ff then continue end

        if FH.UseMaxDistance then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local thrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and thrp and (hrp.Position - thrp.Position).Magnitude > FH.MaxDistance then
                continue
            end
        end

        if tick() - FH.LastShotTime < FH.ShotCooldown then continue end

        if fireGunHandler(target) then
            FH.LastShotTime = tick()
        end
    end
end)

-- ─── target line visuals ──────────────────────────────────────
Config.TargetLine = Drawing.new("Line")
Config.TargetLine.Thickness = 2
Config.TargetLine.Visible = false

Config.TargetLineOutline = Drawing.new("Line")
Config.TargetLineOutline.Thickness = 3.5
Config.TargetLineOutline.Color = Color3.new(0, 0, 0)
Config.TargetLineOutline.Visible = false

RunService.RenderStepped:Connect(function()
    if Config.Unloaded then return end
    local FH = Config.ForceHit
    if not (FH.ShowTargetLine and FH.Enabled and FH.Active and FH.Target) then
        Config.TargetLine.Visible = false
        Config.TargetLineOutline.Visible = false
        return
    end

    local char = FH.Target.Character
    if not char then
        Config.TargetLine.Visible = false
        Config.TargetLineOutline.Visible = false
        return
    end

    local part = char:FindFirstChild(FH.HitPart) or char:FindFirstChild("Head")
    if not part then
        Config.TargetLine.Visible = false
        Config.TargetLineOutline.Visible = false
        return
    end

    local from = UIS:GetMouseLocation()
    local to, on = Camera:WorldToViewportPoint(part.Position)

    if on then
        local toVec = Vector2.new(to.X, to.Y)
        local alpha = 1 - FH.LineTransparency

        Config.TargetLineOutline.From = from
        Config.TargetLineOutline.To   = toVec
        Config.TargetLineOutline.Transparency = alpha
        Config.TargetLineOutline.Visible = true

        Config.TargetLine.From = from
        Config.TargetLine.To   = toVec
        Config.TargetLine.Color = FH.LineColor
        Config.TargetLine.Thickness = FH.LineThickness
        Config.TargetLine.Transparency = alpha
        Config.TargetLine.Visible = true
    else
        Config.TargetLine.Visible = false
        Config.TargetLineOutline.Visible = false
    end
end)

-- ─── rage camlock ─────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if Config.Unloaded then return end
    local FH = Config.ForceHit
    if not FH.RageCamLock then return end
    if not FH.Enabled or not FH.Active then return end

    local target = FH.Target
    if not target or not target.Character then return end

    local part = target.Character:FindFirstChild(FH.RageCamLockPart)
        or target.Character:FindFirstChild("Head")
    if not part then return end

    if FH.RageCamLockInstant then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    else
        local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
        local aimPos = part.Position + vel * FH.RageCamLockPrediction
        local desired = CFrame.new(Camera.CFrame.Position, aimPos)

        local alpha = math.clamp(1 / FH.RageCamLockSmoothing, 0, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  TARGET STRAFE
-- ═══════════════════════════════════════════════════════════════

getgenv().strafeCamera = workspace.CurrentCamera
getgenv().resetStrafeCamera = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then getgenv().strafeCamera.CameraSubject = hum end
end

getgenv().destroyStrafeVisualizer = function()
    if Config.ForceHit.StrafeVisConnection then
        Config.ForceHit.StrafeVisConnection:Disconnect()
        Config.ForceHit.StrafeVisConnection = nil
    end
    if Config.ForceHit.StrafeVisParts then
        for _, v in pairs(Config.ForceHit.StrafeVisParts) do
            if v.part then v.part:Destroy() end
        end
        Config.ForceHit.StrafeVisParts = nil
    end
end

getgenv().createStrafeVisualizer = function()
    getgenv().destroyStrafeVisualizer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local parts = {}
    Config.ForceHit.StrafeVisParts = parts

    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            local ghost = Instance.new("Part")
            ghost.Name = p.Name .. "_strafeghost"
            ghost.Size = p.Size
            ghost.Anchored = true
            ghost.CanCollide = false
            ghost.CastShadow = false
            ghost.Material = Enum.Material.Neon
            ghost.Color = Color3.fromRGB(255, 255, 255)
            ghost.Transparency = 0.4
            ghost.Parent = getgenv().strafeCamera
            parts[p.Name] = {
                part = ghost,
                offset = hrp.CFrame:Inverse() * p.CFrame,
                currentCF = ghost.CFrame
            }
        end
    end

    local alpha = 0.18
    Config.ForceHit.CurrentStrafeCF = hrp.CFrame
    Config.ForceHit.StrafeVisConnection =
        RunService.RenderStepped:Connect(function()
            local cf = Config.ForceHit.CurrentStrafeCF
            if not cf then return end
            for _, entry in pairs(parts) do
                local target = cf * entry.offset
                entry.currentCF = entry.currentCF:Lerp(target, alpha)
                entry.part.CFrame = entry.currentCF
            end
        end)
end

getgenv().SpectateConnection = nil
getgenv().updateSpectate = function(state)
    Config.ForceHit.SpectateTarget = state
    if getgenv().SpectateConnection then
        getgenv().SpectateConnection:Disconnect()
        getgenv().SpectateConnection = nil
    end
    if state then
        getgenv().SpectateConnection = RunService.RenderStepped:Connect(function()
            local target = Config.ForceHit.Target
            local cam = workspace.CurrentCamera
            local char = target and target.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and cam.CameraSubject ~= hum then cam.CameraSubject = hum end
            else
                local myChar = LocalPlayer.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if myHum and cam.CameraSubject ~= myHum then cam.CameraSubject = myHum end
            end
        end)
    else
        getgenv().resetStrafeCamera()
    end
end

getgenv().stopStrafe = function()
    if Config.ForceHit.StrafeConnection then
        Config.ForceHit.StrafeConnection:Disconnect()
        Config.ForceHit.StrafeConnection = nil
    end
    getgenv().destroyStrafeVisualizer()
    getgenv().resetStrafeCamera()
    Config.ForceHit.LookAtTarget = false
end

getgenv().startStrafe = function()
    if Config.ForceHit.StrafeConnection then
        Config.ForceHit.StrafeConnection:Disconnect()
        Config.ForceHit.StrafeConnection = nil
    end

    if Config.ForceHit.VisualizeStrafe then
        getgenv().createStrafeVisualizer()
    end

    Config.ForceHit.LookAtTarget = false

    local elapsed, voided, voidTimer = 0, false, 0

    Config.ForceHit.StrafeConnection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt

        if not Config.ForceHit.StrafeEnabled or not Config.ForceHit.Target then
            getgenv().stopStrafe()
            return
        end

        local myChar = LocalPlayer.Character
        local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local tchar  = Config.ForceHit.Target.Character
        local thrp   = tchar and tchar:FindFirstChild("HumanoidRootPart")
        local thum   = tchar and tchar:FindFirstChildWhichIsA("Humanoid")
        local be     = tchar and tchar:FindFirstChild("BodyEffects")

        local dead = false
        if be then
            local ko = be:FindFirstChild("K.O") or be:FindFirstChild("KO")
            local sd = be:FindFirstChild("Dead") or be:FindFirstChild("SDeath")
            dead = (ko and ko.Value) or (sd and sd.Value)
        end

        if not (myHrp and thrp and thum and thum.Health > 0) or dead then
            getgenv().stopStrafe()
            return
        end

        local origin = thrp.Position
        local newCF

        local mode = Config.ForceHit.StrafeMode
        if mode == "Orbit" then
            local angle = elapsed * (Config.ForceHit.StrafeSpeed or 5)
            newCF = CFrame.lookAt(
                origin + Vector3.new(
                    math.cos(angle) * (Config.ForceHit.StrafeDistance or 8),
                    Config.ForceHit.StrafeHeight or 0,
                    math.sin(angle) * (Config.ForceHit.StrafeDistance or 8)
                ),
                origin
            )
        elseif mode == "Random" then
            local f = elapsed * (Config.ForceHit.StrafeSpeed or 5) * 1.2
            local dist = Config.ForceHit.StrafeDistance or 8
            newCF = CFrame.lookAt(
                origin + Vector3.new(
                    math.noise(f, 0, 0) * dist,
                    math.noise(0, f, 0) * (dist * 0.5) + (Config.ForceHit.StrafeHeight or 0),
                    math.noise(0, 0, f) * dist
                ),
                origin
            )
        elseif mode == "Far Random" then
            local f = elapsed * (Config.ForceHit.StrafeSpeed or 5) * 0.9
            local dist = (Config.ForceHit.StrafeDistance or 8) * 5.5
            newCF = CFrame.lookAt(
                origin + Vector3.new(
                    math.noise(f, 0, 0) * dist,
                    math.noise(0, f, 0) * (dist * 0.4) + (Config.ForceHit.StrafeHeight or 0),
                    math.noise(0, 0, f) * dist
                ),
                origin
            )
        elseif mode == "Void Shoot" then
            voidTimer += dt
            local justFired = tick() - (Config.ForceHit.LastShotTime or 0) < 0.12
            if justFired then
                voided, voidTimer = false, 0
                newCF = CFrame.lookAt(origin + Vector3.new(0, 200, 2), origin)
            else
                local toggled = voidTimer >= (Config.ForceHit.VoidTime or 0.4)
                if toggled then voided, voidTimer = not voided, 0 end
                if voided then
                    newCF = CFrame.new(origin + Vector3.new(0, 10000, 0))
                else
                    newCF = CFrame.lookAt(origin + Vector3.new(0, 3, 2), origin)
                end
            end
        else
            newCF = CFrame.lookAt(origin + Vector3.new(0, 3, 2), origin)
        end

        if not newCF then return end

        if Config.ForceHit.VisualizeStrafe then
            Config.ForceHit.CurrentStrafeCF = newCF
        end

        if Config.ForceHit.StrafeSpoof then
            local saved = myHrp.CFrame
            if Config.DesyncPart then
                Config.DesyncPart.CFrame = saved + Vector3.new(0, 5, 0)
                getgenv().strafeCamera.CameraSubject = Config.DesyncPart
            end
            if myHrp.AssemblyLinearVelocity.Magnitude < 0.1 then
                myHrp.AssemblyLinearVelocity = Vector3.new(0, 0.05, 0)
            end
            myHrp.CFrame = newCF
            RunService.RenderStepped:Wait()
            myHrp.CFrame = saved
            getgenv().resetStrafeCamera()
        else
            myHrp.CFrame = newCF
            if not Config.ForceHit.SpectateTarget then
                local head = tchar:FindFirstChild("Head") or thrp
                local myHum = myChar:FindFirstChildWhichIsA("Humanoid")
                getgenv().strafeCamera.CameraSubject =
                    Config.ForceHit.SpectateStrafe and head or myHum
            end
        end
    end)
end

task.spawn(function()
    while task.wait(0.05) do
        if Config.Unloaded then break end
        local FH = Config.ForceHit
        local live = FH.StrafeEnabled
            and FH.Target
            and FH.Target.Character
            and FH.Target.Character:FindFirstChild("HumanoidRootPart")

        if live then
            if not FH.StrafeConnection then getgenv().startStrafe() end
        else
            if FH.StrafeConnection then getgenv().stopStrafe() end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  AUTO FIRE  (rapid-fire pattern, fires while strafing)
-- ═══════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if Config.Unloaded then return end
    local FH = Config.ForceHit
    if not FH.AutoFireEnabled then return end
    if not FH.AutoFireHeld then return end
    if not FH.Enabled or not FH.Active then return end
    if not FH.StrafeEnabled then return end
    if not FH.Target or not FH.Target.Character then return end
    if isSelfKnocked() then return end

    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local cd = tool:FindFirstChild("ShootingCooldown")
    if cd and cd:IsA("NumberValue") then cd.Value = 0 end
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():find("cool") then
            v.Value = 0
        end
        if v:IsA("BoolValue") and v.Name:lower():find("fire") then
            v.Value = false
        end
    end

    pcall(function() tool:Activate() end)

    if fireGunHandler then
        pcall(fireGunHandler, FH.Target)
    end
end)

-- ─── kill aura ────────────────────────────────────────────────
task.spawn(function()
    while task.wait() do
        if Config.Unloaded then break end
        local KA = Config.KillAura
        if not KA.Enabled then
            KA.CurrentTarget = nil
            task.wait(0.1)
            continue
        end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local tool = char and char:FindFirstChildOfClass("Tool")

        if not (hrp and hum and hum.Health > 0 and tool) then
            KA.CurrentTarget = nil
            continue
        end

        local found = false
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            if isWhitelisted(plr, KA.Whitelist) then continue end

            local tchar = plr.Character
            if not tchar then continue end

            local thum = tchar:FindFirstChildOfClass("Humanoid")
            if not thum or thum.Health <= 0 then continue end

            if KA.DeathCheck and isPlayerKnocked(plr) then continue end

            local ff = tchar:FindFirstChildOfClass("ForceField")
            if KA.FFCheck and ff then continue end

            local part = tchar:FindFirstChild(KA.HitPart) or tchar:FindFirstChild("Head")
            if not part then continue end

            if (hrp.Position - part.Position).Magnitude > KA.Range then continue end

            KA.CurrentTarget = plr
            fireGunHandler(plr)
            found = true
            task.wait(KA.Delay)
            break
        end

        if not found then KA.CurrentTarget = nil end
    end
end)

-- ─── combat input: forcehit toggle key ────────────────────────
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end

    local FH = Config.ForceHit

    if input.KeyCode == FH.Key then
        if FH.Enabled then
            FH.Active = not FH.Active
            if FH.Active then
                if not (FH.Target and FH.Target.Parent) then
                    FH.Target = getClosestToCharacter()
                end
            else
                FH.Target = nil
                Config.TargetLine.Visible = false
            end
        end
    end

    if input.KeyCode == FH.StrafeKey then
        if FH.Enabled and FH.StrafeArmed then
            FH.StrafeEnabled = not FH.StrafeEnabled
        end
    end
end)

-- UI — Combat tab
local combatTab = window:AddTab({ Name = "Combat", Icon = "crosshairs" })
local forceSub  = combatTab:AddSubTab({ Name = "Forcehit",  Icon = "bullseye" })
local strafeSub = combatTab:AddSubTab({ Name = "Strafe",    Icon = "person-running" })
local auraSub   = combatTab:AddSubTab({ Name = "Kill Aura", Icon = "burst" })

-- Forcehit — column 1
local fhEnable = forceSub:AddSection({ Name = "forcehit", Position = "left" })
fhEnable:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "FH_Enabled",
    Callback = function(v)
        Config.ForceHit.Enabled = v
        if not v then
            Config.ForceHit.Active = false
            Config.ForceHit.Target = nil
        end
    end
})
fhEnable:AddLabel("keybind"):AddKeybind({
    Default = "C", Flag = "FH_Keybind",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.ForceHit.Key = parsed end
    end
})
fhEnable:AddLabel("auto closest"):AddToggle({
    Default = false, Flag = "FH_AutoClosest",
    Callback = function(v) Config.ForceHit.AutoClosestTarget = v end
})
fhEnable:AddLabel("closest range"):AddSlider({
    Min = 5, Max = 500, Rounding = 0,
    Default = 50, Flag = "FH_ClosestRange",
    Callback = function(v) Config.ForceHit.ClosestMaxDistance = v end
})
fhEnable:AddLabel("hitpart"):AddDropdown({
    Default = "Head",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Flag = "FH_HitPart",
    Callback = function(v) Config.ForceHit.HitPart = v end
})

-- Forcehit — column 2
local fhChecks = forceSub:AddSection({ Name = "checks", Position = "left" })
fhChecks:AddLabel("wall check"):AddToggle({
    Default = false, Flag = "FH_WallCheck",
    Callback = function(v) Config.ForceHit.WallCheck = v end
})
fhChecks:AddLabel("forcefield check"):AddToggle({
    Default = true, Flag = "FH_FFCheck",
    Callback = function(v) Config.ForceHit.ForceFieldCheck = v end
})
fhChecks:AddLabel("death check"):AddToggle({
    Default = true, Flag = "FH_DeathCheck",
    Callback = function(v) Config.ForceHit.DeathCheck = v end
})
fhChecks:AddLabel("use max distance"):AddToggle({
    Default = true, Flag = "FH_UseMaxDistance",
    Callback = function(v) Config.ForceHit.UseMaxDistance = v end
})
fhChecks:AddLabel("max range"):AddSlider({
    Min = 10, Max = 500, Rounding = 0,
    Default = 250, Flag = "FH_MaxDistance",
    Callback = function(v) Config.ForceHit.MaxDistance = v end
})

-- Forcehit — column 3 (visuals)
local fhVisual = forceSub:AddSection({ Name = "target visuals", Position = "right" })
fhVisual:AddLabel("target line"):AddToggle({
    Default = true, Flag = "FH_TargetLine",
    Callback = function(v) Config.ForceHit.ShowTargetLine = v end
})
fhVisual:AddLabel("line color"):AddColorPicker({
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "FH_LineColor",
    Callback = function(c) Config.ForceHit.LineColor = c end
})
fhVisual:AddLabel("line thickness"):AddSlider({
    Min = 1, Max = 5, Rounding = 0,
    Default = 2, Flag = "FH_LineThickness",
    Callback = function(v) Config.ForceHit.LineThickness = v end
})
fhVisual:AddLabel("line transparency"):AddSlider({
    Min = 0, Max = 1, Rounding = 2,
    Default = 0, Flag = "FH_LineTransparency",
    Callback = function(v) Config.ForceHit.LineTransparency = v end
})

-- Rage camlock — column 4
local rageCamSec = forceSub:AddSection({ Name = "rage camlock", Position = "right" })
rageCamSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "FH_RageCamLock",
    Callback = function(v) Config.ForceHit.RageCamLock = v end
})
rageCamSec:AddLabel("instant (no smoothing/pred)"):AddToggle({
    Default = false, Flag = "FH_RageCamLockInstant",
    Callback = function(v) Config.ForceHit.RageCamLockInstant = v end
})
rageCamSec:AddLabel("part"):AddDropdown({
    Default = "Head",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Flag = "FH_RageCamLockPart",
    Callback = function(v) Config.ForceHit.RageCamLockPart = v end
})
rageCamSec:AddLabel("smoothing"):AddSlider({
    Min = 1, Max = 50, Rounding = 0,
    Default = 40, Flag = "FH_RageCamLockSmoothing",
    Callback = function(v) Config.ForceHit.RageCamLockSmoothing = v end
})
rageCamSec:AddLabel("prediction"):AddSlider({
    Min = 0, Max = 0.4, Rounding = 3,
    Default = 0.135, Flag = "FH_RageCamLockPred",
    Callback = function(v) Config.ForceHit.RageCamLockPrediction = v end
})

-- Strafe — column 1
local strafeSec = strafeSub:AddSection({ Name = "target strafe", Position = "left" })
strafeSec:AddLabel("enable strafe"):AddToggle({
    Default = false, Flag = "FH_StrafeArmed",
    Callback = function(v)
        Config.ForceHit.StrafeArmed = v
        Config.ForceHit.StrafeEnabled = v
        if not v then getgenv().stopStrafe() end
    end
})
strafeSec:AddLabel("keybind"):AddKeybind({
    Default = "N", Flag = "FH_StrafeKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.ForceHit.StrafeKey = parsed end
    end
})
strafeSec:AddLabel("mode"):AddDropdown({
    Default = "Orbit", Values = { "Orbit", "Random", "Far Random", "Void Shoot" },
    Flag = "FH_StrafeMode",
    Callback = function(v) Config.ForceHit.StrafeMode = v end
})
strafeSec:AddLabel("speed"):AddSlider({
    Min = 1, Max = 30, Rounding = 1,
    Default = 5, Flag = "FH_StrafeSpeed",
    Callback = function(v) Config.ForceHit.StrafeSpeed = v end
})
strafeSec:AddLabel("distance"):AddSlider({
    Min = 1, Max = 20, Rounding = 1,
    Default = 8, Flag = "FH_StrafeDistance",
    Callback = function(v) Config.ForceHit.StrafeDistance = v end
})
strafeSec:AddLabel("height"):AddSlider({
    Min = -15, Max = 15, Rounding = 1,
    Default = 0, Flag = "FH_StrafeHeight",
    Callback = function(v) Config.ForceHit.StrafeHeight = v end
})

-- Strafe — column 2 (spoofing + extras)
local strafeSpoof = strafeSub:AddSection({ Name = "spoofing", Position = "left" })
strafeSpoof:AddLabel("spoof"):AddToggle({
    Default = false, Flag = "FH_StrafeSpoof",
    Callback = function(v)
        Config.ForceHit.StrafeSpoof = v
        if not v then getgenv().resetStrafeCamera() end
    end
})
strafeSpoof:AddLabel("look at target"):AddToggle({
    Default = false, Flag = "FH_LookAtTarget",
    Callback = function(v) Config.ForceHit.LookAtTarget = v end
})
strafeSpoof:AddLabel("spectate target"):AddToggle({
    Default = false, Flag = "FH_SpectateTarget",
    Callback = function(v) getgenv().updateSpectate(v) end
})
strafeSpoof:AddLabel("spectate strafe"):AddToggle({
    Default = false, Flag = "FH_SpectateStrafe",
    Callback = function(v) Config.ForceHit.SpectateStrafe = v end
})

-- Strafe — column 3 (auto fire + extras)
local strafeExtra = strafeSub:AddSection({ Name = "auto fire", Position = "right" })
strafeExtra:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "FH_AutoFire",
    Callback = function(v) Config.ForceHit.AutoFireEnabled = v end
})
strafeExtra:AddLabel("held"):AddToggle({
    Default = true, Flag = "FH_AutoFireHeld",
    Callback = function(v) Config.ForceHit.AutoFireHeld = v end
})
strafeExtra:AddLabel("visualize strafe"):AddToggle({
    Default = false, Flag = "FH_VisualizeStrafe",
    Callback = function(v)
        Config.ForceHit.VisualizeStrafe = v
        if not v then getgenv().destroyStrafeVisualizer() end    end
})
strafeExtra:AddLabel("stomp knocked target"):AddToggle({
    Default = false, Flag = "FH_StompTarget",
    Callback = function(v) Config.ForceHit.StompTargetEnabled = v end
})
strafeExtra:AddLabel("void time"):AddSlider({
    Min = 0.05, Max = 2, Rounding = 2,
    Default = 0.4, Flag = "FH_VoidTime",
    Callback = function(v) Config.ForceHit.VoidTime = v end
})
strafeExtra:AddLabel("ground time"):AddSlider({
    Min = 0.05, Max = 2, Rounding = 2,
    Default = 0.133, Flag = "FH_GroundTime",
    Callback = function(v) Config.ForceHit.GroundTime = v end
})

-- Kill aura
local kaSec = auraSub:AddSection({ Name = "kill aura", Position = "left" })
kaSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "KA_Enabled",
    Callback = function(v) Config.KillAura.Enabled = v end
})
kaSec:AddLabel("range"):AddSlider({
    Min = 5, Max = 250, Rounding = 0,
    Default = 50, Flag = "KA_Range",
    Callback = function(v) Config.KillAura.Range = v end
})
kaSec:AddLabel("hitpart"):AddDropdown({
    Default = "Head",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Flag = "KA_HitPart",
    Callback = function(v) Config.KillAura.HitPart = v end
})
kaSec:AddLabel("delay"):AddSlider({
    Min = 0.01, Max = 1, Rounding = 2,
    Default = 0.1, Flag = "KA_Delay",
    Callback = function(v) Config.KillAura.Delay = v end
})

local kaChecks = auraSub:AddSection({ Name = "aura checks", Position = "right" })
kaChecks:AddLabel("wall check"):AddToggle({
    Default = false, Flag = "KA_WallCheck",
    Callback = function(v) Config.KillAura.WallCheck = v end
})
kaChecks:AddLabel("forcefield check"):AddToggle({
    Default = true, Flag = "KA_FFCheck",
    Callback = function(v) Config.KillAura.FFCheck = v end
})
kaChecks:AddLabel("death check"):AddToggle({
    Default = true, Flag = "KA_DeathCheck",
    Callback = function(v) Config.KillAura.DeathCheck = v end
})

print("[EXO UNIFIED] loaded — combat tab.")
-- ═══════════════════════════════════════════════════════════════
--  KNIFEBOT / GLUE
-- ═══════════════════════════════════════════════════════════════
window = getgenv().window
if not window then
    warn("[EXO UNIFIED] no window — chunk 5 skipped")
    return
end

-- ─── Knifebot state ───────────────────────────────────────────
Config.Knifebot = {
    HitboxEnabled   = false,
    HitboxX         = 21,
    HitboxY         = 21,
    HitboxZ         = 21,
    AutoKnife       = false,
    AutoKnifeConn   = nil,
    HoldGunAndKnife = false,
    SelectedGun     = "[Revolver]"
}

-- ─── Glue state ───────────────────────────────────────────────
Config.Glue = {
    Enabled        = false,
    Active         = false,
    Key            = Enum.KeyCode.G,
    AttachPosition = "Back",
    AttachDistance = 3,
    StrafeOffset   = 3,
    TargetPlayers  = {},
    MaxDistance    = 100,
    Spoof          = false,
    StompGlue      = false,
    Loop           = nil
}

getgenv().ExoInternal = getgenv().ExoInternal or {}

-- ═══════════════════════════════════════════════════════════════
--  KNIFEBOT — hitbox expander + auto swing
-- ═══════════════════════════════════════════════════════════════

local function applyKnifeHitbox()
    local KB = Config.Knifebot
    if not KB.HitboxEnabled then return end

    local char = LocalPlayer.Character
    local knife = char and char:FindFirstChild("[Knife]")
    local handle = knife and knife:FindFirstChild("Handle")
    local hbPart = handle and (handle:FindFirstChild("HITBOX_PART") or handle)
    if hbPart then
        hbPart.Size = Vector3.new(KB.HitboxX, KB.HitboxY, KB.HitboxZ)
        hbPart.Transparency = 0.99
        hbPart.Massless = true
        hbPart.CanCollide = false
        hbPart.CastShadow = false
    end
end

task.spawn(function()
    while task.wait(0.03) do
        if Config.Unloaded then break end
        pcall(applyKnifeHitbox)
    end
end)

-- auto knife swing
getgenv().ExoInternal.startAutoKnife = function()
    local KB = Config.Knifebot
    if KB.AutoKnifeConn then
        KB.AutoKnifeConn:Disconnect()
        KB.AutoKnifeConn = nil
    end

    KB.AutoKnifeConn = RunService.Heartbeat:Connect(function()
        if Config.Unloaded then return end
        if not KB.AutoKnife then
            if KB.AutoKnifeConn then
                KB.AutoKnifeConn:Disconnect()
                KB.AutoKnifeConn = nil
            end
            return
        end
        if isSelfKnocked() then return end
        if not Config.Glue.Active then return end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end

        local knife = char:FindFirstChild("[Knife]")
        if not knife then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            local backpackKnife = bp and bp:FindFirstChild("[Knife]")
            if backpackKnife then
                backpackKnife.Parent = char
                knife = backpackKnife
            end
        end
        if not knife then return end

        pcall(function() knife:Activate() end)
    end)
end

-- hold gun + knife
task.spawn(function()
    while task.wait(0.1) do
        if Config.Unloaded then break end
        local KB = Config.Knifebot
        if not KB.HoldGunAndKnife then continue end

        local char = LocalPlayer.Character
        local bp   = LocalPlayer:FindFirstChild("Backpack")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and bp and hum and hum.Health > 0) then continue end

        local gunName = KB.SelectedGun
        local gun   = char:FindFirstChild(gunName) or bp:FindFirstChild(gunName)
        local knife = char:FindFirstChild("[Knife]") or bp:FindFirstChild("[Knife]")

        if gun and gun.Parent == bp then
            hum:EquipTool(gun)
        end
        if knife and knife.Parent == bp then
            knife.Parent = char
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  GLUE — attach to target player
-- ═══════════════════════════════════════════════════════════════

local function getGlueTargetRoot()
    local G = Config.Glue
    for _, name in ipairs(G.TargetPlayers) do
        local plr = Players:FindFirstChild(name)
        if plr and plr.Character then
            local part = plr.Character:FindFirstChild("HumanoidRootPart")
            if part then return part end
        end
    end
    if Config.ForceHit.Target and Config.ForceHit.Target.Character then
        return Config.ForceHit.Target.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getLocalRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function computeGlueOffset()
    local G = Config.Glue
    local d = G.AttachDistance
    local pos = G.AttachPosition
    if pos == "Back"       then return CFrame.new(0, 0, d) end
    if pos == "Front"      then return CFrame.new(0, 0, -d) end
    if pos == "Left Side"  then return CFrame.new(-d, 0, 0) end
    if pos == "Right Side" then return CFrame.new(d, 0, 0) end
    if pos == "Random" then
        local r = math.rad(math.random(0, 360))
        return CFrame.new(math.cos(r) * d, 0, math.sin(r) * d)
    end
    return CFrame.new(0, 0, d)
end

getgenv().ExoInternal.stopGlue = function()
    local G = Config.Glue
    if G.Loop then
        G.Loop:Disconnect()
        G.Loop = nil
    end
    local hrp = getLocalRoot()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

getgenv().ExoInternal.startGlue = function()
    local G = Config.Glue
    if G.Loop then
        G.Loop:Disconnect()
        G.Loop = nil
    end

    G.Loop = RunService.Heartbeat:Connect(function()
        if Config.Unloaded then return end
        if not G.Active then
            getgenv().ExoInternal.stopGlue()
            return
        end

        local hrp  = getLocalRoot()
        local thrp = getGlueTargetRoot()

        if not hrp or not thrp then return end

        local target = thrp.CFrame * computeGlueOffset()

        if G.Spoof then
            local saved = hrp.CFrame
            hrp.CFrame = target
            RunService.RenderStepped:Wait()
            hrp.CFrame = saved
        else
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = target
        end
    end)
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
    local G = Config.Glue
    if input.KeyCode == G.Key then
        if not G.Enabled then return end
        G.Active = not G.Active
        if G.Active then
            getgenv().ExoInternal.startGlue()
        else
            getgenv().ExoInternal.stopGlue()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  UI — KnifeBot tab
-- ═══════════════════════════════════════════════════════════════
local knifeTab = window:AddTab({ Name = "KnifeBot", Icon = "utensils" })

-- Knifebot
local knSec = knifeTab:AddSection({ Name = "knifebot", Position = "left" })
knSec:AddLabel("hitbox expander"):AddToggle({
    Default = false, Flag = "KB_Hitbox",
    Callback = function(v) Config.Knifebot.HitboxEnabled = v end
})
knSec:AddLabel("hitbox size"):AddSlider({
    Min = 3, Max = 50, Rounding = 0,
    Default = 21, Flag = "KB_HitboxSize",
    Callback = function(v)
        Config.Knifebot.HitboxX = v
        Config.Knifebot.HitboxY = v
        Config.Knifebot.HitboxZ = v
    end
})
knSec:AddLabel("auto swing knife"):AddToggle({
    Default = false, Flag = "KB_AutoKnife",
    Callback = function(v)
        Config.Knifebot.AutoKnife = v
        if v then
            getgenv().ExoInternal.startAutoKnife()
        elseif Config.Knifebot.AutoKnifeConn then
            Config.Knifebot.AutoKnifeConn:Disconnect()
            Config.Knifebot.AutoKnifeConn = nil
        end
    end
})
knSec:AddLabel("hold gun + knife"):AddToggle({
    Default = false, Flag = "KB_HoldGunKnife",
    Callback = function(v) Config.Knifebot.HoldGunAndKnife = v end
})
knSec:AddLabel("gun choice"):AddDropdown({
    Default = "[Revolver]",
    Values = {
        "[Revolver]", "[DoubleBarrel]", "[TacticalShotgun]",
        "[SMG]", "[Shotgun]", "[Silencer]"
    },
    Flag = "KB_HoldGunChoice",
    Callback = function(v) Config.Knifebot.SelectedGun = v end
})

-- tracked keybinds additions
table.insert(Config.TrackedKeybinds, {
    Name = "Kill Aura",
    GetKey = function() return "Auto" end,
    IsActive = function() return Config.KillAura.Enabled end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Glue",
    GetKey = function() return Config.Glue.Key.Name end,
    IsActive = function() return Config.Glue.Active end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Forcehit",
    GetKey = function() return Config.ForceHit.Key.Name end,
    IsActive = function()
        return Config.ForceHit.Enabled and Config.ForceHit.Active
    end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Target Lock",
    GetKey = function() return "L" end,
    IsActive = function()
        return Config.ForceHit.TargetLocked
            and Config.ForceHit.LockedTarget ~= nil
    end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Target Strafe",
    GetKey = function() return Config.ForceHit.StrafeKey.Name end,
    IsActive = function() return Config.ForceHit.StrafeEnabled end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Aimbot",
    GetKey = function() return Config.Legit.AimbotKey.Name end,
    IsActive = function()
        return Config.Legit.AimbotEnabled and Config.Legit.AimbotActive
    end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Camlock",
    GetKey = function() return Config.Legit.CamLockKey.Name end,
    IsActive = function()
        return Config.Legit.CamLockEnabled and (
            Config.Legit.CamLockKeyMode == "Always"
            or Config.Legit.CamLockKeyActive
        )
    end
})

print("[EXO UNIFIED] chunk 5 loaded — rage / knifebot / glue.")
-- ═══════════════════════════════════════════════════════════════
--  MISC TAB  — desync / fake position / movement / automation
-- ═══════════════════════════════════════════════════════════════
window = getgenv().window
if not window then
    warn("[EXO UNIFIED] no window — chunk 6 skipped")
    return
end

-- ─── Desync state ─────────────────────────────────────────────
Config.Desync = {
    Enabled       = false,
    Mode          = "void",
    Keybind       = Enum.KeyCode.V,
    MasterEnabled = false,
    VoidTime      = 0.4,
    NormalTime    = 0.133,
    Timer         = 0,
    OldPosition   = nil,
    TargetPosition = nil,
    CustomOffset  = Vector3.new(0, 0, 0)
}

-- ─── Fake position state ──────────────────────────────────────
Config.FakePos = {
    Enabled       = false,
    Keybind       = nil,
    ServerPos     = nil,
    VisEnabled    = false,
    VisColor      = Color3.fromRGB(255, 100, 0),
    VisThickness  = 1.5
}

-- ─── Movement state ───────────────────────────────────────────
Config.Movement = {
    WalkSpeedEnabled = false,
    WalkSpeedValue   = 16,
    WalkSpeedKey     = nil,
    WalkSpeedActive  = false,

    CFrameSpeedEnabled = false,
    CFrameSpeedActive  = false,
    CFrameSpeed        = 2,
    CFrameSpeedKey     = nil,

    CFrameFlyEnabled = false,
    CFrameFlyActive  = false,
    CFrameFlySpeed   = 50,
    CFrameFlyKey     = nil,

    SpinbotEnabled = false,
    SpinbotSpeed   = 50,

    NoclipEnabled = false,
    NoclipKey     = nil
}

-- ─── Automation state ─────────────────────────────────────────
Config.Automation = {
    AutoEat        = false,
    AutoBuyFood    = false,
    AutoBuyInterval = 3,
    AutoReload     = false,
    AntiStomp      = false,
    AntiStompDelay = 1.5,
    FastStomp      = false,
    ForceReset     = false,
    ResetKey       = Enum.KeyCode.E,
    ForceResetDelay = 2,
    PingSpoofEnabled = false,
    PingValue      = 300,
    AntiAFK        = false,
    SpamAFK        = false,
    InfiniteRange  = false,
    InfiniteRangeValue = 999999999,
    RapidFire      = false,
    RapidFireDelay = 0.01,
    RapidFireHeld  = false,

    WeatherEnabled = false,
    WeatherType    = "rain",
    WeatherColor   = Color3.fromRGB(255, 255, 255),
    WeatherRate    = 100,
    ParticleAuraEnabled = false,
    ParticleAuraType    = "angel",
    ParticleAuraColor   = Color3.fromRGB(133, 220, 255)
}

-- ═══════════════════════════════════════════════════════════════
--  WEATHER SYSTEM  (rain / snow / light rain)
-- ═══════════════════════════════════════════════════════════════
getgenv().WV_weatherTypes = {
    ["rain"] = {
        Speed = NumberRange.new(60, 60),
        LockedToPart = true,
        Rate = 600,
        Texture = "rbxassetid://1822883048",
        EmissionDirection = Enum.NormalId.Bottom,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.25, 0.78),
            NumberSequenceKeypoint.new(0.75, 0.78),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Lifetime = NumberRange.new(0.8, 0.8),
        LightEmission = 0.05,
        LightInfluence = 0.9,
        Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 10),
            NumberSequenceKeypoint.new(1, 10)
        })
    },
    ["snow"] = {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.74),
            NumberSequenceKeypoint.new(0.973, 0.77),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Texture = "http://www.roblox.com/asset/?id=99851851",
        SpreadAngle = Vector2.new(50, 50),
        Speed = NumberRange.new(30, 30),
        LightEmission = 0.5,
        Rate = 1000,
        EmissionDirection = Enum.NormalId.Bottom,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.33),
            NumberSequenceKeypoint.new(0.551, 0.4),
            NumberSequenceKeypoint.new(1, 0.33)
        })
    },
    ["light rain"] = {
        LockedToPart = true,
        Rate = 500,
        Squash = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 3),
            NumberSequenceKeypoint.new(1, 3)
        }),
        LightInfluence = 0.3,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.435, 0),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Speed = NumberRange.new(30, 50),
        Lifetime = NumberRange.new(9, 9),
        LightEmission = 0.5,
        Brightness = 2,
        EmissionDirection = Enum.NormalId.Bottom,
        Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0.2)
        })
    }
}

getgenv().WV_weatherPart = nil
getgenv().WV_weatherParticle = nil
getgenv().WV_weatherConn = nil

getgenv().WV_startWeather = function(weatherType, color, rate)
    if getgenv().WV_weatherConn then
        getgenv().WV_weatherConn:Disconnect()
        getgenv().WV_weatherConn = nil
    end
    if getgenv().WV_weatherPart then
        getgenv().WV_weatherPart:Destroy()
        getgenv().WV_weatherPart = nil
        getgenv().WV_weatherParticle = nil
    end

    local def = getgenv().WV_weatherTypes[weatherType]
    if not def then return end

    local part = Instance.new("Part")
    part.Size = Vector3.new(40, 40, 85)
    part.CanCollide = false
    part.Massless = true
    part.CastShadow = false
    part.Transparency = 1
    part.Anchored = true
    part.Parent = workspace
    getgenv().WV_weatherPart = part

    local pe = Instance.new("ParticleEmitter")
    for k, v in pairs(def) do pe[k] = v end
    pe.Color = ColorSequence.new(color or Color3.fromRGB(255, 255, 255))
    if rate then pe.Rate = def.Rate * (rate / 100) end
    pe.Parent = part
    getgenv().WV_weatherParticle = pe

    getgenv().WV_weatherConn = RunService.Heartbeat:Connect(function()
        if getgenv().WV_weatherPart and workspace.CurrentCamera then
            getgenv().WV_weatherPart.CFrame =
                CFrame.new(workspace.CurrentCamera.CFrame.Position) + Vector3.new(0, 20, 0)
        end
    end)
end

getgenv().WV_stopWeather = function()
    if getgenv().WV_weatherConn then
        getgenv().WV_weatherConn:Disconnect()
        getgenv().WV_weatherConn = nil
    end
    if getgenv().WV_weatherPart then
        getgenv().WV_weatherPart:Destroy()
        getgenv().WV_weatherPart = nil
        getgenv().WV_weatherParticle = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--  DESYNC — raknet send hook (falls back if unavailable)
-- ═══════════════════════════════════════════════════════════════
local desyncHooked = false

local function desyncRakHook(packet)
    if packet.PacketId == 0x1B then
        local buf = packet.AsBuffer
        buffer.writeu32(buf, 1, 0xFFFFFFFF)
        packet:SetData(buf)
    end
end

local function setDesyncState(hook)
    if hook and not desyncHooked then
        pcall(function()
            if raknet and raknet.add_send_hook then
                raknet.add_send_hook(desyncRakHook)
                desyncHooked = true
            end
        end)
    elseif not hook and desyncHooked then
        pcall(function()
            if raknet and raknet.remove_send_hook then
                raknet.remove_send_hook(desyncRakHook)
                desyncHooked = false
            end
        end)
    end
end

local serverPosPart = Instance.new("Part")
serverPosPart.Name = "ExoServerPos"
serverPosPart.Size = Vector3.new(1, 1, 1)
serverPosPart.Transparency = 1
serverPosPart.CanCollide = false
serverPosPart.Anchored = true
serverPosPart.Parent = workspace

RunService.Heartbeat:Connect(function(dt)
    if Config.Unloaded then return end
    local D = Config.Desync
    if not D.Enabled then return end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local old = hrp.CFrame
    local mode = D.Mode
    local newCF

    if mode == "void" then
        newCF = CFrame.new(
            hrp.Position + Vector3.new(
                math.random(-900000000, 900000000),
                math.random(100000000, 900000000),
                math.random(-900000000, 900000000)
            )
        )
    elseif mode == "spam void" then
        D.Timer += dt
        if D.Timer < D.VoidTime then
            newCF = CFrame.new(
                hrp.Position + Vector3.new(
                    math.random(-900000000, 900000000),
                    math.random(100000000, 900000000),
                    math.random(-900000000, 900000000)
                )
            )
        else
            newCF = old
            if D.Timer >= D.VoidTime + D.NormalTime then
                D.Timer = 0
            end
        end
    elseif mode == "Epilepsy" then
        if math.floor(tick() * 60) % 2 == 0 then
            newCF = CFrame.new(hrp.Position + Vector3.new(
                2147483647, 2147483647, 2147483647
            ))
        else
            newCF = CFrame.new(hrp.Position - Vector3.new(
                2147483647, 2147483647, 2147483647
            ))
        end
    elseif mode == "Custom" then
        newCF = old + D.CustomOffset
    elseif mode == "Underground" then
        newCF = CFrame.new(hrp.Position - Vector3.new(0, 6, 0))
            * CFrame.Angles(math.rad(90), 0, 0)
    else
        newCF = old
    end

    D.TargetPosition = newCF
    hrp.CFrame = newCF
end)

-- ═══════════════════════════════════════════════════════════════
--  FAKE POSITION
-- ═══════════════════════════════════════════════════════════════

local fakePosTracer = Drawing.new("Line")
fakePosTracer.Thickness = 1.5
fakePosTracer.Color = Color3.fromRGB(255, 100, 0)
fakePosTracer.Visible = false

task.spawn(function()
    while task.wait(0.05) do
        if Config.Unloaded then break end
        local FP = Config.FakePos
        if not FP.Enabled then continue end
        if not sethiddenproperty then continue end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local before = hrp.Position
        pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", nil)
        task.wait(0.1)
        local after = hrp.Position
        pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", hrp)
        if (after - before).Magnitude > 10 then
            FP.ServerPos = after
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.Unloaded then return end
    local FP = Config.FakePos
    if not (FP.Enabled and FP.VisEnabled and FP.ServerPos) then
        fakePosTracer.Visible = false
        return
    end

    local pos, on = Camera:WorldToViewportPoint(FP.ServerPos)
    if on then
        local mouse = UIS:GetMouseLocation()
        fakePosTracer.From = mouse
        fakePosTracer.To   = Vector2.new(pos.X, pos.Y)
        fakePosTracer.Color = FP.VisColor
        fakePosTracer.Thickness = FP.VisThickness
        fakePosTracer.Visible = true
    else
        fakePosTracer.Visible = false
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  MOVEMENT
-- ═══════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
    if Config.Unloaded then return end
    local M = Config.Movement
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if M.WalkSpeedEnabled and M.WalkSpeedActive then
        if hum.WalkSpeed ~= M.WalkSpeedValue then
            hum.WalkSpeed = M.WalkSpeedValue
        end
    elseif M.WalkSpeedActive == false then
        if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Config.Automation.RapidFireHeld = true
    end

    if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
    local M = Config.Movement
    if M.WalkSpeedKey and input.KeyCode == M.WalkSpeedKey and M.WalkSpeedEnabled then
        M.WalkSpeedActive = not M.WalkSpeedActive
    end
    if M.CFrameSpeedKey and input.KeyCode == M.CFrameSpeedKey and M.CFrameSpeedEnabled then
        M.CFrameSpeedActive = not M.CFrameSpeedActive
    end
    if M.CFrameFlyKey and input.KeyCode == M.CFrameFlyKey and M.CFrameFlyEnabled then
        M.CFrameFlyActive = not M.CFrameFlyActive
    end
    if M.NoclipKey and input.KeyCode == M.NoclipKey then
        M.NoclipEnabled = not M.NoclipEnabled
    end
end)

UIS.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Config.Automation.RapidFireHeld = false
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if Config.Unloaded then break end
        local held = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        if held ~= Config.Automation.RapidFireHeld then
            Config.Automation.RapidFireHeld = held
        end
    end
end)

local inputMap = {
    W = Enum.KeyCode.W, A = Enum.KeyCode.A,
    S = Enum.KeyCode.S, D = Enum.KeyCode.D,
    Space = Enum.KeyCode.Space,
    LeftShift = Enum.KeyCode.LeftShift
}
local keyState = {
    W = false, A = false, S = false, D = false,
    Space = false, LeftShift = false
}

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    for name, code in pairs(inputMap) do
        if input.KeyCode == code then keyState[name] = true end
    end
end)
UIS.InputEnded:Connect(function(input)
    for name, code in pairs(inputMap) do
        if input.KeyCode == code then keyState[name] = false end
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.Unloaded then return end
    local M = Config.Movement
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return end

    if M.CFrameSpeedEnabled and M.CFrameSpeedActive and not M.CFrameFlyActive then
        if hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + hum.MoveDirection * (M.CFrameSpeed / 10)
        end
    end

    if M.CFrameFlyEnabled and M.CFrameFlyActive then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hum.PlatformStand = false

        local look = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector
        local move = Vector3.zero

        if keyState.W then move += look end
        if keyState.S then move -= look end
        if keyState.A then move -= right end
        if keyState.D then move += right end
        if keyState.Space then move += Vector3.new(0, 1, 0) end
        if keyState.LeftShift then move -= Vector3.new(0, 1, 0) end

        if move.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + move.Unit * (M.CFrameFlySpeed / 100)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.Unloaded then return end
    local M = Config.Movement
    if not M.SpinbotEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(M.SpinbotSpeed), 0)
    end
end)

RunService.Stepped:Connect(function()
    if Config.Unloaded then return end
    local M = Config.Movement
    if not M.NoclipEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  AUTOMATION
-- ═══════════════════════════════════════════════════════════════

getgenv().ExoInternal.performReset = function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if replicatesignal then
        pcall(function() replicatesignal(LocalPlayer.Kill) end)
    elseif hum then
        hum:ChangeState(Enum.HumanoidStateType.Dead)
    end
end

task.spawn(function()
    local resetting = false
    while task.wait(0.1) do
        if Config.Unloaded then break end
        local A = Config.Automation
        if A.ForceReset and not resetting then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local ko = char:FindFirstChild("KO") or char:FindFirstChild("Ragdoll")
                    local low = hum.Health > 0 and hum.Health <= 15
                    if ko or low then
                        resetting = true
                        task.wait(A.ForceResetDelay or 2)
                        if char.Parent and hum.Health > 0 then
                            getgenv().ExoInternal.performReset()
                        end
                        task.wait(3)
                        resetting = false
                    end
                end
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
    local A = Config.Automation
    if A.ForceReset and input.KeyCode == A.ResetKey then
        getgenv().ExoInternal.performReset()
    end
end)

task.spawn(function()
    local inCooldown = false
    while task.wait(0.1) do
        if Config.Unloaded then break end
        local A = Config.Automation
        if not A.AntiStomp then
            inCooldown = false
            continue
        end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local be  = char and char:FindFirstChild("BodyEffects")
        local ko  = be and (be:FindFirstChild("K.O") or be:FindFirstChild("KO"))

        if ko and ko.Value and not inCooldown and hum and hum.Health > 0 then
            inCooldown = true
            task.spawn(function()
                task.wait(A.AntiStompDelay or 1.5)
                local c = LocalPlayer.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                local b = c and c:FindFirstChild("BodyEffects")
                local k = b and (b:FindFirstChild("K.O") or b:FindFirstChild("KO"))
                if k and k.Value and h and h.Health > 0 then
                    if replicatesignal then
                        pcall(function() replicatesignal(LocalPlayer.Kill) end)
                    else
                        local head = c:FindFirstChild("Head")
                        if head then c:BreakJoints() end
                    end
                end
                task.wait(1)
                inCooldown = false
            end)
        elseif ko and not ko.Value then
            inCooldown = false
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if Config.Unloaded then break end
        if Config.Automation.FastStomp then
            local evt = ReplicatedStorage:FindFirstChild("MainEvent")
            if evt then pcall(function() evt:FireServer("Stomp") end) end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if Config.Unloaded then break end
        if not Config.Automation.InfiniteRange then continue end

        local char = LocalPlayer.Character
        if not char then continue end

        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then continue end

        local range = tool:FindFirstChild("Range")
        if range and range:IsA("NumberValue") then
            range.Value = Config.Automation.InfiniteRangeValue
        end

        local cfg = tool:FindFirstChild("Configuration")
            or tool:FindFirstChild("Config")
            or tool:FindFirstChild("GunConfig")
        if cfg then
            local r = cfg:FindFirstChild("Range")
            if r and r:IsA("NumberValue") then
                r.Value = Config.Automation.InfiniteRangeValue
            end
        end

        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then
                    local r = t:FindFirstChild("Range")
                    if r and r:IsA("NumberValue") then
                        r.Value = Config.Automation.InfiniteRangeValue
                    end
                end
            end
        end
    end
end)

local function isTypingInChat_rapid()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local chat = playerGui:FindFirstChild("Chat")
        if chat then
            local bar = chat:FindFirstChild("ChatBar")
            if bar and bar:FindFirstChild("TextBox") then
                local tb = bar.TextBox
                if tb and tb:IsFocused() then return true end
            end
        end
    end
    local tcs = game:GetService("TextChatService")
    if tcs then
        local cfg = tcs:FindFirstChild("ChatWindowConfiguration")
        if cfg and cfg:GetAttribute("TextBoxFocused") then return true end
    end
    local focused = UserInputService:GetFocusedTextBox()
    if focused then return true end
    return false
end

local function zeroShootingCooldown(tool)
    if not tool or not tool:IsA("Tool") then return end

    local cd = tool:FindFirstChild("ShootingCooldown")
    if cd and cd:IsA("NumberValue") then
        cd.Value = 0
    end

    for _, folderName in ipairs({"Configuration", "Config", "GunConfig", "Settings"}) do
        local folder = tool:FindFirstChild(folderName)
        if folder then
            local nested = folder:FindFirstChild("ShootingCooldown")
            if nested and nested:IsA("NumberValue") then
                nested.Value = 0
            end
        end
    end
end

local function hookToolContainer(container)
    container.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and Config.Automation.RapidFire then
            task.wait(0.03)
            zeroShootingCooldown(child)
        end
    end)
end

if LocalPlayer:FindFirstChild("Backpack") then
    hookToolContainer(LocalPlayer:FindFirstChild("Backpack"))
end
LocalPlayer.ChildAdded:Connect(function(child)
    if child.Name == "Backpack" then
        hookToolContainer(child)
    end
end)
LocalPlayer.CharacterAdded:Connect(function(char)
    hookToolContainer(char)
end)

RunService.Heartbeat:Connect(function()
    if Config.Unloaded then return end
    if not Config.Automation.RapidFire then return end
    if not Config.Automation.RapidFireHeld then return end
    if isTypingInChat_rapid() then return end

    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    zeroShootingCooldown(tool)
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():find("cool") then
            v.Value = 0
        end
        if v:IsA("BoolValue") and v.Name:lower():find("fire") then
            v.Value = false
        end
    end

    pcall(function() tool:Activate() end)
end)

local mainEvent = ReplicatedStorage:WaitForChild("MainEvent", 10)
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.Unloaded then break end
        if Config.Automation.AntiAFK and mainEvent then
            pcall(function()
                mainEvent:FireServer("RequestAFKDisplay", true)
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        if Config.Unloaded then break end
        if Config.Automation.SpamAFK and mainEvent then
            pcall(function()
                mainEvent:FireServer("RequestAFKDisplay", true)
            end)
            task.wait(0.01)
            pcall(function()
                mainEvent:FireServer("RequestAFKDisplay", false)
            end)
        end
    end
end)

task.spawn(function()
    if not mainEvent then return end
    local hooked = false
    local _realGetPing = false

    if getrawmetatable then
        local ok, mt = pcall(getrawmetatable, game)
        if ok and mt and setreadonly then
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = function(self, ...)
                local args = {...}
                local method = getnamecallmethod()
                if method == "FireServer"
                   and self == mainEvent
                   and args[1] == "GetPing"
                   and Config.Automation.PingSpoofEnabled
                   and not checkcaller() then
                    return
                end
                return oldNamecall(self, ...)
            end
            setreadonly(mt, true)
            hooked = true
        end
    end

    while true do
        task.wait(0.5)
        if Config.Unloaded then break end
        if Config.Automation.PingSpoofEnabled and mainEvent and hooked then
            local ms = Config.Automation.PingValue or 300
            pcall(function()
                mainEvent:FireServer("GetPing", ms / 1000)
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  UI — Misc tab
-- ═══════════════════════════════════════════════════════════════
local miscTab   = window:AddTab({ Name = "Misc", Icon = "M" })
local moveSub   = miscTab:AddSubTab({ Name = "Movement", Icon = "person-running" })
local desyncSub = miscTab:AddSubTab({ Name = "Desync",   Icon = "shield-check" })
local autoSub   = miscTab:AddSubTab({ Name = "Automation", Icon = "gear" })
local utilSub   = miscTab:AddSubTab({ Name = "Utility",  Icon = "wrench" })

local wsSec = moveSub:AddSection({ Name = "walkspeed", Position = "left" })
wsSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "MV_WalkSpeedEnabled",
    Callback = function(v)
        Config.Movement.WalkSpeedEnabled = v
        if not v then Config.Movement.WalkSpeedActive = false end
    end
})
wsSec:AddLabel("keybind"):AddKeybind({
    Default = "None", Flag = "MV_WalkSpeedKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Movement.WalkSpeedKey = parsed end
    end
})
wsSec:AddLabel("value"):AddSlider({
    Min = 16, Max = 600, Rounding = 0,
    Default = 16, Flag = "MV_WalkSpeedValue",
    Callback = function(v) Config.Movement.WalkSpeedValue = v end
})

local csSec = moveSub:AddSection({ Name = "cframe speed", Position = "left" })
csSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "MV_CFSpeedEnabled",
    Callback = function(v)
        Config.Movement.CFrameSpeedEnabled = v
        if not v then Config.Movement.CFrameSpeedActive = false end
    end
})
csSec:AddLabel("keybind"):AddKeybind({
    Default = "None", Flag = "MV_CFSpeedKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Movement.CFrameSpeedKey = parsed end
    end
})
csSec:AddLabel("multiplier"):AddSlider({
    Min = 1, Max = 60, Rounding = 1,
    Default = 2, Flag = "MV_CFSpeedValue",
    Callback = function(v) Config.Movement.CFrameSpeed = v end
})

local flySec = moveSub:AddSection({ Name = "cframe fly", Position = "right" })
flySec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "MV_CFlyEnabled",
    Callback = function(v)
        Config.Movement.CFrameFlyEnabled = v
        if not v then Config.Movement.CFrameFlyActive = false end
    end
})
flySec:AddLabel("keybind"):AddKeybind({
    Default = "None", Flag = "MV_CFlyKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Movement.CFrameFlyKey = parsed end
    end
})
flySec:AddLabel("speed"):AddSlider({
    Min = 10, Max = 300, Rounding = 0,
    Default = 50, Flag = "MV_CFlySpeed",
    Callback = function(v) Config.Movement.CFrameFlySpeed = v end
})

local spinSec = moveSub:AddSection({ Name = "spinbot", Position = "right" })
spinSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "MV_SpinbotEnabled",
    Callback = function(v) Config.Movement.SpinbotEnabled = v end
})
spinSec:AddLabel("speed"):AddSlider({
    Min = 5, Max = 150, Rounding = 0,
    Default = 50, Flag = "MV_SpinbotSpeed",
    Callback = function(v) Config.Movement.SpinbotSpeed = v end
})

local ncSec = moveSub:AddSection({ Name = "noclip", Position = "right" })
ncSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "MV_NoclipEnabled",
    Callback = function(v) Config.Movement.NoclipEnabled = v end
})
ncSec:AddLabel("keybind"):AddKeybind({
    Default = "None", Flag = "MV_NoclipKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Movement.NoclipKey = parsed end
    end
})

local dSyncSec = desyncSub:AddSection({ Name = "desync", Position = "left" })
dSyncSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "Des_MasterEnabled",
    Callback = function(v) Config.Desync.MasterEnabled = v end
})
dSyncSec:AddLabel("keybind"):AddKeybind({
    Default = "V", Flag = "Des_Keybind",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Desync.Keybind = parsed end
    end
})
dSyncSec:AddLabel("mode"):AddDropdown({
    Default = "void",
    Values = { "void", "spam void", "Epilepsy", "Custom", "Underground" },
    Flag = "Des_Mode",
    Callback = function(v) Config.Desync.Mode = v end
})
dSyncSec:AddLabel("void time"):AddSlider({
    Min = 0.05, Max = 2, Rounding = 2,
    Default = 0.4, Flag = "Des_VoidTime",
    Callback = function(v) Config.Desync.VoidTime = v end
})
dSyncSec:AddLabel("ground time"):AddSlider({
    Min = 0.05, Max = 2, Rounding = 2,
    Default = 0.133, Flag = "Des_NormalTime",
    Callback = function(v) Config.Desync.NormalTime = v end
})

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
    local D = Config.Desync
    if D.MasterEnabled and input.KeyCode == D.Keybind then
        D.Enabled = not D.Enabled
        setDesyncState(D.Enabled)
    end
end)

local fpSec = desyncSub:AddSection({ Name = "fake position", Position = "right" })
fpSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "FP_Enabled",
    Callback = function(v)
        Config.FakePos.Enabled = v
        if not v then
            Config.FakePos.ServerPos = nil
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and sethiddenproperty then
                pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", hrp)
            end
        end
    end
})
fpSec:AddLabel("keybind"):AddKeybind({
    Default = "None", Flag = "FP_Key",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.FakePos.Keybind = parsed end
    end
})

local fpVisSec = desyncSub:AddSection({ Name = "fake pos visuals", Position = "right" })
fpVisSec:AddLabel("tracer"):AddToggle({
    Default = false, Flag = "FP_VisEnabled",
    Callback = function(v) Config.FakePos.VisEnabled = v end
})
fpVisSec:AddLabel("tracer color"):AddColorPicker({
    Default = Color3.fromRGB(255, 100, 0),
    Flag = "FP_VisColor",
    Callback = function(c) Config.FakePos.VisColor = c end
})
fpVisSec:AddLabel("tracer thickness"):AddSlider({
    Min = 0.5, Max = 5, Rounding = 1,
    Default = 1.5, Flag = "FP_VisThickness",
    Callback = function(v) Config.FakePos.VisThickness = v end
})

local autoSec = autoSub:AddSection({ Name = "survival", Position = "left" })
autoSec:AddLabel("auto eat"):AddToggle({
    Default = false, Flag = "AU_AutoEat",
    Callback = function(v) Config.Automation.AutoEat = v end
})
autoSec:AddLabel("fast stomp"):AddToggle({
    Default = false, Flag = "AU_FastStomp",
    Callback = function(v) Config.Automation.FastStomp = v end
})
autoSec:AddLabel("anti stomp"):AddToggle({
    Default = false, Flag = "AU_AntiStomp",
    Callback = function(v) Config.Automation.AntiStomp = v end
})
autoSec:AddLabel("anti stomp delay"):AddSlider({
    Min = 0.5, Max = 5, Rounding = 1,
    Default = 1.5, Flag = "AU_AntiStompDelay",
    Callback = function(v) Config.Automation.AntiStompDelay = v end
})
autoSec:AddLabel("force reset"):AddToggle({
    Default = false, Flag = "AU_ForceReset",
    Callback = function(v) Config.Automation.ForceReset = v end
})
autoSec:AddLabel("reset key"):AddKeybind({
    Default = "E", Flag = "AU_ResetKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then Config.Automation.ResetKey = parsed end
    end
})

local utilAuto = autoSub:AddSection({ Name = "utility", Position = "right" })
utilAuto:AddLabel("anti afk"):AddToggle({
    Default = false, Flag = "AU_AntiAFK",
    Callback = function(v) Config.Automation.AntiAFK = v end
})
utilAuto:AddLabel("spam afk"):AddToggle({
    Default = false, Flag = "AU_SpamAFK",
    Callback = function(v) Config.Automation.SpamAFK = v end
})
utilAuto:AddLabel("ping spoofer"):AddToggle({
    Default = false, Flag = "AU_PingSpoof",
    Callback = function(v) Config.Automation.PingSpoofEnabled = v end
})
utilAuto:AddLabel("ping value (ms)"):AddSlider({
    Min = 0, Max = 1000, Rounding = 0,
    Default = 300, Flag = "AU_PingValue",
    Callback = function(v) Config.Automation.PingValue = v end
})

local infRangeSec = autoSub:AddSection({ Name = "infinite range", Position = "right" })
infRangeSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "AU_InfiniteRange",
    Callback = function(v) Config.Automation.InfiniteRange = v end
})
infRangeSec:AddLabel("range value"):AddSlider({
    Min = 100, Max = 1000000, Rounding = 0,
    Default = 999999999, Flag = "AU_InfiniteRangeValue",
    Callback = function(v) Config.Automation.InfiniteRangeValue = v end
})

local rapidSec = autoSub:AddSection({ Name = "rapid fire", Position = "right" })
rapidSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "AU_RapidFire",
    Callback = function(v) Config.Automation.RapidFire = v end
})
rapidSec:AddLabel("delay"):AddSlider({
    Min = 0.001, Max = 0.1, Rounding = 3,
    Default = 0.01, Flag = "AU_RapidFireDelay",
    Callback = function(v) Config.Automation.RapidFireDelay = v end
})

local armorSec = utilSub:AddSection({ Name = "auto-buy armor", Position = "left" })
armorSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "Armor_AutoBuyEnabled",
    Callback = function(v) getgenv().ArmorAutoBuyEnabled = v end
})
armorSec:AddLabel("keybind"):AddKeybind({
    Default = "H", Flag = "Armor_BuyKey",
    Callback = function(k)
        local parsed = getgenv().parseKey(k)
        if parsed then getgenv().ArmorBuyKey = parsed end
    end
})

local utilSec = utilSub:AddSection({ Name = "rejoin / copy", Position = "left" })
pcall(function()
    utilSec:AddLabel("rejoin server"):AddButton({
        Name = "Rejoin",
        Callback = function()
            local TS = Services.TeleportService
            local jobId = game.JobId
            pcall(function()
                TS:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
            end)
        end
    })
end)

pcall(function()
    utilSec:AddLabel("copy jobid"):AddButton({
        Name = "Copy JobId",
        Callback = function()
            if setclipboard then
                setclipboard(game.JobId)
                pcall(function()
                    getgenv().Logging.new("clipboard", "jobid copied", 3)
                end)
            end
        end
    })
end)

table.insert(Config.TrackedKeybinds, {
    Name = "Desync",
    GetKey = function() return Config.Desync.Keybind.Name end,
    IsActive = function() return Config.Desync.Enabled end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Fake Position",
    GetKey = function()
        return Config.FakePos.Keybind and Config.FakePos.Keybind.Name or "None"
    end,
    IsActive = function() return Config.FakePos.Enabled end
})
table.insert(Config.TrackedKeybinds, {
    Name = "CFrame Fly",
    GetKey = function()
        return Config.Movement.CFrameFlyKey and Config.Movement.CFrameFlyKey.Name or "None"
    end,
    IsActive = function()
        return Config.Movement.CFrameFlyEnabled and Config.Movement.CFrameFlyActive
    end
})
table.insert(Config.TrackedKeybinds, {
    Name = "CFrame Speed",
    GetKey = function()
        return Config.Movement.CFrameSpeedKey and Config.Movement.CFrameSpeedKey.Name or "None"
    end,
    IsActive = function()
        return Config.Movement.CFrameSpeedEnabled and Config.Movement.CFrameSpeedActive
    end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Noclip",
    GetKey = function()
        return Config.Movement.NoclipKey and Config.Movement.NoclipKey.Name or "None"
    end,
    IsActive = function() return Config.Movement.NoclipEnabled end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Spinbot",
    GetKey = function() return "None" end,
    IsActive = function() return Config.Movement.SpinbotEnabled end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Rapid Fire",
    GetKey = function() return "LMB" end,
    IsActive = function()
        return Config.Automation
            and Config.Automation.RapidFire
            and Config.Automation.RapidFireHeld
    end
})
table.insert(Config.TrackedKeybinds, {
    Name = "Infinite Range",
    GetKey = function() return "None" end,
    IsActive = function()
        return Config.Automation and Config.Automation.InfiniteRange
    end
})

print("[EXO UNIFIED] chunk 6 loaded — misc.")
-- ═══════════════════════════════════════════════════════════════
--  VISUALS TAB  — esp / tracers / chams / crosshair / extras
-- ═══════════════════════════════════════════════════════════════
window = getgenv().window
if not window then
    warn("[EXO UNIFIED] no window — chunk 7 skipped")
    return
end

-- ─── Visuals state ────────────────────────────────────────────
Config.Visuals = {
    NameEspEnabled = false,
    NameEspColor   = Color3.fromRGB(255, 255, 255),
    NameEspLocked  = Color3.fromRGB(255, 60, 60),
    NameEspSize    = 14,

    BoxEspEnabled  = false,
    BoxEspColor    = Color3.fromRGB(160, 32, 240),
    BoxEspFilled   = false,
    BoxEspFillColor = Color3.fromRGB(160, 32, 240),

    TracersEnabled = false,
    TracersColor   = Color3.fromRGB(255, 255, 255),
    TracersThickness = 1.5,
    TracersOrigin  = "bottom",

    ChamsEnabled      = false,
    ChamsColor        = Color3.fromRGB(255, 0, 0),
    ChamsFill         = true,
    ChamsTransparency = 0.5,
    ChamsTeamCheck    = true,

    CrosshairEnabled = false,
    CrosshairSize    = 10,
    CrosshairGap     = 4,
    CrosshairThick   = 1.5,
    CrosshairColor   = Color3.fromRGB(160, 32, 240),
    CrosshairOutline = true,


    FullbrightEnabled = false,
    FullbrightAmbient = Color3.fromRGB(255, 255, 255)
}

-- ═══════════════════════════════════════════════════════════════
--  NAME ESP
-- ═══════════════════════════════════════════════════════════════
local nameEspCache = {}

local function createNameEsp(plr)
    if plr == LocalPlayer then return end
    local tag = Drawing.new("Text")
    tag.Size         = Config.Visuals.NameEspSize
    tag.Center       = true
    tag.Outline      = true
    tag.OutlineColor = Color3.new(0, 0, 0)
    tag.Color        = Config.Visuals.NameEspColor
    tag.Visible      = false
    tag.ZIndex       = 1000
    nameEspCache[plr] = tag
end

for _, plr in ipairs(Players:GetPlayers()) do createNameEsp(plr) end
Players.PlayerAdded:Connect(createNameEsp)
Players.PlayerRemoving:Connect(function(plr)
    if nameEspCache[plr] then
        nameEspCache[plr]:Remove()
        nameEspCache[plr] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  BOX ESP
-- ═══════════════════════════════════════════════════════════════
local boxEspCache = {}

local function createBoxEsp(plr)
    if plr == LocalPlayer then return end
    boxEspCache[plr] = {
        top    = Drawing.new("Line"),
        bottom = Drawing.new("Line"),
        left   = Drawing.new("Line"),
        right  = Drawing.new("Line")
    }
    for _, line in pairs(boxEspCache[plr]) do
        line.Thickness = 1.5
        line.Visible   = false
    end
end

for _, plr in ipairs(Players:GetPlayers()) do createBoxEsp(plr) end
Players.PlayerAdded:Connect(createBoxEsp)
Players.PlayerRemoving:Connect(function(plr)
    local box = boxEspCache[plr]
    if box then
        for _, line in pairs(box) do line:Remove() end
        boxEspCache[plr] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  TRACERS
-- ═══════════════════════════════════════════════════════════════
local tracerCache = {}

local function createTracer(plr)
    if plr == LocalPlayer then return end
    local line = Drawing.new("Line")
    line.Thickness    = 1.5
    line.Color        = Color3.fromRGB(255, 255, 255)
    line.Visible      = false
    line.Transparency = 1
    tracerCache[plr] = line
end

for _, plr in ipairs(Players:GetPlayers()) do createTracer(plr) end
Players.PlayerAdded:Connect(createTracer)
Players.PlayerRemoving:Connect(function(plr)
    if tracerCache[plr] then
        tracerCache[plr]:Remove()
        tracerCache[plr] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  CHAMS (Highlight)
-- ═══════════════════════════════════════════════════════════════
local chamsHighlights = {}

local function addChams(character)
    if chamsHighlights[character] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ExoChams"
    hl.Adornee = character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.OutlineTransparency = 0
    hl.FillTransparency = Config.Visuals.ChamsFill
        and (1 - Config.Visuals.ChamsTransparency)
        or 1
    hl.OutlineColor = Config.Visuals.ChamsColor
    hl.FillColor = Config.Visuals.ChamsColor
    hl.Parent = character
    chamsHighlights[character] = hl
end

local function removeChams(character)
    if chamsHighlights[character] then
        chamsHighlights[character]:Destroy()
        chamsHighlights[character] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--  CROSSHAIR
-- ═══════════════════════════════════════════════════════════════
local crossLines = {}
local crossLinesOutline = {}

local function ensureCrosshairLines(count)
    while #crossLines < count do
        local inline = Drawing.new("Line")
        inline.ZIndex = 3
        inline.Visible = false
        table.insert(crossLines, inline)

        local outline = Drawing.new("Line")
        outline.ZIndex = 2
        outline.Visible = false
        table.insert(crossLinesOutline, outline)
    end
end

ensureCrosshairLines(4)

-- silent aim FOV circle is now the shared Config.FovCircle drawing

-- ═══════════════════════════════════════════════════════════════
--  VISUALS RENDER LOOP
-- ═══════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if Config.Unloaded then return end
    local V = Config.Visuals
    local viewport = Camera.ViewportSize

    -- shared FOV circle
    do
        local inset = Services.GuiService:GetGuiInset()

        Config.FovCircle.Position = Vector2.new(
            Mouse.X, Mouse.Y + (inset and inset.Y or 0)
        )
        -- radius, color, filled, transparency, visible are set by the UI
    end

    if V.CrosshairEnabled then
        local origin = Vector2.new(viewport.X / 2, viewport.Y / 2)
        local gap = V.CrosshairGap
        local size = V.CrosshairSize
        local thick = V.CrosshairThick

        local dirs = {
            { Vector2.new(-1, 0), Vector2.new(-1, 0) },
            { Vector2.new( 1, 0), Vector2.new( 1, 0) },
            { Vector2.new( 0,-1), Vector2.new( 0,-1) },
            { Vector2.new( 0, 1), Vector2.new( 0, 1) }
        }

        for i, d in ipairs(dirs) do
            local inline  = crossLines[i]
            local outline = crossLinesOutline[i]

            local from = origin + d[1] * gap
            local to   = origin + d[2] * (gap + size)

            inline.From = from
            inline.To = to
            inline.Color = V.CrosshairColor
            inline.Thickness = thick
            inline.Visible = true

            if V.CrosshairOutline then
                outline.From = from
                outline.To = to
                outline.Color = Color3.new(0, 0, 0)
                outline.Thickness = thick + 1
                outline.Visible = true
            else
                outline.Visible = false
            end
        end
    else
        for i = 1, #crossLines do
            crossLines[i].Visible = false
            crossLinesOutline[i].Visible = false
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        local visible = char and head and hrp and hum and hum.Health > 0

        local tag = nameEspCache[plr]
        if tag then
            if V.NameEspEnabled and visible then
                local legPos, onScreen = Camera:WorldToViewportPoint(
                    hrp.Position - Vector3.new(0, 3, 0)
                )
                if onScreen then
                    local isLocked =
                        (Config.Legit.StickyAimActive and Config.Legit.CurrentTarget == plr)
                        or (Config.ForceHit.Enabled
                            and Config.ForceHit.Active
                            and Config.ForceHit.Target == plr)

                    tag.Position = Vector2.new(legPos.X, legPos.Y + 15)
                    tag.Text = plr.DisplayName
                    tag.Color = isLocked and V.NameEspLocked or V.NameEspColor
                    tag.Visible = true
                else
                    tag.Visible = false
                end
            else
                tag.Visible = false
            end
        end

        local box = boxEspCache[plr]
        if box then
            if V.BoxEspEnabled and visible then
                local hrpPos, hrpOn = Camera:WorldToViewportPoint(hrp.Position)
                local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                if hrpOn and headOn then
                    local height = math.abs(hrpPos.Y - headPos.Y) * 2.2
                    local width  = height / 2
                    local x = hrpPos.X - width / 2
                    local y = hrpPos.Y - height * 0.7

                    box.top.From    = Vector2.new(x, y)
                    box.top.To      = Vector2.new(x + width, y)
                    box.bottom.From = Vector2.new(x, y + height)
                    box.bottom.To   = Vector2.new(x + width, y + height)
                    box.left.From   = Vector2.new(x, y)
                    box.left.To     = Vector2.new(x, y + height)
                    box.right.From  = Vector2.new(x + width, y)
                    box.right.To    = Vector2.new(x + width, y + height)

                    for _, line in pairs(box) do
                        line.Color = V.BoxEspColor
                        line.Visible = true
                    end
                else
                    for _, line in pairs(box) do line.Visible = false end
                end
            else
                for _, line in pairs(box) do line.Visible = false end
            end
        end

        local tracer = tracerCache[plr]
        if tracer then
            if V.TracersEnabled and visible then
                local hrpPos, on = Camera:WorldToViewportPoint(hrp.Position)
                if on then
                    local origin
                    if V.TracersOrigin == "bottom" then
                        origin = Vector2.new(viewport.X / 2, viewport.Y)
                    elseif V.TracersOrigin == "top" then
                        origin = Vector2.new(viewport.X / 2, 0)
                    elseif V.TracersOrigin == "center" then
                        origin = Vector2.new(viewport.X / 2, viewport.Y / 2)
                    elseif V.TracersOrigin == "mouse" then
                        origin = UIS:GetMouseLocation()
                    else
                        origin = Vector2.new(viewport.X / 2, viewport.Y)
                    end
                    tracer.From = origin
                    tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                    tracer.Color = V.TracersColor
                    tracer.Thickness = V.TracersThickness
                    tracer.Visible = true
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
        end
    end
end)

-- chams update loop
RunService.Heartbeat:Connect(function()
    if Config.Unloaded then return end
    local V = Config.Visuals

    if not V.ChamsEnabled then
        for character in pairs(chamsHighlights) do
            removeChams(character)
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if not (V.ChamsTeamCheck
                    and LocalPlayer.Team
                    and plr.Team
                    and LocalPlayer.Team == plr.Team) then
                addChams(plr.Character)
            else
                removeChams(plr.Character)
            end
        end
    end
end)

-- fullbright
RunService.Heartbeat:Connect(function()
    if Config.Unloaded then return end
    local V = Config.Visuals
    if V.FullbrightEnabled then
        Lighting.Ambient = V.FullbrightAmbient
        Lighting.OutdoorAmbient = V.FullbrightAmbient
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  UI — Visuals tab
-- ═══════════════════════════════════════════════════════════════
local visualsTab = window:AddTab({ Name = "Visuals", Icon = "eye" })
local espSub     = visualsTab:AddSubTab({ Name = "ESP",      Icon = "eye" })
local espSub2    = visualsTab:AddSubTab({ Name = "Self",     Icon = "Human" })
local crossSub   = visualsTab:AddSubTab({ Name = "Crosshair", Icon = "crosshairs" })
local worldSub   = visualsTab:AddSubTab({ Name = "World",    Icon = "sun" })

local nameSec = espSub:AddSection({ Name = "name esp", Position = "left" })
nameSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "V_NameEsp",
    Callback = function(v) Config.Visuals.NameEspEnabled = v end
})
nameSec:AddLabel("color"):AddColorPicker({
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "V_NameEspColor",
    Callback = function(c) Config.Visuals.NameEspColor = c end
})
nameSec:AddLabel("locked color"):AddColorPicker({
    Default = Color3.fromRGB(255, 60, 60),
    Flag = "V_NameEspLocked",
    Callback = function(c) Config.Visuals.NameEspLocked = c end
})
nameSec:AddLabel("size"):AddSlider({
    Min = 8, Max = 24, Rounding = 0,
    Default = 14, Flag = "V_NameEspSize",
    Callback = function(v)
        Config.Visuals.NameEspSize = v
        for _, tag in pairs(nameEspCache) do tag.Size = v end
    end
})

local boxSec = espSub:AddSection({ Name = "box esp", Position = "left" })
boxSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "V_BoxEsp",
    Callback = function(v) Config.Visuals.BoxEspEnabled = v end
})
boxSec:AddLabel("color"):AddColorPicker({
    Default = Color3.fromRGB(160, 32, 240),
    Flag = "V_BoxEspColor",
    Callback = function(c) Config.Visuals.BoxEspColor = c end
})

local tracerSec = espSub:AddSection({ Name = "tracers", Position = "right" })
tracerSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "V_Tracers",
    Callback = function(v) Config.Visuals.TracersEnabled = v end
})
tracerSec:AddLabel("color"):AddColorPicker({
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "V_TracerColor",
    Callback = function(c) Config.Visuals.TracersColor = c end
})
tracerSec:AddLabel("thickness"):AddSlider({
    Min = 1, Max = 5, Rounding = 1,
    Default = 1.5, Flag = "V_TracerThick",
    Callback = function(v) Config.Visuals.TracersThickness = v end
})
tracerSec:AddLabel("origin"):AddDropdown({
    Default = "bottom",
    Values = { "bottom", "top", "center", "mouse" },
    Flag = "V_TracerOrigin",
    Callback = function(v) Config.Visuals.TracersOrigin = v end
})

local selfSec = espSub2:AddSection({ Name = "player chams", Position = "left" })
selfSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "V_Chams",
    Callback = function(v) Config.Visuals.ChamsEnabled = v end
})
selfSec:AddLabel("color"):AddColorPicker({
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "V_ChamsColor",
    Callback = function(c)
        Config.Visuals.ChamsColor = c
        for _, hl in pairs(chamsHighlights) do
            hl.OutlineColor = c
            hl.FillColor = c
        end
    end
})
selfSec:AddLabel("team check"):AddToggle({
    Default = true, Flag = "V_ChamsTeamCheck",
    Callback = function(v) Config.Visuals.ChamsTeamCheck = v end
})
selfSec:AddLabel("fill"):AddToggle({
    Default = true, Flag = "V_ChamsFill",
    Callback = function(v)
        Config.Visuals.ChamsFill = v
        for _, hl in pairs(chamsHighlights) do
            hl.FillTransparency = v
                and (1 - Config.Visuals.ChamsTransparency)
                or 1
        end
    end
})
selfSec:AddLabel("transparency"):AddSlider({
    Min = 0, Max = 1, Rounding = 2,
    Default = 0.5, Flag = "V_ChamsTransp",
    Callback = function(v)
        Config.Visuals.ChamsTransparency = v
        for _, hl in pairs(chamsHighlights) do
            hl.FillTransparency = Config.Visuals.ChamsFill
                and (1 - v) or 1
        end
    end
})

local crossSec = crossSub:AddSection({ Name = "crosshair", Position = "left" })
crossSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "V_Crosshair",
    Callback = function(v) Config.Visuals.CrosshairEnabled = v end
})
crossSec:AddLabel("size"):AddSlider({
    Min = 2, Max = 30, Rounding = 0,
    Default = 10, Flag = "V_CrosshairSize",
    Callback = function(v) Config.Visuals.CrosshairSize = v end
})
crossSec:AddLabel("gap"):AddSlider({
    Min = 0, Max = 20, Rounding = 0,
    Default = 4, Flag = "V_CrosshairGap",
    Callback = function(v) Config.Visuals.CrosshairGap = v end
})
crossSec:AddLabel("thickness"):AddSlider({
    Min = 0.5, Max = 5, Rounding = 1,
    Default = 1.5, Flag = "V_CrosshairThick",
    Callback = function(v) Config.Visuals.CrosshairThick = v end
})
crossSec:AddLabel("color"):AddColorPicker({
    Default = Color3.fromRGB(160, 32, 240),
    Flag = "V_CrosshairColor",
    Callback = function(c) Config.Visuals.CrosshairColor = c end
})
crossSec:AddLabel("outline"):AddToggle({
    Default = true, Flag = "V_CrosshairOutline",
    Callback = function(v) Config.Visuals.CrosshairOutline = v end
})

-- (fov circle controls live on the Legit tab now — single shared instance)

local worldSec = worldSub:AddSection({ Name = "world", Position = "left" })
worldSec:AddLabel("fullbright"):AddToggle({
    Default = false, Flag = "V_Fullbright",
    Callback = function(v) Config.Visuals.FullbrightEnabled = v end
})
worldSec:AddLabel("ambient color"):AddColorPicker({
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "V_FullbrightAmbient",
    Callback = function(c) Config.Visuals.FullbrightAmbient = c end
})

-- ═══════════════════════════════════════════════════════════════
--  WEATHER + AURAS
-- ═══════════════════════════════════════════════════════════════
local weatherSec = worldSub:AddSection({ Name = "weather", Position = "right" })

weatherSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "V_WeatherEnabled",
    Callback = function(v)
        Config.Automation.WeatherEnabled = v
        if v then
            getgenv().WV_startWeather(
                Config.Automation.WeatherType,
                Config.Automation.WeatherColor,
                Config.Automation.WeatherRate
            )
        else
            getgenv().WV_stopWeather()
        end
    end
})
weatherSec:AddLabel("type"):AddDropdown({
    Default = "rain",
    Values  = { "rain", "snow", "light rain" },
    Flag    = "V_WeatherType",
    Callback = function(v)
        Config.Automation.WeatherType = v
        if Config.Automation.WeatherEnabled then
            getgenv().WV_startWeather(
                v,
                Config.Automation.WeatherColor,
                Config.Automation.WeatherRate
            )
        end
    end
})
weatherSec:AddLabel("color"):AddColorPicker({
    Default = Color3.fromRGB(255, 255, 255),
    Flag    = "V_WeatherColor",
    Callback = function(c)
        Config.Automation.WeatherColor = c
        if getgenv().WV_weatherParticle then
            getgenv().WV_weatherParticle.Color = ColorSequence.new(c)
        end
    end
})
weatherSec:AddLabel("rate %"):AddSlider({
    Min = 1, Max = 100, Rounding = 0,
    Default = 100, Flag = "V_WeatherRate",
    Callback = function(v)
        Config.Automation.WeatherRate = v
        if getgenv().WV_weatherParticle then
            local def = getgenv().WV_weatherTypes[Config.Automation.WeatherType]
            if def then getgenv().WV_weatherParticle.Rate = def.Rate * (v / 100) end
        end
    end
})

-- ═══════════════════════════════════════════════════════════════
--  PARTICLE AURAS
-- ═══════════════════════════════════════════════════════════════
getgenv().PA_AuraIds = {
    starlight = "rbxassetid://134645216613107",
    heavenly  = "rbxassetid://139300897520961",
    ribbon    = "rbxassetid://132069507632161",
    sakura    = "rbxassetid://81755778619404",
    angel     = "rbxassetid://97658130917593",
    wind      = "rbxassetid://80694081850877",
    flow      = "rbxassetid://119913533725648",
    star      = "rbxassetid://73754563740680"
}

getgenv().PA_Enabled       = false
getgenv().PA_Color         = Color3.fromRGB(133, 220, 255)
getgenv().PA_CurrentAura   = "angel"
getgenv().PA_Particles     = {}
getgenv().PA_CharConn      = nil
getgenv().PA_AuraObjects   = {}

local function pa_clearParticles()
    for _, p in ipairs(getgenv().PA_Particles) do
        pcall(function() p:Destroy() end)
    end
    getgenv().PA_Particles = {}
end

local function pa_tintObject(root, color)
    local seq = ColorSequence.new(color)
    for _, d in ipairs(root:GetDescendants()) do
        if d.ClassName == "PointLight" then
            d.Color = color
        elseif d.ClassName == "ParticleEmitter"
            or d.ClassName == "Beam"
            or d.ClassName == "Trail" then
            d.Color = seq
        end
    end
end

local function pa_getAuraModel(name)
    if getgenv().PA_AuraObjects[name] then
        return getgenv().PA_AuraObjects[name]
    end
    local id = getgenv().PA_AuraIds[name]
    if not id then return nil end
    local ok, model = pcall(function() return game:GetObjects(id)[1] end)
    if ok and model then
        getgenv().PA_AuraObjects[name] = model
        return model
    end
    return nil
end

local function pa_apply()
    pa_clearParticles()
    local char = LocalPlayer.Character
    if not char or not getgenv().PA_Enabled then return end

    local model = pa_getAuraModel(getgenv().PA_CurrentAura)
    if not model then return end

    local clone = model:Clone()
    pa_tintObject(clone, getgenv().PA_Color)

    for _, child in ipairs(clone:GetChildren()) do
        local target = char:FindFirstChild(child.Name)
        if target then
            for _, sub in ipairs(child:GetChildren()) do
                sub.Parent = target
                table.insert(getgenv().PA_Particles, sub)
            end
        end
    end
    clone:Destroy()
end

getgenv().PA_Apply = pa_apply

getgenv().PA_Toggle = function(state)
    getgenv().PA_Enabled = state
    if getgenv().PA_CharConn then
        getgenv().PA_CharConn:Disconnect()
        getgenv().PA_CharConn = nil
    end
    pa_clearParticles()
    if state then
        pa_apply()
        getgenv().PA_CharConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            pa_apply()
        end)
    end
end

local auraSec = worldSub:AddSection({ Name = "auras", Position = "right" })

auraSec:AddLabel("enabled"):AddToggle({
    Default = false, Flag = "V_AuraEnabled",
    Callback = function(v)
        getgenv().PA_Toggle(v)
    end
})

auraSec:AddLabel("type"):AddDropdown({
    Default = "angel",
    Values  = { "starlight", "heavenly", "ribbon", "sakura",
                "angel", "wind", "flow", "star" },
    Flag    = "V_AuraType",
    Callback = function(v)
        getgenv().PA_CurrentAura = v
        if getgenv().PA_Enabled then getgenv().PA_Apply() end
    end
})

auraSec:AddLabel("color"):AddColorPicker({
    Default = Color3.fromRGB(133, 220, 255),
    Flag    = "V_AuraColor",
    Callback = function(c)
        getgenv().PA_Color = c
        if getgenv().PA_Enabled then getgenv().PA_Apply() end
    end
})

-- ═══════════════════════════════════════════════════════════════
--  FINAL KEYBIND HUD REBUILD
-- ═══════════════════════════════════════════════════════════════
for _, entry in ipairs(Config.TrackedKeybinds) do
    if not getgenv().KB_RowInstances[entry.Name] then
        local row = Instance.new("Frame")
        row.Name = "Row_" .. entry.Name
        row.Size = UDim2.new(1, 0, 0, 16)
        row.BackgroundTransparency = 1
        row.Visible = false
        row.Parent = getgenv().KB_RowsHolder

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(0.65, 0, 1, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = entry.Name
        nameLbl.Font = Enum.Font.GothamMedium
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(200, 202, 212)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local statusLbl = Instance.new("TextLabel", row)
        statusLbl.Size = UDim2.new(0.35, 0, 1, 0)
        statusLbl.Position = UDim2.new(0.65, 0, 0, 0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Font = Enum.Font.GothamMedium
        statusLbl.TextSize = 11
        statusLbl.Text = "[" .. entry.GetKey() .. "]"
        statusLbl.TextColor3 = Color3.fromRGB(130, 134, 146)
        statusLbl.TextXAlignment = Enum.TextXAlignment.Right

        getgenv().KB_RowInstances[entry.Name] = {
            Frame = row,
            NameLabel = nameLbl,
            StatusLabel = statusLbl
        }
    end
end

-- ═══════════════════════════════════════════════════════════════
--  HARDENED UNLOAD
-- ═══════════════════════════════════════════════════════════════
getgenv().Unload = function()
    Config.Unloaded = true

    for _, conn in pairs(getgenv().ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end
    getgenv().ScriptConnections = {}

    pcall(function()
        local c = Config.FovCircle
        if c and c.Remove then c:Remove() end
    end)
    pcall(function()
        local c = Config.TargetLine
        if c and c.Remove then c:Remove() end
    end)
    pcall(function()
        local c = Config.TargetLineOutline
        if c and c.Remove then c:Remove() end
    end)
    pcall(function() fakePosTracer:Remove() end)

    for plr, tag in pairs(nameEspCache) do
        pcall(function() tag:Remove() end)
    end
    nameEspCache = {}

    for plr, box in pairs(boxEspCache) do
        for _, line in pairs(box) do
            pcall(function() line:Remove() end)
        end
    end
    boxEspCache = {}

    for plr, tracer in pairs(tracerCache) do
        pcall(function() tracer:Remove() end)
    end
    tracerCache = {}

    for i = 1, #crossLines do
        pcall(function() crossLines[i]:Remove() end)
        pcall(function() crossLinesOutline[i]:Remove() end)
    end

    for character in pairs(chamsHighlights) do
        pcall(function()
            if chamsHighlights[character] then
                chamsHighlights[character]:Destroy()
            end
        end)
    end
    chamsHighlights = {}

    pcall(function()
        if serverPosPart and serverPosPart.Parent then
            serverPosPart:Destroy()
        end
    end)

    pcall(function() getgenv().WV_stopWeather() end)
    pcall(function() getgenv().PA_Toggle(false) end)

    pcall(function() getgenv().ExoInternal.stopGlue() end)
    pcall(function() getgenv().stopStrafe() end)

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        pcall(function()
            hum.WalkSpeed = 16
            hum.PlatformStand = false
            Camera.CameraSubject = hum
        end)
    end
    if hrp then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    pcall(function() setDesyncState(false) end)

    pcall(function()
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)

    if getgenv().KB_ScreenGui then
        pcall(function() getgenv().KB_ScreenGui:Destroy() end)
    end

    if getgenv().window and getgenv().window.Destroy then
        pcall(function() getgenv().window:Destroy() end)
    end
    if getgenv().NeverLose and getgenv().NeverLose.ScreenGui then
        pcall(function() getgenv().NeverLose.ScreenGui:Destroy() end)
    end

    print("[EXO UNIFIED] unloaded clean.")
end

-- ═══════════════════════════════════════════════════════════════
--  SETTINGS TAB — unload button
-- ═══════════════════════════════════════════════════════════════
local setTab = window:AddTab({ Name = "Settings", Icon = "gear" })
local setSec = setTab:AddSection({ Name = "script", Position = "left" })

pcall(function()
    setSec:AddLabel("rejoin"):AddButton({
        Name = "Rejoin Server",
        Callback = function()
            local TS = Services.TeleportService
            pcall(function()
                TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
        end
    })
end)

pcall(function()
    setSec:AddLabel("copy jobid"):AddButton({
        Name = "Copy JobId",
        Callback = function()
            if setclipboard then
                setclipboard(game.JobId)
            end
        end
    })
end)

pcall(function()
    setSec:AddLabel("unload"):AddButton({
        Name = "Unload Exo Unified",
        Callback = function()
            if getgenv().Unload then getgenv().Unload() end
        end
    })
end)

-- ═══════════════════════════════════════════════════════════════
print("[EXO UNIFIED] chunk 7 loaded — visuals + final wiring.")
print("[EXO UNIFIED] build complete. type 'getgenv().Unload()' to clean up.")
