local A = FonzAppraiser

A.module 'fa.notice'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local util = A.requires(
  'util.string',
  'util.money'
)

local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local config = A.require 'fa.gui.config'

local notice_types = { "item", "money", "target" }

function M.update()
  if not notice:IsVisible() then return end
  
  enable_checkbox:update()
  soulbound_checkbox:update()
  
  for i,v in ipairs({ item_frame, money_frame, target_frame }) do
    v.notice_input:update()
    v.notifier_dropdown:update()
    v.resource_dropdown:update()
    v.notify_editbox:update()
  end
end

function updateEnableCheckbox(self)
  self:SetChecked(A:isEnabled())
end

function updateSoulboundCheckbox(self)
  local db = A.getCharConfig("fa.notice")
  self:SetChecked(db.ignore_soulbound)
end

do
  local previous_saved_values = {}
  
  local function getSavedValue(notice_type)
    local db = A.getCharConfig("fa.notice")
    local saved_value
    if notice_type == "item" then
      saved_value = tonumber(db.item_threshold) or 0
    elseif notice_type == "money" then
      saved_value = tonumber(db.money_threshold) or 0
    elseif notice_type == "target" then
      saved_value = tonumber(db.target) or 0
    else
      A.warn("[CONFIG] Unknown notice type: %s", notice_type or "nil")
      return
    end
    return math.max(saved_value, 0)
  end
  
  function inputUpdate(self, notice_type)
    local saved_value = getSavedValue(notice_type)
    
    local previous_saved = previous_saved_values[notice_type]
    local current_value = util.baseMoney(self:getValue())
    if not previous_saved or self:isEmpty()
        or current_value == saved_value
        or previous_saved ~= saved_value then
      self:setValue(saved_value)
      self.border:SetBackdropBorderColor(palette.color.original())
      self:clearFocus()
    end
    previous_saved_values[notice_type] = saved_value
    
    local function onTextChanged()
      PlaySound(gui.sounds.click)
      local parent = this:GetParent()
      local saved_value = getSavedValue(notice_type)
      local current_value = util.baseMoney(parent:getValue())
      if current_value ~= saved_value then
        parent.border:SetBackdropBorderColor(palette.color.transparent())
      else
        parent.border:SetBackdropBorderColor(palette.color.original())
      end
    end
    
    self.gold_editbox:SetScript("OnTextChanged", onTextChanged)
    self.silver_editbox:SetScript("OnTextChanged", onTextChanged)
    self.copper_editbox:SetScript("OnTextChanged", onTextChanged)
  end
end

do
  local previous_saved_values = {
    item = {},
    money = {},
    target = {},
  }
  
  local function updateEditbox(self, notify_type, notify)
    local parent = self:GetParent()
    local notifier_dropdown = parent.notifier_dropdown
    
    local notifier = notifier_dropdown.selected
    local saved_value = notify[notifier]
    
    local previous_saved = previous_saved_values[notify_type][notifier]
    local current_value = self:GetText()
    if not previous_saved or util.isempty(current_value)
        or current_value == saved_value
        or previous_saved ~= saved_value then
      self:SetText(saved_value)
      self.border:SetBackdropBorderColor(palette.color.original())
      self:HighlightText(0, 0)
      self:SetFocus()
      self:ClearFocus()
    end
    previous_saved_values[notify_type][notifier] = saved_value
    
    local function onTextChanged()
      PlaySound(gui.sounds.click)
      local notifier = notifier_dropdown.selected
      local saved_value = notify[notifier]
      local current_value = this:GetText()
      if current_value ~= saved_value then
        this.border:SetBackdropBorderColor(palette.color.transparent())
      else
        this.border:SetBackdropBorderColor(palette.color.original())
      end
    end
    
    self:SetScript("OnTextChanged", onTextChanged)
  end
  
  function updateItemEditbox(self)
    local db = A.getCharConfig("fa.notice")
    updateEditbox(self, "item", db.item_notify)
  end
  
  function updateMoneyEditbox(self)
    local db = A.getCharConfig("fa.notice")
    updateEditbox(self, "money", db.money_notify)
  end
  
  function updateTargetEditbox(self)
    local db = A.getCharConfig("fa.notice")
    updateEditbox(self, "target", db.target_notify)
  end
end

--------------------------------------------------------------------------------

function notice_OnShow()
  update()
end

function enableCheckboxOnClick(self)
  local db = A.getCharConfig("fa")
  db.enable = not db.enable
  self:SetChecked(db.enable)
end

