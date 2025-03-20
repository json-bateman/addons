--[[
... is a variable operator, it's all of the variables that are supplied to the function or file
in this case you are automatically given 2 arguments, name and namespace of the addon
by default the second name is a table that is automatically shared between all files in the namespace
]]
local _, gambling = ...

-- GLOBAL VARS --
COPPER_PER_SILVER = 100
SILVER_PER_GOLD = 100

GameStates = {
   "REGISTRATION",
   "ROLLING",
}

GameModes = {
   "ROLL",
   "LOTTERY",
}

ChatChannels = {
   "SAY",
   "PARTY",
   "RAID",
   "GUILD",
   "RAIDLEADER",
   "RAID LEADER",
}

gambling.theme = {
   r = 0,
   g = 0.8, -- 204/255
   b = 1,
   hex = "00ccff",
}

gambling.game = {
   enterMessage = "gamba",
   leaveMessage = "job done",
   mode = GameModes[1],
   chatChannel = ChatChannels[1],
   houseCut = 0,
   wager = 1,
   min = 1,
   max = 500,
}
