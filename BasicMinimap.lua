--[[
	Square minimap with basic options
	Features:
	-Moving of the minimap
	-Scaling of the minimap
	-Hiding all minimap buttons
]]

------------------------------
--      Are you local?      --
------------------------------

local _G = _G
local db
local defaults = {
	profile = {
		scale = 1.0,
		x = nil,
		y = nil,
		lock = nil,
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

local function move() this:StartMoving() end
local function stop()
	this:StopMovingOrSizing()
	db.x, db.y = Minimap:GetCenter()
end

local function setScale(n, scale)
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

local bmoptions = {
	type = "group",
	name = "BasicMinimap",
	args = {
		lock = {
			name = "Lock",
			desc = "Lock the minimap.",
			type = "toggle",
			get = function() return db.lock end,
			set = setLock
		},
		scale = {
			name = "Scale",
			type = "range",
			desc = "Adjust the minimap scale.",
			min = 0.5,
			max = 2,
			step = 0.1,
			get = function() return db.scale end,
			set = setScale,
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
	local x = db.x
	local y = db.y
	if x and y then
		Minimap:ClearAllPoints()
		Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
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
	MinimapNorthTag:Hide()

	MinimapBorder:SetTexture()
	MinimapBorderTop:Hide()
	Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\Mask.blp")

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

	local MinimapZoom = CreateFrame("Frame", "BasicMinimapZoom", Minimap)
	MinimapZoom:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
	MinimapZoom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT")
	MinimapZoom:EnableMouseWheel(true)
	MinimapZoom:SetScript("OnMouseWheel", zoom)
end
