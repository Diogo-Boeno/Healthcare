--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Vide = require(Packages.vide)
local Config = require(ReplicatedStorage.Shared.Modules.SanityConfig)
local Crosshair = require(ReplicatedStorage.Shared.UI.Crosshair)

local player = Players.LocalPlayer
local FP = Config.FIRST_PERSON

local RENDER_BIND = "SanityFirstPersonBody"

local FirstPersonController = {}

local HEAD_ACCESSORY_TYPES: { [Enum.AccessoryType]: boolean } = {
	[Enum.AccessoryType.Hat] = true,
	[Enum.AccessoryType.Hair] = true,
	[Enum.AccessoryType.Face] = true,
}

local managed: { [BasePart]: number } = {}

local connections: { RBXScriptConnection } = {}
local charConn: RBXScriptConnection? = nil
local unmount: (() -> ())? = nil

local function buildManaged(character: Model)
	table.clear(managed)
	local head = character:FindFirstChild("Head")

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			managed[descendant] = if descendant == head then 1 else 0
		end
	end

	if head and head:IsA("BasePart") then
		managed[head] = 1
		for _, item in head:GetChildren() do
			if item:IsA("Decal") or item:IsA("Texture") then
				item.Transparency = 1
			end
		end
	end

	for _, item in character:GetChildren() do
		if item:IsA("Accessory") and HEAD_ACCESSORY_TYPES[item.AccessoryType] then
			local handle = item:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				managed[handle] = 1
			end
		end
	end
end

local function applyTransparency()
	for part, modifier in managed do
		if part.Parent then
			part.LocalTransparencyModifier = modifier
		end
	end
end

local function onCharacter(character: Model)
	if charConn then
		charConn:Disconnect()
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.CameraOffset = Vector3.new(0, 0, -FP.FORWARD_OFFSET)
	end

	buildManaged(character)
	charConn = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") or descendant:IsA("Accessory") then
			buildManaged(character)
		end
	end)
end

function FirstPersonController.Init()
	UserInputService.MouseIconEnabled = false
	player.CameraMode = Enum.CameraMode.LockFirstPerson

	table.insert(connections, player.CharacterAdded:Connect(onCharacter))
	table.insert(
		connections,
		player.CharacterRemoving:Connect(function()
			table.clear(managed)
		end)
	)
	if player.Character then
		onCharacter(player.Character)
	end
end

function FirstPersonController.Start()
	local playerGui = player:WaitForChild("PlayerGui")

	unmount = Vide.mount(function()
		return Vide.create "ScreenGui" {
			Name = "FirstPersonHud",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,

			Crosshair(),
		}
	end, playerGui)

	RunService:BindToRenderStep(RENDER_BIND, Enum.RenderPriority.Camera.Value + 1, applyTransparency)
end

function FirstPersonController.Destroy()
	RunService:UnbindFromRenderStep(RENDER_BIND)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if charConn then
		charConn:Disconnect()
		charConn = nil
	end
	if unmount then
		unmount()
		unmount = nil
	end
	table.clear(managed)
	player.CameraMode = Enum.CameraMode.Classic
	UserInputService.MouseIconEnabled = true
end

return FirstPersonController
