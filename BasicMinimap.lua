
local name = ...
local media = LibStub("LibSharedMedia-3.0")
local ldbi = LibStub("LibDBIcon-1.0")

local frame = CreateFrame("Frame", name)
local bmTooltip = CreateFrame("GameTooltip", "BasicMinimapTooltip", UIParent, "GameTooltipTemplate")
frame:Hide()

local TrackingButton = MinimapCluster.Tracking.Button

local blizzButtonNicknames = {
	zoomIn = Minimap.ZoomIn,
	zoomOut = Minimap.ZoomOut,
	missions = ExpansionLandingPageMinimapButton,
	difficulty = MinimapCluster.InstanceDifficulty,
	calendar = GameTimeFrame,
	mail = MinimapCluster.IndicatorFrame.MailFrame,
	craftingOrder = MinimapCluster.IndicatorFrame.CraftingOrderFrame,
	addonCompartment = AddonCompartmentFrame,
}
frame.blizzButtonNicknames = blizzButtonNicknames

do
	local function openOpts()
		local EnableAddOn = C_AddOns.EnableAddOn or EnableAddOn
		local LoadAddOn = C_AddOns.LoadAddOn or LoadAddOn
		EnableAddOn("BasicMinimap_Options") -- Make sure it wasn't left disabled for whatever reason
		LoadAddOn("BasicMinimap_Options")
		LibStub("AceConfigDialog-3.0"):Open(name)
	end
	SlashCmdList.BASICMINIMAP = openOpts
	SLASH_BASICMINIMAP1 = "/bmm"
	SLASH_BASICMINIMAP2 = "/basicminimap"
end

local Minimap = Minimap
if frame.GetFrameStrata(Minimap) ~= "LOW" then
	frame.SetFrameStrata(Minimap, "LOW") -- Blizz Defaults patch 9.0.1 Minimap.xml
end
if frame.GetFrameLevel(Minimap) ~= 2 then
	frame.SetFrameLevel(Minimap, 2) -- Blizz Defaults patch 9.0.1 Minimap.xml
end

-- Prevent the damage caused by automagic fuckery when a frame changes parent by locking the strata/level in place
frame.SetFixedFrameStrata(Minimap, true)
frame.SetFixedFrameLevel(Minimap, true)
frame.SetParent(Minimap, UIParent)

local backdropFrame = CreateFrame("Frame")
backdropFrame:SetParent(Minimap)
-- With the introduction of the HybridMinimap at BACKGROUND level 100, we need to create our backdrop lower
backdropFrame:SetFrameStrata("BACKGROUND")
backdropFrame:SetFrameLevel(1)
backdropFrame:SetFixedFrameStrata(true)
backdropFrame:SetFixedFrameLevel(true)
backdropFrame:Show()
local backdrop = backdropFrame:CreateTexture(nil, "BACKGROUND")
backdrop:SetPoint("CENTER", Minimap, "CENTER")

-- To turn off Blizz auto hiding the zoom buttons, we pretend the mouse is always over it.
-- The alternative is killing the Minimap OnEnter/OnLeave script which could screw over other addons.
-- See MinimapMixin:OnLeave() on line 185 of FrameXML/Minimap.lua
local fakeMouseOver = function() return true end
Minimap.ZoomIn.IsMouseOver = fakeMouseOver
Minimap.ZoomIn:Show()
Minimap.ZoomOut.IsMouseOver = fakeMouseOver
Minimap.ZoomOut:Show()

-- Init
local function Init(self)
	local defaults = {
		profile = {
			lock = false,
			classcolor = false,
			shape = "SQUARE",
			clock = true,
			zoneText = true,
			coords = true,
			missions = true,
			raidDiffIcon = true,
			zoomBtn = false,
			mail = true,
			craftingOrder = true,
			addonCompartment = false,
			autoZoom = true,
			hideAddons = true,
			position = {"CENTER", "CENTER", 0, 0},
			borderSize = 5,
			size = 200,
			scale = 1,
			radius = 2,
			colorBorder = {0,0,0,1},
			calendarBtn = "RightButton",
			trackingBtn = "MiddleButton",
			missionsBtn = "None",
			mapBtn = "None",
			coordPrecision = "%d,%d",
			coordTime = 1,
			zoneTextConfig = {
				x = 0,
				y = 3,
				align = "CENTER",
				font = media:GetDefault("font"),
				fontSize = 12,
				monochrome = false,
				outline = "OUTLINE",
				colorNormal = {1, 0.82, 0, 1},
				colorSanctuary = {0.41, 0.8, 0.94, 1},
				colorArena = {1.0, 0.1, 0.1, 1},
				colorFriendly = {0.1, 1.0, 0.1, 1},
				colorHostile = {1.0, 0.1, 0.1, 1},
				colorContested = {1.0, 0.7, 0.0, 1},
				classcolor = false,
			},
			coordsConfig = {
				x = 0,
				y = -4,
				align = "RIGHT",
				font = media:GetDefault("font"),
				fontSize = 12,
				monochrome = false,
				outline = "OUTLINE",
				color = {1,1,1,1},
				classcolor = false,
			},
			clockConfig = {
				x = 0,
				y = -4,
				align = "LEFT",
				font = media:GetDefault("font"),
				fontSize = 12,
				monochrome = false,
				outline = "OUTLINE",
				color = {1,1,1,1},
				classcolor = false,
			},
			blizzButtonLocation = {
				zoomIn = 328,
				zoomOut = 302,
				missions = 190,
				difficulty = 150,
				calendar = 35,
				mail = 20,
				addonCompartment = 132,
				craftingOrder = 170,
			},
		},
	}
	self.db = LibStub("AceDB-3.0"):New("BasicMinimapSV", defaults, true)
	do
		local rl = function() ReloadUI() end
		self.db.RegisterCallback(self, "OnProfileChanged", rl)
		self.db.RegisterCallback(self, "OnProfileCopied", rl)
		self.db.RegisterCallback(self, "OnProfileReset", rl)
	end

	-- Return minimap shape for other addons
	if self.db.profile.shape ~= "ROUND" then
		function GetMinimapShape()
			return "SQUARE"
		end
	end

	if self.db.profile.hideAddons then
		local tbl = ldbi:GetButtonList()
		for i = 1, #tbl do
			ldbi:ShowOnEnter(tbl[i], true)
		end
		ldbi.RegisterCallback(self, "LibDBIcon_IconCreated", function(_, _, buttonName)
			ldbi:ShowOnEnter(buttonName, true)
		end)
	end
