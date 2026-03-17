-- SUMI DOJO: Client UI Script
-- Place as LocalScript in StarterPlayerScripts
-- Creates HUD: XP bar, streak counter, YinYang balance, companion dialog

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local Remotes = RS:WaitForChild("SUMIRemotes")
local GetData = Remotes:WaitForChild("GetPlayerData")
local SessionComplete = Remotes:WaitForChild("SessionComplete")
local DrillComplete = Remotes:WaitForChild("DrillComplete")
local StartDrill = Remotes:WaitForChild("StartDrill")

-- ============ CREATE HUD ============
local screen = Instance.new("ScreenGui")
screen.Name = "SUMI_HUD"
screen.ResetOnSpawn = false
screen.Parent = gui

-- Top bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.Parent = screen

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.3, 0, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "SUMI DOJO"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- XP display
local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "XPLabel"
xpLabel.Size = UDim2.new(0.2, 0, 1, 0)
xpLabel.Position = UDim2.new(0.35, 0, 0, 0)
xpLabel.Text = "XP: 0"
xpLabel.TextColor3 = Color3.fromRGB(0, 184, 148)
xpLabel.BackgroundTransparency = 1
xpLabel.TextScaled = true
xpLabel.Font = Enum.Font.GothamBold
xpLabel.Parent = topBar

-- Streak display
local streakLabel = Instance.new("TextLabel")
streakLabel.Name = "StreakLabel"
streakLabel.Size = UDim2.new(0.2, 0, 1, 0)
streakLabel.Position = UDim2.new(0.55, 0, 0, 0)
streakLabel.Text = "Streak: 0"
streakLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
streakLabel.BackgroundTransparency = 1
streakLabel.TextScaled = true
streakLabel.Font = Enum.Font.GothamBold
streakLabel.Parent = topBar

-- YinYang balance
local balanceLabel = Instance.new("TextLabel")
balanceLabel.Name = "BalanceLabel"
balanceLabel.Size = UDim2.new(0.25, 0, 1, 0)
balanceLabel.Position = UDim2.new(0.75, 0, 0, 0)
balanceLabel.Text = "Yin 50% | Yang 50%"
balanceLabel.TextColor3 = Color3.fromRGB(108, 92, 231)
balanceLabel.BackgroundTransparency = 1
balanceLabel.TextScaled = true
balanceLabel.Font = Enum.Font.Gotham
balanceLabel.Parent = topBar

-- ============ COMPANION DIALOG BOX ============
local dialogFrame = Instance.new("Frame")
dialogFrame.Name = "CompanionDialog"
dialogFrame.Size = UDim2.new(0.4, 0, 0.15, 0)
dialogFrame.Position = UDim2.new(0.3, 0, 0.82, 0)
dialogFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
dialogFrame.BackgroundTransparency = 0.1
dialogFrame.BorderSizePixel = 0
dialogFrame.Visible = false
dialogFrame.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = dialogFrame

local dialogText = Instance.new("TextLabel")
dialogText.Name = "DialogText"
dialogText.Size = UDim2.new(0.9, 0, 0.6, 0)
dialogText.Position = UDim2.new(0.05, 0, 0.35, 0)
dialogText.Text = ""
dialogText.TextColor3 = Color3.new(1, 1, 1)
dialogText.BackgroundTransparency = 1
dialogText.TextScaled = true
dialogText.Font = Enum.Font.Gotham
dialogText.TextWrapped = true
dialogText.Parent = dialogFrame

local companionName = Instance.new("TextLabel")
companionName.Name = "CompanionName"
companionName.Size = UDim2.new(0.9, 0, 0.3, 0)
companionName.Position = UDim2.new(0.05, 0, 0.05, 0)
companionName.Text = "Dee Dee"
companionName.TextColor3 = Color3.fromRGB(108, 92, 231)
companionName.BackgroundTransparency = 1
companionName.TextScaled = true
companionName.Font = Enum.Font.GothamBold
companionName.TextXAlignment = Enum.TextXAlignment.Left
companionName.Parent = dialogFrame

-- ============ NOTIFICATION POPUP ============
local notif = Instance.new("Frame")
notif.Name = "Notification"
notif.Size = UDim2.new(0.3, 0, 0.08, 0)
notif.Position = UDim2.new(0.35, 0, -0.1, 0)
notif.BackgroundColor3 = Color3.fromRGB(0, 184, 148)
notif.BorderSizePixel = 0
notif.Parent = screen

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notif

local notifText = Instance.new("TextLabel")
notifText.Size = UDim2.new(0.9, 0, 1, 0)
notifText.Position = UDim2.new(0.05, 0, 0, 0)
notifText.Text = ""
notifText.TextColor3 = Color3.new(1, 1, 1)
notifText.BackgroundTransparency = 1
notifText.TextScaled = true
notifText.Font = Enum.Font.GothamBold
notifText.Parent = notif

local function showNotification(msg, color)
  notifText.Text = msg
  notif.BackgroundColor3 = color or Color3.fromRGB(0, 184, 148)
  local tweenIn = TS:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.35, 0, 0.06, 0)})
  local tweenOut = TS:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.35, 0, -0.1, 0)})
  tweenIn:Play()
  task.delay(2.5, function() tweenOut:Play() end)
end

-- ============ UPDATE HUD ============
local function updateHUD(data)
  if not data then return end
  xpLabel.Text = "XP: " .. tostring(data.xp)
  streakLabel.Text = "Streak: " .. tostring(data.streak)
  balanceLabel.Text = "Yin " .. tostring(data.yin) .. "% | Yang " .. tostring(data.yang) .. "%"
end

-- ============ REMOTE HANDLERS ============
SessionComplete.OnClientEvent:Connect(function(data, xpGain)
  updateHUD(data)
  showNotification("Session Complete! +" .. tostring(xpGain) .. " XP", Color3.fromRGB(255, 215, 0))
  dialogFrame.Visible = true
  dialogText.Text = "Bahut vadiya! You earned " .. tostring(xpGain) .. " XP!"
  task.delay(5, function() dialogFrame.Visible = false end)
end)

DrillComplete.OnClientEvent:Connect(function(drillNum, score)
  showNotification("Drill " .. tostring(drillNum) .. " | Score: " .. tostring(score), Color3.fromRGB(108, 92, 231))
end)

StartDrill.OnClientEvent:Connect(function(drillData)
  showNotification("Drill Starting!", Color3.fromRGB(78, 205, 196))
  dialogFrame.Visible = true
  companionName.Text = "Sensei"
  dialogText.Text = "Focus! Match the tiles to complete the drill."
end)

-- ============ INITIAL DATA LOAD ============
task.spawn(function()
  task.wait(2) -- Wait for server to load data
  local data = GetData:InvokeServer()
  updateHUD(data)
  
  showNotification("Welcome to SUMI DOJO!", Color3.fromRGB(108, 92, 231))
  dialogFrame.Visible = true
  companionName.Text = "Dee Dee"
  dialogText.Text = "Focus your mind... breathe with me."
  task.delay(4, function() dialogFrame.Visible = false end)
end)

print("[SUMI] Client UI loaded")
