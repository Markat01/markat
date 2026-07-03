local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = localPlayer:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("AimAssistGui")
if oldGui then
	oldGui:Destroy()
end

local FOV_RADIUS = 120
local MIN_RADIUS = 40
local MAX_RADIUS = 350
local HOLD_KEY = Enum.UserInputType.MouseButton2

local aimbotEnabled = true
local teamCheckEnabled = false
local teamListOpen = true
local aiming = false
local currentTarget = nil
local panelVisible = true
local isTweening = false
local isTeamTweening = false

local allowedTeams = {}
local teamRows = {}
local teamButtons = {}
local defaultTransparency = {}

local gui = Instance.new("ScreenGui")
gui.Name = "AimAssistGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 0
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Parent = gui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.2
stroke.Parent = circle

local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.fromOffset(240, 205)
panel.Position = UDim2.fromOffset(30, 120)
panel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.ZIndex = 5
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 1
panelStroke.Color = Color3.fromRGB(150, 160, 180)
panelStroke.Transparency = 0.25
panelStroke.Parent = panel

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 40, 48)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 13, 17))
})
panelGradient.Rotation = 90
panelGradient.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "DragTitle"
title.Size = UDim2.new(1, -55, 0, 32)
title.Position = UDim2.fromOffset(12, 6)
title.BackgroundTransparency = 1
title.Text = "Aim Assist"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextTransparency = 0
title.TextStrokeTransparency = 1
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 7
title.Parent = panel

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.fromOffset(30, 26)
minimizeButton.Position = UDim2.new(1, -40, 0, 8)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.BackgroundTransparency = 0.76
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextTransparency = 0
minimizeButton.TextStrokeTransparency = 1
minimizeButton.TextSize = 20
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.BorderSizePixel = 0
minimizeButton.ZIndex = 7
minimizeButton.Parent = panel

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeButton

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, -24, 0, 34)
toggleButton.Position = UDim2.fromOffset(12, 44)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundTransparency = 0.76
toggleButton.Text = "Aimbot: ON"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextTransparency = 0
toggleButton.TextStrokeTransparency = 1
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.ZIndex = 7
toggleButton.Parent = panel

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = toggleButton

local teamButton = Instance.new("TextButton")
teamButton.Name = "TeamButton"
teamButton.Size = UDim2.new(1, -24, 0, 34)
teamButton.Position = UDim2.fromOffset(12, 86)
teamButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
teamButton.BackgroundTransparency = 0.76
teamButton.Text = "Reconhecer Time: OFF"
teamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teamButton.TextTransparency = 0
teamButton.TextStrokeTransparency = 1
teamButton.TextSize = 14
teamButton.Font = Enum.Font.GothamBold
teamButton.BorderSizePixel = 0
teamButton.ZIndex = 7
teamButton.Parent = panel

local teamCorner = Instance.new("UICorner")
teamCorner.CornerRadius = UDim.new(0, 7)
teamCorner.Parent = teamButton

local function applyGlassButton(button)
	local glassStroke = Instance.new("UIStroke")
	glassStroke.Thickness = 1.5
	glassStroke.Color = Color3.fromRGB(255, 255, 255)
	glassStroke.Transparency = 0.45
	glassStroke.Parent = button

	local glassGradient = Instance.new("UIGradient")
	glassGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(210, 215, 225)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 125, 135))
	})
	glassGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.58),
		NumberSequenceKeypoint.new(0.5, 0.74),
		NumberSequenceKeypoint.new(1, 0.88)
	})
	glassGradient.Rotation = 90
	glassGradient.Parent = button
end

applyGlassButton(toggleButton)
applyGlassButton(teamButton)
applyGlassButton(minimizeButton)

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, -24, 0, 22)
valueLabel.Position = UDim2.fromOffset(12, 130)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "Range: " .. FOV_RADIUS
valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
valueLabel.TextTransparency = 0
valueLabel.TextStrokeTransparency = 1
valueLabel.TextSize = 14
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.ZIndex = 7
valueLabel.Parent = panel

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(1, -24, 0, 8)
sliderBack.Position = UDim2.fromOffset(12, 168)
sliderBack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderBack.BackgroundTransparency = 0.78
sliderBack.BorderSizePixel = 0
sliderBack.ZIndex = 7
sliderBack.Parent = panel

