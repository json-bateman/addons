local addonName, gambling = ...

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

    UI.openEntries:SetScript("OnClick", OpenEntries);

    -- UI Close Entries Button: 
    UI.startRoll = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.startRoll:SetPoint("CENTER", UI, "TOP", 0, -90);
    UI.startRoll:SetSize(110, 30);
    UI.startRoll:SetText("Start Roll");
    UI.startRoll:SetNormalFontObject("GameFontNormal");
    UI.startRoll:SetHighlightFontObject("GameFontHighlight");

    UI.startRoll:SetScript("OnClick", StartRoll);

    -- UI Finish Roll Button: 
    UI.finishRoll = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.finishRoll:SetPoint("CENTER", UI, "TOP", 0, -130);
    UI.finishRoll:SetSize(110, 30);
    UI.finishRoll:SetText("Finish Roll");
    UI.finishRoll:SetNormalFontObject("GameFontNormal");
    UI.finishRoll:SetHighlightFontObject("GameFontHighlight");

    UI.finishRoll:SetScript("OnClick", FinishRoll);

    -- UI Gold Amount Slider
    UI.goldSlider = CreateFrame("Slider", nil, UI, "OptionsSliderTemplate");
    UI.goldSlider:SetPoint("CENTER", UI, "TOP", 0, -170);
    UI.goldSlider:SetMinMaxValues(1, 10);
    UI.goldSlider:SetValue(gambling.defaults.game.wager);
    UI.goldSlider:SetValueStep(1);
    UI.goldSlider:SetObeyStepOnDrag(true);

    -- Assuming UI.goldSlider is already created
    UI.goldSlider.text = UI.goldSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    UI.goldSlider.text:SetPoint("TOP", UI.goldSlider, "BOTTOM", 0, -5)  -- Adjust the position as needed

    -- Set initial text
    UI.goldSlider.text:SetText(string.format("%dg", UI.goldSlider:GetValue()))

    UI.goldSlider:SetScript("OnValueChanged", function(self, value)
        self.text:SetText(string.format("%dg", math.floor(value)))  -- Update the text display
        gambling.defaults.game.wager = math.floor(value)
    end)

    -- UI Message Channel Type

    UI.msgSay = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.msgSay:SetPoint("CENTER", UI, "TOP", -60, -210);
    UI.msgSay:SetSize(50, 20);
    UI.msgSay:SetText("Say");
    UI.msgSay:SetNormalFontObject("GameFontNormal");
    UI.msgSay:SetHighlightFontObject("GameFontHighlight");

    UI.msgSay:SetScript("OnClick", function(_) gambling.defaults.game.chatChannel = ChatChannels[1] end);

    UI.msgParty = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.msgParty:SetPoint("CENTER", UI, "TOP", 0, -210);
    UI.msgParty:SetSize(50, 20);
    UI.msgParty:SetText("Party");
    UI.msgParty:SetNormalFontObject("GameFontNormal");
    UI.msgParty:SetHighlightFontObject("GameFontHighlight");

    UI.msgParty:SetScript("OnClick", function(_) gambling.defaults.game.chatChannel = ChatChannels[2] end);

    UI.msgRaid = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.msgRaid:SetPoint("CENTER", UI, "TOP", 60, -210);
    UI.msgRaid:SetSize(50, 20);
    UI.msgRaid:SetText("Raid");
    UI.msgRaid:SetNormalFontObject("GameFontNormal");
    UI.msgRaid:SetHighlightFontObject("GameFontHighlight");

    UI.msgParty:SetScript("OnClick", function(_) gambling.defaults.game.chatChannel = ChatChannels[3] end);

    UI:Hide();
    return UI;
end

-- function UI:CreateLotteryMenu()
--     local UI = CreateFrame("Frame", "Gambling", UIParent, "BasicFrameTemplate");
--     UI:SetSize(200,240); --width / height
--     UI:SetPoint("CENTER") -- point, relativeFrame, relativePoint, xOffset, yOffset
--     UI.title = UI:CreateFontString(nil, "OVERLAY");
--     UI.title:SetFontObject("GameFontHighlight");
--     UI.title:SetPoint("LEFT", UI.TitleBg, "LEFT", 5, 0);
--     UI.title:SetText("MommaG's Lottery");

--     -- UI Open Entries Button: 
--     UI.openEntries = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
--     UI.openEntries:SetPoint("CENTER", UI, "TOP", 0, -50);
--     UI.openEntries:SetSize(110, 30);
--     UI.openEntries:SetText("Open Entries");
--     UI.openEntries:SetNormalFontObject("GameFontNormal");
--     UI.openEntries:SetHighlightFontObject("GameFontHighlight");

--     UI.openEntries:SetScript("OnClick", openEntries); 

--     UI:Hide();
--     return UI;
-- end

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
    roll = gambling.UI.Toggle,
    help = function()
        gambling:Print("List of all slash commands:")
        gambling:Print("|cff00cc66/gamba help|r - Shows all commands")
        gambling:Print("|cff00cc66/gamba roll|r - Opens the classic gambling game")
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
                path[arg](select(id + 1, args));
                return;
            end
        else
            gambling.commands.help();
            return;
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
