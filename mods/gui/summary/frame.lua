local A = FonzAppraiser
local L = A.locale

A.module 'fa.gui.summary'

local util = A.require 'util.money'

local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local main = A.require 'fa.gui.main'

do
  local main_frame = main.frame
  local summary = CreateFrame("Frame", "$parentSummary", main_frame)
  M.summary = summary
  main_frame:addTabChild(summary)
  summary:SetPoint("TOPLEFT", main_frame, 11, -32)
  summary:SetPoint("BOTTOMRIGHT", main_frame, -12, 12)
  summary.scrollFrameFauxUpdate = scrollFrameFauxUpdate
  summary:SetScript("OnShow", summary_OnShow)
  summary.update = update
end

do
  local scroll_frame = CreateFrame("ScrollFrame", "$parentScrollFrame", summary,
    "FauxScrollFrameTemplate")
  M.scroll_frame = scroll_frame
  scroll_frame:SetHeight(105)
  scroll_frame:SetPoint("TOPLEFT", summary, 2, -10)
  scroll_frame:SetPoint("RIGHT", summary, 0, 0)

  --WORKAROUND(@fondlez): Blizzard's FauxScrollFrame_Update() calls Hide() on
  --the scroll frame if info.data_size is less than info.display_size.
  --This is inconvenient if the scroll_frame is also used for cosmetics.
  --A static cosmetic wrapper frame seems cheaper than Show() calls after every
  --scroll frame update.
  local scroll_frame_border = CreateFrame("Frame", "$parentScrollFrameBorder",
    summary)
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
  parent["sframe1"].max_size = 100
  parent["sframe1"].data_size = parent["sframe1"].max_size
  parent["sframe1"].display_size = 6
  parent["sframe1"].entry_height = 16
  parent["sframe1"].entries = {}
  gui.makeOneColTextRows(scroll_frame, "sframe1", 6, -15, -21)
  
  scroll_frame:SetScript("OnVerticalScroll", scrollFrame_OnVerticalScroll)
  scroll_frame.update = updateScrollFrame
end

do    
  local text_frame = CreateFrame("Frame", "$parentTextFrame", summary)
  M.text_frame = text_frame
  text_frame:SetPoint("TOPLEFT", summary, 0, -110)
  text_frame:SetPoint("BOTTOMRIGHT", summary, 0, 30)
  
  do
    local name_button = CreateFrame("Button", "$parentNameButton", text_frame)
    M.name_button = name_button
    text_frame.name = name_button
    name_button:SetWidth(250)
    name_button:SetHeight(12)
    name_button:SetPoint("TOPLEFT", text_frame, 4, -8)
    
    local name_text = name_button:CreateFontString()
    name_text:SetFontObject(GameFontHighlightSmall)
    name_text:SetAllPoints(name_button)
    name_text:SetJustifyH("LEFT")
    name_text:SetJustifyV("CENTER")
    name_button:SetFontString(name_text)
    
    name_button.update = updateNameButton
    name_button:Enable()
    name_button:SetScript("OnClick", nameButton_OnClick)
    name_button:SetScript("OnEnter", nameButtonTooltip_OnEnter)
    name_button:SetScript("OnLeave", nameButtonTooltip_OnLeave)
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
    
    local label_tooltip_frame = CreateFrame("Frame", nil, text_frame)
    label_tooltip_frame:EnableMouse(true)
    label_tooltip_frame:SetAllPoints(currency_label)
    label_tooltip_frame:SetScript("OnEnter", currencyLabelTooltip_OnEnter)
    label_tooltip_frame:SetScript("OnLeave", currencyLabelTooltip_OnLeave)
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
    
    local hot_tooltip_frame = CreateFrame("Frame", nil, text_frame)
    hot_tooltip_frame:EnableMouse(true)
    hot_tooltip_frame:SetAllPoints(hot_text)
    hot_tooltip_frame:SetScript("OnEnter", hotItemTooltip_OnEnter)
    hot_tooltip_frame:SetScript("OnLeave", hotItemTooltip_OnLeave)
  end
  
  do  
    local start_button = gui.button(text_frame, nil, 100, 24, "Start Session")
    M.start_button = start_button
    text_frame.start_button = start_button
    start_button:SetPoint("TOPLEFT", hot_text, 0, -14)
    start_button:SetScript("OnClick", startButton_ConfirmOnClick)
    start_button.update = updateStartButton
    
    local stop_button = gui.button(text_frame, nil, 100, 24, "Stop Session")
    M.stop_button = stop_button
    text_frame.stop_button = stop_button
    stop_button:SetPoint("TOPRIGHT", hot_value, 0, -14)
    stop_button:SetScript("OnClick", stopButton_OnClick)
    stop_button.update = updateStopButton
  end
  
  do
    local target_label = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontNormalSmall")
    M.target_label = target_label
    text_frame.target_label = target_label
    target_label:SetPoint("BOTTOMLEFT", text_frame, "BOTTOMLEFT", 4, 0)
    target_label:SetText(L["Target:"])
    
    local target_value = text_frame:CreateFontString(nil, "ARTWORK",
      "GameFontHighlightSmall")
    M.target_value = target_value
    text_frame.target_value = target_value
    target_value:SetPoint("BOTTOMRIGHT", text_frame, "BOTTOMRIGHT", -3, 0)
    target_value:SetJustifyH("RIGHT")
    target_value.updateDisplay = function(self, value, goal)
      if goal and goal > 0 then
        goal = util.formatMoneyFull(goal, true)
        value = value and util.formatMoneyFull(value, true) or "-"
        self:SetText(string.format("%s / %s", value, goal))
      else
        self:SetText(NONE)
      end
    end
    target_value.update = updateTargetValue
  end
