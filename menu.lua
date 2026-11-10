--// HyperShot Elite Combat Menu v2.2 (Minimize Button & Fixed Movement)
--// Features: Minimize/Maximize Header Button, ESP Tracers, Predictive Aimbot, Silent Bullet Redirection.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local uiParent = (gethui and gethui()) or (CoreGui:FindFirstChild("CoreGui") and CoreGui) or playerGui

-- Clean old instances
pcall(function()
    if uiParent:FindFirstChild("HyperShotMenu") then uiParent.HyperShotMenu:Destroy() end
    if uiParent:FindFirstChild("HyperShotVisuals") then uiParent.HyperShotVisuals:Destroy() end
    if uiParent:FindFirstChild("HyperShotAimBtn") then uiParent.HyperShotAimBtn:Destroy() end
    if uiParent:FindFirstChild("HyperShotWatermark") then uiParent.HyperShotWatermark:Destroy() end
end)

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "HyperShot v2.2",
            Text = msg,
            Duration = 2.5
        })
    end)
end

-- Feature States
local showteam, showenemy, espenabled, boxenabled, tracerenabled, healthbarenabled, showdist = true, true, true, true, true, true, true
local maxEspDistance = 1500
local norecoilenabled, rapidfireenabled, silentaimenabled = false, false, false
local fovcircleenabled, fovradius, aimbotenabled, aimbotactive, targetPartOption, aimbotSmoothing, predictionFactor = true, 160, false, false, "Head", 0.2, 0.18

local accentColor = Color3.fromRGB(0, 240, 255)
local teamColor = Color3.fromRGB(0, 255, 120)
local enemyColor = Color3.fromRGB(255, 60, 60)

local function isPlayerTeammate(p)
    if p.Team ~= nil and player.Team ~= nil and not p.Neutral and not player.Neutral then
        return p.Team == player.Team
    end
    return false
end

--// Silent Aim Hook
local oldNamecall
pcall(function()
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if silentaimenabled and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" or method == "Raycast") then
            local closestTarget = nil
            local shortestDist = fovradius
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and not isPlayerTeammate(p) and p.Character and p.Character:FindFirstChild(targetPartOption) then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local part = p.Character[targetPartOption]
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if dist < shortestDist then
                                shortestDist = dist
                                closestTarget = part
                            end
                        end
                    end
                end
            end

            if closestTarget then
                if method == "Raycast" and typeof(args[2]) == "Vector3" then
                    local origin = args[1]
                    local direction = (closestTarget.Position - origin).Unit * 1000
                    args[2] = direction
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end)

--// Floating Aimbot Button
local mobileGui = Instance.new("ScreenGui")
mobileGui.Name = "HyperShotAimBtn"
mobileGui.ResetOnSpawn = false
mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
mobileGui.Parent = uiParent

local aimToggleButton = Instance.new("TextButton")
aimToggleButton.Size = UDim2.new(0, 70, 0, 70)
aimToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
aimToggleButton.Position = UDim2.new(0.5, 0, 0.8, 0)
aimToggleButton.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
aimToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
aimToggleButton.Text = "AIM: OFF"
aimToggleButton.Font = Enum.Font.GothamBold
aimToggleButton.TextSize = 10
aimToggleButton.Active = true
aimToggleButton.Visible = false
aimToggleButton.Parent = mobileGui

local aimBtnCorner = Instance.new("UICorner")
aimBtnCorner.CornerRadius = UDim.new(1, 0)
aimBtnCorner.Parent = aimToggleButton

local aimBtnStroke = Instance.new("UIStroke")
aimBtnStroke.Color = Color3.fromRGB(255, 75, 75)
aimBtnStroke.Thickness = 2
aimBtnStroke.Parent = aimToggleButton

local dragging, dragStart, startPos
aimToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = aimToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.Touch) then
        local delta = input.Position - dragStart
        aimToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local clickTimer = 0
