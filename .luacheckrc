std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
}
ignore = {
	"11/SLASH_BASICMINIMAP[12]", -- slash handlers
	"11/GetMinimapShape",
}
globals = {
	-- Lua
	"date",
	"tonumber",

	-- Addon
	"BasicMinimap",
	"CUSTOM_CLASS_COLORS",
	"LibStub",

	-- WoW (general API)
	"CreateFrame",
	"C_Calendar",
	"C_Map",
	"C_Timer",
	"EnableAddOn",
	"GetCVarBool",
	"GetGameTime",
	"GetLocale",
	"GetZonePVPInfo",
	"LoadAddOn",
	"RAID_CLASS_COLORS",
	"SlashCmdList",
	"ToggleDropDownMenu",
	"UIParent",
	"UnitClass",

	-- WoW (global strings)
	"TIMEMANAGER_TICKER_24HOUR",
	"TIMEMANAGER_TICKER_12HOUR",

	-- WoW (minimap related)
	"GameTimeFrame",
	"GarrisonLandingPageMinimapButton",
	"GuildInstanceDifficulty",
	"HybridMinimap",
	"Minimap",
	"MiniMapChallengeMode",
	"MiniMapInstanceDifficulty",
	"MiniMapTrackingDropDown",
	"MiniMapWorldMapButton",
	"MinimapZoomIn",
	"MinimapZoomOut",
	"Minimap_OnClick",
	"Minimap_ZoomInClick",
	"Minimap_ZoomOutClick",
}
