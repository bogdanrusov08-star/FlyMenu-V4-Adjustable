
--[[
    FlyMenu V4 — Neon UI Edition PLUS + EXTRAS
    LocalScript: StarterPlayer > StarterPlayerScripts
    For your own Roblox Studio experience.
    Note: Not yet tested in Roblox Studio.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- CONFIGURATION
--==================================================

local DEFAULT_MENU_KEY = Enum.KeyCode.G
local UI_SOUND_ID = "" -- Optional: enter a valid Roblox audio asset ID
local TARGET_TAG = "AimTrainingTarget"

local themes = {
    Neon = {
        Purple = Color3.fromRGB(155, 90, 255),
        Cyan = Color3.fromRGB(55, 220, 255),
    },
    Ocean = {
        Purple = Color3.fromRGB(40, 130, 255),
        Cyan = Color3.fromRGB(70, 255, 220),
    },
}

local themeName = "Neon"

local C = {
    Background = Color3.fromRGB(13, 14, 23),
    Panel = Color3.fromRGB(20, 22, 34),
    Card = Color3.fromRGB(27, 29, 44),
    Purple = themes.Neon.Purple,
    Cyan = themes.Neon.Cyan,
    Text = Color3.fromRGB(240, 241, 255),
    Muted = Color3.fromRGB(142, 148, 174),
    Border = Color3.fromRGB(54, 57, 79),
    Red = Color3.fromRGB(255, 82, 110),
}

local defaults = {
    FlySpeed = 25,
    WalkSpeed = 16,
    JumpPower = 50,
    FreecamSpeed = 35,
    FOV = 70,
    SprintSpeed = 26,

    Fly = false,
    Noclip = false,
    ESP = false,
    FPS = false,
    Freecam = false,
    PlayerInfo = false,
    Clock = false,

    Sprint = false,
    DoubleJump = false,
    HideCharacters = false,
    TargetHighlight = false,
    UISounds = false,
    PerformanceMode = false,
}

local settings = {}
for key, value in pairs(defaults) do
    settings[key] = value
end

local connections = {}
local resetActions = {}
local running = true
local minimized = false
local currentPage = "MOVEMENT"
local menuKey = DEFAULT_MENU_KEY

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function new(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    new("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
    }, parent)
end

local function outline(parent, color, transparency)
    return new("UIStroke", {
        Color = color or C.Border,
        Transparency = transparency or 0,
        Thickness = 1,
    }, parent)
end

local function label(parent, text, size, color, font)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size or 14,
        TextColor3 = color or C.Text,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BorderSizePixel = 0,
    }, parent)
end

local function playUISound()
    if not settings.UISounds or UI_SOUND_ID == "" then
        return
    end

    local sound = Instance.new("Sound")
    sound.SoundId = UI_SOUND_ID
    sound.Volume = 0.35
    sound.Parent = SoundService
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    SoundService:PlayLocalSound(sound)

    task.delay(5, function()
        if sound.Parent then
            sound:Destroy()
        end
    end)
end

local oldGui = playerGui:FindFirstChild("FlyMenuV4")
if oldGui then
    oldGui:Destroy()
end

--==================================================
-- MAIN GUI
--==================================================

