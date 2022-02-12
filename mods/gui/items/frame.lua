local A = FonzAppraiser

A.module 'fa.gui.items'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.time'
)

local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local main = A.require 'fa.gui.main'

do
  local main_frame = main.frame
  local items = CreateFrame("Frame", "$parentItems", main_frame)
  M.items = items
  main_frame:addTabChild(items)
  items:SetPoint("TOPLEFT", main_frame, 11, -32)
  items:SetPoint("BOTTOMRIGHT", main_frame, -12, 12)
  items:Hide()
  items:SetScript("OnShow", items_OnShow)
  items.update = update
end

do
  local dropdown = gui.dropdown(items)
  M.session_dropdown = dropdown
  dropdown:ClearAllPoints()
  dropdown:SetPoint("TOPLEFT", main.quality_dropdown, "BOTTOMLEFT", 0, 4)
  UIDropDownMenu_SetWidth(items:GetWidth()-20, dropdown)
  UIDropDownMenu_SetButtonWidth(items:GetWidth()-20, dropdown)
  UIDropDownMenu_JustifyText("LEFT", dropdown)
  dropdown:SetScript("OnShow", function()
      UIDropDownMenu_Initialize(this, sessionDropdown_Initialize)
  end)
  dropdown.update = updateSessionDropdown
  dropdown.reset = resetSessionDropdown
end

do
  local zone_label = items:CreateFontString(nil, "ARTWORK",
    "GameFontNormalSmall")
  M.zone_label = zone_label
  zone_label:SetPoint("TOPLEFT", session_dropdown, "BOTTOMLEFT", 18, 2)
  zone_label:SetJustifyH("LEFT")
  zone_label:SetText(L["Zone:"])
  
  local zone_text = items:CreateFontString(nil, "ARTWORK",
    "GameFontHighlightSmall")
  M.zone_text = zone_text
  zone_text:SetPoint("TOPLEFT", zone_label, "TOPRIGHT", 0, 0)
  zone_text:SetJustifyH("LEFT")
  zone_text.update = updateZoneText
end

do
  local start_label = items:CreateFontString(nil, "ARTWORK",
    "GameFontNormalSmall")
  M.start_label = start_label
  start_label:SetPoint("TOPLEFT", zone_label, "BOTTOMLEFT", 0, -4)
  start_label:SetJustifyH("LEFT")
  start_label:SetText(L["Start:"])
  
  local start_text = items:CreateFontString(nil, "ARTWORK",
    "GameFontHighlightSmall")
  M.start_text = start_text
  start_text:SetPoint("TOPLEFT", start_label, "TOPRIGHT", 0, 0)
  start_text:SetJustifyH("LEFT")
  start_text.updateDisplay = function(self, timestamp)
    timestamp = timestamp and util.isoDateTime(timestamp, true) or "-"
    self:SetText(timestamp)
  end
  start_text.update = updateStartText
  
  local duration_text = items:CreateFontString(nil, "ARTWORK",
    "GameFontNormalSmall")
  M.duration_text = duration_text
  duration_text:SetPoint("TOPLEFT", start_text, "TOPRIGHT", 0, 0)
  duration_text:SetJustifyH("LEFT")
  duration_text.update = updateDurationText
  
  local duration_animation = CreateFrame("Frame", nil, items)
  items.duration_animation = duration_animation
  duration_animation.interval = 1.0
  duration_animation:Hide()
  duration_animation:SetScript("OnUpdate", durationAnimation_OnUpdate)
end

do
  local dropdown = gui.dropdown(items)
  M.store_dropdown = dropdown
  dropdown:ClearAllPoints()
  dropdown:SetPoint("TOPRIGHT", session_dropdown, "BOTTOMRIGHT", 0, 4)
  UIDropDownMenu_SetWidth(54, dropdown)
  UIDropDownMenu_SetButtonWidth(54, dropdown)
  UIDropDownMenu_JustifyText("LEFT", dropdown)
  dropdown:SetScript("OnShow", function()
      UIDropDownMenu_Initialize(this, storeDropdown_Initialize)
  end)
  dropdown.update = updateStoreDropdown
  dropdown.reset = resetStoreDropdown
end

do
  local currency_label = items:CreateFontString(nil, "ARTWORK",
    "GameFontNormalSmall")
  M.currency_label = currency_label
  currency_label:SetPoint("TOPLEFT", start_label, "BOTTOMLEFT", 0, -4)
  currency_label:SetJustifyH("LEFT")
  currency_label:SetText(L["Currency:"])
  
  local currency_value = items:CreateFontString(nil, "ARTWORK",
    "GameFontHighlightSmall")
  M.currency_value = currency_value
  currency_value:SetPoint("TOPLEFT", currency_label, "TOPRIGHT", 0, 0)
  currency_value:SetJustifyH("RIGHT")
  currency_value.updateDisplay = function(self, value)
    value = value and abacus:FormatMoneyFull(value, true) or "-"
    self:SetText(value)
  end
  currency_value.update = updateCurrencyValue
end

