local deathFrame = CreateFrame("Frame")
deathFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")


deathFrame:SetScript("OnEvent", function(self, event)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
        
        -- If subEvent is a death, do something
        if subEvent == "PARTY_KILL" then
            print("Pussy 9!")
        end
    end
end)