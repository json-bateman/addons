------------ Youtube Tutorial ---------------
-- Most of this is taken from Mayron's awesome youtube series on how to make a WoW addon.
-- https://www.youtube.com/watch?v=nfaE7NQhMlc&list=PL3wt7cLYn4N-3D3PTTUZBM2t1exFmoA2G&index=1

--[[
... is a variable operator, it's all of the variables that are supplied to the function or file
in this case you are automatically given 2 arguments, name and namespace of the addon
by default the second name is a table that is automatically shared between all files in the namespace
]]
addonName, gamba = ...

gamba.Config = {};
local Config = gamba.Config;

-- GLOBAL VARS --
local gameStates = {
    "IDLE",
    "REGISTRATION",
    "ROLLING",
}

local gameModes = {
    "ROLL",
    "ROULETTE",
    "WOM",
}

local chatChannels = {
    "PARTY",
    "RAID",
    "GUILD",
}

---------------------------------
-- Defaults (usually a database!)
---------------------------------
defaults = {
    theme = {
        r = 0,
        g = 0.8, -- 204/255
        b = 1,
        hex = "00ccff",
    },
    global = {
        game = {
            mode = gameModes[1],
            chatChannel = chatChannels[1],
            wager = 1,
            houseCut = 0,
            realmFilter = true,
        },
        stats = {
            player = {},
            aliases = {},
            house = 0
        },
    }
}

local function DoSomething(self) 
    print('something')
end

function Config:GetThemeColor()
	local c = defaults.theme;
	return c.r, c.g, c.b, c.hex;
end

function Config:Toggle()
    if not UIConfig then
        UIConfig = Config:CreateMenu();
    end
    UIConfig:SetShown(not UIConfig:IsShown());
end

function Config:CreateMenu()
    --[[ Args 
        1. Type of frame - "Frame"
        2. Name to access from with
        3. The parent frame, UIParent by default
        4. A comma separated list of XML templates to inherit from (can be > 1)
    ]]
    local UIConfig = CreateFrame("Frame", "Gambling", UIParent, "BasicFrameTemplate");
    --[[ Layers order of lowest to highest 
        BACKGROUND
        BORDER
        ARTWORK
        OVERLAY
        HIGHLIGHT
    ]]

    UIConfig:SetSize(200,240); --width / height
    UIConfig:SetPoint("CENTER") -- point, relativeFrame, relativePoint, xOffset, yOffset
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
    
    UIConfig.title = UIConfig:CreateFontString(nil, "OVERLAY");
    UIConfig.title:SetFontObject("GameFontHighlight");
    UIConfig.title:SetPoint("LEFT", UIConfig.TitleBg, "LEFT", 5, 0);
    UIConfig.title:SetText("MommaG's Casino");

    UIConfig:SetMovable(true)
    UIConfig:EnableMouse(true)

    UIConfig:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    UIConfig:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)

    -------------------
    -- Content1
    -------------------
    -- UI Roll Button: 
    UIConfig.rollButton = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
    UIConfig.rollButton:SetPoint("CENTER", UIConfig, "TOP", 0, -50);
    UIConfig.rollButton:SetSize(110, 30);
    UIConfig.rollButton:SetText("Roll");
    UIConfig.rollButton:SetNormalFontObject("GameFontNormalLarge");
    UIConfig.rollButton:SetHighlightFontObject("GameFontHighlightLarge");
    
    UIConfig.rollButton:SetScript("OnClick", DoSomething); 

    -- UI Roulette Button: 
    UIConfig.rouletteButton = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
    UIConfig.rouletteButton:SetPoint("CENTER", UIConfig, "TOP", 0, -90);
    UIConfig.rouletteButton:SetSize(110, 30);
    UIConfig.rouletteButton:SetText("Roulette");
    UIConfig.rouletteButton:SetNormalFontObject("GameFontNormalLarge");
    UIConfig.rouletteButton:SetHighlightFontObject("GameFontHighlightLarge");

    -- UI WoM Button: 
    UIConfig.womButton = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
    UIConfig.womButton:SetPoint("CENTER", UIConfig, "TOP", 0, -130);
    UIConfig.womButton:SetSize(110, 30);
    UIConfig.womButton:SetText("WoM");
    UIConfig.womButton:SetNormalFontObject("GameFontNormalLarge");
    UIConfig.womButton:SetHighlightFontObject("GameFontHighlightLarge");

    -- UI Gold Amount Slider
    UIConfig.goldSlider = CreateFrame("Slider", nil, UIConfig, "OptionsSliderTemplate");
    UIConfig.goldSlider:SetPoint("CENTER", UIConfig, "TOP", 0, -170);
    UIConfig.goldSlider:SetMinMaxValues(1, 10);
    UIConfig.goldSlider:SetValue(defaults.sliderValue);
    UIConfig.goldSlider:SetValueStep(1);
    UIConfig.goldSlider:SetObeyStepOnDrag(true);
    
    -- Assuming UIConfig.goldSlider is already created
    UIConfig.goldSlider.text = UIConfig.goldSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    UIConfig.goldSlider.text:SetPoint("TOP", UIConfig.goldSlider, "BOTTOM", 0, -5)  -- Adjust the position as needed

    -- Set initial text
    UIConfig.goldSlider.text:SetText(string.format("%dg", UIConfig.goldSlider:GetValue()))
    
    UIConfig.goldSlider:SetScript("OnValueChanged", function(self, value)
        self.text:SetText(string.format("%dg", math.floor(value)))  -- Update the text display
        -- Store the value
        -- Assuming you have a table for your addon's data
        defaults.sliderValue = math.floor(value)
    end)
    

    -- UI New Entries Checkbox
    UIConfig.checkEntries = CreateFrame("CheckButton", nil, UIConfig, "UICheckButtonTemplate");
    UIConfig.checkEntries:SetPoint("CENTER", UIConfig, "BOTTOMLEFT", 20, 20);
    -- Create a FontString for the text
    UIConfig.checkEntries.text = UIConfig.checkEntries:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    UIConfig.checkEntries.text:SetPoint("LEFT", UIConfig.checkEntries, "RIGHT", 8, 0);
    UIConfig.checkEntries.text:SetText("Allow new entries?");

    UIConfig:Hide();
    return UIConfig;
end