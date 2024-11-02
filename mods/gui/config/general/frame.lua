local A = FonzAppraiser
local L = A.locale

A.module('fa.gui.general', {'util.compat'})

local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local config = A.require 'fa.gui.config'

do
  local config_frame = config.frame
  local general = CreateFrame("Frame", "$parentGeneral", config_frame)
  M.general = general
  config_frame:addTabChild(general)
  general:SetPoint("TOPLEFT", config_frame, 11, -42)
  general:SetPoint("BOTTOMRIGHT", config_frame, -12, 2)
  general:SetScript("OnShow", general_OnShow)
  general.update = update
end

do
  local checkbox = gui.checkbox(general)
  checkbox:SetPoint("TOPRIGHT", -20, 5)
  M.minimap_checkbox = checkbox
  checkbox.onClick = minimapCheckboxOnClick
  checkbox.update = updateMinimapCheckbox
  
  local fontstring = checkbox:CreateFontString()
  checkbox.text = fontstring
  fontstring:SetFontObject(GameFontNormal)
  fontstring:SetText(L["Show minimap button"])
  fontstring:SetPoint("TOPLEFT", general, 10, -2)
  fontstring:SetJustifyH("LEFT")
  fontstring:SetJustifyV("TOP")
  fontstring:SetHeight(checkbox:GetHeight())
end

do
  local checkbox = gui.checkbox(general)
  checkbox:SetPoint("TOPRIGHT", minimap_checkbox, "BOTTOMRIGHT", 0, 5)
  M.enable_checkbox = checkbox
  checkbox.onClick = enableCheckboxOnClick
  checkbox.update = updateEnableCheckbox
  
  local fontstring = checkbox:CreateFontString()
  checkbox.text = fontstring
  fontstring:SetFontObject(GameFontNormal)
  fontstring:SetText(L["Enable chat output"])
  fontstring:SetPoint("TOPLEFT", minimap_checkbox.text, "BOTTOMLEFT", 0, 5)
  fontstring:SetJustifyH("LEFT")
  fontstring:SetJustifyV("TOP")
  fontstring:SetHeight(checkbox:GetHeight())
end

do
  local checkbox = gui.checkbox(general)
  checkbox:SetPoint("TOPRIGHT", enable_checkbox, "BOTTOMRIGHT", 0, 5)
  M.confirm_oldest_checkbox = checkbox
  checkbox.onClick = confirmOldestCheckboxOnClick
  checkbox.update = updateConfirmOldestCheckbox
  
  local fontstring = checkbox:CreateFontString()
  checkbox.text = fontstring
  fontstring:SetFontObject(GameFontNormal)
  fontstring:SetText(L["Delete oldest session after maximum sessions"])
  fontstring:SetPoint("TOPLEFT", enable_checkbox.text, "BOTTOMLEFT", 0, 5)
  fontstring:SetJustifyH("LEFT")
  fontstring:SetJustifyV("TOP")
  fontstring:SetHeight(checkbox:GetHeight())
end