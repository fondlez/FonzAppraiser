local A = FonzAppraiser

A.module 'fa.gui.main'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local pricing = A.require 'fa.value.pricing'
local filter = A.require 'fa.filter'
local gui = A.require 'fa.gui'
local gui_config = A.require 'fa.gui.config'
local gui_help = A.require 'fa.gui.help'

do
  local frame = CreateFrame("Frame", "FonzAppraiserMainFrame", UIParent)
  M.frame = frame
  gui.styles["default"](frame, 11, 12, 12, 11)
  gui.setSize(frame, 375, 300)
  frame:SetPoint("CENTER", 0, 0)
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:SetFrameStrata("MEDIUM")
  frame:CreateTitleRegion():SetAllPoints()
  frame:Hide()
  
  frame:SetScript("OnShow", function()
    A:guiUpdate()
  end)
end

do
  local texture = frame:CreateTexture(nil, "ARTWORK")
  M.header = texture
  texture:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
  gui.setSize(texture, 300, 64)
  texture:SetPoint("TOP", 0, 12)
  
  local fontstring = frame:CreateFontString(nil, "ARTWORK",
    "GameFontNormal")
  fontstring:SetText(format("FonzAppraiser %s", A.ver))
  fontstring:SetPoint("TOP", texture, "TOP", 0, -13)
end

do
  local button = CreateFrame("Button", "$parentCloseButton", frame,
    "UIPanelCloseButton")
  M.close_button = button
  gui.setSize(button, 36, 36)
  button:SetPoint("TOPRIGHT", -5, -5)
  
  button:SetScript("OnClick", function()
    A.trace("Main window - Close Button - OnClick")
    PlaySound(gui.sounds.click_close)
    HideUIPanel(this:GetParent())
  end)
end

do
  local config_button = gui.imgButton(frame, nil, 16, 16, 
    A.addon_path .. [[\img\settings]], "ADD", 1.0, 1.0, 1.0)
  M.config_button = config_button
  config_button:SetPoint("TOP", frame, -14, -25)
  config_button.onClick = function()
    gui_config.toggleWindow()
  end
  config_button.tooltipOn = function()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:AddLine(L["Settings"])
    GameTooltip:Show()
  end
  config_button.tooltipOff = function()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
  
  local help_button = gui.imgButton(frame, nil, 16, 16, 
    A.addon_path .. [[\img\help]], "ADD", 1.0, 1.0, 1.0)
  M.help_button = help_button
  help_button:SetPoint("TOP", frame, 14, -25)
  help_button.onClick = function()
    gui_help.toggleWindow()
  end
  help_button.tooltipOn = function()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:AddLine(L["Help"])
    GameTooltip:Show()
  end
  help_button.tooltipOff = function()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
end

do
  local function tabName(frame, id)
    --Specific naming required for Blizzard PanelTemplates support
    return frame:GetName() .. "Tab" .. id
  end
  
  local function correctInactiveTab(tab)
    local name = tab:GetName()
    local texture = _G[name .. "Left"]
    texture:SetPoint("TOPLEFT", tab, 0, 2)
  end
  
  function tabButton(frame, text, id)
    local tab = CreateFrame("Button", tabName(frame, id), frame, 
      "CharacterFrameTabButtonTemplate")
    correctInactiveTab(tab)
    tab:SetID(id)
    tab:SetFrameLevel(2)
    tab:SetText(text)
    
    tab:SetScript("OnClick", function()
      PlaySound(gui.sounds.tabbing)
      PanelTemplates_SetTab(frame, this:GetID())
      if this.onSelect then this.onSelect(this:GetID()) end
    end)
    
    return tab
  end
end

