-- SUMI DOJO: Master Loader Script
-- Place in ServerScriptService
-- Creates all game systems: Dojo, NPCs, Drills, DataStore, UI

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local DSS = game:GetService("DataStoreService")
local TS = game:GetService("TweenService")

-- ============ CONFIG MODULE ============
local Config = {}
Config.WORLDS = {
  {id="zen_garden", name="Zen Garden", energy="yin", level=1, color=Color3.fromRGB(78,205,196)},
  {id="fire_dojo", name="Fire Dojo", energy="yang", level=1, color=Color3.fromRGB(255,107,107)},
  {id="ocean_temple", name="Ocean Temple", energy="yin", level=2, color=Color3.fromRGB(72,152,219)},
  {id="thunder_peak", name="Thunder Peak", energy="yang", level=2, color=Color3.fromRGB(241,196,15)},
  {id="bamboo_forest", name="Bamboo Forest", energy="yin", level=3, color=Color3.fromRGB(0,184,148)},
  {id="volcano_core", name="Volcano Core", energy="yang", level=3, color=Color3.fromRGB(214,48,49)}
}

Config.COMPANIONS = {
  {id="dee_dee", name="Dee Dee", energy="yin", dialog={
    en="Focus your mind... breathe with me.",
    pj="Mann lagaa... mere naal saah le.",
    pg="Chal focus kar... breathe with me na."
  }},
  {id="koko", name="Koko", energy="yang", dialog={
    en="Let's GO! Smash those tiles!",
    pj="Chal oye! Tiles todh de!",
    pg="Come on yaar! Tiles smash kar!"
  }},
  {id="mochi", name="Mochi", energy="yin", dialog={
    en="Patience reveals the pattern.",
    pj="Sabar naal pattern dikhda.",
    pg="Patience rakh... pattern mil jauga."
  }},
  {id="blaze", name="Blaze", energy="yang", dialog={
    en="Faster! You can do better!",
    pj="Tez! Tu hor vadiya kar sakda!",
    pg="Faster chal! Tu better kar sakda!"
  }}
}

Config.DRILLS_PER_SESSION = 3
Config.TILES_PER_DRILL = 9
Config.XP_PER_MATCH = 50
Config.FIB = {1, 1, 2, 3, 5, 8, 13, 21, 34, 55}

-- ============ DATASTORE SYSTEM ============
local SumiStore = DSS:GetDataStore("SUMIDojoV1")

local function loadPlayerData(player)
  local key = "player_" .. player.UserId
  local success, data = pcall(function()
    return SumiStore:GetAsync(key)
  end)
  if success and data then
    return data
  end
  return {
    xp = 0, streak = 0, yin = 50, yang = 50,
    companion = 1, lang = "en", level = 1,
    lastLogin = os.time(), sessionsToday = 0,
    worldsCompleted = {}, totalDrills = 0
  }
end

local function savePlayerData(player, data)
  local key = "player_" .. player.UserId
  pcall(function()
    SumiStore:SetAsync(key, data)
  end)
end

local PlayerData = {}

-- ============ REMOTE EVENTS ============
local Remotes = Instance.new("Folder")
Remotes.Name = "SUMIRemotes"
Remotes.Parent = RS

local events = {"StartDrill", "TileTap", "SwitchCompanion", "SwitchLang", "EnterWorld", "RequestData", "DrillComplete", "SessionComplete"}
for _, name in ipairs(events) do
  local re = Instance.new("RemoteEvent")
  re.Name = name
  re.Parent = Remotes
end

local functions = {"GetPlayerData", "GetLeaderboard"}
for _, name in ipairs(functions) do
  local rf = Instance.new("RemoteFunction")
  rf.Name = name
  rf.Parent = Remotes
end