local gui = new("ScreenGui", {
    Name = "FlyMenuV4",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(650, 440),
    Position = UDim2.new(0.5, -325, 0.5, -220),
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
round(main, 14)
local mainStroke = outline(main, C.Purple, 0.2)

local accent = new("Frame", {
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = C.Purple,
    BorderSizePixel = 0,
}, main)

local accentGradient = new("UIGradient", {
    Color = ColorSequence.new(C.Purple, C.Cyan),
}, accent)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    Position = UDim2.fromOffset(0, 3),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, main)

local logo = new("Frame", {
    Position = UDim2.fromOffset(17, 12),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = C.Purple,
    BorderSizePixel = 0,
}, header)
round(logo, 10)

local logoText = label(logo, "F", 22, C.Text, Enum.Font.GothamBlack)
logoText.Size = UDim2.fromScale(1, 1)
logoText.TextXAlignment = Enum.TextXAlignment.Center

local title = label(header, "FLYMENU", 17, C.Text, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(61, 9)
title.Size = UDim2.fromOffset(110, 22)

local version = label(header, "V4  •  NEON PLUS", 10, C.Cyan)
version.Position = UDim2.fromOffset(62, 30)
version.Size = UDim2.fromOffset(180, 17)

local minimizeButton = new("TextButton", {
    Text = "—",
    Size = UDim2.fromOffset(32, 30),
    Position = UDim2.new(1, -75, 0, 14),
    BackgroundColor3 = C.Card,
    TextColor3 = C.Text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, header)
round(minimizeButton, 8)

local closeButton = new("TextButton", {
    Text = "×",
    Size = UDim2.fromOffset(32, 30),
    Position = UDim2.new(1, -37, 0, 14),
    BackgroundColor3 = Color3.fromRGB(60, 28, 44),
    TextColor3 = C.Red,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, header)
round(closeButton, 8)

local sidebar = new("Frame", {
    Position = UDim2.fromOffset(0, 61),
    Size = UDim2.new(0, 172, 1, -61),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, main)

local sideTitle = label(sidebar, "WORKSPACE", 10, C.Muted, Enum.Font.GothamBold)
sideTitle.Position = UDim2.fromOffset(17, 18)
sideTitle.Size = UDim2.new(1, -25, 0, 20)

local tabHolder = new("ScrollingFrame", {
    Position = UDim2.fromOffset(9, 48),
    Size = UDim2.new(1, -18, 1, -58),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, sidebar)

new("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabHolder)

local tabs = {
    {name = "MOVEMENT", icon = "✦"},
    {name = "VISUALS", icon = "◉"},
    {name = "CAMERA", icon = "◎"},
    {name = "CHARACTER", icon = "◇"},
    {name = "LIGHTING", icon = "☼"},
    {name = "EXTRAS", icon = "+"},
}

local tabButtons = {}
local pages = {}

local content = new("Frame", {
    Position = UDim2.fromOffset(172, 61),
    Size = UDim2.new(1, -172, 1, -61),
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
}, main)

local pageTitle = label(content, "MOVEMENT", 19, C.Text, Enum.Font.GothamBold)
pageTitle.Position = UDim2.fromOffset(20, 16)
pageTitle.Size = UDim2.new(1, -40, 0, 27)

local pageSubtitle = label(content, "Configure your movement settings", 11, C.Muted)
pageSubtitle.Position = UDim2.fromOffset(20, 43)
pageSubtitle.Size = UDim2.new(1, -40, 0, 20)

for _, tab in ipairs(tabs) do
    local page = new("ScrollingFrame", {
        Name = tab.name,
        Position = UDim2.fromOffset(16, 75),
        Size = UDim2.new(1, -32, 1, -90),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Purple,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, content)

    new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    new("UIPadding", {
        PaddingBottom = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 4),
    }, page)

    pages[tab.name] = page

    local button = new("TextButton", {
        Name = tab.name .. "Tab",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = C.Panel,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, tabHolder)
    round(button, 9)

    local icon = label(button, tab.icon, 17, C.Muted, Enum.Font.GothamBold)
    icon.Position = UDim2.fromOffset(12, 0)
    icon.Size = UDim2.fromOffset(24, 42)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local nameLabel = label(button, tab.name, 11, C.Muted, Enum.Font.GothamBold)
    nameLabel.Position = UDim2.fromOffset(43, 0)
    nameLabel.Size = UDim2.new(1, -48, 1, 0)

    tabButtons[tab.name] = {
        button = button,
        icon = icon,
        label = nameLabel,
    }
end

local descriptions = {
    MOVEMENT = "Configure your movement settings",
    VISUALS = "Visual helpers and screen information",
    CAMERA = "Camera and freecam settings",
    CHARACTER = "Character options and reset",
    LIGHTING = "Customize the atmosphere",
    EXTRAS = "Additional gameplay and interface tools",
}

local function switchPage(name)
    currentPage = name

    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    pageTitle.Text = name
    pageSubtitle.Text = descriptions[name] or ""

    for tabName, elements in pairs(tabButtons) do
        local selected = tabName == name
        elements.button.BackgroundColor3 =
            selected and Color3.fromRGB(43, 34, 68) or C.Panel
        elements.icon.TextColor3 = selected and C.Cyan or C.Muted
        elements.label.TextColor3 = selected and C.Text or C.Muted

        local stroke = elements.button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke:Destroy()
        end
        if selected then
            outline(elements.button, C.Purple, 0.25)
        end
    end
end

--==================================================
-- UI COMPONENTS
--==================================================

local function section(parent, text)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 27),
        BackgroundTransparency = 1,
    }, parent)

    local heading = label(holder, text, 11, C.Cyan, Enum.Font.GothamBold)
    heading.Size = UDim2.new(1, 0, 1, 0)
    return holder
end

local function card(parent, height)
    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 58),
        BackgroundColor3 = C.Card,
        BorderSizePixel = 0,
    }, parent)
    round(frame, 10)
    outline(frame, C.Border, 0.35)
    return frame
end

local function actionButton(parent, text, color, callback)
    local button = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = C.Card,
        Text = text,
        TextColor3 = color or C.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    }, parent)
    round(button, 9)
    outline(button, color or C.Purple, 0.55)

    track(button.Activated:Connect(function()
        playUISound()
        callback()
    end))

    return button
end

local function makeToggle(parent, text, description, initial, callback, settingKey)
    local holder = card(parent, 62)

    local titleLabel = label(holder, text, 12, C.Text, Enum.Font.GothamSemibold)
    titleLabel.Position = UDim2.fromOffset(13, 8)
    titleLabel.Size = UDim2.new(1, -100, 0, 20)

    local sub = label(holder, description or "", 10, C.Muted)
    sub.Position = UDim2.fromOffset(13, 31)
    sub.Size = UDim2.new(1, -100, 0, 17)

    local toggle = new("TextButton", {
        Size = UDim2.fromOffset(43, 24),
        Position = UDim2.new(1, -57, 0.5, -12),
        BackgroundColor3 = initial and C.Purple or C.Border,
        Text = "",
        BorderSizePixel = 0,
    }, holder)
    round(toggle, 12)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = initial and UDim2.new(1, -21, 0.5, -9)
            or UDim2.fromOffset(3, 3),
        BackgroundColor3 = C.Text,
        BorderSizePixel = 0,
    }, toggle)
    round(knob, 9)

    local enabled = initial

    local function update(callCallback)
        toggle.BackgroundColor3 = enabled and C.Purple or C.Border
        knob.Position = enabled and UDim2.new(1, -21, 0.5, -9)
            or UDim2.fromOffset(3, 3)

        if settingKey then
            settings[settingKey] = enabled
        end

        if callCallback ~= false then
            callback(enabled)
        end
    end

    track(toggle.Activated:Connect(function()
        playUISound()
        enabled = not enabled
        update(true)
    end))

    table.insert(resetActions, function()
        enabled = initial
        update(true)
    end)

    return function(value)
        enabled = value
        update(true)
    end
end

