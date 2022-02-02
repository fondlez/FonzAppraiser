local A = FonzAppraiser

A.module 'fa.value.auctioneer'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

local GetHomeKey
local GetAuctionPriceItem
local GetAuctionPrices
local auction_key

do
  local addon_warning_already
  
  function getRefs()
    if not IsAddOnLoaded("Auctioneer") or not Auctioneer then
      if not addon_warning_already then
        A.info("No Auctioneer addon found")
        addon_warning_already = true
      end
      return
    end
    
    if not Auctioneer.Util or not Auctioneer.Core then 
      A.info("No known modules of Auctioneer")
      return
    end
    
    GetHomeKey = Auctioneer.Util.GetHomeKey
    GetAuctionPriceItem = Auctioneer.Core.GetAuctionPriceItem
    GetAuctionPrices = Auctioneer.Core.GetAuctionPrices
    
    if not (GetHomeKey and GetAuctionPriceItem and GetAuctionPrices) then
      A.info("No known functions of Auctioneer")
      return
    end
    
    if not auction_key then
      auction_key = GetHomeKey()
    end
    
    return true
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
  local floor = math.floor

  function M.minPrice(code)
    if not getRefs() then return end
    local ok
    
    local item_key = codeToKey(code)
    
    local price_item
    ok, price_item = pcall(GetAuctionPriceItem, item_key, auction_key)
    if not ok then
      A.info("Auctioneer.Core.GetAuctionPriceItem() call failed")
      return
    end
    
    local ok, a_count, 
      min_count, min_price,
      bid_count, bid_price, 
      buy_count, buy_price = pcall(GetAuctionPrices, price_item.data)
    if not ok then
      A.info("Auctioneer.Core.GetAuctionPrices() call failed")
      return
    end
      
    if a_count > 0 and min_price and min_count > 0 then
      return floor(min_price/min_count)
    end
  end

  function M.buyout(code)
    if not getRefs() then return end
    local ok
    
    local item_key = codeToKey(code)
    
    local price_item
    ok, price_item = pcall(GetAuctionPriceItem, item_key, auction_key)
    if not ok then
      A.info("Auctioneer.Core.GetAuctionPriceItem() call failed")
      return
    end
    
    local ok, a_count, 
      min_count, min_price,
      bid_count, bid_price, 
      buy_count, buy_price = pcall(GetAuctionPrices, price_item.data)
    if not ok then
      A.info("Auctioneer.Core.GetAuctionPrices() call failed")
      return
    end
      
    if a_count > 0 and buy_price and buy_count > 0 then
      return floor(buy_price/buy_count)
    end
  end
end

pricing.addSystem(L["BO.AUC"], L["Auctioneer: buyout"], buyout)
pricing.addSystem(L["MI.AUC"], L["Auctioneer: min"], minPrice)
