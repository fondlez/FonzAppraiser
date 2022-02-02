local A = FonzAppraiser

A.module 'fa.gui.config'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local gui = A.require 'fa.gui'

do
  local frame = CreateFrame("Frame", "FonzAppraiserConfigFrame", UIParent)
  M.frame = frame
  gui.styles["default"](frame, 11, 12, 12, 11)
  gui.setSize(frame, 375, 400)
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
  fontstring:SetText(format("FonzAppraiser Config"))
  fontstring:SetPoint("TOP", texture, "TOP", 0, -13)
end

do
  local button = CreateFrame("Button", "$parentCloseButton", frame,
    "UIPanelCloseButton")
  M.close_button = button
  gui.setSize(button, 36, 36)
  button:SetPoint("TOPRIGHT", -5, -5)
  
  button:SetScript("OnClick", function()
    A.trace("Config window - Close Button - OnClick")
    PlaySoundFile(gui.sounds.file_close_char)
    HideUIPanel(this:GetParent())
  end)
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
  
  local tab1 = tabButton(frame, L["Notice"], 1)
  PanelTemplates_TabResize(nil, tab1)
  tab1:SetPoint("CENTER", frame, "BOTTOMLEFT", 60, -10)
  tab1.onSelect = hideUnselected
  
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
      PanelTemplates_SetNumTabs(frame, 1)
      PanelTemplates_SetTab(frame, selected_tab_id)
    end
  end)
  
  function frame:addTabChild(child)
    tinsert(tab_children, child)
  end
  
  function M.update()
    if getn(tab_children) > 0 then tab_children[selected_tab_id].update() end
  end
end

function M.toggleWindow()
  if frame:IsVisible() then
    PlaySoundFile(gui.sounds.file_close_char)
    frame:Hide()
  else
    PlaySoundFile(gui.sounds.file_open_char)
    frame:Show()
  end
end

-- MODULE OPTIONS --

if not A.options then
  A.options = {
    type = "group",
    args = {},
  }
end

A.options.args["Config"] = {
  type = "toggle",
  name = L["Config"],
  desc = L["Shows the configuration window"],
  get = function() return frame:IsVisible() end,
  set = function() A.trace("Config commmand option") toggleWindow() end,
}