local sliderBackCorner = Instance.new("UICorner")
sliderBackCorner.CornerRadius = UDim.new(1, 0)
sliderBackCorner.Parent = sliderBack

local sliderFill = Instance.new("Frame")
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderFill.BackgroundTransparency = 0.08
sliderFill.BorderSizePixel = 0
sliderFill.ZIndex = 8
sliderFill.Parent = sliderBack

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.fromOffset(18, 18)
sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderButton.Text = ""
sliderButton.TextTransparency = 0
sliderButton.TextStrokeTransparency = 1
sliderButton.BorderSizePixel = 0
sliderButton.ZIndex = 9
sliderButton.Parent = sliderBack

local sliderButtonCorner = Instance.new("UICorner")
sliderButtonCorner.CornerRadius = UDim.new(1, 0)
sliderButtonCorner.Parent = sliderButton

local teamListPanel = Instance.new("Frame")
teamListPanel.Name = "TeamListPanel"
teamListPanel.Size = UDim2.fromOffset(205, 205)
teamListPanel.Position = UDim2.fromOffset(panel.Position.X.Offset + 250, panel.Position.Y.Offset)
teamListPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
teamListPanel.BackgroundTransparency = 0.06
teamListPanel.BorderSizePixel = 0
teamListPanel.ClipsDescendants = true
teamListPanel.ZIndex = 3
teamListPanel.Parent = gui

local teamListCorner = Instance.new("UICorner")
teamListCorner.CornerRadius = UDim.new(0, 10)
teamListCorner.Parent = teamListPanel

local teamListStroke = Instance.new("UIStroke")
teamListStroke.Thickness = 1
teamListStroke.Color = Color3.fromRGB(150, 160, 180)
teamListStroke.Transparency = 0.28
teamListStroke.Parent = teamListPanel

local teamListGradient = Instance.new("UIGradient")
teamListGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 36, 44)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 15))
})
teamListGradient.Rotation = 90
teamListGradient.Parent = teamListPanel

local teamListTitle = Instance.new("TextLabel")
teamListTitle.Size = UDim2.new(1, -50, 0, 30)
teamListTitle.Position = UDim2.fromOffset(10, 6)
teamListTitle.BackgroundTransparency = 1
teamListTitle.Text = "Times"
teamListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
teamListTitle.TextTransparency = 0
teamListTitle.TextStrokeTransparency = 1
teamListTitle.TextSize = 14
teamListTitle.Font = Enum.Font.GothamBold
teamListTitle.TextXAlignment = Enum.TextXAlignment.Left
teamListTitle.ZIndex = 5
teamListTitle.Parent = teamListPanel

local teamMinimizeButton = Instance.new("TextButton")
teamMinimizeButton.Name = "TeamMinimizeButton"
teamMinimizeButton.Size = UDim2.fromOffset(30, 24)
teamMinimizeButton.Position = UDim2.new(1, -38, 0, 8)
teamMinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
teamMinimizeButton.BackgroundTransparency = 0.76
teamMinimizeButton.Text = "-"
teamMinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teamMinimizeButton.TextTransparency = 0
teamMinimizeButton.TextStrokeTransparency = 1
teamMinimizeButton.TextSize = 20
teamMinimizeButton.Font = Enum.Font.GothamBold
teamMinimizeButton.BorderSizePixel = 0
teamMinimizeButton.ZIndex = 5
teamMinimizeButton.Parent = teamListPanel

local teamMinimizeCorner = Instance.new("UICorner")
teamMinimizeCorner.CornerRadius = UDim.new(0, 6)
teamMinimizeCorner.Parent = teamMinimizeButton

applyGlassButton(teamMinimizeButton)

local teamScroll = Instance.new("ScrollingFrame")
teamScroll.Size = UDim2.new(1, -12, 1, -44)
teamScroll.Position = UDim2.fromOffset(6, 38)
teamScroll.BackgroundTransparency = 1
teamScroll.BorderSizePixel = 0
teamScroll.ScrollBarThickness = 4
teamScroll.CanvasSize = UDim2.fromOffset(0, 0)
teamScroll.ZIndex = 5
teamScroll.Parent = teamListPanel

