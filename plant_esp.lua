-- === SERVICES ===
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- === CONFIG ===
local maxDistance = 25
local maxESP = 5
local nearbyDistance = 15

-- === CROP CATEGORIES & COLORS ===
local cropCategories = {
    Obtainable = {
        Common = {"Carrot", "Strawberry"},
        Uncommon = {"Blueberry", "Manuka Flower", "Orange Tulip", "Rose", "Lavender", "Crocus"},
        Rare = {"Tomato", "Corn", "Dandelion", "Daffodil", "Nectarshade", "Raspberry", "Foxglove", "Succulent", "Bee Balm"},
        Legendary = {"Watermelon", "Pumpkin", "Apple", "Bamboo", "Lilac", "Lumira", "Violet Corn", "Nectar Thorn"},
        Mythical = {"Coconut", "Cactus", "Dragon Fruit", "Honeysuckle", "Mango", "Nectarine", "Peach", "Pineapple", "Pink Lily", "Purple Dahlia", "Bendboo", "Suncoil", "Cocovine"},
        Divine = {"Grape", "Mushroom", "Pepper", "Cacao", "Hive Fruit", "Sunflower", "Dragon Pepper"},
        Prismatic = {"Beanstalk", "Ember Lily", "Sugar Apple"},
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

-- === LOAD MODULES ===
local CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)

-- === UTILITY FUNCTIONS ===
local function getPP(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BasePart") then
            model.PrimaryPart = c
            return c
        end
    end
    return nil
end

-- === ADD MISSING VALUES TO PLANT MODELS ===
spawn(function()
    while true do
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and cropSet[model.Name:lower()] then
                -- Add Item_String
                if not model:FindFirstChild("Item_String") then
                    local itemString = Instance.new("StringValue", model)
                    itemString.Name = "Item_String"
                    itemString.Value = model.Name
                end

                -- Add Variant
                if not model:FindFirstChild("Variant") then
                    local variant = Instance.new("StringValue", model)
                    variant.Name = "Variant"
                    variant.Value = "Normal"
                end

                -- Add Weight
                if not model:FindFirstChild("Weight") then
                    local weight = Instance.new("NumberValue", model)
                    weight.Name = "Weight"
                    weight.Value = 3.4
                end
            end
        end
        wait(5)
    end
end)

-- === NUMBER FORMATTING FUNCTION ===
local function formatPriceWithCommas(n)
    local formatted = tostring(math.floor(n))
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted .. "$"
end

-- === ESP CREATION ===
local espMap = {}

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
    bg.Size = UDim2.new(0, 200, 0, 16)
    bg.StudsOffset = Vector3.new(0, 4, 0)
    bg.AlwaysOnTop = true

    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.Font = Enum.Font.FredokaOne
    tl.TextSize = 10
    tl.TextWrapped = false
    tl.RichText = true
    tl.Text = labelText
    tl.TextStrokeColor3 = Color3.new(0, 0, 0)
    tl.TextStrokeTransparency = 0.3
    tl.TextXAlignment = Enum.TextXAlignment.Center

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

-- === NEARBY PLANTS DISPLAY ===
local NearbyFrame
local NearbyScroll

local function updateNearbyPlants()
    if NearbyScroll then
        for _, child in ipairs(NearbyScroll:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
    else
        return
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
                    table.insert(found, {model=model, dist=dist})
                end
            end
        end
    end

    table.sort(found, function(a,b) return a.dist < b.dist end)

    for _, entry in ipairs(found) do
        local label = Instance.new("TextLabel", NearbyScroll)
        label.Size = UDim2.new(1, -4, 0, 14)
        label.BackgroundTransparency = 1
        local cropInfo = cropSet[entry.model.Name:lower()]
        local rarity = cropInfo and cropInfo.rarity or "Common"
        label.TextColor3 = rarityColors[rarity] or Color3.new(1,1,1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 10
        label.Text = string.format("%s (%.1f)", entry.model.Name, entry.dist)
    end
end

-- === MAIN UPDATE LOOP ===
local selectedTypes = {}
for _, v in pairs(cropSet) do
    selectedTypes[v] = true
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

        table.sort(nearest, function(a,b) return a.dist < b.dist end)

        for i = 1, math.min(#nearest, maxESP) do
            local model = nearest[i].model

            -- Get weight
            local weightObj = model:FindFirstChild("Weight")
            local weight = weightObj and weightObj.Value and string.format("%.1f", weightObj.Value) or "?"

            -- Get rarity color
            local cropInfo = cropSet[model.Name:lower()]
            local rarity = cropInfo and cropInfo.rarity or "Common"
            local color = rarityColors[rarity] or Color3.new(1,1,1)
            local hexColor = string.format("#%02X%02X%02X", math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255))

            -- Calculate price
            local price
            if CalculatePlantValue and typeof(CalculatePlantValue) == "table" and CalculatePlantValue.Calculate then
                price = CalculatePlantValue.Calculate(model)
            elseif CalculatePlantValue and typeof(CalculatePlantValue) == "function" then
                price = CalculatePlantValue(model)
            end

            -- Format label
            local formattedPrice = price and formatPriceWithCommas(price) or "?"

            local label = string.format(
                "<font color='%s'>%s</font> - %s kg - <font color='#50FF50'>%s</font>",
                hexColor, model.Name, weight, formattedPrice
            )

            local espLabel = createESP(model, label)
            if espLabel then
                espLabel.RichText = true
            end
            validModels[model] = true
        end
    end

    cleanup(validModels)
    updateNearbyPlants()
end

-- === RUN EVERY SECOND ===
spawn(function()
    while true do
        pcall(update)
        wait(1)
    end
end)

-- === UI SETUP ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlantESPSelector"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 340, 0, 250)
Frame.Position = UDim2.new(0, 10, 0, 60)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.3
Frame.Active = true
Frame.Draggable = true

-- TitleBar
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

-- LegendCol (Rarity Colors)
local LegendCol = Instance.new("Frame", Frame)
LegendCol.Size = UDim2.new(0, 65, 0, 174)
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

-- ObtainCol (Obtainable Crops)
local ObtainCol = Instance.new("Frame", Frame)
ObtainCol.Size = UDim2.new(0, 120, 0, 174)
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

-- UnobtainCol (Unobtainable Crops)
local UnobtainCol = Instance.new("Frame", Frame)
UnobtainCol.Size = UDim2.new(0, 120, 0, 174)
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

-- NearbyFrame (Nearby Plants List)
NearbyFrame = Instance.new("Frame", Frame)
NearbyFrame.Size = UDim2.new(0, 275, 0, 24)
NearbyFrame.Position = UDim2.new(0, 65, 1, -76)
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

NearbyScroll = Instance.new("ScrollingFrame", NearbyFrame)
NearbyScroll.Size = UDim2.new(1, 0, 1, -12)
NearbyScroll.Position = UDim2.new(0, 0, 0, 12)
NearbyScroll.CanvasSize = UDim2.new(0, 0, 0, 100)
NearbyScroll.BackgroundTransparency = 1
NearbyScroll.ScrollBarThickness = 2

local NearbyListLayout = Instance.new("UIListLayout", NearbyScroll)
NearbyListLayout.Padding = UDim.new(0, 1)

-- InputFrame (Distance Settings)
local InputFrame = Instance.new("Frame", Frame)
InputFrame.Size = UDim2.new(0, 275, 0, 30)
InputFrame.Position = UDim2.new(0, 65, 1, -42)
InputFrame.BackgroundTransparency = 0.3
InputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InputFrame.BorderSizePixel = 0

local inputLabels = {"Max Dist", "Max ESP", "Nearby Dist"}
local inputVars = {"maxDistance", "maxESP", "nearbyDistance"}
local inputValues = {maxDistance, maxESP, nearbyDistance}
local inputLabelsTbl = {}
local inputBoxes = {}

for i, labelName in ipairs(inputLabels) do
    local colWidth = 275 / #inputLabels
    local xPos = (i-1) * colWidth
    local label = Instance.new("TextLabel", InputFrame)
    label.Size = UDim2.new(0, colWidth, 0, 12)
    label.Position = UDim2.new(0, xPos, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelName
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Center
    table.insert(inputLabelsTbl, label)

    local box = Instance.new("TextBox", InputFrame)
    box.Size = UDim2.new(0, colWidth - 4, 0, 16)
    box.Position = UDim2.new(0, xPos + 2, 0, 12)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Text = tostring(inputValues[i])
    box.Font = Enum.Font.SourceSansBold
    box.TextSize = 12
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
end

-- Toggles for Crop Categories
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

-- Toggle Button (Show/Hide UI)
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
    ToggleBtn.Text = "❌"
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

-- Compact Mode Toggle
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
            -- Compact layout
            frame.Size = UDim2.new(0, 160, 0, 160)
            frame.Position = UDim2.new(0, 10, 0, 20)
            LegendCol.Size = UDim2.new(0, 50, 0, 100)
            LegendCol.Position = UDim2.new(0, 0, 0, 22)
            ObtainCol.Size = UDim2.new(0, 50, 0, 100)
            ObtainCol.Position = UDim2.new(0, 50, 0, 22)
            UnobtainCol.Size = UDim2.new(0, 50, 0, 100)
            UnobtainCol.Position = UDim2.new(0, 100, 0, 22)
            NearbyFrame.Size = UDim2.new(0, 150, 0, 18)
            NearbyFrame.Position = UDim2.new(0, 0, 1, -38)
            InputFrame.Size = UDim2.new(0, 150, 0, 16)
            InputFrame.Position = UDim2.new(0, 0, 1, -20)

            Title.TextSize = 10
            LegendLabel.TextSize = 9
            ObtainLabel.TextSize = 9
            UnobtainLabel.TextSize = 9
            NearbyLabel.TextSize = 8
            for _, child in ipairs(LegendCol:GetChildren()) do
                if child:IsA("TextLabel") and child ~= LegendLabel then
                    child.TextSize = 9
                end
            end
            for i, label in ipairs(inputLabelsTbl) do
                label.TextSize = 8
            end
            for i, box in ipairs(inputBoxes) do
                box.TextSize = 10
            end
            for _, b in ipairs(ObtainScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextSize = 8
                end
            end
            for _, b in ipairs(UnobtainScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextSize = 8
                end
            end

            local colWidth = 150 / #inputLabels
            for i, label in ipairs(inputLabelsTbl) do
                label.Size = UDim2.new(0, colWidth, 0, 8)
                label.Position = UDim2.new(0, (i-1)*colWidth, 0, 0)
            end
            for i, box in ipairs(inputBoxes) do
                box.Size = UDim2.new(0, colWidth - 4, 0, 12)
                box.Position = UDim2.new(0, (i-1)*colWidth + 2, 0, 8)
            end
        else
            -- Normal layout
            frame.Size = UDim2.new(0, 340, 0, 250)
            frame.Position = UDim2.new(0, 10, 0, 60)
            LegendCol.Size = UDim2.new(0, 65, 0, 174)
            LegendCol.Position = UDim2.new(0, 0, 0, 22)
            ObtainCol.Size = UDim2.new(0, 120, 0, 174)
            ObtainCol.Position = UDim2.new(0, 65, 0, 22)
            UnobtainCol.Size = UDim2.new(0, 120, 0, 174)
            UnobtainCol.Position = UDim2.new(0, 185, 0, 22)
            NearbyFrame.Size = UDim2.new(0, 275, 0, 24)
            NearbyFrame.Position = UDim2.new(0, 65, 1, -76)
            InputFrame.Size = UDim2.new(0, 275, 0, 30)
            InputFrame.Position = UDim2.new(0, 65, 1, -42)

            Title.TextSize = 14
            LegendLabel.TextSize = 12
            ObtainLabel.TextSize = 12
            UnobtainLabel.TextSize = 12
            NearbyLabel.TextSize = 11
            for _, child in ipairs(LegendCol:GetChildren()) do
                if child:IsA("TextLabel") and child ~= LegendLabel then
                    child.TextSize = 12
                end
            end
            for i, label in ipairs(inputLabelsTbl) do
                label.TextSize = 11
            end
            for i, box in ipairs(inputBoxes) do
                box.TextSize = 12
            end
            for _, b in ipairs(ObtainScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextSize = 10
                end
            end
            for _, b in ipairs(UnobtainScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextSize = 10
                end
            end

            local colWidth = 275 / #inputLabels
            for i, label in ipairs(inputLabelsTbl) do
                label.Size = UDim2.new(0, colWidth, 0, 12)
                label.Position = UDim2.new(0, (i-1)*colWidth, 0, 0)
            end
            for i, box in ipairs(inputBoxes) do
                box.Size = UDim2.new(0, colWidth - 4, 0, 16)
                box.Position = UDim2.new(0, (i-1)*colWidth + 2, 0, 12)
            end
        end
    end)
    return btn
end

local SizeToggleBtn = createSizeToggleBtn(Frame)

-- Initialize Selected Types
for _, crop in ipairs(cropCategories.Obtainable.Common) do
    selectedTypes[crop] = true
end
for _, crop in ipairs(cropCategories.Unobtainable.Common) do
    selectedTypes[crop] = true
end
