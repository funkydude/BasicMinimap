
local name, BM = ...

local buttonValues = {RightButton = KEY_BUTTON2, MiddleButton = KEY_BUTTON3,
	Button4 = KEY_BUTTON4, Button5 = KEY_BUTTON5, Button6 = KEY_BUTTON6,
	Button7 = KEY_BUTTON7, Button8 = KEY_BUTTON8, Button9 = KEY_BUTTON9,
	Button10 = KEY_BUTTON10, Button11 = KEY_BUTTON11, Button12 = KEY_BUTTON12,
	Button13 = KEY_BUTTON13, Button14 = KEY_BUTTON14, Button15 = KEY_BUTTON15,
	None = NONE
}

local hideFrame = function(frame) frame:Hide() end
local noop = function() end
local backdrops = {}
local db

local options = {
	type = "group",
	name = name,
	args = {
		btndesc = {
			name = BM.BUTTONDESC,
			order = 1, type = "description",
		},
		calendarbtn = {
			name = BM.CALENDAR,
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
			name = BM.CLASSCOLORED,
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
			name = BM.BORDERSIZE,
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
			name = BM.BUTTONS,
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
			name = BM.ZONETEXT,
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
			name = BM.CLASSHALL,
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
			name = BM.SCALE,
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
			name = BM.SHAPE,
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
			name = BM.AUTOZOOM,
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
}

LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name, options, true)
LibStub("AceConfigDialog-3.0"):SetDefaultSize(options.name, 400, 540)
SlashCmdList.BASICMINIMAP = function() LibStub("AceConfigDialog-3.0"):Open(name) end
SLASH_BASICMINIMAP1 = "/bm"
SLASH_BASICMINIMAP2 = "/basicminimap"

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(f, event, ...)
	f[event](f, event, ...)
end)