local function makeNumber(parent, text, description, minValue, maxValue, initial, callback)
    local holder = card(parent, 88)

    local titleLabel = label(holder, text, 12, C.Text, Enum.Font.GothamSemibold)
    titleLabel.Position = UDim2.fromOffset(13, 7)
    titleLabel.Size = UDim2.new(1, -100, 0, 20)

    local sub = label(holder, description or "", 10, C.Muted)
    sub.Position = UDim2.fromOffset(13, 29)
    sub.Size = UDim2.new(1, -100, 0, 15)

    local input = new("TextBox", {
        Size = UDim2.fromOffset(66, 28),
        Position = UDim2.new(1, -79, 0, 10),
        BackgroundColor3 = C.Background,
        TextColor3 = C.Cyan,
        PlaceholderColor3 = C.Muted,
        Text = tostring(initial),
        PlaceholderText = "Value",
        ClearTextOnFocus = false,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    }, holder)
    round(input, 7)
    outline(input, C.Border, 0.2)

    local bar = new("Frame", {
        Position = UDim2.fromOffset(13, 64),
        Size = UDim2.new(1, -26, 0, 5),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0,
    }, holder)
    round(bar, 4)

    local fill = new("Frame", {
        Size = UDim2.new((initial - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = C.Purple,
        BorderSizePixel = 0,
    }, bar)
    round(fill, 4)

    local value = initial
    local dragging = false

    local function apply(newValue)
        value = math.clamp(math.floor(newValue + 0.5), minValue, maxValue)
        input.Text = tostring(value)
        fill.Size = UDim2.new(
            (value - minValue) / (maxValue - minValue), 0, 1, 0
        )
        callback(value)
    end

    track(input.FocusLost:Connect(function()
        local number = tonumber(input.Text)
        if number then
            apply(number)
        else
            input.Text = tostring(value)
        end
    end))

    local hitbox = new("TextButton", {
        Position = UDim2.fromOffset(0, -10),
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "",
    }, bar)

    local function setFromX(x)
        local width = math.max(bar.AbsoluteSize.X, 1)
        local alpha = math.clamp(
            (x - bar.AbsolutePosition.X) / width, 0, 1
        )
        apply(minValue + alpha * (maxValue - minValue))
    end

    track(hitbox.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(inputObject.Position.X)
        end
    end))

    track(UIS.InputChanged:Connect(function(inputObject)
        if dragging and (
            inputObject.UserInputType == Enum.UserInputType.MouseMovement
            or inputObject.UserInputType == Enum.UserInputType.Touch
        ) then
            setFromX(inputObject.Position.X)
        end
    end))

    track(UIS.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    table.insert(resetActions, function()
        apply(initial)
    end)

    return apply
end

local function makeTextInput(parent, titleText, description, placeholder, initialText, callback)
    local holder = card(parent, 82)

    local titleLabel = label(holder, titleText, 12, C.Text, Enum.Font.GothamSemibold)
    titleLabel.Position = UDim2.fromOffset(13, 6)
    titleLabel.Size = UDim2.new(1, -26, 0, 20)

    local sub = label(holder, description or "", 10, C.Muted)
    sub.Position = UDim2.fromOffset(13, 27)
    sub.Size = UDim2.new(1, -26, 0, 15)

    local input = new("TextBox", {
        Position = UDim2.fromOffset(13, 49),
        Size = UDim2.new(1, -26, 0, 25),
        BackgroundColor3 = C.Background,
        TextColor3 = C.Cyan,
        PlaceholderColor3 = C.Muted,
        PlaceholderText = placeholder or "",
        Text = initialText or "",
        ClearTextOnFocus = false,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
    }, holder)
    round(input, 6)
    outline(input, C.Border, 0.2)

    track(input.FocusLost:Connect(function()
        callback(input.Text)
    end))

    return input
end

--==================================================
-- CHARACTER REFERENCES
--==================================================

local character
local humanoid
local root

local function refreshCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid", 5)
    root = char:WaitForChild("HumanoidRootPart", 5)

    if humanoid then
        if settings.Sprint then
            humanoid.WalkSpeed = settings.SprintSpeed
        else
            humanoid.WalkSpeed = settings.WalkSpeed
        end

        pcall(function()
            humanoid.UseJumpPower = true
            humanoid.JumpPower = settings.JumpPower
        end)
    end
end

if player.Character then
    refreshCharacter(player.Character)
end

track(player.CharacterAdded:Connect(function(char)
    refreshCharacter(char)
end))

local function getCharacter()
    if not character or not character.Parent then
        if player.Character then
            refreshCharacter(player.Character)
        end
    end
    return character, humanoid, root
end

--==================================================
-- FLIGHT
--==================================================

local flying = false
local flyVelocity
local flyGyro
local flightConnection

local function stopFly()
    flying = false

    if flightConnection then
        flightConnection:Disconnect()
        flightConnection = nil
    end
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end

    local _, hum = getCharacter()
    if hum then
        hum.PlatformStand = false
    end
end

local function startFly()
    local _, hum, part = getCharacter()
    if not hum or not part then
        return
    end

    stopFly()
    flying = true

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = part

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyGyro.P = 12000
    flyGyro.CFrame = part.CFrame
    flyGyro.Parent = part

    flightConnection = RunService.RenderStepped:Connect(function()
        if not flying or not part.Parent then
            stopFly()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local direction = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            direction += camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            direction -= camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            direction += camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            direction -= camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.yAxis
        end

        flyVelocity.Velocity = direction.Magnitude > 0
            and direction.Unit * settings.FlySpeed or Vector3.zero
        flyGyro.CFrame = camera.CFrame
    end)
end

local function setFly(enabled)
    settings.Fly = enabled
    if enabled then
        startFly()
    else
        stopFly()
    end
end

--==================================================
-- NOCLIP
--==================================================

local noclipConnection
local originalCollision = {}

local function setNoclip(enabled)
    settings.Noclip = enabled

    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if not enabled then
        for part, canCollide in pairs(originalCollision) do
            if part and part.Parent then
                part.CanCollide = canCollide
            end
        end
        table.clear(originalCollision)
        return
    end

    noclipConnection = RunService.Stepped:Connect(function()
        local char = getCharacter()
        if not char then
            return
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCollision[part] == nil then
                    originalCollision[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
end

--==================================================
-- ESP HIGHLIGHTS
--==================================================

local espEnabled = false
local espObjects = {}

local function clearESP()
    for _, object in pairs(espObjects) do
        if object then
            object:Destroy()
        end
    end
    table.clear(espObjects)
end

local function updateESP()
    clearESP()
    if not espEnabled then
        return
    end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local highlight = Instance.new("Highlight")
            highlight.Name = "FlyMenuESP"
            highlight.FillColor = C.Purple
            highlight.OutlineColor = C.Cyan
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0.05
            highlight.Adornee = otherPlayer.Character
            highlight.Parent = gui
            table.insert(espObjects, highlight)
        end
    end
end

local function setESP(enabled)
    espEnabled = enabled
    settings.ESP = enabled
    updateESP()
end

track(Players.PlayerAdded:Connect(function()
    task.wait(1)
    if running then
        updateESP()
    end
end))

track(Players.PlayerRemoving:Connect(function()
    task.wait()
    if running then
        updateESP()
    end
end))

--==================================================
-- SCREEN HUD
--==================================================

local fpsLabel = new("TextLabel", {
    Name = "FPSCounter",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 18),
    Size = UDim2.fromOffset(125, 30),
    BackgroundColor3 = C.Panel,
    TextColor3 = C.Cyan,
    Text = "FPS: --",
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    Visible = false,
    BorderSizePixel = 0,
    ZIndex = 10,
}, gui)
round(fpsLabel, 8)
outline(fpsLabel, C.Cyan, 0.4)

local playerInfoLabel = new("TextLabel", {
    Name = "PlayerInfo",
    Position = UDim2.new(0, 18, 0, 18),
    Size = UDim2.fromOffset(235, 75),
    BackgroundColor3 = C.Panel,
    TextColor3 = C.Text,
    Text = "PLAYER INFO\nSpeed: --\nJump: --",
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    Visible = false,
    BorderSizePixel = 0,
    ZIndex = 10,
}, gui)
round(playerInfoLabel, 8)
outline(playerInfoLabel, C.Purple, 0.4)

local clockLabel = new("TextLabel", {
    Name = "FlyMenuClock",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 55),
    Size = UDim2.fromOffset(150, 30),
    BackgroundColor3 = C.Panel,
    TextColor3 = C.Cyan,
    Text = "--:--:--",
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    Visible = false,
    BorderSizePixel = 0,
    ZIndex = 10,
}, gui)
round(clockLabel, 8)
outline(clockLabel, C.Cyan, 0.4)

local function setPlayerInfo(enabled)
    settings.PlayerInfo = enabled
    playerInfoLabel.Visible = enabled
end

local function setClock(enabled)
    settings.Clock = enabled
    clockLabel.Visible = enabled
end

--==================================================
-- FREECAM
--==================================================

local freecamEnabled = false
local freecamConnection
local freecamPosition
local freecamYaw, freecamPitch = 0, 0
local oldCameraType, oldCameraSubject, oldCameraCFrame
local oldMouseBehavior, oldMouseIcon
local oldAnchors = {}
local oldWalkSpeed, oldJumpPower, oldAutoRotate

local function stopFreecam()
    freecamEnabled = false

    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end

    for part, anchored in pairs(oldAnchors) do
        if part and part.Parent then
            part.Anchored = anchored
        end
    end
    table.clear(oldAnchors)

    local _, hum = getCharacter()
    if hum then
        if oldWalkSpeed ~= nil then
            hum.WalkSpeed = oldWalkSpeed
        end
        if oldJumpPower ~= nil then
            pcall(function()
                hum.JumpPower = oldJumpPower
            end)
        end
        if oldAutoRotate ~= nil then
            hum.AutoRotate = oldAutoRotate
        end
    end

    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = oldCameraType or Enum.CameraType.Custom
        camera.CameraSubject = oldCameraSubject or humanoid
        if oldCameraCFrame then
            camera.CFrame = oldCameraCFrame
        end
        camera.FieldOfView = settings.FOV
    end

    UIS.MouseBehavior = oldMouseBehavior or Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = oldMouseIcon ~= false
end

local function startFreecam()
    local char, hum, part = getCharacter()
    local camera = workspace.CurrentCamera
    if not char or not hum or not part or not camera then
        return
    end

    stopFreecam()
    freecamEnabled = true

    oldCameraType = camera.CameraType
    oldCameraSubject = camera.CameraSubject
    oldCameraCFrame = camera.CFrame
    oldMouseBehavior = UIS.MouseBehavior
    oldMouseIcon = UIS.MouseIconEnabled
    oldWalkSpeed = hum.WalkSpeed
    oldJumpPower = hum.JumpPower
    oldAutoRotate = hum.AutoRotate

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            oldAnchors[obj] = obj.Anchored
            obj.Anchored = true
        end
    end

    hum.WalkSpeed = 0
    pcall(function()
        hum.JumpPower = 0
    end)
    hum.AutoRotate = false

    freecamPosition = camera.CFrame.Position
    local look = camera.CFrame.LookVector
    freecamYaw = math.atan2(-look.X, -look.Z)
    freecamPitch = math.asin(math.clamp(look.Y, -1, 1))

    camera.CameraType = Enum.CameraType.Scriptable
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter

    freecamConnection = RunService.RenderStepped:Connect(function(dt)
        if not freecamEnabled then
            return
        end

        local currentCamera = workspace.CurrentCamera
        if not currentCamera then
            return
        end

        local delta = UIS:GetMouseDelta()
        freecamYaw -= delta.X * 0.0025
        freecamPitch = math.clamp(
            freecamPitch - delta.Y * 0.0025,
            math.rad(-85),
            math.rad(85)
        )

        local rotation = CFrame.Angles(0, freecamYaw, 0)
            * CFrame.Angles(freecamPitch, 0, 0)

        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then
            move += Vector3.new(0, 0, -1)
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            move += Vector3.new(0, 0, 1)
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            move += Vector3.new(-1, 0, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            move += Vector3.new(1, 0, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.E) then
            move += Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then
            move += Vector3.new(0, -1, 0)
        end

        if move.Magnitude > 0 then
            freecamPosition += rotation:VectorToWorldSpace(move.Unit)
                * settings.FreecamSpeed * dt
        end

        currentCamera.CFrame = CFrame.new(freecamPosition) * rotation
        currentCamera.FieldOfView = settings.FOV
    end)
end

local function setFreecam(enabled)
    settings.Freecam = enabled
    if enabled then
        startFreecam()
    else
        stopFreecam()
    end
end

--==================================================
-- EXTRAS: SPRINT
--==================================================

local sprintHeld = false

local function applyWalkSpeed()
    local _, hum = getCharacter()
    if not hum or settings.Freecam then
        return
    end

    if settings.Sprint and sprintHeld then
        hum.WalkSpeed = settings.SprintSpeed
    else
        hum.WalkSpeed = settings.WalkSpeed
    end
end

local function setSprint(enabled)
    settings.Sprint = enabled
    if not enabled then
        sprintHeld = false
    end
    applyWalkSpeed()
end

track(UIS.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftShift
        or input.KeyCode == Enum.KeyCode.RightShift then
        if settings.Sprint then
            sprintHeld = true
            applyWalkSpeed()
        end
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift
        or input.KeyCode == Enum.KeyCode.RightShift then
        sprintHeld = false
        applyWalkSpeed()
    end
end))

--==================================================
-- EXTRAS: DOUBLE JUMP
--==================================================

local doubleJumpConnection
local doubleJumpStateConnection
local extraJumpUsed = false

local function setDoubleJump(enabled)
    settings.DoubleJump = enabled
    extraJumpUsed = false

    if doubleJumpConnection then
        doubleJumpConnection:Disconnect()
        doubleJumpConnection = nil
    end
    if doubleJumpStateConnection then
        doubleJumpStateConnection:Disconnect()
        doubleJumpStateConnection = nil
    end

    if not enabled then
        return
    end

    local _, hum = getCharacter()
    if not hum then
        return
    end

    doubleJumpStateConnection = hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Landed
            or newState == Enum.HumanoidStateType.Running
            or newState == Enum.HumanoidStateType.RunningNoPhysics then
            extraJumpUsed = false
        end
    end)

    doubleJumpConnection = UIS.JumpRequest:Connect(function()
        if not running or not settings.DoubleJump then
            return
        end

        local _, currentHum, part = getCharacter()
        if not currentHum or not part or extraJumpUsed then
            return
        end

        local state = currentHum:GetState()
        if state == Enum.HumanoidStateType.Freefall
            or state == Enum.HumanoidStateType.FallingDown then
            extraJumpUsed = true
            local velocity = part.AssemblyLinearVelocity
            part.AssemblyLinearVelocity = Vector3.new(
                velocity.X,
                math.max(currentHum.JumpPower, 50),
                velocity.Z
            )
            currentHum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

--==================================================
-- EXTRAS: HIDE OTHER CHARACTERS
--==================================================

local hiddenCharactersEnabled = false
local hiddenOriginals = {}

local function restoreHiddenCharacters()
    for instance, original in pairs(hiddenOriginals) do
        if instance and instance.Parent then
            pcall(function()
                if instance:IsA("BasePart") then
                    instance.LocalTransparencyModifier = original
                elseif instance:IsA("Decal") or instance:IsA("Texture") then
                    instance.Transparency = original
                end
            end)
        end
    end
    table.clear(hiddenOriginals)
end

local function applyCharacterVisibility(char)
    if not hiddenCharactersEnabled or not char or char == player.Character then
        return
    end

    for _, instance in ipairs(char:GetDescendants()) do
        if instance:IsA("BasePart") then
            if hiddenOriginals[instance] == nil then
                hiddenOriginals[instance] = instance.LocalTransparencyModifier
            end
            instance.LocalTransparencyModifier = 1
        elseif instance:IsA("Decal") or instance:IsA("Texture") then
            if hiddenOriginals[instance] == nil then
                hiddenOriginals[instance] = instance.Transparency
            end
            instance.Transparency = 1
        end
    end
end

local function setHideCharacters(enabled)
    hiddenCharactersEnabled = enabled
    settings.HideCharacters = enabled

    if not enabled then
        restoreHiddenCharacters()
        return
    end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            applyCharacterVisibility(otherPlayer.Character)
        end
    end
end

track(Players.PlayerAdded:Connect(function(otherPlayer)
    track(otherPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.25)
        if running and hiddenCharactersEnabled then
            applyCharacterVisibility(char)
        end
    end))
end))

