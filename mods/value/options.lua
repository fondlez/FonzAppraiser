local A = FonzAppraiser
local L = A.locale

A.module 'fa.value.pricing'

local util = A.requires 'util.string'

if not A.options then
  A.options = {
    type = "group",
    args = {},
  }
end

do
  local function normalize(msg)
    return msg and util.uniqueKeySearch(systems, msg, util.strStartsWith)
  end
  
  local function listSystemIds()
    local ids = {}
    for i,v in ipairs(systems) do
      tinsert(ids, v.id)
    end
    return table.concat(ids, " | ")
  end
  
  A.options.args["Pricing"] = {
    type = "text",
    name = L["Pricing system"],
    desc = L["Pricing system for the value of items"],
    get = function() 
      local db = A.getCharConfig("fa.value.pricing")
      return db.pricing
    end,
    set = function(msg) 
      local db = A.getCharConfig("fa.value.pricing")
      db.pricing = normalize(msg) 
      A:guiUpdate()
    end,
    usage = listSystemIds(),
    validate = normalize,
  }
end