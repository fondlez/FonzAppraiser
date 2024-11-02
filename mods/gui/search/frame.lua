local A = FonzAppraiser
local L = A.locale

A.module 'fa.search'

local util = A.require 'util.money'

local gui = A.require 'fa.gui'
local main = A.require 'fa.gui.main'
local palette = A.require 'fa.palette'

do
  local main_frame = main.frame
  local search = CreateFrame("Frame", "$parentSearch", main_frame)
  M.search = search
  main_frame:addTabChild(search)
  search:SetPoint("TOPLEFT", main_frame, 11, -32)
  search:SetPoint("BOTTOMRIGHT", main_frame, -14, 12)
  search:Hide()
  search:SetScript("OnShow", search_OnShow)
  search.update = update
  search.scrollFrameFauxUpdate = scrollFrameFauxUpdate
end

do
  local editbox = CreateFrame("EditBox", "$parentEditBox", search)
  M.editbox = editbox
  editbox:SetAutoFocus(false)
  editbox:SetPoint("TOPLEFT", search, 2, -10)
  editbox:SetPoint("TOPRIGHT", search, -52, -10)
  editbox:SetHeight(26)
	editbox:SetBackdrop{
    edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], 
    edgeSize=16, 
    tile=true, tileSize=16,
    insets={ left=5, right=5, top=5, bottom=5 },
  }
  editbox:SetBackdropColor(palette.color.transparent())
  editbox:SetTextInsets(24, 17, 3, 3)
  editbox:SetJustifyH("LEFT")
  editbox:SetFont(gui.font.default, gui.font_size.small, "OUTLINE")
  editbox:SetFontObject("GameFontDisable")
  editbox:SetText(L["Search"])
  
  local search_icon = editbox:CreateTexture("$parentSearchIcon", "OVERLAY")
  editbox.search_icon = search_icon
  search_icon:SetTexture(A.addon_path .. [[\img\search\tracker_search]])
  search_icon:SetWidth(14)
  search_icon:SetHeight(14)
  search_icon:SetVertexColor(0.6, 0.6, 0.6)
  search_icon:SetPoint("LEFT", editbox, 6, 0)
  
  local clear_button = CreateFrame("Button", "$parentClearButton", 
    editbox)
  editbox.clear_button = clear_button
  clear_button:Hide()
  clear_button:SetWidth(17)
  clear_button:SetHeight(17)
  clear_button:SetPoint("RIGHT", editbox, "RIGHT", -5, 0)
  
  local clear_button_texture = clear_button:CreateTexture(nil, "ARTWORK")
  clear_button.texture = clear_button_texture
  clear_button_texture:SetTexture(A.addon_path .. [[\img\search\tracker_close]])
  clear_button_texture:SetWidth(17)
  clear_button_texture:SetHeight(17)
  clear_button_texture:SetAlpha(0.5)
  clear_button_texture:SetPoint("TOPLEFT", clear_button, "TOPLEFT", 0, 0)
  
  clear_button:SetScript("OnEnter", function()
    this.texture:SetAlpha(1.0)
  end)
  clear_button:SetScript("OnLeave", function()
    this.texture:SetAlpha(0.5)
  end)
  clear_button:SetScript("OnMouseDown", function()
    if this:IsEnabled() then
      this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 1, -1)
    end
  end)
  clear_button:SetScript("OnMouseUp", function()
    this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 0, 0)
  end)
  clear_button:SetScript("OnClick", function()
    PlaySound(gui.sounds.click)
    local parent = this:GetParent()
    parent:SetText("")
    parent:SetFocus()
    parent:ClearFocus()
    searchButtonOnClick()
  end)

  editbox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  editbox:SetScript("OnEnterPressed", function() 
    this:ClearFocus()
    if this.onEnterPressed then
      this:onEnterPressed()
    end
  end)
  editbox.onEnterPressed = editboxOnEnterPressed
  editbox:SetScript("OnEditFocusGained", function()
    this:HighlightText()
    this:SetFontObject("GameFontWhite")
    this.search_icon:SetVertexColor(1.0, 1.0, 1.0)
    if this:GetText() == L["Search"] then 
      this:SetText("")
    end
    this.clear_button:Show()
  end)
  editbox:SetScript("OnEditFocusLost", function()
    this:HighlightText(0, 0)
    this:SetFontObject("GameFontDisable")
    this.search_icon:SetVertexColor(0.6, 0.6, 0.6)
    
    if this:GetText() == "" then
      this:SetText(L["Search"])
      this.clear_button:Hide()
    end
  end)
  editbox:SetScript("OnEnter", editbox_OnEnter)
  editbox:SetScript("OnLeave", editbox_OnLeave)
