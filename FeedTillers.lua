--[[
	FeedTillers Addon
	Shows daily gift requirements for Tiller NPCs in Valley of the Four Winds.
	Works with both Retail (Mainline) and Mists of Pandaria Classic.
	Automatically caches all required item names at login.

	Author: @project-author@
	Copyright: © 2012-2026 Paul Vandersypen. All rights reserved.
	Version: @project-version@
	Date: @project-date-iso@
--]]

-------------------------------------------------
-- Addon Setup & Constants
-------------------------------------------------
local ADDON = ...
local ADDON_TITLE = C_AddOns.GetAddOnMetadata(ADDON, "Title")
local LOCALE = GetLocale()

-- Upvalues for frequently used globals/API calls.
local C_GossipInfo_GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local C_Item_GetItemCount = C_Item.GetItemCount
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_Map_GetMapInfo = C_Map.GetMapInfo
local C_QuestLog_IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local format = string.format
local IsShiftKeyDown, IsControlKeyDown = IsShiftKeyDown, IsControlKeyDown
local ipairs = ipairs
local print = print
local sort = table.sort
local tostring = tostring


-- Constants
local activeTooltip
local DAILY_ITEM_COUNT = 5
local ITEMS, COMPLETE, YES = ITEMS, COMPLETE, YES
local NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE
local TILLERS_FACTION_NAME
local TOOLTIP_ALIGN_LEFT = "LEFT"
local TOOLTIP_ALIGN_RIGHT = "RIGHT"
local TOOLTIP_AUTO_HIDE_DELAY = 0.1
local TOOLTIP_BLANK = " "
local TOOLTIP_COLS = 3
local TOOLTIP_KEY = "FeedTillersTT"

local event_frame = CreateFrame("Frame")
---@type LibQTip-2.0
local qtip = LibStub("LibQTip-2.0")
local qtipCallbacks = {}

local function HandleTooltipRelease(_, tooltip)
	if activeTooltip == tooltip then
		activeTooltip = nil
	end
end

qtip.RegisterCallback(qtipCallbacks, "OnReleaseTooltip", HandleTooltipRelease)
local TomTom = TomTom -- Optional dependency

-- API compatibility flags
---@type boolean
---@flavor-narrows retail
local isMainline = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

-------------------------------------------------
-- Unified Faction API Wrapper
-------------------------------------------------
---@param factionID number
---@return (string name, number standingID, string? standingText) | (nil, nil, nil)
local function GetFactionData(factionID)
	if isMainline then
		local data = C_Reputation.GetFactionDataByID(factionID)
		if not data then return nil, nil, nil end
		return data.name, data.reaction, _G["FACTION_STANDING_LABEL"..data.reaction]
	else
		local name, _, standingID = GetFactionInfoByID(factionID)
		if not name or not standingID then return nil, nil, nil end
		return name, standingID, _G["FACTION_STANDING_LABEL"..standingID]
	end
end

-------------------------------------------------
-- Localized string table (stub, filled by packager)
-------------------------------------------------
local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end})

-- Locale-specific placeholders (replaced at build time)
if LOCALE == "deDE" then
--@localization(locale="deDE", format="lua_additive_table")@
elseif LOCALE == "esES" then
--@localization(locale="esES", format="lua_additive_table")@
elseif LOCALE == "esMX" then
--@localization(locale="esMX", format="lua_additive_table")@
elseif LOCALE == "frFR" then
--@localization(locale="frFR", format="lua_additive_table")@
elseif LOCALE == "itIT" then
--@localization(locale="itIT", format="lua_additive_table")@
elseif LOCALE == "koKR" then
--@localization(locale="koKR", format="lua_additive_table")@
elseif LOCALE == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table")@
elseif LOCALE == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table")@
elseif LOCALE == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table")@
elseif LOCALE == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table")@
end

