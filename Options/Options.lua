
local acr = LibStub("AceConfigRegistry-3.0")
local acd = LibStub("AceConfigDialog-3.0")
local media = LibStub("LibSharedMedia-3.0")
local adbo = LibStub("AceDBOptions-3.0")
local map = Minimap
local L
do
	local _, mod = ...
	L = mod.L
end

acOptions = {
	name = "BasicMinimap",
	childGroups = "tab", type = "group",
	args = {
		main = {
			name = _G["MISCELLANEOUS"],
			order = 1, type = "group",
			args = {
				
		},
		--profiles = adbo:GetOptionsTable(map.db),
	},
}
acOptions.args.profiles.order = 2

acr:RegisterOptionsTable(acOptions.name, acOptions, true)
acd:SetDefaultSize(acOptions.name, 400, 540)

