local _, gambling = ...

local session = {
   players = {},
   payout = 0,
   results = nil,
   gameState = GameStates[1],
   highTiebreaker = false,
   lowTiebreaker = false,
}

local game = gambling.game

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
   if (game.chatChannel ~= "SAY") then -- "SAY" channel is protected from spam
      ChatMsg(format("%s has been added to gamba!", playerName), ChatChannels)
   end
end

local function updateOverallStats(player, amount)
   DB.stats = DB.stats or {}
   -- if they are already in table
   for i = 1, #DB.stats do
      if (DB.stats[i].name == player.name) then
         DB.stats[i].totalWinnings = DB.stats[i].totalWinnings + amount;
         return
      end
   end
   -- if they aren't in table add them
   local addedPlayer = {
      name = player.name,
      totalWinnings = amount,
   }
   tinsert(DB.stats, addedPlayer)
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
         tinsert(playersToRoll, participants[i])
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
   local winners = { participants[1] }
   local losers = { participants[1] }
   local amountOwed = 0
   for i = 2, #participants do
      if (participants[i].roll < losers[1].roll) then
         losers = { participants[i] }
      elseif (participants[i].roll > winners[1].roll) then
         winners = { participants[i] }
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
chatFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")

function OpenEntries()
   if (session.gameState ~= GameStates[1]) then
      print("Incorrect game state, cannot open entries")
      return
   end
   print(game.chatChannel)
   ChatMsg(".:MommaG's Casino:. --Classic Roll Off!--", game.chatChannel)
   ChatMsg(format("Please type `%s` to join the round (type `%s` to leave).", game.enterMessage, game.leaveMessage),
      game.chatChannel)
   ChatMsg(format("Current Stakes are: %sg", game.wager), game.chatChannel)
   --ChatMsg(format("Current Stakes are: %sg", game.wager, game.chatChannel))

   chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
      -- Name comes in like this [playerName]-[realm]
      -- i.e. Mommadeez-CrusaderStrike
      -- So we must split name before adding to table.
      local playerName, _ = string.split('-', name)

      if (((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID") or (event == "CHAT_MSG_RAID_LEADER")) and msg == game.enterMessage) then
         addPlayer(playerName)
      elseif (((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID") or (event == "CHAT_MSG_RAID_LEADER")) and msg == game.leaveMessage) then
         removePlayer(playerName)
      end
   end)
end

function StartRoll()
   if (#session.players < 1) then
      print("At least 1 person needs to join before rolling begins")
      return
   end
   if (session.gameState == GameStates[1]) then
      session.gameState = GameStates[2]
   else
      print(format("Rolls already begun. Current state is %s, current roll is %s", session.gameState, game.max));
      return
   end

   ChatMsg("Begin rolling you degenerate gamblers!", game.chatChannel)
   chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
      if (event == "CHAT_MSG_SYSTEM") then
         handleSystemMessage(self, msg)
      end
   end)
end

function FinishRoll()
   if (session.gameState ~= GameStates[2]) then
      print("Incorrect game state, game state is currently ", session.gameState)
      return
   end
   local playersToRoll = checkPlayerRolls(session.players);
   if (#playersToRoll > 0) then
      ChatMsg("Some players still need to roll!", game.chatChannel)
      --SendChatMessage("Some players still need to roll!")
      ChatMsg(MakeNameString(playersToRoll), game.chatChannel)
      return
   end
   local results = determineResults(session.players)
   if (results == nil) then return end
   -- store initial payout, result of first round of rolls
   if (session.results == nil) then
      session.results = results
   end

   -- Tiebreaker Logic --
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
   elseif (results ~= nil and #session.results.losers > 1) then
      session.lowTiebreaker = true
      session.players = results.losers
      for _, player in ipairs(session.players) do
         player.roll = nil
      end
      SendChatMessage("Low end tie breaker! " .. MakeNameString(session.players) .. " /roll now!")
   else
      -- No Ties, no tiebreaker needed, display results:
      ChatMsg(
         format("%s owes %s: %d Gold %d Silver! Lmao rekt and also got em.", session.results.losers[1].name,
            session.results.winners[1].name, math.floor(session.results.amountOwed / 100),
            session.results.amountOwed % 100), game.chatChannel)
      -- Reset important game state variables
      -- Add stats to database
      updateOverallStats(session.results.winners[1], session.results.amountOwed)
      updateOverallStats(session.results.losers[1], -session.results.amountOwed)
      ResetRollGame()
   end
end

function ResetRollGame()
   session.players = {};
   session.payout = 0;
   session.results = nil;
   session.gameState = GameStates[1];
   session.highTiebreaker = false;
   session.lowTiebreaker = false;
   print("Game has been reset.")
end
