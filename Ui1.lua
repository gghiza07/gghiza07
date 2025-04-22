local Gghiza07UI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local VERSION = "V0.1"
local LOCKED = false
local DEBUG_MODE = false
local NOTIFICATIONS_ENABLED = false -- ปิดการแจ้งเตือนตามคำขอ

local function debugPrint(...)
    if DEBUG_MODE then
        print("[Gghiza07UI DEBUG]", ...)
    end
end

function Gghiza07UI:SetDebug(enabled)
    DEBUG_MODE = enabled
end

function Gghiza07UI:SetNotifications(enabled)
    NOTIFICATIONS_ENABLED = enabled
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

    -- ใช้ FileFolder จาก config หากกำหนดมา มิฉะนั้นใช้ชื่อโฟลเดอร์เริ่มต้น
    local FOLDER_NAME = config.FileFolder or "Gghiza07UI"
    local SETTINGS_FOLDER = FOLDER_NAME .. "/" .. (config.Name or "DefaultUI")
    local SETTINGS_FILE = SETTINGS_FOLDER .. "/settings.json"
    local BACKGROUND_FILE = SETTINGS_FOLDER .. "/background.txt"
    local VIDEO_FILE = SETTINGS_FOLDER .. "/video.txt"
    local THEME_FILE = SETTINGS_FOLDER .. "/theme.json"
    local ELEMENTS_FILE = SETTINGS_FOLDER .. "/elements.json"
    local SOUND_FILE = SETTINGS_FOLDER .. "/sound.json"
    local KEY_FILE = SETTINGS_FOLDER .. "/" .. (config.Keyconfig and config.Keyconfig.FileName or "key") .. ".txt"

    local elementStates = {
        Toggles = {},
        Inputs = {},
        Dropdowns = {}
    }

    local defaultTheme = {
        BackgroundColor = {R = 30, G = 30, B = 30},
        AccentColor = {R = 0, G = 123, B = 255},
        TextColor = {R = 255, G = 255, B = 255},
        CornerRadius = 10,
        Transparency = 0.2
    }

    local saveSetting = config.SaveSetting ~= false

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
        if not saveSetting then return end
        local success, err = pcall(function()
            if not isfolder(FOLDER_NAME) then
                makefolder(FOLDER_NAME)
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
        if not saveSetting then return end
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
        if not saveSetting then return default end
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

    local loadedElementStates = loadData(ELEMENTS_FILE, {Toggles = {}, Inputs = {}, Dropdowns = {}})
    if type(loadedElementStates) == "table" then
        elementStates.Toggles = loadedElementStates.Toggles or {}
        elementStates.Inputs = loadedElementStates.Inputs or {}
        elementStates.Dropdowns = loadedElementStates.Dropdowns or {}
    else
        debugPrint("Loaded element states is not a table, resetting to default")
        elementStates = {Toggles = {}, Inputs = {}, Dropdowns = {}}
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

    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyFrame"
    keyFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
    keyFrame.Position = UDim2.new(0.3, 0, 0.35, 0)
    keyFrame.BackgroundColor3 = theme.BackgroundColor
    keyFrame.BackgroundTransparency = theme.Transparency
    keyFrame.ZIndex = 1002
    keyFrame.Visible = config.Keyconfig and config.Keyconfig.Keyopen
    keyFrame.Parent = screenGui
    keyFrame.ClipsDescendants = true

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, theme.CornerRadius)
    keyCorner.Parent = keyFrame

    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -20, 0, 30)
    keyTitle.Position = UDim2.new(0, 10, 0, 10)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = "Enter Key"
    keyTitle.TextColor3 = theme.TextColor
    keyTitle.TextScaled = true
    keyTitle.TextXAlignment = Enum.TextXAlignment.Center
    keyTitle.ZIndex = 1003
    keyTitle.Parent = keyFrame

    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(0.8, 0, 0, 40)
    keyInput.Position = UDim2.new(0.1, 0, 0, 50)
    keyInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    keyInput.Text = ""
    keyInput.PlaceholderText = "Type key here..."
    keyInput.TextColor3 = theme.TextColor
    keyInput.TextScaled = true
    keyInput.TextEditable = true
    keyInput.ZIndex = 1003
    keyInput.Parent = keyFrame

    local keyInputCorner = Instance.new("UICorner")
    keyInputCorner.CornerRadius = UDim.new(0, 5)
    keyInputCorner.Parent = keyInput

    local verifyButton = Instance.new("TextButton")
    verifyButton.Size = UDim2.new(0.4, 0, 0, 40)
    verifyButton.Position = UDim2.new(0.1, 0, 0, 100)
    verifyButton.BackgroundColor3 = theme.AccentColor
    verifyButton.Text = "Verify"
    verifyButton.TextColor3 = theme.TextColor
    verifyButton.TextScaled = true
    verifyButton.ZIndex = 1003
    verifyButton.Parent = keyFrame

    local verifyCorner = Instance.new("UICorner")
    verifyCorner.CornerRadius = UDim.new(0, 5)
    verifyCorner.Parent = verifyButton

    local copyKeyLinkButton = Instance.new("TextButton")
    copyKeyLinkButton.Size = UDim2.new(0.4, 0, 0, 40)
    copyKeyLinkButton.Position = UDim2.new(0.5, 0, 0, 100)
    copyKeyLinkButton.BackgroundColor3 = theme.AccentColor
    copyKeyLinkButton.Text = "Copy Key Link"
    copyKeyLinkButton.TextColor3 = theme.TextColor
    copyKeyLinkButton.TextScaled = true
    copyKeyLinkButton.ZIndex = 1003
    copyKeyLinkButton.Parent = keyFrame

    local copyKeyLinkCorner = Instance.new("UICorner")
    copyKeyLinkCorner.CornerRadius = UDim.new(0, 5)
    copyKeyLinkCorner.Parent = copyKeyLinkButton

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = theme.BackgroundColor
    mainFrame.BackgroundTransparency = theme.Transparency
    mainFrame.ZIndex = 1
    mainFrame.Parent = screenGui
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = not (config.Keyconfig and config.Keyconfig.Keyopen)
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

    local buttonClickSound = Instance.new("Sound")
    buttonClickSound.Name = "ButtonClickSound"
    buttonClickSound.SoundId = ""
    buttonClickSound.Parent = screenGui
    buttonClickSound.Volume = 1

    local savedSound = loadData(SOUND_FILE, {SoundId = ""})
    if savedSound and savedSound.SoundId and savedSound.SoundId ~= "" then
        buttonClickSound.SoundId = "rbxassetid://" .. savedSound.SoundId
        debugPrint("Loaded saved Sound ID:", buttonClickSound.SoundId)
    end

    local notifications = {}
    local NOTIFICATION_HEIGHT = 50
    local NOTIFICATION_SPACING = 10
    local NOTIFICATION_DURATION = 2

    local function updateNotificationPositions()
        for i, notif in ipairs(notifications) do
            local targetY = 10 + (i - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)
            TweenService:Create(notif.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(1, -210, 0, targetY)
            }):Play()
        end
    end

    local function showNotification(message)
        if not NOTIFICATIONS_ENABLED then return end
        local notificationFrame = Instance.new("Frame")
        notificationFrame.Size = UDim2.new(0, 200, 0, NOTIFICATION_HEIGHT)
        notificationFrame.Position = UDim2.new(1, -210, 0, 10 + #notifications * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING))
        notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        notificationFrame.BackgroundTransparency = 0.2
        notificationFrame.ZIndex = 1002
        notificationFrame.Parent = screenGui

        local cornerNotif = Instance.new("UICorner")
        cornerNotif.CornerRadius = UDim.new(0, 5)
        cornerNotif.Parent = notificationFrame

        local notifLabel = Instance.new("TextLabel")
        notifLabel.Size = UDim2.new(1, -10, 1, -10)
        notifLabel.Position = UDim2.new(0, 5, 0, 5)
        notifLabel.BackgroundTransparency = 1
        notifLabel.Text = message
        notifLabel.TextColor3 = theme.TextColor
        notifLabel.TextScaled = true
        notifLabel.ZIndex = 1003
        notifLabel.Parent = notificationFrame

        local notif = {Frame = notificationFrame}
        table.insert(notifications, notif)

        local fadeIn = TweenService:Create(notificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 0})
        local fadeOut = TweenService:Create(notificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 1})

        fadeIn:Play()
        fadeIn.Completed:Wait()
        task.wait(NOTIFICATION_DURATION)
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            table.remove(notifications, table.find(notifications, notif))
            notificationFrame:Destroy()
            updateNotificationPositions()
        end)

        updateNotificationPositions()
    end

    local function toggleUI(state)
        local isVisible = mainFrame.Visible
        local targetState = state ~= nil and state or not isVisible

        if targetState == isVisible then
            return
        end

        if targetState then
            mainFrame.Visible = true
            mainFrame.Position = UDim2.new(0.1, 0, -0.8, 0)
            local slideIn = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.1, 0, 0.1, 0)})
            slideIn:Play()
            toggleButton.Text = "ON"
            toggleButton.BackgroundColor3 = theme.AccentColor
        else
            local slideOut = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.1, 0, -0.8, 0)})
            slideOut:Play()
            slideOut.Completed:Connect(function()
                mainFrame.Visible = false
            end)
            toggleButton.Text = "OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end

        if buttonClickSound.SoundId ~= "" then
            buttonClickSound:Play()
        end
        if NOTIFICATIONS_ENABLED then
            showNotification("UI " .. (targetState and "Opened" or "Closed"))
        end
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

    local function verifyKey(inputKey)
        if not config.Keyconfig or not config.Keyconfig.Keyopen then return true end
        local storedKey = loadData(KEY_FILE, "")
        if storedKey == inputKey and inputKey == config.Keyconfig.Key then
            return true
        end
        if inputKey == config.Keyconfig.Key then
            saveData(KEY_FILE, inputKey)
            return true
        end
        warn("Invalid key entered")
        return false
    end

    if config.Keyconfig and config.Keyconfig.Keyopen then
        verifyButton.MouseButton1Click:Connect(function()
            if verifyKey(keyInput.Text) then
                keyFrame.Visible = false
                mainFrame.Visible = true
                toggleButton.Visible = true
                if toggleButton.Text == "ON" then
                    mainFrame.Visible = true
                else
                    mainFrame.Visible = false
                end
                debugPrint("Key verified successfully")
                if buttonClickSound.SoundId ~= "" then
                    buttonClickSound:Play()
                end
                if NOTIFICATIONS_ENABLED then
                    showNotification("Key verified")
                end
            else
                keyInput.Text = ""
                keyInput.PlaceholderText = "Invalid key, try again"
                if buttonClickSound.SoundId ~= "" then
                    buttonClickSound:Play()
                end
                if NOTIFICATIONS_ENABLED then
                    showNotification("Invalid key")
                end
            end
        end)

        copyKeyLinkButton.MouseButton1Click:Connect(function()
            if config.Keyconfig.Linkcopiekey then
                local success, err = pcall(function()
                    setclipboard(config.Keyconfig.Linkcopiekey)
                end)
                if success then
                    copyKeyLinkButton.Text = "Copied!"
                    task.wait(1)
                    copyKeyLinkButton.Text = "Copy Key Link"
                    if buttonClickSound.SoundId ~= "" then
                        buttonClickSound:Play()
                    end
                    if NOTIFICATIONS_ENABLED then
                        showNotification("Key link copied")
                    end
                else
                    warn("Failed to copy key link:", err)
                    if NOTIFICATIONS_ENABLED then
                        showNotification("Failed to copy key link")
                    end
                end
            end
        end)

        local savedKey = loadData(KEY_FILE, "")
        if verifyKey(savedKey) then
            keyFrame.Visible = false
            mainFrame.Visible = true
            toggleButton.Visible = true
        else
            keyFrame.Visible = true
            mainFrame.Visible = false
            toggleButton.Visible = false
        end
    else
        keyFrame.Visible = false
        mainFrame.Visible = true
        toggleButton.Visible = true
    end

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

            if buttonClickSound.SoundId ~= "" then
                buttonClickSound:Play()
            end
            if NOTIFICATIONS_ENABLED then
                showNotification("Switched to " .. tabName)
            end
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
            button.Size = UDim2.new(1, -10, 0, 50) -- ปรับขนาดให้ใหญ่ขึ้น
            button.BackgroundColor3 = theme.AccentColor
            button.Text = buttonConfig.Name or "Button"
            button.TextColor3 = theme.TextColor
            button.TextSize = 18 -- กำหนดขนาดตัวอักษร
            button.TextScaled = false -- ปิด TextScaled เพื่อควบคุมขนาด
            button.TextTruncate = Enum.TextTruncate.AtEnd -- ตัดข้อความยาวเกิน
            button.ZIndex = 11
            button.LayoutOrder = #tabContent:GetChildren()
            button.Active = true
            button.AutoButtonColor = true
            button.Parent = tabContent

            local cornerButton = Instance.new("UICorner")
            cornerButton.CornerRadius = UDim.new(0, 5)
            cornerButton.Parent = button

            button.MouseButton1Click:Connect(function()
                if buttonClickSound.SoundId ~= "" then
                    buttonClickSound:Play()
                end
                if NOTIFICATIONS_ENABLED then
                    showNotification("Clicked " .. (buttonConfig.Name or "Button"))
                end

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
            if elementStates.Toggles and elementStates.Toggles[toggleConfig.Name] ~= nil then
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
                if not elementStates.Toggles then
                    elementStates.Toggles = {}
                end
                elementStates.Toggles[toggleConfig.Name] = toggleState
                saveData(ELEMENTS_FILE, elementStates)
                
                if buttonClickSound.SoundId ~= "" then
                    buttonClickSound:Play()
                end
                if NOTIFICATIONS_ENABLED then
                    showNotification((toggleConfig.Name or "Toggle") .. " set to " .. (toggleState and "ON" or "OFF"))
                end

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

                        if buttonClickSound.SoundId ~= "" then
                            buttonClickSound:Play()
                        end
                        if NOTIFICATIONS_ENABLED then
                            showNotification((sliderConfig.Name or "Slider") .. " set to " .. string.format("%.2f", value))
                        end

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
            dropdownButton.TextSize = 16 -- ปรับขนาดตัวอักษร
            dropdownButton.TextScaled = false -- ปิด TextScaled
            dropdownButton.TextTruncate = Enum.TextTruncate.AtEnd -- ตัดข้อความยาวเกิน
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

            local isMulti = dropdownConfig.Multi or false
            local maxSelections = dropdownConfig.MaxSelections or math.huge
            local selectedOptions = {}
            if elementStates.Dropdowns and elementStates.Dropdowns[dropdownConfig.Name] then
                selectedOptions = elementStates.Dropdowns[dropdownConfig.Name]
                dropdownButton.Text = #selectedOptions > 0 and table.concat(selectedOptions, ", ") or (dropdownConfig.Name or "Select Option")
            elseif not isMulti and dropdownConfig.Default then
                selectedOptions = {dropdownConfig.Default}
                dropdownButton.Text = dropdownConfig.Default
            end

            local function updateListHeight()
                dropdownList.Size = UDim2.new(1, 0, 0, #dropdownConfig.Options * 30)
            end

            local function updateButtonText()
                dropdownButton.Text = #selectedOptions > 0 and table.concat(selectedOptions, ", ") or (dropdownConfig.Name or "Select Option")
                if not elementStates.Dropdowns then
                    elementStates.Dropdowns = {}
                end
                elementStates.Dropdowns[dropdownConfig.Name] = selectedOptions
                saveData(ELEMENTS_FILE, elementStates)
            end

            local optionButtons = {}

            for i, option in ipairs(dropdownConfig.Options) do
                local optionFrame = Instance.new("Frame")
                optionFrame.Size = UDim2.new(1, 0, 0, 30)
                optionFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                optionFrame.ZIndex = 13
                optionFrame.LayoutOrder = i
                optionFrame.Parent = dropdownList

                local checkbox = Instance.new("TextButton")
                checkbox.Size = UDim2.new(isMulti and 0.1 or 0, 0, 0.6, 0)
                checkbox.Position = UDim2.new(isMulti and 0.05 or 0, 0, 0.2, 0)
                checkbox.BackgroundColor3 = table.find(selectedOptions, option) and theme.AccentColor or Color3.fromRGB(100, 100, 100)
                checkbox.Text = table.find(selectedOptions, option) and "✓" or ""
                checkbox.TextColor3 = theme.TextColor
                checkbox.TextScaled = true
                checkbox.ZIndex = 14
                checkbox.Visible = isMulti
                checkbox.Active = true
                checkbox.AutoButtonColor = true
                checkbox.Parent = optionFrame

                local optionLabel = Instance.new("TextButton")
                optionLabel.Size = UDim2.new(isMulti and 0.8 or 1, 0, 1, 0)
                optionLabel.Position = UDim2.new(isMulti and 0.15 or 0, 0, 0, 0)
                optionLabel.BackgroundTransparency = 1
                optionLabel.Text = tostring(option)
                optionLabel.TextColor3 = theme.TextColor
                optionLabel.TextSize = 14 -- ปรับขนาดตัวอักษร
                optionLabel.TextScaled = false -- ปิด TextScaled
                optionLabel.TextTruncate = Enum.TextTruncate.AtEnd -- ตัดข้อความยาวเกิน
                optionLabel.TextXAlignment = Enum.TextXAlignment.Left
                optionLabel.ZIndex = 14
                optionLabel.Active = true
                optionLabel.AutoButtonColor = true
                optionLabel.Parent = optionFrame

                table.insert(optionButtons, {Label = optionLabel, Checkbox = checkbox})

                local function handleSelection()
                    if isMulti then
                        if table.find(selectedOptions, option) then
                            table.remove(selectedOptions, table.find(selectedOptions, option))
                            checkbox.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                            checkbox.Text = ""
                        else
                            if #selectedOptions < maxSelections then
                                table.insert(selectedOptions, option)
                                checkbox.BackgroundColor3 = theme.AccentColor
                                checkbox.Text = "✓"
                            else
                                if NOTIFICATIONS_ENABLED then
                                    showNotification("Maximum selections reached")
                                end
                                return
                            end
                        end
                        updateButtonText()
                        if buttonClickSound.SoundId ~= "" then
                            buttonClickSound:Play()
                        end
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Selected " .. tostring(option))
                        end
                    else
                        for _, btn in ipairs(optionButtons) do
                            btn.Label.TextColor3 = theme.TextColor
                        end
                        selectedOptions = {option}
                        optionLabel.TextColor3 = theme.AccentColor
                        dropdownList.Visible = false
                        updateButtonText()
                        if buttonClickSound.SoundId ~= "" then
                            buttonClickSound:Play()
                        end
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Selected " .. tostring(option))
                        end
                    end

                    if dropdownConfig.Callback then
                        local success, err = pcall(function()
                            dropdownConfig.Callback(isMulti and selectedOptions or selectedOptions[1])
                        end)
                        if not success then
                            debugPrint("Dropdown callback error:", err)
                        end
                    end
                end

                checkbox.MouseButton1Click:Connect(handleSelection)
                optionLabel.MouseButton1Click:Connect(handleSelection)
            end

            updateListHeight()

            dropdownButton.MouseButton1Click:Connect(function()
                dropdownList.Visible = not dropdownList.Visible
                if buttonClickSound.SoundId ~= "" then
                    buttonClickSound:Play()
                end
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
            if elementStates.Inputs and elementStates.Inputs[inputConfig.Name] ~= nil then
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
                    if not elementStates.Inputs then
                        elementStates.Inputs = {}
                    end
                    elementStates.Inputs[inputConfig.Name] = textBox.Text
                    saveData(ELEMENTS_FILE, elementStates)

                    if buttonClickSound.SoundId ~= "" then
                        buttonClickSound:Play()
                    end
                    if NOTIFICATIONS_ENABLED then
                        showNotification("Input updated: " .. textBox.Text)
                    end

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
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Background color updated")
                        end
                    else
                        warn("Invalid RGB format. Use: R,G,B (e.g., 30,30,30)")
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Invalid RGB format")
                        end
                    end
                end
            })
            
            bgTab:AddInput({
                Name = "Image ID (Number only)",
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
                            saveData(BACKGROUND_FILE, thumbId)
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Image loaded")
                            end
                        else
                            warn("Failed to preload image after", retries, "attempts")
                            imageLabel.Image = ""
                            imageLabel.Visible = false
                            mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Failed to load image")
                            end
                        end
                    else
                        warn("Invalid Image ID format. Use a number only (e.g., 5191098772)")
                        imageLabel.Image = ""
                        imageLabel.Visible = false
                        mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                        mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Invalid Image ID format")
                        end
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
                            saveData(VIDEO_FILE, value)
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Video loaded")
                            end
                        else
                            warn("Failed to load video:", err)
                            videoFrame.Video = ""
                            videoFrame.Visible = false
                            imageLabel.Visible = true
                            mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Failed to load video")
                            end
                        end
                    else
                        warn("Invalid Video ID format. Use rbxassetid:// followed by numbers or just the numbers")
                        videoFrame.Video = ""
                        videoFrame.Visible = false
                        imageLabel.Visible = true
                        mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                        mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Invalid Video ID format")
                        end
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
                    if NOTIFICATIONS_ENABLED then
                        showNotification("Transparency set to " .. string.format("%.2f", value))
                    end
                end
            })

            bgTab:AddInput({
                Name = "Sound ID (Number only)",
                Default = savedSound.SoundId or "",
                Callback = function(value)
                    if value == "" then
                        buttonClickSound.SoundId = ""
                        saveData(SOUND_FILE, {SoundId = ""})
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Sound disabled")
                        end
                        debugPrint("Sound disabled")
                        return
                    end

                    if value:match("^%d+$") then
                        local soundId = "rbxassetid://" .. value
                        debugPrint("Attempting to load sound:", soundId)

                        local success, err = pcall(function()
                            ContentProvider:PreloadAsync({soundId})
                            buttonClickSound.SoundId = soundId
                            buttonClickSound:Play()
                        end)

                        if success then
                            debugPrint("Sound loaded successfully")
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Sound updated to ID: " .. value)
                            end
                            saveData(SOUND_FILE, {SoundId = value})
                        else
                            warn("Failed to load sound:", err)
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Failed to load Sound ID: " .. value)
                            end
                            buttonClickSound.SoundId = ""
                            saveData(SOUND_FILE, {SoundId = ""})
                        end
                    else
                        warn("Invalid Sound ID format. Use a number only (e.g., 9120386436)")
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Invalid Sound ID format")
                        end
                    end
                end
            })

            bgTab:AddButton({
                Name = "Pause/Play Video",
                Callback = function()
                    if videoFrame.IsLoaded then
                        if videoFrame.IsPlaying then
                            videoFrame:Pause()
                            debugPrint("Video paused")
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Video paused")
                            end
                        else
                            videoFrame:Play()
                            debugPrint("Video playing")
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Video playing")
                            end
                        end
                    else
                        debugPrint("No video loaded")
                        if NOTIFICATIONS_ENABLED then
                            showNotification("No video loaded")
                        end
                    end
                end
            })

            bgTab:AddButton({
                Name = "Reset Dropdowns",
                Callback = function()
                    local success, err = pcall(function()
                        elementStates.Dropdowns = {}
                        saveData(ELEMENTS_FILE, elementStates)
                        debugPrint("Dropdown states reset")
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Dropdown states reset")
                        end
                    end)
                    if not success then
                        warn("Failed to reset dropdown states:", err)
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Failed to reset dropdown states")
                        end
                    end
                end
            })

            bgTab:AddButton({
                Name = "Reset Theme",
                Callback = function()
                    local success, err = pcall(function()
                        if isfile(THEME_FILE) then
                            delfile(THEME_FILE)
                        end
                        mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        theme.BackgroundColor = Color3.fromRGB(30, 30, 30)
                        theme.Transparency = 0.2
                        mainFrame.BackgroundTransparency = 0.2
                        debugPrint("Theme reset")
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Theme reset")
                        end
                    end)
                    if not success then
                        warn("Failed to reset theme:", err)
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Failed to reset theme")
                        end
                    end
                end
            })

            bgTab:AddButton({
                Name = "Reset All Settings",
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
                        elementStates.Dropdowns = {}
                        buttonClickSound.SoundId = ""
                        saveData(ELEMENTS_FILE, elementStates)
                        saveData(SOUND_FILE, {SoundId = ""})
                        debugPrint("Settings reset successfully")
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Settings reset")
                        end
                    else
                        warn("Failed to reset settings:", err)
                        if NOTIFICATIONS_ENABLED then
                            showNotification("Failed to reset settings")
                        end
                    end
                end
            })

            if config.Discord and config.Discord.Invite then
                bgTab:AddButton({
                    Name = "Copy Discord Invite",
                    Callback = function()
                        local success, err = pcall(function()
                            setclipboard(config.Discord.Invite)
                        end)
                        if success then
                            debugPrint("Discord invite copied:", config.Discord.Invite)
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Discord invite copied")
                            end
                        else
                            warn("Failed to copy Discord invite:", err)
                            if NOTIFICATIONS_ENABLED then
                                showNotification("Failed to copy Discord invite")
                            end
                        end
                    end
                })
            end

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
            else
                debugPrint("Failed to preload saved image after retries")
                imageLabel.Image = ""
                imageLabel.Visible = false
                mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
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
                debugPrint("Video loaded successfully")
            else
                debugPrint("Failed to load saved background video:", err)
                videoFrame.Video = ""
                videoFrame.Visible = false
                imageLabel.Visible = true
                mainFrame.BackgroundTransparency = math.min(theme.Transparency, 0.8)
                mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end
    end

    loadSettings()
    return window
end

return Gghiza07UI