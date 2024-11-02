local A = FonzAppraiser
local client = A.require 'util.client'
if not client.is_wotlk then return end

A.module 'util.item'

local util = A.require 'util.string'

local GetItemInfo, GetItemQualityColor = GetItemInfo, GetItemQualityColor
local strgsub, strfind, strformat, strsub = string.gsub, strfind, string.format, 
  strsub

-- Note. The additional field called 'level' in wotlk item links has no
-- value for looted items, so it is sufficient only to parse tbc item codes.
local PATTERN_PARSE_ITEM_CODE_TBC
  = "(%d+):(%d*):(%d*):(%d*):(%d*):(%d*):(%d*):(%d*)"
local PATTERN_PARSE_ITEM_CODE_VANILLA = "(%d+):(%d*):(%d*):(%d*)"
local PATTERN_PARSE_ITEM_ID_FROM_ITEM_CODE = "(%d+)"
local PATTERN_PARSE_ITEM_ID_FROM_ITEM_STRING = "item:(%d+)"
local PATTERN_PARSE_ITEM_LINK = "(|c(%x+)|Hitem:((%d+).-)|h%[(.-)%]|h)"
local PATTERN_PARSE_STORE_TOKEN = PATTERN_PARSE_ITEM_CODE_VANILLA
local PATTERN_FORMAT_MIN_ITEM_CODE = "%d:%d:0:0:0:0:%d:%d"
local PATTERN_FORMAT_STORE_TOKEN = "%d:%d:%d:%d"

local cached_item_values = {}
M.cached_item_values = cached_item_values

function M.makeItemCode(token)
  local found, _, item_id, enchant_id, suffix_id, unique_id 
    = strfind(token, PATTERN_PARSE_STORE_TOKEN)
  if not found then return end
  
  return strformat(PATTERN_FORMAT_MIN_ITEM_CODE, tonumber(item_id), 
    tonumber(enchant_id) or 0, tonumber(suffix_id) or 0, 
    tonumber(unique_id) or 0)
end

function M.parseItemCode(target)
  local found, _, item_id, enchant_id, gem1, gem2, gem3, gem4, suffix_id, 
    unique_id = strfind(target, PATTERN_PARSE_ITEM_CODE_TBC)
  if not found then
    found, _, item_id, enchant_id, suffix_id, unique_id = strfind(target, 
      PATTERN_PARSE_ITEM_CODE_VANILLA)
  end
  if not found then return end

  return tonumber(item_id), tonumber(enchant_id) or 0, tonumber(suffix_id) or 0, 
    tonumber(unique_id) or 0, tonumber(gem1) or 0, tonumber(gem2) or 0, 
    tonumber(gem3) or 0, tonumber(gem4) or 0
end

function M.makeStoreToken(item)
  local item_id, enchant_id, suffix_id, unique_id = parseItemCode(item)
  if not item_id then return end
  
  return strformat(PATTERN_FORMAT_STORE_TOKEN, item_id, enchant_id, 
    suffix_id, unique_id)
end

function M.parseItemLink(target)
  local _, _, item_link, color, code, id, name = strfind(target, 
    PATTERN_PARSE_ITEM_LINK)
  return item_link, name, tonumber(id), code, color
end

function M.makeItemLink(item, max_len)
  --[[
    GetItemInfo(item)
    - item can be id or itemString or itemLink
    - Returns (wotlk:11):
    - itemName, itemString, itemRarity, [tbc: ilevel,]
    - itemMinLevel, itemType, itemSubType
    - itemStackCount, itemInvType, itemTexture,
    - [wotlk: vendorPrice]
  --]]
  local name, item_string, rarity, ilevel,
    minLevel, item_type, item_subtype,
    stack, item_invtype, texture, vendor_price
    = GetItemInfo(item)

  if not item_string then return end
  
  local _, _, item_id = strfind(item_string, 
    PATTERN_PARSE_ITEM_ID_FROM_ITEM_STRING)
  if not item_id then
    A.warn("Unable to parse item id from item string: %s", item_string)
    return
  end
  
  if not cached_item_values[item_id] then
    cached_item_values[item_id] = vendor_price or 0
  end

  local color
  _, _, _, color = GetItemQualityColor(rarity)
  name = not max_len and name or util.strTrunc(name, max_len, "...")
  --Note. itemString is not an item string in wotlk, but a full item link
  --So, substitute the name part with the potentially shortened name above.
  return strgsub(item_string, "%[[^%]]+%]", strformat("[%s]", name)), 
    name, item_string, rarity,
    minLevel, item_type, item_subtype,
    stack, item_invtype, texture, ilevel,
    vendor_price
end

function M.safeItemLink(item)
  if not item then return end
  
  -- Accept item codes, not just item ids, strings or links
  local i1, i2 = strfind(item, PATTERN_PARSE_ITEM_CODE_TBC)
  if not i1 then
    i1, i2 = strfind(item, PATTERN_PARSE_ITEM_CODE_VANILLA)
  end
  
  if i1 then
    -- Make item string from code so WoW API accepts it
    item = strformat("item:%s", strsub(item, i1, i2))
  end
  
  local item_link, 
    name, item_string, rarity,
    minLevel, item_type, item_subtype,
    stack, item_invtype, texture, ilevel, 
    vendor_price
    = makeItemLink(item)
  if not item_link then return end
  
  -- Returns actual name of a slot, not its key name in global constants
  return item_link, 
    name, item_string, rarity,
    minLevel, item_type, item_subtype,
    stack, _G[item_invtype], texture, ilevel,
    vendor_price
end

function M.getItemVendorPrice(item_code)
  local _, _, item_id = strfind(item_code, PATTERN_PARSE_ITEM_ID_FROM_ITEM_CODE)
  if not item_id then
    A.warn("[getItemVendorPrice] unknown item code: %s", tostring(item_code))
    return
  end
  
  if cached_item_values[item_id] then
    return cached_item_values[item_id]
  end
  
  local name, item_string, rarity, ilevel,
    minLevel, item_type, item_subtype,
    stack, item_invtype, texture, vendor_price
    = GetItemInfo(item_id)
  
  cached_item_values[item_id] = vendor_price or 0
    
  return vendor_price
end