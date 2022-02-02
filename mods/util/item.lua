local A = FonzAppraiser

A.module 'util.item'

local util = A.require 'util.string'

function M.parseItemCode(target)
  local found, _, item_id, enchant_id, suffix_id, unique_id = strfind(target,
    "(%d+):(%d*):(%d*):(%d*)")
  if not found then return end
  return tonumber(item_id), tonumber(enchant_id) or 0, tonumber(suffix_id) or 0,
    tonumber(unique_id) or 0
end

function M.parseItemString(target)
  local found, _, item_id, enchant_id, suffix_id, unique_id = strfind(target,
    "item:(%d+):(%d*):(%d*):(%d*)")
  if not found then return end
  return tonumber(item_id), tonumber(enchant_id) or 0, tonumber(suffix_id) or 0,
    tonumber(unique_id) or 0
end

function M.makeItemString(item_id, enchant_id, suffix_id, unique_id)
  local id = tonumber(item_id)
  if not id then return end
  
  local item_string = format("item:%d", id)
  item_string = format("%s:%d", item_string, tonumber(enchant_id) or 0)
  item_string = format("%s:%d", item_string, tonumber(suffix_id) or 0)
  item_string = format("%s:%d", item_string, tonumber(unique_id) or 0)
  return item_string
end

function M.parseItemLink(target)
  local _, _, item_link, color, code, id, name = strfind(target, 
    "(|c(%x+)|Hitem:((%d+):%d*:%d*:%d*)|h%[(.-)%]|h|r)")
  return item_link, name, tonumber(id), code, color
end

function M.makeItemLink(item, max_len)
  local ITEMLINK_FORMAT = "%s|H%s|h[%s]|h|r"
  --[[
    GetItemInfo(item)
    - item can be id or itemString
    - Returns (9):
    - itemName, itemString, itemRarity, 
    - itemMinLevel, itemType, itemSubType
    - itemStackCount, itemInvType, itemTexture
  --]]
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

function M.safeItemLink(item)
  if not item then return end
  --Accept item links and codes not just ids or item strings
  local i1, i2 = strfind(item, "(%d+):(%d*):(%d*):(%d*)")
  if i1 then
    --Make item string from code
    item = format("item:%s", strsub(item, i1, i2))
  end

  local item_link, 
    name, item_string, rarity,
    level, item_type, item_subtype,
    stack, item_invtype, texture
    = makeItemLink(item)
  
  --Unable to make viable item link so show an item id as item string
  if not item_link and tonumber(item) then 
    return format("item:%d:0:0:0", item)
  end
  
  return item_link, 
    name, item_string, rarity,
    level, item_type, item_subtype,
    stack, _G[item_invtype], texture
end
