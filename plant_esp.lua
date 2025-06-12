-- Grow a Garden ESP: Only Real Crops, 10 Nearest Only, No Lag

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local espMap = {}

-- Only these names are considered crops/plants
local cropList = {
    "Carrot", "Strawberry", "Blueberry", "Manuka Flower", "Orange Tulip", "Rose", "Lavender",
    "Tomato", "Corn", "Dandelion", "Daffodil", "Nectarshade", "Raspberry", "Foxglove",
    "Watermelon", "Pumpkin", "Apple", "Bamboo", "Lilac", "Lumira",
    "Coconut", "Cactus", "Dragon Fruit", "Honeysuckle", "Mango", "Nectarine", "Peach", "Pineapple", "Pink Lily", "Purple Dahlia",
    "Grape", "Mushroom", "Pepper", "Cacao", "Hive Fruit", "Sunflower",
    "Beanstalk", "Ember Lily",
    "Chocolate crops", "Red Lollipop", "Nightshade", "Candy Sunflower", "Mint", "Glowshroom", "Pear",
    "Cranberry", "Durian", "Easter Egg", "Papaya", "Celestiberry", "Blood Banana", "Moon Melon", "Eggplant", "Passionfruit", "Lemon", "Banana",
    "Cherry Blossom", "Crimson Vine", "Candy Blossom", "Lotus", "Venus Fly Trap", "Cursed Fruit", "Soul Fruit", "Mega Mushroom", "Moon Blossom", "Moon Mango"
}
local cropSet = {}
for _, crop in ipairs(cropList) do
    cropSet[crop:lower()] = true
end

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

-- UI (minimal, crops only)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlantESPSelector"
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 180, 0, 300)
Frame.Position = UDim2.new(0, 10, 0, 80)
Frame.BackgroundTransparency = 0.18
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 24)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Crops ESP (10 Nearest)"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14

local CropScroll = Instance.new("ScrollingFrame", Frame)
CropScroll.Size = UDim2.new(1, 0, 1, -24)
CropScroll.Position = UDim2.new(0, 0, 0, 24)
CropScroll.CanvasSize = UDim2.new(0, 0, 0, 1200)
CropScroll.BackgroundTransparency = 1
CropScroll.ScrollBarThickness = 4

local CropListLayout = Instance.new("UIListLayout", CropScroll)
CropListLayout.Padding = UDim.new(0, 2)

local selectedTypes = {}

for _, crop in ipairs(cropList) do
    local btn = Instance.new("TextButton", CropScroll)
    btn.Size = UDim2.new(1, -8, 0, 18)
    btn.BackgroundColor3 = Color3.fromRGB(70, 80, 70)
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

-- Show/hide UI button
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 36, 0, 36)
ToggleBtn.Position = UDim2.new(0, 10, 0, 40)
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
local uiVisible = true
Frame.Visible = uiVisible
ToggleBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    Frame.Visible = uiVisible
    ToggleBtn.Text = uiVisible and "❌" or "☰"
end)

-- ESP Core: Only 10 nearest crops within 25 studs get ESP
local maxDistance = 25
local maxESP = 10

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

local function update()
    local validModels = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local nearest = {}
    if root then
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and cropSet[model.Name:lower()] and selectedTypes[model.Name] then
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
            if price then
                label = label .. "\nPrice: " .. tostring(price)
            end
            createESP(model, label)
            validModels[model] = true
        end
    end
    cleanup(validModels)
end

spawn(function()
    while true do
        update()
        wait(1)
    end
end)
