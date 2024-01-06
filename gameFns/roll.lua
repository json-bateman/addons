--Things to do: 
--  1. set up a chat function that announces a roll to the raid and sets gold amount (sort of done)
--  2. set up a function that takes inputs of some string or 1s and stores those players in a table (sort of done)
--  3. after the players are stored make a function that opens rolls and closes table and stores the rolls (sort of done)
--  4. ends the round compare the players rolls, highest is the winner, make exceptions for ties (sort of done, ties still not working)
--  5. optional stuff wink: if players go afk finish the round without them

-- note: Many of these methods were taken from RollCasino and WoWGoldGambler, respect the gamers


--GLOBALS
local vars = {
    chatEnterMsg = "gamer",
    chatWithdrawMsg = "poor", 
    currentChatMethod = "SAY"
}
 
local roundDefaults = {
	currentStakes = 0,
	entries = {
    }, --stores participants and their rolls
	entriesCount = 0,
	acceptEntries = false,
	acceptRolls = false,
    winner = nil,
    loser = nil,
	maxRollers = {},
	minRollers = {}, 
    highRoll = 0,
    lowRoll = 214749, --214,748g 36s 47c is max gold in WoW tbc
    preTieHigh = 0,
    preTieLow = 214749,
    tied = false,
    tieTable = {}
}

function TableLength(T) --table length function because table.getn({table}) is gaffed
    local count = 0
    for k,v in pairs(T) do count = count + 1 end
        return count
end

local round = roundDefaults
--Game logic

function ChatMsg(msg, chatType, language, channel)
	chatType = vars.currentChatMethod
	SendChatMessage(msg, chatType, language, channelnum)
end

local function AddPlayer(name)
    local charname, realmname = strsplit("-",name)
        if charname ~= nil and round.entries[charname] == nil then
            entrantInfo = { 
                name = charname,
                rolled = false,
                roll = -1,
                entered = true,
            }
            round.entries[charname] = entrantInfo
            round.entriesCount = round.entriesCount + 1

        elseif round.tied and charname ~= nil and round.entries[charname] == nil then --check for ties, add to tie table
            entrantInfo = { 
                name = charname,
                rolled = false,
                roll = -1,
                entered = true,
            }
            round.tieTable[charname] = entrantInfo
            round.entriesCount = round.entriesCount + 1
        else
            round.entries[charname].entered = true
        end
    print ("player added")
end 

local function GetMax(participants) --returns table of the high roller(s)
    for k,v in pairs(participants) do 
      if v.roll > round.highRoll then
        round.highRoll = v.roll
        round.maxRollers = {k}
      elseif v.roll == round.highRoll then 
        table.insert(round.maxRollers,k)
      end
    end
    return (round.maxRollers)
end

local function GetMin(participants) --returns table of the low roller(s)
    for k,v in pairs(participants) do
      if v.roll < round.lowRoll then
        round.lowRoll = v.roll
        round.minRollers = {k}
      elseif v.roll == round.lowRoll then 
        table.insert(round.minRollers,k)
      end 
    end 
    return (round.minRollers)
  end

local function ResetRound() --messy, figure out a way to reset to round defaults, table gets overridden currently
    currentStakes = 0
	entries = {} --stores participants and their rolls
	entriesCount = 0
	acceptEntries = false
	acceptRolls = false
    winner = nil
    loser = nil
	maxRollers = {}
	minRollers = {} 
    highRoll = 0
    lowRoll = 214749 --214,748g 36s 47c is max gold in WoW tbc
    preTieHigh = 0
    preTieLow = 214749
    tied = false
    tieTable = {}
end

local function ParseRoll(msg)
    local playerName, junk, roll, range = strsplit(" ", msg)
    local player = round.entries[playerName]
    --don't parse if player hasn't entered or has already rolled
        if player == nil or not player.entered or player.rolled or junk ~= "rolls" then 
	    	return
	    end 

    local minimum,maximum = strsplit("-", range);
    minimum = tonumber(strsub(minimum,2)) 
    maximum = tonumber(strsub(maximum,1,-2))
    roll = tonumber(roll)
    --don't parse if they roll outside minimum or maximum
        if minimum ~= 1 or maximum ~= round.currentStakes or roll > maximum or roll < minimum then 
            print('must roll', round.currentStakes)
            return
        end

    player.rolled = true
    player.roll = roll 
    round.entriesCount = round.entriesCount - 1

    if round.entriesCount == 0 then
        round.winner = GetMax(round.entries)
        round.loser = GetMin(round.entries)
        
        if TableLength(round.winner) > 1 then --check for high ties
            print ("There's a high tie!",round.highRoll)
            round.preTieHigh = round.highRoll
            round.preTieLow = round.lowRoll
            round.acceptRolls = true
            round.tied = true
            for k,roller in pairs(round.winner) do 
                print(k,roller)
                ChatMsg(format("There's a high tie at %s! --%s-- please re-roll.",round.highRoll, roller))
                AddPlayer(roller)
                round.entriesCount = round.entriesCount + 1
            end

        elseif TableLength(round.loser) > 1 then --check for low ties
            print ("There's a low tie!",round.lowRoll)
            round.preTieHigh = round.highRoll
            round.preTieLow = round.lowRoll
            round.acceptRolls = true
            round.tied = true
            for k,roller in pairs(round.loser) do 
                print(k,roller)
                ChatMsg(format("There's a low tie at %s! --%s-- please re-roll.",round.lowRoll, roller))
                AddPlayer(roller)
                round.entriesCount = round.entriesCount + 1
            end
            
        elseif round.tied then
            ChatMsg(format('Round over! %s owes %s: %sg!',round.loser[1],round.winner[1], round.preTieHigh - round.preTieLow ))
            ResetRound()
        else
            ChatMsg(format('Round over! %s owes %s: %sg!',round.loser[1],round.winner[1], round.highRoll - round.lowRoll ))
            ResetRound()
        end
    end