do
  local selected_tab_id = 1
  local tab_children = {}
  
  local function hideUnselected(selected)
    if not selected then return end
    selected_tab_id = selected
    for id,child in ipairs(tab_children) do
      if id ~= selected then
        child:Hide()
      else
        child:Show()
      end
    end
    gui.hideTooltip()
  end
  
  local tab1 = tabButton(frame, L["Summary"], 1)
  PanelTemplates_TabResize(nil, tab1)
  tab1:SetPoint("CENTER", frame, "BOTTOMLEFT", 60, -10)
  tab1.onSelect = hideUnselected
  
  local tab2 = tabButton(frame, L["Items"], 2)
  PanelTemplates_TabResize(nil, tab2)
  tab2:SetPoint("LEFT", tab1, "RIGHT", -16, 0)
  tab2.onSelect = hideUnselected
  
  local tab3 = tabButton(frame, L["Search"], 3)
  PanelTemplates_TabResize(nil, tab3)
  tab3:SetPoint("LEFT", tab2, "RIGHT", -16, 0)
  tab3.onSelect = hideUnselected
  
  local tab4 = tabButton(frame, L["Sessions"], 4)
  PanelTemplates_TabResize(nil, tab4)
  tab4:SetPoint("LEFT", tab3, "RIGHT", -16, 0)
  tab4.onSelect = hideUnselected
  
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
      PanelTemplates_SetNumTabs(frame, 4)
      PanelTemplates_SetTab(frame, selected_tab_id)
    end
  end)
  
  function frame:addTabChild(child)
    tinsert(tab_children, child)
  end
  
  function M.update()
    quality_dropdown:update()
    pricing_dropdown:update()
    if getn(tab_children) > 0 then tab_children[selected_tab_id].update() end
  end
end

do
  function updateQualityDropdown(self)
    local db = A.getCharConfig("fa.filter")
    UIDropDownMenu_SetSelectedValue(self, db.quality)
  end
  
  local function onClick()
    UIDropDownMenu_SetSelectedValue(quality_dropdown, this.value)
    local db = A.getCharConfig("fa.filter")
    db.quality = this.value
    update()
  end

  function qualityDropdown_Initialize()
    local self = quality_dropdown
    for i=0,4 do
      local rarity_name = filter.ITEM_RARITY[i]
      local info = {}
      info.text = rarity_name
      info.value = rarity_name
      info.owner = self
      info.tooltipTitle = L["Item Quality"]
      info.tooltipText = format(L["List items of %s rarity or better"], 
        rarity_name)
      info.textR, info.textG, info.textB = GetItemQualityColor(i)
      info.func = onClick
      UIDropDownMenu_AddButton(info)
    end
    local db = A.getCharConfig("fa.filter")
    UIDropDownMenu_SetSelectedValue(self, db.quality)
  end

  do
    local dropdown = gui.dropdown(frame)
    M.quality_dropdown = dropdown
    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, -14)
    UIDropDownMenu_SetWidth(77, dropdown)
    UIDropDownMenu_SetButtonWidth(40, dropdown)
    UIDropDownMenu_JustifyText("LEFT", dropdown)
    dropdown:SetScript("OnShow", function()
        UIDropDownMenu_Initialize(this, qualityDropdown_Initialize)
    end)
    dropdown.update = updateQualityDropdown
  end
end

do
  function updatePricingDropdown(self)
    local db = A.getCharConfig("fa.value.pricing")
    UIDropDownMenu_SetSelectedValue(self, db.pricing)
  end
  
  local function onClick()
    UIDropDownMenu_SetSelectedValue(pricing_dropdown, this.value)
    local db = A.getCharConfig("fa.value.pricing")
    db.pricing = this.value
    A:guiUpdate()
  end

  function pricingDropdown_Initialize()
    local self = pricing_dropdown
    for i,system in ipairs(pricing.systems) do
      local info = {}
      info.text = system.id
      info.value = system.id
      info.owner = self
      info.tooltipTitle = L["Item Pricing"]
      info.tooltipText = format("%s", system.description)
      info.func = onClick
      UIDropDownMenu_AddButton(info)
    end
    local db = A.getCharConfig("fa.value.pricing")
    UIDropDownMenu_SetSelectedValue(self, db.pricing)
  end

  do
    local dropdown = gui.dropdown(frame)
    M.pricing_dropdown = dropdown
    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -14)
    UIDropDownMenu_SetWidth(50, dropdown)
    UIDropDownMenu_SetButtonWidth(50, dropdown)
    UIDropDownMenu_JustifyText("LEFT", dropdown)
    dropdown:SetScript("OnShow", function()
        UIDropDownMenu_Initialize(this, pricingDropdown_Initialize)
    end)
    dropdown.update = updatePricingDropdown
  end
end

function M.toggleWindow()
  PlaySound(gui.sounds.click_close)
  if frame:IsVisible() then
    frame:Hide()
  else
    frame:Show()
  end
end
A.toggleMainWindow = toggleWindow

-- MODULE OPTIONS --

if not A.options then
  A.options = {
    type = "group",
    args = {},
  }
end

A.options.args["Show"] = {
  type = "toggle",
  name = L["Show"],
  desc = L["Shows the main window"],
  get = function() return frame:IsVisible() end,
  set = function() A.trace("Show command option") toggleWindow() end,
}