end

local function CreateClock(self) -- Create our own clock
	local clockButton = CreateFrame("Button", nil, Minimap) -- Having a nil frame name prevents minimap button grabbing addons mistaking it for an addon button
	local clockFont = clockButton:CreateFontString()

	do
		-- Kill Blizz Frame
		clockButton.SetParent(TimeManagerClockButton, self)
		clockFont.SetParent(TimeManagerClockTicker, self)
		local function blockBtn(TimeManagerClockButton)
			clockButton.SetParent(TimeManagerClockButton, frame)
		end
		local function blockText(TimeManagerClockTicker)
			clockFont.SetParent(TimeManagerClockTicker, frame)
		end
		hooksecurefunc(TimeManagerClockButton, "SetParent", blockBtn)
		hooksecurefunc(TimeManagerClockTicker, "SetParent", blockText)
	end

	clockButton:SetPoint("TOPLEFT", backdrop, "BOTTOMLEFT", self.db.profile.clockConfig.x, self.db.profile.clockConfig.y)
	clockFont:SetAllPoints(clockButton)
	clockButton:SetHeight(self.db.profile.clockConfig.fontSize+1)
	clockButton:EnableMouse(true)
	clockButton:RegisterForClicks("AnyUp")
	do
		local clockFlags = nil
		if self.db.profile.clockConfig.monochrome and self.db.profile.clockConfig.outline ~= "NONE" then
			clockFlags = "MONOCHROME," .. self.db.profile.clockConfig.outline
		elseif self.db.profile.clockConfig.monochrome then
			clockFlags = "MONOCHROME"
		elseif self.db.profile.clockConfig.outline ~= "NONE" then
			clockFlags = self.db.profile.clockConfig.outline
		end
		clockFont:SetFont(media:Fetch("font", self.db.profile.clockConfig.font), self.db.profile.clockConfig.fontSize, clockFlags)
		clockFont:SetText("99:99")
		local width = clockFont:GetUnboundedStringWidth()
		clockButton:SetWidth(width + 5)
	end
	clockFont:SetTextColor(unpack(self.db.profile.clockConfig.color))
	clockFont:SetJustifyH(self.db.profile.clockConfig.align)
	if not self.db.profile.clock then
		clockButton:SetParent(self)
	end
	do
		local function updateClock()
			C_Timer.After(60, updateClock)
			local hour, minute
			if GetCVarBool("timeMgrUseLocalTime") then
				hour, minute = tonumber(date("%H")), tonumber(date("%M"))
			else
				hour, minute = GetGameTime()
			end

			if GetCVarBool("timeMgrUseMilitaryTime") then
				clockFont:SetFormattedText(TIMEMANAGER_TICKER_24HOUR, hour, minute)
			else
				if hour == 0 then
					hour = 12
				elseif hour > 12 then
					hour = hour - 12
				end
				clockFont:SetFormattedText(TIMEMANAGER_TICKER_12HOUR, hour, minute)
			end

			if clockButton:IsMouseOver() then
				clockButton:GetScript("OnLeave")()
				clockButton:GetScript("OnEnter")(clockButton)
			end
		end
		local prevMin = -1
		local function warmupClock() -- Run warmup clock every 0.1 sec until the minute changes, then swap to 60sec
			local hour, minute
			if GetCVarBool("timeMgrUseLocalTime") then
				hour, minute = tonumber(date("%H")), tonumber(date("%M"))
			else
				hour, minute = GetGameTime()
			end
			if prevMin == -1 then
				prevMin = minute
			elseif minute ~= prevMin then
				warmupClock = nil
				updateClock()
				return
			end
			C_Timer.After(0.1, warmupClock)
			if GetCVarBool("timeMgrUseMilitaryTime") then
				clockFont:SetFormattedText(TIMEMANAGER_TICKER_24HOUR, hour, minute)
			else
				if hour == 0 then
					hour = 12
				elseif hour > 12 then
					hour = hour - 12
				end
				clockFont:SetFormattedText(TIMEMANAGER_TICKER_12HOUR, hour, minute)
			end
		end
		warmupClock()
	end
	do
		local CALENDAR_MONTH_NAMES = {
			MONTH_JANUARY,
			MONTH_FEBRUARY,
			MONTH_MARCH,
			MONTH_APRIL,
			MONTH_MAY,
			MONTH_JUNE,
			MONTH_JULY,
			MONTH_AUGUST,
			MONTH_SEPTEMBER,
			MONTH_OCTOBER,
			MONTH_NOVEMBER,
			MONTH_DECEMBER,
		}
		clockButton:SetScript("OnEnter", function(clockButtonFrame) -- Blizzard_TimeManager.lua line 428 function "TimeManagerClockButton_OnEnter" as of wow 9.0.1
			local whiteR, whiteG, whiteB = HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b
			local normalR, normalG, normalB = NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b

			local dateTbl = date("*t")
			local d, m, y = dateTbl.day, dateTbl.month, dateTbl.year
			local dateDisplay = ("%d %s %d"):format(d, CALENDAR_MONTH_NAMES[m], y)

			bmTooltip:SetOwner(clockButtonFrame, "ANCHOR_LEFT")
			-- GameTime.lua line 107 function "GameTime_UpdateTooltip" as of wow 9.0.1
			bmTooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, whiteR, whiteG, whiteB)
			bmTooltip:AddDoubleLine( -- Realm
				TIMEMANAGER_TOOLTIP_REALMTIME,
				GameTime_GetGameTime(true),
				normalR, normalG, normalB,
				whiteR, whiteG, whiteB)
			bmTooltip:AddDoubleLine( -- Local
				TIMEMANAGER_TOOLTIP_LOCALTIME,
				GameTime_GetLocalTime(true),
				normalR, normalG, normalB,
				whiteR, whiteG, whiteB)
			bmTooltip:AddLine(" ")
			bmTooltip:AddLine(dateDisplay, whiteR, whiteG, whiteB)
			bmTooltip:AddLine(" ")
			bmTooltip:AddLine(RESET, whiteR, whiteG, whiteB) -- Reset
			bmTooltip:AddDoubleLine( -- Daily quests
				STAT_FORMAT:format(DAILY),
				SecondsToTime(C_DateAndTime.GetSecondsUntilDailyReset()),
				normalR, normalG, normalB,
				whiteR, whiteG, whiteB)
			bmTooltip:AddDoubleLine( -- Weekly quests
				STAT_FORMAT:format(WEEKLY),
				SecondsToTime(C_DateAndTime.GetSecondsUntilWeeklyReset()),
				normalR, normalG, normalB,
				whiteR, whiteG, whiteB)
			bmTooltip:AddLine(" ")

			bmTooltip:AddLine(GAMETIME_TOOLTIP_TOGGLE_CLOCK)
			bmTooltip:Show()
		end)
	end
	clockButton:SetScript("OnLeave", function() bmTooltip:Hide() end)
	clockButton:SetScript("OnClick", function()
		if TimeManagerFrame:IsShown() then
			TimeManagerFrame:Hide()
		else
			TimeManagerFrame:Show()
		end
	end)
	self.clock = clockButton
	self.clock.text = clockFont
