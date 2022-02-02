local A = FonzAppraiser

A.module 'fa.gui.sessions'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.table',
  'util.string'
)

local session = A.require 'fa.session'
local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'

function M.update()
  if not sessions:IsVisible() then return end
  
  scroll_frame:update()
  selectall_checkbox:update()
  
  name_button:update()
  duration_text:update()
  total_value:update()
  currency_value:update()
  items_text:update()
  items_value:update()
  hot_text:update()
  hot_value:update()
  most_valued:update()
end

do
  local min = math.min
  
  function updateScrollFrame(self)
    local parent = self:GetParent()
    local info = parent["sframe1"]
    
    local status = session.sessionStatus()
    if status then
      local n = getn(status)
      local data = {}
      for i=n,1,-1 do
        tinsert(data, status[i])
      end
    
      info.data = data
      info.data_size = min(n, info.max_size)
    else
      info.data = nil
    end
    parent:scrollFrameFauxUpdate("sframe1")
  end
end

do
  local previous_checksum
  
  function updateSelectAllCheckbox(self, scroll_frame_index)
    local checksum = session.getSessionsChecksum()
    if not checksum or not previous_checksum 
        or checksum ~= previous_checksum then
      local parent = self:GetParent()
      local info = parent[scroll_frame_index]
      uncheckAll(info)
    end
    previous_checksum = checksum
  end
end

function updateNameButton(self)
  local s = sessions.highlight_session
  self:SetText(session.getSessionName(s) or "-")
end

function updateDurationText(self)
  local duration_animation = self:GetParent().duration_animation
  local s = sessions.highlight_session
  if s then
    if not session.isCurrent(s) then
      duration_animation:Hide()
      
      local duration = session.getSessionDuration(s)
      self:SetTextColor(palette.color.white())
      self:SetText(abacus:FormatDurationFull(duration or 0))
    else
      if not duration_animation.seenLast then
        -- Matching: GameFontGreenSmall
        self:SetTextColor(0.1, 1.0, 0.1)
        self:SetText("-")
      end
      duration_animation.seenLast = GetTime()
      duration_animation.t0 = session.getSessionStart(s)
      duration_animation:Show()
    end
  else
    duration_animation:Hide()
    duration_animation.t0 = nil
    duration_animation.seenLast = nil
    -- Matching: GameFontRedSmall
    self:SetTextColor(1.0, 0.1, 0.1)
    self:SetText("-")
  end
end

function updateTotalValue(self)
  local s = sessions.highlight_session
  self:updateDisplay(session.getSessionTotalValue(s))
end

function updateCurrencyValue(self)
  local s = sessions.highlight_session
  self:updateDisplay(session.getSessionMoney(s))
end

function updateItemsText(self)
  local s = sessions.highlight_session
  self:updateDisplay(session.getSessionItemsCount(s, "items"))
end

function updateItemsValue(self)
  local s = sessions.highlight_session
  self:updateDisplay(session.getSessionItemsValue(s))
end

function updateHotText(self)
  local s = sessions.highlight_session
  self:updateDisplay(session.getSessionItemsCount(s, "hots"))
end

function updateHotValue(self)
  local s = sessions.highlight_session
  self:updateDisplay(session.getSessionItemsValue(s, "hots"))
end

do
  local find, len, gsub = string.find, string.len, string.gsub
  local format = string.format
  local utf8sub = util.utf8sub
  
  local function formatItem(record)
    return format("%sx %s %s",
      record.count, 
      record.item_link,
      abacus:FormatMoneyFull(record.value or 0, true, nil, true))
  end
  
  local function render(self, record)
    local max_width = self:GetParent():GetWidth()
    local text = formatItem(record)
    
    if not gui.fitStringWidth(self, text, max_width) then
      local _, _, item_name = find(text, "%[(.-)%]")
      local n = len(item_name)
      for length=n-1, 1 , -1 do
        text = gsub(text, "%[(.-)%]", function(name)
          return format("[%s]", utf8sub(name, 1, length))
        end)
        if gui.fitStringWidth(self, text, max_width) then
          text = gsub(text, "%[(.-)%]", function(name)
            return format("[%s...]", utf8sub(name, 1, length - 3))
          end)
          self:SetText(text)
          break
        end
      end
    end
  end
  
  local function attemptTofixWdbErrors(record)
    --Item tooltip trick to attempt fix links after WDB cache folder deleted
    if not record.rarity then
      gui.setItemTooltip(UIParent, "NONE", format("item:%s", record.code))
      GameTooltip:Show()
      
      local item_link, name, _, rarity = session.safeItemLink(record.code)
      record.item_link = item_link
      record.name = name
      record.rarity = rarity
      
      GameTooltip:Hide()        
    end
    return record
  end
  
  function updateMostValuable(self)
    local s = sessions.highlight_session
    local items = session.getSessionItems(s)
    local data = items and session.sortItemsByValue(items, true)
    local most_valued = data and data[1]
    
    if not most_valued then
      self:SetText("-")
    else
      attemptTofixWdbErrors(most_valued)
      render(self, most_valued)
    end
  end
