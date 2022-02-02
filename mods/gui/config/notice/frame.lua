local A = FonzAppraiser

A.module 'fa.notice'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local config = A.require 'fa.gui.config'

do
  local config_frame = config.frame
  local name = config_frame:GetName().."Notice"
  local notice = CreateFrame("Frame", name, config_frame)
  M.notice = notice
  config_frame:addTabChild(notice)
  notice:SetPoint("TOPLEFT", config_frame, 11, -42)
  notice:SetPoint("BOTTOMRIGHT", config_frame, -12, 2)
  notice:SetScript("OnShow", notice_OnShow)
  notice.update = update
end

do
  local checkbox = gui.checkbox(notice)
  checkbox:SetPoint("TOPLEFT", 3, 5)
  M.enable_checkbox = checkbox
  checkbox.onClick = enableCheckboxOnClick
  checkbox.update = updateEnableCheckbox
  
  local fontstring = checkbox:CreateFontString()
  fontstring:SetFontObject(GameFontNormal)
  fontstring:SetText(L["Enable chat output"])
  fontstring:SetPoint("TOPLEFT", checkbox, 25, 0)
  fontstring:SetJustifyH("LEFT")
  fontstring:SetJustifyV("CENTER")
  fontstring:SetHeight(checkbox:GetHeight())
end

do
  local checkbox = gui.checkbox(notice)
  checkbox:SetPoint("TOPRIGHT", 0, 5)
  M.soulbound_checkbox = checkbox
  checkbox.onClick = soulboundCheckBoxOnClick
  checkbox.update = updateSoulboundCheckbox
  
  local fontstring = checkbox:CreateFontString()
  fontstring:SetFontObject(GameFontNormal)
  fontstring:SetText(L["Ignore soulbound items"])
  fontstring:SetPoint("TOPRIGHT", checkbox, -25, 0)
  fontstring:SetJustifyH("RIGHT")
  fontstring:SetJustifyV("CENTER")
  fontstring:SetHeight(checkbox:GetHeight())
end

