
-- FlyMenu V4 Adjustable - Freecam Update
-- Для собственной игры в Roblox Studio
-- LocalScript -> StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("FlyMenuV4")
if oldGui then oldGui:Destroy() end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local destroyed = false
local minimized = false
local connections = {}
local espObjects = {}
local originalCollision = {}

local state = {
    fly = false,
    noclip = false,
    esp = false,
    freecam = false,
    flySpeed = 25,
    walkSpeed = 16,
    jumpPower = 50,
    freecamSpeed = 30,
    fov = camera.FieldOfView,
}

local original = {
    WalkSpeed = humanoid.WalkSpeed,
    JumpPower = humanoid.JumpPower,
    UseJumpPower = humanoid.UseJumpPower,
    CameraType = camera.CameraType,
    CameraSubject = camera.CameraSubject,
    CameraMode = player.CameraMode,
    MinZoom = player.CameraMinZoomDistance,
    MaxZoom = player.CameraMaxZoomDistance,
    FOV = camera.FieldOfView,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local flyAttachment
local flyVelocity
local flyOrientation

-- Состояние свободной камеры и персонажа
local freecamOldType
local freecamOldSubject
local freecamOldFOV
local freecamPosition
local freecamRotation = Vector2.zero
local freecamOldAutoRotate
local freecamOldWalkSpeed
local freecamOldJumpPower
local freecamOldUseJumpPower
local freecamOldAnchored = {}
local freecamMouseConnection

local function keep(connection)
    table.insert(connections, connection)
    return connection
end

local function disconnectAll()
    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(connections)
end

local function make(className, properties, parent)
    local obj = Instance.new(className)
    for key, value in pairs(properties or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local gui = make("ScreenGui", {
    Name = "FlyMenuV4",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(650, 470),
    Position = UDim2.new(0.5, -325, 0.5, -235),
    BackgroundColor3 = Color3.fromRGB(17, 14, 30),
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)

make("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
make("UIStroke", {
    Color = Color3.fromRGB(153, 75, 255),
    Thickness = 2,
}, main)

make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 15, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 26, 38)),
    }),
    Rotation = 25,
}, main)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Color3.fromRGB(30, 20, 52),
    BorderSizePixel = 0,
}, main)

make("UICorner", {CornerRadius = UDim.new(0, 12)}, top)

make("TextLabel", {
    Size = UDim2.new(1, -145, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "FLYMENU V4  //  ADJUSTABLE",
    TextColor3 = Color3.fromRGB(207, 151, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local function topButton(text, x, color)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(36, 30),
        Position = UDim2.new(1, x, 0, 9),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        BorderSizePixel = 0,
    }, top)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    return b
end

local minimizeButton = topButton("—", -88, Color3.fromRGB(75, 55, 115))
local closeButton = topButton("×", -45, Color3.fromRGB(145, 45, 85))

-- Перетаскивание меню
do
    local dragging = false
    local dragStart
    local startPosition

    keep(top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end))

    keep(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))

    keep(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

local tabs = make("Frame", {
    Position = UDim2.fromOffset(12, 58),
    Size = UDim2.new(1, -24, 0, 38),
    BackgroundTransparency = 1,
}, main)

make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabs)

local content = make("Frame", {
    Position = UDim2.fromOffset(12, 105),
    Size = UDim2.new(1, -24, 1, -117),
    BackgroundTransparency = 1,
}, main)

local pages = {}
local tabButtons = {}

local function createPage(name)
    local page = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(20, 18, 34),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = Color3.fromRGB(160, 80, 255),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, content)

    make("UICorner", {CornerRadius = UDim.new(0, 9)}, page)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, page)

    make("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    pages[name] = page
    return page
end

local function selectPage(name)
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for pageName, button in pairs(tabButtons) do
        button.BackgroundColor3 = pageName == name
            and Color3.fromRGB(115, 55, 195)
            or Color3.fromRGB(42, 36, 61)
    end
end

local function createTab(name)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(119, 35),
        BackgroundColor3 = Color3.fromRGB(42, 36, 61),
        Text = name,
        TextColor3 = Color3.fromRGB(240, 235, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        BorderSizePixel = 0,
    }, tabs)

    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    tabButtons[name] = b
    keep(b.Activated:Connect(function() selectPage(name) end))
end

local movementPage = createPage("MOVEMENT")
local visualPage = createPage("VISUALS")
local cameraPage = createPage("CAMERA")
local characterPage = createPage("CHARACTER")
local lightingPage = createPage("LIGHTING")

