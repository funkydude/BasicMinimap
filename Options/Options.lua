
local acr = LibStub("AceConfigRegistry-3.0")
local acd = LibStub("AceConfigDialog-3.0")
local media = LibStub("LibSharedMedia-3.0")
local adbo = LibStub("AceDBOptions-3.0")
local map = BasicMinimap

local hideFrame = function(frame) frame:Hide() end
local noop = function() end

local L
do
	local _, mod = ...
	L = mod.L
end

local buttonValues = {RightButton = KEY_BUTTON2, MiddleButton = KEY_BUTTON3,
	Button4 = KEY_BUTTON4, Button5 = KEY_BUTTON5, Button6 = KEY_BUTTON6,
	Button7 = KEY_BUTTON7, Button8 = KEY_BUTTON8, Button9 = KEY_BUTTON9,
	Button10 = KEY_BUTTON10, Button11 = KEY_BUTTON11, Button12 = KEY_BUTTON12,
	Button13 = KEY_BUTTON13, Button14 = KEY_BUTTON14, Button15 = KEY_BUTTON15,
	None = NONE
}

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
			name = _G["MISCELLANEOUS"],
			order = 1, type = "group",
			args = {
				colorBorder = {
					name = EMBLEM_BORDER_COLOR, --Border Color
					order = 1, type = "color", hasAlpha = true,
					get = function() return unpack(map.db.profile.colorBorder) end,
					set = function(_, r, g, b, a)
						map.db.profile.colorBorder = {r, g, b, a}
						for i = 1, 8 do
							map.backdrops[i]:SetColorTexture(r, g, b, a)
						end
					end,
					disabled = function() return map.db.profile.round end,
				},
				classcolor = {
					name = L.CLASSCOLORED,
					order = 2, type = "execute",
					func = function()
						local _, class = UnitClass("player")
						local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
						for i = 1, 4 do
							map.backdrops[i]:SetColorTexture(color.r, color.g, color.b)
						end
						map.db.profile.borderR, map.db.profile.borderG, map.db.profile.borderB = color.r, color.g, color.b
					end,
					disabled = function() return map.db.profile.round end,
				},
				borderSize = {
					name = L.BORDERSIZE,
					order = 3, type = "range", width = "full",
					min = 1, max = 10, step = 1,
					set = function(_, value)
						map.db.profile.borderSize = value
						-- Clockwise: TOP, RIGHT, BOTTOM, LEFT
						local w, h = Minimap:GetWidth(), Minimap:GetHeight()
						for i = 1, 4 do
							map.backdrops[i]:SetWidth(i%2==0 and value or w)
							map.backdrops[i]:SetHeight(i%2==0 and h or value)
						end
						for i = 5, 8 do
							map.backdrops[i]:SetWidth(value)
							map.backdrops[i]:SetHeight(value)
						end
					end,
					disabled = function() return map.db.profile.round end,
				},
				miscspacer = {
					name = "\n",
					order = 4, type = "description",
				},
				mischeader = {
					name = MISCELLANEOUS,
					order = 5, type = "header",
				},
				scale = {
					name = L.SCALE,
					order = 6, type = "range",
					min = 0.5, max = 2, step = 0.01,
					set = function(_, value)
						Minimap:SetScale(value)
						Minimap:ClearAllPoints()
						local s = map.db.profile.scale/value
						map.db.profile.position[3], map.db.profile.position[4] = map.db.profile.position[3]*s, map.db.profile.position[4]*s
						Minimap:SetPoint(map.db.profile.position[1], UIParent, map.db.profile.position[2], map.db.profile.position[3], map.db.profile.position[4])
						map.db.profile.scale = value
					end,
				},
				round = {
					name = L.SHAPE,
					order = 9, type = "toggle",
					set = function(_, value)
						map.db.profile.round = value
						if not value then
							Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
							for i = 1, 8 do
								map.backdrops[i]:Show()
							end
							function GetMinimapShape() return "SQUARE" end
						else
							Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
							for i = 1, 8 do
								map.backdrops[i]:Hide()
							end
							function GetMinimapShape() return "ROUND" end
						end
					end,
				},
				autoZoom = {
					name = L.AUTOZOOM,
					order = 10, type = "toggle",
					width = "full",
				},
				lock = {
					name = LOCK,
					order = 11, type = "toggle",
					set = function(_, value)
						map.db.profile.lock = value
						Minimap:SetMovable(not value)
					end,
				},
			},
		},
		buttons = {
			name = L.BUTTONS,
			order = 2, type = "group",
			args = {
				zoomBtn = {
					name = ZOOM_IN.."/"..ZOOM_OUT,
					order = 1, type = "toggle",
					set = function(_, value)
						map.db.profile.zoomBtn = value
						if value then
							MinimapZoomIn:ClearAllPoints()
							MinimapZoomIn:SetParent("Minimap")
							MinimapZoomIn:SetPoint("RIGHT", "Minimap", "RIGHT", map.db.profile.round and 10 or 20, map.db.profile.round and -40 or -50)
							MinimapZoomIn:Show()
							MinimapZoomOut:ClearAllPoints()
							MinimapZoomOut:SetParent("Minimap")
							MinimapZoomOut:SetPoint("BOTTOM", "Minimap", "BOTTOM", map.db.profile.round and 40 or 50, map.db.profile.round and -10 or -20)
							MinimapZoomOut:Show()
						else
							MinimapZoomIn:Hide()
							MinimapZoomOut:Hide()
						end
					end,
				},
				raidDiffIcon = {
					name = RAID_DIFFICULTY,
					order = 2, type = "toggle",
					set = function(_, value)
						map.db.profile.raidDiffIcon = value
						if value then
							MiniMapInstanceDifficulty:SetScript("OnShow", nil)
							GuildInstanceDifficulty:SetScript("OnShow", nil)
							local _, z = IsInInstance()
							if z and (z == "party" or z == "raid") and (IsInRaid() or IsInGroup()) then
								MiniMapInstanceDifficulty:Show()
								GuildInstanceDifficulty:Show()
							end
						else
							MiniMapInstanceDifficulty:SetScript("OnShow", hideFrame)
							MiniMapInstanceDifficulty:Hide()
							GuildInstanceDifficulty:SetScript("OnShow", hideFrame)
							GuildInstanceDifficulty:Hide()
						end
					end,
				},
				clock = {
					name = TIMEMANAGER_TITLE,
					order = 3, type = "toggle",
					set = function(_, value)
						map.db.profile.clock = value
						if value then
							if TimeManagerClockButton.bmShow then
								TimeManagerClockButton.Show = TimeManagerClockButton.bmShow
								TimeManagerClockButton.bmShow = nil
							end
							TimeManagerClockButton:Show()
						else
							if not TimeManagerClockButton.bmShow then
								TimeManagerClockButton.bmShow = TimeManagerClockButton.Show
								TimeManagerClockButton.Show = noop
							end
							TimeManagerClockButton:Hide()
						end
					end,
				},
				zoneText = {
					name = L.ZONETEXT,
					order = 4, type = "toggle",
					set = function(_, value)
						map.db.profile.zoneText = value
						if value then
							if MinimapZoneTextButton.bmShow then
								MinimapZoneTextButton.Show = MinimapZoneTextButton.bmShow
								MinimapZoneTextButton.bmShow = nil
							end
							MinimapZoneTextButton:Show()
						else
							if not MinimapZoneTextButton.bmShow then
								MinimapZoneTextButton.bmShow = MinimapZoneTextButton.Show
								MinimapZoneTextButton.Show = noop
							end
							MinimapZoneTextButton:Hide()
						end
					end,
				},
				missions = {
					name = L.CLASSHALL,
					order = 5, type = "toggle",
					set = function(_, value)
						map.db.profile.missions = value
						if value then
							if GarrisonLandingPageMinimapButton.bmShow then
								GarrisonLandingPageMinimapButton.Show = GarrisonLandingPageMinimapButton.bmShow
								GarrisonLandingPageMinimapButton.bmShow = nil
							end
							GarrisonLandingPageMinimapButton:Show()
						else
							if not GarrisonLandingPageMinimapButton.bmShow then
								GarrisonLandingPageMinimapButton.bmShow = GarrisonLandingPageMinimapButton.Show
								GarrisonLandingPageMinimapButton.Show = noop
							end
							GarrisonLandingPageMinimapButton:Hide()
						end
					end,
				},
				clickHeaderDesc = {
					name = "\n".. L.BUTTONDESC,
					order = 6, type = "description",
				},
				calendarBtn = {
					name = L.CALENDAR,
					order = 7, type = "select",
					values = buttonValues,
				},
				trackingBtn = {
					name = TRACKING,
					order = 8, type = "select",
					values = buttonValues,
				},
			},
		},
		profiles = adbo:GetOptionsTable(BasicMinimap.db),
	},
}
acOptions.args.profiles.order = 3

acr:RegisterOptionsTable(acOptions.name, acOptions, true)
acd:SetDefaultSize(acOptions.name, 430, 570)