for _, otherPlayer in ipairs(Players:GetPlayers()) do
    if otherPlayer ~= player then
        track(otherPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.25)
            if running and hiddenCharactersEnabled then
                applyCharacterVisibility(char)
            end
        end))
    end
end

--==================================================
-- EXTRAS: TRAINING TARGET HIGHLIGHTS
-- Tag NPC Models with "AimTrainingTarget" in Studio.
--==================================================

local targetHighlights = {}
local targetHighlightEnabled = false

local function removeTargetHighlight(instance)
    local highlight = targetHighlights[instance]
    if highlight then
        highlight:Destroy()
        targetHighlights[instance] = nil
    end
end

local function addTargetHighlight(instance)
    if not targetHighlightEnabled or not instance:IsA("Model") then
        return
    end
    if not instance:FindFirstChildOfClass("Humanoid") then
        return
    end
    if targetHighlights[instance] then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "FlyMenuTrainingTarget"
    highlight.Adornee = instance
    highlight.FillColor = C.Purple
    highlight.OutlineColor = C.Cyan
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.Parent = gui
    targetHighlights[instance] = highlight
end

local function refreshTargetHighlights()
    for instance in pairs(targetHighlights) do
        removeTargetHighlight(instance)
    end

    if not targetHighlightEnabled then
        return
    end

    for _, instance in ipairs(CollectionService:GetTagged(TARGET_TAG)) do
        addTargetHighlight(instance)
    end
