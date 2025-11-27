-- GeckoUI.lua v2
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
    MainBackground   = Color3.fromRGB(15, 25, 20),
    TitleBackground  = Color3.fromRGB(10, 20, 15),
    Accent           = Color3.fromRGB(0, 255, 150),

    ButtonPrimary    = Color3.fromRGB(0, 200, 100),
    ButtonDanger     = Color3.fromRGB(180, 50, 50),
    ButtonWarn       = Color3.fromRGB(255, 189, 46),
    ButtonCopy       = Color3.fromRGB(0, 140, 70),
    SettingsBlue     = Color3.fromRGB(0, 122, 255),

    ScrollBackground = Color3.fromRGB(22, 32, 27),
    TextMain         = Color3.fromRGB(255, 255, 255),
    TextMuted        = Color3.fromRGB(150, 200, 150),

    ToggleOff        = Color3.fromRGB(60, 60, 60),
    ToggleOn         = Color3.fromRGB(0, 200, 100),

    SliderTrack      = Color3.fromRGB(40, 60, 50),
    SliderFill       = Color3.fromRGB(0, 200, 100),

    TabBackground    = Color3.fromRGB(18, 28, 23),
    TabActive        = Color3.fromRGB(25, 45, 35),

    ToastInfo        = Color3.fromRGB(40, 80, 120),
    ToastSuccess     = Color3.fromRGB(30, 110, 70),
    ToastError       = Color3.fromRGB(140, 40, 40),
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

    local fullSize = size

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.BackgroundColor3 = theme.TitleBackground
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Active = true

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

    -----------------------------------------------------------------
    -- Minimize / Close
    -----------------------------------------------------------------
    local isMinimized = false

    local function setMinimized(minimized)
        isMinimized = minimized
        if minimized then
            mainFrame:TweenSize(
                UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 35),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.25,
                true
            )
        else
            mainFrame:TweenSize(
                fullSize,
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.25,
                true
            )
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
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Parent = mainFrame
    settingsPanel.BackgroundColor3 = Color3.fromRGB(12, 20, 16)
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Position = UDim2.new(1, -230, 0, 40)
    settingsPanel.Size = UDim2.new(0, 220, 0, 260)
    settingsPanel.Visible = false
    settingsPanel.ZIndex = 40

    local spCorner = Instance.new("UICorner")
    spCorner.CornerRadius = UDim.new(0, 8)
    spCorner.Parent = settingsPanel

    local spStroke = Instance.new("UIStroke")
    spStroke.Parent = settingsPanel
    spStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    spStroke.Thickness = 1
    spStroke.Color = Color3.fromRGB(0, 150, 90)

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
    spSub.Text = "Farben: R,G,B (0-255)"
    spSub.TextColor3 = theme.TextMuted
    spSub.TextSize = 11
    spSub.TextXAlignment = Enum.TextXAlignment.Left
    spSub.ZIndex = 41

    local settingsRows = {}

    local function addColorRow(labelText, themeKey, order)
        local y = 40 + (order - 1) * 36

        local lbl = Instance.new("TextLabel")
        lbl.Parent = settingsPanel
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.Size = UDim2.new(0.5, -10, 0, 18)
        lbl.Font = Enum.Font.Gotham
        lbl.Text = labelText
        lbl.TextColor3 = theme.TextMain
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 41

        local box = Instance.new("TextBox")
        box.Parent = settingsPanel
        box.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
        box.BorderSizePixel = 0
        box.Position = UDim2.new(0.5, 0, 0, y)
        box.Size = UDim2.new(0.5, -10, 0, 18)
        box.Font = Enum.Font.Code
        box.Text = colorToString(theme[themeKey])
        box.TextColor3 = theme.TextMain
        box.TextSize = 11
        box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ZIndex = 41

        local row = {
            Key = themeKey,
            Input = box,
        }
        table.insert(settingsRows, row)
    end

    addColorRow("Main BG",       "MainBackground",   1)
    addColorRow("Title BG",      "TitleBackground",  2)
    addColorRow("Accent",        "Accent",           3)
    addColorRow("Buttons",       "ButtonPrimary",    4)
    addColorRow("Text Main",     "TextMain",         5)
    addColorRow("Scroll BG",     "ScrollBackground", 6)

    local applyBtn = Instance.new("TextButton")
    applyBtn.Parent = settingsPanel
    applyBtn.BackgroundColor3 = theme.ButtonPrimary
    applyBtn.BorderSizePixel = 0
    applyBtn.Position = UDim2.new(0, 10, 1, -40)
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
    resetBtn.Position = UDim2.new(0.5, 5, 1, -40)
    resetBtn.Size = UDim2.new(0.5, -15, 0, 28)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.Text = "⟲ Reset"
    resetBtn.TextColor3 = theme.TextMain
    resetBtn.TextSize = 12
    resetBtn.ZIndex = 41

    settingsBtn.MouseButton1Click:Connect(function()
        settingsPanel.Visible = not settingsPanel.Visible
    end)

    -----------------------------------------------------------------
    -- TOOLTIP SYSTEM (ein globales Tooltip-Label pro Window)
    -----------------------------------------------------------------
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Parent = screenGui
    tooltip.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    tooltip.BackgroundTransparency = 0.15
    tooltip.BorderSizePixel = 0
    tooltip.AutomaticSize = Enum.AutomaticSize.XY
    tooltip.Visible = false
    tooltip.Font = Enum.Font.Gotham
    tooltip.Text = ""
    tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
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

        closeBtn.BackgroundColor3    = t.ButtonDanger
        minBtn.BackgroundColor3      = t.ButtonWarn
        settingsBtn.BackgroundColor3 = t.SettingsBlue

        spTitle.TextColor3 = t.Accent
        spSub.TextColor3   = t.TextMuted

        for _, row in ipairs(settingsRows) do
            local key = row.Key
            if t[key] then
                row.Input.Text = colorToString(t[key])
            end
        end

        -- Buttons
        for _, btn in ipairs(self.Controls.Buttons) do
            if btn.__geckoPrimary then
                btn.BackgroundColor3 = t.ButtonPrimary
                btn.TextColor3 = t.TextMain
            end
        end

        -- Labels
        for _, lbl in ipairs(self.Controls.Labels) do
            if lbl.__geckoMuted then
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
            local state = tg.__state
            if state then
                tg.__bg.BackgroundColor3 = t.ToggleOn
            else
                tg.__bg.BackgroundColor3 = t.ToggleOff
            end
            tg.__knob.BackgroundColor3 = t.TextMain
        end

        -- Sliders
        for _, sl in ipairs(self.Controls.Sliders) do
            sl.__track.BackgroundColor3 = t.SliderTrack
            sl.__fill.BackgroundColor3  = t.SliderFill
            sl.__knob.BackgroundColor3  = t.TextMain
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
        for _, row in ipairs(settingsRows) do
            local col = parseColor(row.Input.Text)
            if col then
                theme[row.Key] = col
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

        lbl.__geckoMuted = props.Muted or false

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

        if props.CornerRadius then
            local c = Instance.new("UICorner")
            c.CornerRadius = props.CornerRadius
            c.Parent = btn
        end

        btn.__geckoPrimary = (props.Primary ~= false)

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

        table.insert(self.Controls.Scrolls, scroll)
        return scroll
    end

    -- Toggle
    function window:CreateToggle(props)
        props = props or {}
        local parent = props.Parent or content

        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.BackgroundTransparency = 1
        frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
        frame.Size = props.Size or UDim2.new(0, 120, 0, 24)
        frame.ZIndex = props.ZIndex or 1

        local label
        if props.Label then
            label = self:CreateLabel({
                Parent = frame,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                Text = props.Label,
                TextSize = 12,
            })
            label.ZIndex = frame.ZIndex
        end

        local bg = Instance.new("Frame")
        bg.Parent = frame
        bg.BackgroundColor3 = theme.ToggleOff
        bg.BorderSizePixel = 0
        bg.Position = UDim2.new(1, -36, 0.5, -10)
        bg.Size = UDim2.new(0, 32, 0, 20)
        bg.ZIndex = frame.ZIndex

        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(1, 0)
        bgCorner.Parent = bg

        local knob = Instance.new("Frame")
        knob.Parent = bg
        knob.BackgroundColor3 = theme.TextMain
        knob.BorderSizePixel = 0
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.ZIndex = frame.ZIndex + 1

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local state = props.Default == true
        local onChanged = props.OnChanged

        local function updateVisual()
            if state then
                bg.BackgroundColor3 = theme.ToggleOn
                knob.Position = UDim2.new(1, -18, 0, 2)
            else
                bg.BackgroundColor3 = theme.ToggleOff
                knob.Position = UDim2.new(0, 2, 0, 2)
            end
        end

        local function setValue(v)
            state = v and true or false
            updateVisual()
            if onChanged then
                onChanged(state)
            end
        end

        updateVisual()

        local function click()
            setValue(not state)
        end

        bg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                click()
            end
        end)

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                click()
            end
        end)

        local toggleObj = {
            Frame = frame,
            Background = bg,
            Knob = knob,
            Label = label,
            GetValue = function()
                return state
            end,
            SetValue = setValue,
            __bg = bg,
            __knob = knob,
            __state = state,
        }

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
        knob.BackgroundColor3 = theme.TextMain
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
        frame.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
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
            frame.BackgroundColor3       = Color3.fromRGB(20, 30, 25)
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
        frame.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
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
        listFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
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
                itemBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 30)
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
            frame.BackgroundColor3  = Color3.fromRGB(20, 30, 25)
            label.TextColor3        = theme.TextMain
            arrow.TextColor3        = theme.TextMain
            listFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
            for _, btn in ipairs(listFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(25, 35, 30)
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
            btn.Size = UDim2.new(0, 100, 1, 0)
            btn.Font = Enum.Font.GothamBold
            btn.Text = name
            btn.TextSize = 12
            btn.TextColor3 = theme.TextMain
            btn.AutoButtonColor = false
            btn.ZIndex = 6

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
        toast.Position = UDim2.new(1, -10, 0, 60)
        toast.AnchorPoint = Vector2.new(1, 0)
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
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.AutomaticSize = Enum.AutomaticSize.XY
        lbl.ZIndex = 91

        -- nach unten stacken
        local offsetY = 0
        for _, t in ipairs(self.__toasts) do
            offsetY = offsetY + t.AbsoluteSize.Y + 6
        end
        toast.Position = UDim2.new(1, -10, 0, 60 + offsetY)

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

    return window
end

return GeckoUI
