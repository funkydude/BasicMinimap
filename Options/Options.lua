
local acr = LibStub("AceConfigRegistry-3.0")
local acd = LibStub("AceConfigDialog-3.0")
local media = LibStub("LibSharedMedia-3.0")
local adbo = LibStub("AceDBOptions-3.0")
local ldbi = LibStub("LibDBIcon-1.0")
local map = BasicMinimap

local L
do
	local _, mod = ...
	L = mod.L
end

local buttonValues = {RightButton = L.rightMouseButton, MiddleButton = L.middleMouse,
	Button4 = L.mouseButton:format(4), Button5 = L.mouseButton:format(5), Button6 = L.mouseButton:format(6),
	Button7 = L.mouseButton:format(7), Button8 = L.mouseButton:format(8), Button9 = L.mouseButton:format(9),
	Button10 = L.mouseButton:format(10), Button11 = L.mouseButton:format(11), Button12 = L.mouseButton:format(12),
	Button13 = L.mouseButton:format(13), Button14 = L.mouseButton:format(14), Button15 = L.mouseButton:format(15),
	None = L.none
}

local function updateFlags()
	local flags = nil
	if map.db.profile.monochrome and map.db.profile.outline ~= "NONE" then
		flags = "MONOCHROME," .. map.db.profile.outline
	elseif map.db.profile.monochrome then
		flags = "MONOCHROME"
	elseif map.db.profile.outline ~= "NONE" then
		flags = map.db.profile.outline
	end
	return flags
end