-------------------------------------------------
-- NPC & Quest Data
-------------------------------------------------
local npcs = {
	{ factionID = 1273, itemID = 74643, questID = 30439, x = 53.6, y = 52.6 }, -- Jogu the Drunk
	{ factionID = 1275, itemID = 74651, questID = 30386, x = 31.6, y = 58.0 }, -- Ella
	{ factionID = 1276, itemID = 74649, questID = 30396, x = 31.0, y = 53.0 }, -- Old Hillpaw
	{ factionID = 1277, itemID = 74647, questID = 30402, x = 34.4, y = 46.8 }, -- Chee Chee
	{ factionID = 1278, itemID = 74645, questID = 30408, x = 29.6, y = 30.6 }, -- Sho
	{ factionID = 1279, itemID = 74642, questID = 30414, x = 44.6, y = 34.0 }, -- Haohan Mudclaw
	{ factionID = 1280, itemID = 74652, questID = 30433, x = 45.0, y = 33.8 }, -- Tina Mudclaw
	{ factionID = 1281, itemID = 74644, questID = 30390, x = 53.2, y = 51.6 }, -- Gina Mudclaw
	{ factionID = 1282, itemID = 74655, questID = 30427, x = 41.6, y = 30.0 }, -- Fish Fellreed
	{ factionID = 1283, itemID = 74654, questID = 30421, x = 48.2, y = 33.8 }, -- Farmer Fung
}

-- Sorting functions
local function sortByName(a, b) return (a.name or "") < (b.name or "") end
local function sortByItem(a, b) return (a.item or "") < (b.item or "") end

-------------------------------------------------
-- Automatic Item Cache
-------------------------------------------------
local function CacheAllItems()
	for _, npc in ipairs(npcs) do
		local itemObj = Item:CreateFromItemID(npc.itemID)
		itemObj:ContinueOnItemLoad(function()
			local itemName = itemObj:GetItemName()
			local name = GetFactionData(npc.factionID)
			npc.item = itemName or npc.item
			if name then
				npc.name = name
				FeedTillersDB.Tillers[name] = FeedTillersDB.Tillers[name] or npc.item or itemName
			end
		end)
	end
end

-------------------------------------------------
-- TomTom Waypoint Handler
-------------------------------------------------
local function UseTomTom(npc)
	local x, y = npc.x / 100, npc.y / 100
	local opts = {
		title = npc.name,
		from = ADDON_TITLE,
		minimap = true,
		world = true,
		crazy = true,
		silent = false,
		persistant = false
	}
	TomTom:AddWaypoint(376, x, y, opts) -- 376 is the mapID for Valley of the Four Winds

	local uiMapID = C_Map_GetBestMapForUnit("player")
	local info = uiMapID and C_Map_GetMapInfo(uiMapID)
	if not info or info.parentMapID ~= 424 then
		print("|cFF00FF00FeedTillers:|r " .. L["You are not on Pandaria currently. Once you are on that continent the waypoint arrow will display."])
	end
end

-------------------------------------------------
-- LibQTip-2.0 Tooltip Helpers
-------------------------------------------------
local function SetRowTextColor(row, r, g, b, a)
	if row then
		row:SetTextColor(r, g, b, a)
	end
end

local function AddTooltipTextLine(tooltip, text)
	local row = tooltip:AddHeadingRow(text)
	-- row:GetCell(1):SetColSpan(2):SetJustifyH(TOOLTIP_ALIGN_LEFT)
	return row
end