end

local function setTargetHighlight(enabled)
    targetHighlightEnabled = enabled
    settings.TargetHighlight = enabled
    refreshTargetHighlights()
end

track(CollectionService:GetInstanceAddedSignal(TARGET_TAG):Connect(function(instance)
    if running then
        addTargetHighlight(instance)
    end
end))

track(CollectionService:GetInstanceRemovedSignal(TARGET_TAG):Connect(function(instance)
    removeTargetHighlight(instance)
end))

--==================================================
-- EXTRAS: PERFORMANCE MODE
--==================================================

local performanceEnabled = false
local performanceOriginals = {}

local function canToggleEffect(instance)
    return instance:IsA("ParticleEmitter")
        or instance:IsA("Trail")
        or instance:IsA("Beam")
        or instance:IsA("Smoke")
        or instance:IsA("Fire")
        or instance:IsA("Sparkles")
        or instance:IsA("PostEffect")
end

local function disableEffect(instance)
    if not canToggleEffect(instance) then
        return
    end

    if performanceOriginals[instance] == nil then
        performanceOriginals[instance] = instance.Enabled
    end

    instance.Enabled = false
end

local function restorePerformanceEffects()
    for instance, original in pairs(performanceOriginals) do
        if instance and instance.Parent then
            pcall(function()
                instance.Enabled = original
            end)
        end
    end
    table.clear(performanceOriginals)
