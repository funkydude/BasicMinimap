
local name, BM = ...

BM.buttonValues = {RightButton = KEY_BUTTON2, MiddleButton = KEY_BUTTON3,
	Button4 = KEY_BUTTON4, Button5 = KEY_BUTTON5, Button6 = KEY_BUTTON6,
	Button7 = KEY_BUTTON7, Button8 = KEY_BUTTON8, Button9 = KEY_BUTTON9,
	Button10 = KEY_BUTTON10, Button11 = KEY_BUTTON11, Button12 = KEY_BUTTON12,
	Button13 = KEY_BUTTON13, Button14 = KEY_BUTTON14, Button15 = KEY_BUTTON15
}

BM.hide = function(frame) frame:Hide() end

BM.options = {
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
			get = function() return BM.db.calendar or "RightButton" end,
			set = function(_, btn) BM.db.calendar = btn~="RightButton" and btn or nil end,
			values = BM.buttonValues,
		},
		trackingbtn = {
			name = TRACKING,
			order = 3, type = "select",
			get = function() return BM.db.tracking or "MiddleButton" end,
			set = function(_, btn) BM.db.tracking = btn~="MiddleButton" and btn or nil end,
			values = BM.buttonValues,
		},
		borderspacer = {
			name = EMBLEM_BORDER, --Border
			order = 4, type = "header",
		},
		bordercolor = {
			name = EMBLEM_BORDER_COLOR, --Border Color
			order = 5, type = "color",
			get = function() return BM.db.borderR, BM.db.borderG, BM.db.borderB end,
			set = function(_, r, g, b)
				BM.db.borderR = r BM.db.borderG = g BM.db.borderB = b
				BasicMinimapBorder:SetBackdropBorderColor(r, g, b)
			end,
			disabled = function() return BM.db.round or BM.db.ccolor end,
		},
		classcolor = {
			name = BM.CLASSCOLORED,
			order = 6, type = "toggle",
			get = function() return BM.db.ccolor end,
			set = function(_, state)
				if state then
					BM.db.ccolor = true
					local class = select(2, UnitClass("player"))
					local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
					BasicMinimapBorder:SetBackdropBorderColor(color.r, color.g, color.b)
				else
					BM.db.ccolor = nil
					BasicMinimapBorder:SetBackdropBorderColor(BM.db.borderR, BM.db.borderG, BM.db.borderB)
				end
			end,
			disabled = function() return BM.db.round end,
		},
		bordersize = {
			name = BM.BORDERSIZE,
			order = 7, type = "range", width = "full",
			min = 0.5, max = 5, step = 0.5,
			get = function() return BM.db.borderSize or 3 end,
			set = function(_, s) BM.db.borderSize = s~=3 and s or nil
				BasicMinimapBorder:SetBackdrop(
					{edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false,
					tileSize = 0, edgeSize = s,}
				)
				BasicMinimapBorder:SetWidth(Minimap:GetWidth()+s)
				BasicMinimapBorder:SetHeight(Minimap:GetHeight()+s)
				if BM.db.ccolor then
					local class = select(2, UnitClass("player"))
					local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
					BasicMinimapBorder:SetBackdropBorderColor(color.r, color.g, color.b)
				else
					BasicMinimapBorder:SetBackdropBorderColor(BM.db.borderR, BM.db.borderG, BM.db.borderB)
				end
			end,
			disabled = function() return BM.db.round end,
		},
		miscspacer = {
			name = MISCELLANEOUS,
			order = 8, type = "header",
		},
		scale = {
			name = BM.SCALE,
			order = 9, type = "range", width = "full",
			min = 0.5, max = 2, step = 0.01,
			get = function() return BM.db.scale or 1 end,
			set = function(_, scale)
				Minimap:SetScale(scale)
				Minimap:ClearAllPoints()
				local s = (BM.db.scale or 1)/scale
				BM.db.x, BM.db.y = BM.db.x*s, BM.db.y*s
				Minimap:SetPoint(BM.db.point, nil, BM.db.relpoint, BM.db.x, BM.db.y)
				BM.db.scale = scale~=1 and scale or nil
			end,
		},
		strata = {
			name = BM.STRATA,
			order = 10, type = "select",
			get = function() return BM.db.strata or "BACKGROUND" end,
			set = function(_, strata) BM.db.strata = strata~="BACKGROUND" and strata or nil
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
			get = function() return BM.db.round and "circular" or "square" end,
			set = function(_, shape)
				if shape == "square" then
					BM.db.round = nil
					Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
					BasicMinimapBorder:Show()
					function GetMinimapShape() return "SQUARE" end
				else
					BM.db.round = true
					Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
					BasicMinimapBorder:Hide()
					function GetMinimapShape() return "ROUND" end
				end
			end,
			values = {square = RAID_TARGET_6, circular = RAID_TARGET_2}, --Square, Circle
		},
		autozoom = {
			name = BM.AUTOZOOM,
			order = 12, type = "toggle",
			get = function() return BM.db.zoom end,
			set = function(_, state) BM.db.zoom = state and true or nil end,
		},
		raiddiff = {
			name = RAID_DIFFICULTY,
			order = 13, type = "toggle",
			get = function() if BM.db.hideraid then return false else return true end end,
			set = function(_, state)
				if state then
					BM.db.hideraid = nil
					MiniMapInstanceDifficulty:SetScript("OnShow", nil)
					GuildInstanceDifficulty:SetScript("OnShow", nil)
					local z = select(2, IsInInstance())
					if z and (z == "party" or z == "raid") and (IsInRaid() or IsInGroup()) then
						MiniMapInstanceDifficulty:Show()
						GuildInstanceDifficulty:Show()
					end
				else
					BM.db.hideraid = true
					MiniMapInstanceDifficulty:SetScript("OnShow", BM.hide)
					MiniMapInstanceDifficulty:Hide()
					GuildInstanceDifficulty:SetScript("OnShow", BM.hide)
					GuildInstanceDifficulty:Hide()
				end
			end,
		},
		clock = {
			name = TIMEMANAGER_TITLE,
			order = 14, type = "toggle",
			get = function() return BM.db.clock or BM.db.clock == nil and true end,
			set = function(_, state)
				BM.db.clock = state
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
		lock = {
			name = LOCK,
			order = 15, type = "toggle",
			get = function() return BM.db.lock end,
			set = function(_, state) BM.db.lock = state and true or nil
				if not state then state = true else state = false end
				Minimap:SetMovable(state)
			end,
		},
	},
}

