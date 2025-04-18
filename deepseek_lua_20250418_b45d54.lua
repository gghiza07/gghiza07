local Gghiza07UI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

-- เวอร์ชันและระบบล็อก
local VERSION = "V4.1 Enhanced"
local LOCKED = false
local DEBUG_MODE = true

-- ฟังก์ชันดีบัก
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
    if LOCKED then return error("UI is locked") end
    
    local window = {}
    debugPrint("Creating window:", config.Name, "Version:", VERSION)

    -- ระบบไฟล์และโฟลเดอร์
    local SETTINGS_FOLDER = "Gghiza07UI/" .. (config.Name or "DefaultUI")
    local SETTINGS_FILE = SETTINGS_FOLDER .. "/settings.json"
    local BACKGROUND_FILE = SETTINGS_FOLDER .. "/background.txt"
    local VIDEO_FILE = SETTINGS_FOLDER .. "/video.txt"
    local THEME_FILE = SETTINGS_FOLDER .. "/theme.json"

    -- ธีมเริ่มต้น
    local defaultTheme = {
        BackgroundColor = Color3.fromRGB(30, 30, 30),
        AccentColor = Color3.fromRGB(0, 123, 255),
        TextColor = Color3.fromRGB(255, 255, 255),
        CornerRadius = 10,
        Transparency = 0.2
    }

    -- ฟังก์ชันจัดการไฟล์
    local function ensureFolderExists()
        if not isfolder("Gghiza07UI") then
            makefolder("Gghiza07UI")
        end
        if not isfolder(SETTINGS_FOLDER) then
            makefolder(SETTINGS_FOLDER)
        end
    end

    local function saveData(file, data)
        ensureFolderExists()
        local success, err = pcall(function()
            writefile(file, HttpService:JSONEncode(data))
        end)
        if not success then
            debugPrint("Failed to save data to", file, "Error:", err)
        end
    end

    local function loadData(file, default)
        ensureFolderExists()
        if isfile(file) then
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(file))
            end)
            if success then return data end
        end
        return default or nil
    end

    -- โหลดธีม
    local theme = loadData(THEME_FILE, defaultTheme)

    -- สร้าง UI หลัก
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- ลบ UI เก่าถ้ามี
    local existingScreenGui = playerGui:FindFirstChild(config.Name or "Gghiza07UI")
    if existingScreenGui then
        existingScreenGui:Destroy()
    end

    local existingToggleGui = playerGui:FindFirstChild("ToggleGui")
    if existingToggleGui then
        existingToggleGui:Destroy()
    end

    -- สร้าง ScreenGui หลัก
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "Gghiza07UI"
    screenGui.Parent = playerGui
    screenGui.Enabled = true
    screenGui.DisplayOrder = 1000
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    -- เฟรมหลัก
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = theme.BackgroundColor
    mainFrame.BackgroundTransparency = theme.Transparency
    mainFrame.ZIndex = 10
    mainFrame.Parent = screenGui

    -- มุมโค้ง
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, theme.CornerRadius)
    corner.Parent = mainFrame

    -- พื้นหลัง (รูปภาพ)
    local backgroundImage = Instance.new("ImageLabel")
    backgroundImage.Name = "BackgroundImage"
    backgroundImage.Size = UDim2.new(1, 0, 1, 0)
    backgroundImage.Position = UDim2.new(0, 0, 0, 0)
    backgroundImage.BackgroundTransparency = 1
    backgroundImage.ZIndex = 5
    backgroundImage.ScaleType = Enum.ScaleType.Crop
    backgroundImage.Parent = mainFrame

    -- พื้นหลัง (วิดีโอ)
    local videoFrame = Instance.new("VideoFrame")
    videoFrame.Name = "BackgroundVideo"
    videoFrame.Size = UDim2.new(1, 0, 1, 0)
    videoFrame.Position = UDim2.new(0, 0, 0, 0)
    videoFrame.BackgroundTransparency = 1
    videoFrame.ZIndex = 6
    videoFrame.Visible = false
    videoFrame.Parent = mainFrame

    -- ระบบลากเคลื่อนย้าย UI
    local dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragStart = nil
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ส่วนหัว UI
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

    -- ส่วน Tab
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, -20, 0, 40)
    tabButtons.Position = UDim2.new(0, 10, 0, 50)
    tabButtons.BackgroundTransparency = 1
    tabButtons.ZIndex = 11
    tabButtons.Parent = mainFrame

    local tabContents = Instance.new("Frame")
    tabContents.Name = "TabContents"
    tabContents.Size = UDim2.new(1, -20, 1, -110)
    tabContents.Position = UDim2.new(0, 10, 0, 110)
    tabContents.BackgroundTransparency = 1
    tabContents.ZIndex = 10
    tabContents.Parent = mainFrame

    -- ปุ่มเปิดปิด UI
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0, 10, 1, -60)
    toggleButton.BackgroundColor3 = theme.AccentColor
    toggleButton.TextColor3 = theme.TextColor
    toggleButton.Text = "ON"
    toggleButton.TextScaled = true
    toggleButton.ZIndex = 1001
    toggleButton.Parent = screenGui

    local cornerToggle = Instance.new("UICorner")
    cornerToggle.CornerRadius = UDim.new(0, 15)
    cornerToggle.Parent = toggleButton

    -- ระบบเปิดปิด UI
    local function toggleUI(state)
        if state ~= nil then
            screenGui.Enabled = state
        else
            screenGui.Enabled = not screenGui.Enabled
        end
        
        toggleButton.Text = screenGui.Enabled and "ON" or "OFF"
        toggleButton.BackgroundColor3 = screenGui.Enabled and theme.AccentColor or Color3.fromRGB(100, 100, 100)
    end

    toggleButton.MouseButton1Click:Connect(toggleUI)

    -- ระบบลากเคลื่อนย้ายปุ่มเปิดปิด
    local toggleDragStart, toggleStartPos
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleDragStart = input.Position
            toggleStartPos = toggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    toggleDragStart = nil
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and toggleDragStart then
            local delta = input.Position - toggleDragStart
            toggleButton.Position = UDim2.new(
                toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X,
                toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ระบบ Tab
    function window:CreateTab(tabName)
        local tab = {}
        local tabId = #tabButtons:GetChildren() + 1
        
        -- ปุ่ม Tab
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.Position = UDim2.new(0, (tabId-1)*110, 0, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabButton.Text = tabName
        tabButton.TextColor3 = theme.TextColor
        tabButton.ZIndex = 11
        tabButton.Parent = tabButtons

        local cornerTab = Instance.new("UICorner")
        cornerTab.CornerRadius = UDim.new(0, 5)
        cornerTab.Parent = tabButton

        -- เนื้อหา Tab
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabName
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.ScrollBarThickness = 5
        tabContent.ZIndex = 10
        tabContent.Parent = tabContents

        local uiListLayout = Instance.new("UIListLayout")
        uiListLayout.Padding = UDim.new(0, 5)
        uiListLayout.Parent = tabContent

        -- ฟังก์ชันสลับ Tab
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

        -- เลือก Tab แรกโดยอัตโนมัติ
        if tabId == 1 then selectTab() end

        -- ฟังก์ชันสร้าง UI Elements
        function tab:AddButton(buttonConfig)
            local button = Instance.new("TextButton")
            button.Name = buttonConfig.Name or "Button"
            button.Size = UDim2.new(1, -20, 0, 40)
            button.Position = UDim2.new(0, 10, 0, #tabContent:GetChildren() * 45)
            button.BackgroundColor3 = theme.AccentColor
            button.Text = buttonConfig.Name or "Button"
            button.TextColor3 = theme.TextColor
            button.ZIndex = 11
            button.Parent = tabContent

            local cornerButton = Instance.new("UICorner")
            cornerButton.CornerRadius = UDim.new(0, 5)
            cornerButton.Parent = button

            button.MouseButton1Click:Connect(function()
                if buttonConfig.Callback then
                    pcall(buttonConfig.Callback)
                end
            end)

            return button
        end

        -- ระบบเปลี่ยนพื้นหลังแบบปรับปรุง
        function tab:AddBackgroundOptions()
            local bgTab = self
            
            -- เปลี่ยนสีพื้นหลัง
            bgTab:AddInput({
                Name = "Background Color (R,G,B)",
                Default = "30,30,30",
                Callback = function(value)
                    local r, g, b = value:match("(%d+),%s*(%d+),%s*(%d+)")
                    if r and g and b then
                        local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                        mainFrame.BackgroundColor3 = color
                        theme.BackgroundColor = color
                        saveData(THEME_FILE, theme)
                    end
                end
            })
            
            -- เปลี่ยนรูปพื้นหลัง
            bgTab:AddInput({
                Name = "Image ID (rbxassetid://)",
                Callback = function(value)
                    if value:match("^rbxassetid://%d+$") then
                        ContentProvider:PreloadAsync({value})
                        backgroundImage.Image = value
                        videoFrame.Visible = false
                        backgroundImage.Visible = true
                        saveData(BACKGROUND_FILE, value)
                    end
                end
            })
            
            -- เปลี่ยนวิดีโอพื้นหลัง
            bgTab:AddInput({
                Name = "Video ID (rbxassetid://)",
                Callback = function(value)
                    if value:match("^rbxassetid://%d+$") then
                        videoFrame.Video = value
                        videoFrame.Visible = true
                        backgroundImage.Visible = false
                        videoFrame:Play()
                        saveData(VIDEO_FILE, value)
                    end
                end
            })
            
            -- ความโปร่งใส
            bgTab:AddSlider({
                Name = "Transparency",
                Min = 0,
                Max = 1,
                Default = theme.Transparency,
                Callback = function(value)
                    mainFrame.BackgroundTransparency = value
                    theme.Transparency = value
                    saveData(THEME_FILE, theme)
                end
            })
        end

        return tab
    end

    -- โหลดการตั้งค่าที่บันทึกไว้
    local function loadSettings()
        -- โหลดพื้นหลังรูปภาพ
        local bgImage = loadData(BACKGROUND_FILE, "")
        if bgImage ~= "" then
            ContentProvider:PreloadAsync({bgImage})
            backgroundImage.Image = bgImage
            backgroundImage.Visible = true
        end

        -- โหลดวิดีโอ
        local bgVideo = loadData(VIDEO_FILE, "")
        if bgVideo ~= "" then
            videoFrame.Video = bgVideo
            videoFrame.Visible = true
            videoFrame:Play()
            backgroundImage.Visible = false
        end
    end

    loadSettings()

    return window
end

return Gghiza07UI