--[[Initializes all of the /slash commands to be used in the app
    Loads on the event "ADDON_LOADED"
    Adds 2 convenience functions: 
    /fa - for frame stack access 
    /rl - shortened /reload
]]

gamba.commands = {
    ["menu"] = gamba.Config.Toggle;
    ["help"] = function() 
        gamba:Print("List of all slash commands:")
        gamba:Print("|cff00cc66/gamba help|r - Shows all commands")
        gamba:Print("|cff00cc66/gamba menu|r - Opens the gambling menu")
    end,
};

local function HandleSlashCommands(str)
    if (#str == 0) then
        gamba.commands.help();
    end
    
    local args = {};
    for _, arg in pairs({string.split(' ', str)}) do 
        if (#arg > 0) then
            table.insert(args, arg);
        end
    end
    
    local path = gamba.commands;
    
    for id, arg in ipairs(args) do 
        arg = string.lower(arg);
        
        if (path[arg]) then 
            if (type(path[arg]) == "function") then 
                path[arg](select(id + 1, unpack(args)));
                return;
        elseif (type(path[arg]) == "table") then
            path = path[arg]; 
        else 
            gamba.commands.help();
            return;
        end
    end
end
end

function gamba:Print(...)
    local hex = select(4, self.Config:GetThemeColor());
    local prefix = string.format("|cff%s%s|r", hex:upper(), "MommaG's Casino")
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, tostringall(...)));
end

-- Self automatically becomes events frame!
function gamba:init(event, name)
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
events:SetScript("OnEvent", gamba.init);
