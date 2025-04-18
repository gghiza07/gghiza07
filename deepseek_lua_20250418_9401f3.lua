local Gghiza07UI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

function Gghiza07UI:CreateWindow(config)
    local window = {}
    
    -- ตั้งค่าพื้นฐาน
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- ลบ UI เก่าถ้ามี
    local existingUI = playerGui:FindFirstChild(config.Name or "Gghiza07UI")
    if existingUI then existingUI:Destroy() end
    
    -- สร้าง ScreenGui หลัก
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "Gghiza07UI"
    screenGui.Parent = playerGui
    screenGui.Enabled = true
    
    -- เฟรมหลัก
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.3, 0, 0.5, 0)
    mainFrame.Position = UDim2.new(0.35, 0, 0.25, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.Parent = screenGui
    
    -- ปุ่มปิด UI
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.Parent = mainFrame
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- ปุ่มเปิดปิด UI
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0, 10, 1, -60)
    toggleButton.Text = "ON"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
    toggleButton.Parent = screenGui
    
    local function toggleUI()
        screenGui.Enabled = not screenGui.Enabled
        toggleButton.Text = screenGui.Enabled and "ON" or "OFF"
        toggleButton.BackgroundColor3 = screenGui.Enabled and Color3.fromRGB(0, 123, 255) or Color3.fromRGB(100, 100, 100)
    end
    
    toggleButton.MouseButton1Click:Connect(toggleUI)
    
    -- ระบบ Tab
    local tabButtons = Instance.new("Frame")
    tabButtons.Size = UDim2.new(1, -20, 0, 40)
    tabButtons.Position = UDim2.new(0, 10, 0, 40)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = mainFrame
    
    local tabContents = Instance.new("Frame")
    tabContents.Size = UDim2.new(1, -20, 1, -90)
    tabContents.Position = UDim2.new(0, 10, 0, 90)
    tabContents.BackgroundTransparency = 1
    tabContents.Parent = mainFrame
    
    function window:CreateTab(tabName)
        local tab = {}
        local tabId = #tabButtons:GetChildren() + 1
        
        -- ปุ่ม Tab
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.Position = UDim2.new(0, (tabId-1)*110, 0, 0)
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabButton.Parent = tabButtons
        
        -- เนื้อหา Tab
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.ScrollBarThickness = 5
        tabContent.Parent = tabContents
        
        local uiListLayout = Instance.new("UIListLayout")
        uiListLayout.Padding = UDim.new(0, 10)
        uiListLayout.Parent = tabContent
        
        -- ฟังก์ชันสลับ Tab
        local function selectTab()
            for _, content in ipairs(tabContents:GetChildren()) do
                content.Visible = false
            end
            tabContent.Visible = true
            
            for _, button in ipairs(tabButtons:GetChildren()) do
                button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            tabButton.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
        end
        
        tabButton.MouseButton1Click:Connect(selectTab)
        
        -- เลือก Tab แรกโดยอัตโนมัติ
        if tabId == 1 then selectTab() end
        
        -- ฟังก์ชันสร้าง UI Elements
        function tab:CreateButton(btnConfig)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -20, 0, 40)
            button.Position = UDim2.new(0, 10, 0, #tabContent:GetChildren() * 50)
            button.Text = btnConfig.Name or "Button"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
            button.Parent = tabContent
            
            button.MouseButton1Click:Connect(function()
                if btnConfig.Callback then
                    pcall(btnConfig.Callback)
                end
            end)
            
            return button
        end
        
        function tab:CreateToggle(toggleConfig)
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, -20, 0, 40)
            toggleFrame.Position = UDim2.new(0, 10, 0, #tabContent:GetChildren() * 50)
            toggleFrame.BackgroundTransparency = 1
            toggleFrame.Parent = tabContent
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Text = toggleConfig.Name or "Toggle"
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = toggleFrame
            
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 50, 0, 25)
            toggleBtn.Position = UDim2.new(0.8, 0, 0.25, 0)
            toggleBtn.Text = ""
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            toggleBtn.Parent = toggleFrame
            
            local toggleCircle = Instance.new("Frame")
            toggleCircle.Size = UDim2.new(0, 20, 0, 20)
            toggleCircle.Position = UDim2.new(0, 2, 0, 2)
            toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleCircle.Parent = toggleBtn
            
            local isToggled = false
            
            local function updateToggle()
                if isToggled then
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
                    toggleCircle.Position = UDim2.new(0.5, 2, 0, 2)
                else
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                    toggleCircle.Position = UDim2.new(0, 2, 0, 2)
                end
                
                if toggleConfig.Callback then
                    pcall(toggleConfig.Callback, isToggled)
                end
            end
            
            toggleBtn.MouseButton1Click:Connect(function()
                isToggled = not isToggled
                updateToggle()
            end)
            
            updateToggle()
            
            return {
                Set = function(value)
                    isToggled = value
                    updateToggle()
                end,
                Get = function()
                    return isToggled
                end
            }
        end
        
        function tab:CreateSlider(sliderConfig)
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, -20, 0, 60)
            sliderFrame.Position = UDim2.new(0, 10, 0, #tabContent:GetChildren() * 50)
            sliderFrame.BackgroundTransparency = 1
            sliderFrame.Parent = tabContent
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.Text = sliderConfig.Name or "Slider"
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = sliderFrame
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0, 50, 0, 20)
            valueLabel.Position = UDim2.new(1, -50, 0, 0)
            valueLabel.Text = tostring(sliderConfig.Default or 0)
            valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Parent = sliderFrame
            
            local sliderBar = Instance.new("Frame")
            sliderBar.Size = UDim2.new(1, 0, 0, 10)
            sliderBar.Position = UDim2.new(0, 0, 0, 30)
            sliderBar.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
            sliderBar.Parent = sliderFrame
            
            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
            sliderFill.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
            sliderFill.Parent = sliderBar
            
            local minValue = sliderConfig.Min or 0
            local maxValue = sliderConfig.Max or 100
            local currentValue = sliderConfig.Default or minValue
            
            local function updateSlider()
                local percentage = (currentValue - minValue) / (maxValue - minValue)
                sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                valueLabel.Text = tostring(math.floor(currentValue))
                
                if sliderConfig.Callback then
                    pcall(sliderConfig.Callback, currentValue)
                end
            end
            
            local isDragging = false
            
            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = true
                end
            end)
            
            sliderBar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mousePos = input.Position.X
                    local sliderPos = sliderBar.AbsolutePosition.X
                    local sliderWidth = sliderBar.AbsoluteSize.X
                    local percentage = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
                    currentValue = minValue + (maxValue - minValue) * percentage
                    updateSlider()
                end
            end)
            
            updateSlider()
            
            return {
                Set = function(value)
                    currentValue = math.clamp(value, minValue, maxValue)
                    updateSlider()
                end,
                Get = function()
                    return currentValue
                end
            }
        end
        
        function tab:CreateDropdown(dropdownConfig)
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(1, -20, 0, 40)
            dropdownFrame.Position = UDim2.new(0, 10, 0, #tabContent:GetChildren() * 50)
            dropdownFrame.BackgroundTransparency = 1
            dropdownFrame.Parent = tabContent
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Text = dropdownConfig.Name or "Dropdown"
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = dropdownFrame
            
            local dropdownBtn = Instance.new("TextButton")
            dropdownBtn.Size = UDim2.new(0, 100, 0, 25)
            dropdownBtn.Position = UDim2.new(0.8, 0, 0.25, 0)
            dropdownBtn.Text = dropdownConfig.Default or "Select"
            dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            dropdownBtn.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
            dropdownBtn.Parent = dropdownFrame
            
            local dropdownList = Instance.new("ScrollingFrame")
            dropdownList.Size = UDim2.new(0, 100, 0, 0)
            dropdownList.Position = UDim2.new(0.8, 0, 0.25, 25)
            dropdownList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            dropdownList.Visible = false
            dropdownList.ScrollBarThickness = 5
            dropdownList.Parent = dropdownFrame
            
            local uiListLayout = Instance.new("UIListLayout")
            uiListLayout.Parent = dropdownList
            
            local selectedOption = dropdownConfig.Default or "Select"
            
            local function updateDropdown()
                for _, child in ipairs(dropdownList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                
                local listHeight = 0
                for _, option in ipairs(dropdownConfig.Options or {}) do
                    local optionBtn = Instance.new("TextButton")
                    optionBtn.Size = UDim2.new(1, 0, 0, 25)
                    optionBtn.Text = tostring(option)
                    optionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    optionBtn.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
                    optionBtn.Parent = dropdownList
                    
                    optionBtn.MouseButton1Click:Connect(function()
                        selectedOption = option
                        dropdownBtn.Text = selectedOption
                        dropdownList.Visible = false
                        
                        if dropdownConfig.Callback then
                            pcall(dropdownConfig.Callback, selectedOption)
                        end
                    end)
                    
                    listHeight = listHeight + 25
                end
                
                dropdownList.CanvasSize = UDim2.new(0, 0, 0, listHeight)
                dropdownList.Size = UDim2.new(0, 100, 0, math.min(listHeight, 100))
            end
            
            dropdownBtn.MouseButton1Click:Connect(function()
                dropdownList.Visible = not dropdownList.Visible
            end)
            
            updateDropdown()
            
            return {
                Set = function(option)
                    if table.find(dropdownConfig.Options or {}, option) then
                        selectedOption = option
                        dropdownBtn.Text = selectedOption
                    end
                end,
                Get = function()
                    return selectedOption
                end
            }
        end
        
        function tab:CreateInput(inputConfig)
            local inputFrame = Instance.new("Frame")
            inputFrame.Size = UDim2.new(1, -20, 0, 40)
            inputFrame.Position = UDim2.new(0, 10, 0, #tabContent:GetChildren() * 50)
            inputFrame.BackgroundTransparency = 1
            inputFrame.Parent = tabContent
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Text = inputConfig.Name or "Input"
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = inputFrame
            
            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0, 100, 0, 25)
            textBox.Position = UDim2.new(0.8, 0, 0.25, 0)
            textBox.Text = inputConfig.Default or ""
            textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            textBox.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
            textBox.ClearTextOnFocus = false
            textBox.Parent = inputFrame
            
            textBox.FocusLost:Connect(function(enterPressed)
                if enterPressed and inputConfig.Callback then
                    pcall(inputConfig.Callback, textBox.Text)
                end
            end)
            
            return {
                Set = function(text)
                    textBox.Text = text or ""
                end,
                Get = function()
                    return textBox.Text
                end
            }
        end
        
        return tab
    end
    
    return window
end

return Gghiza07UI