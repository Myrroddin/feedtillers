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

-- GLOBALS: sort, GetAddOnMetadata, GetFactionInfoByID, GetItemInfo, IsQuestFlaggedCompleted
-- GLOBALS: COMPLETE, ITEMS, NO, YES
-- GLOBALS: LibStub

local ADDON = ...
local ADDON_TITLE = GetAddOnMetadata(ADDON, "Title")
local TILLERS

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