end

local function CreateZoneText(self, fullMinimapSize) -- Create our own zone text
	local zoneText = CreateFrame("Button", nil, Minimap) -- Having a nil frame name prevents minimap button grabbing addons mistaking it for an addon button
	local zoneTextFont = zoneText:CreateFontString()

	do
		-- Kill Blizz Frame
		if MinimapZoneTextButton then -- XXX Dragonflight compat
			zoneText.SetParent(MinimapZoneTextButton, self)
			zoneTextFont.SetParent(MinimapZoneText, self)
			MinimapCluster:UnregisterEvent("ZONE_CHANGED") -- Minimap.xml line 719-722 script "<OnLoad>" as of wow 9.0.1
			MinimapCluster:UnregisterEvent("ZONE_CHANGED_INDOORS")
			MinimapCluster:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
			local function blockBtn(MinimapZoneTextButton)
				zoneText.SetParent(MinimapZoneTextButton, frame)
			end
			local function blockText(MinimapZoneText)
				zoneTextFont.SetParent(MinimapZoneText, frame)
			end
			hooksecurefunc(MinimapZoneTextButton, "SetParent", blockBtn)
			hooksecurefunc(MinimapZoneText, "SetParent", blockText)
		else
			zoneText.SetParent(MinimapCluster.ZoneTextButton, self)
			zoneText.SetParent(MinimapCluster.BorderTop, self)
		end
	end

	zoneText:SetPoint("BOTTOM", backdrop, "TOP", self.db.profile.zoneTextConfig.x, self.db.profile.zoneTextConfig.y)
	zoneTextFont:SetAllPoints(zoneText)
	zoneText:SetWidth(fullMinimapSize) -- Prevent text cropping
	zoneText:SetHeight(self.db.profile.zoneTextConfig.fontSize+1) -- Prevent text cropping
	do
		local zoneTextFlags = nil
		if self.db.profile.zoneTextConfig.monochrome and self.db.profile.zoneTextConfig.outline ~= "NONE" then
			zoneTextFlags = "MONOCHROME," .. self.db.profile.zoneTextConfig.outline
		elseif self.db.profile.zoneTextConfig.monochrome then
			zoneTextFlags = "MONOCHROME"
		elseif self.db.profile.zoneTextConfig.outline ~= "NONE" then
			zoneTextFlags = self.db.profile.zoneTextConfig.outline
		end
		zoneTextFont:SetFont(media:Fetch("font", self.db.profile.zoneTextConfig.font), self.db.profile.zoneTextConfig.fontSize, zoneTextFlags)
	end
	zoneTextFont:SetJustifyH(self.db.profile.zoneTextConfig.align)
	if not self.db.profile.zoneText then
		zoneText:SetParent(self)
	else
		zoneText:RegisterEvent("ZONE_CHANGED")
		zoneText:RegisterEvent("ZONE_CHANGED_INDOORS")
		zoneText:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	end
	do
		local GetMinimapZoneText, GetZonePVPInfo = GetMinimapZoneText, C_PvP and C_PvP.GetZonePVPInfo or GetZonePVPInfo
		local function UpdateDisplay(zoneTextFrame) -- Minimap.lua line 47 function "Minimap_Update" as of wow 9.0.1
			local text = GetMinimapZoneText()
			zoneTextFont:SetText(text)

			local pvpType = GetZonePVPInfo()
			if pvpType == "sanctuary" then
				local c = frame.db.profile.zoneTextConfig.colorSanctuary
				zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
			elseif pvpType == "arena" then
				local c = frame.db.profile.zoneTextConfig.colorArena
				zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
			elseif pvpType == "friendly" then
				local c = frame.db.profile.zoneTextConfig.colorFriendly
				zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
			elseif pvpType == "hostile" then
				local c = frame.db.profile.zoneTextConfig.colorHostile
				zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
			elseif pvpType == "contested" then
				local c = frame.db.profile.zoneTextConfig.colorContested
				zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
			else
				local c = frame.db.profile.zoneTextConfig.colorNormal
				zoneTextFont:SetTextColor(c[1], c[2], c[3], c[4])
			end

			if zoneTextFrame:IsMouseOver() then
				zoneTextFrame:GetScript("OnLeave")()
				zoneTextFrame:GetScript("OnEnter")(zoneTextFrame)
			end
		end
		zoneText:SetScript("OnEvent", UpdateDisplay)
		zoneText:SetScript("OnEnter", function(zoneTextFrame) -- Minimap.lua line 68 function "Minimap_SetTooltip" as of wow 9.0.1
			bmTooltip:SetOwner(zoneTextFrame, "ANCHOR_LEFT")
			local pvpType, _, factionName = GetZonePVPInfo()
			local zoneName = GetZoneText()
			local subzoneName = GetSubZoneText()
			if subzoneName == zoneName then
				subzoneName = ""
			end
			bmTooltip:AddLine(zoneName, 1.0, 1.0, 1.0)
			if pvpType == "sanctuary" then
				bmTooltip:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorSanctuary))
				bmTooltip:AddLine(SANCTUARY_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorSanctuary))
			elseif pvpType == "arena" then
				bmTooltip:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorArena))
				bmTooltip:AddLine(FREE_FOR_ALL_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorArena))
			elseif pvpType == "friendly" then
				if factionName and factionName ~= "" then
					bmTooltip:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorFriendly))
					bmTooltip:AddLine((FACTION_CONTROLLED_TERRITORY):format(factionName), unpack(frame.db.profile.zoneTextConfig.colorFriendly))
				end
			elseif pvpType == "hostile" then
				if factionName and factionName ~= "" then
					bmTooltip:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorHostile))
					bmTooltip:AddLine((FACTION_CONTROLLED_TERRITORY):format(factionName), unpack(frame.db.profile.zoneTextConfig.colorHostile))
				end
			elseif pvpType == "contested" then
				bmTooltip:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorContested))
				bmTooltip:AddLine(CONTESTED_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorContested))
			elseif pvpType == "combat" then
				bmTooltip:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorArena))
				bmTooltip:AddLine(COMBAT_ZONE, unpack(frame.db.profile.zoneTextConfig.colorArena))
			else
				bmTooltip:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorNormal))
			end
			bmTooltip:Show()
		end)
		zoneText:SetScript("OnLeave", function() bmTooltip:Hide() end)
		UpdateDisplay(zoneText)
	end
	self.zonetext = zoneText
	self.zonetext.text = zoneTextFont
