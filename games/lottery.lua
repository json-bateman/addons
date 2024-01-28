-------------------------
-- Lottery Functions
-------------------------
function ConvertMoney(money)
    local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
    local silver = floor((money % (COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
    local copper = money % COPPER_PER_SILVER
    return gold, silver, copper
end

function CaptureMoneyTraded()
    local playerMoney = GetPlayerTradeMoney()
    local targetMoney = GetTargetTradeMoney()

    local playerGold, playerSilver, playerCopper = convertMoney(playerMoney)
    local targetGold, targetSilver, targetCopper = convertMoney(targetMoney)

    return playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper
end

-- function tradeHandler(self, event, ...)
--     print("Event: " .. event)

--     local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper
--     if event == "TRADE_ACCEPT_UPDATE" then
--         local playerAccept, targetAccept = ...
--         local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper = captureMoneyTraded()
--         if targetAccept == 1 and targetCopper == 1 then
--             print('playerCopper: ', playerCopper, "targetCopper: ", targetCopper)
--             AcceptTrade()
--         end
--     end
--     if event == "TRADE_REQUEST_CANCEL" then
-- end

local tradeFrame = CreateFrame("Frame")
tradeFrame:RegisterEvent("TRADE_SHOW")
tradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeFrame:RegisterEvent("TRADE_CLOSED")
tradeFrame:SetScript("OnEvent", tradeHandler)
