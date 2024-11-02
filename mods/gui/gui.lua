local A = FonzAppraiser

A.module 'fa.gui'

local util = A.requires(
  'util.string',
  'util.money',
  'util.chat'
)

local palette = A.require 'fa.palette'

local font = {
  default=[[Fonts\FRIZQT__.TTF]],
  fixed=[[Fonts\ARIALN.TTF]],
}
M.font = font

local font_size = {
  small = 10,
  medium = 12,
  regular = 14,
  large = 18,
}
M.font_size = font_size

local small_number_font = CreateFont(A.name .. "_NumberFontNormalSmall")
M.small_number_font = small_number_font
small_number_font:CopyFontObject(GameFontHighlightSmall)
small_number_font:SetFont(font.fixed, font_size.medium)

local sounds = {
  click = "igMainMenuOptionCheckBoxOn",
  click_on = "igMainMenuOptionCheckBoxOn",
  click_off = "igMainMenuOptionCheckBoxOff",
  click_close = "UChatScrollButton",
  menu_open = "igMainMenuOpen",
  menu_close = "igMainMenuClose",
  tabbing = "igCharacterInfoTab",
  
  file_numeric_input_ok = "Sound\\interface\\MagicClick.wav",
  file_open_page = "Sound\\interface\\iAbilitiesOpenA.wav",
  file_close_page = "Sound\\interface\\iAbilitiesCloseA.wav",
  file_open_char = "Sound\\interface\\uCharacterSheetOpen.wav",
  file_close_char = "Sound\\interface\\uCharacterSheetClose.wav",
  file_purge = "Sound\\Spells\\Purge.wav",
}
M.sounds = sounds

function M.setSize(frame, width, height)
	frame:SetWidth(width)
	frame:SetHeight(height or width)
end

function M.setBackdropStyle(frame, backdropColor, borderColor, 
    left, right, top, bottom, edgeSize, tileSize, bgFile, edgeFile)
  edgeSize = edgeSize or 32
  tileSize = tileSize or 32
  bgFile = bgFile or [[Interface\DialogFrame\UI-DialogBox-Background]]
  edgeFile = edgeFile or [[Interface\DialogFrame\UI-DialogBox-Border]]
	frame:SetBackdrop{
    bgFile=bgFile, 
    edgeFile=edgeFile, 
    edgeSize=edgeSize, 
    tile=true, tileSize=tileSize,
    insets={ left=left, right=right, top=top, bottom=bottom },
  }
  if backdropColor then
    frame:SetBackdropColor(backdropColor())
  end
  if borderColor then
    frame:SetBackdropBorderColor(borderColor())
  end
end

do
  local function factory(style)
    return function(frame, left, right, top, bottom, edgeSize, tileSize)
      setBackdropStyle(frame, style.background, style.border,
        left, right, top, bottom, edgeSize, tileSize)
    end
  end
  
  local color = palette.color
  
  local properties = {
    ["default"] = color.backdrop.none,
    ["window"] = color.backdrop.window,
    ["panel"] = color.backdrop.panel,
    ["content"] = color.backdrop.content,
  }
  
  M.styles = {}
  for k,v in pairs(properties) do
    styles[k] = factory(properties[k])
  end
end

function M.content(parent, name)
  local frame = CreateFrame("Frame", name, parent)
  styles["content"](frame)
  return frame
end

function M.panel(parent, name)
  local frame = CreateFrame("Frame", name, parent)
  styles["panel"](frame)
  return frame
end

function M.window(parent, name)
  local frame = CreateFrame("Frame", name, parent)
  styles["window"](frame)
  return frame
end