end

local function CreateCoords(self)
	-- Coords
	local coords = self:CreateFontString()
	if not self.db.profile.coords then
		coords:SetParent(self)
		coords.shown = false
	else
		coords:SetParent(Minimap)
		coords.shown = true
	end
	coords:ClearAllPoints()
	coords:SetPoint("TOPRIGHT", backdrop, "BOTTOMRIGHT", self.db.profile.coordsConfig.x, self.db.profile.coordsConfig.y)
	coords:SetHeight(self.db.profile.coordsConfig.fontSize+1) -- Prevent text cropping
	do
		local coordsFlags = nil
		if self.db.profile.coordsConfig.monochrome and self.db.profile.coordsConfig.outline ~= "NONE" then
			coordsFlags = "MONOCHROME," .. self.db.profile.coordsConfig.outline
		elseif self.db.profile.coordsConfig.monochrome then
			coordsFlags = "MONOCHROME"
		elseif self.db.profile.coordsConfig.outline ~= "NONE" then
			coordsFlags = self.db.profile.coordsConfig.outline
		end
		coords:SetFont(media:Fetch("font", self.db.profile.coordsConfig.font), self.db.profile.coordsConfig.fontSize, coordsFlags)
		coords:SetFormattedText(self.db.profile.coordPrecision, 100.77, 100.77)
		local width = coords:GetUnboundedStringWidth()
		coords:SetWidth(width + 5)
	end
	coords:SetTextColor(unpack(self.db.profile.coordsConfig.color))
	coords:SetJustifyH(self.db.profile.coordsConfig.align)
	do
		local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
		local GetBestMapForUnit = C_Map.GetBestMapForUnit
		local CTimerAfter = C_Timer.After
		local function updateCoords()
			local uiMapID = GetBestMapForUnit"player"
			if uiMapID and coords.shown then
				local tbl = GetPlayerMapPosition(uiMapID, "player")
				if tbl then
					local db = frame.db.profile
					CTimerAfter(db.coordTime, updateCoords)
					coords:SetFormattedText(db.coordPrecision, tbl.x*100, tbl.y*100)
				else
					CTimerAfter(5, updateCoords)
					coords:SetText("0,0")
				end
			else
				CTimerAfter(5, updateCoords)
				coords:SetText("0,0")
			end
		end
		updateCoords()
	end
	self.coords = coords
