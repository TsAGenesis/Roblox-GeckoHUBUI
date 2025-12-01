-- GeckoUI.lua v3.1
-- UI-Lib im GeckoHUB-Style: macOS-Titelbar, Settings, Buttons, Toggles, Slider,
-- Tabs, Dropdown, SearchBox, Notifications, Confirm-Dialogs, Tooltips

local GeckoUI = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

---------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------

GeckoUI.BaseTheme = {
    MainBackground   = Color3.fromRGB(0, 0, 0),
    TitleBackground  = Color3.fromRGB(10, 10, 10),
    Accent           = Color3.fromRGB(255, 140, 0),

    ButtonPrimary    = Color3.fromRGB(255, 255, 255),
    ButtonDanger     = Color3.fromRGB(255, 255, 255),
    ButtonWarn       = Color3.fromRGB(255, 255, 255),
    ButtonCopy       = Color3.fromRGB(255, 255, 255),
    SettingsBlue     = Color3.fromRGB(255, 255, 255),

    ScrollBackground = Color3.fromRGB(8, 8, 8),
    TextMain         = Color3.fromRGB(255, 140, 0),
    TextMuted        = Color3.fromRGB(200, 110, 20),

    ToggleOff        = Color3.fromRGB(35, 35, 35),
    ToggleOn         = Color3.fromRGB(255, 255, 255),

    SliderTrack      = Color3.fromRGB(30, 30, 30),
    SliderFill       = Color3.fromRGB(255, 255, 255),

    TabBackground    = Color3.fromRGB(12, 12, 12),
    TabActive        = Color3.fromRGB(255, 255, 255),

    ToastInfo        = Color3.fromRGB(18, 18, 18),
    ToastSuccess     = Color3.fromRGB(18, 18, 18),
    ToastError       = Color3.fromRGB(18, 18, 18),

    -- Particle defaults
    ParticleColor1   = Color3.fromRGB(255, 255, 255),
    ParticleColor2   = Color3.fromRGB(230, 230, 230),
    ParticleMinSize  = 4,
    ParticleMaxSize  = 8,
    ParticleMinDelay = 0.8,
    ParticleMaxDelay = 1.8,
}

local function cloneTheme(t)
    local new = {}
    for k, v in pairs(t) do
        new[k] = v
    end
    return new
end

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------

local function createScreenGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name or "GeckoUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok, core = pcall(function()
        return game:GetService("CoreGui")
    end)

    if ok and core then
        gui.Parent = core
    else
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    return gui
end

local function makeDraggable(dragFrame, mainFrame)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function colorToString(c)
    return string.format("%d,%d,%d",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5)
    )
end

local function parseColor(str)
    local r, g, b = string.match(str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)
    if not (r and g and b) then
        return nil
    end
    r = math.clamp(r, 0, 255)
    g = math.clamp(g, 0, 255)
    b = math.clamp(b, 0, 255)
    return Color3.fromRGB(r, g, b)
end

local function roundify(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 10)
    corner.Parent = instance
    return corner
end

---------------------------------------------------------------------
-- CREATE WINDOW
---------------------------------------------------------------------

-- opts = {
--   Name        = "WindowName",
--   Title       = "🦎 Window Title",
--   Size        = UDim2.new(0, 500, 0, 450),
--   Position    = UDim2.new(0.3, 0, 0.2, 0),
--   Draggable   = true,
--   AllowResize = false
-- }

