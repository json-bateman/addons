local _, gambling = ...

local session = {
    players = {},
    payout = 0,
    gameState = GameStates[1],
    highTiebreaker = false,
    lowTiebreaker = false,
}

local chatChannel = gambling.defaults.game.chatChannel
local game = gambling.defaults.game

-------------------------
-- Classic Gamble Functions
-------------------------
local function addPlayer(playerName)
    -- Ignore entry if player is already entered
    for i = 1, #session.players do
        if (session.players[i].name == playerName) then
            return
        end
    end
    local newPlayer = {
        name = playerName,
        roll = nil,
    }
    tinsert(session.players, newPlayer)
    print("player added")
    if (chatChannel ~= "SAY") then -- "SAY" channel is protected from spam
        SendChatMessage(format("%s has been added to gamba!", playerName))
    end
end

local function removePlayer(playerName)
    for i = 1, #session.players do
        if (session.players[i].name == playerName) then
            tremove(session.players, i)
            print("player removed")
            SendChatMessage(format("%s has been removed from gamba!", playerName))
            return
        end
    end
end

local function checkPlayerRolls(participants)
    local playersToRoll = {}
    for i = 1, #participants do
        if (participants[i].roll == nil) then
            tinsert(playersToRoll, participants[i].name)
        end
    end
    return playersToRoll
end

local function recordRoll(playerName, actualRoll, minRoll, maxRoll)
    if (tonumber(minRoll) == 1 and tonumber(maxRoll) == game.max and not session.tiebreaker) then
        for i = 1, #session.players do
            if (session.players[i].name == playerName and session.players[i].roll == nil) then
                session.players[i].roll = tonumber(actualRoll)
            end
        end
    end
end

local function handleSystemMessage(_, text)
    -- Parses system messages recieved by the Event Listener to find and record player rolls
    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, "^([^ ]+) .+ (%d+) %((%d+)-(%d+)%)%.?$")
    recordRoll(playerName, actualRoll, minRoll, maxRoll);
end

local function determineResults(participants)
    if #participants == 0 then
        return
    end
    local winners = {participants[1]}
    local losers = {participants[1]}
    local amountOwed = 0
    for i = 2, #participants do
        if (participants[i].roll < losers[1].roll) then
            losers = {participants[i]}
        elseif (participants[i].roll > winners[1].roll) then
            winners = {participants[i]}
        else
            -- Handle Ties
            if (participants[i].roll == winners[1].roll) then
                tinsert(winners, participants[i])
            elseif (participants[i].roll == losers[1].roll) then
                tinsert(losers, participants[i])
            end
        end
    end
    amountOwed = (winners[1].roll - losers[1].roll) * game.wager
    return {
        winners = winners,
        losers = losers,
        amountOwed = amountOwed,
    }
end

-------------------------
-- Running the Game
-------------------------

--Create frame to handle chat messages
local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_SAY")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_SYSTEM")

function OpenEntries()
    if (session.gameState ~= GameStates[1]) then
        print("Incorrect game state, cannot open entries")
        return
    end
    ChatMsg(".:MommaDeez's Casino:. --Classic Roll Off!--", chatChannel)
    ChatMsg(format("Please type `%s` to join the round (type `%s` to leave).", game.enterMessage, game.leaveMessage), chatChannel)
    ChatMsg(format("Current Stakes are: %sg", game.wager, chatChannel))

    chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
        -- Name comes in like this [playerName]-[realm]
        -- i.e. Mommadeez-CrusaderStrike
        -- So we must split name before adding to table.
        local playerName, _ = string.split('-', name)

        if ( ((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID")) and msg == game.enterMessage ) then
            addPlayer(playerName)
        elseif ( ((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID")) and msg == game.leaveMessage ) then
            removePlayer(playerName)
        end
    end)
end

function StartRoll()
    if (#session.players < 2) then 
        print("At least 2 people need to join before rolling begins")
        return
    end
    if (session.gameState == GameStates[1]) then
        session.gameState = GameStates[2]
    else
        print(format("Rolls already begun. Current state is %s, current roll is %s", session.gameState, game.max));
        return
    end

    ChatMsg("Begin rolling you degenerate gamblers!", chatChannel)
    chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
        if (event == "CHAT_MSG_SYSTEM") then
            handleSystemMessage(self, msg)
        end
    end)
end

function FinishRoll()
    if (session.gameState ~= GameStates[2]) then
        print("Incorrect game state, game state is currently %s", session.gameState)
        return
    end
    local playersToRoll = checkPlayerRolls(session.players);
    Tprint(playersToRoll)
    if (#playersToRoll > 0) then
        SendChatMessage("Some players still need to roll!")
        print(MakeNameString(playersToRoll))
    end
    local results = determineResults(session.players)
    if (results == nil) then return end
    -- store initial payout, result of first round of rolls
    if (session.results == nil) then
        session.results = results
    end

    if (session.highTiebreaker) then
        results = determineResults(session.players)
        if (results ~= nil and #results.winners == 1 and #results.losers == 1) then
            session.results.winners = results.winners
            session.highTiebreaker = false
        end
    end

    if (session.lowTiebreaker) then
        results = determineResults(session.players)
        if (results ~= nil and #results.winners == 1 and #results.losers == 1) then
            session.results.losers = results.losers
            session.lowTiebreaker = false
        end
    end

    if (results ~= nil and #session.results.winners > 1) then
        session.highTiebreaker = true
        session.players = results.winners
        for _, player in ipairs(session.players) do
            player.roll = nil
        end
        SendChatMessage("High end tie breaker! " .. MakeNameString(session.players) .. " /roll now!")
    elseif(results ~= nil and #session.results.losers > 1) then
        session.lowTiebreaker = true
        session.players = results.losers
        for _, player in ipairs(session.players) do
            player.roll = nil
        end
        SendChatMessage("Low end tie breaker! " .. MakeNameString(session.players) .. " /roll now!")
    else
        -- No Ties, no tiebreaker needed, display results: 
        print(format("%s owes %s: %d Gold %d Silver! Lmao rekt and also got em.", session.results.losers[1].name, session.results.winners[1].name, math.floor(session.results.amountOwed/100), session.results.amountOwed % 100))
        SendChatMessage(format("%s owes %s: %d Gold %d Silver! Lmao rekt and also got em.", session.results.losers[1].name, session.results.winners[1].name, math.floor(session.results.amountOwed/100), session.results.amountOwed % 100))
        -- Reset important game state variables
        session.players = {};
        session.payout = 0;
        session.gameState = GameStates[1];
    end
end