aimToggleButton.MouseButton1Down:Connect(function() clickTimer = tick() end)
aimToggleButton.MouseButton1Up:Connect(function()
    if tick() - clickTimer < 0.2 then
        aimbotactive = not aimbotactive
        if aimbotactive then
            aimToggleButton.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
            aimToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            aimBtnStroke.Color = accentColor
            aimToggleButton.Text = "AIM: ON"
            notify("HyperShot Aimbot Active")
        else
            aimToggleButton.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
            aimToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
            aimBtnStroke.Color = Color3.fromRGB(255, 75, 75)
            aimToggleButton.Text = "AIM: OFF"
            notify("HyperShot Aimbot Inactive")
        end
    end
end)

--// Watermark Overlay
local watermarkGui = Instance.new("ScreenGui")
watermarkGui.Name = "HyperShotWatermark"
watermarkGui.ResetOnSpawn = false
watermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
watermarkGui.Parent = uiParent

local watermarkFrame = Instance.new("Frame")
watermarkFrame.Size = UDim2.new(0, 210, 0, 28)
watermarkFrame.Position = UDim2.new(0, 15, 0, 15)
watermarkFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
watermarkFrame.BackgroundTransparency = 0.2
watermarkFrame.BorderSizePixel = 0
watermarkFrame.Parent = watermarkGui

local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 8)
wmCorner.Parent = watermarkFrame

local wmStroke = Instance.new("UIStroke")
wmStroke.Color = accentColor
wmStroke.Thickness = 1.2
wmStroke.Parent = watermarkFrame

local wmText = Instance.new("TextLabel")
wmText.Size = UDim2.new(1, 0, 1, 0)
wmText.BackgroundTransparency = 1
wmText.TextColor3 = Color3.fromRGB(240, 230, 255)
wmText.Font = Enum.Font.GothamBold
wmText.TextSize = 10
wmText.Text = "⚡ HYPERSHOT V2.2 | 60 FPS"
wmText.Parent = watermarkFrame

--// UI Library Framework
local Library = { Windows = {} }

function Library:CreateWindow(title)
    local window = { Title = title, Categories = {} }
    function window:CreateCategory(catName)
        local category = { Name = catName, Tabs = {} }
        function category:CreateTab(name, config, callback)
            table.insert(category.Tabs, {
                Name = name,
                State = config and config.enabled or false,
                Callback = callback,
                IsSlider = config and config.isSlider or false,
                Min = config and config.min or 0,
                Max = config and config.max or 100,
                Default = config and config.default or 50,
                Step = config and config.step or 1
            })
        end
        table.insert(window.Categories, category)
        return category
    end
    table.insert(Library.Windows, window)
    return window
end

