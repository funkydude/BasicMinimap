--[[
	Configurable minimap with basic options
	Features:
	-Moving of the minimap
	-Scaling of the minimap
	-Hiding all minimap buttons
	-Minimap mouse scroll zooming
	-Square or circular minimap
	-Minimap strata selection
	-Selecting which mouseclick opens which menu (tracking/calendar)
	-Auto showing the calendar button when invites arrive
	-Minimap border and color selection
]]

local Minimap = _G.Minimap
local db, options
local function getOptions()
	if not options then
		local L = LibStub("AceLocale-3.0"):GetLocale("BasicMinimap", true)
		options = {
			type = "group",
			name = "BasicMinimap",
			args = {
				btndesc = {
					name = L["Button Description"],
					order = 1, type = "description",
				},
				calendarbtn = {
					name = L["Calendar"],
					order = 2, type = "select",
					get = function() return db.calendar end,
					set = function(_, btn) db.calendar = btn end,
					values = {RightButton = _G.KEY_BUTTON2, MiddleButton = _G.KEY_BUTTON3, Button4 = _G.KEY_BUTTON4,
						Button5 = _G.KEY_BUTTON5
					},
				},
				trackingbtn = {
					name = L["Tracking"],
					order = 3, type = "select",
					get = function() return db.tracking end,
					set = function(_, btn) db.tracking = btn end,
					values = {RightButton = _G.KEY_BUTTON2, MiddleButton = _G.KEY_BUTTON3, Button4 = _G.KEY_BUTTON4,
						Button5 = _G.KEY_BUTTON5
					},
				},
				borderspacer = {
					name = _G.EMBLEM_BORDER, --Border
					order = 4, type = "header",
				},
				bordercolor = {
					name = _G.EMBLEM_BORDER_COLOR, --Border Color
					order = 5, type = "color",
					get = function() return db.border.r, db.border.g, db.border.b end,
					set = function(_, r, g, b)
						db.border.r = r db.border.g = g db.border.b = b
						BasicMinimapBorder:SetBackdropBorderColor(r, g, b)
					end,
					disabled = function() return db.shape ~= "square" end,
				},
				bordersize = {
					name = L["Border Size"],
					order = 6, type = "range",
					min = 0.5, max = 5, step = 0.5,
					get = function() return db.borderSize end,
					set = function(_, s) db.borderSize = s
						BasicMinimapBorder:SetBackdrop(
							{edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false,
							tileSize = 0, edgeSize = s,}
						)
						BasicMinimapBorder:SetWidth(_G.Minimap:GetWidth()+s)
						BasicMinimapBorder:SetHeight(_G.Minimap:GetHeight()+s)
						BasicMinimapBorder:SetBackdropBorderColor(db.border.r, db.border.g, db.border.b)
					end,
					disabled = function() return db.shape ~= "square" end,
				},
				miscspacer = {
					name = _G.MISCELLANEOUS,
					order = 7, type = "header",
				},
				scale = {
					name = L["Scale"],
					order = 8, type = "range", width = "full",
					min = 0.5, max = 2, step = 0.01,
					get = function() return db.scale end,
					set = function(_, scale)
						Minimap:SetScale(scale)
						Minimap:ClearAllPoints()
						local s = db.scale/scale
						Minimap:SetPoint(db.point, nil, db.relpoint, db.x*s, db.y*s)
						db.scale = scale
						local p, _, rp, x, y = Minimap:GetPoint()
						db.point, db.relpoint, db.x, db.y = p, rp, x, y
					end,
				},
				strata = {
					name = L["Strata"],
					order = 9, type = "select",
					get = function() return db.strata end,
					set = function(_, strata) db.strata = strata
						Minimap:SetFrameStrata(strata)
						BasicMinimapBorder:SetFrameStrata(strata) 
					end,
					values = {TOOLTIP = L["Tooltip"], HIGH = _G.HIGH, MEDIUM = _G.AUCTION_TIME_LEFT2,
						LOW = _G.LOW, BACKGROUND = _G.BACKGROUND
					},
				},
				shape = {
					name = L["Shape"],
					order = 10, type = "select",
					get = function() return db.shape end,
					set = function(_, shape) db.shape = shape
						if shape == "square" then
							Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
							BasicMinimapBorder:Show()
						else
							Minimap:SetMaskTexture("Textures\\MinimapMask")
							BasicMinimapBorder:Hide()
						end
					end,
					values = {square = _G.RAID_TARGET_6, circular = _G.RAID_TARGET_2}, --Square, Circle
				},
				lock = {
					name = _G.LOCK,
					order = 11, type = "toggle",
					get = function() return db.lock end,
					set = function(_, state) db.lock = state
						if not state then state = true else state = false end
						Minimap:SetMovable(state)
					end,
				},
			},
		}
	end
	return options
