local A = FonzAppraiser

A.module 'util.chat'

function isempty(s)
  return s == nil or s == ''
end

function M.colorString(msg, color)
  color = color or "ffffffff"
  return string.format("|c%s%s|r", color, msg)
end

function M.systemChat(...)
  local result, message = pcall(string.format, unpack(arg))
  if not result then
    local t = {}
    for i, v in ipairs(arg) do
      t[i] = tostring(v)
    end
    message = table.concat(t, " ")
  end
  DEFAULT_CHAT_FRAME:AddMessage(message)
end

function M.chatMessage(msg, chat_type)
  if isempty(msg) then return end
  chat_type = chat_type or "GROUP"
  if tonumber(chat_type) then
    SendChatMessage(msg, "CHANNEL", nil, chat_type)
  else
    if chat_type == "GROUP" then
      SendChatMessage(msg, UnitInRaid("player") and "RAID" or "PARTY")
    else
      SendChatMessage(msg, chat_type)
    end
  end
end

function M.whisperMessage(target, msg)
  if isempty(target) or isempty(msg) then return end
  SendChatMessage(msg, "WHISPER", nil, target)
end