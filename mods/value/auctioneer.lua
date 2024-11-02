local A = FonzAppraiser
local L = A.locale

A.module 'fa.value.auctioneer'

local client = A.require 'util.client'
local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

local GetAuctionKey
local GetItemHistoricalMedianBuyout
local GetSuggestedResale

local GetHomeKey
local GetAuctionPriceItem
local GetAuctionPrices

local auction_key

do
  local addon_warning_already
  
  local function addonExists()
    if not IsAddOnLoaded("Auctioneer") or not Auctioneer then
      if not addon_warning_already then
        A.info("No Auctioneer addon found")
        addon_warning_already = true
      end
      
      return false
    end
    
    return true
  end
  
  if client.is_tbc_or_more then
    function getRefs()
      if not addonExists() then return end
      
      if not (Auctioneer.Util and Auctioneer.Statistic) then 
        A.warn("No known modules of Auctioneer")
        return
      end
      
      GetAuctionKey = Auctioneer.Util.GetAuctionKey
      GetItemHistoricalMedianBuyout = 
        Auctioneer.Statistic.GetItemHistoricalMedianBuyout
      GetSuggestedResale = Auctioneer.Statistic.GetSuggestedResale
      
      if not (GetAuctionKey and GetItemHistoricalMedianBuyout
          and GetSuggestedResale) then
        A.warn("No known functions of Auctioneer")
        return
      end
      
      if not auction_key then
        auction_key = GetAuctionKey()
      end
      
      return true
    end
  else
    function getRefs()
      if not addonExists() then return end
      
      if not Auctioneer.Util or not Auctioneer.Core then 
        A.warn("No known modules of Auctioneer")
        return
      end
      
      GetHomeKey = Auctioneer.Util.GetHomeKey
      GetAuctionPriceItem = Auctioneer.Core.GetAuctionPriceItem
      GetAuctionPrices = Auctioneer.Core.GetAuctionPrices
      
      if not (GetHomeKey and GetAuctionPriceItem and GetAuctionPrices) then
        A.warn("No known functions of Auctioneer")
        return
      end
      
      if not auction_key then
        auction_key = GetHomeKey()
      end
      
      return true
    end
  end
end

do
  local parseItemCode = util.parseItemCode
  
  function codeToKey(code)
    local item_id, enchant_id, suffix_id, unique_id = parseItemCode(code)
    local item_key = format("%d:%d:%d", item_id, suffix_id, enchant_id)
    return item_key
  end
end

do
  if client.is_tbc_or_more then
    function M.minPrice(code)
      if not (auction_key and GetSuggestedResale) then
        if not getRefs() then return end
      end
      
      local item_key = codeToKey(code)
      
      local ok, min_price = pcall(GetSuggestedResale, item_key, auction_key, 1)
      if not ok then
        A.warn("Auctioneer.Statistic.GetSuggestedResale() call failed")
        return
      end
      
      return min_price
    end
  else
    function M.minPrice(code)
      if not (auction_key and GetAuctionPriceItem and GetAuctionPrices) then
        if not getRefs() then return end
      end
      
      local item_key = codeToKey(code)
      
      local ok1, price_item = pcall(GetAuctionPriceItem, item_key, auction_key)
      if not ok1 then
        A.warn("Auctioneer.Core.GetAuctionPriceItem() call failed")
        return
      end
      
      local ok2, a_count, min_count, min_price, bid_count, bid_price, buy_count, 
        buy_price = pcall(GetAuctionPrices, price_item.data)
      if not ok2 then
        A.warn("Auctioneer.Core.GetAuctionPrices() call failed")
        return
      end
        
      if a_count > 0 and min_price and min_count > 0 then
        return floor(min_price/min_count)
      end
    end  
  end
  
  if client.is_tbc_or_more then
    function M.buyout(code)
      if not (auction_key and GetItemHistoricalMedianBuyout) then
        if not getRefs() then return end
      end
      
      local item_key = codeToKey(code)
      
      local ok, buyout_price = pcall(GetItemHistoricalMedianBuyout, item_key, 
        auction_key)
      if not ok then
        A.warn(
          "Auctioneer.Statistic.GetItemHistoricalMedianBuyout() call failed")
        return
      end
      
      return buyout_price
    end
  else
    function M.buyout(code)
      if not (auction_key and GetAuctionPriceItem and GetAuctionPrices) then
        if not getRefs() then return end
      end
      
      local item_key = codeToKey(code)
      
      local ok1, price_item = pcall(GetAuctionPriceItem, item_key, auction_key)
      if not ok1 then
        A.warn("Auctioneer.Core.GetAuctionPriceItem() call failed")
        return
      end
      
      local ok2, a_count, 
        min_count, min_price,
        bid_count, bid_price, 
        buy_count, buy_price = pcall(GetAuctionPrices, price_item.data)
      if not ok2 then
        A.warn("Auctioneer.Core.GetAuctionPrices() call failed")
        return
      end
        
      if a_count > 0 and buy_price and buy_count > 0 then
        return floor(buy_price/buy_count)
      end
    end  
  end
end

pricing.addSystem("BO.AUC", L["Auctioneer: buyout"], buyout)
pricing.addSystem("MI.AUC", L["Auctioneer: minimum suggested price"], minPrice)
