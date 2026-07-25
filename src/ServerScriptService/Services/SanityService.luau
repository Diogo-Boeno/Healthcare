--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local Config = require(ReplicatedStorage.Shared.Modules.SanityConfig)

local SanityService = {}

type Record = {
	sanity: number,
	pushed: number,
	lit: boolean,
	lightAccum: number,
	lastScare: number,
}

local records: { [Player]: Record } = {}
local connections: { [Player]: { RBXScriptConnection } } = {}

local function worldPosition(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return nil
end

local function isNearLight(position: Vector3): boolean
	local radiusSq = Config.LIGHT_RADIUS * Config.LIGHT_RADIUS
	for _, light in CollectionService:GetTagged(Config.LIGHT_TAG) do
		local lightPos = worldPosition(light)
		if lightPos then
			local d = position - lightPos
			if d:Dot(d) <= radiusSq then
				return true
			end
		end
	end
	return false
end

local function humanoidOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return humanoid, root
end

local function setSanity(player: Player, value: number)
	local record = records[player]
	if not record then
		return
	end
	value = math.clamp(value, Config.MIN, Config.MAX)
	record.sanity = value

	local rounded = math.round(value)
	if rounded ~= record.pushed then
		record.pushed = rounded
		player:SetAttribute(Config.ATTRIBUTE, rounded)
	end
end

function SanityService.getSanity(player: Player): number
	local record = records[player]
	return if record then record.sanity else Config.START
end

function SanityService.setSanity(player: Player, value: number)
	setSanity(player, value)
end

function SanityService.addSanity(player: Player, delta: number)
	local record = records[player]
	if not record then
		return
	end
	setSanity(player, record.sanity + delta)
end

local function onScareHit(player: Player)
	local record = records[player]
	if not record then
		return
	end
	local humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if record.lit then
		return
	end

	local now = os.clock()
	if now - record.lastScare < Config.SCARE_COOLDOWN then
		return
	end
	record.lastScare = now

	humanoid:TakeDamage(Config.SCARE_DAMAGE)
end

local function step(dt: number)
	for player, record in records do
		local humanoid, root = humanoidOf(player)
		if not humanoid or not root or humanoid.Health <= 0 then
			continue
		end

		record.lightAccum += dt
		if record.lightAccum >= Config.LIGHT_CHECK_INTERVAL then
			record.lightAccum = 0
			record.lit = isNearLight(root.Position)
		end

		local rate = if record.lit then Config.REGEN_PER_SECOND else -Config.DRAIN_PER_SECOND
		if rate ~= 0 then
			setSanity(player, record.sanity + rate * dt)
		end

		if record.sanity <= Config.MIN then
			humanoid:TakeDamage(Config.ZERO_HEALTH_DPS * dt)
		end
	end
end

local function onPlayerAdded(player: Player)
	records[player] = {
		sanity = Config.START,
		pushed = -1,
		lit = true,
		lightAccum = 0,
		lastScare = 0,
	}
	setSanity(player, Config.START)

	local conns = {}
	table.insert(
		conns,
		player.CharacterAdded:Connect(function()
			setSanity(player, Config.START)
		end)
	)
	connections[player] = conns
end

local function onPlayerRemoving(player: Player)
	local conns = connections[player]
	if conns then
		for _, connection in conns do
			connection:Disconnect()
		end
	end
	connections[player] = nil
	records[player] = nil
end

function SanityService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Net.On("SanityScareHit", onScareHit)
end

function SanityService.Start()
	RunService.Heartbeat:Connect(step)
end

return SanityService
