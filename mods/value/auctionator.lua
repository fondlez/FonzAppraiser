local A = FonzAppraiser
local L = A.locale

A.module 'fa.value.auctionator'

local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

local GetAuctionPrice
local CalcDisenchantPrice

do
  local addon_warning_already
  
  function getRefs()
    if not IsAddOnLoaded("Auctionator") then
      if not addon_warning_already then
        A.info("No Auctionator addon found")
        addon_warning_already = true
      end
      return
    end
    
    GetAuctionPrice = Atr_GetAuctionPrice
    CalcDisenchantPrice = Atr_CalcDisenchantPrice
    
    if not (GetAuctionPrice and CalcDisenchantPrice) then
      A.info("No known functions of Auctionator")
      return
    end  
    
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
    
    local ok, disenchant_price = pcall(CalcDisenchantPrice, item_type, rarity, 
      ilevel)
    if not ok then
      A.info("Atr_CalcDisenchantPrice() call failed")
      return
    end
    
    return disenchant_price
  end

  function auction(code)
    if not GetAuctionPrice then
      if not getRefs() then return end
    end
    
    local item_string = format("item:%s", code)
    
    local item_link, name = makeItemLink(item_string)
    
    local ok, auction_price = pcall(GetAuctionPrice, name)
    if not ok then
      A.info("Atr_GetAuctionPrice() call failed")
      return
    end
    
    return auction_price
  end
end

pricing.addSystem("A.AUA", L["Auctionator: auction"], auction)
pricing.addSystem("DE.AUA", L["Auctionator: disenchant"], disenchant)