-- ============ DOJO WORLD BUILDER ============
local function buildDojoGate()
  local gate = Instance.new("Model")
  gate.Name = "DojoGate"
  
  -- Main torii gate
  local leftPillar = Instance.new("Part")
  leftPillar.Size = Vector3.new(2, 16, 2)
  leftPillar.Position = Vector3.new(-8, 8, 0)
  leftPillar.BrickColor = BrickColor.new("Bright red")
  leftPillar.Anchored = true
  leftPillar.Parent = gate
  
  local rightPillar = leftPillar:Clone()
  rightPillar.Position = Vector3.new(8, 8, 0)
  rightPillar.Parent = gate
  
  local topBeam = Instance.new("Part")
  topBeam.Size = Vector3.new(22, 2, 3)
  topBeam.Position = Vector3.new(0, 17, 0)
  topBeam.BrickColor = BrickColor.new("Bright red")
  topBeam.Anchored = true
  topBeam.Parent = gate
  
  -- Dojo sign
  local sign = Instance.new("Part")
  sign.Size = Vector3.new(10, 3, 0.5)
  sign.Position = Vector3.new(0, 14, 0)
  sign.BrickColor = BrickColor.new("Black")
  sign.Anchored = true
  sign.Parent = gate
  
  local sg = Instance.new("SurfaceGui")
  sg.Parent = sign
  local txt = Instance.new("TextLabel")
  txt.Size = UDim2.new(1,0,1,0)
  txt.Text = "SUMI DOJO"
  txt.TextColor3 = Color3.fromRGB(255,215,0)
  txt.BackgroundTransparency = 1
  txt.TextScaled = true
  txt.Font = Enum.Font.GothamBold
  txt.Parent = sg
  
  gate.Parent = workspace
  return gate
end

-- ============ TILE GRID BUILDER ============
local function buildTileGrid(worldConfig, position)
  local grid = Instance.new("Model")
  grid.Name = "DrillGrid_" .. worldConfig.id
  
  local tileSize = 6
  local gap = 1
  local colors = {
    Color3.fromRGB(78,205,196), Color3.fromRGB(255,107,107),
    Color3.fromRGB(108,92,231), Color3.fromRGB(0,184,148),
    Color3.fromRGB(241,196,15), Color3.fromRGB(253,121,168),
    Color3.fromRGB(99,110,114), Color3.fromRGB(162,155,254),
    Color3.fromRGB(255,234,167)
  }
  
  for i = 0, 8 do
    local row = math.floor(i / 3)
    local col = i % 3
    local tile = Instance.new("Part")
    tile.Name = "Tile_" .. i
    tile.Size = Vector3.new(tileSize, 1, tileSize)
    tile.Position = position + Vector3.new(
      (col - 1) * (tileSize + gap),
      0.5,
      (row - 1) * (tileSize + gap)
    )
    tile.BrickColor = BrickColor.new("Medium stone grey")
    tile.Anchored = true
    tile.Material = Enum.Material.SmoothPlastic
    tile.Parent = grid
    
    -- Click detector
    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 20
    cd.Parent = tile
    
    -- Store color index
    local colorVal = Instance.new("IntValue")
    colorVal.Name = "ColorIndex"
    colorVal.Value = 0
    colorVal.Parent = tile
    
    -- Surface label
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Top
    sg.Parent = tile
    local lbl = Instance.new("TextLabel")
    lbl.Name = "TileLabel"
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.Text = "?"
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextScaled = true
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = sg
  end
  
  grid.Parent = workspace
  return grid
end