function Library:Load()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HyperShotMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = uiParent
    
    for _, win in ipairs(self.Windows) do
        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 480, 0, 390)
        mainFrame.Position = UDim2.new(0.5, -240, 0.3, -195)
        mainFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 15)
        mainFrame.BackgroundTransparency = 0.05
        mainFrame.BorderSizePixel = 0
        mainFrame.Active = true
        mainFrame.Draggable = true
        mainFrame.Parent = screenGui
        
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 14)
        mainCorner.Parent = mainFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = accentColor
        stroke.Thickness = 1.8
        stroke.Transparency = 0.1
        stroke.Parent = mainFrame

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 46)
        header.BackgroundColor3 = Color3.fromRGB(16, 13, 24)
        header.BorderSizePixel = 0
        header.Parent = mainFrame

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 14)
        headerCorner.Parent = header

        local titleBar = Instance.new("TextLabel")
        titleBar.Size = UDim2.new(1, -100, 1, 0)
        titleBar.BackgroundTransparency = 1
        titleBar.TextColor3 = Color3.fromRGB(220, 190, 255)
        titleBar.Font = Enum.Font.GothamBold
        titleBar.TextSize = 13
        titleBar.TextXAlignment = Enum.TextXAlignment.Left
        titleBar.Position = UDim2.new(0, 16, 0, 0)
        titleBar.Text = "🎯 " .. string.upper(win.Title)
        titleBar.Parent = header
        
        -- Close Button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 28, 0, 28)
        closeBtn.Position = UDim2.new(1, -34, 0, 9)
        closeBtn.BackgroundColor3 = Color3.fromRGB(230, 60, 85)
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Text = "×"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 15
        closeBtn.Parent = header
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            screenGui:Destroy()
            pcall(function()
                if uiParent:FindFirstChild("HyperShotVisuals") then uiParent.HyperShotVisuals:Destroy() end
                if uiParent:FindFirstChild("HyperShotAimBtn") then uiParent.HyperShotAimBtn:Destroy() end
                if uiParent:FindFirstChild("HyperShotWatermark") then uiParent.HyperShotWatermark:Destroy() end
            end)
            notify("Menu destroyed.")
        end)

        -- Minimize Button
        local minBtn = Instance.new("TextButton")
        minBtn.Size = UDim2.new(0, 28, 0, 28)
        minBtn.Position = UDim2.new(1, -68, 0, 9)
        minBtn.BackgroundColor3 = Color3.fromRGB(35, 28, 50)
        minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minBtn.Text = "-"
        minBtn.Font = Enum.Font.GothamBold
        minBtn.TextSize = 15
        minBtn.Parent = header
        
        local minCorner = Instance.new("UICorner")
        minCorner.CornerRadius = UDim.new(0, 8)
        minCorner.Parent = minBtn

        local sidebar = Instance.new("ScrollingFrame")
        sidebar.Size = UDim2.new(0, 130, 1, -58)
        sidebar.Position = UDim2.new(0, 10, 0, 52)
        sidebar.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
        sidebar.BorderSizePixel = 0
        sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
        sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sidebar.ScrollBarThickness = 2
        sidebar.ScrollBarImageColor3 = accentColor
        sidebar.Parent = mainFrame

        local sideCorner = Instance.new("UICorner")
        sideCorner.CornerRadius = UDim.new(0, 10)
        sideCorner.Parent = sidebar

        local sideLayout = Instance.new("UIListLayout")
        sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sideLayout.Padding = UDim.new(0, 6)
        sideLayout.Parent = sidebar

        local contentContainer = Instance.new("ScrollingFrame")
        contentContainer.Size = UDim2.new(1, -152, 1, -58)
        contentContainer.Position = UDim2.new(0, 146, 0, 52)
        contentContainer.BackgroundTransparency = 1
        contentContainer.BorderSizePixel = 0
        contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        contentContainer.ScrollBarThickness = 3
        contentContainer.ScrollBarImageColor3 = accentColor
        contentContainer.Parent = mainFrame
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 6)
        contentLayout.Parent = contentContainer

        local minimized = false
        local previousSize = mainFrame.Size
        minBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            if minimized then
                previousSize = mainFrame.Size
                sidebar.Visible = false
                contentContainer.Visible = false
                mainFrame.Size = UDim2.new(0, previousSize.X.Offset, 0, 46)
                minBtn.Text = "+"
            else
                mainFrame.Size = previousSize
                sidebar.Visible = true
                contentContainer.Visible = true
                minBtn.Text = "-"
            end
        end)

        UserInputService.InputBegan:Connect(function(input, gp)
            if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
                mainFrame.Visible = not mainFrame.Visible
            end
        end)

        local categoryFrames = {}
        local categoryButtons = {}
        
        for _, cat in ipairs(win.Categories) do
            local cBtn = Instance.new("TextButton")
            cBtn.Size = UDim2.new(1, 0, 0, 34)
            cBtn.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
            cBtn.TextColor3 = Color3.fromRGB(160, 145, 185)
            cBtn.Text = cat.Name
            cBtn.Font = Enum.Font.GothamBold
            cBtn.TextSize = 11
            cBtn.Parent = sidebar
            
            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 8)
            cCorner.Parent = cBtn
            
            local itemHolder = Instance.new("Frame")
            itemHolder.Size = UDim2.new(1, 0, 0, 0)
            itemHolder.BackgroundTransparency = 1
            itemHolder.Visible = false
            itemHolder.AutomaticSize = Enum.AutomaticSize.Y
            itemHolder.Parent = contentContainer
            
            local itemLayout = Instance.new("UIListLayout")
            itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
            itemLayout.Padding = UDim.new(0, 6)
            itemLayout.Parent = itemHolder
            
            for idx, tab in ipairs(cat.Tabs) do
                if tab.IsSlider then
                    local sliderContainer = Instance.new("Frame")
                    sliderContainer.LayoutOrder = idx * 2
                    sliderContainer.Size = UDim2.new(1, 0, 0, 52)
                    sliderContainer.BackgroundColor3 = Color3.fromRGB(18, 15, 26)
                    sliderContainer.BorderSizePixel = 0
                    sliderContainer.Parent = itemHolder

                    local sCorner = Instance.new("UICorner")
                    sCorner.CornerRadius = UDim.new(0, 8)
                    sCorner.Parent = sliderContainer

                    local sLabel = Instance.new("TextLabel")
                    sLabel.Size = UDim2.new(1, -80, 0, 24)
                    sLabel.Position = UDim2.new(0, 12, 0, 4)
                    sLabel.BackgroundTransparency = 1
                    sLabel.TextColor3 = Color3.fromRGB(220, 210, 245)
                    sLabel.Font = Enum.Font.GothamBold
                    sLabel.TextSize = 11
                    sLabel.TextXAlignment = Enum.TextXAlignment.Left
                    sLabel.Text = tab.Name
                    sLabel.Parent = sliderContainer

                    local valBox = Instance.new("TextBox")
                    valBox.Size = UDim2.new(0, 60, 0, 22)
                    valBox.Position = UDim2.new(1, -68, 0, 5)
                    valBox.BackgroundColor3 = Color3.fromRGB(10, 8, 15)
                    valBox.TextColor3 = accentColor
                    valBox.Font = Enum.Font.GothamBold
                    valBox.TextSize = 11
                    valBox.Text = tostring(tab.Default)
                    valBox.Parent = sliderContainer

                    local vCorner = Instance.new("UICorner")
                    vCorner.CornerRadius = UDim.new(0, 6)
                    vCorner.Parent = valBox

                    local track = Instance.new("Frame")
                    track.Size = UDim2.new(1, -24, 0, 8)
                    track.Position = UDim2.new(0, 12, 0, 34)
                    track.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
                    track.BorderSizePixel = 0
                    track.Parent = sliderContainer

                    local tCorner = Instance.new("UICorner")
                    tCorner.CornerRadius = UDim.new(1, 0)
                    tCorner.Parent = track

                    local fill = Instance.new("Frame")
                    local initAlpha = math.clamp((tab.Default - tab.Min) / (tab.Max - tab.Min), 0, 1)
                    fill.Size = UDim2.new(initAlpha, 0, 1, 0)
                    fill.BackgroundColor3 = accentColor
                    fill.BorderSizePixel = 0
                    fill.Parent = track

                    local fCorner = Instance.new("UICorner")
                    fCorner.CornerRadius = UDim.new(1, 0)
                    fCorner.Parent = fill

                    local currentVal = tab.Default
                    local function setSliderValue(val)
                        local snapped = math.floor((val / tab.Step) + 0.5) * tab.Step
                        snapped = tonumber(string.format("%.2f", math.clamp(snapped, tab.Min, tab.Max)))
                        currentVal = snapped
                        local alpha = math.clamp((snapped - tab.Min) / (tab.Max - tab.Min), 0, 1)
                        fill.Size = UDim2.new(alpha, 0, 1, 0)
                        valBox.Text = tostring(snapped)
                        if tab.Callback then tab.Callback(snapped) end
                    end

                    local sliding = false
                    local function updateFromInput(input)
                        local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        local rawVal = tab.Min + (tab.Max - tab.Min) * relX
                        setSliderValue(rawVal)
                    end

                    track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.Touch then
                            sliding = true
                            updateFromInput(input)
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(input)
                        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.Touch) then
                            updateFromInput(input)
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.Touch then
                            sliding = false
                        end
                    end)
                else
                    local togButton = Instance.new("TextButton")
                    togButton.LayoutOrder = idx * 2
                    togButton.Size = UDim2.new(1, 0, 0, 36)
                    togButton.BackgroundColor3 = tab.State and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(18, 15, 26)
                    togButton.TextColor3 = tab.State and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 155, 195)
                    togButton.Text = "  " .. tab.Name .. " : " .. (tab.State and "ON" or "OFF")
                    togButton.TextXAlignment = Enum.TextXAlignment.Left
                    togButton.Font = Enum.Font.GothamBold
                    togButton.TextSize = 11
                    togButton.Parent = itemHolder
                    
                    local pad = Instance.new("UIPadding")
                    pad.PaddingLeft = UDim.new(0, 8)
                    pad.Parent = togButton

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = togButton
                    
                    local currentState = tab.State
                    togButton.MouseButton1Click:Connect(function()
                        currentState = not currentState
                        togButton.Text = "  " .. tab.Name .. " : " .. (currentState and "ON" or "OFF")
                        togButton.BackgroundColor3 = currentState and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(18, 15, 26)
                        togButton.TextColor3 = currentState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 155, 195)
                        if tab.Callback then tab.Callback(currentState) end
                    end)
                end
            end
            
            table.insert(categoryFrames, itemHolder)
            table.insert(categoryButtons, cBtn)
            
            cBtn.MouseButton1Click:Connect(function()
                for _, holder in ipairs(categoryFrames) do holder.Visible = false end
                for _, btn in ipairs(categoryButtons) do 
                    btn.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
                    btn.TextColor3 = Color3.fromRGB(160, 145, 185)
                end
                itemHolder.Visible = true
                cBtn.BackgroundColor3 = accentColor
                cBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end)
        end
        
        if categoryFrames[1] then
            categoryFrames[1].Visible = true
            categoryButtons[1].BackgroundColor3 = accentColor
            categoryButtons[1].TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