do
  local ids = {}
  
  local function name(frame)
    ids[frame] = (ids[frame] or 0) + 1
    return "$parentButton" .. tostring(ids[frame])
  end
  
  function M.button(parent, id, width, height, text)
    local frame = CreateFrame("Button", id or name(parent), parent,
      "UIPanelButtonTemplate")
    frame:SetWidth(width or 64)
    frame:SetHeight(height or 24)
    frame:GetFontString():ClearAllPoints()
    frame:GetFontString():SetAllPoints(frame)
    frame:GetFontString():SetJustifyH("CENTER")
    frame:GetFontString():SetJustifyV("CENTER")
    frame:SetText(text or OKAY)
    frame:SetScript("OnClick", function()
      PlaySound(sounds.click)
      if this.onClick then
        this:onClick()
      end
    end)
    return frame
  end
  
  function M.imgButton(parent, id, width, height, img, blending, 
      initial_alpha, highlight_alpha, unhighlight_alpha)
    local frame = CreateFrame("Button", id or name(parent), parent)
    frame:SetWidth(width or 64)
    frame:SetHeight(height or 64)
    
    local texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture = texture
    texture:SetAllPoints(frame)
    texture:SetTexture(img)
    texture:SetAlpha(initial_alpha or 1.0)
    texture:SetBlendMode(blending or "ADD")
    
    frame:SetScript("OnEnter", function()
      this.texture:SetAlpha(highlight_alpha or 1.0)
      if this.tooltipOn then
        this:tooltipOn()
      end
    end)
    frame:SetScript("OnLeave", function()
      this.texture:SetAlpha(unhighlight_alpha or 1.0)
      if this.tooltipOn then
        this:tooltipOff()
      end
    end)
    frame:SetScript("OnMouseUp", function()
      this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 0, 0)
    end)
    frame:SetScript("OnMouseDown", function()
      if this:IsEnabled() then
        this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 1, -1)
      end
    end)
    frame:SetScript("OnClick", function()
      PlaySound(sounds.click)
      if this.onClick then
        this:onClick()
      end
    end)
    return frame
  end
end

function M.frameBorder(parent, width, r, g, b, a)
  width = width or 1
  
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(parent)
  frame:SetFrameStrata("BACKGROUND")
  frame:SetFrameLevel(1)
  
  frame.left = frame:CreateTexture(nil, "BORDER")
  frame.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1 - width, -1)
  frame.left:SetPoint("TOPRIGHT", frame, "TOPLEFT", -1, 1)
  frame.left:SetTexture(r, g, b, a)
  
  frame.right = frame:CreateTexture(nil, "BORDER")
  frame.right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 1, -1)
  frame.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1 + width, 1)
  frame.right:SetTexture(r, g, b, a)
  
  frame.top = frame:CreateTexture(nil, "BORDER")
  frame.top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -1, 1)
  frame.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1 + width)
  frame.top:SetTexture(r, g, b, a)
  
  frame.bottom = frame:CreateTexture(nil, "BORDER")
  frame.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
  frame.bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 1, -1 - width)
  frame.bottom:SetTexture(r, g, b, a)
  
  return frame
end

do
  local ids = {}
  
  local function name(frame)
    ids[frame] = (ids[frame] or 0) + 1
    return "$parentDropdown" .. tostring(ids[frame])
  end

  function M.dropdown(parent)
    local dropdown = CreateFrame("Frame", name(parent), parent, 
      "UIDropDownMenuTemplate")
    return dropdown
  end
end

do
  local ids = {}
  
  local function name(frame)
    ids[frame] = (ids[frame] or 0) + 1
    return "$parentCheckButton" .. tostring(ids[frame])
  end
  
  function M.checkbox(parent, id, width, height, indeterminate_texture)
    local frame = CreateFrame("CheckButton", id or name(parent), parent)
    frame:SetWidth(width or 25)
    frame:SetHeight(width or 25)
    frame:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
    frame:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])
    frame:SetHighlightTexture([[Interface\Buttons\UI-CheckBox-Highlight]], 
      "ADD")
    frame:SetCheckedTexture([[Interface\Buttons\UI-CheckBox-Check]])
    
    do
      local fontstring = frame:CreateFontString()
      fontstring:SetFontObject(GameFontNormalSmall)
      fontstring:SetPoint("LEFT", frame, "RIGHT", -2, 0)
      frame:SetFontString(fontstring)
    end
    
    do
      local texture = frame:CreateTexture()
      texture:SetPoint("TOPLEFT", frame, 4, -5)
      texture:SetPoint("BOTTOMRIGHT", frame, 4, -5)
      texture:SetTexture(
        [[Interface\Buttons\UI-Checkbox-SwordCheck]])
      texture:Hide()
      frame.indeterminate = indeterminate_texture or texture
    end
    
    function frame:showIndeterminate()
      self.indeterminate:Show()
    end
    function frame:hideIndeterminate()
      self.indeterminate:Hide()
    end
    
    frame:SetScript("OnClick", function()
      if this:GetChecked() then
        PlaySound(sounds.click_off)
      else
        PlaySound(sounds.click_on)
      end
      this:hideIndeterminate()
      if this.onClick then
        this:onClick()
      end
    end)
    return frame
  end
