local A = FonzAppraiser
local L = A.locale

A.module 'fa.gui.sessions'

local util = A.require 'util.money'

local session = A.require 'fa.session'
local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local main = A.require 'fa.gui.main'

do
  local main_frame = main.frame
  local sessions = CreateFrame("Frame", "$parentSessions", main_frame)
  M.sessions = sessions
  main_frame:addTabChild(sessions)
  sessions:SetPoint("TOPLEFT", main_frame, 11, -32)
  sessions:SetPoint("BOTTOMRIGHT", main_frame, -12, 12)
  sessions:Hide()
  sessions:SetScript("OnShow", sessions_OnShow)
  sessions.scrollFrameFauxUpdate = scrollFrameFauxUpdate
  sessions.update = update
end

do
  local scroll_frame = CreateFrame("ScrollFrame", "$parentScrollFrame", 
    sessions, "FauxScrollFrameTemplate")
  M.scroll_frame = scroll_frame
  scroll_frame:SetHeight(89)
  scroll_frame:SetPoint("TOPLEFT", sessions, 2, -10)
  scroll_frame:SetPoint("RIGHT", sessions, 0, 0)

  --WORKAROUND(@fondlez): Blizzard's FauxScrollFrame_Update() calls Hide() on
  --the scroll frame if info.data_size is less than info.display_size.
  --This is inconvenient if the scroll_frame is also used for cosmetics.
  --A static cosmetic wrapper frame seems cheaper than Show() calls after every
  --scroll frame update.
  local scroll_frame_border = CreateFrame("Frame", "$parentScrollFrameBorder",
    sessions)
  scroll_frame_border:SetAllPoints(scroll_frame)
	scroll_frame_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  
  -- Nest the scrollbar/slider inside the scroll frame instead of default space.
  -- Global name resolution is used by Blizzard code.
  scroll_frame.slider = _G[scroll_frame:GetName().."ScrollBar"]
  scroll_frame.slider:SetPoint("TOPLEFT", scroll_frame, "TOPRIGHT", -21, -21)
  scroll_frame.slider:SetPoint("BOTTOMLEFT", scroll_frame, 
    "BOTTOMRIGHT", -21, 20)
  scroll_frame.slider.reset = function(self)
    self:SetValue(self:GetMinMaxValues())
  end
  
  local parent = scroll_frame:GetParent()
  parent["sframe1"] = {}
  parent["sframe1"].object = scroll_frame
  parent["sframe1"].max_size = 10
  parent["sframe1"].data_size = parent["sframe1"].max_size
  parent["sframe1"].display_size = 5
  parent["sframe1"].entry_height = 16
  parent["sframe1"].entries = {}
  parent["sframe1"].checked = {}
  gui.makeCheckButtonRows(scroll_frame, "sframe1", 6, -15, -21, "LEFT", 
    renameOnClick, checkOnClick, updateSession_OnEnter, clearSession_OnLeave)
  
  scroll_frame:SetScript("OnVerticalScroll", scrollFrame_OnVerticalScroll)
  scroll_frame.update = updateScrollFrame
end

do
  local selectall = gui.checkbox(sessions)
  M.selectall_checkbox = selectall
  selectall:SetPoint("TOPLEFT", scroll_frame, "BOTTOMLEFT", 4, 0)
  selectall:SetScript("OnClick", function()
    selectallOnClick(this, "sframe1")
  end)
  selectall.update = function(self)
    updateSelectAllCheckbox(self, "sframe1")
  end
end

do
  local button = gui.button(sessions, nil, nil, nil, L["Delete"])
  M.delete_selected = button
  button:SetPoint("LEFT", selectall_checkbox, "RIGHT", 0, 0)
  button:SetScript("OnEnter", deletedSelected_OnEnter)
  button:SetScript("OnLeave", deletedSelected_OnLeave)
  button.onClick = function(self)
    deleteSelectedOnClick(self, scroll_frame, "sframe1")
  end
end

do
  local button = gui.button(sessions, nil, nil, nil, L["Purge"])
  M.purge_all = button
  button:SetPoint("TOPRIGHT", scroll_frame, "BOTTOMRIGHT", -1, 0)
  button:SetScript("OnEnter", purgeAll_OnEnter)
  button:SetScript("OnLeave", purgeAll_OnLeave)
  
  local name = A.name .. "_PurgeAllSessions"
  M.purgeall_confirm_dialog_name = name
  
  StaticPopupDialogs[name] = {
    text = L["Delete ALL Sessions: are you sure?"],
    button1 = TEXT(YES),
    button2 = TEXT(NO),
    OnAccept = function()
      purgeAllOnClick(button, scroll_frame, "sframe1")
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
  }
  
  button.onClick = purgeAllConfirmOnClick
end