local Window = Library:CreateWindow("HyperShot Elite v2.2")

local catCombat = Window:CreateCategory("Combat")
catCombat:CreateTab("aimbot button", {enabled = false}, function(tog) aimbotenabled = tog aimToggleButton.Visible = tog if not tog then aimbotactive = false aimToggleButton.Text = "AIM: OFF" end end)
catCombat:CreateTab("silent bullet redirect", {enabled = false}, function(tog) silentaimenabled = tog notify("Silent Bullet: " .. (tog and "ON" or "OFF")) end)
catCombat:CreateTab("fov circle", {enabled = true}, function(tog) fovcircleenabled = tog end)
catCombat:CreateTab("fov radius", {isSlider = true, min = 50, max = 300, default = 160, step = 5}, function(val) fovradius = val end)
catCombat:CreateTab("prediction factor", {isSlider = true, min = 0, max = 0.5, default = 0.18, step = 0.01}, function(val) predictionFactor = val end)
catCombat:CreateTab("no recoil hook", {enabled = false}, function(tog) norecoilenabled = tog end)
catCombat:CreateTab("rapid fire hook", {enabled = false}, function(tog) rapidfireenabled = tog end)

local catVisuals = Window:CreateCategory("Visuals")
catVisuals:CreateTab("esp team", {enabled = true}, function(tog) showteam = tog end)
catVisuals:CreateTab("esp enemy", {enabled = true}, function(tog) showenemy = tog end)
catVisuals:CreateTab("esp names", {enabled = true}, function(tog) espenabled = tog end)
catVisuals:CreateTab("esp boxes", {enabled = true}, function(tog) boxenabled = tog end)
catVisuals:CreateTab("esp health bar", {enabled = true}, function(tog) healthbarenabled = tog end)
catVisuals:CreateTab("esp tracers", {enabled = true}, function(tog) tracerenabled = tog end)
catVisuals:CreateTab("distance tags", {enabled = true}, function(tog) showdist = tog end)