-- ============ NPC COMPANION BUILDER ============
local function buildCompanionNPC(companionConfig, position)
  local npc = Instance.new("Model")
  npc.Name = "Companion_" .. companionConfig.id
  
  local torso = Instance.new("Part")
  torso.Name = "HumanoidRootPart"
  torso.Size = Vector3.new(2, 3, 1)
  torso.Position = position
  torso.Anchored = true
  torso.BrickColor = companionConfig.energy == "yin" 
    and BrickColor.new("Teal") or BrickColor.new("Bright red")
  torso.Parent = npc
  
  local head = Instance.new("Part")
  head.Shape = Enum.PartType.Ball
  head.Size = Vector3.new(2, 2, 2)
  head.Position = position + Vector3.new(0, 2.5, 0)
  head.Anchored = true
  head.BrickColor = torso.BrickColor
  head.Parent = npc
  
  -- Name billboard
  local bb = Instance.new("BillboardGui")
  bb.Size = UDim2.new(4, 0, 1.5, 0)
  bb.StudsOffset = Vector3.new(0, 3, 0)
  bb.Adornee = head
  bb.Parent = head
  
  local nameLabel = Instance.new("TextLabel")
  nameLabel.Size = UDim2.new(1,0,0.5,0)
  nameLabel.Text = companionConfig.name
  nameLabel.TextColor3 = Color3.fromRGB(255,215,0)
  nameLabel.BackgroundTransparency = 1
  nameLabel.TextScaled = true
  nameLabel.Font = Enum.Font.GothamBold
  nameLabel.Parent = bb
  
  -- Dialog label
  local dialogLabel = Instance.new("TextLabel")
  dialogLabel.Name = "DialogLabel"
  dialogLabel.Size = UDim2.new(1,0,0.5,0)
  dialogLabel.Position = UDim2.new(0,0,0.5,0)
  dialogLabel.Text = companionConfig.dialog.en
  dialogLabel.TextColor3 = Color3.new(1,1,1)
  dialogLabel.BackgroundTransparency = 1
  dialogLabel.TextScaled = true
  dialogLabel.Font = Enum.Font.Gotham
  dialogLabel.Parent = bb
  
  -- ProximityPrompt for interaction
  local pp = Instance.new("ProximityPrompt")
  pp.ActionText = "Talk"
  pp.ObjectText = companionConfig.name
  pp.MaxActivationDistance = 10
  pp.Parent = torso
  
  npc.Parent = workspace
  return npc
end

-- ============ WORLD PORTALS ============
local function buildWorldPortals()
  local portals = Instance.new("Model")
  portals.Name = "WorldPortals"
  
  for i, world in ipairs(Config.WORLDS) do
    local col = ((i-1) % 2)
    local row = math.floor((i-1) / 2)
    local portal = Instance.new("Part")
    portal.Name = "Portal_" .. world.id
    portal.Size = Vector3.new(8, 8, 1)
    portal.Position = Vector3.new(-10 + col * 20, 4, -30 - row * 12)
    portal.Color = world.color
    portal.Anchored = true
    portal.Material = Enum.Material.Neon
    portal.Transparency = 0.3
    portal.Parent = portals
    
    -- Portal label
    local sg = Instance.new("SurfaceGui")
    sg.Parent = portal
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0.4,0)
    lbl.Text = world.name
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.BackgroundTransparency = 1
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = sg
    
    local lvl = Instance.new("TextLabel")
    lvl.Size = UDim2.new(1,0,0.3,0)
    lvl.Position = UDim2.new(0,0,0.4,0)
    lvl.Text = "Level " .. world.level
    lvl.TextColor3 = Color3.fromRGB(255,215,0)
    lvl.BackgroundTransparency = 1
    lvl.TextScaled = true
    lvl.Font = Enum.Font.Gotham
    lvl.Parent = sg
    
    local energy = Instance.new("TextLabel")
    energy.Size = UDim2.new(1,0,0.3,0)
    energy.Position = UDim2.new(0,0,0.7,0)
    energy.Text = world.energy == "yin" and "YIN" or "YANG"
    energy.TextColor3 = world.energy == "yin" 
      and Color3.fromRGB(78,205,196) or Color3.fromRGB(255,107,107)
    energy.BackgroundTransparency = 1
    energy.TextScaled = true
    energy.Font = Enum.Font.GothamBold
    energy.Parent = sg
    
    -- Proximity prompt to enter
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = "Enter"
    pp.ObjectText = world.name
    pp.MaxActivationDistance = 8
    pp.Parent = portal
  end
  
  portals.Parent = workspace
  return portals
end

