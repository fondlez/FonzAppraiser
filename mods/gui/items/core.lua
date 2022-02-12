local A = FonzAppraiser

A.module 'fa.gui.items'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.string',
  'util.time',
  'util.chat'
)

local filter = A.require 'fa.filter'
local session = A.require 'fa.session'
local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local main = A.require 'fa.gui.main'

function M.update()
  if not items:IsVisible() then return end
  
  session_dropdown:update()
  store_dropdown:update()
  
  zone_text:update()
  start_text:update()
  duration_text:update()
  currency_value:update()
  items_text:update()
  items_value:update()
  
  scroll_frame:update()
end

function updateZoneText(self)
  local index = session_dropdown.selected
  self:SetText(index and session.getSessionZoneByIndex(index) or "-")
end

function updateStartText(self)
  local index = session_dropdown.selected
  self:updateDisplay(session.getSessionStartByIndex(index))
end

function updateDurationText(self)
  local duration_animation = self:GetParent().duration_animation
  local index = session_dropdown.selected
  
  if index and session.isCurrentByIndex(index) then
    duration_animation.seenLast = GetTime()
    duration_animation.t0 = session.getSessionStartByIndex(index)
    duration_animation:Show()
  elseif session.getSessions() then
    duration_animation:Hide()
    duration_animation.t0 = nil
    duration_animation.seenLast = nil
    
    local duration = session.getSessionDurationByIndex(index)
    self:SetTextColor(palette.color.white())
    self:SetText(format("(%s)", abacus:FormatDurationFull(duration or 0)))
  else
    duration_animation:Hide()
    duration_animation.t0 = nil
    duration_animation.seenLast = nil
    self:SetText("")
  end
end

function updateCurrencyValue(self)
  local index = session_dropdown.selected
  self:updateDisplay(session.getSessionMoneyByIndex(index))
end

function updateItemsText(self)
  local index = session_dropdown.selected
  local store = store_dropdown.selected
  self:updateDisplay(session.getSessionItemsCountByIndex(index, store))
end

function updateItemsValue(self)
  local index = session_dropdown.selected
  local store = store_dropdown.selected
  self:updateDisplay(session.getSessionItemsValueByIndex(index, store))
end

function updateScrollFrame(self, sort_func)
  local parent = self:GetParent()
  local info = parent["sframe1"]
  local index = session_dropdown.selected
  local store = store_dropdown.selected
  local items = session.getSessionItemsByIndex(index, store)
  if items then
    local data
    if sort_func then
      data = sort_func(items)
    else
      data = session.sortItemsByValue(items, true)
    end
    
    local filtered_data = {}
    for i,record in ipairs(data) do
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
      --In case of WDB errors, attempt to show items even if no item rarity
      if not record.rarity or record.rarity >= filter.qualityAsRarity() then
        tinsert(filtered_data, record)
      end
    end
    
    info.data = filtered_data
    local n = getn(filtered_data)
    info.data_size = math.min(n, info.max_size)
  else
    info.data = nil
  end
  parent:scrollFrameFauxUpdate("sframe1")
end

--------------------------------------------------------------------------------

function items_OnShow()
  update()
end

do
  function updateSessionDropdown(self)
    --Check no stale sessions data, otherwise re-initialize
    local sessions_checksum = session.getSessionsChecksum()
    if self.checksum and sessions_checksum 
        and self.checksum ~= sessions_checksum then
      self:reset()
      return
    end
    
    if session.getSessions() and self.selected then
      UIDropDownMenu_SetSelectedValue(self, self.selected)
    else
      self.selected = nil
      UIDropDownMenu_ClearAll(self)
    end
  end
  
  local function onClick()
    local self = session_dropdown
    self.selected = this.value
    UIDropDownMenu_SetSelectedValue(self, self.selected)
    update()
  end
  
  local function formatStatus(status)
    return format('%s [%d] "%s" %s',
      status.code, 
      status.index,
      status.name,
      status.total)
  end

  function sessionDropdown_Initialize()
    local self = session_dropdown
    
    UIDropDownMenu_AddButton({text=L["Sessions"], isTitle = 1})
    local _, last_index = session.getLastSession()
    if not last_index then
      self.selected = nil
      self.checksum = nil
      UIDropDownMenu_ClearAll(self)
    else
      self.selected = self.selected or last_index
      self.checksum = session.getSessionsChecksum()
      local status = session.sessionStatus()
      for i=getn(status),1,-1 do
        local info = {}
        info.text = formatStatus(status[i])
        info.value = status[i].index
        info.owner = self
        info.func = onClick
        UIDropDownMenu_AddButton(info)
      end
      UIDropDownMenu_SetSelectedValue(self, self.selected)
    end
  end
  
  function resetSessionDropdown(self)
    self.selected = nil
    store_dropdown:reset()
    sessionDropdown_Initialize()
  end