end

local function kill() end
local function Enable()
	if not _G.BasicMinimapDB or not _G.BasicMinimapDB.scale then
		_G.BasicMinimapDB = {
			scale = 1.0,
			x = 0,
			y = 0,
			point = "CENTER",
			relpoint = "CENTER",
			lock = false,
			shape = "square",
			strata = "BACKGROUND",
			border = { r = 0.73, g = 0.75, b = 1 },
			borderSize = 3,
			calendar = "RightButton",
			tracking = "MiddleButton",
		}
	end
	db = _G.BasicMinimapDB

	_G.LibStub("AceConfig-3.0"):RegisterOptionsTable("BasicMinimap", getOptions)
	_G.LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BasicMinimap")

	_G["SlashCmdList"]["BASICMINIMAP_MAIN"] = function() InterfaceOptionsFrame_OpenToCategory("BasicMinimap") end
	_G["SLASH_BASICMINIMAP_MAIN1"] = "/bm"
	_G["SLASH_BASICMINIMAP_MAIN2"] = "/basicminimap"

	Minimap:SetParent(UIParent)
	MinimapCluster:EnableMouse(false)

	local border = CreateFrame("Frame", "BasicMinimapBorder", Minimap)
	border:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false, tileSize = 0, edgeSize = db.borderSize,})
	border:SetFrameStrata(db.strata)
	border:SetPoint("CENTER", Minimap, "CENTER")
	border:SetBackdropBorderColor(db.border.r, db.border.g, db.border.b)
	border:SetWidth(Minimap:GetWidth()+db.borderSize)
	border:SetHeight(Minimap:GetHeight()+db.borderSize)
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

	Minimap:SetScale(db.scale)
	Minimap:SetFrameStrata(db.strata)
	MinimapNorthTag.Show = kill
	MinimapNorthTag:Hide()

	MinimapBorder:Hide()
	MinimapBorderTop:Hide()
	if db.shape == "square" then
		border:Show()
		Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
		--Return minimap shape for other addons
		function GetMinimapShape() return "SQUARE" end
	end

	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()

	MiniMapVoiceChatFrame:Hide()
	MiniMapVoiceChatFrame:UnregisterAllEvents()
	MiniMapVoiceChatFrame.Show = kill

	MinimapToggleButton:Hide()
	MinimapToggleButton:UnregisterAllEvents()

	border:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
	border:RegisterEvent("CALENDAR_ACTION_PENDING")
	border:SetScript("OnEvent", function()
		if CalendarGetNumPendingInvites() < 1 then
			GameTimeFrame:Hide()
		else
			GameTimeFrame:Show()
		end
	end)

	MiniMapWorldMapButton:Hide()
	MiniMapWorldMapButton:UnregisterAllEvents()
	MiniMapWorldMapButton.Show = kill

	MinimapZoneTextButton:Hide()
	MinimapZoneTextButton:UnregisterAllEvents()

	MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -25, -22)
	MiniMapTracking:Hide()
	MiniMapTracking.Show = kill
	MiniMapTracking:UnregisterAllEvents()

	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(self, d)
		if d > 0 then
			_G.MinimapZoomIn:Click()
		elseif d < 0 then
			_G.MinimapZoomOut:Click()
		end
	end)
	Minimap:SetScript("OnMouseUp", function(self, btn)
		if btn == db.calendar then
			_G.GameTimeFrame:Click()
		elseif btn == db.tracking then
			_G.ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, self)
		elseif btn == "LeftButton" then
			_G.Minimap_OnClick(self)
		end
	end)
end

Minimap:RegisterEvent("PLAYER_LOGIN")
Minimap:SetScript("OnEvent", Enable)

