--[[
    FeedTillers Addon
    Shows daily gift requirements for Tiller NPCs in Valley of the Four Winds.
    Works with both Retail (Mainline) and Mists of Pandaria Classic.
    Automatically caches all required item names at login.

    Author: @project-author@
    Copyright: © 2012-2025 Paul Vandersypen. All rights reserved.
    Version: @project-version@
    Date: @project-date-iso@
--]]

-------------------------------------------------
-- Addon Setup & Constants
-------------------------------------------------
local ADDON = ...
local ADDON_TITLE = C_AddOns.GetAddOnMetadata(ADDON, "Title")
local LOCALE = GetLocale()

local event_frame = CreateFrame("Frame")
local qtip = LibStub("LibQTip-1.0")
local TomTom = TomTom -- Optional dependency

-- API compatibility flags
local isMainline = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isMists    = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

-------------------------------------------------
-- Unified Faction API Wrapper
-------------------------------------------------
local function GetFactionData(factionID)
    if isMainline then
        local data = C_Reputation.GetFactionDataByID(factionID)
        if not data then return nil end
        return data.name, data.reaction, _G["FACTION_STANDING_LABEL"..data.reaction]
    elseif isMists then
        local name, _, standingID = GetFactionInfoByID(factionID)
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
end })

-- Locale-specific placeholders (replaced at build time)
if LOCALE == "deDE" then
	--@localization(locale="deDE", format="lua_additive_table")@
elseif LOCALE == "esES" or LOCALE == "esMX" then
	--@localization(locale="esES", format="lua_additive_table")@
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
local function sortByName(a, b) return a.name < b.name end
local function sortByItem(a, b) return a.item < b.item end

-------------------------------------------------
-- Automatic Item Cache
-------------------------------------------------
local function CacheAllItems()
    for _, npc in ipairs(npcs) do
        local itemObj = Item:CreateFromItemID(npc.itemID)
        itemObj:ContinueOnItemLoad(function()
            local itemName = itemObj:GetItemName()
            npc.item = itemName
            npc.name = GetFactionData(npc.factionID)
            FeedTillersDB.Tillers[npc.name] = FeedTillersDB.Tillers[npc.name] or npc.item or itemName
        end)
    end
end

-------------------------------------------------
-- TomTom Waypoint Handler
-------------------------------------------------
local function UseTomTom(_, npc)
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

    local uiMapID = C_Map.GetBestMapForUnit("player")
    local info = C_Map.GetMapInfo(uiMapID)
    if not info or info.parentMapID ~= 424 then
        print("|cFF00FF00FeedTillers:|r " .. L["You are not on Pandaria currently. Once you are on that continent the waypoint arrow will display."])
    end
end

-------------------------------------------------
-- Broker Object Creation
-------------------------------------------------
local function CreateBroker()
    LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
        type = "data source",
        text = ADDON_TITLE,
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
                    npc.name = GetFactionData(npc.factionID)
                end
                sort(npcs, sortByName)
                CacheAllItems() -- Ensure all items are cached on first hover
            end

            local tooltip = qtip:Acquire("FeedTillersTT", 3, "LEFT", "LEFT", "RIGHT")
            tooltip:SmartAnchorTo(self)
            tooltip:SetAutoHideDelay(0.1, self)
            tooltip:EnableMouse(true)
            tooltip:Clear()
            tooltip:AddHeader(GetFactionData(1272), ITEMS, COMPLETE)

            local showComplete = FeedTillersDB.showComplete
            local showBestFriends = FeedTillersDB.showBestFriends

            for _, npc in ipairs(npcs) do
                local name, standingID = GetFactionData(npc.factionID)
                npc.name, npc.standingID = name, standingID
                local itemName = FeedTillersDB.Tillers[npc.name] or npc.item or "..."
                local hasNextLevel = C_GossipInfo.GetFriendshipReputation(npc.factionID).nextThreshold

                local line
                if not C_QuestLog.IsQuestFlaggedCompleted(npc.questID) then
                    local count = C_Item.GetItemCount(npc.itemID)
                    line = tooltip:AddLine(npc.name, itemName, format("%d/%d", count, 5))
                    if count < 5 then
                        tooltip:SetLineTextColor(line, 1, 0.27, 0, 0.7)
                    end
                elseif showComplete then
                    line = tooltip:AddLine(npc.name, itemName, YES)
                    tooltip:SetLineTextColor(line, 0, 0.5, 0, 0.7)
                elseif not showBestFriends and not hasNextLevel then
                    line = tooltip:AddLine()
                end

                if TomTom and line then
                    tooltip:SetLineScript(line, "OnMouseUp", UseTomTom, npc)
                end
            end

            tooltip:AddLine(" ")
            tooltip:SetCell(tooltip:AddLine(" "), 1, NORMAL_FONT_COLOR_CODE .. L["Click to sort by Tiller name or item name"], "LEFT", 3)
            tooltip:SetCell(tooltip:AddLine(" "), 1, NORMAL_FONT_COLOR_CODE .. L["<Shift> + Click to toggle showing completed quests"], "LEFT", 3)
            tooltip:SetCell(tooltip:AddLine(" "), 1, NORMAL_FONT_COLOR_CODE .. L["<Control> + Click to toggle showing Best Friends"], "LEFT", 3)
            if TomTom then
                tooltip:SetCell(tooltip:AddLine(" "), 1, NORMAL_FONT_COLOR_CODE .. L["Click a Tiller's line to set a waypoint in TomTom"], "LEFT", 3)
            end

            tooltip:Show()
        end,

        OnLeave = function(self)
            qtip:Release(self.tooltip)
            self.tooltip = nil
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

        -- Pre-cache faction names & item names at login
        for _, npc in ipairs(npcs) do
            npc.name = GetFactionData(npc.factionID)
        end
        CacheAllItems()

        CreateBroker()
    end
end)