
local name = ...
local media = LibStub("LibSharedMedia-3.0")
local ldbi = LibStub("LibDBIcon-1.0")

local backdrops = {}

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
frame.backdrops = backdrops

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
				shape = "SQUARE",
				clock = true,
				zoneText = true,
				missions = true,
				raidDiffIcon = true,
				zoomBtn = false,
				autoZoom = true,
				hideAddons = true,
				position = {"CENTER", "CENTER", 0, 0},
				borderSize = 3,
				size = 140,
				scale = 1,
				fontSize = 12,
				radius = 5,
				outline = "OUTLINE",
				monochrome = false,
				font = media:GetDefault("font"),
				colorBorder = {0,0.6,0,1},
				calendarBtn = "RightButton",
				trackingBtn = "MiddleButton",
				missionsBtn = "None",
				mapBtn = "None",
			}
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
	end
end
frame:RegisterEvent("ADDON_LOADED")

-- Enable
function frame:PLAYER_LOGIN(event)
	self:UnregisterEvent(event)
	self[event] = nil

	self:CALENDAR_UPDATE_PENDING_INVITES()

	local Minimap = Minimap
	Minimap:SetParent(UIParent)
	MinimapCluster:EnableMouse(false)

	-- Backdrops, creating the border cleanly
	local size = self.db.profile.borderSize
	local r, g, b, a = unpack(self.db.profile.colorBorder)
	for i = 1, 8 do
		backdrops[i] = Minimap:CreateTexture()
		backdrops[i]:SetColorTexture(r, g, b, a)
		backdrops[i]:SetWidth(size)
		backdrops[i]:SetHeight(size)
	end
	backdrops[1]:SetPoint("BOTTOMRIGHT", Minimap, "TOPLEFT") -- Top-left corner
	backdrops[2]:SetPoint("BOTTOMLEFT", Minimap, "TOPRIGHT") -- Top-right corner
	backdrops[3]:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT") -- Bottom-left corner
	backdrops[4]:SetPoint("TOPLEFT", Minimap, "BOTTOMRIGHT") -- Bottom-right corner
	backdrops[5]:SetPoint("TOPLEFT", backdrops[1], "TOPRIGHT") -- Top border
	backdrops[5]:SetPoint("BOTTOMRIGHT", backdrops[2], "BOTTOMLEFT")
	backdrops[6]:SetPoint("TOPLEFT", backdrops[2], "BOTTOMLEFT") -- Right border
	backdrops[6]:SetPoint("BOTTOMRIGHT", backdrops[4], "TOPRIGHT")
	backdrops[7]:SetPoint("TOPLEFT", backdrops[3], "TOPRIGHT") -- Bottom border
	backdrops[7]:SetPoint("BOTTOMRIGHT", backdrops[4], "BOTTOMLEFT")
	backdrops[8]:SetPoint("TOPLEFT", backdrops[1], "BOTTOMLEFT") -- Left border
	backdrops[8]:SetPoint("BOTTOMRIGHT", backdrops[3], "TOPRIGHT")

	Minimap:ClearAllPoints()
	Minimap:SetPoint(self.db.profile.position[1], UIParent, self.db.profile.position[2], self.db.profile.position[3], self.db.profile.position[4])
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(true)

	Minimap:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local a, _, b, c, d = self:GetPoint()
		frame.db.profile.position[1] = a
		frame.db.profile.position[2] = b
		frame.db.profile.position[3] = c
		frame.db.profile.position[4] = d
	end)
	Minimap:SetMovable(self.db.profile.lock)

	if self.db.profile.scale ~= 1 then -- Non-default
		Minimap:SetScale(self.db.profile.scale)
	end
	if self.db.profile.size ~= 140 then -- Non-default
		Minimap:SetSize(self.db.profile.size, self.db.profile.size)
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
	MinimapNorthTag:SetParent(self) -- North tag (static minimap)
	MinimapCompassTexture:SetParent(self) -- North tag & compass (when rotating minimap is enabled)

	MinimapBorder:Hide()
	MinimapBorderTop:Hide()
	if self.db.profile.shape == "SQUARE" then
		Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
	else
		for i = 1, 8 do
			backdrops[i]:Hide()
		end
	end

	-- Removes the circular "waffle-like" texture that shows when using a non-circular minimap in the blue quest objective area.
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetArchBlobRingAlpha(0)
	Minimap:SetQuestBlobRingScalar(0)
	Minimap:SetQuestBlobRingAlpha(0)

	-- Zoom buttons
	MinimapZoomIn:SetParent(Minimap)
	MinimapZoomIn:ClearAllPoints()
	MinimapZoomIn:SetPoint("RIGHT", Minimap, "RIGHT", self.db.profile.shape == "ROUND" and 10 or 20, self.db.profile.shape == "ROUND" and -40 or -50)
	MinimapZoomOut:SetParent(Minimap)
	MinimapZoomOut:ClearAllPoints()
	MinimapZoomOut:SetPoint("BOTTOM", Minimap, "BOTTOM", self.db.profile.shape == "ROUND" and 40 or 50, self.db.profile.shape == "ROUND" and -10 or -20)
	if not self.db.profile.zoomBtn then
		MinimapZoomIn:SetParent(self)
		MinimapZoomOut:SetParent(self)
	end

	-- Create font flag
	local flags = nil
	if self.db.profile.monochrome and self.db.profile.outline ~= "NONE" then
		flags = "MONOCHROME," .. self.db.profile.outline
	elseif self.db.profile.monochrome then
		flags = "MONOCHROME"
	elseif self.db.profile.outline ~= "NONE" then
		flags = self.db.profile.outline
	end
	--

	-- Clock
	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint("TOP", backdrops[7], "BOTTOM", 0, 6)
	TimeManagerClockButton:SetWidth(100)
	TimeManagerClockTicker:SetFont(media:Fetch("font", self.db.profile.font), self.db.profile.fontSize, flags)
	TimeManagerClockButton:GetRegions():Hide() -- Hide the border
	if not self.db.profile.clock then
		TimeManagerClockButton:SetParent(self)
	end

	-- World map button
	MiniMapWorldMapButton:SetParent(self)

	-- Zone text
	MinimapZoneTextButton:SetParent(Minimap)
	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetPoint("BOTTOM", backdrops[5], "TOP", 0, 4)
	MinimapZoneText:SetFont(media:Fetch("font", self.db.profile.font), self.db.profile.fontSize, flags)
	if not self.db.profile.zoneText then
		MinimapZoneTextButton:SetParent(self)
	end

	-- Tracking button
	MiniMapTracking:SetParent(self)

	-- Difficulty indicators
	MiniMapInstanceDifficulty:SetParent(Minimap)
	MiniMapInstanceDifficulty:ClearAllPoints()
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)
	GuildInstanceDifficulty:SetParent(Minimap)
	GuildInstanceDifficulty:ClearAllPoints()
	GuildInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)
	MiniMapChallengeMode:SetParent(Minimap)
	MiniMapChallengeMode:ClearAllPoints()
	MiniMapChallengeMode:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)
	if not self.db.profile.raidDiffIcon then
		MiniMapInstanceDifficulty:SetParent(self)
		GuildInstanceDifficulty:SetParent(self)
		MiniMapChallengeMode:SetParent(self)
	end

	-- Missions button
	GarrisonLandingPageMinimapButton:SetParent(Minimap)
	GarrisonLandingPageMinimapButton:SetSize(38, 38)
	GarrisonLandingPageMinimapButton:ClearAllPoints()
	GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -23, 15)
	if not self.db.profile.missions then
		GarrisonLandingPageMinimapButton:SetParent(self)
	end

	-- PvE/PvP Queue button
	QueueStatusMinimapButton:SetParent(Minimap)
	QueueStatusMinimapButton:ClearAllPoints()
	QueueStatusMinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -10, -10)

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
	MinimapZoomIn:HookScript("OnClick", zoomBtnFunc)
	MinimapZoomOut:HookScript("OnClick", zoomBtnFunc)

	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(_, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
	end)

	Minimap:SetScript("OnMouseUp", function(self, btn)
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
		GameTimeFrame:Hide()
	else
		GameTimeFrame:Show()
	end
end
frame.CALENDAR_UPDATE_PENDING_INVITES = frame.CALENDAR_ACTION_PENDING
frame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
frame:RegisterEvent("CALENDAR_ACTION_PENDING")

function frame:PET_BATTLE_OPENING_START()
	Minimap:Hide()
end
frame:RegisterEvent("PET_BATTLE_OPENING_START")

function frame:PET_BATTLE_CLOSE()
	Minimap:Show()
end
frame:RegisterEvent("PET_BATTLE_CLOSE")