do
  local items_value = items:CreateFontString(nil, "ARTWORK",
    "GameFontHighlightSmall")
  M.items_value = items_value
  items_value:SetPoint("TOPRIGHT", store_dropdown, "BOTTOMRIGHT", -30, 2)
  items_value:SetJustifyH("RIGHT")
  items_value.updateDisplay = function(self, value)
    --Final argument to custom Abacus library creates zero padding digits.
    value = value and abacus:FormatMoneyFull(value, true, nil, true) or "-"
    self:SetText(value)
  end
  items_value.update = updateItemsValue
  
  local items_text = items:CreateFontString(nil, "ARTWORK",
    "GameFontNormalSmall")
  M.items_text = items_text
  items_text:SetPoint("TOPRIGHT", items_value, "TOPLEFT", 0, 0)
  items_text.updateDisplay = function(self, items_count)
    self:SetText(string.format(L["Items [%s]:"], 
      items_count and palette.color.white(items_count) or ""))
  end
  items_text.update = updateItemsText
end

do
  local table_frame = CreateFrame("Frame", "$parentTable", items)
  M.table_frame = table_frame
  table_frame:SetPoint("TOPLEFT", currency_label, "BOTTOMLEFT", 0, -2)
  table_frame:SetPoint("BOTTOMRIGHT", items)
  table_frame.scrollFrameFauxUpdate = scrollFrameFauxUpdate
end

do
  local function headerButton(parent, text, width, height, justify)
    local button = CreateFrame("Button", nil, parent)
    if width then
      button:SetWidth(width)
    end
    if height then
      button:SetHeight(height)
    end
    
    local texture = button:CreateTexture()
    button.texture = texture
    texture:SetAllPoints(button)
    texture:SetTexture(1, 1, 1, 1)
    texture:SetVertexColor(0, 0, 0, 0.5)
    
    local label = button:CreateFontString()
    button.label = label
    label:SetFontObject(GameFontNormalSmall)
    label:SetAllPoints(button)
    label:SetJustifyH(justify or "CENTER")
    label:SetText(text)
    button:SetFontString(label)
    
    button:SetScript("OnEnter", function()
      texture:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    end)
    button:SetScript("OnLeave", function()
      texture:SetVertexColor(0, 0, 0, 0.5)
    end)
    button:SetScript("OnClick", function()
      PlaySound(gui.sounds.click)
      if this.onClick then 
        this:onClick()
      end
    end)
    
    return button
  end
  
  local count_button = headerButton(table_frame, L["Count"], 33, 20, "RIGHT")
  M.count_button = count_button
  count_button:SetPoint("TOPLEFT", table_frame)
  count_button.reverse = true
  count_button.onClick = countButtonOnClick
  
  local item_button = headerButton(table_frame, L["Item"], 222, 20, nil)
  M.item_button = item_button
  item_button:SetPoint("TOPLEFT", count_button, "TOPRIGHT")
  item_button.reverse = false
  item_button.onClick = itemButtonOnClick

  local value_button = headerButton(table_frame, L["Value"], 78, 20, "RIGHT")
  M.value_button = value_button
  value_button.reverse = true
  value_button:SetPoint("TOPLEFT", item_button, "TOPRIGHT")
  value_button.onClick = valueButtonOnClick
end

do
  local scroll_frame = CreateFrame("ScrollFrame", "$parentScrollFrame", 
    table_frame, "FauxScrollFrameTemplate")
  M.scroll_frame = scroll_frame
  gui.styles["content"](scroll_frame)
  scroll_frame:SetPoint("TOPLEFT", count_button, "BOTTOMLEFT", 0, 0)
  scroll_frame:SetPoint("BOTTOMRIGHT", table_frame)
  scroll_frame:SetBackdropColor(palette.color.transparent())
  
  -- Nest the scrollbar/slider inside the scroll frame instead of default space.
  -- Global name resolution is used by Blizzard code.
  scroll_frame.slider = _G[scroll_frame:GetName().."ScrollBar"]
  scroll_frame.slider:SetPoint("TOPLEFT", scroll_frame, "TOPRIGHT", -16, 0)
  scroll_frame.slider:SetPoint("BOTTOMLEFT", scroll_frame, 
    "BOTTOMRIGHT", -16, 16)
  scroll_frame.slider.reset = function(self)
    self:SetValue(self:GetMinMaxValues())
  end
  
  local parent = scroll_frame:GetParent()
  parent["sframe1"] = {}
  parent["sframe1"].object = scroll_frame
  parent["sframe1"].max_size = 100
  parent["sframe1"].data_size = parent["sframe1"].max_size
  parent["sframe1"].display_size = 10
  parent["sframe1"].entry_height = 16
  parent["sframe1"].entries = {}
  
  local properties = {
    { width=33, justify="RIGHT", font=gui.small_number_font },
    { width=222, justify="LEFT", font=GameFontHighlightSmall },
    { width=78, justify="RIGHT", font=gui.small_number_font },
  }
  gui.makeThreeColTextRows(scroll_frame, "sframe1", 0, -20, -16, properties)
  
  scroll_frame:SetScript("OnVerticalScroll", scrollFrame_OnVerticalScroll)
  scroll_frame.update = updateScrollFrame
end