--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("SanityConfig") :: ModuleScript)
local FlashlightState = require(ReplicatedStorage:WaitForChild("FlashlightState") :: ModuleScript)

local HC = Config.HALLUCINATION

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera :: Camera
local remote = ReplicatedStorage:WaitForChild(Config.REMOTE) :: RemoteEvent

-- ==== sound (clones from SoundService so templates stay pristine) ====

local soundHolder = Instance.new("Folder")
soundHolder.Name = "SanitySounds2D"
soundHolder.Parent = SoundService

local function resolveSound(path: { string }): Instance?
	local node: Instance = SoundService
	for _, name in path do
		local child = node:FindFirstChild(name)
		if not child then
			warn(`[Sanity] missing SoundService.{table.concat(path, ".")}`)
			return nil
		end
		node = child
	end
	return node
end

local function cloneSound(path: { string }): Sound?
	local node = resolveSound(path)
	if not node then
		return nil
	end
	if node:IsA("Sound") then
		return node:Clone()
	end
	local pool = {}
	for _, child in node:GetChildren() do
		if child:IsA("Sound") then
			table.insert(pool, child)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[math.random(#pool)]:Clone()
end

local function playAt(path: { string }, parent: BasePart): Sound?
	local sound = cloneSound(path)
	if not sound then
		return nil
	end
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	return sound
end

local function play2D(path: { string })
	local sound = cloneSound(path)
	if not sound then
		return
	end
	sound.Parent = soundHolder
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

local function loopSound(path: { string }, parent: Instance?): Sound?
	local sound = cloneSound(path)
	if not sound then
		return nil
	end
	sound.Looped = true
	sound.Parent = parent or soundHolder
	sound:Play()
	return sound
end

-- ==== sanity value (smoothed for display) ====

local target = Config.START
local display = Config.START

-- ==== screen effects ====

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "SanityColorCorrection"
colorCorrection.Enabled = false
colorCorrection.Parent = Lighting

local blur = Instance.new("BlurEffect")
blur.Name = "SanityBlur"
blur.Size = 0
blur.Enabled = false
blur.Parent = Lighting

local playerBreathing = loopSound(Config.SOUNDS.PLAYER_BREATHING)
if playerBreathing then
	playerBreathing.Volume = 0
end
local heartbeat: Sound? = nil
if Config.SOUNDS.HEARTBEAT then
	heartbeat = loopSound(Config.SOUNDS.HEARTBEAT)
	if heartbeat then
		heartbeat.Volume = 0
	end
end

local function updateEffects(t: number)
	if t <= 0 then
		colorCorrection.Enabled = false
		blur.Enabled = false
		return
	end
	colorCorrection.Enabled = true
	blur.Enabled = true

	local fx = Config.EFFECTS
	blur.Size = t * fx.BLUR
	colorCorrection.Saturation = fx.SATURATION * t
	colorCorrection.Brightness = fx.BRIGHTNESS * t
	colorCorrection.Contrast = fx.CONTRAST * t
	colorCorrection.TintColor = Color3.new(1, 1, 1):Lerp(fx.TINT, t)
end

local function updateAudio(t: number)
	local pa = Config.PLAYER_AUDIO
	if playerBreathing then
		playerBreathing.Volume = t * pa.BREATHING_VOLUME
	end
	if heartbeat then
		heartbeat.Volume = t * pa.HEARTBEAT_VOLUME
		heartbeat.PlaybackSpeed = pa.PITCH_MIN + t * (pa.PITCH_MAX - pa.PITCH_MIN)
	end
end

-- ==== HUD bar (reuse an existing SanityUI, or build the default) ====

local fill: GuiObject? = nil
local ownsBar = false

local function buildBar(parent: Instance): GuiObject
	local ui = Config.UI
	local screen = Instance.new("ScreenGui")
	screen.Name = ui.SCREEN_NAME
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -24)
	bar.Size = UDim2.fromOffset(260, 16)
	bar.BackgroundColor3 = ui.BAR_BG
	bar.BorderSizePixel = 0
	bar.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = bar

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = ui.BAR_STROKE
	stroke.Parent = bar

	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "Fill"
	fillFrame.Size = UDim2.fromScale(1, 1)
	fillFrame.BackgroundColor3 = ui.BAR_FULL
	fillFrame.BorderSizePixel = 0
	fillFrame.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fillFrame

	screen.Parent = parent
	return fillFrame
end

local function setupBar()
	local playerGui = player:WaitForChild("PlayerGui")
	-- give a copied-in ScreenGui a moment to replicate from StarterGui
	local screen = playerGui:WaitForChild(Config.UI.SCREEN_NAME, 1)
	if screen then
		local found = screen:FindFirstChild("Fill", true)
		if found and found:IsA("GuiObject") then
			fill = found
			ownsBar = false
			return
		end
	end
	fill = buildBar(playerGui)
	ownsBar = true
end

local function updateBar(frac: number)
	local f = fill
	if f and f.Parent then
		f.Size = UDim2.fromScale(frac, 1)
		-- only recolor the bar we built; a custom UI keeps its own styling
		if ownsBar then
			f.BackgroundColor3 = Config.UI.BAR_FULL:Lerp(Config.UI.BAR_EMPTY, 1 - frac)
		end
	end
end

-- ==== hallucination ====

type Entity = {
	model: Model,
	triggered: boolean,
	breathing: Sound?,
}

local active: Entity? = nil
local checkAccum = 0

local function getRoot(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function pivotPosition(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return nil
end

local function isNearAnyLight(position: Vector3): boolean
	local radiusSq = HC.LIGHT_RADIUS * HC.LIGHT_RADIUS
	for _, light in CollectionService:GetTagged(Config.LIGHT_TAG) do
		local pos = pivotPosition(light)
		if pos then
			local d = position - pos
			if d:Dot(d) <= radiusSq then
				return true
			end
		end
	end
	return false
end

local function primaryOf(model: Model): BasePart?
	return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
end

local function destroyEntity(entity: Entity)
	if active == entity then
		active = nil
	end
	if entity.model.Parent then
		entity.model:Destroy()
	end
end

local function dissipate(entity: Entity)
	local model = entity.model
	local info = TweenInfo.new(HC.DISSIPATE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweens: { Tween } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local tween = TweenService:Create(part, info, { Transparency = 1 })
			tween:Play()
			table.insert(tweens, tween)
		end
	end
	if #tweens == 0 then
		destroyEntity(entity)
		return
	end
	tweens[1].Completed:Once(function()
		destroyEntity(entity)
	end)
end

local function trySpawn()
	if active then
		return
	end
	local root = getRoot()
	if not root then
		return
	end
	local rootPos = root.Position

	if isNearAnyLight(rootPos) then
		return
	end

	local sanity = player:GetAttribute(Config.ATTRIBUTE)
	local frac = if typeof(sanity) == "number" then sanity / Config.MAX else 1
	local chance = HC.BASE_CHANCE + (1 - frac) * HC.SANITY_BONUS
	if math.random() > chance then
		return
	end

	local entities = ReplicatedStorage:FindFirstChild("Entities")
	local template = entities and entities:FindFirstChild(HC.ENTITY_NAME)
	if not template or not template:IsA("Model") then
		warn(`[Sanity] missing rig ReplicatedStorage.Entities.{HC.ENTITY_NAME}`)
		return
	end

	local look = camera.CFrame.LookVector
	local back = Vector3.new(-look.X, 0, -look.Z)
	if back.Magnitude < 1e-3 then
		back = Vector3.new(0, 0, -1)
	end
	back = back.Unit

	local spread = (math.random() * 2 - 1) * HC.SPAWN_SPREAD
	local behind = CFrame.Angles(0, spread, 0) * back
	local distance = HC.SPAWN_MIN + math.random() * (HC.SPAWN_MAX - HC.SPAWN_MIN)
	local spawnPos = rootPos + behind * distance

	local lookTarget = Vector3.new(rootPos.X, spawnPos.Y, rootPos.Z)
	local spawnCFrame = CFrame.lookAt(spawnPos, lookTarget)

	local model = template:Clone()
	model:PivotTo(spawnCFrame)
	model.Parent = workspace

	local entity: Entity = { model = model, triggered = false, breathing = nil }
	active = entity

	local primary = primaryOf(model)
	if primary then
		local warned = playAt(Config.SOUNDS.WARN, primary)

		local function startBreathing()
			if active ~= entity or entity.triggered or entity.breathing or not model.Parent then
				return
			end
			entity.breathing = loopSound(Config.SOUNDS.MONSTER_BREATHING, primary)
		end

		if warned then
			warned.Ended:Once(startBreathing)
			task.delay(HC.BREATHING_FALLBACK, startBreathing)
		else
			startBreathing()
		end
	end
end

local function updateGaze()
	local entity = active
	if not entity or entity.triggered then
		return
	end
	local model = entity.model
	if not model.Parent then
		active = nil
		return
	end

	local entityPos = model:GetPivot().Position
	local camPos = camera.CFrame.Position

	local toEntity = entityPos - camPos
	if toEntity.Magnitude < 1e-3 then
		return
	end
	local dot = camera.CFrame.LookVector:Dot(toEntity.Unit)
	if dot < HC.GAZE_DOT then
		return
	end

	entity.triggered = true

	if entity.breathing then
		entity.breathing:Destroy()
		entity.breathing = nil
	end
	play2D(Config.SOUNDS.SCREAM)

	if FlashlightState.isOn() then
		dissipate(entity)
	else
		remote:FireServer()
		task.delay(HC.SCARE_DESPAWN_DELAY, function()
			if entity.model.Parent then
				destroyEntity(entity)
			end
		end)
	end
end

-- ==== main loop ====

local function onRenderStep(dt: number)
	local alpha = 1 - math.exp(-Config.SMOOTH_SPEED * dt)
	display += (target - display) * alpha
	if math.abs(target - display) < 0.01 then
		display = target
	end

	local frac = display / Config.MAX
	local t = math.clamp((Config.EFFECT_THRESHOLD - frac) / Config.EFFECT_THRESHOLD, 0, 1)
	updateBar(frac)
	updateEffects(t)
	updateAudio(t)

	if active then
		updateGaze()
	else
		checkAccum += dt
		if checkAccum >= HC.CHECK_INTERVAL then
			checkAccum = 0
			trySpawn()
		end
	end
end

-- ==== boot ====

local seed = player:GetAttribute(Config.ATTRIBUTE)
if typeof(seed) == "number" then
	target = seed
	display = seed
end

player:GetAttributeChangedSignal(Config.ATTRIBUTE):Connect(function()
	local value = player:GetAttribute(Config.ATTRIBUTE)
	if typeof(value) == "number" then
		target = value
	end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera :: Camera
end)

player.CharacterRemoving:Connect(function()
	if active then
		destroyEntity(active)
	end
end)

setupBar()
RunService.RenderStepped:Connect(onRenderStep)