end

local function setPerformanceMode(enabled)
    performanceEnabled = enabled
    settings.PerformanceMode = enabled

    if not enabled then
        restorePerformanceEffects()
        return
    end

    for _, instance in ipairs(game:GetDescendants()) do
        disableEffect(instance)
    end
end

track(game.DescendantAdded:Connect(function(instance)
    if performanceEnabled then
        disableEffect(instance)
    end
end))

--==================================================
-- EXTRAS: FOV PRESETS
--==================================================

local function setFOV(value)
    settings.FOV = math.clamp(value, 40, 120)
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = settings.FOV
    end
end

--==================================================
-- EXTRAS: RETURN TO SPAWN / QUICK RESPAWN
--==================================================

local function returnToSpawn()
    local char = getCharacter()
    if not char then
        return
    end

    local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if not spawnLocation then
        warn("FlyMenu: No SpawnLocation found in Workspace.")
        return
    end

    char:PivotTo(spawnLocation.CFrame + Vector3.new(0, 4, 0))
end

local function quickRespawn()
    local _, hum = getCharacter()
    if hum and hum.Health > 0 then
        hum.Health = 0
    end
end

--==================================================
-- BUILD MOVEMENT PAGE
--==================================================

local movement = pages.MOVEMENT
section(movement, "MOVEMENT CONTROL")

makeToggle(movement, "Flight", "WASD, Space and Ctrl to move",
    false, setFly, "Fly")

makeNumber(movement, "Fly Speed", "Flight movement speed", 5, 150,
    settings.FlySpeed, function(value)
        settings.FlySpeed = value
    end)

makeNumber(movement, "Walk Speed", "Normal character walking speed", 0, 100,
    settings.WalkSpeed, function(value)
        settings.WalkSpeed = value
        applyWalkSpeed()
    end)

makeNumber(movement, "Jump Power", "Character jump strength", 0, 200,
    settings.JumpPower, function(value)
        settings.JumpPower = value
        local _, hum = getCharacter()
        if hum and not settings.Freecam then
            pcall(function()
                hum.UseJumpPower = true
                hum.JumpPower = value
            end)
        end
    end)

makeToggle(movement, "Noclip", "Disable collision for your character",
    false, setNoclip, "Noclip")

--==================================================
-- BUILD VISUALS PAGE
--==================================================

local visuals = pages.VISUALS
section(visuals, "VISUAL OPTIONS")

makeToggle(visuals, "ESP Highlights",
    "Highlight players in your own test experience",
    false, setESP, "ESP")

makeToggle(visuals, "FPS Counter", "Show a small FPS indicator",
    false, function(value)
        settings.FPS = value
        fpsLabel.Visible = value
    end, "FPS")

makeToggle(visuals, "Player Info", "Show movement stats on screen",
    false, setPlayerInfo, "PlayerInfo")

makeToggle(visuals, "Clock", "Show the current local time",
    false, setClock, "Clock")

local themeButton

local function applyTheme(name)
    themeName = name
    local theme = themes[name]
    if not theme then
        return
    end

    C.Purple = theme.Purple
    C.Cyan = theme.Cyan

    mainStroke.Color = C.Purple
    accent.BackgroundColor3 = C.Purple
    accentGradient.Color = ColorSequence.new(C.Purple, C.Cyan)
    logo.BackgroundColor3 = C.Purple
    version.TextColor3 = C.Cyan

    fpsLabel.TextColor3 = C.Cyan
    playerInfoLabel.TextColor3 = C.Text
    clockLabel.TextColor3 = C.Cyan

    for _, page in pairs(pages) do
        page.ScrollBarImageColor3 = C.Purple
    end

    if themeButton then
        themeButton.Text = "THEME: " .. string.upper(themeName)
        themeButton.TextColor3 = C.Cyan
    end

    updateESP()
    refreshTargetHighlights()
    switchPage(currentPage)
