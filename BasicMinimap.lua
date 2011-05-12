
local name, BM = ...

local db, options
local function getOptions()
	local Minimap, BasicMinimapBorder = _G.Minimap, _G.BasicMinimapBorder
	local val = {RightButton = _G.KEY_BUTTON2, MiddleButton = _G.KEY_BUTTON3,
		Button4 = _G.KEY_BUTTON4, Button5 = _G.KEY_BUTTON5, Button6 = _G.KEY_BUTTON6,
		Button7 = _G.KEY_BUTTON7, Button8 = _G.KEY_BUTTON8, Button9 = _G.KEY_BUTTON9,
		Button10 = _G.KEY_BUTTON10, Button11 = _G.KEY_BUTTON11, Button12 = _G.KEY_BUTTON12,
		Button13 = _G.KEY_BUTTON13, Button14 = _G.KEY_BUTTON14, Button15 = _G.KEY_BUTTON15
	}
	if not options then
		options = {
			type = "group",
			name = "BasicMinimap",
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
					values = val,
				},
				trackingbtn = {
					name = TRACKING,
					order = 3, type = "select",
					get = function() return db.tracking or "MiddleButton" end,
					set = function(_, btn) db.tracking = btn~="MiddleButton" and btn or nil end,
					values = val,
				},
				borderspacer = {
					name = _G.EMBLEM_BORDER, --Border
					order = 4, type = "header",
				},
				bordercolor = {
					name = _G.EMBLEM_BORDER_COLOR, --Border Color
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
					name = _G.MISCELLANEOUS,
					order = 8, type = "header",
				},
				scale = {
					name = BM.SCALE,
					order = 9, type = "range", width = "full",
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
					values = {TOOLTIP = BM.TOOLTIP, HIGH = _G.HIGH, MEDIUM = _G.AUCTION_TIME_LEFT2,
						LOW = _G.LOW, BACKGROUND = _G.BACKGROUND
					},
				},
				shape = {
					name = BM.SHAPE,
					order = 11, type = "select",
					get = function() return db.round and "circular" or "square" end,
					set = function(_, shape)
						if shape == "square" then
							db.round = nil
							Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
							BasicMinimapBorder:Show()
							function GetMinimapShape() return "SQUARE" end
						else
							db.round = true
							Minimap:SetMaskTexture("Textures\\MinimapMask")
							BasicMinimapBorder:Hide()
							function GetMinimapShape() return "ROUND" end
						end
					end,
					values = {square = _G.RAID_TARGET_6, circular = _G.RAID_TARGET_2}, --Square, Circle
				},
				autozoom = {
					name = BM.AUTOZOOM,
					order = 12, type = "toggle",
					get = function() return db.zoom end,
					set = function(_, state) db.zoom = state and true or nil end,
				},
				raiddiff = {
					name = RAID_DIFFICULTY,
					order = 13, type = "toggle",
					get = function() if db.hideraid then return false else return true end end,
					set = function(_, state)
						if state then
							db.hideraid = nil
							MiniMapInstanceDifficulty:SetScript("OnShow", nil)
							local z = select(2, IsInInstance())
							if z and (z == "party" or z == "raid") then MiniMapInstanceDifficulty:Show() end
						else
							db.hideraid = true
							MiniMapInstanceDifficulty:SetScript("OnShow", hideMe)
							MiniMapInstanceDifficulty:Hide()
						end
					end,
				},
				lock = {
					name = _G.LOCK,
					order = 14, type = "toggle",
					get = function() return db.lock end,
					set = function(_, state) db.lock = state and true or nil
						if not state then state = true else state = false end
						Minimap:SetMovable(state)
					end,
				},
			},
		}
	end
	return options
end

local function addOptions()
	BM.self.name = "BasicMinimapNew"
	InterfaceOptions_AddCategory(BM.self)
	local bmTitle = BM.self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	bmTitle:SetPoint("TOPLEFT", 16, -16)
	bmTitle:SetText("BasicMinimapNew".." @project-version@") --wowace magic, replaced with tag version
end

