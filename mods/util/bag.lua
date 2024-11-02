local A = FonzAppraiser

A.module 'util.bag'

local util = A.require 'util.item'

local DeleteCursorItem = DeleteCursorItem
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots
local PickupContainerItem = PickupContainerItem

function isempty(s)
  return s == nil or s == ''
end

function itemLinkToName(link)
	return gsub(link,"^.*%[(.*)%].*$","%1")
end

do
  local find = string.find
  local ref_frame = CreateFrame("Frame", nil)

  function M.isSoulbound(bag, slot)
    GameTooltip:SetOwner(ref_frame, "ANCHOR_NONE")
    
    GameTooltip:SetBagItem(bag, slot)
    
    local status
    
    local fontstring = _G["GameTooltipTextLeft2"]
    if fontstring then
      local text = fontstring:GetText()
      if text then
        status = find(text, ITEM_SOULBOUND)
      end
    end
    
    GameTooltip:Hide()
    
    return status
  end
  
  local makeItemCode = util.makeItemCode
  local parseItemLink = util.parseItemLink
  local safeItemLink = util.safeItemLink
  
  function M.hasSoulboundItemCode(search_code)
    if not search_code then return end
    
    search_code = makeItemCode(search_code) or search_code
    
    for b = 0,4 do
      for s = 1,GetContainerNumSlots(b) do
        local link = GetContainerItemLink(b, s)
        if not isempty(link) then
          local _, _, _, code = parseItemLink(link)
          if code == search_code then
            return isSoulbound(b, s)
          end
        end
      end
    end
    
    return false
  end
  
  function M.hasSoulboundItem(search_item)
    if not search_item then return end
    
    local search_item_link = safeItemLink(search_item)
    if not search_item_link then return end
    
    local _, _, _, search_code = parseItemLink(search_item_link)
    for b = 0,4 do
      for s = 1,GetContainerNumSlots(b) do
        local link = GetContainerItemLink(b, s)
        if not isempty(link) then
          local _, _, _, code = parseItemLink(link)
          if code == search_code then
            return isSoulbound(b, s)
          end
        end
      end
    end
    
    return false
  end
end

function M.findBagItem(item)
	if isempty(item) then return end

	local search_item = itemLinkToName(item)
  if isempty(search_item) then return end
  search_item = strlower(search_item)
  
	local bag, slot, texture
	local totalcount = 0
  
	for b = 0,4 do
		for s = 1,GetContainerNumSlots(b) do
			local link = GetContainerItemLink(b, s)
			if not isempty(link) then
        local bag_item = itemLinkToName(link)
        if not isempty(bag_item) then
          bag_item = strlower(bag_item)
          if search_item == bag_item then
            bag, slot = b, s
            local count
            texture, count = GetContainerItemInfo(b, s)
            totalcount = totalcount + count
          end
        end
			end
		end
	end
  
	return bag, slot, texture, totalcount
end

function M.useBagItem(item)
  if isempty(item) then return end
  
	for b = 0,4 do
		for s = 1,GetContainerNumSlots(b) do
			local link = GetContainerItemLink(b, s)
			if not isempty(link) and string.find(link, item) then
        UseContainerItem(b, s)
        return true
			end
		end
	end
  
  return false
end

function M.deleteBagItem(bag, slot)
  PickupContainerItem(bag,slot)
  DeleteCursorItem()
end

function M.deleteNamedBagItem(item, bag, slot)
	if isempty(item) or bag == nil or slot == nil then return end
  
	local expected_item = string.lower(itemLinkToName(item))  
  if isempty(expected_item) then return end
  
  local link = GetContainerItemLink(bag, slot)
	if not link then return end
  
  local bag_item = string.lower(itemLinkToName(link))
  if bag_item == expected_item then
    deleteBagItem(bag, slot)
    return true
  end
  
  return false
end

function M.deleteItem(item)
	if isempty(item) then return end
  
  local bag, slot = findBagItem(item)
  if bag == nil or slot == nil then return end
  
  deleteNamedBagItem(item, bag, slot)
end