Library:Load()
notify("HyperShot Elite v2.2 Loaded!")

--// Visual Overlay Gui
local visualGui = Instance.new("ScreenGui")
visualGui.Name = "HyperShotVisuals"
visualGui.ResetOnSpawn = false
visualGui.IgnoreGuiInset = true
visualGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
visualGui.Parent = uiParent

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = visualGui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(0, 255, 200)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovAspect = Instance.new("UIAspectRatioConstraint")
fovAspect.AspectRatio = 1
fovAspect.Parent = fovCircle

local function getClosestPlayerInFOV()
    local closestTarget = nil
    local shortestDist = fovradius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and not isPlayerTeammate(p) then
            local char = p.Character
            local targetPart = char and char:FindFirstChild(targetPartOption)
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if screenDist < shortestDist then
                        shortestDist = screenDist
                        closestTarget = targetPart
                    end
                end
            end
        end
    end
    return closestTarget
end

local espCache = {}

local function removeESP(p)
    if espCache[p] then
        pcall(function() 
            if espCache[p].Billboard then espCache[p].Billboard:Destroy() end
            if espCache[p].TracerFrame then espCache[p].TracerFrame:Destroy() end
            if espCache[p].BoxTop then espCache[p].BoxTop:Destroy() end
            if espCache[p].BoxBottom then espCache[p].BoxBottom:Destroy() end
            if espCache[p].BoxLeft then espCache[p].BoxLeft:Destroy() end
            if espCache[p].BoxRight then espCache[p].BoxRight:Destroy() end
            if espCache[p].HealthBg then espCache[p].HealthBg:Destroy() end
            if espCache[p].HealthFill then espCache[p].HealthFill:Destroy() end
        end)
        espCache[p] = nil
    end