local teamLayout = Instance.new("UIListLayout")
teamLayout.Padding = UDim.new(0, 6)
teamLayout.SortOrder = Enum.SortOrder.LayoutOrder
teamLayout.Parent = teamScroll

local function saveTransparency(object)
	if object:IsA("GuiObject") then
		defaultTransparency[object] = {
			BackgroundTransparency = object.BackgroundTransparency
		}

		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			defaultTransparency[object].TextTransparency = object.TextTransparency
			defaultTransparency[object].TextStrokeTransparency = object.TextStrokeTransparency
		end

		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			defaultTransparency[object].ImageTransparency = object.ImageTransparency
		end
	end

	if object:IsA("UIStroke") then
		defaultTransparency[object] = {
			Transparency = object.Transparency
		}
	end
end

local function saveTransparencyTree(root)
	saveTransparency(root)

	for _, object in ipairs(root:GetDescendants()) do
		saveTransparency(object)
	end
end

local function getTeamOpenPosition()
	return UDim2.fromOffset(
		panel.Position.X.Offset + panel.AbsoluteSize.X + 10,
		panel.Position.Y.Offset
	)
end

local function getTeamHiddenPosition()
	return UDim2.fromOffset(
		panel.Position.X.Offset + 22,
		panel.Position.Y.Offset + 18
	)
end

local function syncTeamListPosition()
	if teamListOpen then
		teamListPanel.Position = getTeamOpenPosition()
	else
		teamListPanel.Position = getTeamHiddenPosition()
	end
end

local function updateTeamButtonVisual(button, enabled)
	if enabled then
		button.Text = "ON"
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextTransparency = 0
		button.TextStrokeTransparency = 1
		button.BackgroundTransparency = 0.72
	else
		button.Text = "OFF"
		button.TextColor3 = Color3.fromRGB(225, 225, 225)
		button.TextTransparency = 0
		button.TextStrokeTransparency = 1
		button.BackgroundTransparency = 0.88
	end
end

local function updateTeamCanvas()
	teamScroll.CanvasSize = UDim2.fromOffset(0, teamLayout.AbsoluteContentSize.Y + 8)
end

local function createTeamRow(team)
	if teamRows[team.Name] then
		return
	end

	allowedTeams[team.Name] = true

	local row = Instance.new("Frame")
	row.Name = team.Name
	row.Size = UDim2.new(1, -6, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = 0.88
	row.BorderSizePixel = 0
	row.ZIndex = 5
	row.Parent = teamScroll

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 7)
	rowCorner.Parent = row

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Thickness = 1
	rowStroke.Color = Color3.fromRGB(255, 255, 255)
	rowStroke.Transparency = 0.72
	rowStroke.Parent = row

	local teamName = Instance.new("TextLabel")
	teamName.Size = UDim2.new(1, -62, 1, 0)
	teamName.Position = UDim2.fromOffset(8, 0)
	teamName.BackgroundTransparency = 1
	teamName.Text = team.Name
	teamName.TextColor3 = team.TeamColor.Color
	teamName.TextTransparency = 0
	teamName.TextStrokeTransparency = 1
	teamName.TextSize = 13
	teamName.Font = Enum.Font.GothamBold
	teamName.TextXAlignment = Enum.TextXAlignment.Left
	teamName.TextTruncate = Enum.TextTruncate.AtEnd
	teamName.ZIndex = 6
	teamName.Parent = row

	local selectButton = Instance.new("TextButton")
	selectButton.Size = UDim2.fromOffset(48, 24)
	selectButton.Position = UDim2.new(1, -54, 0.5, -12)
	selectButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.BorderSizePixel = 0
	selectButton.Font = Enum.Font.GothamBold
	selectButton.TextSize = 12
	selectButton.TextTransparency = 0
	selectButton.TextStrokeTransparency = 1
	selectButton.ZIndex = 6
	selectButton.Parent = row

	local selectCorner = Instance.new("UICorner")
	selectCorner.CornerRadius = UDim.new(0, 6)
	selectCorner.Parent = selectButton

	local selectStroke = Instance.new("UIStroke")
	selectStroke.Thickness = 1
	selectStroke.Color = Color3.fromRGB(255, 255, 255)
	selectStroke.Transparency = 0.55
	selectStroke.Parent = selectButton

	teamRows[team.Name] = row
	teamButtons[team.Name] = selectButton

	updateTeamButtonVisual(selectButton, allowedTeams[team.Name])

	selectButton.MouseButton1Click:Connect(function()
		allowedTeams[team.Name] = not allowedTeams[team.Name]
		currentTarget = nil
		updateTeamButtonVisual(selectButton, allowedTeams[team.Name])
	end)

	saveTransparencyTree(row)
	updateTeamCanvas()