do
  local item_frame = CreateFrame("Frame", "$parentItem", notice)
  M.item_frame = item_frame
  item_frame:SetPoint("TOPLEFT", notice, 2, -18)
  item_frame:SetPoint("TOPRIGHT", notice, 2, -18)
  item_frame:SetHeight(100)
  
  local title = item_frame:CreateFontString()
  title:SetFontObject(GameFontHighlight)
  title:SetText(L["Item"])
  title:SetPoint("TOPLEFT", item_frame, 2, 0)
  title:SetHeight(20)
  
  local notice_label = CreateFrame("Frame", nil, item_frame)
  notice_label:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 9, -7)
  notice_label:SetWidth(28)
  notice_label:SetHeight(11)
  notice_label:EnableMouse()
  notice_label:SetScript("OnEnter", noticeLabel_OnEnter)
  notice_label:SetScript("OnLeave", noticeLabel_OnLeave)
  
  local notice_label_text = notice_label:CreateFontString()
  notice_label_text:SetAllPoints(notice_label)
  notice_label_text:SetFontObject(GameFontNormalSmall)
  notice_label_text:SetText(L["Min:"])
  notice_label_text:SetJustifyH("CENTER")
  notice_label_text:SetJustifyV("CENTER")
  
  local notice_input = gui.moneyInput(item_frame, nil, 225, 47)
  item_frame.notice_input = notice_input
  notice_input:SetPoint("LEFT", notice_label, "RIGHT", 10, 0)
  notice_input.update = function(self)
    inputUpdate(self, "item")
  end
  
  local notice_input_border = CreateFrame("Frame", nil, notice_input)
  item_frame.notice_input.border = notice_input_border
  notice_input_border:SetPoint("TOPLEFT", notice_label, "TOPRIGHT", 2, 6)
  notice_input_border:SetWidth(170)
  notice_input_border:SetHeight(25)
  notice_input_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  
  local notice_ok_button = CreateFrame("Button", nil, item_frame, 
    "UIPanelButtonTemplate")
  item_frame.notice_ok_button = notice_ok_button
  notice_ok_button:SetWidth(64)
  notice_ok_button:SetHeight(24)
  notice_ok_button:SetPoint("BOTTOMLEFT", notice_input, "BOTTOMRIGHT", -64, -3)
  notice_ok_button:SetText(L["Okay"])
  notice_ok_button:SetScript("OnClick", function()
    PlaySound(gui.sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  notice_ok_button.input = notice_input
  notice_ok_button.onClick = function(self)
    noticeOkButtonOnClick(self, "item")
  end
  
  local notice_clear_button = CreateFrame("Button", nil, item_frame, 
    "UIPanelButtonTemplate")
  item_frame.notice_clear_button = notice_clear_button
  notice_clear_button:SetWidth(64)
  notice_clear_button:SetHeight(24)
  notice_clear_button:SetPoint("LEFT", notice_ok_button, "RIGHT")
  notice_clear_button:SetText(L["Clear"])
  notice_clear_button:SetScript("OnClick", function()
    PlaySound(gui.sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  notice_clear_button.input = notice_input
  notice_clear_button.onClick = function(self)
    noticeClearButtonOnClick(self, "item")
  end

  local notify_label = CreateFrame("Frame", nil, item_frame)
  notify_label:SetPoint("TOPRIGHT", notice_label, "BOTTOMRIGHT", 0, -15)
  notify_label:SetWidth(38)
  notify_label:SetHeight(11)
  notify_label:EnableMouse()
  notify_label:SetScript("OnEnter", notifyLabel_OnEnter)
  notify_label:SetScript("OnLeave", notifyLabel_OnLeave)
  
  local notify_label_text = notify_label:CreateFontString()
  notify_label_text:SetAllPoints(notify_label)
  notify_label_text:SetFontObject(GameFontNormalSmall)
  notify_label_text:SetText(L["Notify:"])
  notify_label_text:SetJustifyH("CENTER")
  notify_label_text:SetJustifyV("CENTER")
  
  local notifier_dropdown = gui.dropdown(item_frame)
  item_frame.notifier_dropdown = notifier_dropdown
  notifier_dropdown:ClearAllPoints()
  notifier_dropdown:SetPoint("TOPLEFT", notice_input, "BOTTOMLEFT", -24, -4)
  UIDropDownMenu_SetWidth(50, notifier_dropdown)
  UIDropDownMenu_SetButtonWidth(50, notifier_dropdown)
  UIDropDownMenu_JustifyText("LEFT", notifier_dropdown)
  notifier_dropdown:SetScript("OnShow", function()
    UIDropDownMenu_Initialize(this, itemNotifierDropdown_Initialize)
  end)
  notifier_dropdown.update = updateNotifierDropdown
  notifier_dropdown.reset = nil
  
  local resource_dropdown = gui.dropdown(item_frame)
  item_frame.resource_dropdown = resource_dropdown
  resource_dropdown:ClearAllPoints()
  resource_dropdown:SetPoint("TOPLEFT", notifier_dropdown, 
    "TOPRIGHT", -30, 0)
  UIDropDownMenu_SetWidth(211, resource_dropdown)
  UIDropDownMenu_SetButtonWidth(211, resource_dropdown)
  UIDropDownMenu_JustifyText("LEFT", resource_dropdown)
  resource_dropdown:SetScript("OnShow", function()
      UIDropDownMenu_Initialize(this, itemResourceDropdown_Initialize)
  end)
  resource_dropdown.update = updateResourceDropdown
  resource_dropdown.reset = nil
  
  local notify_editbox = CreateFrame("EditBox", nil, item_frame)
  item_frame.notify_editbox = notify_editbox
  notify_editbox:SetPoint("TOPLEFT", notifier_dropdown, "BOTTOMLEFT", 21, 0)
  notify_editbox:SetAutoFocus(false)
  notify_editbox:SetHeight(24)
  notify_editbox:SetWidth(290)
  notify_editbox:SetFontObject(GameFontHighlight)
  do
    local content = palette.color.backdrop.content
    gui.setBackdropStyle(notify_editbox, content.background, content.border,
      nil, nil, nil, nil, 1.5, 8, 
      [[Interface\Buttons\WHITE8X8]],
      [[Interface\Buttons\WHITE8X8]])
  end
  notify_editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  notify_editbox:SetScript("OnEnterPressed", function() 
    this:ClearFocus()
    if this.onEnterPressed then
      this:onEnterPressed()
    end
  end)
  notify_editbox.onEnterPressed = itemEditboxOnEnterPressed
  notify_editbox:SetScript("OnEnter", function()
    notifyEditboxOnEnter(this, notifier_dropdown)
  end)
  notify_editbox:SetScript("OnLeave", function()
    notifyEditboxOnLeave(this, notifier_dropdown)
  end)
  notify_editbox.update = updateItemEditbox
  
  local notify_editbox_border = CreateFrame("Frame", nil, notify_editbox)
  item_frame.notify_editbox.border = notify_editbox_border
  notify_editbox_border:SetPoint("TOPLEFT", notify_editbox, -5, 3)
  notify_editbox_border:SetPoint("BOTTOMRIGHT", notify_editbox, 5, -3)
  notify_editbox_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }

  local none_button = gui.imgButton(item_frame, nil, 16, 16, 
    A.addon_path .. [[\img\trash]], "ADD", 0.5, 1.0, 0.5)
  none_button:SetPoint("RIGHT", notify_editbox, "LEFT", -6, 0)
  none_button.onClick = function()
    itemEditboxOnEnterPressed(notify_editbox, NONE)
  end
  none_button.tooltipOn = noneButtonTooltipOnEnter
  none_button.tooltipOff = noneButtonTooltipOnLeave
  
  local defaults_button = gui.imgButton(item_frame, nil, 16, 16, 
    A.addon_path .. [[\img\reload]], "ADD", 0.5, 1.0, 0.5)
  defaults_button:SetPoint("RIGHT", none_button, "LEFT", -4, 0)
  defaults_button.onClick = function()
    itemEditboxOnEnterPressed(notify_editbox, DEFAULTS)
  end
  defaults_button.tooltipOn = defaultsButtonTooltipOnEnter
  defaults_button.tooltipOff = defaultsButtonTooltipOnLeave
end

do
  local money_frame = CreateFrame("Frame", "$parentMoney", notice)
  M.money_frame = money_frame
  money_frame:SetPoint("TOPLEFT", item_frame, "BOTTOMLEFT", 0, -10)
  money_frame:SetPoint("TOPRIGHT", item_frame, "BOTTOMRIGHT")
  money_frame:SetHeight(100)
  
  local title = money_frame:CreateFontString()
  title:SetFontObject(GameFontHighlight)
  title:SetText(L["Money"])
  title:SetPoint("TOPLEFT", money_frame, 2, 0)
  title:SetHeight(20)
  
  local notice_label = CreateFrame("Frame", nil, money_frame)
  notice_label:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 9, -7)
  notice_label:SetWidth(28)
  notice_label:SetHeight(11)
  notice_label:EnableMouse()
  notice_label:SetScript("OnEnter", noticeLabel_OnEnter)
  notice_label:SetScript("OnLeave", noticeLabel_OnLeave)
  
  local notice_label_text = notice_label:CreateFontString()
  notice_label_text:SetAllPoints(notice_label)
  notice_label_text:SetFontObject(GameFontNormalSmall)
  notice_label_text:SetText(L["Min:"])
  notice_label_text:SetJustifyH("CENTER")
  notice_label_text:SetJustifyV("CENTER")
  
  local notice_input = gui.moneyInput(money_frame, nil, 225, 47)
  money_frame.notice_input = notice_input
  notice_input:SetPoint("LEFT", notice_label, "RIGHT", 10, 0)
  notice_input.update = function(self)
    inputUpdate(self, "money")
  end
  
  local notice_input_border = CreateFrame("Frame", nil, notice_input)
  money_frame.notice_input.border = notice_input_border
  notice_input_border:SetPoint("TOPLEFT", notice_label, "TOPRIGHT", 2, 6)
  notice_input_border:SetWidth(170)
  notice_input_border:SetHeight(25)
  notice_input_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  
  local notice_ok_button = CreateFrame("Button", nil, money_frame, 
    "UIPanelButtonTemplate")
  money_frame.notice_ok_button = notice_ok_button
  notice_ok_button:SetWidth(64)
  notice_ok_button:SetHeight(24)
  notice_ok_button:SetPoint("BOTTOMLEFT", notice_input, "BOTTOMRIGHT", -64, -3)
  notice_ok_button:SetText(L["Okay"])
  notice_ok_button:SetScript("OnClick", function()
    PlaySound(gui.sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  notice_ok_button.input = notice_input
  notice_ok_button.onClick = function(self)
    noticeOkButtonOnClick(self, "money")
  end
  
  local notice_clear_button = CreateFrame("Button", nil, money_frame, 
    "UIPanelButtonTemplate")
  money_frame.notice_clear_button = notice_clear_button
  notice_clear_button:SetWidth(64)
  notice_clear_button:SetHeight(24)
  notice_clear_button:SetPoint("LEFT", notice_ok_button, "RIGHT")
  notice_clear_button:SetText(L["Clear"])
  notice_clear_button:SetScript("OnClick", function()
    PlaySound(gui.sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  notice_clear_button.input = notice_input
  notice_clear_button.onClick = function(self)
    noticeClearButtonOnClick(self, "money")
  end
  
  local notify_label = CreateFrame("Frame", nil, money_frame)
  notify_label:SetPoint("TOPRIGHT", notice_label, "BOTTOMRIGHT", 0, -15)
  notify_label:SetWidth(38)
  notify_label:SetHeight(11)
  notify_label:EnableMouse()
  notify_label:SetScript("OnEnter", notifyLabel_OnEnter)
  notify_label:SetScript("OnLeave", notifyLabel_OnLeave)
  
  local notify_label_text = notify_label:CreateFontString()
  notify_label_text:SetAllPoints(notify_label)
  notify_label_text:SetFontObject(GameFontNormalSmall)
  notify_label_text:SetText(L["Notify:"])
  notify_label_text:SetJustifyH("CENTER")
  notify_label_text:SetJustifyV("CENTER")

  local notifier_dropdown = gui.dropdown(money_frame)
  money_frame.notifier_dropdown = notifier_dropdown
  notifier_dropdown:ClearAllPoints()
  notifier_dropdown:SetPoint("TOPLEFT", notice_input, "BOTTOMLEFT", -24, -4)
  UIDropDownMenu_SetWidth(50, notifier_dropdown)
  UIDropDownMenu_SetButtonWidth(50, notifier_dropdown)
  UIDropDownMenu_JustifyText("LEFT", notifier_dropdown)
  notifier_dropdown:SetScript("OnShow", function()
    UIDropDownMenu_Initialize(this, moneyNotifierDropdown_Initialize)
  end)
  notifier_dropdown.update = updateNotifierDropdown
  notifier_dropdown.reset = nil
  
  local resource_dropdown = gui.dropdown(money_frame)
  money_frame.resource_dropdown = resource_dropdown
  resource_dropdown:ClearAllPoints()
  resource_dropdown:SetPoint("TOPLEFT", notifier_dropdown, 
    "TOPRIGHT", -30, 0)
  UIDropDownMenu_SetWidth(211, resource_dropdown)
  UIDropDownMenu_SetButtonWidth(211, resource_dropdown)
  UIDropDownMenu_JustifyText("LEFT", resource_dropdown)
  resource_dropdown:SetScript("OnShow", function()
      UIDropDownMenu_Initialize(this, moneyResourceDropdown_Initialize)
  end)
  resource_dropdown.update = updateResourceDropdown
  resource_dropdown.reset = nil
  
  local notify_editbox = CreateFrame("EditBox", nil, money_frame)
  money_frame.notify_editbox = notify_editbox
  notify_editbox:SetPoint("TOPLEFT", notifier_dropdown, "BOTTOMLEFT", 21, 0)
  notify_editbox:SetAutoFocus(false)
  notify_editbox:SetHeight(24)
  notify_editbox:SetWidth(290)
  notify_editbox:SetFontObject(GameFontHighlight)
  do
    local content = palette.color.backdrop.content
    gui.setBackdropStyle(notify_editbox, content.background, content.border,
      nil, nil, nil, nil, 1.5, 8, 
      [[Interface\Buttons\WHITE8X8]],
      [[Interface\Buttons\WHITE8X8]])
  end
  notify_editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  notify_editbox:SetScript("OnEnterPressed", function() 
    this:ClearFocus()
    if this.onEnterPressed then
      this:onEnterPressed()
    end
  end)
  notify_editbox.onEnterPressed = moneyEditboxOnEnterPressed
  notify_editbox:SetScript("OnEnter", function()
    notifyEditboxOnEnter(this, notifier_dropdown)
  end)
  notify_editbox:SetScript("OnLeave", function()
    notifyEditboxOnLeave(this, notifier_dropdown)
  end)
  notify_editbox.update = updateMoneyEditbox
  
  local notify_editbox_border = CreateFrame("Frame", nil, notify_editbox)
  money_frame.notify_editbox.border = notify_editbox_border
  notify_editbox_border:SetPoint("TOPLEFT", notify_editbox, -5, 3)
  notify_editbox_border:SetPoint("BOTTOMRIGHT", notify_editbox, 5, -3)
  notify_editbox_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  
  local none_button = gui.imgButton(money_frame, nil, 16, 16, 
    A.addon_path .. [[\img\trash]], "ADD", 0.5, 1.0, 0.5)
  none_button:SetPoint("RIGHT", notify_editbox, "LEFT", -6, 0)
  none_button.onClick = function()
    moneyEditboxOnEnterPressed(notify_editbox, NONE)
  end
  none_button.tooltipOn = noneButtonTooltipOnEnter
  none_button.tooltipOff = noneButtonTooltipOnLeave
  
  local defaults_button = gui.imgButton(money_frame, nil, 16, 16, 
    A.addon_path .. [[\img\reload]], "ADD", 0.5, 1.0, 0.5)
  defaults_button:SetPoint("RIGHT", none_button, "LEFT", -4, 0)
  defaults_button.onClick = function()
    moneyEditboxOnEnterPressed(notify_editbox, DEFAULTS)
  end
  defaults_button.tooltipOn = defaultsButtonTooltipOnEnter
  defaults_button.tooltipOff = defaultsButtonTooltipOnLeave
end

do
  local target_frame = CreateFrame("Frame", "$parentTarget", notice)
  M.target_frame = target_frame
  target_frame:SetPoint("TOPLEFT", money_frame, "BOTTOMLEFT", 0, -10)
  target_frame:SetPoint("TOPRIGHT", money_frame, "BOTTOMRIGHT")
  target_frame:SetHeight(100)
  
  local title = target_frame:CreateFontString()
  title:SetFontObject(GameFontHighlight)
  title:SetText(L["Target"])
  title:SetPoint("TOPLEFT", target_frame, 2, 0)
  title:SetHeight(20)
  
  local notice_label = CreateFrame("Frame", nil, target_frame)
  notice_label:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 9, -7)
  notice_label:SetWidth(28)
  notice_label:SetHeight(11)
  notice_label:EnableMouse()
  notice_label:SetScript("OnEnter", noticeLabel_OnEnter)
  notice_label:SetScript("OnLeave", noticeLabel_OnLeave)
  
  local notice_label_text = notice_label:CreateFontString()
  notice_label_text:SetAllPoints(notice_label)
  notice_label_text:SetFontObject(GameFontNormalSmall)
  notice_label_text:SetText(L["Min:"])
  notice_label_text:SetJustifyH("CENTER")
  notice_label_text:SetJustifyV("CENTER")
  
  local notice_input = gui.moneyInput(target_frame, nil, 225, 47)
  target_frame.notice_input = notice_input
  notice_input:SetPoint("LEFT", notice_label, "RIGHT", 10, 0)
  notice_input.update = function(self)
    inputUpdate(self, "target")
  end
  
  local notice_input_border = CreateFrame("Frame", nil, notice_input)
  target_frame.notice_input.border = notice_input_border
  notice_input_border:SetPoint("TOPLEFT", notice_label, "TOPRIGHT", 2, 6)
  notice_input_border:SetWidth(170)
  notice_input_border:SetHeight(25)
  notice_input_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  
  local notice_ok_button = CreateFrame("Button", nil, target_frame, 
    "UIPanelButtonTemplate")
  target_frame.notice_ok_button = notice_ok_button
  notice_ok_button:SetWidth(64)
  notice_ok_button:SetHeight(24)
  notice_ok_button:SetPoint("BOTTOMLEFT", notice_input, "BOTTOMRIGHT", -64, -3)
  notice_ok_button:SetText(L["Okay"])
  notice_ok_button:SetScript("OnClick", function()
    PlaySound(gui.sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  notice_ok_button.input = notice_input
  notice_ok_button.onClick = function(self)
    noticeOkButtonOnClick(self, "target")
  end
  
  local notice_clear_button = CreateFrame("Button", nil, target_frame, 
    "UIPanelButtonTemplate")
  target_frame.notice_clear_button = notice_clear_button
  notice_clear_button:SetWidth(64)
  notice_clear_button:SetHeight(24)
  notice_clear_button:SetPoint("LEFT", notice_ok_button, "RIGHT")
  notice_clear_button:SetText(L["Clear"])
  notice_clear_button:SetScript("OnClick", function()
    PlaySound(gui.sounds.click)
    if this.onClick then 
      this:onClick()
    end
  end)
  notice_clear_button.input = notice_input
  notice_clear_button.onClick = function(self)
    noticeClearButtonOnClick(self, "target")
  end
  
  local notify_label = CreateFrame("Frame", nil, target_frame)
  notify_label:SetPoint("TOPRIGHT", notice_label, "BOTTOMRIGHT", 0, -15)
  notify_label:SetWidth(38)
  notify_label:SetHeight(11)
  notify_label:EnableMouse()
  notify_label:SetScript("OnEnter", notifyLabel_OnEnter)
  notify_label:SetScript("OnLeave", notifyLabel_OnLeave)
  
  local notify_label_text = notify_label:CreateFontString()
  notify_label_text:SetAllPoints(notify_label)
  notify_label_text:SetFontObject(GameFontNormalSmall)
  notify_label_text:SetText(L["Notify:"])
  notify_label_text:SetJustifyH("CENTER")
  notify_label_text:SetJustifyV("CENTER")

  local notifier_dropdown = gui.dropdown(target_frame)
  target_frame.notifier_dropdown = notifier_dropdown
  notifier_dropdown:ClearAllPoints()
  notifier_dropdown:SetPoint("TOPLEFT", notice_input, "BOTTOMLEFT", -24, -4)
  UIDropDownMenu_SetWidth(50, notifier_dropdown)
  UIDropDownMenu_SetButtonWidth(50, notifier_dropdown)
  UIDropDownMenu_JustifyText("LEFT", notifier_dropdown)
  notifier_dropdown:SetScript("OnShow", function()
    UIDropDownMenu_Initialize(this, targetNotifierDropdown_Initialize)
  end)
  notifier_dropdown.update = updateNotifierDropdown
  notifier_dropdown.reset = nil
  
  local resource_dropdown = gui.dropdown(target_frame)
  target_frame.resource_dropdown = resource_dropdown
  resource_dropdown:ClearAllPoints()
  resource_dropdown:SetPoint("TOPLEFT", notifier_dropdown, 
    "TOPRIGHT", -30, 0)
  UIDropDownMenu_SetWidth(211, resource_dropdown)
  UIDropDownMenu_SetButtonWidth(211, resource_dropdown)
  UIDropDownMenu_JustifyText("LEFT", resource_dropdown)
  resource_dropdown:SetScript("OnShow", function()
      UIDropDownMenu_Initialize(this, targetResourceDropdown_Initialize)
  end)
  resource_dropdown.update = updateResourceDropdown
  resource_dropdown.reset = nil
  
  local notify_editbox = CreateFrame("EditBox", nil, target_frame)
  target_frame.notify_editbox = notify_editbox
  notify_editbox:SetPoint("TOPLEFT", notifier_dropdown, "BOTTOMLEFT", 21, 0)
  notify_editbox:SetAutoFocus(false)
  notify_editbox:SetHeight(24)
  notify_editbox:SetWidth(290)
  notify_editbox:SetFontObject(GameFontHighlight)
  do
    local content = palette.color.backdrop.content
    gui.setBackdropStyle(notify_editbox, content.background, content.border,
      nil, nil, nil, nil, 1.5, 8, 
      [[Interface\Buttons\WHITE8X8]],
      [[Interface\Buttons\WHITE8X8]])
  end
  notify_editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  notify_editbox:SetScript("OnEnterPressed", function() 
    this:ClearFocus()
    if this.onEnterPressed then
      this:onEnterPressed()
    end
  end)
  notify_editbox.onEnterPressed = targetEditboxOnEnterPressed
  notify_editbox:SetScript("OnEnter", function()
    notifyEditboxOnEnter(this, notifier_dropdown)
  end)
  notify_editbox:SetScript("OnLeave", function()
    notifyEditboxOnLeave(this, notifier_dropdown)
  end)
  notify_editbox.update = updateTargetEditbox
  
  local notify_editbox_border = CreateFrame("Frame", nil, notify_editbox)
  target_frame.notify_editbox.border = notify_editbox_border
  notify_editbox_border:SetPoint("TOPLEFT", notify_editbox, -5, 3)
  notify_editbox_border:SetPoint("BOTTOMRIGHT", notify_editbox, 5, -3)
  notify_editbox_border:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  
  local none_button = gui.imgButton(target_frame, nil, 16, 16, 
    A.addon_path .. [[\img\trash]], "ADD", 0.5, 1.0, 0.5)
  none_button:SetPoint("RIGHT", notify_editbox, "LEFT", -6, 0)
  none_button.onClick = function()
    targetEditboxOnEnterPressed(notify_editbox, NONE)
  end
  none_button.tooltipOn = noneButtonTooltipOnEnter
  none_button.tooltipOff = noneButtonTooltipOnLeave
  
  local defaults_button = gui.imgButton(target_frame, nil, 16, 16, 
    A.addon_path .. [[\img\reload]], "ADD", 0.5, 1.0, 0.5)
  defaults_button:SetPoint("RIGHT", none_button, "LEFT", -4, 0)
  defaults_button.onClick = function()
    targetEditboxOnEnterPressed(notify_editbox, DEFAULTS)
  end
  defaults_button.tooltipOn = defaultsButtonTooltipOnEnter
  defaults_button.tooltipOff = defaultsButtonTooltipOnLeave
end