end

themeButton = actionButton(visuals, "THEME: NEON", C.Cyan, function()
    applyTheme(themeName == "Neon" and "Ocean" or "Neon")
end)

--==================================================
-- BUILD CAMERA PAGE
--==================================================

local cameraPage = pages.CAMERA
section(cameraPage, "CAMERA SETTINGS")

makeNumber(cameraPage, "Field of View", "Camera viewing angle", 40, 120,
    settings.FOV, setFOV)

makeNumber(cameraPage, "Freecam Speed", "Independent camera movement speed", 5, 150,
    settings.FreecamSpeed, function(value)
        settings.FreecamSpeed = value
    end)

makeToggle(cameraPage, "Freecam",
    "WASD to move, mouse to look, Q/E vertical",
    false, setFreecam, "Freecam")

actionButton(cameraPage, "FOV PRESET: 70", C.Cyan, function()
    setFOV(70)
end)

actionButton(cameraPage, "FOV PRESET: 90", C.Cyan, function()
    setFOV(90)
end)

actionButton(cameraPage, "FOV PRESET: 110", C.Cyan, function()
    setFOV(110)
end)

--==================================================
-- BUILD CHARACTER PAGE
--==================================================

local characterPage = pages.CHARACTER
section(characterPage, "CHARACTER OPTIONS")

makeToggle(characterPage, "Apply Walk Speed",
    "Apply the selected walking speed", false, function(enabled)
        if enabled then
            local _, hum = getCharacter()
            if hum then
                hum.WalkSpeed = settings.WalkSpeed
            end
        end
    end)

makeToggle(characterPage, "Apply Jump Power",
    "Apply the selected jump strength", false, function(enabled)
        if enabled then
            local _, hum = getCharacter()
            if hum then
                pcall(function()
                    hum.UseJumpPower = true
                    hum.JumpPower = settings.JumpPower
                end)
            end
        end
    end)

actionButton(characterPage, "↻  RESET ALL SETTINGS", C.Cyan, function()
    setFly(false)
    setNoclip(false)
    setESP(false)
    setFreecam(false)
    setSprint(false)
    setDoubleJump(false)
    setHideCharacters(false)
    setTargetHighlight(false)
    setPerformanceMode(false)

    for _, reset in ipairs(resetActions) do
        pcall(reset)
    end

    settings.FlySpeed = defaults.FlySpeed
    settings.WalkSpeed = defaults.WalkSpeed
    settings.JumpPower = defaults.JumpPower
    settings.FreecamSpeed = defaults.FreecamSpeed
    settings.FOV = defaults.FOV
    settings.SprintSpeed = defaults.SprintSpeed

    local _, hum = getCharacter()
    if hum then
        hum.WalkSpeed = defaults.WalkSpeed
        pcall(function()
            hum.UseJumpPower = true
            hum.JumpPower = defaults.JumpPower
        end)
    end

    setFOV(defaults.FOV)
    setPlayerInfo(false)
    setClock(false)
    fpsLabel.Visible = false
    settings.FPS = false
    applyTheme("Neon")
end)

--==================================================
-- BUILD LIGHTING PAGE
--==================================================

local lightingPage = pages.LIGHTING
section(lightingPage, "LIGHTING PRESETS")

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

actionButton(lightingPage, "☀  BRIGHT DAY", C.Cyan, function()
    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.Ambient = Color3.fromRGB(160, 160, 180)
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 180)
end)

actionButton(lightingPage, "☾  NIGHT MODE", C.Purple, function()
    Lighting.Brightness = 1
    Lighting.ClockTime = 0
    Lighting.FogEnd = 100000
    Lighting.Ambient = Color3.fromRGB(45, 40, 80)
    Lighting.OutdoorAmbient = Color3.fromRGB(35, 35, 65)
end)

actionButton(lightingPage, "↺  RESTORE LIGHTING", C.Text, function()
    for property, value in pairs(originalLighting) do
        Lighting[property] = value
    end
end)

--==================================================
-- BUILD EXTRAS PAGE
--==================================================

local extras = pages.EXTRAS
section(extras, "MOVEMENT EXTRAS")

makeToggle(extras, "Sprint", "Hold Shift to run faster",
    false, setSprint, "Sprint")

makeNumber(extras, "Sprint Speed", "Speed while holding Shift", 16, 100,
    settings.SprintSpeed, function(value)
        settings.SprintSpeed = value
        applyWalkSpeed()
    end)

makeToggle(extras, "Double Jump", "Jump once more while in the air",
    false, setDoubleJump, "DoubleJump")

section(extras, "VISUAL EXTRAS")

makeToggle(extras, "Hide Other Characters",
    "Hide other player characters on your screen only",
    false, setHideCharacters, "HideCharacters")

makeToggle(extras, "Training Target Highlight",
    "Highlight NPC models tagged AimTrainingTarget",
    false, setTargetHighlight, "TargetHighlight")

makeToggle(extras, "Performance Mode",
    "Temporarily disable particles and post effects",
    false, setPerformanceMode, "PerformanceMode")

section(extras, "QUICK ACTIONS")

actionButton(extras, "RETURN TO SPAWN", C.Cyan, returnToSpawn)
actionButton(extras, "QUICK RESPAWN", C.Red, quickRespawn)

section(extras, "INTERFACE")

makeToggle(extras, "UI Sounds", "Play a click sound for interface buttons",
    false, function(value)
        settings.UISounds = value
    end, "UISounds")

makeTextInput(extras, "Menu Hotkey",
    "Enter a KeyCode name, such as G, H or F6",
    "Example: G", menuKey.Name, function(text)
        local keyName = string.gsub(text, "%s+", "")
        local ok, keyCode = pcall(function()
            return Enum.KeyCode[keyName]
        end)

        if ok and keyCode and keyCode ~= Enum.KeyCode.Unknown then
            menuKey = keyCode
            print("FlyMenu hotkey set to:", keyName)
        else
            warn("FlyMenu: Invalid key name. Example values: G, H, F6.")
        end
    end)

