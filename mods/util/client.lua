local A = FonzAppraiser

A.module 'util.client'

local GetBuildInfo = _G.GetBuildInfo

function M.getClient()
  local display_version, build_number, build_date, ui_version = GetBuildInfo()
  ui_version = ui_version or 11200
  return ui_version, display_version, build_number, build_date
end

do 
  local ui_version = getClient()
  M.ui_version = ui_version
  
  if not ui_version or ui_version <= 11200 then
    M.is_vanilla = true
  else
    M.is_not_vanilla = true
    
    if ui_version >= 20000 and ui_version <= 20400 then
      M.is_tbc = true
    elseif ui_version >= 30000 and ui_version <= 30300 then
      M.is_wotlk = true
    else
      M.is_unknown = true
      -- Set unknown compatibility to latest supported game version for best 
      -- chance to run
      M.is_wotlk = true
    end
  end
  
  if is_tbc or is_vanilla then
    M.is_tbc_or_less = true
  end
  
  if is_wotlk or is_tbc or is_vanilla then
    M.is_wotlk_or_less = true
  end
  
  if is_tbc or is_wotlk or is_unknown then
    M.is_tbc_or_more = true
  end
  
  -- Set unknown compatibility to latest supported game version for best 
  -- chance to run
  if is_wotlk or is_unknown then
    M.is_wotlk_or_more = true
  end
end
