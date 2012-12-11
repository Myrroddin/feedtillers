--[[
	- file and project errata -
	Project Author:		@project-author@
	Project Date:		@project-date-iso@
	Project Version:	@project-version@
	
	File Author:		@file-author@
	File Date:			@file-date-iso@
	File Revision:		@file-revision@
]]--

-- local references so FindGlobals doesn't throw a fit
local _G = getfenv(0)
local LibStub = _G.LibStub
local GetLocale = _G.GetLocale
local GetFactionInfoByID = _G.GetFactionInfoByID
local GetItemInfo = _G.GetItemInfo
local GetQuestsCompleted = _G.GetQuestsCompleted
local COMPLETE = _G.COMPLETE
local ITEMS = _G.ITEMS
local YES = _G.YES
local NO = _G.NO
local wipe = _G.wipe

-- build addon and add localization table
local FeedTillers = LibStub("AceAddon-3.0"):NewAddon("FeedTillers")

-- load libraries
local ldb = LibStub("LibDataBroker-1.1")
local qtip = LibStub("LibQTip-1.0")

-- localize "Feed Tillers"
local addon_name = "Feed Tillers"
--[===[@non-debug@
local locale = GetLocale()
if locale == "esES" then
	addon_name = "@localization(locale="esES", key="Title", namespace="ToC")@"
elseif locale == "esMX" then
	addon_name = "@localization(locale="esMX", key="Title", namespace="ToC")@"
elseif locale == "deDE" then
	addon_name = "@localization(locale="deDE", key="Title", namespace="ToC")@"
elseif locale == "frFR" then
	addon_name = "@localization(locale="frFR", key="Title", namespace="ToC")@"
elseif locale == "koKR" then
	addon_name = "@localization(locale="koKR", key="Title", namespace="ToC")@"
elseif locale == "ruRU" then
	addon_name = "@localization(locale="ruRU", key="Title", namespace="ToC")@"
elseif locale == "zhTW" then
	addon_name = "@localization(locale="zhTW", key="Title", namespace="ToC")@"
elseif locale == "zhCN" then
	addon_name = "@localization(locale="zhCN", key="Title", namespace="ToC")@"
elseif locale == "ptBR" then
	addon_name = "@localization(locale="ptBR", key="Title", namespace="ToC")@"
elseif locale == "itIT" then
	addon_name = "@localization(locale="itIT", key="Title", namespace="ToC")@"
end
--@end-non-debug@]===]

-- local variables
-- we need to know which quests have been completed today
local Tillers_Quests = {
	30402, -- A Dish for Chee Chee
	30386, -- A Dish for Ella
	30421, -- A Dish for Farmer Fung
	30427, -- A Dish for Fish
	30390, -- A Dish for Gina Mudclaw
	30414, -- A Dish for Haohan Mudclaw
	30439, -- A Dish for Jogu
	30396, -- A Dish for Old Hillpaw
	30408, -- A Dish for Sho
	30433  -- A Dish for Tina Mudclaw
}
local completed_quests

-- frame script functions
local function data_obj_OnEnter(frame)
	local FT_Tooltip = qtip:Acquire("FeedTillersTT", 3, "CENTER", "CENTER", "CENTER")
	FeedTillers.tooltip = FT_Tooltip
	completed_quests = GetQuestsCompleted(Tillers_Quests)
	FT_Tooltip:AddHeader(GetFactionInfoByID(1272), ITEMS, COMPLETE)
	FT_Tooltip:AddLine(GetFactionInfoByID(1277), GetItemInfo(74647), completed_quests[30402] == true and YES or NO) -- Chee Chee
	FT_Tooltip:AddLine(GetFactionInfoByID(1275), GetItemInfo(74651), completed_quests[30386] == true and YES or NO) -- Ella
	FT_Tooltip:AddLine(GetFactionInfoByID(1283), GetItemInfo(74654), completed_quests[30421] == true and YES or NO) -- Farmer Fung
	FT_Tooltip:AddLine(GetFactionInfoByID(1282), GetItemInfo(74655), completed_quests[30427] == true and YES or NO) -- Fish Fellreed
	FT_Tooltip:AddLine(GetFactionInfoByID(1281), GetItemInfo(74644), completed_quests[30390] == true and YES or NO) -- Gina Mudclaw
	FT_Tooltip:AddLine(GetFactionInfoByID(1279), GetItemInfo(74642), completed_quests[30414] == true and YES or NO) -- Haohan Mudclaw
	FT_Tooltip:AddLine(GetFactionInfoByID(1273), GetItemInfo(74643), completed_quests[30439] == true and YES or NO) -- Jogu the Drunk
	FT_Tooltip:AddLine(GetFactionInfoByID(1276), GetItemInfo(74649), completed_quests[30396] == true and YES or NO) -- Old Hillpaw
	FT_Tooltip:AddLine(GetFactionInfoByID(1278), GetItemInfo(74645), completed_quests[30408] == true and YES or NO) -- Sho
	FT_Tooltip:AddLine(GetFactionInfoByID(1280), GetItemInfo(74652), completed_quests[30433] == true and YES or NO) -- Tina Mudclaw
	FT_Tooltip:SmartAnchorTo(frame)
	FT_Tooltip:Show()
end
	
local function data_obj_OnLeave()
	if qtip:IsAcquired("FeedTillersTT") then
		qtip:Release(FeedTillers.tooltip)
		FeedTillers.tooltip = nil		
		wipe(completed_quests)
	end
end	

function FeedTillers:OnInitialize()	
	-- create Broker display and populate
	local data_obj = ldb:NewDataObject(addon_name, {
		type = "data source",
		icon = [[Interface/ICONS/Achievement_Profession_ChefHat]],
		OnEnter = data_obj_OnEnter,
		OnLeave = data_obj_OnLeave
	})
end

function FeedTillers:OnEnable()
end

function FeedTillers:OnDisable()
end