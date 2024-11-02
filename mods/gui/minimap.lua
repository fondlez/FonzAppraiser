local A = FonzAppraiser
local L = A.locale

A.module 'fa.gui.minimap'

local util = A.require 'util.money'

local palette = A.require 'fa.palette'
local notice = A.require 'fa.notice'
local session = A.require 'fa.session'
local gui = A.require 'fa.gui'

-- Minimap icon
do
  local frame = CreateFrame("Button", A.name .. "MinimapIcon", Minimap)
  M.icon = frame
  
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  frame:SetFrameStrata("LOW")
  gui.setSize(frame, 31)
  frame:SetFrameLevel(9)
  frame:SetHighlightTexture(
    [[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])
  frame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
end

-- Icon overlay
do
  local overlay = icon:CreateTexture(nil, "OVERLAY")
  icon.overlay = overlay
  gui.setSize(overlay, 53)
  overlay:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
  overlay:SetPoint("TOPLEFT", 0, 0)
end

-- Icon logo
do
  local logo = icon:CreateTexture(nil, "BACKGROUND")
  icon.logo = logo
  gui.setSize(logo, 20)
  logo:SetTexture(A.addon_path .. [[\img\icon_disable]])
  logo:SetPoint("CENTER", 0, 0)
end

-- Icon behavior --

-- Dragging

icon:SetScript("OnDragStart", function()
  if IsShiftKeyDown() then
    this:StartMoving()
  end 
end)
icon:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

-- Tooltip

do
  local white = palette.color.white
  local white_rgb = { white() }
  local yellow = palette.color.yellow
  local yellow_rgb = { yellow() }
  local blue = palette.color.blue1
  local blue_rgb = { blue() }
  local getCurrentPerHourValue = session.getCurrentPerHourValue
  local getCurrentTotalValue = session.getCurrentTotalValue
  local getCurrentMoney =session.getCurrentMoney
  local getCurrentItemsCount = session.getCurrentItemsCount
  local getCurrentItemsValue = session.getCurrentItemsValue
  local getCurrentHotsValue = session.getCurrentHotsValue
  local getTarget = notice.getTarget
  local getCurrentItems = session.getCurrentItems
  local sortItemsByValue = session.sortItemsByValue
  local formatMoneyFull = util.formatMoneyFull
  
  local function formatMoney(money)
    return money and formatMoneyFull(money, true, nil, true) or "-"
  end
  
  local function formatCount(count)
    return count and format("%s", white(count)) or ""
  end
  
  local function formatItem(record)
    return format("%s %s", 
      record.count and format("%sx", record.count) or "", 
      record.item_link or "-"), 
      formatMoneyFull(record.value or 0, true, nil, true) or ""
  end
  
  icon:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
    GameTooltip:SetText(A.name)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(
      L["Hourly:"], 
      formatMoney(getCurrentPerHourValue()),
      yellow_rgb[1], yellow_rgb[2], yellow_rgb[3],
      white_rgb[1], white_rgb[2], white_rgb[3])
    GameTooltip:AddDoubleLine(
      L["Session Value:"], 
      formatMoney(getCurrentTotalValue()),
      yellow_rgb[1], yellow_rgb[2], yellow_rgb[3],
      white_rgb[1], white_rgb[2], white_rgb[3])
    GameTooltip:AddDoubleLine(
      L["Currency:"],
      formatMoney(getCurrentMoney()), 
      yellow_rgb[1], yellow_rgb[2], yellow_rgb[3],
      white_rgb[1], white_rgb[2], white_rgb[3])
    GameTooltip:AddDoubleLine(
      format(L["All Items [%s]:"], 
        formatCount(getCurrentItemsCount("items"))), 
      formatMoney(getCurrentItemsValue()), 
      yellow_rgb[1], yellow_rgb[2], yellow_rgb[3],
      white_rgb[1], white_rgb[2], white_rgb[3])
    GameTooltip:AddDoubleLine(
      format(L["Hot Items [%s]:"], 
        formatCount(getCurrentItemsCount("hots"))),
      formatMoney(getCurrentHotsValue()), 
      yellow_rgb[1], yellow_rgb[2], yellow_rgb[3],
      white_rgb[1], white_rgb[2], white_rgb[3])
      
    if session.isCurrent() then
      local total, target = getTarget()
      local n = tonumber(target)
      if n and n > 0 then
        GameTooltip:AddDoubleLine(
          L["Target:"],
          formatMoney(n),
          yellow_rgb[1], yellow_rgb[2], yellow_rgb[3],
          white_rgb[1], white_rgb[2], white_rgb[3])
        GameTooltip:AddDoubleLine(
          L["Progress:"],
          format("%d%%", math.min(100, math.floor(total/n * 100))),
          yellow_rgb[1], yellow_rgb[2], yellow_rgb[3],
          white_rgb[1], white_rgb[2], white_rgb[3])
      end
    end
    
    local items = getCurrentItems()
    local items_data = items and sortItemsByValue(items, true)
    local top_item = items_data and items_data[1]
    
    if top_item then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L["Most Valuable Item"], 
        blue_rgb[1], blue_rgb[2], blue_rgb[3])
      local left, right = formatItem(top_item)
      GameTooltip:AddDoubleLine(left, right,
        white_rgb[1], white_rgb[2], white_rgb[3],
        white_rgb[1], white_rgb[2], white_rgb[3])
    end
    
    GameTooltip:Show()
  end)
  icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Clicks

icon:SetScript("OnClick", function()
  if arg1 == "LeftButton" then
    A.toggleMainWindow()
  else
    A.toggleConfigWindow()
  end
end)

-- Icon updates: icon may change if the state of the addon changes
function M.update()
  -- Update the logo to visually show if the addon has a current session
  if session.isCurrent() then
    icon.logo:SetTexture(A.addon_path .. [[\img\icon]])
  else
    icon.logo:SetTexture(A.addon_path .. [[\img\icon_disable]])
  end
end

function M.showOnSetting(setting)
  PlaySound(gui.sounds.click_close)
  if icon:IsVisible() and not setting then
    icon:Hide()
  end
  if not icon:IsVisible() and setting then
    icon:Show()
  end
end