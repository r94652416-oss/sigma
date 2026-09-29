-- ============================================================
-- SHOP BUYER MENU — toggle with Right Shift
-- ============================================================

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    ShopFolderPath = { "Ignored", "Shop" },
    Cooldown       = 1.2,
    AllowTeleport  = true,
    Debug          = true,
    ToggleKey      = Enum.KeyCode.RightShift,   -- ← menu toggle
}

-- ============================================================
-- RESOLVE SHOP FOLDER
-- ============================================================
local function getShopFolder()
    local obj = Workspace
    for _, name in ipairs(CONFIG.ShopFolderPath) do
        obj = obj:FindFirstChild(name)
        if not obj then return nil end
    end
    return obj
end

-- ============================================================
-- SHOP STATE
-- ============================================================
local Shop = {
    items     = {},   -- [name] = { model = Model, cd = ClickDetector }
    bindings  = {},   -- [KeyCode.Name] = itemName
    cooldowns = {},   -- [itemName] = lastBuyTime
}

-- ============================================================
-- SCAN SHOP
-- ============================================================
local function scanShop()
    local folder = getShopFolder()
    if not folder then
        warn("[SHOP] Shop folder not found")
        return
    end
    Shop.items = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Accessory") then
            local cd = child:FindFirstChildOfClass("ClickDetector")
                or child:FindFirstChild("ClickDetector", true)
            if cd then
                Shop.items[child.Name] = { model = child, cd = cd }
            end
        end
    end
    local count = 0
    for _ in pairs(Shop.items) do count = count + 1 end
    print(string.format("[SHOP] Scanned %d items", count))
end

-- ============================================================
-- BUY
-- ============================================================
local function fireClick(cd)
    if not cd then return end
    local ok = pcall(fireclickdetector, cd)
    if not ok then pcall(fireclickdetector, cd, 0) end
end

local function buyItem(itemName)
    local item = Shop.items[itemName]
    if not item then
        warn("[SHOP] Unknown item: " .. tostring(itemName))
        return false
    end
    local now = os.clock()
    if Shop.cooldowns[itemName] and now - Shop.cooldowns[itemName] < CONFIG.Cooldown then
        return false
    end

    local cd = item.cd
    if not cd or not cd.Parent then
        scanShop()
        item = Shop.items[itemName]
        if not item then return false end
        cd = item.cd
    end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local model = item.model
    local shopPos = model:GetPivot().Position
    local dist = (hrp.Position - shopPos).Magnitude
    local maxDist = cd.MaxActivationDistance or 32

    if dist <= maxDist then
        fireClick(cd); task.wait(0.05); fireClick(cd)
        Shop.cooldowns[itemName] = os.clock()
        return true
    end

    if not CONFIG.AllowTeleport then return false end

    local savedCF  = hrp.CFrame
    local savedVel = hrp.AssemblyLinearVelocity
    hrp.CFrame = CFrame.new(shopPos + Vector3.new(0, 3, 0))
    hrp.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.12)
    fireClick(cd); task.wait(0.05); fireClick(cd); task.wait(0.05); fireClick(cd)
    task.wait(0.15)
    hrp.CFrame = savedCF
    hrp.AssemblyLinearVelocity = savedVel
    Shop.cooldowns[itemName] = os.clock()
    return true
end

