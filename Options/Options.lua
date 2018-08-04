
local acr = LibStub("AceConfigRegistry-3.0")
local acd = LibStub("AceConfigDialog-3.0")
local media = LibStub("LibSharedMedia-3.0")
local adbo = LibStub("AceDBOptions-3.0")
local map = Minimap
local db, backdrops = map.db, map.backdrops

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
	args = {
		main = {
			name = _G["MISCELLANEOUS"],
			order = 1, type = "group",
			args = {
				btndesc = {
					name = L.BUTTONDESC,
					order = 1, type = "description",
				},
				calendarbtn = {
					name = L.CALENDAR,
					order = 2, type = "select",
					get = function() return db.calendar or "RightButton" end,
					set = function(_, btn) db.calendar = btn~="RightButton" and btn or nil end,
					values = buttonValues,
				},
				trackingbtn = {
					name = TRACKING,
					order = 3, type = "select",
					get = function() return db.tracking or "MiddleButton" end,
					set = function(_, btn) db.tracking = btn~="MiddleButton" and btn or nil end,
					values = buttonValues,
				},
				borderspacer = {
					name = "\n",
					order = 3.1, type = "description",
				},
				bordertitle = {
					name = EMBLEM_BORDER, --Border
					order = 4, type = "header",
				},
				bordercolor = {
					name = EMBLEM_BORDER_COLOR, --Border Color
					order = 5, type = "color",
					get = function() return db.borderR, db.borderG, db.borderB end,
					set = function(_, r, g, b)
						db.borderR = r db.borderG = g db.borderB = b
						for i = 1, 4 do
							backdrops[i]:SetColorTexture(r, g, b)
						end
					end,
					disabled = function() return db.round end,
				},
				classcolor = {
					name = L.CLASSCOLORED,
					order = 6, type = "execute",
					func = function()
						local _, class = UnitClass("player")
						local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
						for i = 1, 4 do
							backdrops[i]:SetColorTexture(color.r, color.g, color.b)
						end
						db.borderR, db.borderG, db.borderB = color.r, color.g, color.b
					end,
					disabled = function() return db.round end,
				},
				bordersize = {
					name = L.BORDERSIZE,
					order = 7, type = "range", width = "full",
					min = 1, max = 10, step = 1,
					get = function() return db.borderSize or 3 end,
					set = function(_, b) db.borderSize = b~=3 and b or nil
						-- Clockwise: TOP, RIGHT, BOTTOM, LEFT
						local b2 = b*2
						local w, h = Minimap:GetWidth()+b2, Minimap:GetHeight()+b2
						for i = 1, 4 do
							backdrops[i]:SetWidth(i%2==0 and b or w)
							backdrops[i]:SetHeight(i%2==0 and h or b)
						end
					end,
					disabled = function() return db.round end,
				},
				buttonsspacer = {
					name = "\n",
					order = 7.1, type = "description",
				},
				buttonsheader = {
					name = L.BUTTONS,
					order = 8, type = "header",
				},
				zoom = {
					name = ZOOM_IN.."/"..ZOOM_OUT,
					order = 9, type = "toggle",
					get = function() return db.zoomBtn end,
					set = function(_, state)
						db.zoomBtn = state
						if state then
							MinimapZoomIn:ClearAllPoints()
							MinimapZoomIn:SetParent("Minimap")
							MinimapZoomIn:SetPoint("RIGHT", "Minimap", "RIGHT", db.round and 10 or 20, db.round and -40 or -50)
							MinimapZoomIn:Show()
							MinimapZoomOut:ClearAllPoints()
							MinimapZoomOut:SetParent("Minimap")
							MinimapZoomOut:SetPoint("BOTTOM", "Minimap", "BOTTOM", db.round and 40 or 50, db.round and -10 or -20)
							MinimapZoomOut:Show()
						else
							MinimapZoomIn:Hide()
							MinimapZoomOut:Hide()
						end
					end,
				},
				raiddiff = {
					name = RAID_DIFFICULTY,
					order = 10, type = "toggle",
					get = function() if db.hideraid then return false else return true end end,
					set = function(_, state)
						if state then
							db.hideraid = nil
							MiniMapInstanceDifficulty:SetScript("OnShow", nil)
							GuildInstanceDifficulty:SetScript("OnShow", nil)
							local z = select(2, IsInInstance())
							if z and (z == "party" or z == "raid") and (IsInRaid() or IsInGroup()) then
								MiniMapInstanceDifficulty:Show()
								GuildInstanceDifficulty:Show()
							end
						else
							db.hideraid = true
							MiniMapInstanceDifficulty:SetScript("OnShow", hideFrame)
							MiniMapInstanceDifficulty:Hide()
							GuildInstanceDifficulty:SetScript("OnShow", hideFrame)
							GuildInstanceDifficulty:Hide()
						end
					end,
				},
				clock = {
					name = TIMEMANAGER_TITLE,
					order = 11, type = "toggle",
					get = function() return db.clock or db.clock == nil and true end,
					set = function(_, state)
						db.clock = state
						if state then
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
					order = 12, type = "toggle",
					get = function() return db.zoneText or db.zoneText == nil and true end,
					set = function(_, state)
						db.zoneText = state
						if state then
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
				classHall = {
					name = L.CLASSHALL,
					order = 13, type = "toggle",
					get = function() return db.classHall or db.classHall == nil and true end,
					set = function(_, state)
						db.classHall = state
						if state then
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
				miscspacer = {
					name = "\n",
					order = 13.1, type = "description",
				},
				mischeader = {
					name = MISCELLANEOUS,
					order = 14, type = "header",
				},
				scale = {
					name = L.SCALE,
					order = 15, type = "range",
					min = 0.5, max = 2, step = 0.01,
					get = function() return db.scale or 1 end,
					set = function(_, scale)
						Minimap:SetScale(scale)
						Minimap:ClearAllPoints()
						local s = (db.scale or 1)/scale
						db.x, db.y = db.x*s, db.y*s
						Minimap:SetPoint(db.point, UIParent, db.relpoint, db.x, db.y)
						db.scale = scale~=1 and scale or nil
					end,
				},
				shape = {
					name = L.SHAPE,
					order = 16, type = "select",
					get = function() return db.round and "circular" or "square" end,
					set = function(_, shape)
						if shape == "square" then
							db.round = nil
							Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
							for i = 1, 4 do
								backdrops[i]:Show()
							end
							function GetMinimapShape() return "SQUARE" end
						else
							db.round = true
							Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
							for i = 1, 4 do
								backdrops[i]:Hide()
							end
							function GetMinimapShape() return "ROUND" end
						end
					end,
					values = {square = RAID_TARGET_6, circular = RAID_TARGET_2}, --Square, Circle
				},
				autozoom = {
					name = L.AUTOZOOM,
					order = 17, type = "toggle",
					width = "full",
					get = function() return db.zoom end,
					set = function(_, state) db.zoom = state and true or nil end,
				},
				lock = {
					name = LOCK,
					order = 18, type = "toggle",
					get = function() return db.lock end,
					set = function(_, state) db.lock = state and true or nil
						if not state then state = true else state = false end
						Minimap:SetMovable(state)
					end,
				},
			},
		},
		profiles = adbo:GetOptionsTable(BasicMinimap.db),
	},
}
acOptions.args.profiles.order = 2

acr:RegisterOptionsTable(acOptions.name, acOptions, true)
acd:SetDefaultSize(acOptions.name, 430, 570)

