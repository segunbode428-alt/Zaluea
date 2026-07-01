-- FMLY Detector | Delta Executor Script
-- Detects players with FMLY (or close variants) in username/display name
-- Features: Head tags, startup notification, modern hub GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ┌─────────────────────────────────────────┐
-- │  CONFIG — change these to your liking   │
-- └─────────────────────────────────────────┘
local TAG_TEXT   = "⚠ OPPS"          -- Change to "⚠ FMLY USER" if you prefer
local TAG_COLOR  = Color3.fromRGB(255, 55, 55)
local HUB_TITLE  = "FMLY DETECTOR"

-- Fuzzy match patterns (lowercase). Catches FMLY, FAMLY, FMILY, FMLEY, etc.
local FMLY_PATTERNS = { "fmly", "famly", "fmily", "fmley", "fmlly", "fmlyy" }

-- ┌──────────────────────────────────┐
-- │  DETECTION                       │
-- └──────────────────────────────────┘
local function matchesFMLY(str)
    str = str:lower()
    for _, p in ipairs(FMLY_PATTERNS) do
        if str:find(p, 1, true) then return true end
    end
    return false
end

local function isFMLYPlayer(player)
    return matchesFMLY(player.Name) or matchesFMLY(player.DisplayName)
end

local function countFMLY()
    local n = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if isFMLYPlayer(p) then n = n + 1 end
    end
    return n
end

-- ┌──────────────────────────────────┐
-- │  HEAD TAGS                       │
-- └──────────────────────────────────┘
local activeTags = {}
local tagsEnabled = true

local function makeTagFor(player)
    if activeTags[player] then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "FMLYTag"
    bb.Size = UDim2.new(0, 130, 0, 38)
    bb.StudsOffset = Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(8, 14, 48)
    bg.BorderSizePixel = 0
    bg.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = bg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 110, 255)
    stroke.Thickness = 1.5
    stroke.Parent = bg

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -6, 1, 0)
    lbl.Position = UDim2.new(0, 3, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = TAG_TEXT
    lbl.TextColor3 = TAG_COLOR
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bg

    activeTags[player] = bb
end

local function removeTagFor(player)
    if activeTags[player] then
        activeTags[player]:Destroy()
        activeTags[player] = nil
    end
end

local function applyTagsAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isFMLYPlayer(p) then
            makeTagFor(p)
        end
    end
end

local function removeTagsAll()
    for p in pairs(activeTags) do
        removeTagFor(p)
    end
end

-- Re-apply tag when character respawns
local function hookPlayer(player)
    if not isFMLYPlayer(player) then return end
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if tagsEnabled then makeTagFor(player) end
    end)
    player.CharacterRemoving:Connect(function()
        activeTags[player] = nil
    end)
end

-- ┌──────────────────────────────────┐
-- │  STARTUP NOTIFICATION            │
-- └──────────────────────────────────┘
local function showNotification(fmlyCount)
    -- Remove old notif if any
    if PlayerGui:FindFirstChild("FMLYNotif") then
        PlayerGui.FMLYNotif:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FMLYNotif"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 62)
    frame.Position = UDim2.new(0.5, -150, 0, -70)
    frame.BackgroundColor3 = Color3.fromRGB(6, 12, 42)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 100, 255)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    -- Accent bar on left
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 5, 1, -16)
    accent.Position = UDim2.new(0, 0, 0, 8)
    accent.BackgroundColor3 = Color3.fromRGB(255, 55, 55)
    accent.BorderSizePixel = 0
    accent.Parent = frame

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 4)
    accentCorner.Parent = accent

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 42, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "⚠"
    icon.TextColor3 = Color3.fromRGB(255, 80, 80)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame

    local msg = fmlyCount == 0
        and "No FMLY users in this server"
        or fmlyCount .. " FMLY user" .. (fmlyCount ~= 1 and "s" or "") .. " detected in server"

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -62, 0, 22)
    title.Position = UDim2.new(0, 56, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "FMLY DETECTOR"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -62, 0, 20)
    sub.Position = UDim2.new(0, 56, 0, 32)
    sub.BackgroundTransparency = 1
    sub.Text = msg
    sub.TextColor3 = Color3.fromRGB(160, 190, 255)
    sub.TextScaled = true
    sub.Font = Enum.Font.Gotham
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = frame

    -- Slide in
    TweenService:Create(frame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -150, 0, 16)
    }):Play()

    task.delay(4.5, function()
        local t = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -150, 0, -70)
        })
        t:Play()
        t.Completed:Connect(function() gui:Destroy() end)
    end)
