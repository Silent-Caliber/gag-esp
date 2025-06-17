-- === SERVICES ===
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- === CONFIG ===
local maxDistance = 25
local maxESP = 3
local nearbyDistance = 15
local updateInterval = 2.0
local plantCheckDelay = 15
local nearbyUpdateInterval = 5
local maxNearbyPlants = 20

-- === PERFORMANCE OPTIMIZATION ===
local lastDescendantsUpdate = 0
local cacheValidity = 10

-- === NOTIFICATION SYSTEM ===
local function showNotification(message)
    local screenGui = LocalPlayer.PlayerGui:FindFirstChild("PlantESPSelector")
    if not screenGui then return end
    
    for _, obj in ipairs(screenGui:GetChildren()) do
        if obj.Name == "Notification" then
            obj:Destroy()
        end
    end
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0.1, 0)
    notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notification.BackgroundTransparency = 0.3
    notification.BorderSizePixel = 0
    notification.ZIndex = 100
    notification.Parent = screenGui
    
    local corner = Instance.new("UICorner", notification)
    corner.CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", notification)
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 2
    
    local label = Instance.new("TextLabel", notification)
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextWrapped = true
    
    notification.BackgroundTransparency = 1
    label.TextTransparency = 1
    
    local fadeIn = TweenService:Create(
        notification,
        TweenInfo.new(0.5),
        {BackgroundTransparency = 0.3}
    )
    
    local textFadeIn = TweenService:Create(
        label,
        TweenInfo.new(0.5),
        {TextTransparency = 0}
    )
    
    fadeIn:Play()
    textFadeIn:Play()
    
    wait(3)
    
    local fadeOut = TweenService:Create(
        notification,
        TweenInfo.new(0.5),
        {BackgroundTransparency = 1}
    )
    
    local textFadeOut = TweenService:Create(
        label,
        TweenInfo.new(0.5),
        {TextTransparency = 1}
    )
    
    fadeOut:Play()
    textFadeOut:Play()
    
    fadeOut.Completed:Wait()
    notification:Destroy()
end

-- === CROP CATEGORIES & COLORS ===
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

-- === LOAD MODULES ===
local CalculatePlantValue
if ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("CalculatePlantValue") then
    CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)
end

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
    while task.wait(plantCheckDelay) do
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and cropSet[model.Name:lower()] then
                if not model:FindFirstChild("Item_String") then
                    local itemString = Instance.new("StringValue", model)
                    itemString.Name = "Item_String"
                    itemString.Value = model.Name
                end

                if not model:FindFirstChild("Variant") then
                    local variant = Instance.new("StringValue", model)
                    variant.Name = "Variant"
                    variant.Value = "Normal"
                end

                if not model:FindFirstChild("Weight") then
                    local weight = Instance.new("NumberValue", model)
                    weight.Name = "Weight"
                    weight.Value = 3.4
                end
            end
        end
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
local lastUpdate = 0
local updateInterval = 1

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
    bg.MaxDistance = 100

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
    if not NearbyScroll then return end
    
    for _, child in ipairs(NearbyScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
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
        label.TextWrapped = false
        label.TextScaled = false
        label.ClipsDescendants = false
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
    local currentTime = tick()
    if currentTime - lastUpdate < updateInterval then return end
    lastUpdate = currentTime

    local validModels = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local nearest = {}

    if root then
        local descendants = workspace:GetDescendants()
        for i = 1, #descendants do
            local model = descendants[i]
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

            local weightObj = model:FindFirstChild("Weight")
            local weight = weightObj and weightObj.Value and string.format("%.1f", weightObj.Value) or "?"

            local cropInfo = cropSet[model.Name:lower()]
            local rarity = cropInfo and cropInfo.rarity or "Common"
            local color = rarityColors[rarity] or Color3.new(1,1,1)
            local hexColor = string.format("#%02X%02X%02X", math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255))

            local price
            if CalculatePlantValue then
                if typeof(CalculatePlantValue) == "table" and CalculatePlantValue.Calculate then
                    price = CalculatePlantValue.Calculate(model)
                elseif typeof(CalculatePlantValue) == "function" then
                    price = CalculatePlantValue(model)
                end
            end

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
    
    if currentTime % 3 < 0.1 then
        updateNearbyPlants()
    end
end

-- === RUN EVERY SECOND ===
RunService.Heartbeat:Connect(function()
    pcall(update)
end)

