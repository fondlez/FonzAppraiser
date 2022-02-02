local A = FonzAppraiser

A.module 'fa.value.pricing'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local defaults = {
  pricing = L["VENDOR"]
}
A.registerCharConfigDefaults("fa.value.pricing", defaults)

local systems = {}
M.systems = systems

function M.addSystem(id, description, func)
  tinsert(systems, { id=id, description=description, func=func })
  systems[id] = getn(systems)
end
 
function M.value(code)
  local db = A.getCharConfig("fa.value.pricing")
  
  local index = systems[db.pricing]
  local value = systems[index].func(code)
  if value and value > 0 then
    return value, db.pricing
  end
  
  index = systems[defaults.pricing]
  value = systems[index].func(code)
  if value then
    return value, defaults.pricing
  end
  
  A.debug("[PRICING] Unable to value this item. Code: %s", code)
  return 0, NONE
end
