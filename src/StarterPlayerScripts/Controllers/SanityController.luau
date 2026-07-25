--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Vide = require(Packages.vide)
local Config = require(ReplicatedStorage.Shared.Modules.SanityConfig)
local SoundKit = require(ReplicatedStorage.Shared.Modules.SoundKit)
local SanityBar = require(ReplicatedStorage.Shared.UI.SanityBar)

local player = Players.LocalPlayer

local SanityController = {}

local target = Vide.source(Config.START)
local display = Vide.source(Config.START)

local colorCorrection: ColorCorrectionEffect
local blur: BlurEffect

local playerBreathing: Sound?
local heartbeat: Sound?

local connections: { RBXScriptConnection } = {}
local unmount: (() -> ())? = nil

local function computeIntensity(fraction: number): number
	return math.clamp((Config.EFFECT_THRESHOLD - fraction) / Config.EFFECT_THRESHOLD, 0, 1)
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

local function onRenderStep(dt: number)
	local alpha = 1 - math.exp(-Config.SMOOTH_SPEED * dt)
	local current = display()
	current += (target() - current) * alpha
	if math.abs(target() - current) < 0.01 then
		current = target()
	end
	display(current)

	local t = computeIntensity(current / Config.MAX)
	updateEffects(t)
	updateAudio(t)
end

function SanityController.Init()
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "SanityColorCorrection"
	colorCorrection.Enabled = false
	colorCorrection.Parent = Lighting

	blur = Instance.new("BlurEffect")
	blur.Name = "SanityBlur"
	blur.Size = 0
	blur.Enabled = false
	blur.Parent = Lighting

	playerBreathing = SoundKit.loop(Config.SOUNDS.PLAYER_BREATHING)
	if playerBreathing then
		playerBreathing.Volume = 0
	end
	if Config.SOUNDS.HEARTBEAT then
		heartbeat = SoundKit.loop(Config.SOUNDS.HEARTBEAT)
		if heartbeat then
			heartbeat.Volume = 0
		end
	end

	local initial = player:GetAttribute(Config.ATTRIBUTE)
	if typeof(initial) == "number" then
		target(initial)
		display(initial)
	end

	table.insert(
		connections,
		player:GetAttributeChangedSignal(Config.ATTRIBUTE):Connect(function()
			local value = player:GetAttribute(Config.ATTRIBUTE)
			if typeof(value) == "number" then
				target(value)
			end
		end)
	)
end

function SanityController.Start()
	local playerGui = player:WaitForChild("PlayerGui")

	unmount = Vide.mount(function()
		return Vide.create "ScreenGui" {
			Name = "SanityHud",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

			SanityBar {
				fraction = function()
					return display() / Config.MAX
				end,
			},
		}
	end, playerGui)

	table.insert(connections, RunService.RenderStepped:Connect(onRenderStep))
end

function SanityController.Destroy()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if unmount then
		unmount()
		unmount = nil
	end
	if colorCorrection then
		colorCorrection:Destroy()
	end
	if blur then
		blur:Destroy()
	end
	if playerBreathing then
		playerBreathing:Destroy()
		playerBreathing = nil
	end
	if heartbeat then
		heartbeat:Destroy()
		heartbeat = nil
	end
end

return SanityController
