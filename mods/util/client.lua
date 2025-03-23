local A = FonzAppraiser

A.module 'util.client'

do -- VERSION
  local GetBuildInfo = _G.GetBuildInfo

  function M.getClient()
    local display_version, build_number, build_date, ui_version = GetBuildInfo()
    ui_version = ui_version or 11200
    return ui_version, display_version, build_number, build_date
  end
  
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

do -- CONTENT
  local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
  local MAX_PLAYER_LEVEL_TABLE  = _G.MAX_PLAYER_LEVEL_TABLE
  
  local expansion = GetAccountExpansionLevel ~= nil and GetAccountExpansionLevel() or 0
  local content = {}
  M.content = content

  content.VANILLA = 0
  content.TBC = 1
  content.WOTLK = 2
  content.expansion = expansion
  content.maxPlayerLevel = MAX_PLAYER_LEVEL_TABLE ~= nil and MAX_PLAYER_LEVEL_TABLE[expansion] or 60
  
  content.has_vanilla = true
  if content.expansion >= content.TBC then
    content.has_tbc = true
  end
  
  if content.expansion >= content.WOTLK then
    content.has_wotlk = true
  end
end
