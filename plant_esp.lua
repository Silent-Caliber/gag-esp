local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local espMap = {}

local cropCategories = {
    Obtainable = {
        Common = {"Carrot", "Strawberry"},
        Uncommon = {"Blueberry", "Manuka Flower", "Orange Tulip", "Rose", "Lavender"},
        Rare = {"Tomato", "Corn", "Dandelion", "Daffodil", "Nectarshade", "Raspberry", "Foxglove"},
        Legendary = {"Watermelon", "Pumpkin", "Apple", "Bamboo", "Lilac", "Lumira"},
        Mythical = {"Coconut", "Cactus", "Dragon Fruit", "Honeysuckle", "Mango", "Nectarine", "Peach", "Pineapple", "Pink Lily", "Purple Dahlia"},
        Divine = {"Grape", "Mushroom", "Pepper", "Cacao", "Hive Fruit", "Sunflower"},
        Prismatic = {"Beanstalk", "Ember Lily"},
    },
    Unobtainable = {
        Common = {"Chocolate crops"},
        Uncommon = {"Red Lollipop", "Nightshade"},
        Rare = {"Candy Sunflower", "Mint", "Glowshroom", "Pear"},
        Legendary = {"Cranberry", "Durian", "Easter Egg", "Papaya"},
        Mythical = {"Celestiberry", "Blood Banana", "Moon Melon", "Eggplant", "Passionfruit", "Lemon", "Banana"},
        Divine = {"Cherry Blossom", "Crimson Vine", "Candy Blossom", "Lotus", "Venus Fly Trap", "Cursed Fruit", "Soul Fruit", "Mega Mushroom", "Moon Blossom", "Moon Mango"},
    }
}

local cropSet = {}
for obtain, rarities in pairs(cropCategories) do
    for rarity, crops in pairs(rarities) do
        for _, crop in ipairs(crops) do
            cropSet[crop:lower()] = {obtain=obtain, rarity=rarity}
        end
    end
end

local rarityOrder = {"Common","Uncommon","Rare","Legendary","Mythical","Divine","Prismatic"}
local rarityColors = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare = Color3.fromRGB(80, 120, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythical = Color3.fromRGB(255, 100, 255),
    Divine = Color3.fromRGB(255, 90, 90),
    Prismatic = Color3.fromRGB(100,255,255),
}

local function getCategorizedTypes()
    local cropsByCategory = {}
    for obtain, rarities in pairs(cropCategories) do
        cropsByCategory[obtain] = {}
        for rarity, _ in pairs(rarities) do
            cropsByCategory[obtain][rarity] = {}
        end
    end
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") then
            local info = cropSet[model.Name:lower()]
            if info then
                cropsByCategory[info.obtain][info.rarity][model.Name] = true
            end
        end
    end
    return cropsByCategory
end

-- UI Sizes (adjusted for Infinite Sprinkler row)
local normalSize = UDim2.new(0, 340, 0, 250)
local compactSize = UDim2.new(0, 210, 0, 160)
local normalPos = UDim2.new(0, 10, 0, 60)
local compactPos = UDim2.new(0, 10, 0, 20)

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlantESPSelector"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = normalSize
Frame.Position = normalPos
Frame.BackgroundTransparency = 1
Frame.Active = true
Frame.Draggable = true

local TitleBar = Instance.new("Frame", Frame)
TitleBar.Size = UDim2.new(1, 0, 0, 22)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 0.25
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TitleBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Grow a Garden ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14

local LegendCol = Instance.new("Frame", Frame)
LegendCol.Size = UDim2.new(0, 65, 1, -22)
LegendCol.Position = UDim2.new(0, 0, 0, 22)
LegendCol.BackgroundTransparency = 0.2
LegendCol.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LegendCol.BorderSizePixel = 0

local LegendLabel = Instance.new("TextLabel", LegendCol)
LegendLabel.Size = UDim2.new(1, 0, 0, 16)
LegendLabel.Position = UDim2.new(0, 0, 0, 0)
LegendLabel.BackgroundTransparency = 1
LegendLabel.Text = "RARITY"
LegendLabel.TextColor3 = Color3.fromRGB(255,255,255)
LegendLabel.Font = Enum.Font.SourceSansBold
LegendLabel.TextSize = 12

local LegendListLayout = Instance.new("UIListLayout", LegendCol)
LegendListLayout.Padding = UDim.new(0, 2)
LegendListLayout.SortOrder = Enum.SortOrder.LayoutOrder

