
local name = ...
local media = LibStub("LibSharedMedia-3.0")
local ldbi = LibStub("LibDBIcon-1.0")

local frame = CreateFrame("Frame", name)
local bmTooltip = CreateFrame("GameTooltip", "BasicMinimapTooltip", UIParent, "GameTooltipTemplate")
frame:Hide()

local blizzButtonNicknames = {
	zoomIn = MinimapZoomIn,
	zoomOut = MinimapZoomOut,
	difficulty = MiniMapInstanceDifficulty,
	calendar = GameTimeFrame,
	mail = MiniMapMailFrame,
	pvp = MiniMapBattlefieldFrame,
	lfg = MiniMapLFGFrame,
}
frame.blizzButtonNicknames = blizzButtonNicknames

do
	local function openOpts()
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
			autoZoom = true,
			hideAddons = true,
			position = {"CENTER", "CENTER", 0, 0},
			borderSize = 5,
			size = 140,
			scale = 1,
			radius = 5,
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
				difficulty = 140,
				calendar = 44,
				mail = 20,
				pvp = 210,
				lfg = 215,
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
		local GetMinimapZoneText, GetZonePVPInfo = GetMinimapZoneText, GetZonePVPInfo
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
	if self.db.profile.size ~= 140 then -- Non-default
		self.SetSize(Minimap, self.db.profile.size, self.db.profile.size)
		-- I'm not sure of a better way to update the render layer to the new size
		if Minimap:GetZoom() ~= 5 then
			Minimap_ZoomInClick()
			Minimap_ZoomOutClick()
		else
			Minimap_ZoomOutClick()
			Minimap_ZoomInClick()
		end
	end
	ldbi:SetButtonRadius(self.db.profile.radius) -- Do this after changing size as an easy way to avoid having to call :Refresh
	self.SetParent(MinimapNorthTag, self) -- North tag (static minimap)
	-- When rotating minimap is enabled, it has it's own special north tag. I don't think we need to hide it
	--self.SetParent(MinimapCompassTexture, self) -- North tag & compass (when rotating minimap is enabled)
	self.SetParent(MinimapBorderTop, self) -- Zone text border
	self.SetParent(MinimapBorder, self) -- Minimap border

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
	--Minimap:SetArchBlobRingScalar(0)
	--Minimap:SetArchBlobRingAlpha(0)
	--Minimap:SetQuestBlobRingScalar(0)
	--Minimap:SetQuestBlobRingAlpha(0)

	-- Zoom buttons
	if not self.db.profile.zoomBtn then
		self.SetParent(MinimapZoomIn, self)
		self.SetParent(MinimapZoomOut, self)
	else
		self.SetParent(MinimapZoomIn, Minimap)
		self.SetParent(MinimapZoomOut, Minimap)
	end

	-- New mail button
	if self.db.profile.mail then
		self.SetParent(MiniMapMailFrame, Minimap)
	else
		self.SetParent(MiniMapMailFrame, self)
	end

	-- World map button
	self.SetParent(MiniMapWorldMapButton, self)

	-- Tracking button
	self.SetParent(MiniMapTracking, self)

	-- Classic Wrath
	self.SetParent(GameTimeFrame, Minimap) -- Calendar isn't parented to Minimap in Wrath

	-- Difficulty indicators
	if not self.db.profile.raidDiffIcon then
		self.SetParent(MiniMapInstanceDifficulty, self)
		if GuildInstanceDifficulty then
			self.SetParent(GuildInstanceDifficulty, self)
		end
		--self.SetParent(MiniMapChallengeMode, self)
	else
		self.SetParent(MiniMapInstanceDifficulty, Minimap)
		if GuildInstanceDifficulty then
			self.SetParent(GuildInstanceDifficulty, Minimap)
		end
		--self.SetParent(MiniMapChallengeMode, Minimap)
	end

	-- Missions button
	--self.SetParent(GarrisonLandingPageMinimapButton, Minimap)
	--self.SetSize(GarrisonLandingPageMinimapButton, 36, 36) -- Shrink the missions button
	-- Stop Blizz changing the icon size || GarrisonLandingPageMinimapButton_UpdateIcon() >> SetLandingPageIconFromAtlases() >> self:SetSize()
	--hooksecurefunc(GarrisonLandingPageMinimapButton, "SetSize", function()
	--	frame.SetSize(GarrisonLandingPageMinimapButton, 36, 36)
	--end)
	-- Stop Blizz moving the icon || GarrisonLandingPageMinimapButton_UpdateIcon() >> ApplyGarrisonTypeAnchor() >> anchor:SetPoint()
	--hooksecurefunc("GarrisonLandingPageMinimapButton_UpdateIcon", function() -- GarrisonLandingPageMinimapButton, "SetPoint" || LDBI would call :SetPoint and cause an infinite loop
	--	frame.ClearAllPoints(GarrisonLandingPageMinimapButton)
	--	ldbi:SetButtonToPosition(GarrisonLandingPageMinimapButton, self.db.profile.blizzButtonLocation.missions)
	--end)
	--if not self.db.profile.missions then
	--	self.SetParent(GarrisonLandingPageMinimapButton, self)
	--end

	-- PvE/PvP Queue button
	--self.SetParent(QueueStatusMinimapButton, Minimap)
	self.SetParent(MiniMapBattlefieldFrame, Minimap) -- QueueStatusMinimapButton (Retail) > MiniMapBattlefieldFrame (Classic)
	self.SetParent(MiniMapLFGFrame, Minimap) -- Special LFG button for classic/TBC

	-- Update all blizz button positions
	for nickName, button in next, blizzButtonNicknames do
		self.ClearAllPoints(button)
		ldbi:SetButtonToPosition(button, self.db.profile.blizzButtonLocation[nickName])
		if nickName == "difficulty" and GuildInstanceDifficulty then
			self.ClearAllPoints(GuildInstanceDifficulty)
			ldbi:SetButtonToPosition(GuildInstanceDifficulty, self.db.profile.blizzButtonLocation[nickName])
		end
	end

	-- This is our method of cancelling timers, we only let the very last scheduled timer actually run the code.
	-- We do this by using a simple counter, which saves us using the more expensive C_Timer.NewTimer API.
	local started, current = 0, 0
	--[[ Auto Zoom Out ]]--
	local zoomOut = function()
		current = current + 1
		if started == current then
			Minimap:SetZoom(0)
			MinimapZoomIn:Enable()
			MinimapZoomOut:Disable()
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
	self.HookScript(MinimapZoomIn, "OnClick", zoomBtnFunc)
	self.HookScript(MinimapZoomOut, "OnClick", zoomBtnFunc)

	self.EnableMouseWheel(Minimap, true)
	self.SetScript(Minimap, "OnMouseWheel", function(_, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
	end)

	self.SetScript(Minimap, "OnMouseUp", function(minimapFrame, btn)
		if btn == frame.db.profile.calendarBtn then
			GameTimeFrame:Click()
		elseif btn == frame.db.profile.trackingBtn then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, minimapFrame)
		--elseif btn == frame.db.profile.missionsBtn then
		--	GarrisonLandingPageMinimapButton:Click()
		elseif btn == frame.db.profile.mapBtn then
			MiniMapWorldMapButton:Click()
		elseif btn == "LeftButton" then
			Minimap_OnClick(minimapFrame)
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
