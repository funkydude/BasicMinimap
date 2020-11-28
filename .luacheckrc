std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
}
ignore = {
	"11/SLASH_BASICMINIMAP[12]", -- slash handlers
}
globals = {
	-- Lua
	"date",
	"tonumber",

	-- Addon
	"BasicMinimap",
	"LibStub",

	-- WoW
	"CreateFrame",
	"EnableAddOn",
	"GetLocale",
	"LoadAddOn",
	"SlashCmdList",
	"UIParent",
}
