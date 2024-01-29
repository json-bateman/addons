-- Utility functions across games --
function Tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
          print(formatting)
          Tprint(v, indent+1)
        elseif type(v) == 'boolean' then
          print(formatting .. tostring(v))      
        else
          print(formatting .. v)
        end
    end
end

function ChatMsg(msg, chatType, language, channel)
	SendChatMessage(msg, chatType, language, channel)
end

function MakeNameString(players)
    local nameString = players[1].name
    if (#players > 1) then
        for i = 2, #players do
            if (i == #players) then
                nameString = nameString .. " and " .. players[i].name
            else
                nameString = nameString .. ", " .. players[i].name
            end
        end
    end

    return nameString
end