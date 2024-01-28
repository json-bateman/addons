--globals
local wheel = {
    [0] = "green", [1] = "red", [2] = "black", [3] = "red", [4] = "black", [5] = "red", [6] = "black", [7] = "red", 
    [8] = "black", [9] = "red", [10] = "black", [11] = "black", [12] = "red", [13] = "black", [14] = "red", [15] = "black", [16] = "red",
    [17] = "black", [18] = "red", [19] = "red", [20] = "black", [21] = "red", [22] = "black", [23] = "red", [24] = "black", [25] = "red",
    [26] = "black", [27] = "red", [28] = "black", [29] = "black", [30] = "red", [31] = "black", [32] = "red", [33] = "black",
    [34] = "red", [35] = "black", [36] = "red", ["00"] = "green", 
}

local vars = {
    chatEnterMsg = "1",
    chatWithdrawMsg = "poor", 
    currentChatMethod = "RAID"
}

local roundDefaults = {
	currentStakes = 0,
	entries = {}, --stores participants and their rolls
	entriesCount = 0,
	acceptEntries = false,
    placeYourBets = false,
    spin = -1, 
    multiplier = 1,
    someEntries = 0
}

local round = roundDefaults

function TableLength(T) --table length function because table.getn({table}) is gaffed
    local count = 0
    for k,v in pairs(T) do count = count + 1 end
        return count
end

local function ParseMsg(msg, username)
    local charname, realmname = strsplit("-",username)
    local player = round.entries[charname]
    --don't parse if player hasn't entered 
    if player == nil or not player.entered then 
        return
    end

    if round.placeYourBets then
        for k,v in pairs(wheel) do 
            if msg == k then
                player.bet = msg
                round.entriesCount = round.entriesCount - 1
                print (k)
            elseif tonumber(msg) == k and msg ~= "00" then --00 gets changed to 0 and double bets, ~= "00" takes care of that case
                player.bet = msg
                round.entriesCount = round.entriesCount - 1
                print (k)
            end
        end
    end
    if round.entriesCount == 0 then
        if TableLength(round.entries) > 0 and not round.acceptEntries then
            round.spin = math.random(0,37)
            allEntries = TableLength(round.entries)
            round.placeYourBets = false
        end
        if round.spin == 37 then --fixes the case where someone bets 00
            round.spin = "00"
        end
        ChatMsg(format("Spinning the wheel! **marble sounds, wheel spinning sounds** The number is: %s!",round.spin))
            print (round.spin)
            roundPayout = round.multiplier * 32
            for k,v in pairs (round.entries) do
                local player = round.entries[k]
                round.someEntries = round.someEntries + 1
                if tonumber(v.bet) == round.spin then
                    ChatMsg(format("%s Wins: -- %sg!", k, roundPayout))
                    player.moneyWon = player.moneyWon + (roundPayout)
                elseif v.bet == round.spin then --solves 00 case, they're both strings of "00" 
                    ChatMsg(format("%s Wins: -- %sg!", k, roundPayout))
                    player.moneyWon = player.moneyWon + (roundPayout)
                else
                    player.moneyWon = player.moneyWon - (round.multiplier * 1)
                    print (k, player.moneyWon)
                end 
            player.entered = false 
            end
        if round.someEntries == allEntries then
            ChatMsg(format('No winners this time!'))
        end
        round.multiplier = 1
    end
end
                  
local function AddPlayer(name)
    local charname, realmname = strsplit("-",name)
        if charname ~= nil and round.entries[charname] == nil then
            entrantInfo = { 
                name = charname,
                bet = -1,
                entered = true,
                moneyWon = 0
            }
            round.entries[charname] = entrantInfo
            round.entriesCount = round.entriesCount + 1
            print ('player added')
        elseif round.entries[charname].name == charname then --if already entered on a previous round, add 1 to entries count
                round.entriesCount = round.entriesCount + 1
                print ('player resuming')
        end
end

local function GAMBLE_roulette(arg)
    if arg == '' then
    ChatMsg(format(".:Mommarte's Casino:. --ROULETTE!-- Please type %s to join the round (type %s to leave). The buy in is 1g!", 
    vars.chatEnterMsg, vars.chatWithdrawMsg))
    round.acceptEntries = true 
    else
    round.multiplier = round.multiplier * tonumber(arg)
    ChatMsg(format(".:Mommarte's Casino:. --ROULETTE!-- Please type %s to join the round (type %s to leave). The buy in is %sg!", 
    vars.chatEnterMsg, vars.chatWithdrawMsg, round.multiplier))
    round.acceptEntries = true
    end
end 

local function GAMBLE_place()
    if round.entriesCount > 0 and round.acceptEntries == true then
    ChatMsg(format("Place your bets! payout is 32 to 1, bet any number 0-36 or 00!"))
    round.acceptEntries = false
    round.placeYourBets = true
    print (round.entriesCount)
    end


end

local function GAMBLE_results()
    for k,v in pairs (round.entries) do 
        if v.moneyWon > 0 then
            ChatMsg(format("%s has won: %sg!",k,v.moneyWon))
        else 
            ChatMsg(format("%s owes: %sg to the Casino :>",k,abs(v.moneyWon)))
        end
    end
end 

SLASH_ROULETTE1 = "/roulette"
SlashCmdList["ROULETTE"] = GAMBLE_roulette

SLASH_PLACE1 = "/place"
SlashCmdList["PLACE"] = GAMBLE_place

SLASH_RESULTS1 = "/results"
SlashCmdList["RESULTS"] = GAMBLE_results