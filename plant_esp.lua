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
        Common = {"Chocolate Carrot"},
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

local CalculatePlantValue = require(game:GetService("ReplicatedStorage").Modules.CalculatePlantValue)

local basePrices = {
    carrot = 1,
    strawberry = 5,
    blueberry = 40,
    ["orange tulip"] = 60,
    tomato = 80,
    ["chocolate carrot"] = 100,
    corn = 130,
    daffodil = 150,
    watermelon = 250,
    apple = 325,
    pumpkin = 400,
    bamboo = 400,
    ["red lollipop"] = 500,
    coconut = 600,
    mango = 800,
    ["candy sunflower"] = 1000,
    ["easter egg"] = 1000,
    cactus = 1000,
    ["candy blossom"] = 1000,
    ["dragon fruit"] = 1400,
    raspberry = 1500,
    grape = 1500,
    mushroom = 1700,
    pear = 2000,
    pepper = 2000,
    pineapple = 3000,
    peach = 3000,
    papaya = 5000,
    cranberry = 5000,
    ["cherry blossom"] = 5000,
    durian = 6000,
    banana = 6000,
    lemon = 6000,
    passionfruit = 8000,
    eggplant = 8000,
    lotus = 15000,
    ["soul fruit"] = 15000,
    ["venus fly trap"] = 20000,
    ["cursed fruit"] = 20000,
}

local maxDistance = 25
local maxESP = 10
local nearbyDistance = 15
local infiniteSprinklerEnabled = false

local selectedTypes = {}

-- UI sizes and positions
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

-- Legend Column
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

-- Input boxes for Max Dist, Max ESP, Nearby Dist
local inputLabels = {"Max Dist", "Max ESP", "Nearby Dist"}
local inputVars = {"maxDistance", "maxESP", "nearbyDistance"}
local inputValues = {maxDistance, maxESP, nearbyDistance}
local inputBoxes = {}
local inputLabelObjects = {}

for i, labelName in ipairs(inputLabels) do
    local yPos = (#rarityOrder * 16) + (i - 1) * 24 + 4

    local label = Instance.new("TextLabel", LegendCol)
    label.Size = UDim2.new(1, 0, 0, 16)
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelName
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", LegendCol)
    box.Size = UDim2.new(1, 0, 0, 20)
    box.Position = UDim2.new(0, 0, 0, yPos + 16)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Text = tostring(inputValues[i])
    box.Font = Enum.Font.SourceSansBold
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.TextStrokeTransparency = 0.5
    box.TextWrapped = false
    box.PlaceholderText = "Enter number"

    box.FocusLost:Connect(function(enterPressed)
        local val = tonumber(box.Text)
        if val and val > 0 then
            if inputVars[i] == "maxDistance" then
                maxDistance = val
            elseif inputVars[i] == "maxESP" then
                maxESP = math.floor(val)
            elseif inputVars[i] == "nearbyDistance" then
                nearbyDistance = val
            end
            box.Text = tostring(val)
        else
            box.Text = tostring(inputValues[i])
        end
    end)

    table.insert(inputBoxes, box)
    table.insert(inputLabelObjects, label)
end

-- Obtainable and Unobtainable columns
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

-- Nearby plants frame
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

-- Infinite Sprinkler Frame and Toggle
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
SprinklerLabel.TextColor3 = Color3.new(1, 1, 1)
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

SprinklerToggleBtn.MouseButton1Click:Connect(function()
    infiniteSprinklerEnabled = not infiniteSprinklerEnabled
    SprinklerToggleBtn.Text = infiniteSprinklerEnabled and "ON" or "OFF"
    SprinklerToggleBtn.BackgroundColor3 = infiniteSprinklerEnabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(50, 50, 50)
end)

-- Functions

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

local function createESP(model, labelText)
    if espMap[model] then
        espMap[model].Text = labelText
        return espMap[model]
    end
    local pp = getPP(model)
    if not pp then return end
    local bg = Instance.new("BillboardGui", model)
    bg.Name = "PlantESP"
    bg.Adornee = pp
    bg.Size = UDim2.new(0, 120, 0, 36)
    bg.StudsOffset = Vector3.new(0, 4, 0)
    bg.AlwaysOnTop = true
    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeColor3 = Color3.new(0, 0, 0)
    tl.TextStrokeTransparency = 0.2
    tl.Font = Enum.Font.SourceSansBold
    tl.TextSize = 12
    tl.TextWrapped = true
    tl.RichText = true
    tl.Text = labelText
    espMap[model] = tl
    return tl
end

local function cleanup(validModels)
    for model, gui in pairs(espMap) do
        if not validModels[model] then
            if gui.Parent then gui.Parent:Destroy() end
            espMap[model] = nil
        end
    end
end

local function getExactPrice(model)
    local nameKey = model.Name:lower()
    
    local price
    if CalculatePlantValue then
        if typeof(CalculatePlantValue) == "table" and CalculatePlantValue.Calculate then
            price = CalculatePlantValue.Calculate(model)
        elseif typeof(CalculatePlantValue) == "function" then
            price = CalculatePlantValue(model)
        end
    end

    if (not price or price == 0) and model:FindFirstChild("Price") and model.Price:IsA("NumberValue") then
        price = model.Price.Value
    end

    if not price or price == 0 then
        local basePrice = basePrices[nameKey] or 10
        local weight = 1
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("NumberValue") and child.Name:lower():find("weight") then
                weight = child.Value
                break
            end
        end
        price = math.floor(basePrice * weight)
    end

    return price
end

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

-- UI toggle button (top left)
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
    return ToggleBtn
end

local ToggleBtn = createToggleBtn(ScreenGui, Frame)

-- UI size toggle button (top right)
local normalSize = UDim2.new(0, 340, 0, 250)
local compactSize = UDim2.new(0, 210, 0, 160)
local normalPos = UDim2.new(0, 10, 0, 60)
local compactPos = UDim2.new(0, 10, 0, 20)

local ObtainCol = Frame:FindFirstChildOfClass("Frame") -- Assuming you keep references
local UnobtainCol = Frame:FindFirstChildOfClass("Frame")
local NearbyFrame = Frame:FindFirstChildOfClass("Frame")
local SprinklerFrame = Frame:FindFirstChildOfClass("Frame")

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

    local function updateTextSizes(compact)
        -- Update text sizes of labels and buttons here if needed
    end

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
        updateTextSizes(compact)
    end)

    updateTextSizes(false)

    return btn
end

local SizeToggleBtn = createSizeToggleBtn(Frame)

-- Main update loop
spawn(function()
    while true do
        if infiniteSprinklerEnabled then
            sprinklerAction()
        end
        update()
        wait(1)
    end
end)
