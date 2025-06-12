-- Grow a Garden ESP: Fixed Rarity Legend, No Repeated Headings
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local espMap = {}

-- Crop List by Rarity and Obtainability
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

-- UI Setup: Fixed Legend + Two Columns, Draggable, Scrollable
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlantESPSelector"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 530, 0, 420)
Frame.Position = UDim2.new(0, 10, 0, 100)
Frame.BackgroundTransparency = 0.2
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 24)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Grow a Garden ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

-- Fixed Rarity Legend (leftmost)
local LegendCol = Instance.new("Frame", Frame)
LegendCol.Size = UDim2.new(0, 90, 1, -28)
LegendCol.Position = UDim2.new(0, 0, 0, 28)
LegendCol.BackgroundTransparency = 1

local LegendLabel = Instance.new("TextLabel", LegendCol)
LegendLabel.Size = UDim2.new(1, 0, 0, 18)
LegendLabel.Position = UDim2.new(0, 0, 0, 0)
LegendLabel.BackgroundTransparency = 1
LegendLabel.Text = "RARITY"
LegendLabel.TextColor3 = Color3.fromRGB(255,255,255)
LegendLabel.Font = Enum.Font.SourceSansBold
LegendLabel.TextSize = 15

local LegendListLayout = Instance.new("UIListLayout", LegendCol)
LegendListLayout.Padding = UDim.new(0, 2)
LegendListLayout.SortOrder = Enum.SortOrder.LayoutOrder

for _, rarity in ipairs(rarityOrder) do
    local label = Instance.new("TextLabel", LegendCol)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = rarity
    label.TextColor3 = rarityColors[rarity]
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
end

-- Left: Obtainable Crops
local ObtainCol = Instance.new("Frame", Frame)
ObtainCol.Size = UDim2.new(0, 210, 1, -28)
ObtainCol.Position = UDim2.new(0, 90, 0, 28)
ObtainCol.BackgroundTransparency = 1

local ObtainLabel = Instance.new("TextLabel", ObtainCol)
ObtainLabel.Size = UDim2.new(1, 0, 0, 18)
ObtainLabel.Position = UDim2.new(0, 0, 0, 0)
ObtainLabel.BackgroundTransparency = 1
ObtainLabel.Text = "Obtainable Crops"
ObtainLabel.TextColor3 = Color3.fromRGB(90, 255, 90)
ObtainLabel.Font = Enum.Font.SourceSansBold
ObtainLabel.TextSize = 15

local ObtainScroll = Instance.new("ScrollingFrame", ObtainCol)
ObtainScroll.Size = UDim2.new(1, 0, 1, -20)
ObtainScroll.Position = UDim2.new(0, 0, 0, 20)
ObtainScroll.CanvasSize = UDim2.new(0, 0, 0, 1600)
ObtainScroll.BackgroundTransparency = 1
ObtainScroll.ScrollBarThickness = 6

local ObtainListLayout = Instance.new("UIListLayout", ObtainScroll)
ObtainListLayout.Padding = UDim.new(0, 2)

-- Right: Unobtainable Crops
local UnobtainCol = Instance.new("Frame", Frame)
UnobtainCol.Size = UDim2.new(0, 210, 1, -28)
UnobtainCol.Position = UDim2.new(0, 300, 0, 28)
UnobtainCol.BackgroundTransparency = 1

local UnobtainLabel = Instance.new("TextLabel", UnobtainCol)
UnobtainLabel.Size = UDim2.new(1, 0, 0, 18)
UnobtainLabel.Position = UDim2.new(0, 0, 0, 0)
UnobtainLabel.BackgroundTransparency = 1
UnobtainLabel.Text = "Unobtainable Crops"
UnobtainLabel.TextColor3 = Color3.fromRGB(255, 180, 90)
UnobtainLabel.Font = Enum.Font.SourceSansBold
UnobtainLabel.TextSize = 15

local UnobtainScroll = Instance.new("ScrollingFrame", UnobtainCol)
UnobtainScroll.Size = UDim2.new(1, 0, 1, -20)
UnobtainScroll.Position = UDim2.new(0, 0, 0, 20)
UnobtainScroll.CanvasSize = UDim2.new(0, 0, 0, 1600)
UnobtainScroll.BackgroundTransparency = 1
UnobtainScroll.ScrollBarThickness = 6

local UnobtainListLayout = Instance.new("UIListLayout", UnobtainScroll)
UnobtainListLayout.Padding = UDim.new(0, 2)

-- Parent columns to main frame!
LegendCol.Parent = Frame
ObtainCol.Parent = Frame
UnobtainCol.Parent = Frame

local selectedTypes = {}

local function createToggles()
    -- Clear old
    for _, child in ipairs(ObtainScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, child in ipairs(UnobtainScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local cropsByCategory = getCategorizedTypes()

    -- Obtainable Crops
    for _, rarity in ipairs(rarityOrder) do
        if cropCategories.Obtainable[rarity] then
            for _, crop in ipairs(cropCategories.Obtainable[rarity]) do
                if cropsByCategory.Obtainable[rarity][crop] then
                    local btn = Instance.new("TextButton", ObtainScroll)
                    btn.Size = UDim2.new(1, -8, 0, 18)
                    btn.BackgroundColor3 = rarityColors[rarity] or Color3.fromRGB(50, 80, 50)
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.Text = "[OFF] " .. crop
                    btn.AutoButtonColor = true
                    btn.TextSize = 12
                    btn.Font = Enum.Font.SourceSansBold
                    btn.MouseButton1Click:Connect(function()
                        selectedTypes[crop] = not selectedTypes[crop]
                        btn.Text = (selectedTypes[crop] and "[ON] " or "[OFF] ") .. crop
                    end)
                end
            end
        end
    end

    -- Unobtainable Crops
    for _, rarity in ipairs(rarityOrder) do
        if cropCategories.Unobtainable[rarity] then
            for _, crop in ipairs(cropCategories.Unobtainable[rarity]) do
                if cropsByCategory.Unobtainable[rarity][crop] then
                    local btn = Instance.new("TextButton", UnobtainScroll)
                    btn.Size = UDim2.new(1, -8, 0, 18)
                    btn.BackgroundColor3 = rarityColors[rarity] or Color3.fromRGB(50, 80, 50)
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.Text = "[OFF] " .. crop
                    btn.AutoButtonColor = true
                    btn.TextSize = 12
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

local maxDistance = 80 -- Only show ESP within 80 studs

local function update()
    local validModels = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and selectedTypes[model.Name] then
            local pp = getPP(model)
            if pp and root then
                local dist = (pp.Position - root.Position).Magnitude
                if dist <= maxDistance then
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
                        label = label .. "\nWeight: " .. tostring(weight)
                    end
                    if price then
                        label = label .. "\nPrice: " .. tostring(price)
                    end
                    createESP(model, label)
                    validModels[model] = true
                end
            end
        end
    end
    cleanup(validModels)
end

spawn(function()
    while true do
        update()
        wait(0.2)
    end
end)
