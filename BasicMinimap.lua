
local name = ...
local media = LibStub("LibSharedMedia-3.0")
local ldbi = LibStub("LibDBIcon-1.0")

local blizzButtonPositions = {
	[328] = MinimapZoomIn,
	[302] = MinimapZoomOut,
	[44] = GameTimeFrame,
	[20] = MiniMapMailFrame,
}

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
frame:Hide()
frame:SetScript("OnEvent", function(f, event, ...)
	f[event](f, event, ...)
end)
frame.blizzButtonPositions = blizzButtonPositions

function frame:HideButtons(_, _, name)
	ldbi:ShowOnEnter(name, true)
end

-- Init
function frame:ADDON_LOADED(event, addon)
	if addon == "BasicMinimap" then
		self:UnregisterEvent(event)
		self[event] = nil

		local defaults = {
			profile = {
				lock = false,
				shape = "SQUARE",
				clock = true,
				zoneText = true,
				missions = true,
				raidDiffIcon = true,
				zoomBtn = false,
				autoZoom = true,
				hideAddons = true,
				position = {"CENTER", "CENTER", 0, 0},
				borderSize = 3,
				size = 140,
				scale = 1,
				fontSize = 12,
				radius = 5,
				outline = "OUTLINE",
				monochrome = false,
				font = media:GetDefault("font"),
				colorBorder = {0,0.6,0,1},
				mapBtn = "RightButton",
			}
		}
		self.db = LibStub("AceDB-3.0"):New("BasicMinimapClassicSV", defaults, true)

		-- Return minimap shape for other addons
		if self.db.profile.shape ~= "ROUND" then
			function GetMinimapShape()
				return "SQUARE"
			end
		end

		if self.db.profile.hideAddons then
			local tbl = ldbi:GetButtonList()
			for i = 1, #tbl do
				ldbi:ShowOnEnter(tbl[i], true)
			end
			ldbi.RegisterCallback(self, "LibDBIcon_IconCreated", "HideButtons")
		end
	end
end
frame:RegisterEvent("ADDON_LOADED")

