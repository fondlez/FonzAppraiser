local A = FonzAppraiser
local L = A.locale

local client = A.require 'util.client'
-- Little point adding an Auctionator option at this time for vanilla
-- since there is no powerful or widely-used version of the addon.
if not client.is_tbc_or_more then return end

A.module 'fa.value.auctionator'

local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

local CalcDisenchantPrice
local GetAuctionPrice
local GetMeanPrice

do
  local addon_warning_already
  
  function getRefs()
    if not IsAddOnLoaded("Auctionator") then
      if not addon_warning_already then
        A.info("No Auctionator addon found")
        addon_warning_already = true
      end
      
      return false
    end
    
    -- Atr_GetMeanPrice is an optional feature in one version of the addon
    if not (Atr_GetAuctionPrice and Atr_CalcDisenchantPrice) then
      A.warn("No known functions of Auctionator")
      return
    end  
    
    CalcDisenchantPrice = Atr_CalcDisenchantPrice
    GetAuctionPrice = Atr_GetAuctionPrice
    GetMeanPrice = Atr_GetMeanPrice
    
    return true
  end
end

do
  local makeItemLink = util.makeItemLink
  
  function disenchant(code)
    if not CalcDisenchantPrice then
      if not getRefs() then return end
    end
    
    local item_string = format("item:%s", code)
    
    local item_link, 
    name, item_string, rarity,
    level, item_type, item_subtype,
    stack, item_invtype, texture, ilevel = makeItemLink(item_string)
    
    local ok, price = pcall(CalcDisenchantPrice, item_type, rarity, ilevel)
    if not ok then
      A.warn("Atr_CalcDisenchantPrice() call failed")
      return
    end
    
    return price
  end
  
  function auctionMedian(code)
    if not GetMeanPrice then
      if not getRefs() then return end
    end
    
    -- Optional feature in one version of the Auctionator addon
    if GetMeanPrice then
      local item_string = format("item:%s", code)
      
      local item_link, name = makeItemLink(item_string)
      
      local ok, price = pcall(GetMeanPrice, name)
      if not ok then
        A.warn("Atr_GetMeanPrice() call failed")
        return
      end
      
      return price
    end
  end
  
  function auction(code)
    if not GetAuctionPrice then
      if not getRefs() then return end
    end
    
    local item_string = format("item:%s", code)
    
    local item_link, name = makeItemLink(item_string)
    
    local ok, price = pcall(GetAuctionPrice, name)
    if not ok then
      A.warn("Atr_GetAuctionPrice() call failed")
      return
    end
    
    return price
  end
end

pricing.addSystem("A.AUA", L["Auctionator: auction"], auction)
pricing.addSystem("AM.AUA", L["Auctionator: auction median"], auctionMedian)
pricing.addSystem("DE.AUA", L["Auctionator: disenchant"], disenchant)
