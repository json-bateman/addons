--[[
... is a variable operator, it's all of the variables that are supplied to the function or file
in this case you are automatically given 2 arguments, name and namespace of the addon
by default the second name is a table that is automatically shared between all files in the namespace
]]
local addonName, gambling = ...

-- GLOBAL VARS --
local gameStates = {
    "REGISTRATION",
    "ROLLING",
}

local gameModes = {
    "ROLL",
    "LOTTERY",
}

local chatChannels = {
    "SAY", 
    "PARTY",
    "RAID",
    "GUILD",
}

gambling.theme = {
    r = 0,
    g = 0.8, -- 204/255
    b = 1,
    hex = "00ccff",
}

---------------------------------
-- Defaults (usually a database!)
---------------------------------
gambling.defaults = {
    game = {
        enterMessage = "gamba gamba",
        leaveMessage = "job done",
        mode = gameModes[1],
        chatChannel = chatChannels[1],
        houseCut = 0,
        min = 1,
        max = 100,
    },
    stats = {
        player = {},
        aliases = {},
        house = 0
    },
}

session = {
    currentChatMethod = chatChannels[2],
    wager = 1,
    players = {},
    payout = 0,
    gameState = gameStates[1],
    highTiebreaker = true,
    lowTiebreaker = true,
}

local game = gambling.defaults.game


-------------------------
-- Classic Gamble Functions
-------------------------
function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
          print(formatting)
          tprint(v, indent+1)
        elseif type(v) == 'boolean' then
          print(formatting .. tostring(v))      
        else
          print(formatting .. v)
        end
    end
end

function addPlayer(name)
    -- Ignore entry if player is already entered
    for i = 1, #session.players do
        if (session.players[i].name == playerName) then
            return
        end
    end
    newPlayer = {
        name = playerName,
        roll = nil,
    }
    tinsert(session.players, newPlayer)
    print("player added")
    chatMsg(format("%s has been added to gamba!", playerName))
end

function removePlayer(name)
    for i = 1, #session.players do 
        if (session.players[i].name == playerName) then
            tremove(session.players, i)
            print("player removed")
            chatMsg(format("%s has been removed from gamba!", playerName))
            return
        end
    end
end

function makeNameString(players)
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

function checkPlayerRolls(participants)
    local playersToRoll = {}
    for i = 1, #participants do 
        if (participants[i].roll == nil) then
            tinsert(playersToRoll, participants[i].name)
        end
    end
    return playersToRoll
end

function chatMsg(msg, chatType, language, channel)
	chatType = session.currentChatMethod
	SendChatMessage(msg, chatType, language, channelnum)
end

function handleSystemMessage(_, text)
    -- Parses system messages recieved by the Event Listener to find and record player rolls
    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, "^([^ ]+) .+ (%d+) %((%d+)-(%d+)%)%.?$")
    print(playerName, "---", actualRoll, "---", minRoll, "---", maxRoll);
    recordRoll(playerName, actualRoll, minRoll, maxRoll);
end

function recordRoll(playerName, actualRoll, minRoll, maxRoll)
    print(playerName, "---", actualRoll, "---", minRoll, "---", maxRoll);
    if (tonumber(minRoll) == 1 and tonumber(maxRoll) == game.max and not tiebreaker) then
        for i = 1, #session.players do 
            if (session.players[i].name == playerName and session.players[i].roll == nil) then
                session.players[i].roll = tonumber(actualRoll)
                print (session.players[i].roll)
            end
        end
    end
end

function determineResults(participants)
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
            end
            if (participants[i].roll == losers[1].roll) then
                tinsert(losers, participants[i])
            end
        end
    end
    amountOwed = (winners[1].roll - losers[1].roll) * session.wager
    return {
        winners = winners,
        losers = losers,
        amountOwed = amountOwed,
    }
end

--Create frame to handle chat messages
local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_SAY")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_SYSTEM")