for _, rarity in ipairs(rarityOrder) do
    local label = Instance.new("TextLabel", LegendCol)
    label.Size = UDim2.new(1, 0, 0, 14)
    label.BackgroundTransparency = 1
    label.Text = rarity
    label.TextColor3 = rarityColors[rarity]
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 12
end

local ObtainCol = Instance.new("Frame", Frame)
ObtainCol.Size = UDim2.new(0, 120, 1, -52)
ObtainCol.Position = UDim2.new(0, 65, 0, 22)
ObtainCol.BackgroundTransparency = 0.2
ObtainCol.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ObtainCol.BorderSizePixel = 0

local ObtainLabel = Instance.new("TextLabel", ObtainCol)
ObtainLabel.Size = UDim2.new(1, 0, 0, 16)
ObtainLabel.Position = UDim2.new(0, 0, 0, 0)
ObtainLabel.BackgroundTransparency = 1
ObtainLabel.Text = "Obtainable"
ObtainLabel.TextColor3 = Color3.fromRGB(90, 255, 90)
ObtainLabel.Font = Enum.Font.SourceSansBold
ObtainLabel.TextSize = 12

local ObtainScroll = Instance.new("ScrollingFrame", ObtainCol)
ObtainScroll.Size = UDim2.new(1, 0, 1, -16)
ObtainScroll.Position = UDim2.new(0, 0, 0, 16)
ObtainScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
ObtainScroll.BackgroundTransparency = 1
ObtainScroll.ScrollBarThickness = 4

local ObtainListLayout = Instance.new("UIListLayout", ObtainScroll)
ObtainListLayout.Padding = UDim.new(0, 1)

local UnobtainCol = Instance.new("Frame", Frame)
UnobtainCol.Size = UDim2.new(0, 120, 1, -52)
UnobtainCol.Position = UDim2.new(0, 185, 0, 22)
UnobtainCol.BackgroundTransparency = 0.2
UnobtainCol.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
UnobtainCol.BorderSizePixel = 0

local UnobtainLabel = Instance.new("TextLabel", UnobtainCol)
UnobtainLabel.Size = UDim2.new(1, 0, 0, 16)
UnobtainLabel.Position = UDim2.new(0, 0, 0, 0)
UnobtainLabel.BackgroundTransparency = 1
UnobtainLabel.Text = "Unobtainable"
UnobtainLabel.TextColor3 = Color3.fromRGB(255, 180, 90)
UnobtainLabel.Font = Enum.Font.SourceSansBold
UnobtainLabel.TextSize = 12

local UnobtainScroll = Instance.new("ScrollingFrame", UnobtainCol)
UnobtainScroll.Size = UDim2.new(1, 0, 1, -16)
UnobtainScroll.Position = UDim2.new(0, 0, 0, 16)
UnobtainScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
UnobtainScroll.BackgroundTransparency = 1
UnobtainScroll.ScrollBarThickness = 4

local UnobtainListLayout = Instance.new("UIListLayout", UnobtainScroll)
UnobtainListLayout.Padding = UDim.new(0, 1)

local NearbyFrame = Instance.new("Frame", Frame)
NearbyFrame.Size = UDim2.new(0, 275, 0, 24)
NearbyFrame.Position = UDim2.new(0, 65, 1, -52)
NearbyFrame.BackgroundTransparency = 0.3
NearbyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
NearbyFrame.BorderSizePixel = 0

local NearbyLabel = Instance.new("TextLabel", NearbyFrame)
NearbyLabel.Size = UDim2.new(1, 0, 0, 12)
NearbyLabel.Position = UDim2.new(0, 0, 0, 0)
NearbyLabel.BackgroundTransparency = 1
NearbyLabel.Text = "Nearby"
NearbyLabel.TextColor3 = Color3.fromRGB(255,255,255)
NearbyLabel.Font = Enum.Font.SourceSansBold
NearbyLabel.TextSize = 11

local NearbyScroll = Instance.new("ScrollingFrame", NearbyFrame)
NearbyScroll.Size = UDim2.new(1, 0, 1, -12)
NearbyScroll.Position = UDim2.new(0, 0, 0, 12)
NearbyScroll.CanvasSize = UDim2.new(0, 0, 0, 100)
NearbyScroll.BackgroundTransparency = 1
NearbyScroll.ScrollBarThickness = 2

local NearbyListLayout = Instance.new("UIListLayout", NearbyScroll)
NearbyListLayout.Padding = UDim.new(0, 1)

