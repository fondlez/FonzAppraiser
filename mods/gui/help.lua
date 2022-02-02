local A = FonzAppraiser

A.module 'fa.gui.help'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local gui = A.require 'fa.gui'

do
  local frame = CreateFrame("Frame", "FonzAppraiserHelpFrame", UIParent)
  M.frame = frame
  gui.styles["default"](frame, 11, 12, 12, 11)
  gui.setSize(frame, 400, 400)
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
  fontstring:SetText(format("FonzAppraiser Help"))
  fontstring:SetPoint("TOP", texture, "TOP", 0, -13)
end

do
  local button = CreateFrame("Button", "$parentCloseButton", frame,
    "UIPanelCloseButton")
  M.close_button = button
  gui.setSize(button, 36, 36)
  button:SetPoint("TOPRIGHT", -5, -5)
  
  button:SetScript("OnClick", function()
    A.trace("Help window - Close Button - OnClick")
    PlaySound(gui.sounds.menu_close)
    HideUIPanel(this:GetParent())
  end)
end

do
  local inner_frame = CreateFrame("Frame", "$parentInnerFrame", frame)
  M.inner_frame = inner_frame
  inner_frame:SetPoint("TOPLEFT", frame, 12, -52)
  inner_frame:SetPoint("BOTTOMRIGHT", frame, -11, 9)
  inner_frame:SetBackdrop{
    bgFile=[[Interface\Buttons\UI-SliderBar-Background]], 
    edgeFile=[[Interface\Buttons\UI-SliderBar-Border]], 
    edgeSize=8, 
    tile=true, tileSize=8,
    insets={ left=3, right=3, top=3, bottom=6 },
  }
end

do
  local function tabName(frame, id)
    --Specific naming required for Blizzard PanelTemplates support
    return frame:GetName() .. "Tab" .. id
  end
  function tabButton(frame, text, id)
    local tab = CreateFrame("Button", tabName(frame, id), frame, 
      "TabButtonTemplate")
    tab:SetID(id)
    tab:SetFrameLevel(2)
    tab:SetText(text)
    
    tab:SetScript("OnClick", function()
      PlaySound(gui.sounds.click)
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
  
  local tab1 = tabButton(inner_frame, L["Description"], 1)
  PanelTemplates_TabResize(nil, tab1)
  tab1:SetPoint("CENTER", inner_frame, "TOPLEFT", 60, 12)
  tab1.onSelect = hideUnselected
  
  local tab2 = tabButton(inner_frame, L["Version History"], 2)
  PanelTemplates_TabResize(nil, tab2)
  tab2:SetPoint("LEFT", tab1, "RIGHT", 5, 0)
  tab2.onSelect = hideUnselected
  
  local tab3 = tabButton(inner_frame, L["Credits"], 3)
  PanelTemplates_TabResize(nil, tab3)
  tab3:SetPoint("LEFT", tab2, "RIGHT", 5, 0)
  tab3.onSelect = hideUnselected
  
  inner_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  inner_frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
      PanelTemplates_SetNumTabs(inner_frame, 3)
      PanelTemplates_SetTab(inner_frame, selected_tab_id)
    end
  end)
  
  function inner_frame:addTabChild(child)
    tinsert(tab_children, child)
  end
  
  function M.update()
    if getn(tab_children) > 0 then tab_children[selected_tab_id].update() end
  end
end

function M.toggleWindow()
  if frame:IsVisible() then
    PlaySound(gui.sounds.menu_close)
    frame:Hide()
  else
    PlaySound(gui.sounds.menu_open)
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

A.options.args["Help"] = {
  type = "toggle",
  name = L["Help"],
  desc = L["Shows the help window"],
  get = function() return frame:IsVisible() end,
  set = function() A.trace("Help commmand option") toggleWindow() end,
}