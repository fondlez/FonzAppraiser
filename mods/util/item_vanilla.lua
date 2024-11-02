local A = FonzAppraiser
local client = A.require 'util.client'
if not client.is_vanilla then return end

A.module 'util.item'

local util = A.require 'util.string'

local GetItemInfo, GetItemQualityColor = GetItemInfo, GetItemQualityColor
local strgsub, strfind, strformat, strsub = string.gsub, strfind, string.format, 
  strsub

local PATTERN_PARSE_ITEM_CODE_VANILLA = "(%d+):(%d*):(%d*):(%d*)"
local PATTERN_PARSE_ITEM_LINK = "(|c(%x+)|Hitem:((%d+).-)|h%[(.-)%]|h)"

function M.makeItemCode(token)
  return token
end

function M.parseItemCode(target)
  local found, _, item_id, enchant_id, suffix_id, unique_id = 
    strfind(target, PATTERN_PARSE_ITEM_CODE_VANILLA)
  if not found then return end
  
  return tonumber(item_id), tonumber(enchant_id) or 0, 
    tonumber(suffix_id) or 0, tonumber(unique_id) or 0
end

function M.makeStoreToken(item)
  return item
end

function M.parseItemLink(target)
  local _, _, item_link, color, code, id, name = strfind(target, 
    PATTERN_PARSE_ITEM_LINK)
  return item_link, name, tonumber(id), code, color
end

function M.makeItemLink(item, max_len)
  --[[
    GetItemInfo(item)
    - item can be id or itemString
    - Returns (vanilla: 9):
    - itemName, itemString, itemRarity,
    - itemMinLevel, itemType, itemSubType
    - itemStackCount, itemInvType, itemTexture
  --]]
  local name, item_string, rarity, 
    minLevel, item_type, item_subtype,
    stack, item_invtype, texture
    = GetItemInfo(item)

  if not item_string then return end

  local color
  _, _, _, color = GetItemQualityColor(rarity)
  name = not max_len and name or util.strTrunc(name, max_len, "...")
  
  local ITEMLINK_FORMAT = "%s|H%s|h[%s]|h|r"
  
  return strformat(ITEMLINK_FORMAT, color, item_string, name), 
    name, item_string, rarity,
    minLevel, item_type, item_subtype,
    stack, item_invtype, texture
end

function M.safeItemLink(item)
  if not item then return end
  
  -- Accept item codes, not just item ids, strings or links
  local i1, i2 = strfind(item, PATTERN_PARSE_ITEM_CODE_VANILLA)
  if i1 then
    -- Make item string from code so WoW API accepts it
    item = strformat("item:%s", strsub(item, i1, i2))
  end
  
  local item_link, 
    name, item_string, rarity,
    minLevel, item_type, item_subtype,
    stack, item_invtype, texture
    = makeItemLink(item)
  if not item_link then return end
  
  -- Returns actual name of a slot, not its key name in global constants
  return item_link, 
    name, item_string, rarity,
    minLevel, item_type, item_subtype,
    stack, _G[item_invtype], texture
end