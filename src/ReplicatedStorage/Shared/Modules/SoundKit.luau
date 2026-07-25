--!strict

local SoundService = game:GetService("SoundService")

local SoundKit = {}

local holder = Instance.new("Folder")
holder.Name = "SanitySounds2D"
holder.Parent = SoundService

local function resolve(path: { string }): Instance?
	local node: Instance = SoundService
	for _, name in path do
		local child = node:FindFirstChild(name)
		if not child then
			warn(`[SoundKit] missing SoundService.{table.concat(path, ".")}`)
			return nil
		end
		node = child
	end
	return node
end

local function cloneSound(path: { string }): Sound?
	local node = resolve(path)
	if not node then
		return nil
	end

	if node:IsA("Sound") then
		return node:Clone()
	end

	local sounds = {}
	for _, child in node:GetChildren() do
		if child:IsA("Sound") then
			table.insert(sounds, child)
		end
	end
	if #sounds == 0 then
		warn(`[SoundKit] no Sound under SoundService.{table.concat(path, ".")}`)
		return nil
	end
	return sounds[math.random(#sounds)]:Clone()
end

function SoundKit.playAt(path: { string }, parent: BasePart): Sound?
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

function SoundKit.play2D(path: { string }): Sound?
	local sound = cloneSound(path)
	if not sound then
		return nil
	end
	sound.Parent = holder
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	return sound
end

function SoundKit.loop(path: { string }, parent: Instance?): Sound?
	local sound = cloneSound(path)
	if not sound then
		return nil
	end
	sound.Looped = true
	sound.Parent = parent or holder
	sound:Play()
	return sound
end

return SoundKit