-------------------------------------------------
-- Broker Object Creation
-------------------------------------------------
local function CreateBroker()
	LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
		type = "data source",
		text = "",
		icon = [[Interface/ICONS/Achievement_Profession_ChefHat]],

		OnClick = function(self)
			if IsShiftKeyDown() then
				FeedTillersDB.showComplete = not FeedTillersDB.showComplete
				print("|cFF00FF00FeedTillers:|r " .. (FeedTillersDB.showComplete and L["Showing completed quest for the day."] or L["Hiding completed quest for the day."]))
			elseif IsControlKeyDown() then
				FeedTillersDB.showBestFriends = not FeedTillersDB.showBestFriends
				print("|cFF00FF00FeedTillers:|r " .. (FeedTillersDB.showBestFriends and L["Showing Best Friends."] or L["Hiding Best Friends."]))
			else
				FeedTillersDB.currentSort = (FeedTillersDB.currentSort == "NAME") and "ITEM" or "NAME"
				sort(npcs, FeedTillersDB.currentSort == "NAME" and sortByName or sortByItem)
			end
			self:GetScript("OnLeave")(self)
			self:GetScript("OnEnter")(self)
		end,

		OnEnter = function(self)
			if not npcs[1].name then
				for _, npc in ipairs(npcs) do
					local name = GetFactionData(npc.factionID)
					if name then
						npc.name = name
					end
				end
				sort(npcs, sortByName)
				CacheAllItems() -- Ensure all items are cached on first hover
			end

			local tooltip = qtip:AcquireTooltip(TOOLTIP_KEY, TOOLTIP_COLS, TOOLTIP_ALIGN_LEFT, TOOLTIP_ALIGN_LEFT, TOOLTIP_ALIGN_RIGHT)
			activeTooltip = tooltip
			tooltip:SmartAnchorTo(self)
			tooltip:SetAutoHideDelay(TOOLTIP_AUTO_HIDE_DELAY, self)
			tooltip:EnableMouse(true)
			tooltip:Clear()
			tooltip:AddHeadingRow(TILLERS_FACTION_NAME or ADDON_TITLE or ADDON, ITEMS, COMPLETE)

			local showComplete = FeedTillersDB.showComplete
			local showBestFriends = FeedTillersDB.showBestFriends

			for _, npc in ipairs(npcs) do
				local name, standingID = GetFactionData(npc.factionID)
				if name and standingID then
					npc.name, npc.standingID = name, standingID
					local itemName = FeedTillersDB.Tillers[name] or npc.item or "..."
					local friendshipData = C_GossipInfo_GetFriendshipReputation(npc.factionID)
					local hasNextLevel = friendshipData and friendshipData.nextThreshold

					local line
					if showBestFriends or hasNextLevel then
						if not C_QuestLog_IsQuestFlaggedCompleted(npc.questID) then
							local count = C_Item_GetItemCount(npc.itemID)
							line = tooltip:AddRow(name, itemName, format("%d/%d", count, DAILY_ITEM_COUNT))
							if count < DAILY_ITEM_COUNT then
								SetRowTextColor(line, 1, 0.27, 0, 0.7)
							end
							if not hasNextLevel then
								SetRowTextColor(line, 1, 1, 0, 0.7)
							end
						elseif showComplete then
							line = tooltip:AddRow(name, itemName, YES)
							SetRowTextColor(line, 0, 0.5, 0, 0.7)
							if not hasNextLevel then
								SetRowTextColor(line, 1, 1, 0, 0.7)
							end
						end
					end

					if TomTom and line then
						line:SetScript("OnMouseUp", function()
							UseTomTom(npc)
						end)
					end
				end
			end

			tooltip:AddRow(TOOLTIP_BLANK):GetCell(1):SetColSpan(TOOLTIP_COLS)
			tooltip:AddSeparator()
			tooltip:AddRow(TOOLTIP_BLANK):GetCell(1):SetColSpan(TOOLTIP_COLS)
			--[[
			tooltip:AddHeadingRow(NORMAL_FONT_COLOR_CODE .. L["Click to sort by Tiller name or item name"])
			tooltip:AddHeadingRow(NORMAL_FONT_COLOR_CODE .. L["<Shift> + Click to toggle showing completed quests"])
			tooltip:AddHeadingRow(NORMAL_FONT_COLOR_CODE .. L["<Control> + Click to toggle showing Best Friends"])
			--]]
			AddTooltipTextLine(tooltip, NORMAL_FONT_COLOR_CODE .. L["Click to sort by Tiller name or item name"])
			AddTooltipTextLine(tooltip, NORMAL_FONT_COLOR_CODE .. L["<Shift> + Click to toggle showing completed quests"])
			AddTooltipTextLine(tooltip, NORMAL_FONT_COLOR_CODE .. L["<Control> + Click to toggle showing Best Friends"])
			if TomTom then
				AddTooltipTextLine(tooltip, NORMAL_FONT_COLOR_CODE .. L["Click a Tiller's line to set a waypoint in TomTom"])
			end

			tooltip:Show()
		end,

		OnLeave = function(self)
			if activeTooltip then
				qtip:ReleaseTooltip(activeTooltip)
				activeTooltip = nil
			end
		end
	})
end

-------------------------------------------------
-- Event Handling
-------------------------------------------------
event_frame:RegisterEvent("PLAYER_LOGIN")
event_frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		FeedTillersDB = FeedTillersDB or {}
		FeedTillersDB.Tillers = FeedTillersDB.Tillers or {}
		FeedTillersDB.showComplete = FeedTillersDB.showComplete or true
		FeedTillersDB.showBestFriends = FeedTillersDB.showBestFriends or true
		FeedTillersDB.currentSort = FeedTillersDB.currentSort or "NAME"

		-- Pre-Cache Tillers faction name
		TILLERS_FACTION_NAME = GetFactionData(1272)

		-- Pre-cache faction names & item names at login
		for _, npc in ipairs(npcs) do
			local name = GetFactionData(npc.factionID)
			if name then
				npc.name = name
			end
		end
		CacheAllItems()

		CreateBroker()
	end
end)