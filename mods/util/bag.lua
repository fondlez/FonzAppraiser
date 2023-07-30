local A = FonzAppraiser

A.module 'util.bag'

local util = A.require 'util.item'

function mprint(...)
  local arg = {...}
  local t = {}
  for i, v in ipairs(arg) do
    t[i] = tostring(v)
  end
  DEFAULT_CHAT_FRAME:AddMessage(table.concat(t, " "))
end

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
  
  local safeItemLink = util.safeItemLink
  local parseItemCode = util.parseItemCode
  
  function M.hasSoulboundItem(search_item)
    if not search_item then return end
    
    local search_item_link = safeItemLink(search_item)
    if not search_item_link then return end
    
    local search_key = format("%d:%d:%d", parseItemCode(search_item_link))
    for b = 0,4 do
      for s = 1,GetContainerNumSlots(b) do
        local link = GetContainerItemLink(b, s)
        if not isempty(link) then
          local key = format("%d:%d:%d", parseItemCode(link))
          if key == search_key then
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

function M.useBagItem(item, show)
  if isempty(item) then return end
  
	for b = 0,4 do
		for s = 1,GetContainerNumSlots(b) do
			local link = GetContainerItemLink(b, s)
			if not isempty(link) then
				if string.find(link, item) then
          UseContainerItem(b, s)
          if show then
            mprint("Item '" .. itemLinkToName(link) .. "' used.")
          end
          return true
				end
			end
		end
	end
end

function M.deleteBagItem(bag, slot)
  PickupContainerItem(bag,slot)
  DeleteCursorItem()
end

function M.deleteNamedBagItem(item, bag, slot, show)
	if isempty(item) or bag == nil or slot == nil then return end
  if show == nil then show = true end
  
	local expected_item = string.lower(itemLinkToName(item))  
  if isempty(expected_item) then return end
  
  local link = GetContainerItemLink(bag, slot)
	if not link then return end
  
  local bag_item = string.lower(itemLinkToName(link))
  if bag_item == expected_item then
    if show then
      mprint("Deleting bag item: "..bag_item)
    end
    deleteBagItem(bag, slot)
  end
end

function M.deleteItem(item)
	if isempty(item) then return end
  
  local bag, slot = findBagItem(item)
  if bag == nil or slot == nil then return end
  
  deleteNamedBagItem(item, bag, slot)
end