-- === UI SETUP ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlantESPSelector"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame with rounded corners and border
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 340, 0, 250)
Frame.Position = UDim2.new(0, 10, 0, 60)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.3
Frame.Active = true
Frame.Draggable = true

-- Add rounded corners to main frame
local frameCorner = Instance.new("UICorner", Frame)
frameCorner.CornerRadius = UDim.new(0, 8)

-- Add border to main frame
local frameStroke = Instance.new("UIStroke", Frame)
frameStroke.Color = Color3.fromRGB(255, 50, 50)
frameStroke.Thickness = 2
frameStroke.Transparency = 0.2

-- TitleBar
local TitleBar = Instance.new("Frame", Frame)
TitleBar.Size = UDim2.new(1, 0, 0, 22)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 0.25
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TitleBar.BorderSizePixel = 0

-- Discord Button with rounded corners and border
local DiscordBtn = Instance.new("TextButton", TitleBar)
DiscordBtn.Size = UDim2.new(0, 60, 0, 18)
DiscordBtn.Position = UDim2.new(0, 4, 0.5, -9)
DiscordBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DiscordBtn.Text = "DISCORD"
DiscordBtn.TextColor3 = Color3.new(1, 1, 1)
DiscordBtn.Font = Enum.Font.SourceSansBold
DiscordBtn.TextSize = 10
DiscordBtn.AutoButtonColor = false
DiscordBtn.ZIndex = 20

-- Add rounded corners to Discord button
local DiscordCorner = Instance.new("UICorner", DiscordBtn)
DiscordCorner.CornerRadius = UDim.new(0, 4)

-- Add border to Discord button
local DiscordStroke = Instance.new("UIStroke", DiscordBtn)
DiscordStroke.Color = Color3.fromRGB(255, 50, 50)
DiscordStroke.Thickness = 2

-- Discord button functionality
DiscordBtn.MouseButton1Click:Connect(function()
    pcall(function()
        showNotification("Joining PUNK TEAM Discord...")
        
        local success = pcall(function()
            GuiService:OpenBrowserWindow("https://discord.gg/JxEjAtdgWD")
        end)
        
        if not success then
            success = pcall(function()
                StarterGui:SetCore("OpenBrowserWindow", {
                    URL = "https://discord.gg/JxEjAtdgWD"
                })
            end)
        end
        
        if not success then
            pcall(function()
                setclipboard("https://discord.gg/JxEjAtdgWD")
                showNotification("Discord link copied to clipboard!")
            end)
        end
    end)
end)