end

do
  local progress_bar = CreateFrame("StatusBar", "$parentProgressBar", summary)
  M.progress_bar = progress_bar
  progress_bar:SetHeight(16)
  progress_bar:SetPoint("TOPLEFT", text_frame, "BOTTOMLEFT", 0, -3)
  progress_bar:SetPoint("BOTTOMRIGHT", summary)
  progress_bar:SetBackdrop{
		tile = false,
    bgFile = A.addon_path .. [[\img\statusbar\Fifths]],
		edgeSize = 16,
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
    insets={ left=3, right=3, top=3, bottom=3 },
	}
  local r, g, b, a = progress_bar:GetBackdropColor()
  progress_bar:SetBackdropColor(palette.color.nero3())
  progress_bar.border_color = palette.color.transparent
  progress_bar:SetBackdropBorderColor(progress_bar.border_color())
  
  progress_bar:SetStatusBarTexture(A.addon_path
    .. [[\img\statusbar\UI-Achievement-Parchment-Horizontal]])
  local background = progress_bar:GetStatusBarTexture()
  background:SetDrawLayer("BORDER")
  background:ClearAllPoints()
  -- Be aware that StatusBar:GetWidth() returns the underlying texture 
  -- dimensions, not its dynamic cropped "fill" version within the status bar.
  -- Also, changes to its anchors affects the fill width for OnValueChanged
  -- calculations.
  local background_left_offset, background_right_offset = 5, -5
  background:SetPoint("TOPLEFT", background_left_offset, -5)
  background:SetPoint("BOTTOMRIGHT", background_right_offset, 5)
  progress_bar.background = background
  progress_bar.background.width = progress_bar:GetWidth()
    - background_left_offset + background_right_offset
  
  local fill_text = progress_bar:CreateFontString()
  progress_bar.fill_text = fill_text
  fill_text:SetFont(A.addon_path .. [[\font\FuturaBold.ttf]], 10)
  fill_text:SetPoint("RIGHT", background)
  
  do
    local spark = progress_bar:CreateTexture(nil, "OVERLAY")
    progress_bar.spark = spark
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    -- Scaling factor is a manual fudge to align spark glowy edges with bar
    spark:SetHeight(progress_bar:GetHeight()*2.2) 
    spark:SetBlendMode("ADD")
    spark:Hide()
  end
  
  do
    local glow = progress_bar:CreateTexture(nil, "OVERLAY")
    progress_bar.glow = glow
    glow:SetPoint("TOPLEFT", progress_bar, -8, 4)
    glow:SetPoint("BOTTOMRIGHT", progress_bar, 6, -4)
    glow:SetTexture(A.addon_path 
      .. [[\img\statusbar\UI-Achievement-Alert-Glow]])
    glow:SetBlendMode("ADD")
    --Manually obtained by examining texture and fitting relevant edges
    --based on its own dimensions, e.g. 30px from left out of 512px.
    --This section contains the border glow only.
    glow:SetTexCoord(30/512, 370/512, 26/256, 144/256)
    glow:SetAlpha(0)
    
    local glow_animation = CreateFrame("Frame", nil, progress_bar)
    progress_bar.glow_animation = glow_animation
    glow_animation:Hide()
    glow_animation:SetScript("OnUpdate", glowAnimation_OnUpdate)
    glow_animation.play = playGlowAnimation
  end
  
  do
    local shine = progress_bar:CreateTexture(nil, "ARTWORK")
    progress_bar.shine = shine
    shine:SetPoint("TOPLEFT", progress_bar, 8, -3)
    --Use the normalized width of the sparkle section and a height rescaled with
    --the same aspect ratio as original section.
    shine:SetWidth(58/512 * progress_bar:GetWidth()*1.1)
    shine:SetHeight(71/58 * progress_bar:GetHeight()*1.1)
    shine:SetTexture(A.addon_path
      .. [[\img\statusbar\UI-Achievement-Alert-Glow]])
    shine:SetBlendMode("ADD")
    --Manually obtained by examining texture and fitting relevant edges
    --based on its own dimensions, e.g. 30px from left out of 512px.
    --This section contains the sparkle only.
    shine:SetTexCoord(405/512, 463/512, 0, 71/256)
    shine:SetAlpha(0)
    
		local shine_animation = CreateFrame("Frame", nil, progress_bar)
    progress_bar.shine_animation = shine_animation
		shine_animation:Hide()
		shine_animation:SetScript("OnUpdate", shineAnimation_OnUpdate)
    shine_animation.play = playShineAnimation
  end
  
  progress_bar:SetScript("OnShow", progressBar_OnShow)
  progress_bar:EnableMouse(true)
  progress_bar:SetScript("OnMouseUp", progressBar_OnClick)
  progress_bar:SetScript("OnEnter", progressBar_OnEnter)
  progress_bar:SetScript("OnLeave", progressBar_OnLeave)
  progress_bar.update = updateProgressBar
end