function GeckoUI.CreateWindow(opts)
    opts = opts or {}
    local name        = opts.Name or "GeckoWindow"
    local titleText   = opts.Title or name
    local size        = opts.Size or UDim2.new(0, 500, 0, 450)
    local pos         = opts.Position or UDim2.new(0.3, 0, 0.2, 0)
    local draggable   = (opts.Draggable ~= false)
    local allowResize = opts.AllowResize or false

    local theme     = cloneTheme(GeckoUI.BaseTheme)
    local screenGui = createScreenGui(name)

    local window = {
        Theme = theme,
        ScreenGui = screenGui,
        Controls = {
            Buttons   = {},
            Labels    = {},
            Scrolls   = {},
            Toggles   = {},
            Sliders   = {},
            Dropdowns = {},
            Tabs      = {},
            SearchBoxes = {},
        },
        __tooltips = {},
        __toasts   = {},
    }

    -----------------------------------------------------------------
    -- FRAME / TITLEBAR
    -----------------------------------------------------------------
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = theme.MainBackground
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = pos
    mainFrame.Size = size
    mainFrame.ClipsDescendants = false
    roundify(mainFrame, UDim.new(0, 12))

    local fullSize = size

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.BackgroundColor3 = theme.TitleBackground
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Active = true
    roundify(titleBar, UDim.new(0, 12))

    if draggable then
        makeDraggable(titleBar, mainFrame)
    end

    -- macOS Buttons: rot, gelb, blau (Settings)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = titleBar
    closeBtn.BackgroundColor3 = theme.ButtonDanger
    closeBtn.BorderSizePixel = 0
    closeBtn.Position = UDim2.new(0, 10, 0.5, -6)
    closeBtn.Size = UDim2.new(0, 12, 0, 12)
    closeBtn.Text = ""
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10
    closeBtn.AutoButtonColor = false
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

        local minBtn = Instance.new("TextButton")
        minBtn.Parent = titleBar
        minBtn.BackgroundColor3 = theme.ButtonWarn
    minBtn.BorderSizePixel = 0
    minBtn.Position = UDim2.new(0, 30, 0.5, -6)
    minBtn.Size = UDim2.new(0, 12, 0, 12)
    minBtn.Text = ""
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 10
    minBtn.AutoButtonColor = false
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Parent = titleBar
    settingsBtn.BackgroundColor3 = theme.SettingsBlue
    settingsBtn.BorderSizePixel = 0
    settingsBtn.Position = UDim2.new(0, 50, 0.5, -6)
    settingsBtn.Size = UDim2.new(0, 12, 0, 12)
    settingsBtn.Text = ""
    settingsBtn.Font = Enum.Font.GothamBold
    settingsBtn.TextSize = 10
    settingsBtn.AutoButtonColor = false
    Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(1, 0)

    closeBtn.MouseEnter:Connect(function() closeBtn.Text = "×" end)
    closeBtn.MouseLeave:Connect(function() closeBtn.Text = "" end)
    minBtn.MouseEnter:Connect(function() minBtn.Text = "−" end)
    minBtn.MouseLeave:Connect(function() minBtn.Text = "" end)
    settingsBtn.MouseEnter:Connect(function() settingsBtn.Text = "⚙" end)
    settingsBtn.MouseLeave:Connect(function() settingsBtn.Text = "" end)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Parent = titleBar
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 80, 0, 0)
    titleLabel.Size = UDim2.new(1, -160, 1, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = titleText
    titleLabel.TextColor3 = theme.Accent
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Haupt-Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Parent = mainFrame
    content.BackgroundColor3 = theme.ScrollBackground
    content.BorderSizePixel = 0
    content.Position = UDim2.new(0, 0, 0, 35)
    content.Size = UDim2.new(1, 0, 1, -35)
    roundify(content, UDim.new(0, 12))

    -- Animated particle background (subtle bubbles)
    local particleFrame = Instance.new("Frame")
    particleFrame.Name = "ParticleFrame"
    particleFrame.Parent = content
    particleFrame.BackgroundTransparency = 1
    particleFrame.BorderSizePixel = 0
    particleFrame.Size = UDim2.new(1, 0, 1, 0)
    particleFrame.ClipsDescendants = true
    particleFrame.ZIndex = 0
    particleFrame.Active = false

    local particleConfig = {
        Color1 = theme.ParticleColor1,
        Color2 = theme.ParticleColor2,
        MinSize = theme.ParticleMinSize or 4,
        MaxSize = theme.ParticleMaxSize or 8,
        MinDelay = theme.ParticleMinDelay or 0.8,
        MaxDelay = theme.ParticleMaxDelay or 1.8,
    }

    local function spawnParticle()
        local dot = Instance.new("Frame")
        dot.Parent = particleFrame
        dot.BackgroundTransparency = 0.2
        dot.BorderSizePixel = 0
        local sz = math.random(math.floor(particleConfig.MinSize), math.floor(particleConfig.MaxSize))
        dot.Size = UDim2.new(0, sz, 0, sz)
        dot.Position = UDim2.new(math.random(), 0, 1, 0)
        dot.BackgroundColor3 = (math.random() < 0.5) and particleConfig.Color1 or particleConfig.Color2
        dot.ZIndex = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local duration = math.random(6, 12)
        local endPos = UDim2.new(dot.Position.X.Scale, 0, -0.1, 0)
        local tween = TweenService:Create(dot, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Position = endPos,
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            dot:Destroy()
        end)
    end

    task.spawn(function()
        while particleFrame.Parent do
            spawnParticle()
            local minD = math.max(0.1, particleConfig.MinDelay)
            local maxD = math.max(minD, particleConfig.MaxDelay)
            task.wait(math.random() * (maxD - minD) + minD)
        end
    end)

    -- Forward declaration so minimize can reference it
    local settingsPanel

    -----------------------------------------------------------------
    -- Minimize / Close
    -----------------------------------------------------------------
    local isMinimized = false

    local function setMinimized(minimized)
        isMinimized = minimized
        local prevSettingsVisible = settingsPanel and settingsPanel.Visible
        if minimized then
            mainFrame:TweenSize(
                UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 35),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.25,
                true
            )
            if content then content.Visible = false end
            if settingsPanel then settingsPanel.Visible = false end
        else
            mainFrame:TweenSize(
                fullSize,
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.25,
                true
            )
            if content then content.Visible = true end
            if settingsPanel then settingsPanel.Visible = prevSettingsVisible end
        end
    end

    minBtn.MouseButton1Click:Connect(function()
        setMinimized(not isMinimized)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -----------------------------------------------------------------
    -- Resize Handle (optional)
    -----------------------------------------------------------------
    local resizeHandle
    if allowResize then
        resizeHandle = Instance.new("TextButton")
        resizeHandle.Name = "ResizeHandle"
        resizeHandle.Parent = mainFrame
        resizeHandle.BackgroundColor3 = theme.ButtonPrimary
        resizeHandle.BorderSizePixel = 0
        resizeHandle.Position = UDim2.new(1, -15, 1, -15)
        resizeHandle.Size = UDim2.new(0, 15, 0, 15)
        resizeHandle.Text = "⇲"
        resizeHandle.TextColor3 = theme.TextMain
        resizeHandle.TextSize = 10
        resizeHandle.Font = Enum.Font.GothamBold
        resizeHandle.ZIndex = 50
        roundify(resizeHandle, UDim.new(0, 6))

        local resizing = false
        local resizeStart
        local startSize

        resizeHandle.MouseButton1Down:Connect(function()
            resizing = true
            resizeStart = UserInputService:GetMouseLocation()
            startSize = mainFrame.Size
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
                fullSize = mainFrame.Size
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local currentPos = UserInputService:GetMouseLocation()
                local delta = currentPos - resizeStart

                local newW = math.max(300, startSize.X.Offset + delta.X)
                local newH = math.max(150, startSize.Y.Offset + delta.Y)
                mainFrame.Size = UDim2.new(0, newW, 0, newH)
            end
        end)
    end

    -----------------------------------------------------------------
    -- SETTINGS PANEL (Farben einstellen)
    -----------------------------------------------------------------
    settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Parent = mainFrame
    settingsPanel.BackgroundColor3 = theme.MainBackground
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Position = UDim2.new(1, -280, 0, 40)
    settingsPanel.Size = UDim2.new(0, 280, 0, 560)
    settingsPanel.Visible = false
    settingsPanel.ZIndex = 40

    local spCorner = Instance.new("UICorner")
    spCorner.CornerRadius = UDim.new(0, 8)
    spCorner.Parent = settingsPanel

    local spStroke = Instance.new("UIStroke")
    spStroke.Parent = settingsPanel
    spStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    spStroke.Thickness = 1
    spStroke.Color = theme.ButtonPrimary

    local spTitle = Instance.new("TextLabel")
    spTitle.Parent = settingsPanel
    spTitle.BackgroundTransparency = 1
    spTitle.Position = UDim2.new(0, 10, 0, 8)
    spTitle.Size = UDim2.new(1, -20, 0, 18)
    spTitle.Font = Enum.Font.GothamBold
    spTitle.Text = "⚙ Einstellungen"
    spTitle.TextColor3 = theme.Accent
    spTitle.TextSize = 14
    spTitle.TextXAlignment = Enum.TextXAlignment.Left
    spTitle.ZIndex = 41

    local spSub = Instance.new("TextLabel")
    spSub.Parent = settingsPanel
    spSub.BackgroundTransparency = 1
    spSub.Position = UDim2.new(0, 10, 0, 26)
    spSub.Size = UDim2.new(1, -20, 0, 16)
    spSub.Font = Enum.Font.Gotham
    spSub.Text = "Farben per Picker setzen"
    spSub.TextColor3 = theme.TextMuted
    spSub.TextSize = 11
    spSub.TextXAlignment = Enum.TextXAlignment.Left
    spSub.ZIndex = 41

    local settingsRows = {}
    local numberRows = {}

    local function openColorPicker(row)
        local overlay = Instance.new("Frame")
        overlay.Parent = mainFrame
        overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
        overlay.BackgroundTransparency = 0.35
        overlay.BorderSizePixel = 0
        overlay.Size = UDim2.new(1,0,1,0)
        overlay.ZIndex = 120

        local dialog = Instance.new("Frame")
        dialog.Parent = overlay
        dialog.BackgroundColor3 = theme.TitleBackground
        dialog.BorderSizePixel = 0
        dialog.Size = UDim2.new(0, 300, 0, 240)
        dialog.Position = UDim2.new(0.5,0,0.5,0)
        dialog.AnchorPoint = Vector2.new(0.5,0.5)
        dialog.ZIndex = 121

        Instance.new("UICorner", dialog).CornerRadius = UDim.new(0,8)

        local title = Instance.new("TextLabel")
        title.Parent = dialog
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0,10,0,10)
        title.Size = UDim2.new(1,-20,0,18)
        title.Font = Enum.Font.GothamBold
        title.Text = "Farbe: "..row.Label
        title.TextColor3 = theme.TextMain
        title.TextSize = 13
        title.ZIndex = 122

        local preview = Instance.new("Frame")
        preview.Parent = dialog
        preview.BackgroundColor3 = row.Color
        preview.BorderSizePixel = 0
        preview.Position = UDim2.new(0,10,0,40)
        preview.Size = UDim2.new(0,60,0,30)
        preview.ZIndex = 122
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0,4)

        local function makeSlider(y,labelText,initial,cb)
            local frame = Instance.new("Frame")
            frame.Parent = dialog
            frame.BackgroundTransparency = 1
            frame.Position = UDim2.new(0,10,0,y)
            frame.Size = UDim2.new(1,-20,0,28)
            frame.ZIndex = 122

            local lbl = Instance.new("TextLabel")
            lbl.Parent = frame
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0,0,0,0)
            lbl.Size = UDim2.new(0,24,1,0)
            lbl.Font = Enum.Font.GothamBold
            lbl.Text = labelText
            lbl.TextColor3 = theme.TextMain
            lbl.TextSize = 11
            lbl.ZIndex = 122

            local track = Instance.new("Frame")
            track.Parent = frame
            track.BackgroundColor3 = theme.SliderTrack
            track.BorderSizePixel = 0
            track.Position = UDim2.new(0,30,0.5,-3)
            track.Size = UDim2.new(1,-40,0,6)
            track.ZIndex = 122

            local fill = Instance.new("Frame")
            fill.Parent = track
            fill.BackgroundColor3 = theme.ButtonPrimary
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new(initial/255,0,1,0)
            fill.ZIndex = 122

            local dragging=false
            local function updateFromX(x)
                local left = track.AbsolutePosition.X
                local w = track.AbsoluteSize.X
                local rel = math.clamp((x-left)/math.max(w,1),0,1)
                fill.Size = UDim2.new(rel,0,1,0)
                local v = math.floor(rel*255+0.5)
                cb(v)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=true
                    updateFromX(UserInputService:GetMouseLocation().X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                    updateFromX(UserInputService:GetMouseLocation().X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=false
                end
            end)
        end

        local r = math.floor(row.Color.R*255+0.5)
        local g = math.floor(row.Color.G*255+0.5)
        local b = math.floor(row.Color.B*255+0.5)

        local function applyColor()
            local c = Color3.fromRGB(r,g,b)
            preview.BackgroundColor3 = c
            row.Color = c
        end

        makeSlider(80,"R",r,function(v) r=v applyColor() end)
        makeSlider(120,"G",g,function(v) g=v applyColor() end)
        makeSlider(160,"B",b,function(v) b=v applyColor() end)

        local okBtn = Instance.new("TextButton")
        okBtn.Parent = dialog
        okBtn.BackgroundColor3 = theme.ButtonPrimary
        okBtn.BorderSizePixel = 0
        okBtn.Position = UDim2.new(0,10,1,-50)
        okBtn.Size = UDim2.new(0.5,-15,0,32)
        okBtn.Font = Enum.Font.GothamBold
        okBtn.Text = "OK"
        okBtn.TextColor3 = theme.TextMain
        okBtn.TextSize = 12
        okBtn.ZIndex = 122
        Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0,4)

        local cancelBtn = Instance.new("TextButton")
        cancelBtn.Parent = dialog
        cancelBtn.BackgroundColor3 = theme.ButtonDanger
        cancelBtn.BorderSizePixel = 0
        cancelBtn.Position = UDim2.new(0.5,5,1,-50)
        cancelBtn.Size = UDim2.new(0.5,-15,0,32)
        cancelBtn.Font = Enum.Font.GothamBold
        cancelBtn.Text = "Cancel"
        cancelBtn.TextColor3 = theme.TextMain
        cancelBtn.TextSize = 12
        cancelBtn.ZIndex = 122
        Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,4)

        okBtn.MouseButton1Click:Connect(function()
            theme[row.Key] = row.Color
            row.Preview.BackgroundColor3 = row.Color
            window:ApplyTheme()
            overlay:Destroy()
        end)

        cancelBtn.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end)
    end

    local function addColorRow(labelText, themeKey, order)
        local y = 46 + (order - 1) * 38

        local lbl = Instance.new("TextLabel")
        lbl.Parent = settingsPanel
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.Size = UDim2.new(0.5, -10, 0, 20)
        lbl.Font = Enum.Font.Gotham
        lbl.Text = labelText
        lbl.TextColor3 = theme.TextMain
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 41

        local preview = Instance.new("Frame")
        preview.Parent = settingsPanel
        preview.BackgroundColor3 = theme[themeKey]
        preview.BorderSizePixel = 0
        preview.Position = UDim2.new(0.5, 0, 0, y)
        preview.Size = UDim2.new(0, 26, 0, 20)
        preview.ZIndex = 41
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)

        local pickBtn = Instance.new("TextButton")
        pickBtn.Parent = settingsPanel
        pickBtn.BackgroundColor3 = theme.ButtonPrimary
        pickBtn.BorderSizePixel = 0
        pickBtn.Position = UDim2.new(0.5, 32, 0, y)
        pickBtn.Size = UDim2.new(0, 80, 0, 20)
        pickBtn.Font = Enum.Font.GothamBold
        pickBtn.Text = "Pick"
        pickBtn.TextColor3 = theme.TextMain
        pickBtn.TextSize = 11
        pickBtn.ZIndex = 41
        Instance.new("UICorner", pickBtn).CornerRadius = UDim.new(0, 4)

        local row = {
            Key = themeKey,
            Label = labelText,
            Preview = preview,
            Color = theme[themeKey],
        }
        table.insert(settingsRows, row)

        pickBtn.MouseButton1Click:Connect(function()
            openColorPicker(row)
        end)
    end

    -- Apply/Reset stay at bottom; content scrolls
    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Parent = settingsPanel
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0
    settingsScroll.Position = UDim2.new(0, 0, 0, 50)
    settingsScroll.Size = UDim2.new(1, 0, 1, -120)
    settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    settingsScroll.ScrollBarThickness = 4
    settingsScroll.ZIndex = 41

    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.Parent = settingsScroll
    settingsLayout.FillDirection = Enum.FillDirection.Vertical
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    settingsLayout.Padding = UDim.new(0, 6)

    local function addNumberRow(labelText, themeKey)
        local row = Instance.new("Frame")
        row.Parent = settingsScroll
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, -10, 0, 24)
        row.ZIndex = 41

        local lbl = Instance.new("TextLabel")
        lbl.Parent = row
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 10, 0, 2)
        lbl.Size = UDim2.new(0.55, -10, 0, 20)
        lbl.Font = Enum.Font.Gotham
        lbl.Text = labelText
        lbl.TextColor3 = theme.TextMain
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 41

        local box = Instance.new("TextBox")
        box.Parent = row
        box.BackgroundColor3 = theme.ScrollBackground
        box.BorderSizePixel = 0
        box.Position = UDim2.new(0.55, 0, 0, 2)
        box.Size = UDim2.new(0.45, -10, 0, 20)
        box.Font = Enum.Font.Code
        box.Text = tostring(theme[themeKey] or "")
        box.TextColor3 = theme.TextMain
        box.TextSize = 11
        box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ZIndex = 41
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

        table.insert(numberRows, {Key = themeKey, Box = box, Label = lbl})
    end

    -- Add rows into scroll
    local function addColorRow(labelText, themeKey)
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = settingsScroll
        rowFrame.BackgroundTransparency = 1
        rowFrame.Size = UDim2.new(1, -10, 0, 26)
        rowFrame.ZIndex = 41

        local lbl = Instance.new("TextLabel")
        lbl.Parent = rowFrame
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.Size = UDim2.new(0.5, -10, 1, 0)
        lbl.Font = Enum.Font.Gotham
        lbl.Text = labelText
        lbl.TextColor3 = theme.TextMain
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 41

        local preview = Instance.new("Frame")
        preview.Parent = rowFrame
        preview.BackgroundColor3 = theme[themeKey]
        preview.BorderSizePixel = 0
        preview.Position = UDim2.new(0.5, 0, 0.5, -10)
        preview.Size = UDim2.new(0, 26, 0, 20)
        preview.ZIndex = 41
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)

        local pickBtn = Instance.new("TextButton")
        pickBtn.Parent = rowFrame
        pickBtn.BackgroundColor3 = theme.ButtonPrimary
        pickBtn.BorderSizePixel = 0
        pickBtn.Position = UDim2.new(0.5, 32, 0.5, -10)
        pickBtn.Size = UDim2.new(0, 80, 0, 20)
        pickBtn.Font = Enum.Font.GothamBold
        pickBtn.Text = "Pick"
        pickBtn.TextColor3 = theme.TextMain
        pickBtn.TextSize = 11
        pickBtn.ZIndex = 41
        Instance.new("UICorner", pickBtn).CornerRadius = UDim.new(0, 4)

        local row = {
            Key = themeKey,
            Label = labelText,
            Preview = preview,
            Color = theme[themeKey],
        }
        table.insert(settingsRows, row)

        pickBtn.MouseButton1Click:Connect(function()
            openColorPicker(row)
        end)
    end

    addColorRow("Main BG",       "MainBackground")
    addColorRow("Title BG",      "TitleBackground")
    addColorRow("Accent",        "Accent")
    addColorRow("Buttons",       "ButtonPrimary")
    addColorRow("Text Main",     "TextMain")
    addColorRow("Scroll BG",     "ScrollBackground")
    addColorRow("Particle A",    "ParticleColor1")
    addColorRow("Particle B",    "ParticleColor2")

    addNumberRow("Particle Min Size", "ParticleMinSize")
    addNumberRow("Particle Max Size", "ParticleMaxSize")
    addNumberRow("Particle Min Delay", "ParticleMinDelay")
    addNumberRow("Particle Max Delay", "ParticleMaxDelay")

    settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        settingsScroll.CanvasSize = UDim2.new(0,0,0, settingsLayout.AbsoluteContentSize.Y + 10)
    end)

    local applyBtn = Instance.new("TextButton")
    applyBtn.Parent = settingsPanel
    applyBtn.BackgroundColor3 = theme.ButtonPrimary
    applyBtn.BorderSizePixel = 0
    applyBtn.Position = UDim2.new(0, 10, 1, -60)
    applyBtn.Size = UDim2.new(0.5, -15, 0, 28)
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.Text = "✔ Anwenden"
    applyBtn.TextColor3 = theme.TextMain
    applyBtn.TextSize = 12
    applyBtn.ZIndex = 41

    local resetBtn = Instance.new("TextButton")
    resetBtn.Parent = settingsPanel
    resetBtn.BackgroundColor3 = theme.ButtonDanger
    resetBtn.BorderSizePixel = 0
    resetBtn.Position = UDim2.new(0.5, 5, 1, -60)
    resetBtn.Size = UDim2.new(0.5, -15, 0, 28)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.Text = "⟲ Reset"
    resetBtn.TextColor3 = theme.TextMain
    resetBtn.TextSize = 12
    resetBtn.ZIndex = 41

        settingsBtn.MouseButton1Click:Connect(function()
            if isMinimized then return end
            settingsPanel.Visible = not settingsPanel.Visible
        end)

    -----------------------------------------------------------------
    -- TOOLTIP SYSTEM (ein globales Tooltip-Label pro Window)
    -----------------------------------------------------------------
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Parent = screenGui
    tooltip.BackgroundColor3 = theme.TitleBackground
    tooltip.BackgroundTransparency = 0.15
    tooltip.BorderSizePixel = 0
    tooltip.AutomaticSize = Enum.AutomaticSize.XY
    tooltip.Visible = false
    tooltip.Font = Enum.Font.Gotham
    tooltip.Text = ""
    tooltip.TextColor3 = theme.TextMain
    tooltip.TextSize = 11
    tooltip.TextXAlignment = Enum.TextXAlignment.Left
    tooltip.TextYAlignment = Enum.TextYAlignment.Center
    tooltip.ZIndex = 100

    local tipCorner = Instance.new("UICorner")
    tipCorner.CornerRadius = UDim.new(0, 4)
    tipCorner.Parent = tooltip

    local tipPadding = Instance.new("UIPadding")
    tipPadding.Parent = tooltip
    tipPadding.PaddingLeft = UDim.new(0, 6)
    tipPadding.PaddingRight = UDim.new(0, 6)
    tipPadding.PaddingTop = UDim.new(0, 2)
    tipPadding.PaddingBottom = UDim.new(0, 2)

    local currentTooltipTarget = nil

    local function setTooltipVisible(v)
        tooltip.Visible = v
    end

    UserInputService.InputChanged:Connect(function(input)
        if tooltip.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = UserInputService:GetMouseLocation()
            tooltip.Position = UDim2.new(0, pos.X + 10, 0, pos.Y + 10)
        end
    end)

    function window:SetTooltip(guiObject, text)
        if not guiObject then return end
        self.__tooltips[guiObject] = text

        guiObject.MouseEnter:Connect(function()
            local t = self.__tooltips[guiObject]
            if t and t ~= "" then
                tooltip.Text = t
                local pos = UserInputService:GetMouseLocation()
                tooltip.Position = UDim2.new(0, pos.X + 10, 0, pos.Y + 10)
                currentTooltipTarget = guiObject
                setTooltipVisible(true)
            end
        end)

        guiObject.MouseLeave:Connect(function()
            if currentTooltipTarget == guiObject then
                setTooltipVisible(false)
                currentTooltipTarget = nil
            end
        end)
    end

    -----------------------------------------------------------------
    -- THEME APPLY
    -----------------------------------------------------------------
    function window:ApplyTheme()
        local t = self.Theme

        mainFrame.BackgroundColor3 = t.MainBackground
        titleBar.BackgroundColor3 = t.TitleBackground
        titleLabel.TextColor3     = t.Accent
        content.BackgroundColor3  = t.ScrollBackground
        tooltip.BackgroundColor3  = t.TitleBackground
        tooltip.TextColor3        = t.TextMain

        closeBtn.BackgroundColor3    = t.ButtonDanger
        minBtn.BackgroundColor3      = t.ButtonWarn
        settingsBtn.BackgroundColor3 = t.SettingsBlue

        spTitle.TextColor3 = t.Accent
        spSub.TextColor3   = t.TextMuted

        for _, row in ipairs(settingsRows) do
            local key = row.Key
            if t[key] then
                row.Color = t[key]
                row.Preview.BackgroundColor3 = t[key]
            end
        end

        for _, row in ipairs(numberRows) do
            local key = row.Key
            if t[key] then
                row.Box.Text = tostring(t[key])
            end
        end

        particleConfig.Color1   = t.ParticleColor1
        particleConfig.Color2   = t.ParticleColor2
        particleConfig.MinSize  = t.ParticleMinSize
        particleConfig.MaxSize  = t.ParticleMaxSize
        particleConfig.MinDelay = t.ParticleMinDelay
        particleConfig.MaxDelay = t.ParticleMaxDelay

        -- Buttons
        for _, btn in ipairs(self.Controls.Buttons) do
            local primary = btn:GetAttribute("GeckoPrimary")
            if primary == nil then primary = true end
            if primary then
                btn.BackgroundColor3 = t.ButtonPrimary
                btn.TextColor3 = t.TextMain
            end
        end

        -- Labels
        for _, lbl in ipairs(self.Controls.Labels) do
            local muted = lbl:GetAttribute("GeckoMuted") == true
            if muted then
                lbl.TextColor3 = t.TextMuted
            else
                lbl.TextColor3 = t.TextMain
            end
        end

        -- Scrolls
        for _, sc in ipairs(self.Controls.Scrolls) do
            sc.BackgroundColor3 = t.ScrollBackground
            sc.ScrollBarImageColor3 = t.ButtonPrimary
        end

        -- Toggles
        for _, tg in ipairs(self.Controls.Toggles) do
            local state = tg.state or false
            if state then
                tg.__bg.BackgroundColor3 = t.ToggleOn
                tg.__knob.Position = UDim2.new(1, -18, 0, 2)
            else
                tg.__bg.BackgroundColor3 = t.ToggleOff
                tg.__knob.Position = UDim2.new(0, 2, 0, 2)
            end
            tg.__knob.BackgroundColor3 = state and t.MainBackground or t.ButtonPrimary
        end

        -- Sliders
        for _, sl in ipairs(self.Controls.Sliders) do
            sl.__track.BackgroundColor3 = t.SliderTrack
            sl.__fill.BackgroundColor3  = t.SliderFill
            sl.__knob.BackgroundColor3  = t.ButtonPrimary
            sl:__UpdateVisual()
        end

        -- Tabs
        for _, tabView in ipairs(self.Controls.Tabs) do
            tabView:ApplyTheme()
        end

        -- Dropdowns
        for _, dd in ipairs(self.Controls.Dropdowns) do
            dd:ApplyTheme()
        end

        -- SearchBoxes
        for _, sb in ipairs(self.Controls.SearchBoxes) do
            sb:ApplyTheme()
        end
    end

    applyBtn.MouseButton1Click:Connect(function()
        for _, row in ipairs(numberRows) do
            local num = tonumber(row.Box.Text)
            if num then
                theme[row.Key] = num
            end
        end
        window:ApplyTheme()
    end)

    resetBtn.MouseButton1Click:Connect(function()
        window.Theme = cloneTheme(GeckoUI.BaseTheme)
        theme = window.Theme
        window:ApplyTheme()
    end)

    -----------------------------------------------------------------
    -- BASIC CONTROLS
    -----------------------------------------------------------------

    function window:CreateLabel(props)
        props = props or {}
        local parent = props.Parent or content

        local lbl = Instance.new("TextLabel")
        lbl.Parent = parent
        lbl.BackgroundTransparency = props.BackgroundTransparency or 1
        lbl.BackgroundColor3 = props.BackgroundColor3 or theme.MainBackground
        lbl.BorderSizePixel = 0
        lbl.Position = props.Position or UDim2.new(0, 0, 0, 0)
        lbl.Size = props.Size or UDim2.new(0, 100, 0, 20)
        lbl.Font = props.Font or Enum.Font.Gotham
        lbl.Text = props.Text or "Label"
        lbl.TextColor3 = props.TextColor3 or theme.TextMain
        lbl.TextSize = props.TextSize or 12
        lbl.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
        lbl.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
        lbl.TextWrapped = props.TextWrapped or false
        lbl.ZIndex = props.ZIndex or 1

        lbl:SetAttribute("GeckoMuted", props.Muted or false)

        table.insert(self.Controls.Labels, lbl)
        return lbl
    end

    function window:CreateButton(props)
        props = props or {}
        local parent = props.Parent or content

        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.BackgroundColor3 = props.BackgroundColor3 or theme.ButtonPrimary
        btn.BorderSizePixel = 0
        btn.Position = props.Position or UDim2.new(0, 0, 0, 0)
        btn.Size = props.Size or UDim2.new(0, 120, 0, 32)
        btn.Font = props.Font or Enum.Font.GothamBold
        btn.Text = props.Text or "Button"
        btn.TextColor3 = props.TextColor3 or theme.TextMain
        btn.TextSize = props.TextSize or 12
        btn.AutoButtonColor = (props.AutoButtonColor ~= false)
        btn.ZIndex = props.ZIndex or 1

        local cornerRadius = props.CornerRadius
        if cornerRadius ~= false then
            local c = Instance.new("UICorner")
            c.CornerRadius = cornerRadius or UDim.new(0, 8)
            c.Parent = btn
        end

        btn:SetAttribute("GeckoPrimary", (props.Primary ~= false))

        if props.OnClick then
            btn.MouseButton1Click:Connect(props.OnClick)
        end

        table.insert(self.Controls.Buttons, btn)
        return btn
    end

    function window:CreateScroll(props)
        props = props or {}
        local parent = props.Parent or content

        local scroll = Instance.new("ScrollingFrame")
        scroll.Parent = parent
        scroll.BackgroundColor3 = props.BackgroundColor3 or theme.ScrollBackground
        scroll.BorderSizePixel = 0
        scroll.Position = props.Position or UDim2.new(0, 0, 0, 0)
        scroll.Size = props.Size or UDim2.new(1, 0, 1, 0)
        scroll.CanvasSize = props.CanvasSize or UDim2.new(0, 0, 0, 0)
        scroll.ScrollBarThickness = props.ScrollBarThickness or 6
        scroll.ScrollBarImageColor3 = props.ScrollBarImageColor3 or theme.ButtonPrimary
        scroll.ZIndex = props.ZIndex or 1
        roundify(scroll, UDim.new(0, 8))

        table.insert(self.Controls.Scrolls, scroll)
        return scroll
    end

    -- Toggle
    function window:CreateToggle(props)
        props = props or {}
        local parent = props.Parent or content
        local state = props.Default == true
        local onChanged = props.OnChanged
        local toggleObj = {state = state}

        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.BackgroundTransparency = 1
        frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
        frame.Size = props.Size or UDim2.new(0, 120, 0, 24)
        frame.ZIndex = props.ZIndex or 10

        local label
        if props.Label then
            label = self:CreateLabel({
                Parent = frame,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                Text = props.Label,
                TextSize = 12,
                ZIndex = frame.ZIndex,
            })
        end

        local bg = Instance.new("TextButton")
        bg.Parent = frame
        bg.BackgroundColor3 = theme.ToggleOff
        bg.BorderSizePixel = 0
        bg.Position = UDim2.new(1, -36, 0.5, -10)
        bg.Size = UDim2.new(0, 32, 0, 20)
        bg.ZIndex = frame.ZIndex + 1
        bg.Text = ""
        bg.AutoButtonColor = false

        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(1, 0)
        bgCorner.Parent = bg

        local knob = Instance.new("TextButton")
        knob.Parent = bg
        knob.BackgroundColor3 = theme.ButtonPrimary
        knob.BorderSizePixel = 0
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.ZIndex = frame.ZIndex + 2
        knob.Text = ""
        knob.AutoButtonColor = false

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local function updateVisual()
            local targetBg = state and theme.ToggleOn or theme.ToggleOff
            local targetPos = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
            local targetKnob = state and theme.MainBackground or theme.ButtonPrimary

            TweenService:Create(bg, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundColor3 = targetBg}):Play()
            TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = targetPos,
                BackgroundColor3 = targetKnob,
            }):Play()
        end

        local function setValue(v)
            local newState = v and true or false
            if newState == state then return end
            state = newState
            toggleObj.state = state
            updateVisual()
            if onChanged then
                onChanged(state)
            end
        end

        updateVisual()

        local debounce = false
        local function click()
            if debounce then return end
            debounce = true
            setValue(not state)
            task.delay(0.05, function() debounce = false end)
        end

        bg.MouseButton1Click:Connect(click)
        knob.MouseButton1Click:Connect(click)

        toggleObj.Frame = frame
        toggleObj.Background = bg
        toggleObj.Knob = knob
        toggleObj.Label = label
        toggleObj.GetValue = function()
            return state
        end
        toggleObj.SetValue = setValue
        toggleObj.__bg = bg
        toggleObj.__knob = knob

        table.insert(self.Controls.Toggles, toggleObj)
        return toggleObj
    end

    -- Slider
    function window:CreateSlider(props)
        props = props or {}
        local parent = props.Parent or content

        local minVal = props.Min or 0
        local maxVal = props.Max or 100
        local value  = props.Default or minVal
        local onChanged = props.OnChanged

        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.BackgroundTransparency = 1
        frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
        frame.Size = props.Size or UDim2.new(0, 180, 0, 32)
        frame.ZIndex = props.ZIndex or 1

        local label
        if props.Label then
            label = self:CreateLabel({
                Parent = frame,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 14),
                Text = props.Label,
                TextSize = 11,
                Muted = true,
            })
            label.ZIndex = frame.ZIndex
        end

        local track = Instance.new("Frame")
        track.Parent = frame
        track.BackgroundColor3 = theme.SliderTrack
        track.BorderSizePixel = 0
        track.Position = UDim2.new(0, 0, 0, props.Label and 18 or 8)
        track.Size = UDim2.new(1, 0, 0, 6)
        track.ZIndex = frame.ZIndex

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0, 3)
        trackCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.Parent = track
        fill.BackgroundColor3 = theme.SliderFill
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.ZIndex = frame.ZIndex + 1

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fill

        local knob = Instance.new("Frame")
        knob.Parent = frame
        knob.BackgroundColor3 = theme.ButtonPrimary
        knob.BorderSizePixel = 0
        knob.Size = UDim2.new(0, 10, 0, 14)
        knob.Position = UDim2.new(0, 0, 0, (props.Label and 14 or 4))
        knob.ZIndex = frame.ZIndex + 2

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 3)
        knobCorner.Parent = knob

        local valueLabel = self:CreateLabel({
            Parent = frame,
            Position = UDim2.new(1, -40, 0, props.Label and 0 or -2),
            Size = UDim2.new(0, 40, 0, 14),
            Text = tostring(value),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            Muted = false,
        })
        valueLabel.ZIndex = frame.ZIndex + 2

        local dragging = false
        local sliderObj = {}

        function sliderObj:__UpdateVisual()
            local rel = 0
            if maxVal ~= minVal then
                rel = (value - minVal) / (maxVal - minVal)
            end
            rel = math.clamp(rel, 0, 1)

            local w = track.AbsoluteSize.X
            local px = w * rel
            fill.Size = UDim2.new(0, px, 1, 0)
            knob.Position = UDim2.new(0, px - knob.Size.X.Offset/2, 0, knob.Position.Y.Offset)
            valueLabel.Text = string.format("%.0f", value)
        end

        local function setValue(v, fromUser)
            v = math.clamp(v, minVal, maxVal)
            value = v
            sliderObj:__UpdateVisual()
            if onChanged and fromUser then
                onChanged(value)
            end
        end

        local function inputToValue(xPos)
            local left = track.AbsolutePosition.X
            local w = track.AbsoluteSize.X
            local rel = 0
            if w > 0 then
                rel = (xPos - left) / w
            end
            rel = math.clamp(rel, 0, 1)
            local v = minVal + (maxVal - minVal) * rel
            return v
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local mouse = UserInputService:GetMouseLocation()
                setValue(inputToValue(mouse.X), true)
            end
        end)

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                setValue(inputToValue(mouse.X), true)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        function sliderObj:GetValue()
            return value
        end

        function sliderObj:SetValue(v)
            setValue(v, false)
        end

        sliderObj.Frame    = frame
        sliderObj.__track  = track
        sliderObj.__fill   = fill
        sliderObj.__knob   = knob

        sliderObj:__UpdateVisual()

        table.insert(self.Controls.Sliders, sliderObj)
        return sliderObj
    end

    -----------------------------------------------------------------
    -- SEARCH BOX
    -----------------------------------------------------------------
    function window:CreateSearchBox(props)
        props = props or {}
        local parent = props.Parent or content

        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.BackgroundColor3 = theme.ScrollBackground
        frame.BorderSizePixel = 0
        frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
        frame.Size = props.Size or UDim2.new(0, 220, 0, 26)
        frame.ZIndex = props.ZIndex or 1

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = frame

        local icon = self:CreateLabel({
            Parent = frame,
            Position = UDim2.new(0, 6, 0, 0),
            Size = UDim2.new(0, 20, 1, 0),
            Text = "🔍",
            TextSize = 12,
        })
        icon.ZIndex = frame.ZIndex + 1

        local box = Instance.new("TextBox")
        box.Parent = frame
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Position = UDim2.new(0, 24, 0, 0)
        box.Size = UDim2.new(1, -26, 1, 0)
        box.Font = Enum.Font.Gotham
        box.Text = ""
        box.TextColor3 = theme.TextMain
        box.TextSize = 12
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.PlaceholderText = props.Placeholder or "Suche..."
        box.PlaceholderColor3 = theme.TextMuted
        box.ZIndex = frame.ZIndex + 1

        local searchObj = {}

        function searchObj:ApplyTheme()
            frame.BackgroundColor3       = theme.ScrollBackground
            box.TextColor3               = theme.TextMain
            box.PlaceholderColor3        = theme.TextMuted
        end

        box:GetPropertyChangedSignal("Text"):Connect(function()
            if props.OnChanged then
                props.OnChanged(box.Text)
            end
        end)

        searchObj.Frame = frame
        searchObj.TextBox = box

        table.insert(self.Controls.SearchBoxes, searchObj)
        self:ApplyTheme()

        return searchObj
    end

    -----------------------------------------------------------------
    -- DROPDOWN
    -----------------------------------------------------------------
    function window:CreateDropdown(props)
        props = props or {}
        local parent = props.Parent or content
        local items  = props.Items or {}
        local defaultIndex = props.DefaultIndex or 1
        local onChanged = props.OnChanged

        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.BackgroundColor3 = theme.ScrollBackground
        frame.BorderSizePixel = 0
        frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
        frame.Size = props.Size or UDim2.new(0, 180, 0, 26)
        frame.ZIndex = props.ZIndex or 1

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = frame

        local label = self:CreateLabel({
            Parent = frame,
            Position = UDim2.new(0, 6, 0, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = items[defaultIndex] or "Select...",
            TextSize = 12,
        })
        label.ZIndex = frame.ZIndex + 1

        local arrow = self:CreateLabel({
            Parent = frame,
            Position = UDim2.new(1, -18, 0, 0),
            Size = UDim2.new(0, 18, 1, 0),
            Text = "▼",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        arrow.ZIndex = frame.ZIndex + 1

        local listFrame = Instance.new("Frame")
        listFrame.Parent = parent
        listFrame.BackgroundColor3 = theme.ScrollBackground
        listFrame.BorderSizePixel = 0
        listFrame.Size = UDim2.new(0, frame.Size.X.Offset, 0, 0)
        listFrame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 0, frame.Position.Y.Offset + frame.Size.Y.Offset + 2)
        listFrame.Visible = false
        listFrame.ZIndex = frame.ZIndex + 10

        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 4)
        listCorner.Parent = listFrame

        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = listFrame
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local currentIndex = defaultIndex

        local dropdownObj = {}

        local function rebuildList()
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            for i, text in ipairs(items) do
                local itemBtn = Instance.new("TextButton")
                itemBtn.Parent = listFrame
                itemBtn.BackgroundColor3 = theme.TabBackground
                itemBtn.BorderSizePixel = 0
                itemBtn.Size = UDim2.new(1, 0, 0, 24)
                itemBtn.Font = Enum.Font.Gotham
                itemBtn.Text = text
                itemBtn.TextSize = 12
                itemBtn.TextColor3 = theme.TextMain
                itemBtn.ZIndex = listFrame.ZIndex + 1

                itemBtn.MouseButton1Click:Connect(function()
                    currentIndex = i
                    label.Text = text
                    listFrame.Visible = false
                    if onChanged then
                        onChanged(text, i)
                    end
                end)
            end

            local totalHeight = #items * 24
            listFrame.Size = UDim2.new(0, frame.Size.X.Offset, 0, totalHeight)
        end

        rebuildList()

        local function toggleList()
            listFrame.Visible = not listFrame.Visible
        end

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                toggleList()
            end
        end)

        function dropdownObj:GetSelected()
            return items[currentIndex], currentIndex
        end

        function dropdownObj:SetSelected(index)
            index = math.clamp(index, 1, #items)
            currentIndex = index
            label.Text = items[index]
        end

        function dropdownObj:ApplyTheme()
            frame.BackgroundColor3  = theme.ScrollBackground
            label.TextColor3        = theme.TextMain
            arrow.TextColor3        = theme.TextMain
            listFrame.BackgroundColor3 = theme.ScrollBackground
            for _, btn in ipairs(listFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = theme.TabBackground
                    btn.TextColor3 = theme.TextMain
                end
            end
        end

        table.insert(self.Controls.Dropdowns, dropdownObj)
        self:ApplyTheme()

        dropdownObj.Frame = frame
        dropdownObj.ListFrame = listFrame

        return dropdownObj
    end

    -----------------------------------------------------------------
    -- TABS
    -----------------------------------------------------------------
    function window:CreateTabs(props)
        props = props or {}
        local parent = props.Parent or content
        local height = props.Height or 28

        local tabsBar = Instance.new("Frame")
        tabsBar.Parent = parent
        tabsBar.BackgroundColor3 = theme.TabBackground
        tabsBar.BorderSizePixel = 0
        tabsBar.Position = UDim2.new(0, 0, 0, 0)
        tabsBar.Size = UDim2.new(1, 0, 0, height)
        tabsBar.ZIndex = 5
        roundify(tabsBar, UDim.new(0, 8))

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Parent = tabsBar
        tabLayout.FillDirection = Enum.FillDirection.Horizontal
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Padding = UDim.new(0, 4)

        local contentArea = Instance.new("Frame")
        contentArea.Parent = parent
        contentArea.BackgroundTransparency = 1
        contentArea.BorderSizePixel = 0
        contentArea.Position = UDim2.new(0, 0, 0, height)
        contentArea.Size = UDim2.new(1, 0, 1, -height)
        contentArea.ZIndex = 4

        local tabView = {
            Tabs = {},
            ActiveTab = nil,
            Bar = tabsBar,
            ContentArea = contentArea,
        }

        function tabView:ApplyTheme()
            tabsBar.BackgroundColor3 = theme.TabBackground
            for _, tab in ipairs(self.Tabs) do
                if self.ActiveTab == tab then
                    tab.Button.BackgroundColor3 = theme.TabActive
                    tab.Button.TextColor3 = theme.Accent
                else
                    tab.Button.BackgroundColor3 = theme.TabBackground
                    tab.Button.TextColor3 = theme.TextMain
                end
            end
        end

    function tabView:AddTab(name)
        local btn = Instance.new("TextButton")
        btn.Parent = tabsBar
        btn.BackgroundColor3 = theme.TabBackground
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(0, 120, 1, 0)
            btn.Font = Enum.Font.GothamBold
            btn.Text = name
            btn.TextSize = 12
            btn.TextColor3 = theme.TextMain
            btn.AutoButtonColor = false
            btn.ZIndex = 6
            roundify(btn, UDim.new(0, 8))

            local page = Instance.new("Frame")
            page.Parent = contentArea
            page.BackgroundTransparency = 1
            page.BorderSizePixel = 0
            page.Size = UDim2.new(1, 0, 1, 0)
            page.Visible = false
            page.ZIndex = 4

            local tab = {
                Name = name,
                Button = btn,
                Page = page,
            }
            table.insert(self.Tabs, tab)

            local function setActive()
                if self.ActiveTab == tab then return end
                if self.ActiveTab then
                    self.ActiveTab.Page.Visible = false
                end
                self.ActiveTab = tab
                tab.Page.Visible = true
                self:ApplyTheme()
            end

            btn.MouseButton1Click:Connect(setActive)

            if not self.ActiveTab then
                setActive()
            end

            return tab
        end

        table.insert(window.Controls.Tabs, tabView)
        window:ApplyTheme()

        return tabView
    end

    -----------------------------------------------------------------
    -- NOTIFICATIONS (Toasts)
    -----------------------------------------------------------------
    -- type: "info", "success", "error"
    function window:Notify(opts)
        opts = opts or {}
        local message  = opts.Text or "Notification"
        local ntype    = opts.Type or "info"
        local duration = opts.Duration or 3

        local bgColor = theme.ToastInfo
        if ntype == "success" then
            bgColor = theme.ToastSuccess
        elseif ntype == "error" then
            bgColor = theme.ToastError
        end

        local toast = Instance.new("Frame")
        toast.Parent = screenGui
        toast.BackgroundColor3 = bgColor
        toast.BorderSizePixel = 0
        toast.AutomaticSize = Enum.AutomaticSize.XY
        toast.AnchorPoint = Vector2.new(0.5, 1)
        toast.ZIndex = 90

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = toast

        local padding = Instance.new("UIPadding")
        padding.Parent = toast
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 5)

        local lbl = Instance.new("TextLabel")
        lbl.Parent = toast
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.Text = message
        lbl.TextColor3 = theme.TextMain
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.AutomaticSize = Enum.AutomaticSize.XY
        lbl.ZIndex = 91

        -- nach oben stacken, unten mittig
        local offsetY = 0
        for _, t in ipairs(self.__toasts) do
            offsetY = offsetY + t.AbsoluteSize.Y + 6
        end
        toast.Position = UDim2.new(0.5, 0, 1, -10 - offsetY)

        table.insert(self.__toasts, toast)

        -- Fade-out + Remove
        task.spawn(function()
            task.wait(duration)
            local tween = TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1})
            for _, child in ipairs(toast:GetChildren()) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                end
            end
            tween:Play()
            tween.Completed:Wait()
            toast:Destroy()
        end)
    end

    -----------------------------------------------------------------
    -- CONFIRM DIALOG
    -----------------------------------------------------------------
    function window:Confirm(opts)
        opts = opts or {}
        local title    = opts.Title or "Bist du sicher?"
        local text     = opts.Text or ""
        local okText   = opts.ConfirmText or "Ja"
        local cancelText = opts.CancelText or "Abbrechen"
        local onConfirm = opts.OnConfirm
        local onCancel  = opts.OnCancel

        local overlay = Instance.new("Frame")
        overlay.Parent = mainFrame
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 0.4
        overlay.BorderSizePixel = 0
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.ZIndex = 80

        local dialog = Instance.new("Frame")
        dialog.Parent = overlay
        dialog.BackgroundColor3 = theme.MainBackground
        dialog.BorderSizePixel = 0
        dialog.Size = UDim2.new(0, 320, 0, 150)
        dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
        dialog.AnchorPoint = Vector2.new(0.5, 0.5)
        dialog.ZIndex = 81

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = dialog

        local titleLbl = self:CreateLabel({
            Parent = dialog,
            Position = UDim2.new(0, 12, 0, 10),
            Size = UDim2.new(1, -24, 0, 20),
            Text = title,
            TextSize = 14,
        })
        titleLbl.ZIndex = 82

        local textLbl = self:CreateLabel({
            Parent = dialog,
            Position = UDim2.new(0, 12, 0, 35),
            Size = UDim2.new(1, -24, 0, 50),
            Text = text,
            TextSize = 12,
            TextWrapped = true,
            Muted = true,
        })
        textLbl.ZIndex = 82

        local okBtn = self:CreateButton({
            Parent = dialog,
            Position = UDim2.new(0, 12, 1, -40),
            Size = UDim2.new(0.5, -18, 0, 30),
            Text = okText,
            Primary = true,
        })
        okBtn.ZIndex = 82

        local cancelBtn = self:CreateButton({
            Parent = dialog,
            Position = UDim2.new(0.5, 6, 1, -40),
            Size = UDim2.new(0.5, -18, 0, 30),
            Text = cancelText,
            BackgroundColor3 = theme.ButtonDanger,
            Primary = false,
        })
        cancelBtn.ZIndex = 82

        local closed = false
        local function close()
            if closed then return end
            closed = true
            overlay:Destroy()
        end

        okBtn.MouseButton1Click:Connect(function()
            close()
            if onConfirm then
                onConfirm()
            end
        end)

        cancelBtn.MouseButton1Click:Connect(function()
            close()
            if onCancel then
                onCancel()
            end
        end)
    end

    -----------------------------------------------------------------
    -- PUBLIC WINDOW FIELDS
    -----------------------------------------------------------------
    window.MainFrame      = mainFrame
    window.TitleBar       = titleBar
    window.TitleLabel     = titleLabel
    window.Content        = content
    window.CloseButton    = closeBtn
    window.MinimizeButton = minBtn
    window.SettingsButton = settingsBtn
    window.ResizeHandle   = resizeHandle
    window.SettingsPanel  = settingsPanel
    window.SetMinimized   = setMinimized

    function window:Destroy()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end

    window:ApplyTheme()

    -- Title glow animation
    task.spawn(function()
        while mainFrame.Parent do
            TweenService:Create(titleLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.1}):Play()
            task.wait(1.2)
            TweenService:Create(titleLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.3}):Play()
            task.wait(1.2)
        end
    end)

    return window
end

return GeckoUI
