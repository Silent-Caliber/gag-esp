-- Grow a Garden ESP: Full Optimized Version with UI
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

local function getCategorizedTypes()
    local cropsByCategory = {}
    local others = {}
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
            else
                others[model.Name] = true
            end
        end
    end
    return cropsByCategory, others
end

-- UI Setup: Scrollable, Draggable, Categorized
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlantESPSelector"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 340, 0, 400)
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

-- Left: Crops, Right: Other Objects
local CropScroll = Instance.new("ScrollingFrame", Frame)
CropScroll.Size = UDim2.new(0, 210, 1, -28)
CropScroll.Position = UDim2.new(0, 0, 0, 28)
CropScroll.CanvasSize = UDim2.new(0, 0, 0, 1600)
CropScroll.BackgroundTransparency = 1
CropScroll.ScrollBarThickness = 6

local CropListLayout = Instance.new("UIListLayout", CropScroll)
CropListLayout.Padding = UDim.new(0, 2)

local OtherScroll = Instance.new("ScrollingFrame", Frame)
OtherScroll.Size = UDim2.new(0, 120, 1, -28)
OtherScroll.Position = UDim2.new(0, 220, 0, 28)
OtherScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
OtherScroll.BackgroundTransparency = 1
OtherScroll.ScrollBarThickness = 6

local OtherLabel = Instance.new("TextLabel", OtherScroll)
OtherLabel.Size = UDim2.new(1, 0, 0, 18)
OtherLabel.BackgroundTransparency = 1
OtherLabel.Text = "Other Objects"
OtherLabel.TextColor3 = Color3.fromRGB(255, 180, 90)
OtherLabel.Font = Enum.Font.SourceSansBold
OtherLabel.TextSize = 13

local OtherListLayout = Instance.new("UIListLayout", OtherScroll)
OtherListLayout.Padding = UDim.new(0, 2)

local selectedTypes = {}

local function makeSectionLabel(parent, text, color)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    return label
end

local rarityColors = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare = Color3.fromRGB(80, 120, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythical = Color3.fromRGB(255, 100, 255),
    Divine = Color3.fromRGB(255, 90, 90),
    Prismatic = Color3.fromRGB(100,255,255),
}

local function createToggles()
    -- Clear old
    for _, child in ipairs(CropScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    for _, child in ipairs(OtherScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    OtherLabel.Parent = OtherScroll

    local cropsByCategory, others = getCategorizedTypes()

    for obtainKey, obtainLabel in pairs({Obtainable="Obtainable Crops", Unobtainable="Unobtainable Crops"}) do
        makeSectionLabel(CropScroll, obtainLabel, Color3.fromRGB(255,255,255))
        for _, rarity in ipairs({"Common","Uncommon","Rare","Legendary","Mythical","Divine","Prismatic"}) do
            if cropCategories[obtainKey][rarity] then
                makeSectionLabel(CropScroll, "  "..rarity, rarityColors[rarity] or Color3.new(1,1,1))
                for _, crop in ipairs(cropCategories[obtainKey][rarity]) do
                    if cropsByCategory[obtainKey][rarity][crop] then
                        local btn = Instance.new("TextButton", CropScroll)
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

    -- Other objects buttons
    for otherType, _ in pairs(others) do
        local btn = Instance.new("TextButton", OtherScroll)
        btn.Size = UDim2.new(1, -8, 0, 18)
        btn.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = "[OFF] " .. otherType
        btn.AutoButtonColor = true
        btn.TextSize = 12
        btn.Font = Enum.Font.SourceSansBold
        btn.MouseButton1Click:Connect(function()
            selectedTypes[otherType] = not selectedTypes[otherType]
            btn.Text = (selectedTypes[otherType] and "[ON] " or "[OFF] ") .. otherType
        end)
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

-- Update every 0.2 seconds instead of every frame
spawn(function()
    while true do
        update()
        wait(0.2)
    end
end)
