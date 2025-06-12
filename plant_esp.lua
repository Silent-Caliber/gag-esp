local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local espMap = {}

-- Crop categories and rarity colors (your existing data)
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
    Common = Color3.fromRGB(180,180,180),
    Uncommon = Color3.fromRGB(80,200,80),
    Rare = Color3.fromRGB(80,120,255),
    Legendary = Color3.fromRGB(255,215,0),
    Mythical = Color3.fromRGB(255,100,255),
    Divine = Color3.fromRGB(255,90,90),
    Prismatic = Color3.fromRGB(100,255,255),
}

-- Helper to get PrimaryPart of model
local function getPrimaryPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            model.PrimaryPart = part
            return part
        end
    end
    return nil
end

-- UI Setup (use your existing UI code here, including toggles and layout)
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "PlantESPSelector"
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 340, 0, 220)
Frame.Position = UDim2.new(0, 10, 0, 60)
Frame.BackgroundTransparency = 1
Frame.Active = true
Frame.Draggable = true

-- Add your UI elements here (TitleBar, LegendCol, ObtainCol, UnobtainCol, NearbyFrame, toggles, etc.)

-- Infinite Sprinkler Toggle Button (add inside your UI)
local SprinklerToggleBtn = Instance.new("TextButton", Frame)
SprinklerToggleBtn.Size = UDim2.new(0, 80, 0, 30)
SprinklerToggleBtn.Position = UDim2.new(1, -90, 0, 5)
SprinklerToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SprinklerToggleBtn.TextColor3 = Color3.new(1,1,1)
SprinklerToggleBtn.Text = "Infinite Sprinkler OFF"
SprinklerToggleBtn.Font = Enum.Font.SourceSansBold
SprinklerToggleBtn.TextSize = 14
SprinklerToggleBtn.AutoButtonColor = true

local infiniteSprinklerEnabled = false

SprinklerToggleBtn.MouseButton1Click:Connect(function()
    infiniteSprinklerEnabled = not infiniteSprinklerEnabled
    SprinklerToggleBtn.Text = infiniteSprinklerEnabled and "Infinite Sprinkler ON" or "Infinite Sprinkler OFF"
    SprinklerToggleBtn.BackgroundColor3 = infiniteSprinklerEnabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(50, 50, 50)
end)

-- Infinite Sprinkler watering function
local function infiniteSprinklerWatering()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local WaterEvent = ReplicatedStorage:FindFirstChild("WaterPlant")
    if not WaterEvent or not WaterEvent:IsA("RemoteEvent") then return end

    local range = 15
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and cropSet[model.Name:lower()] then
            local pp = getPrimaryPart(model)
            if pp and (pp.Position - root.Position).Magnitude <= range then
                pcall(function()
                    WaterEvent:FireServer(model)
                end)
            end
        end
    end
end

-- ESP update and cleanup functions (use your existing code)

-- Main loops
spawn(function()
    while true do
        if infiniteSprinklerEnabled then
            infiniteSprinklerWatering()
        end
        wait(3) -- watering interval
    end
end)

spawn(function()
    while true do
        -- Your existing update() function to refresh ESP and UI
        wait(1)
    end
end)