-- Init
function frame:ADDON_LOADED(event, addon)
	if addon == "BasicMinimap" then
		self:UnregisterEvent(event)
		self[event] = nil

		if not BasicMinimapDB then
			BasicMinimapDB = {
				x = 0, y = 0,
				point = "CENTER", relpoint = "CENTER",
				borderR = 0, borderG = 0.6, borderB = 0
			}
		end
		db = BasicMinimapDB

		--Return minimap shape for other addons
		if not db.round then function GetMinimapShape() return "SQUARE" end end
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
	-- Clockwise: TOP, RIGHT, BOTTOM, LEFT
	local b = db.borderSize or 3
	local b2 = b*2
	local w, h = Minimap:GetWidth()+b2, Minimap:GetHeight()+b2
	for i = 1, 4 do
		backdrops[i] = Minimap:CreateTexture()
		backdrops[i]:SetColorTexture(db.borderR, db.borderG, db.borderB)
		backdrops[i]:SetWidth(i%2==0 and b or w)
		backdrops[i]:SetHeight(i%2==0 and h or b)
	end
	backdrops[1]:SetPoint("BOTTOM", Minimap, "TOP")
	backdrops[2]:SetPoint("LEFT", Minimap, "RIGHT")
	backdrops[3]:SetPoint("TOP", Minimap, "BOTTOM")
	backdrops[4]:SetPoint("RIGHT", Minimap, "LEFT")

	Minimap:ClearAllPoints()
	Minimap:SetPoint(db.point, nil, db.relpoint, db.x, db.y)
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(true)

	Minimap:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = self:GetPoint()
		db.point, db.relpoint, db.x, db.y = p, rp, x, y
	end)

	if not db.lock then Minimap:SetMovable(true) end

	Minimap:SetScale(db.scale or 1)
	MinimapNorthTag.Show = MinimapNorthTag.Hide
	MinimapNorthTag:Hide()

	MinimapBorder:Hide()
	MinimapBorderTop:Hide()
	if not db.round then
		Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
	else
		for i = 1, 4 do
			backdrops[i]:Hide()
		end
	end

	-- Removes the circular "waffle-like" texture that shows when using a non-circular minimap in the blue quest objective area.
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetArchBlobRingAlpha(0)
	Minimap:SetQuestBlobRingScalar(0)
	Minimap:SetQuestBlobRingAlpha(0)

	if not db.zoomBtn then
		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	else
		MinimapZoomIn:ClearAllPoints()
		MinimapZoomIn:SetParent("Minimap")
		MinimapZoomIn:SetPoint("RIGHT", "Minimap", "RIGHT", db.round and 10 or 20, db.round and -40 or -50)
		MinimapZoomIn:Show()
		MinimapZoomOut:ClearAllPoints()
		MinimapZoomOut:SetParent("Minimap")
		MinimapZoomOut:SetPoint("BOTTOM", "Minimap", "BOTTOM", db.round and 40 or 50, db.round and -10 or -20)
		MinimapZoomOut:Show()
	end

	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint("TOP", backdrops[3], "BOTTOM", 0, 6)
	TimeManagerClockButton:SetWidth(100)
	local a, b = WhiteNormalNumberFont:GetFont()
	TimeManagerClockTicker:SetFont(a, b+1, "OUTLINE")
	TimeManagerClockButton:GetRegions():Hide()
	if db.clock == false then
		TimeManagerClockButton:Hide()
		TimeManagerClockButton.bmShow = TimeManagerClockButton.Show
		TimeManagerClockButton.Show = noop
	end

	MiniMapWorldMapButton:SetScript("OnShow", hideFrame)
	MiniMapWorldMapButton:Hide()
	MiniMapWorldMapButton:UnregisterAllEvents()

	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetParent(Minimap)
	MinimapZoneTextButton:SetPoint("BOTTOM", backdrops[1], "TOP", 0, 4)
	local a, b = GameFontNormal:GetFont()
	MinimapZoneText:SetFont(a, b, "OUTLINE")
	if db.zoneText == false then
		MinimapZoneTextButton:Hide()
		MinimapZoneTextButton.bmShow = MinimapZoneTextButton.Show
		MinimapZoneTextButton.Show = noop
	end

	if db.classHall == false then
		GarrisonLandingPageMinimapButton:Hide()
		GarrisonLandingPageMinimapButton.bmShow = GarrisonLandingPageMinimapButton.Show
		GarrisonLandingPageMinimapButton.Show = noop
	end

	MiniMapTracking:SetScript("OnShow", hideFrame)
	MiniMapTracking:Hide()
	MiniMapTracking:UnregisterAllEvents()

	MiniMapInstanceDifficulty:ClearAllPoints()
	MiniMapInstanceDifficulty:SetParent(Minimap)
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)

	GuildInstanceDifficulty:ClearAllPoints()
	GuildInstanceDifficulty:SetParent(Minimap)
	GuildInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)

	GarrisonLandingPageMinimapButton:SetSize(38, 38)
	GarrisonLandingPageMinimapButton:ClearAllPoints()
	GarrisonLandingPageMinimapButton:SetParent(Minimap)
	GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -23, 15)

	if db.hideraid then
		MiniMapInstanceDifficulty:SetScript("OnShow", hideFrame)
		MiniMapInstanceDifficulty:Hide()
		GuildInstanceDifficulty:SetScript("OnShow", hideFrame)
		GuildInstanceDifficulty:Hide()
	end

	QueueStatusMinimapButton:ClearAllPoints()
	QueueStatusMinimapButton:SetParent(Minimap)
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
		if db.zoom then
			started = started + 1
			C_Timer.After(4, zoomOut)
		end
	end
	zoomBtnFunc()
	MinimapZoomIn:HookScript("OnClick", zoomBtnFunc)
	MinimapZoomOut:HookScript("OnClick", zoomBtnFunc)

	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(self, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
	end)

	Minimap:SetScript("OnMouseUp", function(self, btn)
		if btn == (db.calendar or "RightButton") then
			GameTimeFrame:Click()
		elseif btn == (db.tracking or "MiddleButton") then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
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