end

-- Enable
local function Login(self)
	self:CALENDAR_UPDATE_PENDING_INVITES()

	self.EnableMouse(MinimapCluster, false)
	local fullMinimapSize = self.db.profile.size + self.db.profile.borderSize

	do
		local _, class = UnitClass("player")
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		if self.db.profile.classcolor then
			local a = self.db.profile.colorBorder[4]
			self.db.profile.colorBorder = {color.r, color.g, color.b, a}
		end
		if self.db.profile.coordsConfig.classcolor then
			local a = self.db.profile.coordsConfig.color[4]
			self.db.profile.coordsConfig.color = {color.r, color.g, color.b, a}
		end
		if self.db.profile.clockConfig.classcolor then
			local a = self.db.profile.clockConfig.color[4]
			self.db.profile.clockConfig.color = {color.r, color.g, color.b, a}
		end
		if self.db.profile.zoneTextConfig.classcolor then
			local a = self.db.profile.zoneTextConfig.colorNormal[4]
			self.db.profile.zoneTextConfig.colorNormal = {color.r, color.g, color.b, a}
			a = self.db.profile.zoneTextConfig.colorSanctuary[4]
			self.db.profile.zoneTextConfig.colorSanctuary = {color.r, color.g, color.b, a}
			a = self.db.profile.zoneTextConfig.colorArena[4]
			self.db.profile.zoneTextConfig.colorArena = {color.r, color.g, color.b, a}
			a = self.db.profile.zoneTextConfig.colorFriendly[4]
			self.db.profile.zoneTextConfig.colorFriendly = {color.r, color.g, color.b, a}
			a = self.db.profile.zoneTextConfig.colorHostile[4]
			self.db.profile.zoneTextConfig.colorHostile = {color.r, color.g, color.b, a}
			a = self.db.profile.zoneTextConfig.colorContested[4]
			self.db.profile.zoneTextConfig.colorContested = {color.r, color.g, color.b, a}
		end
	end
	-- Backdrop, creating the border cleanly
	backdrop:SetSize(fullMinimapSize, fullMinimapSize)
	backdrop:SetColorTexture(unpack(self.db.profile.colorBorder))
	local mask = backdropFrame:CreateMaskTexture()
	mask:SetAllPoints(backdrop)
	mask:SetParent(backdropFrame)
	backdrop:AddMaskTexture(mask)
	frame.backdrop = backdrop
	frame.mask = mask

	self.ClearAllPoints(Minimap)
	self.SetPoint(Minimap, self.db.profile.position[1], UIParent, self.db.profile.position[2], self.db.profile.position[3], self.db.profile.position[4])
	self.RegisterForDrag(Minimap, "LeftButton")
	self.SetClampedToScreen(Minimap, true)

	self.SetScript(Minimap, "OnDragStart", function(minimapFrame)
		if frame.IsMovable(minimapFrame) then
			frame.StartMoving(minimapFrame)
		end
	end)
	self.SetScript(Minimap, "OnDragStop", function(minimapFrame)
		frame.StopMovingOrSizing(minimapFrame)
		local a, _, b, c, d = frame.GetPoint(minimapFrame)
		frame.db.profile.position[1] = a
		frame.db.profile.position[2] = b
		frame.db.profile.position[3] = c
		frame.db.profile.position[4] = d
	end)
	self.SetMovable(Minimap, not self.db.profile.lock)

	if self.db.profile.scale ~= 1 then -- Non-default
		self.SetScale(Minimap, self.db.profile.scale)
	end
	self.SetSize(Minimap, self.db.profile.size, self.db.profile.size)
	-- I'm not sure of a better way to update the render layer to the new size
	if Minimap:GetZoom() ~= 5 then
		if Minimap_ZoomInClick then -- XXX Dragonflight compat
			Minimap_ZoomInClick()
			Minimap_ZoomOutClick()
		else
			Minimap.ZoomIn:Click()
			Minimap.ZoomOut:Click()
		end
	else
		if Minimap_ZoomInClick then -- XXX Dragonflight compat
			Minimap_ZoomOutClick()
			Minimap_ZoomInClick()
		else
			Minimap.ZoomOut:Click()
			Minimap.ZoomIn:Click()
		end
	end

	ldbi:SetButtonRadius(self.db.profile.radius) -- Do this after changing size as an easy way to avoid having to call :Refresh
	if MinimapNorthTag then -- XXX Dragonflight compat
		self.SetParent(MinimapNorthTag, self) -- North tag (static minimap)
		-- When rotating minimap is enabled, it has it's own special north tag. I don't think we need to hide it
		--self.SetParent(MinimapCompassTexture, self) -- North tag & compass (when rotating minimap is enabled)
		self.SetParent(MinimapBorderTop, self) -- Zone text border
		self.SetParent(MinimapBorder, self) -- Minimap border
	else
		self.SetParent(MinimapBackdrop, self) -- N/E/S/W circular indicator
	end

	local shape = self.db.profile.shape
	if shape == "SQUARE" then
		Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
		mask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
		if HybridMinimap then
			HybridMinimap.MapCanvas:SetUseMaskTexture(false)
			HybridMinimap.CircleMask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
			HybridMinimap.MapCanvas:SetUseMaskTexture(true)
		end
	else
		Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
		mask:SetTexture("Interface\\AddOns\\BasicMinimap\\circle")
		if HybridMinimap then
			HybridMinimap.MapCanvas:SetUseMaskTexture(false)
			HybridMinimap.CircleMask:SetTexture("Interface\\AddOns\\BasicMinimap\\circle")
			HybridMinimap.MapCanvas:SetUseMaskTexture(true)
		end
	end

	-- Removes the circular "waffle-like" texture that shows when using a non-circular minimap in the blue quest objective area.
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetArchBlobRingAlpha(0)
	Minimap:SetQuestBlobRingScalar(0)
	Minimap:SetQuestBlobRingAlpha(0)

	-- Zoom buttons
	if MinimapZoomIn then -- XXX Dragonflight compat
		if not self.db.profile.zoomBtn then
			self.SetParent(MinimapZoomIn, self)
			self.SetParent(MinimapZoomOut, self)
		else
			self.SetParent(MinimapZoomIn, Minimap)
			self.SetParent(MinimapZoomOut, Minimap)
		end
	else
		if not self.db.profile.zoomBtn then
			self.SetParent(Minimap.ZoomIn, self)
			self.SetParent(Minimap.ZoomOut, self)
		else
			self.SetParent(Minimap.ZoomIn, Minimap)
			self.SetParent(Minimap.ZoomOut, Minimap)
		end
	end

	-- New mail button
	if self.db.profile.mail then
		self.SetParent(MinimapCluster.IndicatorFrame.MailFrame, Minimap)
	else
		self.SetParent(MinimapCluster.IndicatorFrame.MailFrame, self)
	end
	-- New Crafting Order button
	if self.db.profile.craftingOrder then
		self.SetParent(MinimapCluster.IndicatorFrame.CraftingOrderFrame, Minimap)
	else
		self.SetParent(MinimapCluster.IndicatorFrame.CraftingOrderFrame, self)
	end
	-- Addon Compartment
	if self.db.profile.addonCompartment then
		self.SetParent(AddonCompartmentFrame, Minimap)
	else
		self.SetParent(AddonCompartmentFrame, self)
	end

	-- XXX hopefuly temporary workaround for line 376 of Minimap.lua
	self.Layout = function() end
	Minimap.Layout = self.Layout

	self.SetParent(GameTimeFrame, Minimap)

	-- World map button
	if MiniMapWorldMapButton then -- XXX Dragonflight compat
		self.SetParent(MiniMapWorldMapButton, self)
	else
		local overlayMail = MinimapCluster.IndicatorFrame.MailFrame:CreateTexture(nil, "OVERLAY")
		overlayMail:SetSize(53,53)
		overlayMail:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlayMail:SetPoint("CENTER", MiniMapMailIcon, "CENTER", 10, -10)
		local backgroundMail = MinimapCluster.IndicatorFrame.MailFrame:CreateTexture(nil, "BACKGROUND")
		backgroundMail:SetSize(25,25)
		backgroundMail:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		backgroundMail:SetPoint("CENTER", MiniMapMailIcon, "CENTER")

		local overlayCraftingOrder = MinimapCluster.IndicatorFrame.CraftingOrderFrame:CreateTexture(nil, "OVERLAY")
		overlayCraftingOrder:SetSize(53,53)
		overlayCraftingOrder:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlayCraftingOrder:SetPoint("CENTER", MiniMapCraftingOrderIcon, "CENTER", 10, -10)
		local backgroundCraftingOrder = MinimapCluster.IndicatorFrame.CraftingOrderFrame:CreateTexture(nil, "BACKGROUND")
		backgroundCraftingOrder:SetSize(25,25)
		backgroundCraftingOrder:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		backgroundCraftingOrder:SetPoint("CENTER", MiniMapCraftingOrderIcon, "CENTER")

		local overlayAddonCompartment = AddonCompartmentFrame:CreateTexture(nil, "OVERLAY")
		overlayAddonCompartment:SetSize(53,53)
		overlayAddonCompartment:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlayAddonCompartment:SetPoint("CENTER", AddonCompartmentFrame, "CENTER", 10, -10)
		local backgroundAddonCompartment = AddonCompartmentFrame:CreateTexture(nil, "BACKGROUND")
		backgroundAddonCompartment:SetSize(25,25)
		backgroundAddonCompartment:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		backgroundAddonCompartment:SetPoint("CENTER", AddonCompartmentFrame, "CENTER")

		local overlayCalendar = GameTimeFrame:CreateTexture(nil, "OVERLAY")
		overlayCalendar:SetSize(53,53)
		overlayCalendar:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlayCalendar:SetPoint("CENTER", GameTimeFrame, "CENTER", 10, -10)
		local backgroundCalendar = GameTimeFrame:CreateTexture(nil, "BACKGROUND")
		backgroundCalendar:SetSize(25,25)
		backgroundCalendar:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		backgroundCalendar:SetPoint("CENTER", GameTimeFrame, "CENTER")

		local overlayZoomIn = Minimap.ZoomIn:CreateTexture(nil, "OVERLAY")
		overlayZoomIn:SetSize(53,53)
		overlayZoomIn:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlayZoomIn:SetPoint("CENTER", Minimap.ZoomIn, "CENTER", 10, -10)
		local backgroundZoomIn = Minimap.ZoomIn:CreateTexture(nil, "BACKGROUND")
		backgroundZoomIn:SetSize(25,25)
		backgroundZoomIn:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		backgroundZoomIn:SetPoint("CENTER", Minimap.ZoomIn, "CENTER")

		local overlayZoomOut = Minimap.ZoomOut:CreateTexture(nil, "OVERLAY")
		overlayZoomOut:SetSize(53,53)
		overlayZoomOut:SetTexture(136430) -- 136430 = Interface\\Minimap\\MiniMap-TrackingBorder
		overlayZoomOut:SetPoint("CENTER", Minimap.ZoomOut, "CENTER", 10, -10)
		local backgroundZoomOut = Minimap.ZoomOut:CreateTexture(nil, "BACKGROUND")
		backgroundZoomOut:SetSize(25,25)
		backgroundZoomOut:SetTexture(136467) -- 136467 = Interface\\Minimap\\UI-Minimap-Background
		backgroundZoomOut:SetPoint("CENTER", Minimap.ZoomOut, "CENTER")
	end

	-- Tracking button
	if MiniMapTracking then -- XXX Dragonflight compat
		self.SetParent(MiniMapTracking, self)
	else
		self.SetParent(MinimapCluster.Tracking, self)
		self.SetParent(TrackingButton, Minimap)
		self.ClearAllPoints(TrackingButton)
		self.SetPoint(TrackingButton, "CENTER")
		self.SetFixedFrameStrata(TrackingButton, false)
		self.SetFrameStrata(TrackingButton, "BACKGROUND")
		self.SetFixedFrameStrata(TrackingButton, true)
		TrackingButton:SetMenuAnchor(AnchorUtil.CreateAnchor("CENTER", Minimap, "CENTER"))
	end

	-- Difficulty indicators
	if not self.db.profile.raidDiffIcon then
		if MiniMapInstanceDifficulty then
			self.SetParent(MiniMapInstanceDifficulty, self)
			self.SetParent(GuildInstanceDifficulty, self)
			self.SetParent(MiniMapChallengeMode, self)
		else
			self.SetParent(MinimapCluster.InstanceDifficulty, self)
		end
	else
		if MiniMapInstanceDifficulty then
			self.SetParent(MiniMapInstanceDifficulty, Minimap)
			self.SetParent(GuildInstanceDifficulty, Minimap)
			self.SetParent(MiniMapChallengeMode, Minimap)
		else
			self.SetParent(MinimapCluster.InstanceDifficulty, Minimap)
		end
	end

	-- Missions button
	if GarrisonLandingPageMinimapButton then -- XXX Dragonflight compat
		self.SetParent(GarrisonLandingPageMinimapButton, Minimap)
		self.SetSize(GarrisonLandingPageMinimapButton, 36, 36) -- Shrink the missions button
		-- Stop Blizz changing the icon size || GarrisonLandingPageMinimapButton_UpdateIcon() >> SetLandingPageIconFromAtlases() >> self:SetSize()
		hooksecurefunc(GarrisonLandingPageMinimapButton, "SetSize", function()
			frame.SetSize(GarrisonLandingPageMinimapButton, 36, 36)
		end)
		-- Stop Blizz moving the icon || GarrisonLandingPageMinimapButton_UpdateIcon() >> ApplyGarrisonTypeAnchor() >> anchor:SetPoint()
		hooksecurefunc("GarrisonLandingPageMinimapButton_UpdateIcon", function() -- GarrisonLandingPageMinimapButton, "SetPoint" || LDBI would call :SetPoint and cause an infinite loop
			frame.ClearAllPoints(GarrisonLandingPageMinimapButton)
			ldbi:SetButtonToPosition(GarrisonLandingPageMinimapButton, 190)
		end)
		if not self.db.profile.missions then
			self.SetParent(GarrisonLandingPageMinimapButton, self)
		end
	else
		self.SetParent(ExpansionLandingPageMinimapButton, Minimap)
		self.SetSize(ExpansionLandingPageMinimapButton, 36, 36) -- Shrink the missions button
		-- Stop Blizz changing the icon size || Minimap.lua ExpansionLandingPageMinimapButtonMixin:UpdateIcon() >> SetLandingPageIconFromAtlases() >> self:SetSize()
		hooksecurefunc(ExpansionLandingPageMinimapButton, "SetSize", function()
			frame.SetSize(ExpansionLandingPageMinimapButton, 36, 36)
		end)
		-- Stop Blizz moving the icon || Minimap.lua ExpansionLandingPageMinimapButtonMixin:UpdateIcon() >> self:UpdateIconForGarrison() >> ApplyGarrisonTypeAnchor() >> anchor:SetPoint()
		hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIconForGarrison", function() -- ExpansionLandingPageMinimapButton, "SetPoint" || LDBI would call :SetPoint and cause an infinite loop
			frame.ClearAllPoints(ExpansionLandingPageMinimapButton)
			ldbi:SetButtonToPosition(ExpansionLandingPageMinimapButton, self.db.profile.blizzButtonLocation.missions)
		end)
		-- Stop Blizz moving the icon || Minimap.lua ExpansionLandingPageMinimapButtonMixin:SetLandingPageIconOffset() >> anchor:SetPoint()
		hooksecurefunc(ExpansionLandingPageMinimapButton, "SetLandingPageIconOffset", function() -- ExpansionLandingPageMinimapButton, "SetPoint" || LDBI would call :SetPoint and cause an infinite loop
			frame.ClearAllPoints(ExpansionLandingPageMinimapButton)
			ldbi:SetButtonToPosition(ExpansionLandingPageMinimapButton, self.db.profile.blizzButtonLocation.missions)
		end)
		if not self.db.profile.missions then
			self.SetParent(ExpansionLandingPageMinimapButton, self)
		end
	end

	-- PvE/PvP Queue button
	if QueueStatusMinimapButton then -- XXX Dragonflight compat
		self.SetParent(QueueStatusMinimapButton, Minimap)
	end

	-- Update all blizz button positions
	for nickName, button in next, blizzButtonNicknames do
		self.ClearAllPoints(button)
		ldbi:SetButtonToPosition(button, self.db.profile.blizzButtonLocation[nickName])
	end

	-- This is our method of cancelling timers, we only let the very last scheduled timer actually run the code.
	-- We do this by using a simple counter, which saves us using the more expensive C_Timer.NewTimer API.
	local started, current = 0, 0
	--[[ Auto Zoom Out ]]--
	local zoomOut = function()
		current = current + 1
		if started == current then
			Minimap:SetZoom(0)
			if MinimapZoomIn then -- XXX Dragonflight compat
				MinimapZoomIn:Enable()
				MinimapZoomOut:Disable()
			else
				Minimap.ZoomIn:Enable()
				Minimap.ZoomOut:Disable()
			end
			started, current = 0, 0
		end
	end

	local zoomBtnFunc = function()
		if frame.db.profile.autoZoom then
			started = started + 1
			C_Timer.After(10, zoomOut)
		end
	end
	zoomBtnFunc()
	self.HookScript(Minimap.ZoomIn, "OnClick", zoomBtnFunc)
	self.HookScript(Minimap.ZoomOut, "OnClick", zoomBtnFunc)

	self.EnableMouseWheel(Minimap, true)
	self.SetScript(Minimap, "OnMouseWheel", function(_, d)
		if d > 0 then
			Minimap.ZoomIn:Click()
		elseif d < 0 then
			Minimap.ZoomOut:Click()
		end
	end)

	self.SetScript(Minimap, "OnMouseUp", function(_, btn)
		if btn == frame.db.profile.calendarBtn then
			GameTimeFrame:Click()
		elseif btn == frame.db.profile.trackingBtn then
			TrackingButton:OpenMenu()
		elseif btn == frame.db.profile.missionsBtn then
			ExpansionLandingPageMinimapButton:Click()
		elseif btn == frame.db.profile.mapBtn then
			if not InCombatLockdown() then
				ToggleWorldMap()
			end
		elseif btn == "LeftButton" then
			Minimap:OnClick()
		end
	end)
