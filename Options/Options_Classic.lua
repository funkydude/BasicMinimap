
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

local function UpdateFont(frame, db)
	local flags = nil
	if db.monochrome and db.outline ~= "NONE" then
		flags = "MONOCHROME," .. db.outline
	elseif db.monochrome then
		flags = "MONOCHROME"
	elseif db.outline ~= "NONE" then
		flags = db.outline
	end
	frame:SetFont(media:Fetch("font", db.font), db.fontSize, flags)
end

local function UpdateCoords()
	local uiMapID = C_Map.GetBestMapForUnit"player"
	if uiMapID then
		local tbl = C_Map.GetPlayerMapPosition(uiMapID, "player")
		if tbl then
			map.coords:SetFormattedText(map.db.profile.coordPrecision, tbl.x*100, tbl.y*100)
		else
			map.coords:SetText("0,0")
		end
	else
		map.coords:SetText("0,0")
	end
end

local function UpdateZoneText()
	local pvpType = GetZonePVPInfo()
	if pvpType == "sanctuary" then
		local c = map.db.profile.zoneTextConfig.colorSanctuary
		map.zonetext.text:SetTextColor(c[1], c[2], c[3], c[4])
	elseif pvpType == "arena" then
		local c = map.db.profile.zoneTextConfig.colorArena
		map.zonetext.text:SetTextColor(c[1], c[2], c[3], c[4])
	elseif pvpType == "friendly" then
		local c = map.db.profile.zoneTextConfig.colorFriendly
		map.zonetext.text:SetTextColor(c[1], c[2], c[3], c[4])
	elseif pvpType == "hostile" then
		local c = map.db.profile.zoneTextConfig.colorHostile
		map.zonetext.text:SetTextColor(c[1], c[2], c[3], c[4])
	elseif pvpType == "contested" then
		local c = map.db.profile.zoneTextConfig.colorContested
		map.zonetext.text:SetTextColor(c[1], c[2], c[3], c[4])
	else
		local c = map.db.profile.zoneTextConfig.colorNormal
		map.zonetext.text:SetTextColor(c[1], c[2], c[3], c[4])
	end
end

local function UpdateClock()
	local hour, minute
	if GetCVarBool("timeMgrUseLocalTime") then
		hour, minute = tonumber(date("%H")), tonumber(date("%M"))
	else
		hour, minute = GetGameTime()
	end

	if GetCVarBool("timeMgrUseMilitaryTime") then
		map.clock.text:SetFormattedText(TIMEMANAGER_TICKER_24HOUR, hour, minute)
	else
		if hour == 0 then
			hour = 12
		elseif hour > 12 then
			hour = hour - 12
		end
		map.clock.text:SetFormattedText(TIMEMANAGER_TICKER_12HOUR, hour, minute)
	end
end

