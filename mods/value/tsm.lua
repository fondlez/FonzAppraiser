local A = FonzAppraiser
local L = A.locale

local client = A.require 'util.client'
-- TSM addon only exists for wotlk or later
if not client.is_wotlk_or_more then return end

A.module 'fa.value.tsm'

local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

do
  local addon_warning_already
  
  function getRefs()
    if not IsAddOnLoaded("TradeSkillMaster") then
      if not addon_warning_already then
        A.info("No TradeSkillMaster addon found")
        addon_warning_already = true
      end
      
      return false
    end
    
    if not TSMAPI or not TSMAPI.GetItemValue then
      A.warn("No known functions of TradeSkillMaster")
      return
    end  
    
    return true
  end
end

do
  function M.marketValue(code)
    if not getRefs() then return end
    
    local item_string = format("item:%s", code)
    
    local ok, price = pcall(TSMAPI.GetItemValue, TSMAPI, item_string,
      "DBMarket")
    if not ok then
      A.warn("TSMAPI:GetItemValue(<item>, 'DBMarket') call failed")
      return
    end
    
    return price
  end
  
  function M.minBuyout(code)
    if not getRefs() then return end
    
    local item_string = format("item:%s", code)
    
    local ok, price = pcall(TSMAPI.GetItemValue, TSMAPI, item_string,
      "DBMinBuyout")
    if not ok then
      A.warn("TSMAPI:GetItemValue(<item>, 'DBMinBuyout') call failed")
      return
    end
    
    return price
  end
  
  function M.disenchantValue(code)
    if not getRefs() then return end
    
    local item_string = format("item:%s", code)
    
    local ok, price = pcall(TSMAPI.GetItemValue, TSMAPI, item_string,
      "Disenchant")
    if not ok then
      A.warn("TSMAPI:GetItemValue(<item>, 'Disenchant') call failed")
      return
    end
    
    return price
  end
end

pricing.addSystem("MV.TSM", L["TSM: market value"], marketValue)
pricing.addSystem("MB.TSM", L["TSM: minimum buyout"], minBuyout)
pricing.addSystem("DV.TSM", L["TSM: disenchant value"], disenchantValue)