function soulboundCheckBoxOnClick(self)
  local db = A.getCharConfig("fa.notice")
  db.ignore_soulbound = not db.ignore_soulbound
  self:SetChecked(db.ignore_soulbound)
end

do
  function noticeLabel_OnEnter()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    
    GameTooltip:AddLine(L["Notice Threshold"], 1, 1, 1)
    GameTooltip:AddLine(L["Set minimum value to trigger notice"])
      
    GameTooltip:Show()
  end
  
  function noticeLabel_OnLeave()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
end

function noticeOkButtonOnClick(self, notice_type)
  local money_input = self.input
  local current_value = util.baseMoney(money_input:getValue())
  local db = A.getCharConfig("fa.notice")
  
  if notice_type == "item" then
    if current_value > 0 then
      PlaySoundFile(gui.sounds.file_numeric_input_ok)
    else
      PlaySoundFile(gui.sounds.click)
    end
    db.item_threshold = current_value > 0 and current_value or NONE
    money_input:clearFocus()
  elseif notice_type == "money" then
    if current_value > 0 then
      PlaySoundFile(gui.sounds.file_numeric_input_ok)
    else
      PlaySoundFile(gui.sounds.click)
    end
    db.money_threshold = current_value > 0 and current_value or NONE
    PlaySoundFile(gui.sounds.file_numeric_input_ok)  
    money_input:clearFocus()
  elseif notice_type == "target" then
    if current_value > 0 then
      PlaySoundFile(gui.sounds.file_numeric_input_ok)
    else
      PlaySoundFile(gui.sounds.click)
    end
    changeTarget(current_value > 0 and current_value or NONE)
    PlaySoundFile(gui.sounds.file_numeric_input_ok)
    money_input:clearFocus()
  else
    A.warn("[CONFIG] Unknown notice type: %s", notice_type or "nil")
  end
  
  update()
end

function noticeClearButtonOnClick(self, notice_type)
  local money_input = self.input
  local db = A.getCharConfig("fa.notice")
  
  if notice_type == "item" then
    PlaySoundFile(gui.sounds.click)
    money_input:setValue(0)
    db.item_threshold = NONE
    money_input:clearFocus()
  elseif notice_type == "money" then
    PlaySoundFile(gui.sounds.click)  
    money_input:setValue(0)
    db.money_threshold = NONE
    money_input:clearFocus()
  elseif notice_type == "target" then
    PlaySoundFile(gui.sounds.click)
    money_input:setValue(0)
    changeTarget(NONE)
    money_input:clearFocus()
  else
    A.warn("[CONFIG] Unknown notice type: %s", notice_type or "nil")
  end
  
  update()
end

do
  function notifyLabel_OnEnter()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    
    GameTooltip:AddLine(L["Notify Method"], 1, 1, 1)
    GameTooltip:AddLine(L["Setting for each type of notify method"])
      
    GameTooltip:Show()
  end
  
  function notifyLabel_OnLeave()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
end

do
  local function showResourceDropdown(self)
    local resource_dropdown = self:GetParent().resource_dropdown
    if self.selected == "sound" then
      resource_dropdown:Show()
    else
      resource_dropdown:Hide()
    end
  end
  
  function updateNotifierDropdown(self)
    UIDropDownMenu_SetSelectedValue(self, self.selected)
    showResourceDropdown(self)
  end
  
  local function initialize(self, notify)
    local function onClick()      
      self.selected = this.value
      UIDropDownMenu_SetSelectedValue(self, self.selected)
      showResourceDropdown(self)
      
      local value = notify[self.selected]
      local notify_editbox = self:GetParent().notify_editbox
      notify_editbox:SetText(value)
      notify_editbox:HighlightText(0, 0)
      notify_editbox:SetFocus()
      notify_editbox:ClearFocus()
      notify_editbox:update()
    end
    
    self.selected = self.selected or "system"
    for i,v in ipairs(NOTIFY_TYPES) do
      if notify[v] then
        local info = {}
        info.text = v
        info.value = v
        info.owner = self
        info.func = onClick
        UIDropDownMenu_AddButton(info)
      end
    end
    
    UIDropDownMenu_SetSelectedValue(self, self.selected)
    showResourceDropdown(self)
  end
  
  function itemNotifierDropdown_Initialize()
    local self = item_frame.notifier_dropdown
    local db = A.getCharConfig("fa.notice")
    local notify = db.item_notify
    initialize(self, notify)
  end
  
  function moneyNotifierDropdown_Initialize()
    local self = money_frame.notifier_dropdown
    local db = A.getCharConfig("fa.notice")
    local notify = db.money_notify
    initialize(self, notify)
  end
  
  function targetNotifierDropdown_Initialize()
    local self = target_frame.notifier_dropdown
    local db = A.getCharConfig("fa.notice")
    local notify = db.target_notify
    initialize(self, notify)
  end