end

--------------------------------------------------------------------------------

function sessions_OnShow()
  update()
end

do
  local strtrim, replace_vars = util.strtrim, util.replace_vars
  
  local editbox_dialog = gui.editboxDialog(nil, nil, L["Rename Session"])
  editbox_dialog:Hide()
  
  editbox_dialog.editbox:SetScript("OnTextChanged", function()
    local this_session = editbox_dialog.session    
    if not this_session then return end
    
    local current_value = this:GetText()
    local saved_value = session.getSessionName(this_session)
    if current_value ~= saved_value then
      this.border:SetBackdropBorderColor(palette.color.transparent())
    else
      this.border:SetBackdropBorderColor(palette.color.original())
    end
    local ok_button = editbox_dialog.ok_button
    if strtrim(current_value) ~= "" then
      ok_button:Enable()
    else
      ok_button:Disable()
    end
  end)
  
  editbox_dialog.editbox:SetScript("OnEnterPressed", function()
    editbox_dialog.ok_button:onClick()
  end)
  
  function editbox_dialog.ok_button:onClick()
    local this_session = editbox_dialog.session    
    if not this_session then return end
    
    local editbox = editbox_dialog.editbox
    local current_value = editbox:GetText()
    local zone = session.getSessionZone(this_session)
    local start = session.getSessionStart(this_session)
    
    session.setSessionName(this_session, replace_vars{
      current_value,
      zone = zone,
      start = session.isoDateTime(start, true)
    })
    
    editbox.border:SetBackdropBorderColor(palette.color.original())
    editbox_dialog:Hide()
    A:guiUpdate()
  end
  
  function renameOnClick(self)
    local this_session = self.session
    if not this_session or editbox_dialog:IsVisible() then return end
    
    PlaySound(gui.sounds.click)
    gui.cursorAnchor(editbox_dialog, "BOTTOMRIGHT")
    
    local editbox = editbox_dialog.editbox
    editbox:SetText(session.getSessionName(this_session))
    editbox_dialog.session = this_session
    editbox_dialog:Show()
    editbox:HighlightText()
    editbox:SetFocus()
  end
end

do
  local find, len, gsub = string.find, string.len, string.gsub
  local format = string.format
  local utf8sub = util.utf8sub
  
  local function formatStatus(status)
    return format('%s [%d] "%s" %s',
      status.code, 
      status.index,
      status.name,
      status.total)
  end
  
  local function render(entry, row)
    local fontstring = entry.button.text
    local text = formatStatus(row)
    local max_width = fontstring:GetWidth()
    local n = len(row.name)
    if not gui.fitStringWidth(fontstring, text, max_width) then
      for length=n-1,1,-1 do
        row.name = utf8sub(row.name, 1, length)
        text = formatStatus(row)
        if gui.fitStringWidth(fontstring, text, max_width) then
          row.name = format("%s...", utf8sub(row.name, 1, length - 3))
          text = formatStatus(row)
          fontstring:SetText(text)
          break
        end
      end
    end
  end
  
  do
    local wipe = util.wipe
    
    local previous_checksum
    
    local function neq(previous, current)
      return previous and current and previous ~= current
    end
    
    function resetCheck(slider, info)
      local checksum = session.getSessionsChecksum()
      if neq(previous_checksum, checksum) then
        slider:reset()
        wipe(info.checked)
      end
      previous_checksum = checksum
    end
  end
  
  function scrollFrameFauxUpdate(self, scroll_frame_index)
    local info = self[scroll_frame_index]
    local scroll_frame = info.object
    FauxScrollFrame_Update(scroll_frame, info.data_size, info.display_size, 
      info.entry_height)

    local entries = info.entries
    local offset = FauxScrollFrame_GetOffset(scroll_frame)
    for id=1,info.display_size do      
      local entry = entries[id]
      if not entry then 
        A.error("No entry object found. Id: %d.", id)
        break 
      end
      
      local position = id + offset
      local row = info.data and info.data[position]
      if not row or position > info.data_size then
        entry.checkbox:SetChecked(false)
        entry:Disable()
        entry:Hide()
      else
        render(entry, row)
        
        entry.session_index = row.index
        entry.session = row.session
        entry.checkbox:SetChecked(info.checked[row.session])
        
        entry:Enable()
        entry:Show()
      end
    end
    resetCheck(scroll_frame.slider, info)
  end
  
  function scrollFrame_OnVerticalScroll()
    local parent = this:GetParent()
    FauxScrollFrame_OnVerticalScroll(parent["sframe1"].entry_height, 
      function() parent:scrollFrameFauxUpdate("sframe1") end)
  end