end

function ListRemainingPlayers()
	local strRollers = ""
	for player, info in pairs(round.entries) do
		if not info.rolled then
			local delim = ", "
			if strRollers == "" then
				delim = ""
			end

			strRollers = player..delim..strRollers
		end	
	end

	local msg = format("Remaining Rollers: %s", strRollers)
	if strRollers == "" then
		msg = "Everyone has rolled."
	end
	ChatMsg(msg)
end

local function GAMBLE_announce(stakes) 
    if type(tonumber(stakes)) ~= 'number' then
        print ('please enter stakes as a number, type /gamble [stakes]')
        return
    elseif tonumber(stakes) >= round.lowRoll then
        print('214,748g is the maximum gold limit in TBC classic')
        return
    else
        round.currentStakes = tonumber(stakes)
        print("Stakes are set to:",stakes)
        ChatMsg(format(".:Mommarte's Casino:. --Classic Roll Off!-- Please type %s to join the round (type %s to leave). Current Stakes are: %sg", 
        vars.chatEnterMsg, vars.chatWithdrawMsg, round.currentStakes))
        round.acceptEntries = true 
    end
end 

function GAMBLE_start() 
    local x = TableLength(round.entries)
    if x < 1 then
        print('not enough entries')
        return
    end 
    round.acceptEntries = false
    round.acceptRolls = true 
    ChatMsg(format('%s entries! Start rolling now (>^.^)>', x))
end

local function GAMBLE_results()
    if round.entriesCount ~= 0 then
        ListRemainingPlayers()
    end
end

local function GAMBLE_reset()
    ChatMsg(format("Round has been reset!"))
    ResetRound()
end 

--Slash Commands because i'm too lazy to make a UI
SLASH_GAMBLE1 = "/gamble"
SLASH_GAMBLE2 = "/greg"
SlashCmdList["GAMBLE"] = GAMBLE_announce

SLASH_START1 = "/start"
SlashCmdList["START"] = GAMBLE_start

SLASH_REMAIN1 = "/remain"
SlashCmdList["REMAIN"] = GAMBLE_remain

SLASH_TIE1 = "/tie"
SlashCmdList["TIE"] = GAMBLE_tie

SLASH_RESET1 = "/reset" 
SlashCmdList["RESET"] = GAMBLE_reset


--Create frame to handle chat messages
local framer = CreateFrame("Frame")

-- Register to monitor events
	framer:RegisterEvent("CHAT_MSG_RAID")
	framer:RegisterEvent("CHAT_MSG_RAID_LEADER")
	framer:RegisterEvent("CHAT_MSG_SAY")
	framer:RegisterEvent("CHAT_MSG_SYSTEM")


-- Handle the events as they happen, pretty messy, only works for MSG_SYSTEM, RAID and SAY channels
framer:SetScript("OnEvent", function(self, event, ...)
    if ((event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and round.acceptEntries and vars.currentChatMethod == "RAID") then
        local msg, name = ... 
        if string.lower(msg) == string.lower(vars.chatEnterMsg) then
            AddPlayer(name); 
        elseif string.lower(msg) == string.lower(vars.chatWithdrawMsg) then
            print ("haven't made a remove function yet lmao") 
        end

    elseif event == "CHAT_MSG_SAY" and round.acceptEntries and vars.currentChatMethod == "SAY" then
        local msg, name = ... 
        if string.lower(msg) == string.lower(vars.chatEnterMsg) then
            AddPlayer(name); 
        elseif string.lower(msg) == string.lower(vars.chatWithdrawMsg) then
            print ("haven't made a remove function yet lmao") 
        end
    elseif event == "CHAT_MSG_SYSTEM" and round.acceptRolls then
        local msg = ...
        ParseRoll(msg);
    end
end)








