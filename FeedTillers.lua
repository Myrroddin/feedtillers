--[[
	-- file and project errata --
	Project Author:		@project-author@
	Project Date:		@project-date-iso@
	Project Version:	@project-version@
	Project Revision:	@project-revision@

	File Author:		@file-author@
	File Date:			@file-date-iso@
	File Revision:		@file-revision@
]]--

local ADDON, AddOn = ...
local ADDON_TITLE = GetAddOnMetadata(ADDON, "Title")
local TILLERS
local LOCALE = GetLocale()
local event_frame = CreateFrame("frame")
local tooltip = "NAME"

local L = setmetatable({}, {__index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end})

if LOCALE == "deDE" then
--@localization(locale="deDE", format="lua_additive_table")@
return end

if LOCALE == "esES" or LOCALE == "esMX" then
--@localization(locale="esES", format="lua_additive_table")@
return end

if LOCALE == "frFR" then
--@localization(locale="frFR", format="lua_additive_table")@
return end

if LOCALE == "itIT" then
--@localization(locale="itIT", format="lua_additive_table")@
return end

if LOCALE == "koKR" then
--@localization(locale="koKR", format="lua_additive_table")@
return end

if LOCALE == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table")@
return end

if LOCALE == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table")@
return end

if LOCALE == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table")@
return end

if LOCALE == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table")@
return end

local qtip = LibStub("LibQTip-1.0")
local TomTom = _G.TomTom

