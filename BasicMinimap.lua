--[[
	Configurable minimap with basic options
	Features:
	-Moving of the minimap
	-Scaling of the minimap
	-Hiding all minimap buttons
	-Minimap mouse scroll zooming
	-Square or circular minimap
	-Minimap strata selection
]]

local BasicMinimap = LibStub("AceAddon-3.0"):NewAddon("BasicMinimap")

------------------------------
--      Are you local?      --
------------------------------

local db
local defaults = {
	profile = {
		scale = 1.0,
		x = nil,
		y = nil,
		lock = nil,
		shape = "square",
		strata = "BACKGROUND",
		border = { r = 0.73, g = 0.75, b = 1 },
		borderSize = 3,
	}
}

local options
local function getOptions()
	if not options then
		local L = LibStub("AceLocale-3.0"):GetLocale("BasicMinimap", true)
		options = {
			type = "group",
			name = "BasicMinimap",
			args = {
				intro = {
					name = L["Intro"],
					order = 1, type = "description",
				},
				spacer = {
					name = "",
					order = 2, type = "header",
				},
				scale = {
					name = L["Scale"], desc = L["Adjust the minimap scale, from 0.5 to 2.0"],
					order = 3, type = "range", width = "full",
					min = 0.5, max = 2, step = 0.01,
					get = function() return db.scale end,
					set = function(_, scale) db.scale = scale _G.Minimap:SetScale(scale) end,
				},
				strata = {
					name = L["Strata"], desc = L["Change the strata of the Minimap."],
					order = 4, type = "select", width = "full",
					get = function() return db.strata end,
					set = function(_, strata) db.strata = strata
						_G.Minimap:SetFrameStrata(strata)
						_G.BasicMinimapBorder:SetFrameStrata(strata) 
					end,
					values = {TOOLTIP = L["Tooltip"], FULLSCREEN_DIALOG = L["Fullscreen_dialog"], FULLSCREEN = L["Fullscreen"],
					DIALOG = L["Dialog"], HIGH = _G["HIGH"], MEDIUM = _G["AUCTION_TIME_LEFT2"], LOW = _G["LOW"], BACKGROUND = _G["BACKGROUND"]},
				},
				lock = {
					name = _G["LOCK"], desc = L["Lock the minimap in its current location."],
					order = 5, type = "toggle",
					get = function() return db.lock end,
					set = function(_, state) db.lock = state
						if not state then state = true else state = false end
						_G.Minimap:SetMovable(state)
					end,
				},
				shape = {
					name = L["Shape"], desc = L["Change the minimap shape, curcular or square."],
					order = 6, type = "select",
					values = {square = _G["RAID_TARGET_6"], circular = _G["RAID_TARGET_2"]}, --Square, Circle
					get = function() return db.shape end,
					set = function(_, shape) db.shape = shape
						if shape == "square" then
							_G.Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
							BasicMinimapBorder:Show()
						else
							_G.Minimap:SetMaskTexture("Textures\\MinimapMask")
							BasicMinimapBorder:Hide()
						end
					end,
				},
				bordercolor = {
					name = L["Border Color"], desc = L["Change the minimap border color."],
					order = 7, type = "color",
					get = function() return db.border.r, db.border.g, db.border.b end,
					set = function(_, r, g, b)
						db.border.r = r db.border.g = g db.border.b = b
						_G.BasicMinimapBorder:SetBackdropBorderColor(r, g, b)
					end,
					disabled = function() return db.shape ~= "square" end,
				},
				bordersize = {
					name = L["Border Size"], desc = L["Adjust the minimap border size."],
					order = 8, type = "range",
					min = 0.5, max = 5, step = 0.5,
					get = function() return db.borderSize end,
					set = function(_, s) db.borderSize = s
						_G.BasicMinimapBorder:SetBackdrop(
							{edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false,
							tileSize = 0, edgeSize = s,}
						)
						_G.BasicMinimapBorder:SetWidth(_G.Minimap:GetWidth()+s)
						_G.BasicMinimapBorder:SetHeight(_G.Minimap:GetHeight()+s)
					end,
					disabled = function() return db.shape ~= "square" end,
				},
			},
		}
	end
	return options
end

------------------------------
--      Initialization      --
------------------------------

function BasicMinimap:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("BasicMinimapDB", defaults)
	db = self.db.profile

	LibStub("AceConfig-3.0"):RegisterOptionsTable("BasicMinimap", getOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BasicMinimap")

	_G["SlashCmdList"]["BASICMINIMAP_MAIN"] = function() InterfaceOptionsFrame_OpenToCategory("BasicMinimap") end
	_G["SLASH_BASICMINIMAP_MAIN1"] = "/bm"
	_G["SLASH_BASICMINIMAP_MAIN2"] = "/basicminimap"
end

local function kill() end
function BasicMinimap:OnEnable()
	local Minimap = _G.Minimap

	local border = CreateFrame("Frame", "BasicMinimapBorder", Minimap)
	border:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = false, tileSize = 0, edgeSize = db.borderSize,})
	border:SetFrameStrata(db.strata)
	border:SetPoint("CENTER", Minimap, "CENTER")
	border:SetBackdropBorderColor(db.border.r, db.border.g, db.border.b)
	border:SetWidth(Minimap:GetWidth()+db.borderSize)
	border:SetHeight(Minimap:GetHeight()+db.borderSize)
	border:Hide()

	if db.x and db.y then
		Minimap:ClearAllPoints()
		Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x, db.y)
	else
		Minimap:SetPoint("CENTER", UIParent, "CENTER")
	end

	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(true)

	Minimap:SetScript("OnDragStart", function(self) if self:IsMovable() then self:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		db.x, db.y = Minimap:GetCenter()
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
		print(evt,arg)
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
		if btn == "RightButton" then
			_G.GameTimeFrame:Click()
		elseif btn == "MiddleButton" then
			_G.ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, self)
		else
			_G.Minimap_OnClick(self)
		end
	end)
end
