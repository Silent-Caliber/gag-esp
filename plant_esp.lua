local P=game:GetService("Players").LocalPlayer
local R=game:GetService("RunService")
local basePrices={
Carrot=20,Strawberry=20,Blueberry=20,OrangeTulip=750,Nightshade=2000,RedLollipop=70000,
Tomato=30,Corn=40,Raspberry=60,Glowshroom=175,Daffodil=1000,Mint=6000,CandySunflower=145000,
Apple=275,Papaya=1000,Cranberry=1805,Watermelon=3000,Pumpkin=4000,Bamboo=4000,Durian=4513,
Moonflower=8500,Starfruit=15538,Pear=80,Peach=271,Pineapple=350,Coconut=400,Lemon=500,
Banana=3000,Passionfruit=3204,Cactus=3400,EasterEgg=4513,DragonFruit=4750,BloodBanana=5415,
Mango=6500,Eggplant=6769,MoonMelon=16245,Moonglow=18000,CherryBlossom=550,CandyBlossom=100000,
Beanstalk=20000,Mushroom=136000,Pepper=7220,Grape=850000
}
local espMap={}
local function calcPrice(w,b,m) m=m or 1 return math.floor(w*b*m) end
local function getPP(p)
 if p.PrimaryPart then return p.PrimaryPart end
 for _,c in pairs(p:GetChildren()) do
  if c:IsA("BasePart") then p.PrimaryPart=c return c end
 end
 return nil
end
local function createESP(p)
 if espMap[p] then return espMap[p] end
 local pp=getPP(p)
 if not pp then return end
 local bg=Instance.new("BillboardGui",p)
 bg.Name="PlantESP"
 bg.Adornee=pp
 bg.Size=UDim2.new(0,160,0,50)
 bg.StudsOffset=Vector3.new(0,3,0)
 bg.AlwaysOnTop=true
 local tl=Instance.new("TextLabel",bg)
 tl.Size=UDim2.new(1,0,1,0)
 tl.BackgroundTransparency=1
 tl.TextColor3=Color3.new(1,1,1)
 tl.TextStrokeColor3=Color3.new(0,0,0)
 tl.TextStrokeTransparency=0
 tl.Font=Enum.Font.SourceSansBold
 tl.TextSize=14
 tl.TextWrapped=true
 espMap[p]=tl
 return tl
end
local function cleanup()
 for p,g in pairs(espMap) do
  if not p.Parent or not getPP(p) then
   if g.Parent then g.Parent:Destroy() end
   espMap[p]=nil
  end
 end
end
local function update()
 cleanup()
 for _,p in pairs(workspace:GetDescendants()) do
  if p:IsA("Model") and p:FindFirstChild("Weight") and p:FindFirstChild("CropType") then
   local pp=getPP(p)
   if pp then
    local w=p.Weight.Value or 0
    local c=p.CropType.Value or "Unknown"
    local b=basePrices[c] or 10
    local m=1
    local sp=calcPrice(w,b,m)
    local tl=createESP(p)
    if tl then tl.Text=string.format("%s\nWeight: %.2f\nSell Price: %d Sheckles",c,w,sp) end
   end
  end
 end
end
R.Heartbeat:Connect(update)