end

function frame:CALENDAR_ACTION_PENDING()
	if C_Calendar.GetNumPendingInvites() < 1 then
		self.Hide(GameTimeFrame)
	else
		self.Show(GameTimeFrame)
	end
end
frame.CALENDAR_UPDATE_PENDING_INVITES = frame.CALENDAR_ACTION_PENDING
frame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
frame:RegisterEvent("CALENDAR_ACTION_PENDING")

function frame:PET_BATTLE_OPENING_START()
	self.Hide(Minimap)
end
frame:RegisterEvent("PET_BATTLE_OPENING_START")

function frame:PET_BATTLE_CLOSE()
	self.Show(Minimap)
end
frame:RegisterEvent("PET_BATTLE_CLOSE")

function frame:ADDON_LOADED(event, addon)
	if addon == "Blizzard_HybridMinimap" then
		self:UnregisterEvent(event)
		local shape = self.db.profile.shape
		if shape == "SQUARE" then
			HybridMinimap.MapCanvas:SetUseMaskTexture(false)
			HybridMinimap.CircleMask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
			HybridMinimap.MapCanvas:SetUseMaskTexture(true)
		else
			HybridMinimap.MapCanvas:SetUseMaskTexture(false)
			HybridMinimap.CircleMask:SetTexture("Interface\\AddOns\\BasicMinimap\\circle")
			HybridMinimap.MapCanvas:SetUseMaskTexture(true)
		end
	end
end
frame:RegisterEvent("ADDON_LOADED")

-- Hopefully temporary workaround for :GetUnboundedStringWidth returning 0 for foreign fonts at PLAYER_LOGIN on a cold boot, issue #19
function frame:LOADING_SCREEN_DISABLED(event)
	self:UnregisterEvent(event)
	self[event] = nil
	CreateClock(self)
	CreateCoords(self)
	local fullMinimapSize = self.db.profile.size + self.db.profile.borderSize
	CreateZoneText(self, fullMinimapSize)
end
frame:RegisterEvent("LOADING_SCREEN_DISABLED")

frame:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" and addon == "BasicMinimap" then
		if HybridMinimap then -- It somehow loaded before us
			self:UnregisterEvent(event) -- The mask will be applied in Login() so unregister
			self[event] = nil
		end
		Init(self)
	elseif event == "PLAYER_LOGIN" then
		self:UnregisterEvent(event)
		Login(self)
		self:SetScript("OnEvent", function(s, e, a)
			s[e](s, e, a)
		end)
	end
end)
frame:RegisterEvent("PLAYER_LOGIN")
