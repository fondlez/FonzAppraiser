local A = FonzAppraiser

A.module 'fa.gui.summary'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.string',
  'util.time',
  'util.money',
  'util.chat'
)

local palette = A.require 'fa.palette'
local notice = A.require 'fa.notice'
local session = A.require 'fa.session'
local misc = A.require 'fa.misc'
local gui = A.require 'fa.gui'
local main = A.require 'fa.gui.main'

function M.update()
  if not summary:IsVisible() then return end
  
  scroll_frame:update()
  
  name_button:update()
  duration_text:update()
  total_value:update()
  currency_value:update()
  items_text:update()
  items_value:update()
  hot_text:update()
  hot_value:update()
  
  start_button:update()
  stop_button:update()
  
  target_value:update()
  progress_bar:update()
end

do
  local safeItemLink = session.safeItemLink
  local isoTime, isoDateTime = session.isoTime, session.isoDateTime
  local getCurrentItems = session.getCurrentItems
  local getCurrentLootAndMoney = session.getCurrentLootAndMoney
  
  local function transformItem(item)
    --Item tooltip trick to attempt fix links after WDB cache folder deleted.
    if not item["item_link"] then
      gui.setItemTooltip(UIParent, "NONE", item["item_string"])
      GameTooltip:Show()
      item["item_link"] = safeItemLink(item["code"])
      GameTooltip:Hide()
    end
    
    local row = format("%s %sx %s %s",
      isoTime(item["loot_time"]),
      item["count"],
      item["item_link"],
      abacus:FormatMoneyFull(item["value"], true))
      
    local hots = getCurrentItems("hots")
    local extra_data_record = {
      ["from"] = item["zone"],
      ["when"] = isoDateTime(item["loot_time"]),
      ["item_link"] = item["item_link"],
      ["item_string"] = item["item_string"],
      ["pricing"] = item["pricing"],
      ["is_hot"] = hots[item.code],
      ["price"] = math.floor(item["value"]/item["count"]),
    }
    
    return row, extra_data_record
  end
  
  local function transformMoney(record)
    local row = format(L["%s Money - %s: %s"],
      isoTime(record["loot_time"]),
      record["type"],
      abacus:FormatMoneyFull(record["money"], true))
    
    local extra_data_record = {
      ["from"] = record["zone"],
      ["when"] = isoDateTime(record["loot_time"]),
      ["type"] = record["type"],
      ["is_hot"] = true,
    }
    
    return row, extra_data_record
  end

  function updateScrollFrame(self)
    local parent = self:GetParent()
    local info = parent["sframe1"]
    local loots = getCurrentLootAndMoney()
    if loots then
      local data, extra_data = {}, {}
      local n = getn(loots)
      local m = math.max(n - info.max_size + 1, 1)
      for i=n, m, -1 do
        local record = loots[i]
        
        local row, extra_data_record
        if record["count"] then
          row, extra_data_record = transformItem(record)
        else
          row, extra_data_record = transformMoney(record)
        end
        
        tinsert(data, row)
        tinsert(extra_data, extra_data_record)
      end
      info.data = data
      info.extra_data = extra_data
      info.data_size = n < info.max_size and n or info.max_size
    else
      info.data = nil
      info.extra_data = nil
    end
    parent:scrollFrameFauxUpdate("sframe1")
  end
end

function updateNameButton(self)
  self:SetText(session.getCurrentName() or "-")
end

function updateDurationText(self)
  local duration_animation = self:GetParent().duration_animation
  if session.isCurrent() then
    if not duration_animation.seenLast then
      -- Matching: GameFontGreenSmall
      self:SetTextColor(0.1, 1.0, 0.1)
      self:SetText("-")
    end
    duration_animation.seenLast = GetTime()
    duration_animation.t0 = session.getCurrentStart()
    duration_animation:Show()
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
  self:updateDisplay(session.getCurrentTotalValue())
end

function updateCurrencyValue(self)
  self:updateDisplay(session.getCurrentMoney())
end

function updateItemsText(self)
  self:updateDisplay(session.getCurrentItemsCount("items"))
end

function updateItemsValue(self)
  self:updateDisplay(session.getCurrentItemsValue())
