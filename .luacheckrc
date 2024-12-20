std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
}
ignore = {
	"111/SLASH_BASICMINIMAP[12]", -- slash handlers
	"111/GetMinimapShape",
	"112/SlashCmdList", -- SlashCmdList.BASICMINIMAP
	"122/Minimap", -- Minimap.ZoomIn.IsMouseOver
}
read_globals = {
	-- Lua
	"date",
	"tonumber",

	-- Addon
	"BasicMinimap",
	"CUSTOM_CLASS_COLORS",
	"LibStub",

	-- WoW (general API)
	"AnchorUtil",
	"CreateFrame",
	"C_AddOns",
	"C_Calendar",
	"C_DateAndTime",
	"C_PvP",
	"C_Map",
	"C_Timer",
	"EnableAddOn",
	"GameTime_GetGameTime",
	"GameTime_GetLocalTime",
	"GetCVarBool",
	"GetGameTime",
	"GetLocale",
	"GetMinimapZoneText",
	"GetSubZoneText",
	"GetZonePVPInfo",
	"GetZoneText",
	"HIGHLIGHT_FONT_COLOR",
	"hooksecurefunc",
	"InCombatLockdown",
	"LoadAddOn",
	"NORMAL_FONT_COLOR",
	"RAID_CLASS_COLORS",
	"ReloadUI",
	"SecondsToTime",
	"ToggleDropDownMenu",
	"UIParent",
	"UnitClass",

	-- WoW (global strings)
	"COMBAT_ZONE",
	"CONTESTED_TERRITORY",
	"DAILY",
	"FACTION_CONTROLLED_TERRITORY",
	"FREE_FOR_ALL_TERRITORY",
	"GAMETIME_TOOLTIP_TOGGLE_CLOCK",
	"MONTH_JANUARY",
	"MONTH_FEBRUARY",
	"MONTH_MARCH",
	"MONTH_APRIL",
	"MONTH_MAY",
	"MONTH_JUNE",
	"MONTH_JULY",
	"MONTH_AUGUST",
	"MONTH_SEPTEMBER",
	"MONTH_OCTOBER",
	"MONTH_NOVEMBER",
	"MONTH_DECEMBER",
	"RESET",
	"SANCTUARY_TERRITORY",
	"STAT_FORMAT",
	"TIMEMANAGER_TICKER_24HOUR",
	"TIMEMANAGER_TICKER_12HOUR",
	"TIMEMANAGER_TOOLTIP_LOCALTIME",
	"TIMEMANAGER_TOOLTIP_REALMTIME",
	"TIMEMANAGER_TOOLTIP_TITLE",
	"WEEKLY",

	-- WoW (minimap related)
	"AddonCompartmentFrame",
	"ExpansionLandingPageMinimapButton",
	"GameTimeFrame",
	"GarrisonLandingPageMinimapButton",
	"GuildInstanceDifficulty",
	"HybridMinimap",
	"Minimap",
	"MinimapBackdrop",
	"MinimapBorder",
	"MinimapBorderTop",
	"MiniMapChallengeMode",
	"MinimapCluster",
	"MiniMapInstanceDifficulty",
	"MiniMapMailFrame",
	"MiniMapMailIcon",
	"MiniMapCraftingOrderIcon",
	"MinimapNorthTag",
	"MiniMapTracking",
	"MiniMapTrackingButton",
	"MiniMapTrackingDropDown",
	"MiniMapWorldMapButton",
	"MinimapZoneText",
	"MinimapZoneTextButton",
	"MinimapZoomIn",
	"MinimapZoomOut",
	"Minimap_OnClick",
	"Minimap_ZoomInClick",
	"Minimap_ZoomOutClick",
	"QueueStatusMinimapButton",
	"TimeManagerClockButton",
	"TimeManagerClockTicker",
	"TimeManagerFrame",
	"ToggleWorldMap",

	-- Classic
	"LFGMinimapFrame", -- classic era
	"MiniMapBattlefieldFrame",
	"MinimapToggleButton",
	"MiniMapLFGFrame", -- tbc and beyond
	"GetTrackingTexture",
	"MiniMapTrackingIcon",
}
