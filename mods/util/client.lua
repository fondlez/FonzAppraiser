local A = FonzAppraiser

A.module 'util.client'

function M.getClient()
  local _, _, _, client = GetBuildInfo()
  client = client or 11200
  return client
end

do 
  local client = getClient()
  if client >= 20000 and client <= 20400 then
    M.is_tbc = true
  else
    M.is_vanilla = true
  end
end