end

do
  function updateResourceDropdown(self)
    UIDropDownMenu_SetSelectedValue(self, self.selected)
  end
  
  local function initialize(self, notify)
    local function onClick()
      self.selected = this.value
      UIDropDownMenu_SetSelectedValue(self, self.selected)
      
      PlaySoundFile(this.value)
      notify.sound = self.selected
      
      local notify_editbox = self:GetParent().notify_editbox
      notify_editbox:SetText(self.selected)
      notify_editbox:HighlightText(0, 0)
      notify_editbox:SetFocus()
      notify_editbox:ClearFocus()
      notify_editbox:update()
    end
    
    self.selected = self.selected or notify.sound
    for i,v in ipairs(SOUNDS) do
      local info = {}
      info.text = v.name
      info.value = v.file
      info.owner = self
      info.func = onClick
      UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_SetSelectedValue(self, self.selected)
  end
  
  function itemResourceDropdown_Initialize()
    local self = item_frame.resource_dropdown
    local db = A.getCharConfig("fa.notice")
    local notify = db.item_notify
    initialize(self, notify)
  end
  
  function moneyResourceDropdown_Initialize()
    local self = money_frame.resource_dropdown
    local db = A.getCharConfig("fa.notice")
    local notify = db.money_notify
    initialize(self, notify)
  end
  
  function targetResourceDropdown_Initialize()
    local self = target_frame.resource_dropdown
    local db = A.getCharConfig("fa.notice")
    local notify = db.target_notify
    initialize(self, notify)
  end
end

do
  local strtrim = util.strtrim
  
  function noneButtonTooltipOnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    
    GameTooltip:AddLine(NONE, 1, 1, 1)
    GameTooltip:AddLine(L["Disable output"])
      
    GameTooltip:Show()
  end
  
  function noneButtonTooltipOnLeave(self)
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
  
  function defaultsButtonTooltipOnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    
    GameTooltip:AddLine(DEFAULTS, 1, 1, 1)
    GameTooltip:AddLine(L["Return to defaults"])
      
    GameTooltip:Show()
  end
  
  function defaultsButtonTooltipOnLeave(self)
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
  
  function notifyEditboxOnEnter(self, notifier_dropdown)
    local notify_method = notifier_dropdown.selected
    if notify_method then
      GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
      
      GameTooltip:AddLine(notify_method, 1, 1, 1)
      GameTooltip:AddLine(NOTIFY_METHOD_HELP[notify_method])
        
      GameTooltip:Show()
    end
  end
  
  function notifyEditboxOnLeave(self, notifier_dropdown)
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
  
  local function onEnterPressed(self, notify, default_notify, button_value)
    local parent = self:GetParent()
    local notifier_dropdown = parent.notifier_dropdown
    local value = button_value or self:GetText()
    
    local notifier = notifier_dropdown.selected
    if notifier == "sound" then
      value = normalizePath(value)
      PlaySoundFile(value)
    else
      PlaySound(gui.sounds.click)
    end
    value = strtrim(value)
    if value == "" or value == NONE then
      notify[notifier] = NONE
      self:SetText(NONE)
    elseif value == DEFAULTS then
      notify[notifier] = default_notify[notifier]
      self:SetText(default_notify[notifier])
    else
      notify[notifier] = value
    end
    
    local resource_dropdown = parent.resource_dropdown
    if resource_dropdown:IsVisible() 
        and resource_dropdown.selected ~= value then
      resource_dropdown.selected = value
      --Make empty dropdown text
      _G[resource_dropdown:GetName().."Text"]:SetText("")
    end
    
    self.border:SetBackdropBorderColor(palette.color.original())
    self:HighlightText(0, 0)
    self:SetFocus()
    self:ClearFocus()
    self:update()
  end

  function itemEditboxOnEnterPressed(self, button_value)
    local db = A.getCharConfig("fa.notice")
    onEnterPressed(self, db.item_notify, defaults.item_notify, button_value)
  end
  
  function moneyEditboxOnEnterPressed(self, button_value)
    local db = A.getCharConfig("fa.notice")
    onEnterPressed(self, db.money_notify, defaults.money_notify, button_value)
  end
  
  function targetEditboxOnEnterPressed(self, button_value)
    local db = A.getCharConfig("fa.notice")
    onEnterPressed(self, db.target_notify, defaults.target_notify, button_value)
  end
end