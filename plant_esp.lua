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
local normalSize = UDim2.new(0, 340, 0, 250) -- +30 height
local compactSize = UDim2.new(0, 210, 0, 160) -- +30 height
local normalPos = UDim2.new(0, 10, 0, 60)
local compactPos = UDim2.new(0, 10, 0, 20)

-- UI Setup (unchanged, omitted for brevity)
-- ... (your UI creation code here, unchanged) ...

-- Helper for formatting price
local function formatNumber(n)
    local str = string.format("%.3f", n)
    local before, after = str:match("^(.-)%.(%d+)$")
    before = before:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return before .. "." .. after
end

-- Only one BillboardGui per plant, always two lines
local function createESP(model, labelText, price)
    local pp = getPP(model)
    if not pp then return end

    -- Find or create BillboardGui
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

    -- Find or create main label
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

    -- Find or create price label
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
    -- ... (unchanged) ...
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

-- ... (rest of your code: toggles, UI, sprinkler, etc. unchanged) ...

spawn(function()
    while true do
        update()
        wait(1)
    end
end)