-- Enable
function frame:PLAYER_LOGIN(event)
	self:UnregisterEvent(event)
	self[event] = nil

	local Minimap = Minimap
	self.SetParent(Minimap, UIParent)
	self.EnableMouse(MinimapCluster, false)

	-- Backdrop, creating the border cleanly
	local backdrop = self.CreateTexture(Minimap, nil, "BACKGROUND")
	backdrop:SetPoint("CENTER", Minimap, "CENTER")
	backdrop:SetSize(self.db.profile.size + self.db.profile.borderSize, self.db.profile.size + self.db.profile.borderSize)
	backdrop:SetColorTexture(unpack(self.db.profile.colorBorder))
	local mask = self:CreateMaskTexture()
	mask:SetAllPoints(backdrop)
	mask:SetParent(Minimap)
	backdrop:AddMaskTexture(mask)
	frame.backdrop = backdrop
	frame.mask = mask

	self.ClearAllPoints(Minimap)
	self.SetPoint(Minimap, self.db.profile.position[1], UIParent, self.db.profile.position[2], self.db.profile.position[3], self.db.profile.position[4])
	self.RegisterForDrag(Minimap, "LeftButton")
	self.SetClampedToScreen(Minimap, true)

	self.SetScript(Minimap, "OnDragStart", function(self) if frame.IsMovable(self) then frame.StartMoving(self) end end)
	self.SetScript(Minimap, "OnDragStop", function(self)
		frame.StopMovingOrSizing(self)
		local a, _, b, c, d = frame.GetPoint(self)
		frame.db.profile.position[1] = a
		frame.db.profile.position[2] = b
		frame.db.profile.position[3] = c
		frame.db.profile.position[4] = d
	end)
	self.SetMovable(Minimap, not self.db.profile.lock)

	if self.db.profile.scale ~= 1 then -- Non-default
		self.SetScale(Minimap, self.db.profile.scale)
	end
	if self.db.profile.size ~= 140 then -- Non-default
		self.SetSize(Minimap, self.db.profile.size, self.db.profile.size)
		-- I'm not sure of a better way to update the render layer to the new size
		if Minimap:GetZoom() ~= 5 then
			Minimap_ZoomInClick()
			Minimap_ZoomOutClick()
		else
			Minimap_ZoomOutClick()
			Minimap_ZoomInClick()
		end
	end
	ldbi:SetButtonRadius(self.db.profile.radius) -- Do this after changing size as an easy way to avoid having to call :Refresh
	self.SetParent(MinimapNorthTag, self) -- North tag (static minimap)
	self.SetParent(MinimapCompassTexture, self) -- North tag & compass (when rotating minimap is enabled)
	self.SetParent(MinimapBorderTop, self) -- Zone text border
	self.SetParent(MinimapBorder, self) -- Minimap border

	local shape = self.db.profile.shape
	if shape == "SQUARE" then
		Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
		mask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
	else
		Minimap:SetMaskTexture("Interface\\AddOns\\BasicMinimap\\circle")
		mask:SetTexture("Interface\\AddOns\\BasicMinimap\\circle")
	end

	-- Zoom buttons
	if not self.db.profile.zoomBtn then
		self.SetParent(MinimapZoomIn, self)
		self.SetParent(MinimapZoomOut, self)
	else
		self.SetParent(MinimapZoomIn, Minimap)
		self.SetParent(MinimapZoomOut, Minimap)
	end

	-- Create font flag
	local flags = nil
	if self.db.profile.monochrome and self.db.profile.outline ~= "NONE" then
		flags = "MONOCHROME," .. self.db.profile.outline
	elseif self.db.profile.monochrome then
		flags = "MONOCHROME"
	elseif self.db.profile.outline ~= "NONE" then
		flags = self.db.profile.outline
	end
	--

	-- Clock
	self.ClearAllPoints(TimeManagerClockButton)
	self.SetPoint(TimeManagerClockButton, "TOP", backdrop, "BOTTOM", 0, 6)
	self.SetWidth(TimeManagerClockButton, 100)
	TimeManagerClockTicker:SetFont(media:Fetch("font", self.db.profile.font), self.db.profile.fontSize, flags)
	local clockBorder = self.GetRegions(TimeManagerClockButton)
	self.SetParent(clockBorder, self) -- Hide the border
	if not self.db.profile.clock then
		self.SetParent(TimeManagerClockButton, self)
	end

	self.SetParent(MiniMapWorldMapButton, self) -- World map button
	self.SetParent(GameTimeFrame, self) -- Day/Night button
	self.SetParent(MinimapToggleButton, self) -- Minimap "X" to close button

	-- Zone text
	self.SetParent(MinimapZoneTextButton, Minimap)
	self.ClearAllPoints(MinimapZoneTextButton)
	self.SetPoint(MinimapZoneTextButton, "BOTTOM", backdrop, "TOP", 0, 2)
	self.ClearAllPoints(MinimapZoneText)
	self.SetPoint(MinimapZoneText, "BOTTOM", MinimapZoneTextButton, "BOTTOM") -- Prevent text overlapping the border
	self.SetWidth(MinimapZoneText, self.db.profile.size) -- Prevent text cropping
	self.SetHeight(MinimapZoneText, self.db.profile.fontSize) -- Prevent text cropping
	MinimapZoneText:SetFont(media:Fetch("font", self.db.profile.font), self.db.profile.fontSize, flags)
	if not self.db.profile.zoneText then
		self.SetParent(MinimapZoneTextButton, self)
	end

	-- Update all blizz button positions
	for position, button in next, blizzButtonPositions do
		self.ClearAllPoints(button)
		ldbi:SetButtonToPosition(button, position)
	end

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
		if frame.db.profile.autoZoom then
			started = started + 1
			C_Timer.After(4, zoomOut)
		end
	end
	zoomBtnFunc()
	self.HookScript(MinimapZoomIn, "OnClick", zoomBtnFunc)
	self.HookScript(MinimapZoomOut, "OnClick", zoomBtnFunc)

	self.EnableMouseWheel(Minimap, true)
	self.SetScript(Minimap, "OnMouseWheel", function(_, d)
		if d > 0 then
			MinimapZoomIn:Click()
		elseif d < 0 then
			MinimapZoomOut:Click()
		end
	end)

	self.SetScript(Minimap, "OnMouseUp", function(self, btn)
		if btn == frame.db.profile.mapBtn then
			MiniMapWorldMapButton:Click()
		elseif btn == "LeftButton" then
			Minimap_OnClick(self)
		end
	end)
end
frame:RegisterEvent("PLAYER_LOGIN")
