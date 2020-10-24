
local name = ...
local media = LibStub("LibSharedMedia-3.0")
local ldbi = LibStub("LibDBIcon-1.0")

local blizzButtonPositions = {
	[328] = MinimapZoomIn,
	[302] = MinimapZoomOut,
	[190] = GarrisonLandingPageMinimapButton,
	[230] = QueueStatusMinimapButton,
	[140] = MiniMapInstanceDifficulty,
	[141] = GuildInstanceDifficulty,
	[142] = MiniMapChallengeMode,
	[44] = GameTimeFrame,
	[20] = MiniMapMailFrame,
}

do
	local function openOpts()
		EnableAddOn("BasicMinimap_Options") -- Make sure it wasn't left disabled for whatever reason
		LoadAddOn("BasicMinimap_Options")
		LibStub("AceConfigDialog-3.0"):Open(name)
	end
	SlashCmdList.BASICMINIMAP = openOpts
	SLASH_BASICMINIMAP1 = "/bm"
	SLASH_BASICMINIMAP2 = "/basicminimap"
end

local frame = CreateFrame("Frame", name)
frame:Hide()
frame:SetScript("OnEvent", function(f, event, ...)
	f[event](f, event, ...)
end)
frame.blizzButtonPositions = blizzButtonPositions

function frame:HideButtons(_, _, name)
	ldbi:ShowOnEnter(name, true)
end

-- Init
function frame:ADDON_LOADED(event, addon)
	if addon == "BasicMinimap" then
		self:UnregisterEvent(event)
		self[event] = nil

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
				},
			},
		}
		self.db = LibStub("AceDB-3.0"):New("BasicMinimapSV", defaults, true)

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
			ldbi.RegisterCallback(self, "LibDBIcon_IconCreated", "HideButtons")
		end

		-- XXX temp 8.2.0
		self.db.profile.fontSize = nil
		self.db.profile.outline = nil
		self.db.profile.monochrome = nil
		self.db.profile.font = nil
	end
end
frame:RegisterEvent("ADDON_LOADED")

frame.SetParent(Minimap, UIParent)
-- Undo the damage caused by automagic fuckery when a frame changes parent
-- In other words, restore the minimap defaults to what they were, when it was parented to MinimapCluster
frame.SetFrameStrata(Minimap, "LOW")
frame.SetFrameLevel(Minimap, 1)

