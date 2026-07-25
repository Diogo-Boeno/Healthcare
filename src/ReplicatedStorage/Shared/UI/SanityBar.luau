--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Vide = require(Packages.vide)
local Theme = require(ReplicatedStorage.Shared.UI.Common.Theme)

local create = Vide.create
local derive = Vide.derive
local read = Vide.read

type Reactive<T> = T | () -> T

export type SanityBarProps = {
	fraction: Reactive<number>,
}

local BAR_WIDTH = 260
local BAR_HEIGHT = 14

local function SanityBar(props: SanityBarProps)
	local function frac(): number
		return math.clamp(read(props.fraction), 0, 1)
	end

	local fillColor = derive(function()
		return Theme.color.textPrimary:Lerp(Theme.color.danger, 1 - frac())
	end)

	return create "Frame" {
		Name = "SanityBar",
		Size = UDim2.fromOffset(BAR_WIDTH, BAR_HEIGHT + 22),
		Position = UDim2.new(0.5, 0, 1, -28),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,

		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Padding = UDim.new(0, Theme.spacing.xs),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		create "TextLabel" {
			Name = "Label",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = "SANITY",
			TextColor3 = Theme.color.textMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = Theme.textSize.sm,
			FontFace = Theme.font.strong,
		},

		create "Frame" {
			Name = "Track",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
			BackgroundColor3 = Theme.color.surface,
			BorderSizePixel = 0,

			create "UICorner" { CornerRadius = Theme.radius.sm },
			create "UIStroke" {
				Thickness = Theme.strokeThickness,
				Color = Theme.color.stroke,
			},

			create "Frame" {
				Name = "Fill",
				Size = function()
					return UDim2.fromScale(frac(), 1)
				end,
				BackgroundColor3 = fillColor,
				BorderSizePixel = 0,
				create "UICorner" { CornerRadius = Theme.radius.sm },
			},
		},
	}
end

return SanityBar
