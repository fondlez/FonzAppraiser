local A = FonzAppraiser
local L = A.locale

A.module 'fa.value.aux'

local client = A.require 'util.client'
local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

do
  local addon_warning_already
  
  function getRefs()
    if not IsAddOnLoaded("aux-addon") then
      if not addon_warning_already then
        A.info("No aux-addon detected")
        addon_warning_already = true
      end
      
      return false
    end
    
    return true
  end
end

do
  local parseItemCode = util.parseItemCode
  local makeItemLink = util.makeItemLink
  
  function codeToKey(code)
    local item_id, _, suffix_id = parseItemCode(code)
    return item_id and suffix_id and item_id .. ":" .. suffix_id
  end
  
  function codeToInfo(code)
    local item_string = format("item:%s", code)
    
    local item_link, 
    name, item_string, rarity,
    level, item_type, item_subtype,
    stack, item_invtype, texture, ilevel = makeItemLink(item_string)
    
    if client.is_tbc then
      return item_invtype, rarity, ilevel
    else
      return item_invtype, rarity, level
    end
  end
end

function historyValue(code)
  if not getRefs() then return end
  local ok
  
  local history
  ok, history = pcall(require, "aux.core.history")
  if not ok or not history then 
    A.warn("Error loading aux.core.history module")
    return
  end
  
  local item_key = codeToKey(code)
  
  local value
  ok, value = pcall(history.value, item_key)
  if not ok then
    A.warn("aux.core.history - history.value() call failed")
    return
  end
  
  return value
end

function historyMarketValue(code)
  if not getRefs() then return end
  local ok
  
  local history
  ok, history = pcall(require, "aux.core.history")
  if not ok or not history then 
    A.warn("Error loading aux.core.history module")
    return
  end
  
  local item_key = codeToKey(code)
  
  local value
  ok, value = pcall(history.market_value, item_key)
  if not ok then
    A.warn("aux.core.history - history.market_value() call failed")
    return
  end
  
  return value
end

function disenchantValue(code)
  if not getRefs() then return end
  local ok
  
  local disenchant
  ok, disenchant = pcall(require, "aux.core.disenchant")
  if not ok or not disenchant then 
    A.warn("Error loading aux.core.disenchant module")
    return
  end
  
  local slot, rarity, level_or_ilevel = codeToInfo(code)
  
  local value
  ok, value = pcall(disenchant.value, slot, rarity, level_or_ilevel)
  if not ok then
    A.warn("aux.core.history - disenchant.value() call failed")
    return
  end

  return value
end

pricing.addSystem("TV.AUX", L["aux-addon: tooltip value"], historyValue)
pricing.addSystem("TD.AUX", L["aux-addon: tooltip daily"], historyMarketValue)
pricing.addSystem("DE.AUX", L["aux-addon: disenchant value"], disenchantValue)
