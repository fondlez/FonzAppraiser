local A = FonzAppraiser

A.module 'fa'

-- TRANSLATIONS

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

-- LIBRARIES

local tablet  = AceLibrary("Tablet-2.0")
local abacus = AceLibrary("Abacus-2.0")

-- MODULES

local util = A.requires(
  'util.table',
  'util.money',
  'util.item',
  'util.group'
)
local palette = A.require 'fa.palette'
local pricing = A.require 'fa.value.pricing'
local filter = A.require 'fa.filter'
local notice = A.require 'fa.notice'
local session = A.require 'fa.session'
local misc = A.require 'fa.misc'
local gui_main = A.require 'fa.gui.main'
local gui_config = A.require 'fa.gui.config'

--------------------------------------------------------------------------------

-- Settings --

local defaults = {
  enable = false,
  money_correct = true,
}
A.registerCharConfigDefaults("fa", defaults)

if not A.options then
  A.options = {
    type = "group",
    args = {},
  }
end

do
  function A:isEnabled()
    local db = A.getCharConfig("fa")
    return db.enable
  end
  
  function A:ePrint(...)
    if A:isEnabled() then
      A:Print(unpack(arg))
    end
  end

  function toggleEnabled()
    local db = A.getCharConfig("fa")
    db.enable = not db.enable
    gui_config.update()
  end

  function getMoneyCorrect()
    local db = A.getCharConfig("fa")
    return db.money_correct
  end

  function setMoneyCorrect()
    local db = A.getCharConfig("fa")
    db.money_correct = not db.money_correct
  end

  A.options.args["Enable"] = {
    type = "toggle",
    name = L["Enable chat output"],
    desc = L["Toggles whether to show chat output"],
    get = A.isEnabled,
    set = toggleEnabled,
  }

  if A.logging("INFO") then
    A.options.args["MoneyCorrect"] = {
      type = "toggle",
      name = L["Enable money correction"],
      desc = L["Advanced: toggles money gain correction"],
      get = getMoneyCorrect,
      set = setMoneyCorrect,
      guiHidden = true,
    }
  end
end

-- Events --

