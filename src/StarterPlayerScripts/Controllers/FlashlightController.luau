--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local FlashlightState = require(ReplicatedStorage.Shared.Modules.FlashlightState)

local player = Players.LocalPlayer
local TOGGLE_KEY = Enum.KeyCode.F

local FlashlightController = {}

local isOn = Vide.source(false)
FlashlightController.isOn = isOn

local light: SpotLight? = nil
local connections: { RBXScriptConnection } = {}

function FlashlightController.isFlashlightOn(): boolean
	return isOn()
end

local function setOn(value: boolean)
	isOn(value)
	FlashlightState.set(value)
	if light then
		light.Enabled = value
	end
end

local function attachLight(character: Model)
	local head = character:WaitForChild("Head", 5)
	if not head or not head:IsA("BasePart") then
		return
	end
	local spot = Instance.new("SpotLight")
	spot.Name = "Flashlight"
	spot.Face = Enum.NormalId.Front
	spot.Angle = 45
	spot.Range = 40
	spot.Brightness = 8
	spot.Enabled = isOn()
	spot.Parent = head
	light = spot
end

function FlashlightController.Init()
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if processed then
				return
			end
			if input.KeyCode == TOGGLE_KEY then
				setOn(not isOn())
			end
		end)
	)

	local function onCharacter(character: Model)
		attachLight(character)
		setOn(isOn())
	end

	table.insert(connections, player.CharacterAdded:Connect(onCharacter))
	if player.Character then
		onCharacter(player.Character)
	end
end

function FlashlightController.Destroy()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if light then
		light:Destroy()
		light = nil
	end
end

return FlashlightController