-------------------------
-- Running the Game
-------------------------
function openEntries()
    if (session.gameState == "REGISTRATION") then
        chatMsg(format(".:MommaDeez's Casino:. --Classic Roll Off!-- Please type `%s` to join the round (type `%s` to leave). Current Stakes are: %sg", game.enterMessage, game.leaveMessage, session.wager))
        chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
            -- Name comes in like this [playerName]-[realm]
            -- i.e. Mommadeez-CrusaderStrike
            -- So we must split name before adding to table.
            playerName, _ = string.split('-', name)
            
            if ( ((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID")) and msg == game.enterMessage ) then
                addPlayer(playerName)
            elseif ( ((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID")) and msg == game.leaveMessage ) then
                print("here!")
                removePlayer(playerName)
            end
        end)
    else 
        print("Incorrect game state, cannot open entries")
    end
end

function startRoll()
    if (session.gameState == gameStates[1]) then
        session.gameState = gameStates[2]
    else 
        print(format("Rolls already begun. Current state is %s", session.gameState));
        return
    end

    chatMsg("Begin Rolling you Degenerate Gamblers!")
    --chatMsg(format("Begin Rolling you Degenerate Gamblers!"))
    chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
        -- Name comes in like this [playerName]-[realm]
        -- i.e. Mommadeez-CrusaderStrike
        -- So we must split name before adding to table.
        if (event == "CHAT_MSG_SYSTEM") then
            handleSystemMessage(self, msg)
        end
    end)
end

function finishRoll()
    local playersToRoll = checkPlayerRolls(session.players); 
    if (#playersToRoll > 0) then
        chatMsg("Some players still need to roll!")
        for _, player in ipairs(playersToRoll) do 
            playerString = playerString .. ", " .. player
        end
        chatMsg(playerString .. " Still has to roll!")
        return
    end
    local results = determineResults(session.players)
    -- store initial payout, result of first round of rolls
    if (session.results == nil) then
        session.results = results 
    end
    
    if (session.highTiebreaker) then
        results = determineResults(session.players)
        if (#results.winners == 1 and #results.losers == 1) then
            session.results.winners = results.winners
            session.highTiebreaker = false
        end
    end

    if (session.lowTiebreaker) then 
        results = determineResults(session.players)
        if (#results.winners == 1 and #results.losers == 1) then 
            session.results.losers = results.losers
            session.lowTiebreaker = false
        end
    end
        
    
    if (#session.results.winners > 1) then
        session.highTiebreaker = true
        session.players = results.winners
        for _, player in ipairs(session.players) do 
            player.roll = nil
        end
        chatMsg("High end tie breaker! " .. makeNameString(session.players) .. " /roll now!")
    elseif(#session.results.losers > 1) then
        session.lowTiebreaker = true
        session.players = results.losers
        for _, player in ipairs(session.players) do 
            player.roll = nil
        end
        chatMsg("Low end tie breaker! " .. makeNameString(session.players) .. " /roll now!")
    else 
        -- No Ties, no tiebreaker needed, display results 
        chatMsg(format("%s owes %s: %d Gold %d Silver! Lmao rekt and also got em.", session.results.winners[1].name, session.results.losers[1].name, math.floor(session.results.amountOwed/100), session.results.amountOwed % 100))
    end
end

-------------------------
-- Lottery Functions
-------------------------
function convertMoney(money)
    local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
    local silver = floor((money % (COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
    local copper = money % COPPER_PER_SILVER
    return gold, silver, copper
end

function captureMoneyTraded()
    local playerMoney = GetPlayerTradeMoney()
    local targetMoney = GetTargetTradeMoney()

    local playerGold, playerSilver, playerCopper = convertMoney(playerMoney)
    local targetGold, targetSilver, targetCopper = convertMoney(targetMoney)

    return playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper
end

function tradeHandler(self, event, ...)
    print("Event: " .. event)

    local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper
    if event == "TRADE_ACCEPT_UPDATE" then
        local playerAccept, targetAccept = ...
        local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper = captureMoneyTraded()
        if targetAccept == 1 and targetCopper == 1 then
            print('playerCopper: ', playerCopper, "targetCopper: ", targetCopper)
            AcceptTrade()
        end
    end
    if event == "TRADE_REQUEST_CANCEL" then
end

local tradeFrame = CreateFrame("Frame")
tradeFrame:RegisterEvent("TRADE_SHOW")
tradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeFrame:RegisterEvent("TRADE_CLOSED")
tradeFrame:SetScript("OnEvent", tradeHandler)

-------------------------
-- Game UI
-------------------------
gambling.UI = {};
local UI = gambling.UI;

function UI:GetThemeColor()
	local c = gambling.theme;
	return c.r, c.g, c.b, c.hex;
end

function UI:Toggle()
    if not Interface then
        Interface = UI:CreateClassicMenu();
    end
    Interface:SetShown(not Interface:IsShown());
end


function UI:CreateClassicMenu()
    --[[ Args 
        1. Type of frame - "Frame"
        2. Name to access from with
        3. The parent frame, UIParent by default
        4. A comma separated list of XML templates to inherit from (can be > 1)
    ]]
    local UI = CreateFrame("Frame", "Gambling", UIParent, "BasicFrameTemplate");
    --[[ Layers order of lowest to highest 
        BACKGROUND
        BORDER
        ARTWORK
        OVERLAY
        HIGHLIGHT
    ]]

    UI:SetSize(200,240); --width / height
    UI:SetPoint("CENTER") -- point, relativeFrame, relativePoint, xOffset, yOffset
    -- Point and relativePoint "CENTER" could have been: 
    --[[
       "TOPLEFT" 
       "TOP" 
       "TOPRIGHT" 
       "LEFT" 
       "BOTTOMLEFT"
       "BOTTOM"
       "BOTTOMRIGHT"
       "RIGHT"
    ]]
    
    UI.title = UI:CreateFontString(nil, "OVERLAY");
    UI.title:SetFontObject("GameFontHighlight");
    UI.title:SetPoint("LEFT", UI.TitleBg, "LEFT", 5, 0);
    UI.title:SetText("MommaG's Casino");

    UI:SetMovable(true)
    UI:EnableMouse(true)

    UI:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    UI:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)

    -- UI Open Entries Button: 
    UI.openEntries = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.openEntries:SetPoint("CENTER", UI, "TOP", 0, -50);
    UI.openEntries:SetSize(110, 30);
    UI.openEntries:SetText("Open Entries");
    UI.openEntries:SetNormalFontObject("GameFontNormal");
    UI.openEntries:SetHighlightFontObject("GameFontHighlight");
    
    UI.openEntries:SetScript("OnClick", openEntries); 

    -- UI Close Entries Button: 
    UI.startRoll = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.startRoll:SetPoint("CENTER", UI, "TOP", 0, -90);
    UI.startRoll:SetSize(110, 30);
    UI.startRoll:SetText("Start Roll");
    UI.startRoll:SetNormalFontObject("GameFontNormal");
    UI.startRoll:SetHighlightFontObject("GameFontHighlight");

    UI.startRoll:SetScript("OnClick", startRoll); 

    -- UI Finish Roll Button: 
    UI.finishRoll = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.finishRoll:SetPoint("CENTER", UI, "TOP", 0, -130);
    UI.finishRoll:SetSize(110, 30);
    UI.finishRoll:SetText("Finish Roll");
    UI.finishRoll:SetNormalFontObject("GameFontNormal");
    UI.finishRoll:SetHighlightFontObject("GameFontHighlight");

    UI.finishRoll:SetScript("OnClick", finishRoll); 

    -- UI Gold Amount Slider
    UI.goldSlider = CreateFrame("Slider", nil, UI, "OptionsSliderTemplate");
    UI.goldSlider:SetPoint("CENTER", UI, "TOP", 0, -170);
    UI.goldSlider:SetMinMaxValues(1, 10);
    UI.goldSlider:SetValue(session.wager);
    UI.goldSlider:SetValueStep(1);
    UI.goldSlider:SetObeyStepOnDrag(true);

    -- Assuming UI.goldSlider is already created
    UI.goldSlider.text = UI.goldSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    UI.goldSlider.text:SetPoint("TOP", UI.goldSlider, "BOTTOM", 0, -5)  -- Adjust the position as needed

    -- Set initial text
    UI.goldSlider.text:SetText(string.format("%dg", UI.goldSlider:GetValue()))
    
    UI.goldSlider:SetScript("OnValueChanged", function(self, value)
        self.text:SetText(string.format("%dg", math.floor(value)))  -- Update the text display
        -- Store the value
        -- Assuming you have a table for your addon's data
        session.wager = math.floor(value)
    end)

    UI:Hide();
    return UI;
end

function UI:CreateLotteryMenu()
    local UI = CreateFrame("Frame", "Gambling", UIParent, "BasicFrameTemplate");
    UI:SetSize(200,240); --width / height
    UI:SetPoint("CENTER") -- point, relativeFrame, relativePoint, xOffset, yOffset
    UI.title = UI:CreateFontString(nil, "OVERLAY");
    UI.title:SetFontObject("GameFontHighlight");
    UI.title:SetPoint("LEFT", UI.TitleBg, "LEFT", 5, 0);
    UI.title:SetText("MommaG's Lottery");
    
    -- UI Open Entries Button: 
    UI.openEntries = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.openEntries:SetPoint("CENTER", UI, "TOP", 0, -50);
    UI.openEntries:SetSize(110, 30);
    UI.openEntries:SetText("Open Entries");
    UI.openEntries:SetNormalFontObject("GameFontNormal");
    UI.openEntries:SetHighlightFontObject("GameFontHighlight");
    
    UI.openEntries:SetScript("OnClick", openEntries); 

    UI:Hide();
    return UI;
end

--[[Initializes all of the /slash commands to be used in the app
    Loads on the event "ADDON_LOADED"
    Adds 2 convenience functions: 
    /fa - for frame stack access 
    /rl - shortened /reload
]]

-------------------------
-- Slash Commands
-------------------------

gambling.commands = {
    classic = gambling.UI.Toggle,
    help = function() 
        gambling:Print("List of all slash commands:")
        gambling:Print("|cff00cc66/gamba help|r - Shows all commands")
        gambling:Print("|cff00cc66/gamba menu|r - Opens the gambling menu")
    end,
};

local function HandleSlashCommands(str)
    if (#str == 0) then
        gambling.commands.help();
    end
    
    local args = {};
    for _, arg in pairs({string.split(' ', str)}) do 
        if (#arg > 0) then
            table.insert(args, arg);
        end
    end
    
    local path = gambling.commands;
    
    for id, arg in ipairs(args) do 
        arg = string.lower(arg);
        
        if (path[arg]) then 
            if (type(path[arg]) == "function") then 
                path[arg](select(id + 1, unpack(args)));
                return;
        elseif (type(path[arg]) == "table") then
            path = path[arg]; 
        else 
            gambling.commands.help();
            return;
        end
    end
end
end

function gambling:Print(...)
    local hex = select(4, self.UI:GetThemeColor());
    local prefix = string.format("|cff%s%s|r", hex:upper(), "MommaG's Casino")
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, tostringall(...)));
end

-- Self automatically becomes events frame!
function gambling:init(event, name)
    if (addonName ~= "Gambling") then return end
    
    -- Register Slash Commands!
    SLASH_RELOADUI1 = "/rl" -- reload UI shortened from /reload
    SlashCmdList.RELOADUI = ReloadUI;
    SLASH_FRAMESTK1 = "/fa" -- access to the frame stack
    SlashCmdList.FRAMESTK = function()
        LoadAddOn('Blizzard_DebugTools')
        FrameStackTooltip_Toggle()
    end

    SLASH_Gamba1 = "/gamba" -- main entry point into addon
    SlashCmdList.Gamba = HandleSlashCommands;
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", gambling.init);
