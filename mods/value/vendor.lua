local A = FonzAppraiser
local L = A.locale

A.module 'fa.value.vendor'

local vendorValue = _G[string.gsub("LibVendorValue-2.0", "[^_%w]", "_")]

local util = A.require 'util.item'

local pricing = A.require 'fa.value.pricing'

do
  local parseItemCode = util.parseItemCode

  function M.value(code)
    local id = parseItemCode(code)
    if not id then
      A.warn("[VENDOR] unable to parse item id from code. Code: %s", code)
    end
    return vendorValue(id)
  end
end

pricing.addSystem("VENDOR", L["Vendor"], value)
