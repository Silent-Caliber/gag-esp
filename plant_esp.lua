-- Grow a Garden ESP: Dual Column, All Fruits/Plants (2025)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local espMap = {}
 
-- All known fruits/plants in Grow a Garden (2025)
local plantFruitNames = {
    "Apple", "Banana", "Blueberry", "Cacao", "Coconut", "Corn", "Daffodil", "Dragonfruit", "Fig", "Flower", "Glowshroom",
    "Grape", "Guava", "HoneyCrafter", "HoneyStation", "Kiwi", "Lemon", "Lime", "Lychee", "Mango", "Melon", "Orange", "Papaya",
    "Peach", "Pear", "Pineapple", "Plum", "Pomegranate", "Pumpkin", "Raspberry", "Strawberry", "Tomato", "Watermelon",
    "Blood Banana", "Common Egg", "FlowerBed", "Cactus", "Cranberry", "Starfruit", "Passionfruit", "Durian", "Jackfruit",
    "Tangerine", "Apricot", "Mandarin", "Cherry", "Avocado", "Mulberry", "Blackberry", "Currant", "Gooseberry", "Date",
    "Olive", "Persimmon", "Quince", "Sapote", "Soursop", "Breadfruit", "Longan", "Rambutan", "Salak", "Jabuticaba",
    "Mangosteen", "Miracle Berry", "Tamarind", "Yuzu", "Custard Apple", "Sugar Apple", "Ackee", "Feijoa", "Medlar"
}
local plantFruitSet = {}
for _, name in ipairs(plantFruitNames) do
    plantFruitSet[name:lower()] = true
end
 
-- Categorize models
local function getCategorizedTypes()
    local plants, others = {}, {}
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") then
            local lname = model.Name:lower()
            if plantFruitSet[lname] then
                plants[model.Name] = true
            else
                others[model.Name] = true
            end
        end
    end
    return plants, others
end
 
-- UI Setup: Dual Column, Scrollable, Draggable
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "PlantESPSelector"
 
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 260)
Frame.Position = UDim2.new(0, 10, 0, 100)
Frame.BackgroundTransparency = 0.2
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
 
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 20)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Plant ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
 
-- Left Column: Plants/Fruits
local PlantScroll = Instance.new("ScrollingFrame", Frame)
PlantScroll.Size = UDim2.new(0, 120, 1, -24)
PlantScroll.Position = UDim2.new(0, 0, 0, 24)
PlantScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
PlantScroll.BackgroundTransparency = 1
PlantScroll.ScrollBarThickness = 4
 
local PlantLabel = Instance.new("TextLabel", PlantScroll)
PlantLabel.Size = UDim2.new(1, 0, 0, 18)
PlantLabel.BackgroundTransparency = 1
PlantLabel.Text = "Plants/Fruits"
PlantLabel.TextColor3 = Color3.fromRGB(90, 255, 90)
PlantLabel.Font = Enum.Font.SourceSansBold
PlantLabel.TextSize = 13
 
local PlantListLayout = Instance.new("UIListLayout", PlantScroll)
PlantListLayout.Padding = UDim.new(0, 2)
 
-- Right Column: Other Objects
local OtherScroll = Instance.new("ScrollingFrame", Frame)
OtherScroll.Size = UDim2.new(0, 120, 1, -24)
OtherScroll.Position = UDim2.new(0, 130, 0, 24)
OtherScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
OtherScroll.BackgroundTransparency = 1
OtherScroll.ScrollBarThickness = 4
 
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
 
local function createToggles()
    -- Clear old buttons
    for _, child in ipairs(PlantScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, child in ipairs(OtherScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
 
    local plants, others = getCategorizedTypes()
 
    -- Plants/Fruits buttons
    for plantType, _ in pairs(plants) do
        local btn = Instance.new("TextButton", PlantScroll)
        btn.Size = UDim2.new(1, -8, 0, 18)
        btn.BackgroundColor3 = Color3.fromRGB(50, 80, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = "[OFF] " .. plantType
        btn.AutoButtonColor = true
        btn.TextSize = 12
        btn.Font = Enum.Font.SourceSansBold
        btn.MouseButton1Click:Connect(function()
            selectedTypes[plantType] = not selectedTypes[plantType]
            btn.Text = (selectedTypes[plantType] and "[ON] " or "[OFF] ") .. plantType
        end)
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
    if espMap[model] then return espMap[model] end
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
 
local function cleanup()
    for model, gui in pairs(espMap) do
        if not model.Parent or not getPP(model) then
            if gui.Parent then gui.Parent:Destroy() end
            espMap[model] = nil
        end
    end
end
 
local function update()
    cleanup()
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and selectedTypes[model.Name] then
            local pp = getPP(model)
            if pp then
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
            end
        end
    end
end
 
RunService.Heartbeat:Connect(update)