--[[
  Notes:
  - Variadic arguments in event handlers used throughout for testability
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
  
  function A:CHAT_MSG_MONEY(...)
    --Money loot while solo obtained reliably from LOOT_OPENED/LOOT_SLOT_CLEARED 
    --events.
    --These chat messages are checked only in groups.
    if not isInGroup() then return end
    
    local str = arg[1]
    local money_string
    
    --Shift-click money loot in a group.
    _, _, money_string = find(str, PATTERN_MONEY_LOOT_YOU)
    if not money_string then
      --Shared money loot in a group.
      _, _, money_string = find(str, PATTERN_MONEY_LOOT_SPLIT)
      if not money_string then return end
    end

    local value = extendedStringToMoney(money_string)
    if value and value > 0 then
      session.lootMoney(value, L["shared"])
      self:guiUpdate()
    else
      A.warn("Money loot message but no value found. Original message: %s",
        str)
    end
  end
end

do
  local find = string.find
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
  
  function A:CHAT_MSG_LOOT(...)  
    local str = arg[1]
    local loot_string
    
    _, _, loot_string = find(str, PATTERN_ITEM_LOOT_SELF)
    if not loot_string then 
      _, _, loot_string = find(str, PATTERN_ITEM_LOOT_WON)
      if not loot_string then return end
    end
    
    local item_link, _, id, code = parseItemLink(loot_string)
    local _, _, count = find(loot_string, PATTERN_ITEM_LOOT_SELF_COUNT)
    count = count and tonumber(count) or 1
    
    if code then
      if self:isEnabled() and filter.itemMatchQuality(id) then
        local value = pricing.value(code)
        
        if value and value > 0 then
          self:Print(format("%dx %s = %s", count, item_link, 
            abacus:FormatMoneyFull(count * value)))
        else
          self:Print(format("%dx %s", count, item_link))
        end
      end
      
      session.lootItem(code, count, id)
      self:guiUpdate()
    else
      A.warn("Item loot message but no item code found. Original message: %s",
        str)
    end
  end
end

do
  local find = string.find
  local isInGroup = util.isInGroup
  local extendedStringToMoney = util.extendedStringToMoney
  
  local money_loot_slot, money_loot_amount
  
  function A:LOOT_OPENED(...)
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
  
  function A:LOOT_SLOT_CLEARED(...)
    if not money_loot_slot then return end

    local slot = arg[1]
    if slot ~= money_loot_slot then return end
    
    if money_loot_amount then
      session.lootMoney(money_loot_amount, L["solo"])
      money_loot_slot = nil
      money_loot_amount = nil
      
      self:guiUpdate()
    end
  end
  
  function A:LOOT_CLOSED(...)
    money_loot_slot = nil
    money_loot_amount = nil
  end
end

do
  local find = string.find
  local extendedStringToMoney = util.extendedStringToMoney
  
  --GlobalStrings.lua: ERR_QUEST_REWARD_MONEY_S = "Received %s."
  --GlobalStrings.lua: ERR_QUEST_REWARD_ITEM_S = "Received item: %s."
  local PATTERN_ITEM_OR_MONEY_RECEIVED_FROM_QUEST = "^Received (.+)%.$"
  local PATTERN_ITEM_RECEIVED_FROM_QUEST = "^Received item: .+$"
  
  local quest_money = {}
  M.quest_money = quest_money
  
  function A:CHAT_MSG_SYSTEM(...)
    local str = arg[1]
    
    --Matches both items and money
    local money_or_item
    _, _, money_or_item = find(str, PATTERN_ITEM_OR_MONEY_RECEIVED_FROM_QUEST)
    --Stop if neither found
    if not money_or_item then return end
    
    --Matches items only, and stop if found
    if find(str, PATTERN_ITEM_RECEIVED_FROM_QUEST) then return end

    --Only money left. Check for valid value
    local value = extendedStringToMoney(money_or_item)
    if value and value > 0 then
      tinsert(quest_money, value)
    end
  end
end

do
  local wipe = util.wipe
  
  local session_checksum
  local last_money, last_session_money
  
  --[[
    PLAYER_MONEY appears to fire after other (money) loot events.
    
    It is known that events and system chat messages may occasionally be 
    skipped by the client. This event can be used to track changes to actual 
    money from the API, i.e. GetMoney(), which will always be accurate.
    
    The intention is therefore to track all money gains that are not from
    loot sources. Any extra gain that is more than the session money gain
    is applied as a money correction if the MoneyCorrect option is enabled.
    
    Without the MoneyCorrect option, session money may fall behind actual
    money gained due to missing loot events or system messages.
  --]]
  function A:PLAYER_MONEY()
    --No point continuing if money correction disabled
    if not getMoneyCorrect() then return end
    
    --No current session = reset correction reference
    if not session.isCurrent() then
      last_money = nil
      start_session_money = nil
      return
    end
    
    --Check if anything has changed about sessions and if so reset reference
    local current_checksum = session.getSessionsChecksum()
    if not session_checksum or current_checksum ~= session_checksum then
      last_money = nil
      start_session_money = nil
      session_checksum = current_checksum
    end
    
    --Reference point for actual money
    last_money = last_money or GetMoney()
    local now_money = GetMoney()
    local diff = now_money - last_money
    last_money = now_money
    
    --Reference point for current session money
    last_session_money = last_session_money or session.getCurrentMoney()
    local gain = session.getCurrentMoney() - last_session_money
    last_session_money = session.getCurrentMoney()
    
    --Only care about actual money gains 
    if diff < 1 then return end
    
    --Eliminate possible gains from known non-loot sources
    if InboxFrame and InboxFrame:IsVisible() then return end
    if MerchantFrame and MerchantFrame:IsVisible() then return end
    if TradeFrame and TradeFrame:IsVisible() then return end
    if quest_money and getn(quest_money) > 0 then
      wipe(quest_money)
      return
    end
    
    --[[
      Any gain in actual money more than the gain from known loot sources is
      considered a gain from an unknown loot source.

      This extra gain is applied as a correction to the session money, if the
      MoneyCorrect option is enabled.
    --]]
    local extra_gain = diff - gain
    
    if extra_gain > 0 then
      session.lootMoney(extra_gain, L["correction"])
      last_session_money = last_session_money + extra_gain
      
      A.info("Money gain from unknown source. "
        .. palette.color.red("Session money corrected."))

      self:guiUpdate()
    end
  end
end

-- Loading --

function A:HookEvents()
  -- Fires when receiving notice that the player or a member of the player’s 
  -- group has looted an item.
  self:RegisterEvent("CHAT_MSG_LOOT")
  -- Fires when the player receives money as loot
  self:RegisterEvent("CHAT_MSG_MONEY")
  -- Fires when a system message is received
  self:RegisterEvent("CHAT_MSG_SYSTEM")
  -- Fires when the player begins interaction with a lootable corpse or object
  self:RegisterEvent("LOOT_OPENED")
  -- Fires when the contents of a loot slot are removed
  self:RegisterEvent("LOOT_SLOT_CLEARED")
  -- Fires when the player ends interaction with a lootable corpse or object
  self:RegisterEvent("LOOT_CLOSED")
  -- Fires when the player gains or spends money
  self:RegisterEvent("PLAYER_MONEY")
end

function A:OnEnable()
  self:HookEvents()
end

function A:OnInitialize()
  A.setCharConfigDefaults()
  filter.populateItemType()
  filter.populateZones()
  self:updateIcon()
end

-- Command line --

A:RegisterChatCommand({L["SLASHCMD_SHORT"], L["SLASHCMD_LONG"]}, A.options)

function SlashCmdList.fa_value()
  misc.bagValue()
end
_G.SLASH_fa_value1 = L["SLASHCMD_BAG_VALUE1"]
_G.SLASH_fa_value2 = L["SLASHCMD_BAG_VALUE2"] 

function SlashCmdList.fa_rvalue()
  misc.bagValue(true)
end
_G.SLASH_fa_rvalue1 = L["SLASHCMD_BAG_REVERSE_VALUE1"]
_G.SLASH_fa_rvalue2 = L["SLASHCMD_BAG_REVERSE_VALUE2"]

-- Fubar --

A.hasIcon = A.addon_path .. [[\img\icon]]
A.defaultMinimapPosition = 260
A.defaultPosition = "CENTER"
A.cannotDetachTooltip = true
A.tooltipHiddenWhenEmpty = false
A.hideWithoutStandby = true
A.independentProfile = true
A.OnMenuRequest = A.options
if not FuBar then
  A.OnMenuRequest.args.hide.guiName = L["Hide minimap icon"]
  A.OnMenuRequest.args.hide.desc = L["Hide minimap icon"]
end

function A:OnTextUpdate()
  local total_value = session.getCurrentTotalValue()
  if total_value then
    --Final argument to custom Abacus library creates zero padding digits.
    self:SetText(abacus:FormatMoneyFull(total_value, true, nil, true))
  else
    self:SetText(A.name)
  end
end

do
  local function formatMoney(money)
    --Final argument to custom Abacus library creates zero padding digits.
    return money and abacus:FormatMoneyFull(money, true, nil, true) or "-"
  end
  
  local function formatCount(count)
    local str = count and format("[%s]", palette.color.white(count)) or ""
    return str
  end
  
  function A:OnTooltipUpdate()
    local category = tablet:AddCategory(
      "columns", 2,
      "child_textR", 1,"child_textG", 1, "child_textB", 0,
      "child_text2R", 1, "child_text2G", 1, "child_text2B", 1
    )
    category:AddLine(
      "text", L["Session Value:"],
      "text2", formatMoney(session.getCurrentTotalValue())
    )
    category:AddLine(
      "text", L["Currency:"],
      "text2", formatMoney(session.getCurrentMoney())
    )
    category:AddLine(
      "text", format(L["Items%s:"], formatCount(
        session.getCurrentItemsCount("items"))),
      "text2", formatMoney(session.getCurrentItemsValue())
    )
    category:AddLine(
      "text", format(L["Hot Items%s:"], formatCount(
        session.getCurrentItemsCount("hots"))),
      "text2", formatMoney(session.getCurrentHotsValue())
    )
    if session.isCurrent() then
      local total, target = notice.getTarget()
      local n = tonumber(target)
      if n and n > 0 then
        category:AddLine(
          "text", L["Target:"],
          "text2", formatMoney(n)
        )
        category:AddLine(
          "text", L["Progress:"],
          "text2", format("%d%%", math.min(100, math.floor(total/n * 100)))
        )
      end
    end
  end
end

function A:updateIcon()
  if session.isCurrent() then
    self:SetIcon(A.addon_path .. [[\img\icon]])
  else
    self:SetIcon(A.addon_path .. [[\img\icon_disable]])
  end
end

function A:OnClick()
  A.trace("Fubar - OnClick")
  gui_main.toggleWindow()
end

function A:guiUpdate()
  gui_main.update()
  gui_config.update()
  self:UpdateText()
  self:UpdateTooltip()
  self:updateIcon()
end