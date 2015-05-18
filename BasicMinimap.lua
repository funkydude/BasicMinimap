
local name, BM = ...

local buttonValues = {RightButton = KEY_BUTTON2, MiddleButton = KEY_BUTTON3,
	Button4 = KEY_BUTTON4, Button5 = KEY_BUTTON5, Button6 = KEY_BUTTON6,
	Button7 = KEY_BUTTON7, Button8 = KEY_BUTTON8, Button9 = KEY_BUTTON9,
	Button10 = KEY_BUTTON10, Button11 = KEY_BUTTON11, Button12 = KEY_BUTTON12,
	Button13 = KEY_BUTTON13, Button14 = KEY_BUTTON14, Button15 = KEY_BUTTON15,
	None = NONE
}

local hideFrame = function(frame) frame:Hide() end
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
				BasicMinimapBorder:SetBackdropBorderColor(r, g, b)
			end,
			disabled = function() return db.round or db.ccolor end,
		},
		classcolor = {
			name = BM.CLASSCOLORED,
			order = 6, type = "toggle",
			get = function() return db.ccolor end,
			set = function(_, state)
				if state then
					db.ccolor = true
					local class = select(2, UnitClass("player"))
					local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
					BasicMinimapBorder:SetBackdropBorderColor(color.r, color.g, color.b)
				else
					db.ccolor = nil
					BasicMinimapBorder:SetBackdropBorderColor(db.borderR, db.borderG, db.borderB)
				end
			end,
			disabled = function() return db.round end,
		},
		bordersize = {
			name = BM.BORDERSIZE,
			order = 7, type = "range", width = "full",
			min = 0.5, max = 5, step = 0.5,
			get = function() return db.borderSize or 3 end,
			set = function(_, s) db.borderSize = s~=3 and s or nil
				BasicMinimapBorder:SetBackdrop(
					{edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false,
					tileSize = 0, edgeSize = s,}
				)
				BasicMinimapBorder:SetWidth(Minimap:GetWidth()+s)
				BasicMinimapBorder:SetHeight(Minimap:GetHeight()+s)
				if db.ccolor then
					local class = select(2, UnitClass("player"))
					local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
					BasicMinimapBorder:SetBackdropBorderColor(color.r, color.g, color.b)
				else
					BasicMinimapBorder:SetBackdropBorderColor(db.borderR, db.borderG, db.borderB)
				end
			end,
			disabled = function() return db.round end,
		},
		miscspacer = {
			name = "\n",
			order = 7.1, type = "description",
		},
		mischeader = {
			name = MISCELLANEOUS,
			order = 8, type = "header",
		},
		scale = {
			name = BM.SCALE,
			order = 9, type = "range",
			min = 0.5, max = 2, step = 0.01,
			get = function() return db.scale or 1 end,
			set = function(_, scale)
				Minimap:SetScale(scale)
				Minimap:ClearAllPoints()
				local s = (db.scale or 1)/scale
				db.x, db.y = db.x*s, db.y*s
				Minimap:SetPoint(db.point, nil, db.relpoint, db.x, db.y)
				db.scale = scale~=1 and scale or nil
			end,
		},
		strata = {
			name = BM.STRATA,
			order = 10, type = "select",
			get = function() return db.strata or "BACKGROUND" end,
			set = function(_, strata) db.strata = strata~="BACKGROUND" and strata or nil
				Minimap:SetFrameStrata(strata)
				BasicMinimapBorder:SetFrameStrata(strata)
			end,
			values = {TOOLTIP = BM.TOOLTIP, HIGH = HIGH, MEDIUM = AUCTION_TIME_LEFT2,
				LOW = LOW, BACKGROUND = BACKGROUND
			},
		},
		shape = {
			name = BM.SHAPE,
			order = 11, type = "select",
			get = function() return db.round and "circular" or "square" end,
			set = function(_, shape)
				if shape == "square" then
					db.round = nil
					Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
					BasicMinimapBorder:Show()
					function GetMinimapShape() return "SQUARE" end
				else
					db.round = true
					Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
					BasicMinimapBorder:Hide()
					function GetMinimapShape() return "ROUND" end
				end
			end,
			values = {square = RAID_TARGET_6, circular = RAID_TARGET_2}, --Square, Circle
		},
		zoom = {
			name = ZOOM_IN.."/"..ZOOM_OUT,
			order = 12, type = "toggle",
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
			order = 13, type = "toggle",
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
			order = 14, type = "toggle",
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
						TimeManagerClockButton.Show = function() end
					end
					TimeManagerClockButton:Hide()
				end
			end,
		},
		autozoom = {
			name = BM.AUTOZOOM,
			order = 15, type = "toggle",
			get = function() return db.zoom end,
			set = function(_, state) db.zoom = state and true or nil end,
		},
		lockspacer = {
			name = "\n",
			order = 15.1, type = "description",
		},
		lock = {
			name = LOCK,
			order = 16, type = "toggle",
			get = function() return db.lock end,
			set = function(_, state) db.lock = state and true or nil
				if not state then state = true else state = false end
				Minimap:SetMovable(state)
			end,
		},
	},
}

LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(name, options, true)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name)
SlashCmdList.BASICMINIMAP = function() InterfaceOptionsFrame_OpenToCategory(name) InterfaceOptionsFrame_OpenToCategory(name) end
SLASH_BASICMINIMAP1 = "/bm"
SLASH_BASICMINIMAP2 = "/basicminimap"

local frame = CreateFrame("Frame", "BasicMinimap", InterfaceOptionsFramePanelContainer)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
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
				borderR = 0.73, borderG = 0.75, borderB = 1
			}
		end
		db = BasicMinimapDB

		--Return minimap shape for other addons
		if not db.round then function GetMinimapShape() return "SQUARE" end end
	end
end

-- Enable
function frame:PLAYER_LOGIN(event)
	self:UnregisterEvent(event)
	self[event] = nil

	local Minimap = Minimap
	Minimap:SetParent(UIParent)
	MinimapCluster:EnableMouse(false)

	local border = CreateFrame("Frame", "BasicMinimapBorder", Minimap)
	border:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false, tileSize = 0, edgeSize = db.borderSize or 3})
	border:SetFrameStrata(db.strata or "BACKGROUND")
	border:SetPoint("CENTER", Minimap, "CENTER")
	if db.ccolor then
		local class = select(2, UnitClass("player"))
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		BasicMinimapBorder:SetBackdropBorderColor(color.r, color.g, color.b)
	else
		border:SetBackdropBorderColor(db.borderR, db.borderG, db.borderB)
	end
	border:SetWidth(Minimap:GetWidth()+(db.borderSize or 3))
	border:SetHeight(Minimap:GetHeight()+(db.borderSize or 3))
	border:Hide()

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
	Minimap:SetFrameStrata(db.strata or "BACKGROUND")
	MinimapNorthTag.Show = MinimapNorthTag.Hide
	MinimapNorthTag:Hide()

	MinimapBorder:Hide()
	MinimapBorderTop:Hide()
	if not db.round then
		border:Show()
		Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
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

	MiniMapVoiceChatFrame:SetScript("OnShow", hideFrame)
	MiniMapVoiceChatFrame:Hide()
	MiniMapVoiceChatFrame:UnregisterAllEvents()

	if db.clock == false then
		TimeManagerClockButton:Hide()
		TimeManagerClockButton.bmShow = TimeManagerClockButton.Show
		TimeManagerClockButton.Show = function() end
	end

	border:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
	border:RegisterEvent("CALENDAR_ACTION_PENDING")
	border:SetScript("OnEvent", function()
		if CalendarGetNumPendingInvites() < 1 then
			GameTimeFrame:Hide()
		else
			GameTimeFrame:Show()
		end
	end)
	if CalendarGetNumPendingInvites() < 1 then
		GameTimeFrame:Hide()
	else
		GameTimeFrame:Show()
	end

	MiniMapWorldMapButton:SetScript("OnShow", hideFrame)
	MiniMapWorldMapButton:Hide()
	MiniMapWorldMapButton:UnregisterAllEvents()

	MinimapZoneTextButton:SetScript("OnShow", hideFrame)
	MinimapZoneTextButton:Hide()
	MinimapZoneTextButton:UnregisterAllEvents()

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

	self:SetScript("OnEvent", function(_, event)
		if event == "PET_BATTLE_CLOSE" then
			Minimap:Show()
		else
			Minimap:Hide()
		end
	end)
	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self:RegisterEvent("PET_BATTLE_CLOSE")
end