-- ============================================================
-- UI
-- ============================================================
local function makeUI()
    local parentGui = (gethui and gethui()) or CoreGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "SHOP_BUYER_UI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled = false          -- start hidden
    gui.Parent = parentGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 360, 0, 480)
    main.Position = UDim2.new(0, 20, 0.5, -240)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 70)
    stroke.Thickness = 1
    stroke.Parent = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    header.BorderSizePixel = 0
    header.Parent = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(230, 230, 240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Shop Buyer  •  RightShift"
    title.Parent = header

    local refresh = Instance.new("TextButton")
    refresh.Size = UDim2.new(0, 26, 0, 26)
    refresh.Position = UDim2.new(1, -34, 0, 5)
    refresh.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    refresh.BorderSizePixel = 0
    refresh.Font = Enum.Font.GothamBold
    refresh.TextSize = 14
    refresh.TextColor3 = Color3.fromRGB(220, 220, 230)
    refresh.Text = "⟳"
    refresh.Parent = header
    Instance.new("UICorner", refresh).CornerRadius = UDim.new(0, 6)

    local minimize = Instance.new("TextButton")
    minimize.Size = UDim2.new(0, 26, 0, 26)
    minimize.Position = UDim2.new(1, -64, 0, 5)
    minimize.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    minimize.BorderSizePixel = 0
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 14
    minimize.TextColor3 = Color3.fromRGB(220, 220, 230)
    minimize.Text = "—"
    minimize.Parent = header
    Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 6)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -50)
    scroll.Position = UDim2.new(0, 8, 0, 42)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = main

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll

    local minimized = false
    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        scroll.Visible = not minimized
        if minimized then
            main.Size = UDim2.new(0, 360, 0, 36)
            minimize.Text = "+"
        else
            main.Size = UDim2.new(0, 360, 0, 480)
            minimize.Text = "—"
        end
    end)

    -- BIND CAPTURE
    local bindButtons = {}
    local captureConn

    local function refreshBindLabels()
        for itemName, btn in pairs(bindButtons) do
            local bound = nil
            for keyName, name in pairs(Shop.bindings) do
                if name == itemName then bound = keyName; break end
            end
            btn.Text = bound and ("[" .. bound .. "]") or "[ — ]"
        end
    end

    local function startCapture(itemName, btn)
        btn.Text = "[ press… ]"
        if captureConn then captureConn:Disconnect() end
        captureConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local keyName = input.KeyCode.Name

            -- Don't let them bind to RightShift (that's the menu toggle)
            if keyName == CONFIG.ToggleKey.Name then
                btn.Text = "[ — ]"
                if captureConn then captureConn:Disconnect(); captureConn = nil end
                return
            end

            Shop.bindings[keyName] = nil
            if keyName == "Escape" or keyName == "Backspace" then
                for k, v in pairs(Shop.bindings) do
                    if v == itemName then Shop.bindings[k] = nil end
                end
                print("[SHOP] Unbound " .. itemName)
            else
                Shop.bindings[keyName] = itemName
                print(string.format("[SHOP] Bound %s → %s", keyName, itemName))
            end
            if captureConn then captureConn:Disconnect(); captureConn = nil end
            refreshBindLabels()
        end)
    end

    local function buildRow(itemName)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 40)
        row.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        row.BorderSizePixel = 0
        row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1
        nameLbl.Size = UDim2.new(1, -130, 1, 0)
        nameLbl.Position = UDim2.new(0, 10, 0, 0)
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Text = itemName
        nameLbl.Parent = row

        local bind = Instance.new("TextButton")
        bind.Size = UDim2.new(0, 62, 0, 26)
        bind.Position = UDim2.new(1, -128, 0.5, -13)
        bind.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        bind.BorderSizePixel = 0
        bind.Font = Enum.Font.GothamBold
        bind.TextSize = 11
        bind.TextColor3 = Color3.fromRGB(220, 220, 230)
        bind.Text = "[ — ]"
        bind.Parent = row
        Instance.new("UICorner", bind).CornerRadius = UDim.new(0, 6)
        bind.MouseButton1Click:Connect(function() startCapture(itemName, bind) end)
        bindButtons[itemName] = bind

        local buy = Instance.new("TextButton")
        buy.Size = UDim2.new(0, 56, 0, 26)
        buy.Position = UDim2.new(1, -62, 0.5, -13)
        buy.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        buy.BorderSizePixel = 0
        buy.Font = Enum.Font.GothamBold
        buy.TextSize = 11
        buy.TextColor3 = Color3.fromRGB(255, 255, 255)
        buy.Text = "BUY"
        buy.Parent = row
        Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 6)
        buy.MouseButton1Click:Connect(function() buyItem(itemName) end)
    end

    local function rebuildList()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        bindButtons = {}
        local names = {}
        for name in pairs(Shop.items) do table.insert(names, name) end
        table.sort(names)
        for _, name in ipairs(names) do buildRow(name) end
        refreshBindLabels()
        print("[SHOP] UI rebuilt with", #names, "items")
    end

    refresh.MouseButton1Click:Connect(function()
        scanShop()
        rebuildList()
    end)

    return gui, rebuildList
end

-- ============================================================
-- KEYBIND DISPATCH (item binds)
-- ============================================================
local function setupBindDispatch()
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if UserInputService:GetFocusedTextBox() then return end
        -- Ignore the menu toggle key
        if input.KeyCode == CONFIG.ToggleKey then return end

        local itemName = Shop.bindings[input.KeyCode.Name]
        if itemName then
            buyItem(itemName)
        end
    end)
end

-- ============================================================
-- MENU TOGGLE (RightShift)
-- ============================================================
local function setupMenuToggle(gui)
    local wasDown = false
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == CONFIG.ToggleKey and not wasDown then
            wasDown = true
            gui.Enabled = not gui.Enabled
            print("[SHOP] Menu", gui.Enabled and "opened" or "closed")
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard
           and input.KeyCode == CONFIG.ToggleKey then
            wasDown = false
        end
    end)
end

-- ============================================================
-- WATCH SHOP FOR NEW ITEMS
-- ============================================================
local function watchShop()
    local folder = getShopFolder()
    if not folder then return end
    folder.ChildAdded:Connect(function()
        task.wait(0.2)
        scanShop()
        if _G.SHOP_UI_REBUILD then pcall(_G.SHOP_UI_REBUILD) end
    end)
    folder.ChildRemoved:Connect(function()
        task.wait(0.2)
        scanShop()
        if _G.SHOP_UI_REBUILD then pcall(_G.SHOP_UI_REBUILD) end
    end)
end

-- ============================================================
-- BOOT
-- ============================================================
scanShop()
local gui, rebuildList = makeUI()
_G.SHOP_UI_REBUILD = rebuildList
rebuildList()
setupBindDispatch()
setupMenuToggle(gui)
watchShop()

_G.SHOP_UI = gui
_G.SHOP_BUYER = {
    Config  = CONFIG,
    Shop    = Shop,
    Buy     = buyItem,
    Scan    = scanShop,
    Rebuild = rebuildList,
    Toggle  = function() gui.Enabled = not gui.Enabled end,
}

print("[SHOP] Loaded. Press RightShift to toggle the menu.")
print("  Click BUY on any item to buy it.")
print("  Click [ — ] next to an item and press a key to bind it.")
print("  Escape / Backspace during bind = unbind.")
print("  RightShift cannot be bound (reserved for menu toggle).")