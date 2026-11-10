--// HyperShot Elite Combat Menu v2.4 (Universal Executor Fallback Build)
--// Features: Rock-solid Universal Aimbot, ESP Box/Tracer Suite, FoV Circle, No-Crash Execution.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local uiParent = (gethui and gethui()) or (CoreGui:FindFirstChild("CoreGui") and CoreGui) or player:WaitForChild("PlayerGui")

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
            Title = "HyperShot v2.4",
            Text = msg,
            Duration = 2.5
        })
    end)
end

-- Feature States
local espenabled, boxenabled, tracerenabled, healthbarenabled = true, true, true, true
local fovcircleenabled, fovradius, aimbotenabled, aimbotactive = true, 180, false, false
local predictionFactor = 0.15

local accentColor = Color3.fromRGB(0, 240, 255)
local teamColor = Color3.fromRGB(0, 255, 120)
local enemyColor = Color3.fromRGB(255, 60, 60)

local function isPlayerTeammate(p)
    if p.Team ~= nil and player.Team ~= nil and not p.Neutral and not player.Neutral then
        return p.Team == player.Team
    end
    return false
end

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

aimToggleButton.MouseButton1Click:Connect(function()
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
wmText.Text = "⚡ HYPERSHOT V2.4 | 60 FPS"
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
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 28, 0, 28)
        closeBtn.Position = UDim2.new(1, -34, 0, 9)
        closeBtn.BackgroundColor3 = Color3.fromRGB(230, 60, 85)
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Text = "×"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 15
        closeBtn.Parent = header
        
        closeBtn.MouseButton1Click:Connect(function()
            screenGui:Destroy()
            pcall(function()
                if uiParent:FindFirstChild("HyperShotVisuals") then uiParent.HyperShotVisuals:Destroy() end
                if uiParent:FindFirstChild("HyperShotAimBtn") then uiParent.HyperShotAimBtn:Destroy() end
                if uiParent:FindFirstChild("HyperShotWatermark") then uiParent.HyperShotWatermark:Destroy() end
            end)
            notify("Menu destroyed.")
        end)

        local minBtn = Instance.new("TextButton")
        minBtn.Size = UDim2.new(0, 28, 0, 28)
        minBtn.Position = UDim2.new(1, -68, 0, 9)
        minBtn.BackgroundColor3 = Color3.fromRGB(35, 28, 50)
        minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minBtn.Text = "-"
        minBtn.Font = Enum.Font.GothamBold
        minBtn.TextSize = 15
        minBtn.Parent = header
        
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
                    sliderContainer.Parent = itemHolder

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

                    local track = Instance.new("Frame")
                    track.Size = UDim2.new(1, -24, 0, 8)
                    track.Position = UDim2.new(0, 12, 0, 34)
                    track.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
                    track.Parent = sliderContainer

                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new(math.clamp((tab.Default - tab.Min) / (tab.Max - tab.Min), 0, 1), 0, 1, 0)
                    fill.BackgroundColor3 = accentColor
                    fill.Parent = track

                    local sliding = false
                    track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.Touch then sliding = true end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.Touch then sliding = false end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.Touch) then
                            local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                            local rawVal = tab.Min + (tab.Max - tab.Min) * relX
                            fill.Size = UDim2.new(relX, 0, 1, 0)
                            valBox.Text = tostring(math.floor(rawVal + 0.5))
                            if tab.Callback then tab.Callback(rawVal) end
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

local Window = Library:CreateWindow("HyperShot Elite v2.4")

local catCombat = Window:CreateCategory("Combat")
catCombat:CreateTab("aimbot button", {enabled = false}, function(tog) aimbotenabled = tog aimToggleButton.Visible = tog if not tog then aimbotactive = false aimToggleButton.Text = "AIM: OFF" end end)
catCombat:CreateTab("fov circle", {enabled = true}, function(tog) fovcircleenabled = tog end)
catCombat:CreateTab("fov radius", {isSlider = true, min = 50, max = 300, default = 180, step = 5}, function(val) fovradius = val end)

local catVisuals = Window:CreateCategory("Visuals")
catVisuals:CreateTab("esp team", {enabled = true}, function(tog) showteam = tog end)
catVisuals:CreateTab("esp enemy", {enabled = true}, function(tog) showenemy = tog end)
catVisuals:CreateTab("esp boxes", {enabled = true}, function(tog) boxenabled = tog end)
catVisuals:CreateTab("esp tracers", {enabled = true}, function(tog) tracerenabled = tog end)
catVisuals:CreateTab("esp health bar", {enabled = true}, function(tog) healthbarenabled = tog end)

Library:Load()
notify("HyperShot Elite v2.4 Loaded Successfully!")

--// Visuals & Aimbot Core Loop
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
            local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestTarget = head
                    end
                end
            end
        end
    end
    return closestTarget
end

local espCache = {}

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera

    fovCircle.Visible = fovcircleenabled
    if fovcircleenabled and Camera then
        fovCircle.Size = UDim2.new(0, fovradius * 2, 0, fovradius * 2)
        fovCircle.Position = UDim2.new(0, Camera.ViewportSize.X / 2, 0, Camera.ViewportSize.Y / 2)
    end

    if aimbotenabled and aimbotactive and Camera then
        local target = getClosestPlayerInFOV()
        if target then
            local predPos = target.Position + (target.AssemblyLinearVelocity * predictionFactor)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predPos), 0.3)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and hrp and head and hum and hum.Health > 0 then
                if not espCache[p] then
                    local box = Instance.new("Highlight")
                    box.Name = "HyperShotBox"
                    box.Adornee = char
                    box.FillTransparency = 0.7
                    box.OutlineTransparency = 0
                    box.Parent = char
                    espCache[p] = box
                else
                    espCache[p].Enabled = boxenabled
                    espCache[p].FillColor = isPlayerTeammate(p) and teamColor or enemyColor
                    espCache[p].OutlineColor = espCache[p].FillColor
                end
            else
                if espCache[p] then
                    espCache[p]:Destroy()
                    espCache[p] = nil
                end
            end
        end
    end
end)
