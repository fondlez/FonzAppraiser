local A = FonzAppraiser

A.module 'util.item'

local util = A.requires(
  'util.string',
  'util.client'
)

local PATTERN_PARSE_ITEM_CODE = "(%d+):(%d*):(%d*):(%d*)"
local PATTERN_PARSE_ITEM_LINK = "(|c(%x+)|Hitem:((%d+):%d*:%d*:%d*)|h%[(.-)%]|h|r)"
local PATTERN_FORMAT_MIN_ITEM_STRING = "item:%d:0:0:0"

if util.is_tbc then
  PATTERN_PARSE_ITEM_CODE = "(%d+):(%d*):(%d*):(%d*):(%d*):(%d*):(%d*):(%d*)"
  PATTERN_PARSE_ITEM_LINK = "(|c(%x+)|Hitem:((%d+):%d*:%d*:%d*:%d*:%d*:%d*:%d*)|h%[(.-)%]|h|r)"
  PATTERN_FORMAT_MIN_ITEM_STRING = "item:%d:0:0:0:0:0:0:0"
end

function M.parseItemCode(target)
  if util.is_tbc then
    local found, _, item_id, enchant_id, gem1, gem2, gem3, gem4, suffix_id, 
      unique_id = strfind(target, PATTERN_PARSE_ITEM_CODE)
    if not found or tonumber(item_id) < 1 then return end
    return tonumber(item_id), tonumber(enchant_id) or 0, 
      tonumber(suffix_id) or 0, tonumber(unique_id) or 0,
      tonumber(gem1) or 0, tonumber(gem2) or 0, 
      tonumber(gem3) or 0, tonumber(gem4) or 0
  else
    local found, _, item_id, enchant_id, suffix_id, unique_id = 
      strfind(target, PATTERN_PARSE_ITEM_CODE)
    if not found or tonumber(item_id) < 1 then return end
    return tonumber(item_id), tonumber(enchant_id) or 0, 
      tonumber(suffix_id) or 0, tonumber(unique_id) or 0
  end
end

function M.parseItemLink(target)
  local _, _, item_link, color, code, id, name = strfind(target, 
    PATTERN_PARSE_ITEM_LINK)
  return item_link, name, tonumber(id), code, color
end

--CHECK
function M.makeItemLink(item, max_len)
  --[[
    GetItemInfo(item)
    - item can be id or itemString
    - Returns (vanilla: 9, tbc:10):
    - itemName, itemString, itemRarity, [tbc: ilevel,]
    - itemMinLevel, itemType, itemSubType
    - itemStackCount, itemInvType, itemTexture
  --]]
  if util.is_tbc then
    local name, item_string, rarity, ilevel,
      level, item_type, item_subtype,
      stack, item_invtype, texture
      = GetItemInfo(item)
    
    if not item_string then return end
    
    local color
    _, _, _, color = GetItemQualityColor(rarity)
    name = not max_len and name or util.strTrunc(name, max_len, "...")
    --Note. itemString is not an item string in tbc, but a full item link
    --So, substitute the name part with the potentially shortened name above.
    return string.gsub(item_string, "%[[^%]]+%]", format("[%s]", name)), 
      name, item_string, rarity,
      level, item_type, item_subtype,
      stack, item_invtype, texture, ilevel
  else
    local ITEMLINK_FORMAT = "%s|H%s|h[%s]|h|r"
    local name, item_string, rarity, 
      level, item_type, item_subtype,
      stack, item_invtype, texture
      = GetItemInfo(item)
    
    if not item_string then return end
    
    local color
    _, _, _, color = GetItemQualityColor(rarity)
    name = not max_len and name or util.strTrunc(name, max_len, "...")
    return format(ITEMLINK_FORMAT, color, item_string, name), 
      name, item_string, rarity,
      level, item_type, item_subtype,
      stack, item_invtype, texture
  end
end

function M.safeItemLink(item)
  if not item then return end
  --Accept item links and codes not just ids or item strings
  local i1, i2 = strfind(item, PATTERN_PARSE_ITEM_CODE)
  if i1 then
    --Make item string from code
    item = format("item:%s", strsub(item, i1, i2))
  end
  
  if util.is_tbc then
    local item_link, 
      name, item_string, rarity, ilevel,
      level, item_type, item_subtype,
      stack, item_invtype, texture
      = makeItemLink(item)
    
    if item_link then
      return item_link, 
        name, item_string, rarity,
        level, item_type, item_subtype,
        stack, _G[item_invtype], texture, ilevel
    end
  else
    local item_link, 
      name, item_string, rarity,
      level, item_type, item_subtype,
      stack, item_invtype, texture
      = makeItemLink(item)
    
    if item_link then
      return item_link, 
        name, item_string, rarity,
        level, item_type, item_subtype,
        stack, _G[item_invtype], texture
    end
  end
  
  --Unable to make viable item link so show an item id as item string
  local potential_item = tonumber(item) or 0
  if potential_item > 0 then
    return format(PATTERN_FORMAT_MIN_ITEM_STRING, item)
  end
end