BM.self = CreateFrame("Frame", "BasicMinimap", InterfaceOptionsFramePanelContainer)
BM.self:SetScript("OnEvent", function()
	local hideMe = function(frame) frame:Hide() end
	addOptions()

		if not _G.BasicMinimapDB or not _G.BasicMinimapDB.borderR then
			_G.BasicMinimapDB = {
				x = 0, y = 0,
				point = "CENTER", relpoint = "CENTER",
				borderR = 0.73, borderG = 0.75, borderB = 1
			}
		end
		db = _G.BasicMinimapDB

		--Return minimap shape for other addons
		if not db.round then function GetMinimapShape() return "SQUARE" end end

		_G.LibStub("AceConfig-3.0"):RegisterOptionsTable("BasicMinimap", getOptions)
		_G.LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BasicMinimap")

		_G["SlashCmdList"]["BASICMINIMAP"] = function() InterfaceOptionsFrame_OpenToCategory("BasicMinimap") end
		_G["SLASH_BASICMINIMAP1"] = "/bm"
		_G["SLASH_BASICMINIMAP2"] = "/basicminimap"

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
			local p, _, rp, x, y = Minimap:GetPoint()
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
			Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
		end

		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()

		MiniMapVoiceChatFrame:SetScript("OnShow", hideMe)
		MiniMapVoiceChatFrame:Hide()
		MiniMapVoiceChatFrame:UnregisterAllEvents()

		border:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
		border:RegisterEvent("CALENDAR_ACTION_PENDING")
		border:SetScript("OnEvent", function()
			if CalendarGetNumPendingInvites() < 1 then
				GameTimeFrame:Hide()
			else
				GameTimeFrame:Show()
			end
		end)

		MiniMapWorldMapButton:SetScript("OnShow", hideMe)
		MiniMapWorldMapButton:Hide()
		MiniMapWorldMapButton:UnregisterAllEvents()

		MinimapZoneTextButton:SetScript("OnShow", hideMe)
		MinimapZoneTextButton:Hide()
		MinimapZoneTextButton:UnregisterAllEvents()

		MiniMapTracking:SetScript("OnShow", hideMe)
		MiniMapTracking:Hide()
		MiniMapTracking:UnregisterAllEvents()

		MiniMapInstanceDifficulty:ClearAllPoints()
		MiniMapInstanceDifficulty:SetParent(Minimap)
		MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)

		GuildInstanceDifficulty:ClearAllPoints()
		GuildInstanceDifficulty:SetParent(Minimap)
		GuildInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, 0)

		if db.hideraid then
			MiniMapInstanceDifficulty:SetScript("OnShow", hideMe)
			MiniMapInstanceDifficulty:Hide()
		end

		MiniMapLFGFrame:ClearAllPoints()
		MiniMapLFGFrame:SetParent(Minimap)
		MiniMapLFGFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -10, -10)

		Minimap:EnableMouseWheel(true)
		local t = 0
		local zoomfunc = function(_, e)
			t = t + e
			if t > 4 then
				t = 0
				for i = 1, 5 do
					_G.MinimapZoomOut:Click()
				end
				Minimap:SetScript("OnUpdate", nil)
			end
		end
		Minimap:SetScript("OnMouseWheel", function(self, d)
			if d > 0 then
				_G.MinimapZoomIn:Click()
			elseif d < 0 then
				_G.MinimapZoomOut:Click()
			end
			if db.zoom then
				t = 0
				Minimap:SetScript("OnUpdate", zoomfunc)
			end
		end)
		Minimap:SetScript("OnMouseUp", function(self, btn)
			if btn == (db.calendar or "RightButton") then
				_G.GameTimeFrame:Click()
			elseif btn == (db.tracking or "MiddleButton") then
				_G.ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, self)
			elseif btn == "LeftButton" then
				_G.Minimap_OnClick(self)
			end
		end)

		BM.self:UnregisterEvent("PLAYER_LOGIN")
		BM.self:SetScript("OnEvent", nil)
end)
BM.self:RegisterEvent("PLAYER_LOGIN")

