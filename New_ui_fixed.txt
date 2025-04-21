local Gghiza07UI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local VERSION = "V4.12 Enhanced"
local LOCKED = false
local DEBUG_MODE = false

local function debugPrint(...)
    if DEBUG_MODE then
        print("[Gghiza07UI DEBUG]", ...)
    end
end

function Gghiza07UI:SetDebug(enabled)
    DEBUG_MODE = enabled
end

function Gghiza07UI:Lock()
    LOCKED = true
end

function Gghiza07UI:Unlock()
    LOCKED = false
end

function Gghiza07UI:CreateWindow(config)
    if LOCKED then
        warn("UI is locked. Call Gghiza07UI:Unlock() to enable UI creation.")
        return
    end
    
    if not config or type(config) ~= "table" then
        warn("Invalid config for CreateWindow. Expected a table.")
        return
    end

    local window = {}
    debugPrint("Creating window:", config.Name, "Version:", VERSION)

    local SETTINGS_FOLDER = "Gghiza07UI/" .. (config.Name or "DefaultUI")
    local SETTINGS_FILE = SETTINGS_FOLDER .. "/settings.json"
    local BACKGROUND_FILE = SETTINGS_FOLDER .. "/background.txt"
    local VIDEO_FILE = SETTINGS_FOLDER .. "/video.txt"
    local THEME_FILE = SETTINGS_FOLDER .. "/theme.json"
    local ELEMENTS_FILE = SETTINGS_FOLDER .. "/elements.json"

    local elementStates = {
        Toggles = {},
        Inputs = {}
    }

    local defaultTheme = {
        BackgroundColor = {R = 30, G = 30, B = 30},
        AccentColor = {R = 0, G = 123, B = 255},
        TextColor = {R = 255, G = 255, B = 255},
        CornerRadius = 10,
        Transparency = 0.2
    }

    local function color3ToTable(color)
        return {
            R = math.floor(color.R * 255 + 0.5),
            G = math.floor(color.G * 255 + 0.5),
            B = math.floor(color.B * 255 + 0.5)
        }
    end

    local function tableToColor3(tbl)
        if tbl and tbl.R and tbl.G and tbl.B then
            return Color3.fromRGB(tbl.R, tbl.G, tbl.B)
        end
        return nil
    end

    local function ensureFolderExists()
        local success, err = pcall(function()
            if not isfolder("Gghiza07UI") then
                makefolder("Gghiza07UI")
            end
            if not isfolder(SETTINGS_FOLDER) then
                makefolder(SETTINGS_FOLDER)
            end
        end)
        if not success then
            debugPrint("Failed to create folders:", err)
        end
    end

    local function saveData(file, data)
        ensureFolderExists()
        local success, err = pcall(function()
            writefile(file, HttpService:JSONEncode(data))
        end)
        if not success then
            debugPrint("Failed to save data to", file, "Error:", err)
            warn("Failed to save settings. Check file permissions.")
        end
        return success
    end

    local function loadData(file, default)
        ensureFolderExists()
        if isfile(file) then
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(file))
            end)
            if success then
                debugPrint("Successfully loaded data from", file)
                return data
            else
                debugPrint("Failed to load data from", file, "Error:", data)
                return default
            end
        end
        debugPrint(file, "does not exist, using default")
        return default
    end

    elementStates = loadData(ELEMENTS_FILE, {Toggles = {}, Inputs = {}})
    if not isfile(ELEMENTS_FILE) then
        debugPrint("No elements file found, resetting elementStates")
        elementStates = {Toggles = {}, Inputs = {}}
    end

    local loadedTheme = loadData(THEME_FILE, defaultTheme)
    local theme = {}
    
    if type(loadedTheme) == "table" then
        theme.BackgroundColor = tableToColor3(loadedTheme.BackgroundColor) or tableToColor3(defaultTheme.BackgroundColor)
        theme.AccentColor = tableToColor3(loadedTheme.AccentColor) or tableToColor3(defaultTheme.AccentColor)
        theme.TextColor = tableToColor3(loadedTheme.TextColor) or tableToColor3(defaultTheme.TextColor)
        theme.CornerRadius = loadedTheme.CornerRadius or defaultTheme.CornerRadius
        theme.Transparency = loadedTheme.Transparency or defaultTheme.Transparency
    else
        debugPrint("Loaded theme is not a table, using default theme")
        theme.BackgroundColor = tableToColor3(defaultTheme.BackgroundColor)
        theme.AccentColor = tableToColor3(defaultTheme.AccentColor)
        theme.TextColor = tableToColor3(defaultTheme.TextColor)
        theme.CornerRadius = defaultTheme.CornerRadius
        theme.Transparency = defaultTheme.Transparency
    end

    if not theme.BackgroundColor then
        debugPrint("theme.BackgroundColor is still nil after loading, using default")
        theme.BackgroundColor = Color3.fromRGB(30, 30, 30)
    end

    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then
        warn("PlayerGui not found")
        return
    end

    local function clearGui(gui)
        if gui then
            for _, connection in ipairs(gui:GetConnections()) do
                connection:Disconnect()
            end
            gui:Destroy()
        end
    end
    clearGui(playerGui:FindFirstChild(config.Name or "Gghiza07UI"))
    clearGui(playerGui:FindFirstChild("ToggleGui"))

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "Gghiza07UI"
    screenGui.Parent = playerGui
    screenGui.Enabled = true
    screenGui.DisplayOrder = 1000
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    debugPrint("ScreenGui created with Name:", screenGui.Name, "Parent:", screenGui.Parent)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = theme.BackgroundColor
    mainFrame.BackgroundTransparency = theme.Transparency
    mainFrame.ZIndex = 1
    mainFrame.Parent = screenGui
    debugPrint("MainFrame created with Parent:", mainFrame.Parent)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, theme.CornerRadius)
    corner.Parent = mainFrame

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ImageLabel"
    imageLabel.Size = UDim2.new(1, 0, 1, 0)
    imageLabel.Position = UDim2.new(0, 0, 0, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.ZIndex = 2
    imageLabel.ScaleType = Enum.ScaleType.Crop
    imageLabel.ImageTransparency = 0
    imageLabel.Parent = mainFrame
    debugPrint("ImageLabel created with Parent:", imageLabel.Parent)

    imageLabel:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
        debugPrint("ImageLabel ImageTransparency changed to:", imageLabel.ImageTransparency)
    end)

    local videoFrame = Instance.new("VideoFrame")
    videoFrame.Name = "BackgroundVideo"
    videoFrame.Size = UDim2.new(1, 0, 1, 0)
    videoFrame.Position = UDim2.new(0, 0, 0, 0)
    videoFrame.BackgroundTransparency = 1
    videoFrame.ZIndex = 3
    videoFrame.Visible = false
    videoFrame.Parent = mainFrame
    debugPrint("BackgroundVideo created with Parent:", videoFrame.Parent)

    local dragging, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 200, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.Name or "Gghiza07UI"
    titleLabel.TextColor3 = theme.TextColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextScaled = true
    titleLabel.ZIndex = 11
    titleLabel.Parent = mainFrame

    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, -20, 0, 40)
    tabButtons.Position = UDim2.new(0, 10, 0, 50)
    tabButtons.BackgroundTransparency = 1
    tabButtons.ZIndex = 10
    tabButtons.Parent = mainFrame

    local tabContents = Instance.new("Frame")
    tabContents.Name = "TabContents"
    tabContents.Size = UDim2.new(1, -20, 1, -110)
    tabContents.Position = UDim2.new(0, 10, 0, 110)
    tabContents.BackgroundTransparency = 1
    tabContents.ZIndex = 10
    tabContents.Active = true
    tabContents.Parent = mainFrame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0, 10, 1, -60)
    toggleButton.BackgroundColor3 = theme.AccentColor
    toggleButton.TextColor3 = theme.TextColor
    toggleButton.Text = "ON"
    toggleButton.TextScaled = true
    toggleButton.ZIndex = 1001
    toggleButton.Active = true
    toggleButton.AutoButtonColor = true
    toggleButton.Parent = screenGui

    local cornerToggle = Instance.new("UICorner")
    cornerToggle.CornerRadius = UDim.new(0, 15)
    cornerToggle.Parent = toggleButton

    local function toggleUI(state)
        if state ~= nil then
            mainFrame.Visible = state
        else
            mainFrame.Visible = not mainFrame.Visible
        end
        
        toggleButton.Text = mainFrame.Visible and "ON" or "OFF"
        toggleButton.BackgroundColor3 = mainFrame.Visible and theme.AccentColor or Color3.fromRGB(100, 100, 100)
    end

    toggleButton.MouseButton1Click:Connect(toggleUI)

    local toggleDragging, toggleDragStart, toggleStartPos
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggleDragging = true
            toggleDragStart = input.Position
            toggleStartPos = toggleButton.Position
        end
    end)

    toggleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggleDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - toggleDragStart
            toggleButton.Position = UDim2.new(
                toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X,
                toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y
            )
        end
    end)

    function window:CreateTab(tabName)
        if not tabName or type(tabName) ~= "string" then
            warn("Invalid tab name. Expected a string.")
            return
        end

        local tab = {}
        local tabId = #tabButtons:GetChildren() + 1
        
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.Position = UDim2.new(0, (tabId-1)*110, 0, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabButton.Text = tabName
        tabButton.TextColor3 = theme.TextColor
        tabButton.ZIndex = 11
        tabButton.Active = true
        tabButton.AutoButtonColor = true
        tabButton.Parent = tabButtons

        local cornerTab = Instance.new("UICorner")
        cornerTab.CornerRadius = UDim.new(0, 5)
        cornerTab.Parent = tabButton

        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabName
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.ScrollBarThickness = 5
        tabContent.ZIndex = 10
        tabContent.Active = true
        tabContent.Parent = tabContents

        local uiListLayout = Instance.new("UIListLayout")
        uiListLayout.Padding = UDim.new(0, 5)
        uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        uiListLayout.Parent = tabContent

        local function updateCanvasSize()
            local contentHeight = uiListLayout.AbsoluteContentSize.Y
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
        end

        uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

        local function selectTab()
            for _, content in ipairs(tabContents:GetChildren()) do
                if content:IsA("ScrollingFrame") then
                    content.Visible = false
                end
            end
            tabContent.Visible = true
            
            for _, button in ipairs(tabButtons:GetChildren()) do
                if button:IsA("TextButton") then
                    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            tabButton.BackgroundColor3 = theme.AccentColor
        end

        tabButton.MouseButton1Click:Connect(selectTab)

        if tabId == 1 then selectTab() end

        function tab:AddButton(buttonConfig)
            if not buttonConfig or type(buttonConfig) ~= "table" then
                warn("Invalid button config. Expected a table.")
                return
            end

            local button = Instance.new("TextButton")
            button.Name = buttonConfig.Name or "Button"
            button.Size = UDim2.new(1, -20, 0, 40)
            button.BackgroundColor3 = theme.AccentColor
            button.Text = buttonConfig.Name or "Button"
            button.TextColor3 = theme.TextColor
            button.ZIndex = 11
            button.LayoutOrder = #tabContent:GetChildren()
            button.Active = true
            button.AutoButtonColor = true
            button.Parent = tabContent

            local cornerButton = Instance.new("UICorner")
            cornerButton.CornerRadius = UDim.new(0, 5)
            cornerButton.Parent = button

            button.MouseButton1Click:Connect(function()
                if buttonConfig.Callback then
                    local success, err = pcall(buttonConfig.Callback)
                    if not success then
                        debugPrint("Button callback error:", err)
                    end
                end
            end)

            updateCanvasSize()
            return button
        end

        function tab:AddToggle(toggleConfig)
            if not toggleConfig or type(toggleConfig) ~= "table" then
                warn("Invalid toggle config. Expected a table.")
                return
            end

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = toggleConfig.Name or "Toggle"
            toggleFrame.Size = UDim2.new(1, -20, 0, 40)
            toggleFrame.BackgroundTransparency = 1
            toggleFrame.LayoutOrder = #tabContent:GetChildren()
            toggleFrame.ZIndex = 11
            toggleFrame.Active = true
            toggleFrame.Parent = tabContent

            local toggleLabel = Instance.new("TextLabel")
            toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
            toggleLabel.BackgroundTransparency = 1
            toggleLabel.Text = toggleConfig.Name or "Toggle"
            toggleLabel.TextColor3 = theme.TextColor
            toggleLabel.TextScaled = true
            toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            toggleLabel.ZIndex = 11
            toggleLabel.Parent = toggleFrame

            local toggleState = toggleConfig.Default or false
            if elementStates.Toggles[toggleConfig.Name] ~= nil then
                toggleState = elementStates.Toggles[toggleConfig.Name]
                debugPrint("Loaded toggle state for", toggleConfig.Name, ":", toggleState)
            else
                debugPrint("No saved state for", toggleConfig.Name, ", using default:", toggleState)
            end

            local toggleButton = Instance.new("TextButton")
            toggleButton.Size = UDim2.new(0.2, 0, 0.6, 0)
            toggleButton.Position = UDim2.new(0.8, 0, 0.2, 0)
            toggleButton.BackgroundColor3 = toggleState and theme.AccentColor or Color3.fromRGB(100, 100, 100)
            toggleButton.Text = toggleState and "ON" or "OFF"
            toggleButton.TextColor3 = theme.TextColor
            toggleButton.TextScaled = true
            toggleButton.ZIndex = 11
            toggleButton.Active = true
            toggleButton.AutoButtonColor = true
            toggleButton.Parent = toggleFrame

            local cornerToggle = Instance.new("UICorner")
            cornerToggle.CornerRadius = UDim.new(0, 5)
            cornerToggle.Parent = toggleButton

            toggleButton.MouseButton1Click:Connect(function()
                toggleState = not toggleState
                toggleButton.Text = toggleState and "ON" or "OFF"
                toggleButton.BackgroundColor3 = toggleState and theme.AccentColor or Color3.fromRGB(100, 100, 100)
                elementStates.Toggles[toggleConfig.Name] = toggleState
                saveData(ELEMENTS_FILE, elementStates)
                if toggleConfig.Callback then
                    local success, err = pcall(function()
                        toggleConfig.Callback(toggleState)
                    end)
                    if not success then
                        debugPrint("Toggle callback error:", err)
                    end
                end
            end)

            updateCanvasSize()
            return toggleFrame
        end

        function tab:AddSlider(sliderConfig)
            if not sliderConfig or type(sliderConfig) ~= "table" then
                warn("Invalid slider config. Expected a table.")
                return
            end

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = sliderConfig.Name or "Slider"
            sliderFrame.Size = UDim2.new(1, -20, 0, 60)
            sliderFrame.BackgroundTransparency = 1
            sliderFrame.LayoutOrder = #tabContent:GetChildren()
            sliderFrame.ZIndex = 11
            sliderFrame.Active = true
            sliderFrame.Parent = tabContent

            local sliderLabel = Instance.new("TextLabel")
            sliderLabel.Size = UDim2.new(1, 0, 0.4, 0)
            sliderLabel.BackgroundTransparency = 1
            sliderLabel.Text = sliderConfig.Name or "Slider"
            sliderLabel.TextColor3 = theme.TextColor
            sliderLabel.TextScaled = true
            sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            sliderLabel.ZIndex = 11
            sliderLabel.Parent = sliderFrame

            local sliderBar = Instance.new("Frame")
            sliderBar.Size = UDim2.new(1, -10, 0.2, 0)
            sliderBar.Position = UDim2.new(0, 5, 0.6, 0)
            sliderBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            sliderBar.ZIndex = 11
            sliderBar.Active = true
            sliderBar.Parent = sliderFrame

            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
            sliderFill.BackgroundColor3 = theme.AccentColor
            sliderFill.ZIndex = 11
            sliderFill.Parent = sliderBar

            local cornerSlider = Instance.new("UICorner")
            cornerSlider.CornerRadius = UDim.new(0, 5)
            cornerSlider.Parent = sliderBar

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
            valueLabel.Position = UDim2.new(0.8, 0, 0.4, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(sliderConfig.Default or sliderConfig.Min)
            valueLabel.TextColor3 = theme.TextColor
            valueLabel.TextScaled = true
            valueLabel.ZIndex = 11
            valueLabel.Parent = sliderFrame

            local min, max = sliderConfig.Min or 0, sliderConfig.Max or 100
            local value = sliderConfig.Default or min

            local draggingSlider = false
            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                end
            end)

            sliderBar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local mouseX = input.Position.X
                    local barPos = sliderBar.AbsolutePosition.X
                    local barWidth = sliderBar.AbsoluteSize.X
                    if barWidth > 0 then
                        local newValue = math.clamp((mouseX - barPos) / barWidth, 0, 1)
                        value = min + (max - min) * newValue
                        sliderFill.Size = UDim2.new(newValue, 0, 1, 0)
                        valueLabel.Text = string.format("%.2f", value)
                        if sliderConfig.Callback then
                            local success, err = pcall(function()
                                sliderConfig.Callback(value)
                            end)
                            if not success then
                                debugPrint("Slider callback error:", err)
                            end
                        end
                    end
                end
            end)

            updateCanvasSize()
            return sliderFrame
        end

        function tab:AddDropdown(dropdownConfig)
            if not dropdownConfig or type(dropdownConfig) ~= "table" or not dropdownConfig.Options then
                warn("Invalid dropdown config. Expected a table with Options.")
                return
            end

            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Name = dropdownConfig.Name or "Dropdown"
            dropdownFrame.Size = UDim2.new(1, -20, 0, 40)
            dropdownFrame.BackgroundTransparency = 1
            dropdownFrame.LayoutOrder = #tabContent:GetChildren()
            dropdownFrame.ZIndex = 11
            dropdownFrame.Active = true
            dropdownFrame.Parent = tabContent

            local dropdownButton = Instance.new("TextButton")
            dropdownButton.Size = UDim2.new(1, 0, 1, 0)
            dropdownButton.BackgroundColor3 = theme.AccentColor
            dropdownButton.Text = dropdownConfig.Name or "Select Option"
            dropdownButton.TextColor3 = theme.TextColor
            dropdownButton.TextScaled = true
            dropdownButton.ZIndex = 11
            dropdownButton.Active = true
            dropdownButton.AutoButtonColor = true
            dropdownButton.Parent = dropdownFrame

            local cornerDropdown = Instance.new("UICorner")
            cornerDropdown.CornerRadius = UDim.new(0, 5)
            cornerDropdown.Parent = dropdownButton

            local dropdownList = Instance.new("Frame")
            dropdownList.Size = UDim2.new(1, 0, 0, 0)
            dropdownList.Position = UDim2.new(0, 0, 1, 0)
            dropdownList.BackgroundColor3 = theme.BackgroundColor
            dropdownList.Visible = false
            dropdownList.ZIndex = 12
            dropdownList.Active = true
            dropdownList.Parent = dropdownFrame

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = dropdownList

            local function updateListHeight()
                dropdownList.Size = UDim2.new(1, 0, 0, #dropdownConfig.Options * 30)
            end

            for i, option in ipairs(dropdownConfig.Options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Size = UDim2.new(1, 0, 0, 30)
                optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                optionButton.Text = tostring(option)
                optionButton.TextColor3 = theme.TextColor
                optionButton.TextScaled = true
                optionButton.ZIndex = 13
                optionButton.LayoutOrder = i
                optionButton.Active = true
                optionButton.AutoButtonColor = true
                optionButton.Parent = dropdownList

                optionButton.MouseButton1Click:Connect(function()
                    dropdownButton.Text = tostring(option)
                    dropdownList.Visible = false
                    if dropdownConfig.Callback then
                        local success, err = pcall(function()
                            dropdownConfig.Callback(option)
                        end)
                        if not success then
                            debugPrint("Dropdown callback error:", err)
                        end
                    end
                end)
            end

            updateListHeight()

            dropdownButton.MouseButton1Click:Connect(function()
                dropdownList.Visible = not dropdownList.Visible
            end)

            updateCanvasSize()
            return dropdownFrame
        end

        function tab:AddInput(inputConfig)
            if not inputConfig or type(inputConfig) ~= "table" then
                warn("Invalid input config. Expected a table.")
                return
            end

            local inputFrame = Instance.new("Frame")
            inputFrame.Name = inputConfig.Name or "Input"
            inputFrame.Size = UDim2.new(1, -20, 0, 40)
            inputFrame.BackgroundTransparency = 1
            inputFrame.LayoutOrder = #tabContent:GetChildren()
            inputFrame.ZIndex = 11
            inputFrame.Active = true
            inputFrame.Parent = tabContent

            local inputLabel = Instance.new("TextLabel")
            inputLabel.Size = UDim2.new(0.4, 0, 1, 0)
            inputLabel.BackgroundTransparency = 1
            inputLabel.Text = inputConfig.Name or "Input"
            inputLabel.TextColor3 = theme.TextColor
            inputLabel.TextScaled = true
            inputLabel.TextXAlignment = Enum.TextXAlignment.Left
            inputLabel.ZIndex = 11
            inputLabel.Parent = inputFrame

            local defaultText = inputConfig.Default or ""
            if elementStates.Inputs[inputConfig.Name] ~= nil then
                defaultText = elementStates.Inputs[inputConfig.Name]
            end

            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0.6, 0, 0.8, 0)
            textBox.Position = UDim2.new(0.4, 0, 0.1, 0)
            textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            textBox.Text = defaultText
            textBox.TextColor3 = theme.TextColor
            textBox.TextScaled = true
            textBox.TextEditable = true
            textBox.ZIndex = 11
            textBox.Parent = inputFrame

            local cornerInput = Instance.new("UICorner")
            cornerInput.CornerRadius = UDim.new(0, 5)
            cornerInput.Parent = textBox

            textBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    elementStates.Inputs[inputConfig.Name] = textBox.Text
                    saveData(ELEMENTS_FILE, elementStates)
                    if inputConfig.Callback then
                        local success, err = pcall(function()
                            inputConfig.Callback(textBox.Text)
                        end)
                        if not success then
                            debugPrint("Input callback error:", err)
                        end
                    end
                end
            end)

            updateCanvasSize()
            return inputFrame
        end

        function tab:AddBackgroundOptions()
            local bgTab = self
            
            bgTab:AddInput({
                Name = "Background Color (R,G,B)",
                Default = "30,30,30",
                Callback = function(value)
                    local r, g, b = value:match("(%d+),%s*(%d+),%s*(%d+)")
                    if r and g and b then
                        local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                        debugPrint("Setting BackgroundColor3 to:", r, g, b)
                        mainFrame.BackgroundColor3 = color
                        theme.BackgroundColor = color
                        local themeToSave = {
                            BackgroundColor = color3ToTable(theme.BackgroundColor),
                            AccentColor = color3ToTable(theme.AccentColor),
                            TextColor = color3ToTable(theme.TextColor),
                            CornerRadius = theme.CornerRadius,
                            Transparency = theme.Transparency
                        }
                        saveData(THEME_FILE, themeToSave)
                        debugPrint("MainFrame BackgroundColor3:", mainFrame.BackgroundColor3.R * 255, mainFrame.BackgroundColor3.G * 255, mainFrame.BackgroundColor3.B * 255)
                    else
                        warn("Invalid RGB format. Use: R,G,B (e.g., 30,30,30)")
                    end
                end
            })
            
            bgTab:AddInput({
                Name = "Image ID (Number only, e.g., 5191098772)",
                Callback = function(value)
                    if value:match("^%d+$") then
                        local thumbId = string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", value)
                        debugPrint("Using rbxthumb:// format:", thumbId)

                        local retries = 3
                        local success = false
                        for i = 1, retries do
                            local attempt, err = pcall(function()
                                ContentProvider:PreloadAsync({thumbId})
                            end)
                            if attempt then
                                success = true
                                break
                            else
                                debugPrint("Retry", i, "failed to preload image:", err)
                                task.wait(1)
                            end
                        end

                        if success then
                            debugPrint("Image preloaded successfully after retries")
                            imageLabel.Image = thumbId
                            videoFrame.Visible = false
                            imageLabel.Visible = true
                            imageLabel.ZIndex = 5
                            imageLabel.ImageTransparency = 0
                            mainFrame.BackgroundTransparency = 1

                            local timeout = 20
                            local elapsed = 0
                            local connection
                            connection = RunService.Heartbeat:Connect(function(deltaTime)
                                elapsed = elapsed + deltaTime
                                if elapsed >= timeout then
                                    connection:Disconnect()
                                    debugPrint("Image load timeout")
                                    if imageLabel.Image == thumbId and imageLabel.ImageTransparency == 1 then
                                        debugPrint("Image still set but not displayed, assuming failure")
                                        imageLabel.Image = ""
                                        imageLabel.Visible = false
                                        mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                                        mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                                        warn("Image failed to load after timeout. Check if the Image ID is valid or accessible.")
                                    end
                                    return
                                end

                                local loaded = pcall(function()
                                    return ContentProvider:PreloadAsync({thumbId})
                                end)
                                if imageLabel.Image == thumbId and (imageLabel.ImageTransparency == 0 or loaded) then
                                    debugPrint("Image confirmed displayed")
                                    connection:Disconnect()
                                    mainFrame.BackgroundTransparency = 1
                                    saveData(BACKGROUND_FILE, thumbId)
                                end
                            end)
                        else
                            warn("Failed to preload image after", retries, "attempts, trying direct load")
                            imageLabel.Image = thumbId
                            videoFrame.Visible = false
                            imageLabel.Visible = true
                            imageLabel.ZIndex = 5
                            imageLabel.ImageTransparency = 0
                            mainFrame.BackgroundTransparency = 1

                            local timeout = 20
                            local elapsed = 0
                            local connection
                            connection = RunService.Heartbeat:Connect(function(deltaTime)
                                elapsed = elapsed + deltaTime
                                if elapsed >= timeout then
                                    connection:Disconnect()
                                    if imageLabel.Image == thumbId and imageLabel.ImageTransparency == 1 then
                                        debugPrint("Image failed to load (transparency still 1)")
                                        imageLabel.Image = ""
                                        imageLabel.Visible = false
                                        mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                                        mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                                        warn("Image failed to load after timeout. Check if the Image ID is valid or accessible.")
                                    end
                                    return
                                end

                                local loaded = pcall(function()
                                    return ContentProvider:PreloadAsync({thumbId})
                                end)
                                if imageLabel.Image == thumbId and (imageLabel.ImageTransparency == 0 or loaded) then
                                    debugPrint("Image confirmed displayed")
                                    connection:Disconnect()
                                    mainFrame.BackgroundTransparency = 1
                                    saveData(BACKGROUND_FILE, thumbId)
                                end
                            end)
                        end
                    else
                        warn("Invalid Image ID format. Use a number only (e.g., 5191098772)")
                        imageLabel.Image = ""
                        imageLabel.Visible = false
                        mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                        mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    end
                end
            })
            
            bgTab:AddInput({
                Name = "Video ID (rbxassetid:// or number)",
                Callback = function(value)
                    if value:match("^rbxassetid://%d+$") or value:match("^%d+$") then
                        if not value:match("^rbxassetid://") then
                            value = "rbxassetid://"..value
                        end
                        debugPrint("Attempting to load video:", value)
                        local success, err = pcall(function()
                            videoFrame.Video = value
                            videoFrame.Visible = true
                            imageLabel.Visible = false
                            videoFrame.ZIndex = 5
                            mainFrame.BackgroundTransparency = 1
                            videoFrame:Play()
                        end)
                        if success then
                            debugPrint("Video loaded successfully")
                            local timeout = 15
                            local elapsed = 0
                            local connection
                            connection = RunService.Heartbeat:Connect(function(deltaTime)
                                elapsed = elapsed + deltaTime
                                if elapsed >= timeout then
                                    connection:Disconnect()
                                    debugPrint("Video load timeout")
                                    if videoFrame.Video == value and not videoFrame.IsPlaying then
                                        debugPrint("Video still set but not playing, assuming failure")
                                        videoFrame.Video = ""
                                        videoFrame.Visible = false
                                        imageLabel.Visible = true
                                        mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                                        mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                                        warn("Video failed to load after timeout. Check if the Video ID is valid or accessible.")
                                    end
                                    return
                                end

                                if videoFrame.Video == value and videoFrame.IsPlaying then
                                    debugPrint("Video confirmed playing")
                                    connection:Disconnect()
                                    mainFrame.BackgroundTransparency = 1
                                    saveData(VIDEO_FILE, value)
                                end
                            end)
                        else
                            warn("Failed to load video:", err)
                            videoFrame.Video = ""
                            videoFrame.Visible = false
                            imageLabel.Visible = true
                            mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        end
                    else
                        warn("Invalid Video ID format. Use rbxassetid:// followed by numbers or just the numbers (e.g., rbxassetid://1234567890 or 1234567890)")
                        videoFrame.Video = ""
                        videoFrame.Visible = false
                        imageLabel.Visible = true
                        mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                        mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    end
                end
            })
            
            bgTab:AddSlider({
                Name = "Transparency",
                Min = 0,
                Max = 1,
                Default = theme.Transparency,
                Callback = function(value)
                    debugPrint("Setting Transparency to:", value)
                    theme.Transparency = value
                    local isImageDisplayed = imageLabel.Visible and imageLabel.Image ~= "" and imageLabel.ImageTransparency == 0
                    local isVideoPlaying = videoFrame.Visible and videoFrame.Video ~= "" and videoFrame.IsPlaying
                    if not isImageDisplayed and not isVideoPlaying then
                        mainFrame.BackgroundTransparency = math.min(value, 0.8)
                        debugPrint("No image or video displayed, MainFrame Transparency updated to:", mainFrame.BackgroundTransparency)
                    else
                        debugPrint("Image or video is displayed, keeping MainFrame Transparency at 1")
                    end
                    local themeToSave = {
                        BackgroundColor = color3ToTable(theme.BackgroundColor),
                        AccentColor = color3ToTable(theme.AccentColor),
                        TextColor = color3ToTable(theme.TextColor),
                        CornerRadius = theme.CornerRadius,
                        Transparency = theme.Transparency
                    }
                    saveData(THEME_FILE, themeToSave)
                    debugPrint("MainFrame Transparency:", mainFrame.BackgroundTransparency)
                end
            })

            bgTab:AddButton({
                Name = "Pause/Play Video",
                Callback = function()
                    if videoFrame.IsLoaded then
                        if videoFrame.IsPlaying then
                            videoFrame:Pause()
                            debugPrint("Video paused")
                        else
                            videoFrame:Play()
                            debugPrint("Video playing")
                        end
                    else
                        debugPrint("No video loaded")
                    end
                end
            })

            bgTab:AddButton({
                Name = "Reset Settings",
                Callback = function()
                    local success, err = pcall(function()
                        if isfolder(SETTINGS_FOLDER) then
                            delfolder(SETTINGS_FOLDER)
                            debugPrint("Deleted settings folder:", SETTINGS_FOLDER)
                        end
                    end)
                    if success then
                        mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        mainFrame.BackgroundTransparency = 0.2
                        imageLabel.Image = ""
                        imageLabel.Visible = true
                        videoFrame.Video = ""
                        videoFrame.Visible = false
                        elementStates.Toggles = {}
                        elementStates.Inputs = {}
                        saveData(ELEMENTS_FILE, elementStates)
                        debugPrint("Settings reset successfully")
                    else
                        warn("Failed to reset settings:", err)
                    end
                end
            })

            updateCanvasSize()
        end

        return tab
    end

    local function loadSettings()
        imageLabel.Visible = true
        videoFrame.Visible = false

        local bgImage = loadData(BACKGROUND_FILE, "")
        if bgImage and bgImage ~= "" then
            debugPrint("Loading saved background image:", bgImage)
            if bgImage:match("^rbxthumb://type=Asset&id=%d+&w=%d+&h=%d+$") then
                debugPrint("Saved image is in rbxthumb:// format, loading directly:", bgImage)
            else
                debugPrint("Saved background image is not in rbxthumb:// format, skipping")
                return
            end

            local retries = 3
            local success = false
            for i = 1, retries do
                local attempt, err = pcall(function()
                    ContentProvider:PreloadAsync({bgImage})
                end)
                if attempt then
                    success = true
                    break
                else
                    debugPrint("Retry", i, "failed to preload saved image:", err)
                    task.wait(1)
                end
            end

            if success then
                debugPrint("Saved image preloaded successfully")
                imageLabel.Image = bgImage
                imageLabel.Visible = true
                imageLabel.ZIndex = 5
                mainFrame.BackgroundTransparency = 1
                videoFrame.Visible = false

                local timeout = 15
                local elapsed = 0
                local connection
                connection = RunService.Heartbeat:Connect(function(deltaTime)
                    elapsed = elapsed + deltaTime
                    if elapsed >= timeout then
                        connection:Disconnect()
                        debugPrint("Saved image load timeout")
                        if imageLabel.Image == bgImage and imageLabel.ImageTransparency == 1 then
                            debugPrint("Saved image still set but not displayed, assuming failure")
                            imageLabel.Image = ""
                            imageLabel.Visible = false
                            mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        end
                        return
                    end

                    if imageLabel.Image == bgImage and imageLabel.ImageTransparency == 0 then
                        debugPrint("Saved image confirmed displayed")
                        connection:Disconnect()
                        mainFrame.BackgroundTransparency = 1
                    end
                end)
            else
                debugPrint("Failed to preload saved image after retries, trying direct load")
                imageLabel.Image = bgImage
                imageLabel.Visible = true
                imageLabel.ZIndex = 5
                mainFrame.BackgroundTransparency = 1
                videoFrame.Visible = false

                local timeout = 15
                local elapsed = 0
                local connection
                connection = RunService.Heartbeat:Connect(function(deltaTime)
                    elapsed = elapsed + deltaTime
                    if elapsed >= timeout then
                        connection:Disconnect()
                        if imageLabel.Image == bgImage and imageLabel.ImageTransparency == 1 then
                            debugPrint("Saved image failed to load (transparency still 1)")
                            imageLabel.Image = ""
                            imageLabel.Visible = false
                            mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        end
                        return
                    end
                    if imageLabel.Image == bgImage and imageLabel.ImageTransparency == 0 then
                        debugPrint("Saved image confirmed displayed")
                        connection:Disconnect()
                        mainFrame.BackgroundTransparency = 1
                    end
                end)
            end
        end

        local bgVideo = loadData(VIDEO_FILE, "")
        if bgVideo and bgVideo ~= "" then
            debugPrint("Loading saved background video:", bgVideo)
            local success, err = pcall(function()
                videoFrame.Video = bgVideo
                videoFrame.Visible = true
                imageLabel.Visible = false
                videoFrame.ZIndex = 5
                mainFrame.BackgroundTransparency = 1
                videoFrame:Play()
            end)
            if success then
                local timeout = 15
                local elapsed = 0
                local connection
                connection = RunService.Heartbeat:Connect(function(deltaTime)
                    elapsed = elapsed + deltaTime
                    if elapsed >= timeout then
                        connection:Disconnect()
                        debugPrint("Saved video load timeout")
                        if videoFrame.Video == bgVideo and not videoFrame.IsPlaying then
                            debugPrint("Saved video still set but not playing, assuming failure")
                            videoFrame.Video = ""
                            videoFrame.Visible = false
                            imageLabel.Visible = true
                            mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        end
                        return
                    end

                    if videoFrame.Video == bgVideo and videoFrame.IsPlaying then
                        debugPrint("Saved video confirmed playing")
                        connection:Disconnect()
                        mainFrame.BackgroundTransparency = 1
                    end
                end)
            else
                debugPrint("Failed to load saved background video:", err)
                videoFrame.Video = ""
                videoFrame.Visible = false
                imageLabel.Visible = true
                mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end

        if not imageLabel.Visible and not videoFrame.Visible then
            mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            debugPrint("No saved image or video, MainFrame Transparency:", mainFrame.BackgroundTransparency)
            debugPrint("MainFrame BackgroundColor3 set to fallback:", mainFrame.BackgroundColor3)
        end
    end

    loadSettings()

    return window
end

return Gghiza07UI