end

local function removeTeamRow(team)
	local row = teamRows[team.Name]

	if row then
		row:Destroy()
	end

	teamRows[team.Name] = nil
	teamButtons[team.Name] = nil
	allowedTeams[team.Name] = nil

	updateTeamCanvas()
end

local function refreshTeams()
	for _, team in ipairs(Teams:GetChildren()) do
		if team:IsA("Team") then
			createTeamRow(team)
		end
	end
end

teamLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTeamCanvas)

Teams.ChildAdded:Connect(function(child)
	if child:IsA("Team") then
		createTeamRow(child)
	end
end)

Teams.ChildRemoved:Connect(function(child)
	if child:IsA("Team") then
		removeTeamRow(child)
	end
end)

refreshTeams()
syncTeamListPosition()

saveTransparencyTree(panel)
saveTransparencyTree(teamListPanel)

local function tweenObjectTransparency(object, show)
	local values = defaultTransparency[object]
	if not values or object.Parent == nil then
		return
	end

	local goal = {}

	if object:IsA("GuiObject") then
		goal.BackgroundTransparency = show and values.BackgroundTransparency or 1

		if values.TextTransparency ~= nil then
			goal.TextTransparency = show and values.TextTransparency or 1
		end

		if values.TextStrokeTransparency ~= nil then
			goal.TextStrokeTransparency = show and values.TextStrokeTransparency or 1
		end

		if values.ImageTransparency ~= nil then
			goal.ImageTransparency = show and values.ImageTransparency or 1
		end
	elseif object:IsA("UIStroke") then
		goal.Transparency = show and values.Transparency or 1
	end

	TweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function tweenTreeTransparency(root, show)
	tweenObjectTransparency(root, show)

	for _, object in ipairs(root:GetDescendants()) do
		tweenObjectTransparency(object, show)
	end
end

local function tweenTeamList(show)
	if isTeamTweening then
		return
	end

	isTeamTweening = true

	local openPosition = getTeamOpenPosition()
	local hiddenPosition = getTeamHiddenPosition()

	if show then
		teamListOpen = true
		teamListPanel.Visible = true
		teamListPanel.ZIndex = 3
		teamListPanel.Position = hiddenPosition
		teamListPanel.Size = UDim2.fromOffset(190, 190)
		tweenTreeTransparency(teamListPanel, true)

		TweenService:Create(
			teamListPanel,
			TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				Position = openPosition,
				Size = UDim2.fromOffset(205, 205)
			}
		):Play()
	else
		teamListOpen = false
		tweenTreeTransparency(teamListPanel, false)

		TweenService:Create(
			teamListPanel,
			TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{
				Position = hiddenPosition,
				Size = UDim2.fromOffset(170, 170)
			}
		):Play()
	end

	task.delay(0.34, function()
		teamListPanel.Visible = show
		isTeamTweening = false
	end)
end

teamMinimizeButton.MouseButton1Click:Connect(function()
	tweenTeamList(false)
end)

local function tweenPanel(show)
	if isTweening then
		return
	end

	isTweening = true

	if show then
		panel.Visible = true

		if teamListOpen then
			teamListPanel.Visible = true
		end
	end

	tweenTreeTransparency(panel, show)

	if teamListOpen then
		tweenTreeTransparency(teamListPanel, show)
	end

	task.delay(0.27, function()
		panelVisible = show
		panel.Visible = show

		if teamListOpen then
			teamListPanel.Visible = show
		else
			teamListPanel.Visible = false
		end

		isTweening = false
	end)
end

local function togglePanel()
	tweenPanel(not panelVisible)
end

minimizeButton.MouseButton1Click:Connect(togglePanel)