end

function updateHotText(self)
  self:updateDisplay(session.getCurrentItemsCount("hots"))
end

function updateHotValue(self)
  self:updateDisplay(session.getCurrentHotsValue())
end

function updateStartButton(self)
  local found, current = session.isCurrent()
  if not found then
    self:SetText(L["Start Session"])
  else
    self:SetText(L["New Session"])
  end
end

function updateStopButton(self)
  local found, current = session.isCurrent()
  if not found then
    self:Disable()
  else
    self:Enable()
  end
end

function updateTargetValue(self)
  local value, goal = notice.getTarget()
  self:updateDisplay(tonumber(value), tonumber(goal))
end

function updateProgressBar(self)
  local value, goal = notice.getTarget()
  value = tonumber(value)
  goal = tonumber(goal)
  if goal and goal > 0 then
    self:SetMinMaxValues(0, goal)
    self:SetValue(value or 0)
    if value and value >= goal and not self.notified then
      self.glow_animation:play()
      self.shine_animation:play()
      self.notified = true
    end
  else
    self:SetMinMaxValues(0, 0)
    self:SetValue(0)
  end
  if not goal or not value or value < goal then
    self.notified = false
  end
end

--------------------------------------------------------------------------------

function summary_OnShow()
  update()
end

do
  local find, len, gsub = string.find, string.len, string.gsub
  local format = string.format
  local utf8sub = util.utf8sub
  
  local function render(entry, row)
    local fontstring = entry.text
    local max_width = fontstring:GetWidth()
    if not gui.fitStringWidth(fontstring, row, max_width) then
      local _, _, item_name = find(row, "%[(.-)%]")
      local n = len(item_name)
      for length=n-1, 1 , -1 do
        row = gsub(row, "%[(.-)%]", function(name)
          return format("[%s]", utf8sub(name, 1, length))
        end)
        if gui.fitStringWidth(fontstring, row, max_width) then
          row = gsub(row, "%[(.-)%]", function(name)
            return format("[%s...]", utf8sub(name, 1, length - 3))
          end)
          fontstring:SetText(row)
          break
        end
      end
    end
  end
  
  local function highlightEntry(entry)
    entry:SetBackdrop{
      bgFile=[[Interface\Buttons\UI-Listbox-Highlight]]
    }
  end
  
  local function unhighlightEntry(entry)
    entry:SetBackdrop(nil)
  end
  
  local function importExtraData(entry, extra_data)
    --Manage tooltip
    entry.item_link = extra_data["item_link"] --chat link + dressing link
    entry:SetScript("OnEnter", function()
      local records = {}
      tinsert(records, { desc=L["Zone:"], value=extra_data["from"] })
      tinsert(records, { desc=L["When:"], value=extra_data["when"] })
      local item_string = extra_data["item_string"]
      if item_string then
        --Clearly an item so add item fields
        tinsert(records, { desc=L["Pricing:"], value=extra_data["pricing"] })
        tinsert(records, { desc=L["Price:"], 
          value=abacus:FormatMoneyFull(extra_data["price"], true) })
        if extra_data["is_hot"] then
          tinsert(records, { desc=L["Notice:"], value=L["Hot"] })
        end
        gui.setItemTooltip(this, "ANCHOR_BOTTOMRIGHT", item_string, 
          records)
      else
        --Not an item, so no initial item tooltip information
        tinsert(records, { desc=L["Notice:"], value=L["Money"] })
        tinsert(records, { desc=L["Type:"], value=extra_data["type"] })
        gui.setRecordTooltip(this, "ANCHOR_BOTTOMRIGHT", records)
      end
    end)
    entry:SetScript("OnLeave", gui.hideTooltip)
    
    --Highlight Hot items
    if extra_data["is_hot"] then
      highlightEntry(entry)
    else
      unhighlightEntry(entry)
    end
  end
  
  do
    local previous_quality, previous_checksum
    
    local function neq(previous, current)
      return previous and current and previous ~= current
    end
    
    function sliderResetCheck(slider)
      local current_quality = main.quality_dropdown.selectedValue
      local checksum = session.getSessionsChecksum()
      if not session.isCurrent()
          or neq(previous_quality, current_quality) 
          or neq(previous_checksum, checksum) then
        slider:reset()
      end
      previous_quality = current_quality
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
        entry:Disable()
        entry:Hide()
      else
        render(entry, row)
        
        local extra_data = info.extra_data[position]
        if extra_data then
          importExtraData(entry, extra_data)
        else
          A.warn("scrollFrameFauxUpdate: no extra data found. Pos: %d", 
            position)
        end
        
        entry:Show()
        entry:Enable()
      end
    end
    sliderResetCheck(scroll_frame.slider)
  end
  
  function scrollFrame_OnVerticalScroll()
    local parent = this:GetParent()
    FauxScrollFrame_OnVerticalScroll(parent["sframe1"].entry_height, 
      function() parent:scrollFrameFauxUpdate("sframe1") end)
  end
