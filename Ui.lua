local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ui = {}

function ui:CreateWindow(config)
    local win = {}
    config = config or {}
    config.Name = config.Name or "My UI"
    config.Creditconfig = config.Creditconfig or { Name = "", Show = false }

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Ui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        if gethui then
            screenGui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = CoreGui
        else
            screenGui.Parent = CoreGui
        end
    end)
    if not screenGui.Parent then
        warn("Fallback to PlayerGui")
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10)
    end

    -- Create main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 400)
    frame.Position = UDim2.new(0.5, -250, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    -- Add shadow
    local uiStroke = Instance.new("UIStroke", frame)
    uiStroke.Thickness = 2
    uiStroke.Color = Color3.fromRGB(60, 60, 60)
    uiStroke.Transparency = 0.8

    -- Make window draggable
    local dragging, dragInput, dragStart, startPos
    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 250, 0, 30)
    titleLabel.Position = UDim2.new(0, 15, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.Name
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    -- Credit label
    if config.Creditconfig.Show then
        local creditLabel = Instance.new("TextLabel")
        creditLabel.Size = UDim2.new(0, 100, 0, 15)
        creditLabel.Position = UDim2.new(0, 390, 0, 15)
        creditLabel.BackgroundTransparency = 1
        creditLabel.Text = config.Creditconfig.Name or ""
        creditLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        creditLabel.TextScaled = true
        creditLabel.Font = Enum.Font.Gotham
        creditLabel.TextXAlignment = Enum.TextXAlignment.Right
        creditLabel.Parent = frame
    end

    -- Tab system
    win.Tabs = {}
    win.CurrentTab = nil

    win.TabContainer = Instance.new("Frame")
    win.TabContainer.Size = UDim2.new(0, 120, 1, -60)
    win.TabContainer.Position = UDim2.new(0, 15, 0, 60)
    win.TabContainer.BackgroundTransparency = 1
    win.TabContainer.ZIndex = 2
    win.TabContainer.Parent = frame

    win.ContentArea = Instance.new("ScrollingFrame")
    win.ContentArea.Size = UDim2.new(0, 350, 1, -60)
    win.ContentArea.Position = UDim2.new(0, 140, 0, 60)
    win.ContentArea.BackgroundTransparency = 1
    win.ContentArea.ZIndex = 2
    win.ContentArea.ScrollBarThickness = 4
    win.ContentArea.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    win.ContentArea.Parent = frame
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = win.ContentArea

    function win:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.Name = tabConfig.Name or "Tab"
        tabConfig.Imageid = tabConfig.Imageid or ""

        local tabCount = #self.Tabs + 1
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, 0, 0, 32)
        tabButton.Position = UDim2.new(0, 0, 0, (tabCount - 1) * 37)
        tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        tabButton.Text = tabConfig.Name
        tabButton.TextColor3 = Color3.fromRGB(230, 230, 230)
        tabButton.TextScaled = true
        tabButton.Font = Enum.Font.GothamBold
        tabButton.AutoButtonColor = false
        tabButton.Parent = self.TabContainer
        Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 8)

        -- Add image to tab button if Imageid is provided
        if tabConfig.Imageid ~= "" then
            local tabImage = Instance.new("ImageLabel")
            tabImage.Size = UDim2.new(0, 20, 0, 20)
            tabImage.Position = UDim2.new(0, 5, 0.5, -10)
            tabImage.BackgroundTransparency = 1
            tabImage.Image = "rbxassetid://" .. tabConfig.Imageid
            tabImage.Parent = tabButton
            tabButton.TextXAlignment = Enum.TextXAlignment.Right
        end

        local tabContent = Instance.new("Frame")
        tabContent.Size = UDim2.new(1, 0, 0, 0) -- Height will adjust dynamically
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.Parent = self.ContentArea
        local tabListLayout = Instance.new("UIListLayout")
        tabListLayout.Padding = UDim.new(0, 5)
        tabListLayout.Parent = tabContent

        tabButton.MouseButton1Click:Connect(function()
            if self.CurrentTab ~= tabContent then
                if self.CurrentTab then
                    self.CurrentTab.Visible = false
                    self.Tabs[self.CurrentTab].Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                end
                tabContent.Visible = true
                tabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                self.CurrentTab = tabContent
            end
        end)

        self.Tabs[tabContent] = {
            Button = tabButton,
            Content = tabContent
        }

        -- Auto-select first tab
        if tabCount == 1 then
            tabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            tabContent.Visible = true
            self.CurrentTab = tabContent
        end

        -- UI Element Creation Functions
        function tabContent:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            btnConfig.Name = btnConfig.Name or "Button"
            btnConfig.Flag = btnConfig.Flag or "Button"
            btnConfig.Callfunction = btnConfig.Callfunction or function() end

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 30)
            button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            button.Text = btnConfig.Name
            button.TextColor3 = Color3.new(1, 1, 1)
            button.TextScaled = true
            button.Font = Enum.Font.Gotham
            button.Parent = self
            Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

            button.MouseButton1Click:Connect(function()
                btnConfig.Callfunction()
            end)

            -- Hover effect
            button.MouseEnter:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            end)
            button.MouseLeave:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
            end)

            return button
        end

        function tabContent:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            toggleConfig.Name = toggleConfig.Name or "Toggle"
            toggleConfig.Flag = toggleConfig.Flag or "Toggle"
            toggleConfig.Callfunction = toggleConfig.Callfunction or function() end

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, -10, 0, 30)
            toggleFrame.BackgroundTransparency = 1
            toggleFrame.Parent = self

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.8, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = toggleConfig.Name
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextScaled = true
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggleFrame

            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(0, 40, 0, 20)
            toggle.Position = UDim2.new(1, -40, 0.5, -10)
            toggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            toggle.Text = ""
            toggle.Parent = toggleFrame
            Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)

            local state = false
            toggle.MouseButton1Click:Connect(function()
                state = not state
                TweenService:Create(toggle, TweenInfo.new(0.2), {
                    BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
                }):Play()
                toggleConfig.Callfunction(state)
            end)

            return toggleFrame
        end

        function tabContent:CreateDropdown(dropConfig)
            dropConfig = dropConfig or {}
            dropConfig.Name = dropConfig.Name or "Dropdown"
            dropConfig.Flag = dropConfig.Flag or "Dropdown"
            dropConfig.Option = dropConfig.Option or {"None"}
            dropConfig.Muti = dropConfig.Muti or false
            dropConfig.Callfunction = dropConfig.Callfunction or function() end

            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(1, -10, 0, 30)
            dropdownFrame.BackgroundTransparency = 1
            dropdownFrame.Parent = self

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.8, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = dropConfig.Name
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextScaled = true
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = dropdownFrame

            local dropdownBtn = Instance.new("TextButton")
            dropdownBtn.Size = UDim2.new(0, 40, 0, 20)
            dropdownBtn.Position = UDim2.new(1, -40, 0.5, -10)
            dropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            dropdownBtn.Text = "▼"
            dropdownBtn.TextColor3 = Color3.new(1, 1, 1)
            dropdownBtn.TextScaled = true
            dropdownBtn.Font = Enum.Font.Gotham
            dropdownBtn.Parent = dropdownFrame
            Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 6)

            local dropdownMenu = Instance.new("Frame")
            dropdownMenu.Size = UDim2.new(1, -10, 0, 0)
            dropdownMenu.Position = UDim2.new(0, 0, 1, 5)
            dropdownMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            dropdownMenu.Visible = false
            dropdownMenu.Parent = dropdownFrame
            Instance.new("UICorner", dropdownMenu).CornerRadius = UDim.new(0, 6)

            local uiListLayout = Instance.new("UIListLayout")
            uiListLayout.Padding = UDim.new(0, 2)
            uiListLayout.Parent = dropdownMenu

            local selected = dropConfig.Muti and {} or dropConfig.Option[1]
            local function updateLabel()
                label.Text = dropConfig.Name .. ": " .. (dropConfig.Muti and table.concat(selected, ", ") or selected)
            end
            updateLabel()

            for i, option in ipairs(dropConfig.Option) do
                local optionBtn = Instance.new("TextButton")
                optionBtn.Size = UDim2.new(1, 0, 0, 20)
                optionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                optionBtn.Text = option
                optionBtn.TextColor3 = Color3.new(1, 1, 1)
                optionBtn.TextScaled = true
                optionBtn.Font = Enum.Font.Gotham
                optionBtn.Parent = dropdownMenu
                Instance.new("UICorner", optionBtn).CornerRadius = UDim.new(0, 4)

                optionBtn.MouseButton1Click:Connect(function()
                    if dropConfig.Muti then
                        if table.find(selected, option) then
                            table.remove(selected, table.find(selected, option))
                        else
                            table.insert(selected, option)
                        end
                    else
                        selected = option
                        dropdownMenu.Visible = false
                    end
                    updateLabel()
                    dropConfig.Callfunction(selected)
                end)
            end
            dropdownMenu.Size = UDim2.new(1, -10, 0, #dropConfig.Option * 22)

            dropdownBtn.MouseButton1Click:Connect(function()
                dropdownMenu.Visible = not dropdownMenu.Visible
            end)

            return dropdownFrame
        end

        function tabContent:CreateSlide(slideConfig)
            slideConfig = slideConfig or {}
            slideConfig.Name = slideConfig.Name or "Slider"
            slideConfig.Flag = slideConfig.Flag or "Slider"
            slideConfig.Min = slideConfig.Min or 0
            slideConfig.Max = slideConfig.Max or 100
            slideConfig.Add = slideConfig.Add or 1
            slideConfig.Callfunction = slideConfig.Callfunction or function() end

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, -10, 0, 50)
            sliderFrame.BackgroundTransparency = 1
            sliderFrame.Parent = self

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Text = slideConfig.Name .. ": " .. slideConfig.Min
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextScaled = true
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sliderFrame

            local slider = Instance.new("Frame")
            slider.Size = UDim2.new(1, 0, 0, 10)
            slider.Position = UDim2.new(0, 0, 0, 30)
            slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            slider.Parent = sliderFrame
            Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 5)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            fill.Parent = slider
            Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

            local dragging = false
            local value = slideConfig.Min
            slider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            slider.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mouseX = input.Position.X
                    local sliderPos = slider.AbsolutePosition.X
                    local sliderWidth = slider.AbsoluteSize.X
                    local ratio = math.clamp((mouseX - sliderPos) / sliderWidth, 0, 1)
                    value = math.floor(slideConfig.Min + ratio * (slideConfig.Max - slideConfig.Min))
                    value = math.floor(value / slideConfig.Add) * slideConfig.Add
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    label.Text = slideConfig.Name .. ": " .. value
                    slideConfig.Callfunction(value)
                end
            end)

            return sliderFrame
        end

        function tabContent:CreateInput(inputConfig)
            inputConfig = inputConfig or {}
            inputConfig.Name = inputConfig.Name or "Input"
            inputConfig.Flag = inputConfig.Flag or "Input"
            inputConfig.DefaultText = inputConfig.DefaultText or "Text here"
            inputConfig.RemoveText = inputConfig.RemoveText or false
            inputConfig.Callfunction = inputConfig.Callfunction or function() end

            local inputFrame = Instance.new("Frame")
            inputFrame.Size = UDim2.new(1, -10, 0, 30)
            inputFrame.BackgroundTransparency = 1
            inputFrame.Parent = self

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.4, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = inputConfig.Name
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextScaled = true
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = inputFrame

            local input = Instance.new("TextBox")
            input.Size = UDim2.new(0.6, 0, 0, 20)
            input.Position = UDim2.new(0.4, 0, 0.5, -10)
            input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            input.Text = ""
            input.PlaceholderText = inputConfig.DefaultText
            input.TextColor3 = Color3.new(1, 1, 1)
            input.TextScaled = true
            input.Font = Enum.Font.Gotham
            input.Parent = inputFrame
            Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

            input.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    inputConfig.Callfunction(input.Text)
                    if inputConfig.RemoveText then
                        input.Text = ""
                    end
                end
            end)

            return inputFrame
        end

        return tabContent
    end

    return win
end

return ui