-- Infinite Sprinkler UI Row (below NearbyFrame)
local SprinklerFrame = Instance.new("Frame", Frame)
SprinklerFrame.Size = UDim2.new(0, 275, 0, 24)
SprinklerFrame.Position = UDim2.new(0, 65, 1, -28)
SprinklerFrame.BackgroundTransparency = 0.3
SprinklerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SprinklerFrame.BorderSizePixel = 0

local SprinklerLabel = Instance.new("TextLabel", SprinklerFrame)
SprinklerLabel.Size = UDim2.new(0.6, 0, 1, 0)
SprinklerLabel.Position = UDim2.new(0, 4, 0, 0)
SprinklerLabel.BackgroundTransparency = 1
SprinklerLabel.Text = "Infinite Sprinkler"
SprinklerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SprinklerLabel.Font = Enum.Font.SourceSansBold
SprinklerLabel.TextSize = 12
SprinklerLabel.TextXAlignment = Enum.TextXAlignment.Left

local SprinklerToggleBtn = Instance.new("TextButton", SprinklerFrame)
SprinklerToggleBtn.Size = UDim2.new(0, 50, 0, 18)
SprinklerToggleBtn.Position = UDim2.new(1, -54, 0.5, -9)
SprinklerToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SprinklerToggleBtn.TextColor3 = Color3.new(1, 1, 1)
SprinklerToggleBtn.Text = "OFF"
SprinklerToggleBtn.Font = Enum.Font.SourceSansBold
SprinklerToggleBtn.TextSize = 14
SprinklerToggleBtn.AutoButtonColor = true
SprinklerToggleBtn.BorderSizePixel = 0
local corner = Instance.new("UICorner", SprinklerToggleBtn)
corner.CornerRadius = UDim.new(0, 6)

LegendCol.Parent = Frame
ObtainCol.Parent = Frame
UnobtainCol.Parent = Frame
NearbyFrame.Parent = Frame
SprinklerFrame.Parent = Frame

local selectedTypes = {}

