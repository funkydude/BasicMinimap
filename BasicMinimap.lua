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

local function zoom()
	if arg1 > 0 then
		MinimapZoomIn:Click()
	elseif arg1 < 0 then
		MinimapZoomOut:Click()
	end
end

local BasicMinimap = LibStub("AceAddon-3.0"):NewAddon("BasicMinimap", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BasicMinimap", true)

local function move() this:StartMoving() end
local function stop()
	this:StopMovingOrSizing()
	db.x, db.y = Minimap:GetCenter()
end

local function setScale(_, scale)
	db.scale = scale
	Minimap:SetScale(scale)
end

local function setLock()
	if not db.lock then
		Minimap:SetMovable(false)
		Minimap:SetScript("OnDragStart", nil)
		Minimap:SetScript("OnDragStop", nil)
		db.lock = true
	else
		Minimap:SetMovable(true)
		Minimap:SetScript("OnDragStart", move)
		Minimap:SetScript("OnDragStop", stop)
		db.lock = nil
	end
end

local function setShape(_, shape)
	if shape == "square" then
		Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")
		db.shape = "square"
	else
		Minimap:SetMaskTexture("Textures\\MinimapMask")
		db.shape = "circular"
	end
end

local function setStrata(_, strata)
	Minimap:SetFrameStrata(strata)
	db.strata = strata
end

local bmoptions = {
	type = "group",
	name = "BasicMinimap",
	args = {
		intro = {
			type = "description",
			name = L["Intro"],
			order = 1,
		},
		shape = {
			order = 2,
			name = L["Shape"],
			type = "group",
			args = {
				shapedesc = {
					order = 1,
					type = "description",
					name = L["Change the minimap shape, curcular or square."],
				},
				shapeset = {
					name = L["Shape"],
					type = "select",
					get = function() return db.shape end,
					set = setShape,
					values = {square = L["Square"], circular = L["Circular"]},
					order = 2,
				},
			},
		},
		scale = {
			order = 3,
			name = L["Scale"],
			type = "group",
			args = {
				scaledesc = {
					order = 1,
					type = "description",
					name = L["Adjust the minimap scale, from 0.5 to 2.0"],
				},
				scaleset = {
					name = L["Scale"],
					type = "range",
					min = 0.5,
					max = 2,
					step = 0.01,
					get = function() return db.scale end,
					set = setScale,
					order = 2,
				},
			},
		},
		strata = {
			order = 4,
			name = L["Strata"],
			type = "group",
			args = {
				stratadesc = {
					order = 1,
					type = "description",
					name = L["Change the strata of the Minimap."],
				},
				strataset = {
					name = L["Strata"],
					type = "select",
					get = function() return db.strata end,
					set = setStrata,
					values = {TOOLTIP = "Tooltip", FULLSCREEN_DIALOG = "Fullscreen_dialog", FULLSCREEN = "Fullscreen",
					DIALOG = "Dialog", HIGH = "High", MEDIUM = "Medium", LOW = "Low", BACKGROUND = "Background"},
					order = 2,
				},
			},
		},
		lock = {
			order = 5,
			name = L["Lock"],
			type = "group",
			args = {
				lockdesc = {
					order = 1,
					type = "description",
					name = L["Lock the minimap in its current location."],
				},
				lockset = {
					name = L["Lock"],
					type = "toggle",
					get = function() return db.lock end,
					set = setLock,
					order = 2,
				},
			},
		},
	}
}

------------------------------
--      Initialization      --
------------------------------

function BasicMinimap:OnInitialize()
	BasicMinimap.db = LibStub("AceDB-3.0"):New("BasicMinimapDB", defaults)
	db = self.db.profile

	LibStub("AceConfig-3.0"):RegisterOptionsTable("BasicMinimap", bmoptions)
	self:RegisterChatCommand("bm", function() LibStub("AceConfigDialog-3.0"):Open("BasicMinimap") end)
end

function BasicMinimap:OnEnable()
	if db.x and db.y then
		Minimap:ClearAllPoints()
		Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x, db.y)
	else
		Minimap:SetPoint("CENTER", UIParent, "CENTER")
	end

	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetClampedToScreen(true)

	if not db.lock then
		Minimap:SetMovable(true)
		Minimap:SetScript("OnDragStart", move)
		Minimap:SetScript("OnDragStop", stop)
	end

	Minimap:SetScale(db.scale)
	Minimap:SetFrameStrata(db.strata)
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

	local MinimapZoom = CreateFrame("Frame", "BasicMinimapZoom", Minimap)
	MinimapZoom:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
	MinimapZoom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT")
	MinimapZoom:EnableMouseWheel(true)
	MinimapZoom:SetScript("OnMouseWheel", zoom)
end