for _, name in ipairs({
    "MOVEMENT", "VISUALS", "CAMERA", "CHARACTER", "LIGHTING"
}) do
    createTab(name)
end
selectPage("MOVEMENT")

local function section(parent, text)
    make("TextLabel", {
        Size = UDim2.new(1, -5, 0, 27),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(95, 225, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function button(parent, text, callback)
    local b = make("TextButton", {
        Size = UDim2.new(1, -5, 0, 35),
        BackgroundColor3 = Color3.fromRGB(54, 39, 83),
        Text = text,
        TextColor3 = Color3.fromRGB(245, 240, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        BorderSizePixel = 0,
    }, parent)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    keep(b.Activated:Connect(callback))
    return b
end

local function statusButton(parent, text, getter, callback)
    local b
    local function refresh()
        local enabled = getter()
        b.Text = text .. (enabled and "  [ON]" or "  [OFF]")
        b.BackgroundColor3 = enabled
            and Color3.fromRGB(42, 120, 110)
            or Color3.fromRGB(54, 39, 83)
    end

    b = button(parent, text, function()
        callback()
        refresh()
    end)

    refresh()
    return refresh
end

-- Ползунок + поле точного ввода
local function numberSetting(parent, title, minValue, maxValue, initialValue, callback)
    local card = make("Frame", {
        Size = UDim2.new(1, -5, 0, 98),
        BackgroundColor3 = Color3.fromRGB(29, 25, 45),
        BorderSizePixel = 0,
    }, parent)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, card)

    make("TextLabel", {
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -125, 0, 24),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(235, 230, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
    }, card)

    local valueBox = make("TextBox", {
        Position = UDim2.new(1, -105, 0, 5),
        Size = UDim2.fromOffset(65, 27),
        BackgroundColor3 = Color3.fromRGB(15, 14, 27),
        Text = tostring(initialValue),
        TextColor3 = Color3.fromRGB(100, 230, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
    }, card)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, valueBox)

    local apply = make("TextButton", {
        Position = UDim2.new(1, -34, 0, 5),
        Size = UDim2.fromOffset(27, 27),
        BackgroundColor3 = Color3.fromRGB(112, 59, 190),
        Text = "✓",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
    }, card)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, apply)

    local track = make("Frame", {
        Position = UDim2.fromOffset(10, 48),
        Size = UDim2.new(1, -20, 0, 9),
        BackgroundColor3 = Color3.fromRGB(57, 48, 76),
        BorderSizePixel = 0,
    }, card)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, track)

    local fill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(150, 80, 255),
        BorderSizePixel = 0,
    }, track)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

    local knob = make("Frame", {
        Size = UDim2.fromOffset(15, 15),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(105, 225, 255),
        BorderSizePixel = 0,
    }, track)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

    make("TextLabel", {
        Position = UDim2.fromOffset(10, 65),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        Text = "MIN: " .. minValue .. "     MAX: " .. maxValue,
        TextColor3 = Color3.fromRGB(150, 140, 175),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local currentValue = initialValue
    local dragging = false

    local function setValue(value)
        value = tonumber(value)
        if not value or value ~= value then value = currentValue end

        value = math.floor(math.clamp(value, minValue, maxValue) * 100 + 0.5) / 100
        currentValue = value

        local ratio = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valueBox.Text = tostring(value)

        callback(value)
    end

    local function updatePointer(input)
        local ratio = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        ratio = math.clamp(ratio, 0, 1)
        setValue(minValue + ratio * (maxValue - minValue))
    end

    keep(track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updatePointer(input)
        end
    end))

    keep(UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            updatePointer(input)
        end
    end))

    keep(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    local function applyText()
        setValue(valueBox.Text)
    end

    keep(apply.Activated:Connect(applyText))
    keep(valueBox.FocusLost:Connect(applyText))

    setValue(initialValue)
end

-- FREE CAMERA
local function disableFreecam()
    if not state.freecam then return end
    state.freecam = false

    if freecamMouseConnection then
        freecamMouseConnection:Disconnect()
        freecamMouseConnection = nil
    end

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true

    camera.CameraType = freecamOldType or Enum.CameraType.Custom
    camera.CameraSubject = freecamOldSubject or humanoid
    camera.FieldOfView = freecamOldFOV or original.FOV

    -- Возвращаем состояние Humanoid.
    if humanoid and humanoid.Parent then
        humanoid.AutoRotate = freecamOldAutoRotate ~= false
        humanoid.WalkSpeed = freecamOldWalkSpeed or state.walkSpeed
        humanoid.UseJumpPower = freecamOldUseJumpPower ~= false
        humanoid.JumpPower = freecamOldJumpPower or state.jumpPower
    end

    -- Возвращаем Anchored всех частей персонажа.
    for part, wasAnchored in pairs(freecamOldAnchored) do
        if part and part.Parent then
            part.Anchored = wasAnchored
        end
    end
    table.clear(freecamOldAnchored)
end

local function enableFreecam()
    if state.freecam then return end
    state.freecam = true

    camera = workspace.CurrentCamera
    freecamOldType = camera.CameraType
    freecamOldSubject = camera.CameraSubject
    freecamOldFOV = camera.FieldOfView
    freecamPosition = camera.CFrame

    -- Запоминаем поворот камеры, чтобы мышь могла её вращать.
    local look = freecamPosition.LookVector
    freecamRotation = Vector2.new(
        math.asin(math.clamp(look.Y, -1, 1)),
        math.atan2(-look.X, -look.Z)
    )

    -- Замораживаем персонажа, не двигая свободную камеру.
    if humanoid and humanoid.Parent then
        freecamOldAutoRotate = humanoid.AutoRotate
        freecamOldWalkSpeed = humanoid.WalkSpeed
        freecamOldJumpPower = humanoid.JumpPower
        freecamOldUseJumpPower = humanoid.UseJumpPower

        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
    end

    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                freecamOldAnchored[part] = part.Anchored
                part.Anchored = true
            end
        end
    end

    camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    freecamMouseConnection = UserInputService.InputChanged:Connect(function(input)
        if not state.freecam then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local sensitivity = 0.003
            freecamRotation = Vector2.new(
                math.clamp(
                    freecamRotation.X - input.Delta.Y * sensitivity,
                    -math.rad(85),
                    math.rad(85)
                ),
                freecamRotation.Y - input.Delta.X * sensitivity
            )
        end
    end)
end

-- MOVEMENT PAGE
section(movementPage, "MOVEMENT CONTROLS")

local flyRefresh = statusButton(
    movementPage, "Flight",
    function() return state.fly end,
    function()
        state.fly = not state.fly
    end
)

numberSetting(movementPage, "Fly speed", 1, 250, state.flySpeed, function(v)
    state.flySpeed = v
end)

numberSetting(movementPage, "Walk speed", 1, 150, state.walkSpeed, function(v)
    state.walkSpeed = v
    if humanoid and humanoid.Parent and not state.freecam then
        humanoid.WalkSpeed = v
    end
end)

numberSetting(movementPage, "Jump power", 1, 250, state.jumpPower, function(v)
    state.jumpPower = v
    if humanoid and humanoid.Parent and not state.freecam then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = v
    end
end)

local noclipRefresh = statusButton(
    movementPage, "Noclip",
    function() return state.noclip end,
    function()
        state.noclip = not state.noclip
    end
)

button(movementPage, "Flight controls: WASD / Space / Ctrl", function() end)

-- VISUALS PAGE
section(visualPage, "VISUAL SETTINGS")

local espRefresh = statusButton(
    visualPage, "Player ESP",
    function() return state.esp end,
    function() state.esp = not state.esp end
)

local fpsLabel = make("TextLabel", {
    Size = UDim2.new(1, -5, 0, 30),
    BackgroundTransparency = 1,
    Text = "FPS: --",
    TextColor3 = Color3.fromRGB(95, 225, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, visualPage)

-- CAMERA PAGE
section(cameraPage, "CAMERA SETTINGS")

numberSetting(cameraPage, "Camera FOV", 40, 120, state.fov, function(v)
    state.fov = v
    if not state.freecam then
        camera.FieldOfView = v
    end
end)

numberSetting(cameraPage, "Free camera speed", 1, 200, state.freecamSpeed, function(v)
    state.freecamSpeed = v
end)

local freecamRefresh = statusButton(
    cameraPage, "Free camera",
    function() return state.freecam end,
    function()
        if state.freecam then
            disableFreecam()
        else
            enableFreecam()
        end
    end
)

button(cameraPage, "Reset camera FOV", function()
    state.fov = original.FOV
    camera.FieldOfView = original.FOV
end)

-- CHARACTER PAGE
section(characterPage, "CHARACTER SETTINGS")

button(characterPage, "Toggle first-person mode", function()
    if player.CameraMode == Enum.CameraMode.LockFirstPerson then
        player.CameraMode = Enum.CameraMode.Classic
    else
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end)

button(characterPage, "Reset movement values", function()
    state.walkSpeed = 16
    state.jumpPower = 50

    if humanoid and humanoid.Parent and not state.freecam then
        humanoid.WalkSpeed = 16
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50
    end
end)

button(characterPage, "Restore default zoom", function()
    player.CameraMinZoomDistance = 0.5
    player.CameraMaxZoomDistance = 128
end)

-- LIGHTING PAGE
section(lightingPage, "LIGHTING SETTINGS")

button(lightingPage, "Bright preset", function()
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
end)

button(lightingPage, "Daytime", function()
    Lighting.ClockTime = 14
end)

button(lightingPage, "Night", function()
    Lighting.ClockTime = 0
end)

button(lightingPage, "Toggle global shadows", function()
    Lighting.GlobalShadows = not Lighting.GlobalShadows
end)

button(lightingPage, "Restore original lighting", function()
    for property, value in pairs({
        Brightness = original.Brightness,
        ClockTime = original.ClockTime,
        GlobalShadows = original.GlobalShadows,
        Ambient = original.Ambient,
        OutdoorAmbient = original.OutdoorAmbient,
    }) do
        Lighting[property] = value
    end
end)

-- FLIGHT SETUP
local function stopFlight()
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    if flyOrientation then flyOrientation:Destroy(); flyOrientation = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
end

local function setupFlight()
    stopFlight()

    if not state.fly or not character or not humanoid then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "FlyMenuAttachment"
    flyAttachment.Parent = root

    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Name = "FlyMenuVelocity"
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.MaxForce = 1000000
    flyVelocity.Parent = root

    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Name = "FlyMenuOrientation"
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.Responsiveness = 20
    flyOrientation.MaxTorque = 1000000
    flyOrientation.Parent = root
end

local function clearESP()
    for _, item in ipairs(espObjects) do
        pcall(function() item:Destroy() end)
    end
    table.clear(espObjects)
end

local function updateESP()
    clearESP()
    if not state.esp then return end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local highlight = Instance.new("Highlight")
            highlight.Name = "FlyMenuESP"
            highlight.Adornee = otherPlayer.Character
            highlight.FillColor = Color3.fromRGB(150, 65, 255)
            highlight.OutlineColor = Color3.fromRGB(90, 230, 255)
            highlight.FillTransparency = 0.65
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = workspace
            table.insert(espObjects, highlight)
        end
    end
end

-- Главный цикл
local frames = 0
local elapsed = 0
local lastFlyState = state.fly

keep(RunService.RenderStepped:Connect(function(dt)
    if destroyed then return end

    frames += 1
    elapsed += dt

    if elapsed >= 1 then
        fpsLabel.Text = "FPS: " .. math.floor(frames / elapsed)
        frames = 0
        elapsed = 0
    end

    camera = workspace.CurrentCamera

    -- Независимая камера: персонаж не двигается.
    if state.freecam then
        local movement = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            movement += Vector3.new(0, 0, -1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            movement += Vector3.new(0, 0, 1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            movement += Vector3.new(-1, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            movement += Vector3.new(1, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            movement += Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            movement += Vector3.new(0, -1, 0)
        end

        local rotation = CFrame.fromOrientation(
            freecamRotation.X,
            freecamRotation.Y,
            0
        )

        if movement.Magnitude > 0 then
            local worldMove = rotation:VectorToWorldSpace(movement.Unit)
            freecamPosition += worldMove * state.freecamSpeed * dt
        end

        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(freecamPosition.Position) * rotation
        camera.FieldOfView = state.fov
    end

    -- Полёт персонажа отключается отдельно от свободной камеры.
    if state.fly and not state.freecam and flyVelocity and flyOrientation and humanoid then
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if root then
            local move = Vector3.zero
            local cam = workspace.CurrentCamera

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                move += cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                move -= cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                move -= cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                move += cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                move += Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                move -= Vector3.new(0, 1, 0)
            end

            if move.Magnitude > 0 then move = move.Unit end

            flyVelocity.VectorVelocity = move * state.flySpeed
            flyOrientation.CFrame = CFrame.lookAt(
                root.Position,
                root.Position + cam.CFrame.LookVector
            )
        end
    end
end))

keep(RunService.Heartbeat:Connect(function()
    if destroyed or not character then return end

    if state.noclip and not state.freecam then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCollision[part] == nil then
                    originalCollision[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    else
        for part, oldValue in pairs(originalCollision) do
            if part and part.Parent then part.CanCollide = oldValue end
            originalCollision[part] = nil
        end
    end
end))

keep(RunService.Heartbeat:Connect(function()
    if destroyed then return end

    if state.fly ~= lastFlyState then
        lastFlyState = state.fly
        if state.fly then
            setupFlight()
        else
            stopFlight()
        end
    end
end))

-- Горячая клавиша G открывает и скрывает меню.
keep(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or destroyed then return end

    if input.KeyCode == Enum.KeyCode.G then
        minimized = not minimized
        main.Visible = not minimized
    end
end))

local function restoreEverything()
    if state.freecam then
        disableFreecam()
    end

    state.fly = false
    state.noclip = false
    state.esp = false
    stopFlight()
    clearESP()

    for part, oldValue in pairs(originalCollision) do
        if part and part.Parent then part.CanCollide = oldValue end
    end
    table.clear(originalCollision)

    if humanoid and humanoid.Parent then
        humanoid.WalkSpeed = original.WalkSpeed
        humanoid.JumpPower = original.JumpPower
        humanoid.UseJumpPower = original.UseJumpPower
    end

    for property, value in pairs({
        Brightness = original.Brightness,
        ClockTime = original.ClockTime,
        GlobalShadows = original.GlobalShadows,
        Ambient = original.Ambient,
        OutdoorAmbient = original.OutdoorAmbient,
    }) do
        pcall(function() Lighting[property] = value end)
    end

    camera = workspace.CurrentCamera
    camera.FieldOfView = original.FOV
    camera.CameraType = original.CameraType
    camera.CameraSubject = original.CameraSubject

    player.CameraMode = original.CameraMode
    player.CameraMinZoomDistance = original.MinZoom
    player.CameraMaxZoomDistance = original.MaxZoom
end

keep(minimizeButton.Activated:Connect(function()
    minimized = not minimized
    main.Visible = not minimized
end))

keep(closeButton.Activated:Connect(function()
    if destroyed then return end

    local modal = make("Frame", {
        Size = UDim2.fromOffset(350, 150),
        Position = UDim2.new(0.5, -175, 0.5, -75),
        BackgroundColor3 = Color3.fromRGB(27, 20, 42),
        BorderSizePixel = 0,
        ZIndex = 20,
    }, main)

    make("UICorner", {CornerRadius = UDim.new(0, 10)}, modal)

    make("TextLabel", {
        Size = UDim2.new(1, -20, 0, 65),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Text = "Закрыть меню навсегда?\nНастройки будут восстановлены.",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextWrapped = true,
        ZIndex = 21,
    }, modal)

    local yes = make("TextButton", {
        Size = UDim2.fromOffset(145, 35),
        Position = UDim2.fromOffset(18, 95),
        BackgroundColor3 = Color3.fromRGB(150, 50, 90),
        Text = "Закрыть",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 21,
    }, modal)

    local no = make("TextButton", {
        Size = UDim2.fromOffset(145, 35),
        Position = UDim2.fromOffset(187, 95),
        BackgroundColor3 = Color3.fromRGB(70, 60, 100),
        Text = "Отмена",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 21,
    }, modal)

    keep(yes.Activated:Connect(function()
        if destroyed then return end
        destroyed = true
        restoreEverything()
        disconnectAll()
        gui:Destroy()
    end))

    keep(no.Activated:Connect(function()
        modal:Destroy()
    end))
end))

keep(player.CharacterAdded:Connect(function(newCharacter)
    -- Если персонаж переродился во время Free Camera, выключаем её,
    -- чтобы не оставить новый персонаж замороженным.
    if state.freecam then
        disableFreecam()
    end

    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")

    original.WalkSpeed = humanoid.WalkSpeed
    original.JumpPower = humanoid.JumpPower
    original.UseJumpPower = humanoid.UseJumpPower

    humanoid.WalkSpeed = state.walkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = state.jumpPower

    if state.fly then
        task.wait(0.2)
        if not destroyed then setupFlight() end
    end
end))

task.spawn(function()
    while not destroyed do
        task.wait(1.5)
        if destroyed then break end

        if state.esp then
            updateESP()
        else
            clearESP()
        end
    end
end)

main.Size = UDim2.fromOffset(580, 420)
TweenService:Create(
    main,
    TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size = UDim2.fromOffset(650, 470)}
):Play()

print("FlyMenu V4 Adjustable loaded")

