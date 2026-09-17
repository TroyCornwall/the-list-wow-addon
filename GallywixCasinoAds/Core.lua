-- Gallywix Casino Ads
-- Purely cosmetic, client-side combat "ad" popup. Doesn't touch combat log,
-- doesn't click anything, doesn't taint secure frames. Just an annoying window.

local ADDON_NAME = ...

--------------------------------------------------------------------------
-- Saved settings
--------------------------------------------------------------------------

local defaults = {
    enabled = true,
    minDelay = 8,     -- seconds between ads, minimum
    maxDelay = 20,    -- seconds between ads, maximum
    adDuration = 7,   -- seconds an ad stays up before auto-dismissing
    point = "TOPRIGHT",
    x = -40,
    y = -220,
}

local db

local function InitDB()
    GallywixCasinoAdsDB = GallywixCasinoAdsDB or {}
    for k, v in pairs(defaults) do
        if GallywixCasinoAdsDB[k] == nil then
            GallywixCasinoAdsDB[k] = v
        end
    end
    db = GallywixCasinoAdsDB
end

--------------------------------------------------------------------------
-- Ad content
--------------------------------------------------------------------------

local ADS = {
    { title = "CONGRATULATIONS!!!", sub = "YOU ARE THE 1,000,000th VISITOR TO UNDERMINE!", cta = "CLICK HERE TO CLAIM YOUR PRIZE >>>" },
    { title = "YOU HAVE WON!!", sub = "Gallywix has selected YOU for 500 FREE SPINS", cta = "CLAIM NOW BEFORE IT'S GONE" },
    { title = "!! SYSTEM ALERT !!", sub = "Your account QUALIFIES for VIP Jackpot Access", cta = "TAP HERE IMMEDIATELY" },
    { title = "★ WINNER SELECTED ★", sub = "1 raider in this instance just won a FREE GOBLIN GLIDER", cta = "IS IT YOU?? CLICK TO FIND OUT" },
    { title = "DO NOT CLOSE THIS AD", sub = "You have been chosen by an ancient Undermine algorithm", cta = "CLAIM YOUR REWARD NOW!!" },
    { title = "JACKPOT!!! JACKPOT!!!", sub = "Everyone reading this wins... probably... maybe", cta = "SPIN THE WHEEL >>> FREE <<<" },
    { title = "GALLYWIX WANTS TO KNOW", sub = "Local raider discovers ONE WEIRD TRICK to skip enrage", cta = "BOSSES HATE HIM! CLICK NOW" },
    { title = "URGENT: ACT NOW", sub = "Your free spins expire the moment this ad closes", cta = "DO NOT MISS THIS OFFER" },
}

local RAINBOW = {
    { 1, 0.15, 0.15 },
    { 1, 0.6, 0.1 },
    { 1, 1, 0.15 },
    { 0.2, 1, 0.2 },
    { 0.2, 1, 1 },
    { 0.3, 0.5, 1 },
    { 0.8, 0.2, 1 },
    { 1, 0.2, 0.8 },
}

local FLAIR_PHRASES = {
    "|cffff2222*|r |cffffff00YOU ARE VISITOR #1,000,000|r |cffff2222*|r",
    "|cff00ff00*|r |cffff2222WINNER WINNER|r |cff00ff00*|r",
    "|cffffff00*|r |cff00ffffCLICK NOW|r |cffffff00*|r",
    "|cffff66ff*|r |cffffff00LIMITED TIME ONLY|r |cffff66ff*|r",
}

local REEL_ICONS = {
    "Interface\\Icons\\INV_Misc_Coin_01",
    "Interface\\Icons\\INV_Misc_Coin_02",
    "Interface\\Icons\\INV_Misc_Coin_17",
    "Interface\\Icons\\INV_Misc_Coin_18",
    "Interface\\Icons\\INV_Misc_Gem_01",
    "Interface\\Icons\\INV_Misc_Gem_Variety_01",
    "Interface\\Icons\\INV_Misc_Dice_01",
    "Interface\\Icons\\INV_Misc_Dice_02",
    "Interface\\Icons\\Achievement_Dungeon_UtgardePinnacle_25man",
}

--------------------------------------------------------------------------
-- Frame construction (built once)
--------------------------------------------------------------------------

local adFrame

