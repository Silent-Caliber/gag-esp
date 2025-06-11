-- Improved Plant ESP with Scrollable, Categorized, Draggable UI
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local espMap = {}
 
-- Define known plant/fruit types (add more as needed)
local plantFruitNames = {
    "Cacao", "Coconut", "Apple", "Pumpkin", "Watermelon", "Strawberry", "Blueberry", "Tomato", "Corn", "Daffodil", "Raspberry", "Carrot", "Banana", "Pineapple", "Lemon", "Lime", "Orange", "Pear", "Peach", "Cherry", "Kiwi", "Mango", "Grape", "Melon", "Plum", "Avocado", "Dragonfruit", "Lychee", "Papaya", "Guava", "Fig", "Pomegranate"
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
 
-- UI Setup (Compact, Scrollable, Categorized)
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "PlantESPSelector"
 
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 160, 0, 260)
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
 
local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1, 0, 1, -20)
Scroll.Position = UDim2.new(0, 0, 0, 20)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 6
 
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 2)
 
local selectedTypes = {}
 
local function createToggles()
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    local plants, others = getCategorizedTypes()
 
    -- Section: Plants/Fruits
    local plantLabel = Instance.new("TextLabel", Scroll)
    plantLabel.Size = UDim2.new(1, 0, 0, 18)
    plantLabel.BackgroundTransparency = 1
    plantLabel.Text = "Plants/Fruits"
    plantLabel.TextColor3 = Color3.fromRGB(90, 255, 90)
    plantLabel.Font = Enum.Font.SourceSansBold
    plantLabel.TextSize = 14
 
    for plantType, _ in pairs(plants) do
        local btn = Instance.new("TextButton", Scroll)
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
 
    -- Section: Other Objects
    local otherLabel = Instance.new("TextLabel", Scroll)
    otherLabel.Size = UDim2.new(1, 0, 0, 18)
    otherLabel.BackgroundTransparency = 1
    otherLabel.Text = "Other Objects"
    otherLabel.TextColor3 = Color3.fromRGB(255, 180, 90)
    otherLabel.Font = Enum.Font.SourceSansBold
    otherLabel.TextSize = 14
 
    for otherType, _ in pairs(others) do
        local btn = Instance.new("TextButton", Scroll)
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