local function createToggles()
    for _, child in ipairs(ObtainScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, child in ipairs(UnobtainScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local cropsByCategory = getCategorizedTypes()
    for _, rarity in ipairs(rarityOrder) do
        if cropCategories.Obtainable[rarity] then
            for _, crop in ipairs(cropCategories.Obtainable[rarity]) do
                if cropsByCategory.Obtainable[rarity][crop] then
                    local btn = Instance.new("TextButton", ObtainScroll)
                    btn.Size = UDim2.new(1, -4, 0, 14)
                    btn.BackgroundColor3 = rarityColors[rarity] or Color3.fromRGB(50, 80, 50)
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.Text = "[OFF] " .. crop
                    btn.AutoButtonColor = true
                    btn.TextSize = 10
                    btn.Font = Enum.Font.SourceSansBold
                    btn.MouseButton1Click:Connect(function()
                        selectedTypes[crop] = not selectedTypes[crop]
                        btn.Text = (selectedTypes[crop] and "[ON] " or "[OFF] ") .. crop
                    end)
                end
            end
        end
    end
    for _, rarity in ipairs(rarityOrder) do
        if cropCategories.Unobtainable[rarity] then
            for _, crop in ipairs(cropCategories.Unobtainable[rarity]) do
                if cropsByCategory.Unobtainable[rarity][crop] then
                    local btn = Instance.new("TextButton", UnobtainScroll)
                    btn.Size = UDim2.new(1, -4, 0, 14)
                    btn.BackgroundColor3 = rarityColors[rarity] or Color3.fromRGB(50, 80, 50)
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.Text = "[OFF] " .. crop
                    btn.AutoButtonColor = true
                    btn.TextSize = 10
                    btn.Font = Enum.Font.SourceSansBold
                    btn.MouseButton1Click:Connect(function()
                        selectedTypes[crop] = not selectedTypes[crop]
                        btn.Text = (selectedTypes[crop] and "[ON] " or "[OFF] ") .. crop
                    end)
                end
            end
        end
    end
end

createToggles()
spawn(function()
    while true do
        wait(10)
        createToggles()
    end
end)

-- Toggle UI Button (top left)
local function createToggleBtn(screenGui, frame)
    if screenGui:FindFirstChild("ShowHideESPBtn") then
        screenGui.ShowHideESPBtn:Destroy()
    end

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ShowHideESPBtn"
    ToggleBtn.Parent = screenGui
    ToggleBtn.Size = UDim2.new(0, 38, 0, 38)
    ToggleBtn.Position = UDim2.new(0, 6, 0, 6)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    ToggleBtn.Text = "✖"
    ToggleBtn.Font = Enum.Font.SourceSansBold
    ToggleBtn.TextSize = 22
    ToggleBtn.AutoButtonColor = true
    ToggleBtn.BackgroundTransparency = 0.15
    ToggleBtn.ZIndex = 100
    ToggleBtn.BorderSizePixel = 0

    local corner = Instance.new("UICorner", ToggleBtn)
    corner.CornerRadius = UDim.new(1, 0)

    local shadow = Instance.new("ImageLabel", ToggleBtn)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.Size = UDim2.new(1.4, 0, 1.4, 0)
    shadow.Position = UDim2.new(-0.2, 0, -0.2, 0)
    shadow.ZIndex = 99

    local uiVisible = true
    frame.Visible = uiVisible

    ToggleBtn.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        frame.Visible = uiVisible
        ToggleBtn.Text = uiVisible and "✖" or "⟳"
    end)
end

createToggleBtn(ScreenGui, Frame)

-- UI Size Toggle Button (top right)
local function createSizeToggleBtn(frame)
    if frame:FindFirstChild("SizeToggleBtn") then
        frame.SizeToggleBtn:Destroy()
    end

    local btn = Instance.new("TextButton")
    btn.Name = "SizeToggleBtn"
    btn.Parent = frame
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = UDim2.new(1, -36, 0, 2)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "🔍"
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.AutoButtonColor = true
    btn.BackgroundTransparency = 0.13
    btn.ZIndex = 101
    btn.BorderSizePixel = 0
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(1, 0)

    local compact = false

    btn.MouseButton1Click:Connect(function()
        compact = not compact
        if compact then
            frame.Size = compactSize
            frame.Position = compactPos
            ObtainCol.Size = UDim2.new(0, 70, 1, -52)
            ObtainCol.Position = UDim2.new(0, 65, 0, 22)
            UnobtainCol.Size = UDim2.new(0, 70, 1, -52)
            UnobtainCol.Position = UDim2.new(0, 135, 0, 22)
            NearbyFrame.Size = UDim2.new(0, 140, 0, 16)
            NearbyFrame.Position = UDim2.new(0, 65, 1, -36)
            SprinklerFrame.Size = UDim2.new(0, 140, 0, 16)
            SprinklerFrame.Position = UDim2.new(0, 65, 1, -18)
        else
            frame.Size = normalSize
            frame.Position = normalPos
            ObtainCol.Size = UDim2.new(0, 120, 1, -52)
            ObtainCol.Position = UDim2.new(0, 65, 0, 22)
            UnobtainCol.Size = UDim2.new(0, 120, 1, -52)
            UnobtainCol.Position = UDim2.new(0, 185, 0, 22)
            NearbyFrame.Size = UDim2.new(0, 275, 0, 24)
            NearbyFrame.Position = UDim2.new(0, 65, 1, -52)
            SprinklerFrame.Size = UDim2.new(0, 275, 0, 24)
            SprinklerFrame.Position = UDim2.new(0, 65, 1, -28)
        end
    end)
end

createSizeToggleBtn(Frame)

-- ESP Core
local function getPP(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _,c in ipairs(model:GetChildren()) do
        if c:IsA("BasePart") then
            model.PrimaryPart = c
            return c
        end
    end
    return nil
end

local function formatNumber(n)
    local str = string.format("%.3f", n)
    local before, after = str:match("^(.-)%.(%d+)$")
    before = before:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return before .. "." .. after
end

local function createESP(model, labelText, price)
    local pp = getPP(model)
    if not pp then return end

    -- Only ONE BillboardGui per plant
    local bg = model:FindFirstChild("PlantESP")
    if not bg then
        bg = Instance.new("BillboardGui")
        bg.Name = "PlantESP"
        bg.Adornee = pp
        bg.Size = UDim2.new(0, 140, 0, 38)
        bg.StudsOffset = Vector3.new(0, 4, 0)
        bg.AlwaysOnTop = true
        bg.Parent = model
    end

    -- Main label (name/weight)
    local tl = bg:FindFirstChild("MainLabel")
    if not tl then
        tl = Instance.new("TextLabel")
        tl.Name = "MainLabel"
        tl.Size = UDim2.new(1, 0, 0, 18)
        tl.Position = UDim2.new(0, 0, 0, 0)
        tl.BackgroundTransparency = 1
        tl.TextColor3 = Color3.new(1, 1, 1)
        tl.TextStrokeColor3 = Color3.new(0, 0, 0)
        tl.TextStrokeTransparency = 0.2
        tl.Font = Enum.Font.SourceSansBold
        tl.TextSize = 12
        tl.TextWrapped = true
        tl.RichText = true
        tl.Parent = bg
    end
    tl.Text = labelText

    -- Price label (green, below)
    local priceLabel = bg:FindFirstChild("PriceESP")
    if not priceLabel then
        priceLabel = Instance.new("TextLabel")
        priceLabel.Name = "PriceESP"
        priceLabel.Size = UDim2.new(1, 0, 0, 16)
        priceLabel.Position = UDim2.new(0, 0, 0, 18)
        priceLabel.BackgroundTransparency = 1
        priceLabel.TextColor3 = Color3.fromRGB(80,255,80)
        priceLabel.TextStrokeTransparency = 0.2
        priceLabel.Font = Enum.Font.SourceSansBold
        priceLabel.TextSize = 12
        priceLabel.TextWrapped = true
        priceLabel.RichText = true
        priceLabel.Parent = bg
    end
    if price then
        priceLabel.Text = "<font color='rgb(80,255,80)'>" .. formatNumber(price) .. "₵</font>"
    else
        priceLabel.Text = ""
    end

    espMap[model] = tl
    return tl
end

local function cleanup(validModels)
    for model, gui in pairs(espMap) do
        if not validModels[model] then
            if gui.Parent and gui.Parent.Parent then gui.Parent:Destroy() end
            espMap[model] = nil
        end
    end
end

local maxDistance = 25
local maxESP = 10
local nearbyDistance = 15

local function updateNearbyPlants()
    for _, child in ipairs(NearbyScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local found = {}
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and cropSet[model.Name:lower()] then
            local pp = getPP(model)
            if pp then
                local dist = (pp.Position - root.Position).Magnitude
                if dist <= nearbyDistance then
                    found[#found+1] = {model=model, dist=dist}
                end
            end
        end
    end
    table.sort(found, function(a,b) return a.dist < b.dist end)
    for _, entry in ipairs(found) do
        local label = Instance.new("TextLabel", NearbyScroll)
        label.Size = UDim2.new(1, -4, 0, 14)
        label.BackgroundTransparency = 1
        local rarity = cropSet[entry.model.Name:lower()] and cropSet[entry.model.Name:lower()].rarity or "Common"
        label.TextColor3 = rarityColors[rarity] or Color3.new(1,1,1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 10
        label.Text = string.format("%s (%.1f)", entry.model.Name, entry.dist)
    end
end

local function update()
    local validModels = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local nearest = {}
    if root then
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and selectedTypes[model.Name] then
                local pp = getPP(model)
                if pp then
                    local dist = (pp.Position - root.Position).Magnitude
                    if dist <= maxDistance then
                        table.insert(nearest, {model=model, dist=dist})
                    end
                end
            end
        end
        table.sort(nearest, function(a, b) return a.dist < b.dist end)
        for i = 1, math.min(#nearest, maxESP) do
            local model = nearest[i].model
            local weight, price
            for _, child in ipairs(model:GetChildren()) do
                if child:IsA("NumberValue") and child.Name:lower():find("weight") then
                    weight = child.Value
                elseif child:IsA("NumberValue") and (child.Name:lower():find("price") or child.Name:lower():find("sell")) then
                    price = child.Value
                end
            end
            local label = model.Name
            if weight then
                label = label .. "\nWt.: " .. tostring(weight)
            end
            createESP(model, label, price)
            validModels[model] = true
        end
    end
    cleanup(validModels)
    updateNearbyPlants()
end

-- Infinite Sprinkler Logic
local infiniteSprinklerEnabled = false

local function sprinklerAction()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local range = 15
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and cropSet[model.Name:lower()] then
            local pp = getPP(model)
            if pp then
                local dist = (pp.Position - root.Position).Magnitude
                if dist <= range then
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local WaterEvent = ReplicatedStorage:FindFirstChild("WaterPlant")
                    if WaterEvent and WaterEvent:IsA("RemoteEvent") then
                        WaterEvent:FireServer(model)
                    end
                end
            end
        end
    end
end

SprinklerToggleBtn.MouseButton1Click:Connect(function()
    infiniteSprinklerEnabled = not infiniteSprinklerEnabled
    SprinklerToggleBtn.Text = infiniteSprinklerEnabled and "ON" or "OFF"
    SprinklerToggleBtn.BackgroundColor3 = infiniteSprinklerEnabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(50, 50, 50)
end)

spawn(function()
    while true do
        if infiniteSprinklerEnabled then
            sprinklerAction()
        end
        wait(3)
    end
end)

spawn(function()
    while true do
        update()
        wait(1)
    end
end)
