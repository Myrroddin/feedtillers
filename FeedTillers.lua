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
-- GLOBALS: COMPLETE, ITEMS, YES
-- GLOBALS: LibStub
-- GLOBALS: FeedTillers_hideComplete, FeedTillers_currentSort

local ADDON, L = ...
local ADDON_TITLE = GetAddOnMetadata(ADDON, "Title")
local TILLERS
local LOCALE = GetLocale()
local event_frame = CreateFrame("frame")

-- translate the tooltips
if LOCALE == "esES" then
--@localization(locale="esES", format="lua_additive_table")@
elseif LOCALE == "esMX" then
--@localization(locale="esMX", format="lua_additive_table")@
elseif LOCALE == "itIT" then
--@localization(locale="itIT", format="lua_additive_table")@
elseif LOCALE == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table")@
elseif LOCALE == "frFR" then
--@localization(locale="frFR", format="lua_additive_table")@
elseif LOCALE == "deDE" then
--@localization(locale="deDE", format="lua_additive_table")@
elseif LOCALE == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table")@
elseif LOCALE == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table)@
elseif LOCALE == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table")@
else
L["CLICK_SORT"] = "Click the plugin to sort by Tiller name or item name"
L["SHIFT_DOWN"] = "Hold the <Shift> key and click to hide already fed Tillers"
end

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

local tooltip = "NAME"
local sortByName = function(a, b)
	return a.name < b.name
end
local sortByItem = function(a, b)
	return a.item < b.item
end

local function CreateBroker()
	LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
		type = "data source",
		text = ADDON_TITLE,
		icon = [[Interface/ICONS/Achievement_Profession_ChefHat]],
		OnClick = function(self)
			if IsShiftKeyDown() then
				FeedTillers_hideComplete = not FeedTillers_hideComplete
			else
				FeedTillers_currentSort = FeedTillers_currentSort == "NAME" and "ITEM" or "NAME"
				sort(npcs, FeedTillers_currentSort == "NAME" and sortByName or sortByItem)
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
			local line
			local hideComplete = FeedTillers_hideComplete
			for i = 1, #npcs do
				local npc = npcs[i]
				if not npc.item then
					npc.item = GetItemInfo(npc.itemID)
				end
				if not IsQuestFlaggedCompleted(npc.questID) then
					-- note "line" is no longer local to this scope!
					local count = GetItemCount(npc.itemID)
					line = tooltip:AddLine(npc.name, npc.item, format("%d/%d", count, 5))
					if count < 5 then
						tooltip:SetLineColor(line, 1, 0.1, 0.1, 0.3)
					end
				elseif not hideComplete then
					line = tooltip:AddLine(npc.name, npc.item, YES)
					tooltip:SetLineColor(line, 0.1, 1, 0.1, 0.3)
				end
			end

			if not line then
				hideComplete = nil
				self:GetScript("OnLeave")(self)
				return self:GetScript("OnEnter")(self)
			end

			line = tooltip:AddLine(" ") -- blank line

			line = tooltip:AddLine(" ")
			tooltip:SetCell(line, 1, NORMAL_FONT_COLOR_CODE .. L.CLICK_SORT, "LEFT", 3)

			line = tooltip:AddLine(" ")
			tooltip:SetCell(line, 1, NORMAL_FONT_COLOR_CODE .. L.SHIFT_DOWN, "LEFT", 3)

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
end

event_frame:RegisterEvent("ADDON_LOADED")
event_frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and ... == ADDON then	
		if not FeedTillers_hideComplete then
			FeedTillers_hideComplete = false
		end
		if not FeedTillers_currentSort then
			FeedTillers_currentSort = "NAME"
		end
	end	
	CreateBroker()
	self:UnregisterEvent("ADDON_LOADED")
end)