local A = FonzAppraiser
local L = A.locale

A.module 'fa.value.vendor'

local vendorValue = _G[string.gsub("LibVendorValue-2.0", "[^_%w]", "_")]

local client = A.require 'util.client'
local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

local compat = client.compatibility
do
  local parseItemCode = util.parseItemCode
  local getItemVendorPrice = util.getItemVendorPrice
  
  if compat.version >= compat.WOTLK then
    function M.value(code)
      local price = getItemVendorPrice(code)
      if not price then
        A.info("[VENDOR] unable to get price for code. Code:'%s'", 
          tostring(code))
      end
      
      return price
    end  
  else
    function M.value(code)
      local id = parseItemCode(code)
      if not id then
        A.info("[VENDOR] unable to parse item id from code. Code: '%s'", 
          tostring(code))
      end
      
      return vendorValue(id)
    end
  end
end

pricing.addSystem("VENDOR", L["Vendor"], value)