end

do
  local function name(frame, id)
    return "$parentEntry".. tostring(id)
  end
  
  local function enableHighlight(button)
    local texture = button:CreateTexture()
    texture:SetAllPoints(button)
    texture:SetTexture([[Interface\Buttons\UI-Listbox-Highlight]])
    texture:SetAlpha(.2)
    button:SetHighlightTexture(texture)
  end

  function M.scrollEntry(parent, scroll_frame_index, first, x, y, z)
    local info = parent[scroll_frame_index]
    if first then 
      info.id = 1
    end
    local id = info.id
    if not id then
      A.error("No id set. A 'first' scroll frame entry is required.")
      return
    end
    
    local entry = CreateFrame("Button", name(parent, id), parent)
    entry:SetID(id)
    entry:SetHeight(info.entry_height)
    entry.info = info
    
    if not first then
      local previous = info.entries[id - 1]
      entry:SetPoint("TOPLEFT", previous,
        "BOTTOMLEFT")
      entry:SetPoint("TOPRIGHT", previous,
        "BOTTOMRIGHT")
    else
      x = x or 0; y = y or 0; z = z or 0
      entry:SetPoint("TOPLEFT", parent, x, y)
      entry:SetPoint("TOPRIGHT", parent, z, y)
    end

    enableHighlight(entry)
    
    entry:SetScript("OnClick", function()
      if this.onClick then
        this:onClick()
      end
    end)
    
    entry:Disable()
    entry:Hide()
    
    info.id = id + 1
    return entry
  end
  
  local function onClickItem(self)
    if not self.item_link then return end
    if IsShiftKeyDown() then
      util.chatlink(self.item_link)
    elseif IsControlKeyDown() then
      DressUpItemLink(self.item_link)
    end
  end
  
  function M.makeOneColTextRows(self, scroll_frame_index, x, y, z, justify, 
      onClick)
    local parent = self:GetParent()
    local info = parent[scroll_frame_index]
    
    local entry = scrollEntry(parent, scroll_frame_index, true, x, y, z)
    entry.onClick = onClick or onClickItem
    
    local entry_text = entry:CreateFontString(nil, "ARTWORK")
    entry.text = entry_text
    entry_text:SetFontObject(GameFontHighlightSmall)
    entry_text:SetAllPoints(entry)
    entry_text:SetWidth(entry:GetWidth())
    entry_text:SetJustifyH(justify or "LEFT")
    
    tinsert(info.entries, entry)

    for i=2,info.display_size do
      entry = scrollEntry(parent, scroll_frame_index)
      entry.onClick = onClick or onClickItem
      
      entry_text = entry:CreateFontString(nil, "ARTWORK")
      entry.text = entry_text
      entry_text:SetFontObject(GameFontHighlightSmall)
      entry_text:SetAllPoints(entry)
      entry_text:SetWidth(entry:GetWidth())      
      entry_text:SetJustifyH(justify or "LEFT")
      
      tinsert(info.entries, entry)
    end
  end
  
  function M.makeThreeColTextRows(self, scroll_frame_index, x, y, z, 
      properties, onClick)
    local parent = self:GetParent()
    local info = parent[scroll_frame_index]
    
    local entry = scrollEntry(parent, scroll_frame_index, true, x, y, z)
    entry.onClick = onClick or onClickItem
    
    local function genFontString(frame, property)
      local fontstring = frame:CreateFontString(nil, "ARTWORK")
      fontstring:SetFontObject(property.font or GameFontHighlightSmall)
      fontstring:SetHeight(frame:GetHeight())
      fontstring:SetWidth(property.width)
      fontstring:SetJustifyV("CENTER")
      fontstring:SetJustifyH(property.justify or "LEFT")
      return fontstring
    end
    
    local text1 = genFontString(entry, properties[1])
    entry.text1 = text1
    text1:SetPoint("TOPLEFT", entry)
    
    local text2 = genFontString(entry, properties[2])
    entry.text2 = text2
    text2:SetPoint("TOPLEFT", text1, "TOPRIGHT")
    
    local text3 = genFontString(entry, properties[3])
    entry.text3 = text3
    text3:SetPoint("TOPLEFT", text2, "TOPRIGHT")
    
    tinsert(info.entries, entry)

    for i=2,info.display_size do
      entry = scrollEntry(parent, scroll_frame_index)
      entry.onClick = onClick or onClickItem
      
      text1 = genFontString(entry, properties[1])
      entry.text1 = text1
      text1:SetPoint("TOPLEFT", entry)
      
      text2 = genFontString(entry, properties[2])
      entry.text2 = text2
      text2:SetPoint("TOPLEFT", text1, "TOPRIGHT")

      text3 = genFontString(entry, properties[3])
      entry.text3 = text3
      text3:SetPoint("TOPLEFT", text2, "TOPRIGHT")
      
      tinsert(info.entries, entry)
    end
  end
  
  function M.makeCheckButtonRows(self, scroll_frame_index, x, y, z, justify,
      onClickEntry, onClickCheckbox, onEnterEntry, onLeaveEntry)
    local parent = self:GetParent()
    local info = parent[scroll_frame_index]
    
    local entry = scrollEntry(parent, scroll_frame_index, true, x, y, z)
    entry.onClick = onClickEntry
    if onEnterEntry then
      entry:SetScript("OnEnter", onEnterEntry)
    end
    if onLeaveEntry then
      entry:SetScript("OnLeave", onLeaveEntry)
    end
    
    local entry_checkbox = checkbox(entry, nil)
    entry.checkbox = entry_checkbox
    entry_checkbox:SetPoint("LEFT", entry)
    entry_checkbox:SetChecked(false)
    entry_checkbox.onClick = onClickCheckbox
    
    local button = CreateFrame("Button", "$parentCurrentSessionButton", entry)
    entry.button = button
    button:SetPoint("TOPLEFT", entry_checkbox, "TOPRIGHT")
    button:SetPoint("BOTTOMRIGHT", entry, 0, 0)
    
    --Entry parent has highlight texture so put child behind parent
    --Note. in TBC changing parent frame level affects children, so only 
    --change child.
    button:SetFrameLevel(entry:GetFrameLevel() - 1)
    --Checkbox must still remain clickable, so pull in front of parent
    entry_checkbox:SetFrameLevel(entry:GetFrameLevel() + 1)
    
    local text = button:CreateFontString(nil, "ARTWORK")
    button.text = text
    text:SetFontObject(GameFontHighlightSmall)
    text:SetAllPoints(button)
    text:SetWidth(button:GetWidth())
    text:SetJustifyH(justify or "LEFT")
    
    tinsert(info.entries, entry)
    
    for i=2,info.display_size do
      entry = scrollEntry(parent, scroll_frame_index)
      entry.onClick = onClickEntry
      if onEnterEntry then
        entry:SetScript("OnEnter", onEnterEntry)
      end
      if onLeaveEntry then
        entry:SetScript("OnLeave", onLeaveEntry)
      end
      
      entry_checkbox = checkbox(entry, nil)
      entry.checkbox = entry_checkbox
      entry_checkbox:SetPoint("LEFT", entry)
      entry_checkbox:SetChecked(false)
      entry_checkbox.onClick = onClickCheckbox
      
      button = CreateFrame("Button", nil, entry)
      entry.button = button
      button:SetPoint("TOPLEFT", entry_checkbox, "TOPRIGHT")
      button:SetPoint("BOTTOMRIGHT", entry, 0, 0)
      
      button:SetFrameLevel(entry:GetFrameLevel() - 1)
      entry_checkbox:SetFrameLevel(entry:GetFrameLevel() + 1)
      
      text = button:CreateFontString(nil, "ARTWORK")
      button.text = text
      text:SetFontObject(GameFontHighlightSmall)
      text:SetAllPoints(button)
      text:SetWidth(button:GetWidth())
      text:SetJustifyH(justify or "LEFT")
      
      tinsert(info.entries, entry)
    end
  end
