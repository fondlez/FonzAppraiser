local A = FonzAppraiser
local L = A.locale

A.module 'fa.gui.help.credits'

local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local help = A.require 'fa.gui.help'

do
  local help_frame = help.inner_frame
  local scroll_frame = CreateFrame("ScrollFrame", "$parentCredits", 
    help_frame, "UIPanelScrollFrameTemplate")
  M.credits = scroll_frame
  scroll_frame:Hide()
  scroll_frame:SetPoint("TOPLEFT", help_frame, 0, -6)
  scroll_frame:SetPoint("BOTTOMRIGHT", help_frame, 0, 4)
  help_frame:addTabChild(scroll_frame)
  
  --Adjust scrollbar to fit inside
  local scrollbar = _G[scroll_frame:GetName() .. "ScrollBar"]
  scrollbar:ClearAllPoints()
  scrollbar:SetPoint("TOPLEFT", scroll_frame, "TOPRIGHT", -18, -17)
  scrollbar:SetPoint("BOTTOMLEFT", scroll_frame, "BOTTOMRIGHT", -18, 16)
  
  local scroll_child = CreateFrame("Frame", "$parentScrollChild", scroll_frame)
  gui.setSize(scroll_child, 1, 1)
  scroll_child:SetFrameStrata("HIGH")
  scroll_frame:SetScrollChild(scroll_child)

  local text = CreateFrame("SimpleHTML", "$parentText", scroll_child)
  gui.setSize(text, 324, 296)
  text:SetPoint("TOPLEFT", scroll_child, 10, -10)
  text:SetJustifyH("LEFT")
  text:SetFont("h1", gui.font.default, gui.font_size.regular)
  text:SetTextColor("h1", palette.color.gold_text())
  text:SetFont("h2", gui.font.default, gui.font_size.medium)
  text:SetTextColor("h2", palette.color.gold_text())
  text:SetFont("h3", gui.font.default, gui.font_size.medium) 
  text:SetTextColor("h3", palette.color.gold_text())
  text:SetFont("p", gui.font.default, gui.font_size.medium) 
  text:SetTextColor("p", palette.color.white_text())
  text:SetText(L["HELP_CREDITS"])
end