local acOptions = {
	name = "BasicMinimap",
	type = "group", childGroups = "tab",
	get = function(info)
		return map.db.profile[info[#info]]
	end,
	set = function(info, value)
		map.db.profile[info[#info]] = value
	end,
	args = {
		main = {
			name = L.general,
			order = 1, type = "group",
			args = {
				colorBorder = {
					name = L.borderColor,
					order = 1, type = "color", hasAlpha = true,
					get = function() return unpack(map.db.profile.colorBorder) end,
					set = function(_, r, g, b, a)
						map.db.profile.colorBorder = {r, g, b, a}
						map.backdrop:SetColorTexture(r, g, b, a)
					end,
				},
				classcolor = {
					name = L.CLASSCOLORED,
					order = 2, type = "execute",
					func = function()
						local _, class = UnitClass("player")
						local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
						local a = map.db.profile.colorBorder[4]
						map.db.profile.colorBorder = {color.r, color.g, color.b, a}
						map.backdrop:SetColorTexture(color.r, color.g, color.b, a)
					end,
				},
				borderSize = {
					name = L.BORDERSIZE,
					order = 3, type = "range", width = "full",
					min = 1, max = 30, step = 1,
					set = function(_, value)
						map.db.profile.borderSize = value
						map.backdrop:SetSize(map.db.profile.size+value, map.db.profile.size+value)
					end,
				},
				miscspacer = {
					name = "\n\n",
					order = 4, type = "description",
				},
				lock = {
					name = L.lock,
					order = 5, type = "toggle",
					width = "full",
					set = function(_, value)
						map.db.profile.lock = value
						map.SetMovable(Minimap, not value)
					end,
				},
				autoZoom = {
					name = L.AUTOZOOM,
					order = 6,
					type = "toggle",
				},
				shape = {
					name = L.SHAPE,
					order = 7, type = "select",
					values = {SQUARE = L.square, ROUND = L.round},
					set = function(_, value)
						map.db.profile.shape = value
						if value == "SQUARE" then
							Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
							map.mask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
							function GetMinimapShape() return "SQUARE" end
						else
							Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
							map.mask:SetTexture("Interface\\AddOns\\BasicMinimap\\circle")
							function GetMinimapShape() return "ROUND" end
						end
						local tbl = ldbi:GetButtonList()
						for i = 1, #tbl do
							ldbi:Refresh(tbl[i])
						end
						-- Update all blizz button positions
						for position, button in next, map.blizzButtonPositions do
							map.ClearAllPoints(button)
							ldbi:SetButtonToPosition(button, position)
						end
					end,
				},
				sizeDesc = {
					name = "\n\n".. L.sizeHeader,
					order = 8, type = "description", fontSize = "medium",
				},
				size = {
					name = L.size,
					order = 9, type = "range",
					min = 70, max = 400, step = 1, bigStep = 5,
					set = function(_, value)
						map.db.profile.size = value
						map.SetSize(Minimap, value, value)
						map.SetWidth(MinimapZoneText, value)
						-- I'm not sure of a better way to update the render layer to the new size
						if Minimap:GetZoom() ~= 5 then
							Minimap_ZoomInClick()
							Minimap_ZoomOutClick()
						else
							Minimap_ZoomOutClick()
							Minimap_ZoomInClick()
						end
						map.backdrop:SetSize(value+map.db.profile.borderSize, value+map.db.profile.borderSize)
						local tbl = ldbi:GetButtonList()
						for i = 1, #tbl do
							ldbi:Refresh(tbl[i])
						end
						-- Update all blizz button positions
						for position, button in next, map.blizzButtonPositions do
							map.ClearAllPoints(button)
							ldbi:SetButtonToPosition(button, position)
						end
					end,
				},
				scale = {
					name = L.scale,
					order = 10, type = "range",
					min = 0.5, max = 2, step = 0.01,
					set = function(_, value)
						map.SetScale(Minimap, value)
						map.ClearAllPoints(Minimap)
						local s = map.db.profile.scale/value
						map.db.profile.position[3], map.db.profile.position[4] = map.db.profile.position[3]*s, map.db.profile.position[4]*s
						map.SetPoint(Minimap, map.db.profile.position[1], UIParent, map.db.profile.position[2], map.db.profile.position[3], map.db.profile.position[4])
						map.db.profile.scale = value
					end,
				},
			},
		},
		buttons = {
			name = L.BUTTONS,
			order = 2, type = "group",
			args = {
				hideAddons = {
					name = L.hideAddons,
					desc = L.hideAddonsDesc,
					order = 1, type = "toggle",
					set = function(_, value)
						map.db.profile.hideAddons = value
						local tbl = ldbi:GetButtonList()
						for i = 1, #tbl do
							ldbi:ShowOnEnter(tbl[i], value)
						end
						if value then
							ldbi.RegisterCallback(map, "LibDBIcon_IconCreated", "HideButtons")
						else
							ldbi.UnregisterCallback(map, "LibDBIcon_IconCreated")
						end
					end,
				},
				radius = {
					type = "range",
					name = L.radius,
					desc = L.radiusDesc,
					order = 2,
					max = 50,
					min = -50,
					step = 1,
					set = function(_, value)
						map.db.profile.radius = value
						ldbi:SetButtonRadius(value)
						-- Update all blizz button positions
						for position, button in next, map.blizzButtonPositions do
							map.ClearAllPoints(button)
							ldbi:SetButtonToPosition(button, position)
						end
					end,
				},
				buttonShowDesc = {
					name = "\n\n".. L.buttonHeader,
					order = 3, type = "description",
				},
				zoomBtn = {
					name = L.zoomInZoomOut,
					order = 4, type = "toggle",
					set = function(_, value)
						map.db.profile.zoomBtn = value
						if value then
							map.SetParent(MinimapZoomIn, Minimap)
							map.SetParent(MinimapZoomOut, Minimap)
						else
							map.SetParent(MinimapZoomIn, map)
							map.SetParent(MinimapZoomOut, map)
						end
					end,
				},
				clock = {
					name = L.clock,
					order = 6, type = "toggle",
					set = function(_, value)
						map.db.profile.clock = value
						map.SetParent(TimeManagerClockButton, value and Minimap or map)
					end,
				},
				zoneText = {
					name = L.ZONETEXT,
					order = 7, type = "toggle",
					set = function(_, value)
						map.db.profile.zoneText = value
						map.SetParent(MinimapZoneTextButton, value and Minimap or map)
					end,
				},
				fontHeaderDesc = {
					name = "\n\n".. L.fontHeader,
					order = 9, type = "description",
				},
				font = {
					type = "select",
					name = L.font,
					order = 10,
					values = media:List("font"),
					itemControl = "DDI-Font",
					get = function()
						for i, v in next, media:List("font") do
							if v == map.db.profile.font then return i end
						end
					end,
					set = function(_, value)
						local list = media:List("font")
						local font = list[value]
						map.db.profile.font = font
						MinimapZoneText:SetFont(media:Fetch("font", font), map.db.profile.fontSize, updateFlags())
						TimeManagerClockTicker:SetFont(media:Fetch("font", font), map.db.profile.fontSize, updateFlags())
					end,
				},
				fontSize = {
					type = "range",
					name = L.fontSize,
					order = 11,
					max = 200,
					min = 1,
					step = 1,
					set = function(_, value)
						map.db.profile.fontSize = value
						map.SetHeight(MinimapZoneText, map.db.profile.fontSize)
						MinimapZoneText:SetFont(media:Fetch("font", map.db.profile.font), value, updateFlags())
						TimeManagerClockTicker:SetFont(media:Fetch("font", map.db.profile.font), value, updateFlags())
					end,
				},
				monochrome = {
					type = "toggle",
					name = L.monochrome,
					order = 12,
					set = function(_, value)
						map.db.profile.monochrome = value
						MinimapZoneText:SetFont(media:Fetch("font", map.db.profile.font), map.db.profile.fontSize, updateFlags())
						TimeManagerClockTicker:SetFont(media:Fetch("font", map.db.profile.font), map.db.profile.fontSize, updateFlags())
					end,
				},
				outline = {
					type = "select",
					name = L.outline,
					order = 13,
					values = {
						NONE = L.none,
						OUTLINE = L.thin,
						THICKOUTLINE = L.thick,
					},
					set = function(_, value)
						map.db.profile.outline = value
						MinimapZoneText:SetFont(media:Fetch("font", map.db.profile.font), map.db.profile.fontSize, updateFlags())
						TimeManagerClockTicker:SetFont(media:Fetch("font", map.db.profile.font), map.db.profile.fontSize, updateFlags())
					end,
				},
			},
		},
		clicks = {
			name = L.clicks,
			order = 3, type = "group",
			args = {
				clickHeaderDesc = {
					name = "\n".. L.minimapClicks,
					order = 1, type = "description",
				},
				mapBtn = {
					name = L.openMap,
					order = 5, type = "select",
					values = buttonValues,
				},
			},
		},
		profiles = adbo:GetOptionsTable(BasicMinimap.db),
	},
}
acOptions.args.profiles.order = 4

acr:RegisterOptionsTable(acOptions.name, acOptions, true)
acd:SetDefaultSize(acOptions.name, 430, 500)

