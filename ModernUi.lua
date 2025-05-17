
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local ui = {}

local Settings = {}

-- Save & Load
local function SaveSettings(filename)
    if not filename then return end
    local data = HttpService:JSONEncode(Settings)
    pcall(function()
        writefile(filename .. ".json", data)
    end)
end

local function LoadSettings(filename)
    if not filename then return end
    if isfile(filename .. ".json") then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(filename .. ".json"))
        end)
        if success and data then
            Settings = data
        end
    end
end

function ui:CreateWindow(config)
    config = config or {}
    config.Name = config.Name or "My UI"
    local SaveFile = (config.SaveSetting and config.SaveSetting.Save and config.SaveSetting.Filename) or nil
    LoadSettings(SaveFile)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = gethui and gethui() or CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = UDim.new(0, 12)

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.Padding = UDim.new(0, 10)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top

    local padding = Instance.new("UIPadding", mainFrame)
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)

    local win = {}

    function win:CreateTab(data)
        local tab = {}

        function tab:CreateButton(opt)
            local btn = Instance.new("TextButton")
            btn.Text = opt.Name or "Button"
            btn.Size = UDim2.new(1, -30, 0, 40)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 16
            btn.AutoButtonColor = true
            btn.Parent = mainFrame

            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            btn.MouseButton1Click:Connect(function()
                if opt.Callfunction then
                    opt.Callfunction()
                end
                if opt.Flag then
                    Settings[opt.Flag] = true
                    SaveSettings(SaveFile)
                end
            end)
        end

        function tab:CreateToggle(opt)
            local toggle = Instance.new("TextButton")
            toggle.Text = (Settings[opt.Flag] and "ON: " or "OFF: ") .. opt.Name
            toggle.Size = UDim2.new(1, -30, 0, 40)
            toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            toggle.TextColor3 = Color3.new(1, 1, 1)
            toggle.Font = Enum.Font.Gotham
            toggle.TextSize = 16
            toggle.Parent = mainFrame

            Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

            toggle.MouseButton1Click:Connect(function()
                Settings[opt.Flag] = not Settings[opt.Flag]
                toggle.Text = (Settings[opt.Flag] and "ON: " or "OFF: ") .. opt.Name
                if opt.Callfunction then
                    opt.Callfunction(Settings[opt.Flag])
                end
                SaveSettings(SaveFile)
            end)

            -- load previous state
            if Settings[opt.Flag] ~= nil then
                opt.Callfunction(Settings[opt.Flag])
            end
        end

        -- You can add more UI elements similarly...

        return tab
    end

    return win
end

return ui