end

do
  function updateStoreDropdown(self)
    UIDropDownMenu_SetSelectedValue(self, self.selected)
  end
  
  local function onClick()
    local self = store_dropdown
    self.selected = this.value
    UIDropDownMenu_SetSelectedValue(self, self.selected)
    update()
  end

  function storeDropdown_Initialize()
    local self = store_dropdown
    self.selected = self.selected or "items"
    for i,v in ipairs({
        { store="items", desc=L["All"] }, 
        { store="hots", desc=L["Hot"] },
    }) do
      local info = {}
      info.text = v.desc
      info.value = v.store
      info.owner = self
      info.func = onClick
      UIDropDownMenu_AddButton(info)
    end
    UIDropDownMenu_SetSelectedValue(self, self.selected)
  end
  
  function resetStoreDropdown(self)
    self.selected = nil
    storeDropdown_Initialize()
  end
end

function durationAnimation_OnUpdate()
  if not this.seenLast then return end
  if (GetTime() - this.seenLast) >= this.interval then
    -- Matching: GameFontGreenSmall
    duration_text:SetTextColor(0.1, 1.0, 0.1)
    local duration = session.diffTime(session.currentTime(), this.t0)
    duration_text:SetText(format("(%s)",
      abacus:FormatDurationFull(duration or 0)))
    this.seenLast = GetTime()
  end
end

function countButtonOnClick(self)
  local sort_toggle = function(items)
    return session.sortItemsByCount(items, self.reverse)
  end
  updateScrollFrame(scroll_frame, sort_toggle)
  self.reverse = not self.reverse
end

function itemButtonOnClick(self)
  local sort_toggle = function(items)
    return session.sortItemsByName(items, self.reverse)
  end
  updateScrollFrame(scroll_frame, sort_toggle)
  self.reverse = not self.reverse
end

function valueButtonOnClick(self)
  local sort_toggle = function(items)
    return session.sortItemsByValue(items, self.reverse)
  end
  updateScrollFrame(scroll_frame, sort_toggle)
  self.reverse = not self.reverse
end

do
  local find, len, gsub = string.find, string.len, string.gsub
  local format = string.format
  local utf8sub = util.utf8sub
  
  local function render(entry, row)
    entry.text1:SetText(format("%dx ", row["count"]))
    
    do
      local fontstring = entry.text2
      local max_width = fontstring:GetWidth()
      --WDB errors can make temp nil item values
      local item_link = row["item_link"] or "???"
      if not gui.fitStringWidth(fontstring, item_link, max_width) then
        local _, _, item_name = find(item_link, "%[(.-)%]")
        local n = item_name and len(item_name) or 0
        for length=n-1, 1 , -1 do
          item_link = gsub(item_link, "%[(.-)%]", function(name)
            return format("[%s]", utf8sub(name, 1, length))
          end)
          if gui.fitStringWidth(fontstring, item_link, max_width) then
            item_link = gsub(item_link, "%[(.-)%]", function(name)
              return format("[%s...]", utf8sub(name, 1, length - 3))
            end)
            fontstring:SetText(item_link)
            break
          end
        end
      end
    end
    
    --Final argument to custom Abacus library creates zero padding digits.
    entry.text3:SetText(abacus:FormatMoneyFull(row["value"] or 0, true, nil, 
      true))
  end
  
  local previous_quality, previous_checksum
  
  local function neq(previous, current)
    return previous and current and previous ~= current
  end

  local function sliderResetCheck(slider)
    local current_quality = main.quality_dropdown.selectedValue
    local checksum = session.getSessionsChecksum()
    if neq(previous_quality, current_quality) 
        or neq(previous_checksum, checksum) then
      slider:reset()
    end
    previous_quality = current_quality
    previous_checksum = checksum
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
        
        --Hover item tooltip
        entry.item_link = row["item_link"] --chat link + dressing link
        local item_string = format("item:%s", row["code"])
        local price = math.floor(row["value"]/row["count"])
        local extra_data = {
          { desc=L["Pricing:"], value=row["pricing"] },
          { desc=L["Price:"], value=price and
            abacus:FormatMoneyFull(price, true) or "-" },
        }
        entry:SetScript("OnEnter", function()
          gui.setItemTooltip(this, "ANCHOR_BOTTOMRIGHT", 
            item_string, extra_data)
        end)
        entry:SetScript("OnLeave", gui.hideTooltip)
        
        entry:Enable()
        entry:Show()
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