end

local function hideESP(cache)
    if not cache then return end
    if cache.Billboard then cache.Billboard.Enabled = false end
    if cache.TracerFrame then cache.TracerFrame.Visible = false end
    if cache.BoxTop then cache.BoxTop.Visible = false end
    if cache.BoxBottom then cache.BoxBottom.Visible = false end
    if cache.BoxLeft then cache.BoxLeft.Visible = false end
    if cache.BoxRight then cache.BoxRight.Visible = false end
    if cache.HealthBg then cache.HealthBg.Visible = false end
    if cache.HealthFill then cache.HealthFill.Visible = false end
end

Players.PlayerRemoving:Connect(removeESP)

local function createLine()
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = enemyColor
    line.BorderSizePixel = 0
    line.Visible = false
    line.Parent = visualGui
    return line
end

local function updatePlayerESP(p)
    if p == player then return end
    local char = p.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local head = char and char:FindFirstChild("Head")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if not char or not head or not hrp or not humanoid or humanoid.Health <= 0 then
        removeESP(p)
        return
    end

    local localChar = player.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if localHrp then
        local dist = (localHrp.Position - hrp.Position).Magnitude
        if dist > maxEspDistance then
            if espCache[p] then hideESP(espCache[p]) end
            return
        end
    else
        if espCache[p] then hideESP(espCache[p]) end
        return
    end
    
    if not espCache[p] then
        espCache[p] = {}
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HyperShotTag"
        billboard.Size = UDim2.new(0, 160, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3.2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = enemyColor
        textLabel.TextStrokeTransparency = 0
        textLabel.TextSize = 13
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Parent = billboard
        
        espCache[p].Billboard = billboard
        espCache[p].TextLabel = textLabel
        espCache[p].TracerFrame = createLine()
        espCache[p].BoxTop = createLine()
        espCache[p].BoxBottom = createLine()
        espCache[p].BoxLeft = createLine()
        espCache[p].BoxRight = createLine()

        local hbBg = Instance.new("Frame")
        hbBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        hbBg.BorderSizePixel = 0
        hbBg.Visible = false
        hbBg.Parent = visualGui
        espCache[p].HealthBg = hbBg

        local hbFill = Instance.new("Frame")
        hbFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        hbFill.BorderSizePixel = 0
        hbFill.Visible = false
        hbFill.Parent = visualGui
        espCache[p].HealthFill = hbFill
    end
    
    local cache = espCache[p]
    local isTeammate = isPlayerTeammate(p)
    if (isTeammate and not showteam) or (not isTeammate and not showenemy) then
        hideESP(cache)
        return
    end

    local activeColor = isTeammate and teamColor or enemyColor
    if cache.Billboard and cache.TextLabel then
        cache.Billboard.Enabled = espenabled
        cache.TextLabel.TextColor3 = activeColor
        if espenabled then
            local distStr = ""
            if localHrp and showdist then
                local dist = math.floor((localHrp.Position - hrp.Position).Magnitude)
                distStr = " [" .. dist .. "m]"
            end
            cache.TextLabel.Text = p.Name .. distStr
        end
    end

    Camera = workspace.CurrentCamera
    local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    
    if onScreen then
        if cache.TracerFrame then
            cache.TracerFrame.Visible = tracerenabled
            cache.TracerFrame.BackgroundColor3 = activeColor
            if tracerenabled then
                local screenBottomCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                local targetPos = Vector2.new(hrpPos.X, hrpPos.Y)
                local distance = (targetPos - screenBottomCenter).Magnitude
                cache.TracerFrame.Size = UDim2.new(0, distance, 0, 1.5)
                cache.TracerFrame.Position = UDim2.new(0, (screenBottomCenter.X + targetPos.X) / 2, 0, (screenBottomCenter.Y + targetPos.Y) / 2)
                cache.TracerFrame.Rotation = math.deg(math.atan2(targetPos.Y - screenBottomCenter.Y, targetPos.X - screenBottomCenter.X))
            end
        end

        if cache.BoxTop and cache.BoxBottom and cache.BoxLeft and cache.BoxRight then
            cache.BoxTop.Visible = boxenabled
            cache.BoxBottom.Visible = boxenabled
            cache.BoxLeft.Visible = boxenabled
            cache.BoxRight.Visible = boxenabled
            cache.BoxTop.BackgroundColor3 = activeColor
            cache.BoxBottom.BackgroundColor3 = activeColor
            cache.BoxLeft.BackgroundColor3 = activeColor
            cache.BoxRight.BackgroundColor3 = activeColor
            
            if boxenabled then
                local Victim_Head = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local Victim_Legs = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local boxSizeX = 2000 / hrpPos.Z
                local boxSizeY = math.abs(Victim_Legs.Y - Victim_Head.Y)
                local centerX = hrpPos.X
                local centerY = hrpPos.Y

                cache.BoxTop.Size = UDim2.new(0, boxSizeX, 0, 1.5)
                cache.BoxTop.Position = UDim2.new(0, centerX, 0, centerY - (boxSizeY / 2))
                cache.BoxBottom.Size = UDim2.new(0, boxSizeX, 0, 1.5)
                cache.BoxBottom.Position = UDim2.new(0, centerX, 0, centerY + (boxSizeY / 2))
                cache.BoxLeft.Size = UDim2.new(0, 1.5, 0, boxSizeY)
                cache.BoxLeft.Position = UDim2.new(0, centerX - (boxSizeX / 2), 0, centerY)
                cache.BoxRight.Size = UDim2.new(0, 1.5, 0, boxSizeY)
                cache.BoxRight.Position = UDim2.new(0, centerX + (boxSizeX / 2), 0, centerY)

                if cache.HealthBg and cache.HealthFill then
                    cache.HealthBg.Visible = healthbarenabled
                    cache.HealthFill.Visible = healthbarenabled
                    if healthbarenabled then
                        local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        local hbHeight = boxSizeY * hpPercent
                        cache.HealthBg.Size = UDim2.new(0, 3, 0, boxSizeY)
                        cache.HealthBg.Position = UDim2.new(0, centerX - (boxSizeX / 2) - 6, 0, centerY - (boxSizeY / 2))
                        
                        cache.HealthFill.Size = UDim2.new(0, 2, 0, hbHeight)
                        cache.HealthFill.Position = UDim2.new(0, centerX - (boxSizeX / 2) - 5, 0, centerY - (boxSizeY / 2) + (boxSizeY - hbHeight))
                        cache.HealthFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - hpPercent), 255 * hpPercent, 0)
                    end
                end
            end
        end
    else
        hideESP(cache)
    end
end

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera

    fovCircle.Visible = fovcircleenabled
    if fovcircleenabled and Camera then
        fovCircle.Size = UDim2.new(0, fovradius * 2, 0, fovradius * 2)
        fovCircle.Position = UDim2.new(0, Camera.ViewportSize.X / 2, 0, Camera.ViewportSize.Y / 2)
    end

    if aimbotenabled and aimbotactive and Camera then
        local targetPart = getClosestPlayerInFOV()
        if targetPart then
            local predictedPos = targetPart.Position + (targetPart.AssemblyLinearVelocity * predictionFactor)
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, predictedPos)
            if aimbotSmoothing <= 0 then
                Camera.CFrame = targetCFrame
            else
                Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 - aimbotSmoothing)
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then updatePlayerESP(p) end
    end
end)
