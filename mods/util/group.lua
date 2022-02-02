local A = FonzAppraiser

A.module 'util.group'

function M.isInParty()
  return GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0
end

function M.isInRaid()
  return GetNumRaidMembers() > 0
end

function M.isInGroup()
  return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
end