local npcs = {
	{ factionID = 1273, itemID = 74643, questID = 30439, x = 52.6, y = 49.2 }, -- Jogu the Drunk
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

local sortByName = function(a, b)
	return a.name < b.name
end
local sortByItem = function(a, b)
	return a.item < b.item
end

local function UseTomTom(frame, npc)
	local x, y = npc.x/100, npc.y/100
	TomTom:AddWaypoint(376, x, y, {
		title = npc.name,
		source = ADDON_TITLE,
		minimap = true,
		world = true,
		crazy = true,
		silent = false,
		persistant = false
	}) --376 is the mapID for Valley of the Four Winds

	-- let the user know why the arrow isn't visible and when it will become visible
	local uiMapID = C_Map.GetBestMapForUnit("player")
	local info = C_Map.GetMapInfo(uiMapID)
	if info.parentMapID ~= 424 or info.parentMapID == 0 then
		print("|cFF00FF00FeedTillers:|r " .. L["You are not on Pandaria currently. Once you are on that continent the waypoint arrow will display."])
	end
end

local function CreateBroker()
	LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
		type = "data source",
		text = ADDON_TITLE,
		icon = [[Interface/ICONS/Achievement_Profession_ChefHat]],
		OnClick = function(self)
			if IsShiftKeyDown() then
				FeedTillersDB.showComplete = not FeedTillersDB.showComplete
				if FeedTillersDB.showComplete then
					print("|cFF00FF00FeedTillers:|r " .. L["Showing completed quest for the day."])
				else
					print("|cFF00FF00FeedTillers:|r " .. L["Hiding completed quest for the day."])
				end
			elseif IsControlKeyDown() then
				FeedTillersDB.showBestFriends = not FeedTillersDB.showBestFriends
				if FeedTillersDB.showBestFriends then
					print("|cFF00FF00FeedTillers:|r " .. L["Showing Best Friends."])
				else
					print("|cFF00FF00FeedTillers:|r " .. L["Hiding Best Friends."])
				end
			else
				FeedTillersDB.currentSort = FeedTillersDB.currentSort == "NAME" and "ITEM" or "NAME"
				sort(npcs, FeedTillersDB.currentSort == "NAME" and sortByName or sortByItem)
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
			tooltip:SmartAnchorTo(self)
			tooltip:SetAutoHideDelay(0.1, self)
			tooltip:EnableMouse(true)
			tooltip:Clear()
			tooltip:AddHeader(TILLERS, ITEMS, COMPLETE)

			local line
			local showComplete = FeedTillersDB.showComplete
			local showBestFriends = FeedTillersDB.showBestFriends

			for i = 1, #npcs do
				local npc = npcs[i]
				npc.name, npc.noop, npc.standingID = GetFactionInfoByID(npc.factionID) -- npc.noop is not used by FeedTillers
				local hasNextLevel = select(9, GetFriendshipReputation(npc.factionID)) -- will be nil if Best Friend
				if not npc.item then
					npc.item = GetItemInfo(npc.itemID)
				end

				-- cache the item so we don't have to keep looking it up
				if not FeedTillersDB["Tillers"][npc.name] then
					print("|cFF00FF00FeedTillers:|r " .. L["The food item is being cached. Please wait and try viewing the display a few times until it is updated."])
					FeedTillersDB["Tillers"][npc.name] = npc.item
				end

				if not C_QuestLog.IsQuestFlaggedCompleted(npc.questID) then
					-- note "line" is no longer local to this scope!
					local count = GetItemCount(npc.itemID)
					line = tooltip:AddLine(npc.name, FeedTillersDB["Tillers"][npc.name], format("%d/%d", count, 5))

					if count < 5 then
						tooltip:SetLineTextColor(line, 1, 0.27, 0, 0.7)
					end
				elseif showComplete then
					line = tooltip:AddLine(npc.name, FeedTillersDB["Tillers"][npc.name], YES)
					tooltip:SetLineTextColor(line, 0, 0.5, 0, 0.7)
				elseif not showBestFriends and not hasNextLevel or not showComplete and C_QuestLog.IsQuestFlaggedCompleted(npc.questID) then
					line = tooltip:AddLine() -- add empty line with no height
				end

				if TomTom then
					tooltip:SetLineScript(line, "OnMouseUp", UseTomTom, npc)
				end
			end

			--[[
			if not line then
				showComplete = nil
				showBestFriends = nil
				self:GetScript("OnLeave")(self)
				return self:GetScript("OnEnter")(self)
			end
			]]--

			line = tooltip:AddLine(" ") -- blank line

			line = tooltip:AddLine(" ")
			tooltip:SetCell(line, 1, NORMAL_FONT_COLOR_CODE .. L["Click the plugin to sort by Tiller name or item name"], "LEFT", 3)

			line = tooltip:AddLine(" ")
			tooltip:SetCell(line, 1, NORMAL_FONT_COLOR_CODE .. L["Hold the <Shift> key and click to hide already fed Tillers"], "LEFT", 3)

			line = tooltip:AddLine(" ")
			tooltip:SetCell(line, 1, NORMAL_FONT_COLOR_CODE .. L["Hold the <Control> key and click to hide Best Friend Tillers"], "LEFT", 3)

			if TomTom then
				line = tooltip:AddLine(" ")
				tooltip:SetCell(line, 1, NORMAL_FONT_COLOR_CODE .. L["Click a Tiller's line to set a waypoint in TomTom"], "LEFT", 3)
			end

			tooltip:Show()
		end,
		OnLeave = function(self)
			--[[
			if qtip:IsAcquired("FeedTillersTT") then
				qtip:Release(tooltip)
			end
			tooltip = nil
			]]--
		end
	})
end

event_frame:RegisterEvent("PLAYER_LOGIN")
event_frame:SetScript("OnEvent", function(self, ...)
	if ... == "PLAYER_LOGIN" then
		FeedTillersDB = FeedTillersDB or {}
		FeedTillersDB["Tillers"] = FeedTillersDB["Tillers"] or {}
		FeedTillersDB.showComplete = FeedTillersDB.showComplete or true
		FeedTillersDB.showBestFriends = FeedTillersDB.showBestFriends or true
		FeedTillersDB.currentSort = FeedTillersDB.currentSort or "NAME"

		-- clean up old saved variables
		FeedTillers_hideComplete = nil
		FeedTillers_currentSort = nil

		CreateBroker()
	end
end)