-- ============ DRILL GAME LOGIC ============
local ActiveDrills = {}

local function shuffleArray(arr)
  local n = #arr
  for i = n, 2, -1 do
    local j = math.random(i)
    arr[i], arr[j] = arr[j], arr[i]
  end
  return arr
end

local function setupDrill(player, worldId)
  local colors = {1,1,2,2,3,3,4,4,5}
  shuffleArray(colors)
  ActiveDrills[player.UserId] = {
    worldId = worldId,
    tiles = colors,
    revealed = {},
    matched = {},
    drillNum = 1,
    score = 0,
    firstPick = nil
  }
end

local function handleTileTap(player, tileIndex)
  local drill = ActiveDrills[player.UserId]
  if not drill then return end
  if drill.matched[tileIndex] then return end
  if drill.revealed[tileIndex] then return end
  
  drill.revealed[tileIndex] = true
  
  if not drill.firstPick then
    drill.firstPick = tileIndex
  else
    local first = drill.firstPick
    drill.firstPick = nil
    
    if drill.tiles[first] == drill.tiles[tileIndex] then
      drill.matched[first] = true
      drill.matched[tileIndex] = true
      drill.score = drill.score + 1
      
      -- Check if drill complete (4 pairs matched)
      local matchCount = 0
      for _,v in pairs(drill.matched) do
        if v then matchCount = matchCount + 1 end
      end
      
      if matchCount >= 8 then
        drill.drillNum = drill.drillNum + 1
        if drill.drillNum > Config.DRILLS_PER_SESSION then
          -- Session complete!
          local data = PlayerData[player.UserId]
          if data then
            local xpGain = drill.score * Config.XP_PER_MATCH
            data.xp = data.xp + xpGain
            data.streak = data.streak + 1
            data.totalDrills = data.totalDrills + Config.DRILLS_PER_SESSION
            data.sessionsToday = data.sessionsToday + 1
            -- YinYang balance
            local world = nil
            for _,w in ipairs(Config.WORLDS) do
              if w.id == drill.worldId then world = w break end
            end
            if world and world.energy == "yin" then
              data.yin = math.min(100, data.yin + 5)
              data.yang = math.max(0, data.yang - 5)
            else
              data.yang = math.min(100, data.yang + 5)
              data.yin = math.max(0, data.yin - 5)
            end
            savePlayerData(player, data)
            Remotes.SessionComplete:FireClient(player, data, xpGain)
          end
          ActiveDrills[player.UserId] = nil
        else
          -- Next drill
          local newColors = {1,1,2,2,3,3,4,4,5}
          shuffleArray(newColors)
          drill.tiles = newColors
          drill.revealed = {}
          drill.matched = {}
          drill.firstPick = nil
          Remotes.DrillComplete:FireClient(player, drill.drillNum, drill.score)
        end
      end
    else
      -- No match - hide after delay
      task.delay(0.8, function()
        drill.revealed[first] = nil
        drill.revealed[tileIndex] = nil
      end)
    end
  end
end

-- ============ DOJO FLOOR ============
local function buildDojoFloor()
  local floor = Instance.new("Part")
  floor.Name = "DojoFloor"
  floor.Size = Vector3.new(200, 1, 200)
  floor.Position = Vector3.new(0, -0.5, 0)
  floor.BrickColor = BrickColor.new("Reddish brown")
  floor.Material = Enum.Material.WoodPlanks
  floor.Anchored = true
  floor.Parent = workspace
  
  -- Spawn location
  local spawn = Instance.new("SpawnLocation")
  spawn.Size = Vector3.new(6, 1, 6)
  spawn.Position = Vector3.new(0, 0.5, 10)
  spawn.Anchored = true
  spawn.Material = Enum.Material.SmoothPlastic
  spawn.BrickColor = BrickColor.new("Institutional white")
  spawn.Parent = workspace
  
  return floor
end

-- ============ REMOTE EVENT CONNECTIONS ============
Remotes.TileTap.OnServerEvent:Connect(function(player, tileIndex)
  handleTileTap(player, tileIndex)
end)