end

do
  local search_button = gui.button(search, "$parentSearchButton", 50, 23, 
    L["Search"])
  M.search_button = search_button
  search_button:SetPoint("LEFT", editbox, "RIGHT", 3, 1)
  search_button.onClick = searchButtonOnClick
end

do
  local results_frame = CreateFrame("Frame", "$parentResultsFrame", search)
  M.results_frame = results_frame
  results_frame:SetPoint("TOPLEFT", editbox, "BOTTOMLEFT", 0, -2)
  results_frame:SetPoint("TOPRIGHT", editbox, "BOTTOMRIGHT", 0, -2)
  results_frame:SetHeight(14)
  
  local results_label = results_frame:CreateFontString()
  results_frame.label = results_label
  results_label:SetPoint("TOPLEFT", results_frame, 2, 0)
  results_label:SetFontObject(GameFontNormalSmall)
  results_label:SetJustifyH("LEFT")
  results_label:SetText(L["Results:"])
  
  local loot_count_text = results_frame:CreateFontString()
  M.loot_count_text = loot_count_text
  loot_count_text:SetPoint("LEFT", results_label, "RIGHT")
  loot_count_text:SetFontObject(GameFontHighlightSmall)
  loot_count_text:SetJustifyH("LEFT")
  loot_count_text:SetText("-")
  loot_count_text.updateDisplay = function(self, count)
    self:SetText(count > 0 and format(L["%d loots"], count) or "-")
  end
  
  local item_count_text = results_frame:CreateFontString()
  M.item_count_text = item_count_text
  item_count_text:SetPoint("LEFT", loot_count_text, "RIGHT")
  item_count_text:SetFontObject(GameFontHighlightSmall)
  item_count_text:SetJustifyH("LEFT")
  item_count_text:SetText(", -")
  item_count_text.updateDisplay = function(self, count)
    self:SetText(count > 0 and format(L[", %d items"], count) or "-")
  end
  
  local item_value_text = results_frame:CreateFontString()
  M.item_value_text = item_value_text
  item_value_text:SetPoint("LEFT", item_count_text, "RIGHT")
  item_value_text:SetFontObject(GameFontHighlightSmall)
  item_value_text:SetJustifyH("LEFT")
  item_value_text:SetText(", -")
  item_value_text.updateDisplay = function(self, value)
    self:SetText(value 
      and format(L[", %s value"], util.formatMoneyFull(value, true)) or "-")
  end
end

do
  local scroll_frame = CreateFrame("ScrollFrame", "$parentScrollFrame", search,
    "FauxScrollFrameTemplate")
  M.scroll_frame = scroll_frame
  scroll_frame:SetHeight(201)
  scroll_frame:SetPoint("TOPLEFT", search, 0, -51)
  scroll_frame:SetPoint("TOPRIGHT", search, 2, -51)
  
  --WORKAROUND(@fondlez): Blizzard's FauxScrollFrame_Update() calls Hide() on
  --the scroll frame if info.data_size is less than info.display_size.
  --This is inconvenient if the scroll_frame is also used for cosmetics.
  --A static cosmetic wrapper frame seems cheaper than Show() calls after every
  --scroll frame update.
  local scroll_frame_border = CreateFrame("Frame", "$parentScrollFrameBorder",
    search)
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
  parent["sframe1"].display_size = 12
  parent["sframe1"].entry_height = 16
  parent["sframe1"].entries = {}
  gui.makeOneColTextRows(scroll_frame, "sframe1", 6, -56, -21)
  
  scroll_frame:SetScript("OnVerticalScroll", scrollFrame_OnVerticalScroll)
  scroll_frame.update = updateScrollFrame
end
