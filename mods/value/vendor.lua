local A = FonzAppraiser

A.module 'fa.value.vendor'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local vendorValue = AceLibrary("LibVendorValue-1.0")

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

pricing.addSystem(L["VENDOR"], L["Vendor"], value)