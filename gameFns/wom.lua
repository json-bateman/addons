------------ Wheel of Misfortune Code ---------------
local vars = {
    chatEnterMsg = "wheel",
    chatWithdrawMsg = "withdraw", 
    currentChatMethod = "RAID"
}

local wheelDefaults = {
	entries = {
    }, --stores participants and their message
	entriesCount = 0,
	acceptEntries = false,
}

local womConstants = {}
SLASH_WHEEL1 = "/wheel"
SlashCmdList["WHEEL"] = WHEEL_announce 