end

function M.fitStringWidth(fontstring, text, max_string_width)
  fontstring:SetText(text)
  return fontstring:GetStringWidth() <= max_string_width
end

do
  function M.extendItemTooltip(tooltip, records)
    for i,v in ipairs(records) do
      tooltip:AddDoubleLine(v.desc, v.value or "-")
    end
  end
  
  function M.setRecordTooltip(frame, anchor, records)
    GameTooltip:SetOwner(frame, anchor)
    extendItemTooltip(GameTooltip, records)
    GameTooltip:Show()
  end

  function M.setItemTooltip(frame, anchor, item_string, extra_records)
    GameTooltip:SetOwner(frame, anchor)
    if item_string then
      GameTooltip:SetHyperlink(item_string)
      if extra_records then
        extendItemTooltip(GameTooltip, extra_records)
        GameTooltip:Show()
      end
    end
  end
  
  function M.hideTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
end

function M.cursorAnchor(frame, anchor)
  local scale = frame:GetEffectiveScale()
  local x, y =  GetCursorPosition()
  frame:ClearAllPoints()
  frame:SetPoint(anchor or "CENTER", nil, "BOTTOMLEFT" , x/scale , y/scale)
end

function M.moneyInput(parent, id, total_width, gold_width)
  local name = "$parentMoneyInput"..(id or "")
  local money_input = CreateFrame("Frame", name, parent)
  parent.money_input = money_input
  money_input:SetWidth(total_width or 210)
  money_input:SetHeight(18)
  
  do
    local editbox = CreateFrame("EditBox", nil, money_input)
    money_input.gold_editbox = editbox
    editbox:SetWidth(gold_width or 32)
    editbox:SetHeight(20)
    editbox:SetPoint("TOPLEFT", money_input)
    editbox:SetNumeric(true)
    editbox:SetAutoFocus(false)
    editbox:SetMaxLetters(6)
    editbox:SetFontObject(ChatFontNormal)
    
    local left_border = money_input:CreateTexture(nil, "BACKGROUND")
    left_border:SetWidth(8)
    left_border:SetHeight(20)
    left_border:SetPoint("TOPLEFT", editbox, -5, 0)
    left_border:SetTexture([[Interface\Common\Common-Input-Border]])
    left_border:SetTexCoord(0, 0.0625, 0, 0.625)
    
    local right_border = money_input:CreateTexture(nil, "BACKGROUND")
    right_border:SetWidth(8)
    right_border:SetHeight(20)
    right_border:SetPoint("RIGHT", editbox, 0, 0)
    right_border:SetTexture([[Interface\Common\Common-Input-Border]])
    right_border:SetTexCoord(0.9375, 1.0, 0, 0.625)
    
    local middle_border = money_input:CreateTexture(nil, "BACKGROUND")
    middle_border:SetWidth(10)
    middle_border:SetHeight(20)
    middle_border:SetPoint("LEFT", left_border, "RIGHT")
    middle_border:SetPoint("RIGHT", right_border, "LEFT")
    middle_border:SetTexture([[Interface\Common\Common-Input-Border]])
    middle_border:SetTexCoord(0.0625, 0.9375, 0, 0.625)
    
    local icon = money_input:CreateTexture(nil, "BACKGROUND")
    money_input.gold_icon = icon
    icon:SetWidth(13)
    icon:SetHeight(13)
    icon:SetPoint("LEFT", editbox, "RIGHT", 2, 0)
    icon:SetTexture([[Interface\MoneyFrame\UI-MoneyIcons]])
    icon:SetTexCoord(0, 0.25, 0, 1)
  end
  
  do
    local editbox = CreateFrame("EditBox", nil, money_input)
    money_input.silver_editbox = editbox
    editbox:SetWidth(30)
    editbox:SetHeight(20)
    editbox:SetPoint("LEFT", money_input.gold_editbox, "RIGHT", 26, 0)
    editbox:SetNumeric(true)
    editbox:SetAutoFocus(false)
    editbox:SetMaxLetters(2)
    editbox:SetFontObject(ChatFontNormal)
    
    local left_border = money_input:CreateTexture(nil, "BACKGROUND")
    left_border:SetWidth(8)
    left_border:SetHeight(20)
    left_border:SetPoint("TOPLEFT", editbox, -5, 0)
    left_border:SetTexture([[Interface\Common\Common-Input-Border]])
    left_border:SetTexCoord(0, 0.0625, 0, 0.625)
    
    local right_border = money_input:CreateTexture(nil, "BACKGROUND")
    right_border:SetWidth(8)
    right_border:SetHeight(20)
    right_border:SetPoint("RIGHT", editbox, -10, 0)
    right_border:SetTexture([[Interface\Common\Common-Input-Border]])
    right_border:SetTexCoord(0.9375, 1.0, 0, 0.625)
    
    local middle_border = money_input:CreateTexture(nil, "BACKGROUND")
    middle_border:SetWidth(10)
    middle_border:SetHeight(20)
    middle_border:SetPoint("LEFT", left_border, "RIGHT")
    middle_border:SetPoint("RIGHT", right_border, "LEFT")
    middle_border:SetTexture([[Interface\Common\Common-Input-Border]])
    middle_border:SetTexCoord(0.0625, 0.9375, 0, 0.625)
    
    local icon = money_input:CreateTexture(nil, "BACKGROUND")
    money_input.silver_icon = icon
    icon:SetWidth(13)
    icon:SetHeight(13)
    icon:SetPoint("LEFT", editbox, "RIGHT", -8, 0)
    icon:SetTexture([[Interface\MoneyFrame\UI-MoneyIcons]])
    icon:SetTexCoord(0.25, 0.5, 0, 1)
  end

  do
    local editbox = CreateFrame("EditBox", nil, money_input)
    money_input.copper_editbox = editbox
    editbox:SetWidth(30)
    editbox:SetHeight(20)
    editbox:SetPoint("LEFT", money_input.silver_editbox, "RIGHT", 16, 0)
    editbox:SetNumeric(true)
    editbox:SetAutoFocus(false)
    editbox:SetMaxLetters(2)
    editbox:SetFontObject(ChatFontNormal)
    
    local left_border = money_input:CreateTexture(nil, "BACKGROUND")
    left_border:SetWidth(8)
    left_border:SetHeight(20)
    left_border:SetPoint("TOPLEFT", editbox, -5, 0)
    left_border:SetTexture([[Interface\Common\Common-Input-Border]])
    left_border:SetTexCoord(0, 0.0625, 0, 0.625)
    
    local right_border = money_input:CreateTexture(nil, "BACKGROUND")
    right_border:SetWidth(8)
    right_border:SetHeight(20)
    right_border:SetPoint("RIGHT", editbox, -10, 0)
    right_border:SetTexture([[Interface\Common\Common-Input-Border]])
    right_border:SetTexCoord(0.9375, 1.0, 0, 0.625)
    
    local middle_border = money_input:CreateTexture(nil, "BACKGROUND")
    middle_border:SetWidth(10)
    middle_border:SetHeight(20)
    middle_border:SetPoint("LEFT", left_border, "RIGHT")
    middle_border:SetPoint("RIGHT", right_border, "LEFT")
    middle_border:SetTexture([[Interface\Common\Common-Input-Border]])
    middle_border:SetTexCoord(0.0625, 0.9375, 0, 0.625)
    
    local icon = money_input:CreateTexture(nil, "BACKGROUND")
    money_input.copper_icon = icon
    icon:SetWidth(13)
    icon:SetHeight(13)
    icon:SetPoint("LEFT", editbox, "RIGHT", -8, 0)
    icon:SetTexture([[Interface\MoneyFrame\UI-MoneyIcons]])
    icon:SetTexCoord(0.5, 0.75, 0, 1)
  end
  
  money_input.gold_editbox:SetScript("OnTabPressed", function()
    if IsShiftKeyDown() and money_input.previousFocus then
      this:GetParent().previousFocus:SetFocus()
    else
      this:GetParent().silver_editbox:SetFocus()
    end
  end)
  money_input.gold_editbox:SetScript("OnEnterPressed", function()
    this:GetParent().silver_editbox:SetFocus()
  end)
  money_input.gold_editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  money_input.gold_editbox:SetScript("OnEditFocusLost", function()
    this.gotFocus = false
    this:HighlightText(0, 0)
  end)
  money_input.gold_editbox:SetScript("OnEditFocusGained", function()
    this.gotFocus = true
    this:HighlightText()
  end)
  function money_input.gold_editbox:hasFocus()
    return self.gotFocus
  end
  
  money_input.silver_editbox:SetScript("OnTabPressed", function()
    if IsShiftKeyDown() then
      this:GetParent().gold_editbox:SetFocus()
    else
      this:GetParent().copper_editbox:SetFocus()
    end
  end)
  money_input.silver_editbox:SetScript("OnEnterPressed", function()
    this:GetParent().copper_editbox:SetFocus()
  end)
  money_input.silver_editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  money_input.silver_editbox:SetScript("OnEditFocusLost", function()
    this.gotFocus = false
    this:HighlightText(0, 0)
  end)
  money_input.silver_editbox:SetScript("OnEditFocusGained", function()
    this.gotFocus = true
    this:HighlightText()
  end)
  function money_input.silver_editbox:hasFocus()
    return self.gotFocus
  end
  
  money_input.copper_editbox:SetScript("OnTabPressed", function()
    if IsShiftKeyDown() then
      this:GetParent().silver_editbox:SetFocus()
    else
      if this:GetParent().nextFocus then
        this:GetParent().nextFocus:SetFocus()
      else
        this:ClearFocus()
      end
    end
  end)
  money_input.copper_editbox:SetScript("OnEnterPressed", function()
    if this:GetParent().nextFocus then
      this:GetParent().nextFocus:SetFocus()
    else
      this:ClearFocus()
    end
  end)
  money_input.copper_editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  money_input.copper_editbox:SetScript("OnEditFocusLost", function()
    this.gotFocus = false
    this:HighlightText(0, 0)
  end)
  money_input.copper_editbox:SetScript("OnEditFocusGained", function()
    this.gotFocus = true
    this:HighlightText()
  end)
  function money_input.copper_editbox:hasFocus()
    return self.gotFocus
  end
  
  function money_input:hasFocus()
    return self.gold_editbox:hasFocus()
      or self.silver_editbox:hasFocus()
      or self.copper_editbox:hasFocus()
  end
  
  function money_input:clearFocus()
    self.gold_editbox:SetFocus()
    self.gold_editbox:ClearFocus()
  end
  
  function money_input:isEmpty()
    local gold_text = self.gold_editbox:GetText()
    local silver_text = self.silver_editbox:GetText()
    local copper_text = self.copper_editbox:GetText()
    return gold_text == "" and silver_text == "" and copper_text == ""
  end
  
  function money_input:getValue()
    local gold = self.gold_editbox:GetNumber()
    local silver = self.silver_editbox:GetNumber()
    local copper = self.copper_editbox:GetNumber()
    return gold, silver, copper
  end
  
  function money_input:setValue(value)
    if not value or value < 0 then value = 0 end
    local gold, silver, copper = util.unitMoney(value)
    self.gold_editbox:SetNumber(gold or 0)
    self.silver_editbox:SetNumber(silver or 0)
    self.copper_editbox:SetNumber(copper or 0)
  end
  
  return money_input
