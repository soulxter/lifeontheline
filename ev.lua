local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local requireSupported = false
pcall(function()
    local pk = ReplicatedStorage:FindFirstChild("packets") or ReplicatedStorage:WaitForChild("packets", 5)
    if pk then
        local res = require(pk)
        if type(res) == "table" and (rawget(res, "bytenet_use") or res.bytenet_use) then
            requireSupported = true
        end
    end
end)

if not requireSupported then
    if LocalPlayer then
        LocalPlayer:Kick(
            "Your executor doesn't support require - use high-UNC executors. Among the free ones: Real, Madium, and others.")
    else
        game:GetService("Players").LocalPlayer:Kick(
            "Your executor doesn't support require - use high-UNC executors. Among the free ones: Real, Madium, and others.")
    end
    return
end

if _G.AzlScriptLoaded then
    warn("[Azl] Script was already executed!")
    return
end
_G.AzlScriptLoaded                 = true

local Library                      = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Serl1cia/EvolutionHub/refs/heads/main/ui.lua",
    true))()
Library.ConfigSystem.CurrentConfig = "azl"
Library.ConfigSystem.AutoSave      = false

local Players                      = game:GetService("Players")
local RunService                   = game:GetService("RunService")
local UserInputService             = game:GetService("UserInputService")
local ReplicatedStorage            = game:GetService("ReplicatedStorage")
local Workspace                    = game:GetService("Workspace")
local HttpService                  = game:GetService("HttpService")
local TweenService                 = game:GetService("TweenService")

local IS_MOBILE                    = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Player                       = Players.LocalPlayer
local NameProtect                  = nil
local AutoLineUps, LineUpCreator, AutoDefensive, NET, SecretAwakening

local ExecutorName                 = "Unknown"
pcall(function()
    local name = identifyexecutor and identifyexecutor()
    if name then ExecutorName = tostring(name) end
end)

local ExecutorCaps = {
    IsXeno = ExecutorName:lower():find("xeno", 1, true) ~= nil,
    IsSolara = ExecutorName:lower():find("solara", 1, true) ~= nil,
    Hook = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function",
    Drawing = Drawing ~= nil and type(Drawing.new) == "function",
    Files = type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
        and type(isfolder) == "function" and type(makefolder) == "function",
    RobloxModules = type(getscriptclosure) == "function"
        and ExecutorName:lower():find("xeno", 1, true) == nil
        and ExecutorName:lower():find("solara", 1, true) == nil,
}

local function CreateMobileButton(name, position, onPress, onRelease, mode)
    if not IS_MOBILE then return nil end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileButton_" .. name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Player:WaitForChild("PlayerGui")

    local btn = Instance.new("Frame")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = position or UDim2.new(0.85, 0, 0.7, 0)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Active = false
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextWrapped = true
    label.Parent = btn

    local dragStart, startPos, wasDragged, isActive, trackedTouch = nil, nil, false, false, nil

    local function clampPosition(x, y)
        local screenSize, btnSize = gui.AbsoluteSize, btn.AbsoluteSize
        return math.clamp(x, 5, math.max(5, screenSize.X - btnSize.X - 5)),
            math.clamp(y, 5, math.max(5, screenSize.Y - btnSize.Y - 5))
    end

    local function isPlayerMoving()
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        return hum and hum.MoveDirection.Magnitude > 0.1
    end

    UserInputService.TouchStarted:Connect(function(touch, gp)
        if gp then return end
        local pos, btnPos, btnSize = touch.Position, btn.AbsolutePosition, btn.AbsoluteSize
        if pos.X >= btnPos.X and pos.X <= btnPos.X + btnSize.X and pos.Y >= btnPos.Y and pos.Y <= btnPos.Y + btnSize.Y then
            trackedTouch, wasDragged, dragStart, startPos = touch, false, Vector2.new(pos.X, pos.Y), btn.Position
            if mode == "hold" then
                isActive = true
                btn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
                if onPress then onPress() end
            end
        end
    end)

    UserInputService.TouchMoved:Connect(function(touch)
        if touch ~= trackedTouch then return end
        local pos = touch.Position
        local delta = Vector2.new(pos.X - dragStart.X, pos.Y - dragStart.Y)
        if delta.Magnitude > 10 and not isPlayerMoving() then
            wasDragged = true
            local cx, cy = clampPosition(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
            btn.Position = UDim2.fromOffset(cx, cy)
        end
    end)

    UserInputService.TouchEnded:Connect(function(touch)
        if touch ~= trackedTouch then return end
        trackedTouch = nil
        if not wasDragged then
            if mode == "toggle" then
                isActive = not isActive
                btn.BackgroundColor3 = isActive and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(20, 20, 20)
                if isActive then
                    if onPress then onPress() end
                elseif onRelease then
                    onRelease()
                end
            elseif mode == "hold" then
                isActive = false
                btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                if onRelease then onRelease() end
            elseif mode == "tap" then
                btn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
                if onPress then onPress() end
                task.wait(0.15)
                btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            end
        end
        wasDragged = false
    end)

    local buttonObj = {
        GUI = gui,
        Frame = btn,
        IsActive = function() return isActive end,
        SetActive = function(active)
            isActive = active
            btn.BackgroundColor3 = active and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(20, 20, 20)
        end,
        Destroy = function() gui:Destroy() end
    }

    return buttonObj
end

local Window               = Library:CreateWindow()

local MainTab              = Window:CreateTopTab("Main")
local PlayerTab            = Window:CreateTopTab("Player")
local VisualsTab           = Window:CreateTopTab("Visuals")
local MiscTab              = Window:CreateTopTab("Misc")

local MainCat              = Window:CreateCategory(MainTab, "Main")
local AutoCounterSection   = Library:CreateSection(MainCat, "Auto Counter", "left")
local AutoPositionSection  = Library:CreateSection(MainCat, "Auto Position", "right")
local AntiCounterSection   = Library:CreateSection(MainCat, "Anti Counter", "left")
local AntiPriceSection     = Library:CreateSection(MainCat, "Anti Price Check", "right")
local AutoLineUpsSection   = Library:CreateSection(MainCat, "Auto Line Ups", "left")
local LineUpCreatorSection = Library:CreateSection(MainCat, "LineUp Creator", "left")

local MiscCat              = Window:CreateCategory(MiscTab, "Settings")

local MiscUISection        = Library:CreateSection(MiscCat, "UI Settings", "right")


local ESPCat                = Window:CreateCategory(VisualsTab, "ESP")
local ESPSection            = Library:CreateSection(ESPCat, "Style Indicator", "left")

local CrosshairCat          = Window:CreateCategory(VisualsTab, "Crosshair")
local CrosshairMainSection  = Library:CreateSection(CrosshairCat, "Crosshair", "left")
local CrosshairStyleSection = Library:CreateSection(CrosshairCat, "Style", "right")
local CrosshairAnimSection  = Library:CreateSection(CrosshairCat, "Animations", "left")
local CrosshairColorSection = Library:CreateSection(CrosshairCat, "Colors", "right")


local UISettings = { Watermark = not IS_MOBILE, Notifications = true }

local function SafeNotify(message, duration, sound)
    if not UISettings.Notifications then return end
    Library:CreateNotification({
        Message = message,
        Duration = duration or 2,
        Sound = sound
    })
end

local buffers = setmetatable({}, { __index = function(_, k) return k end })

local ByteNetPackets = {
    use = 30,
    findBall = 29,
    selectRole = 4
}

local function BN_ReadPacketIDs()
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local function parseJson(str)
            if type(str) ~= "string" or str == "" then return false end
            local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
            if ok and data and data.packets then
                if data.packets["bytenet_use"] then ByteNetPackets.use = data.packets["bytenet_use"] end
                if data.packets["bytenet_findBall"] then ByteNetPackets.findBall = data.packets["bytenet_findBall"] end
                if data.packets["bytenet_selectRole"] then
                    ByteNetPackets.selectRole = data.packets
                        ["bytenet_selectRole"]
                end
                return true
            end
            return false
        end

        local bytenetStorage = ReplicatedStorage:FindFirstChild("BytenetStorage")
        if bytenetStorage then
            local networking = bytenetStorage:FindFirstChild("Networking")
            if networking and networking:IsA("StringValue") then
                if parseJson(networking.Value) then return end
            end
        end

        for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
            if child:IsA("StringValue") and (child.Name == "Networking" or child.Name:find("ByteNet") or child.Name:find("packets")) then
                if parseJson(child.Value) then return end
            end
        end
    end)
end

BN_ReadPacketIDs()

local function BN_UseBuffer()
    return buffer.fromstring(string.char(ByteNetPackets.use) .. string.char(1))
end

local function BN_FindBallBuffer()
    return buffer.fromstring(string.char(ByteNetPackets.findBall))
end

local function GetByteNetReliable()
    return ReplicatedStorage:FindFirstChild("ByteNetReliable")
        or ReplicatedStorage:FindFirstChild("Reliable", true)
        or (ReplicatedStorage:FindFirstChild("packets") and ReplicatedStorage.packets:FindFirstChild("Reliable", true))
end

local cachedBaseClient = nil
local lastBCCheck = 0
local function GetBaseClient()
    if cachedBaseClient then return cachedBaseClient end
    local now = os.clock()
    if now - lastBCCheck < 3 then return nil end
    lastBCCheck = now

    local bc = nil
    if shared and shared.metatable then bc = shared.metatable.baseClient end
    if not bc and getgenv then
        pcall(function()
            for _, v in pairs(getgenv()) do
                if type(v) == "table" and v.baseClient and v.baseClient.use then
                    bc = v.baseClient
                    break
                end
            end
        end)
    end
    if not bc and getrenv then
        pcall(function()
            if _G and _G.baseClient then bc = _G.baseClient end
        end)
    end
    if not bc and getgc then
        pcall(function()
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" and type(rawget(v, "givmeBall")) == "function" and type(rawget(v, "senduse")) == "function" then
                    bc = v
                    break
                end
            end
        end)
    end
    if bc then cachedBaseClient = bc end
    return bc
end

NET = (function()
    local Packets = nil
    local warned = {}

    local function warnOnce(key, message)
        if not warned[key] then
            warned[key] = true
            warn("[Network Shim] " .. message)
        end
    end

    local function findLoadedPackets()
        if Packets then return Packets end
        pcall(function()
            local rsPackets = game:GetService("ReplicatedStorage"):FindFirstChild("packets") or
                game:GetService("ReplicatedStorage"):FindFirstChild("packets", true)
            if rsPackets then
                local res = require(rsPackets)
                if type(res) == "table" and (rawget(res, "bytenet_use") or res.bytenet_use or rawget(res, "bytenet_selectRole") or res.bytenet_selectRole) then
                    Packets = res
                end
            end
        end)
        if Packets then return Packets end

        pcall(function()
            if getrenv and getrenv().require then
                local rsPackets = game:GetService("ReplicatedStorage"):FindFirstChild("packets") or
                    game:GetService("ReplicatedStorage"):FindFirstChild("packets", true)
                if rsPackets then
                    local res = getrenv().require(rsPackets)
                    if type(res) == "table" and (rawget(res, "bytenet_use") or res.bytenet_use or rawget(res, "bytenet_selectRole") or res.bytenet_selectRole) then
                        Packets = res
                    end
                end
            end
        end)
        if Packets then return Packets end

        pcall(function()
            if getloadedmodules then
                for _, mod in ipairs(getloadedmodules()) do
                    if mod and mod.Name == "packets" then
                        local res = require(mod)
                        if type(res) == "table" and (rawget(res, "bytenet_use") or res.bytenet_use or rawget(res, "bytenet_selectRole") or res.bytenet_selectRole) then
                            Packets = res
                            return
                        end
                    end
                end
            end
        end)
        if Packets then return Packets end

        if getgc then
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" and ((rawget(v, "bytenet_use") or v.bytenet_use) or (rawget(v, "bytenet_selectRole") or v.bytenet_selectRole)) then
                        Packets = v
                        return
                    end
                end
            end)
        end
        return Packets
    end

    findLoadedPackets()

    local function convertToString(inputData)
        if type(inputData) == "string" then return inputData end
        if typeof(inputData) == "buffer" then return buffer.tostring(inputData) end
        return tostring(inputData)
    end

    local standalonePackets = {
        bytenet_use = {
            send = function(action)
                local remote = GetByteNetReliable()
                if remote then
                    pcall(function() remote:FireServer(BN_UseBuffer(), { action }) end)
                    pcall(function() remote:FireServer(buffer.fromstring(buffers["base"]), { action }) end)
                end
                local bc = GetBaseClient()
                if bc and type(action) == "table" then
                    pcall(function()
                        if bc.senduse then
                            bc:senduse(action)
                        elseif bc.use then
                            bc:use(unpack(action))
                        end
                    end)
                end
            end
        },
        bytenet_findBall = {
            send = function(actionsList)
                local loadedPk = findLoadedPackets()
                if loadedPk and loadedPk.bytenet_findBall and loadedPk.bytenet_findBall.send then
                    local ok = pcall(function() loadedPk.bytenet_findBall.send() end)
                    if not ok then
                        pcall(function() loadedPk.bytenet_findBall:send() end)
                    end
                    return
                end
                local remote = GetByteNetReliable()
                if remote then
                    pcall(function() remote:FireServer(BN_FindBallBuffer()) end)
                    pcall(function() remote:FireServer(buffer.fromstring(buffers["grabball"]), actionsList) end)
                end
            end
        },
        bytenet_selectRole = {
            send = function(data)
                local loadedPk = findLoadedPackets()
                if loadedPk and loadedPk.bytenet_selectRole and loadedPk.bytenet_selectRole.send then
                    local ok = pcall(function() loadedPk.bytenet_selectRole.send(data) end)
                    if not ok then
                        pcall(function() loadedPk.bytenet_selectRole:send(data) end)
                    end
                    return
                end
                pcall(function()
                    local rsPackets = game:GetService("ReplicatedStorage"):FindFirstChild("packets")
                        or game:GetService("ReplicatedStorage"):FindFirstChild("packets", true)
                    if rsPackets then
                        local mod = require(rsPackets)
                        if mod and mod.bytenet_selectRole and mod.bytenet_selectRole.send then
                            mod.bytenet_selectRole.send(data)
                        end
                    end
                end)
            end
        },
        bytenet_clientCFrame = {
            send = function(data)
            end
        }
    }

    local netShim = {
        Packets = Packets or standalonePackets
    }

    function netShim.GetPackets()
        return findLoadedPackets() or standalonePackets
    end

    function netShim.FireServer(_, dataBuffer, actionsList)
        local bufferType = convertToString(dataBuffer)
        local remote = GetByteNetReliable()
        local loadedPk = findLoadedPackets()

        if bufferType == "base" then
            if type(actionsList) ~= "table" then return end

            local fired = false
            if loadedPk and loadedPk.bytenet_use and loadedPk.bytenet_use.send then
                for _, primaryAction in ipairs(actionsList) do
                    if type(primaryAction) == "table" then
                        local success = pcall(loadedPk.bytenet_use.send, primaryAction)
                        if success then
                            fired = true
                        else
                            warnOnce("use_" .. tostring(primaryAction),
                                "bytenet_use execution failed for: " .. tostring(primaryAction))
                        end
                    end
                end
            end

            if not fired then
                if remote then
                    pcall(function()
                        remote:FireServer(BN_UseBuffer(), actionsList)
                    end)
                    pcall(function()
                        remote:FireServer(dataBuffer, actionsList)
                    end)
                end

                local bc = GetBaseClient()
                if bc then
                    for _, primaryAction in ipairs(actionsList) do
                        if type(primaryAction) == "table" then
                            pcall(function()
                                if bc.senduse then
                                    bc:senduse(primaryAction)
                                elseif bc.use then
                                    bc:use(unpack(primaryAction))
                                end
                            end)
                        end
                    end
                end
            end
        elseif bufferType == "grabball" then
            local fired = false
            if loadedPk and loadedPk.bytenet_findBall and loadedPk.bytenet_findBall.send then
                local success = pcall(function() loadedPk.bytenet_findBall.send() end)
                if not success then
                    success = pcall(function() loadedPk.bytenet_findBall:send() end)
                end
                if success then
                    fired = true
                else
                    warnOnce("grab", "bytenet_findBall execution channel failed.")
                end
            end

            if not fired and remote then
                pcall(function()
                    remote:FireServer(BN_FindBallBuffer())
                end)
                pcall(function()
                    remote:FireServer(dataBuffer, actionsList)
                end)
            end
        else
            if remote then
                pcall(function()
                    if actionsList ~= nil then
                        remote:FireServer(dataBuffer, actionsList)
                    else
                        remote:FireServer(dataBuffer)
                    end
                end)
            end
        end
    end

    netShim.fireServer = netShim.FireServer
    return netShim
end)()

local function BN_SendClientCFrame()
    pcall(function()
        local cam = Workspace.CurrentCamera
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not cam or not hrp then return end
        local p = NET and NET.GetPackets and NET.GetPackets()
        if p and p.bytenet_clientCFrame and p.bytenet_clientCFrame.send then
            local lv = hrp.CFrame.LookVector
            local clampY = math.clamp(cam.CFrame.LookVector.Y, -1, 1)
            local adjDir = Vector3.new(lv.X, clampY, lv.Z)
            p.bytenet_clientCFrame.send({
                adjustedDirection = adjDir,
                camCFrame = cam.CFrame
            })
        end
    end)
end

local function FireUse(name)
    pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { name } }) end)
end

local function IsDribbleOnCooldown()
    local gui = Player:FindFirstChild("PlayerGui")
    local hotbar = gui and gui:FindFirstChild("Hotbar")
    if not hotbar then return false end
    for _, v in ipairs(hotbar:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text and v.Text:find("dribble", 1, true) then
            return true
        end
    end
    return false
end

local function FireDribble(allowDash)
    if IsDribbleOnCooldown() then
        if allowDash then
            pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { "run" } }) end)
        end
    else
        pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { "dribble", false } }) end)
    end
end

local function GetTeam(name)
    local p = Players:FindFirstChild(name)
    if p and p.Team and p.Team.Name ~= "" and p.Team.Name ~= "lobby" and p.Team.Name ~= "Spectators" then
        return p.Team.Name
    end
    local chars = Workspace:FindFirstChild("characters")
    local c = (chars and chars:FindFirstChild(name)) or (p and p.Character)
    local st = c and c:FindFirstChild("state")
    local t = st and st:FindFirstChild("team")
    if t and t.Value and t.Value ~= "" and t.Value ~= "lobby" and t.Value ~= "Spectators" then
        return t.Value
    end
    if p and p:GetAttribute("team") and p:GetAttribute("team") ~= "" and p:GetAttribute("team") ~= "lobby" and p:GetAttribute("team") ~= "Spectators" then
        return tostring(p:GetAttribute("team"))
    end
    if c and c:GetAttribute("team") and c:GetAttribute("team") ~= "" and c:GetAttribute("team") ~= "lobby" and c:GetAttribute("team") ~= "Spectators" then
        return tostring(c:GetAttribute("team"))
    end
    return nil
end

local function HasIFrame(name)
    local chars = Workspace:FindFirstChild("characters")
    local c = chars and chars:FindFirstChild(name)
    if not c then return false end
    local st = c:FindFirstChild("state")
    local f = st and st:FindFirstChild("iframe")
    return f and f.Value == true
end

local function HasMyIFrame()
    return HasIFrame(Player.Name)
end

local function GetHitboxPosition(char, defaultPart)
    if char then
        local hbId = char:GetAttribute("HitboxId")
        if hbId then
            local fx = Workspace:FindFirstChild("Effects")
            local hv = fx and fx:FindFirstChild("HitboxVisuals")
            local box = hv and hv:FindFirstChild(hbId)
            if box then
                return box.Position + Vector3.new(0, 0.5, 0)
            end
        end
    end
    return defaultPart and defaultPart.Position or nil
end

local function HasBall(name)
    local rsWorkspace = ReplicatedStorage:FindFirstChild("workspace")
    if rsWorkspace and rsWorkspace:FindFirstChild("ballHolder") then
        local holder = rsWorkspace.ballHolder.Value
        if holder then
            if name then
                if holder.Name == name then return true end
            else
                if holder == Player.Character then return true end
            end
        end
    end
    local chars = Workspace:FindFirstChild("characters")
    local c = chars and chars:FindFirstChild(name or Player.Name)
    if not c then return false end
    return c:FindFirstChild("Ball") ~= nil or c:FindFirstChild("AlternateBallRig") ~= nil
end

local function FindSkillButton(name)
    local gui = Player:FindFirstChild("PlayerGui")
    local hb = gui and gui:FindFirstChild("Hotbar")
    local bp = hb and hb:FindFirstChild("Backpack")
    local hf = bp and bp:FindFirstChild("Hotbar")
    if hf then
        local found = hf:FindFirstChild(name)
        if found then return found end
        for _, child in ipairs(hf:GetChildren()) do
            if child.Name:lower() == name:lower() then return child end
        end
    end
    if hb then
        local found = hb:FindFirstChild(name, true)
        if found then return found end
        for _, child in ipairs(hb:GetDescendants()) do
            if child:IsA("GuiObject") and child.Name:lower() == name:lower() then return child end
        end
    end
    return nil
end

local function IsSkillOnCooldown(name)
    local btn = FindSkillButton(name)
    if not btn then return true end
    local cd = btn:FindFirstChild("Cooldown")
    if not cd then return false end
    return cd.AbsoluteSize.Y > 1 or (cd.Visible and cd.BackgroundTransparency < 0.9)
end

local function HasCrossElastico()
    local btn = FindSkillButton("skill2")
    local base = btn and btn:FindFirstChild("Base")
    local toolName = base and base:FindFirstChild("ToolName")
    return toolName and toolName.Text == "Cross Elastico"
end

local function IsSaeReflex()
    local gui = Player:FindFirstChild("PlayerGui")
    local hb = gui and gui:FindFirstChild("Hotbar")
    local mh = hb and hb:FindFirstChild("MagicHealth")
    local saeText = mh and mh:FindFirstChild("saeText")
    return saeText and saeText.Text ~= "LOGIC"
end

local function GetReoSkill4ToolName()
    local gui = Player:FindFirstChild("PlayerGui")
    local hb = gui and gui:FindFirstChild("Hotbar")
    local bp = hb and hb:FindFirstChild("Backpack")
    local hf = bp and bp:FindFirstChild("Hotbar")
    local s4 = hf and hf:FindFirstChild("skill4")
    local base = s4 and s4:FindFirstChild("Base")
    local tn = base and base:FindFirstChild("ToolName")
    return tn and tn.Text or nil
end

local HioriSpecialAnims = {
    ["116769918041530"] = true,
    ["126660944970058"] = true,
    ["80537494389388"]  = true,
    ["88376233137551"]  = true,
}

local function IsHioriSpecialAnimPlaying()
    local char = Player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        if track.Animation then
            local animId = tostring(track.Animation.AnimationId)
            for id in pairs(HioriSpecialAnims) do
                if animId:find(id, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

local function IsMasteryLorenzoAnimPlaying()
    local char = Player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")

    local allTracks = {}
    pcall(function()
        if animator then
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do table.insert(allTracks, t) end
        end
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do table.insert(allTracks, t) end
    end)

    for _, track in ipairs(allTracks) do
        local anim = track.Animation
        local animId = anim and tostring(anim.AnimationId) or ""
        if animId:find("85862104307480", 1, true) or tostring(track.Name):find("85862104307480", 1, true) then
            return true
        end
    end
    return false
end

local function ShouldIgnoreIFrameForCounter()
    local style = Player:GetAttribute("style")
    if style == "hiori" and IsHioriSpecialAnimPlaying() then return true end
    if style == "masterylorenzo" and IsMasteryLorenzoAnimPlaying() then return true end
    return false
end

local AutoCounter = {
    Enabled = false,
    Mode = "New",
    Connection = nil,
    PreferDribble = false,
    UseDash = false,
    SoundHooks = {},
    SoundCooldowns = {},
    Cooldowns = {},
    HookedHRPs = {},
    ActiveTargets = {},
    ActiveWindow = 5,
    CounterCooldown = 0.1,
    ActivationDistance = 60,
    CloseDistance = 11,
    MaxAngleDeg = 15,
    UseDelay = false,
    DelayAmount = 0.3,
    FixMisses = true,
    ShowRange = false,
    RangeFolder = nil,
    RangeBase = nil,
    RangeConnection = nil,
    TackleAnims = {
        ["109744655458082"] = true,
    },
    HookedChars = {},
    CharConnections = {},
    CharsAddedConnection = nil,

    SoundIds = {
        ["71212694698006"] = true,
        ["124780743838383"] = true,
    },

    SpecialSoundIds = {
        ["137771919165585"] = true,
        ["136095107474705"] = true,
        ["135794884575834"] = true,
        ["117676277921436"] = true,
        ["77834862567057"] = true,
        ["89339537870505"] = true,
        ["86374214619488"] = true,
        ["83955271022581"] = true,
        ["80313615927187"] = true,
    },
    SpecialDistance = 60,

    StyleSkills = {
        nagi           = "Tspecialer",
        bachira        = "skill2",
        yukimiya       = "skill4",
        kaiser         = "skill4",
        masterykaiser  = "skill4",
        sae            = "skill2",
        barou          = "skill1",
        rin            = "skill2",
        nelisagi       = "skill4",
        reo            = "skill2",
        karasu         = "skill1",
        masterylorenzo = "skill2",
        kurona         = "skill3",
        kiyora         = "skill2",
        hiori          = "Tspecialer",
    },
}

local function ExtractSoundId(s)
    if not s then return nil end
    local sid = ""
    pcall(function()
        sid = tostring(s.SoundId or "")
    end)
    local id = sid:match("rbxassetid://(%d+)") or sid:match("id=(%d+)") or sid:match("://(%d+)") or sid:match("(%d+)")
    if not id then
        pcall(function()
            id = tostring(s.Name):match("(%d+)")
        end)
    end
    return id
end

function AutoCounter.AttemptForSound(sound)
    if not AutoCounter.Enabled then
        return
    end
    if HasMyIFrame() and not ShouldIgnoreIFrameForCounter() then
        return
    end

    local id = ExtractSoundId(sound)
    if not id then
        return
    end

    local isSpecial = AutoCounter.SpecialSoundIds[id]
    local isNormalSound = AutoCounter.SoundIds and AutoCounter.SoundIds[id]

    if not isSpecial then
        if AutoCounter.Mode ~= "Old" or not isNormalSound then
            return
        end
    end

    local chars = Workspace:FindFirstChild("characters")
    if not chars then return end
    local char = nil
    local current = sound.Parent
    while current and current ~= chars and current ~= Workspace do
        if current.Parent == chars and current:IsA("Model") then
            char = current
            break
        end
        current = current.Parent
    end
    if not char or char.Name == Player.Name then
        return
    end

    local theirHRP = char:FindFirstChild("HumanoidRootPart")
    if not theirHRP then
        return
    end

    local key = char.Name .. "_" .. id
    local now = tick()
    local lastTrigger = AutoCounter.SoundCooldowns[key] or 0
    if (now - lastTrigger) < 0.2 then
        return
    end
    AutoCounter.SoundCooldowns[key] = now

    local window = isSpecial and math.max(AutoCounter.ActiveWindow, 3) or AutoCounter.ActiveWindow
    if AutoCounter.ActiveTargets[key] then
        AutoCounter.ActiveTargets[key].expiry = now + window
        AutoCounter.ActiveTargets[key].sound = sound
        AutoCounter.ActiveTargets[key].hrp = theirHRP
        AutoCounter.ActiveTargets[key].startTime = now
    else
        AutoCounter.ActiveTargets[key] = {
            charName = char.Name,
            hrp = theirHRP,
            expiry = now + window,
            startTime = now,
            special = isSpecial or false,
            id = id,
            sound = sound,
        }
    end

    AutoCounter.TryCounter()
end

function AutoCounter.AttemptForTackleAnim(char, hrp, track)
    if not AutoCounter.Enabled then
        return
    end
    if HasMyIFrame() and not ShouldIgnoreIFrameForCounter() then
        return
    end
    if not char or not char.Parent or char.Parent.Name ~= "characters" then
        return
    end
    if char.Name == Player.Name then
        return
    end

    local key = char.Name .. "_tackle"
    if AutoCounter.ActiveTargets[key] then
        AutoCounter.ActiveTargets[key].expiry = tick() + AutoCounter.ActiveWindow
        AutoCounter.ActiveTargets[key].track = track
        AutoCounter.ActiveTargets[key].hrp = hrp
        AutoCounter.ActiveTargets[key].startTime = tick()
    else
        AutoCounter.ActiveTargets[key] = {
            charName = char.Name,
            hrp = hrp,
            expiry = tick() + AutoCounter.ActiveWindow,
            special = true,
            track = track,
            startTime = tick(),
        }
    end

    AutoCounter.TryCounter()
end

function AutoCounter.TryCounter()
    if not AutoCounter.Enabled then return end
    if not next(AutoCounter.ActiveTargets) then return end

    local now = tick()
    local logNow = (now - (AutoCounter._lastLog or 0)) >= 0.3
    if logNow then AutoCounter._lastLog = now end

    local ball = HasBall()
    if not ball then
        return
    end

    if HasMyIFrame() and not ShouldIgnoreIFrameForCounter() then
        return
    end

    local myChar = Player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        return
    end

    local mine = GetTeam(Player.Name)
    if not mine or mine == "lobby" then
        return
    end

    if AutoCounter.Mode == "Old" then
        for key, data in pairs(AutoCounter.ActiveTargets) do
            if now > data.expiry then
                AutoCounter.ActiveTargets[key] = nil
            else
                if not data.special and data.sound and not data.sound.IsPlaying and (now - (data.startTime or now)) > 0.6 then
                    AutoCounter.ActiveTargets[key] = nil
                    continue
                end
                if AutoCounter.FixMisses and (data.id == "71212694698006" or data.id == "124780743838383") and data.sound and data.sound.TimePosition > 0.5 then
                    AutoCounter.ActiveTargets[key] = nil
                    continue
                end
                local hrp = data.hrp
                if not hrp or not hrp.Parent then
                    local chars = Workspace:FindFirstChild("characters")
                    local c = chars and chars:FindFirstChild(data.charName)
                    hrp = c and c:FindFirstChild("HumanoidRootPart")
                    data.hrp = hrp
                end

                if hrp and hrp.Parent then
                    local theirs = GetTeam(data.charName)
                    local enemyPos = GetHitboxPosition(hrp.Parent, hrp)
                    local dist = (myHRP.Position - enemyPos).Magnitude
                    local close = dist <= (AutoCounter.CloseDistance or 11)
                    local maxDist = data.special and (AutoCounter.SpecialDistance or AutoCounter.ActivationDistance) or
                        AutoCounter.ActivationDistance
                    local inRange = close or dist <= maxDist
                    local angleOk = close
                    if not close then
                        local toMe = (myHRP.Position - hrp.Position).Unit
                        local dot = hrp.CFrame.LookVector:Dot(toMe)
                        local angle = math.acos(math.clamp(dot, -1, 1))
                        angleOk = angle <= math.rad(AutoCounter.MaxAngleDeg or 15)
                    end
                    local iframe = HasIFrame(data.charName)

                    local teamOk = theirs and theirs ~= "lobby" and theirs ~= mine

                    if teamOk and inRange and angleOk and (data.special or iframe) then
                        local last = AutoCounter.Cooldowns[data.charName] or 0
                        if now - last >= AutoCounter.CounterCooldown then
                            AutoCounter.Cooldowns[data.charName] = now
                            AutoCounter.ActiveTargets[key] = nil

                            if AutoCounter.UseDelay and AutoCounter.DelayAmount > 0 then
                                task.delay(AutoCounter.DelayAmount, function() AutoCounter.PerformCounter() end)
                            else
                                AutoCounter.PerformCounter()
                            end
                            return
                        end
                    end
                end
            end
        end
        return
    end


    for key, data in pairs(AutoCounter.ActiveTargets) do
        if now > data.expiry then
            AutoCounter.ActiveTargets[key] = nil
        else
            if data.track and not data.track.IsPlaying then
                AutoCounter.ActiveTargets[key] = nil
                continue
            end
            if AutoCounter.FixMisses and data.track and (data.track.TimePosition > 0.5 or (data.startTime and (now - data.startTime) > 0.5)) then
                AutoCounter.ActiveTargets[key] = nil
                continue
            end
            if not data.special and data.sound and not data.sound.IsPlaying and (now - (data.startTime or now)) > 0.6 then
                AutoCounter.ActiveTargets[key] = nil
                continue
            end
            local hrp = data.hrp
            if not hrp or not hrp.Parent then
                local chars = Workspace:FindFirstChild("characters")
                local c = chars and chars:FindFirstChild(data.charName)
                hrp = c and c:FindFirstChild("HumanoidRootPart")
                data.hrp = hrp
            end

            if hrp and hrp.Parent then
                local theirs = GetTeam(data.charName)
                local enemyPos = GetHitboxPosition(hrp.Parent, hrp)
                local toMe3D = myHRP.Position - enemyPos
                local toMeFlat = Vector3.new(toMe3D.X, 0, toMe3D.Z)
                local dist = toMeFlat.Magnitude
                local maxDist = data.special and (AutoCounter.SpecialDistance or AutoCounter.ActivationDistance) or
                    AutoCounter.ActivationDistance
                local inRange = dist <= maxDist
                local angleDeg = 180
                local angleOk = data.angleWasValid or false

                if inRange and not angleOk then
                    if dist <= (AutoCounter.CloseDistance or 11) then
                        angleOk = true
                        data.angleWasValid = true
                    else
                        local enemyLookFlat = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
                        if enemyLookFlat.Magnitude > 0.001 and dist > 0.001 then
                            local dot = enemyLookFlat.Unit:Dot(toMeFlat.Unit)
                            local angle = math.acos(math.clamp(dot, -1, 1))
                            angleDeg = math.deg(angle)
                            angleOk = angleDeg <= (AutoCounter.MaxAngleDeg or 15)
                            if angleOk then
                                data.angleWasValid = true
                            end
                        end
                    end
                end
                local iframe = HasIFrame(data.charName)

                local teamOk = theirs and theirs ~= "lobby" and theirs ~= mine

                if teamOk and inRange and angleOk and (data.special or iframe) then
                    local last = AutoCounter.Cooldowns[data.charName] or 0
                    if now - last >= AutoCounter.CounterCooldown then
                        AutoCounter.Cooldowns[data.charName] = now
                        AutoCounter.ActiveTargets[key] = nil

                        if AutoCounter.UseDelay and AutoCounter.DelayAmount > 0 then
                            task.delay(AutoCounter.DelayAmount, function() AutoCounter.PerformCounter() end)
                        else
                            AutoCounter.PerformCounter()
                        end
                        return
                    end
                end
            else

            end
        end
    end
end

function AutoCounter.HookSound(sound)
    if not sound or not sound:IsA("Sound") or AutoCounter.SoundHooks[sound] then return end

    local function onSoundTrigger()
        AutoCounter.AttemptForSound(sound)
    end

    local played = sound.Played:Connect(onSoundTrigger)
    local prop = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then
            onSoundTrigger()
        end
    end)
    local idProp = sound:GetPropertyChangedSignal("SoundId"):Connect(function()
        if sound.IsPlaying or sound.TimePosition > 0 then
            onSoundTrigger()
        end
    end)
    local destroy
    destroy = sound.Destroying:Connect(function()
        pcall(function() played:Disconnect() end)
        pcall(function() prop:Disconnect() end)
        pcall(function() idProp:Disconnect() end)
        pcall(function() destroy:Disconnect() end)
        AutoCounter.SoundHooks[sound] = nil
        AutoCounter.SoundCooldowns[sound] = nil
    end)
    AutoCounter.SoundHooks[sound] = { played = played, prop = prop, idProp = idProp, destroy = destroy }
    if sound.IsPlaying or sound.TimePosition > 0 then
        onSoundTrigger()
    end
end

function AutoCounter.HookHRPSounds(hrp)
    if not hrp or AutoCounter.HookedHRPs[hrp] then return end
    AutoCounter.HookedHRPs[hrp] = true

    for _, s in ipairs(hrp:GetChildren()) do
        if s:IsA("Sound") then AutoCounter.HookSound(s) end
    end
    hrp.ChildAdded:Connect(function(child)
        if AutoCounter.Enabled and child:IsA("Sound") then
            AutoCounter.HookSound(child)
        end
    end)
    hrp.Destroying:Connect(function()
        AutoCounter.HookedHRPs[hrp] = nil
    end)
end

function AutoCounter.UnhookCharacter(char)
    AutoCounter.HookedChars[char] = nil
    local conns = AutoCounter.CharConnections[char]
    if conns then
        for _, c in ipairs(conns) do
            pcall(function() c:Disconnect() end)
        end
        AutoCounter.CharConnections[char] = nil
    end
end

function AutoCounter.HookCharacter(char)
    if not char or char.Name == Player.Name or AutoCounter.HookedChars[char] then return end
    AutoCounter.HookedChars[char] = true
    AutoCounter.CharConnections[char] = {}

    local function addConn(conn)
        if conn then
            table.insert(AutoCounter.CharConnections[char], conn)
        end
    end

    local function hookHRP(hrp)
        if not hrp then return end
        for _, s in ipairs(hrp:GetChildren()) do
            if s:IsA("Sound") then AutoCounter.HookSound(s) end
        end
        addConn(hrp.ChildAdded:Connect(function(child)
            if AutoCounter.Enabled and child:IsA("Sound") then
                AutoCounter.HookSound(child)
            end
        end))
    end

    local function hookHum(hum)
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 1)
        if animator then
            addConn(animator.AnimationPlayed:Connect(function(track)
                if not AutoCounter.Enabled then return end
                local anim = track.Animation
                if anim then
                    local id = tostring(anim.AnimationId):match("%d+")
                    if id and AutoCounter.TackleAnims[id] then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            AutoCounter.AttemptForTackleAnim(char, hrp, track)
                        end
                    end
                end
            end))
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local anim = track.Animation
                if anim then
                    local id = tostring(anim.AnimationId):match("%d+")
                    if id and AutoCounter.TackleAnims[id] then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            AutoCounter.AttemptForTackleAnim(char, hrp, track)
                        end
                    end
                end
            end
        end
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hookHRP(hrp) end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hookHum(hum) end

    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Sound") then
            AutoCounter.HookSound(desc)
        end
    end

    addConn(char.DescendantAdded:Connect(function(child)
        if not AutoCounter.Enabled then return end
        if child:IsA("Sound") then
            AutoCounter.HookSound(child)
        elseif child.Name == "HumanoidRootPart" then
            hookHRP(child)
        elseif child:IsA("Humanoid") then
            hookHum(child)
        end
    end))

    addConn(char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            AutoCounter.UnhookCharacter(char)
        end
    end))
end

local function AC_StopRange()
    if AutoCounter.RangeConnection then
        AutoCounter.RangeConnection:Disconnect()
        AutoCounter.RangeConnection = nil
    end
    if AutoCounter.RangeFolder then
        AutoCounter.RangeFolder:Destroy()
        AutoCounter.RangeFolder = nil
    end
    AutoCounter.RangeBase = nil
end

local function AC_StartRange()
    if AutoCounter.RangeFolder then return end
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "AutoCounter_Range", Workspace

    local base = Instance.new("Part")
    base.Anchored, base.CanCollide, base.CanQuery, base.Transparency = true, false, false, 1
    base.Size = Vector3.new(AutoCounter.ActivationDistance * 2, 0.05, AutoCounter.ActivationDistance * 2)
    base.Parent = folder

    local gui = Instance.new("SurfaceGui")
    gui.Face, gui.LightInfluence, gui.AlwaysOnTop = Enum.NormalId.Top, 0, true
    gui.PixelsPerStud, gui.SizingMode, gui.CanvasSize = 100, Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(200, 200)
    gui.Parent = base

    local circle = Instance.new("Frame")
    circle.AnchorPoint, circle.Position, circle.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5),
        UDim2.fromScale(0.92, 0.92)
    circle.BackgroundColor3, circle.BackgroundTransparency, circle.BorderSizePixel = Color3.fromRGB(149, 138, 204), 0.82,
        0
    circle.Parent = gui
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Color, stroke.Thickness, stroke.Transparency = Color3.fromRGB(170, 160, 225), 3, 0
    stroke.Parent = circle

    AutoCounter.RangeFolder, AutoCounter.RangeBase = folder, base
    AutoCounter.RangeConnection = RunService.RenderStepped:Connect(function()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not AutoCounter.ShowRange then return end
        local team = GetTeam(Player.Name)
        if not team or team == "lobby" or not HasBall() then
            base.Parent = nil
            return
        end
        if base.Parent ~= folder then base.Parent = folder end
        local size = AutoCounter.ActivationDistance * 2
        base.Size = Vector3.new(size, 0.05, size)
        base.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3.2, 0))
    end)
end

function AutoCounter.Cleanup()
    AC_StopRange()
    if AutoCounter.Connection then
        pcall(function() AutoCounter.Connection:Disconnect() end)
        AutoCounter.Connection = nil
    end
    if AutoCounter.CharsAddedConnection then
        pcall(function() AutoCounter.CharsAddedConnection:Disconnect() end)
        AutoCounter.CharsAddedConnection = nil
    end
    for char, conns in pairs(AutoCounter.CharConnections) do
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end
    AutoCounter.CharConnections = {}
    AutoCounter.HookedChars = {}
    for _, hooks in pairs(AutoCounter.SoundHooks) do
        for _, c in pairs(hooks) do pcall(function() c:Disconnect() end) end
    end
    AutoCounter.SoundHooks = {}
    AutoCounter.SoundCooldowns = {}
    AutoCounter.Cooldowns = {}
    AutoCounter.HookedHRPs = {}
    AutoCounter.ActiveTargets = {}
end

function AutoCounter.Start()
    AutoCounter.Enabled = true

    if AutoCounter.ShowRange then AC_StartRange() end

    if AutoCounter.Connection then AutoCounter.Connection:Disconnect() end
    AutoCounter.Connection = RunService.Heartbeat:Connect(AutoCounter.TryCounter)

    local chars = Workspace:FindFirstChild("characters")
    if chars then
        for _, c in ipairs(chars:GetChildren()) do
            AutoCounter.HookCharacter(c)
        end
        if AutoCounter.CharsAddedConnection then AutoCounter.CharsAddedConnection:Disconnect() end
        AutoCounter.CharsAddedConnection = chars.ChildAdded:Connect(function(c)
            if AutoCounter.Enabled then
                AutoCounter.HookCharacter(c)
            end
        end)
    end

    task.spawn(function()
        while AutoCounter.Enabled do
            task.wait(3)
            if not AutoCounter.Enabled then break end
            local ch = Workspace:FindFirstChild("characters")
            if ch then
                for _, c in ipairs(ch:GetChildren()) do
                    AutoCounter.HookCharacter(c)
                end
            end
        end
    end)
    SafeNotify("Auto Counter Enabled", 2, "Enable")
end

function AutoCounter.Stop()
    AutoCounter.Enabled = false

    AutoCounter.Cleanup()
    SafeNotify("Auto Counter Disabled", 2, "Disable")
end

AutoCounter.Toggle = Library:CreateToggle(AutoCounterSection, {
    Name = "Auto Counter",
    Default = false,
    Callback = function(v) if v then AutoCounter.Start() else AutoCounter.Stop() end end
})

Library:CreateDropdown(AutoCounterSection, {
    Name = "Mode",
    Options = { "New", "Old" },
    Default = "New",
    Callback = function(v) AutoCounter.Mode = v end
})

AutoCounter.Keybind = Library:CreateKeybind(AutoCounterSection, {
    Name = "Auto Counter",
    Default = Enum.KeyCode.X,
    Mode = "Toggle",
    Callback = function(active)
        local t = AutoCounter.Toggle
        if not t or not t.SetValue then return end
        if t.Value ~= active then
            t:SetValue(active and true or false)
        end
    end
})

Library:CreateToggle(AutoCounterSection, {
    Name = "Prefer Dribble",
    Default = false,
    Callback = function(v) AutoCounter.PreferDribble = v end
})

Library:CreateToggle(AutoCounterSection, {
    Name = "Use Dash",
    Default = false,
    Callback = function(v) AutoCounter.UseDash = v end
})

Library:CreateToggle(AutoCounterSection, {
    Name = "Fix Misses",
    Default = true,
    Callback = function(v) AutoCounter.FixMisses = v end
})

Library:CreateSlider(AutoCounterSection, {
    Name = "Activation Range",
    Min = 25,
    Max = 90,
    Default = 60,
    Step = 0.1,
    Suffix = " studs",
    Callback = function(v)
        AutoCounter.ActivationDistance = v
        AutoCounter.SpecialDistance = v
    end
})

Library:CreateSlider(AutoCounterSection, {
    Name = "Max Angle",
    Min = 1,
    Max = 25,
    Default = 15,
    Step = 1,
    Suffix = "°",
    Callback = function(v) AutoCounter.MaxAngleDeg = v end
})

Library:CreateToggle(AutoCounterSection, {
    Name = "Show Range",
    Default = false,
    Callback = function(v)
        AutoCounter.ShowRange = v
        if v then AC_StartRange() else AC_StopRange() end
    end
})

Library:CreateToggle(AutoCounterSection, {
    Name = "Delay",
    Default = false,
    Callback = function(v) AutoCounter.UseDelay = v end
})

Library:CreateSlider(AutoCounterSection, {
    Name = "Delay Amount",
    Min = 0.01,
    Max = 3,
    Default = 0.3,
    Step = 0.01,
    Suffix = " s",
    Callback = function(v) AutoCounter.DelayAmount = v end
})

local SkillSwap = {
    bachira = { skills = { "skill2", "skill1", "skill4" }, current = 1, preferred = 1 },
    rin = { skills = { "skill2", "skill5" }, current = 1, preferred = 1 },
    sae = { skills = { "skill2", "skill5" }, current = 1, preferred = 1 },
    yukimiya = { skills = { "skill4", "skill2" }, current = 1, preferred = 1 },
    karasu = { skills = { "skill1", "Tspecialer" }, current = 1, preferred = 1 },
    reo = { skills = { "skill2", "skill1" }, current = 1, preferred = 1 },
}

local GlobalFlowTracker = {
    Was100 = false,
    IsActive = false,
}

task.spawn(function()
    while true do
        task.wait(0.1)
        local chars = Workspace:FindFirstChild("characters")
        local my = chars and chars:FindFirstChild(Player.Name)
        local st = my and my:FindFirstChild("state")
        local flow = st and st:FindFirstChild("flow")
        local flowVal = flow and tonumber(flow.Value) or 0

        if flowVal >= 100 then
            GlobalFlowTracker.Was100 = true
            GlobalFlowTracker.IsActive = false
        elseif GlobalFlowTracker.Was100 and flowVal < 100 and flowVal > 0 then
            GlobalFlowTracker.IsActive = true
        elseif flowVal <= 0 then
            GlobalFlowTracker.Was100 = false
            GlobalFlowTracker.IsActive = false
        end
    end
end)

local function GetFlow()
    local char = Player.Character
    local chars = Workspace:FindFirstChild("characters")
    local my = (chars and chars:FindFirstChild(Player.Name)) or char
    local st = my and my:FindFirstChild("state")
    local flow = st and st:FindFirstChild("flow")
    if flow and tonumber(flow.Value) then return tonumber(flow.Value) end
    if char then
        local charState = char:FindFirstChild("state")
        local charFlow = charState and charState:FindFirstChild("flow")
        if charFlow and tonumber(charFlow.Value) then return tonumber(charFlow.Value) end
        local attrFlow = char:GetAttribute("flow")
        if attrFlow and tonumber(attrFlow) then return tonumber(attrFlow) end
    end
    local gui = Player:FindFirstChild("PlayerGui")
    local hb = gui and gui:FindFirstChild("Hotbar")
    local mh = hb and hb:FindFirstChild("MagicHealth")
    local h = mh and mh:FindFirstChild("Health")
    local fc = h and h:FindFirstChild("flowCharge")
    if fc and fc.Text then
        local num = tonumber(fc.Text:match("(%d+)"))
        if num then return num end
    end
    return 0
end

local function IsInFlow()
    return GlobalFlowTracker.IsActive
end

local function CanUseSwapSkill(style, skill)
    if style == "rin" and skill == "skill5" then return IsInFlow() end
    if style == "sae" and skill == "skill5" then
        local isLastAwk = false
        pcall(function()
            local folder = ReplicatedStorage:FindFirstChild("workspace")
            local lastAwaken = folder and folder:FindFirstChild("lastAwaken")
            local val = lastAwaken and lastAwaken.Value
            isLastAwk = (val == Player or val == Player.Name or (typeof(val) == "Instance" and val.Name == Player.Name))
        end)
        return IsInFlow() and isLastAwk
    end
    if style == "reo" then
        if skill == "skill1" then
            local pGui = Player:FindFirstChild("PlayerGui")
            local tName = pGui and pGui:FindFirstChild("Hotbar") and pGui.Hotbar:FindFirstChild("Backpack") and
                pGui.Hotbar.Backpack:FindFirstChild("Hotbar") and pGui.Hotbar.Backpack.Hotbar:FindFirstChild("skill1") and
                pGui.Hotbar.Backpack.Hotbar.skill1:FindFirstChild("Base") and
                pGui.Hotbar.Backpack.Hotbar.skill1.Base:FindFirstChild("ToolName")
            return (tName and tName:IsA("TextLabel") and tName.Text == "Twin Steps")
        elseif skill == "skill2" then
            return HasCrossElastico()
        end
    end
    return true
end

local function GetCurrentCounterSkill()
    local style = Player:GetAttribute("style")
    local swap = SkillSwap[style]
    if not swap then return AutoCounter.StyleSkills[style] end

    local skill = swap.skills[swap.current]

    if not CanUseSwapSkill(style, skill) then
        swap.current = 1
        skill = swap.skills[1]
    end

    if IsSkillOnCooldown(skill) then
        for i, s in ipairs(swap.skills) do
            if i ~= swap.current and not IsSkillOnCooldown(s) then
                if CanUseSwapSkill(style, s) then return s end
            end
        end
    end

    return skill
end

task.spawn(function()
    while true do
        task.wait(0.2)
        local style = Player:GetAttribute("style")
        local swap = SkillSwap[style]
        if swap then
            local currentSkill = swap.skills[swap.current]
            local prefSkill = swap.skills[swap.preferred]

            if not CanUseSwapSkill(style, currentSkill) or not CanUseSwapSkill(style, prefSkill) then
                if swap.current ~= 1 or swap.preferred ~= 1 then
                    swap.current = 1
                    swap.preferred = 1
                    AutoCounter.StyleSkills[style] = swap.skills[1]
                end
            elseif swap.current ~= swap.preferred then
                if not IsSkillOnCooldown(prefSkill) then
                    swap.current = swap.preferred
                    AutoCounter.StyleSkills[style] = prefSkill
                end
            end
        end
    end
end)

local function DoSkillSwap()
    local style = Player:GetAttribute("style")
    local swap = SkillSwap[style]
    if not swap then
        return
    end

    local allOnCd = true
    local maxIndex = #swap.skills
    while maxIndex > 1 and not CanUseSwapSkill(style, swap.skills[maxIndex]) do maxIndex = maxIndex - 1 end
    for i = 1, maxIndex do
        if not IsSkillOnCooldown(swap.skills[i]) then
            allOnCd = false
            break
        end
    end
    if allOnCd then
        SafeNotify("Skill Swap: all skills on cooldown", 2)
        return
    end

    local next = swap.current + 1
    if next > maxIndex then next = 1 end

    local tried = 0
    while IsSkillOnCooldown(swap.skills[next]) and tried < maxIndex do
        next = next + 1
        if next > maxIndex then next = 1 end
        tried = tried + 1
    end

    swap.current = next
    swap.preferred = next

    local skill = swap.skills[next]
    AutoCounter.StyleSkills[style] = skill
    SafeNotify("Skill Swap: " .. tostring(style) .. " > " .. skill, 2)
end

Library:CreateKeybind(AutoCounterSection, {
    Name = "Skill Swap",
    Default = Enum.KeyCode.C,
    Mode = "Hold",
    ManualWatermark = true,
    Callback = function(active)
        if active then DoSkillSwap() end
    end
})

AutoCounter.Mode = "counter"

Library:CreateKeybind(AutoCounterSection, {
    Name = "Mode Swap",
    Default = Enum.KeyCode.Z,
    Mode = "Hold",
    ManualWatermark = true,
    Callback = function(active)
        if not active then return end
        if AutoCounter.Mode == "counter" then
            AutoCounter.Mode = "dribble"
            SafeNotify("Mode: Auto Dribble", 2)
        else
            AutoCounter.Mode = "counter"
            SafeNotify("Mode: Auto Counter", 2)
        end
    end
})

function AutoCounter.GetRandomTeammate()
    local chars = Workspace:FindFirstChild("characters")
    local myChar = chars and chars:FindFirstChild(Player.Name)
    local myTeam = myChar and myChar:FindFirstChild("state") and myChar.state:FindFirstChild("team") and
        myChar.state.team.Value
    local teammates = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local char = p.Character or (chars and chars:FindFirstChild(p.Name))
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then continue end

            local isTeammate = false
            local cState = char:FindFirstChild("state")
            local cTeam = cState and cState:FindFirstChild("team") and cState.team.Value

            if myTeam and myTeam ~= "lobby" and cTeam then
                isTeammate = (cTeam == myTeam)
            elseif p.Team and Player.Team and Player.Team.Name ~= "lobby" then
                isTeammate = (p.Team == Player.Team)
            end

            if isTeammate then
                table.insert(teammates, char)
            end
        end
    end

    if #teammates > 0 then
        return teammates[math.random(1, #teammates)]
    end
    return nil
end

function AutoCounter.PerformCounter()
    shared.CancelAutoLineUps = true

    local now = tick()
    if AutoCounter.LastPerformTime and (now - AutoCounter.LastPerformTime) < 0.15 then
        return
    end
    AutoCounter.LastPerformTime = now

    if HasMyIFrame() and not ShouldIgnoreIFrameForCounter() then
        return
    end
    local style = Player:GetAttribute("style")

    if style == "hiori" and IsHioriSpecialAnimPlaying() then
        if not IsSkillOnCooldown("Tspecialer") then
            FireUse("Tspecialer")
        else
            FireDribble(AutoCounter.UseDash)
        end
        return
    end

    if AutoCounter.Mode == "dribble" then
        FireDribble(AutoCounter.UseDash)
        return
    end

    if AutoCounter.Mode == "counter" and AutoCounter.PreferDribble then
        if not IsDribbleOnCooldown() then
            FireDribble(false)
            return
        end
    end

    if style == "barou" then
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local isAnimPlaying = false
        if hum then
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                if track.Animation and tostring(track.Animation.AnimationId):match("73560885704292") then
                    isAnimPlaying = true
                    break
                end
            end
        end
        if isAnimPlaying then
            FireUse("Tspecialer")
            return
        end
    end

    if style == "sae" then
        local skill = GetCurrentCounterSkill()
        if skill == "skill5" and not IsSkillOnCooldown("skill5") and CanUseSwapSkill("sae", "skill5") then
            if not IsSaeReflex() then
                FireUse("Tspecialer")
                task.wait(0.03)
            end
            FireUse("skill5")
        elseif IsSaeReflex() or IsSkillOnCooldown("skill2") then
            FireDribble(AutoCounter.UseDash)
        else
            FireUse("skill2")
        end
        return
    end

    if style == "reo" then
        local copiedCounters = {
            ["Imperial Break"] = true,
            ["Fake Volley"] = true,
            ["Step Overs"] = true,
            ["Monster Counter"] = true,
            ["Monster Trance"] = true,
            ["Drag Scissors"] = true,
            ["Street Tag"] = true,
            ["Rabona Nutmeg"] = true,
            ["Chop Dribble"] = true,
            ["Fake Shot"] = true,
            ["Corvine Feint"] = true,
            ["Feint"] = true,
            ["Dance Battle"] = true,
        }

        local skill4Name = ""
        local pGui = Player:FindFirstChild("PlayerGui")
        local hb = pGui and pGui:FindFirstChild("Hotbar")
        local bp = hb and hb:FindFirstChild("Backpack")
        local hf = bp and bp:FindFirstChild("Hotbar")
        local s4 = hf and hf:FindFirstChild("skill4")
        local base = s4 and s4:FindFirstChild("Base")
        local tName = base and base:FindFirstChild("ToolName")
        if tName and tName:IsA("TextLabel") then
            skill4Name = tName.Text
        end

        if copiedCounters[skill4Name] and not IsSkillOnCooldown("skill4") then
            FireUse("skill4")
        else
            local prefSkill = GetCurrentCounterSkill()
            if prefSkill and not IsSkillOnCooldown(prefSkill) then
                FireUse(prefSkill)
            else
                FireDribble(AutoCounter.UseDash)
            end
        end
        return
    end

    if style == "masterylorenzo" then
        if IsMasteryLorenzoAnimPlaying() then
            FireUse("skill2")
            pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { "skill2" } }) end)
            pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { "skill2", true } }) end)
            return
        end

        if IsSkillOnCooldown("skill2") then
            FireDribble(AutoCounter.UseDash)
            return
        end

        local teammate = AutoCounter.GetRandomTeammate()
        if teammate then
            pcall(function()
                NET:FireServer(buffer.fromstring(buffers["base"]), {
                    { "skill2", teammate }
                })
            end)
            FireUse("skill2")
        else
            FireDribble(AutoCounter.UseDash)
        end
        return
    end

    local swap = SkillSwap[style]
    if swap then
        local skill = GetCurrentCounterSkill()
        if skill and not IsSkillOnCooldown(skill) then
            FireUse(skill)
        else
            FireDribble(AutoCounter.UseDash)
        end
        return
    end

    local skill = AutoCounter.StyleSkills[style]
    if skill and not IsSkillOnCooldown(skill) then
        FireUse(skill)
    else
        FireDribble(AutoCounter.UseDash)
    end
end

do
    local AutoPosition = {
        Enabled = false,
        Role = "CF",
        Team = "A",
        Connection = nil,
        GuiConnection = nil,
        RoleConnA = nil,
        RoleConnB = nil,
        LoopThread = nil,
        Toggle = nil,
        RoleDropdown = nil,
        TeamDropdown = nil,
        RoleMapping = {
            CF = 1,
            LW = 2,
            RW = 3,
            CM = 4,
            GK = 5,
        },
        CF = { Enabled = false },
        GK = { Enabled = false }
    }

    local function AP_GetPackets()
        local pk = NET and NET.GetPackets and NET.GetPackets()
        if pk and (rawget(pk, "bytenet_selectRole") or pk.bytenet_selectRole) then
            return pk
        end
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local pMod = rs:FindFirstChild("packets", true)
            if pMod then
                local res = require(pMod)
                if type(res) == "table" and (rawget(res, "bytenet_selectRole") or res.bytenet_selectRole) then
                    pk = res
                end
            end
        end)
        return pk
    end

    local cachedWiki = nil
    local function AP_GetWiki()
        if cachedWiki then return cachedWiki end
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local w = rs:FindFirstChild("wiki") or rs:FindFirstChild("wiki", true)
            if w then
                cachedWiki = require(w)
            end
        end)
        if not cachedWiki then
            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local clientFolder = rs:FindFirstChild("client")
                if clientFolder and clientFolder:FindFirstChild("wiki") then
                    cachedWiki = require(clientFolder.wiki)
                end
            end)
        end
        return cachedWiki
    end

    local function AP_GetRoleIdFor(roleName)
        local w = AP_GetWiki()
        if w and type(w.teamroles) == "table" then
            local idx = table.find(w.teamroles, roleName)
            if idx then return idx end
        end

        pcall(function()
            local pGui = Player:FindFirstChild("PlayerGui")
            local selectGui = pGui and pGui:FindFirstChild("Select")
            local frame = selectGui and selectGui:FindFirstChild("Frame")
            if not frame then return end
            local teamContainer = frame:FindFirstChild("A") or frame:FindFirstChild("B")
            local child = teamContainer and teamContainer:FindFirstChild(roleName)
            if child then
                if child:GetAttribute("roleId") then
                    return tonumber(child:GetAttribute("roleId"))
                elseif child:GetAttribute("id") then
                    return tonumber(child:GetAttribute("id"))
                elseif child.LayoutOrder and child.LayoutOrder > 0 then
                    return child.LayoutOrder
                end
            end
        end)

        return AutoPosition.RoleMapping[roleName] or 1
    end

    local function AP_GetMyTeam()
        if Player.Team and Player.Team.Name ~= "" and Player.Team.Name ~= "lobby" and Player.Team.Name ~= "Spectators" then
            return Player.Team.Name
        end
        local attr = Player:GetAttribute("team")
        if attr and attr ~= "" and attr ~= "lobby" then
            return tostring(attr)
        end
        local chars = Workspace:FindFirstChild("characters")
        local myChar = (chars and chars:FindFirstChild(Player.Name)) or Player.Character
        local state = myChar and myChar:FindFirstChild("state")
        local team = state and state:FindFirstChild("team")
        local val = team and tostring(team.Value)
        if val and val ~= "" and val ~= "lobby" then
            return val
        end
        return nil
    end

    local function AP_GetMyRole()
        local chars = Workspace:FindFirstChild("characters")
        local myChar = (chars and chars:FindFirstChild(Player.Name)) or Player.Character
        local state = myChar and myChar:FindFirstChild("state")
        local role = state and state:FindFirstChild("role")
        local val = role and tostring(role.Value)
        if val and val ~= "" then
            return val
        end
        return ""
    end

    local function AP_IsRoleTaken(targetRole, targetTeam)
        local myChar = Player.Character
        local soccerState = ReplicatedStorage:FindFirstChild("workspace")
        local ownerRole = soccerState and soccerState:FindFirstChild("ownerRole")
        if ownerRole then
            local teamFolder = ownerRole:FindFirstChild(targetTeam)
            if teamFolder then
                local roleVal = teamFolder:FindFirstChild(targetRole)
                if roleVal and roleVal:IsA("ValueObject") then
                    local v = roleVal.Value
                    if v ~= nil then
                        if myChar and v == myChar then
                            return false
                        end
                        return true
                    else
                        return false
                    end
                end
            end
        end

        local chars = Workspace:FindFirstChild("characters")
        if chars then
            for _, charFolder in pairs(chars:GetChildren()) do
                if charFolder.Name ~= Player.Name then
                    local state = charFolder:FindFirstChild("state")
                    if state then
                        local t = state:FindFirstChild("team")
                        local r = state:FindFirstChild("role")
                        local teamVal = t and tostring(t.Value) or ""
                        local roleVal = r and tostring(r.Value) or ""
                        if roleVal == targetRole and (not targetTeam or targetTeam == "Both" or teamVal == targetTeam) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    local function AP_ClickGUIButton(targetRole, teamLetter)
        local clicked = false
        pcall(function()
            local pGui = Player:FindFirstChild("PlayerGui")
            local selectGui = pGui and pGui:FindFirstChild("Select")
            local frame = selectGui and selectGui:FindFirstChild("Frame")
            if not frame then return end
            local teamContainer = frame:FindFirstChild(teamLetter) or frame:FindFirstChild("Team" .. teamLetter)
            if not teamContainer then return end
            local roleFrame = teamContainer:FindFirstChild(targetRole)
            if not roleFrame then return end

            local btn = roleFrame:FindFirstChild("Button")
                or roleFrame:FindFirstChildWhichIsA("GuiButton")
                or (roleFrame:IsA("GuiButton") and roleFrame)

            if btn and firesignal then
                pcall(function() firesignal(btn.MouseButton1Up) end)
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
                clicked = true
            end
        end)
        return clicked
    end

    local function AP_FireRolePacket(targetRole, teamLetter)
        local roleId = math.clamp(math.floor(tonumber(AP_GetRoleIdFor(targetRole)) or 1), 1, 5)
        local teamStr = (teamLetter == "B") and "B" or "A"

        local clicked = AP_ClickGUIButton(targetRole, teamStr)
        if clicked then
            return
        end

        local pk = AP_GetPackets()
        if pk and pk.bytenet_selectRole and pk.bytenet_selectRole.send then
            local ok = pcall(function()
                pk.bytenet_selectRole.send({
                    index = roleId,
                    t = teamStr
                })
            end)
            if not ok then
                pcall(function()
                    pk.bytenet_selectRole:send({
                        index = roleId,
                        t = teamStr
                    })
                end)
            end
        end
    end

    local lastSelectAttempt = 0
    local function AP_AttemptSelect()
        if not AutoPosition.Enabled then return end
        local now = os.clock()
        if now - lastSelectAttempt < 0.4 then return end

        local targetRole = AutoPosition.Role or "CF"
        local targetTeam = AutoPosition.Team or "A"

        local myRole = AP_GetMyRole()
        local myTeam = AP_GetMyTeam()

        if myRole == targetRole then
            if targetTeam == "Both" and (myTeam == "A" or myTeam == "B") then
                return
            elseif myTeam == targetTeam then
                return
            end
        end

        lastSelectAttempt = now

        if targetTeam == "Both" then
            local takenA = AP_IsRoleTaken(targetRole, "A")
            local takenB = AP_IsRoleTaken(targetRole, "B")
            if not takenA then
                AP_FireRolePacket(targetRole, "A")
            elseif not takenB then
                AP_FireRolePacket(targetRole, "B")
            end
        else
            local taken = AP_IsRoleTaken(targetRole, targetTeam)
            if not taken then
                AP_FireRolePacket(targetRole, targetTeam)
            end
        end
    end

    local function AP_HookOwnerRole()
        if AutoPosition.RoleConnA then
            AutoPosition.RoleConnA:Disconnect()
            AutoPosition.RoleConnA = nil
        end
        if AutoPosition.RoleConnB then
            AutoPosition.RoleConnB:Disconnect()
            AutoPosition.RoleConnB = nil
        end
        pcall(function()
            local soccerState = ReplicatedStorage:FindFirstChild("workspace")
            local ownerRole = soccerState and soccerState:FindFirstChild("ownerRole")
            if ownerRole then
                local currentRole = AutoPosition.Role or "CF"
                local roleA = ownerRole:FindFirstChild("A") and ownerRole.A:FindFirstChild(currentRole)
                local roleB = ownerRole:FindFirstChild("B") and ownerRole.B:FindFirstChild(currentRole)
                if roleA and roleA:IsA("ValueObject") then
                    AutoPosition.RoleConnA = roleA.Changed:Connect(function()
                        if AutoPosition.Enabled then
                            task.wait(0.05)
                            AP_AttemptSelect()
                        end
                    end)
                end
                if roleB and roleB:IsA("ValueObject") then
                    AutoPosition.RoleConnB = roleB.Changed:Connect(function()
                        if AutoPosition.Enabled then
                            task.wait(0.05)
                            AP_AttemptSelect()
                        end
                    end)
                end
            end
        end)
    end

    function AutoPosition.Start()
        if AutoPosition.Enabled then return end
        AutoPosition.Enabled = true

        if AutoPosition.Connection then AutoPosition.Connection:Disconnect() end
        AutoPosition.Connection = Player.CharacterAdded:Connect(function()
            task.wait(0.3)
            if AutoPosition.Enabled then
                AP_AttemptSelect()
            end
        end)

        if AutoPosition.GuiConnection then AutoPosition.GuiConnection:Disconnect() end
        local pGui = Player:FindFirstChild("PlayerGui")
        if pGui then
            AutoPosition.GuiConnection = pGui.ChildAdded:Connect(function(child)
                if child.Name == "Select" and AutoPosition.Enabled then
                    task.wait(0.05)
                    AP_AttemptSelect()
                end
            end)
        end

        AP_HookOwnerRole()

        if AutoPosition.LoopThread then task.cancel(AutoPosition.LoopThread) end
        AutoPosition.LoopThread = task.spawn(function()
            while AutoPosition.Enabled do
                AP_AttemptSelect()
                task.wait(0.4)
            end
        end)

        AP_AttemptSelect()
        SafeNotify("Auto Choose (" .. tostring(AutoPosition.Role) .. " - " .. tostring(AutoPosition.Team) .. ") Enabled",
            2, "Enable")
    end

    function AutoPosition.Stop()
        AutoPosition.Enabled = false
        if AutoPosition.Connection then
            AutoPosition.Connection:Disconnect()
            AutoPosition.Connection = nil
        end
        if AutoPosition.GuiConnection then
            AutoPosition.GuiConnection:Disconnect()
            AutoPosition.GuiConnection = nil
        end
        if AutoPosition.RoleConnA then
            AutoPosition.RoleConnA:Disconnect()
            AutoPosition.RoleConnA = nil
        end
        if AutoPosition.RoleConnB then
            AutoPosition.RoleConnB:Disconnect()
            AutoPosition.RoleConnB = nil
        end
        if AutoPosition.LoopThread then
            task.cancel(AutoPosition.LoopThread)
            AutoPosition.LoopThread = nil
        end
        SafeNotify("Auto Choose Disabled", 2, "Disable")
    end

    AutoPosition.Toggle = Library:CreateToggle(AutoPositionSection, {
        Name = "Auto Choose",
        Default = false,
        Callback = function(v)
            if v then
                AutoPosition.Start()
            else
                AutoPosition.Stop()
            end
        end
    })

    AutoPosition.RoleDropdown = Library:CreateDropdown(AutoPositionSection, {
        Name = "Role",
        Options = { "CF", "CM", "LW", "RW", "GK" },
        Default = "CF",
        CurrentOption = "CF",
        MultipleOptions = false,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            AutoPosition.Role = v
            if AutoPosition.Enabled then
                AP_HookOwnerRole()
                AP_AttemptSelect()
            end
        end
    })

    AutoPosition.TeamDropdown = Library:CreateDropdown(AutoPositionSection, {
        Name = "Team",
        Options = { "A", "B", "Both" },
        Default = "A",
        CurrentOption = "A",
        MultipleOptions = false,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            AutoPosition.Team = v
            if AutoPosition.Enabled then
                AP_AttemptSelect()
            end
        end
    })
end

local AntiCounter = {
    Enabled = false,
    Connection = nil,
    FlickCooldown = 0.5,
    LastFlickTime = 0,
    TackleBlocked = false,
    BlockUntil = 0,
    BlockDuration = 0.55,
    LastSoundBlock = {},
    NamecallHook = nil,

    OurTackleAnims = {
        ["109744655458082"] = true,
        ["111439544531399"] = true,
        ["113088324958896"] = true,
        ["82417661349987"] = true,
        ["107502555664359"] = true,
        ["131986477806061"] = true,
        ["80730958176662"] = true,
        ["89782964116671"] = true,
    },

    EnemyCounterSounds = {
        ["75192333930117"] = 0.55,
        ["76120610878881"] = 1,
        ["76927273170207"] = 0.8,
        ["78747803174257"] = 1,
        ["88793265981049"] = 1,
        ["94658988441760"] = 0.9,
        ["100429516080298"] = 0.65,
        ["102793689582816"] = 0.8,
        ["124634000710435"] = 0.4,
        ["127698474876007"] = 0.62,
        ["138903348406356"] = 0.7,
        ["90434532771613"] = 1,
        ["90638566809999"] = 1,
    },

    SoundHooks = {},
    HookedHRPs = {},
}

function AntiCounter.IsMyTackleAnimPlaying()
    local char = Player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        if track.IsPlaying and track.Animation then
            local id = tostring(track.Animation.AnimationId):match("%d+")
            if id and AntiCounter.OurTackleAnims[id] then return true end
        end
    end
    return false
end

function AntiCounter.IsLookingAtTarget(targetHRP)
    local char = Player.Character
    if not char then return false end
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP or not targetHRP then return false end
    local toTarget = (targetHRP.Position - myHRP.Position)
    if toTarget.Magnitude < 1 then return true end
    toTarget = toTarget.Unit
    local dot = myHRP.CFrame.LookVector:Dot(toTarget)
    return dot > 0.5
end

function AntiCounter.FlickCamera()
    local now = tick()
    if now - AntiCounter.LastFlickTime < AntiCounter.FlickCooldown then return end
    AntiCounter.LastFlickTime = now

    local cam = Workspace.CurrentCamera
    if not cam then return end

    local cf = cam.CFrame
    cam.CFrame = cf * CFrame.Angles(0, math.rad(90), 0)
end

function AntiCounter.SetupTackleBlock()
    if AntiCounter.NamecallHook then return end
    if not ExecutorCaps.Hook then return end

    local function shouldBlockAction(v, depth)
        depth = depth or 0
        if depth > 4 then return false end
        if type(v) == "string" then
            return v == "tackle"
        end
        if type(v) ~= "table" then return false end
        for _, x in pairs(v) do
            if shouldBlockAction(x, depth + 1) then return true end
        end
        return false
    end

    local oldNamecall
    local function onNamecall(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and AntiCounter.TackleBlocked then
            if tick() >= AntiCounter.BlockUntil then
                AntiCounter.TackleBlocked = false
            elseif typeof(self) == "Instance" and self.ClassName == "RemoteEvent" then
                for i = 2, select("#", ...) do
                    if shouldBlockAction(select(i, ...)) then return nil end
                end
            end
        end
        return oldNamecall(self, ...)
    end
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure and newcclosure(onNamecall) or onNamecall)
    AntiCounter.NamecallHook = oldNamecall
end

function AntiCounter.OnEnemyCounterSound(sound)
    if not AntiCounter.Enabled then return end

    local id = tostring(sound.SoundId or "")
    local numId = id:match("rbxassetid://(%d+)") or id:match("://(%d+)") or id:match("^(%d+)$")
    if not numId or not AntiCounter.EnemyCounterSounds[numId] then return end

    local theirHRP = sound.Parent
    if not theirHRP or theirHRP.Name ~= "HumanoidRootPart" then return end
    local char = theirHRP.Parent
    if not char or not char.Parent or char.Parent.Name ~= "characters" then return end
    if char.Name == Player.Name then return end

    local mine = GetTeam(Player.Name)
    local theirs = GetTeam(char.Name)
    if not mine or mine == "lobby" or not theirs or theirs == "lobby" or theirs == mine then return end

    local enemyBall = HasBall(char.Name)
    if not enemyBall then return end

    local looking = AntiCounter.IsLookingAtTarget(theirHRP)
    if not looking then return end

    local tackleAnim = AntiCounter.IsMyTackleAnimPlaying()
    if tackleAnim then
        AntiCounter.FlickCamera()
    end

    local now = tick()
    if AntiCounter.LastSoundBlock[sound] and now - AntiCounter.LastSoundBlock[sound] < 0.25 then return end
    AntiCounter.LastSoundBlock[sound] = now

    local bDuration = type(AntiCounter.EnemyCounterSounds[numId]) == "number" and AntiCounter.EnemyCounterSounds[numId] or
        AntiCounter.BlockDuration
    AntiCounter.BlockUntil = math.max(AntiCounter.BlockUntil, now + bDuration)
    AntiCounter.TackleBlocked = true
    task.spawn(function()
        task.wait(bDuration + 0.05)
        if tick() >= AntiCounter.BlockUntil then AntiCounter.TackleBlocked = false end
    end)
end

function AntiCounter.HookSound(sound)
    if not sound or not sound:IsA("Sound") or AntiCounter.SoundHooks[sound] then return end
    local played = sound.Played:Connect(function() AntiCounter.OnEnemyCounterSound(sound) end)
    local prop = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then AntiCounter.OnEnemyCounterSound(sound) end
    end)
    local destroy
    destroy = sound.Destroying:Connect(function()
        pcall(function() played:Disconnect() end)
        pcall(function() prop:Disconnect() end)
        pcall(function() destroy:Disconnect() end)
        AntiCounter.SoundHooks[sound] = nil
    end)
    AntiCounter.SoundHooks[sound] = { played = played, prop = prop, destroy = destroy }
    if sound.IsPlaying then AntiCounter.OnEnemyCounterSound(sound) end
end

function AntiCounter.HookHRP(hrp)
    if not hrp or AntiCounter.HookedHRPs[hrp] then return end
    AntiCounter.HookedHRPs[hrp] = true
    for _, s in ipairs(hrp:GetChildren()) do
        if s:IsA("Sound") then AntiCounter.HookSound(s) end
    end
    hrp.ChildAdded:Connect(function(child)
        if AntiCounter.Enabled and child:IsA("Sound") then AntiCounter.HookSound(child) end
    end)
end

function AntiCounter.HookCharacter(char)
    if not char or char.Name == Player.Name then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then AntiCounter.HookHRP(hrp) end
    char.ChildAdded:Connect(function(child)
        if AntiCounter.Enabled and child.Name == "HumanoidRootPart" then
            AntiCounter.HookHRP(child)
        end
    end)
end

function AntiCounter.InitHooks()
    local chars = Workspace:FindFirstChild("characters")
    if not chars then return end
    for _, c in ipairs(chars:GetChildren()) do
        AntiCounter.HookCharacter(c)
    end
    chars.ChildAdded:Connect(function(c)
        if AntiCounter.Enabled then AntiCounter.HookCharacter(c) end
    end)
end

function AntiCounter.Start()
    AntiCounter.Enabled = true
    AntiCounter.SetupTackleBlock()
    AntiCounter.InitHooks()
    SafeNotify("Anti Counter Enabled", 2, "Enable")
end

function AntiCounter.Stop()
    AntiCounter.Enabled = false
    AntiCounter.TackleBlocked = false
    AntiCounter.BlockUntil = 0
    AntiCounter.LastSoundBlock = {}
    for _, hooks in pairs(AntiCounter.SoundHooks) do
        for _, c in pairs(hooks) do pcall(function() c:Disconnect() end) end
    end
    AntiCounter.SoundHooks = {}
    AntiCounter.HookedHRPs = {}
    SafeNotify("Anti Counter Disabled", 2, "Disable")
end

Library:CreateToggle(AntiCounterSection, {
    Name = "Anti Counter",
    Default = false,
    Callback = function(v) if v then AntiCounter.Start() else AntiCounter.Stop() end end
})

local AntiPriceCheck = {
    Enabled = false,
    Connection = nil,
    IsCompensating = false,
    WalkSpeedMap = {
        [31.2] = 40,
        [19.5] = 25,
        [23.4] = 30,
        [3.9] = 5,
        [7.8] = 10,
        [8.58] = 11,
    },
}

function AntiPriceCheck.HasFX()
    local chars = Workspace:FindFirstChild("characters")
    local myChar = chars and chars:FindFirstChild(Player.Name)
    local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    return hrp and hrp:FindFirstChild("FX") ~= nil
end

function AntiPriceCheck.CompensateWalkSpeed()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    local speed = hum.WalkSpeed
    for debuffed, normal in pairs(AntiPriceCheck.WalkSpeedMap) do
        if math.abs(speed - debuffed) < 0.5 then
            hum.WalkSpeed = normal
            break
        end
    end
end

function AntiPriceCheck.Process()
    if not AntiPriceCheck.Enabled then return end
    if AntiPriceCheck.HasFX() then
        AntiPriceCheck.IsCompensating = true
        AntiPriceCheck.CompensateWalkSpeed()
    else
        AntiPriceCheck.IsCompensating = false
    end
end

function AntiPriceCheck.Start()
    AntiPriceCheck.Enabled = true
    AntiPriceCheck.IsCompensating = false
    AntiPriceCheck.Connection = RunService.Heartbeat:Connect(AntiPriceCheck.Process)
    SafeNotify("Anti Price Check Enabled", 2, "Enable")
end

function AntiPriceCheck.Stop()
    AntiPriceCheck.Enabled = false
    if AntiPriceCheck.Connection then
        AntiPriceCheck.Connection:Disconnect()
        AntiPriceCheck.Connection = nil
    end
    AntiPriceCheck.IsCompensating = false
    SafeNotify("Anti Price Check Disabled", 2, "Disable")
end

Library:CreateToggle(AntiPriceSection, {
    Name = "Anti Price Check",
    Default = false,
    Callback = function(v) if v then AntiPriceCheck.Start() else AntiPriceCheck.Stop() end end
})

local FastPickupSection = Library:CreateSection(MainCat, "Fast Auto-Pickup", "right")

do
    local FastPickup = {
        Enabled = false,
        RequireHoldKey = false,
        HoldKeyDown = false,
        PickupRange = 12,
        Ball = nil,
        CachedChars = nil,
        Connection = nil,
        ShowRange = false,
        RangeFolder = nil,
        RangeBase = nil,
        RangeConnection = nil,
        LastProcessTime = 0,
    }

    local function FP_FindBall()
        local terrain = Workspace:FindFirstChild("Terrain")
        local ball = (terrain and (terrain:FindFirstChild("Ball") or terrain:FindFirstChild("MarbleStuckBall")))
            or Workspace:FindFirstChild("Ball")
        if ball and ball:IsA("BasePart") then
            FastPickup.Ball = ball
            return ball
        end
        local cfBall = ReplicatedStorage:FindFirstChild("CFBall")
        if cfBall and cfBall:IsA("CFrameValue") then
            return cfBall
        end
        return nil
    end

    local function FP_GetBallPosition()
        local cfBall = ReplicatedStorage:FindFirstChild("CFBall")
        if cfBall and cfBall:IsA("CFrameValue") then
            return cfBall.Value.Position
        end
        local ball = FP_FindBall()
        if ball then
            if ball:IsA("BasePart") then
                return ball.Position
            elseif ball:IsA("CFrameValue") then
                return ball.Value.Position
            end
        end
        return nil
    end

    local function FP_GetChars()
        if not FastPickup.CachedChars or not FastPickup.CachedChars.Parent then
            FastPickup.CachedChars = Workspace:FindFirstChild("characters")
        end
        return FastPickup.CachedChars
    end

    local function FP_StopRange()
        if FastPickup.RangeConnection then
            FastPickup.RangeConnection:Disconnect()
            FastPickup.RangeConnection = nil
        end
        if FastPickup.RangeFolder then
            FastPickup.RangeFolder:Destroy()
            FastPickup.RangeFolder = nil
        end
        FastPickup.RangeBase = nil
    end

    local function FP_StartRange()
        if FastPickup.RangeFolder then return end
        local folder = Instance.new("Folder")
        folder.Name, folder.Parent = "FastPickup_Range", Workspace

        local base = Instance.new("Part")
        base.Anchored, base.CanCollide, base.CanQuery, base.Transparency = true, false, false, 1
        base.Size = Vector3.new(FastPickup.PickupRange * 2, 0.05, FastPickup.PickupRange * 2)
        base.Parent = folder

        local gui = Instance.new("SurfaceGui")
        gui.Face, gui.LightInfluence, gui.AlwaysOnTop = Enum.NormalId.Top, 0, true
        gui.PixelsPerStud, gui.SizingMode, gui.CanvasSize = 100, Enum.SurfaceGuiSizingMode.FixedSize,
            Vector2.new(200, 200)
        gui.Parent = base

        local circle = Instance.new("Frame")
        circle.AnchorPoint, circle.Position, circle.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5),
            UDim2.fromScale(0.92, 0.92)
        circle.BackgroundColor3, circle.BackgroundTransparency, circle.BorderSizePixel = Color3.fromRGB(70, 190, 255),
            0.82,
            0
        circle.Parent = gui
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

        local stroke = Instance.new("UIStroke")
        stroke.Color, stroke.Thickness, stroke.Transparency = Color3.fromRGB(150, 235, 255), 3, 0
        stroke.Parent = circle

        FastPickup.RangeFolder, FastPickup.RangeBase = folder, base
        FastPickup.RangeConnection = RunService.RenderStepped:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or not FastPickup.ShowRange then return end
            if base.Parent ~= folder then base.Parent = folder end
            local size = FastPickup.PickupRange * 2
            base.Size = Vector3.new(size, 0.05, size)
            base.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3.2, 0))
        end)
    end

    local function FP_IsPlayingRestrictedAnimation(humanoid)
        if not humanoid then return false end
        local animator = humanoid:FindFirstChild("Animator")
        if not animator then return false end

        local restrictedIds = {
            ["81249694116204"] = true,
            ["115839777221212"] = true,
            ["127428631641330"] = true,
            ["97586424269981"] = true,
            ["133565559497234"] = true,
            ["79074253499106"] = true
        }

        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if track.Animation and track.Animation.AnimationId then
                local id = track.Animation.AnimationId:match("%d+")
                if id and restrictedIds[id] then
                    return true
                end
            end
        end
        return false
    end

    function FastPickup.Process()
        if not FastPickup.Enabled then return end
        if FastPickup.RequireHoldKey and not FastPickup.HoldKeyDown then return end

        local now = os.clock()
        if now - FastPickup.LastProcessTime < 0.08 then return end

        local character = Player.Character
        if not character then return end
        if character:GetAttribute("cantgetball") or character:GetAttribute("InMarble") then return end
        if HasBall() then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end
        if FP_IsPlayingRestrictedAnimation(humanoid) then return end

        local ballPos = FP_GetBallPosition()
        if not ballPos then return end

        if (hrp.Position - ballPos).Magnitude > FastPickup.PickupRange then return end

        FastPickup.LastProcessTime = now

        local pk = NET and NET.GetPackets and NET.GetPackets()
        if pk and pk.bytenet_findBall and pk.bytenet_findBall.send then
            pcall(function() pk.bytenet_findBall.send() end)
        else
            pcall(function() NET:FireServer(buffer.fromstring(buffers["grabball"])) end)
        end
    end

    function FastPickup.Start()
        FastPickup.CachedChars = Workspace:FindFirstChild("characters")
        FastPickup.Enabled = true
        FP_FindBall()
        FastPickup.Connection = RunService.Heartbeat:Connect(FastPickup.Process)
        SafeNotify("Fast Auto-Pickup Enabled", 2, "Enable")
    end

    function FastPickup.Stop()
        FastPickup.Enabled = false
        if FastPickup.Connection then
            FastPickup.Connection:Disconnect()
            FastPickup.Connection = nil
        end
        FastPickup.Ball = nil
        FastPickup.CachedChars = nil
        FP_StopRange()
        SafeNotify("Fast Auto-Pickup Disabled", 2, "Disable")
    end

    Library:CreateToggle(FastPickupSection, {
        Name = "Fast Auto-Pickup",
        Default = false,
        Callback = function(v) if v then FastPickup.Start() else FastPickup.Stop() end end
    })

    Library:CreateToggle(FastPickupSection, {
        Name = "Hold Key",
        Default = false,
        Callback = function(v)
            FastPickup.RequireHoldKey = v
            if not v then FastPickup.HoldKeyDown = false end
        end
    })

    Library:CreateKeybind(FastPickupSection, {
        Name = "Keybind",
        Default = Enum.UserInputType.MouseButton2,
        Mode = "Hold",
        Callback = function(v)
            FastPickup.HoldKeyDown = v
        end
    })

    Library:CreateToggle(FastPickupSection, {
        Name = "Show Range",
        Default = false,
        Callback = function(v)
            FastPickup.ShowRange = v
            if v then FP_StartRange() else FP_StopRange() end
        end
    })

    Library:CreateSlider(FastPickupSection, {
        Name = "Pickup Range",
        Min = 5,
        Max = 14,
        Default = 12,
        Step = 0.5,
        Suffix = " studs",
        Callback = function(v) FastPickup.PickupRange = v end
    })
end

local AutoQTESection = Library:CreateSection(MainCat, "Auto QTE", "right")
local HideBlackSection = Library:CreateSection(MainCat, "Hide Black GUI", "left")
local LegitNoStunSection = Library:CreateSection(MainCat, "Legit No Stun", "right")

do
    local AutoQTE = { Enabled = false, Connection = nil, Processing = false }
    local VIM = game:GetService("VirtualInputManager")

    local function AQ_FindQteGui()
        local gui = Player:FindFirstChild("PlayerGui")
        return gui and gui:FindFirstChild("Qte")
    end

    local function AQ_ConvertNumber(text)
        local map = {
            ["1"] = "One",
            ["2"] = "Two",
            ["3"] = "Three",
            ["4"] = "Four",
            ["5"] = "Five",
            ["6"] = "Six",
            ["7"] = "Seven",
            ["8"] = "Eight",
            ["9"] = "Nine",
            ["0"] = "Zero"
        }
        return map[text] or text
    end

    local function AQ_IsGreenColor(color)
        local r, g, b = color.R * 255, color.G * 255, color.B * 255
        return g > 100 and g > r * 1.5 and g > b * 1.5 and r < 100 and b < 100
    end

    local function AQ_ClickTargetButton(btn)
        if not btn then return end
        if firesignal then
            pcall(firesignal, btn.Activated)
            pcall(firesignal, btn.MouseButton1Click)
            return
        end

        if getconnections then
            for _, signal in ipairs({ btn.Activated, btn.MouseButton1Click }) do
                for _, conn in ipairs(getconnections(signal)) do
                    conn:Fire()
                end
            end
        end
    end

    function AutoQTE.CheckQTE()
        if not AutoQTE.Enabled or AutoQTE.Processing then return end
        local qteGui = AQ_FindQteGui()
        if not qteGui then return end
        local qteFrame = qteGui:FindFirstChild("QTE") or qteGui:FindFirstChild("CanvasGroup")
        if not qteFrame then return end
        for _, desc in ipairs(qteFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                if AQ_IsGreenColor(desc.BackgroundColor3) then
                    AutoQTE.Processing = true

                    if IS_MOBILE then
                        local targetButton = qteFrame:FindFirstChild("Button")
                        if not targetButton then
                            for _, v in ipairs(qteGui:GetDescendants()) do
                                if v:IsA("TextButton") and v.Name == "Button" then
                                    targetButton = v
                                    break
                                end
                            end
                        end

                        if targetButton then
                            AQ_ClickTargetButton(targetButton)
                        end
                    else
                        local keyText = desc:IsA("TextLabel") and AQ_ConvertNumber(desc.Text) or nil
                        local keyCode = keyText and Enum.KeyCode[keyText]
                        if keyCode then
                            pcall(function()
                                VIM:SendKeyEvent(true, keyCode, false, game)
                                task.wait(0.05)
                                VIM:SendKeyEvent(false, keyCode, false, game)
                            end)
                        end
                    end

                    task.wait(0.5)
                    AutoQTE.Processing = false
                    break
                end
            end
        end
    end

    function AutoQTE.Start()
        if AutoQTE.Connection then AutoQTE.Connection:Disconnect() end
        AutoQTE.Enabled = true
        AutoQTE.Connection = RunService.RenderStepped:Connect(AutoQTE.CheckQTE)
        SafeNotify("Auto QTE Enabled", 2, "Enable")
    end

    function AutoQTE.Stop()
        AutoQTE.Enabled = false
        if AutoQTE.Connection then
            AutoQTE.Connection:Disconnect()
            AutoQTE.Connection = nil
        end
        SafeNotify("Auto QTE Disabled", 2, "Disable")
    end

    Library:CreateToggle(AutoQTESection, {
        Name = "Auto QTE",
        Default = false,
        Callback = function(v) if v then AutoQTE.Start() else AutoQTE.Stop() end end
    })
end

local LegitNoStun = { Enabled = false, Token = 0, CharacterConnection = nil, Flags = { "ragdoll", "stun", "knockback", "actived" } }

function LegitNoStun.Run(character, token)
    while LegitNoStun.Enabled and LegitNoStun.Token == token and character and character.Parent do
        local state = character:FindFirstChild("state") or character:WaitForChild("state", 1)
        if state then
            for _, flag in ipairs(LegitNoStun.Flags) do
                local val = state:FindFirstChild(flag)
                if val and val.Value == true then val.Value = false end
            end
        end
        task.wait()
    end
end

function LegitNoStun.Start()
    if LegitNoStun.Enabled then return end
    LegitNoStun.Enabled = true
    LegitNoStun.Token = LegitNoStun.Token + 1
    if Player.Character then task.spawn(LegitNoStun.Run, Player.Character, LegitNoStun.Token) end
    if LegitNoStun.CharacterConnection then LegitNoStun.CharacterConnection:Disconnect() end
    LegitNoStun.CharacterConnection = Player.CharacterAdded:Connect(function(character)
        task.spawn(LegitNoStun.Run, character, LegitNoStun.Token)
    end)
    SafeNotify("Legit No Stun Enabled", 2, "Enable")
end

function LegitNoStun.Stop()
    LegitNoStun.Enabled = false
    LegitNoStun.Token = LegitNoStun.Token + 1
    if LegitNoStun.CharacterConnection then
        LegitNoStun.CharacterConnection:Disconnect()
        LegitNoStun.CharacterConnection = nil
    end
    SafeNotify("Legit No Stun Disabled", 2, "Disable")
end

Library:CreateToggle(LegitNoStunSection, {
    Name = "Legit No Stun",
    Default = false,
    Callback = function(v) if v then LegitNoStun.Start() else LegitNoStun.Stop() end end
})

local HideBlackGUI = { Enabled = false, Connections = {} }

function HideBlackGUI.DestroyBlack()
    local gui = Player:FindFirstChild("PlayerGui")
    if not gui then return end
    local black = gui:FindFirstChild("Black")
    if black and black:IsA("ScreenGui") then
        black:Destroy()
    end
end

function HideBlackGUI.Start()
    if HideBlackGUI.Enabled then return end
    HideBlackGUI.Enabled = true
    HideBlackGUI.DestroyBlack()
    local gui = Player:FindFirstChild("PlayerGui")
    if gui then
        local conn = gui.ChildAdded:Connect(function(child)
            if child.Name == "Black" and child:IsA("ScreenGui") then
                child:Destroy()
            end
        end)
        table.insert(HideBlackGUI.Connections, conn)
    end
    local hb = RunService.Heartbeat:Connect(function()
        if not HideBlackGUI.Enabled then return end
        HideBlackGUI.DestroyBlack()
    end)
    table.insert(HideBlackGUI.Connections, hb)
    SafeNotify("Hide Black GUI Enabled", 2, "Enable")
end

function HideBlackGUI.Stop()
    if not HideBlackGUI.Enabled then return end
    HideBlackGUI.Enabled = false
    for _, c in ipairs(HideBlackGUI.Connections) do pcall(function() c:Disconnect() end) end
    HideBlackGUI.Connections = {}
    SafeNotify("Hide Black GUI Disabled", 2, "Disable")
end

Library:CreateToggle(HideBlackSection, {
    Name = "Hide Black GUI",
    Default = false,
    Callback = function(v) if v then HideBlackGUI.Start() else HideBlackGUI.Stop() end end
})

if IS_MOBILE then
    local section = Library:CreateSection(MainCat, "Mobile Keyboard", "right")
    Library:CreateButton(section, {
        Name = "Mobile Keyboard",
        Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/PSKAdxnH"))() end
    })
end

local AirDribbleSection = Library:CreateSection(MainCat, "Air Dribble", "left")

do
    local function AD_IsCutsceneActive()
        local cam = Workspace.CurrentCamera
        if not cam then return false end
        local ct = cam.CameraType
        return ct == Enum.CameraType.Scriptable or ct == Enum.CameraType.Fixed
    end

    local AirDribble = {
        Enabled = false,
        Connection = nil,
        CurrentTrack = nil,
        LastExecution = 0,
        ExecutionDelay = 0.15,
        Delay = 0.2,
        KickCount = 0,
        JumpCount = 0,
        IsExecuting = false,
        IsActive = false,
        InputConnection = nil,
        InputEndConnection = nil,
        CurrentKey = Enum.KeyCode.LeftAlt,
        IsPlayingAnimation = false,
        AnimationDuration = 0.5,
        AutoJumpEnabled = false,
        JumpAfterKick = true,
        IsKeyHeld = false,
        Height = 50,
        Forward = 1,
        Power = 29,
        VectorScale = 50,
    }

    local function AD_HasBall()
        local chars = Workspace:FindFirstChild("characters")
        local c = chars and chars:FindFirstChild(Player.Name)
        return c and c:FindFirstChild("Ball")
    end

    function AirDribble.PerformAutoJump()
        if not AirDribble.AutoJumpEnabled then return end
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        local waitStart = tick()
        while tick() - waitStart < 1 do
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics then
                if AirDribble.JumpCount >= 1 then
                    task.wait(0.08)
                else
                    task.wait(0.03)
                end
                if not hum or not hum.Parent then return end
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                hum.Jump = true
                AirDribble.JumpCount = AirDribble.JumpCount + 1
                return
            end
            task.wait()
        end
    end

    function AirDribble.PlayAnim()
        if AirDribble.CurrentTrack then AirDribble.CurrentTrack:Stop() end
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://76587445975710"
        AirDribble.CurrentTrack = hum:LoadAnimation(anim)
        AirDribble.CurrentTrack:Play()
        AirDribble.IsPlayingAnimation = true
        AirDribble.JumpAfterKick = true
        task.delay(AirDribble.AnimationDuration, function()
            if AirDribble.Enabled then AirDribble.IsPlayingAnimation = false end
        end)
    end

    function AirDribble.StopAnim()
        if AirDribble.CurrentTrack then
            AirDribble.CurrentTrack:Stop()
            AirDribble.CurrentTrack = nil
        end
        AirDribble.IsPlayingAnimation = false
        AirDribble.JumpAfterKick = false
    end

    function AirDribble.GetKickVector(hrp)
        local look = hrp.CFrame.LookVector
        local dir = Vector3.new(look.X * AirDribble.Forward, AirDribble.Height, look.Z * AirDribble.Forward)
        if dir.Magnitude <= 0 then return Vector3.new(0, AirDribble.VectorScale, 0) end
        return dir.Unit * AirDribble.VectorScale
    end

    function AirDribble.ExecuteDribble()
        if not AirDribble.Enabled then return end
        if AirDribble.IsExecuting then return end
        if HasMyIFrame() then return end
        local now = tick()
        if now - AirDribble.LastExecution > 1.5 then
            AirDribble.KickCount = 0
            AirDribble.JumpCount = 0
        elseif now - AirDribble.LastExecution < AirDribble.ExecutionDelay then
            return
        end
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not AD_HasBall() then
            AirDribble.StopAnim()
            AirDribble.KickCount = 0
            AirDribble.JumpCount = 0
            return
        end

        AirDribble.IsExecuting = true
        AirDribble.PlayAnim()

        if AirDribble.KickCount == 0 and AirDribble.Delay and AirDribble.Delay > 0 then
            task.wait(AirDribble.Delay)
        end

        if not AirDribble.Enabled or not AD_HasBall() then
            AirDribble.IsExecuting = false
            return
        end

        local currentChar = Player.Character
        local currentHrp = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentHrp then
            AirDribble.IsExecuting = false
            return
        end

        local kickVec = AirDribble.GetKickVector(currentHrp)
        pcall(function()
            NET:FireServer(buffer.fromstring(buffers["base"]),
                { { "kick", AirDribble.Power, false, kickVec } })
        end)
        AirDribble.KickCount = AirDribble.KickCount + 1
        if AirDribble.AutoJumpEnabled then
            task.spawn(function()
                if AirDribble.JumpCount == 0 then
                    task.wait(0.15)
                end
                AirDribble.PerformAutoJump()
            end)
        end
        AirDribble.LastExecution = tick()
        AirDribble.IsExecuting = false
    end

    function AirDribble.CheckKeyHold()
        while AirDribble.Enabled and AirDribble.IsKeyHeld do
            if AD_IsCutsceneActive() then
                task.wait(0.1)
            elseif AD_HasBall() then
                AirDribble.ExecuteDribble()
            end
            task.wait()
        end
    end

    function AirDribble.Start()
        if AirDribble.Connection then AirDribble.Connection:Disconnect() end
        AirDribble.Enabled = true
        AirDribble.IsPlayingAnimation = false
        AirDribble.JumpAfterKick = true
        AirDribble.IsKeyHeld = false
        AirDribble.KickCount = 0
        AirDribble.JumpCount = 0
        SafeNotify("Air Dribble Enabled", 2, "Enable")
    end

    function AirDribble.Stop()
        AirDribble.Enabled = false
        AirDribble.IsActive = false
        AirDribble.IsExecuting = false
        AirDribble.IsPlayingAnimation = false
        AirDribble.JumpAfterKick = false
        AirDribble.IsKeyHeld = false
        AirDribble.KickCount = 0
        AirDribble.JumpCount = 0
        if AirDribble.Connection then
            AirDribble.Connection:Disconnect()
            AirDribble.Connection = nil
        end
        AirDribble.StopAnim()
        SafeNotify("Air Dribble Disabled", 2, "Disable")
    end

    Library:CreateToggle(AirDribbleSection, {
        Name = "Enable",
        Default = false,
        Callback = function(v) if v then AirDribble.Start() else AirDribble.Stop() end end
    })

    Library:CreateToggle(AirDribbleSection, {
        Name = "Auto Jump",
        Default = false,
        Callback = function(v) AirDribble.AutoJumpEnabled = v end
    })

    Library:CreateSlider(AirDribbleSection, {
        Name = "Delay",
        Min = 0,
        Max = 1.5,
        Default = 0.2,
        Step = 0.01,
        Suffix = "s",
        Callback = function(v) AirDribble.Delay = v end
    })

    Library:CreateSlider(AirDribbleSection, {
        Name = "Forward",
        Min = 0,
        Max = 20,
        Default = 1,
        Step = 0.05,
        Suffix = "",
        Callback = function(v) AirDribble.Forward = v end
    })

    Library:CreateSlider(AirDribbleSection, {
        Name = "Power",
        Min = 1,
        Max = 100,
        Default = 29,
        Step = 0.5,
        Suffix = "",
        Callback = function(v) AirDribble.Power = v end
    })

    AirDribble.Keybind = Library:CreateKeybind(AirDribbleSection, {
        Name = "Air Dribble",
        Default = Enum.KeyCode.LeftAlt,
        Mode = "Hold",
        ManualWatermark = true,
        Callback = function(active)
            if not AirDribble.Enabled then return end
            if active then
                if AirDribble.Keybind and AirDribble.Keybind.Mode == "Toggle" then
                    if not AD_IsCutsceneActive() and AD_HasBall() and not AirDribble.IsPlayingAnimation then
                        task.spawn(AirDribble.ExecuteDribble)
                    end
                    task.spawn(function()
                        task.wait(0.1)
                        if AirDribble.Keybind then
                            AirDribble.Keybind.Active = false
                        end
                    end)
                else
                    AirDribble.IsKeyHeld = true
                    AirDribble.IsActive = true
                    task.spawn(AirDribble.CheckKeyHold)
                end
            else
                AirDribble.IsKeyHeld = false
                AirDribble.IsActive = false
                AirDribble.KickCount = 0
                AirDribble.JumpCount = 0
            end
        end
    })

    if IS_MOBILE then
        function AirDribble.SetMobileButton(v)
            if v and not AirDribble.MobileButton then
                AirDribble.MobileButton = CreateMobileButton("Air Dribble", UDim2.new(0.42, 0, 0.5, 0),
                    AirDribble.ExecuteDribble, nil, "tap")
            elseif not v and AirDribble.MobileButton then
                AirDribble.MobileButton.Destroy()
                AirDribble.MobileButton = nil
            end
        end

        Library:CreateToggle(AirDribbleSection, {
            Name = "Mobile Button",
            Default = true,
            Callback = AirDribble.SetMobileButton
        })
        AirDribble.SetMobileButton(true)
    end
end

local AutoVSSection = Library:CreateSection(MainCat, "Auto Variant Steal", "right")

do
    local AutoVariantSteal = {
        Enabled = false,
        Connection = nil,
        CurrentCharacter = nil,
        MyTeam = nil,
        IsPressing = false,
        HasReached100 = false,
        WaitingForCooldown = false,
        LastPressTime = 0,
        LastFlowValue = 0,
        TargetPart = nil,
        AimConn = nil,
        StyleMapping = {
            donlorenzo = "DonLorenzo",
            sae = "Sae",
            kunigami = "Kunigami",
            barou = "Barou",
            kurona = "Kurona",
            reo = "Reo",
            masterylorenzo = "Lorenzo",
            aiku2 = "MasteryAiku",
            chigiri = "Chigiri",
        },
        CharacterConfig = {
            DonLorenzo = { radius = 49, skillName = "skill2" },
            Sae = { radius = 38, skillName = "skill2" },
            Kunigami = { radius = 29, skillName = "skill3" },
            Barou = { radius = 49, skillName = "skill5" },
            Kurona = { radius = 27, skillName = "skill1" },
            Lorenzo = { radius = 49, skillName = "skill2" },
            Reo = { radius = 15, skillName = "skill3", requiresFlow = true, requiredSkillText = "Dobermann Press" },
            MasteryAiku = { radius = 38, skillName = "skill2" },
            Chigiri = { radius = 60, skillName = "skill4", aimbot = true },
        },
    }

    function AutoVariantSteal.GetSkill3Name()
        local gui = Player:FindFirstChild("PlayerGui")
        local hb = gui and gui:FindFirstChild("Hotbar")
        local bp = hb and hb:FindFirstChild("Backpack")
        local hf = bp and bp:FindFirstChild("Hotbar")
        local s3 = hf and hf:FindFirstChild("skill3")
        local base = s3 and s3:FindFirstChild("Base")
        local tn = base and base:FindFirstChild("ToolName")
        return tn and tn.Text or nil
    end

    function AutoVariantSteal.GetPlayerTeam(name)
        local chars = Workspace:FindFirstChild("characters")
        local c = chars and chars:FindFirstChild(name)
        local st = c and c:FindFirstChild("state")
        local t = st and st:FindFirstChild("team")
        return t and t.Value or nil
    end

    function AutoVariantSteal.FindMyFlow()
        local chars = Workspace:FindFirstChild("characters")
        local my = chars and chars:FindFirstChild(Player.Name)
        local st = my and my:FindFirstChild("state")
        return st and st:FindFirstChild("flow")
    end

    function AutoVariantSteal.GetBall()
        return Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
    end

    function AutoVariantSteal.CheckBallProximity(radius)
        AutoVariantSteal.TargetPart = nil
        if HasBall(Player.Name) then return false end
        local char = Player.Character
        if char and (char:FindFirstChild("Ball") or char:GetAttribute("cantgetball") or char:GetAttribute("InMarble")) then return false end

        local myTeam = AutoVariantSteal.GetPlayerTeam(Player.Name)
        if not myTeam or myTeam == "lobby" then return false end
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        local rsWorkspace = ReplicatedStorage:FindFirstChild("workspace")
        local serverHolder = rsWorkspace and rsWorkspace:FindFirstChild("ballHolder") and rsWorkspace.ballHolder.Value

        local chars = Workspace:FindFirstChild("characters")
        if chars then
            for _, c in ipairs(chars:GetChildren()) do
                if c.Name ~= Player.Name and (c:FindFirstChild("Ball") or c:FindFirstChild("AlternateBallRig") or c == serverHolder) then
                    local st = c:FindFirstChild("state")
                    local t = st and st:FindFirstChild("team")
                    local ot = t and t.Value
                    if ot and ot ~= "lobby" and ot ~= myTeam then
                        local ohrp = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Ball")
                        local hbId = c:GetAttribute("HitboxId")
                        if hbId then
                            local fx = Workspace:FindFirstChild("Effects")
                            local hv = fx and fx:FindFirstChild("HitboxVisuals")
                            local box = hv and hv:FindFirstChild(hbId)
                            if box then ohrp = box end
                        end
                        if ohrp and (root.Position - ohrp.Position).Magnitude <= radius then
                            AutoVariantSteal.TargetPart = ohrp
                            return true
                        end
                    end
                end
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player then
                local oc = p.Character
                if oc and (oc:FindFirstChild("Ball") or oc:FindFirstChild("AlternateBallRig") or oc == serverHolder) then
                    local ot = AutoVariantSteal.GetPlayerTeam(p.Name)
                    if ot and ot ~= "lobby" and ot ~= myTeam then
                        local ohrp = oc:FindFirstChild("HumanoidRootPart") or oc:FindFirstChild("Ball")
                        local hbId = oc:GetAttribute("HitboxId")
                        if hbId then
                            local fx = Workspace:FindFirstChild("Effects")
                            local hv = fx and fx:FindFirstChild("HitboxVisuals")
                            local box = hv and hv:FindFirstChild(hbId)
                            if box then ohrp = box end
                        end
                        if ohrp and (root.Position - ohrp.Position).Magnitude <= radius then
                            AutoVariantSteal.TargetPart = ohrp
                            return true
                        end
                    end
                end
            end
        end

        return false
    end

    function AutoVariantSteal.AimAtTarget(targetPart, duration)
        if not targetPart then return end

        if AutoVariantSteal.AimConn then
            pcall(function() AutoVariantSteal.AimConn:Disconnect() end)
            AutoVariantSteal.AimConn = nil
        end

        local endTime = tick() + (duration or 0.45)
        AutoVariantSteal.AimConn = RunService.RenderStepped:Connect(function()
            if tick() > endTime or not targetPart or not targetPart.Parent then
                if AutoVariantSteal.AimConn then
                    pcall(function() AutoVariantSteal.AimConn:Disconnect() end)
                    AutoVariantSteal.AimConn = nil
                end
                return
            end
            local cam = Workspace.CurrentCamera
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local tPos = targetPart.Position
            if cam then
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, tPos)
            end
            if hrp then
                local flat = Vector3.new(tPos.X, hrp.Position.Y, tPos.Z)
                if (flat - hrp.Position).Magnitude > 0.1 then
                    hrp.CFrame = CFrame.new(hrp.Position, flat)
                end
            end
        end)
    end

    function AutoVariantSteal.PressSkill(skillName)
        pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillName } }) end)
    end

    function AutoVariantSteal.Process()
        local currentTime = tick()
        local style = Player:GetAttribute("style")
        local mappedStyle = style and AutoVariantSteal.StyleMapping[style:lower()]
        local flow = AutoVariantSteal.FindMyFlow()
        local playerTeam = flow and flow.Parent and flow.Parent:FindFirstChild("team") and flow.Parent.team.Value

        if playerTeam ~= "A" and playerTeam ~= "B" then
            AutoVariantSteal.IsPressing, AutoVariantSteal.HasReached100, AutoVariantSteal.WaitingForCooldown = false,
                false,
                false
            AutoVariantSteal.CurrentCharacter = nil
            return
        end

        if mappedStyle ~= AutoVariantSteal.CurrentCharacter then
            AutoVariantSteal.CurrentCharacter = mappedStyle
            AutoVariantSteal.IsPressing, AutoVariantSteal.HasReached100, AutoVariantSteal.WaitingForCooldown = false,
                false,
                false
            if mappedStyle then AutoVariantSteal.MyTeam = AutoVariantSteal.GetPlayerTeam(Player.Name) end
        end

        if not AutoVariantSteal.CurrentCharacter then return end
        local config = AutoVariantSteal.CharacterConfig[AutoVariantSteal.CurrentCharacter]

        if config.requiredSkillText then
            if AutoVariantSteal.GetSkill3Name() ~= config.requiredSkillText then
                AutoVariantSteal.IsPressing = false
                return
            end
        end

        local flowObj = AutoVariantSteal.FindMyFlow()
        if not flowObj then return end
        local currentFlow = flowObj.Value

        if currentFlow <= 0 then
            AutoVariantSteal.IsPressing, AutoVariantSteal.HasReached100 = false, false
            return
        end

        if currentFlow >= 100 and not AutoVariantSteal.HasReached100 then AutoVariantSteal.HasReached100 = true end
        local isTriggerReady = AutoVariantSteal.HasReached100 and currentFlow < 100

        if config.requiresFlow and not isTriggerReady then
            AutoVariantSteal.IsPressing = false
            return
        end

        if isTriggerReady then
            if IsSkillOnCooldown(config.skillName) then
                AutoVariantSteal.IsPressing = false
                return
            end
            if AutoVariantSteal.CheckBallProximity(config.radius) then
                if not AutoVariantSteal.IsPressing then
                    AutoVariantSteal.IsPressing = true
                    AutoVariantSteal.LastPressTime = 0
                end
            elseif AutoVariantSteal.IsPressing then
                AutoVariantSteal.IsPressing = false
            end
        elseif AutoVariantSteal.IsPressing then
            AutoVariantSteal.IsPressing = false
        end

        if AutoVariantSteal.IsPressing and currentTime - AutoVariantSteal.LastPressTime >= 0.1 then
            AutoVariantSteal.PressSkill(config.skillName)
            if config.aimbot and AutoVariantSteal.TargetPart then
                AutoVariantSteal.AimAtTarget(AutoVariantSteal.TargetPart, 0.45)
            end
            AutoVariantSteal.LastPressTime = currentTime
        end
    end

    function AutoVariantSteal.Start()
        AutoVariantSteal.Enabled = true
        AutoVariantSteal.CurrentCharacter = nil
        AutoVariantSteal.MyTeam = nil
        AutoVariantSteal.IsPressing = false
        AutoVariantSteal.HasReached100 = false
        AutoVariantSteal.WaitingForCooldown = false
        AutoVariantSteal.LastPressTime = 0
        AutoVariantSteal.Connection = RunService.Heartbeat:Connect(function()
            if not AutoVariantSteal.Enabled then return end
            AutoVariantSteal.Process()
        end)
        SafeNotify("Auto Variant Steal Enabled", 2, "Enable")
    end

    function AutoVariantSteal.Stop()
        AutoVariantSteal.Enabled = false
        if AutoVariantSteal.Connection then
            AutoVariantSteal.Connection:Disconnect()
            AutoVariantSteal.Connection = nil
        end
        if AutoVariantSteal.AimConn then
            pcall(function() AutoVariantSteal.AimConn:Disconnect() end)
            AutoVariantSteal.AimConn = nil
        end
        SafeNotify("Auto Variant Steal Disabled", 2, "Disable")
    end

    Library:CreateToggle(AutoVSSection, {
        Name = "Auto Variant Steal",
        Default = false,
        Callback = function(v) if v then AutoVariantSteal.Start() else AutoVariantSteal.Stop() end end
    })
end

local ShotPredictorSection = Library:CreateSection(MainCat, "Shot Predictor", "left")

do
    local STYLES_CONFIG = {
        ["yukimiya"] = {
            Curve = "left",
            CurvePower = 3.4,
            CurveTime = 0.30,
            DefaultShotPower = 120.7125,
            DefaultSpeed = 1.215,
            MaxTime = 3.0,
            LineColor = Color3.fromRGB(255, 85, 0),
            SecondaryColor = Color3.fromRGB(255, 170, 0),
            LandingMarkerColor = Color3.fromRGB(255, 70, 70),
        },
        ["kaiser"] = {
            Curve = "left",
            CurvePower = 1.0,
            CurveTime = 0.5,
            DefaultShotPower = 145,
            DefaultSpeed = 1.5,
            MaxTime = 3.5,
            LineColor = Color3.fromRGB(0, 140, 255),
            SecondaryColor = Color3.fromRGB(79, 126, 255),
            LandingMarkerColor = Color3.fromRGB(0, 200, 255),
        },
        ["masterykaiser"] = {
            Curve = "left",
            CurvePower = 1.0,
            CurveTime = 0.5,
            DefaultShotPower = 145,
            DefaultSpeed = 1.5,
            MaxTime = 3.5,
            LineColor = Color3.fromRGB(0, 150, 255),
            SecondaryColor = Color3.fromRGB(90, 140, 255),
            LandingMarkerColor = Color3.fromRGB(0, 220, 255),
        },
        ["sae"] = {
            Curve = "right",
            CurvePower = 1.05,
            CurveTime = 0.50,
            DefaultShotPower = 132.5,
            DefaultSpeed = 1.44,
            MaxTime = 3.5,
            MinElevationY = 0.0734,
            MaxElevationY = 0.587,
            ElevationPower = 0.76,
            LineColor = Color3.fromRGB(225, 40, 110),
            SecondaryColor = Color3.fromRGB(255, 120, 180),
            LandingMarkerColor = Color3.fromRGB(255, 50, 130),
        },
        ["rin"] = {
            Curve = "right",
            CurvePower = 1.20,
            CurveTime = 0.45,
            DefaultShotPower = 129.7,
            DefaultSpeed = 1.85,
            MaxTime = 2.8,
            MinElevationY = 0.192,
            MaxElevationY = 0.593,
            ElevationPower = 0.80,
            MinCamY = 0.24,
            LineColor = Color3.fromRGB(0, 220, 160),
            SecondaryColor = Color3.fromRGB(0, 255, 200),
            LandingMarkerColor = Color3.fromRGB(0, 240, 180),
        },
        ["karasu"] = {
            Curve = "right",
            CurvePower = 1.05,
            CurveTime = 0.50,
            DefaultShotPower = 112,
            DefaultSpeed = 1.42,
            MaxTime = 3.5,
            LineColor = Color3.fromRGB(83, 76, 144),
            SecondaryColor = Color3.fromRGB(83, 76, 144),
            LandingMarkerColor = Color3.fromRGB(83, 76, 144),
        }
    }

    local ShotPredictor = {
        Enabled = false,
        Connection = nil,
        ShowForEnemies = false,
        OnlyNearEnemyGoalBox = false,
        OnlyInOurGoalbox = false,
        OnlyWhenGK = false,
        AimSource = "Camera",
        VerticalAngleMultiplier = 1.0,
        LineThickness = 0.20,
        LineTransparency = 0.20,
        MaxPoints = 50,
        LandingMarkerSize = Vector3.new(2.3, 0.15, 2.3),
        Goalboxes = {
            A = { minX = -858.91, maxX = -217.89, minZ = 1500.90, maxZ = 1706.09 },
            B = { minX = -858.61, maxX = -217.91, minZ = 841.90, maxZ = 1041.18 },
        }
    }

    local spDefaultEnemyConfig = {
        SkillNumber = 1,
        SkillName = "Shoot",
        SkillKeyword = "shoot",
        Curve = nil,
        CurvePower = 0,
        CurveTime = 0,
        DefaultShotPower = 110,
        DefaultSpeed = 1.4,
        MaxTime = 3.0,
        LineColor = Color3.fromRGB(255, 60, 60),
        SecondaryColor = Color3.fromRGB(255, 140, 140),
        LandingMarkerColor = Color3.fromRGB(255, 70, 70),
    }

    local sp_v3_new = Vector3.new
    local sp_v3_zero = Vector3.zero
    local sp_cf_new = CFrame.new
    local sp_cf_lookAt = CFrame.lookAt
    local sp_cf_angles = CFrame.Angles
    local sp_m_clamp = math.clamp
    local sp_m_abs = math.abs
    local sp_m_pow = math.pow
    local sp_m_sin = math.sin
    local sp_m_cos = math.cos
    local sp_m_rad = math.rad

    local spActiveStyleName = ""
    local spActiveConfig = nil
    local spCurrentShotPower = 0
    local spCurrentSpeed = 1.5
    local spLastStyleCheck = 0

    local spRayParams = RaycastParams.new()
    spRayParams.FilterType = Enum.RaycastFilterType.Include
    local spBarrier = Workspace:FindFirstChild("map") and Workspace.map:FindFirstChild("barriar")
    if spBarrier then
        spRayParams.FilterDescendantsInstances = { spBarrier }
    else
        spRayParams.FilterType = Enum.RaycastFilterType.Exclude
    end

    local spPointsBuffer = table.create(ShotPredictor.MaxPoints)

    local spEffectsFolder = Workspace:FindFirstChild("Effects") or Workspace
    local spLineModel = Instance.new("Model")
    spLineModel.Name = "AzureLockShotPrediction"
    spLineModel.Parent = spEffectsFolder

    local spPartPool = table.create(ShotPredictor.MaxPoints)
    for i = 1, ShotPredictor.MaxPoints do
        local p = Instance.new("Part")
        p.Name = "Trace_" .. i
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Transparency = 1
        p.Size = sp_v3_new(ShotPredictor.LineThickness, ShotPredictor.LineThickness, 1)
        p.CFrame = sp_cf_new(0, -500, 0)
        p.Parent = spLineModel
        spPartPool[i] = p
    end

    local spLandingMarker = Instance.new("Part")
    spLandingMarker.Name = "LandingMarker"
    spLandingMarker.Anchored = true
    spLandingMarker.CanCollide = false
    spLandingMarker.CanQuery = false
    spLandingMarker.CanTouch = false
    spLandingMarker.CastShadow = false
    spLandingMarker.Material = Enum.Material.Neon
    spLandingMarker.Shape = Enum.PartType.Cylinder
    spLandingMarker.Size = ShotPredictor.LandingMarkerSize
    spLandingMarker.Transparency = 1
    spLandingMarker.CFrame = sp_cf_new(0, -500, 0)
    spLandingMarker.Parent = spLineModel

    local spCachedColors = table.create(ShotPredictor.MaxPoints)
    local spLastColorStyle = ""

    local function spUpdateColorGradient(config, styleKey)
        local targetCfg = config or spActiveConfig
        local key = styleKey or spActiveStyleName
        if not targetCfg or spLastColorStyle == key then return end
        spLastColorStyle = key
        local col1 = targetCfg.LineColor
        local col2 = targetCfg.SecondaryColor
        local total = ShotPredictor.MaxPoints - 1
        for i = 1, total do
            local alpha = (i / total) * 0.75
            spCachedColors[i] = col1:Lerp(col2, alpha)
        end
        spLandingMarker.Color = targetCfg.LandingMarkerColor
    end

    local function spGetCharacterStyle(character)
        if not character then return nil end
        local state = character:FindFirstChild("state")
        local styleVal = state and state:FindFirstChild("style")
        if styleVal and styleVal.Value and styleVal.Value ~= "" then
            return string.lower(styleVal.Value)
        end
        local attrStyle = character:GetAttribute("Style") or character:GetAttribute("style")
        if attrStyle and attrStyle ~= "" then
            return string.lower(attrStyle)
        end
        local plr = Players:GetPlayerFromCharacter(character) or Players:FindFirstChild(character.Name)
        if plr then
            local playerAttr = plr:GetAttribute("style") or plr:GetAttribute("Style")
            if playerAttr and playerAttr ~= "" then
                return string.lower(playerAttr)
            end
        end
        if character == Player.Character then
            local playerAttr = Player:GetAttribute("style") or Player:GetAttribute("Style")
            if playerAttr and playerAttr ~= "" then
                return string.lower(playerAttr)
            end
        end
        return nil
    end

    local function spUpdateActiveStyle(character, now)
        if (now - spLastStyleCheck) < 0.5 then return end
        spLastStyleCheck = now

        local styleName = spGetCharacterStyle(character)
        if not styleName or styleName == "" then
            if spActiveConfig ~= nil then
                spActiveStyleName = ""
                spActiveConfig = nil
            end
            return
        end

        if styleName ~= spActiveStyleName then
            spActiveStyleName = styleName
            local matchedConfig = STYLES_CONFIG[styleName]
            spActiveConfig = matchedConfig
            if matchedConfig then
                spCurrentShotPower = matchedConfig.DefaultShotPower
                spCurrentSpeed = matchedConfig.DefaultSpeed
            end

            if not spBarrier and character then
                spRayParams.FilterDescendantsInstances = { character }
            end
        end
    end

    local function spSimulateTrajectory(params)
        local startCF = params.CFrame
        local startPos = startCF.Position
        local noY = params.NoY == true
        local gravityY = noY and 0 or (-196.2 * 2.5)
        local speed = params.Speed
        local maxTime = params.maxTime
        local curveTime = params.curveTime
        local curvePower = params.curvePower
        local isCurve = params.IsCurve
        local isLeft = (isCurve == "left")
        local isUp = not noY and (isCurve == "up")
        local doLoopty = not noY and params.DoLoopty
        local loopRadius = params.LoopRadius or 2
        local loopSpeed = params.LoopSpeed or 6
        local loopWidth = params.LoopWidth or 4
        local loopHeight = params.LoopHeight or 2

        local vel = params.Velocity
        local curveVelMag = vel.Magnitude * curveTime
        local rightVec = -startCF.RightVector

        if isCurve and not doLoopty then
            if isUp then
                curveVelMag = curveVelMag * 0.5
            else
                if isLeft then
                    vel = vel + (-startCF.RightVector * curveVelMag)
                else
                    vel = vel + (startCF.RightVector * curveVelMag)
                end
            end
        end

        local pointsCount = 1
        spPointsBuffer[1] = startPos

        local currentPosX = startPos.X
        local currentPosY = startPos.Y
        local currentPosZ = startPos.Z

        local currentVelX = vel.X
        local currentVelY = noY and 0 or vel.Y
        local currentVelZ = vel.Z

        local curTime = 0
        local stepDt = 1 / 45
        local curveElapsed = 0
        local bounceLimit = 5
        local groundLevel = 0.85

        while curTime < maxTime do
            local remaining = maxTime - curTime
            local dt = remaining < stepDt and remaining or stepDt
            curTime = curTime + dt
            if dt <= 0 then break end

            local scaledDt = dt / speed

            local velMagSq = currentVelX * currentVelX + (noY and 0 or (currentVelY * currentVelY)) +
                currentVelZ * currentVelZ
            if velMagSq > 0.01 then
                local decay = sp_m_pow(0.1, scaledDt)
                currentVelX = currentVelX * decay
                if not noY then
                    currentVelY = currentVelY * decay
                end
                currentVelZ = currentVelZ * decay
            end
            if not noY then
                currentVelY = currentVelY + gravityY * scaledDt
            end

            local horizVelX = currentVelX
            local horizVelZ = currentVelZ
            local vertVelY = noY and 0 or currentVelY

            if spBarrier then
                local moveStep = sp_v3_new(horizVelX * scaledDt, 0, horizVelZ * scaledDt)
                local currentPosV3 = sp_v3_new(currentPosX, currentPosY, currentPosZ)
                local rayHit = Workspace:Raycast(currentPosV3, moveStep, spRayParams)
                if rayHit then
                    local norm = rayHit.Normal
                    local dot = horizVelX * norm.X + horizVelZ * norm.Z
                    horizVelX = horizVelX - 2 * dot * norm.X
                    horizVelZ = horizVelZ - 2 * dot * norm.Z
                    currentPosX = rayHit.Position.X + norm.X * 0.1
                    currentPosZ = rayHit.Position.Z + norm.Z * 0.1
                    if isCurve then
                        horizVelX = horizVelX * 0.5
                        horizVelZ = horizVelZ * 0.5
                        isCurve = nil
                    end
                end
            end

            if isUp then
                if isCurve and curveElapsed < curveTime then
                    curveElapsed = sp_m_clamp(curveElapsed + scaledDt, 0, curveTime)
                    vertVelY = vertVelY +
                        2 * (curveVelMag * curvePower) / curveTime * (1 - curveElapsed / curveTime) * scaledDt
                    if curveElapsed >= curveTime then isCurve = nil end
                end
            elseif isCurve and curveElapsed < curveTime then
                curveElapsed = sp_m_clamp(curveElapsed + scaledDt, 0, curveTime)
                local offsetMag = (curveVelMag * curvePower * 2) * scaledDt
                if isLeft then
                    horizVelX = horizVelX - rightVec.X * offsetMag
                    horizVelZ = horizVelZ - rightVec.Z * offsetMag
                else
                    horizVelX = horizVelX + rightVec.X * offsetMag
                    horizVelZ = horizVelZ + rightVec.Z * offsetMag
                end
            end

            if doLoopty and (horizVelX * horizVelX + horizVelZ * horizVelZ) > 0.01 and currentPosY > 0.9 then
                local loopAngle = curTime * loopSpeed
                local hUnit = sp_v3_new(horizVelX, 0, horizVelZ).Unit
                local unitCross1 = hUnit:Cross(sp_v3_new(0, 1, 0)).Unit
                local unitCross2 = unitCross1:Cross(hUnit).Unit
                local loopOffset = unitCross1 * (sp_m_sin(loopAngle) * loopRadius * loopWidth) +
                    unitCross2 * (sp_m_cos(loopAngle) * loopRadius * loopHeight)
                if loopOffset.Magnitude > 0 then
                    local transformed = CFrame.fromAxisAngle(loopOffset.Unit, loopOffset.Magnitude * scaledDt)
                        :VectorToWorldSpace(sp_v3_new(horizVelX, 0, horizVelZ))
                    horizVelX = transformed.X
                    horizVelZ = transformed.Z
                end
            end

            currentPosX = currentPosX + horizVelX * scaledDt
            if not noY then
                currentPosY = currentPosY + vertVelY * scaledDt
            end
            currentPosZ = currentPosZ + horizVelZ * scaledDt

            if not noY and currentPosY <= groundLevel then
                currentPosY = groundLevel
                if sp_m_abs(vertVelY) > 0.1 and bounceLimit > 0 then
                    bounceLimit = bounceLimit - 1
                    vertVelY = -vertVelY * 0.7
                else
                    vertVelY = 0
                end
                if (horizVelX * horizVelX + horizVelZ * horizVelZ) < 0.01 then
                    horizVelX = 0
                    horizVelZ = 0
                end
            end

            currentVelX = horizVelX
            if not noY then
                currentVelY = vertVelY
            end
            currentVelZ = horizVelZ

            pointsCount = pointsCount + 1
            spPointsBuffer[pointsCount] = sp_v3_new(currentPosX, currentPosY, currentPosZ)

            if pointsCount >= ShotPredictor.MaxPoints or (velMagSq < 0.01 and (noY or currentPosY < 1.85)) then
                break
            end
        end

        return pointsCount
    end

    local function spResolveDirection(hrp)
        local cam = Workspace.CurrentCamera or workspace.CurrentCamera
        local camAimSetting = Player:FindFirstChild("setting") and Player.setting:FindFirstChild("camAim")
        local isCamAim = (camAimSetting and camAimSetting.Value) or (ShotPredictor.AimSource == "Camera")

        local LookVector
        if isCamAim and cam then
            local _, camYaw, _ = cam.CFrame:ToEulerAnglesYXZ()
            LookVector = (CFrame.fromEulerAnglesYXZ(0, camYaw, 0)).LookVector
        else
            LookVector = hrp.CFrame.LookVector
        end

        local rawCamY = (cam and cam.CFrame.LookVector.Y or 0.05) * ShotPredictor.VerticalAngleMultiplier
        local minY = (spActiveConfig and spActiveConfig.MinElevationY) or 0.0734
        local maxY = (spActiveConfig and spActiveConfig.MaxElevationY) or 0.587
        local elevPow = (spActiveConfig and spActiveConfig.ElevationPower) or 0.76
        local minCamY = (spActiveConfig and spActiveConfig.MinCamY) or 0.04

        local Y
        if rawCamY <= minCamY then
            Y = minY
        else
            local normT = sp_m_clamp((rawCamY - minCamY) / (0.94 - minCamY), 0, 1.0)
            Y = minY + (maxY - minY) * sp_m_pow(normT, elevPow)
        end

        local shootDirX = LookVector.X
        local shootDirY = Y
        local shootDirZ = LookVector.Z
        local mag = math.sqrt(shootDirX * shootDirX + shootDirY * shootDirY + shootDirZ * shootDirZ)

        return sp_v3_new(shootDirX / mag, shootDirY / mag, shootDirZ / mag)
    end

    local function spGetBallOrigin(character, hrp, shootDir)
        local charBall = character:FindFirstChild("Ball")
        if charBall and charBall:IsA("BasePart") and charBall.Position.Y < (hrp.Position.Y - 1.0) then
            return charBall.Position
        end

        local mapFootball = Workspace:FindFirstChild("Football") or
            (Workspace:FindFirstChild("Effects") and Workspace.Effects:FindFirstChild("Ball"))
        if mapFootball and mapFootball:IsA("BasePart") and (mapFootball.Position - hrp.Position).Magnitude < 7 and mapFootball.Position.Y < (hrp.Position.Y - 1.0) then
            return mapFootball.Position
        end

        local hMag = math.sqrt(shootDir.X * shootDir.X + shootDir.Z * shootDir.Z)
        local hX = shootDir.X / hMag
        local hZ = shootDir.Z / hMag
        local groundY = hrp.Position.Y - 2.15

        return sp_v3_new(hrp.Position.X + hX * 1.8, groundY, hrp.Position.Z + hZ * 1.8)
    end

    local spShotParamsObj = {
        Velocity = sp_v3_zero,
        CFrame = sp_cf_new(),
        IsCurve = nil,
        Speed = 1.5,
        curveTime = 0.5,
        curvePower = 1.0,
        DoLoopty = false,
        maxTime = 3.5,
    }

    local function spHideVisuals()
        for i = 1, ShotPredictor.MaxPoints do
            local part = spPartPool[i]
            if part.Transparency ~= 1 then
                part.Transparency = 1
                part.CFrame = sp_cf_new(0, -500, 0)
            end
        end
        if spLandingMarker.Transparency ~= 1 then
            spLandingMarker.Transparency = 1
            spLandingMarker.CFrame = sp_cf_new(0, -500, 0)
        end
    end

    function ShotPredictor.IsInOurGoalbox(pos, myTeam)
        local g = ShotPredictor.Goalboxes[myTeam]
        if not g then return false end
        return pos.X >= g.minX and pos.X <= g.maxX and pos.Z >= g.minZ and pos.Z <= g.maxZ
    end

    function ShotPredictor.IsInEnemyGoalbox(pos, myTeam)
        local g = ShotPredictor.Goalboxes[myTeam == "A" and "B" or "A"]
        if not g then return false end
        return pos.X >= g.minX and pos.X <= g.maxX and pos.Z >= g.minZ and pos.Z <= g.maxZ
    end

    local function spGetMyTeam()
        local t = GetTeam and GetTeam(Player.Name)
        if t and (t == "A" or t == "B") then return t end
        if AutoLineUps and AutoLineUps.GetTeam then
            local at = AutoLineUps.GetTeam()
            if at and (at == "A" or at == "B") then return at end
        end
        return nil
    end

    local function spGetEnemyWithBall(myTeam)
        local chars = Workspace:FindFirstChild("characters")
        if not chars or not myTeam then return nil, nil end
        for _, c in ipairs(chars:GetChildren()) do
            if c:IsA("Model") and c.Name ~= Player.Name and c:FindFirstChild("Ball") then
                local enemyTeam = GetTeam and GetTeam(c.Name)
                if not enemyTeam then
                    local st = c:FindFirstChild("state")
                    local tv = st and st:FindFirstChild("team")
                    if tv and (tv.Value == "A" or tv.Value == "B") then enemyTeam = tv.Value end
                end
                if enemyTeam and enemyTeam ~= myTeam and (enemyTeam == "A" or enemyTeam == "B") then
                    local enemyHrp = c:FindFirstChild("HumanoidRootPart")
                    if enemyHrp then
                        return c, enemyHrp
                    end
                end
            end
        end
        return nil, nil
    end

    function ShotPredictor.Update()
        if not ShotPredictor.Enabled then
            spHideVisuals()
            return
        end

        if ShotPredictor.OnlyWhenGK then
            local state = Player.Character and Player.Character:FindFirstChild("state")
            local role = state and state:FindFirstChild("role")
            if not role or role.Value ~= "GK" then
                spHideVisuals()
                return
            end
        end

        local char = Player.Character
        if not char or not char:IsDescendantOf(Workspace) then
            spHideVisuals()
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            spHideVisuals()
            return
        end

        local myTeam = spGetMyTeam()

        local targetChar = nil
        local targetHrp = nil
        local targetConfig = nil
        local targetStyleKey = nil
        local isEnemy = false

        if HasBall and HasBall(Player.Name) then
            local now = os.clock()
            spUpdateActiveStyle(char, now)
            if spActiveConfig then
                local valid = true
                if ShotPredictor.OnlyNearEnemyGoalBox and myTeam then
                    if not ShotPredictor.IsInEnemyGoalbox(hrp.Position, myTeam) then
                        valid = false
                    end
                end
                if ShotPredictor.OnlyInOurGoalbox and myTeam then
                    if not ShotPredictor.IsInOurGoalbox(hrp.Position, myTeam) then
                        valid = false
                    end
                end
                if valid then
                    targetChar = char
                    targetHrp = hrp
                    targetConfig = spActiveConfig
                    targetStyleKey = spActiveStyleName
                    isEnemy = false
                end
            end
        elseif ShotPredictor.ShowForEnemies and myTeam then
            local enemyChar, enemyHrp = spGetEnemyWithBall(myTeam)
            if enemyChar and enemyHrp then
                local valid = true
                if ShotPredictor.OnlyInOurGoalbox then
                    if not ShotPredictor.IsInOurGoalbox(enemyHrp.Position, myTeam) then
                        valid = false
                    end
                end
                if valid then
                    local enemyStyle = spGetCharacterStyle(enemyChar) or ""
                    local cfg = STYLES_CONFIG[enemyStyle]
                    if cfg then
                        targetChar = enemyChar
                        targetHrp = enemyHrp
                        targetConfig = cfg
                        targetStyleKey = "enemy_" .. enemyStyle
                        isEnemy = true
                    end
                end
            end
        end

        if not targetChar or not targetHrp or not targetConfig then
            spHideVisuals()
            return
        end

        spUpdateColorGradient(targetConfig, targetStyleKey)

        local dir, vel, startPos, startCF
        local power = isEnemy and (targetConfig.DefaultShotPower or 110) or spCurrentShotPower
        local baseSpeed = (power / 10) * 50

        if isEnemy then
            local look = targetHrp.CFrame.LookVector
            local hMag = math.sqrt(look.X * look.X + look.Z * look.Z)
            if hMag > 0.001 then
                dir = sp_v3_new(look.X / hMag, 0, look.Z / hMag)
            else
                dir = sp_v3_new(0, 0, 1)
            end
            vel = dir * baseSpeed
            startPos = targetHrp.Position
            startCF = sp_cf_lookAt(startPos, startPos + dir)
        else
            dir = spResolveDirection(targetHrp)
            vel = dir * baseSpeed
            startPos = spGetBallOrigin(targetChar, targetHrp, dir)
            startCF = sp_cf_lookAt(startPos, startPos + dir)
        end

        local curveVal = targetConfig.Curve
        if curveVal == "none" or curveVal == "" then curveVal = nil end

        spShotParamsObj.Velocity = vel
        spShotParamsObj.CFrame = startCF
        spShotParamsObj.IsCurve = curveVal
        spShotParamsObj.Speed = isEnemy and (targetConfig.DefaultSpeed or 1.4) or spCurrentSpeed
        spShotParamsObj.curveTime = targetConfig.CurveTime
        spShotParamsObj.curvePower = targetConfig.CurvePower
        spShotParamsObj.maxTime = targetConfig.MaxTime
        spShotParamsObj.NoY = isEnemy

        local pointsCount = spSimulateTrajectory(spShotParamsObj)
        if pointsCount < 2 then
            spHideVisuals()
            return
        end

        local segCount = pointsCount - 1
        for i = 1, segCount do
            local p1 = spPointsBuffer[i]
            local p2 = spPointsBuffer[i + 1]
            local dx = p2.X - p1.X
            local dy = p2.Y - p1.Y
            local dz = p2.Z - p1.Z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

            local part = spPartPool[i]
            if dist > 0.02 then
                part.Size = sp_v3_new(ShotPredictor.LineThickness, ShotPredictor.LineThickness, dist)
                part.CFrame = sp_cf_lookAt(p1, p2) * sp_cf_new(0, 0, -dist * 0.5)
                part.Color = spCachedColors[i] or targetConfig.LineColor
                part.Transparency = ShotPredictor.LineTransparency
            else
                part.Transparency = 1
            end
        end

        for i = segCount + 1, ShotPredictor.MaxPoints do
            local part = spPartPool[i]
            if part.Transparency ~= 1 then
                part.Transparency = 1
                part.CFrame = sp_cf_new(0, -500, 0)
            end
        end

        if isEnemy then
            if spLandingMarker.Transparency ~= 1 then
                spLandingMarker.Transparency = 1
                spLandingMarker.CFrame = sp_cf_new(0, -500, 0)
            end
        else
            local lastPos = spPointsBuffer[pointsCount]
            spLandingMarker.Transparency = 0.35
            spLandingMarker.CFrame = sp_cf_new(lastPos.X, lastPos.Y + 0.08, lastPos.Z) * sp_cf_angles(0, 0, sp_m_rad(90))
        end
    end

    function ShotPredictor.Start()
        if ShotPredictor.Connection then ShotPredictor.Connection:Disconnect() end
        ShotPredictor.Enabled = true
        ShotPredictor.Connection = RunService.RenderStepped:Connect(ShotPredictor.Update)
        task.spawn(function()
            task.wait(0.5)
            SafeNotify("Shot Predictor Enabled", 2, "Enable")
        end)
    end

    function ShotPredictor.Stop()
        ShotPredictor.Enabled = false
        if ShotPredictor.Connection then
            ShotPredictor.Connection:Disconnect()
            ShotPredictor.Connection = nil
        end
        spHideVisuals()
        SafeNotify("Shot Predictor Disabled", 2, "Disable")
    end

    Library:CreateToggle(ShotPredictorSection, {
        Name = "Shot Predictor",
        Default = false,
        Callback = function(v) if v then ShotPredictor.Start() else ShotPredictor.Stop() end end
    })

    Library:CreateToggle(ShotPredictorSection, {
        Name = "Show For Enemies",
        Default = false,
        Callback = function(v) ShotPredictor.ShowForEnemies = v end
    })

    Library:CreateToggle(ShotPredictorSection, {
        Name = "Only In Our Goalbox",
        Default = false,
        Callback = function(v) ShotPredictor.OnlyInOurGoalbox = v end
    })

    Library:CreateToggle(ShotPredictorSection, {
        Name = "Only When GK",
        Default = false,
        Callback = function(v) ShotPredictor.OnlyWhenGK = v end
    })

    Library:CreateToggle(ShotPredictorSection, {
        Name = "Only Near Goal",
        Default = false,
        Callback = function(v) ShotPredictor.OnlyNearEnemyGoalBox = v end
    })
end


local MoveBuff
AutoLineUps = {
    Enabled = false,
    Connection = nil,
    AnimConnection = nil,
    Markers = {},
    IsExecuting = false,
    CurrentTeam = nil,
    CurrentStyle = nil,
    LastExecutionTime = 0,
    ExecutionStartTime = 0,
    Frozen = false,
    MouseLocked = false,
    OriginalMouseDelta = nil,
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
    LastFlowState = false,
    MarkerMode = "Old",
    UserChangedDisableBasic = false,
    DisableBasicToggle = nil,
    IsHoldingKey = false,
    HoldKeybind = nil,
    CurrentPoint = nil,
    IsAssistingWalk = false,
    Config = {
        mode = "Old",
        useFreeze = true,
        noFreeze = false,
        positionTolerance = 3.5,
        smoothAiming = false,
        smoothness = 0.15,
        useAccuracy = false,
        accuracy = 100,
        aimTime = 0.01,
        postSuccessFreeze = 0.5,
        markerSize = Vector3.new(4, 8, 4),
        markerTransparency = 0.3,
        disableBasicLineups = false,
        disableRegularInFlow = false,
        holdToUse = false,
        holdKey = Enum.KeyCode.H,
    },
}

AutoLineUps.FlowState = { HasFlow = false, WasAbove100 = false, LastFlowValue = 0 }

AutoLineUps.ReoSkillMapping = {
    ["Curve Shot"] = "rin",
    ["Kill."] = "rin_flow",
    ["Kaiser Impact: Magnus"] = "kaiser",
    ["Gyro Shot"] = "yukimiya",
    ["Drive Shot"] = "sae",
    ["Direct Shot"] = "isagi",
    ["Long Shot"] = "barou",
    ["Bon!"] = "bachira",
    ["Lefty Shot"] = "kunigami",
    ["Neo Direct Shot"] = "nelisagi",
    ["Dive-Bomb Assault"] = "karasu",
}
AutoLineUps.ReoMarkerColor = Color3.fromRGB(147, 63, 232)
AutoLineUps.CurrentReoSkill = nil
AutoLineUps.ReoFlowUsedThisCycle = false

function AutoLineUps.GetReoSkill4Name()
    local gui = Player:FindFirstChild("PlayerGui")
    local hb = gui and gui:FindFirstChild("Hotbar")
    local bp = hb and hb:FindFirstChild("Backpack")
    local hf = bp and bp:FindFirstChild("Hotbar")
    local s4 = hf and hf:FindFirstChild("skill4")
    local base = s4 and s4:FindFirstChild("Base")
    local tn = base and base:FindFirstChild("ToolName")
    return tn and tn.Text or nil
end

function AutoLineUps.GetReoSkill3Name()
    local gui = Player:FindFirstChild("PlayerGui")
    local hb = gui and gui:FindFirstChild("Hotbar")
    local bp = hb and hb:FindFirstChild("Backpack")
    local hf = bp and bp:FindFirstChild("Hotbar")
    local s3 = hf and hf:FindFirstChild("skill3")
    local base = s3 and s3:FindFirstChild("Base")
    local tn = base and base:FindFirstChild("ToolName")
    return tn and tn.Text or nil
end

AutoLineUps.StylesConfig = {
    rin = {
        skillName = "skill3",
        markerColor = Color3.fromRGB(81, 149, 144),
        requiredKey = Enum.KeyCode.Three,
        points = {
            A = {
                { targetPosition = Vector3.new(-637.31, 3.00, 994.71),  mouseTargetPosition = Vector3.new(-593.40, 58.55, 841.19), lookAtHeight = 58.55 },
                { targetPosition = Vector3.new(-571.40, 3.00, 1001.75), mouseTargetPosition = Vector3.new(-597.22, 51.67, 841.19), lookAtHeight = 51.67 },
                { targetPosition = Vector3.new(-495.93, 3.00, 994.28),  mouseTargetPosition = Vector3.new(-603.81, 51.72, 841.19), lookAtHeight = 51.72 },
                { targetPosition = Vector3.new(-423.81, 3.00, 950.98),  mouseTargetPosition = Vector3.new(-523.92, 37.66, 881.58), lookAtHeight = 37.66 },
                { targetPosition = Vector3.new(-699.55, 3.00, 869.03),  mouseTargetPosition = Vector3.new(-643.77, 21.24, 841.27), lookAtHeight = 21.24 }
            },
            B = {
                { targetPosition = Vector3.new(-447.51, 3.00, 1560.03), mouseTargetPosition = Vector3.new(-478.30, 56.02, 1706.37), lookAtHeight = 56.02 },
                { targetPosition = Vector3.new(-533.76, 3.00, 1556.36), mouseTargetPosition = Vector3.new(-471.14, 52.52, 1706.58), lookAtHeight = 52.52 },
                { targetPosition = Vector3.new(-569.68, 3.00, 1555.14), mouseTargetPosition = Vector3.new(-528.28, 37.18, 1665.63), lookAtHeight = 37.18 },
                { targetPosition = Vector3.new(-633.96, 3.00, 1593.53), mouseTargetPosition = Vector3.new(-541.68, 34.70, 1665.63), lookAtHeight = 34.70 },
                { targetPosition = Vector3.new(-381.16, 3.00, 1673.41), mouseTargetPosition = Vector3.new(-443.21, 24.40, 1706.58), lookAtHeight = 24.40 }
            }
        }
    },
    rin_flow = {
        skillName = "skill4",
        markerColor = Color3.fromRGB(255, 60, 60),
        requiredKey = Enum.KeyCode.Four,
        flow = true,
        points = { A = {}, B = {} }
    },
    kaiser = {
        skillName = "skill2",
        markerColor = Color3.fromRGB(148, 242, 240),
        requiredKey = Enum.KeyCode.Two,
        points = {
            A = {
                { targetPosition = Vector3.new(-537.77, 3.00, 1041.04), mouseTargetPosition = Vector3.new(-465.29, 60.94, 841.74), lookAtHeight = 60.94 },
                { targetPosition = Vector3.new(-621.25, 3.00, 994.00),  mouseTargetPosition = Vector3.new(-505.90, 41.70, 881.58), lookAtHeight = 41.70 },
                { targetPosition = Vector3.new(-660.85, 3.00, 928.65),  mouseTargetPosition = Vector3.new(-521.35, 49.52, 881.58), lookAtHeight = 49.52 },
                { targetPosition = Vector3.new(-478.35, 3.00, 1026.82), mouseTargetPosition = Vector3.new(-486.88, 53.26, 841.74), lookAtHeight = 53.26 },
                { targetPosition = Vector3.new(-425.10, 3.00, 979.05),  mouseTargetPosition = Vector3.new(-462.87, 35.31, 841.74), lookAtHeight = 35.31 }
            },
            B = {
                { targetPosition = Vector3.new(-535.47, 3.00, 1502.57), mouseTargetPosition = Vector3.new(-553.69, 49.92, 1665.63), lookAtHeight = 49.92 },
                { targetPosition = Vector3.new(-442.76, 3.00, 1560.32), mouseTargetPosition = Vector3.new(-560.06, 41.08, 1665.63), lookAtHeight = 41.08 },
                { targetPosition = Vector3.new(-415.06, 3.00, 1618.33), mouseTargetPosition = Vector3.new(-562.18, 53.00, 1665.63), lookAtHeight = 53.00 },
                { targetPosition = Vector3.new(-606.86, 3.00, 1558.38), mouseTargetPosition = Vector3.new(-594.11, 36.30, 1706.68), lookAtHeight = 36.30 },
                { targetPosition = Vector3.new(-662.77, 3.00, 1531.79), mouseTargetPosition = Vector3.new(-605.36, 51.95, 1706.68), lookAtHeight = 51.95 }
            }
        }
    },
    masterykaiser = {
        skillName = "skill2",
        markerColor = Color3.fromRGB(115, 199, 197),
        requiredKey = Enum.KeyCode.Two,
        points = { A = {}, B = {} }
    },
    sae = {
        skillName = "skill3",
        markerColor = Color3.fromRGB(181, 60, 102),
        requiredKey = Enum.KeyCode.Three,
        points = {
            A = {
                { targetPosition = Vector3.new(-624.60, 3.00, 981.95),  mouseTargetPosition = Vector3.new(-592.20, 40.41, 841.19), lookAtHeight = 40.41 },
                { targetPosition = Vector3.new(-537.06, 3.00, 1003.45), mouseTargetPosition = Vector3.new(-602.54, 47.09, 841.19), lookAtHeight = 47.09 },
                { targetPosition = Vector3.new(-686.89, 3.00, 874.20),  mouseTargetPosition = Vector3.new(-633.46, 20.03, 841.19), lookAtHeight = 20.03 },
                { targetPosition = Vector3.new(-445.68, 3.00, 973.82),  mouseTargetPosition = Vector3.new(-533.49, 35.20, 881.58), lookAtHeight = 35.20 }
            },
            B = {
                { targetPosition = Vector3.new(-430.59, 3.00, 1553.31), mouseTargetPosition = Vector3.new(-477.97, 56.75, 1706.37), lookAtHeight = 56.75 },
                { targetPosition = Vector3.new(-535.31, 3.00, 1540.93), mouseTargetPosition = Vector3.new(-523.21, 35.14, 1665.63), lookAtHeight = 35.14 },
                { targetPosition = Vector3.new(-372.55, 3.00, 1672.74), mouseTargetPosition = Vector3.new(-433.69, 22.40, 1706.58), lookAtHeight = 22.40 },
                { targetPosition = Vector3.new(-648.20, 3.00, 1563.40), mouseTargetPosition = Vector3.new(-542.75, 44.91, 1665.63), lookAtHeight = 44.91 }
            }
        }
    },
    yukimiya = {
        skillName = "skill1",
        markerColor = Color3.fromRGB(255, 134, 35),
        requiredKey = Enum.KeyCode.One,
        points = {
            A = {
                { targetPosition = Vector3.new(-529.10, 3.00, 1042.31), mouseTargetPosition = Vector3.new(-598.02, 105.64, 841.19), lookAtHeight = 105.64 },
                { targetPosition = Vector3.new(-592.91, 3.00, 1029.53), mouseTargetPosition = Vector3.new(-587.54, 113.04, 841.74), lookAtHeight = 113.04 },
                { targetPosition = Vector3.new(-417.89, 3.00, 978.81),  mouseTargetPosition = Vector3.new(-514.11, 51.76, 881.58),  lookAtHeight = 51.76 },
                { targetPosition = Vector3.new(-362.41, 3.00, 928.97),  mouseTargetPosition = Vector3.new(-540.42, 81.23, 881.58),  lookAtHeight = 81.23 }
            },
            B = {
                { targetPosition = Vector3.new(-500.77, 3.00, 1509.83), mouseTargetPosition = Vector3.new(-475.30, 125.28, 1706.58), lookAtHeight = 125.28 },
                { targetPosition = Vector3.new(-460.22, 3.00, 1541.17), mouseTargetPosition = Vector3.new(-477.16, 70.45, 1706.37),  lookAtHeight = 70.45 },
                { targetPosition = Vector3.new(-639.42, 3.00, 1559.84), mouseTargetPosition = Vector3.new(-548.11, 57.58, 1665.63),  lookAtHeight = 57.58 },
                { targetPosition = Vector3.new(-733.86, 3.00, 1635.17), mouseTargetPosition = Vector3.new(-217.35, 227.98, 1684.21), lookAtHeight = 227.98 }
            }
        }
    },
    yukimiya_flow = {
        skillName = "skill1",
        markerColor = Color3.fromRGB(220, 100, 20),
        requiredKey = Enum.KeyCode.One,
        flow = true,
        followUpSkill = "Tspecialer",
        followUpDelay = 0.03,
        points = { A = {}, B = {} }
    },
    karasu = {
        skillName = "skill3",
        markerColor = Color3.fromRGB(83, 76, 144),
        requiredKey = Enum.KeyCode.Three,
        points = {
            A = {
                { targetPosition = Vector3.new(-620.06, 3.00, 983.84), mouseTargetPosition = Vector3.new(-596.78, 50.04, 841.19), lookAtHeight = 50.04 },
                { targetPosition = Vector3.new(-537.49, 3.00, 993.53), mouseTargetPosition = Vector3.new(-547.38, 38.36, 881.58), lookAtHeight = 38.36 },
                { targetPosition = Vector3.new(-473.51, 3.00, 979.64), mouseTargetPosition = Vector3.new(-605.95, 50.75, 841.19), lookAtHeight = 50.75 },
                { targetPosition = Vector3.new(-692.10, 3.00, 866.55), mouseTargetPosition = Vector3.new(-641.60, 20.01, 841.19), lookAtHeight = 20.01 }
            },
            B = {
                { targetPosition = Vector3.new(-471.45, 3.00, 1561.91), mouseTargetPosition = Vector3.new(-504.11, 27.39, 1680.83), lookAtHeight = 27.39 },
                { targetPosition = Vector3.new(-535.48, 3.00, 1550.53), mouseTargetPosition = Vector3.new(-524.41, 37.11, 1665.63), lookAtHeight = 37.11 },
                { targetPosition = Vector3.new(-629.86, 3.00, 1574.08), mouseTargetPosition = Vector3.new(-548.73, 41.61, 1665.63), lookAtHeight = 41.61 },
                { targetPosition = Vector3.new(-381.09, 3.00, 1674.72), mouseTargetPosition = Vector3.new(-443.28, 24.78, 1706.58), lookAtHeight = 24.78 }
            }
        }
    },
    isagi = { skillName = "skill1", markerColor = Color3.fromRGB(157, 227, 86), requiredKey = Enum.KeyCode.One, points = { A = {}, B = {} } },
    barou = { skillName = "skill2", markerColor = Color3.fromRGB(120, 2, 2), requiredKey = Enum.KeyCode.Two, points = { A = {}, B = {} } },
    barou_curve = { skillName = "skill2", followUpSkill = "Tspecialer", markerColor = Color3.fromRGB(255, 0, 0), requiredKey = Enum.KeyCode.Two, points = { A = {}, B = {} } },
    bachira = { skillName = "skill3", markerColor = Color3.fromRGB(232, 220, 116), requiredKey = Enum.KeyCode.Three, points = { A = {}, B = {} } },
    kunigami = { skillName = "skill2", markerColor = Color3.fromRGB(255, 102, 0), requiredKey = Enum.KeyCode.Two, points = { A = {}, B = {} } },
    nelisagi = { skillName = "skill1", markerColor = Color3.fromRGB(37, 102, 245), requiredKey = Enum.KeyCode.One, points = { A = {}, B = {} } },
    otoya = { skillName = "skill1", markerColor = Color3.fromRGB(135, 195, 124), requiredKey = Enum.KeyCode.One, points = { A = {}, B = {} } },
    kiyora = { skillName = "skill1", markerColor = Color3.fromRGB(0, 85, 127), requiredKey = Enum.KeyCode.One, points = { A = {}, B = {} } },
    kiyora_strong = { skillName = "skill1", followUpSkill = "Tspecialer", followUpDelay = 0.03, markerColor = Color3.fromRGB(0, 140, 210), requiredKey = Enum.KeyCode.One, points = { A = {}, B = {} } },
    shidou = { skillName = "skill2", followUpSkill = "Tspecialer", followUpDelay = 0.03, markerColor = Color3.fromRGB(242, 85, 139), requiredKey = Enum.KeyCode.Two, points = { A = {}, B = {} } },
}

function AutoLineUps.GetTeam()
    local chars = Workspace:FindFirstChild("characters")
    local my = chars and chars:FindFirstChild(Player.Name)
    local st = my and my:FindFirstChild("state")
    local t = st and st:FindFirstChild("team")
    return t and t.Value or nil
end

function AutoLineUps.GetStyle()
    if SecretAwakening and SecretAwakening.Active and tick() < SecretAwakening.ExpiresAt then
        return "rin"
    end
    local s = Player:GetAttribute("style")
    if s == "masterykaiser" then s = "kaiser" end
    return s
end

function AutoLineUps.GetFlow()
    local chars = Workspace:FindFirstChild("characters")
    local my = chars and chars:FindFirstChild(Player.Name)
    local st = my and my:FindFirstChild("state")
    return st and st:FindFirstChild("flow")
end

function AutoLineUps.UpdateFlowState()
    if SecretAwakening and SecretAwakening.Active and tick() < SecretAwakening.ExpiresAt then
        AutoLineUps.FlowState.HasFlow = true
        AutoLineUps.FlowState.WasAbove100 = true
        return
    end
    local flowObj = AutoLineUps.GetFlow()
    if not flowObj then
        AutoLineUps.FlowState.HasFlow = false
        AutoLineUps.FlowState.WasAbove100 = false
        AutoLineUps.FlowState.LastFlowValue = 0
        AutoLineUps.ReoFlowUsedThisCycle = false
        return
    end
    local value = tonumber(flowObj.Value) or 0
    local isDraining = AutoLineUps.FlowState.LastFlowValue > 0 and value < AutoLineUps.FlowState.LastFlowValue and
        value > 0 and value < 100
    local isGlobalActive = GlobalFlowTracker and GlobalFlowTracker.IsActive
    local isLastAwk = false
    pcall(function()
        local folder = ReplicatedStorage:FindFirstChild("workspace")
        local lastAwaken = folder and folder:FindFirstChild("lastAwaken")
        local val = lastAwaken and lastAwaken.Value
        isLastAwk = (val == Player or val == Player.Name or (typeof(val) == "Instance" and val.Name == Player.Name))
    end)

    if value >= 100 then
        AutoLineUps.FlowState.WasAbove100 = true
        AutoLineUps.FlowState.HasFlow = false
        AutoLineUps.ReoFlowUsedThisCycle = false
    elseif (value < 100 and AutoLineUps.FlowState.WasAbove100) or isDraining or (isGlobalActive and value > 0) or (isLastAwk and value > 0) then
        AutoLineUps.FlowState.WasAbove100 = true
        AutoLineUps.FlowState.HasFlow = true
    end
    if value <= 0 then
        AutoLineUps.FlowState.WasAbove100 = false
        AutoLineUps.FlowState.HasFlow = false
        AutoLineUps.ReoFlowUsedThisCycle = false
    end
    AutoLineUps.FlowState.LastFlowValue = value
end

task.spawn(function()
    while true do
        task.wait(0.05)
        pcall(AutoLineUps.UpdateFlowState)
    end
end)

function AutoLineUps.HasEnemyNearby(radius)
    local char = Player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local myTeam = AutoLineUps.GetTeam()
    if not myTeam then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local oc = p.Character
            if oc then
                local ohrp = oc:FindFirstChild("HumanoidRootPart")
                if ohrp then
                    local ot = GetTeam(p.Name)
                    if ot and ot ~= myTeam and ot ~= "lobby" then
                        if (hrp.Position - ohrp.Position).Magnitude <= radius then return true end
                    end
                end
            end
        end
    end
    return false
end

function AutoLineUps.IsSkillOnCooldown(skillName)
    return IsSkillOnCooldown(skillName)
end

function AutoLineUps.IsNoFreeze()
    return AutoLineUps.Config.noFreeze == true or AutoLineUps.Config.useFreeze == false
end

function AutoLineUps.GroundPosition(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = Player.Character and { Player.Character } or {}
    local hit = Workspace:Raycast(pos + Vector3.new(0, 15, 0), Vector3.new(0, -80, 0), params)
    if hit then return hit.Position + Vector3.new(0, 0.04, 0) end
    return Vector3.new(pos.X, pos.Y - 2.95, pos.Z)
end

function AutoLineUps.SetMarkerColor(marker, color)
    if marker:IsA("BasePart") then
        marker.Color = color
        return
    end
    for _, v in ipairs(marker:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Color = color
        elseif v:IsA("Frame") then
            v.BackgroundColor3 = color
        elseif v:IsA("UIStroke") then
            v.Color = color:Lerp(Color3.new(1, 1, 1), 0.45)
        end
    end
end

function AutoLineUps.GetMarkerPosition(marker)
    if marker:IsA("BasePart") then return marker.Position end
    return Vector3.new(marker:GetAttribute("TargetX") or 0, marker:GetAttribute("TargetY") or 3,
        marker:GetAttribute("TargetZ") or 0)
end

function AutoLineUps.CreateMarker(pos, color, index)
    local marker = Instance.new("Part")
    marker.Name = "LineUpMarker_" .. index
    marker.Size = AutoLineUps.Config.markerSize
    marker.Shape = Enum.PartType.Cylinder
    marker.Material = Enum.Material.Neon
    marker.Color = color
    marker.Anchored = true
    marker.CanCollide = false
    marker.CastShadow = false

    local groundPos = AutoLineUps.GroundPosition(pos)
    marker.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
    marker.Transparency = 0.5
    marker:SetAttribute("BaseColor", color)
    marker.Parent = Workspace
    return marker
end

function AutoLineUps.CreateMarkers()
    for _, m in pairs(AutoLineUps.Markers) do if m and m.Parent then m:Destroy() end end
    AutoLineUps.Markers = {}
    AutoLineUps.NewMarkerElements = {}
    local style = AutoLineUps.GetStyle()
    local team = AutoLineUps.GetTeam()
    if not style or not team then return end

    if LineUpCreator and LineUpCreator.CustomLineUps then
        for _, lineup in ipairs(LineUpCreator.CustomLineUps) do
            local styleName = lineup.style
            if lineup.isFlow and not string.find(styleName, "_flow$") then styleName = styleName .. "_flow" end
            local cfg = AutoLineUps.StylesConfig[styleName]
            if cfg and cfg.points[lineup.team] then
                local exists = false
                for _, pt in ipairs(cfg.points[lineup.team]) do
                    if pt.isCustom and math.abs(pt.targetPosition.X - lineup.targetPosition.X) < 2 and math.abs(pt.targetPosition.Z - lineup.targetPosition.Z) < 2 then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(cfg.points[lineup.team], {
                        targetPosition = Vector3.new(lineup.targetPosition.X, lineup.targetPosition.Y,
                            lineup.targetPosition.Z),
                        mouseTargetPosition = Vector3.new(lineup.mouseTargetPosition.X, lineup.mouseTargetPosition.Y,
                            lineup.mouseTargetPosition.Z),
                        lookAtHeight = lineup.mouseTargetPosition.Y,
                        isCustom = true,
                    })
                end
            end
        end
    end

    local configsToUse = {}
    local isReo = style == "reo"

    if isReo then
        local skill4Name = AutoLineUps.GetReoSkill4Name()
        AutoLineUps.CurrentReoSkill = skill4Name
        local mappedStyle = skill4Name and AutoLineUps.ReoSkillMapping[skill4Name]
        if mappedStyle then
            local cfg = AutoLineUps.StylesConfig[mappedStyle]
            if cfg and cfg.points[team] then
                local shouldShow = true
                if cfg.flow then shouldShow = AutoLineUps.FlowState.HasFlow end
                if shouldShow then table.insert(configsToUse, { config = cfg, name = mappedStyle, isReo = true }) end
            end
        end
    else
        local flowCfgName = style .. "_flow"
        local flowCfg = AutoLineUps.StylesConfig[flowCfgName]
        local hasFlow = AutoLineUps.FlowState.HasFlow
        local hasFlowCfg = flowCfg and flowCfg.flow and flowCfg.points and flowCfg.points[team]
        local shouldDisableRegular = AutoLineUps.Config.disableRegularInFlow and hasFlow and hasFlowCfg

        if not shouldDisableRegular then
            local cfg = AutoLineUps.StylesConfig[style]
            if cfg and cfg.points[team] and not cfg.flow then
                table.insert(configsToUse, { config = cfg, name = style, isReo = false })
            end
            local curveCfgName = style .. "_curve"
            local curveCfg = AutoLineUps.StylesConfig[curveCfgName]
            if curveCfg and curveCfg.points[team] and not curveCfg.flow then
                table.insert(configsToUse, { config = curveCfg, name = curveCfgName, isReo = false })
            end
            local strongCfgName = style .. "_strong"
            local strongCfg = AutoLineUps.StylesConfig[strongCfgName]
            if strongCfg and strongCfg.points[team] and not strongCfg.flow then
                table.insert(configsToUse, { config = strongCfg, name = strongCfgName, isReo = false })
            end
        end

        if flowCfg and flowCfg.points[team] and flowCfg.flow and hasFlow then
            table.insert(configsToUse, { config = flowCfg, name = flowCfgName, isReo = false })
        end
    end

    local markerIndex = 1
    for _, cfgData in ipairs(configsToUse) do
        local c = cfgData.config
        local color = cfgData.isReo and AutoLineUps.ReoMarkerColor or c.markerColor
        for _, pt in ipairs(c.points[team]) do
            if not AutoLineUps.Config.disableBasicLineups or pt.isCustom then
                local marker = AutoLineUps.CreateMarker(pt.targetPosition, color, markerIndex)
                AutoLineUps.Markers[markerIndex] = marker
                markerIndex = markerIndex + 1
            end
        end
    end
end

function AutoLineUps.GetActivePoint()
    local char = Player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum then return nil end

    local ignoredAnims = {
        ["88690614253524"] = true,
        ["98170073378390"] = true,
        ["132649884321052"] = true,
        ["139469489709120"] = true,
        ["133198924811958"] = true,
        ["93881520867340"] = true,
        ["127318371971354"] = true,
    }
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local animId = track.Animation and tostring(track.Animation.AnimationId)
        if animId then
            local idNum = animId:match("rbxassetid://(%d+)") or animId:match("://(%d+)") or animId:match("^(%d+)$")
            if idNum and ignoredAnims[idNum] then return nil end
        end
    end
    local style = AutoLineUps.GetStyle()
    local team = AutoLineUps.GetTeam()
    if not style or not team then return nil end

    local configsToCheck = {}
    local isReo = style == "reo"

    if isReo then
        local skill4Name = AutoLineUps.GetReoSkill4Name()
        local mappedStyle = skill4Name and AutoLineUps.ReoSkillMapping[skill4Name]
        if mappedStyle then
            local cfg = AutoLineUps.StylesConfig[mappedStyle]
            if cfg and cfg.points[team] then
                table.insert(configsToCheck,
                    {
                        skillName = "skill4",
                        points = cfg.points,
                        flow = cfg.flow,
                        isReo = true,
                        isReoFlow = false,
                        markerColor =
                            cfg.markerColor,
                        noEnemyRadius = cfg.noEnemyRadius,
                        requireEnemyRadius = cfg.requireEnemyRadius
                    })
            end
        end
    else
        local flowCfg = AutoLineUps.StylesConfig[style .. "_flow"]
        local hasFlow = AutoLineUps.FlowState.HasFlow
        local hasFlowCfg = flowCfg and flowCfg.flow and flowCfg.points and flowCfg.points[team]
        local shouldDisableRegular = AutoLineUps.Config.disableRegularInFlow and hasFlow and hasFlowCfg

        if not shouldDisableRegular then
            local cfg = AutoLineUps.StylesConfig[style]
            if cfg and cfg.points[team] and not cfg.flow then table.insert(configsToCheck, cfg) end
            local curveCfg = AutoLineUps.StylesConfig[style .. "_curve"]
            if curveCfg and curveCfg.points[team] and not curveCfg.flow then table.insert(configsToCheck, curveCfg) end
            local strongCfg = AutoLineUps.StylesConfig[style .. "_strong"]
            if strongCfg and strongCfg.points[team] and not strongCfg.flow then table.insert(configsToCheck, strongCfg) end
        end

        if flowCfg and flowCfg.points[team] and flowCfg.flow and hasFlow then
            if flowCfg.noEnemyRadius then
                if not AutoLineUps.HasEnemyNearby(flowCfg.noEnemyRadius) then table.insert(configsToCheck, flowCfg) end
            elseif flowCfg.requireEnemyRadius then
                if AutoLineUps.HasEnemyNearby(flowCfg.requireEnemyRadius) then table.insert(configsToCheck, flowCfg) end
            else
                table.insert(configsToCheck, flowCfg)
            end
        end
    end

    local isNewMode = AutoLineUps.Config.mode == "New"
    local markerRadius = (AutoLineUps.Config.markerSize and AutoLineUps.Config.markerSize.Y / 2) or 4.0
    local triggerRadius = isNewMode and math.max(5.5, markerRadius + 1.5) or
        (AutoLineUps.Config.positionTolerance or 3.5)
    local bestPt, bestCfg = nil, nil
    local bestDist = triggerRadius
    local hrpPos = hrp.Position

    for _, c in ipairs(configsToCheck) do
        for _, pt in ipairs(c.points[team]) do
            if not AutoLineUps.Config.disableBasicLineups or pt.isCustom then
                local hDist = math.sqrt((hrpPos.X - pt.targetPosition.X) ^ 2 + (hrpPos.Z - pt.targetPosition.Z) ^ 2)
                local vDist = math.abs(hrpPos.Y - pt.targetPosition.Y)
                if hDist <= bestDist and vDist <= 6 then
                    bestDist = hDist
                    bestPt = pt
                    bestCfg = c
                end
            end
        end
    end

    if AutoLineUps.CurrentPoint and bestPt and bestPt ~= AutoLineUps.CurrentPoint then
        local curHDist = math.sqrt((hrpPos.X - AutoLineUps.CurrentPoint.targetPosition.X) ^ 2 +
            (hrpPos.Z - AutoLineUps.CurrentPoint.targetPosition.Z) ^ 2)
        local curVDist = math.abs(hrpPos.Y - AutoLineUps.CurrentPoint.targetPosition.Y)
        if curHDist <= triggerRadius and curVDist <= 6 and (curHDist - bestDist) < 0.6 then
            for _, c in ipairs(configsToCheck) do
                for _, pt in ipairs(c.points[team]) do
                    if pt == AutoLineUps.CurrentPoint then
                        return pt, c
                    end
                end
            end
        end
    end

    return bestPt, bestCfg
end

function AutoLineUps.IsDashing()
    if MoveBuff and MoveBuff.ActiveDashes and #MoveBuff.ActiveDashes > 0 then
        return true
    end
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local dashAnims = {
            ["79394729551302"] = true,
            ["114016332539655"] = true,
            ["100207093237932"] = true,
            ["133945265328817"] = true,
            ["88448030655006"] = true,
        }
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local animId = track.Animation and tostring(track.Animation.AnimationId)
            if animId then
                local idNum = animId:match("rbxassetid://(%d+)") or animId:match("://(%d+)") or animId:match("^(%d+)$")
                if idNum and dashAnims[idNum] then
                    return true
                end
            end
        end
    end
    return false
end

function AutoLineUps.LockCharacter()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum then
        AutoLineUps.OriginalWalkSpeed = hum.WalkSpeed
        AutoLineUps.OriginalJumpPower = hum.JumpPower
        AutoLineUps.OriginalAutoRotate = hum.AutoRotate

        if not AutoLineUps.IsNoFreeze() then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.AutoRotate = false
            if hrp then
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hrp.Velocity = Vector3.zero
                    hrp.RotVelocity = Vector3.zero
                end)
            end
            AutoLineUps.Frozen = true
        end
    end
    if not AutoLineUps.IsNoFreeze() and MoveBuff and MoveBuff.StopAll then
        MoveBuff.StopAll()
    end
end

function AutoLineUps.UnlockCharacter()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if AutoLineUps.Frozen then
        if hum then
            hum.WalkSpeed = AutoLineUps.OriginalWalkSpeed or 16
            hum.JumpPower = AutoLineUps.OriginalJumpPower or 50
            if AutoLineUps.OriginalAutoRotate ~= nil then
                hum.AutoRotate = AutoLineUps.OriginalAutoRotate
            else
                hum.AutoRotate = true
            end
            hum.PlatformStand = false
        end
        if hrp then hrp.Anchored = false end
        AutoLineUps.Frozen = false
    end
end

function AutoLineUps.SnapCamera(pt)
    local cam = Workspace.CurrentCamera
    if not cam or not pt then return end
    local targetLook = Vector3.new(pt.mouseTargetPosition.X, pt.lookAtHeight, pt.mouseTargetPosition.Z)
    local localLookVector = pt.lookVector
    local cp = cam.CFrame.Position
    cam.CFrame = localLookVector and CFrame.lookAt(cp, cp + localLookVector) or CFrame.lookAt(cp, targetLook)
end

local function IsSpecialFlowLineup(cfg, pt)
    if not cfg and not pt then return false end
    if cfg then
        if cfg.style == "rin_flow" or cfg.style == "yukimiya_flow" then return true end
        if cfg == AutoLineUps.StylesConfig.rin_flow or cfg == AutoLineUps.StylesConfig.yukimiya_flow then return true end
        if cfg.isReoFlow then return true end
        if cfg.flow then
            local st = AutoLineUps.GetStyle()
            if st == "rin" or st == "yukimiya" or AutoLineUps.CurrentReoSkill == "Kill." then return true end
        end
    end
    if pt then
        if pt.style == "rin_flow" or pt.style == "yukimiya_flow" then return true end
    end
    return false
end

function AutoLineUps.AimCamera(pt, cfg)
    local cam = Workspace.CurrentCamera
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not AutoLineUps.MouseLocked then
        local currentSens = UserInputService.MouseDeltaSensitivity
        if currentSens and currentSens > 0 then
            AutoLineUps.OriginalMouseDelta = currentSens
        else
            AutoLineUps.OriginalMouseDelta = 1
        end
    end
    UserInputService.MouseDeltaSensitivity = 0
    AutoLineUps.MouseLocked = true

    local targetLook = Vector3.new(pt.mouseTargetPosition.X, pt.lookAtHeight, pt.mouseTargetPosition.Z)
    local localLookVector = pt.lookVector

    if AutoLineUps.Config.useAccuracy and AutoLineUps.Config.accuracy < 100 then
        local missChance = 100 - AutoLineUps.Config.accuracy
        if math.random(1, 100) <= missChance then
            local maxOffset = (missChance / 50) * 15
            local offsetX = (math.random() - 0.5) * 2 * maxOffset
            local offsetZ = (math.random() - 0.5) * 2 * maxOffset
            targetLook = targetLook + Vector3.new(offsetX, 0, offsetZ)

            if localLookVector then
                local angle = math.rad((math.random() - 0.5) * 2 * (missChance / 2.5))
                localLookVector = CFrame.Angles(0, angle, 0) * localLookVector
            end
        end
    end

    local isSpecialFlow = IsSpecialFlowLineup(cfg, pt)
    local currentAimTime
    if isSpecialFlow then
        currentAimTime = 0.25
    else
        currentAimTime = AutoLineUps.Config.smoothAiming and AutoLineUps.Config.smoothness or
            AutoLineUps.Config.aimTime
    end

    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local startTime = tick()
    local startLookDir = cam.CFrame.LookVector
    local camPos = cam.CFrame.Position
    local targetLookDir = localLookVector and localLookVector.Unit or (targetLook - camPos).Unit

    local hrpLook = hrp.CFrame.LookVector
    local startHDir = Vector3.new(hrpLook.X, 0, hrpLook.Z).Unit
    if startHDir.Magnitude == 0 then startHDir = Vector3.new(startLookDir.X, 0, startLookDir.Z).Unit end
    if startHDir.Magnitude == 0 then startHDir = Vector3.new(0, 0, -1) end

    local targetHDir = Vector3.new(targetLookDir.X, 0, targetLookDir.Z).Unit
    if targetHDir.Magnitude == 0 then targetHDir = Vector3.new(0, 0, -1) end

    local startCamRot = CFrame.lookAt(Vector3.zero, startLookDir)
    local targetCamRot = CFrame.lookAt(Vector3.zero, targetLookDir)
    local startBodyRot = CFrame.lookAt(Vector3.zero, startHDir)
    local targetBodyRot = CFrame.lookAt(Vector3.zero, targetHDir)

    if AutoLineUps.HoldAimConn then pcall(function() AutoLineUps.HoldAimConn:Disconnect() end) end
    AutoLineUps.HoldAimConn = RunService.RenderStepped:Connect(function()
        if not AutoLineUps.IsExecuting or shared.CancelAutoLineUps then return end
        local c = Player.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not AutoLineUps.IsNoFreeze() and hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.AutoRotate = false
        end
        if root and not AutoLineUps.IsNoFreeze() then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.Velocity = Vector3.zero
                root.RotVelocity = Vector3.zero
            end)
        end

        local elapsed = tick() - startTime
        local alpha = (currentAimTime <= 0.02) and 1 or math.clamp(elapsed / currentAimTime, 0, 1)
        local easedAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

        local curCamRot = (alpha >= 1) and targetCamRot or startCamRot:Lerp(targetCamRot, easedAlpha)
        if cam then
            local cp = cam.CFrame.Position
            cam.CFrame = CFrame.lookAt(cp, cp + curCamRot.LookVector)
        end

        if root then
            local curBodyRot = (alpha >= 1) and targetBodyRot or startBodyRot:Lerp(targetBodyRot, easedAlpha)
            local curH = curBodyRot.LookVector
            local rpos = not AutoLineUps.IsNoFreeze() and pt.targetPosition or root.Position
            if curH.Magnitude > 0 then
                root.CFrame = CFrame.lookAt(rpos, rpos + curH)
            end
        end

        BN_SendClientCFrame()
    end)

    if currentAimTime > 0.02 then
        while (tick() - startTime) < currentAimTime do
            if shared.CancelAutoLineUps then break end
            task.wait()
        end
    end
end

function AutoLineUps.UnlockMouse()
    if not AutoLineUps.MouseLocked then
        if UserInputService.MouseDeltaSensitivity <= 0 then
            local fallback = (AutoLineUps.OriginalMouseDelta and AutoLineUps.OriginalMouseDelta > 0) and
                AutoLineUps.OriginalMouseDelta or 1
            UserInputService.MouseDeltaSensitivity = fallback
        end
        return
    end
    local sens = AutoLineUps.OriginalMouseDelta
    if not sens or sens <= 0 then sens = 1 end
    UserInputService.MouseDeltaSensitivity = sens
    AutoLineUps.MouseLocked = false
end

function AutoLineUps.PerformAction(cfg)
    local function executeSkillTrigger(name, key, isHold)
        local byteNet = ReplicatedStorage:FindFirstChild("ByteNetReliable")
        if byteNet then
            pcall(function() byteNet:FireServer(BN_UseBuffer(), { { name, isHold == true } }) end)
            pcall(function() byteNet:FireServer(BN_UseBuffer(), { { name } }) end)
        end

        pcall(function()
            local packets = NET and NET.GetPackets and NET.GetPackets()
            if packets and packets.bytenet_use and packets.bytenet_use.send then
                packets.bytenet_use.send({ name, isHold == true })
            end
        end)

        pcall(function()
            local gui = Player:FindFirstChild("PlayerGui")
            local hb = gui and gui:FindFirstChild("Hotbar")
            local bp = hb and hb:FindFirstChild("Backpack")
            local hf = bp and bp:FindFirstChild("Hotbar")
            local btn = hf and hf:FindFirstChild(name)
            local base = btn and btn:FindFirstChild("Base")
            if base and firesignal then
                pcall(function() firesignal(base.MouseButton1Click) end)
                pcall(function() firesignal(base.Activated) end)
            end
        end)

        local baseClient = nil
        if shared and shared.metatable then baseClient = shared.metatable.baseClient end
        if not baseClient and getgenv then
            for _, v in pairs(getgenv()) do
                if type(v) == "table" and v.baseClient and v.baseClient.use then
                    baseClient = v.baseClient
                    break
                end
            end
        end
        if baseClient then
            pcall(function() baseClient:use(name, isHold == true) end)
        end

        if not UserInputService.TouchEnabled then
            if key and typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
                pcall(function()
                    local VIM = game:GetService("VirtualInputManager")
                    if VIM then
                        VIM:SendKeyEvent(true, key, false, game)
                        task.delay(0.04, function()
                            pcall(function() VIM:SendKeyEvent(false, key, false, game) end)
                        end)
                    end
                end)
            end
        end
    end

    if cfg.followUpSkill then
        if AutoLineUps.IsSkillOnCooldown(cfg.skillName) or AutoLineUps.IsSkillOnCooldown(cfg.followUpSkill) then
            return false
        end
        local delayAmount = cfg.followUpDelay or 0.1

        BN_SendClientCFrame()
        executeSkillTrigger(cfg.skillName, cfg.requiredKey, false)
        task.wait(delayAmount)
        BN_SendClientCFrame()
        if cfg.followUpSkill == "Tspecialer" then
            executeSkillTrigger("Tspecialer", Enum.KeyCode.T, true)
        else
            executeSkillTrigger(cfg.followUpSkill, nil, false)
        end
        return true
    end

    local startTime = tick()
    local cooldownDetected = false
    while tick() - startTime < 1.0 do
        if shared.CancelAutoLineUps then return false end
        BN_SendClientCFrame()
        executeSkillTrigger(cfg.skillName, cfg.requiredKey, false)
        if AutoLineUps.IsSkillOnCooldown(cfg.skillName) then
            cooldownDetected = true
            break
        end
        task.wait(0.04)
    end
    return cooldownDetected
end

local function StopAssistWalk()
    if AutoLineUps.IsAssistingWalk then
        local c = Player.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if r then
            pcall(function()
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        if h then pcall(function() h:Move(Vector3.zero, false) end) end
        AutoLineUps.IsAssistingWalk = false
    end
    AutoLineUps.AssistStartTime = nil
end

function AutoLineUps.SafeRestore()
    StopAssistWalk()
    if AutoLineUps.HoldAimConn then
        pcall(function() AutoLineUps.HoldAimConn:Disconnect() end)
        AutoLineUps.HoldAimConn = nil
    end
    local cam = Workspace.CurrentCamera
    if cam and AutoLineUps.OriginalCameraType then
        cam.CameraType = AutoLineUps.OriginalCameraType
        AutoLineUps.OriginalCameraType = nil
    elseif cam and cam.CameraType == Enum.CameraType.Scriptable then
        cam.CameraType = Enum.CameraType.Custom
    end
    AutoLineUps.UnlockMouse()
    AutoLineUps.UnlockCharacter()
    AutoLineUps.IsExecuting = false
    shared.CancelAutoLineUps = false
end

function AutoLineUps.IsHoldKeyActive()
    if not AutoLineUps.Config.holdToUse then return true end
    if AutoLineUps.IsHoldingKey then return true end
    local boundKey = AutoLineUps.HoldKeybind and AutoLineUps.HoldKeybind.Key or AutoLineUps.Config.holdKey
    if boundKey and boundKey ~= Enum.KeyCode.Unknown then
        if typeof(boundKey) == "EnumItem" and boundKey.EnumType == Enum.KeyCode then
            if UserInputService:IsKeyDown(boundKey) then return true end
        elseif typeof(boundKey) == "EnumItem" and boundKey.EnumType == Enum.UserInputType then
            if UserInputService:IsMouseButtonPressed(boundKey) then return true end
        end
    end
    return false
end

function AutoLineUps.Execute(dt)
    if not AutoLineUps.IsHoldKeyActive() then
        StopAssistWalk()
        if AutoLineUps.CurrentPoint then
            AutoLineUps.CurrentPoint = nil
            shared.CancelAutoLineUps = true
            AutoLineUps.SafeRestore()
        end
        return
    end

    if not HasBall() then
        StopAssistWalk()
        if AutoLineUps.CurrentPoint then
            AutoLineUps.CurrentPoint = nil
            shared.CancelAutoLineUps = true
            AutoLineUps.SafeRestore()
        end
        return
    end

    local pt, cfg = AutoLineUps.GetActivePoint()
    if not pt or not cfg then
        StopAssistWalk()
        if AutoLineUps.CurrentPoint then
            AutoLineUps.CurrentPoint = nil
            shared.CancelAutoLineUps = true
            AutoLineUps.SafeRestore()
        end
        return
    end

    if AutoLineUps.IsSkillOnCooldown(cfg.skillName) then
        StopAssistWalk()
        return
    end
    if cfg.followUpSkill and AutoLineUps.IsSkillOnCooldown(cfg.followUpSkill) then
        StopAssistWalk()
        return
    end

    local isNewMode = AutoLineUps.Config.mode == "New"
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrpPos = hrp and hrp.Position
    local hDist = hrpPos and math.sqrt((hrpPos.X - pt.targetPosition.X) ^ 2 + (hrpPos.Z - pt.targetPosition.Z) ^ 2) or
        999

    if not AutoLineUps.IsNoFreeze() and isNewMode then
        if AutoLineUps.IsDashing() then
            StopAssistWalk()
            return
        end

        local exactTol = 1.2
        AutoLineUps.AssistStartTime = AutoLineUps.AssistStartTime or tick()
        local assistDuration = tick() - AutoLineUps.AssistStartTime

        if hDist > exactTol and assistDuration < 0.35 then
            if hrp and hum and hrpPos then
                local walkDir = Vector3.new(pt.targetPosition.X - hrpPos.X, 0, pt.targetPosition.Z - hrpPos.Z).Unit
                if walkDir.Magnitude > 0 then
                    local baseSpeed = (hum.WalkSpeed and hum.WalkSpeed > 0) and hum.WalkSpeed or 16
                    local assistSpeed = math.max(baseSpeed, 22)
                    local actualDt = (typeof(dt) == "number" and dt > 0 and dt < 0.1) and dt or 0.016
                    local step = math.min(assistSpeed * actualDt, hDist)

                    hrp.AssemblyLinearVelocity = Vector3.new(walkDir.X * assistSpeed, hrp.AssemblyLinearVelocity.Y,
                        walkDir.Z * assistSpeed)

                    local newX = hrpPos.X + walkDir.X * step
                    local newZ = hrpPos.Z + walkDir.Z * step
                    local targetCF = CFrame.lookAt(Vector3.new(newX, hrpPos.Y, newZ),
                        Vector3.new(newX + walkDir.X, hrpPos.Y, newZ + walkDir.Z))
                    hrp.CFrame = hrp.CFrame:Lerp(targetCF, math.clamp(actualDt * 12, 0.15, 0.5))

                    pcall(function() hum:Move(walkDir, false) end)
                    AutoLineUps.IsAssistingWalk = true
                end
            end
            return
        else
            StopAssistWalk()
        end
    else
        StopAssistWalk()
    end

    if AutoLineUps.IsNoFreeze() then
        if AutoLineUps.CurrentPoint ~= pt then
            shared.CancelAutoLineUps = true
            AutoLineUps.SafeRestore()
            AutoLineUps.LastExecutionTime = 0

            if not (AutoLineUps.Config.smoothAiming or IsSpecialFlowLineup(cfg, pt)) then
                AutoLineUps.SnapCamera(pt)
            end
            AutoLineUps.CurrentPoint = pt
        end
    end

    if AutoLineUps.IsExecuting then return end
    if tick() - AutoLineUps.LastExecutionTime < 0.3 then return end

    if HasMyIFrame() then
        local allowedAnims = {
            ["79394729551302"] = true,
            ["114016332539655"] = true,
            ["100207093237932"] = true,
            ["133945265328817"] = true,
            ["88448030655006"] = true,
            ["109744655458082"] = true,
            ["134609545061747"] = true,
            ["128821996857876"] = true,
            ["137180116441298"] = true,
        }
        local allowedAnimPlaying = false
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                local animId = track.Animation and tostring(track.Animation.AnimationId)
                if animId then
                    local idNum = animId:match("rbxassetid://(%d+)") or animId:match("://(%d+)") or
                        animId:match("^(%d+)$")
                    if idNum and allowedAnims[idNum] then
                        allowedAnimPlaying = true
                        break
                    end
                end
            end
        end
        if not allowedAnimPlaying then return end
    end

    local preExistingAnimIds = {}
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local animId = track.Animation and tostring(track.Animation.AnimationId)
            if animId then
                local idNum = animId:match("rbxassetid://(%d+)") or animId:match("://(%d+)") or animId:match("^(%d+)$")
                if idNum then preExistingAnimIds[idNum] = true end
            end
        end
    end

    AutoLineUps.IsExecuting = true
    shared.CancelAutoLineUps = false
    if not AutoLineUps.IsNoFreeze() and MoveBuff and MoveBuff.StopAll then
        MoveBuff.StopAll()
    end
    local isReoFlowLineup = cfg.isReoFlow

    task.spawn(function()
        local cancelAnims = {
            ["134609545061747"] = true,
            ["128821996857876"] = true,
            ["137180116441298"] = true,
        }
        while AutoLineUps.IsExecuting and not shared.CancelAutoLineUps do
            local c = Player.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then
                for _, track in ipairs(h:GetPlayingAnimationTracks()) do
                    local animId = track.Animation and tostring(track.Animation.AnimationId)
                    if animId then
                        local idNum = animId:match("rbxassetid://(%d+)") or animId:match("://(%d+)") or
                            animId:match("^(%d+)$")
                        if idNum and cancelAnims[idNum] and not preExistingAnimIds[idNum] then
                            shared.CancelAutoLineUps = true
                            break
                        end
                    end
                end
            end
            task.wait()
        end
    end)

    local success = pcall(function()
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        AutoLineUps.LockCharacter()

        if not AutoLineUps.IsNoFreeze() and hrp then
            local curLook = hrp.CFrame.LookVector
            local curH = Vector3.new(curLook.X, 0, curLook.Z).Unit
            if curH.Magnitude > 0 then
                hrp.CFrame = CFrame.lookAt(pt.targetPosition, pt.targetPosition + curH)
            else
                hrp.CFrame = CFrame.new(pt.targetPosition)
            end
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
            end)
        end

        AutoLineUps.AimCamera(pt, cfg)
        if shared.CancelAutoLineUps then return end

        local isKill = (cfg.skillName == "skill4" and (AutoLineUps.CurrentStyle == "rin" or cfg.flow or AutoLineUps.CurrentReoSkill == "Kill."))
        local isSpecialFlow = IsSpecialFlowLineup(cfg, pt)

        if isSpecialFlow and not AutoLineUps.IsNoFreeze() then
            local flowPreFreezeDuration = 0.10
            local preFreezeStart = tick()
            while (tick() - preFreezeStart) < flowPreFreezeDuration do
                if shared.CancelAutoLineUps then return end
                task.wait(0.02)
            end
        else
            for _ = 1, 3 do
                if shared.CancelAutoLineUps then return end
                task.wait()
            end
        end
        if shared.CancelAutoLineUps then return end

        local cooldownDetected = AutoLineUps.PerformAction(cfg)

        local isFlowShot = cfg.flow or isKill or cfg.skillName == "skill4"
        if isFlowShot then
            local animTrack = nil
            local detectStart = tick()
            while (tick() - detectStart) < 0.45 do
                if shared.CancelAutoLineUps then break end
                local c = Player.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local anim = hum and hum:FindFirstChildOfClass("Animator")
                local source = anim or hum
                if source then
                    for _, track in ipairs(source:GetPlayingAnimationTracks()) do
                        if track.IsPlaying then
                            local aId = track.Animation and tostring(track.Animation.AnimationId) or ""
                            local num = aId:match("(%d+)$") or aId:match("://(%d+)")
                            if num and (num == "130521968154479" or num == "79731379179063" or (LineUpCreator and LineUpCreator.SkillAnimations and LineUpCreator.SkillAnimations[num])) then
                                animTrack = track
                                break
                            end
                        end
                    end
                end
                if animTrack then break end
                BN_SendClientCFrame()
                task.wait(0.02)
            end

            local holdStart = tick()
            local maxAnimDuration = 2.6
            if animTrack then
                while animTrack.IsPlaying and (tick() - holdStart) < maxAnimDuration do
                    if shared.CancelAutoLineUps then break end
                    BN_SendClientCFrame()
                    task.wait(0.02)
                end
            else
                while (tick() - holdStart) < 1.6 do
                    if shared.CancelAutoLineUps then break end
                    BN_SendClientCFrame()
                    task.wait(0.03)
                end
            end

            local bufferStart = tick()
            while (tick() - bufferStart) < 0.1 do
                if shared.CancelAutoLineUps then break end
                BN_SendClientCFrame()
                task.wait(0.02)
            end
        elseif cooldownDetected and not AutoLineUps.IsNoFreeze() then
            local freezeTime = AutoLineUps.Config.postSuccessFreeze or 0.3
            local holdStart = tick()
            while (tick() - holdStart) < freezeTime do
                if shared.CancelAutoLineUps then break end
                BN_SendClientCFrame()
                task.wait(0.02)
            end
        end

        if AutoLineUps.HoldAimConn then
            pcall(function() AutoLineUps.HoldAimConn:Disconnect() end)
            AutoLineUps.HoldAimConn = nil
        end

        AutoLineUps.LastExecutionTime = tick()

        if isReoFlowLineup then
            AutoLineUps.ReoFlowUsedThisCycle = true
            AutoLineUps.CreateMarkers()
        end
    end)

    AutoLineUps.SafeRestore()
    if not success then AutoLineUps.SafeRestore() end
end

function AutoLineUps.Start()
    if AutoLineUps.Connection then AutoLineUps.Connection:Disconnect() end
    if AutoLineUps.AnimConnection then AutoLineUps.AnimConnection:Disconnect() end
    AutoLineUps.Enabled = true
    AutoLineUps.UpdateFlowState()
    AutoLineUps.LastFlowState = AutoLineUps.FlowState.HasFlow
    AutoLineUps.CurrentTeam = AutoLineUps.GetTeam()
    AutoLineUps.CurrentStyle = AutoLineUps.GetStyle()
    AutoLineUps.CurrentReoSkill = nil
    AutoLineUps.CurrentPoint = nil
    AutoLineUps.ReoFlowUsedThisCycle = false
    AutoLineUps.CreateMarkers()

    AutoLineUps.AnimLoopActive = true
    task.spawn(function()
        while AutoLineUps.AnimLoopActive and AutoLineUps.Enabled do
            if AutoLineUps.NewMarkerElements and #AutoLineUps.NewMarkerElements > 0 then
                local t = tick()
                local phase = (t % 2.4) / 1.2
                local alpha
                if phase < 1 then
                    alpha = -(math.cos(math.pi * phase) - 1) / 2
                else
                    alpha = -(math.cos(math.pi * (2 - phase)) - 1) / 2
                end

                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hrpPos = hrp and hrp.Position or Vector3.zero

                for _, elem in ipairs(AutoLineUps.NewMarkerElements) do
                    if elem.circle and elem.circle.Parent and elem.base and elem.base.Parent then
                        local dist = hrpPos == Vector3.zero and 0 or (hrpPos - elem.base.Position).Magnitude
                        if dist < 120 then
                            elem.circle.Size = UDim2.fromScale(0.7 + 0.18 * alpha, 0.7 + 0.18 * alpha)
                            elem.circle.BackgroundTransparency = 0.55 + 0.17 * alpha
                            elem.stroke.Thickness = 4 - 2 * alpha
                            elem.stroke.Transparency = 0.18 * alpha

                            elem.meshCore.Scale = Vector3.new(0.70 + 0.10 * alpha, 1, 0.70 + 0.10 * alpha)
                            elem.wallCore.Transparency = 0.78 + 0.08 * alpha
                            elem.meshOuter.Scale = Vector3.new(0.84 + 0.12 * alpha, 1, 0.84 + 0.12 * alpha)
                            elem.wallOuter.Transparency = 0.88 + 0.05 * alpha
                            elem.meshRing.Scale = Vector3.new(0.74 + 0.12 * alpha, 1, 0.74 + 0.12 * alpha)
                            elem.topRing.Transparency = 0.45 + 0.23 * alpha
                        end
                    end
                end
            end
            task.wait(1 / 30)
        end
    end)

    AutoLineUps.Connection = RunService.Heartbeat:Connect(function(dt)
        if not AutoLineUps.Enabled then return end
        AutoLineUps.UpdateFlowState()
        local newTeam = AutoLineUps.GetTeam()
        local newStyle = AutoLineUps.GetStyle()
        local flowChanged = AutoLineUps.FlowState.HasFlow ~= AutoLineUps.LastFlowState
        local reoSkillChanged = false
        if newStyle == "reo" then
            local newReoSkill4 = AutoLineUps.GetReoSkill4Name()
            local newReoSkill3 = AutoLineUps.GetReoSkill3Name()
            if newReoSkill4 ~= AutoLineUps.CurrentReoSkill or newReoSkill3 ~= AutoLineUps.CurrentReoSkill3 then
                reoSkillChanged = true
                AutoLineUps.CurrentReoSkill = newReoSkill4
                AutoLineUps.CurrentReoSkill3 = newReoSkill3
            end
        end
        if newTeam ~= AutoLineUps.CurrentTeam or newStyle ~= AutoLineUps.CurrentStyle or flowChanged or reoSkillChanged then
            AutoLineUps.CurrentTeam = newTeam
            AutoLineUps.CurrentStyle = newStyle
            AutoLineUps.LastFlowState = AutoLineUps.FlowState.HasFlow
            AutoLineUps.CreateMarkers()
        end
        AutoLineUps.Execute(dt)
    end)
    SafeNotify("Auto Line Ups Enabled", 2, "Enable")
end

function AutoLineUps.Stop()
    StopAssistWalk()
    AutoLineUps.Enabled = false
    AutoLineUps.AnimLoopActive = false
    if AutoLineUps.Connection then
        AutoLineUps.Connection:Disconnect()
        AutoLineUps.Connection = nil
    end
    if AutoLineUps.AnimConnection then
        AutoLineUps.AnimConnection:Disconnect()
        AutoLineUps.AnimConnection = nil
    end
    for _, m in pairs(AutoLineUps.Markers) do if m and m.Parent then m:Destroy() end end
    AutoLineUps.Markers = {}
    AutoLineUps.NewMarkerElements = {}
    AutoLineUps.CurrentPoint = nil
    AutoLineUps.SafeRestore()
    SafeNotify("Auto Line Ups Disabled", 2, "Disable")
end

AutoLineUps.Toggle = Library:CreateToggle(AutoLineUpsSection, {
    Name = "Enable",
    Default = false,
    Callback = function(v)
        if v then
            local ok, err = pcall(AutoLineUps.Start)
            if not ok then SafeNotify("Auto Line Ups error", 2) end
        else
            AutoLineUps.Stop()
        end
    end
})

Library:CreateDropdown(AutoLineUpsSection, {
    Name = "Mode",
    Options = { "Old", "New" },
    Default = AutoLineUps.Config.mode or "Old",
    Callback = function(v)
        AutoLineUps.Config.mode = v
    end
})

Library:CreateKeybind(AutoLineUpsSection, {
    Name = "Toggle Line Ups",
    Default = Enum.KeyCode.C,
    Mode = "Toggle",
    Callback = function(active)
        local t = AutoLineUps.Toggle
        if not t or not t.SetValue then return end
        if t.Value ~= active then
            t:SetValue(active and true or false)
        end
    end
})

Library:CreateToggle(AutoLineUpsSection, {
    Name = "Hold Key To Use",
    Default = false,
    Callback = function(v) AutoLineUps.Config.holdToUse = v end
})

AutoLineUps.HoldKeybind = Library:CreateKeybind(AutoLineUpsSection, {
    Name = "Hold Key",
    Default = Enum.KeyCode.H,
    Mode = "Hold",
    Callback = function(active)
        AutoLineUps.IsHoldingKey = active
    end
})

Library:CreateToggle(AutoLineUpsSection, {
    Name = "No Freeze",
    Default = false,
    Callback = function(v)
        AutoLineUps.Config.noFreeze = v
        AutoLineUps.Config.useFreeze = not v
    end
})
Library:CreateToggle(AutoLineUpsSection, {
    Name = "Smooth Aiming",
    Default = false,
    Callback = function(v) AutoLineUps.Config.smoothAiming = v end
})

Library:CreateSlider(AutoLineUpsSection, {
    Name = "Smoothness",
    Min = 0.01,
    Max = 0.5,
    Default = 0.15,
    Step = 0.01,
    Suffix = "s",
    Callback = function(v) AutoLineUps.Config.smoothness = v end
})

Library:CreateToggle(AutoLineUpsSection, {
    Name = "Use Accuracy",
    Default = false,
    Callback = function(v) AutoLineUps.Config.useAccuracy = v end
})

Library:CreateSlider(AutoLineUpsSection, {
    Name = "Accuracy",
    Min = 50,
    Max = 100,
    Default = 100,
    Step = 1,
    Suffix = "%",
    Callback = function(v) AutoLineUps.Config.accuracy = v end
})

AutoLineUps.DisableBasicToggle = Library:CreateToggle(AutoLineUpsSection, {
    Name = "Disable Basic Lineups",
    Default = AutoLineUps.Config.disableBasicLineups or false,
    Callback = function(v)
        AutoLineUps.UserChangedDisableBasic = true
        AutoLineUps.Config.disableBasicLineups = v
        if AutoLineUps.Enabled then
            AutoLineUps.CreateMarkers()
        end
    end
})

AutoLineUps.DisableRegularInFlowToggle = Library:CreateToggle(AutoLineUpsSection, {
    Name = "Disable Regular In Flow",
    Default = false,
    Callback = function(v)
        AutoLineUps.Config.disableRegularInFlow = v
        if AutoLineUps.Enabled then
            AutoLineUps.CreateMarkers()
        end
    end
})

LineUpCreator = {
    Enabled = false,
    Connection = nil,
    LatestLineUp = nil,
    CustomLineUps = {},
    ConfigPath = "EvoHubAlpha/lineups.json",
    SkillAnimations = {
        ["100709498654724"] = "kaiser",
        ["113561329577143"] = "rin",
        ["130521968154479"] = "rin_flow",
        ["102279684195373"] = "yukimiya",
        ["79731379179063"] = "yukimiya_flow",
        ["76200134398422"] = "sae",
        ["131229402549770"] = "isagi",
        ["98869531447623"] = "barou",
        ["134009712042797"] = "bachira",
        ["138598504314653"] = "kunigami",
        ["97103063277850"] = "nelisagi",
        ["105750734684772"] = "karasu",
        ["94714913486342"] = "otoya",
        ["114955963969575"] = "kiyora",
        ["106320194059952"] = "shidou",
    },
    AnimationDelays = {
        ["100709498654724"] = 0.15,
        ["113561329577143"] = 0.23,
        ["130521968154479"] = 0,
        ["102279684195373"] = 0.40,
        ["79731379179063"] = 0,
        ["76200134398422"] = 0.23,
        ["131229402549770"] = 0.28,
        ["98869531447623"] = 0.22,
        ["134009712042797"] = 0.13,
        ["138598504314653"] = 0.27,
        ["97103063277850"] = 0.25,
        ["105750734684772"] = 0.32,
        ["94714913486342"] = 0.14,
        ["114955963969575"] = 1.3,
        ["106320194059952"] = 0.5,
    },
    LastShotData = nil,
    WaitingForGoal = false,
    ShotTime = 0,
}

function LineUpCreator.LoadConfig()
    if not ExecutorCaps.Files then return end
    pcall(function()
        LineUpCreator.CustomLineUps = {}

        local function loadFile(path)
            local content = readfile(path)
            local data = HttpService:JSONDecode(content)
            if data then
                for _, lineup in ipairs(data) do
                    if lineup.style == "masterykaiser" then
                        lineup.style = "kaiser"
                    elseif lineup.style == "masterykaiser_flow" then
                        lineup.style = "kaiser_flow"
                    end

                    local isDup = false
                    for _, existing in ipairs(LineUpCreator.CustomLineUps) do
                        if existing.style == lineup.style and existing.team == lineup.team then
                            local dX = existing.targetPosition.X - lineup.targetPosition.X
                            local dY = existing.targetPosition.Y - lineup.targetPosition.Y
                            local dZ = existing.targetPosition.Z - lineup.targetPosition.Z
                            if math.sqrt(dX * dX + dY * dY + dZ * dZ) < 1 then
                                isDup = true
                                break
                            end
                        end
                    end
                    if not isDup then
                        table.insert(LineUpCreator.CustomLineUps, lineup)
                    end
                end
            end
        end

        if isfile(LineUpCreator.ConfigPath) then
            pcall(loadFile, LineUpCreator.ConfigPath)
        end

        if isfolder("EvoHubAlpha") then
            for _, file in ipairs(listfiles("EvoHubAlpha")) do
                local name = file:match("([^/\\]+)$")
                if name and name:match("^lineups.*%.json$") and file ~= LineUpCreator.ConfigPath and file ~= "EvoHubAlpha\\lineups.json" and file ~= "EvoHubAlpha/lineups.json" then
                    pcall(loadFile, file)
                end
            end
        end

        if isfile("lineups.json") then
            pcall(loadFile, "lineups.json")
        end

        LineUpCreator.ApplyCustomLineUps()

        if #LineUpCreator.CustomLineUps > 0 and not AutoLineUps.UserChangedDisableBasic then
            AutoLineUps.Config.disableBasicLineups = true
            if AutoLineUps.DisableBasicToggle and AutoLineUps.DisableBasicToggle.SetValue then
                AutoLineUps.DisableBasicToggle:SetValue(true)
            end
            if AutoLineUps.Enabled then
                AutoLineUps.CreateMarkers()
            end
        end
    end)
    task.spawn(function()
        task.wait(1)
        if LineUpCreator.RefreshDropdown then LineUpCreator.RefreshDropdown() end
    end)
end

function LineUpCreator.SaveConfig()
    if not ExecutorCaps.Files then return end
    pcall(function()
        if not isfolder("EvoHubAlpha") then makefolder("EvoHubAlpha") end
        writefile(LineUpCreator.ConfigPath, HttpService:JSONEncode(LineUpCreator.CustomLineUps))
    end)
end

function LineUpCreator.ApplyCustomLineUps()
    for _, lineup in ipairs(LineUpCreator.CustomLineUps) do
        local styleName = lineup.style
        if lineup.isFlow and not string.find(styleName, "_flow") then styleName = styleName .. "_flow" end
        local cfg = AutoLineUps.StylesConfig[styleName]
        if cfg and cfg.points[lineup.team] then
            table.insert(cfg.points[lineup.team], {
                targetPosition = Vector3.new(lineup.targetPosition.X, lineup.targetPosition.Y, lineup.targetPosition.Z),
                mouseTargetPosition = Vector3.new(lineup.mouseTargetPosition.X, lineup.mouseTargetPosition.Y,
                    lineup.mouseTargetPosition.Z),
                lookAtHeight = lineup.mouseTargetPosition.Y,
                lookVector = lineup.lookVector and
                    Vector3.new(lineup.lookVector.X, lineup.lookVector.Y, lineup.lookVector.Z) or nil,
                isCustom = true,
            })
        end
    end
end

function LineUpCreator.GetCurrentAnimationId()
    local char = Player.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil, nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return nil, nil end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.IsPlaying then
            local animId = tostring(track.Animation.AnimationId)
            local num = animId:match("(%d+)$") or animId:match("://(%d+)")
            if num and LineUpCreator.SkillAnimations[num] then
                local styleStr = LineUpCreator.SkillAnimations[num]
                if styleStr == "masterykaiser" then styleStr = "kaiser" end
                return num, styleStr
            end
        end
    end
    return nil, nil
end

function LineUpCreator.GetMouseTarget()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local char = Player.Character
    local vps = cam.ViewportSize
    local ray = cam:ViewportPointToRay(vps.X * 0.5, vps.Y * 0.5)
    local origin, dir = ray.Origin, ray.Direction.Unit
    local blacklist = {}
    if char then table.insert(blacklist, char) end
    for _ = 1, 40 do
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = blacklist
        params.IgnoreWater = true
        local result = Workspace:Raycast(origin, dir * 1000, params)
        if not result then return origin + dir * 1000 end
        if (result.Position - origin).Magnitude < 35 then
            table.insert(blacklist, result.Instance)
        else
            return result.Position
        end
    end
    return origin + dir * 35
end

function LineUpCreator.IsNearExistingLineup(position, styleName, team)
    if not position or not styleName or not team then return true end
    local cfg = AutoLineUps.StylesConfig[styleName]
    if cfg and cfg.points[team] then
        for _, pt in ipairs(cfg.points[team]) do
            if (position - pt.targetPosition).Magnitude < 5 then return true end
        end
    end
    return false
end

function LineUpCreator.CheckGoalScored()
    local gui = Player:FindFirstChild("PlayerGui")
    local stats = gui and gui:FindFirstChild("playerstatsUI")
    local frame = stats and stats:FindFirstChild("Frame")
    local img = frame and frame:FindFirstChild("ImageLabel3")
    local goname = img and img:FindFirstChild("goname")
    if not goname then return false end
    if goname.Text == Player.Name then return true end
    if NameProtect and NameProtect.Enabled and goname.Text == NameProtect.FakeName then return true end

    local folder = ReplicatedStorage:FindFirstChild("workspace")
    local lastAwaken = folder and folder:FindFirstChild("lastAwaken")
    local awkVal = lastAwaken and lastAwaken.Value
    if awkVal == Player or awkVal == Player.Name or (typeof(awkVal) == "Instance" and awkVal.Name == Player.Name) then
        return true
    end

    return false
end

function LineUpCreator.HasFlow()
    local flowObj = AutoLineUps.GetFlow()
    if not flowObj then return false end
    return AutoLineUps.FlowState.HasFlow or flowObj.Value >= 100
end

function LineUpCreator.OnShotDetected(styleName, savedPosition, savedMouseTarget, savedLookVector)
    local team = AutoLineUps.GetTeam()
    local isFlow = string.find(styleName, "_flow") ~= nil
    if not savedPosition or not savedMouseTarget or not team then return end
    if LineUpCreator.IsNearExistingLineup(savedPosition, styleName, team) then return end

    LineUpCreator.LastShotData = {
        style = styleName,
        team = team,
        isFlow = isFlow,
        targetPosition = { X = math.floor(savedPosition.X * 100) / 100, Y = 3, Z = math.floor(savedPosition.Z * 100) / 100 },
        mouseTargetPosition = { X = math.floor(savedMouseTarget.X * 100) / 100, Y = math.floor(savedMouseTarget.Y * 100) / 100, Z = math.floor(savedMouseTarget.Z * 100) / 100 },
        lookVector = savedLookVector and { X = savedLookVector.X, Y = savedLookVector.Y, Z = savedLookVector.Z } or nil,
    }
    LineUpCreator.WaitingForGoal = true
    LineUpCreator.ShotTime = tick()

    task.spawn(function()
        local myShotTime = LineUpCreator.ShotTime
        for _ = 1, 12 do
            task.wait(0.5)
            if LineUpCreator.ShotTime ~= myShotTime then return end
            if LineUpCreator.CheckGoalScored() then
                LineUpCreator.WaitingForGoal = false
                LineUpCreator.LatestLineUp = LineUpCreator.LastShotData
                SafeNotify("LineUp Creator: Goal! Press Save to keep.", 3)
                return
            end
        end
        if LineUpCreator.ShotTime == myShotTime then
            LineUpCreator.WaitingForGoal = false
        end
    end)
end

function LineUpCreator.SaveLatest()
    if not LineUpCreator.LatestLineUp then
        SafeNotify("No lineup to save!", 2)
        return
    end
    local lineup = LineUpCreator.LatestLineUp
    if lineup.isFlow and not string.find(lineup.style, "_flow") then
        lineup.style = lineup.style .. "_flow"
    end
    table.insert(LineUpCreator.CustomLineUps, lineup)
    LineUpCreator.SaveConfig()
    local cfg = AutoLineUps.StylesConfig[lineup.style]
    if cfg and cfg.points[lineup.team] then
        table.insert(cfg.points[lineup.team], {
            targetPosition = Vector3.new(lineup.targetPosition.X, lineup.targetPosition.Y, lineup.targetPosition.Z),
            mouseTargetPosition = Vector3.new(lineup.mouseTargetPosition.X, lineup.mouseTargetPosition.Y,
                lineup.mouseTargetPosition.Z),
            lookAtHeight = lineup.mouseTargetPosition.Y,
            lookVector = lineup.lookVector and Vector3.new(lineup.lookVector.X, lineup.lookVector.Y, lineup.lookVector.Z) or
                nil,
            isCustom = true,
        })
    end
    SafeNotify("LineUp saved: " .. lineup.style .. " " .. lineup.team, 3)
    if AutoLineUps.Enabled then AutoLineUps.CreateMarkers() end
    LineUpCreator.LatestLineUp = nil
    if LineUpCreator.RefreshDropdown then LineUpCreator.RefreshDropdown() end
end

function LineUpCreator.DeleteLatest()
    if LineUpCreator.LatestLineUp then
        LineUpCreator.LatestLineUp = nil
        SafeNotify("Unsaved lineup deleted", 2)
        return
    end
    if #LineUpCreator.CustomLineUps > 0 then
        local removed = table.remove(LineUpCreator.CustomLineUps)
        LineUpCreator.SaveConfig()
        local styleName = removed.style
        if removed.isFlow and not string.find(styleName, "_flow") then styleName = styleName .. "_flow" end
        local cfg = AutoLineUps.StylesConfig[styleName]
        if cfg and cfg.points[removed.team] then
            for i = #cfg.points[removed.team], 1, -1 do
                local pt = cfg.points[removed.team][i]
                if pt.isCustom and math.abs(pt.targetPosition.X - removed.targetPosition.X) < 2 and math.abs(pt.targetPosition.Z - removed.targetPosition.Z) < 2 then
                    table.remove(cfg.points[removed.team], i)
                    break
                end
            end
        end
        AutoLineUps.CreateMarkers()
        if LineUpCreator.RefreshDropdown then LineUpCreator.RefreshDropdown() end
        SafeNotify("Last lineup deleted: " .. removed.style .. " " .. removed.team, 2)
        return
    end
    SafeNotify("No lineups to delete!", 2)
end

function LineUpCreator.IsTspecialerOnCooldown()
    return IsSkillOnCooldown("Tspecialer")
end

function LineUpCreator.Start()
    if LineUpCreator.Connection then LineUpCreator.Connection:Disconnect() end
    LineUpCreator.Enabled = true
    local hadBall = HasBall()
    local lastAnimId, lastAnimStyle = nil, nil
    local savedPosition, savedMouseTarget, savedLookVector = nil, nil, nil
    local animStartTime, coordsSaved = 0, false
    local lastGoodTarget, lastGoodLookVector, lastGoodPosition = nil, nil, nil
    local kiyoraStrongSoundDetected = false
    local soundConns = {}

    local function hookHRP(hrp)
        for _, c in ipairs(soundConns) do pcall(function() c:Disconnect() end) end
        table.clear(soundConns)
        if not hrp then return end
        local function checkSound(s)
            if s:IsA("Sound") then
                local sid = tostring(s.SoundId or "")
                if sid:find("133444704350985") then
                    kiyoraStrongSoundDetected = true
                    local pConn = s.Played:Connect(function()
                        kiyoraStrongSoundDetected = true
                    end)
                    local propConn = s:GetPropertyChangedSignal("IsPlaying"):Connect(function()
                        if s.IsPlaying then kiyoraStrongSoundDetected = true end
                    end)
                    table.insert(soundConns, pConn)
                    table.insert(soundConns, propConn)
                end
            end
        end
        for _, s in ipairs(hrp:GetChildren()) do checkSound(s) end
        local cAdded = hrp.ChildAdded:Connect(checkSound)
        table.insert(soundConns, cAdded)
    end

    LineUpCreator.SoundConns = soundConns
    LineUpCreator.CharAddedConn = Player.CharacterAdded:Connect(function(newChar)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        if hrp then hookHRP(hrp) end
    end)
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        hookHRP(Player.Character.HumanoidRootPart)
    end

    LineUpCreator.Connection = RunService.Heartbeat:Connect(function()
        if not LineUpCreator.Enabled then return end
        local hasBall = HasBall()
        local animId, animStyle = LineUpCreator.GetCurrentAnimationId()

        if not animId then
            lastGoodTarget = LineUpCreator.GetMouseTarget()
            local cam = Workspace.CurrentCamera
            lastGoodLookVector = cam and cam.CFrame.LookVector
            lastGoodPosition = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and
                Player.Character.HumanoidRootPart.Position
        end

        if animId and animStyle then
            if animId ~= lastAnimId then
                lastAnimId = animId
                lastAnimStyle = animStyle
                animStartTime = tick()
                coordsSaved = false
                kiyoraStrongSoundDetected = false
                local delay = LineUpCreator.AnimationDelays[animId] or 0
                if delay == 0 then
                    savedPosition = lastGoodPosition or
                        (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position)
                    savedMouseTarget = lastGoodTarget or LineUpCreator.GetMouseTarget()
                    local cam = Workspace.CurrentCamera
                    savedLookVector = lastGoodLookVector or (cam and cam.CFrame.LookVector)
                    coordsSaved = true
                end
            end
            if not coordsSaved and lastAnimId then
                local delay = LineUpCreator.AnimationDelays[lastAnimId] or 0
                if delay > 0 and (tick() - animStartTime) >= delay then
                    savedPosition = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and
                        Player.Character.HumanoidRootPart.Position
                    savedMouseTarget = LineUpCreator.GetMouseTarget()
                    local cam = Workspace.CurrentCamera
                    savedLookVector = cam and cam.CFrame.LookVector
                    coordsSaved = true
                end
            end
            if lastAnimId == "98869531447623" and lastAnimStyle == "barou" then
                if LineUpCreator.IsTspecialerOnCooldown() then
                    lastAnimStyle = "barou_curve"
                end
            end
            if lastAnimId == "114955963969575" and (lastAnimStyle == "kiyora" or lastAnimStyle == "kiyora_strong") then
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hasSound = false
                if hrp then
                    for _, s in ipairs(hrp:GetChildren()) do
                        if s:IsA("Sound") and tostring(s.SoundId or ""):find("133444704350985") then
                            hasSound = true
                            break
                        end
                    end
                end
                if kiyoraStrongSoundDetected or hasSound or LineUpCreator.IsTspecialerOnCooldown() then
                    lastAnimStyle = "kiyora_strong"
                end
            end
        else
            if lastAnimStyle then
                if not coordsSaved then
                    savedPosition = lastGoodPosition or
                        (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position)
                    savedMouseTarget = lastGoodTarget or LineUpCreator.GetMouseTarget()
                    local cam = Workspace.CurrentCamera
                    savedLookVector = lastGoodLookVector or (cam and cam.CFrame.LookVector)
                    coordsSaved = true
                end
                if savedPosition and savedMouseTarget and savedLookVector then
                    LineUpCreator.OnShotDetected(lastAnimStyle, savedPosition, savedMouseTarget, savedLookVector)
                end
            end
            lastAnimStyle, lastAnimId, savedPosition, savedMouseTarget, savedLookVector, coordsSaved = nil, nil, nil, nil,
                nil, false
            kiyoraStrongSoundDetected = false
        end

        if hadBall and not hasBall then
            if lastAnimStyle then
                if not coordsSaved then
                    savedPosition = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and
                        Player.Character.HumanoidRootPart.Position
                    savedMouseTarget = lastGoodTarget or LineUpCreator.GetMouseTarget()
                    local cam = Workspace.CurrentCamera
                    savedLookVector = lastGoodLookVector or (cam and cam.CFrame.LookVector)
                    coordsSaved = true
                end
                if savedPosition and savedMouseTarget and savedLookVector then
                    LineUpCreator.OnShotDetected(lastAnimStyle, savedPosition, savedMouseTarget, savedLookVector)
                end
            end
            lastAnimStyle, lastAnimId, savedPosition, savedMouseTarget, savedLookVector, coordsSaved = nil, nil, nil, nil,
                nil, false
            kiyoraStrongSoundDetected = false
        end
        hadBall = hasBall
    end)
    SafeNotify("LineUp Creator Enabled", 3, "Enable")
end

function LineUpCreator.Stop()
    LineUpCreator.Enabled = false
    if LineUpCreator.Connection then
        LineUpCreator.Connection:Disconnect()
        LineUpCreator.Connection = nil
    end
    if LineUpCreator.SoundConns then
        for _, c in ipairs(LineUpCreator.SoundConns) do pcall(function() c:Disconnect() end) end
        LineUpCreator.SoundConns = nil
    end
    if LineUpCreator.CharAddedConn then
        LineUpCreator.CharAddedConn:Disconnect()
        LineUpCreator.CharAddedConn = nil
    end
    SafeNotify("LineUp Creator Disabled", 2, "Disable")
end

pcall(function() LineUpCreator.LoadConfig() end)

Library:CreateToggle(LineUpCreatorSection, {
    Name = "LineUp Creator",
    Default = false,
    Callback = function(v) if v then LineUpCreator.Start() else LineUpCreator.Stop() end end
})

Library:CreateButton(LineUpCreatorSection, {
    Name = "Save Latest",
    Callback = function() LineUpCreator.SaveLatest() end
})

Library:CreateButton(LineUpCreatorSection, {
    Name = "Delete Latest",
    Callback = function() LineUpCreator.DeleteLatest() end
})

local LineUpIndexMap = {}
local SelectedLineUpIndex = nil

local function GetLineUpOptions()
    local options = { "None" }
    LineUpIndexMap = {}
    local currentStyle = Player:GetAttribute("style")
    if currentStyle == "masterykaiser" then currentStyle = "kaiser" end
    if LineUpCreator.CustomLineUps and currentStyle then
        local displayIndex = 1
        for i, lineup in ipairs(LineUpCreator.CustomLineUps) do
            local baseStyle = lineup.style:gsub("_flow%d?$", ""):gsub("_curve$", ""):gsub("_strong$", "")
            if baseStyle == currentStyle then
                local flowText = lineup.isFlow and " (flow)" or ""
                local curveText = string.find(lineup.style, "_curve") and " (curve)" or ""
                local strongText = string.find(lineup.style, "_strong") and " (strong)" or ""
                table.insert(options, displayIndex .. ". " .. lineup.team .. flowText .. curveText .. strongText)
                LineUpIndexMap[displayIndex] = i
                displayIndex = displayIndex + 1
            end
        end
    end
    return options
end

local LineUpDropdown = Library:CreateDropdown(LineUpCreatorSection, {
    Name = "Select LineUp",
    Options = GetLineUpOptions(),
    Default = "None",
    Callback = function(v)
        if v == "None" then
            SelectedLineUpIndex = nil
            return
        end
        local displayIdx = tonumber(v:match("^(%d+)%."))
        SelectedLineUpIndex = displayIdx and LineUpIndexMap[displayIdx]
        if SelectedLineUpIndex and LineUpCreator.CustomLineUps[SelectedLineUpIndex] then
            local lineup = LineUpCreator.CustomLineUps[SelectedLineUpIndex]
            local lineupPos = Vector3.new(lineup.targetPosition.X, lineup.targetPosition.Y, lineup.targetPosition.Z)
            for _, marker in pairs(AutoLineUps.Markers) do
                if marker and marker.Parent then
                    local markerPos = AutoLineUps.GetMarkerPosition(marker)
                    if (Vector3.new(markerPos.X, 3, markerPos.Z) - lineupPos).Magnitude < 2 then
                        local origColor = marker:GetAttribute("BaseColor")
                        if not origColor and marker:IsA("BasePart") then origColor = marker.Color end
                        origColor = origColor or Color3.fromRGB(70, 190, 255)
                        AutoLineUps.SetMarkerColor(marker, Color3.fromRGB(0, 255, 0))
                        task.delay(0.3, function()
                            if marker and marker.Parent then AutoLineUps.SetMarkerColor(marker, Color3.fromRGB(0, 255, 0)) end
                        end)
                        task.delay(0.6, function()
                            if marker and marker.Parent then AutoLineUps.SetMarkerColor(marker, origColor) end
                        end)
                        break
                    end
                end
            end
        end
    end
})

LineUpCreator.RefreshDropdown = function()
    SelectedLineUpIndex = nil
    if LineUpDropdown and LineUpDropdown.Refresh then
        LineUpDropdown:Refresh(GetLineUpOptions())
        LineUpDropdown:SetValue("None", true)
    end
end

Player:GetAttributeChangedSignal("style"):Connect(function()
    if LineUpCreator.RefreshDropdown then LineUpCreator.RefreshDropdown() end
end)

Library:CreateButton(LineUpCreatorSection, {
    Name = "Delete Selected",
    Callback = function()
        if not SelectedLineUpIndex then
            SafeNotify("No lineup selected!", 2)
            return
        end
        if not LineUpCreator.CustomLineUps[SelectedLineUpIndex] then
            SafeNotify("Invalid lineup!", 2)
            return
        end
        local removed = LineUpCreator.CustomLineUps[SelectedLineUpIndex]
        local styleName = removed.style
        if removed.isFlow and not string.find(styleName, "_flow$") then styleName = styleName .. "_flow" end
        local cfg = AutoLineUps.StylesConfig[styleName]
        if cfg and cfg.points[removed.team] then
            for i = #cfg.points[removed.team], 1, -1 do
                local pt = cfg.points[removed.team][i]
                if pt.isCustom and math.abs(pt.targetPosition.X - removed.targetPosition.X) < 2 and math.abs(pt.targetPosition.Z - removed.targetPosition.Z) < 2 then
                    table.remove(cfg.points[removed.team], i)
                    break
                end
            end
        end
        table.remove(LineUpCreator.CustomLineUps, SelectedLineUpIndex)
        LineUpCreator.SaveConfig()
        if AutoLineUps.Enabled then AutoLineUps.CreateMarkers() end
        SafeNotify("Deleted: " .. removed.style .. " " .. removed.team, 2)
        SelectedLineUpIndex = nil
        if LineUpCreator.RefreshDropdown then LineUpCreator.RefreshDropdown() end
    end
})

local OffBallAwkSection = Library:CreateSection(MainCat, "Off Ball Awk", "right")

local OffBallAwk = {
    Enabled = false,
    GoalboxOnly = false,
    Connection = nil,
    LastDefenseTime = 0,
    IsSpammingG = false,
    SpamDuration = 1.3,
    lastBallOwnerTeam = nil,
    MAX_BALL_DISTANCE = 53,
    MAX_VERTICAL_DISTANCE = 65,
    MinBallSpeed = 100,
    Goalboxes = { A = { minX = -858.91, maxX = -217.89, minZ = 1500.90, maxZ = 1706.09 }, B = { minX = -858.61, maxX = -217.91, minZ = 841.90, maxZ = 1041.18 } },
    SupportedStyles = { kaiser = true, masterykaiser = true, nelisagi = true, shidou = true, reo = true, masterylorenzo = true },
}

function OffBallAwk.IsSupportedStyle() return OffBallAwk.SupportedStyles[Player:GetAttribute("style")] or false end

function OffBallAwk.GetFlow()
    local chars = Workspace:FindFirstChild("characters")
    local my = chars and chars:FindFirstChild(Player.Name)
    local st = my and my:FindFirstChild("state")
    local f = st and st:FindFirstChild("flow")
    return f and tonumber(f.Value) or 0
end

function OffBallAwk.FindBallOwnerTeam()
    local chars = Workspace:FindFirstChild("characters")
    if not chars then return nil end
    for _, pf in ipairs(chars:GetChildren()) do
        if pf:FindFirstChild("Ball") then
            local st = pf:FindFirstChild("state")
            if st and st:FindFirstChild("team") then return st.team.Value end
        end
    end
    return nil
end

function OffBallAwk.IsInGoalbox(pos, team)
    local g = OffBallAwk.Goalboxes[team]
    return g and pos.X >= g.minX and pos.X <= g.maxX and pos.Z >= g.minZ and pos.Z <= g.maxZ
end

function OffBallAwk.IsBallComing(ball, vel, pPos)
    if not ball or vel.Magnitude == 0 then return false end
    return vel.Unit:Dot((pPos - ball.Position).Unit) > math.cos(math.rad(45))
end

function OffBallAwk.CanReach(ball, pPos)
    if not ball then return false end
    local hd = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(ball.Position.X, 0, ball.Position.Z)).Magnitude
    return hd <= OffBallAwk.MAX_BALL_DISTANCE and math.abs(pPos.Y - ball.Position.Y) <= OffBallAwk.MAX_VERTICAL_DISTANCE
end

function OffBallAwk.SpamBaseAwaken()
    if OffBallAwk.IsSpammingG then return end
    OffBallAwk.IsSpammingG = true
    local st = tick()
    while tick() - st < OffBallAwk.SpamDuration and OffBallAwk.Enabled do
        pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { "baseAwaken", false } }) end)
        task.wait(0.1)
    end
    OffBallAwk.IsSpammingG = false
end

function OffBallAwk.ProcessDefense()
    if not OffBallAwk.Enabled then return end
    local char = Player.Character
    if not char then return end
    if OffBallAwk.GetFlow() ~= 100 or not OffBallAwk.IsSupportedStyle() then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ownerTeam = OffBallAwk.FindBallOwnerTeam()
    if ownerTeam then OffBallAwk.lastBallOwnerTeam = ownerTeam end

    if not HasBall() then
        local ball = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
        local cfBall = ball and ReplicatedStorage:FindFirstChild("CFBall")
        if cfBall and cfBall:FindFirstChild("velocity") then
            local vel = cfBall.velocity.Value
            local spd = vel.Magnitude
            if spd >= OffBallAwk.MinBallSpeed and OffBallAwk.IsBallComing(ball, vel, hrp.Position) and (ball.Position - hrp.Position).Magnitude / spd <= 0.3 and OffBallAwk.CanReach(ball, hrp.Position) then
                local myTeam = GetTeam(Player.Name)
                if OffBallAwk.lastBallOwnerTeam and myTeam and OffBallAwk.lastBallOwnerTeam ~= "lobby" and myTeam ~= "lobby" and OffBallAwk.lastBallOwnerTeam ~= myTeam then
                    if (not OffBallAwk.GoalboxOnly or OffBallAwk.IsInGoalbox(hrp.Position, myTeam)) and tick() - OffBallAwk.LastDefenseTime > 2 then
                        OffBallAwk.LastDefenseTime = tick()
                        task.spawn(OffBallAwk.SpamBaseAwaken)
                    end
                end
            end
        end
    end
end

function OffBallAwk.Start()
    OffBallAwk.Enabled = true
    OffBallAwk.Connection = RunService.Heartbeat:Connect(OffBallAwk.ProcessDefense)
    SafeNotify("Off Ball Awk Enabled", 2, "Enable")
end

function OffBallAwk.Stop()
    OffBallAwk.Enabled = false
    if OffBallAwk.Connection then
        OffBallAwk.Connection:Disconnect()
        OffBallAwk.Connection = nil
    end
    OffBallAwk.IsSpammingG = false
    OffBallAwk.LastDefenseTime = 0
    SafeNotify("Off Ball Awk Disabled", 2, "Disable")
end

Library:CreateToggle(OffBallAwkSection, {
    Name = "Enable",
    Default = false,
    Callback = function(v) if v then OffBallAwk.Start() else OffBallAwk.Stop() end end
})

Library:CreateToggle(OffBallAwkSection, {
    Name = "Goalbox Only",
    Default = false,
    Callback = function(v) OffBallAwk.GoalboxOnly = v end
})

Library:CreateSlider(OffBallAwkSection, {
    Name = "Min Ball Speed",
    Min = 0.1,
    Max = 100,
    Default = 100,
    Step = 0.1,
    Suffix = "",
    Callback = function(v) OffBallAwk.MinBallSpeed = v end
})

local DubSection = Library:CreateSection(MainCat, "Misc Features", "right")

local InfPassRange = {
    Enabled = false,
    Busy = false,
    Keybind = nil,
    StyleRules = {
        sae = { skill = "skill4" },
        donlorenzo = { skill = "skill2" },
        masterylorenzo = { skill = "skill2" },
        lorenzo = { skill = "skill2" },
        kurona = { skill = "skill2" },
        hiori = { skill = "skill4" },
        reo = { skill = "skill2", tool = "100-Point Pass" },
        kiyora = { skill = "skill4", requireBall = true },
        karasu = { skill = "skill2" },
    },
}

function InfPassRange.GetRule()
    local style = Player:GetAttribute("style")
    return style and InfPassRange.StyleRules[style:lower()]
end

function InfPassRange.CanPass()
    local rule = InfPassRange.GetRule()
    if not rule then return false end
    if rule.requireBall and not HasBall() then return false end
    if IsSkillOnCooldown(rule.skill) then return false end
    if rule.tool then
        local btn = FindSkillButton(rule.skill)
        local base = btn and btn:FindFirstChild("Base")
        local toolName = base and base:FindFirstChild("ToolName")
        if not toolName or toolName.Text ~= rule.tool then return false end
    end
    return true, rule
end

function InfPassRange.GetClosestTeammate()
    local mousePos = UserInputService:GetMouseLocation()
    local closestChar, closestDist = nil, math.huge
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local chars = Workspace:FindFirstChild("characters")
    local myChar = chars and chars:FindFirstChild(Player.Name)
    local myTeam = myChar and myChar:FindFirstChild("state") and myChar.state:FindFirstChild("team") and
        myChar.state.team.Value

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local char = p.Character or (chars and chars:FindFirstChild(p.Name))
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")

            local isTeammate = false
            local cState = char:FindFirstChild("state")
            local cTeam = cState and cState:FindFirstChild("team") and cState.team.Value

            if myTeam and myTeam ~= "lobby" and cTeam then
                isTeammate = (cTeam == myTeam)
            elseif p.Team and Player.Team and Player.Team.Name ~= "lobby" then
                isTeammate = (p.Team == Player.Team)
            end

            if isTeammate and hum and hrp and hum.Health > 0 then
                local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestChar = char
                    end
                end
            end
        end
    end
    return closestChar
end

function InfPassRange.Execute()
    if not InfPassRange.Enabled or InfPassRange.Busy then return end

    local lobbyTeam = game:GetService("Teams"):FindFirstChild("lobby")
    if lobbyTeam and Player.Team == lobbyTeam then return end

    local canPass, rule = InfPassRange.CanPass()
    if not canPass or not rule then return end

    local targetChar = InfPassRange.GetClosestTeammate()
    if not targetChar then return end

    InfPassRange.Busy = true
    pcall(function()
        NET:FireServer(buffer.fromstring(buffers["base"]), {
            { rule.skill, targetChar }
        })
    end)

    task.delay(0.1, function()
        InfPassRange.Busy = false
    end)
end

function InfPassRange.Start()
    if InfPassRange.Enabled then return end
    InfPassRange.Enabled = true
    SafeNotify("Inf Pass Range Enabled", 2, "Enable")
end

function InfPassRange.Stop()
    InfPassRange.Enabled = false
    InfPassRange.Busy = false
    SafeNotify("Inf Pass Range Disabled", 2, "Disable")
end

Library:CreateToggle(DubSection, {
    Name = "Inf Pass Range",
    Default = false,
    Callback = function(v) if v then InfPassRange.Start() else InfPassRange.Stop() end end
})

InfPassRange.Keybind = Library:CreateKeybind(DubSection, {
    Name = "Pass Keybind",
    Default = Enum.KeyCode.J,
    Mode = "Hold",
    ManualWatermark = true,
    Callback = function(active)
        if not InfPassRange.Enabled then return end
        if active then
            InfPassRange.Execute()
            if InfPassRange.Keybind and InfPassRange.Keybind.Mode == "Toggle" then
                task.spawn(function()
                    task.wait(0.1)
                    if InfPassRange.Keybind then
                        InfPassRange.Keybind.Active = false
                    end
                end)
            end
        end
    end
})

local dubVoicelineNames = {
    "dubVoicelines", "dub_aiku", "dub_aiku2", "dub_barou", "dub_chigiri", "dub_donlorenzo",
    "dub_gagamaru", "dub_isagi", "dub_kaiser", "dub_karasu", "dub_kunigami",
    "dub_masterylorenzo", "dub_masterykaiser", "dub_nagi", "dub_nelisagi", "dub_otoya",
    "dub_rin", "dub_sae", "dub_shidou", "dub_what", "dub_yukimiya",
}

local MarketplaceService = game:GetService("MarketplaceService")
local hasDubGamepass = false
pcall(function()
    hasDubGamepass = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 1672150010)
end)

local function disableAllDubVoicelines()
    local setting = Player:FindFirstChild("setting") or Player:WaitForChild("setting", 3)
    if setting then
        for _, name in ipairs(dubVoicelineNames) do
            local value = setting:FindFirstChild(name)
            if value and value:IsA("BoolValue") then
                value.Value = false
            end
        end
    end
end

if hasDubGamepass then
    disableAllDubVoicelines()
else
    local dubToggle = Library:CreateToggle(DubSection, {
        Name = "Enable Dub Voicelines",
        Default = false,
        Callback = function(v)
            local setting = Player:FindFirstChild("setting")
            if not setting then return end
            for _, name in ipairs(dubVoicelineNames) do
                local value = setting:FindFirstChild(name)
                if value and value:IsA("BoolValue") then value.Value = v end
            end
            SafeNotify(v and "Dub Voicelines Enabled" or "Dub Voicelines Disabled", 2)
        end
    })

    task.spawn(function()
        local recheck = false
        pcall(function()
            recheck = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 1672150010)
        end)
        if recheck then
            if dubToggle and dubToggle.SetValue then
                dubToggle:SetValue(false)
            end
            disableAllDubVoicelines()
            pcall(function()
                if DubSection and DubSection.Container then
                    for _, child in ipairs(DubSection.Container:GetChildren()) do
                        local lbl = child:FindFirstChildOfClass("TextLabel")
                        if lbl and lbl.Text == "Enable Dub Voicelines" then
                            child.Visible = false
                        end
                    end
                end
            end)
        end
    end)
end

Library:CreateButton(DubSection, {
    Name = "Break Ball",
    Callback = function()
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char:SetPrimaryPartCFrame(CFrame.new(-3500, -422, -2081))
            SafeNotify("Break Ball: Teleported!", 2)
        else
            SafeNotify("Break Ball: No character!", 2)
        end
    end
})

local NameProtectSection = Library:CreateSection(MainCat, "Name Protect", "right")

NameProtect = {
    Enabled = false,
    FakeName = "EvoHub",
    FakeDisplay = "EvoHub",
    Initialized = false,
    Connections = {},
    ProcessedObjects = {},
}

function NameProtect.SpoofText(obj)
    if not NameProtect.Enabled then return end
    if typeof(obj.Text) ~= "string" then return end

    local txt = obj.Text
    local rName, rDisplay = Player.Name, Player.DisplayName

    if not string.find(txt, rName, 1, true) and not string.find(txt, rDisplay, 1, true) then return end

    local newText = string.gsub(txt, rName, NameProtect.FakeName)
    newText = string.gsub(newText, rDisplay, NameProtect.FakeDisplay)

    if txt ~= newText then
        obj.Text = newText
    end
end

function NameProtect.MonitorObject(obj)
    if NameProtect.ProcessedObjects[obj] then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        NameProtect.ProcessedObjects[obj] = true
        NameProtect.SpoofText(obj)
        local conn = obj:GetPropertyChangedSignal("Text"):Connect(function()
            NameProtect.SpoofText(obj)
        end)
        table.insert(NameProtect.Connections, conn)
    end
end

function NameProtect.MonitorCharacter(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        if NameProtect.Enabled then
            humanoid.DisplayName = NameProtect.FakeDisplay
        end
        local conn = humanoid:GetPropertyChangedSignal("DisplayName"):Connect(function()
            if NameProtect.Enabled and humanoid.DisplayName ~= NameProtect.FakeDisplay then
                humanoid.DisplayName = NameProtect.FakeDisplay
            end
        end)
        table.insert(NameProtect.Connections, conn)
    end
end

function NameProtect.RemoveBackDecal()
    if not NameProtect.Enabled then return end
    local chars = Workspace:FindFirstChild("characters")
    local myChar = chars and chars:FindFirstChild(Player.Name)
    local torso = myChar and myChar:FindFirstChild("Torso")
    if torso then
        local decal = torso:FindFirstChild("BackDecal")
        if decal then decal:Destroy() end
    end
end

function NameProtect.Init()
    if NameProtect.Initialized then return end
    NameProtect.Initialized = true

    for _, v in ipairs(Player.PlayerGui:GetDescendants()) do
        NameProtect.MonitorObject(v)
    end
    table.insert(NameProtect.Connections, Player.PlayerGui.DescendantAdded:Connect(NameProtect.MonitorObject))

    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        for _, v in ipairs(CoreGui:GetDescendants()) do
            NameProtect.MonitorObject(v)
        end
        table.insert(NameProtect.Connections, CoreGui.DescendantAdded:Connect(NameProtect.MonitorObject))
    end)

    if Player.Character then
        NameProtect.MonitorCharacter(Player.Character)
    end
    table.insert(NameProtect.Connections, Player.CharacterAdded:Connect(NameProtect.MonitorCharacter))

    table.insert(NameProtect.Connections, RunService.Heartbeat:Connect(function()
        if NameProtect.Enabled then
            NameProtect.RemoveBackDecal()
        end
    end))
end

Library:CreateToggle(NameProtectSection, {
    Name = "Enable Name Protect",
    Default = false,
    Callback = function(v)
        NameProtect.Enabled = v
        if v then
            NameProtect.Init()
            if Player.Character then
                local hum = Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.DisplayName = NameProtect.FakeDisplay end
                NameProtect.RemoveBackDecal()
            end
        end
    end
})


local SkillAimbot = {}
SkillAimbot.Instances = {}

function SkillAimbot.GetClosestEnemy(maxDist, requireBall)
    local localRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    local myTeam = GetTeam(Player.Name)
    if not myTeam or myTeam == "lobby" then return nil end
    local closest, shortest = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            if not requireBall or HasBall(p.Name) then
                local et = GetTeam(p.Name)
                if et and et ~= myTeam and et ~= "lobby" then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and hrp then
                        local dist = (hrp.Position - localRoot.Position).Magnitude
                        if dist < maxDist and dist < shortest then
                            shortest = dist
                            closest = p
                        end
                    end
                end
            end
        end
    end
    return closest
end

function SkillAimbot.Create(section, config)
    local data = {
        name = config.name,
        styles = type(config.style) == "table" and config.style or { config.style },
        animId = config.animId,
        maxDistance = config.maxDistance or 1000,
        requireBall = config.requireBall or false,
        delay = config.delay or 0,
        hasPrediction = config.hasPrediction or false,
        usePrediction = true,
        prediction = 0.5,
        smoothness = 0.5,
        velocity = Vector3.new(0, 0, 0),
        oldPos = Vector3.new(0, 0, 0),
        enabled = false,
        aiming = false,
        currentTarget = nil,
        animator = nil,
        connections = {},
    }

    local function checkStyle()
        local s = Player:GetAttribute("style")
        for _, v in ipairs(data.styles) do
            if v == "all" or s == v then return true end
        end
        return false
    end

    local function AimTick()
        if not data.aiming then
            if data.connections.aim then
                data.connections.aim:Disconnect()
                data.connections.aim = nil
            end
            return
        end
        if not data.currentTarget or not data.currentTarget.Character or (data.requireBall and not HasBall(data.currentTarget.Name)) then
            data.currentTarget = SkillAimbot.GetClosestEnemy(data.maxDistance, data.requireBall)
            if data.currentTarget and data.currentTarget.Character then
                local root = data.currentTarget.Character:FindFirstChild("HumanoidRootPart") or
                    data.currentTarget.Character.PrimaryPart
                if root then data.oldPos = root.Position end
            end
        end
        local targetPart = data.currentTarget and data.currentTarget.Character and
            (data.currentTarget.Character:FindFirstChild("HumanoidRootPart") or data.currentTarget.Character.PrimaryPart)
        if targetPart then
            local cam = Workspace.CurrentCamera
            if cam then
                local targetPos = targetPart.Position
                if data.hasPrediction and data.usePrediction then
                    targetPos = targetPos + (data.velocity * data.prediction)
                end

                if data.hasPrediction and data.usePrediction then
                    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, targetPos), data.smoothness)
                else
                    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
                end
            end
        end
    end

    local function HeartbeatUpdate(dt)
        if data.aiming and data.currentTarget and data.currentTarget.Character then
            local root = data.currentTarget.Character:FindFirstChild("HumanoidRootPart") or
                data.currentTarget.Character.PrimaryPart
            if root then
                local CurrPos = root.Position
                if data.oldPos ~= Vector3.new(0, 0, 0) then
                    local Displacement = CurrPos - data.oldPos
                    local Vel = Displacement / dt
                    data.velocity = data.velocity:Lerp(Vector3.new(Vel.X, Vel.Y * 0.94, Vel.Z), 0.4)
                end
                data.oldPos = CurrPos
            end
        end
    end

    local function StartAiming()
        if data.aiming then return end
        data.aiming = true
        data.currentTarget = SkillAimbot.GetClosestEnemy(data.maxDistance, data.requireBall)
        if data.currentTarget and data.currentTarget.Character then
            local root = data.currentTarget.Character:FindFirstChild("HumanoidRootPart") or
                data.currentTarget.Character.PrimaryPart
            if root then data.oldPos = root.Position end
        end
        data.velocity = Vector3.new(0, 0, 0)
        if data.connections.aim then data.connections.aim:Disconnect() end
        data.connections.aim = RunService.RenderStepped:Connect(AimTick)
        if data.connections.hb then data.connections.hb:Disconnect() end
        data.connections.hb = RunService.Heartbeat:Connect(HeartbeatUpdate)
    end

    local function StopAiming()
        data.aiming = false
        data.currentTarget = nil
        if data.connections.aim then
            data.connections.aim:Disconnect()
            data.connections.aim = nil
        end
        if data.connections.hb then
            data.connections.hb:Disconnect()
            data.connections.hb = nil
        end
    end

    local function AnimatorUpdate()
        if not data.enabled or not checkStyle() or not data.animator then return end
        local found = false
        for _, track in ipairs(data.animator:GetPlayingAnimationTracks()) do
            if track.Animation and tostring(track.Animation.AnimationId):find(data.animId) then
                if track.TimePosition >= data.delay then
                    found = true
                    break
                end
            end
        end
        if found and not data.aiming then
            StartAiming()
        elseif not found and data.aiming then
            StopAiming()
        end
    end

    local function SetupCharacter(char)
        if not data.enabled then return end
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            data.animator = hum:WaitForChild("Animator", 5)
            if data.connections.animator then data.connections.animator:Disconnect() end
            data.connections.animator = RunService.Heartbeat:Connect(AnimatorUpdate)
        end
    end

    local function Start()
        if data.enabled then return end
        data.enabled = true
        if Player.Character then SetupCharacter(Player.Character) end
        if data.connections.char then data.connections.char:Disconnect() end
        data.connections.char = Player.CharacterAdded:Connect(function(c)
            task.wait(1)
            if data.enabled then SetupCharacter(c) end
        end)
        SafeNotify(data.name .. " Enabled", 2, "Enable")
    end

    local function Stop()
        data.enabled = false
        StopAiming()
        for k, c in pairs(data.connections) do
            c:Disconnect()
        end
        data.connections = {}
        SafeNotify(data.name .. " Disabled", 2, "Disable")
    end

    data.toggle = Library:CreateToggle(section, {
        Name = data.name,
        Default = false,
        Callback = function(v) if v then Start() else Stop() end end
    })

    if config.defaultKey then
        data.keybind = Library:CreateKeybind(section, {
            Name = data.name,
            Default = config.defaultKey,
            Mode = "Toggle",
            Callback = function(active)
                local t = data.toggle
                if not t or not t.SetValue then return end
                if t.Value ~= active then
                    t:SetValue(active and true or false)
                end
            end
        })
    end

    if data.hasPrediction then
        Library:CreateToggle(section, {
            Name = data.name .. " Prediction",
            Default = true,
            Callback = function(v) data.usePrediction = v end
        })
        Library:CreateSlider(section, {
            Name = data.name .. " Prediction Value",
            Min = 0,
            Max = 1,
            Default = 0.5,
            Step = 0.1,
            Suffix = "",
            Callback = function(v) data.prediction = v end
        })
    end

    table.insert(SkillAimbot.Instances, data)
    return data
end

local TrapHelper = {}
do
    function TrapHelper.Create(section, config)
        local data = {
            Enabled = false,
            Connection = nil,
            AnimationConnection = nil,
            CharacterConnection = nil,
            IsActive = false,
            StartTime = 0,
            LastPosition = nil,
            name = config.name,
            ANIMATION_ID = config.animId,
            MIN_BALL_HEIGHT = 5,
            MagnetRadius = 55,
            MagnetSpeed = 0.07,
            ACTIVATION_DELAY = 0.01,
            MAGNET_DURATION = 1.5,
            VERTICAL_OFFSET = 2
        }

        local function TH_GetBall()
            return Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
        end

        local function TH_IsPlayingTargetAnimation()
            local char = Player.Character
            if not char then return false end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then return false end
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                if track.Animation and tostring(track.Animation.AnimationId):find(data.ANIMATION_ID) then return true end
            end
            return false
        end

        local function TH_CanActivateMagnet(ball)
            if not ball then return false end
            local char = Player.Character
            if not char then return false end
            if char:FindFirstChild("Ball") or char:GetAttribute("cantgetball") or char:GetAttribute("InMarble") then return false end
            if ball.Position.Y < data.MIN_BALL_HEIGHT then return false end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            return (hrp.Position - ball.Position).Magnitude <= data.MagnetRadius
        end

        local function TH_SmoothMagnetToBall()
            local ball = TH_GetBall()
            if not ball or not TH_CanActivateMagnet(ball) then return false end
            local char = Player.Character
            if not char then return false end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            local targetPosition = ball.Position + Vector3.new(0, data.VERTICAL_OFFSET, 0)
            local currentPosition = hrp.Position
            local distance = (currentPosition - targetPosition).Magnitude
            if distance < 2 then return true end
            local newPosition = currentPosition:Lerp(targetPosition, data.MagnetSpeed)
            local playerHeight = currentPosition.Y
            if playerHeight > 10 then newPosition = Vector3.new(newPosition.X, playerHeight, newPosition.Z) end
            hrp.CFrame = CFrame.new(newPosition)
            return true
        end

        function data.StartMagnet()
            if data.IsActive then return end
            data.StartTime = tick()
            data.IsActive = true
            local char = Player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then data.LastPosition = hrp.Position end
            end
            data.Connection = RunService.Heartbeat:Connect(function()
                if not data.IsActive or not TH_IsPlayingTargetAnimation() then
                    data.StopMagnet()
                    return
                end
                local elapsed = tick() - data.StartTime
                if elapsed < data.ACTIVATION_DELAY then return end
                if elapsed > data.MAGNET_DURATION then
                    data.StopMagnet()
                    return
                end
                TH_SmoothMagnetToBall()
                local char2 = Player.Character
                if char2 then
                    local hrp = char2:FindFirstChild("HumanoidRootPart")
                    if hrp then data.LastPosition = hrp.Position end
                end
            end)
            task.delay(data.MAGNET_DURATION + 0.1, function() data.StopMagnet() end)
        end

        function data.StopMagnet()
            if data.IsActive then
                data.IsActive = false
                if data.Connection then
                    data.Connection:Disconnect()
                    data.Connection = nil
                end
            end
        end

        function data.SetupAnimationMonitor()
            local char = Player.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then return end
            if data.AnimationConnection then data.AnimationConnection:Disconnect() end
            data.AnimationConnection = hum.AnimationPlayed:Connect(function(track)
                if not data.Enabled then return end
                if track.Animation then
                    local animId = tostring(track.Animation.AnimationId)
                    if animId:find(data.ANIMATION_ID) then
                        task.delay(data.ACTIVATION_DELAY, function()
                            if TH_IsPlayingTargetAnimation() then
                                local ball = TH_GetBall()
                                if TH_CanActivateMagnet(ball) then data.StartMagnet() end
                            end
                        end)
                    end
                end
            end)
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                if track.Animation and tostring(track.Animation.AnimationId):find(data.ANIMATION_ID) then
                    task.delay(0.3, function()
                        if TH_IsPlayingTargetAnimation() then
                            local ball = TH_GetBall()
                            if TH_CanActivateMagnet(ball) then data.StartMagnet() end
                        end
                    end)
                end
            end
        end

        function data.Start()
            data.Enabled = true
            data.SetupAnimationMonitor()
            data.CharacterConnection = Player.CharacterAdded:Connect(function(newChar)
                data.StopMagnet()
                task.wait(1)
                if newChar:FindFirstChild("HumanoidRootPart") then
                    data.SetupAnimationMonitor()
                end
            end)
            SafeNotify(data.name .. " Trap Helper Enabled", 2, "Enable")
        end

        function data.Stop()
            data.Enabled = false
            data.StopMagnet()
            if data.AnimationConnection then
                data.AnimationConnection:Disconnect()
                data.AnimationConnection = nil
            end
            if data.CharacterConnection then
                data.CharacterConnection:Disconnect()
                data.CharacterConnection = nil
            end
            SafeNotify(data.name .. " Trap Helper Disabled", 2, "Disable")
        end

        Library:CreateToggle(section, {
            Name = "Trap Helper",
            Default = false,
            Callback = function(v) if v then data.Start() else data.Stop() end end
        })

        Library:CreateSlider(section, {
            Name = "Helper Radius",
            Min = 10,
            Max = 100,
            Default = 55,
            Step = 1,
            Suffix = " studs",
            Callback = function(v) data.MagnetRadius = v end
        })

        Library:CreateSlider(section, {
            Name = "Helper Speed",
            Min = 0.01,
            Max = 1,
            Default = 0.07,
            Step = 0.01,
            Suffix = "",
            Callback = function(v) data.MagnetSpeed = v end
        })

        return data
    end
end

MoveBuff = {
    ActiveBuffs = {},
    ActiveDashes = {},
    RenderConn = nil,
    AnimConn = nil
}

function MoveBuff.StopAll()
    table.clear(MoveBuff.ActiveDashes)
    if MoveBuff.RenderConn then
        MoveBuff.RenderConn:Disconnect()
        MoveBuff.RenderConn = nil
    end
end

local ZERO = Vector3.zero
local DEFAULT_DIR = Vector3.new(0, 0, 1)
local DirectionOffsets = {
    Front = Vector3.new(0, 0, 1),
    Back = Vector3.new(0, 0, -1),
    Left = Vector3.new(-1, 0, 0),
    Right = Vector3.new(1, 0, 0),
    FrontLeft = Vector3.new(-1, 0, 1).Unit,
    FrontRight = Vector3.new(1, 0, 1).Unit,
    LeftBack = Vector3.new(-1, 0, -1).Unit,
    RightBack = Vector3.new(1, 0, -1).Unit,
}

local function getDirectionVector(hrp, dirName)
    local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
    local right = Vector3.new(hrp.CFrame.RightVector.X, 0, hrp.CFrame.RightVector.Z).Unit
    if look.Magnitude < 0.01 then look = DEFAULT_DIR end
    if right.Magnitude < 0.01 then right = Vector3.new(1, 0, 0) end

    if dirName == "Right" then
        return right
    elseif dirName == "Left" then
        return -right
    elseif dirName == "Front" then
        return look
    elseif dirName == "Back" then
        return -look
    elseif dirName == "FrontRight" then
        return (look + right).Unit
    elseif dirName == "FrontLeft" then
        return (look - right).Unit
    elseif dirName == "RightBack" then
        return (-look + right).Unit
    elseif dirName == "LeftBack" then
        return (-look - right).Unit
    end
    return look
end

local function updateDashes(dt)
    if AutoLineUps and (AutoLineUps.IsExecuting or AutoLineUps.Frozen) then
        MoveBuff.StopAll()
        return
    end

    for i = #MoveBuff.ActiveDashes, 1, -1 do
        local dash = MoveBuff.ActiveDashes[i]
        local hrp = dash.hrp
        if not hrp or not hrp.Parent then
            table.remove(MoveBuff.ActiveDashes, i)
            continue
        end

        local step = dash.isUnlimited and (dash.speed * dt) or math.min(dash.speed * dt, dash.remaining)
        local moveDir

        if dash.isDirectional and dash.directionName then
            moveDir = getDirectionVector(hrp, dash.directionName)
        elseif dash.useMovement then
            local char = hrp.Parent
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0.05 then
                moveDir = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit
            else
                local look = hrp.CFrame.LookVector
                moveDir = Vector3.new(look.X, 0, look.Z).Unit
            end
        else
            local look = hrp.CFrame.LookVector
            moveDir = Vector3.new(look.X, 0, look.Z).Unit
        end

        if not moveDir or moveDir.Magnitude < 0.01 then
            moveDir = DEFAULT_DIR
        end

        local newPos = hrp.Position + moveDir * step
        local yPos = hrp.Position.Y
        if dash.heightFunc then
            local addedY = dash.heightFunc(dt)
            if addedY then yPos = yPos + addedY end
        end

        local _, yaw = hrp.CFrame:ToOrientation()
        local uprightRot = CFrame.Angles(0, yaw, 0)
        hrp.CFrame = CFrame.new(newPos.X, yPos, newPos.Z) * uprightRot

        dash.remaining = dash.remaining - step
        if dash.remaining <= 0 then
            table.remove(MoveBuff.ActiveDashes, i)
        end
    end

    if #MoveBuff.ActiveDashes == 0 and MoveBuff.RenderConn then
        MoveBuff.RenderConn:Disconnect()
        MoveBuff.RenderConn = nil
    end
end

local function startDash(hrp, buff, track, directionName)
    local rawDist = buff.distance or 0
    if not buff.enabled or rawDist <= 0 then return end
    if AutoLineUps and (AutoLineUps.IsExecuting or AutoLineUps.Frozen) then return end

    local now = tick()
    if buff.lastTrigger and (now - buff.lastTrigger) < (buff.cooldown or 0.15) then return end
    buff.lastTrigger = now

    task.delay(buff.delay or 0, function()
        if not hrp or not hrp.Parent then return end
        if not buff.enabled then return end
        if AutoLineUps and (AutoLineUps.IsExecuting or AutoLineUps.Frozen) then return end

        if buff.requiresBall then
            local ball = hrp.Parent:FindFirstChild("Ball")
            if not ball or not ball:IsA("MeshPart") then return end
        end

        for j = #MoveBuff.ActiveDashes, 1, -1 do
            if MoveBuff.ActiveDashes[j].hrp == hrp then
                table.remove(MoveBuff.ActiveDashes, j)
            end
        end

        local actualDist = rawDist * 6
        local dur = buff.duration
        if track and track.Length and track.Length > 0.1 then
            local remainingAnim = track.Length - (buff.delay or 0)
            if remainingAnim > 0.05 then
                dur = remainingAnim
            end
        end
        if not dur or dur <= 0 then dur = (buff.duration and buff.duration > 0) and buff.duration or 0.4 end

        local dash = {
            hrp = hrp,
            buff = buff,
            directionName = directionName,
            remaining = actualDist,
            speed = buff.isUnlimited and (buff.speed or 150) or (actualDist / dur),
            isUnlimited = buff.isUnlimited == true,
            isDirectional = (buff.isDirectional == true or directionName ~= nil),
            useMovement = buff.useMovement == true,
            heightFunc = buff.heightFunc
        }

        if track then
            local stoppedConn
            stoppedConn = track.Stopped:Connect(function()
                dash.remaining = 0
                if stoppedConn then stoppedConn:Disconnect() end
            end)
        end

        table.insert(MoveBuff.ActiveDashes, dash)
        if not MoveBuff.RenderConn then
            MoveBuff.RenderConn = RunService.RenderStepped:Connect(updateDashes)
        end
    end)
end

function MoveBuff.OnAnimationPlayed(track)
    if AutoLineUps and (AutoLineUps.IsExecuting or AutoLineUps.Frozen) then return end
    if not track.Animation then return end
    local fullId = tostring(track.Animation.AnimationId)
    local numId = fullId:match("%d+")
    if not numId then return end

    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, dash in ipairs(MoveBuff.ActiveDashes) do
        if dash.buff and dash.buff.stopAnimIds and (dash.buff.stopAnimIds[numId] or dash.buff.stopAnimIds[fullId]) then
            dash.remaining = 0
        end
    end

    for _, buff in ipairs(MoveBuff.ActiveBuffs) do
        if buff.enabled and (buff.distance or 0) > 0 then
            local match = false
            local directionName = nil

            if type(buff.animIds) == "table" then
                directionName = buff.animIds[numId] or buff.animIds[fullId]
                if directionName then
                    match = true
                else
                    for k, id in pairs(buff.animIds) do
                        if id == numId or id == fullId or k == numId or k == fullId then
                            match = true
                            break
                        end
                    end
                end
            elseif buff.animId == numId or buff.animId == fullId then
                match = true
            end

            if match then
                startDash(hrp, buff, track, directionName)
            end
        end
    end
end

function MoveBuff.SetupCharacter(char)
    if MoveBuff.AnimConn then
        MoveBuff.AnimConn:Disconnect()
        MoveBuff.AnimConn = nil
    end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local animator = hum:WaitForChild("Animator", 5) or hum
    MoveBuff.AnimConn = animator.AnimationPlayed:Connect(MoveBuff.OnAnimationPlayed)
end

if Player.Character then task.spawn(MoveBuff.SetupCharacter, Player.Character) end
Player.CharacterAdded:Connect(MoveBuff.SetupCharacter)

function MoveBuff.Create(section, config)
    local stopAnimIds = nil
    if config.stopAnimIds then
        stopAnimIds = {}
        for _, id in ipairs(config.stopAnimIds) do stopAnimIds[tostring(id)] = true end
    end

    local buff = {
        name = config.name or "Move Buff",
        animIds = config.animIds or (config.animId and { config.animId } or {}),
        animId = config.animId,
        delay = config.delay or config.wait or 0,
        duration = config.duration or 0.4,
        distance = config.defaultDistance or config.distance or 4,
        maxDistance = config.maxDistance or 10,
        isDirectional = config.isDirectional or false,
        useMovement = config.useMovement or false,
        isUnlimited = config.isUnlimited or false,
        speed = config.speed or 150,
        requiresBall = config.requiresBall or false,
        cooldown = config.cooldown or 0.15,
        stopAnimIds = stopAnimIds,
        heightFunc = config.heightFunc,
        enabled = false,
    }
    table.insert(MoveBuff.ActiveBuffs, buff)

    Library:CreateToggle(section, {
        Name = buff.name,
        Default = false,
        Callback = function(v)
            buff.enabled = v
            SafeNotify(buff.name .. (v and " Enabled" or " Disabled"), 2, v and "Enable" or "Disable")
        end
    })

    Library:CreateSlider(section, {
        Name = buff.name .. " Distance",
        Min = config.minDistance or 0.1,
        Max = buff.maxDistance,
        Default = buff.distance,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) buff.distance = v end
    })

    return buff
end

AutoDefensive = {
    Variants = {},
    Enabled = false,
    Connection = nil,
    AnimationTracking = {},
    LastDefenseTime = 0,
    MAX_BALL_DISTANCE = 53,
    MAX_VERTICAL_DISTANCE = 65,
    GlobalGoalboxes = {
        A = { minX = -668.15, maxX = -407.51, minZ = 1611.19, maxZ = 1706.13 },
        B = { minX = -668.01, maxX = -407.68, minZ = 841.70, maxZ = 935.59 },
    },
    GlobalEnemyGoalboxes = {
        A = { minX = -858.81, maxX = -217.79, minZ = 1460.15, maxZ = 1706.26 },
        B = { minX = -859.01, maxX = -217.90, minZ = 841.60, maxZ = 1098.19 },
    },
    lastBallOwnerTeam = nil,
    lastBallOwnerName = nil,
    MAX_BALL_DISTANCE = 200,
    MAX_VERTICAL_DISTANCE = 200,
}

function AutoDefensive.Register(variant)
    table.insert(AutoDefensive.Variants, variant)
end

local function AD_IsInGoalbox(pos, team, isEnemy)
    local g = isEnemy and AutoDefensive.GlobalEnemyGoalboxes[team == "A" and "B" or "A"] or
        AutoDefensive.GlobalGoalboxes[team]
    return g and pos.X >= g.minX and pos.X <= g.maxX and pos.Z >= g.minZ and pos.Z <= g.maxZ
end

local function AD_IsBallComing(ball, vel, pPos)
    if not ball or vel.Magnitude == 0 then return false end
    return vel.Unit:Dot((pPos - ball.Position).Unit) > math.cos(math.rad(45))
end

local function AD_CanReach(ball, pPos, variant)
    if not ball then return false end
    local hd = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(ball.Position.X, 0, ball.Position.Z)).Magnitude
    local maxD = (variant and variant.maxBallDistance) or AutoDefensive.MAX_BALL_DISTANCE
    local maxV = (variant and variant.maxVerticalDistance) or AutoDefensive.MAX_VERTICAL_DISTANCE
    return hd <= maxD and math.abs(pPos.Y - ball.Position.Y) <= maxV
end

local function AD_IsFacing(hrp, pPos, maxAngleDeg)
    if not hrp then return false end
    maxAngleDeg = maxAngleDeg or 20
    return hrp.CFrame.LookVector:Dot((pPos - hrp.Position).Unit) > math.cos(math.rad(maxAngleDeg))
end

local function AD_IsBehindOrSide(hrp, pPos)
    if not hrp then return false end
    return hrp.CFrame.LookVector:Dot((pPos - hrp.Position).Unit) < math.cos(math.rad(60))
end

local function AD_GetImpact(ball, vel, pPos, window)
    if not ball or vel.Magnitude <= 0 then return nil end
    local pos, v = ball.Position, vel
    local bestT, bestH, bestV = nil, math.huge, math.huge
    for t = 0, window, 0.05 do
        local hd = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(pPos.X, 0, pPos.Z)).Magnitude
        local vd = math.abs(pos.Y - pPos.Y)
        if hd < bestH then bestT, bestH, bestV = t, hd, vd end
        pos = pos + v * 0.05
        v = Vector3.new(v.X * 0.9737, v.Y - Workspace.Gravity * 0.05, v.Z * 0.9737)
    end
    if bestH <= AutoDefensive.MAX_BALL_DISTANCE and bestV <= AutoDefensive.MAX_VERTICAL_DISTANCE then
        return bestT, bestH, bestV
    end
    return nil
end

local function AD_Update()
    if not AutoDefensive.Enabled or not Player.Character then return end
    local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myTeam = GetTeam(Player.Name)
    if not myTeam or myTeam == "lobby" then return end

    local style = Player:GetAttribute("style")
    local activeVariant = nil
    for _, v in ipairs(AutoDefensive.Variants) do
        if v.enabled and v.isSupported(style) then
            activeVariant = v
            break
        end
    end

    if not activeVariant then return end

    local myPos = hrp.Position
    local now = tick()

    local chars = Workspace:FindFirstChild("characters")
    if not chars then return end

    local rsWorkspace = ReplicatedStorage:FindFirstChild("workspace")
    local serverHolder = rsWorkspace and rsWorkspace:FindFirstChild("ballHolder") and rsWorkspace.ballHolder.Value

    local ballOwnerName = nil
    local ballOwnerTeam = nil
    if serverHolder then
        local st = serverHolder:FindFirstChild("state")
        local t = st and st:FindFirstChild("team")
        if t then
            ballOwnerName = serverHolder.Name
            ballOwnerTeam = t.Value
        end
    end
    if not ballOwnerTeam then
        for _, c in ipairs(chars:GetChildren()) do
            if c:FindFirstChild("Ball") or c:FindFirstChild("AlternateBallRig") then
                local st = c:FindFirstChild("state")
                local t = st and st:FindFirstChild("team")
                if t then
                    ballOwnerName = c.Name
                    ballOwnerTeam = t.Value
                end
                break
            end
        end
    end

    if ballOwnerTeam then
        AutoDefensive.lastBallOwnerTeam = ballOwnerTeam
        AutoDefensive.lastBallOwnerName = ballOwnerName
    end

    local ball = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
    local cfBall = ReplicatedStorage:FindFirstChild("CFBall")
    local vel = cfBall and cfBall:FindFirstChild("velocity")

    if ball and vel then
        local speed = vel.Value.Magnitude
        local canProceed = true

        if speed < activeVariant.minBallSpeed then canProceed = false end

        local ctx = { isBallDirectlyAtUs = false }
        if canProceed and activeVariant.useImpact then
            local impact, bestH, bestV = AD_GetImpact(ball, vel.Value, myPos, activeVariant.predictWindow or 0.75)
            if not impact then
                canProceed = false
            else
                if bestH <= 12 then ctx.isBallDirectlyAtUs = true end
            end
        elseif canProceed then
            local distToBall = (ball.Position - myPos).Magnitude
            local isComing = AD_IsBallComing(ball, vel.Value, myPos)
            local canReach = AD_CanReach(ball, myPos, activeVariant)

            if not canReach then
                canProceed = false
            elseif not isComing and distToBall > 15 then
                canProceed = false
            else
                if vel.Value.Unit:Dot((myPos - ball.Position).Unit) > 0.85 then ctx.isBallDirectlyAtUs = true end
            end
            if canProceed and (distToBall / speed) > 0.55 then canProceed = false end
        end

        local validTeam = false
        local t = activeVariant.targetTeam or "enemy"
        if t == "enemy" then
            validTeam = (AutoDefensive.lastBallOwnerTeam ~= myTeam)
        elseif t == "teammate" then
            validTeam = (AutoDefensive.lastBallOwnerTeam == myTeam)
        elseif t == "both" then
            validTeam = true
        end

        if canProceed and AutoDefensive.lastBallOwnerTeam and AutoDefensive.lastBallOwnerTeam ~= "lobby" and AutoDefensive.lastBallOwnerName ~= Player.Name and validTeam then
            local inOwnGoalbox = AD_IsInGoalbox(myPos, myTeam, false)
            local inEnemyGoalbox = AD_IsInGoalbox(myPos, myTeam, true)

            local passesBox = true
            if activeVariant.goalboxOnly and not inOwnGoalbox then passesBox = false end
            if activeVariant.enemyGoalboxOnly and not inEnemyGoalbox then passesBox = false end
            if activeVariant.ownGoalboxOnly and not inOwnGoalbox then passesBox = false end

            if passesBox and now - AutoDefensive.LastDefenseTime > 2 then
                if activeVariant.performDefense(ball, myPos, inOwnGoalbox, ctx) then
                    AutoDefensive.LastDefenseTime = now
                end
            end
        end
    end

    if activeVariant.animPredict then
        local inOwnGoalbox = AD_IsInGoalbox(myPos, myTeam, false)
        local inEnemyGoalbox = AD_IsInGoalbox(myPos, myTeam, true)
        local passesBox = true
        if activeVariant.goalboxOnly and not inOwnGoalbox then passesBox = false end
        if activeVariant.enemyGoalboxOnly and not inEnemyGoalbox then passesBox = false end
        if activeVariant.ownGoalboxOnly and not inOwnGoalbox then passesBox = false end

        if passesBox then
            for _, targetChar in ipairs(chars:GetChildren()) do
                if targetChar.Name ~= Player.Name and targetChar:FindFirstChild("Ball") then
                    local st = targetChar:FindFirstChild("state")
                    local t = st and st:FindFirstChild("team")
                    local animValidTeam = false
                    local tgt = activeVariant.targetTeam or "enemy"
                    if t and t.Value ~= "lobby" then
                        if tgt == "enemy" and t.Value ~= myTeam then
                            animValidTeam = true
                        elseif tgt == "teammate" and t.Value == myTeam then
                            animValidTeam = true
                        elseif tgt == "both" then
                            animValidTeam = true
                        end
                    end

                    if animValidTeam then
                        local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
                        local hum = targetChar:FindFirstChildOfClass("Humanoid")
                        local animator = hum and hum:FindFirstChildOfClass("Animator")

                        if tHrp and animator then
                            local dist = (tHrp.Position - myPos).Magnitude
                            local isEnemyFacingUs = AD_IsFacing(tHrp, myPos, 45)
                            local areWeFacingEnemy = AD_IsFacing(hrp, tHrp.Position, 45)
                            local isBehindOrSide = AD_IsBehindOrSide(tHrp, myPos)

                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                local animId = track.Animation and track.Animation.AnimationId
                                if animId and track.IsPlaying and activeVariant.animations[animId] then
                                    local animData = activeVariant.animations[animId]
                                    if not animData.maxDistance or dist <= animData.maxDistance then
                                        local key = targetChar.Name .. "_" .. animId
                                        if not AutoDefensive.AnimationTracking[key] then
                                            AutoDefensive.AnimationTracking[key] = {
                                                detectedTime = now,
                                                hasTriggered = false,
                                                delay =
                                                    animData.delay
                                            }
                                        end

                                        local td = AutoDefensive.AnimationTracking[key]
                                        if not td.hasTriggered and (now - td.detectedTime) >= td.delay then
                                            if now - AutoDefensive.LastDefenseTime > 2 then
                                                local ctx = {
                                                    isEnemyFacingUs = isEnemyFacingUs,
                                                    areWeFacingEnemy = areWeFacingEnemy,
                                                    isBehindOrSide = isBehindOrSide,
                                                    dist = dist,
                                                    targetHrp = tHrp,
                                                    isBallDirectlyAtUs = isEnemyFacingUs
                                                }
                                                if activeVariant.performDefense(targetChar:FindFirstChild("Ball"), myPos, inOwnGoalbox, ctx) then
                                                    AutoDefensive.LastDefenseTime = now
                                                    td.hasTriggered = true
                                                end
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for key, data in pairs(AutoDefensive.AnimationTracking) do
        if now - data.detectedTime > 5 then AutoDefensive.AnimationTracking[key] = nil end
    end
end

function AutoDefensive.CheckAnyEnabled()
    local anyEnabled = false
    for _, v in ipairs(AutoDefensive.Variants) do
        if v.enabled then
            anyEnabled = true
            break
        end
    end

    if anyEnabled and not AutoDefensive.Enabled then
        AutoDefensive.Enabled = true
        AutoDefensive.Connection = RunService.RenderStepped:Connect(AD_Update)
    elseif not anyEnabled and AutoDefensive.Enabled then
        AutoDefensive.Enabled = false
        if AutoDefensive.Connection then
            AutoDefensive.Connection:Disconnect()
            AutoDefensive.Connection = nil
        end
        AutoDefensive.AnimationTracking = {}
        AutoDefensive.LastDefenseTime = 0
    end
end

do
    local BaseMoveCat = Window:CreateCategory(PlayerTab, "Base Moves")
    local BaseMoveSection = Library:CreateSection(BaseMoveCat, "Distance Increase", "left")
    local BaseMoveAimbotSection = Library:CreateSection(BaseMoveCat, "Aimbots", "right")

    MoveBuff.Create(BaseMoveSection,
        { name = "Tackle Distance", animIds = { "109744655458082" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(BaseMoveSection,
        { name = "Dash Distance", animIds = { "79394729551302" }, delay = 0.15, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(BaseMoveSection,
        { name = "Side Dash Distance Increase", animIds = { ["114016332539655"] = "Right", ["100207093237932"] = "Left" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4, isDirectional = true })
    MoveBuff.Create(BaseMoveSection,
        { name = "Doberman Charge", animIds = { "118833138118261" }, delay = 0.8, duration = 0.5, maxDistance = 15, defaultDistance = 6 })
    MoveBuff.Create(BaseMoveSection,
        { name = "Dive Distance Increase", animIds = { "90537955276413" }, delay = 0.05, duration = 0.55, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(BaseMoveSection,
        { name = "Side Dive Distance Increase", animIds = { ["77573911221465"] = "Left", ["98466858696699"] = "Right" }, delay = 0.05, duration = 0.55, maxDistance = 10, defaultDistance = 4, isDirectional = true })

    SkillAimbot.Create(BaseMoveAimbotSection, {
        name = "Tackle Aimbot",
        style = "all",
        animId = "109744655458082",
        maxDistance = 1000,
        requireBall = true,
        delay = 0,
        hasPrediction = true,
        defaultKey = Enum.KeyCode.H
    })
end

SecretAwakening = {
    Active = false,
    ExpiresAt = 0,
    UsedSkill = false,
    AllowedSkills = {
        ["Instant Chameleon Volley"] = true,
        ["Instant Drive Shot Variant"] = true,
        ["Instant Demon's Contract"] = true,
        ["Instant Dragon Drive"] = true,
        ["Instant Center Of The World"] = true,
        ["Instant Dive-Bomb Assault"] = true,
    }
}
local function SetupSecretAwakening(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.AnimationPlayed:Connect(function(track)
            if track.Animation and tostring(track.Animation.AnimationId):match("110173493094070") then
                SecretAwakening.Active = true
                SecretAwakening.ExpiresAt = tick() + 45
                SecretAwakening.UsedSkill = false
            end
        end)
    end
end
Player.CharacterAdded:Connect(SetupSecretAwakening)
if Player.Character then task.spawn(SetupSecretAwakening, Player.Character) end

local InstantSkill = {}

function InstantSkill.PlayAnim(data)
    if data.track then data.track:Stop() end
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or not data.playAnimId then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. data.playAnimId
    local animator = hum:FindFirstChildOfClass("Animator") or hum
    data.track = animator:LoadAnimation(anim)
    data.track:Play()
end

function InstantSkill.StopAnim(data)
    if data.track then
        data.track:Stop()
        data.track = nil
    end
end

function InstantSkill.HasAnim(data)
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+")
        if id and data.blockAnimSet[id] then return true end
    end
    return false
end

function InstantSkill.EnemyNearby(radius)
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local myTeam = GetTeam(Player.Name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local et = GetTeam(p.Name)
            local er = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if er and hum and hum.Health > 0 and (er.Position - myRoot.Position).Magnitude <= radius then
                if myTeam and et then
                    if et ~= myTeam and et ~= "lobby" and et ~= "Spectators" then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end
    return false
end

function InstantSkill.PlayerNearby(radius)
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local team = GetTeam(p.Name)
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if team and team ~= "lobby" and hum and hum.Health > 0 and root and (root.Position - myRoot.Position).Magnitude <= radius then return true end
        end
    end
    return false
end

function InstantSkill.HasToolText(slot, text)
    local gui = Player:FindFirstChild("PlayerGui")
    local hb = gui and gui:FindFirstChild("Hotbar")
    local bp = hb and hb:FindFirstChild("Backpack")
    local hf = (bp and bp:FindFirstChild("Hotbar")) or (hb and hb:FindFirstChild("Hotbar")) or hb
    local skill = hf and (hf:FindFirstChild(slot) or hf:FindFirstChild(slot, true))
    if not skill and hf then
        for _, child in ipairs(hf:GetChildren()) do
            if child.Name:lower() == slot:lower() then
                skill = child
                break
            end
        end
    end
    local base = skill and skill:FindFirstChild("Base")
    local toolName = base and base:FindFirstChild("ToolName")
    if not toolName or not toolName.Text then return false end
    if toolName.Text == text then return true end
    return toolName.Text:lower():find(text:lower(), 1, true) ~= nil
end

function InstantSkill.LastAwakenIsMe()
    local folder = ReplicatedStorage:FindFirstChild("workspace") or Workspace:FindFirstChild("workspace")
    local lastAwaken = (folder and folder:FindFirstChild("lastAwaken")) or Workspace:FindFirstChild("lastAwaken") or
        ReplicatedStorage:FindFirstChild("lastAwaken")
    local value = lastAwaken and lastAwaken.Value
    if not value then return false end
    local char = Player.Character
    return value == Player or value == Player.Name or (char and value == char) or
        (typeof(value) == "Instance" and (value.Name == Player.Name or (char and value == char)))
end

function InstantSkill.Create(section, config)
    local data = {
        name = config.name,
        style = config.style,
        skillName = config.skillName,
        enabled = false,
        executing = false,
        wasFlow100 = false,
        ready = false,
        animUsed = false,
        track = nil,
        connections = {},
        blockAnimSet = {},
        requireBall = config.requireBall ~= false,
        requireFlowDrop = config.requireFlowDrop ~= false,
        requireLastAwaken = config.requireLastAwaken == true,
        blockOnce = config.blockOnce ~= false,
        playAnimId = config.playAnimId,
        kickPower = config.kickPower,
        kickVector = config.kickVector,
        delay = config.delay or 0.05,
        key = config.key or Enum.KeyCode.V,
        kickFromLook = config.kickFromLook,
        enemyRadius = config.enemyRadius,
        playerRadius = config.playerRadius,
        toolSlot = config.toolSlot,
        toolText = config.toolText,
    }
    for _, id in ipairs(config.blockAnimIds or {}) do data.blockAnimSet[tostring(id)] = true end

    function data.Reset()
        data.wasFlow100, data.ready, data.animUsed, data.executing = false, false, false, false
    end

    function data.Tick()
        if not data.enabled then return end
        if data.requireLastAwaken and not InstantSkill.LastAwakenIsMe() then
            data.Reset()
            return
        end
        if data.requireFlowDrop then
            local flow = GetFlow()
            local flowActive = (Player.Character and Player.Character:GetAttribute("FlowActive") == true) or
                GlobalFlowTracker.IsActive
            if flow >= 100 or (flowActive and not data.wasFlow100) then
                data.wasFlow100, data.ready, data.animUsed = true, false, false
            elseif data.wasFlow100 and (flow < 100 or flowActive) then
                data.ready = true
            else
                data.ready = false
            end
            if flow <= 0 and not flowActive then data.Reset() end
        else
            data.ready = true
        end
        if data.blockOnce and InstantSkill.HasAnim(data) then data.animUsed = true end
    end

    function data.Execute()
        if data.executing or not data.enabled then return false end
        if data.style and Player:GetAttribute("style") ~= data.style then return false end
        if data.requireBall and not HasBall() then return false end
        if data.toolSlot and data.toolText and not InstantSkill.HasToolText(data.toolSlot, data.toolText) then return false end
        if data.enemyRadius and not InstantSkill.EnemyNearby(data.enemyRadius) then return false end
        if data.playerRadius and not InstantSkill.PlayerNearby(data.playerRadius) then return false end

        local bypass = false
        if SecretAwakening.Active and tick() < SecretAwakening.ExpiresAt and not SecretAwakening.UsedSkill and SecretAwakening.AllowedSkills[data.name] then
            bypass = true
        end

        if not bypass and data.requireLastAwaken and not InstantSkill.LastAwakenIsMe() then return false end
        if not bypass and data.requireFlowDrop and (not data.ready or (data.blockOnce and data.animUsed)) then return false end

        if IsSkillOnCooldown(data.skillName) then return false end
        local rel = GetByteNetReliable()
        if not rel then return false end

        if bypass then SecretAwakening.UsedSkill = true end

        data.executing = true
        if data.blockOnce then data.animUsed = true end
        InstantSkill.PlayAnim(data)
        if data.delay and data.delay > 0 then
            task.wait(data.delay)
        end
        if data.kickPower then
            local kickVec
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local look = hrp.CFrame.LookVector
                local dir = Vector3.new(look.X * 1.25, 50, look.Z * 1.25)
                kickVec = (dir.Magnitude > 0) and (dir.Unit * 50) or Vector3.new(0, 50, 0)
            else
                kickVec = data.kickVector or Vector3.new(0, 1, 0)
            end
            pcall(function()
                NET:FireServer(buffer.fromstring(buffers["base"]),
                    { { "kick", data.kickPower, false, kickVec } })
            end)
            task.wait(0.06)
        end

        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            hum.Jump = true
        end
        task.wait(0.12)

        pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { data.skillName } }) end)
        SafeNotify(data.name .. " Executed", 1)
        data.executing = false
        return true
    end

    function data.Start()
        if data.enabled then return end
        data.enabled = true
        data.Reset()
        data.connections.heartbeat = RunService.Heartbeat:Connect(data.Tick)
        data.connections.character = Player.CharacterAdded:Connect(function()
            task.wait(1)
            data.Reset()
        end)
        SafeNotify(data.name .. " Enabled", 2, "Enable")
    end

    function data.Stop()
        data.enabled = false
        InstantSkill.StopAnim(data)
        data.Reset()
        for _, c in pairs(data.connections) do if c then c:Disconnect() end end
        data.connections = {}
        SafeNotify(data.name .. " Disabled", 2, "Disable")
    end

    data.toggle = Library:CreateToggle(section, {
        Name = data.name,
        Default = false,
        Callback = function(v) if v then data.Start() else data.Stop() end end
    })

    data.keybind = Library:CreateKeybind(section, {
        Name = (config.keybindName or (data.name .. " Keybind")),
        Default = data.key,
        Mode = "Hold",
        ManualWatermark = true,
        Callback = function(active) if active then data.Execute() end end
    })
    return data
end

do
    local IsagiCat = Window:CreateCategory(PlayerTab, "Isagi")
    local IsagiSection = Library:CreateSection(IsagiCat, "Distance Increase", "left")

    MoveBuff.Create(IsagiSection,
        { name = "Naruhaya Footwork", animIds = { "82240286756891" }, delay = 0.33, duration = 0.45, maxDistance = 10, defaultDistance = 6 })
    MoveBuff.Create(IsagiSection,
        { name = "Reflex Shot Run Distance Increase", animIds = { "106307629508344" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
end

do
    local ChigiriCat = Window:CreateCategory(PlayerTab, "Chigiri")
    local ChigiriSection = Library:CreateSection(ChigiriCat, "Distance Increase", "left")

    MoveBuff.Create(ChigiriSection,
        { name = "Self Pass", animIds = { "84083782378049" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(ChigiriSection,
        { name = "Non-Stop Dribble", animIds = { "105707565952027" }, delay = 0, duration = 0.5, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(ChigiriSection,
        { name = "Mach Cut-In Dash", animIds = { "133945265328817", "88448030655006" }, delay = 0.625, duration = 0.15, maxDistance = 10, defaultDistance = 6, useMovement = true })
    MoveBuff.Create(ChigiriSection,
        { name = "Blitz", animIds = { "87517087691471" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
end

do
    local BachiraCat = Window:CreateCategory(PlayerTab, "Bachira")
    local BachiraSection = Library:CreateSection(BachiraCat, "Distance Increase", "left")
    local BachiraInstantSection = Library:CreateSection(BachiraCat, "Instant Skills", "right")

    MoveBuff.Create(BachiraSection,
        { name = "Step Overs Distance Increase", animIds = { "84063609284472" }, delay = 1.275, duration = 0.15, maxDistance = 10, defaultDistance = 6, useMovement = true })
    MoveBuff.Create(BachiraSection,
        { name = "Monster Trance Distance Increase", animIds = { "97921174307159" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(BachiraSection,
        { name = "Counter Distance Increase", animIds = { "139469489709120" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    local BachiraInstantSkills = {
        { name = "Instant Monster Leap", style = "bachira", skillName = "Tspecialer", playAnimId = "76587445975710", requireFlowDrop = false, kickPower = 29, kickFromLook = true, key = Enum.KeyCode.Y },
        { name = "Instant Air Bon",      style = "bachira", skillName = "skill3",     playAnimId = "76587445975710", requireFlowDrop = false, kickPower = 29, kickFromLook = true, key = Enum.KeyCode.V },
    }
    for _, cfg in ipairs(BachiraInstantSkills) do InstantSkill.Create(BachiraInstantSection, cfg) end
end

local function TrapHelperVelocity(ball)
    local cfBall = ReplicatedStorage:FindFirstChild("CFBall")
    local vel = cfBall and cfBall:FindFirstChild("velocity")
    if vel and typeof(vel.Value) == "Vector3" then return vel.Value end
    return ball and ball.AssemblyLinearVelocity or Vector3.zero
end

local function TrapHelperCatchable(ball, maxSpeed, maxFallSpeed)
    local vel = TrapHelperVelocity(ball)
    if vel.Magnitude > maxSpeed then return false end
    if vel.Y < -maxFallSpeed then return false end
    return true
end

do
    local NagiCat = Window:CreateCategory(PlayerTab, "Nagi")
    local NagiSection = Library:CreateSection(NagiCat, "Distance Increase", "left")
    local NagiInstantSection = Library:CreateSection(NagiCat, "Instant Skills", "right")

    MoveBuff.Create(NagiSection,
        { name = "Control Ground Distance Increase", animIds = { "77370115011368" }, delay = 0.1, duration = 0.3, maxDistance = 10, defaultDistance = 4 })

    local NagiInstantSkills = {
        { name = "Instant Heavy Variant", style = "nagi", skillName = "Tspecialer", playAnimId = "76587445975710", blockAnimIds = { "130372168910538" }, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }
    for _, cfg in ipairs(NagiInstantSkills) do InstantSkill.Create(NagiInstantSection, cfg) end

    TrapHelper.Create(NagiSection, { name = "Nagi", animId = "73387016994281" })
end

do
    local ShidouCat = Window:CreateCategory(PlayerTab, "Shidou")
    local ShidouSection = Library:CreateSection(ShidouCat, "Distance Increase", "left")
    local ShidouInstantSection = Library:CreateSection(ShidouCat, "Instant Skills", "right")
    local ShidouMacroSection = Library:CreateSection(ShidouCat, "Formless Macro", "right")

    MoveBuff.Create(ShidouSection,
        { name = "Draconic Rush Distance Increase", animIds = { "95359966795185" }, delay = 0.175, duration = 0.625, maxDistance = 10, defaultDistance = 5 })

    local ShidouInstantSkills = {
        { name = "Instant Big Bang Drive", style = "shidou", skillName = "skill4", playAnimId = "76587445975710", blockAnimIds = { "132876424584395" }, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
        { name = "Instant Dragon Drive",   style = "shidou", skillName = "skill5", playAnimId = "76587445975710", blockAnimIds = { "92214239049423" },  kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.Y },
    }
    for _, cfg in ipairs(ShidouInstantSkills) do InstantSkill.Create(ShidouInstantSection, cfg) end
    local Formless = {
        Enabled = false,
        Debounce = false,
        IsMoving = false,
        MoveThread = nil,
        CurrentTrack = nil,
        CurrentKey = Enum.KeyCode.C,
    }

    function Formless.IsReoWithFormless()
        local currentStyle = (Player:GetAttribute("style") or (Player.Character and Player.Character:GetAttribute("style")) or "")
            :lower()
        if currentStyle ~= "reo" then return false end
        local btn = FindSkillButton("skill4")
        local base = btn and btn:FindFirstChild("Base")
        local tn = base and base:FindFirstChild("ToolName")
        if tn and tn.Text:lower():find("formless") then return true end
        local gui = Player:FindFirstChild("PlayerGui")
        local hb = gui and gui:FindFirstChild("Hotbar")
        local bp = hb and hb:FindFirstChild("Backpack")
        local hf = bp and bp:FindFirstChild("Hotbar")
        local s4 = hf and hf:FindFirstChild("skill4")
        local b2 = s4 and s4:FindFirstChild("Base")
        local t2 = b2 and b2:FindFirstChild("ToolName")
        return t2 and t2.Text:lower():find("formless") ~= nil
    end

    function Formless.PlayKickAnim()
        if Formless.CurrentTrack then Formless.CurrentTrack:Stop() end
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://76587445975710"
        Formless.CurrentTrack = hum:LoadAnimation(anim)
        Formless.CurrentTrack:Play()
    end

    function Formless.StopKickAnim()
        if Formless.CurrentTrack then
            Formless.CurrentTrack:Stop()
            Formless.CurrentTrack = nil
        end
    end

    function Formless.StartMoving()
        if Formless.IsMoving then return end
        Formless.IsMoving = true
        Formless.MoveThread = task.spawn(function()
            while Formless.IsMoving do
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local look = hrp.CFrame.LookVector
                    local flat = Vector3.new(look.X, 0, look.Z).Unit
                    hrp.CFrame = hrp.CFrame + flat * 0.3
                end
                task.wait(0.02)
            end
        end)
    end

    function Formless.StopMoving()
        Formless.IsMoving = false
        if Formless.MoveThread then
            pcall(function() task.cancel(Formless.MoveThread) end)
            Formless.MoveThread = nil
        end
    end

    function Formless.Combo()
        if not Formless.Enabled or Formless.Debounce then return end
        local currentStyle = (Player:GetAttribute("style") or (Player.Character and Player.Character:GetAttribute("style")) or "")
            :lower()
        local isShidou = currentStyle == "shidou"
        local isReoFormless = Formless.IsReoWithFormless()
        if not isShidou and not isReoFormless then return end
        if not HasBall() then return end

        local skillToUse = isShidou and "skill1" or "skill4"
        local btn = FindSkillButton(skillToUse)
        if btn and IsSkillOnCooldown(skillToUse) then
            SafeNotify("Formless: on cooldown", 2)
            return
        end

        Formless.Debounce = true
        local char = Player.Character
        if not char then
            Formless.Debounce = false
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            Formless.Debounce = false
            return
        end

        Formless.StartMoving()

        hum.AutoRotate = false
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)

        local cam = Workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
        task.delay(0.1, function()
            if char and char:FindFirstChildOfClass("Humanoid") then
                cam.CameraSubject = char:FindFirstChildOfClass("Humanoid")
                cam.CameraType = Enum.CameraType.Custom
            end
            if hum then hum.AutoRotate = true end
        end)

        Formless.PlayKickAnim()
        task.wait(0.05)

        local kickVec = hrp.CFrame.LookVector + Vector3.new(0, 1, 0) * 50
        pcall(function()
            NET:FireServer(buffer.fromstring(buffers["base"]), { { "kick", 45, false, kickVec } })
        end)

        task.wait(0.1)

        pcall(function()
            NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse } })
        end)

        task.wait(1.0)
        Formless.StopMoving()
        Formless.StopKickAnim()
        Formless.Debounce = false
    end

    function Formless.Start()
        Formless.Enabled = true
        SafeNotify("Formless Macro Enabled (Press " .. tostring(Formless.CurrentKey):gsub("Enum.KeyCode.", "") .. ")", 2,
            "Enable")
    end

    function Formless.Stop()
        Formless.Enabled = false
        Formless.StopMoving()
        Formless.StopKickAnim()
        Formless.Debounce = false
        SafeNotify("Formless Macro Disabled", 2, "Disable")
    end

    Library:CreateToggle(ShidouMacroSection, {
        Name = "Enable",
        Default = false,
        Callback = function(v) if v then Formless.Start() else Formless.Stop() end end
    })

    Library:CreateKeybind(ShidouMacroSection, {
        Name = "Formless",
        Default = Enum.KeyCode.C,
        Mode = "Hold",
        ManualWatermark = true,
        Callback = function(active)
            if active and Formless.Enabled then Formless.Combo() end
        end
    })
end

do
    local KuronaCat = Window:CreateCategory(PlayerTab, "Kurona")
    local KuronaAimbotSection = Library:CreateSection(KuronaCat, "Aimbots", "right")
    SkillAimbot.Create(KuronaAimbotSection, {
        name = "Guard Dog Aimbot",
        style = { "kurona", "reo" },
        animId = "111439544531399",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })
    local KuronaSection = Library:CreateSection(KuronaCat, "Distance Increase", "left")

    MoveBuff.Create(KuronaSection,
        { name = "Close Quarter Dribble Distance Increase", animIds = { "94171465685487" }, delay = 0.18, duration = 2.25, maxDistance = 10, defaultDistance = 5, useMovement = true })
    MoveBuff.Create(KuronaSection,
        { name = "Go-Go! Distance Increase", animIds = { "111297568709238" }, delay = 0.55, duration = 0.35, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(KuronaSection,
        { name = "Fetch Distance Increase", animIds = { "110734304480469" }, delay = 0.125, duration = 0.525, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(KuronaSection,
        { name = "Guard Dog Distance Increase", animIds = { "111439544531399" }, delay = 0.1, duration = 0.35, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(KuronaSection,
        { name = "Speedy Turn Distance Increase", animIds = { "109145068926350" }, delay = 0.05, duration = 0.7, maxDistance = 10, defaultDistance = 5 })
end

do
    local KiyoraCat = Window:CreateCategory(PlayerTab, "Kiyora")
    local KiyoraSection = Library:CreateSection(KiyoraCat, "Distance Increase", "left")
    local KiyoraAimbotSection = Library:CreateSection(KiyoraCat, "Aimbots", "right")
    local KiyoraTrapSection = Library:CreateSection(KiyoraCat, "Trap Helper", "left")

    SkillAimbot.Create(KiyoraAimbotSection, {
        name = "Twister Pass Steal Aimbot",
        style = { "kiyora", "reo" },
        animId = "80730958176662",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })

    MoveBuff.Create(KiyoraSection,
        { name = "Dance Battle Distance Increase", animIds = { "95483906118039" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(KiyoraSection,
        { name = "Twister Pass Steal Distance Increase", animIds = { "80730958176662" }, delay = 0.4, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    TrapHelper.Create(KiyoraTrapSection, { name = "Kiyora", animId = "101043441232233" })
end

do
    local OtoyaCat = Window:CreateCategory(PlayerTab, "Otoya")
    local OtoyaSection = Library:CreateSection(OtoyaCat, "Distance Increase", "left")
    local OtoyaInstantSection = Library:CreateSection(OtoyaCat, "Instant Skills", "right")

    MoveBuff.Create(OtoyaSection,
        { name = "Kusarigama Slash Distance Increase", animIds = { "84772583028665" }, delay = 0, duration = 0.55, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(OtoyaSection,
        { name = "Stealthy Steps Distance Increase", animIds = { "83067604549127" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(OtoyaSection,
        { name = "Shadow Step Distance Increase", animIds = { "133810381664491", "139230259021390" }, delay = 0, duration = 0.3, maxDistance = 10, defaultDistance = 4 })

    for _, cfg in ipairs({
        { name = "Instant Center Of The World", style = "otoya", skillName = "skill5", playAnimId = "76587445975710", playerRadius = 40, blockOnce = false, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }) do InstantSkill.Create(OtoyaInstantSection, cfg) end
end

do
    local KunigamiCat = Window:CreateCategory(PlayerTab, "Kunigami")
    local KunigamiSection = Library:CreateSection(KunigamiCat, "Distance Increase", "left")
    local KunigamiInstantSection = Library:CreateSection(KunigamiCat, "Instant Skills", "right")

    MoveBuff.Create(KunigamiSection,
        { name = "Hero's Instinct Distance Increase", animIds = { "82417661349987" }, delay = 0.33, duration = 1.25, maxDistance = 15, defaultDistance = 6 })
    MoveBuff.Create(KunigamiSection,
        { name = "Heroic Clash Distance Increase", animIds = { "101568232677122" }, delay = 0, duration = 0.5, maxDistance = 10, defaultDistance = 4, useMovement = true })

    local KunigamiInstantSkills = {
        { name = "Instant Demon's Contract", style = "kunigami", skillName = "skill5", playAnimId = "76587445975710", enemyRadius = 50, blockOnce = false, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }
    for _, cfg in ipairs(KunigamiInstantSkills) do InstantSkill.Create(KunigamiInstantSection, cfg) end

    local KunigamiDefenseSection = Library:CreateSection(KunigamiCat, "Justice Header Defense", "right")
    local KunigamiPredictSection = Library:CreateSection(KunigamiCat, "Animation Predict", "right")

    local JusticeHeaderDefense = {
        Enabled = false,
        GoalboxOnly = false,
        AnimationPredict = false,
        Connection = nil,
        LastDefenseTime = 0,
        AnimationTracking = {},
        lastBallOwnerTeam = nil,
        MAX_BALL_DISTANCE = 53,
        MAX_VERTICAL_DISTANCE = 65,
        MinBallSpeed = 100,
        Animations = {
            ["rbxassetid://131229402549770"] = 0.27,
            ["rbxassetid://80063325550268"] = 0.1,
            ["rbxassetid://107869643584417"] = 0.1,
            ["rbxassetid://119133025118742"] = 0.3,
            ["rbxassetid://71166281570409"] = 0.3,
            ["rbxassetid://88985413044521"] = 0.2,
            ["rbxassetid://138598504314653"] = 0.2,
            ["rbxassetid://98869531447623"] = 0.3,
            ["rbxassetid://97103063277850"] = 0.2,
            ["rbxassetid://98975331828005"] = 0.5,
            ["rbxassetid://114955963969575"] = 1.1,
            ["rbxassetid://94714913486342"] = 0.3,
        },
        Goalboxes = {
            A = { minX = -668.15, maxX = -407.51, minZ = 1611.19, maxZ = 1706.13 },
            B = { minX = -668.01, maxX = -407.68, minZ = 841.70, maxZ = 935.59 },
        },
    }
    JusticeHeaderDefense.AnimationSet = {}
    for id in pairs(JusticeHeaderDefense.Animations) do JusticeHeaderDefense.AnimationSet[id] = true end
    JusticeHeaderDefense.AnimationDelayControls = {
        { name = "Isagi",     id = "rbxassetid://131229402549770" },
        { name = "Nagi",      id = "rbxassetid://80063325550268" },
        { name = "Chigiri",   id = "rbxassetid://107869643584417" },
        { name = "Shidou",    id = "rbxassetid://119133025118742" },
        { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
        { name = "Kaiser",    id = "rbxassetid://88985413044521" },
        { name = "Kunigami",  id = "rbxassetid://138598504314653" },
        { name = "Barou",     id = "rbxassetid://98869531447623" },
        { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
        { name = "Reo",       id = "rbxassetid://98975331828005" },
        { name = "Kiyora",    id = "rbxassetid://114955963969575" },
        { name = "Otoya",     id = "rbxassetid://94714913486342" },
    }

    local function JHD_IsKunigami()
        return Player:GetAttribute("style") == "kunigami"
    end

    local function JHD_GetTeam()
        local chars = Workspace:FindFirstChild("characters")
        local my = chars and chars:FindFirstChild(Player.Name)
        local st = my and my:FindFirstChild("state")
        local t = st and st:FindFirstChild("team")
        return t and t.Value or nil
    end

    local function JHD_FindBallOwnerTeam()
        local chars = Workspace:FindFirstChild("characters")
        if not chars then return nil end
        for _, c in ipairs(chars:GetChildren()) do
            if c:FindFirstChild("Ball") then
                local st = c:FindFirstChild("state")
                if st and st:FindFirstChild("team") then return st.team.Value end
            end
        end
        return nil
    end

    local function JHD_IsBallComing(ball, vel, pPos)
        if not ball or vel.Magnitude == 0 then return false end
        return vel.Unit:Dot((pPos - ball.Position).Unit) > math.cos(math.rad(45))
    end

    local function JHD_CanReach(ball, pPos)
        if not ball then return false end
        local hd = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(ball.Position.X, 0, ball.Position.Z)).Magnitude
        return hd <= JusticeHeaderDefense.MAX_BALL_DISTANCE and
            math.abs(pPos.Y - ball.Position.Y) <= JusticeHeaderDefense.MAX_VERTICAL_DISTANCE
    end

    local function JHD_IsInGoalbox(pos, team)
        local g = JusticeHeaderDefense.Goalboxes[team]
        if not g then return false end
        return pos.X >= g.minX and pos.X <= g.maxX and pos.Z >= g.minZ and pos.Z <= g.maxZ
    end

    function JusticeHeaderDefense.PerformDefense()
        if IsSkillOnCooldown("skill4") then return false end
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not rootPart then return false end

        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        rootPart.Velocity = rootPart.Velocity + Vector3.new(0, 55, 0)

        local isXenoOrSolara = ExecutorCaps.IsXeno or ExecutorCaps.IsSolara

        if not isXenoOrSolara then
            local moveDir = rootPart.CFrame:VectorToObjectSpace(hum.MoveDirection)
            local x = math.round(moveDir.X)
            local z = math.round(moveDir.Z)
            local dir = "Front"
            if x == 1 then
                dir = "Right"
            elseif x == -1 then
                dir = "Left"
            elseif z == -1 then
                dir = "Front"
            elseif z == 1 then
                dir = "Back"
            end

            local packet = { "skill4", true, dir }
            local success = false
            pcall(function()
                NET:FireServer(buffer.fromstring(buffers["base"]), { packet })
                success = true
            end)
            if success then return true end
        end

        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        task.wait(0.01)
        VIM:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
        return true
    end

    function JusticeHeaderDefense.ProcessAnimationPredict(myTeam, myPos)
        if not JusticeHeaderDefense.AnimationPredict then return end
        local chars = Workspace:FindFirstChild("characters")
        if not chars then return end
        local shouldDefend = not JusticeHeaderDefense.GoalboxOnly or JHD_IsInGoalbox(myPos, myTeam)
        if not shouldDefend then return end
        local now = tick()
        for _, targetChar in ipairs(chars:GetChildren()) do
            if targetChar.Name ~= Player.Name then
                local st = targetChar:FindFirstChild("state")
                local t = st and st:FindFirstChild("team")
                if t and t.Value ~= myTeam and t.Value ~= "lobby" then
                    local hum = targetChar:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local animator = hum:FindFirstChildOfClass("Animator")
                        if animator then
                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                local animId = track.Animation and track.Animation.AnimationId
                                if animId and track.IsPlaying and JusticeHeaderDefense.AnimationSet[animId] then
                                    local delay = JusticeHeaderDefense.Animations[animId]
                                    local key = targetChar.Name .. "_" .. animId
                                    if not JusticeHeaderDefense.AnimationTracking[key] then
                                        JusticeHeaderDefense.AnimationTracking[key] = {
                                            detectedTime = now,
                                            hasTriggered = false,
                                            delay = delay
                                        }
                                    end
                                    local data = JusticeHeaderDefense.AnimationTracking[key]
                                    if not data.hasTriggered and (now - data.detectedTime) >= data.delay then
                                        if now - JusticeHeaderDefense.LastDefenseTime > 6 then
                                            JusticeHeaderDefense.LastDefenseTime = now
                                            JusticeHeaderDefense.PerformDefense()
                                            data.hasTriggered = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        for key, data in pairs(JusticeHeaderDefense.AnimationTracking) do
            if now - data.detectedTime > 5 then JusticeHeaderDefense.AnimationTracking[key] = nil end
        end
    end

    function JusticeHeaderDefense.ProcessDefense(myTeam, myPos)
        local ownerTeam = JHD_FindBallOwnerTeam()
        if ownerTeam then JusticeHeaderDefense.lastBallOwnerTeam = ownerTeam end
        if HasBall() then return end
        local ball = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
        local cfBall = ReplicatedStorage:FindFirstChild("CFBall")
        if not cfBall or not cfBall:FindFirstChild("velocity") or not ball then return end
        local vel = cfBall.velocity.Value
        local spd = vel.Magnitude
        if spd < JusticeHeaderDefense.MinBallSpeed then return end
        if not JHD_IsBallComing(ball, vel, myPos) then return end
        if not JHD_CanReach(ball, myPos) then return end
        if not JusticeHeaderDefense.lastBallOwnerTeam or not myTeam then return end
        if JusticeHeaderDefense.lastBallOwnerTeam == "lobby" or myTeam == "lobby" then return end
        if JusticeHeaderDefense.lastBallOwnerTeam == myTeam then return end
        local shouldDefend = not JusticeHeaderDefense.GoalboxOnly or JHD_IsInGoalbox(myPos, myTeam)
        if shouldDefend and tick() - JusticeHeaderDefense.LastDefenseTime > 6 then
            JusticeHeaderDefense.LastDefenseTime = tick()
            JusticeHeaderDefense.PerformDefense()
        end
    end

    local function JHD_Update()
        if not JusticeHeaderDefense.Enabled or not Player.Character then return end
        if not JHD_IsKunigami() then return end
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myTeam = JHD_GetTeam()
        if not myTeam or myTeam == "lobby" then return end
        JusticeHeaderDefense.ProcessDefense(myTeam, hrp.Position)
        JusticeHeaderDefense.ProcessAnimationPredict(myTeam, hrp.Position)
    end

    function JusticeHeaderDefense.Start()
        JusticeHeaderDefense.Enabled = true
        JusticeHeaderDefense.Connection = RunService.Heartbeat:Connect(JHD_Update)
        SafeNotify("Justice Header Defense Enabled", 2, "Enable")
    end

    function JusticeHeaderDefense.Stop()
        JusticeHeaderDefense.Enabled = false
        if JusticeHeaderDefense.Connection then
            JusticeHeaderDefense.Connection:Disconnect()
            JusticeHeaderDefense.Connection = nil
        end
        JusticeHeaderDefense.AnimationTracking = {}
        JusticeHeaderDefense.LastDefenseTime = 0
        SafeNotify("Justice Header Defense Disabled", 2, "Disable")
    end

    JusticeHeaderDefense.Toggle = Library:CreateToggle(KunigamiDefenseSection, {
        Name = "Justice Header Defense",
        Default = false,
        Callback = function(v) if v then JusticeHeaderDefense.Start() else JusticeHeaderDefense.Stop() end end
    })

    Library:CreateToggle(KunigamiDefenseSection, {
        Name = "Goalbox Only",
        Default = false,
        Callback = function(v) JusticeHeaderDefense.GoalboxOnly = v end
    })

    Library:CreateToggle(KunigamiDefenseSection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) JusticeHeaderDefense.AnimationPredict = v end
    })

    Library:CreateSlider(KunigamiDefenseSection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 100,
        Default = 100,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) JusticeHeaderDefense.MinBallSpeed = v end
    })

    Library:CreateSlider(KunigamiDefenseSection, {
        Name = "Max Ball Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) JusticeHeaderDefense.MAX_BALL_DISTANCE = v end
    })

    Library:CreateSlider(KunigamiDefenseSection, {
        Name = "Max Vertical Distance",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) JusticeHeaderDefense.MAX_VERTICAL_DISTANCE = v end
    })

    for _, cfg in ipairs(JusticeHeaderDefense.AnimationDelayControls) do
        Library:CreateSlider(KunigamiPredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = JusticeHeaderDefense.Animations[cfg.id] or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v) JusticeHeaderDefense.Animations[cfg.id] = v end
        })
    end

    JusticeHeaderDefense.Keybind = Library:CreateKeybind(KunigamiDefenseSection, {
        Name = "Justice Header Defense",
        Default = Enum.KeyCode.C,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not JHD_IsKunigami() then
                if JusticeHeaderDefense.Keybind then JusticeHeaderDefense.Keybind.Active = false end
                return
            end
            local t = JusticeHeaderDefense.Toggle
            if t and t.SetValue and t.Value ~= active then
                t:SetValue(active and true or false)
            end
        end
    })

    do
        local origStart, origStop = JusticeHeaderDefense.Start, JusticeHeaderDefense.Stop
        JusticeHeaderDefense.Start = function()
            origStart()
            if JusticeHeaderDefense.Keybind then JusticeHeaderDefense.Keybind:SetActive(true) end
        end
        JusticeHeaderDefense.Stop = function()
            origStop()
            if JusticeHeaderDefense.Keybind then JusticeHeaderDefense.Keybind:SetActive(false) end
        end
    end

    task.spawn(function()
        local shown = false
        while true do
            task.wait(1)
            local isStyle = JHD_IsKunigami()
            if isStyle and not shown then
                shown = true
                if Window and Window.Watermark then
                    local kbw = Window.Watermark
                    local kb = JusticeHeaderDefense.Keybind
                    if kbw.UpdateKeybind then
                        kbw:UpdateKeybind("Justice Header Defense", kb.Key and kb.Key.Name or "None", kb.Active)
                    end
                end
            elseif not isStyle and shown then
                shown = false
                if Window and Window.Watermark then
                    local kbw = Window.Watermark
                    if kbw.RemoveKeybind then kbw:RemoveKeybind("Justice Header Defense") end
                end
            end
        end
    end)
end

do
    local YukimiyaCat = Window:CreateCategory(PlayerTab, "Yukimiya")
    local YukimiyaSection = Library:CreateSection(YukimiyaCat, "Distance Increase", "left")

    MoveBuff.Create(YukimiyaSection, {
        name = "Razor Break Distance Increase",
        animIds = {
            ["131681055843039"] = "Front",
            ["114963791456755"] = "Left",
            ["115966658644919"] = "Right",
            ["122404546980503"] = "Back",
            ["70754845580062"] = "RightBack",
            ["128061536134952"] = "LeftBack",
            ["71501932579824"] = "FrontRight",
            ["96632954418440"] = "FrontLeft",
            ["70397727954557"] = "Front",
            ["131196726012273"] = "Front"
        },
        delay = 0.1,
        duration = 0.35,
        maxDistance = 10,
        defaultDistance = 5,
        isDirectional = true
    })
    MoveBuff.Create(YukimiyaSection,
        { name = "Drag Scissors Distance Increase", animIds = { "87853371514282", "71217538180364" }, delay = 0.2, duration = 1.0, maxDistance = 10, defaultDistance = 4, useMovement = true })
    MoveBuff.Create(YukimiyaSection,
        { name = "Counter Distance Increase", animIds = { "93881520867340", "133198924811958" }, delay = 0.4, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })
    MoveBuff.Create(YukimiyaSection,
        { name = "Lane Splitter Distance Increase", animIds = { "126021811944208" }, delay = 0.4, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })
    MoveBuff.Create(YukimiyaSection,
        { name = "Full Breakthrough Distance Increase", animIds = { "96872849167773", "97563821982092", "105545130257223", "134599636818066" }, delay = 0.4, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })
end

do
    local BarouCat = Window:CreateCategory(PlayerTab, "Barou")
    local BarouSection = Library:CreateSection(BarouCat, "Distance Increase", "left")

    MoveBuff.Create(BarouSection,
        { name = "King's Path Distance Increase", animIds = { "73560885704292" }, delay = 0.4, duration = 1.175, maxDistance = 15, defaultDistance = 6 })
    MoveBuff.Create(BarouSection,
        { name = "Chop Dribble Distance Increase", animIds = { "78306683522961", "108343574100752" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })
    MoveBuff.Create(BarouSection,
        { name = "Devour Distance Increase", animIds = { "117921992582675" }, delay = 0.2, maxDistance = 10, defaultDistance = 4, isUnlimited = true, speed = 150 })
end

do
    local KarasuCat = Window:CreateCategory(PlayerTab, "Karasu")
    local KarasuSection = Library:CreateSection(KarasuCat, "Distance Increase", "left")
    local KarasuInstantSection = Library:CreateSection(KarasuCat, "Instant Skills", "right")
    local KarasuAimbotSection = Library:CreateSection(KarasuCat, "Aimbots", "right")

    MoveBuff.Create(KarasuSection,
        { name = "Corvine Feint Distance Increase", animIds = { "79459013513539" }, delay = 1.1, duration = 0.4, maxDistance = 10, defaultDistance = 5 })
    MoveBuff.Create(KarasuSection,
        { name = "Corvine Feint Clash Distance Increase", animIds = { "114866946968143" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(KarasuSection,
        { name = "Silent Steal Distance Increase", animIds = { "89782964116671" }, delay = 0.1, duration = 0.55, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(KarasuSection,
        { name = "Wing Arm Block Land Distance Increase", animIds = { "123994829903056" }, delay = 0.8, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    for _, cfg in ipairs({
        { name = "Instant Dive-Bomb Assault", style = "karasu", skillName = "skill3", playAnimId = "76587445975710", blockOnce = false, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }) do InstantSkill.Create(KarasuInstantSection, cfg) end



    SkillAimbot.Create(KarasuAimbotSection, {
        name = "Silent Steal Aimbot",
        style = { "karasu", "reo" },
        animId = "89782964116671",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })

    SkillAimbot.Create(KarasuAimbotSection, {
        name = "Corvine Feint Aimbot",
        style = { "karasu", "reo" },
        animId = "79459013513539",
        maxDistance = 1000,
        requireBall = false,
        delay = 1.0
    })

    local KarasuDefenseSection = Library:CreateSection(KarasuCat, "Silent Steal Defense", "right")
    local KarasuPredictSection = Library:CreateSection(KarasuCat, "Animation Predict", "right")

    local SilentStealDefense = {
        Enabled = false,
        GoalboxOnly = false,
        AnimationPredict = false,
        Connection = nil,
        LastDefenseTime = 0,
        AnimationTracking = {},
        lastBallOwnerTeam = nil,
        MAX_BALL_DISTANCE = 53,
        MAX_VERTICAL_DISTANCE = 65,
        MinBallSpeed = 100,
        Animations = {
            ["rbxassetid://131229402549770"] = 0.27,
            ["rbxassetid://80063325550268"] = 0.1,
            ["rbxassetid://107869643584417"] = 0.1,
            ["rbxassetid://119133025118742"] = 0.3,
            ["rbxassetid://71166281570409"] = 0.3,
            ["rbxassetid://88985413044521"] = 0.2,
            ["rbxassetid://138598504314653"] = 0.2,
            ["rbxassetid://98869531447623"] = 0.3,
            ["rbxassetid://97103063277850"] = 0.2,
            ["rbxassetid://98975331828005"] = 0.5,
            ["rbxassetid://114955963969575"] = 1.1,
            ["rbxassetid://94714913486342"] = 0.3,
        },
        Goalboxes = {
            A = { minX = -668.15, maxX = -407.51, minZ = 1611.19, maxZ = 1706.13 },
            B = { minX = -668.01, maxX = -407.68, minZ = 841.70, maxZ = 935.59 },
        },
    }
    SilentStealDefense.AnimationSet = {}
    for id in pairs(SilentStealDefense.Animations) do SilentStealDefense.AnimationSet[id] = true end
    SilentStealDefense.AnimationDelayControls = {
        { name = "Isagi",     id = "rbxassetid://131229402549770" },
        { name = "Nagi",      id = "rbxassetid://80063325550268" },
        { name = "Chigiri",   id = "rbxassetid://107869643584417" },
        { name = "Shidou",    id = "rbxassetid://119133025118742" },
        { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
        { name = "Kaiser",    id = "rbxassetid://88985413044521" },
        { name = "Kunigami",  id = "rbxassetid://138598504314653" },
        { name = "Barou",     id = "rbxassetid://98869531447623" },
        { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
        { name = "Reo",       id = "rbxassetid://98975331828005" },
        { name = "Kiyora",    id = "rbxassetid://114955963969575" },
        { name = "Otoya",     id = "rbxassetid://94714913486342" },
    }

    local function KHD_IsKarasu()
        return Player:GetAttribute("style") == "karasu"
    end

    local function KHD_GetTeam()
        local chars = Workspace:FindFirstChild("characters")
        local my = chars and chars:FindFirstChild(Player.Name)
        local st = my and my:FindFirstChild("state")
        local t = st and st:FindFirstChild("team")
        return t and t.Value or nil
    end

    local function KHD_FindBallOwnerTeam()
        local chars = Workspace:FindFirstChild("characters")
        if not chars then return nil end
        for _, c in ipairs(chars:GetChildren()) do
            if c:FindFirstChild("Ball") then
                local st = c:FindFirstChild("state")
                if st and st:FindFirstChild("team") then return st.team.Value end
            end
        end
        return nil
    end

    local function KHD_IsBallComing(ball, vel, pPos)
        if not ball or vel.Magnitude == 0 then return false end
        return vel.Unit:Dot((pPos - ball.Position).Unit) > math.cos(math.rad(45))
    end

    local function KHD_CanReach(ball, pPos)
        if not ball then return false end
        local hd = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(ball.Position.X, 0, ball.Position.Z)).Magnitude
        return hd <= SilentStealDefense.MAX_BALL_DISTANCE and
            math.abs(pPos.Y - ball.Position.Y) <= SilentStealDefense.MAX_VERTICAL_DISTANCE
    end

    local function KHD_IsInGoalbox(pos, team)
        local g = SilentStealDefense.Goalboxes[team]
        if not g then return false end
        return pos.X >= g.minX and pos.X <= g.maxX and pos.Z >= g.minZ and pos.Z <= g.maxZ
    end

    function SilentStealDefense.PerformDefense()
        if IsSkillOnCooldown("skill4") then return false end
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not rootPart then return false end


        local isXenoOrSolara = ExecutorCaps.IsXeno or ExecutorCaps.IsSolara

        if not isXenoOrSolara then
            local success = false
            pcall(function()
                local packets = NET and NET.GetPackets and NET.GetPackets()
                if packets and packets.bytenet_use then
                    packets.bytenet_use.send({ "skill4", true })
                    success = true
                else
                    local bytenetUse = game:GetService("ReplicatedStorage"):FindFirstChild("bytenet_use", true)
                    if bytenetUse then
                        if bytenetUse:IsA("RemoteFunction") then
                            bytenetUse:InvokeServer({ "skill4", true })
                            success = true
                        elseif bytenetUse:IsA("RemoteEvent") then
                            bytenetUse:FireServer({ "skill4", true })
                            success = true
                        end
                    end
                end
            end)
            if success then return true end
        end

        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        task.wait(0.01)
        VIM:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
        return true
    end

    function SilentStealDefense.ProcessAnimationPredict(myTeam, myPos)
        if not SilentStealDefense.AnimationPredict then return end
        local chars = Workspace:FindFirstChild("characters")
        if not chars then return end
        local shouldDefend = not SilentStealDefense.GoalboxOnly or KHD_IsInGoalbox(myPos, myTeam)
        if not shouldDefend then return end
        local now = tick()
        for _, targetChar in ipairs(chars:GetChildren()) do
            if targetChar.Name ~= Player.Name then
                local st = targetChar:FindFirstChild("state")
                local t = st and st:FindFirstChild("team")
                if t and t.Value ~= myTeam and t.Value ~= "lobby" then
                    local hum = targetChar:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local animator = hum:FindFirstChildOfClass("Animator")
                        if animator then
                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                local animId = track.Animation and track.Animation.AnimationId
                                if animId and track.IsPlaying and SilentStealDefense.AnimationSet[animId] then
                                    local delay = SilentStealDefense.Animations[animId]
                                    local key = targetChar.Name .. "_" .. animId
                                    if not SilentStealDefense.AnimationTracking[key] then
                                        SilentStealDefense.AnimationTracking[key] = {
                                            detectedTime = now,
                                            hasTriggered = false,
                                            delay = delay
                                        }
                                    end
                                    local data = SilentStealDefense.AnimationTracking[key]
                                    if not data.hasTriggered and (now - data.detectedTime) >= data.delay then
                                        if now - SilentStealDefense.LastDefenseTime > 6 then
                                            SilentStealDefense.LastDefenseTime = now
                                            SilentStealDefense.PerformDefense()
                                            data.hasTriggered = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        for key, data in pairs(SilentStealDefense.AnimationTracking) do
            if now - data.detectedTime > 5 then SilentStealDefense.AnimationTracking[key] = nil end
        end
    end

    function SilentStealDefense.ProcessDefense(myTeam, myPos)
        local ownerTeam = KHD_FindBallOwnerTeam()
        if ownerTeam then SilentStealDefense.lastBallOwnerTeam = ownerTeam end
        if HasBall() then return end
        local ball = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
        local cfBall = ReplicatedStorage:FindFirstChild("CFBall")
        if not cfBall or not cfBall:FindFirstChild("velocity") or not ball then return end
        local vel = cfBall.velocity.Value
        local spd = vel.Magnitude
        if spd < SilentStealDefense.MinBallSpeed then return end
        if not KHD_IsBallComing(ball, vel, myPos) then return end
        if not KHD_CanReach(ball, myPos) then return end
        if not SilentStealDefense.lastBallOwnerTeam or not myTeam then return end
        if SilentStealDefense.lastBallOwnerTeam == "lobby" or myTeam == "lobby" then return end
        if SilentStealDefense.lastBallOwnerTeam == myTeam then return end
        local shouldDefend = not SilentStealDefense.GoalboxOnly or KHD_IsInGoalbox(myPos, myTeam)
        if shouldDefend and tick() - SilentStealDefense.LastDefenseTime > 6 then
            SilentStealDefense.LastDefenseTime = tick()
            SilentStealDefense.PerformDefense()
        end
    end

    local function KHD_Update()
        if not SilentStealDefense.Enabled or not Player.Character then return end
        if not KHD_IsKarasu() then return end
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myTeam = KHD_GetTeam()
        if not myTeam or myTeam == "lobby" then return end
        SilentStealDefense.ProcessDefense(myTeam, hrp.Position)
        SilentStealDefense.ProcessAnimationPredict(myTeam, hrp.Position)
    end

    function SilentStealDefense.Start()
        SilentStealDefense.Enabled = true
        SilentStealDefense.Connection = RunService.Heartbeat:Connect(KHD_Update)
        SafeNotify("Silent Steal Defense Enabled", 2, "Enable")
    end

    function SilentStealDefense.Stop()
        SilentStealDefense.Enabled = false
        if SilentStealDefense.Connection then
            SilentStealDefense.Connection:Disconnect()
            SilentStealDefense.Connection = nil
        end
        SilentStealDefense.AnimationTracking = {}
        SilentStealDefense.LastDefenseTime = 0
        SafeNotify("Silent Steal Defense Disabled", 2, "Disable")
    end

    SilentStealDefense.Toggle = Library:CreateToggle(KarasuDefenseSection, {
        Name = "Silent Steal Defense",
        Default = false,
        Callback = function(v) if v then SilentStealDefense.Start() else SilentStealDefense.Stop() end end
    })

    Library:CreateToggle(KarasuDefenseSection, {
        Name = "Goalbox Only",
        Default = false,
        Callback = function(v) SilentStealDefense.GoalboxOnly = v end
    })

    Library:CreateToggle(KarasuDefenseSection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) SilentStealDefense.AnimationPredict = v end
    })

    Library:CreateSlider(KarasuDefenseSection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 100,
        Default = 100,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) SilentStealDefense.MinBallSpeed = v end
    })

    Library:CreateSlider(KarasuDefenseSection, {
        Name = "Max Ball Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) SilentStealDefense.MAX_BALL_DISTANCE = v end
    })

    Library:CreateSlider(KarasuDefenseSection, {
        Name = "Max Vertical Distance",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) SilentStealDefense.MAX_VERTICAL_DISTANCE = v end
    })

    for _, cfg in ipairs(SilentStealDefense.AnimationDelayControls) do
        Library:CreateSlider(KarasuPredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = SilentStealDefense.Animations[cfg.id] or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v) SilentStealDefense.Animations[cfg.id] = v end
        })
    end

    SilentStealDefense.Keybind = Library:CreateKeybind(KarasuDefenseSection, {
        Name = "Silent Steal Defense",
        Default = Enum.KeyCode.V,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not KHD_IsKarasu() then
                if SilentStealDefense.Keybind then SilentStealDefense.Keybind.Active = false end
                return
            end
            local t = SilentStealDefense.Toggle
            if t and t.SetValue and t.Value ~= active then
                t:SetValue(active and true or false)
            end
        end
    })

    do
        local origStart, origStop = SilentStealDefense.Start, SilentStealDefense.Stop
        SilentStealDefense.Start = function()
            origStart()
            if SilentStealDefense.Keybind then SilentStealDefense.Keybind:SetActive(true) end
        end
        SilentStealDefense.Stop = function()
            origStop()
            if SilentStealDefense.Keybind then SilentStealDefense.Keybind:SetActive(false) end
        end
    end

    task.spawn(function()
        local shown = false
        while true do
            task.wait(1)
            local isStyle = KHD_IsKarasu()
            if isStyle and not shown then
                shown = true
                if Window and Window.Watermark then
                    local kbw = Window.Watermark
                    local kb = SilentStealDefense.Keybind
                    if kbw.UpdateKeybind then
                        kbw:UpdateKeybind("Silent Steal Defense", kb.Key and kb.Key.Name or "None", kb.Active)
                    end
                end
            elseif not isStyle and shown then
                shown = false
                if Window and Window.Watermark then
                    local kbw = Window.Watermark
                    if kbw.RemoveKeybind then kbw:RemoveKeybind("Silent Steal Defense") end
                end
            end
        end
    end)

    local KFA = {
        Enabled = false,
        Aiming = false,
        CurrentTarget = nil,
        AnimatorConnection = nil,
        AimConnection = nil,
        CharacterConnection = nil,
        Animator = nil,
        ANIMATION_ID = "130479203653055",
        MAX_DISTANCE = 1000,
    }

    function KFA.IsKarasu() return Player:GetAttribute("style") == "karasu" end

    function KFA.GetClosestEnemy()
        local localRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then return nil end
        local myTeam = GetTeam(Player.Name)
        if not myTeam or myTeam == "lobby" then return nil end
        local closest, shortest = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and HasBall(p.Name) then
                local et = GetTeam(p.Name)
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if et and et ~= myTeam and et ~= "lobby" and hum and hum.Health > 0 and hrp then
                    local dist = (hrp.Position - localRoot.Position).Magnitude
                    if dist < KFA.MAX_DISTANCE and dist < shortest then
                        shortest = dist
                        closest = p
                    end
                end
            end
        end
        return closest
    end

    function KFA.AimTick()
        if not KFA.Aiming then
            if KFA.AimConnection then
                KFA.AimConnection:Disconnect()
                KFA.AimConnection = nil
            end
            return
        end
        if not KFA.CurrentTarget or not KFA.CurrentTarget.Character or not HasBall(KFA.CurrentTarget.Name) then
            KFA.CurrentTarget = KFA.GetClosestEnemy()
        end
        local targetPart = KFA.CurrentTarget and KFA.CurrentTarget.Character and
            KFA.CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local pos = cam.CFrame.Position
            cam.CFrame = CFrame.new(pos, targetPart.Position)
        end
    end

    function KFA.StartAiming()
        if KFA.Aiming then return end
        KFA.Aiming = true
        KFA.CurrentTarget = KFA.GetClosestEnemy()
        if KFA.AimConnection then KFA.AimConnection:Disconnect() end
        KFA.AimConnection = RunService.RenderStepped:Connect(KFA.AimTick)
    end

    function KFA.StopAiming()
        KFA.Aiming = false
        KFA.CurrentTarget = nil
        if KFA.AimConnection then
            KFA.AimConnection:Disconnect()
            KFA.AimConnection = nil
        end
    end

    function KFA.AnimatorUpdate()
        if not KFA.Enabled or not KFA.IsKarasu() or not KFA.Animator then return end
        local found = false
        for _, track in ipairs(KFA.Animator:GetPlayingAnimationTracks()) do
            if track.Animation and tostring(track.Animation.AnimationId):find(KFA.ANIMATION_ID) then
                found = true
                break
            end
        end
        if found and not KFA.Aiming then
            KFA.StartAiming()
        elseif not found and KFA.Aiming then
            KFA.StopAiming()
        end
    end

    function KFA.SetupCharacter(char)
        if not KFA.Enabled then return end
        local hum = char:WaitForChild("Humanoid")
        local animator = hum:WaitForChild("Animator")
        KFA.Animator = animator
        if KFA.AnimatorConnection then KFA.AnimatorConnection:Disconnect() end
        KFA.AnimatorConnection = RunService.Heartbeat:Connect(KFA.AnimatorUpdate)
    end

    function KFA.Start()
        if KFA.Enabled then return end
        KFA.Enabled = true
        if Player.Character then KFA.SetupCharacter(Player.Character) end
        if KFA.CharacterConnection then KFA.CharacterConnection:Disconnect() end
        KFA.CharacterConnection = Player.CharacterAdded:Connect(function(c)
            task.wait(1)
            if KFA.Enabled then KFA.SetupCharacter(c) end
        end)
        SafeNotify("Flow Aimbot Enabled", 2, "Enable")
    end

    function KFA.Stop()
        KFA.Enabled = false
        KFA.StopAiming()
        if KFA.AnimatorConnection then
            KFA.AnimatorConnection:Disconnect()
            KFA.AnimatorConnection = nil
        end
        if KFA.CharacterConnection then
            KFA.CharacterConnection:Disconnect()
            KFA.CharacterConnection = nil
        end
        SafeNotify("Flow Aimbot Disabled", 2, "Disable")
    end

    Library:CreateToggle(KarasuAimbotSection, {
        Name = "Flow Aimbot",
        Default = false,
        Callback = function(v) if v then KFA.Start() else KFA.Stop() end end
    })
end

do
    local AikuCat = Window:CreateCategory(PlayerTab, "Aiku")
    local AikuSection = Library:CreateSection(AikuCat, "Distance Increase", "left")
    local AikuVenomSection = Library:CreateSection(AikuCat, "Auto Venom Trap", "right")
    local AikuPredictSection = Library:CreateSection(AikuCat, "Animation Predict", "right")
    local AikuAimbotSection = Library:CreateSection(AikuCat, "Aimbots", "left")
    local AikuRunFlowSection = Library:CreateSection(AikuCat, "Run Flow Aimbot", "left")
    local AikuTrapSection = Library:CreateSection(AikuCat, "Trap Helper", "left")

    TrapHelper.Create(AikuTrapSection, { name = "Aiku", animId = "116422938520670" })

    MoveBuff.Create(AikuSection,
        { name = "Reflex Tackle Distance Increase", animIds = { "113088324958896" }, delay = 0, duration = 0.2, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(AikuSection,
        { name = "Serpent's Sway Off Ball Distance Increase", animIds = { "112312116169687" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(AikuSection,
        { name = "Snake's Grasp Distance Increase", animIds = { "130345228612384" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    local VenomTrapHeight = { value = 5, minBallHeight = 15 }
    Library:CreateSlider(AikuSection, {
        Name = "Venom Trap Height",
        Min = 0,
        Max = 20,
        Default = 5,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) VenomTrapHeight.value = v end
    })
    MoveBuff.Create(AikuSection, {
        name = "Venom Trap Distance Increase",
        animIds = { "116422938520670" },
        delay = 0,
        duration = 0.4,
        maxDistance = 10,
        defaultDistance = 4,
        heightFunc = function(dt)
            if VenomTrapHeight.value > 0 then
                local ball = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
                if ball and ball.Position.Y > VenomTrapHeight.minBallHeight then
                    return VenomTrapHeight.value * dt * 3
                end
            end
            return 0
        end
    })
    MoveBuff.Create(AikuSection,
        { name = "Serpent's Sway Distance Increase", animIds = { "93382093981195", "71920366343806" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })
    MoveBuff.Create(AikuSection,
        { name = "Aiku Run Flow Distance Increase", animIds = { "119774966094217" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })


    local VenomTrap
    VenomTrap = {
        enabled = false,
        goalboxOnly = false,
        animPredict = false,
        useJump = true,
        useFlick = true,
        useImpact = false,
        minBallSpeed = 70,
        skill3MinHeight = 3,
        animations = {
            ["rbxassetid://131229402549770"] = { delay = 0.27 },
            ["rbxassetid://80063325550268"] = { delay = 0.1 },
            ["rbxassetid://107869643584417"] = { delay = 0.1 },
            ["rbxassetid://119133025118742"] = { delay = 0.3 },
            ["rbxassetid://71166281570409"] = { delay = 0.3 },
            ["rbxassetid://88985413044521"] = { delay = 0.2 },
            ["rbxassetid://138598504314653"] = { delay = 0.2 },
            ["rbxassetid://98869531447623"] = { delay = 0.3 },
            ["rbxassetid://97103063277850"] = { delay = 0.2 },
            ["rbxassetid://98975331828005"] = { delay = 0.5 },
            ["rbxassetid://114955963969575"] = { delay = 1.1 },
            ["rbxassetid://94714913486342"] = { delay = 0.3 },
        },
        AnimationDelayControls = {
            { name = "Isagi",     id = "rbxassetid://131229402549770" },
            { name = "Nagi",      id = "rbxassetid://80063325550268" },
            { name = "Chigiri",   id = "rbxassetid://107869643584417" },
            { name = "Shidou",    id = "rbxassetid://119133025118742" },
            { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
            { name = "Kaiser",    id = "rbxassetid://88985413044521" },
            { name = "Kunigami",  id = "rbxassetid://138598504314653" },
            { name = "Barou",     id = "rbxassetid://98869531447623" },
            { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
            { name = "Reo",       id = "rbxassetid://98975331828005" },
            { name = "Kiyora",    id = "rbxassetid://114955963969575" },
            { name = "Otoya",     id = "rbxassetid://94714913486342" },
        },
        isSupported = function(style)
            if style == "aiku" or style == "aiku2" then return true end
            if style == "reo" then
                local name = GetReoSkill4ToolName()
                return name == "Venom Trap"
            end
            return false
        end,
        performDefense = function(ball, myPos, inOwnGoalbox, ctx)
            local isReo = Player:GetAttribute("style") == "reo"
            local skillToUse = isReo and "skill4" or "skill3"

            if IsSkillOnCooldown(skillToUse) then return false end
            if ball and ball.Position.Y < VenomTrap.skill3MinHeight then return false end
            local isPredict = (ctx == nil)
            if VenomTrap.useJump and ball and (ball.Position.Y >= 5 or isPredict) then
                local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hum.Jump = true
                end
                task.wait(0.03)
            end

            if VenomTrap.useFlick and ctx and ctx.isBallDirectlyAtUs then
                local cam = Workspace.CurrentCamera
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local ballPos = ball and ball.Position or myPos
                    local dot = hrp.CFrame.LookVector:Dot((ballPos - hrp.Position).Unit)
                    if dot > 0.5 then
                        if cam then
                            local look = cam.CFrame.LookVector
                            local newLook = Vector3.new(-look.X, 0, -look.Z)
                            if newLook.Magnitude > 0 then
                                newLook = newLook.Unit
                                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + newLook)
                                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + newLook)
                            end
                        end
                    end
                end
            end

            local rel = ReplicatedStorage:FindFirstChild("ByteNetReliable") or AutoDefensive.ByteNetReliable
            if rel then
                pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse } }) end)
                pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse, true } }) end)
            end
            FireUse(skillToUse)

            if not (ExecutorCaps.IsXeno or ExecutorCaps.IsSolara) then
                pcall(function()
                    local pk = NET and NET.GetPackets and NET.GetPackets()
                    if pk and pk.bytenet_use and pk.bytenet_use.send then
                        pk.bytenet_use.send({ skillToUse })
                        pk.bytenet_use.send({ skillToUse, true })
                    end
                end)
            end

            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                local keyCode = isReo and Enum.KeyCode.Four or Enum.KeyCode.Three
                vim:SendKeyEvent(true, keyCode, false, game)
                task.delay(0.03, function()
                    pcall(function() vim:SendKeyEvent(false, keyCode, false, game) end)
                end)
            end)

            return true
        end
    }
    AutoDefensive.Register(VenomTrap)

    VenomTrap.Toggle = Library:CreateToggle(AikuVenomSection, {
        Name = "Auto Venom Trap",
        Default = false,
        Callback = function(v)
            if v and not VenomTrap.isSupported(Player:GetAttribute("style")) then
                if VenomTrap.Toggle and VenomTrap.Toggle.SetValue then
                    VenomTrap.Toggle:SetValue(false)
                end
                return
            end
            VenomTrap.enabled = v
            AutoDefensive.CheckAnyEnabled()
            SafeNotify("Auto Venom Trap " .. (v and "Enabled" or "Disabled"), 2, v and "Enable" or "Disable")
        end
    })

    Library:CreateToggle(AikuVenomSection, {
        Name = "Goalbox Only",
        Default = false,
        Callback = function(v) VenomTrap.goalboxOnly = v end
    })

    Library:CreateToggle(AikuVenomSection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) VenomTrap.animPredict = v end
    })

    Library:CreateToggle(AikuVenomSection, {
        Name = "Use Jump",
        Default = true,
        Callback = function(v) VenomTrap.useJump = v end
    })

    Library:CreateToggle(AikuVenomSection, {
        Name = "Flick",
        Default = true,
        Callback = function(v) VenomTrap.useFlick = v end
    })

    Library:CreateSlider(AikuVenomSection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 300,
        Default = 200,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) VenomTrap.minBallSpeed = v end
    })

    Library:CreateSlider(AikuVenomSection, {
        Name = "Max Ball Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_BALL_DISTANCE = v end
    })

    Library:CreateSlider(AikuVenomSection, {
        Name = "Max Vertical Distance",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_VERTICAL_DISTANCE = v end
    })

    for _, cfg in ipairs(VenomTrap.AnimationDelayControls) do
        Library:CreateSlider(AikuPredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = VenomTrap.animations[cfg.id].delay or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v) VenomTrap.animations[cfg.id].delay = v end
        })
    end

    VenomTrap.Keybind = Library:CreateKeybind(AikuVenomSection, {
        Name = "Auto Venom Trap",
        Default = Enum.KeyCode.V,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not VenomTrap.isSupported(Player:GetAttribute("style")) then
                if VenomTrap.Keybind then VenomTrap.Keybind.Active = false end
                return
            end
            local t = VenomTrap.Toggle
            if t and t.SetValue and t.Value ~= active then t:SetValue(active and true or false) end
        end
    })

    task.spawn(function()
        local shown = false
        while true do
            local isAiku = VenomTrap.isSupported(Player:GetAttribute("style"))
            if not isAiku and VenomTrap.enabled then
                VenomTrap.enabled = false
                if VenomTrap.Toggle and VenomTrap.Toggle.SetValue then VenomTrap.Toggle:SetValue(false) end
                AutoDefensive.CheckAnyEnabled()
            end
            local kbw, kb = Library.KeybindsWindow, VenomTrap.Keybind
            if kbw and kb then
                if isAiku and not shown then
                    kbw:UpdateKeybind("Auto Venom Trap", kb.Key and kb.Key.Name or "None", kb.Active)
                    shown = true
                elseif not isAiku and shown then
                    if kbw.RemoveKeybind then kbw:RemoveKeybind("Auto Venom Trap") end
                    shown = false
                elseif isAiku and shown then
                    kbw:UpdateKeybind("Auto Venom Trap", kb.Key and kb.Key.Name or "None", kb.Active)
                end
            end
            task.wait(0.25)
        end
    end)

    SkillAimbot.Create(AikuAimbotSection, {
        name = "Reflex Tackle Aimbot",
        style = { "aiku", "aiku2", "reo" },
        animId = "113088324958896",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })
    SkillAimbot.Create(AikuAimbotSection, {
        name = "Snake's Grasp Aimbot",
        style = { "aiku", "aiku2", "reo" },
        animId = "130345228612384",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })

    SkillAimbot.Create(AikuRunFlowSection, {
        name = "Run Flow Aimbot",
        style = { "aiku", "aiku2" },
        animId = "119774966094217",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })
end

do
    local SaeCat = Window:CreateCategory(PlayerTab, "Sae")
    local SaeSection = Library:CreateSection(SaeCat, "Distance Increase", "left")
    local SaeVolleySection = Library:CreateSection(SaeCat, "Auto Volley", "left")
    local SaePredictSection = Library:CreateSection(SaeCat, "Animation Predict", "right")
    local SaeInstantSection = Library:CreateSection(SaeCat, "Instant Skills", "right")
    local SaeAimbotSection = Library:CreateSection(SaeCat, "Rabona Nutmeg Aimbot", "right")
    local SaeOSTSection = Library:CreateSection(SaeCat, "OST", "right")

    MoveBuff.Create(SaeSection,
        { name = "Beautiful Destruction Forward", animIds = { "83467654630220", "132788854309681", "138985718053619" }, delay = 0, duration = 0.3, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(SaeSection,
        { name = "Beautiful Destruction Side", animIds = { "77926234700416" }, delay = 0.85, duration = 0.2, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(SaeSection,
        { name = "Rabona Nutmeg Distance Increase", animIds = { "73266865968554" }, delay = 0.05, duration = 0.25, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(SaeSection,
        { name = "Magical Turn Distance Increase", animIds = { "72549924871994" }, delay = 0.3, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })
    MoveBuff.Create(SaeSection,
        { name = "Counter Distance Increase", animIds = { "88690614253524" }, delay = 1.0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    local SaeInstantSkills = {
        { name = "Instant Drive Shot Variant", style = "sae", skillName = "skill3", playAnimId = "76587445975710", blockAnimIds = { "83477287588669" }, requireLastAwaken = true, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }
    for _, cfg in ipairs(SaeInstantSkills) do InstantSkill.Create(SaeInstantSection, cfg) end

    local SaeRabonaNutmeg = { Enabled = false }
    Library:CreateToggle(SaeAimbotSection, {
        Name = "Auto Reflex Rabona Nutmeg Tackling",
        Default = false,
        Callback = function(v) SaeRabonaNutmeg.Enabled = v end
    })

    task.spawn(function()
        local targetEnemy = nil
        local hasCheckedSounds = false
        local tackleAnimId = "109744655458082"
        local nutmegSounds = {
            ["91659314150979"] = true,
            ["113245624532376"] = true,
            ["101213707639775"] = true
        }

        while true do
            task.wait()
            if not SaeRabonaNutmeg.Enabled then
                task.wait(1)
                continue
            end
            local style = Player:GetAttribute("style")
            if style ~= "sae" then
                task.wait(1)
                continue
            end

            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then continue end

            local isTackling = false
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                if track.Animation and tostring(track.Animation.AnimationId):match(tackleAnimId) then
                    isTackling = true
                    break
                end
            end

            if not isTackling then
                targetEnemy = nil
                hasCheckedSounds = false
                continue
            end

            local chars = Workspace:FindFirstChild("characters")
            if not chars then continue end

            if not targetEnemy then
                for _, c in ipairs(chars:GetChildren()) do
                    if c.Name ~= Player.Name and c:FindFirstChild("Ball") then
                        local hrp = c:FindFirstChild("HumanoidRootPart")
                        local myHRP = char:FindFirstChild("HumanoidRootPart")
                        if hrp and myHRP and (hrp.Position - myHRP.Position).Magnitude <= 15 then
                            targetEnemy = c
                            break
                        end
                    end
                end
            else
                local iHaveBall = char:FindFirstChild("Ball") ~= nil
                local enemyHasBall = targetEnemy:FindFirstChild("Ball") ~= nil

                if iHaveBall and not enemyHasBall and not hasCheckedSounds then
                    local enemyHRP = targetEnemy:FindFirstChild("HumanoidRootPart")
                    if enemyHRP then
                        local soundPlayed = false
                        for _, obj in ipairs(enemyHRP:GetChildren()) do
                            if obj:IsA("Sound") then
                                local sid = tostring(obj.SoundId)
                                for reqId, _ in pairs(nutmegSounds) do
                                    if sid:match(reqId) then
                                        soundPlayed = true
                                        break
                                    end
                                end
                            end
                            if soundPlayed then break end
                        end

                        if soundPlayed then
                            local myHRP = char:FindFirstChild("HumanoidRootPart")
                            if myHRP and (enemyHRP.Position - myHRP.Position).Magnitude <= 12 then
                                hasCheckedSounds = true
                                if not IsSaeReflex() then
                                    FireUse("Tspecialer")
                                    task.wait()
                                end
                                FireUse("skill2")
                            end
                        end
                    end
                end
            end
        end
    end)

    local OldSaeOST = {
        Enabled = false,
        OriginalTheme1 = "rbxassetid://113866260852036",
        OriginalTheme2 = "rbxassetid://137186387240470",
        NewTheme1 = "rbxassetid://70979311703713",
        NewTheme2 = "rbxassetid://128623853689708",
    }

    local SaeRunUpOST = {
        Enabled = false,
        OriginalTheme = "rbxassetid://113866260852036",
        NewTheme = "rbxassetid://129960717755080",
    }

    local OldSaeOSTToggle, SaeRunUpOSTToggle

    local function SaeTheme()
        local resources = ReplicatedStorage:FindFirstChild("Resources")
        local sae = resources and resources:FindFirstChild("sae")
        return sae and sae:FindFirstChild("sae theme")
    end

    local function SaeIptoTheme()
        local resources = ReplicatedStorage:FindFirstChild("Resources")
        local sae = resources and resources:FindFirstChild("sae")
        local ipto = sae and sae:FindFirstChild("iptoshobuda")
        return ipto and ipto:FindFirstChild("theme")
    end

    function OldSaeOST.Start()
        if OldSaeOST.Enabled then return end
        if SaeRunUpOST.Enabled then
            SaeRunUpOST.Stop()
            if SaeRunUpOSTToggle and SaeRunUpOSTToggle.SetValue then SaeRunUpOSTToggle:SetValue(false) end
        end
        OldSaeOST.Enabled = true
        pcall(function()
            local s = SaeTheme()
            if s then s.SoundId = OldSaeOST.NewTheme1 end
        end)
        pcall(function()
            local s = SaeIptoTheme()
            if s then s.SoundId = OldSaeOST.NewTheme2 end
        end)
        SafeNotify("Old Sae OST Enabled", 2, "Enable")
    end

    function OldSaeOST.Stop()
        if not OldSaeOST.Enabled then return end
        OldSaeOST.Enabled = false
        pcall(function()
            local s = SaeTheme()
            if s then s.SoundId = OldSaeOST.OriginalTheme1 end
        end)
        pcall(function()
            local s = SaeIptoTheme()
            if s then s.SoundId = OldSaeOST.OriginalTheme2 end
        end)
        SafeNotify("Old Sae OST Disabled", 2, "Disable")
    end

    function SaeRunUpOST.Start()
        if SaeRunUpOST.Enabled then return end
        if OldSaeOST.Enabled then
            OldSaeOST.Stop()
            if OldSaeOSTToggle and OldSaeOSTToggle.SetValue then OldSaeOSTToggle:SetValue(false) end
        end
        SaeRunUpOST.Enabled = true
        pcall(function()
            local s = SaeTheme()
            if s then s.SoundId = SaeRunUpOST.NewTheme end
        end)
        SafeNotify("Sae Run Up OST Enabled", 2, "Enable")
    end

    function SaeRunUpOST.Stop()
        if not SaeRunUpOST.Enabled then return end
        SaeRunUpOST.Enabled = false
        pcall(function()
            local s = SaeTheme()
            if s then s.SoundId = SaeRunUpOST.OriginalTheme end
        end)
        SafeNotify("Sae Run Up OST Disabled", 2, "Disable")
    end

    OldSaeOSTToggle = Library:CreateToggle(SaeOSTSection, {
        Name = "Old Sae OST",
        Default = false,
        Callback = function(v) if v then OldSaeOST.Start() else OldSaeOST.Stop() end end
    })

    SaeRunUpOSTToggle = Library:CreateToggle(SaeOSTSection, {
        Name = "Sae Run Up OST",
        Default = false,
        Callback = function(v) if v then SaeRunUpOST.Start() else SaeRunUpOST.Stop() end end
    })

    SkillAimbot.Create(SaeAimbotSection, {
        name = "Rabona Nutmeg Aimbot",
        style = "sae",
        animId = "73266865968554",
        maxDistance = 1000,
        requireBall = false,
        delay = 0
    })

    local SaeAutoVolley
    SaeAutoVolley = {
        enabled = false,
        enemyGoalboxOnly = false,
        ownGoalboxOnly = false,
        animPredict = false,
        useJump = true,
        useImpact = true,
        predictWindow = 0.55,
        minBallSpeed = 150,
        targetTeam = "both",
        animations = {
            ["rbxassetid://131229402549770"] = { delay = 0.27, maxDistance = 90 },
            ["rbxassetid://80063325550268"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://107869643584417"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://119133025118742"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://71166281570409"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://88985413044521"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://138598504314653"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98869531447623"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://97103063277850"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98975331828005"] = { delay = 0.5, maxDistance = 90 },
            ["rbxassetid://114955963969575"] = { delay = 1.1, maxDistance = 90 },
            ["rbxassetid://94714913486342"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://76200134398422"] = { delay = 0.23, maxDistance = 90 },
        },
        AnimationDelayControls = {
            { name = "Isagi",     id = "rbxassetid://131229402549770" },
            { name = "Nagi",      id = "rbxassetid://80063325550268" },
            { name = "Chigiri",   id = "rbxassetid://107869643584417" },
            { name = "Shidou",    id = "rbxassetid://119133025118742" },
            { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
            { name = "Kaiser",    id = "rbxassetid://88985413044521" },
            { name = "Kunigami",  id = "rbxassetid://138598504314653" },
            { name = "Barou",     id = "rbxassetid://98869531447623" },
            { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
            { name = "Reo",       id = "rbxassetid://98975331828005" },
            { name = "Kiyora",    id = "rbxassetid://114955963969575" },
            { name = "Otoya",     id = "rbxassetid://94714913486342" },
            { name = "Sae",       id = "rbxassetid://76200134398422" },
        },
        isSupported = function(style)
            if style == "sae" then return true end
            if style == "reo" then
                local gui = Player:FindFirstChild("PlayerGui")
                local hb = gui and gui:FindFirstChild("Hotbar")
                local bp = hb and hb:FindFirstChild("Backpack")
                local hf = bp and bp:FindFirstChild("Hotbar")
                local s4 = hf and hf:FindFirstChild("skill4")
                local base = s4 and s4:FindFirstChild("Base")
                local tn = base and base:FindFirstChild("ToolName")
                return tn and tn.Text == "Drive Shot"
            end
            return false
        end,
        performDefense = function(ball, myPos, inOwnGoalbox, ctx)
            local isReo = Player:GetAttribute("style") == "reo"
            local skillToUse = isReo and "skill4" or "skill3"

            if IsSkillOnCooldown(skillToUse) then return false end

            local isPredict = (ctx == nil)
            if SaeAutoVolley.useJump and ball and (ball.Position.Y >= 5 or isPredict) then
                local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hum.Jump = true
                end
                task.wait(0.03)
            end
            pcall(function()
                NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse } })
            end)
            return true
        end
    }
    AutoDefensive.Register(SaeAutoVolley)

    SaeAutoVolley.Toggle = Library:CreateToggle(SaeVolleySection, {
        Name = "Sae Auto Volley",
        Default = false,
        Callback = function(v)
            SaeAutoVolley.enabled = v
            AutoDefensive.CheckAnyEnabled()
            SafeNotify("Sae Auto Volley " .. (v and "Enabled" or "Disabled"), 2, v and "Enable" or "Disable")
        end
    })

    Library:CreateToggle(SaeVolleySection, {
        Name = "Only near/in Enemy Goalbox",
        Default = false,
        Callback = function(v) SaeAutoVolley.enemyGoalboxOnly = v end
    })

    Library:CreateToggle(SaeVolleySection, {
        Name = "Only near/in Goalbox",
        Default = false,
        Callback = function(v) SaeAutoVolley.ownGoalboxOnly = v end
    })

    Library:CreateToggle(SaeVolleySection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) SaeAutoVolley.animPredict = v end
    })

    Library:CreateToggle(SaeVolleySection, {
        Name = "Use Jump",
        Default = true,
        Callback = function(v) SaeAutoVolley.useJump = v end
    })

    Library:CreateSlider(SaeVolleySection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 300,
        Default = 150,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) SaeAutoVolley.minBallSpeed = v end
    })

    Library:CreateSlider(SaeVolleySection, {
        Name = "Max Ball Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_BALL_DISTANCE = v end
    })

    Library:CreateSlider(SaeVolleySection, {
        Name = "Max Vertical Distance",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_VERTICAL_DISTANCE = v end
    })

    for _, cfg in ipairs(SaeAutoVolley.AnimationDelayControls) do
        Library:CreateSlider(SaePredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = SaeAutoVolley.animations[cfg.id] and SaeAutoVolley.animations[cfg.id].delay or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v)
                if SaeAutoVolley.animations[cfg.id] then
                    SaeAutoVolley.animations[cfg.id].delay = v
                end
            end
        })
    end

    SaeAutoVolley.Keybind = Library:CreateKeybind(SaeVolleySection, {
        Name = "Sae Auto Volley",
        Default = Enum.KeyCode.V,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not SaeAutoVolley.isSupported(Player:GetAttribute("style")) then
                if SaeAutoVolley.Keybind then SaeAutoVolley.Keybind.Active = false end
                return
            end
            local t = SaeAutoVolley.Toggle
            if t and t.SetValue and t.Value ~= active then t:SetValue(active and true or false) end
        end
    })

    task.spawn(function()
        local shown = false
        while true do
            local isSae = SaeAutoVolley.isSupported(Player:GetAttribute("style"))
            local kbw, kb = Library.KeybindsWindow, SaeAutoVolley.Keybind
            if kbw and kb then
                if isSae and not shown then
                    kbw:UpdateKeybind("Sae Auto Volley", kb.Key and kb.Key.Name or "None", kb.Active)
                    shown = true
                elseif not isSae and shown then
                    if kbw.RemoveKeybind then kbw:RemoveKeybind("Sae Auto Volley") end
                    shown = false
                elseif isSae and shown then
                    kbw:UpdateKeybind("Sae Auto Volley", kb.Key and kb.Key.Name or "None", kb.Active)
                end
            end
            task.wait(0.25)
        end
    end)
end

do
    local ReoCat = Window:CreateCategory(PlayerTab, "Reo")
    local ReoAimbotSection = Library:CreateSection(ReoCat, "Aimbots", "right")
    SkillAimbot.Create(ReoAimbotSection, {
        name = "Metavision Run Aimbot",
        style = "reo",
        animId = "98607356585505",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })
    SkillAimbot.Create(ReoAimbotSection, {
        name = "Doberman Press Aimbot",
        style = "reo",
        animId = "131986477806061",
        maxDistance = 1000,
        requireBall = true,
        delay = 0
    })
    local ReoSection = Library:CreateSection(ReoCat, "Distance Increase", "left")
    local ReoInstantSection = Library:CreateSection(ReoCat, "Instant Skills", "right")

    MoveBuff.Create(ReoSection,
        { name = "Twin Steps Distance Increase", animIds = { "106299517516303" }, delay = 1.75, duration = 0.15, maxDistance = 10, defaultDistance = 5, useMovement = true })
    MoveBuff.Create(ReoSection,
        { name = "Doberman Press Distance Increase", animIds = { "131986477806061" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(ReoSection,
        { name = "Counter Distance Increase", animIds = { "91010279634862" }, delay = 1.6, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(ReoSection,
        { name = "Metavision Run Distance Increase", animIds = { "98607356585505" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    local ReoInstantSkills = {
        { name = "Instant Chameleon Volley", style = "reo", skillName = "skill5", toolSlot = "skill5", toolText = "Chameleon Volley", enemyRadius = 50, playAnimId = "76587445975710", blockAnimIds = { "127577513196952" }, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }
    for _, cfg in ipairs(ReoInstantSkills) do InstantSkill.Create(ReoInstantSection, cfg) end
end

do
    local DonLorenzoCat = Window:CreateCategory(PlayerTab, "Don Lorenzo")
    local DonLorenzoSection = Library:CreateSection(DonLorenzoCat, "Distance Increase", "left")
    local DonLorenzoDefenseSection = Library:CreateSection(DonLorenzoCat, "Auto Defense", "right")
    local DonLorenzoPredictSection = Library:CreateSection(DonLorenzoCat, "Animation Predict", "right")
    local DonLorenzoTrapSection = Library:CreateSection(DonLorenzoCat, "Trap Helper", "left")

    TrapHelper.Create(DonLorenzoTrapSection, { name = "Don Lorenzo", animId = "90734196141468" })

    MoveBuff.Create(DonLorenzoSection,
        { name = "Zombie Dribble Distance Increase", animIds = { "102294508090597" }, delay = 0.15, duration = 1.7, maxDistance = 15, defaultDistance = 6 })
    MoveBuff.Create(DonLorenzoSection,
        { name = "Defensive Stance Distance Increase", animIds = { "79800224209188", "89915301440000" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })

    local HorrificInterceptHeight = { value = 7, minBallHeight = 15 }
    Library:CreateSlider(DonLorenzoSection, {
        Name = "Horrific Intercept Height",
        Min = 0,
        Max = 20,
        Default = 7,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) HorrificInterceptHeight.value = v end
    })

    MoveBuff.Create(DonLorenzoSection, {
        name = "Horrific Intercept Distance Increase",
        animIds = { "90734196141468" },
        delay = 0,
        duration = 0.4,
        maxDistance = 10,
        defaultDistance = 4,
        heightFunc = function(dt)
            if HorrificInterceptHeight.value > 0 then
                local ball = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
                if ball and ball.Position.Y > HorrificInterceptHeight.minBallHeight then
                    return HorrificInterceptHeight.value * dt * 3
                end
            end
            return 0
        end
    })

    MoveBuff.Create(DonLorenzoSection,
        { name = "Zombie Walk Distance Increase", animIds = { "133733511838098" }, delay = 0.7, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(DonLorenzoSection,
        { name = "Dribble Land Distance Increase", animIds = { "77512595429495" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(DonLorenzoSection,
        { name = "Counter Distance Increase", animIds = { "126033682871844" }, delay = 0.8, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    local AutoDefense
    AutoDefense = {
        enabled = false,
        goalboxOnly = false,
        animPredict = false,
        useJump = true,
        useFlick = true,
        useImpact = false,
        preferSkill = "Skill3",
        minBallSpeed = 70,
        skill3MaxDist = 53,
        skill3MaxVert = 65,
        skill4MaxDist = 53,
        skill4MaxVert = 65,
        skill4MinHeight = 3,
        animations = {
            ["rbxassetid://131229402549770"] = { delay = 0.27 },
            ["rbxassetid://80063325550268"] = { delay = 0.1 },
            ["rbxassetid://107869643584417"] = { delay = 0.1 },
            ["rbxassetid://119133025118742"] = { delay = 0.3 },
            ["rbxassetid://71166281570409"] = { delay = 0.3 },
            ["rbxassetid://88985413044521"] = { delay = 0.2 },
            ["rbxassetid://138598504314653"] = { delay = 0.2 },
            ["rbxassetid://98869531447623"] = { delay = 0.3 },
            ["rbxassetid://97103063277850"] = { delay = 0.2 },
            ["rbxassetid://98975331828005"] = { delay = 0.5 },
            ["rbxassetid://114955963969575"] = { delay = 1.1 },
            ["rbxassetid://94714913486342"] = { delay = 0.3 },
        },
        AnimationDelayControls = {
            { name = "Isagi",     id = "rbxassetid://131229402549770" },
            { name = "Nagi",      id = "rbxassetid://80063325550268" },
            { name = "Chigiri",   id = "rbxassetid://107869643584417" },
            { name = "Shidou",    id = "rbxassetid://119133025118742" },
            { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
            { name = "Kaiser",    id = "rbxassetid://88985413044521" },
            { name = "Kunigami",  id = "rbxassetid://138598504314653" },
            { name = "Barou",     id = "rbxassetid://98869531447623" },
            { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
            { name = "Reo",       id = "rbxassetid://98975331828005" },
            { name = "Kiyora",    id = "rbxassetid://114955963969575" },
            { name = "Otoya",     id = "rbxassetid://94714913486342" },
        },
        isSupported = function(style)
            if style == "donlorenzo" or style == "masterylorenzo" then return true end
            if style == "reo" then
                local name = GetReoSkill4ToolName()
                return name == "Defensive Stance" or name == "Horrific Intercept"
            end
            return false
        end,
        performDefense = function(ball, myPos, inOwnGoalbox, ctx)
            local style = Player:GetAttribute("style")
            local isReo = style == "reo"

            if isReo then
                local reoSkillName = GetReoSkill4ToolName()
                if not reoSkillName or (reoSkillName ~= "Defensive Stance" and reoSkillName ~= "Horrific Intercept") then
                    return false
                end

                local skillToUse = "skill4"
                if IsSkillOnCooldown(skillToUse) then return false end

                local isDefensiveStance = (reoSkillName == "Defensive Stance")
                local isHorrificIntercept = (reoSkillName == "Horrific Intercept")

                local maxDist = isDefensiveStance and AutoDefense.skill3MaxDist or AutoDefense.skill4MaxDist
                local maxVert = isDefensiveStance and AutoDefense.skill3MaxVert or AutoDefense.skill4MaxVert

                local hd = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(ball.Position.X, 0, ball.Position.Z))
                    .Magnitude
                local vd = math.abs(myPos.Y - ball.Position.Y)
                if hd > maxDist or vd > maxVert then return false end

                if isHorrificIntercept and ball and ball.Position.Y < AutoDefense.skill4MinHeight then
                    return false
                end

                if AutoDefense.useJump and ball and ball.Position.Y >= 5 then
                    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        hum.Jump = true
                    end
                    task.wait(0.03)
                end

                local flick = isHorrificIntercept and ((ctx and ctx.isBallDirectlyAtUs) or false)
                if AutoDefense.useFlick and flick then
                    local cam = Workspace.CurrentCamera
                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local ballPos = ball and ball.Position or myPos
                        local dot = hrp.CFrame.LookVector:Dot((ballPos - hrp.Position).Unit)
                        if dot > 0.5 then
                            if cam then
                                local look = cam.CFrame.LookVector
                                local newLook = Vector3.new(-look.X, 0, -look.Z)
                                if newLook.Magnitude > 0 then
                                    newLook = newLook.Unit
                                    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + newLook)
                                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + newLook)
                                end
                            end
                        end
                    end
                end

                pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse } }) end)
                return true
            end

            local function trySkill(sk, doFlick)
                local maxDist = (sk == "skill3") and AutoDefense.skill3MaxDist or AutoDefense.skill4MaxDist
                local maxVert = (sk == "skill3") and AutoDefense.skill3MaxVert or AutoDefense.skill4MaxVert
                local hd = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(ball.Position.X, 0, ball.Position.Z))
                    .Magnitude
                local vd = math.abs(myPos.Y - ball.Position.Y)
                if hd > maxDist or vd > maxVert then return false end

                if sk == "skill4" and ball and ball.Position.Y < AutoDefense.skill4MinHeight then return false end

                if IsSkillOnCooldown(sk) then return false end
                if AutoDefense.useJump and ball and ball.Position.Y >= 5 then
                    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        hum.Jump = true
                    end
                    task.wait(0.03)
                end
                if AutoDefense.useFlick and doFlick then
                    local cam = Workspace.CurrentCamera
                    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local ballPos = ball and ball.Position or myPos
                        local dot = hrp.CFrame.LookVector:Dot((ballPos - hrp.Position).Unit)
                        if dot > 0.5 then
                            if cam then
                                local look = cam.CFrame.LookVector
                                local newLook = Vector3.new(-look.X, 0, -look.Z)
                                if newLook.Magnitude > 0 then
                                    newLook = newLook.Unit
                                    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + newLook)
                                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + newLook)
                                end
                            end
                        end
                    end
                end
                pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { sk } }) end)
                return true
            end

            local flick4 = (ctx and ctx.isBallDirectlyAtUs) or false

            if inOwnGoalbox then
                if trySkill("skill4", flick4) then return true end
                return trySkill("skill3", false)
            else
                if AutoDefense.preferSkill == "Skill4" then
                    if not IsSkillOnCooldown("skill4") then
                        return trySkill("skill4", flick4)
                    else
                        return trySkill("skill3", false)
                    end
                else
                    if not IsSkillOnCooldown("skill3") then
                        return trySkill("skill3", false)
                    else
                        return trySkill("skill4", flick4)
                    end
                end
            end
            return false
        end
    }
    AutoDefensive.Register(AutoDefense)

    AutoDefense.Toggle = Library:CreateToggle(DonLorenzoDefenseSection, {
        Name = "Auto Defense",
        Default = false,
        Callback = function(v)
            if v and not AutoDefense.isSupported(Player:GetAttribute("style")) then
                if AutoDefense.Toggle and AutoDefense.Toggle.SetValue then
                    AutoDefense.Toggle:SetValue(false)
                end
                return
            end
            AutoDefense.enabled = v
            AutoDefensive.CheckAnyEnabled()
            SafeNotify("Auto Defense " .. (v and "Enabled" or "Disabled"), 2, v and "Enable" or "Disable")
        end
    })

    Library:CreateToggle(DonLorenzoDefenseSection, {
        Name = "Goalbox Only",
        Default = false,
        Callback = function(v) AutoDefense.goalboxOnly = v end
    })

    Library:CreateToggle(DonLorenzoDefenseSection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) AutoDefense.animPredict = v end
    })

    Library:CreateToggle(DonLorenzoDefenseSection, {
        Name = "Use Jump",
        Default = true,
        Callback = function(v) AutoDefense.useJump = v end
    })

    Library:CreateToggle(DonLorenzoDefenseSection, {
        Name = "Flick",
        Default = true,
        Callback = function(v) AutoDefense.useFlick = v end
    })

    Library:CreateDropdown(DonLorenzoDefenseSection, {
        Name = "Prefer",
        Options = { "Skill3", "Skill4" },
        CurrentOption = "Skill3",
        MultipleOptions = false,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            AutoDefense.preferSkill = v
        end
    })

    Library:CreateSlider(DonLorenzoDefenseSection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 300,
        Default = 100,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) AutoDefense.minBallSpeed = v end
    })

    Library:CreateSlider(DonLorenzoDefenseSection, {
        Name = "Skill 3 Max Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefense.skill3MaxDist = v end
    })

    Library:CreateSlider(DonLorenzoDefenseSection, {
        Name = "Skill 3 Max Vertical",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefense.skill3MaxVert = v end
    })

    Library:CreateSlider(DonLorenzoDefenseSection, {
        Name = "Skill 4 Max Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefense.skill4MaxDist = v end
    })

    Library:CreateSlider(DonLorenzoDefenseSection, {
        Name = "Skill 4 Max Vertical",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefense.skill4MaxVert = v end
    })

    for _, cfg in ipairs(AutoDefense.AnimationDelayControls) do
        Library:CreateSlider(DonLorenzoPredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = AutoDefense.animations[cfg.id].delay or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v) AutoDefense.animations[cfg.id].delay = v end
        })
    end

    AutoDefense.Keybind = Library:CreateKeybind(DonLorenzoDefenseSection, {
        Name = "Auto Defense",
        Default = Enum.KeyCode.V,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not AutoDefense.isSupported(Player:GetAttribute("style")) then
                if AutoDefense.Keybind then AutoDefense.Keybind.Active = false end
                return
            end
            local t = AutoDefense.Toggle
            if t and t.SetValue and t.Value ~= active then
                t:SetValue(active and true or false)
            end
        end
    })

    task.spawn(function()
        local shown = false
        while true do
            local isDL = AutoDefense.isSupported(Player:GetAttribute("style"))
            if not isDL and AutoDefense.enabled then
                AutoDefense.enabled = false
                if AutoDefense.Toggle and AutoDefense.Toggle.SetValue then AutoDefense.Toggle:SetValue(false) end
                AutoDefensive.CheckAnyEnabled()
            end
            local kbw = Library.KeybindsWindow
            local kb = AutoDefense.Keybind
            if kbw and kb then
                if isDL and not shown then
                    kbw:UpdateKeybind("Auto Defense", kb.Key and kb.Key.Name or "None", kb.Active)
                    shown = true
                elseif not isDL and shown then
                    if kbw.RemoveKeybind then kbw:RemoveKeybind("Auto Defense") end
                    shown = false
                elseif isDL and shown then
                    kbw:UpdateKeybind("Auto Defense", kb.Key and kb.Key.Name or "None", kb.Active)
                end
            end
            task.wait(0.25)
        end
    end)
end

do
    local RinCat = Window:CreateCategory(PlayerTab, "Rin")
    local RinSection = Library:CreateSection(RinCat, "Distance Increase", "left")
    local RinInstantSection = Library:CreateSection(RinCat, "Instant Skills", "right")

    MoveBuff.Create(RinSection,
        { name = "Occlusion Break Distance Increase", animIds = { "116181317759538" }, delay = 0.2, duration = 1.0, maxDistance = 15, defaultDistance = 6 })
    MoveBuff.Create(RinSection,
        { name = "Fake Shot Distance Increase", animIds = { "116367146157633" }, delay = 0.8, duration = 0.4, maxDistance = 10, defaultDistance = 4, stopAnimIds = { "72384842123850" } })

    local RinInstantSkills = {
        { name = "Instant Curve Shot Variant", style = "rin", skillName = "skill3", playAnimId = "76587445975710", enemyRadius = 50, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }
    for _, cfg in ipairs(RinInstantSkills) do InstantSkill.Create(RinInstantSection, cfg) end

    local AutoFinalMatchup = {
        Enabled = false,
        Connection = nil,
        IsSpamming = false,
        SpamDuration = 1.3,
    }

    function AutoFinalMatchup.IsRin() return Player:GetAttribute("style") == "rin" end

    function AutoFinalMatchup.GetFlow()
        local chars = Workspace:FindFirstChild("characters")
        local my = chars and chars:FindFirstChild(Player.Name)
        local st = my and my:FindFirstChild("state")
        local f = st and st:FindFirstChild("flow")
        return f and tonumber(f.Value) or 0
    end

    function AutoFinalMatchup.IsOvertime()
        local ot = ReplicatedStorage:FindFirstChild("workspace")
        ot = ot and ot:FindFirstChild("overtime")
        return ot and ot.Value == true
    end

    function AutoFinalMatchup.HasFlowLock()
        local gui = Player:FindFirstChild("PlayerGui")
        local hb = gui and gui:FindFirstChild("Hotbar")
        local mh = hb and hb:FindFirstChild("MagicHealth")
        local fl = mh and mh:FindFirstChild("FlowLock")
        return fl and fl.Visible
    end

    function AutoFinalMatchup.FindEnemySaeWithBall()
        local myTeam = GetTeam(Player.Name)
        if not myTeam or myTeam == "lobby" then return false end
        local chars = Workspace:FindFirstChild("characters")
        if not chars then return false end
        for _, c in pairs(chars:GetChildren()) do
            if c.Name ~= Player.Name and c:FindFirstChild("Ball") then
                local st = c:FindFirstChild("state")
                local t = st and st:FindFirstChild("team")
                if t and t.Value ~= "lobby" and t.Value ~= myTeam then
                    local tp = Players:FindFirstChild(c.Name)
                    if tp and tp:GetAttribute("style") == "sae" then return true end
                end
            end
        end
        return false
    end

    function AutoFinalMatchup.SpamBaseAwaken()
        if AutoFinalMatchup.IsSpamming then return end
        AutoFinalMatchup.IsSpamming = true
        local st = tick()
        while tick() - st < AutoFinalMatchup.SpamDuration and AutoFinalMatchup.Enabled do
            if AutoFinalMatchup.ByteNetReliable then
                pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { "baseAwaken", false } }) end)
            end
            task.wait(0.1)
        end
        AutoFinalMatchup.IsSpamming = false
    end

    function AutoFinalMatchup.Process()
        if not AutoFinalMatchup.Enabled then return end
        if not AutoFinalMatchup.IsRin() then return end
        if not AutoFinalMatchup.IsOvertime() then return end
        if AutoFinalMatchup.GetFlow() ~= 100 then return end
        if not AutoFinalMatchup.FindEnemySaeWithBall() then return end
        if AutoFinalMatchup.HasFlowLock() then return end
        task.spawn(AutoFinalMatchup.SpamBaseAwaken)
    end

    function AutoFinalMatchup.Start()
        AutoFinalMatchup.Enabled = true
        AutoFinalMatchup.Connection = RunService.Heartbeat:Connect(AutoFinalMatchup.Process)
        SafeNotify("Auto Final Matchup Enabled", 2, "Enable")
    end

    function AutoFinalMatchup.Stop()
        AutoFinalMatchup.Enabled = false
        if AutoFinalMatchup.Connection then
            AutoFinalMatchup.Connection:Disconnect()
            AutoFinalMatchup.Connection = nil
        end
        AutoFinalMatchup.IsSpamming = false
        SafeNotify("Auto Final Matchup Disabled", 2, "Disable")
    end

    Library:CreateToggle(RinSection, {
        Name = "Auto Final Matchup",
        Default = false,
        Callback = function(v) if v then AutoFinalMatchup.Start() else AutoFinalMatchup.Stop() end end
    })
end

do
    local KaiserCat = Window:CreateCategory(PlayerTab, "Kaiser")
    local KaiserSection = Library:CreateSection(KaiserCat, "Distance Increase", "left")

    MoveBuff.Create(KaiserSection,
        { name = "Emperors Path Distance Increase", animIds = { "110660551661470", "95710141714520" }, delay = 0.15, duration = 0.55, maxDistance = 10, defaultDistance = 5, useMovement = true })
    MoveBuff.Create(KaiserSection,
        { name = "Imperial Break Distance Increase", animIds = { "98170073378390" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })
    MoveBuff.Create(KaiserSection,
        { name = "Restriction Charge Distance Increase", animIds = { "87538177157625", "77001258605541" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })

    local KaiserVolleySection = Library:CreateSection(KaiserCat, "Auto Volley", "right")
    local KaiserAutoVolley
    KaiserAutoVolley = {
        enabled = false,
        enemyGoalboxOnly = false,
        animPredict = false,
        useJump = true,
        useFlick = false,
        useImpact = false,
        minBallSpeed = 150,
        targetTeam = "teammate",
        animations = {
            ["rbxassetid://131229402549770"] = { delay = 0.27, maxDistance = 90 },
            ["rbxassetid://80063325550268"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://107869643584417"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://119133025118742"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://71166281570409"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://88985413044521"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://138598504314653"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98869531447623"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://97103063277850"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98975331828005"] = { delay = 0.5, maxDistance = 90 },
            ["rbxassetid://114955963969575"] = { delay = 1.1, maxDistance = 90 },
            ["rbxassetid://94714913486342"] = { delay = 0.3, maxDistance = 90 },
        },
        AnimationDelayControls = {
            { name = "Isagi",     id = "rbxassetid://131229402549770" },
            { name = "Nagi",      id = "rbxassetid://80063325550268" },
            { name = "Chigiri",   id = "rbxassetid://107869643584417" },
            { name = "Shidou",    id = "rbxassetid://119133025118742" },
            { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
            { name = "Kaiser",    id = "rbxassetid://88985413044521" },
            { name = "Kunigami",  id = "rbxassetid://138598504314653" },
            { name = "Barou",     id = "rbxassetid://98869531447623" },
            { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
            { name = "Reo",       id = "rbxassetid://98975331828005" },
            { name = "Kiyora",    id = "rbxassetid://114955963969575" },
            { name = "Otoya",     id = "rbxassetid://94714913486342" },
        },
        isSupported = function(style)
            return style == "masterykaiser"
        end,
        performDefense = function(ball, myPos, inOwnGoalbox, ctx)
            local skillToUse = "skill1"

            if IsSkillOnCooldown(skillToUse) then return false end

            local isPredict = (ctx == nil)
            if KaiserAutoVolley.useJump and ball and (ball.Position.Y >= 5 or isPredict) then
                local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hum.Jump = true
                end
                task.wait(0.03)
            end
            pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse } }) end)
            return true
        end
    }
    AutoDefensive.Register(KaiserAutoVolley)

    KaiserAutoVolley.Toggle = Library:CreateToggle(KaiserVolleySection, {
        Name = "Auto Volley",
        Default = false,
        Callback = function(v)
            KaiserAutoVolley.enabled = v
            AutoDefensive.CheckAnyEnabled()
            SafeNotify("Auto Volley " .. (v and "Enabled" or "Disabled"), 2, v and "Enable" or "Disable")
        end
    })

    Library:CreateToggle(KaiserVolleySection, {
        Name = "Only near/in Enemy Goalbox",
        Default = false,
        Callback = function(v) KaiserAutoVolley.enemyGoalboxOnly = v end
    })

    Library:CreateToggle(KaiserVolleySection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) KaiserAutoVolley.animPredict = v end
    })

    Library:CreateToggle(KaiserVolleySection, {
        Name = "Use Jump",
        Default = true,
        Callback = function(v) KaiserAutoVolley.useJump = v end
    })

    Library:CreateSlider(KaiserVolleySection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 300,
        Default = 150,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) KaiserAutoVolley.minBallSpeed = v end
    })

    Library:CreateSlider(KaiserVolleySection, {
        Name = "Max Ball Distance",
        Min = 10,
        Max = 200,
        Default = 200,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) KaiserAutoVolley.maxBallDistance = v end
    })

    Library:CreateSlider(KaiserVolleySection, {
        Name = "Max Vertical Distance",
        Min = 10,
        Max = 200,
        Default = 100,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) KaiserAutoVolley.maxVerticalDistance = v end
    })

    KaiserAutoVolley.Keybind = Library:CreateKeybind(KaiserVolleySection, {
        Name = "Auto Volley",
        Default = Enum.KeyCode.V,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not KaiserAutoVolley.isSupported(Player:GetAttribute("style")) then
                if KaiserAutoVolley.Keybind then KaiserAutoVolley.Keybind.Active = false end
                return
            end
            local t = KaiserAutoVolley.Toggle
            if t and t.SetValue and t.Value ~= active then t:SetValue(active and true or false) end
        end
    })

    task.spawn(function()
        local shown = false
        while true do
            local isKaiser = KaiserAutoVolley.isSupported(Player:GetAttribute("style"))
            local kbw, kb = Library.KeybindsWindow, KaiserAutoVolley.Keybind
            if kbw and kb then
                if isKaiser and not shown then
                    kbw:UpdateKeybind("Kaiser Auto Volley", kb.Key and kb.Key.Name or "None", kb.Active)
                    shown = true
                elseif not isKaiser and shown then
                    kbw:UpdateKeybind("Kaiser Auto Volley", kb.Key and kb.Key.Name or "None", false)
                    shown = false
                end
            end
            task.wait(0.5)
        end
    end)

    local KaiserPredictSection = Library:CreateSection(KaiserCat, "Animation Predict", "left")
    for _, cfg in ipairs(KaiserAutoVolley.AnimationDelayControls) do
        Library:CreateSlider(KaiserPredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = KaiserAutoVolley.animations[cfg.id] and KaiserAutoVolley.animations[cfg.id].delay or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v)
                if KaiserAutoVolley.animations[cfg.id] then
                    KaiserAutoVolley.animations[cfg.id].delay =
                        v
                end
            end
        })
    end
end

do
    local NelIsagiCat = Window:CreateCategory(PlayerTab, "Nel Isagi")
    local NelIsagiSection = Library:CreateSection(NelIsagiCat, "Distance Increase", "left")
    local NelIsagiVolleySection = Library:CreateSection(NelIsagiCat, "Auto Volley", "right")
    local NelIsagiPredictSection = Library:CreateSection(NelIsagiCat, "Animation Predict", "right")
    local NelIsagiInstantSection = Library:CreateSection(NelIsagiCat, "Instant Skills", "left")

    local NelIsagiTrapSection = Library:CreateSection(NelIsagiCat, "Trap Helper", "left")
    TrapHelper.Create(NelIsagiTrapSection, { name = "Nel Isagi", animId = "111091327490255" })
    MoveBuff.Create(NelIsagiSection,
        { name = "Raumdeuter Distance Increase", animIds = { "81582265162782" }, delay = 0.1, duration = 0.55, maxDistance = 10, defaultDistance = 5 })

    MoveBuff.Create(NelIsagiSection,
        { name = "Meta-Burst-Point Steal Distance Increase", animIds = { "107502555664359" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    local MetaBurstTrapHeight = { value = 5, minBallHeight = 15 }
    Library:CreateSlider(NelIsagiSection, {
        Name = "Meta-Burst Trap Height",
        Min = 0,
        Max = 20,
        Default = 5,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) MetaBurstTrapHeight.value = v end
    })

    MoveBuff.Create(NelIsagiSection, {
        name = "Meta-Burst-Point Trap Distance Increase",
        animIds = { "111091327490255" },
        delay = 0,
        duration = 0.4,
        maxDistance = 10,
        defaultDistance = 4,
        heightFunc = function(dt)
            if MetaBurstTrapHeight.value > 0 then
                local ball = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
                if ball and ball.Position.Y > MetaBurstTrapHeight.minBallHeight then
                    return MetaBurstTrapHeight.value * dt * 3
                end
            end
            return 0
        end
    })

    MoveBuff.Create(NelIsagiSection,
        { name = "Counter Distance Increase", animIds = { "127318371971354" }, delay = 0, duration = 0.4, maxDistance = 10, defaultDistance = 4 })

    local NelIsagiInstantSkills = {
        { name = "Instant Two Gun Volley", style = "nelisagi", skillName = "skill5", playAnimId = "76587445975710", blockAnimIds = { "116783590202845" }, enemyRadius = 40, kickPower = 24, kickVector = Vector3.new(0, 1, 0), key = Enum.KeyCode.V },
    }
    for _, cfg in ipairs(NelIsagiInstantSkills) do InstantSkill.Create(NelIsagiInstantSection, cfg) end

    local AutoVolley = {
        Enabled = false,
        EnemyGoalboxOnly = false,
        OwnGoalboxOnly = false,
        AnimationPredict = false,
        Connection = nil,
        LastDefenseTime = 0,
        AnimationTracking = {},
        lastBallOwnerTeam = nil,
        lastBallOwnerName = nil,
        IsUsingAbility = false,
        UseJump = true,
        MinBallSpeed = 150,
        MAX_BALL_DISTANCE = 53,
        MAX_VERTICAL_DISTANCE = 65,
        PredictWindow = 0.75,
        Animations = {
            ["rbxassetid://131229402549770"] = { delay = 0.27, maxDistance = 90 },
            ["rbxassetid://80063325550268"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://107869643584417"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://119133025118742"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://71166281570409"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://88985413044521"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://138598504314653"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98869531447623"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://97103063277850"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98975331828005"] = { delay = 0.5, maxDistance = 90 },
            ["rbxassetid://114955963969575"] = { delay = 1.1, maxDistance = 90 },
            ["rbxassetid://94714913486342"] = { delay = 0.3, maxDistance = 90 },
        },
        Goalboxes = {
            A = { minX = -668.15, maxX = -407.51, minZ = 1611.19, maxZ = 1706.13 },
            B = { minX = -668.01, maxX = -407.68, minZ = 841.70, maxZ = 935.59 },
        },
        EnemyGoalboxes = {
            A = { minX = -858.81, maxX = -217.79, minZ = 1460.15, maxZ = 1706.26 },
            B = { minX = -859.01, maxX = -217.90, minZ = 841.60, maxZ = 1098.19 },
        },
    }
    AutoVolley.AnimationDelayControls = {
        { name = "Isagi",     id = "rbxassetid://131229402549770" },
        { name = "Nagi",      id = "rbxassetid://80063325550268" },
        { name = "Chigiri",   id = "rbxassetid://107869643584417" },
        { name = "Shidou",    id = "rbxassetid://119133025118742" },
        { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
        { name = "Kaiser",    id = "rbxassetid://88985413044521" },
        { name = "Kunigami",  id = "rbxassetid://138598504314653" },
        { name = "Barou",     id = "rbxassetid://98869531447623" },
        { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
        { name = "Reo",       id = "rbxassetid://98975331828005" },
        { name = "Kiyora",    id = "rbxassetid://114955963969575" },
        { name = "Otoya",     id = "rbxassetid://94714913486342" },
    }

    local AutoVolley
    AutoVolley = {
        enabled = false,
        enemyGoalboxOnly = false,
        ownGoalboxOnly = false,
        animPredict = false,
        useJump = true,
        useImpact = true,
        predictWindow = 0.55,
        minBallSpeed = 150,
        targetTeam = "both",
        animations = {
            ["rbxassetid://131229402549770"] = { delay = 0.27, maxDistance = 90 },
            ["rbxassetid://80063325550268"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://107869643584417"] = { delay = 0.1, maxDistance = 90 },
            ["rbxassetid://119133025118742"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://71166281570409"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://88985413044521"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://138598504314653"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98869531447623"] = { delay = 0.3, maxDistance = 90 },
            ["rbxassetid://97103063277850"] = { delay = 0.2, maxDistance = 90 },
            ["rbxassetid://98975331828005"] = { delay = 0.5, maxDistance = 90 },
            ["rbxassetid://114955963969575"] = { delay = 1.1, maxDistance = 90 },
            ["rbxassetid://94714913486342"] = { delay = 0.3, maxDistance = 90 },
        },
        AnimationDelayControls = {
            { name = "Isagi",     id = "rbxassetid://131229402549770" },
            { name = "Nagi",      id = "rbxassetid://80063325550268" },
            { name = "Chigiri",   id = "rbxassetid://107869643584417" },
            { name = "Shidou",    id = "rbxassetid://119133025118742" },
            { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
            { name = "Kaiser",    id = "rbxassetid://88985413044521" },
            { name = "Kunigami",  id = "rbxassetid://138598504314653" },
            { name = "Barou",     id = "rbxassetid://98869531447623" },
            { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
            { name = "Reo",       id = "rbxassetid://98975331828005" },
            { name = "Kiyora",    id = "rbxassetid://114955963969575" },
            { name = "Otoya",     id = "rbxassetid://94714913486342" },
        },
        isSupported = function(style)
            if style == "nelisagi" then return true end
            if style == "reo" then
                local gui = Player:FindFirstChild("PlayerGui")
                local hb = gui and gui:FindFirstChild("Hotbar")
                local bp = hb and hb:FindFirstChild("Backpack")
                local hf = bp and bp:FindFirstChild("Hotbar")
                local s4 = hf and hf:FindFirstChild("skill4")
                local base = s4 and s4:FindFirstChild("Base")
                local tn = base and base:FindFirstChild("ToolName")
                return tn and tn.Text == "Neo Direct Shot"
            end
            return false
        end,
        performDefense = function(ball, myPos, inOwnGoalbox, ctx)
            local isReo = Player:GetAttribute("style") == "reo"
            local skillToUse = isReo and "skill4" or "skill1"

            if IsSkillOnCooldown(skillToUse) then return false end

            local isPredict = (ctx == nil)
            if AutoVolley.useJump and ball and (ball.Position.Y >= 5 or isPredict) then
                local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hum.Jump = true
                end
                task.wait(0.03)
            end
            pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse } }) end)
            return true
        end
    }
    AutoDefensive.Register(AutoVolley)

    AutoVolley.Toggle = Library:CreateToggle(NelIsagiVolleySection, {
        Name = "Auto Volley",
        Default = false,
        Callback = function(v)
            AutoVolley.enabled = v
            AutoDefensive.CheckAnyEnabled()
            SafeNotify("Auto Volley " .. (v and "Enabled" or "Disabled"), 2, v and "Enable" or "Disable")
        end
    })

    Library:CreateToggle(NelIsagiVolleySection, {
        Name = "Only near/in Enemy Goalbox",
        Default = false,
        Callback = function(v) AutoVolley.enemyGoalboxOnly = v end
    })

    Library:CreateToggle(NelIsagiVolleySection, {
        Name = "Only near/in Goalbox",
        Default = false,
        Callback = function(v) AutoVolley.ownGoalboxOnly = v end
    })

    Library:CreateToggle(NelIsagiVolleySection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) AutoVolley.animPredict = v end
    })

    Library:CreateToggle(NelIsagiVolleySection, {
        Name = "Use Jump",
        Default = true,
        Callback = function(v) AutoVolley.useJump = v end
    })

    Library:CreateSlider(NelIsagiVolleySection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 300,
        Default = 150,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) AutoVolley.minBallSpeed = v end
    })

    Library:CreateSlider(NelIsagiVolleySection, {
        Name = "Max Ball Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_BALL_DISTANCE = v end
    })

    Library:CreateSlider(NelIsagiVolleySection, {
        Name = "Max Vertical Distance",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_VERTICAL_DISTANCE = v end
    })

    for _, cfg in ipairs(AutoVolley.AnimationDelayControls) do
        Library:CreateSlider(NelIsagiPredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = AutoVolley.animations[cfg.id] and AutoVolley.animations[cfg.id].delay or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v) if AutoVolley.animations[cfg.id] then AutoVolley.animations[cfg.id].delay = v end end
        })
    end

    AutoVolley.Keybind = Library:CreateKeybind(NelIsagiVolleySection, {
        Name = "Auto Volley",
        Default = Enum.KeyCode.V,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not AutoVolley.isSupported(Player:GetAttribute("style")) then
                if AutoVolley.Keybind then AutoVolley.Keybind.Active = false end
                return
            end
            local t = AutoVolley.Toggle
            if t and t.SetValue and t.Value ~= active then t:SetValue(active and true or false) end
        end
    })

    task.spawn(function()
        local shown = false
        while true do
            local isNel = AutoVolley.isSupported(Player:GetAttribute("style"))
            local kbw, kb = Library.KeybindsWindow, AutoVolley.Keybind
            if kbw and kb then
                if isNel and not shown then
                    kbw:UpdateKeybind("Auto Volley", kb.Key and kb.Key.Name or "None", kb.Active)
                    shown = true
                elseif not isNel and shown then
                    if kbw.RemoveKeybind then kbw:RemoveKeybind("Auto Volley") end
                    shown = false
                elseif isNel and shown then
                    kbw:UpdateKeybind("Auto Volley", kb.Key and kb.Key.Name or "None", kb.Active)
                end
            end
            task.wait(0.25)
        end
    end)
end

do
    local HioriCat = Window:CreateCategory(PlayerTab, "Hiori")
    local HioriSection = Library:CreateSection(HioriCat, "Distance Increase", "left")
    local HioriFrostSection = Library:CreateSection(HioriCat, "Auto Frost Guard", "right")
    local HioriPredictSection = Library:CreateSection(HioriCat, "Animation Predict", "right")

    MoveBuff.Create(HioriSection,
        { name = "Glacial Cut Distance Increase", animIds = { "116769918041530" }, delay = 0.425, duration = 0.5, maxDistance = 10, defaultDistance = 5 })
    MoveBuff.Create(HioriSection,
        { name = "Glacial Cut Directional Distance Increase", animIds = { "126660944970058", "80537494389388" }, delay = 0.425, duration = 0.5, maxDistance = 10, defaultDistance = 5, useMovement = true })
    MoveBuff.Create(HioriSection,
        { name = "Counter Distance Increase", animIds = { "130243864962113" }, delay = 0.4, duration = 0.4, maxDistance = 10, defaultDistance = 4, useMovement = true })

    local FrostGuard
    FrostGuard = {
        enabled = false,
        goalboxOnly = false,
        animPredict = false,
        useJump = true,
        useImpact = false,
        minBallSpeed = 70,
        skill2MinHeight = 3,
        animations = {
            ["rbxassetid://131229402549770"] = { delay = 0.27 },
            ["rbxassetid://80063325550268"]  = { delay = 0.1 },
            ["rbxassetid://107869643584417"] = { delay = 0.1 },
            ["rbxassetid://119133025118742"] = { delay = 0.3 },
            ["rbxassetid://71166281570409"]  = { delay = 0.3 },
            ["rbxassetid://88985413044521"]  = { delay = 0.2 },
            ["rbxassetid://138598504314653"] = { delay = 0.2 },
            ["rbxassetid://98869531447623"]  = { delay = 0.3 },
            ["rbxassetid://97103063277850"]  = { delay = 0.2 },
            ["rbxassetid://98975331828005"]  = { delay = 0.5 },
            ["rbxassetid://114955963969575"] = { delay = 1.1 },
            ["rbxassetid://94714913486342"]  = { delay = 0.3 },
        },
        AnimationDelayControls = {
            { name = "Isagi",     id = "rbxassetid://131229402549770" },
            { name = "Nagi",      id = "rbxassetid://80063325550268" },
            { name = "Chigiri",   id = "rbxassetid://107869643584417" },
            { name = "Shidou",    id = "rbxassetid://119133025118742" },
            { name = "Yukimiya",  id = "rbxassetid://71166281570409" },
            { name = "Kaiser",    id = "rbxassetid://88985413044521" },
            { name = "Kunigami",  id = "rbxassetid://138598504314653" },
            { name = "Barou",     id = "rbxassetid://98869531447623" },
            { name = "Nel Isagi", id = "rbxassetid://97103063277850" },
            { name = "Reo",       id = "rbxassetid://98975331828005" },
            { name = "Kiyora",    id = "rbxassetid://114955963969575" },
            { name = "Otoya",     id = "rbxassetid://94714913486342" },
        },
        isSupported = function(style)
            if style == "hiori" then return true end
            if style == "reo" then
                local name = GetReoSkill4ToolName()
                return name == "Frost Guard"
            end
            return false
        end,
        performDefense = function(ball, myPos, inOwnGoalbox, ctx)
            local isReo = Player:GetAttribute("style") == "reo"
            local skillToUse = isReo and "skill4" or "skill2"

            if isReo then
                local reoSkillName = GetReoSkill4ToolName()
                if reoSkillName ~= "Frost Guard" then return false end
            end

            if IsSkillOnCooldown(skillToUse) then return false end
            if ball and ball.Position.Y < FrostGuard.skill2MinHeight then return false end
            local isPredict = (ctx == nil)
            if FrostGuard.useJump and ball and (ball.Position.Y >= 5 or isPredict) then
                local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hum.Jump = true
                end
            end

            local rel = ReplicatedStorage:FindFirstChild("ByteNetReliable") or AutoDefensive.ByteNetReliable
            if rel then
                pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse } }) end)
                pcall(function() NET:FireServer(buffer.fromstring(buffers["base"]), { { skillToUse, true } }) end)
            end
            FireUse(skillToUse)

            if not (ExecutorCaps.IsXeno or ExecutorCaps.IsSolara) then
                pcall(function()
                    local pk = NET and NET.GetPackets and NET.GetPackets()
                    if pk and pk.bytenet_use and pk.bytenet_use.send then
                        pk.bytenet_use.send({ skillToUse })
                        pk.bytenet_use.send({ skillToUse, true })
                    end
                end)
            end

            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                local keyToSend = isReo and Enum.KeyCode.Four or Enum.KeyCode.Two
                vim:SendKeyEvent(true, keyToSend, false, game)
                task.delay(0.03, function()
                    pcall(function() vim:SendKeyEvent(false, keyToSend, false, game) end)
                end)
            end)

            return true
        end
    }
    AutoDefensive.Register(FrostGuard)

    FrostGuard.Toggle = Library:CreateToggle(HioriFrostSection, {
        Name = "Auto Frost Guard",
        Default = false,
        Callback = function(v)
            if v and not FrostGuard.isSupported(Player:GetAttribute("style")) then
                if FrostGuard.Toggle and FrostGuard.Toggle.SetValue then
                    FrostGuard.Toggle:SetValue(false)
                end
                return
            end
            FrostGuard.enabled = v
            AutoDefensive.CheckAnyEnabled()
            SafeNotify("Auto Frost Guard " .. (v and "Enabled" or "Disabled"), 2, v and "Enable" or "Disable")
        end
    })

    Library:CreateToggle(HioriFrostSection, {
        Name = "Goalbox Only",
        Default = false,
        Callback = function(v) FrostGuard.goalboxOnly = v end
    })

    Library:CreateToggle(HioriFrostSection, {
        Name = "Animation Predict",
        Default = false,
        Callback = function(v) FrostGuard.animPredict = v end
    })

    Library:CreateToggle(HioriFrostSection, {
        Name = "Use Jump",
        Default = true,
        Callback = function(v) FrostGuard.useJump = v end
    })

    Library:CreateSlider(HioriFrostSection, {
        Name = "Min Ball Speed",
        Min = 0.1,
        Max = 300,
        Default = 200,
        Step = 0.1,
        Suffix = "",
        Callback = function(v) FrostGuard.minBallSpeed = v end
    })

    Library:CreateSlider(HioriFrostSection, {
        Name = "Max Ball Distance",
        Min = 10,
        Max = 200,
        Default = 53,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_BALL_DISTANCE = v end
    })

    Library:CreateSlider(HioriFrostSection, {
        Name = "Max Vertical Distance",
        Min = 10,
        Max = 200,
        Default = 65,
        Step = 1,
        Suffix = " studs",
        Callback = function(v) AutoDefensive.MAX_VERTICAL_DISTANCE = v end
    })

    for _, cfg in ipairs(FrostGuard.AnimationDelayControls) do
        Library:CreateSlider(HioriPredictSection, {
            Name = cfg.name,
            Min = 0,
            Max = 1.5,
            Default = FrostGuard.animations[cfg.id].delay or 0,
            Step = 0.01,
            Suffix = "s",
            Callback = function(v) FrostGuard.animations[cfg.id].delay = v end
        })
    end

    FrostGuard.Keybind = Library:CreateKeybind(HioriFrostSection, {
        Name = "Auto Frost Guard",
        Default = Enum.KeyCode.V,
        Mode = "Toggle",
        ManualWatermark = true,
        Callback = function(active)
            if not FrostGuard.isSupported(Player:GetAttribute("style")) then
                if FrostGuard.Keybind then FrostGuard.Keybind.Active = false end
                return
            end
            local t = FrostGuard.Toggle
            if t and t.SetValue and t.Value ~= active then t:SetValue(active and true or false) end
        end
    })

    task.spawn(function()
        local shown = false
        while true do
            local isHiori = FrostGuard.isSupported(Player:GetAttribute("style"))
            if not isHiori and FrostGuard.enabled then
                FrostGuard.enabled = false
                if FrostGuard.Toggle and FrostGuard.Toggle.SetValue then FrostGuard.Toggle:SetValue(false) end
                AutoDefensive.CheckAnyEnabled()
            end
            local kbw, kb = Library.KeybindsWindow, FrostGuard.Keybind
            if kbw and kb then
                if isHiori and not shown then
                    kbw:UpdateKeybind("Auto Frost Guard", kb.Key and kb.Key.Name or "None", kb.Active)
                    shown = true
                elseif not isHiori and shown then
                    if kbw.RemoveKeybind then kbw:RemoveKeybind("Auto Frost Guard") end
                    shown = false
                elseif isHiori and shown then
                    kbw:UpdateKeybind("Auto Frost Guard", kb.Key and kb.Key.Name or "None", kb.Active)
                end
            end
            task.wait(0.25)
        end
    end)
end

do
    local ESPCamera = Workspace.CurrentCamera
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        ESPCamera = Workspace.CurrentCamera
    end)

    local StyleIndicator = {
        Enabled = false,
        TeamCheck = false,
        OnlyForBallHolder = false,
        TextSize = 18,
        Cache = {},
        Connections = {},
        ShowStyle = true,
        ShowBox = true,
        MaxDistance = 330,
        BoxColor = Color3.fromRGB(149, 138, 204),
        ShowIframe = true,
        ShowFlow = true,
        ShowCooldown = true,
        CooldownAnims = {
            ["109744655458082"] = { name = "Tackle", duration = 3 },
            ["134609545061747"] = { name = "Dribble", duration = 2.7 },
            ["128821996857876"] = { name = "Dribble", duration = 2.7 },
            ["137180116441298"] = { name = "Dribble", duration = 2.7 },
            ["79394729551302"] = { name = "Dash", duration = 4 },
        },
        StyleDisplayNames = {
            sae = "Sae",
            aiku = "Aiku",
            aiku2 = "Mastery Aiku",
            nelisagi = "Nel Isagi",
            barou = "Barou",
            barou_curve = "Barou Curve",
            kunigami = "Kunigami",
            kaiser = "Kaiser",
            masterykaiser = "Mastery Kaiser",
            donlorenzo = "Don Lorenzo",
            masterylorenzo = "Mastery Lorenzo",
            nagi = "Nagi",
            bachira = "Bachira",
            chigiri = "Chigiri",
            isagi = "Isagi",
            rin = "Rin",
            shidou = "Shidou",
            yukimiya = "Yukimiya",
            reo = "Reo",
            kurona = "Kurona",
            hiori = "Hiori",
            kiyora = "Kiyora",
            kiyora_strong = "Kiyora Strong",
            gagamaru = "Gagamaru",
            karasu = "Karasu",
            otoya = "Otoya",
        },
        StyleColors = {
            Isagi = Color3.fromRGB(157, 227, 86),
            Bachira = Color3.fromRGB(232, 220, 116),
            Kurona = Color3.fromRGB(205, 63, 138),
            ["Don Lorenzo"] = Color3.fromRGB(107, 31, 184),
            ["Mastery Lorenzo"] = Color3.fromRGB(160, 92, 230),
            ["Nel Isagi"] = Color3.fromRGB(37, 102, 245),
            Nagi = Color3.fromRGB(227, 222, 222),
            Barou = Color3.fromRGB(120, 2, 2),
            ["Barou Curve"] = Color3.fromRGB(255, 0, 0),
            Chigiri = Color3.fromRGB(255, 0, 102),
            Kaiser = Color3.fromRGB(148, 242, 240),
            ["Mastery Kaiser"] = Color3.fromRGB(115, 199, 197),
            Aiku = Color3.fromRGB(97, 180, 98),
            ["Mastery Aiku"] = Color3.fromRGB(56, 110, 57),
            Rin = Color3.fromRGB(81, 149, 144),
            Sae = Color3.fromRGB(181, 60, 102),
            Gagamaru = Color3.fromRGB(220, 253, 255),
            Shidou = Color3.fromRGB(242, 85, 139),
            Yukimiya = Color3.fromRGB(255, 134, 35),
            Kunigami = Color3.fromRGB(235, 135, 2),
            Reo = Color3.fromRGB(147, 63, 232),
            Hiori = Color3.fromRGB(195, 247, 246),
            Kiyora = Color3.fromRGB(0, 85, 127),
            ["Kiyora Strong"] = Color3.fromRGB(0, 140, 210),
            Karasu = Color3.fromRGB(83, 76, 144),
            Otoya = Color3.fromRGB(135, 195, 124),
            Unknown = Color3.fromRGB(200, 200, 200),
        },
    }

    local function siMakeLine(color, thickness)
        local l = Drawing.new("Line")
        l.Visible = false; l.Thickness = thickness or 1
        l.Color = color or Color3.new(1, 1, 1); l.Transparency = 1
        return l
    end

    local function siGetBoxScreen(model)
        if not model or not ESPCamera then return nil end
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local upOffset, downOffset = 3.0, 3.0
        if hum then
            local hip = hum.HipHeight or 0
            if hip > 0 then downOffset = 2.0 + hip end
        end
        local rootPos = root.Position
        local topScreen = ESPCamera:WorldToViewportPoint(rootPos + Vector3.new(0, upOffset, 0))
        local botScreen = ESPCamera:WorldToViewportPoint(rootPos + Vector3.new(0, -downOffset, 0))
        if topScreen.Z <= 0 or botScreen.Z <= 0 then return nil end
        local height = botScreen.Y - topScreen.Y
        if height < 8 then return nil end
        local width = height * 0.55
        local centerX = (topScreen.X + botScreen.X) * 0.5
        return Vector2.new(centerX - width * 0.5, topScreen.Y), Vector2.new(width, height)
    end

    local function siApplyCornerBox(lines, tl, sz, color)
        local lenX = math.max(4, sz.X * 0.25)
        local lenY = math.max(4, sz.Y * 0.25)
        local x1, y1 = tl.X, tl.Y
        local x2, y2 = tl.X + sz.X, tl.Y + sz.Y
        local v = Vector2.new
        lines[1].From = v(x1, y1); lines[1].To = v(x1 + lenX, y1)
        lines[2].From = v(x1, y1); lines[2].To = v(x1, y1 + lenY)
        lines[3].From = v(x2, y1); lines[3].To = v(x2 - lenX, y1)
        lines[4].From = v(x2, y1); lines[4].To = v(x2, y1 + lenY)
        lines[5].From = v(x1, y2); lines[5].To = v(x1 + lenX, y2)
        lines[6].From = v(x1, y2); lines[6].To = v(x1, y2 - lenY)
        lines[7].From = v(x2, y2); lines[7].To = v(x2 - lenX, y2)
        lines[8].From = v(x2, y2); lines[8].To = v(x2, y2 - lenY)
        for i = 1, 8 do
            lines[i].Color = color; lines[i].Visible = true
        end
    end

    local function siHideCornerBox(lines)
        for i = 1, 8 do lines[i].Visible = false end
    end

    function StyleIndicator.AddPlayer(plr)
        if not ExecutorCaps.Drawing then return end
        if plr == Player then return end
        if StyleIndicator.Cache[plr] then return end
        local label = Drawing.new("Text")
        label.Size = 18; label.Center = true; label.Outline = true
        label.OutlineColor = Color3.new(0, 0, 0)
        label.Color = Color3.new(1, 1, 1); label.Visible = false
        local iframeLabel = Drawing.new("Text")
        iframeLabel.Size = 18; iframeLabel.Center = true; iframeLabel.Outline = true
        iframeLabel.OutlineColor = Color3.new(0, 0, 0)
        iframeLabel.Color = Color3.fromRGB(0, 255, 0); iframeLabel.Visible = false
        local flowLabel = Drawing.new("Text")
        flowLabel.Size = 18; flowLabel.Center = true; flowLabel.Outline = true
        flowLabel.OutlineColor = Color3.new(0, 0, 0)
        flowLabel.Color = Color3.fromRGB(255, 255, 0); flowLabel.Visible = false
        local cooldownLabel = Drawing.new("Text")
        cooldownLabel.Size = 18; cooldownLabel.Center = true; cooldownLabel.Outline = true
        cooldownLabel.OutlineColor = Color3.new(0, 0, 0)
        cooldownLabel.Color = Color3.fromRGB(180, 220, 255); cooldownLabel.Visible = false
        local boxLines = {}
        for i = 1, 8 do boxLines[i] = siMakeLine(StyleIndicator.BoxColor, 1) end
        StyleIndicator.Cache[plr] = {
            player = plr,
            label = label,
            iframeLabel = iframeLabel,
            flowLabel = flowLabel,
            cooldownLabel =
                cooldownLabel,
            boxLines = boxLines,
            Cooldowns = {}
        }
    end

    function StyleIndicator.StartCooldown(cache, id)
        local cfg = id and StyleIndicator.CooldownAnims[id]
        if cfg then cache.Cooldowns[id] = { name = cfg.name, expire = tick() + cfg.duration } end
    end

    function StyleIndicator.SetupCooldownWatcher(cache, char)
        if cache.WatchedChar == char then return end
        if cache.CooldownConn then
            pcall(function() cache.CooldownConn:Disconnect() end)
            cache.CooldownConn = nil
        end
        cache.WatchedChar = char
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        cache.CooldownConn = hum.AnimationPlayed:Connect(function(track)
            local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+")
            StyleIndicator.StartCooldown(cache, id)
        end)
    end

    function StyleIndicator.RemovePlayer(plr)
        local c = StyleIndicator.Cache[plr]
        if c then
            if c.CooldownConn then pcall(function() c.CooldownConn:Disconnect() end) end
            if c.label then
                pcall(function()
                    c.label.Visible = false
                    c.label:Remove()
                end)
            end
            if c.iframeLabel then
                pcall(function()
                    c.iframeLabel.Visible = false
                    c.iframeLabel:Remove()
                end)
            end
            if c.flowLabel then
                pcall(function()
                    c.flowLabel.Visible = false
                    c.flowLabel:Remove()
                end)
            end
            if c.cooldownLabel then
                pcall(function()
                    c.cooldownLabel.Visible = false
                    c.cooldownLabel:Remove()
                end)
            end
            if c.boxLines then
                for i = 1, 8 do
                    pcall(function()
                        c.boxLines[i].Visible = false
                        c.boxLines[i]:Remove()
                    end)
                end
            end
            StyleIndicator.Cache[plr] = nil
        end
    end

    local function siHideCache(cache)
        cache.label.Visible = false
        cache.iframeLabel.Visible = false
        cache.flowLabel.Visible = false
        cache.cooldownLabel.Visible = false
        siHideCornerBox(cache.boxLines)
    end

    function StyleIndicator.UpdateCooldowns(cache, char)
        local now = tick()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+")
                if id and StyleIndicator.CooldownAnims[id] and not cache.Cooldowns[id] then
                    StyleIndicator.StartCooldown(
                        cache, id)
                end
            end
        end
        local parts = {}
        for id, data in pairs(cache.Cooldowns) do
            local left = data.expire - now
            if left > 0 then
                table.insert(parts, data.name .. ": " .. string.format("%.1f", left))
            else
                cache.Cooldowns[id] = nil
            end
        end
        return table.concat(parts, " | ")
    end

    function StyleIndicator.UpdatePlayer(cache, camPos)
        local plr = cache.player
        if not plr or not plr.Parent then
            StyleIndicator.RemovePlayer(plr)
            return
        end

        if StyleIndicator.OnlyForBallHolder and not HasBall(plr.Name) then
            siHideCache(cache)
            return
        end

        if StyleIndicator.TeamCheck then
            local myTeam = GetTeam(Player.Name)
            local theirTeam = GetTeam(plr.Name)
            if myTeam and theirTeam and myTeam == theirTeam then
                siHideCache(cache)
                return
            end
        end

        local char = plr.Character
        if not char or not char.Parent then
            siHideCache(cache)
            return
        end
        StyleIndicator.SetupCooldownWatcher(cache, char)
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            siHideCache(cache)
            return
        end

        local dist = (camPos - root.Position).Magnitude
        if dist > StyleIndicator.MaxDistance then
            siHideCache(cache)
            return
        end

        local boxTL, boxSize = siGetBoxScreen(char)
        if not boxTL then
            siHideCache(cache)
            return
        end

        local styleAttr = tostring(plr:GetAttribute("style") or "")
        local displayName = StyleIndicator.StyleDisplayNames[styleAttr:lower()] or
            (styleAttr ~= "" and styleAttr or "Unknown")
        local color = StyleIndicator.StyleColors[displayName] or StyleIndicator.StyleColors.Unknown

        cache.label.Size = StyleIndicator.TextSize
        cache.iframeLabel.Size = StyleIndicator.TextSize
        cache.flowLabel.Size = StyleIndicator.TextSize
        if cache.cooldownLabel then cache.cooldownLabel.Size = StyleIndicator.TextSize end

        if StyleIndicator.ShowStyle then
            cache.label.Text = displayName
            cache.label.Color = color
            cache.label.Position = Vector2.new(boxTL.X + boxSize.X * 0.5, boxTL.Y - 18)
            cache.label.Visible = true
        else
            cache.label.Visible = false
        end

        if StyleIndicator.ShowBox then
            siApplyCornerBox(cache.boxLines, boxTL, boxSize, StyleIndicator.BoxColor)
        else
            siHideCornerBox(cache.boxLines)
        end

        local bottomY = boxTL.Y + boxSize.Y + 2
        if StyleIndicator.ShowIframe then
            local iframe = HasIFrame(plr.Name)
            if iframe then
                cache.iframeLabel.Text = "Iframe ON"
                cache.iframeLabel.Color = Color3.fromRGB(85, 255, 85)
            else
                cache.iframeLabel.Text = "Iframe OFF"
                cache.iframeLabel.Color = Color3.fromRGB(255, 85, 85)
            end
            cache.iframeLabel.Position = Vector2.new(boxTL.X + boxSize.X * 0.5, bottomY)
            cache.iframeLabel.Visible = true
            bottomY = bottomY + 18
        else
            cache.iframeLabel.Visible = false
        end

        if StyleIndicator.ShowFlow then
            local chars = Workspace:FindFirstChild("characters")
            local c = chars and chars:FindFirstChild(plr.Name)
            local st = c and c:FindFirstChild("state")
            local f = st and st:FindFirstChild("flow")
            local flowVal = f and tonumber(f.Value) or 0
            cache.flowLabel.Text = "Flow: " .. tostring(math.floor(flowVal))
            if flowVal >= 100 then
                cache.flowLabel.Color = Color3.fromRGB(149, 138, 204)
            elseif flowVal >= 60 then
                cache.flowLabel.Color = Color3.fromRGB(255, 200, 0)
            else
                cache.flowLabel.Color = Color3.fromRGB(255, 85, 85)
            end
            cache.flowLabel.Position = Vector2.new(boxTL.X + boxSize.X * 0.5, bottomY)
            cache.flowLabel.Visible = true
            bottomY = bottomY + 18
        else
            cache.flowLabel.Visible = false
        end

        if StyleIndicator.ShowCooldown then
            local cdText = StyleIndicator.UpdateCooldowns(cache, char)
            cache.cooldownLabel.Text = cdText
            cache.cooldownLabel.Position = Vector2.new(boxTL.X + boxSize.X * 0.5, bottomY)
            cache.cooldownLabel.Visible = cdText ~= ""
        else
            cache.cooldownLabel.Visible = false
        end
    end

    function StyleIndicator.Start()
        if StyleIndicator.Enabled or not ExecutorCaps.Drawing then return end
        StyleIndicator.Enabled = true
        for _, plr in ipairs(Players:GetPlayers()) do StyleIndicator.AddPlayer(plr) end
        table.insert(StyleIndicator.Connections, Players.PlayerAdded:Connect(function(plr)
            if StyleIndicator.Enabled then StyleIndicator.AddPlayer(plr) end
        end))
        table.insert(StyleIndicator.Connections, Players.PlayerRemoving:Connect(function(plr)
            StyleIndicator.RemovePlayer(plr)
        end))
        SafeNotify("Indicators Enabled", 2, "Enable")
    end

    function StyleIndicator.Stop()
        if not StyleIndicator.Enabled then return end
        StyleIndicator.Enabled = false
        for plr in pairs(StyleIndicator.Cache) do StyleIndicator.RemovePlayer(plr) end
        StyleIndicator.Cache = {}
        for _, c in ipairs(StyleIndicator.Connections) do pcall(function() c:Disconnect() end) end
        StyleIndicator.Connections = {}
        SafeNotify("Indicators Disabled", 2, "Disable")
    end

    local PlayerAimBeam = {
        Enabled = false,
        Connection = nil,
        Beam = nil,
        CachedBallOwner = nil,
        CachedCharacter = nil,
        LastLookDirection = Vector3.new(0, 0, -1),
        BeamConnections = {},
        LocalPlayerRole = nil,
        RoleCheckAttempts = 0,
        MaxRoleCheckAttempts = 30,
        BeamLength = 50,
        SmoothPos = nil,
        SmoothDir = nil,
        LastOwner = nil,
        Smoothness = 0.35,
    }

    function PlayerAimBeam.GetLocalPlayerRole()
        local chars = Workspace:FindFirstChild("characters")
        local character = chars and chars:FindFirstChild(Player.Name)
        local state = character and character:FindFirstChild("state")
        local roleValue = state and state:FindFirstChild("role")
        return roleValue and roleValue:IsA("StringValue") and roleValue.Value or nil
    end

    function PlayerAimBeam.CheckRole()
        if PlayerAimBeam.LocalPlayerRole == "GK" then return false end
        PlayerAimBeam.LocalPlayerRole = PlayerAimBeam.GetLocalPlayerRole()
        if not PlayerAimBeam.LocalPlayerRole then
            PlayerAimBeam.RoleCheckAttempts = PlayerAimBeam.RoleCheckAttempts + 1
            return PlayerAimBeam.RoleCheckAttempts > PlayerAimBeam.MaxRoleCheckAttempts
        end
        return PlayerAimBeam.LocalPlayerRole ~= "GK"
    end

    function PlayerAimBeam.FindBallAndOwner()
        if not PlayerAimBeam.CheckRole() then return nil, nil end
        if PlayerAimBeam.CachedBallOwner and PlayerAimBeam.CachedCharacter and PlayerAimBeam.CachedCharacter.Parent and PlayerAimBeam.CachedCharacter:FindFirstChild("Ball") then
            return PlayerAimBeam.CachedBallOwner, PlayerAimBeam.CachedCharacter
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character and plr.Character:FindFirstChild("Ball") then
                PlayerAimBeam.CachedBallOwner, PlayerAimBeam.CachedCharacter = plr, plr.Character
                return plr, plr.Character
            end
        end
        PlayerAimBeam.CachedBallOwner, PlayerAimBeam.CachedCharacter = nil, nil
        return nil, nil
    end

    function PlayerAimBeam.GetLookDirection(character)
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return Vector3.new(0, 0, -1) end
        local dir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
        return dir.Magnitude > 0 and dir.Unit or Vector3.new(0, 0, -1)
    end

    function PlayerAimBeam.Hide()
        if PlayerAimBeam.Beam then PlayerAimBeam.Beam.Position = Vector3.new(0, -1000, 0) end
        PlayerAimBeam.SmoothPos, PlayerAimBeam.SmoothDir, PlayerAimBeam.LastOwner = nil, nil, nil
    end

    function PlayerAimBeam.UpdateBeam()
        if not PlayerAimBeam.Beam or not PlayerAimBeam.CheckRole() then
            PlayerAimBeam.Hide()
            return
        end
        local owner, character = PlayerAimBeam.FindBallAndOwner()
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local head = character and character:FindFirstChild("Head")
        if not hum or not head then
            PlayerAimBeam.Hide()
            return
        end
        local lookDirection = PlayerAimBeam.GetLookDirection(character)
        if PlayerAimBeam.LastOwner ~= owner then
            PlayerAimBeam.SmoothPos, PlayerAimBeam.SmoothDir, PlayerAimBeam.LastOwner = head.Position, lookDirection,
                owner
        else
            PlayerAimBeam.SmoothPos = PlayerAimBeam.SmoothPos and
                PlayerAimBeam.SmoothPos:Lerp(head.Position, PlayerAimBeam.Smoothness) or head.Position
            local dir = PlayerAimBeam.SmoothDir and PlayerAimBeam.SmoothDir:Lerp(lookDirection, PlayerAimBeam.Smoothness) or
                lookDirection
            PlayerAimBeam.SmoothDir = dir.Magnitude > 0.001 and dir.Unit or lookDirection
        end
        PlayerAimBeam.LastLookDirection = PlayerAimBeam.SmoothDir
        local startPos = PlayerAimBeam.SmoothPos
        local endPos = startPos + PlayerAimBeam.SmoothDir * PlayerAimBeam.BeamLength
        PlayerAimBeam.Beam.Size = Vector3.new(0.2, 0.2, PlayerAimBeam.BeamLength)
        PlayerAimBeam.Beam.CFrame = CFrame.new((startPos + endPos) / 2, endPos)
    end

    function PlayerAimBeam.TrackRole()
        local chars = Workspace:FindFirstChild("characters")
        local character = chars and chars:FindFirstChild(Player.Name)
        local state = character and character:FindFirstChild("state")
        local roleValue = state and state:FindFirstChild("role")
        if roleValue and roleValue:IsA("StringValue") then
            table.insert(PlayerAimBeam.BeamConnections, roleValue.Changed:Connect(function(v)
                PlayerAimBeam.LocalPlayerRole, PlayerAimBeam.RoleCheckAttempts = v, 0
            end))
        end
    end

    function PlayerAimBeam.TrackPlayers()
        table.insert(PlayerAimBeam.BeamConnections, Player.CharacterAdded:Connect(function()
            task.wait(1)
            PlayerAimBeam.LocalPlayerRole, PlayerAimBeam.RoleCheckAttempts = nil, 0
            PlayerAimBeam.TrackRole()
        end))
        if Player.Character then PlayerAimBeam.TrackRole() end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                table.insert(PlayerAimBeam.BeamConnections,
                    plr.CharacterAdded:Connect(function()
                        PlayerAimBeam.CachedBallOwner, PlayerAimBeam.CachedCharacter =
                            nil, nil
                    end))
            end
        end
        table.insert(PlayerAimBeam.BeamConnections, Players.PlayerAdded:Connect(function(plr)
            table.insert(PlayerAimBeam.BeamConnections,
                plr.CharacterAdded:Connect(function()
                    PlayerAimBeam.CachedBallOwner, PlayerAimBeam.CachedCharacter = nil,
                        nil
                end))
        end))
    end

    function PlayerAimBeam.Start()
        if PlayerAimBeam.Enabled then return end
        PlayerAimBeam.Enabled = true
        if PlayerAimBeam.Beam then pcall(function() PlayerAimBeam.Beam:Destroy() end) end
        PlayerAimBeam.Beam = Instance.new("Part")
        PlayerAimBeam.Beam.Name = "PlayerAimBeamPart"
        PlayerAimBeam.Beam.Material = Enum.Material.Neon
        PlayerAimBeam.Beam.Color = Color3.fromRGB(128, 128, 128)
        PlayerAimBeam.Beam.Transparency = 0.7
        PlayerAimBeam.Beam.Anchored = true
        PlayerAimBeam.Beam.CanCollide = false
        PlayerAimBeam.Beam.Parent = Workspace.Terrain
        PlayerAimBeam.Hide()
        PlayerAimBeam.TrackPlayers()
        PlayerAimBeam.Connection = RunService.RenderStepped:Connect(PlayerAimBeam.UpdateBeam)
        SafeNotify("Player Aim Beam Enabled", 2, "Enable")
    end

    function PlayerAimBeam.Stop()
        PlayerAimBeam.Enabled = false
        if PlayerAimBeam.Connection then
            PlayerAimBeam.Connection:Disconnect()
            PlayerAimBeam.Connection = nil
        end
        for _, c in ipairs(PlayerAimBeam.BeamConnections) do pcall(function() c:Disconnect() end) end
        PlayerAimBeam.BeamConnections = {}
        if PlayerAimBeam.Beam then
            pcall(function() PlayerAimBeam.Beam:Destroy() end)
            PlayerAimBeam.Beam = nil
        end
        PlayerAimBeam.CachedBallOwner, PlayerAimBeam.CachedCharacter, PlayerAimBeam.LocalPlayerRole = nil, nil, nil
        PlayerAimBeam.SmoothPos, PlayerAimBeam.SmoothDir, PlayerAimBeam.LastOwner = nil, nil, nil
        PlayerAimBeam.RoleCheckAttempts = 0
        SafeNotify("Player Aim Beam Disabled", 2, "Disable")
    end

    local SelfChams = { Enabled = false, ChamsColor = Color3.fromRGB(149, 138, 204), Cache = {} }

    local function chamsApplyToPart(v, color, parts)
        if parts[v] then return end
        local origPhys = v.CustomPhysicalProperties or PhysicalProperties.new(v.Material)
        parts[v] = {
            mat = v.Material,
            color = v.Color,
            tex = v:IsA("MeshPart") and v.TextureID or nil,
            canCollide = v
                .CanCollide,
            physProps = origPhys
        }
        pcall(function()
            v.Material = Enum.Material.ForceField
            v.Color = color
            v.CanCollide = parts[v].canCollide
            v.CustomPhysicalProperties = origPhys
            if v:IsA("MeshPart") then v.TextureID = "" end
        end)
    end

    local function chamsRestoreAll(cache)
        if cache._selfHeartbeat then
            pcall(function() cache._selfHeartbeat:Disconnect() end)
            cache._selfHeartbeat = nil
        end
        if cache._chamsParts then
            for part, orig in pairs(cache._chamsParts) do
                if part and part.Parent then
                    pcall(function()
                        part.Material = orig.mat
                        part.Color = orig.color
                        part.CanCollide = orig.canCollide
                        if orig.tex ~= nil and part:IsA("MeshPart") then part.TextureID = orig.tex end
                    end)
                end
            end
            cache._chamsParts = nil
        end
        cache.model = nil
    end

    local function chamsShouldApply(v)
        if not v:IsA("BasePart") then return false end
        if v.Name == "HumanoidRootPart" then return false end
        if v.Parent and v.Parent:IsA("Tool") then return false end
        if v:FindFirstAncestorOfClass("Accessory") then return false end
        return true
    end

    function SelfChams.Apply()
        local char = Player.Character
        if not char or not char.Parent then return end
        if SelfChams.Cache.model ~= char then
            if SelfChams.Cache._chamsParts then
                for part, orig in pairs(SelfChams.Cache._chamsParts) do
                    if part and part.Parent then
                        pcall(function()
                            part.Material = orig.mat
                            part.Color = orig.color
                            part.CanCollide = orig.canCollide
                            if orig.tex ~= nil and part:IsA("MeshPart") then part.TextureID = orig.tex end
                        end)
                    end
                end
            end
            SelfChams.Cache.model = char
            SelfChams.Cache._chamsParts = {}
        end
        local parts = SelfChams.Cache._chamsParts
        for _, v in ipairs(char:GetDescendants()) do
            if chamsShouldApply(v) then
                chamsApplyToPart(v, SelfChams.ChamsColor, parts)
                pcall(function()
                    v.Material = Enum.Material.ForceField
                    v.Color = SelfChams.ChamsColor
                    if v:IsA("MeshPart") then v.TextureID = "" end
                end)
            end
        end
    end

    function SelfChams.Start()
        if SelfChams.Enabled then return end
        SelfChams.Enabled = true
        SelfChams.Apply()
        if SelfChams.Cache.charAdded then SelfChams.Cache.charAdded:Disconnect() end
        SelfChams.Cache.charAdded = Player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if SelfChams.Enabled then SelfChams.Apply() end
        end)
        SelfChams.Cache._selfHeartbeat = RunService.RenderStepped:Connect(function()
            if SelfChams.Enabled then
                SelfChams
                    .Apply()
            end
        end)
        SafeNotify("Self Chams Enabled", 2, "Enable")
    end

    function SelfChams.Stop()
        SelfChams.Enabled = false
        chamsRestoreAll(SelfChams.Cache)
        if SelfChams.Cache.charAdded then
            pcall(function() SelfChams.Cache.charAdded:Disconnect() end)
            SelfChams.Cache.charAdded = nil
        end
        SafeNotify("Self Chams Disabled", 2, "Disable")
    end

    RunService.Heartbeat:Connect(function()
        if not ESPCamera then return end
        if not StyleIndicator.Enabled then return end
        local camPos = ESPCamera.CFrame.Position
        for _, cache in pairs(StyleIndicator.Cache) do
            StyleIndicator.UpdatePlayer(cache, camPos)
        end
    end)

    Library:CreateToggle(ESPSection, {
        Name = "Indicators",
        Default = false,
        Callback = function(v) if v then StyleIndicator.Start() else StyleIndicator.Stop() end end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Style Indicator",
        Default = true,
        Callback = function(v) StyleIndicator.ShowStyle = v end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Show Box",
        Default = true,
        Callback = function(v) StyleIndicator.ShowBox = v end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Iframe Indicator",
        Default = true,
        Callback = function(v) StyleIndicator.ShowIframe = v end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Flow Indicator",
        Default = true,
        Callback = function(v) StyleIndicator.ShowFlow = v end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Cooldown Indicator",
        Default = true,
        Callback = function(v)
            StyleIndicator.ShowCooldown = v
            if not v then
                for _, cache in pairs(StyleIndicator.Cache) do
                    cache.Cooldowns = {}
                    if cache.cooldownLabel then cache.cooldownLabel.Visible = false end
                end
            end
        end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Team Check",
        Default = false,
        Callback = function(v) StyleIndicator.TeamCheck = v end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Only For Ball Holder",
        Default = false,
        Callback = function(v) StyleIndicator.OnlyForBallHolder = v end
    })

    Library:CreateSlider(ESPSection, {
        Name = "Text Size",
        Min = 8,
        Max = 32,
        Default = 18,
        Step = 1,
        Suffix = "px",
        Callback = function(v) StyleIndicator.TextSize = v end
    })

    Library:CreateSlider(ESPSection, {
        Name = "Indicators Range",
        Min = 100,
        Max = 1500,
        Default = 330,
        Step = 10,
        Suffix = " studs",
        Callback = function(v) StyleIndicator.MaxDistance = v end
    })

    Library:CreateColorPicker(ESPSection, {
        Name = "Box Color",
        Default = Color3.fromRGB(149, 138, 204),
        Callback = function(c) StyleIndicator.BoxColor = c end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Player Aim Beam",
        Default = false,
        Callback = function(v) if v then PlayerAimBeam.Start() else PlayerAimBeam.Stop() end end
    })

    Library:CreateSlider(ESPSection, {
        Name = "Aim Beam Length",
        Min = 10,
        Max = 300,
        Default = 50,
        Step = 5,
        Suffix = " studs",
        Callback = function(v) PlayerAimBeam.BeamLength = v end
    })

    Library:CreateToggle(ESPSection, {
        Name = "Self Chams",
        Default = false,
        Callback = function(v) if v then SelfChams.Start() else SelfChams.Stop() end end
    })

    Library:CreateColorPicker(ESPSection, {
        Name = "Chams Color",
        Default = Color3.fromRGB(149, 138, 204),
        Callback = function(c) SelfChams.ChamsColor = c end
    })
end

do
    local BallMetaCat = Window:CreateCategory(VisualsTab, "Ball Metavision")
    local BallMetaSection = Library:CreateSection(BallMetaCat, "Ball Metavision", "left")

    local BallMetavision = {
        Enabled = false,
        Mode = "New",
        Connection = nil,
        Container = nil,
        LineParts = {},
        PartPool = {},
        TrajectoryPoints = {},
        BallInstance = nil,
        LastUpdateTime = 0,
        LINE_WIDTH = 0.2,
        LINE_COLOR = Color3.fromRGB(58, 201, 255),
        START_TRANSPARENCY = 0.2,
        END_TRANSPARENCY = 0.7,
        FADE_DURATION = 2,
        REQUEST_INTERVAL = 0,
        OldConnection = nil,
    }

    local function bmGetPart()
        if #BallMetavision.PartPool > 0 then
            local p = table.remove(BallMetavision.PartPool)
            p.Transparency = 0
            return p
        end
        local p = Instance.new("Part")
        p.Anchored = true; p.CanCollide = false; p.CastShadow = false
        p.Material = Enum.Material.Neon; p.Color = BallMetavision.LINE_COLOR
        return p
    end

    local function bmReturnPart(p)
        if p then
            p.Parent = nil
            table.insert(BallMetavision.PartPool, p)
        end
    end

    local function bmClearLines()
        for _, p in ipairs(BallMetavision.LineParts) do bmReturnPart(p) end
        BallMetavision.LineParts = {}
    end

    local function bmFindBall()
        return Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
    end

    local function bmDrawLines()
        local pts = BallMetavision.TrajectoryPoints
        local numPts = #pts
        if numPts < 2 then
            bmClearLines()
            return
        end
        local numLines = numPts - 1
        local now = tick()

        while #BallMetavision.LineParts > numLines do
            bmReturnPart(table.remove(BallMetavision.LineParts))
        end

        for i = 1, numLines do
            local part = BallMetavision.LineParts[i]
            if not part then
                part = bmGetPart()
                BallMetavision.LineParts[i] = part
            end

            local p1 = pts[i].Position
            local p2 = pts[i + 1].Position
            local dist = (p2 - p1).Magnitude

            if dist > 0.01 then
                part.Size = Vector3.new(BallMetavision.LINE_WIDTH, BallMetavision.LINE_WIDTH, dist)
                part.CFrame = CFrame.new(p1, p2) * CFrame.new(0, 0, -dist / 2)
                part.Color = BallMetavision.LINE_COLOR

                local age = pts[i].Time and (now - pts[i].Time) or 0
                local fadeFactor = math.clamp(age / BallMetavision.FADE_DURATION, 0, 1)
                local baseT = BallMetavision.START_TRANSPARENCY +
                    ((i - 1) / numLines) * (BallMetavision.END_TRANSPARENCY - BallMetavision.START_TRANSPARENCY)
                part.Transparency = baseT + fadeFactor * (1 - baseT)

                if part.Transparency >= 0.99 then
                    part.Parent = nil
                else
                    part.Parent = BallMetavision.Container
                end
            else
                part.Parent = nil
            end
        end

        while #BallMetavision.TrajectoryPoints > 2 do
            local age = BallMetavision.TrajectoryPoints[1].Time and (now - BallMetavision.TrajectoryPoints[1].Time) or 0
            if age > BallMetavision.FADE_DURATION then
                table.remove(BallMetavision.TrajectoryPoints, 1)
            else
                break
            end
        end
    end

    local function bmTrackBall()
        local newBall = bmFindBall()
        if newBall ~= BallMetavision.BallInstance then
            BallMetavision.BallInstance = newBall
            bmClearLines()
            BallMetavision.TrajectoryPoints = {}
        end
    end

    function BallMetavision.Start()
        BallMetavision.Enabled = true
        BallMetavision.Mode = "Old"
        BallMetavision.StartOld()
        SafeNotify("Ball Metavision Enabled", 2, "Enable")
    end

    function BallMetavision.Stop()
        BallMetavision.Enabled = false
        BallMetavision.StopOld()
        SafeNotify("Ball Metavision Disabled", 2, "Disable")
    end

    function BallMetavision.StartOld()
        BallMetavision.OldData = {
            BlueArcParts = {},
            GrayArcParts = {},
            PartPool = {},
            PositionHistory = {},
            VelocityHistory = {},
            LastBallPosition = nil,
            SmoothedVelocity = Vector3.new(0, 0, 0),
            BallInstance = nil,
            LastUpdateTime = nil,
            FrameSkipCounter = 0,
            BLUE_ARC_COLOR = Color3.fromRGB(9, 137, 207),
            GRAY_ARC_COLOR = Color3.fromRGB(150, 150, 150),
            ARC_WIDTH = 0.2,
            ARC_TRANSPARENCY = 0.4,
            MAX_HISTORY = 50,
            PREDICTION_STEPS = 18,
            PREDICTION_TIME = 2,
            MIN_MOVE = 0.5,
            SMOOTHING = 0.15,
            VEL_HISTORY_SIZE = 10,
            DRAG = 0.9737,
            GROUND = 1.5,
        }
        local D = BallMetavision.OldData

        D.BlueContainer = Instance.new("Folder")
        D.BlueContainer.Name = "BlueArc"
        D.BlueContainer.Parent = Workspace
        D.GrayContainer = Instance.new("Folder")
        D.GrayContainer.Name = "GrayArc"
        D.GrayContainer.Parent = Workspace

        local function getPart()
            if #D.PartPool > 0 then
                local p = table.remove(D.PartPool)
                p.Transparency = 0
                return p
            end
            local p = Instance.new("Part")
            p.Anchored = true
            p.CanCollide = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            return p
        end
        local function retPart(p)
            if p then
                p.Transparency = 1
                p.Parent = nil
                table.insert(D.PartPool, p)
            end
        end

        local function findBall()
            if D.BallInstance and D.BallInstance.Parent then return true end

            if D.BallInstance and not D.BallInstance.Parent then
                D.BallInstance = nil
                for i = #D.BlueArcParts, 1, -1 do
                    local p = D.BlueArcParts[i]
                    if p then
                        p.Transparency = 1
                        p.Parent = nil
                    end
                    D.BlueArcParts[i] = nil
                end
                for i = #D.GrayArcParts, 1, -1 do
                    local p = D.GrayArcParts[i]
                    if p then
                        p.Transparency = 1
                        p.Parent = nil
                    end
                    D.GrayArcParts[i] = nil
                end
                D.PositionHistory = {}
                D.VelocityHistory = {}
                D.LastBallPosition = nil
                D.SmoothedVelocity = Vector3.new(0, 0, 0)
            end
            local b = Workspace.Terrain:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
            if b and b:IsA("BasePart") then
                D.BallInstance = b
                D.PositionHistory = {}
                D.VelocityHistory = {}
                D.LastBallPosition = nil
                D.SmoothedVelocity = Vector3.new(0, 0, 0)
                return true
            end
            return false
        end

        local function updateBlueArc()
            local needed = math.max(#D.PositionHistory - 1, 0)
            for i = #D.BlueArcParts, needed + 1, -1 do
                retPart(D.BlueArcParts[i])
                D.BlueArcParts[i] = nil
            end
            for i = 1, needed do
                local part = D.BlueArcParts[i] or getPart()
                D.BlueArcParts[i] = part
                local p1, p2 = D.PositionHistory[i], D.PositionHistory[i + 1]
                local dist = (p2 - p1).Magnitude
                if dist > 0.01 then
                    part.Size = Vector3.new(D.ARC_WIDTH, D.ARC_WIDTH, dist)
                    part.CFrame = CFrame.new(p1, p2) * CFrame.new(0, 0, -dist / 2)
                    part.Color = D.BLUE_ARC_COLOR; part.Transparency = D.ARC_TRANSPARENCY; part.Parent = D.BlueContainer
                else
                    part.Transparency = 1
                end
            end
        end

        local function updateGrayArc(startPos, vel)
            local gravity = Workspace.Gravity
            local pos, v = startPos, vel
            local dt = D.PREDICTION_TIME / D.PREDICTION_STEPS
            for i = #D.GrayArcParts, D.PREDICTION_STEPS + 1, -1 do
                retPart(D.GrayArcParts[i])
                D.GrayArcParts[i] = nil
            end
            for i = 1, D.PREDICTION_STEPS do
                local part = D.GrayArcParts[i] or getPart()
                D.GrayArcParts[i] = part
                local prev = pos
                v = Vector3.new(v.X * D.DRAG, v.Y - gravity * dt, v.Z * D.DRAG)
                pos = pos + v * dt
                if pos.Y <= D.GROUND then
                    pos = Vector3.new(pos.X, D.GROUND, pos.Z)
                    v = Vector3.new(v.X * 0.85, 0, v.Z * 0.85)
                end
                local dist = (pos - prev).Magnitude
                if dist > 0.05 then
                    part.Size = Vector3.new(D.ARC_WIDTH * 0.75, D.ARC_WIDTH * 0.75, dist)
                    part.CFrame = CFrame.new(prev, pos) * CFrame.new(0, 0, -dist / 2)
                    part.Color = D.GRAY_ARC_COLOR; part.Transparency = D.ARC_TRANSPARENCY; part.Parent = D.GrayContainer
                else
                    part.Transparency = 1
                end
            end
        end

        BallMetavision.OldConnection = RunService.Heartbeat:Connect(function()
            if not BallMetavision.Enabled or BallMetavision.Mode ~= "Old" then return end
            D.FrameSkipCounter = D.FrameSkipCounter + 1
            if D.FrameSkipCounter < 2 then return end
            D.FrameSkipCounter = 0

            if not findBall() then return end
            local curPos = D.BallInstance.Position
            local last = D.PositionHistory[#D.PositionHistory]
            if not last then
                D.PositionHistory = { curPos }
                updateBlueArc()
                return
            end
            if (curPos - last).Magnitude > D.MIN_MOVE then
                table.insert(D.PositionHistory, curPos)
                if #D.PositionHistory > D.MAX_HISTORY then table.remove(D.PositionHistory, 1) end
                updateBlueArc()
            end

            local now = tick()
            if D.LastBallPosition then
                local td = now - (D.LastUpdateTime or now)
                if td > 0 and td < 0.1 then
                    local newVel = (curPos - D.LastBallPosition) / td
                    table.insert(D.VelocityHistory, newVel)
                    if #D.VelocityHistory > D.VEL_HISTORY_SIZE then table.remove(D.VelocityHistory, 1) end
                    if #D.VelocityHistory >= 5 then
                        local avg, tw = Vector3.new(0, 0, 0), 0
                        for idx, vv in ipairs(D.VelocityHistory) do
                            local w = idx / #D.VelocityHistory
                            avg = avg + vv * w
                            tw = tw + w
                        end
                        avg = avg / tw
                        D.SmoothedVelocity = D.SmoothedVelocity:Lerp(avg, D.SMOOTHING)
                    else
                        D.SmoothedVelocity = D.SmoothedVelocity:Lerp(newVel, D.SMOOTHING * 0.5)
                    end
                    if D.SmoothedVelocity.Magnitude < 1 then
                        for i = #D.GrayArcParts, 1, -1 do
                            local p = D.GrayArcParts[i]
                            if p then
                                p.Transparency = 1
                                p.Parent = nil
                                table.insert(D.PartPool, p)
                            end
                            D.GrayArcParts[i] = nil
                        end
                    else
                        updateGrayArc(curPos, D.SmoothedVelocity)
                    end
                end
            end
            D.LastBallPosition = curPos
            D.LastUpdateTime = now
        end)
    end

    function BallMetavision.StopOld()
        if BallMetavision.OldConnection then
            BallMetavision.OldConnection:Disconnect()
            BallMetavision.OldConnection = nil
        end
        if BallMetavision.OldData then
            local D = BallMetavision.OldData
            for _, p in ipairs(D.BlueArcParts) do if p then p:Destroy() end end
            for _, p in ipairs(D.GrayArcParts) do if p then p:Destroy() end end
            for _, p in ipairs(D.PartPool) do if p then p:Destroy() end end
            if D.BlueContainer then D.BlueContainer:Destroy() end
            if D.GrayContainer then D.GrayContainer:Destroy() end
            BallMetavision.OldData = nil
        end
    end

    BallMetavision.Mode = "Old"

    Library:CreateToggle(BallMetaSection, {
        Name = "Ball Metavision",
        Default = false,
        Callback = function(v) if v then BallMetavision.Start() else BallMetavision.Stop() end end
    })
end


Library:CreateDropdown(MiscUISection, {
    Name = "UI Scale",
    Options = { "50%", "60%", "75%", "100%", "125%", "150%" },
    Default = "100%",
    Callback = function(v)
        local scale = tonumber(v:match("%d+"))
        if scale and Window.SetUIScale then
            Window:SetUIScale(scale)
        end
    end
})

Library:CreateColorPicker(MiscUISection, {
    Name = "UI Color",
    Default = Color3.fromRGB(149, 138, 204),
    Callback = function(color)
        if Library.UpdateAccentColor then
            Library:UpdateAccentColor(color)
        end
    end
})

Library:CreateToggle(MiscUISection, {
    Name = "Watermark",
    Default = not IS_MOBILE,
    Callback = function(v)
        UISettings.Watermark = v
        if Window and Window.Watermark and Window.Watermark.SetVisible then
            Window.Watermark.SetVisible(v)
        end
    end
})

Library:CreateToggle(MiscUISection, {
    Name = "Notifications",
    Default = true,
    Callback = function(v) UISettings.Notifications = v end
})

Library:CreateToggle(MiscUISection, {
    Name = "Keybinds Display",
    Default = not IS_MOBILE,
    Callback = function(v)
        if Library.KeybindsWindow and Library.KeybindsWindow.SetVisible then
            Library.KeybindsWindow:SetVisible(v)
        end
    end
})

Library:CreateToggle(MiscUISection, {
    Name = "Notification Sounds",
    Default = true,
    Callback = function(v)
        if v then
            Library:LoadNotificationSounds()
        end
        Library.NotificationSoundsUserEnabled = v
    end
})

Library:CreateSlider(MiscUISection, {
    Name = "Sound Volume",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 5,
    Suffix = "%",
    Callback = function(v)
        local vol = v / 100
        if Library.NotificationSounds and Library.NotificationSounds.Sounds then
            for _, sound in pairs(Library.NotificationSounds.Sounds) do
                if sound and sound.Parent then
                    pcall(function() sound.Volume = vol end)
                end
            end
        end
        Library.NotificationSoundVolume = vol
    end
})

do
    local UIKeybind = Library:CreateKeybind(MiscUISection, {
        Name            = "UI Toggle Key",
        Default         = Enum.KeyCode.K,
        Mode            = "Toggle",
        ManualWatermark = true,
        Callback        = function() end
    })

    local _origSetKey = UIKeybind.SetKey
    UIKeybind.SetKey = function(self, key)
        _origSetKey(self, key)
        if key and Window and Window.SetToggleKey then
            Window:SetToggleKey(key)
        end
    end

    _G.__UIKeybind = UIKeybind
end

local Crosshair = {
    Enabled       = false,
    Style         = "Cross",
    Color         = Color3.fromRGB(149, 138, 204),
    DotColor      = Color3.fromRGB(149, 138, 204),
    Outline       = true,
    OutlineColor  = Color3.fromRGB(0, 0, 0),
    ShowText      = true,
    Width         = 2,
    Length        = 12,
    Gap           = 4,
    DotSize       = 2,
    CircleRadius  = 12,
    CircleSides   = 16,
    Spin          = true,
    SpinSpeed     = 180,
    Pulse         = true,
    PulseSpeed    = 1.6,
    PulseMin      = 6,
    PulseMax      = 13,
    SilentAimSnap = true,
    drawings      = nil,
    connection    = nil,
}

local function getSilentAimTarget()
    return nil
end

local function chMakeDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

function Crosshair.Destroy()
    if Crosshair.connection then
        Crosshair.connection:Disconnect(); Crosshair.connection = nil
    end
    if not Crosshair.drawings then return end
    for _, d in ipairs(Crosshair.drawings.lines or {}) do d:Remove() end
    for _, d in ipairs(Crosshair.drawings.outlineLines or {}) do d:Remove() end
    for _, d in ipairs(Crosshair.drawings.circleSegs or {}) do d:Remove() end
    for _, d in ipairs(Crosshair.drawings.circleOutlineSegs or {}) do d:Remove() end
    if Crosshair.drawings.dot then Crosshair.drawings.dot:Remove() end
    if Crosshair.drawings.dotOutline then Crosshair.drawings.dotOutline:Remove() end
    if Crosshair.drawings.textEvo then Crosshair.drawings.textEvo:Remove() end
    if Crosshair.drawings.textHub then Crosshair.drawings.textHub:Remove() end
    Crosshair.drawings = nil
end

function Crosshair.Initialize()
    if not ExecutorCaps.Drawing then return end
    Crosshair.Destroy()
    Crosshair.drawings = { lines = {}, outlineLines = {}, circleSegs = {}, circleOutlineSegs = {} }
    for i = 1, 4 do
        Crosshair.drawings.outlineLines[i] = chMakeDrawing("Line", {
            Visible = false, Thickness = Crosshair.Width + 2, Color = Crosshair.OutlineColor, Transparency = 1,
        })
        Crosshair.drawings.lines[i] = chMakeDrawing("Line", {
            Visible = false, Thickness = Crosshair.Width, Color = Crosshair.Color, Transparency = 1,
        })
    end
    for i = 1, Crosshair.CircleSides do
        Crosshair.drawings.circleOutlineSegs[i] = chMakeDrawing("Line", {
            Visible = false, Thickness = Crosshair.Width + 2, Color = Crosshair.OutlineColor, Transparency = 1,
        })
        Crosshair.drawings.circleSegs[i] = chMakeDrawing("Line", {
            Visible = false, Thickness = Crosshair.Width, Color = Crosshair.Color, Transparency = 1,
        })
    end
    Crosshair.drawings.dotOutline = chMakeDrawing("Circle", {
        Visible = false,
        Radius = Crosshair.DotSize + 1,
        Color = Crosshair.OutlineColor,
        Filled = true,
        NumSides = 16,
        Transparency = 1,
        Thickness = 1,
    })
    Crosshair.drawings.dot = chMakeDrawing("Circle", {
        Visible = false,
        Radius = Crosshair.DotSize,
        Color = Crosshair.DotColor,
        Filled = true,
        NumSides = 16,
        Transparency = 1,
        Thickness = 1,
    })
    Crosshair.drawings.textEvo = chMakeDrawing("Text", {
        Visible = false,
        Text = "Evo",
        Size = 14,
        Font = 2,
        Outline = true,
        Color = Color3.fromRGB(149, 138, 204),
        Center = true,
        Transparency = 1,
    })
    Crosshair.drawings.textHub = chMakeDrawing("Text", {
        Visible = false,
        Text = "Hub",
        Size = 14,
        Font = 2,
        Outline = true,
        Color = Color3.fromRGB(255, 255, 255),
        Center = true,
        Transparency = 1,
    })
    Crosshair.StartRender()
end

local function hideAllCrosshair(d)
    for i = 1, 4 do
        if d.lines[i] then d.lines[i].Visible = false end
        if d.outlineLines[i] then d.outlineLines[i].Visible = false end
    end
    if d.circleSegs then
        for _, s in ipairs(d.circleSegs) do s.Visible = false end
        for _, s in ipairs(d.circleOutlineSegs) do s.Visible = false end
    end
    if d.dot then d.dot.Visible = false end
    if d.dotOutline then d.dotOutline.Visible = false end
    if d.textEvo then d.textEvo.Visible = false end
    if d.textHub then d.textHub.Visible = false end
end

local STYLE_LINES = {
    ["Cross"]      = { true, true, true, true },
    ["Plus + Dot"] = { true, true, true, true },
    ["T-Shape"]    = { false, true, true, true },
    ["Dot Only"]   = { false, false, false, false },
    ["Circle"]     = { false, false, false, false },
}
local STYLE_DOT = {
    ["Cross"]      = false,
    ["Plus + Dot"] = true,
    ["T-Shape"]    = false,
    ["Dot Only"]   = true,
    ["Circle"]     = true,
}
local STYLE_CIRCLE = {
    ["Cross"]      = false,
    ["Plus + Dot"] = false,
    ["T-Shape"]    = false,
    ["Dot Only"]   = false,
    ["Circle"]     = true,
}

function Crosshair.StartRender()
    if Crosshair.connection then Crosshair.connection:Disconnect() end
    Crosshair.connection = RunService.RenderStepped:Connect(function()
        local d = Crosshair.drawings
        if not d then return end
        if not Crosshair.Enabled then
            hideAllCrosshair(d); return
        end

        local pos
        if Crosshair.SilentAimSnap then
            local target = getSilentAimTarget()
            if target then
                local part = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
                local cam = workspace.CurrentCamera
                if part and cam then
                    local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then pos = Vector2.new(sp.X, sp.Y) end
                end
            end
        end
        if not pos then pos = UserInputService:GetMouseLocation() end

        local length = Crosshair.Length
        if Crosshair.Pulse then
            local t = math.abs(math.sin(tick() * Crosshair.PulseSpeed))
            length = Crosshair.PulseMin + t * (Crosshair.PulseMax - Crosshair.PulseMin)
        end

        local spinAngle = 0
        if Crosshair.Spin then
            spinAngle = math.rad((tick() * Crosshair.SpinSpeed) % 360)
        end

        local linesShown  = STYLE_LINES[Crosshair.Style] or STYLE_LINES["Cross"]
        local dotShown    = STYLE_DOT[Crosshair.Style] or false
        local circleShown = STYLE_CIRCLE[Crosshair.Style] or false

        local directions  = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }
        local cosA, sinA  = math.cos(spinAngle), math.sin(spinAngle)
        for i = 1, 4 do
            local line = d.lines[i]
            local outline = d.outlineLines[i]
            if linesShown[i] then
                local dx, dy = directions[i][1], directions[i][2]
                if Crosshair.Spin then
                    dx, dy = dx * cosA - dy * sinA, dx * sinA + dy * cosA
                end
                local sx = pos.X + dx * Crosshair.Gap
                local sy = pos.Y + dy * Crosshair.Gap
                local ex = pos.X + dx * (Crosshair.Gap + length)
                local ey = pos.Y + dy * (Crosshair.Gap + length)
                local from, to = Vector2.new(sx, sy), Vector2.new(ex, ey)

                if Crosshair.Outline then
                    outline.From = from; outline.To = to
                    outline.Color = Crosshair.OutlineColor
                    outline.Thickness = Crosshair.Width + 2
                    outline.Visible = true
                else
                    outline.Visible = false
                end

                line.From = from; line.To = to
                line.Color = Crosshair.Color
                line.Thickness = Crosshair.Width
                line.Visible = true
            else
                line.Visible = false
                outline.Visible = false
            end
        end

        if dotShown then
            if Crosshair.Outline then
                d.dotOutline.Position = pos
                d.dotOutline.Radius = Crosshair.DotSize + 1
                d.dotOutline.Color = Crosshair.OutlineColor
                d.dotOutline.Visible = true
            else
                d.dotOutline.Visible = false
            end
            d.dot.Position = pos
            d.dot.Radius = Crosshair.DotSize
            d.dot.Color = Crosshair.DotColor
            d.dot.Visible = true
        else
            d.dot.Visible = false
            d.dotOutline.Visible = false
        end

        if circleShown then
            local sides = Crosshair.CircleSides
            local r = Crosshair.CircleRadius
            local twoPi = math.pi * 2
            for i = 1, sides do
                local a1   = spinAngle + (i - 1) / sides * twoPi
                local a2   = spinAngle + i / sides * twoPi
                local from = Vector2.new(pos.X + math.cos(a1) * r, pos.Y + math.sin(a1) * r)
                local to   = Vector2.new(pos.X + math.cos(a2) * r, pos.Y + math.sin(a2) * r)
                local seg  = d.circleSegs[i]
                local oseg = d.circleOutlineSegs[i]
                if Crosshair.Outline then
                    oseg.From = from; oseg.To = to
                    oseg.Color = Crosshair.OutlineColor
                    oseg.Thickness = Crosshair.Width + 2
                    oseg.Visible = true
                else
                    oseg.Visible = false
                end
                seg.From = from; seg.To = to
                seg.Color = Crosshair.Color
                seg.Thickness = Crosshair.Width
                seg.Visible = true
            end
        else
            for _, s in ipairs(d.circleSegs) do s.Visible = false end
            for _, s in ipairs(d.circleOutlineSegs) do s.Visible = false end
        end

        if Crosshair.ShowText then
            local t1, t2 = d.textEvo, d.textHub
            local totalW = t1.TextBounds.X + t2.TextBounds.X
            local textY = pos.Y + Crosshair.Gap + length + 6
            t1.Position = Vector2.new(pos.X - totalW * 0.5 + t1.TextBounds.X * 0.5, textY)
            t2.Position = Vector2.new(pos.X - totalW * 0.5 + t1.TextBounds.X + t2.TextBounds.X * 0.5, textY)
            t1.Visible = true; t2.Visible = true
        else
            d.textEvo.Visible = false; d.textHub.Visible = false
        end
    end)
end

function Crosshair.Start()
    if not ExecutorCaps.Drawing then return end
    Crosshair.Enabled = true
    Crosshair.Initialize()
    SafeNotify("Crosshair Enabled", 2, "Enable")
end

function Crosshair.Stop()
    Crosshair.Enabled = false
    if Crosshair.drawings then hideAllCrosshair(Crosshair.drawings) end
    SafeNotify("Crosshair Disabled", 2, "Disable")
end

Library:CreateToggle(CrosshairMainSection, {
    Name = "Enabled",
    Default = not IS_MOBILE,
    Callback = function(v) if v then Crosshair.Start() else Crosshair.Stop() end end
})
Library:CreateToggle(CrosshairMainSection, {
    Name = "Outline",
    Default = true,
    Callback = function(v) Crosshair.Outline = v end
})
Library:CreateToggle(CrosshairMainSection, {
    Name = "EvoHub Label",
    Default = true,
    Callback = function(v) Crosshair.ShowText = v end
})
Library:CreateToggle(CrosshairMainSection, {
    Name = "Silent Aim Snap",
    Default = true,
    Callback = function(v) Crosshair.SilentAimSnap = v end
})

Library:CreateDropdown(CrosshairStyleSection, {
    Name = "Style",
    Options = { "Cross", "Plus + Dot", "T-Shape", "Dot Only", "Circle" },
    Default = "Cross",
    Callback = function(v) Crosshair.Style = v end
})
Library:CreateSlider(CrosshairStyleSection, {
    Name = "Width",
    Min = 1,
    Max = 6,
    Default = 2,
    Step = 1,
    Suffix = "px",
    Callback = function(v) Crosshair.Width = v end
})
Library:CreateSlider(CrosshairStyleSection, {
    Name = "Length",
    Min = 0,
    Max = 30,
    Default = 12,
    Step = 1,
    Suffix = "px",
    Callback = function(v) Crosshair.Length = v end
})
Library:CreateSlider(CrosshairStyleSection, {
    Name = "Gap",
    Min = 0,
    Max = 20,
    Default = 4,
    Step = 1,
    Suffix = "px",
    Callback = function(v) Crosshair.Gap = v end
})
Library:CreateSlider(CrosshairStyleSection, {
    Name = "Dot Size",
    Min = 1,
    Max = 8,
    Default = 2,
    Step = 1,
    Suffix = "px",
    Callback = function(v) Crosshair.DotSize = v end
})
Library:CreateSlider(CrosshairStyleSection, {
    Name = "Circle Radius",
    Min = 4,
    Max = 40,
    Default = 12,
    Step = 1,
    Suffix = "px",
    Callback = function(v) Crosshair.CircleRadius = v end
})
Library:CreateSlider(CrosshairStyleSection, {
    Name = "Circle Sides",
    Min = 3,
    Max = 32,
    Default = 16,
    Step = 1,
    Suffix = "",
    Callback = function(v)
        Crosshair.CircleSides = v
        if Crosshair.Enabled then Crosshair.Initialize() end
    end
})

Library:CreateToggle(CrosshairAnimSection, {
    Name = "Spin",
    Default = true,
    Callback = function(v) Crosshair.Spin = v end
})
Library:CreateSlider(CrosshairAnimSection, {
    Name = "Spin Speed",
    Min = 0,
    Max = 720,
    Default = 180,
    Step = 5,
    Suffix = "В°/s",
    Callback = function(v) Crosshair.SpinSpeed = v end
})
Library:CreateToggle(CrosshairAnimSection, {
    Name = "Pulse",
    Default = true,
    Callback = function(v) Crosshair.Pulse = v end
})
Library:CreateSlider(CrosshairAnimSection, {
    Name = "Pulse Speed",
    Min = 0.5,
    Max = 10,
    Default = 1.6,
    Step = 0.1,
    Suffix = "Hz",
    Callback = function(v) Crosshair.PulseSpeed = v end
})
Library:CreateSlider(CrosshairAnimSection, {
    Name = "Pulse Min",
    Min = 0,
    Max = 30,
    Default = 6,
    Step = 1,
    Suffix = "px",
    Callback = function(v) Crosshair.PulseMin = v end
})
Library:CreateSlider(CrosshairAnimSection, {
    Name = "Pulse Max",
    Min = 1,
    Max = 40,
    Default = 13,
    Step = 1,
    Suffix = "px",
    Callback = function(v) Crosshair.PulseMax = v end
})

Library:CreateColorPicker(CrosshairColorSection, {
    Name = "Line Color",
    Default = Color3.fromRGB(149, 138, 204),
    Callback = function(c) Crosshair.Color = c end
})
Library:CreateColorPicker(CrosshairColorSection, {
    Name = "Dot Color",
    Default = Color3.fromRGB(149, 138, 204),
    Callback = function(c) Crosshair.DotColor = c end
})
Library:CreateColorPicker(CrosshairColorSection, {
    Name = "Outline Color",
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(c) Crosshair.OutlineColor = c end
})

if Library.CreateKeybinds then
    pcall(function() Library:CreateKeybinds() end)
end

if not IS_MOBILE then
    pcall(function() Crosshair.Start() end)
end

task.spawn(function()
    task.wait(1.2)
    if Window and Window.Watermark and Window.Watermark.SetVisible then
        pcall(function() Window.Watermark.SetVisible(UISettings.Watermark) end)
    end
    if IS_MOBILE then
        if Library.KeybindsWindow and Library.KeybindsWindow.SetVisible then
            pcall(function() Library.KeybindsWindow:SetVisible(false) end)
        end
    end
end)

if ExecutorCaps.Files then Library.ConfigSystem.Load("azl") end
Library.ConfigSystem.AutoSave = ExecutorCaps.Files

task.spawn(function()
    task.wait(0.5)
    if _G.__UIKeybind and _G.__UIKeybind.Key then
        local key = _G.__UIKeybind.Key
        if Window and Window.SetToggleKey then
            Window:SetToggleKey(key)
        end
    end
end)
