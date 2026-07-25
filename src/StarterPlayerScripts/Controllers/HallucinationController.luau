--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local Config = require(ReplicatedStorage.Shared.Modules.SanityConfig)
local SoundKit = require(ReplicatedStorage.Shared.Modules.SoundKit)
local FlashlightState = require(ReplicatedStorage.Shared.Modules.FlashlightState)

local HC = Config.HALLUCINATION

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera :: Camera

local HallucinationController = {}

type Entity = {
	model: Model,
	triggered: boolean,
	breathing: Sound?,
}

local active: Entity? = nil
local checkAccum = 0
local connections: { RBXScriptConnection } = {}

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
		warn(`[Hallucination] missing rig ReplicatedStorage.Entities.{HC.ENTITY_NAME}`)
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
		local warned = SoundKit.playAt(Config.SOUNDS.WARN, primary)

		local function startBreathing()
			if active ~= entity or entity.triggered or entity.breathing or not model.Parent then
				return
			end
			entity.breathing = SoundKit.loop(Config.SOUNDS.MONSTER_BREATHING, primary)
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
	SoundKit.play2D(Config.SOUNDS.SCREAM)

	if FlashlightState.isOn() then
		dissipate(entity)
	else
		Net.FireServer("SanityScareHit")
		task.delay(HC.SCARE_DESPAWN_DELAY, function()
			if entity.model.Parent then
				destroyEntity(entity)
			end
		end)
	end
end

local function onRenderStep(dt: number)
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

local function onCharacterRemoving()
	if active then
		destroyEntity(active)
	end
end

function HallucinationController.Init()
	table.insert(
		connections,
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			camera = workspace.CurrentCamera :: Camera
		end)
	)
	table.insert(connections, player.CharacterRemoving:Connect(onCharacterRemoving))
end

function HallucinationController.Start()
	table.insert(connections, RunService.RenderStepped:Connect(onRenderStep))
end

function HallucinationController.Destroy()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if active then
		destroyEntity(active)
	end
end

return HallucinationController
