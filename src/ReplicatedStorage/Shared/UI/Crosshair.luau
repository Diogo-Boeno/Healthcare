--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local Theme = require(ReplicatedStorage.Shared.UI.Common.Theme)

local create = Vide.create

local DOT_SIZE = 5

local function Crosshair()
	return create "Frame" {
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE),
		BackgroundColor3 = Theme.color.textPrimary,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,

		create "UICorner" { CornerRadius = UDim.new(1, 0) },
		create "UIStroke" {
			Thickness = 1,
			Color = Theme.color.background,
			Transparency = 0.3,
		},
	}
end

return Crosshair