-- Enable
function frame:PLAYER_LOGIN(event)
	self:UnregisterEvent(event)
	self[event] = nil

	self:CALENDAR_UPDATE_PENDING_INVITES()

	local Minimap = Minimap
	self.EnableMouse(MinimapCluster, false)

	local tt = CreateFrame("GameTooltip", "BasicMinimapTooltip", UIParent, "GameTooltipTemplate")
	local fullMinimapSize = self.db.profile.size + self.db.profile.borderSize

	-- Backdrop, creating the border cleanly
	if self.db.profile.classcolor then
		local _, class = UnitClass("player")
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		local a = self.db.profile.colorBorder[4]
		self.db.profile.colorBorder = {color.r, color.g, color.b, a}
	end
	local backdrop = self.CreateTexture(Minimap, nil, "BACKGROUND")
	backdrop:SetPoint("CENTER", Minimap, "CENTER")
	backdrop:SetSize(fullMinimapSize, fullMinimapSize)
	backdrop:SetColorTexture(unpack(self.db.profile.colorBorder))
	local mask = self:CreateMaskTexture()
	mask:SetAllPoints(backdrop)
	mask:SetParent(Minimap)
	backdrop:AddMaskTexture(mask)
	frame.backdrop = backdrop
	frame.mask = mask

	self.ClearAllPoints(Minimap)
	self.SetPoint(Minimap, self.db.profile.position[1], UIParent, self.db.profile.position[2], self.db.profile.position[3], self.db.profile.position[4])
	self.RegisterForDrag(Minimap, "LeftButton")
	self.SetClampedToScreen(Minimap, true)

	self.SetScript(Minimap, "OnDragStart", function(self) if frame.IsMovable(self) then frame.StartMoving(self) end end)
	self.SetScript(Minimap, "OnDragStop", function(self)
		frame.StopMovingOrSizing(self)
		local a, _, b, c, d = frame.GetPoint(self)
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
	self.SetParent(MinimapCompassTexture, self) -- North tag & compass (when rotating minimap is enabled)
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
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetArchBlobRingAlpha(0)
	Minimap:SetQuestBlobRingScalar(0)
	Minimap:SetQuestBlobRingAlpha(0)

	-- Zoom buttons
	if not self.db.profile.zoomBtn then
		self.SetParent(MinimapZoomIn, self)
		self.SetParent(MinimapZoomOut, self)
	else
		self.SetParent(MinimapZoomIn, Minimap)
		self.SetParent(MinimapZoomOut, Minimap)
	end

	-- Clock
	self.ClearAllPoints(TimeManagerClockButton)
	self.SetPoint(TimeManagerClockButton, "TOPLEFT", backdrop, "BOTTOMLEFT", self.db.profile.clockConfig.x, self.db.profile.clockConfig.y)
	self.SetHeight(TimeManagerClockButton, self.db.profile.clockConfig.fontSize+1)
	do
		local clockFlags = nil
		if self.db.profile.clockConfig.monochrome and self.db.profile.clockConfig.outline ~= "NONE" then
			clockFlags = "MONOCHROME," .. self.db.profile.clockConfig.outline
		elseif self.db.profile.clockConfig.monochrome then
			clockFlags = "MONOCHROME"
		elseif self.db.profile.clockConfig.outline ~= "NONE" then
			clockFlags = self.db.profile.clockConfig.outline
		end
		TimeManagerClockTicker:SetFont(media:Fetch("font", self.db.profile.clockConfig.font), self.db.profile.clockConfig.fontSize, clockFlags)
		TimeManagerClockTicker:SetText("99:99")
		local width = TimeManagerClockTicker:GetUnboundedStringWidth()
		self.SetWidth(TimeManagerClockButton, width + 5)
	end
	TimeManagerClockTicker:SetTextColor(unpack(self.db.profile.clockConfig.color))
	TimeManagerClockTicker:SetJustifyH(self.db.profile.clockConfig.align)
	self.ClearAllPoints(TimeManagerClockTicker)
	self.SetAllPoints(TimeManagerClockTicker, TimeManagerClockButton)
	local clockBorder = self.GetRegions(TimeManagerClockButton)
	self.SetParent(clockBorder, self) -- Hide the border
	if not self.db.profile.clock then
		self.SetParent(TimeManagerClockButton, self)
	end

	-- World map button
	self.SetParent(MiniMapWorldMapButton, self)

	-- Zone text
	do
		-- Kill Blizz Frame
		local Parent = self.SetParent
		Parent(MinimapZoneTextButton, self)
		Parent(MinimapZoneText, self)
		MinimapCluster:UnregisterEvent("ZONE_CHANGED") -- Minimap.xml line 719-722 script "<OnLoad>" as of wow 9.0.1
		MinimapCluster:UnregisterEvent("ZONE_CHANGED_INDOORS")
		MinimapCluster:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
		local function block(self)
			Parent(self, frame)
		end
		hooksecurefunc(MinimapZoneTextButton, "SetParent", block)
		hooksecurefunc(MinimapZoneText, "SetParent", block)
	end
	local zoneText = CreateFrame("Frame", nil, Minimap) -- Create our own zone text
	zoneText:SetPoint("BOTTOM", backdrop, "TOP", self.db.profile.zoneTextConfig.x, self.db.profile.zoneTextConfig.y)
	local zoneTextFont = zoneText:CreateFontString()
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
		local function update(self) -- Minimap.lua line 47 function "Minimap_Update" as of wow 9.0.1
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

			if self:IsMouseOver() then
				self:GetScript("OnLeave")()
				self:GetScript("OnEnter")(self)
			end
		end
		update(zoneText)
		zoneText:SetScript("OnEvent", update)
		zoneText:SetScript("OnEnter", function(self) -- Minimap.lua line 68 function "Minimap_SetTooltip" as of wow 9.0.1
			tt:SetOwner(self, "ANCHOR_LEFT")
			local pvpType, _, factionName = GetZonePVPInfo()
			local zoneName = GetZoneText()
			local subzoneName = GetSubZoneText()
			if subzoneName == zoneName then
				subzoneName = ""
			end
			tt:AddLine(zoneName, 1.0, 1.0, 1.0)
			if pvpType == "sanctuary" then
				tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorSanctuary))
				tt:AddLine(SANCTUARY_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorSanctuary))
			elseif pvpType == "arena" then
				tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorArena))
				tt:AddLine(FREE_FOR_ALL_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorArena))
			elseif pvpType == "friendly" then
				if factionName and factionName ~= "" then
					tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorFriendly))
					tt:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), unpack(frame.db.profile.zoneTextConfig.colorFriendly))
				end
			elseif pvpType == "hostile" then
				if factionName and factionName ~= "" then
					tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorHostile))
					tt:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), unpack(frame.db.profile.zoneTextConfig.colorHostile))
				end
			elseif pvpType == "contested" then
				tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorContested))
				tt:AddLine(CONTESTED_TERRITORY, unpack(frame.db.profile.zoneTextConfig.colorContested))
			elseif pvpType == "combat" then
				tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorArena))
				tt:AddLine(COMBAT_ZONE, unpack(frame.db.profile.zoneTextConfig.colorArena))
			else
				tt:AddLine(subzoneName, unpack(frame.db.profile.zoneTextConfig.colorNormal))
			end
			tt:Show()
		end)
		zoneText:SetScript("OnLeave", function() tt:Hide() end)
	end
	self.zonetext = zoneText
	self.zonetext.text = zoneTextFont

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

	-- Tracking button
	self.SetParent(MiniMapTracking, self)

	-- Difficulty indicators
	if not self.db.profile.raidDiffIcon then
		self.SetParent(MiniMapInstanceDifficulty, self)
		self.SetParent(GuildInstanceDifficulty, self)
		self.SetParent(MiniMapChallengeMode, self)
	else
		self.SetParent(MiniMapInstanceDifficulty, Minimap)
		self.SetParent(GuildInstanceDifficulty, Minimap)
		self.SetParent(MiniMapChallengeMode, Minimap)
	end

	-- Missions button
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

	-- PvE/PvP Queue button
	self.SetParent(QueueStatusMinimapButton, Minimap)

	-- Update all blizz button positions
	for position, button in next, blizzButtonPositions do
		self.ClearAllPoints(button)
		ldbi:SetButtonToPosition(button, position)
	end

	-- This is our method of cancelling timers, we only let the very last scheduled timer actually run the code.
	-- We do this by using a simple counter, which saves us using the more expensive C_Timer.NewTimer API.
	local started, current = 0, 0
	--[[ Auto Zoom Out ]]--
	local zoomOut = function()
		current = current + 1
		if started == current then
			for i = 1, Minimap:GetZoom() or 0 do
				Minimap_ZoomOutClick() -- Call it directly so we don't run our own hook
			end
			started, current = 0, 0
		end
	end

	local zoomBtnFunc = function()
		if frame.db.profile.autoZoom then
			started = started + 1
			C_Timer.After(4, zoomOut)
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

	self.SetScript(Minimap, "OnMouseUp", function(self, btn)
		if btn == frame.db.profile.calendarBtn then
			GameTimeFrame:Click()
		elseif btn == frame.db.profile.trackingBtn then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
		elseif btn == frame.db.profile.missionsBtn then
			GarrisonLandingPageMinimapButton:Click()
		elseif btn == frame.db.profile.mapBtn then
			MiniMapWorldMapButton:Click()
		elseif btn == "LeftButton" then
			Minimap_OnClick(self)
		end
	end)
end
frame:RegisterEvent("PLAYER_LOGIN")

function frame:CALENDAR_ACTION_PENDING()
	if C_Calendar.GetNumPendingInvites() < 1 then
		frame.Hide(GameTimeFrame)
	else
		frame.Show(GameTimeFrame)
	end
end
frame.CALENDAR_UPDATE_PENDING_INVITES = frame.CALENDAR_ACTION_PENDING
frame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
frame:RegisterEvent("CALENDAR_ACTION_PENDING")

function frame:PET_BATTLE_OPENING_START()
	frame.Hide(Minimap)
end
frame:RegisterEvent("PET_BATTLE_OPENING_START")

function frame:PET_BATTLE_CLOSE()
	frame.Show(Minimap)
end
frame:RegisterEvent("PET_BATTLE_CLOSE")

function frame:PLAYER_ENTERING_WORLD() -- XXX Investigate if it's safe to unregister this after the first application
	if C_Minimap.ShouldUseHybridMinimap() and HybridMinimap then
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
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
