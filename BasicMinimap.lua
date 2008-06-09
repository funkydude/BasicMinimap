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
					set = function(_, scale) db.scale = scale Minimap:SetScale(scale) end,
				},
				strata = {
					name = L["Strata"], desc = L["Change the strata of the Minimap."],
					order = 4, type = "select", width = "full",
					get = function() return db.strata end,
					set = function(_, strata) Minimap:SetFrameStrata(strata) db.strata = strata end,
					values = {TOOLTIP = L["Tooltip"], FULLSCREEN_DIALOG = L["Fullscreen_dialog"], FULLSCREEN = L["Fullscreen"],
					DIALOG = L["Dialog"], HIGH = _G["HIGH"], MEDIUM = _G["AUCTION_TIME_LEFT2"], LOW = _G["LOW"], BACKGROUND = _G["BACKGROUND"]},
				},
				lock = {
					name = _G["LOCK"], desc = L["Lock the minimap in its current location."],
					order = 5, type = "toggle",
					get = function() return db.lock end,
					set = function(_, state) db.lock = state
						if not state then state = true else state = false end
						Minimap:SetMovable(state)
					end,
				},
				shape = {
					name = L["Shape"], desc = L["Change the minimap shape, curcular or square."],
					order = 6, type = "select",
					values = {square = _G["RAID_TARGET_6"], circular = _G["RAID_TARGET_2"]}, --Square, Circle
					get = function() return db.shape end,
					set = function(_, shape) db.shape = shape
						if shape == "square" then
							Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
						else
							Minimap:SetMaskTexture("Textures\\MinimapMask")
						end
					end,
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
	BasicMinimap.db = LibStub("AceDB-3.0"):New("BasicMinimapDB", defaults)
	db = self.db.profile

	LibStub("AceConfig-3.0"):RegisterOptionsTable("BasicMinimap", getOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BasicMinimap")

	_G["SlashCmdList"]["BASICMINIMAP_MAIN"] = function() InterfaceOptionsFrame_OpenToFrame("BasicMinimap") end
	_G["SLASH_BASICMINIMAP_MAIN1"] = "/bm"
	_G["SLASH_BASICMINIMAP_MAIN2"] = "/basicminimap"
end

local function zoom(_, d)
	if d > 0 then
		MinimapZoomIn:Click()
	elseif d < 0 then
		MinimapZoomOut:Click()
	end
end

local function kill() end

function BasicMinimap:OnEnable()
	if db.x and db.y then
		Minimap:ClearAllPoints()
		Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x, db.y)
	else
		Minimap:SetPoint("CENTER", UIParent, "CENTER")
	end

	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(true)

	Minimap:SetScript("OnDragStart", function() if this:IsMovable() then this:StartMoving() end end)
	Minimap:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
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
		Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
		--Return minimap shape for other addons
		function GetMinimapShape() return "SQUARE" end
	end

	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()

	MiniMapVoiceChatFrame:Hide()
	MiniMapVoiceChatFrame:UnregisterAllEvents()

	MinimapToggleButton:Hide()
	MinimapToggleButton:UnregisterAllEvents()

	GameTimeFrame:Hide()
	GameTimeFrame:UnregisterAllEvents()

	MiniMapWorldMapButton:Hide()
	MiniMapWorldMapButton:UnregisterAllEvents()

	MinimapZoneTextButton:Hide()
	MinimapZoneTextButton:UnregisterAllEvents()

	MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -25, -22)

	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", zoom)
end