end

do
  local function countChecked(info)
    local count = 0
    for k,v in pairs(info.checked) do
      if v then
        count = count + 1
      end
    end
    return count, info.data_size or 0
  end
  
  function checkOnClick(self)
    local entry = self:GetParent()
    local info = entry.info
    
    info.checked[entry.session] = self:GetChecked()
    
    local count, total = countChecked(info)
    if count == 0 then
      selectall_checkbox:hideIndeterminate()
      selectall_checkbox:SetChecked(false)
    elseif count > 0 and count < total then
      selectall_checkbox:SetChecked(false)
      selectall_checkbox:showIndeterminate()
    elseif count == total then
      selectall_checkbox:hideIndeterminate()
      selectall_checkbox:SetChecked(true)
    else
      A.error("Invalid checked count.")
      return
    end
  end

  function selectallOnClick(self, scroll_frame_index)
    if not session.getSessions() then 
      self:SetChecked(false)
      return
    end
    
    self:hideIndeterminate()
    local status = self:GetChecked()
    
    local parent = self:GetParent()
    local info = parent[scroll_frame_index]
    
    if info.data then
      for i,record in ipairs(info.data) do
        info.checked[record.session] = status
      end
    end
    
    local entries = info.entries
    for i,entry in ipairs(entries) do
      if entry:IsEnabled() then
        local checkbox = entry.checkbox
        checkbox:SetChecked(status)
      end
    end
  end
end

function uncheckAll(info)
  if info.data then
    for i,record in ipairs(info.data) do
      info.checked[record.session] = false
    end
  end
  
  local entries = info.entries
  for i,entry in ipairs(entries) do
    if entry:IsEnabled() then
      entry.checkbox:SetChecked(false)
    end
  end
  
  selectall_checkbox:hideIndeterminate()
  selectall_checkbox:SetChecked(false)
end

do  
  function deletedSelected_OnEnter()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:AddLine(L["Delete Selected"], 1, 1, 1)
    GameTooltip:AddLine(L["Delete selected sessions"])
    GameTooltip:Show()
  end
  
  function deletedSelected_OnLeave()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
  
  function deleteSelectedOnClick(self, frame, scroll_frame_index)
    local parent = frame:GetParent()
    local info = parent[scroll_frame_index]
    if not info.data then return end
    
    local deletions = {}
    for i,record in ipairs(info.data) do
      if info.checked[record.session] then
        tinsert(deletions, record.session)
      end
    end
    
    if getn(deletions) > 0 then
      uncheckAll(info)
      for i,to_delete in ipairs(deletions) do
        session.deleteSessionByRef(to_delete)
      end
    end
  end
end

do
  function purgeAll_OnEnter()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:AddLine(L["Purge All"], 1, 1, 1)
    GameTooltip:AddLine(L["Delete ALL sessions"])
    GameTooltip:Show()
  end
  
  function purgeAll_OnLeave()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
  
  function purgeAllConfirmOnClick(self)
    if not session.getSessions() then return end
    
    StaticPopup_Show(purgeall_confirm_dialog_name)
  end
  
  function purgeAllOnClick(self, frame, scroll_frame_index)
    if not session.getSessions() then return end
    
    local parent = frame:GetParent()
    local info = parent[scroll_frame_index]
    
    uncheckAll(info)
    PlaySoundFile(gui.sounds.file_purge)
    session.purgeSessions()
  end
end

do
  function updateSession_OnEnter()
    sessions.highlight_session = this.session
    update()
  end
  
  function clearSession_OnLeave()
    sessions.highlight_session = nil
    update()
  end
end

do
  function durationAnimation_OnUpdate()
    if not this.seenLast then return end
    if (GetTime() - this.seenLast) >= this.interval then
      -- Matching: GameFontGreenSmall
      duration_text:SetTextColor(0.1, 1.0, 0.1)
      local duration = session.diffTime(session.currentTime(), this.t0)
      duration_text:SetText(
        abacus:FormatDurationFull(duration or 0))
      this.seenLast = GetTime()
    end
  end
end
