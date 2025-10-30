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
  
  local compat = {}
  M.compatibility = compat
  
  compat.VANILLA = 0
  compat.TBC = 1
  compat.WOTLK = 2
  compat.CATA = 3
  compat.MOP = 4
  compat.is_unknown = false
  
  function M.getCompatibility()
    if not ui_version or ui_version <= 11200 then 
      return compat.VANILLA
    elseif ui_version >= 20000 and ui_version <= 20400 then 
      return compat.TBC
    elseif ui_version >= 30000 and ui_version <= 30300 then
      return compat.WOTLK
    elseif ui_version >= 40000 and ui_version <= 40300 then
      return compat.CATA
    elseif ui_version >= 50000 and ui_version <= 50400 then
      return compat.MOP
    else
      compat.is_unknown = true
      return compat.MOP
    end
  end
  
  compat.version = getCompatibility()
 
    
  
  
  
  
end

do -- CONTENT
  local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
  local MAX_PLAYER_LEVEL_TABLE  = _G.MAX_PLAYER_LEVEL_TABLE
  
  local expansion = GetAccountExpansionLevel and GetAccountExpansionLevel() or 0
  local content = {}
  M.content = content

  content.VANILLA = 0
  content.TBC = 1
  content.WOTLK = 2
  content.CATA = 3
  content.MOP = 4
  content.expansion = expansion
  content.maxPlayerLevel = MAX_PLAYER_LEVEL_TABLE and 
    MAX_PLAYER_LEVEL_TABLE[expansion] or 60
  
  
end