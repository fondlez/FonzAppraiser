local A = FonzAppraiser
local L = A.locale

A.module 'fa.value.pricing'

local util = A.require 'util.item'

local defaults = {
  pricing = "VENDOR"
}
A.registerCharConfigDefaults("fa.value.pricing", defaults)

local systems = {}
M.systems = systems

function M.addSystem(id, description, func)
  tinsert(systems, { id=id, description=description, func=func })
  systems[id] = getn(systems)
end

function M.getSystemDescription(id)
  local index = systems[id]
  local data = systems[index]
  return data and data.description
end

do
  local ITEM_RARITY_POOR = 0
  local ITEM_RARITY_COMMON = 1
  local ITEM_RARITY_UNCOMMON = 2
  local ITEM_RARITY_RARE = 3
  
  local gsub = string.gsub
  
  local function getItemId(code)
    return gsub(code, "^(%d+).*", "%1")
  end
  
  local GetItemInfo = _G.GetItemInfo
  local threshold = ITEM_RARITY_POOR
  local cache = {}
  
  -- Check if an item is worth valuing beyond default price (vendor)
  -- - internally checks by minimum rarity
  -- - TODO(@fondlez): add UI option for minimum rarity for market value
  function hasMarketValue(code)
    local id = getItemId(code)    
    local rarity = cache[id]
    local _
    
    if not rarity then
      _, _, rarity = GetItemInfo(id)
      if not rarity then 
        A.debug("[PRICING] No rarity for this item. Code: '%s'", tostring(code))
        return true -- be conservative, no filter on lack of information
      end
      
      cache[id] = rarity
    end
    
    return rarity > threshold
  end
end

do
  local makeItemCode = util.makeItemCode
  
  function M.value(token)
    local db = A.getCharConfig("fa.value.pricing")
    
    local code = makeItemCode(token)
    if not code then return 0, NONE end
    
    if hasMarketValue(code) then
      local index = systems[db.pricing]
      local value = systems[index].func(code)
      if value and value > 0 then
        return value, db.pricing
      end
    end
    
    index = systems[defaults.pricing]
    value = systems[index].func(code)
    if value then
      return value, defaults.pricing
    end
    
    A.debug("[PRICING] Unable to value this item. Code: '%s'", tostring(code))
    return 0, NONE
  end
end