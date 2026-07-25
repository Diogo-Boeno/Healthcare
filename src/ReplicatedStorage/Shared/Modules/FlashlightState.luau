--!strict

local FlashlightState = {}

local on = false

function FlashlightState.set(value: boolean)
	on = value
end

function FlashlightState.isOn(): boolean
	return on
end

return FlashlightState
