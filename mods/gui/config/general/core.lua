local A = FonzAppraiser
local L = A.locale

A.module 'fa.gui.general'

local util = A.requires(
  'util.string',
  'util.money'
)

local palette = A.require 'fa.palette'
local gui = A.require 'fa.gui'
local config = A.require 'fa.gui.config'
local minimap = A.require 'fa.gui.minimap'

local defaults = {
  show_minimap = true,
}
A.registerCharConfigDefaults("fa.gui.general", defaults)

function M.update()
  if not general:IsVisible() then return end
  
  minimap_checkbox:update()
  enable_checkbox:update()
  confirm_oldest_checkbox:update()
end

function updateMinimapCheckbox(self)
  local db = A.getCharConfig("fa.gui.general")
  self:SetChecked(db.show_minimap)
  minimap.showOnSetting(db.show_minimap)
end

function updateEnableCheckbox(self)
  self:SetChecked(A:isEnabled())
end

function updateConfirmOldestCheckbox(self)
  local db = A.getCharConfig("fa.session")
  self:SetChecked(db.confirm_delete_oldest)
end

--------------------------------------------------------------------------------

function general_OnShow()
  update()
end

function minimapCheckboxOnClick(self)
  local db = A.getCharConfig("fa.gui.general")
  db.show_minimap = not db.show_minimap
  self:SetChecked(db.show_minimap)
  minimap.showOnSetting(db.show_minimap)
end

function enableCheckboxOnClick(self)
  local db = A.getCharConfig("fa")
  db.enable = not db.enable
  self:SetChecked(db.enable)
end

function confirmOldestCheckboxOnClick(self)
  local db = A.getCharConfig("fa.session")
  db.confirm_delete_oldest = not db.confirm_delete_oldest
  self:SetChecked(db.confirm_delete_oldest)
end