DiscordBtn.MouseEnter:Connect(function()
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

DiscordBtn.MouseLeave:Connect(function()
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
end)

-- Title
local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 70, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PUNK TEAM Grow Garden ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- LegendCol (Rarity Colors)
local LegendCol = Instance.new("Frame", Frame)
LegendCol.Size = UDim2.new(0, 65, 0, 174)
LegendCol.Position = UDim2.new(0, 0, 0, 22)
LegendCol.BackgroundTransparency = 0.2
LegendCol.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LegendCol.BorderSizePixel = 0

-- Add rounded corners and border
local legendCorner = Instance.new("UICorner", LegendCol)
legendCorner.CornerRadius = UDim.new(0, 6)
local legendStroke = Instance.new("UIStroke", LegendCol)
legendStroke.Color = Color3.fromRGB(255, 50, 50)
legendStroke.Thickness = 1
legendStroke.Transparency = 0.3

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

local rarityFullNames = {}
for _, rarity in ipairs(rarityOrder) do
    local label = Instance.new("TextLabel", LegendCol)
    label.Size = UDim2.new(1, 0, 0, 14)
    label.BackgroundTransparency = 1
    label.Text = rarity
    label.TextColor3 = rarityColors[rarity]
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 12
    rarityFullNames[rarity] = label
end

-- ObtainCol (Obtainable Crops)
local ObtainCol = Instance.new("Frame", Frame)
ObtainCol.Size = UDim2.new(0, 120, 0, 174)
ObtainCol.Position = UDim2.new(0, 65, 0, 22)
ObtainCol.BackgroundTransparency = 0.2
ObtainCol.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ObtainCol.BorderSizePixel = 0

-- Add rounded corners and border
local obtainCorner = Instance.new("UICorner", ObtainCol)
obtainCorner.CornerRadius = UDim.new(0, 6)
local obtainStroke = Instance.new("UIStroke", ObtainCol)
obtainStroke.Color = Color3.fromRGB(255, 50, 50)
obtainStroke.Thickness = 1
obtainStroke.Transparency = 0.3

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

-- Add rounded corners and border
local unobtainCorner = Instance.new("UICorner", UnobtainCol)
unobtainCorner.CornerRadius = UDim.new(0, 6)
local unobtainStroke = Instance.new("UIStroke", UnobtainCol)
unobtainStroke.Color = Color3.fromRGB(255, 50, 50)
unobtainStroke.Thickness = 1
unobtainStroke.Transparency = 0.3

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

-- Add rounded corners and border
local nearbyCorner = Instance.new("UICorner", NearbyFrame)
nearbyCorner.CornerRadius = UDim.new(0, 6)
local nearbyStroke = Instance.new("UIStroke", NearbyFrame)
nearbyStroke.Color = Color3.fromRGB(255, 50, 50)
nearbyStroke.Thickness = 1
nearbyStroke.Transparency = 0.3

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

-- Add rounded corners and border
local inputCorner = Instance.new("UICorner", InputFrame)
inputCorner.CornerRadius = UDim.new(0, 6)
local inputStroke = Instance.new("UIStroke", InputFrame)
inputStroke.Color = Color3.fromRGB(255, 50, 50)
inputStroke.Thickness = 1
inputStroke.Transparency = 0.3

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
-- === TOGGLE BUTTONS WITH ANIMATION ===
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

    -- Function to create toggle buttons with visual state
    local function createCropToggleButton(parent, crop, rarity)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, -4, 0, 14)
        btn.BackgroundColor3 = rarityColors[rarity] or Color3.fromRGB(50, 80, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = crop
        btn.AutoButtonColor = true
        btn.TextSize = 10
        btn.Font = Enum.Font.SourceSansBold
        
        -- Visual state based on selection
        local function updateButtonAppearance()
            if selectedTypes[crop] then
                btn.BackgroundTransparency = 0.3
                btn.TextTransparency = 0
            else
                btn.BackgroundTransparency = 0.7
                btn.TextTransparency = 0.5
            end
        end
        
        btn.MouseButton1Click:Connect(function()
            selectedTypes[crop] = not selectedTypes[crop]
            updateButtonAppearance()
        end)
        
        -- Set initial appearance
        updateButtonAppearance()
        return btn
    end

    -- Create obtainable crop toggles
    for _, rarity in ipairs(rarityOrder) do
        if cropCategories.Obtainable[rarity] then
            for _, crop in ipairs(cropCategories.Obtainable[rarity]) do
                if cropsByCategory.Obtainable[rarity][crop] then
                    createCropToggleButton(ObtainScroll, crop, rarity)
                end
            end
        end
    end

    -- Create unobtainable crop toggles
    for _, rarity in ipairs(rarityOrder) do
        if cropCategories.Unobtainable[rarity] then
            for _, crop in ipairs(cropCategories.Unobtainable[rarity]) do
                if cropsByCategory.Unobtainable[rarity][crop] then
                    createCropToggleButton(UnobtainScroll, crop, rarity)
                end
            end
        end
    end
end

createToggles()

spawn(function()
    while task.wait(10) do
        createToggles()
    end
end)

-- Initialize Selected Types
for _, crop in ipairs(cropCategories.Obtainable.Common) do
    selectedTypes[crop] = true
end
for _, crop in ipairs(cropCategories.Unobtainable.Common) do
    selectedTypes[crop] = true
end

-- Toggle Button (Show/Hide UI)
local function createToggleBtn(screenGui, frame)
    if screenGui:FindFirstChild("ShowHideESPBtn") then
        screenGui.ShowHideESPBtn:Destroy()
    end

    -- Main toggle button container
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "ShowHideESPBtn"
    ToggleBtn.Parent = screenGui
    ToggleBtn.Size = UDim2.new(0, 38, 0, 38)
    ToggleBtn.Position = UDim2.new(0, 6, 0, 6)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Image = "rbxassetid://131613009113138"
    ToggleBtn.ZIndex = 100

    -- Add circular background
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.15
    bg.ZIndex = 99
    bg.Parent = ToggleBtn
    
    -- Make background circular
    local corner = Instance.new("UICorner", bg)
    corner.CornerRadius = UDim.new(1, 0)
    
    -- Add border to background
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 2
    
    -- Make toggle button movable
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true

    local uiVisible = true
    frame.Visible = uiVisible

    ToggleBtn.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        frame.Visible = uiVisible
        
        -- Animation effects
        local tweenInfo = TweenInfo.new(
            0.5, -- Time
            Enum.EasingStyle.Quint, -- Easing style
            Enum.EasingDirection.Out, -- Easing direction
            0, -- Repeat count
            false, -- Reverses
            0 -- Delay
        )
        
        -- Scale animation
        local scaleGoal = uiVisible and 1 or 0.8
        local scaleTween = TweenService:Create(
            ToggleBtn,
            tweenInfo,
            {Size = UDim2.new(0, 38 * scaleGoal, 0, 38 * scaleGoal)}
        )
        
        -- Rotation animation
        local rotationTween = TweenService:Create(
            ToggleBtn,
            tweenInfo,
            {Rotation = uiVisible and 0 or 180}
        )
        
        -- Color pulse effect
        local pulseColor = uiVisible and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        local colorTween = TweenService:Create(
            stroke,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Color = pulseColor}
        )
        
        -- Play animations
        scaleTween:Play()
        rotationTween:Play()
        colorTween:Play()
        
        -- Reset color after pulse
        wait(0.5)
        local resetTween = TweenService:Create(
            stroke,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Color = Color3.fromRGB(255, 50, 50)}
        )
        resetTween:Play()
    end)

    -- Hover effects
    ToggleBtn.MouseEnter:Connect(function()
        local tween = TweenService:Create(
            bg,
            TweenInfo.new(0.2),
            {BackgroundTransparency = 0}
        )
        tween:Play()
    end)

    ToggleBtn.MouseLeave:Connect(function()
        local tween = TweenService:Create(
            bg,
            TweenInfo.new(0.2),
            {BackgroundTransparency = 0.15}
        )
        tween:Play()
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

    -- Add rounded corners
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(1, 0)

    -- Add border
    local sizeToggleStroke = Instance.new("UIStroke", btn)
    sizeToggleStroke.Color = Color3.fromRGB(255, 50, 50)
    sizeToggleStroke.Thickness = 2

    local compact = false

    btn.MouseButton1Click:Connect(function()
        compact = not compact
        if compact then
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
            
            DiscordBtn.Size = UDim2.new(0, 50, 0, 15)
            DiscordBtn.TextSize = 8
            DiscordBtn.Position = UDim2.new(0, 2, 0.5, -7.5)
            Title.Text = "PUNK TEAM ESP"
            Title.TextSize = 10
            Title.Position = UDim2.new(0, 52, 0, 0)
            Title.Size = UDim2.new(1, -55, 1, 0)

            LegendLabel.TextSize = 9
            ObtainLabel.TextSize = 9
            UnobtainLabel.TextSize = 9
            NearbyLabel.TextSize = 8
            
            local rarityAbbreviations = {
                Common = "Com",
                Uncommon = "Unc",
                Rare = "Rare",
                Legendary = "Leg",
                Mythical = "Myth",
                Divine = "Div",
                Prismatic = "Prism"
            }
            
            for _, rarity in ipairs(rarityOrder) do
                if rarityFullNames[rarity] then
                    rarityFullNames[rarity].Text = rarityAbbreviations[rarity] or rarity
                    rarityFullNames[rarity].TextSize = 9
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
                    b.TextWrapped = true
                end
            end
            for _, b in ipairs(UnobtainScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextSize = 8
                    b.TextWrapped = true
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
            
            DiscordBtn.Size = UDim2.new(0, 60, 0, 18)
            DiscordBtn.TextSize = 10
            DiscordBtn.Position = UDim2.new(0, 4, 0.5, -9)
            Title.Text = "PUNK TEAM Grow Garden ESP"
            Title.TextSize = 14
            Title.Position = UDim2.new(0, 70, 0, 0)
            Title.Size = UDim2.new(1, -80, 1, 0)

            LegendLabel.TextSize = 12
            ObtainLabel.TextSize = 12
            UnobtainLabel.TextSize = 12
            NearbyLabel.TextSize = 11
            
            for _, rarity in ipairs(rarityOrder) do
                if rarityFullNames[rarity] then
                    rarityFullNames[rarity].Text = rarity
                    rarityFullNames[rarity].TextSize = 12
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
                    b.TextWrapped = false
                end
            end
            for _, b in ipairs(UnobtainScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextSize = 10
                    b.TextWrapped = false
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