do    
  local text_frame = CreateFrame("Frame", "$parentTextFrame", sessions)
  M.text_frame = text_frame
  text_frame:SetPoint("TOPLEFT", sessions, 0, -130)
  text_frame:SetPoint("BOTTOMRIGHT", sessions, 0, 5)
  
  do
    local name_button = CreateFrame("Button", "$parentNameButton", text_frame)
    M.name_button = name_button
    text_frame.name = name_button
    name_button:Enable()
    name_button:SetPoint("TOPLEFT", text_frame, 4, -8)
    name_button:SetWidth(250)
    name_button:SetHeight(12)
    
    local name_text = name_button:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    name_text:SetPoint("TOPLEFT", name_button, 2, 0)
    name_text:SetPoint("BOTTOMRIGHT", name_button, 0, 0)
    name_text:SetJustifyH("LEFT")
    
    name_button:SetFontString(name_text)
    name_button.update = updateNameButton
  end
  
  do
    local duration_text = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontNormalSmall")
    M.duration_text = duration_text
    text_frame.duration = duration_text
    duration_text:SetPoint("TOPRIGHT", text_frame, -2, -8)
    duration_text.update = updateDurationText
    
    local duration_animation = CreateFrame("Frame", nil, text_frame)
    text_frame.duration_animation = duration_animation
    duration_animation.interval = 1.0
    duration_animation:Hide()
    duration_animation:SetScript("OnUpdate", durationAnimation_OnUpdate)
  end
  
  do
    local total_label = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontNormalSmall")
    text_frame.total_label = total_label
    total_label:SetPoint("TOPLEFT", name_button, "BOTTOMLEFT", 0, -3)
    total_label:SetText(L["Session Value:"])
    M.total_label = total_label
    
    local total_value = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    M.total_value = total_value
    text_frame.total_value = total_value
    total_value:SetPoint("TOPRIGHT", duration_text, "BOTTOMRIGHT", 0, -3)
    total_value:SetJustifyH("RIGHT")
    total_value.updateDisplay = function(self, value)
      value = value and util.formatMoneyFull(value, true, nil, true) 
        or "-"
      self:SetText(value)
    end
    total_value.update = updateTotalValue
  end
  
  do
    local gph_value = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    M.gph_value = gph_value
    text_frame.gph_value = gph_value
    gph_value:SetPoint("TOPRIGHT", total_value, "TOPLEFT", 0, 0)
    gph_value:SetJustifyH("CENTER")
    gph_value.updateDisplay = function(self, value)
      if value then
        self:SetText(string.format(L["(%s / hour) "], 
          util.formatMoneyFull(value, true, nil, true)))
      else
        self:SetText("")
      end
    end
  end
  
  do
    local currency_label = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontNormalSmall")
    text_frame.currency_label = currency_label
    currency_label:SetPoint("TOPLEFT", total_label, "BOTTOMLEFT", 0, -3)
    currency_label:SetText(L["Currency:"])
    M.currency_label = currency_label
    
    local currency_value = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    M.currency_value = currency_value
    text_frame.currency_value = currency_value
    currency_value:SetPoint("TOPRIGHT", total_value, "BOTTOMRIGHT", 0, -3)
    currency_value:SetJustifyH("RIGHT")
    currency_value.updateDisplay = function(self, value)
      value = value and util.formatMoneyFull(value, true, nil, true) 
        or "-"
      self:SetText(value)
    end
    currency_value.update = updateCurrencyValue
  end
  
  do
    local items_text = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontNormalSmall")
    M.items_text = items_text
    text_frame.items_text = items_text
    items_text:SetPoint("TOPLEFT", currency_label, "BOTTOMLEFT", 0, -3)
    items_text.updateDisplay = function(self, items_count)
      self:SetText(string.format(L["All Items [%s]:"], 
        items_count and palette.color.white(items_count) or ""))
    end
    items_text.update = updateItemsText
    
    local items_value = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    M.items_value = items_value
    text_frame.items_value = items_value
    items_value:SetPoint("TOPRIGHT", currency_value, "BOTTOMRIGHT", 0, -3)
    items_value:SetJustifyH("RIGHT")
    items_value.updateDisplay = function(self, value)
      value = value and util.formatMoneyFull(value, true, nil, true) 
        or "-"
      self:SetText(value)
    end
    items_value.update = updateItemsValue
  end
  
  do
    local hot_count = 1000
    
    local hot_text = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    M.hot_text = hot_text
    text_frame.hot_text = hot_text
    hot_text:SetPoint("TOPLEFT", items_text, "BOTTOMLEFT", 0, -3)
    hot_text.updateDisplay = function(self, hot_count)
      self:SetText(string.format(L["Hot Items [%s]:"], 
        hot_count and palette.color.white(hot_count) or ""))
    end
    hot_text.update = updateHotText
    
    local hot_value = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    M.hot_value = hot_value
    text_frame.hot_value = hot_value
    hot_value:SetPoint("TOPRIGHT", items_value, "BOTTOMRIGHT", 0, -3)
    hot_value:SetJustifyH("RIGHT")
    hot_value.updateDisplay = function(self, value)
      value = value and util.formatMoneyFull(value, true, nil, true) 
        or "-"
      self:SetText(value)
    end
    hot_value.update = updateHotValue
  end
  
  local most_valued_title = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontNormalSmall")
  most_valued_title:SetPoint("BOTTOM", text_frame, 0, 24)
  most_valued_title:SetText(L["Most Valuable Item"])
  
  local most_valued_text = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
  M.most_valued = most_valued_text
  most_valued_text:SetPoint("TOP", most_valued_title, "BOTTOM", 0, -5)
  most_valued_text.update = updateMostValuable
end