BM.self = CreateFrame("Frame", "BasicMinimap", InterfaceOptionsFramePanelContainer)
BM.self:RegisterEvent("PLAYER_LOGIN")
BM.self:SetScript("OnEvent", function(f)
	if not BasicMinimapDB or not BasicMinimapDB.borderR then
		BasicMinimapDB = {
			x = 0, y = 0,
			point = "CENTER", relpoint = "CENTER",
			borderR = 0.73, borderG = 0.75, borderB = 1
		}
	end
	BM.db = BasicMinimapDB

	--Return minimap shape for other addons
	if not BM.db.round then function GetMinimapShape() return "SQUARE" end end

	LibStub("AceConfig-3.0"):RegisterOptionsTable(name, BM.options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name)

	SlashCmdList.BASICMINIMAP = function() InterfaceOptionsFrame_OpenToCategory(name) end
	SLASH_BASICMINIMAP1 = "/bm"
	SLASH_BASICMINIMAP2 = "/basicminimap"

	local Minimap = Minimap
	Minimap:SetParent(UIParent)
	MinimapCluster:EnableMouse(false)

	local border = CreateFrame("Frame", "BasicMinimapBorder", Minimap)
	border:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false, tileSize = 0, edgeSize = BM.db.borderSize or 3})
	border:SetFrameStrata(BM.db.strata or "BACKGROUND")
	border:SetPoint("CENTER", Minimap, "CENTER")
	if BM.db.ccolor then
		local class = select(2, UnitClass("player"))
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		BasicMinimapBorder:SetBackdropBorderColor(color.r, color.g, color.b)
	else
		border:SetBackdropBorderColor(BM.db.borderR, BM.db.borderG, BM.db.borderB)
	end
	border:SetWidth(Minimap:GetWidth()+(BM.db.borderSize or 3))
	border:SetHeight(Minimap:GetHeight()+(BM.db.borderSize or 3))
	border:Hide()

	Minimap:ClearAllPoints()
	Minimap:SetPoint(BM.db.point, nil, BM.db.relpoint, BM.db.x, BM.db.y)
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(true)

	Minimap:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = Minimap:GetPoint()
		BM.db.point, BM.db.relpoint, BM.db.x, BM.db.y = p, rp, x, y
	end)

	if not BM.db.lock then Minimap:SetMovable(true) end

	Minimap:SetScale(BM.db.scale or 1)
	Minimap:SetFrameStrata(BM.db.strata or "BACKGROUND")
	MinimapNorthTag.Show = MinimapNorthTag.Hide
	MinimapNorthTag:Hide()

	MinimapBorder:Hide()
	MinimapBorderTop:Hide()
	if not BM.db.round then
		border:Show()
		Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
	end

	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()

	MiniMapVoiceChatFrame:SetScript("OnShow", BM.hide)
	MiniMapVoiceChatFrame:Hide()
	MiniMapVoiceChatFrame:UnregisterAllEvents()

	if BM.db.clock == false then
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

	MiniMapWorldMapButton:SetScript("OnShow", BM.hide)
	MiniMapWorldMapButton:Hide()
	MiniMapWorldMapButton:UnregisterAllEvents()

	MinimapZoneTextButton:SetScript("OnShow", BM.hide)
	MinimapZoneTextButton:Hide()
	MinimapZoneTextButton:UnregisterAllEvents()

	MiniMapTracking:SetScript("OnShow", BM.hide)
	MiniMapTracking:Hide()
	MiniMapTracking:UnregisterAllEvents()

	MiniMapInstanceDifficulty:ClearAllPoints()
	MiniMapInstanceDifficulty:SetParent(Minimap)
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)

	GuildInstanceDifficulty:ClearAllPoints()
	GuildInstanceDifficulty:SetParent(Minimap)
	GuildInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)

	if BM.db.hideraid then
		MiniMapInstanceDifficulty:SetScript("OnShow", BM.hide)
		MiniMapInstanceDifficulty:Hide()
		GuildInstanceDifficulty:SetScript("OnShow", BM.hide)
		GuildInstanceDifficulty:Hide()
	end

	local lfg = MiniMapLFGFrame or QueueStatusMinimapButton
	lfg:ClearAllPoints()
	lfg:SetParent(Minimap)
	lfg:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -10, -10)

	Minimap:EnableMouseWheel(true)
	local t = 0
	local zoomfunc = function(_, e)
		t = t + e
		if t > 4 then
			t = 0
			for i = 1, 5 do
				MinimapZoomOut:Click()
			end
			Minimap:SetScript("OnUpdate", nil)
		end
	end
	Minimap:SetScript("OnMouseWheel", function(self, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
		if BM.db.zoom then
			t = 0
			Minimap:SetScript("OnUpdate", zoomfunc)
		end
	end)
	Minimap:SetScript("OnMouseUp", function(self, btn)
		if btn == (BM.db.calendar or "RightButton") then
			GameTimeFrame:Click()
		elseif btn == (BM.db.tracking or "MiddleButton") then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
		elseif btn == "LeftButton" then
			Minimap_OnClick(self)
		end
	end)

	f:UnregisterEvent("PLAYER_LOGIN")

	-- Hide the Minimap during a pet battle
	f:SetScript("OnEvent", function(_, event)
		if event == "PET_BATTLE_CLOSE" then
			Minimap:Show()
		else
			Minimap:Hide()
		end
	end)
	f:RegisterEvent("PET_BATTLE_OPENING_START")
	f:RegisterEvent("PET_BATTLE_CLOSE")
end)