end

do
  local strtrim, replace_vars = util.strtrim, util.replace_vars
  
  function nameButtonTooltip_OnEnter()
    if not session.isCurrent() then return end
    
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:AddLine(L["Click to rename session"])
    GameTooltip:Show()
  end
  
  function nameButtonTooltip_OnLeave()
    if not session.isCurrent() then return end
    
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
  
  local editbox_dialog = gui.editboxDialog(nil, nil, L["Rename Session"])
  editbox_dialog:Hide()
  
  editbox_dialog.editbox:SetScript("OnTextChanged", function()
    if not session.isCurrent() then return end
    
    local current_value = this:GetText()
    local saved_value = session.getCurrentName()
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
    if not session.isCurrent() then return end
    
    local editbox = editbox_dialog.editbox
    local current_value = editbox:GetText()
    local zone = session.getCurrentZone()
    local start = session.getCurrentStart()
    session.setCurrentName(replace_vars{
      current_value,
      zone = zone,
      start = session.isoDateTime(start, true)
    })
    editbox.border:SetBackdropBorderColor(palette.color.original())
    editbox_dialog:Hide()
    A:guiUpdate()
  end
  
  function nameButton_OnClick()
    if not session.isCurrent() or editbox_dialog:IsVisible() then return end
    
    PlaySound(gui.sounds.click)
    gui.cursorAnchor(editbox_dialog, "BOTTOMRIGHT")
    editbox_dialog.editbox:SetText(session.getCurrentName())
    editbox_dialog:Show()
    editbox_dialog.editbox:HighlightText()
    editbox_dialog.editbox:SetFocus()
  end
end

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

do
  function currencyLabelTooltip_OnEnter()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    
    local db = A.getCharConfig("fa.notice")
    local threshold = tonumber(db.money_threshold)
    GameTooltip:AddLine(L["Notice Money"], 1, 1, 1)
    GameTooltip:AddLine(format(L["Threshold: %s"], 
      threshold and abacus:FormatMoneyFull(threshold, true)
      or NONE))
      
    GameTooltip:Show()
  end
  
  function currencyLabelTooltip_OnLeave()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
end

do
  function hotItemTooltip_OnEnter()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    
    local db = A.getCharConfig("fa.notice")
    local threshold = tonumber(db.item_threshold)
    GameTooltip:AddLine(L["Notice Item"], 1, 1, 1)
    GameTooltip:AddLine(format(L["Threshold: %s"], 
      threshold and abacus:FormatMoneyFull(threshold, true)
      or NONE))
      
    GameTooltip:Show()
  end
  
  function hotItemTooltip_OnLeave()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
  end
end

do
  function startButton_OnClick()
    PlaySoundFile(gui.sounds.file_open_page)
    session.startSession()
    update()
  end
  
  function stopButton_OnClick()
    PlaySoundFile(gui.sounds.file_close_page)
    session.stopSession()
    update()
  end
end

do
  function progressBar_OnShow()
    this:update()
  end
  
  do
    local tooltip
    
    function progressBar_OnEnter()
      local _, target = notice.getTarget()
      local n = tonumber(target) or 0
      if n < 1 then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:AddLine(L["Click to set session value target"])
        GameTooltip:Show()
        tooltip = true
      end
    end
    
    function progressBar_OnLeave()
      if tooltip then
        GameTooltip:ClearLines()
        GameTooltip:Hide()
        tooltip = false
      end
    end
  end

  do 
    local money_dialog = gui.moneyInputDialog(main.frame)
    
    money_dialog.ok_button.onClick = function(self)
      local parent = self:GetParent()
      local gold, silver, copper = parent.money_input:getValue()
      local copper_value = util.baseMoney(gold, silver, copper)
      notice.changeTarget(copper_value)
      if copper_value > 0 then
        PlaySoundFile(gui.sounds.file_numeric_input_ok)
      end
      parent:Hide()
    end
    
    function progressBar_OnClick()
      PlaySound(gui.sounds.click)
      if not money_dialog:IsVisible() then
        gui.cursorAnchor(money_dialog, "BOTTOMRIGHT")
        local _, target = notice.getTarget()
        money_dialog.money_input:setValue(target and target == NONE and 0 
          or target)
        money_dialog:Show()
      end
    end
  end
  
  function progressBar_OnValueChanged()
    local value = this:GetValue()
    local spark = this.spark
    local pmin, pmax = this:GetMinMaxValues()
    if value and value > 0 and value < pmax then
      this:SetBackdropBorderColor(this.border_color())
      if pmax > pmin then
        local pos = (value - pmin) / (pmax - pmin)
        local width = this.background.width
        spark:SetPoint("LEFT", this, "LEFT", pos * width - 4, 0)
        spark:Show()
        this.fill_text:SetText(format("%d%%", floor(pos*100)))
        return
      end
    elseif value and value > 0 and value >= pmax then
      this:SetBackdropBorderColor(palette.color.yellow())
      this.fill_text:SetText("100%")
    else
      this:SetBackdropBorderColor(this.border_color())
      this.fill_text:SetText("")
    end
    spark:Hide()
  end

  do
    local RAMP_TIME, DECAY_TIME = 0.5, 2.5
    local RAMP_STEP = 1/RAMP_TIME
    local DECAY_STEP = 1/(DECAY_TIME - RAMP_TIME)
    
    function glowAnimation_OnUpdate()
      local glow = this:GetParent().glow
      local t = GetTime() - this.t0
      if t <= RAMP_TIME then
        glow:SetAlpha(t * RAMP_STEP)
      elseif t <= DECAY_TIME then
        glow:SetAlpha(1 - (t - RAMP_TIME) * DECAY_STEP)
      else
        glow:SetAlpha(0)
        this:Hide()
      end
    end
    
    function playGlowAnimation(self)
      self.t0 = GetTime()
      self:Show()
    end
  end
  
  do
    local RAMP_TIME, HOLD_TIME, DECAY_TIME = 0.3, 0.5, 2.5
    local DECAY_STEP = 1/(DECAY_TIME - HOLD_TIME)
    local DECAY_WEIGHTING = 1
    local SPOT_TIME, SWEEP_TIME = RAMP_TIME, DECAY_TIME
    local SWEEP_STEP = 1/(SWEEP_TIME - SPOT_TIME)
    local step = 1
    
    function shineAnimation_OnUpdate()
      local shine = this:GetParent().shine
			local t = GetTime() - this.t0
			if t <= SPOT_TIME then
				shine:SetPoint("TOPLEFT", progress_bar, 8, -3)
			elseif t <= SWEEP_TIME then
				shine:SetPoint("TOPLEFT", progress_bar, 
          8 + (t - SPOT_TIME) * SWEEP_STEP * this.distance, -3)
			end
			if t <= RAMP_TIME then
				shine:SetAlpha(0)
			elseif t <= HOLD_TIME then
				shine:SetAlpha(1)
			elseif t <= DECAY_TIME then
				shine:SetAlpha(1 - (t - HOLD_TIME) * DECAY_STEP * DECAY_WEIGHTING^step)
        step = step + 1
			else
        step = 1
				shine:SetAlpha(0)
				this:Hide()
			end
    end
    
    function playShineAnimation(self)
      local progress_bar = self:GetParent()
      local shine = progress_bar.shine
			self.t0 = GetTime()
			self.distance = progress_bar:GetWidth() - shine:GetWidth() + 1
			self:Show()
    end
  end
end