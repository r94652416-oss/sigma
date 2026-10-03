-- Shop Buyer v1.2 (Toggle: Right Shift)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer

local cfg = {
    path = {"Ignored", "Shop"},
    cooldown = 1.2,
    teleport = true,
    key = Enum.KeyCode.RightShift,
}

local function getShop()
    local folder = Workspace
    for _, name in ipairs(cfg.path) do
        folder = folder:FindFirstChild(name)
        if not folder then return nil end
    end
    return folder
end

local shopData = {
    items = {},
    bindings = {},
    cds = {},
}

local function scanShop()
    local folder = getShop()
    if not folder then return warn("Shop folder missing!") end
    
    shopData.items = {}
    for _, item in ipairs(folder:GetChildren()) do
        local cd = item:FindFirstChildOfClass("ClickDetector") or item:FindFirstChild("ClickDetector", true)
        if cd then
            shopData.items[item.Name] = { model = item, cd = cd }
        end
    end
end

local function fire(cd)
    if not cd then return end
    pcall(fireclickdetector, cd)
    pcall(fireclickdetector, cd, 0)
end

local function buy(name)
    local data = shopData.items[name]
    if not data then return false end
    
    local now = os.clock()
    if shopData.cds[name] and now - shopData.cds[name] < cfg.cooldown then return false end
    
    local cd = data.cd
    if not cd or not cd.Parent then
        scanShop()
        data = shopData.items[name]
        if not data then return false end
        cd = data.cd
    end

    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local pos = data.model:GetPivot().Position
    local dist = (hrp.Position - pos).Magnitude

    if dist <= (cd.MaxActivationDistance or 32) then
        fire(cd)
        task.wait(0.05)
        fire(cd)
        shopData.cds[name] = os.clock()
        return true
    end

    if not cfg.teleport then return false end

    local oldCF = hrp.CFrame
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    hrp.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.12)
    fire(cd); task.wait(0.05); fire(cd)
    task.wait(0.15)
    hrp.CFrame = oldCF
    shopData.cds[name] = os.clock()
    return true
end

-- UI Setup
local function createUI()
    local parent = (gethui and gethui()) or CoreGui
    local gui = Instance.new("ScreenGui", parent)
    gui.Name = "ShopGui"
    gui.ResetOnSpawn = false
    gui.Enabled = false

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 340, 0, 450)
    main.Position = UDim2.new(0, 30, 0.5, -225)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    main.BorderSizePixel = 0
    main.Draggable = true
    main.Active = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(45, 45, 55)

    local topBar = Instance.new("Frame", main)
    topBar.Size = UDim2.new(1, 0, 0, 32)
    topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    topBar.BorderSizePixel = 0
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 6)

    local title = Instance.new("TextLabel", topBar)
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Shop Menu [RightShift]"

    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Size = UDim2.new(1, -12, 1, -44)
    scroll.Position = UDim2.new(0, 6, 0, 38)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local bindButtons = {}
    local capturing = nil

    local function updateBinds()
        for name, btn in pairs(bindButtons) do
            local boundKey = nil
            for k, v in pairs(shopData.bindings) do
                if v == name then boundKey = k; break end
            end
            btn.Text = boundKey and ("[" .. boundKey .. "]") or "[ - ]"
        end
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        
        if capturing then
            local kName = input.KeyCode.Name
            if kName == cfg.key.Name then
                capturing = nil
                return
            end
            if kName == "Escape" or kName == "Backspace" then
                for k, v in pairs(shopData.bindings) do
                    if v == capturing then shopData.bindings[k] = nil end
                end
            else
                shopData.bindings[kName] = capturing
            end
            capturing = nil
            updateBinds()
            return
        end

        if input.KeyCode == cfg.key then
            gui.Enabled = not gui.Enabled
        elseif not UserInputService:GetFocusedTextBox() then
            local item = shopData.bindings[input.KeyCode.Name]
            if item then buy(item) end
        end
    end)

    local function rebuild()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        bindButtons = {}

        local names = {}
        for name in pairs(shopData.items) do table.insert(names, name) end
        table.sort(names)

        for _, name in ipairs(names) do
            local row = Instance.new("Frame", scroll)
            row.Size = UDim2.new(1, -2, 0, 36)
            row.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
            row.BorderSizePixel = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

            local lbl = Instance.new("TextLabel", row)
            lbl.Size = UDim2.new(1, -115, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = name

            local bBtn = Instance.new("TextButton", row)
            bBtn.Size = UDim2.new(0, 50, 0, 24)
            bBtn.Position = UDim2.new(1, -110, 0.5, -12)
            bBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            bBtn.BorderSizePixel = 0
            bBtn.Font = Enum.Font.GothamBold
            bBtn.TextSize = 10
            bBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            bBtn.Text = "[ - ]"
            Instance.new("UICorner", bBtn).CornerRadius = UDim.new(0, 4)

            bBtn.MouseButton1Click:Connect(function()
                capturing = name
                bBtn.Text = "[...]"
            end)
            bindButtons[name] = bBtn

            local buyBtn = Instance.new("TextButton", row)
            buyBtn.Size = UDim2.new(0, 50, 0, 24)
            buyBtn.Position = UDim2.new(1, -54, 0.5, -12)
            buyBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
            buyBtn.BorderSizePixel = 0
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.TextSize = 10
            buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            buyBtn.Text = "BUY"
            Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 4)

            buyBtn.MouseButton1Click:Connect(function()
                buy(name)
            end)
        end
        updateBinds()
    end

    scanShop()
    rebuild()
    return gui
end

createUI()
print("Shop script loaded successfully.")