local options = function()
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
							if map.db.profile.classcolor then
								r, g, b = unpack(map.db.profile.colorBorder)
							end
							map.db.profile.colorBorder = {r, g, b, a}
							map.backdrop:SetColorTexture(r, g, b, a)
						end,
						disabled = function() return map.db.profile.classcolor end,
					},
					classcolor = {
						name = L.CLASSCOLORED,
						order = 2, type = "toggle",
						set = function(_, value)
							map.db.profile.classcolor = value
							if value then
								local _, class = UnitClass("player")
								local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
								local a = map.db.profile.colorBorder[4]
								map.db.profile.colorBorder = {color.r, color.g, color.b, a}
								map.backdrop:SetColorTexture(color.r, color.g, color.b, a)
							else
								map.db.profile.colorBorder = {0, 0, 0, 1}
								map.backdrop:SetColorTexture(0, 0, 0, 1)
							end
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
								if HybridMinimap then
									HybridMinimap.MapCanvas:SetUseMaskTexture(false)
									HybridMinimap.CircleMask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
									HybridMinimap.MapCanvas:SetUseMaskTexture(true)
								end
								function GetMinimapShape() return "SQUARE" end
							else
								Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
								map.mask:SetTexture("Interface\\AddOns\\BasicMinimap\\circle")
								if HybridMinimap then
									HybridMinimap.MapCanvas:SetUseMaskTexture(false)
									HybridMinimap.CircleMask:SetTexture("Interface\\AddOns\\BasicMinimap\\circle")
									HybridMinimap.MapCanvas:SetUseMaskTexture(true)
								end
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
							map.zonetext:SetWidth(value)
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

							-- Fix Size (Clock)
							map.clock.text:SetText("99:99")
							local clockWidth = map.clock.text:GetUnboundedStringWidth()
							map.clock:SetWidth(clockWidth + 5)
							UpdateClock()

							-- Fix size (Coords)
							map.coords:SetFormattedText(map.db.profile.coordPrecision, 100.77, 100.77)
							local coordsWidth = map.coords:GetUnboundedStringWidth()
							map.coords:SetWidth(coordsWidth + 5)
							UpdateCoords()
						end,
					},
				},
			},
			clicks = {
				name = L.clicks,
				order = 2, type = "group",
				args = {
					clickHeaderDesc = {
						name = "\n".. L.minimapClicks,
						order = 1, type = "description",
					},
					calendarBtn = {
						name = L.openCalendar,
						order = 2, type = "select",
						values = buttonValues,
						disabled = true,
					},
					trackingBtn = {
						name = L.openTracking,
						order = 3, type = "select",
						values = buttonValues,
					},
					missionsBtn = {
						name = L.openMissions,
						order = 4, type = "select",
						values = buttonValues,
						disabled = true,
					},
					mapBtn = {
						name = L.openMap,
						order = 5, type = "select",
						values = buttonValues,
					},
				},
			},
			buttons = {
				name = L.BUTTONS,
				order = 3, type = "group",
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
								ldbi.RegisterCallback(map, "LibDBIcon_IconCreated", function(_, _, buttonName)
									ldbi:ShowOnEnter(buttonName, true)
								end)
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
						name = "\n\n\n".. L.buttonHeader,
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
					raidDiffIcon = {
						name = L.difficultyIndicator,
						order = 5, type = "toggle",
						set = function(_, value)
							map.db.profile.raidDiffIcon = value
							if value then
								map.SetParent(MiniMapInstanceDifficulty, Minimap)
								map.SetParent(GuildInstanceDifficulty, Minimap)
								map.SetParent(MiniMapChallengeMode, Minimap)
							else
								map.SetParent(MiniMapInstanceDifficulty, map)
								map.SetParent(GuildInstanceDifficulty, map)
								map.SetParent(MiniMapChallengeMode, map)
							end
						end,
						disabled = true,
					},
					missions = {
						name = L.missions,
						order = 6, type = "toggle",
						set = function(_, value)
							map.db.profile.missions = value
							map.SetParent(GarrisonLandingPageMinimapButton, value and Minimap or map)
						end,
						disabled = true,
					},
					zoneText = {
						name = L.ZONETEXT,
						order = 7, type = "toggle",
						set = function(_, value)
							map.db.profile.zoneText = value
							if value then
								map.zonetext:SetParent(Minimap)
								map.zonetext:RegisterEvent("ZONE_CHANGED")
								map.zonetext:RegisterEvent("ZONE_CHANGED_INDOORS")
								map.zonetext:RegisterEvent("ZONE_CHANGED_NEW_AREA")
							else
								map.zonetext:SetParent(map)
								map.zonetext:UnregisterEvent("ZONE_CHANGED")
								map.zonetext:UnregisterEvent("ZONE_CHANGED_INDOORS")
								map.zonetext:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
							end
						end,
					},
					clock = {
						name = L.clock,
						order = 8, type = "toggle",
						set = function(_, value)
							map.db.profile.clock = value
							map.clock:SetParent(value and Minimap or map)
						end,
					},
					coords = {
						name = L.coordinates,
						order = 9, type = "toggle",
						set = function(_, value)
							map.db.profile.coords = value
							map.coords.shown = value
							map.coords:SetParent(value and Minimap or map)
						end,
					},
					coordDesc = {
						name = "\n\n\n".. L.coordinates..":",
						order = 10, type = "description",
					},
					coordPrecision = {
						name = L.coordPrecision,
						desc = L.coordPrecisionDesc,
						order = 11, type = "select",
						values = {["%d,%d"] = L.normal, ["%.1f, %.1f"] = L.high, ["%.2f, %.2f"] = L.veryHigh},
						set = function(_, value)
							map.db.profile.coordPrecision = value
							map.coords:SetFormattedText(value, 100.77, 100.77)
							local width = map.coords:GetUnboundedStringWidth()
							map.coords:SetWidth(width + 5)
						end,
					},
					coordTime = {
						name = L.coordUpdates,
						desc = L.coordUpdatesDesc,
						order = 12, type = "select",
						values = {[1] = L.normal, [0.5] = L.high, [0.1] = L.veryHigh},
						set = function(_, value)
							map.db.profile.coordTime = value
						end,
					},
				},
			},
			text = {
				name = L.text,
				order = 4, type = "group", childGroups = "tab",
				args = {
					zonetext = {
						name = L.ZONETEXT,
						order = 1, type = "group",
						get = function(info)
							return map.db.profile.zoneTextConfig[info[#info]]
						end,
						args = {
							x = {
								type = "range",
								name = L.horizontalX,
								order = 1,
								max = 2000,
								softMax = 250,
								min = -2000,
								softMin = -250,
								step = 1,
								set = function(_, value)
									map.db.profile.zoneTextConfig.x = value
									map.zonetext:ClearAllPoints()
									map.zonetext:SetPoint("BOTTOM", map.backdrop, "TOP", value, map.db.profile.zoneTextConfig.y)
								end,
							},
							y = {
								type = "range",
								name = L.verticalY,
								order = 2,
								max = 2000,
								softMax = 250,
								min = -2000,
								softMin = -250,
								step = 1,
								set = function(_, value)
									map.db.profile.zoneTextConfig.y = value
									map.zonetext:ClearAllPoints()
									map.zonetext:SetPoint("BOTTOM", map.backdrop, "TOP", map.db.profile.zoneTextConfig.x, value)
								end,
							},
							align = {
								type = "select",
								name = L.align,
								order = 3,
								values = {
									LEFT = L.alignLeft,
									CENTER = L.alignCenter,
									RIGHT = L.alignRight,
								},
								set = function(_, value)
									map.db.profile.zoneTextConfig.align = value
									map.zonetext.text:SetJustifyH(value)
								end,
							},
							reset = {
								name = L.reset,
								order = 4, type = "execute",
								func = function()
									map.db.profile.zoneTextConfig.x = 0
									map.db.profile.zoneTextConfig.y = 3
									map.db.profile.zoneTextConfig.align = "CENTER"
									map.zonetext.text:SetJustifyH(map.db.profile.zoneTextConfig.align)
									map.zonetext:ClearAllPoints()
									map.zonetext:SetPoint("BOTTOM", map.backdrop, "TOP", map.db.profile.zoneTextConfig.x, map.db.profile.zoneTextConfig.y)
								end,
							},
							spacer = {
								name = "\n\n",
								order = 5, type = "description", width = "full",
							},
							font = {
								type = "select",
								name = L.font,
								order = 6,
								values = media:List("font"),
								itemControl = "DDI-Font",
								get = function()
									for i, v in next, media:List("font") do
										if v == map.db.profile.zoneTextConfig.font then return i end
									end
								end,
								set = function(_, value)
									local list = media:List("font")
									local font = list[value]
									map.db.profile.zoneTextConfig.font = font
									UpdateFont(map.zonetext.text, map.db.profile.zoneTextConfig)
								end,
							},
							fontSize = {
								type = "range",
								name = L.fontSize,
								order = 7,
								max = 200,
								min = 1,
								step = 1,
								set = function(_, value)
									map.db.profile.zoneTextConfig.fontSize = value
									map.zonetext:SetHeight(value)
									UpdateFont(map.zonetext.text, map.db.profile.zoneTextConfig)
								end,
							},
							monochrome = {
								type = "toggle",
								name = L.monochrome,
								order = 8,
								set = function(_, value)
									map.db.profile.zoneTextConfig.monochrome = value
									UpdateFont(map.zonetext.text, map.db.profile.zoneTextConfig)
								end,
							},
							outline = {
								type = "select",
								name = L.outline,
								order = 9,
								values = {
									NONE = L.none,
									OUTLINE = L.thin,
									THICKOUTLINE = L.thick,
								},
								set = function(_, value)
									map.db.profile.zoneTextConfig.outline = value
									UpdateFont(map.zonetext.text, map.db.profile.zoneTextConfig)
								end,
							},
							colorDesc = {
								name = function() return L.currentZone:format(type((GetZonePVPInfo())) == "string" and L[GetZonePVPInfo()] or L.normal) end,
								order = 9.5, type = "description", width = "full",
							},
							colorNormal = {
								name = L.normal,
								order = 10, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.zoneTextConfig.colorNormal) end,
								set = function(_, r, g, b, a)
									map.db.profile.zoneTextConfig.colorNormal = {r, g, b, a}
									UpdateZoneText()
								end,
								disabled = function() return map.db.profile.zoneTextConfig.classcolor end,
							},
							colorSanctuary = {
								name = L.sanctuary,
								order = 11, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.zoneTextConfig.colorSanctuary) end,
								set = function(_, r, g, b, a)
									map.db.profile.zoneTextConfig.colorSanctuary = {r, g, b, a}
									UpdateZoneText()
								end,
								disabled = function() return map.db.profile.zoneTextConfig.classcolor end,
							},
							colorArena = {
								name = L.arena,
								order = 12, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.zoneTextConfig.colorArena) end,
								set = function(_, r, g, b, a)
									map.db.profile.zoneTextConfig.colorArena = {r, g, b, a}
									UpdateZoneText()
								end,
								disabled = function() return map.db.profile.zoneTextConfig.classcolor end,
							},
							colorFriendly = {
								name = L.friendly,
								order = 13, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.zoneTextConfig.colorFriendly) end,
								set = function(_, r, g, b, a)
									map.db.profile.zoneTextConfig.colorFriendly = {r, g, b, a}
									UpdateZoneText()
								end,
								disabled = function() return map.db.profile.zoneTextConfig.classcolor end,
							},
							colorHostile = {
								name = L.hostile,
								order = 14, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.zoneTextConfig.colorHostile) end,
								set = function(_, r, g, b, a)
									map.db.profile.zoneTextConfig.colorHostile = {r, g, b, a}
									UpdateZoneText()
								end,
								disabled = function() return map.db.profile.zoneTextConfig.classcolor end,
							},
							colorContested = {
								name = L.contested,
								order = 15, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.zoneTextConfig.colorContested) end,
								set = function(_, r, g, b, a)
									map.db.profile.zoneTextConfig.colorContested = {r, g, b, a}
									UpdateZoneText()
								end,
								disabled = function() return map.db.profile.zoneTextConfig.classcolor end,
							},
							classcolor = {
								name = L.CLASSCOLORED,
								order = 16, type = "toggle",
								set = function(_, value)
									map.db.profile.zoneTextConfig.classcolor = value
									if value then
										local _, class = UnitClass("player")
										local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
										local a = map.db.profile.zoneTextConfig.colorNormal[4]
										map.db.profile.zoneTextConfig.colorNormal = {color.r, color.g, color.b, a}
										a = map.db.profile.zoneTextConfig.colorSanctuary[4]
										map.db.profile.zoneTextConfig.colorSanctuary = {color.r, color.g, color.b, a}
										a = map.db.profile.zoneTextConfig.colorArena[4]
										map.db.profile.zoneTextConfig.colorArena = {color.r, color.g, color.b, a}
										a = map.db.profile.zoneTextConfig.colorFriendly[4]
										map.db.profile.zoneTextConfig.colorFriendly = {color.r, color.g, color.b, a}
										a = map.db.profile.zoneTextConfig.colorHostile[4]
										map.db.profile.zoneTextConfig.colorHostile = {color.r, color.g, color.b, a}
										a = map.db.profile.zoneTextConfig.colorContested[4]
										map.db.profile.zoneTextConfig.colorContested = {color.r, color.g, color.b, a}
										UpdateZoneText()
									else
										map.db.profile.zoneTextConfig.colorNormal = {1, 0.82, 0, 1}
										map.db.profile.zoneTextConfig.colorSanctuary = {0.41, 0.8, 0.94, 1}
										map.db.profile.zoneTextConfig.colorArena = {1.0, 0.1, 0.1, 1}
										map.db.profile.zoneTextConfig.colorFriendly = {0.1, 1.0, 0.1, 1}
										map.db.profile.zoneTextConfig.colorHostile = {1.0, 0.1, 0.1, 1}
										map.db.profile.zoneTextConfig.colorContested = {1.0, 0.7, 0.0, 1}
										UpdateZoneText()
									end
								end,
							},
						},
					},
					clock = {
						name = L.clock,
						order = 2, type = "group",
						get = function(info)
							return map.db.profile.clockConfig[info[#info]]
						end,
						args = {
							x = {
								type = "range",
								name = L.horizontalX,
								order = 1,
								max = 2000,
								softMax = 250,
								min = -2000,
								softMin = -250,
								step = 1,
								set = function(_, value)
									map.db.profile.clockConfig.x = value
									map.clock:ClearAllPoints()
									map.clock:SetPoint("TOPLEFT", map.backdrop, "BOTTOMLEFT", value, map.db.profile.clockConfig.y)
								end,
							},
							y = {
								type = "range",
								name = L.verticalY,
								order = 2,
								max = 2000,
								softMax = 250,
								min = -2000,
								softMin = -250,
								step = 1,
								set = function(_, value)
									map.db.profile.clockConfig.y = value
									map.clock:ClearAllPoints()
									map.clock:SetPoint("TOPLEFT", map.backdrop, "BOTTOMLEFT", map.db.profile.clockConfig.x, value)
								end,
							},
							align = {
								type = "select",
								name = L.align,
								order = 3,
								values = {
									LEFT = L.alignLeft,
									CENTER = L.alignCenter,
									RIGHT = L.alignRight,
								},
								set = function(_, value)
									map.db.profile.clockConfig.align = value
									map.clock.text:SetJustifyH(value)
								end,
							},
							reset = {
								name = L.reset,
								order = 4, type = "execute",
								func = function()
									map.db.profile.clockConfig.x = 0
									map.db.profile.clockConfig.y = -4
									map.db.profile.clockConfig.align = "LEFT"
									map.clock.text:SetJustifyH(map.db.profile.clockConfig.align)
									map.clock:ClearAllPoints()
									map.clock:SetPoint("TOPLEFT", map.backdrop, "BOTTOMLEFT", map.db.profile.clockConfig.x, map.db.profile.clockConfig.y)
								end,
							},
							spacer = {
								name = "\n\n",
								order = 5, type = "description", width = "full",
							},
							font = {
								type = "select",
								name = L.font,
								order = 6,
								values = media:List("font"),
								itemControl = "DDI-Font",
								get = function()
									for i, v in next, media:List("font") do
										if v == map.db.profile.clockConfig.font then return i end
									end
								end,
								set = function(_, value)
									local list = media:List("font")
									local font = list[value]
									map.db.profile.clockConfig.font = font
									UpdateFont(map.clock.text, map.db.profile.clockConfig)
									-- Fix Size
									map.clock.text:SetText("99:99")
									local width = map.clock.text:GetUnboundedStringWidth()
									map.clock:SetWidth(width + 5)
									UpdateClock()
								end,
							},
							fontSize = {
								type = "range",
								name = L.fontSize,
								order = 7,
								max = 200,
								min = 1,
								step = 1,
								set = function(_, value)
									map.db.profile.clockConfig.fontSize = value
									map.clock:SetHeight(value)
									UpdateFont(map.clock.text, map.db.profile.clockConfig)
									-- Fix Size
									map.clock.text:SetText("99:99")
									local width = map.clock.text:GetUnboundedStringWidth()
									map.clock:SetWidth(width + 5)
									UpdateClock()
								end,
							},
							monochrome = {
								type = "toggle",
								name = L.monochrome,
								order = 8,
								set = function(_, value)
									map.db.profile.clockConfig.monochrome = value
									UpdateFont(map.clock.text, map.db.profile.clockConfig)
								end,
							},
							outline = {
								type = "select",
								name = L.outline,
								order = 9,
								values = {
									NONE = L.none,
									OUTLINE = L.thin,
									THICKOUTLINE = L.thick,
								},
								set = function(_, value)
									map.db.profile.clockConfig.outline = value
									UpdateFont(map.clock.text, map.db.profile.clockConfig)
									-- Fix Size
									map.clock.text:SetText("99:99")
									local width = map.clock.text:GetUnboundedStringWidth()
									map.clock:SetWidth(width + 5)
									UpdateClock()
								end,
							},
							color = {
								name = L.color,
								order = 10, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.clockConfig.color) end,
								set = function(_, r, g, b, a)
									map.db.profile.clockConfig.color = {r, g, b, a}
									map.clock.text:SetTextColor(r, g, b, a)
								end,
								disabled = function() return map.db.profile.clockConfig.classcolor end,
							},
							classcolor = {
								name = L.CLASSCOLORED,
								order = 11, type = "toggle",
								set = function(_, value)
									map.db.profile.clockConfig.classcolor = value
									if value then
										local _, class = UnitClass("player")
										local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
										local a = map.db.profile.clockConfig.color[4]
										map.db.profile.clockConfig.color = {color.r, color.g, color.b, a}
										map.clock.text:SetTextColor(color.r, color.g, color.b, a)
									else
										map.db.profile.clockConfig.color = {1, 1, 1, 1}
										map.clock.text:SetTextColor(1, 1, 1, 1)
									end
								end,
							},
						},
					},
					coords = {
						name = L.coordinates,
						order = 3, type = "group",
						get = function(info)
							return map.db.profile.coordsConfig[info[#info]]
						end,
						args = {
							x = {
								type = "range",
								name = L.horizontalX,
								order = 1,
								max = 2000,
								softMax = 250,
								min = -2000,
								softMin = -250,
								step = 1,
								set = function(_, value)
									map.db.profile.coordsConfig.x = value
									map.coords:ClearAllPoints()
									map.coords:SetPoint("TOPRIGHT", map.backdrop, "BOTTOMRIGHT", value, map.db.profile.coordsConfig.y)
								end,
							},
							y = {
								type = "range",
								name = L.verticalY,
								order = 2,
								max = 2000,
								softMax = 250,
								min = -2000,
								softMin = -250,
								step = 1,
								set = function(_, value)
									map.db.profile.coordsConfig.y = value
									map.coords:ClearAllPoints()
									map.coords:SetPoint("TOPRIGHT", map.backdrop, "BOTTOMRIGHT", map.db.profile.coordsConfig.x, value)
								end,
							},
							align = {
								type = "select",
								name = L.align,
								order = 3,
								values = {
									LEFT = L.alignLeft,
									CENTER = L.alignCenter,
									RIGHT = L.alignRight,
								},
								set = function(_, value)
									map.db.profile.coordsConfig.align = value
									map.coords:SetJustifyH(value)
								end,
							},
							reset = {
								name = L.reset,
								order = 4, type = "execute",
								func = function()
									map.db.profile.coordsConfig.x = 0
									map.db.profile.coordsConfig.y = -4
									map.db.profile.coordsConfig.align = "RIGHT"
									map.coords:SetJustifyH(map.db.profile.coordsConfig.align)
									map.coords:ClearAllPoints()
									map.coords:SetPoint("TOPRIGHT", map.backdrop, "BOTTOMRIGHT", map.db.profile.coordsConfig.x, map.db.profile.coordsConfig.y)
								end,
							},
							spacer = {
								name = "\n\n",
								order = 5, type = "description", width = "full",
							},
							font = {
								type = "select",
								name = L.font,
								order = 6,
								values = media:List("font"),
								itemControl = "DDI-Font",
								get = function()
									for i, v in next, media:List("font") do
										if v == map.db.profile.coordsConfig.font then return i end
									end
								end,
								set = function(_, value)
									local list = media:List("font")
									local font = list[value]
									map.db.profile.coordsConfig.font = font
									UpdateFont(map.coords, map.db.profile.coordsConfig)
									-- Fix size
									map.coords:SetFormattedText(map.db.profile.coordPrecision, 100.77, 100.77)
									local width = map.coords:GetUnboundedStringWidth()
									map.coords:SetWidth(width + 5)
									UpdateCoords()
								end,
							},
							fontSize = {
								type = "range",
								name = L.fontSize,
								order = 7,
								max = 200,
								min = 1,
								step = 1,
								set = function(_, value)
									map.db.profile.coordsConfig.fontSize = value
									map.coords:SetHeight(value)
									UpdateFont(map.coords, map.db.profile.coordsConfig)
									-- Fix size
									map.coords:SetFormattedText(map.db.profile.coordPrecision, 100.77, 100.77)
									local width = map.coords:GetUnboundedStringWidth()
									map.coords:SetWidth(width + 5)
									UpdateCoords()
								end,
							},
							monochrome = {
								type = "toggle",
								name = L.monochrome,
								order = 8,
								set = function(_, value)
									map.db.profile.coordsConfig.monochrome = value
									UpdateFont(map.coords, map.db.profile.coordsConfig)
								end,
							},
							outline = {
								type = "select",
								name = L.outline,
								order = 9,
								values = {
									NONE = L.none,
									OUTLINE = L.thin,
									THICKOUTLINE = L.thick,
								},
								set = function(_, value)
									map.db.profile.coordsConfig.outline = value
									UpdateFont(map.coords, map.db.profile.coordsConfig)
									-- Fix size
									map.coords:SetFormattedText(map.db.profile.coordPrecision, 100.77, 100.77)
									local width = map.coords:GetUnboundedStringWidth()
									map.coords:SetWidth(width + 5)
									UpdateCoords()
								end,
							},
							color = {
								name = L.color,
								order = 10, type = "color", hasAlpha = true,
								get = function() return unpack(map.db.profile.coordsConfig.color) end,
								set = function(_, r, g, b, a)
									map.db.profile.coordsConfig.color = {r, g, b, a}
									map.coords:SetTextColor(r, g, b, a)
								end,
								disabled = function() return map.db.profile.coordsConfig.classcolor end,
							},
							classcolor = {
								name = L.CLASSCOLORED,
								order = 11, type = "toggle",
								set = function(_, value)
									map.db.profile.coordsConfig.classcolor = value
									if value then
										local _, class = UnitClass("player")
										local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
										local a = map.db.profile.coordsConfig.color[4]
										map.db.profile.coordsConfig.color = {color.r, color.g, color.b, a}
										map.coords:SetTextColor(color.r, color.g, color.b, a)
									else
										map.db.profile.coordsConfig.color = {1, 1, 1, 1}
										map.coords:SetTextColor(1, 1, 1, 1)
									end
								end,
							},
						},
					},
				},
			},
			profiles = adbo:GetOptionsTable(BasicMinimap.db),
		},
	}
	acOptions.args.profiles.order = 5
	return acOptions
end

acr:RegisterOptionsTable("BasicMinimap", options, true)
acd:SetDefaultSize("BasicMinimap", 440, 500)

