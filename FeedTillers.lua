--[[
	- file and project errata -
	Project Author:		@project-author@
	Project Date:		@project-date-iso@
	Project Version:	@project-version@
	Project Revision:	@project-revision@
	
	File Author:		@file-author@
	File Date:			@file-date-iso@
	File Revision:		@file-revision@
]]--

-- GLOBALS: sort, GetAddOnMetadata, GetFactionInfoByID, GetItemInfo, IsQuestFlaggedCompleted, GetLocale
-- GLOBALS: COMPLETE, ITEMS, NO, YES, GameTooltip
-- GLOBALS: LibStub

local ADDON, L = ...
local ADDON_TITLE = GetAddOnMetadata(ADDON, "Title")
local TILLERS
locale LOCALE = GetLocale()

--@non-debug@
-- translate the tooltips
if LOCALE == "enUS" then
@localization(locale="enUS", format="lua_additive_table")@
elseif LOCALE == "esES" then
@localization(locale="esES", format="lua_additive_table")@
elseif LOCALE == "esMX" then
@localization(locale="esMX", format="lua_additive_table")@
elseif LOCALE == "itIT" then
@localization(locale="itIT", format="lua_additive_table")@
elseif LOCALE == "ptBR" then
@localization(locale="ptBR", format="lua_additive_table")@
elseif LOCALE == "frFR" then
@localization(locale="frFR", format="lua_additive_table")@
elseif LOCALE == "deDE" then
@localization(locale="deDE", format="lua_additive_table")@
elseif LOCALE == "ruRU" then
@localization(locale="ruRU", format="lua_additive_table")@
elseif LOCALE == "zhCN" then
@localization(locale="zhCN", format="lua_additive_table")@
elseif LOCALE == "zhTW" then
@localization(locale="zhTW", format="lua_additive_table")@
end
--@end-non-debug@
--@debug@
if LOCALE == "enUS" then
L["CLICK_SORT"] = "Click the plugin to sort by Tiller name or item name"
L["SHIFT_DOWN"] = "Hold the <Shift> key to hide already fed Tillers"
end
--@end-debug@

local qtip = LibStub("LibQTip-1.0")

local npcs = {
	{ factionID = 1273, itemID = 74643, questID = 30439 }, -- Jogu the Drunk
	{ factionID = 1275, itemID = 74651, questID = 30386 }, -- Ella
	{ factionID = 1276, itemID = 74649, questID = 30396 }, -- Old Hillpaw
	{ factionID = 1277, itemID = 74647, questID = 30402 }, -- Chee Chee
	{ factionID = 1278, itemID = 74645, questID = 30408 }, -- Sho
	{ factionID = 1279, itemID = 74642, questID = 30414 }, -- Haohan Mudclaw
	{ factionID = 1280, itemID = 74652, questID = 30433 }, -- Tina Mudclaw
	{ factionID = 1281, itemID = 74644, questID = 30390 }, -- Gina Mudclaw
	{ factionID = 1282, itemID = 74655, questID = 30427 }, -- Fish Fellreed
	{ factionID = 1283, itemID = 74654, questID = 30421 }, -- Farmer Fung
}

local currentSort, hideComplete, tooltip = "NAME"
local sortByName = function(a, b)
	return a.name < b.name
end
local sortByItem = function(a, b)
	return a.item < b.item
end

LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
	type = "data source",
	text = ADDON_TITLE,
	icon = [[Interface/ICONS/Achievement_Profession_ChefHat]],
	OnClick = function(self)
		if IsShiftKeyDown() then
			hideComplete = not hideComplete
		else
			currentSort = currentSort == "NAME" and "ITEM" or "NAME"
			sort(npcs, currentSort == "NAME" and sortByName or sortByItem)
		end
		GameTooltip:AddLine(L.SHIFT_DOWN)
		GameTooltip:AddLine(L.CLICK_SORT)
		self:GetScript("OnLeave")(self)
		self:GetScript("OnEnter")(self)
	end,
	OnEnter = function(self)
		if not TILLERS then
			TILLERS = GetFactionInfoByID(1272)
			for i = 1, #npcs do
				local npc = npcs[i]
				npc.name = GetFactionInfoByID(npc.factionID)
			end
			sort(npcs, sortByName)
		end

		tooltip = qtip:Acquire("FeedTillersTT", 3, "LEFT", "LEFT", "RIGHT")
		tooltip:AddHeader(TILLERS, ITEMS, COMPLETE)
		for i = 1, #npcs do
			local npc = npcs[i]
			if not npc.item then
				npc.item = GetItemInfo(npc.itemID)
			end
			if not IsQuestFlaggedCompleted(npc.questID) then
				local line = tooltip:AddLine(npc.name, npc.item, NO)
				tooltip:SetLineColor(line, 1, 0.1, 0.1, 0.3)
			elseif not hideComplete then
				local line = tooltip:AddLine(npc.name, npc.item, YES)
				tooltip:SetLineColor(line, 0.1, 1, 0.1, 0.3)
			end
		end
		tooltip:SmartAnchorTo(self)
		tooltip:Show()
	end,
	OnLeave = function(self)
		if qtip:IsAcquired("FeedTillersTT") then
			qtip:Release(tooltip)
		end
		tooltip = nil
	end
})