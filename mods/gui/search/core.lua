local A = FonzAppraiser

A.module 'fa.search'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.string',
  'util.time',
  'util.money',
  'util.chat'
)

local filter = A.require 'fa.filter'
local session = A.require 'fa.session'
local gui = A.require 'fa.gui'
local main = A.require 'fa.gui.main'

function M.update()
  if not search:IsVisible() then return end
  
  scroll_frame:update()
end

do
  local subtotal = session.lootSubtotal
  
  function updateScrollFrame(self)
    local parent = self:GetParent()
    local info = parent["sframe1"]
    local last_search = editbox.last_search
    local filters = last_search and filter.makeFilter(last_search)
    editbox.filters = filters
    
    local loots = session.searchAllLoot(filters)
    if loots and getn(loots) > 0 then
      local data, extra_data = {}, {}
      local n = getn(loots)
      local m = math.max(n - info.max_size + 1, 1)
      for i=n, m, -1 do
        local item = loots[i]
        if not item["item_link"] then
          --Item tooltip trick to attempt fix links after WDB cache folder 
          --deleted.
          gui.setItemTooltip(UIParent, "NONE", item["item_string"])
          GameTooltip:Show()
          item["item_link"] = session.safeItemLink(item["code"])
          GameTooltip:Hide()
        end
        
        local row = format("%s %s %sx %s %s",
          util.strTrunc(item["zone"], 12, "..."),
          session.isoTime(item["loot_time"]),
          item["count"],
          item["item_link"],
          abacus:FormatMoneyFull(item["value"], true))
          
        tinsert(data, row)
        tinsert(extra_data, {
          ["item_link"] = item["item_link"],
          ["item_string"] = item["item_string"],
          ["from"] = item["zone"],
          ["when"] = session.isoDateTime(item["loot_time"]),
          ["pricing"] = item["pricing"],
          ["price"] = math.floor(item["value"]/item["count"]),
        }) 
      end
      info.data = data
      info.extra_data = extra_data
      info.data_size = n < info.max_size and n or info.max_size
      loot_count_text:updateDisplay(n)
      
      local sum = subtotal(loots)
      item_count_text:updateDisplay(sum.count)
      item_value_text:updateDisplay(sum.value)
    else
      info.data = nil
      info.extra_data = nil
      loot_count_text:updateDisplay(0)
      item_count_text:updateDisplay(0)
      item_value_text:updateDisplay(0)
    end
    editbox_OnEnter(editbox)
    parent:scrollFrameFauxUpdate("sframe1")
  end
end

function search_OnShow()
  update()
end

function editboxOnEnterPressed(self)
  search_button:Click("LeftButton", false)
end

function searchButtonOnClick(self)
  local msg = editbox:GetText()
  if msg == L["Search"] then msg = nil end
  editbox.last_search = msg
  scroll_frame:update()
end

do
  local strim, isempty = util.strtrim, util.isempty
  
  function editbox_OnEnter(self)
    self = self or this
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:AddLine(L["Search Filters:"])
    local filters = self.filters
    if filters and next(filters, nil) then
      for k,v in pairs(filters) do
        local text = v and tostring(v)
        if type(v) == "table" then
          local _, first = next(v, nil)
          text = first and tostring(first)
          if text and getn(v) > 1 then
            text = text .. "..."
          end
        end
        GameTooltip:AddDoubleLine(k, text or "-")
      end
    else
      local str = self.last_search and strim(self.last_search)
      if isempty(str) then
        GameTooltip:AddLine(L["<empty>"])
      else
        GameTooltip:AddLine(L["<invalid>"])
      end
    end
    GameTooltip:Show()
  end
end

function editbox_OnLeave()
  GameTooltip:ClearLines()
  GameTooltip:Hide()
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
  
  local previous_quality
  
  local function neq(previous, current)
    return previous and current and previous ~= current
  end
  
  local function sliderResetCheck(slider)
    local current_quality = main.quality_dropdown.selectedValue
    if neq(previous_quality, current_quality) then
      slider:reset()
    end
    previous_quality = current_quality
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
          entry.item_link = extra_data["item_link"] --chat link + dressing link
          entry:SetScript("OnEnter", function()
            local item_string = extra_data["item_string"]
            local records = {}
            tinsert(records, { desc=L["Zone:"], value=extra_data["from"] })
            tinsert(records, { desc=L["When:"], value=extra_data["when"] })
            tinsert(records, { desc=L["Pricing:"], value=extra_data["pricing"] })
            tinsert(records, { desc=L["Price:"], 
              value=abacus:FormatMoneyFull(extra_data["price"], true) })
            gui.setItemTooltip(this, "ANCHOR_BOTTOMRIGHT", 
              item_string, records)
          end)
          entry:SetScript("OnLeave", gui.hideTooltip)
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