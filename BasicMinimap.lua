
local name, BM = ...

local hideFrame = function(frame) frame:Hide() end
local noop = function() end
local backdrops = {}
local db

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
frame:SetScript("OnEvent", function(f, event, ...)
	f[event](f, event, ...)
end)

-- Init
function frame:ADDON_LOADED(event, addon)
	if addon == "BasicMinimap" then
		self:UnregisterEvent(event)
		self[event] = nil

		local defaults = {
			profile = {
				lock = false,
				position = {"CENTER", "CENTER", 0, 0},
				--shadow = true,
				--outline = "NONE",
				--font = media:GetDefault("font"),
				colorBorder = {0,0.6,0,1},
			}
		}
		self.db = LibStub("AceDB-3.0"):New("TempBasicMinimapDB", defaults, true)

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
	Minimap.db = db
	Minimap.backdrops = backdrops

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

