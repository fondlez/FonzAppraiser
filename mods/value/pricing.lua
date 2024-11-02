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
  local makeItemCode = util.makeItemCode
  
  function M.value(token)
    local db = A.getCharConfig("fa.value.pricing")
    
    local code = makeItemCode(token)
    if not code then return 0, NONE end
    
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
    
    A.debug("[PRICING] Unable to value this item. Code: '%s'", tostring(code))
    return 0, NONE
  end
end