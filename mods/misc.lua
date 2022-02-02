local A = FonzAppraiser

A.module 'fa.misc'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.item',
  'util.bag'
)

local pricing = A.require 'fa.value.pricing'

function M.bagValue(reverseSort)
  local sort = table.sort
  local format = string.format
  local parseItemLink = util.parseItemLink
  local isSoulbound = util.isSoulbound
  local pricingValue = pricing.value
  
  local total = 0
  local items = {}
  
  local name, id, code, count
	for b = 0,4 do
		for s = 1,GetContainerNumSlots(b) do
      local item_link = GetContainerItemLink(b, s)
      local not_soulbound = not isSoulbound(b, s)
      if item_link and not_soulbound then
        _, name, id, code = parseItemLink(item_link)
        _, count = GetContainerItemInfo(b, s)
        local value = pricingValue(code)
        if value and value > 0 then
          value = value * count
          --Unique by item and aggregate count and aggregate value
          items[item_link] = {
            name=name,
            id=id,
            code=code,
            count=items[item_link] and (items[item_link].count + count) 
              or count,
            value=items[item_link] and (items[item_link].value + value) 
              or value,
          }
          total = total + value
        end
      end
    end
  end
  
  local sort_array = {}
  for k, v in pairs(items) do
    tinsert(sort_array, { item_link=k, 
      name=v.name, id=v.id, code=v.code,
      count=v.count, value=v.value })
  end
  
  if not reverseSort then
    sort(sort_array, function(a, b)
      if a.value ~= b.value then
        return a.value < b.value
      elseif a.count ~= b.count then
        return a.count > b.count
      elseif a.name ~= b.name then
        return a.name < b.name
      else
        return a.code < b.code
      end
    end)
  else
    sort(sort_array, function(a, b)
      if a.value ~= b.value then
        return a.value > b.value
      elseif a.count ~= b.count then
        return a.count > b.count
      elseif a.name ~= b.name then
        return a.name < b.name
      else
        return a.code < b.code
      end
    end)  
  end
  
  for _, v in pairs(sort_array) do
    A:Print(format("%dx %s = %s", v.count, v.item_link, 
      abacus:FormatMoneyFull(v.value, true)))
  end
  
  A:Print(format(L["Total: %s"], abacus:FormatMoneyFull(total, true)))
end