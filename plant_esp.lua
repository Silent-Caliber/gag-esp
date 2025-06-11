-- Plant ESP with Weight and Price, Compact UI
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local espMap = {}
 
-- Utility: Get all plant types in workspace
local function getAllPlantTypes()
    local types = {}
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") then
            types[model.Name] = true
        end
    end
    return types
end
 
-- UI Setup (Compact)
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "PlantESPSelector"
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 120, 0, 200)
Frame.Position = UDim2.new(0, 10, 0, 100)
Frame.BackgroundTransparency = 0.2
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
 
local UIListLayout = Instance.new("UIListLayout", Frame)
UIListLayout.Padding = UDim.new(0, 2)
 
local selectedTypes = {}
 
local function createToggles()
    for _, child in ipairs(Frame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local types = getAllPlantTypes()
    for plantType, _ in pairs(types) do
        local btn = Instance.new("TextButton", Frame)
        btn.Size = UDim2.new(1, -8, 0, 20)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
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
                -- Try to find ValueBase named "Weight" or "Sell" or "Price"
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
