local Gghiza07UI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ปรับปรุงเวอร์ชันและเพิ่มระบบล็อก
local VERSION = "J (4.1 Enhanced)"
local LOCKED = false

function Gghiza07UI:Lock()
    LOCKED = true
end

function Gghiza07UI:Unlock()
    LOCKED = false
end

function Gghiza07UI:CreateWindow(config)
    if LOCKED then return error("UI is locked") end
    
    local window = {}
    print("Creating window:", config.Name, "Version:", VERSION)

    -- ปรับปรุงระบบเก็บข้อมูล
    local SETTINGS_FOLDER = "Gghiza07UI/" .. (config.Name or "DefaultUI")
    local SETTINGS_FILE = SETTINGS_FOLDER .. "/settings.json"
    local BACKGROUND_FILE = SETTINGS_FOLDER .. "/background.txt"
    local THEME_FILE = SETTINGS_FOLDER .. "/theme.json"

    -- ลบ UI เก่าถ้ามี
    local existingScreenGui = playerGui:FindFirstChild(config.Name or "Gghiza07UI")
    if existingScreenGui then
        existingScreenGui:Destroy()
    end

    local existingToggleGui = playerGui:FindFirstChild("ToggleGui")
    if existingToggleGui then
        existingToggleGui:Destroy()
    end

    -- สร้าง UI หลัก
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "Gghiza07UI"
    screenGui.Parent = playerGui
    screenGui.Enabled = true
    screenGui.DisplayOrder = 1000
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    -- ธีมเริ่มต้น
    local defaultTheme = {
        BackgroundColor = Color3.fromRGB(30, 30, 30),
        AccentColor = Color3.fromRGB(0, 123, 255),
        TextColor = Color3.fromRGB(255, 255, 255),
        CornerRadius = 10
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
        pcall(function()
            writefile(file, HttpService:JSONEncode(data))
        end)
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

    -- สร้างพื้นหลังแบบปรับปรุง
    local backgroundImage = Instance.new("ImageLabel")
    backgroundImage.Name = "Background"
    backgroundImage.Size = UDim2.new(1, 0, 1, 0)
    backgroundImage.Position = UDim2.new(0, 0, 0, 0)
    backgroundImage.BackgroundColor3 = theme.BackgroundColor
    backgroundImage.BackgroundTransparency = 0.5
    backgroundImage.ImageTransparency = 0.5
    backgroundImage.ZIndex = 5
    backgroundImage.ScaleType = Enum.ScaleType.Crop
    backgroundImage.Parent = screenGui

    -- ฟังก์ชันเปลี่ยนพื้นหลังแบบปรับปรุง
    local function setBackground(type, value)
        if type == "Color" then
            backgroundImage.Image = ""
            backgroundImage.BackgroundColor3 = value
            backgroundImage.BackgroundTransparency = 0.5
        elseif type == "Image" then
            if value:match("^rbxassetid://%d+$") then
                ContentProvider:PreloadAsync({value})
                backgroundImage.Image = value
                backgroundImage.BackgroundTransparency = 1
            end
        elseif type == "Transparency" then
            backgroundImage.ImageTransparency = value
            backgroundImage.BackgroundTransparency = value
        end
    end

    -- ส่วนหลักของ UI
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = theme.BackgroundColor
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.ZIndex = 10
    mainFrame.Parent = screenGui

    -- เพิ่มระบบลากเคลื่อนย้าย
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

    -- ส่วน Tab ระบบ
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, -20, 0, 40)
    tabButtons.Position = UDim2.new(0, 10, 0, 10)
    tabButtons.BackgroundTransparency = 1
    tabButtons.ZIndex = 11
    tabButtons.Parent = mainFrame

    local tabContents = Instance.new("Frame")
    tabContents.Name = "TabContents"
    tabContents.Size = UDim2.new(1, -20, 1, -60)
    tabContents.Position = UDim2.new(0, 10, 0, 60)
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
    toggleButton.ZIndex = 1001
    toggleButton.Parent = screenGui

    -- ฟังก์ชันเปิดปิด UI
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

    -- ระบบ Tab
    function window:CreateTab(tabName)
        local tab = {}
        local tabId = #mainFrame:GetChildren() + 1
        
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

        -- เนื้อหา Tab
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabName
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.ZIndex = 10
        tabContent.Parent = tabContents

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
            -- ... (โค้ดเดิม)
        end

        function tab:AddToggle(toggleConfig)
            -- ... (โค้ดเดิม)
        end

        -- ระบบเปลี่ยนพื้นหลังแบบปรับปรุง
        function tab:AddBackgroundOptions()
            local bgTab = self:AddTab("Background")
            
            -- เปลี่ยนสีพื้นหลัง
            bgTab:AddInput({
                Name = "Background Color",
                Default = tostring(theme.BackgroundColor),
                Callback = function(value)
                    local r, g, b = value:match("(%d+),%s*(%d+),%s*(%d+)")
                    if r and g and b then
                        local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                        setBackground("Color", color)
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
                        setBackground("Image", value)
                        pcall(function()
                            writefile(BACKGROUND_FILE, value)
                        end)
                    end
                end
            })
            
            -- ความโปร่งใส
            bgTab:AddSlider({
                Name = "Transparency",
                Min = 0,
                Max = 1,
                Default = 0.5,
                Callback = function(value)
                    setBackground("Transparency", value)
                end
            })
        end

        return tab
    end

    -- โหลดพื้นหลังที่บันทึกไว้
    if isfile(BACKGROUND_FILE) then
        local bgId = readfile(BACKGROUND_FILE)
        if bgId:match("^rbxassetid://%d+$") then
            setBackground("Image", bgId)
        end
    end

    return window
end

print("Gghiza07UI Enhanced loaded successfully")
return Gghiza07UI