end

function M.moneyInputDialog(parent, id)
  parent = parent or UIParent
  local name = "$parentMoneyDialog"..(id or "")
  local money_dialog = CreateFrame("Frame", name, parent)
  money_dialog:SetWidth(159)
  money_dialog:SetHeight(86) 
  
  local texture = money_dialog:CreateTexture(nil, "BACKGROUND")
  money_dialog.background = texture
  texture:SetTexture([[Interface\MoneyFrame\UI-MoneyFrame2]])
  texture:SetPoint("TOPLEFT", money_dialog, -7, 3)
  
  money_dialog:SetPoint("CENTER", 0, 0)
  money_dialog:SetToplevel(true)
  money_dialog:EnableMouse(true)
  money_dialog:SetClampedToScreen(true)
  money_dialog:SetFrameStrata("DIALOG")
  money_dialog:Hide()
  
  local ok_button = CreateFrame("Button", nil, money_dialog, 
    "UIPanelButtonTemplate")
  money_dialog.ok_button = ok_button
  ok_button:SetWidth(64)
  ok_button:SetHeight(24)
  ok_button:SetPoint("RIGHT", money_dialog, "BOTTOM", -4, 24)
  ok_button:SetText("Okay")
  ok_button:SetScript("OnClick", function()
    PlaySound(sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  
  local cancel_button = CreateFrame("Button", nil, money_dialog, 
    "UIPanelButtonTemplate")
  money_dialog.cancel_button = cancel_button
  cancel_button:SetWidth(64)
  cancel_button:SetHeight(24)
  cancel_button:SetPoint("LEFT", money_dialog, "BOTTOM", 5, 24)
  cancel_button:SetText("Cancel")
  cancel_button:SetScript("OnClick", function()
    PlaySound(sounds.click)
    if this.onClick then 
      this:onClick()
    end
    this:GetParent():Hide()
  end)
  
  local money_input = moneyInput(money_dialog)
  money_input:SetPoint("TOPLEFT", money_dialog, 14, -20)
  
  return money_dialog
end

function M.editboxDialog(parent, id, title, width, editbox_width, max_letters)
  parent = parent or UIParent
  local name = "$parentEditBoxDialog"..(id or "")
  local frame = CreateFrame("Frame", name, parent)
  setSize(frame, width or 250, 100)
  setBackdropStyle(frame, nil, nil, 
      11, 12, 12, 11, 
      32, 32,
      [[Interface\DialogFrame\UI-DialogBox-Background]], 
      [[Interface\DialogFrame\UI-DialogBox-Border]])
  frame:SetPoint("CENTER", 0, 0)
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:CreateTitleRegion():SetAllPoints()
  
  local title_fontstring = frame:CreateFontString(nil, "ARTWORK",
    "GameFontNormal")
  title_fontstring:SetPoint("TOP", frame, 0, -15)
  title_fontstring:SetText(title or "")
  
  local editbox = CreateFrame("EditBox", "$parentEditBox", frame)
  frame.editbox = editbox
  editbox:SetPoint("TOP", title_fontstring, "BOTTOM", 0, -5)
  editbox:SetAutoFocus(false)
  editbox:SetHeight(24)
  editbox:SetWidth(editbox_width or 200)
  editbox:SetFontObject(GameFontHighlight)
  editbox:SetMaxLetters(max_letters or 42)
  do
    local content = palette.color.backdrop.content
    setBackdropStyle(editbox, content.background, content.border,
      nil, nil, nil, nil, 1.5, 8, 
      [[Interface\Buttons\WHITE8X8]],
      [[Interface\Buttons\WHITE8X8]])
  end
  editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  editbox:SetScript("OnEnterPressed", function() 
    PlaySound(sounds.click)
    this:ClearFocus()
    if this.onEnterPressed then
      this:onEnterPressed()
    end
  end)
  
  local editbox_border = CreateFrame("Frame", nil, editbox)
  editbox.border = editbox_border
  editbox_border:SetPoint("TOPLEFT", editbox, -5, 3)
  editbox_border:SetPoint("BOTTOMRIGHT", editbox, 5, -3)
  editbox_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  
  local ok_button = button(frame, nil, 100, 24, OKAY)
  frame.ok_button = ok_button
  ok_button:SetPoint("TOPLEFT", editbox, "BOTTOMLEFT", -4, -5)
  ok_button:SetScript("OnClick", function()
    PlaySound(sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  
  local ok_button_label = ok_button:CreateFontString()
  ok_button.label = ok_button_label
  ok_button_label:SetFontObject(GameFontNormal)
  ok_button_label:SetAllPoints(ok_button)
  ok_button_label:SetText(OKAY)
  ok_button_label:SetJustifyH("CENTER")
  ok_button_label:SetJustifyV("CENTER")
  ok_button:SetFontString(ok_button_label)
  
  local cancel_button = button(frame, nil, 100, 24, CANCEL)
  frame.cancel_button = cancel_button
  cancel_button:SetPoint("TOPRIGHT", editbox, "BOTTOMRIGHT", 4, -5)
  cancel_button:SetScript("OnClick", function()
    PlaySound(sounds.click)
    if this.onClick then 
      this:onClick()
    end
    this:GetParent():Hide()
  end)
  
  local cancel_button_label = cancel_button:CreateFontString()
  cancel_button.label = cancel_button_label
  cancel_button_label:SetFontObject(GameFontNormal)
  cancel_button_label:SetAllPoints(cancel_button)
  cancel_button_label:SetText(CANCEL)
  cancel_button_label:SetJustifyH("CENTER")
  cancel_button_label:SetJustifyV("CENTER")
  cancel_button:SetFontString(cancel_button_label)
  
  return frame
end