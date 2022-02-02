local A = FonzAppraiser

A.module 'util.money'

local COPPER_TO_SILVER = 100
local SILVER_TO_GOLD = 100
local COPPER_TO_GOLD = 10000
local DENOMINATIONS = { 1, COPPER_TO_SILVER, COPPER_TO_GOLD }

function M.unitMoney(copper_value)
  local gold = floor(copper_value/COPPER_TO_GOLD)
  local silver = floor(mod(copper_value, COPPER_TO_GOLD)/COPPER_TO_SILVER)
  local copper = mod(copper_value, COPPER_TO_SILVER)
  
  return gold, silver, copper
end

function M.baseMoney(gold, silver, copper)
  return (gold or 0) * COPPER_TO_GOLD 
    + (silver or 0) * COPPER_TO_SILVER
    + (copper or 0)
end

do
  --Source: library "Abacus-2.0" constant references
  ---[[
  local COPPER_ABBR = strlower(strsub(COPPER, 1, 1))
  local SILVER_ABBR = strlower(strsub(SILVER, 1, 1))
  local GOLD_ABBR = strlower(strsub(GOLD, 1, 1))
  if (strbyte(COPPER_ABBR) or 128) > 127 then
    -- non-western
    COPPER_ABBR = COPPER
    SILVER_ABBR = SILVER
    GOLD_ABBR = GOLD
  end
  --]]
  
  local _, _, DECIMAL_SEPARATOR = strfind(format("%.1f", 1/3), "(%D+)")
  
  function M.stringToMoney(money_string)
    local _, _, num = strfind(money_string, "^%s*(%d+)%s*$")
    if num then return tonumber(num) end
    
    local pattern = format("^%%s*(%%d+%s%%d+)%%s*$", 
      gsub(DECIMAL_SEPARATOR, "(%p)", "%%%1", 1))
    _, _, num = strfind(money_string, pattern)
    if num then return floor(tonumber(num)*COPPER_TO_GOLD) end
    
    local units = {0, 0, 0}
    local found = false
    for i,v in ipairs({COPPER_ABBR, SILVER_ABBR, GOLD_ABBR}) do
      local pattern = format("(%%d+)%%s*%s", v)
      gsub(money_string, pattern, function(num_string)
        units[i] = units[i] + tonumber(num_string)
        found = true
      end, 1)
    end
    if not found then return end
    
    local value = 0
    for i = 1,3 do
      value = value + units[i] * DENOMINATIONS[i]
    end
    return value
  end
end

function M.extendedStringToMoney(money_string)
  local units = {}
  gsub(money_string, "%d+", function(num_string)
    tinsert(units, tonumber(num_string))
  end)
  local n = getn(units); if n < 1 then return end
  
  local value = 0
  for i = n, 1, -1 do
    value = value + units[i] * DENOMINATIONS[n - i + 1]
  end
  return value
end
