local A = FonzAppraiser
local L = A.locale

A.module 'fa'

local util = A.requires(
  'util.table',
  'util.money',
  'util.item',
  'util.group'
)
local palette = A.require 'fa.palette'
local pricing = A.require 'fa.value.pricing'
local filter = A.require 'fa.filter'
local session = A.require 'fa.session'
local misc = A.require 'fa.misc'
local gui_main = A.require 'fa.gui.main'
local gui_config = A.require 'fa.gui.config'
local gui_minimap = A.require 'fa.gui.minimap'

-- Events --

--[[
  Notes:
  - GlobalStrings.lua is Blizzard's own code for Lua string constants
--]]

do
  local find = string.find
  local isInGroup = util.isInGroup
  local extendedStringToMoney = util.extendedStringToMoney
  
  --GlobalStrings.lua: YOU_LOOT_MONEY = "You loot %s"
  -- e.g. "You loot 1 Silver, 10 Copper"
  local PATTERN_MONEY_LOOT_YOU = "^You loot (.+)"
  --GlobalStrings.lua: LOOT_MONEY_SPLIT = "Your share of the loot is %s."
  -- e.g. "Your share of the loot is 2 Silver, 21 Copper."
  local PATTERN_MONEY_LOOT_SPLIT = "^Your share of the loot is (.+)%.$"
  
  function A:CHAT_MSG_MONEY(msg)
    --Money loot while solo obtained reliably from LOOT_OPENED/LOOT_SLOT_CLEARED 
    --events.
    --These chat messages are checked only in groups.
    if not isInGroup() then return end
    
    local money_string    
    --Shift-click money loot in a group.
    _, _, money_string = find(msg, PATTERN_MONEY_LOOT_YOU)
    if not money_string then
      --Shared money loot in a group.
      _, _, money_string = find(msg, PATTERN_MONEY_LOOT_SPLIT)
      if not money_string then return end
    end

    local value = extendedStringToMoney(money_string)
    if value and value > 0 then
      session.lootMoney(value, L["shared"])
      A:guiUpdate()
    else
      A.warn("Money loot message but no value found. Original message: %s",
        msg)
    end
  end
end

do
  local find = string.find
  local makeStoreToken = util.makeStoreToken
  local parseItemLink = util.parseItemLink
  
  --GlobalStrings.lua: LOOT_ITEM_SELF = "You receive loot: %s."
  -- e.g. "You receive loot: [Heavy Leather]."
  --GlobalStrings.lua: LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
  -- e.g. "You receive loot: [Heavy Leather]x3."
  local PATTERN_ITEM_LOOT_SELF = "^You receive loot: (.+)%.$"
  local PATTERN_ITEM_LOOT_SELF_COUNT = "x(%d+)$"
  --GlobalStrings.lua: LOOT_ROLL_WON = "%s won: %s|Hitem:%d:%d:%d:%d|h[%s]|h%s"
  -- e.g. "You won: [Heavy Leather]"
  local PATTERN_ITEM_LOOT_WON = "^You won: (.+)"
  
  function A:CHAT_MSG_LOOT(msg)
    local loot_string
    _, _, loot_string = find(msg, PATTERN_ITEM_LOOT_SELF)
    if not loot_string then 
      _, _, loot_string = find(msg, PATTERN_ITEM_LOOT_WON)
      if not loot_string then return end
    end
    
    local item_link, _, id, code = parseItemLink(loot_string)
    local _, _, count = find(loot_string, PATTERN_ITEM_LOOT_SELF_COUNT)
    count = count and tonumber(count) or 1
    
    if code then      
      local token = makeStoreToken(code)
      
      if A:isEnabled() and filter.itemMatchQuality(id) then
        local value = pricing.value(token)
        
        if value and value > 0 then
          A:print(format("%dx %s = %s", count, item_link, 
            util.formatMoneyFull(count * value)))
        else
          A:print(format("%dx %s", count, item_link))
        end
      end
      
      session.lootItem(token, count, id)
      A:guiUpdate()
    else
      A.warn("Item loot message but no item code found. Original message: %s",
        msg)
    end
  end
end

do
  local find = string.find
  local isInGroup = util.isInGroup
  local extendedStringToMoney = util.extendedStringToMoney
  
  local money_loot_slot, money_loot_amount
  
  function A:LOOT_OPENED()
    --These events are checked only while solo.
    if isInGroup() then return end
    
    local count = GetNumLootItems()
    if count < 1 then return end
    
    for slot=1,count do
      local _, name, quantity = GetLootSlotInfo(slot)
      if quantity and quantity == 0 then
        --Slot with quantity 0 should be coin info
        local value = extendedStringToMoney(name)
        if value and value > 0 then
          money_loot_slot = slot
          money_loot_amount = value
          --Leave because there should only be a single coin slot
          return
        end
      end
    end
  end
  
  function A:LOOT_SLOT_CLEARED(slot)
    if not money_loot_slot then return end
    if not slot or slot ~= money_loot_slot then return end

    if money_loot_amount then
      session.lootMoney(money_loot_amount, L["solo"])
      money_loot_slot = nil
      money_loot_amount = nil
      
      A:guiUpdate()
    end
  end
  
  function A:LOOT_CLOSED()
    money_loot_slot = nil
    money_loot_amount = nil
  end
end

function A:guiUpdate()
  gui_main.update()
  gui_config.update()
  gui_minimap.update()
end

-- Loading --

local frame = CreateFrame("Frame")
A.eventframe = frame

-- Fires when an addon and its saved variables are loaded
frame:RegisterEvent("ADDON_LOADED")
-- Fires when receiving notice that the player or a member of the player’s 
-- group has looted an item.
frame:RegisterEvent("CHAT_MSG_LOOT")
-- Fires when the player receives money as loot
frame:RegisterEvent("CHAT_MSG_MONEY")
-- Fires when the player begins interaction with a lootable corpse or object
frame:RegisterEvent("LOOT_OPENED")
-- Fires when the contents of a loot slot are removed
frame:RegisterEvent("LOOT_SLOT_CLEARED")
-- Fires when the player ends interaction with a lootable corpse or object
frame:RegisterEvent("LOOT_CLOSED")

frame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == A.name then
    A.is_loaded = true
    A.loaded_name = A.name
    A.setCharConfigDefaults()
    filter.populateItemType()
    gui_minimap.update()
  else
    local event_method = A[event]
    if event_method then
      event_method(A, arg1, arg2, arg3, arg4, arg5)
    end
  end
end)
