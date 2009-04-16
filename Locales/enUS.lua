local debug = false
--@debug@
debug = true
--@end-debug@

local L = LibStub("AceLocale-3.0"):NewLocale("BasicMinimap","enUS",true,debug)
--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="concat")@

L["Intro"] = "BasicMinimap is a basic solution to a clean, square minimap. Allowing scaling, moving, mouse-wheel zooming, strata changing and locking of the minimap."

L["Shape"] = true
L["Change the minimap shape, curcular or square."] = true

L["Scale"] = true
L["Adjust the minimap scale, from 0.5 to 2.0"] = true

L["Strata"] = true
L["Change the strata of the Minimap."] = true

L["Lock the minimap in its current location."] = true

L["Tooltip"] = true
L["Fullscreen_dialog"] = true
L["Fullscreen"] = true
L["Dialog"] = true

L["Border Color"] = true
L["Change the minimap border color."] = true

L["Border Size"] = true
L["Adjust the minimap border size."] = true

L["Button Description"] = "Choose the buttons for opening the Calendar and tracking menu.\nOptions are: RightButton, MiddleButton, Button4, Button5 ..."

L["Calendar"] = true
L["Tracking"] = true