local function PlayDing()
    local ok = pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE or 567, "Master")
    if not ok then
        pcall(PlaySoundFile, "Sound\\Interface\\LevelUp.ogg", "Master")
    end
end

local function CreateAdFrame()
    local f = CreateFrame("Frame", "GallywixCasinoAdFrame", UIParent, "BackdropTemplate")
    f:SetSize(340, 190)
    f:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    f:SetFrameStrata("TOOLTIP")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        db.point, db.x, db.y = point, x, y
    end)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 11, top = 11, bottom = 11 },
        })
        f:SetBackdropColor(0.15, 0.05, 0, 0.95)
        f:SetBackdropBorderColor(1, 0.82, 0, 1)
    end

    -- gaudy flashing frame border texture
    local glow = f:CreateTexture(nil, "BACKGROUND")
    glow:SetAllPoints()
    glow:SetColorTexture(1, 0.85, 0, 0.15)
    f.glow = glow

    local flair = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    flair:SetPoint("TOP", f, "TOP", 0, -8)
    flair:SetText("|cffff2222*|r |cffffff00SPONSORED|r |cffff2222*|r")
    f.flair = flair

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", flair, "BOTTOM", 0, -6)
    title:SetWidth(300)
    title:SetJustifyH("CENTER")
    title:SetTextColor(1, 0.85, 0.1)
    f.title = title

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -4)
    sub:SetWidth(300)
    sub:SetJustifyH("CENTER")
    f.sub = sub

    -- slot machine reels
    local reels = {}
    for i = 1, 3 do
        local icon = f:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("CENTER", f, "CENTER", (i - 2) * 40, -6)
        icon:SetTexture(REEL_ICONS[1])
        reels[i] = icon
    end
    f.reels = reels

    local cta = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cta:SetPoint("BOTTOM", f, "BOTTOM", 0, 28)
    cta:SetWidth(300)
    cta:SetJustifyH("CENTER")
    cta:SetTextColor(0.2, 1, 0.2)
    f.cta = cta

    local timer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    timer:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    timer:SetWidth(300)
    timer:SetJustifyH("CENTER")
    f.timer = timer

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 4)
    close:SetScript("OnClick", function()
        f:Hide()
    end)

    -- flashing background pulse
    f:SetScript("OnUpdate", function(self, elapsed)
        self.pulseT = (self.pulseT or 0) + elapsed
        local a = 0.10 + math.abs(math.sin(self.pulseT * 6)) * 0.3
        self.glow:SetColorTexture(1, 0.85, 0, a)

        -- flair marquee, cycles fast
        self.flairT = (self.flairT or 0) + elapsed
        if self.flairT > 0.18 then
            self.flairT = 0
            self.flairIdx = (self.flairIdx or 0) + 1
            self.flair:SetText(FLAIR_PHRASES[(self.flairIdx % #FLAIR_PHRASES) + 1])
        end

        -- title flashes through rainbow colors, old-school <blink> style
        self.titleT = (self.titleT or 0) + elapsed
        if self.titleT > 0.12 then
            self.titleT = 0
            self.titleIdx = (self.titleIdx or 0) + 1
            local c = RAINBOW[(self.titleIdx % #RAINBOW) + 1]
            self.title:SetTextColor(c[1], c[2], c[3])
        end

        -- cta blinks on/off and swaps between the offer text and a CLICK NOW nag
        self.ctaT = (self.ctaT or 0) + elapsed
        if self.ctaT > 0.35 then
            self.ctaT = 0
            self.ctaBlink = not self.ctaBlink
            self.cta:SetShown(self.ctaBlink)
        end

        -- fake urgency countdown, loops forever
        self.countdownT = (self.countdownT or 0) + elapsed
        if self.countdownT >= 1 then
            self.countdownT = 0
            self.countdown = (self.countdown or 10) - 1
            if self.countdown <= 0 then
                self.countdown = 10
            end
            self.timer:SetText(("|cffff4444HURRY! Offer expires in 0:%02d|r"):format(self.countdown))
        end

        if self.spinning then
            self.spinT = (self.spinT or 0) + elapsed
            if self.spinT > 0.06 then
                self.spinT = 0
                for _, reel in ipairs(self.reels) do
                    reel:SetTexture(REEL_ICONS[math.random(#REEL_ICONS)])
                end
            end
        end
    end)

    f:Hide()
    return f
end

--------------------------------------------------------------------------
-- Showing an ad
--------------------------------------------------------------------------

local function RandomizePosition(f)
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    local margin = 20
    local maxX = math.max(math.floor((screenW - f:GetWidth()) / 2) - margin, 0)
    local maxY = math.max(math.floor((screenH - f:GetHeight()) / 2) - margin, 0)
    local x = math.random(-maxX, maxX)
    local y = math.random(-maxY, maxY)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

local function StopSpin(f)
    f.spinning = false
    for _, reel in ipairs(f.reels) do
        reel:SetTexture(REEL_ICONS[math.random(#REEL_ICONS)])
    end
end

local function ShowRandomAd()
    if not adFrame then
        adFrame = CreateAdFrame()
    end

    local ad = ADS[math.random(#ADS)]
    adFrame.title:SetText(ad.title)
    adFrame.sub:SetText(ad.sub)
    adFrame.cta:SetText(ad.cta)
    adFrame.cta:Show()
    adFrame.ctaBlink = true
    adFrame.ctaT = 0
    adFrame.countdown = 10
    adFrame.countdownT = 0
    adFrame.spinning = true

    RandomizePosition(adFrame)
    adFrame:SetAlpha(0)
    adFrame:Show()
    adFrame:SetScale(0.7)
    PlayDing()

    -- quick "pop in" grow effect
    local grow = 0
    local grower = CreateFrame("Frame")
    grower:SetScript("OnUpdate", function(self, elapsed)
        grow = grow + elapsed * 4
        if grow >= 1 then
            adFrame:SetAlpha(1)
            adFrame:SetScale(1)
            self:SetScript("OnUpdate", nil)
        else
            adFrame:SetAlpha(grow)
            adFrame:SetScale(0.7 + 0.3 * grow)
        end
    end)

    C_Timer.After(1.4, function()
        if adFrame:IsShown() then
            StopSpin(adFrame)
        end
    end)

    C_Timer.After(db.adDuration, function()
        if adFrame:IsShown() then
            adFrame:Hide()
        end
    end)
end

local function HideAd()
    if adFrame then
        adFrame.spinning = false
        adFrame:Hide()
    end
end

--------------------------------------------------------------------------
-- Combat scheduling
--------------------------------------------------------------------------

local inCombat = false
local scheduleGeneration = 0

local function ScheduleNextAd(generation)
    if not db.enabled or not inCombat or generation ~= scheduleGeneration then
        return
    end
    local delay = math.random(db.minDelay, db.maxDelay)
    C_Timer.After(delay, function()
        if not db.enabled or not inCombat or generation ~= scheduleGeneration then
            return
        end
        ShowRandomAd()
        ScheduleNextAd(generation)
    end)
end

local function OnEnterCombat()
    inCombat = true
    scheduleGeneration = scheduleGeneration + 1
    ScheduleNextAd(scheduleGeneration)
end

local function OnLeaveCombat()
    inCombat = false
    scheduleGeneration = scheduleGeneration + 1
    HideAd()
end

--------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        InitDB()
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnEnterCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnLeaveCombat()
    end
end)

--------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------

SLASH_GALLYWIXADS1 = "/ads"
SlashCmdList["GALLYWIXADS"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "test" then
        ShowRandomAd()
        print("|cffffd200[GallywixAds]|r Test ad fired.")
    elseif msg == "off" then
        db.enabled = false
        HideAd()
        print("|cffffd200[GallywixAds]|r Disabled. The house always wins, but not today.")
    elseif msg == "on" then
        db.enabled = true
        print("|cffffd200[GallywixAds]|r Enabled. See you in combat.")
    elseif msg:match("^freq") then
        local a, b = msg:match("^freq%s+(%d+)%s+(%d+)$")
        if a and b then
            db.minDelay, db.maxDelay = tonumber(a), tonumber(b)
            print(("|cffffd200[GallywixAds]|r Ad frequency set to %d-%d seconds."):format(db.minDelay, db.maxDelay))
        else
            print("|cffffd200[GallywixAds]|r Usage: /ads freq <min> <max>")
        end
    else
        db.enabled = not db.enabled
        if not db.enabled then
            HideAd()
        end
        print("|cffffd200[GallywixAds]|r " .. (db.enabled and "Enabled." or "Disabled.") ..
            " Commands: /ads test, /ads on, /ads off, /ads freq <min> <max>")
    end
end