local function updateToggleButton()
	if aimbotEnabled then
		toggleButton.Text = "Aimbot: ON"
		stroke.Transparency = 0.2
	else
		toggleButton.Text = "Aimbot: OFF"
		stroke.Color = Color3.fromRGB(150, 150, 150)
		stroke.Transparency = 0.45
	end

	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextTransparency = 0
	toggleButton.TextStrokeTransparency = 1
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.BackgroundTransparency = 0.76
end

local function updateTeamButton()
	if teamCheckEnabled then
		teamButton.Text = "Reconhecer Time: ON"
	else
		teamButton.Text = "Reconhecer Time: OFF"
	end

	teamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamButton.TextTransparency = 0
	teamButton.TextStrokeTransparency = 1
	teamButton.Font = Enum.Font.GothamBold
	teamButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	teamButton.BackgroundTransparency = 0.76
end

toggleButton.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	currentTarget = nil
	updateToggleButton()
end)

teamButton.MouseButton1Click:Connect(function()
	teamCheckEnabled = not teamCheckEnabled
	currentTarget = nil
	updateTeamButton()
end)

local function updateCircleSize()
	circle.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
	valueLabel.Text = "Range: " .. math.floor(FOV_RADIUS)

	local percent = (FOV_RADIUS - MIN_RADIUS) / (MAX_RADIUS - MIN_RADIUS)
	sliderFill.Size = UDim2.fromScale(percent, 1)
	sliderButton.Position = UDim2.fromScale(percent, 0.5)
end

local draggingPanel = false
local draggingSlider = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingPanel = true
		dragStart = input.Position
		startPos = panel.Position
	end
end)

local function setSliderFromMouse()
	local mouseX = UserInputService:GetMouseLocation().X
	local sliderX = sliderBack.AbsolutePosition.X
	local sliderWidth = sliderBack.AbsoluteSize.X

	local percent = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
	FOV_RADIUS = MIN_RADIUS + ((MAX_RADIUS - MIN_RADIUS) * percent)

	updateCircleSize()
end

sliderBack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
		draggingPanel = false
		setSliderFromMouse()
	end
end)

sliderButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
		draggingPanel = false
		setSliderFromMouse()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingPanel = false
		draggingSlider = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	if draggingSlider then
		setSliderFromMouse()
	elseif draggingPanel then
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)

		syncTeamListPosition()
	end
end)

local function isValidTarget(player)
	if player == localPlayer then
		return false
	end

	if teamCheckEnabled and player.Team == localPlayer.Team then
		return false
	end

	if player.Team then
		local allowed = allowedTeams[player.Team.Name]

		if allowed == false then
			return false
		end
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")

	return humanoid and humanoid.Health > 0 and head ~= nil
end

local function getClosestTarget()
	local mousePos = UserInputService:GetMouseLocation()
	local closestPlayer = nil
	local shortestDistance = FOV_RADIUS

	for _, player in ipairs(Players:GetPlayers()) do
		if isValidTarget(player) then
			local head = player.Character.Head
			local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)

			if onScreen then
				local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

				if distance < shortestDistance then
					shortestDistance = distance
					closestPlayer = player
				end
			end
		end
	end

	return closestPlayer
end

local function aimAtTarget(target)
	local character = target.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	camera.CFrame = CFrame.lookAt(camera.CFrame.Position, head.Position)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.K then
		if not panelVisible then
			tweenPanel(true)
		else
			tweenPanel(false)
		end

		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		if panelVisible then
			tweenTeamList(not teamListOpen)
		end

		return
	end

	if input.UserInputType == HOLD_KEY then
		aiming = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == HOLD_KEY then
		aiming = false
		currentTarget = nil
	end
end)

RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()
	circle.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)

	if not aimbotEnabled then
		stroke.Color = Color3.fromRGB(150, 150, 150)
		return
	end

	if aiming then
		currentTarget = getClosestTarget()

		if currentTarget then
			aimAtTarget(currentTarget)
			stroke.Color = Color3.fromRGB(255, 80, 80)
		else
			stroke.Color = Color3.fromRGB(255, 255, 255)
		end
	else
		stroke.Color = Color3.fromRGB(255, 255, 255)
	end
end)

updateCircleSize()
updateToggleButton()
updateTeamButton()