Remotes.EnterWorld.OnServerEvent:Connect(function(player, worldId)
  setupDrill(player, worldId)
  Remotes.StartDrill:FireClient(player, ActiveDrills[player.UserId])
end)

Remotes.SwitchCompanion.OnServerEvent:Connect(function(player)
  local data = PlayerData[player.UserId]
  if data then
    data.companion = (data.companion % #Config.COMPANIONS) + 1
    savePlayerData(player, data)
  end
end)

Remotes.SwitchLang.OnServerEvent:Connect(function(player, lang)
  local data = PlayerData[player.UserId]
  if data then
    data.lang = lang
    savePlayerData(player, data)
  end
end)

Remotes.GetPlayerData.OnServerInvoke = function(player)
  return PlayerData[player.UserId]
end

Remotes.GetLeaderboard.OnServerInvoke = function(player)
  local lb = {}
  for uid, data in pairs(PlayerData) do
    table.insert(lb, {userId=uid, xp=data.xp, streak=data.streak})
  end
  table.sort(lb, function(a,b) return a.xp > b.xp end)
  return lb
end

-- ============ PLAYER CONNECTION ============
Players.PlayerAdded:Connect(function(player)
  local data = loadPlayerData(player)
  
  -- Check streak
  local now = os.time()
  local lastLogin = data.lastLogin or 0
  local dayDiff = math.floor((now - lastLogin) / 86400)
  if dayDiff > 1 then
    data.streak = 0 -- Reset streak if missed a day
  end
  data.lastLogin = now
  data.sessionsToday = 0
  
  PlayerData[player.UserId] = data
  savePlayerData(player, data)
  
  print("[SUMI] Player joined: " .. player.Name .. " | XP: " .. data.xp .. " | Streak: " .. data.streak)
end)

Players.PlayerRemoving:Connect(function(player)
  local data = PlayerData[player.UserId]
  if data then
    savePlayerData(player, data)
    PlayerData[player.UserId] = nil
  end
  ActiveDrills[player.UserId] = nil
end)

-- ============ MAIN INITIALIZATION ============
print("[SUMI DOJO] Initializing...")

-- Build the dojo environment
buildDojoFloor()
print("[SUMI] Floor built")

buildDojoGate()
print("[SUMI] Dojo gate built")

buildWorldPortals()
print("[SUMI] World portals built")

-- Build companions at dojo entrance
for i, comp in ipairs(Config.COMPANIONS) do
  local pos = Vector3.new(-12 + (i-1) * 8, 1.5, 5)
  buildCompanionNPC(comp, pos)
end
print("[SUMI] Companions spawned")

-- Build drill grid in center
buildTileGrid(Config.WORLDS[1], Vector3.new(0, 0, -10))
print("[SUMI] Drill grid built")

-- Connect portal proximity prompts
for _, portal in ipairs(workspace.WorldPortals:GetChildren()) do
  local pp = portal:FindFirstChildOfClass("ProximityPrompt")
  if pp then
    pp.Triggered:Connect(function(player)
      local worldId = string.gsub(portal.Name, "Portal_", "")
      setupDrill(player, worldId)
      Remotes.StartDrill:FireClient(player, ActiveDrills[player.UserId])
    end)
  end
end

-- Connect companion prompts
for _, model in ipairs(workspace:GetChildren()) do
  if string.find(model.Name, "Companion_") then
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
      local pp = root:FindFirstChildOfClass("ProximityPrompt")
      if pp then
        pp.Triggered:Connect(function(player)
          local data = PlayerData[player.UserId]
          if data then
            data.companion = (data.companion % #Config.COMPANIONS) + 1
            savePlayerData(player, data)
            Remotes.SwitchCompanion:FireClient(player, data.companion)
          end
        end)
      end
    end
  end
end

print("[SUMI DOJO] Ready! 6 Worlds | 4 Companions | 3 Languages | YinYang Balance")