makeTextInput(extras, "UI Sound Asset ID",
    "Paste a numeric Roblox audio asset ID",
    "Example: 1234567890", "", function(text)
        local digits = string.match(text, "%d+")
        if digits then
            UI_SOUND_ID = "rbxassetid://" .. digits
            print("FlyMenu UI sound ID updated.")
        else
            UI_SOUND_ID = ""
            warn("FlyMenu: Enter a numeric audio asset ID.")
        end
    end)

actionButton(extras, "RESET MENU HOTKEY TO G", C.Cyan, function()
    menuKey = DEFAULT_MENU_KEY
end)

--==================================================
-- LIVE HUD UPDATES
--==================================================

local frames = 0
local lastFPS = os.clock()

track(RunService.RenderStepped:Connect(function()
    if not running then
        return
    end

    frames += 1
    local now = os.clock()

    if now - lastFPS >= 1 then
        fpsLabel.Text = "FPS: " .. tostring(frames)
        frames = 0
        lastFPS = now
    end

    if settings.PlayerInfo then
        local _, hum = getCharacter()
        if hum then
            playerInfoLabel.Text = string.format(
                "PLAYER INFO\nSpeed: %.0f\nJump: %.0f",
                hum.WalkSpeed,
                hum.JumpPower
            )
        else
            playerInfoLabel.Text = "PLAYER INFO\nSpeed: --\nJump: --"
        end
    end

    if settings.Clock then
        clockLabel.Text = os.date("%H:%M:%S")
    end
end))

--==================================================
-- DRAG WINDOW
--==================================================

local dragging = false
local dragStart
local startPosition

track(header.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1
        or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inputObject.Position
        startPosition = main.Position
    end
end))

track(UIS.InputChanged:Connect(function(inputObject)
    if dragging and (
        inputObject.UserInputType == Enum.UserInputType.MouseMovement
        or inputObject.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = inputObject.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

track(UIS.InputEnded:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1
        or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

--==================================================
-- MINIMIZE
--==================================================

local expandedSize = main.Size

track(minimizeButton.Activated:Connect(function()
    playUISound()
    minimized = not minimized
    sidebar.Visible = not minimized
    content.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(650, 61) or expandedSize
    minimizeButton.Text = minimized and "□" or "—"
end))

--==================================================
-- CLOSE CONFIRMATION
--==================================================

local modal = new("Frame", {
    Size = UDim2.fromOffset(290, 145),
    Position = UDim2.new(0.5, -145, 0.5, -72),
    BackgroundColor3 = C.Panel,
    Visible = false,
    ZIndex = 20,
    BorderSizePixel = 0,
}, main)
round(modal, 12)
outline(modal, C.Purple, 0.15)

local modalTitle = label(modal, "Close FlyMenu?", 16, C.Text, Enum.Font.GothamBold)
modalTitle.Position = UDim2.fromOffset(18, 16)
modalTitle.Size = UDim2.new(1, -36, 0, 24)
modalTitle.ZIndex = 21

local modalText = label(modal, "Your active local effects will be disabled.", 10, C.Muted)
modalText.Position = UDim2.fromOffset(18, 44)
modalText.Size = UDim2.new(1, -36, 0, 28)
modalText.ZIndex = 21

local cancelButton = new("TextButton", {
    Size = UDim2.fromOffset(115, 34),
    Position = UDim2.fromOffset(18, 92),
    BackgroundColor3 = C.Card,
    Text = "CANCEL",
    TextColor3 = C.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 21,
}, modal)
round(cancelButton, 8)

local confirmButton = new("TextButton", {
    Size = UDim2.fromOffset(115, 34),
    Position = UDim2.fromOffset(157, 92),
    BackgroundColor3 = C.Red,
    Text = "CLOSE",
    TextColor3 = C.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 21,
}, modal)
round(confirmButton, 8)

track(closeButton.Activated:Connect(function()
    playUISound()
    modal.Visible = true
end))

track(cancelButton.Activated:Connect(function()
    playUISound()
    modal.Visible = false
end))

--==================================================
-- CLEANUP
--==================================================

local function cleanup()
    if not running then
        return
    end
    running = false

    setFly(false)
    setNoclip(false)
    setESP(false)
    setFreecam(false)
    setSprint(false)
    setDoubleJump(false)
    setHideCharacters(false)
    setTargetHighlight(false)
    setPerformanceMode(false)

    for part, canCollide in pairs(originalCollision) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
    end

    restoreHiddenCharacters()
    restorePerformanceEffects()

    for property, value in pairs(originalLighting) do
        Lighting[property] = value
    end

    local _, hum = getCharacter()
    if hum then
        hum.WalkSpeed = defaults.WalkSpeed
        pcall(function()
            hum.UseJumpPower = true
            hum.JumpPower = defaults.JumpPower
        end)
    end

    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = defaults.FOV
    end

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    gui:Destroy()
end

track(confirmButton.Activated:Connect(cleanup))

--==================================================
-- MENU HOTKEY
--==================================================

track(UIS.InputBegan:Connect(function(inputObject, processed)
    if processed or not running then
        return
    end

    if UIS:GetFocusedTextBox() then
        return
    end

    if inputObject.KeyCode == menuKey then
        main.Visible = not main.Visible
    end
end))

--==================================================
-- START
--==================================================

for name, elements in pairs(tabButtons) do
    track(elements.button.Activated:Connect(function()
        playUISound()
        switchPage(name)
    end))
end

switchPage("MOVEMENT")

print("FlyMenu V4 Neon PLUS loaded. Default menu key: G.")