end

-- ┌──────────────────────────────────┐
-- │  HUB GUI                         │
-- └──────────────────────────────────┘
local function createHub()
    if PlayerGui:FindFirstChild("FMLYHub") then
        PlayerGui.FMLYHub:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FMLYHub"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.Parent = PlayerGui

    -- Shadow
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(0, 276, 0, 192)
    shadow.Position = UDim2.new(0.5, -134, 0.5, -92)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 0
    shadow.Parent = gui

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 14)
    shadowCorner.Parent = shadow

    -- Main
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 270, 0, 188)
    main.Position = UDim2.new(0.5, -135, 0.5, -94)
    main.BackgroundColor3 = Color3.fromRGB(6, 12, 42)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.ZIndex = 1
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(0, 90, 220)
    mainStroke.Thickness = 1.5
    mainStroke.Parent = main

    -- Animated shimmer overlay
    local shimmer = Instance.new("Frame")
    shimmer.Size = UDim2.new(0.4, 0, 2, 0)
    shimmer.Position = UDim2.new(-0.5, 0, -0.5, 0)
    shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shimmer.BackgroundTransparency = 0.93
    shimmer.BorderSizePixel = 0
    shimmer.ZIndex = 2
    shimmer.Parent = main

    local shimmerCorner = Instance.new("UICorner")
    shimmerCorner.CornerRadius = UDim.new(0, 4)
    shimmerCorner.Parent = shimmer

    local function runShimmer()
        while main.Parent do
            TweenService:Create(shimmer, TweenInfo.new(2.2, Enum.EasingStyle.Linear), {
                Position = UDim2.new(1.2, 0, -0.5, 0)
            }):Play()
            task.wait(4)
            shimmer.Position = UDim2.new(-0.5, 0, -0.5, 0)
        end
    end
    task.spawn(runShimmer)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 55, 175)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = main

    -- Round only top corners of title bar
    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 14)
    tbCorner.Parent = titleBar

    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 14)
    tbFix.Position = UDim2.new(0, 0, 1, -14)
    tbFix.BackgroundColor3 = Color3.fromRGB(0, 55, 175)
    tbFix.BorderSizePixel = 0
    tbFix.ZIndex = 3
    tbFix.Parent = titleBar

    -- Title gradient
    local tbGrad = Instance.new("UIGradient")
    tbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 70, 210)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 40, 140)),
    })
    tbGrad.Rotation = 90
    tbGrad.Parent = titleBar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -50, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "⚠  " .. HUB_TITLE
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextScaled = true
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 4
    titleLbl.Parent = titleBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -62, 0.5, -13)
    minBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 200)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextScaled = true
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    minBtn.ZIndex = 5
    minBtn.Parent = titleBar

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minBtn

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 5
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -52)
    content.Position = UDim2.new(0, 10, 0, 48)
    content.BackgroundTransparency = 1
    content.ZIndex = 3
    content.Parent = main

    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 0)
    divider.BackgroundColor3 = Color3.fromRGB(0, 70, 200)
    divider.BorderSizePixel = 0
    divider.ZIndex = 3
    divider.Parent = content

    -- Server count label
    local countLbl = Instance.new("TextLabel")
    countLbl.Size = UDim2.new(1, 0, 0, 28)
    countLbl.Position = UDim2.new(0, 0, 0, 8)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = "Designates in server: " .. countFMLY()
    countLbl.TextColor3 = Color3.fromRGB(140, 180, 255)
    countLbl.TextScaled = true
    countLbl.Font = Enum.Font.Gotham
    countLbl.TextXAlignment = Enum.TextXAlignment.Left
    countLbl.ZIndex = 3
    countLbl.Parent = content

    -- Toggle row
    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(1, -70, 0, 32)
    rowLabel.Position = UDim2.new(0, 0, 0, 44)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = "Show Head Tags"
    rowLabel.TextColor3 = Color3.fromRGB(210, 225, 255)
    rowLabel.TextScaled = true
    rowLabel.Font = Enum.Font.Gotham
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.ZIndex = 3
    rowLabel.Parent = content

    -- Toggle pill
    local pillBg = Instance.new("Frame")
    pillBg.Size = UDim2.new(0, 52, 0, 28)
    pillBg.Position = UDim2.new(1, -52, 0, 46)
    pillBg.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    pillBg.BorderSizePixel = 0
    pillBg.ZIndex = 3
    pillBg.Parent = content

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pillBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = UDim2.new(1, -25, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 4
    knob.Parent = pillBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local pillBtn = Instance.new("TextButton")
    pillBtn.Size = UDim2.new(1, 0, 1, 0)
    pillBtn.BackgroundTransparency = 1
    pillBtn.Text = ""
    pillBtn.ZIndex = 5
    pillBtn.Parent = pillBg

    -- Second divider
    local div2 = Instance.new("Frame")
    div2.Size = UDim2.new(1, 0, 0, 1)
    div2.Position = UDim2.new(0, 0, 0, 90)
    div2.BackgroundColor3 = Color3.fromRGB(20, 35, 80)
    div2.BorderSizePixel = 0
    div2.ZIndex = 3
    div2.Parent = content

    -- Credits
    local credits = Instance.new("TextLabel")
    credits.Size = UDim2.new(1, 0, 0, 22)
    credits.Position = UDim2.new(0, 0, 1, -22)
    credits.BackgroundTransparency = 1
    credits.Text = "FMLY Detector  •  Delta Executor"
    credits.TextColor3 = Color3.fromRGB(50, 70, 130)
    credits.TextScaled = true
    credits.Font = Enum.Font.Gotham
    credits.ZIndex = 3
    credits.Parent = content

    -- ── Dragging ──
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            main.Position  = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            shadow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X - 3, startPos.Y.Scale, startPos.Y.Offset + d.Y + 2)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ── Toggle logic ──
    pillBtn.MouseButton1Click:Connect(function()
        tagsEnabled = not tagsEnabled
        if tagsEnabled then
            TweenService:Create(pillBg, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(0, 150, 80) }):Play()
            TweenService:Create(knob,   TweenInfo.new(0.2), { Position = UDim2.new(1, -25, 0.5, -11) }):Play()
            applyTagsAll()
        else
            TweenService:Create(pillBg, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(70, 70, 90) }):Play()
            TweenService:Create(knob,   TweenInfo.new(0.2), { Position = UDim2.new(0, 3, 0.5, -11) }):Play()
            removeTagsAll()
        end
    end)

    -- ── Minimize logic ──
    local minimized = false
    local fullHeight, miniHeight = UDim2.new(0, 270, 0, 188), UDim2.new(0, 270, 0, 42)
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local target = minimized and miniHeight or fullHeight
        TweenService:Create(main,   TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = target }):Play()
        TweenService:Create(shadow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = minimized and UDim2.new(0, 276, 0, 46) or UDim2.new(0, 276, 0, 192)
        }):Play()
        minBtn.Text = minimized and "+" or "—"
    end)

    -- ── Close with animation ──
    closeBtn.MouseButton1Click:Connect(function()
        local t = TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset + 135,
                                 main.Position.Y.Scale, main.Position.Y.Offset + 94)
        })
        TweenService:Create(shadow, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        }):Play()
        t:Play()
        t.Completed:Connect(function() gui:Destroy() end)
    end)

    -- ── Live count update ──
    task.spawn(function()
        while gui.Parent do
            countLbl.Text = "Designates in server: " .. countFMLY()
            task.wait(6)
        end
    end)

    -- ── Open animation ──
    main.Size     = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.BackgroundTransparency = 1
    TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size     = UDim2.new(0, 270, 0, 188),
        Position = UDim2.new(0.5, -135, 0.5, -94)
    }):Play()
    TweenService:Create(shadow, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.5
    }):Play()
end

-- ┌──────────────────────────────────┐
-- │  INIT                            │
-- └──────────────────────────────────┘
task.spawn(function()
    task.wait(1.5)

    -- Hook existing players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            hookPlayer(p)
            if isFMLYPlayer(p) then
                task.spawn(makeTagFor, p)
            end
        end
    end

    -- Hook new players
    Players.PlayerAdded:Connect(function(p)
        hookPlayer(p)
        if isFMLYPlayer(p) then
            p.CharacterAdded:Connect(function()
                task.wait(1)
                if tagsEnabled then makeTagFor(p) end
            end)
        end
    end)

    -- Clean up on leave
    Players.PlayerRemoving:Connect(function(p)
        activeTags[p] = nil
    end)

    -- Notification then hub
    showNotification(countFMLY())
    task.wait(0.6)
    createHub()
end)
