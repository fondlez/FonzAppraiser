local A = FonzAppraiser

A.module 'fa.filter'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local babble_zone = AceLibrary("Babble-Zone-2.2")

local util = A.requires(
  'util.string',
  'util.time',
  'util.money',
  'util.item',
  'util.chat'
)

local session = A.require 'fa.session'
local misc = A.require 'fa.misc'
local gui_main = A.require 'fa.gui.main'

--[[
  ITEM_QUALITY0_DESC = "Poor";
  ITEM_QUALITY1_DESC = "Common";
  ITEM_QUALITY2_DESC = "Uncommon";
  ITEM_QUALITY3_DESC = "Rare";
  ITEM_QUALITY4_DESC = "Epic";
  ITEM_QUALITY5_DESC = "Legendary";
  ITEM_QUALITY6_DESC = "Artifact";
  Source: WoW GlobalStrings
--]]
local ITEM_RARITY = {
  [ITEM_QUALITY0_DESC] = 0,
  [ITEM_QUALITY1_DESC] = 1,
  [ITEM_QUALITY2_DESC] = 2,
  [ITEM_QUALITY3_DESC] = 3,
  [ITEM_QUALITY4_DESC] = 4,
  [ITEM_QUALITY5_DESC] = 5,
  [ITEM_QUALITY6_DESC] = 6,
  [0] = ITEM_QUALITY0_DESC,
  [1] = ITEM_QUALITY1_DESC,
  [2] = ITEM_QUALITY2_DESC,
  [3] = ITEM_QUALITY3_DESC,
  [4] = ITEM_QUALITY4_DESC,
  [5] = ITEM_QUALITY5_DESC,
  [6] = ITEM_QUALITY6_DESC,
}
M.ITEM_RARITY = ITEM_RARITY
local CREATURE_LEVEL_MAX = 63
local ITEM_TYPE = {}
local ITEM_SUBTYPE = {}
local ITEM_INVTYPE = {}
local ZONES = {}
M.ZONES = ZONES

local defaults = {
  quality = ITEM_RARITY[0],
}
A.registerCharConfigDefaults("fa.filter", defaults)

local filter_check = {
  ["id"]=function(arg)
    local n = tonumber(arg)
    return n and n > 0 and n
  end,
  ["name"]=function(arg)
    local patterns = {
      [[^(%w["'%w%s%:%(%)%!%?]*)$]],
      [[^%[(%w["'%w%s%:%(%)%!%?]*)%]$]],
    }
    local name
    for i,v in ipairs(patterns) do
      _, _, name = string.find(arg, v)
      if name then return name end
    end
  end,
  ["rarity"]=function(arg)
    local n = tonumber(arg)
    if n and ITEM_RARITY[n] then return n end
    local text = util.uniqueKeySearch(ITEM_RARITY, arg, util.strStartsWith)
    return text and ITEM_RARITY[text]
  end, 
  ["quality"]=function(arg)
    local n = tonumber(arg)
    if n and ITEM_RARITY[n] then return n end
    local text = util.uniqueKeySearch(ITEM_RARITY, arg, util.strStartsWith)
    return text and ITEM_RARITY[text]
  end,
  ["level"]=function(arg)
    arg = tonumber(arg)
    return arg and arg >=0 and arg <= CREATURE_LEVEL_MAX and arg
  end, 
  ["lmin"]=function(arg)
    arg = tonumber(arg)
    return arg and arg >=0 and arg <= CREATURE_LEVEL_MAX and arg
  end, 
  ["lmax"]=function(arg)
    arg = tonumber(arg)
    return arg and arg >=0 and arg <= CREATURE_LEVEL_MAX and arg
  end,
  ["type"]=function(arg)
    return ITEM_TYPE[arg] and arg
      or util.keySearch(ITEM_TYPE, arg) and arg
  end,
  ["subtype"]=function(arg)
    return ITEM_SUBTYPE[arg] and arg
      or util.keySearch(ITEM_SUBTYPE, arg) and arg
  end,
  ["slot"]=function(arg)
    return ITEM_INVTYPE[arg] and arg 
      or util.uniqueKeySearch(ITEM_INVTYPE, arg, util.strStartsWith)
  end,
  ["count"]=function(arg)
    arg = tonumber(arg)
    return arg and arg > 0 and arg
  end,
  ["value"]=function(arg)
    return util.stringToMoney(arg)
  end,
  ["zone"]=function(arg)
    return ZONES[arg]
      or util.uniqueKeySearch(ZONES, arg, util.strStartsWith)
  end,
  ["session"]=function(arg)
    arg = tonumber(arg)
    return arg and session.getSession(arg) and arg
  end,
  ["from"]=function(arg)
    return util.parseIso8601(arg, true)
  end,
  ["to"]=function(arg)
    return util.parseIso8601(arg, true)
  end,
  ["since"]=function(arg)
    local n = util.parseDuration(arg, true)
    return n and util.diffTime(time(), n, true)
  end,
  ["until"]=function(arg)
    local n = util.parseDuration(arg, true)
    return n and util.diffTime(time(), n, true)
  end,
  ["group"]=function(arg)
    return isFilterGroup(arg)
  end,
}

do
  local find = string.find
  
  function seq(a, b)
    return a and b and a == b
  end
  
  function lfind(a, b)
    return a and b and find(strlower(a), strlower(b))
  end
  
  function eq(a, b)
    return a and b and tonumber(a) == tonumber(b)
  end
  
  function leq(a, b)
    return a and b and tonumber(a) <= tonumber(b)
  end
  
  function geq(a, b)
    return a and b and tonumber(a) >= tonumber(b)
  end
end

local filter_search = {
  ["id"]=function(item, filter)
    return eq(item, filter)
  end,
  ["item_link"]=function(item, filter)
    return seq(item, filter)
  end,
  ["name"]=function(item, filter)
    return lfind(item, filter)
  end,
  ["rarity"]=function(item, filter)
    return eq(item, filter)
  end,
  ["quality"]=function(item, filter)
    return geq(item, filter)
  end,
  ["level"]=function(item, filter)
    return eq(item, filter)
  end,
  ["lmin"]=function(item, filter)
    return geq(item, filter)
  end,
  ["lmax"]=function(item, filter)
    return leq(item, filter)
  end,
  ["type"]=function(item, filter)
    return lfind(item, filter)
  end,
  ["subtype"]=function(item, filter)
    return lfind(item, filter)
  end,
  ["slot"]=function(item, filter)
    return seq(item, filter)
  end,
  ["count"]=function(item, filter)
    return geq(item, filter)
  end,
  ["value"]=function(item, filter)
    return geq(item, filter)
  end,
  ["zone"]=function(item, filter)
    return seq(item, filter)
  end,
  ["session"]=function(item, filter)
    return eq(item, filter)
  end,
  ["from"]=function(item, filter)
    return geq(item, filter)
  end,
  ["to"]=function(item, filter)
    return leq(item, filter)
  end,
  ["since"]=function(item, filter)
    return geq(item, filter)
  end,
  ["until"]=function(item, filter)
    return leq(item, filter)
  end,
}

function M.populateItemType()  
  local classes = { GetAuctionItemClasses() }
  
  local m = getn(classes)
  for i=1,m do
    local item_type = classes[i]
    
    ITEM_TYPE[item_type] = {}
    
    local subclasses = { GetAuctionItemSubClasses(i) }
    local n = getn(subclasses)
    
    for j=1,n do
      local item_subtype = subclasses[j]
      
      ITEM_TYPE[item_type][item_subtype] = true
      ITEM_SUBTYPE[item_subtype] = true
      
      local slots = { GetAuctionInvTypes(i, j) }
      local o = getn(slots)
      
      for k=1,o do
        local item_invtype = slots[k]
        ITEM_INVTYPE[_G[item_invtype]] = true
      end
    end
  end
end

function M.populateZones()
  for base,localized in babble_zone:GetIterator() do
    ZONES[base] = localized
  end
end

function M.qualityAsRarity()
  local db = A.getCharConfig("fa.filter")
  return ITEM_RARITY[db.quality]
end

function M.itemMatchQuality(item)
  if not item then return end
  local _, _, rarity = GetItemInfo(item)
  return rarity and rarity >= qualityAsRarity()
end

--[[
  EBNF syntax for filter strings:
  
  filterstring = filter, { "/", filter } | string | itemLink ;
  filter = keyword, "=", argument ;
  keyword = "item_link" | "name" | "rarity" | "quality" | "level" | "lmin"
    | "lmax" | "type" | "subtype" | "slot" | "count" | "value" | "zone" ;
  string = '"', { all characters - '"' }, '"' 
    | "'", { all characters - "'" }, "'"
    | '[', { all characters - ('[', ']') }, ']'
  argument = { all characters - ( '=' | '/' ) } ;
  all characters = ? all visible characters ? ;
  itemLink = ? WoW itemLink ? ;

  e.g. 
  type=recipe/subtype=alchemy/rarity=uncommon
  - matches all items that are green (uncommon) alchemy profession recipes

  lmin=51/lmax=60/rarity=rare
  - matches all items of required level 51 to 60 that are blue (rare) 
  
  Blizzard API GetItemInfo(item)
  Returns:
  - itemName, itemLink, itemQuality, 
  - itemMinLevel, itemType, itemSubType
  - itemStackCount, itemEquipLoc, itemTexture
--]]
do
  local trim, find, split = util.strtrim, string.find, util.strsplit
  local parseItemLink = util.parseItemLink
  local startsWith, uniqueKeySearch = util.strStartsWith, util.uniqueKeySearch
  
  local FILTER_SYNTAX = "^([^=]+)=([^=]+)$"
  
  function M.makeFilter(filter_string)
    if not filter_string or type(filter_string) ~= "string" then return end
    
    local filters = {}
    
    filter_string = trim(filter_string)
    
    -- Match itemLink  
    local item_link

    item_link = parseItemLink(filter_string)
    if item_link then
      filters.item_link = item_link
      return filters
    end
    
    -- Match only item name
    local name = filter_check["name"](filter_string)
    if name then
      filters.name = name
      return filters
    end
    
    -- Match keyword=argument strings
    local possible_filters = { split("/", filter_string) }
    local keyword, argument
    
    for i, v in ipairs(possible_filters) do
      local possible_filter = trim(v)
      _, _, keyword, argument = find(possible_filter, FILTER_SYNTAX)
      if not keyword then
        keyword = "name"
        argument = possible_filter
      else
        local expanded = uniqueKeySearch(filter_check, keyword, startsWith)
        if not expanded then
          local err = {
            type = L["Unknown keyword"],
            data = { keyword = keyword }
          }
          return nil, err
        end
        keyword = expanded
      end
      local check_func = filter_check[keyword]
      local normalized = check_func(argument)
      if not normalized then
        local err = {
          type = L["Invalid argument"],
          data = { keyword = keyword, argument = argument }
        }
        return nil, err
      end
      if keyword ~= "group" and not filters[keyword] then
        filters[keyword] = normalized
      else
        if not filters["group"] then
          filters["group"] = {}
        end
        tinsert(filters["group"], normalized)
      end
    end
    return filters
  end
end

function M.searchByFilter(filter_keyword, item_property, filter_argument)
  local compare = filter_search[filter_keyword]
  return compare(item_property, filter_argument)
end

-- MODULE OPTIONS --

if not A.options then
  A.options = {
    type = "group",
    args = {},
  }
end

do
  local function normalize(msg)
    local n = tonumber(msg)
    if n and n >= 0 and n <= 4 then
      return ITEM_RARITY[n]
    end
    if not n and msg then
      return util.uniqueKeySearch(ITEM_RARITY, msg, util.strStartsWith)
    end
  end
  
  local function check(msg)
    return normalize(msg)
  end
  
  A.options.args["Quality"] = {
    type = "text",
    name = L["Item Quality"],
    desc = L["Filter item lists by minimum rarity"],
    get = function() 
      local db = A.getCharConfig("fa.filter")
      return db.quality
    end,
    set = function(msg) 
      local db = A.getCharConfig("fa.filter")
      db.quality = normalize(msg) 
      gui_main.update()
    end,
    usage = L["Poor | Uncommon | Common | Rare | Epic | <number:0-4>"],
    validate = check,
  }
end
