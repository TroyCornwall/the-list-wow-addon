-- The List
-- Watches the applicant list on your posted Group Finder ("Premade Groups")
-- listing and warns you when someone on your personal blacklist applies to
-- your Mythic+ key. Client-side only: it reads applicant info from the
-- normal LFG list API and never invites, declines, or otherwise touches
-- anyone's group automatically.

local ADDON_NAME = ...

local defaults = {
    enabled = true,
    sound = true,
    alertDuration = 8,
    point = "TOP",
    x = 0,
    y = -150,
    blacklist = {}, -- [normalizedName] = note (string) or true
    seededDefaults = false,
}

local db

--------------------------------------------------------------------------
-- Blacklist
--------------------------------------------------------------------------

local function NormalizeName(name)
    if not name or name == "" then
        return nil
    end
    name = name:gsub("%-.*$", "") -- drop "-Realm" suffix, if any
    name = name:lower():trim()
    if name == "" then
        return nil
    end
    return name
end

local function IsBlacklisted(name)
    local norm = NormalizeName(name)
    return norm ~= nil and db.blacklist[norm] ~= nil
end

local function AddToBlacklist(name, note)
    local norm = NormalizeName(name)
    if not norm then
        return false
    end
    db.blacklist[norm] = (note and note ~= "") and note or true
    return true
end

local function RemoveFromBlacklist(name)
    local norm = NormalizeName(name)
    if not norm or db.blacklist[norm] == nil then
        return false
    end
    db.blacklist[norm] = nil
    return true
end

local function ExportBlacklist()
    local names = {}
    for name in pairs(db.blacklist) do
        table.insert(names, name)
    end
    table.sort(names)
    return table.concat(names, ",")
end

local function ImportBlacklist(str, replace)
    if replace then
        wipe(db.blacklist)
    end
    local count = 0
    for name in str:gmatch("[^,]+") do
        if AddToBlacklist(name) then
            count = count + 1
        end
    end
    return count
end

--------------------------------------------------------------------------
-- Saved settings
--------------------------------------------------------------------------

local function InitDB()
    TheListDB = TheListDB or {}
    for k, v in pairs(defaults) do
        if TheListDB[k] == nil then
            TheListDB[k] = (type(v) == "table") and {} or v
        end
    end
    db = TheListDB

    -- One-time seed from the optional Blacklist.lua file shipped alongside
    -- this addon. After this runs once, everything lives in SavedVariables
    -- (which survives addon updates), so this only matters for a brand new
    -- install that hasn't built up a blacklist yet.
    if not db.seededDefaults then
        db.seededDefaults = true
        if TheListSeedBlacklist then
            for name, note in pairs(TheListSeedBlacklist) do
                AddToBlacklist(name, note)
            end
        end
    end
end

--------------------------------------------------------------------------
-- Alert banner
--------------------------------------------------------------------------

local alertFrame
local alertQueue = {}
local alertActive = false
local AdvanceQueue

local function CreateAlertFrame()
    local f = CreateFrame("Frame", "TheListAlertFrame", UIParent, "BackdropTemplate")
    f:SetSize(360, 92)
    f:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
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
        f:SetBackdropColor(0.25, 0, 0, 0.95)
        f:SetBackdropBorderColor(1, 0.15, 0.15, 1)
    end

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -14)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Key_03")
    f.icon = icon

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    title:SetTextColor(1, 0.2, 0.2)
    title:SetText("BLACKLISTED PLAYER APPLIED")
    f.title = title

    local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    body:SetWidth(260)
    body:SetJustifyH("LEFT")
    f.body = body

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 4)
    close:SetScript("OnClick", function()
        f:Hide()
        AdvanceQueue()
    end)

    f:Hide()
    return f
end

local function PlayAlertSound()
    if not db.sound then
        return
    end
    local ok = pcall(PlaySound, SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
    if not ok then
        pcall(PlaySoundFile, "Sound\\Interface\\RaidWarning.ogg", "Master")
    end
end

AdvanceQueue = function()
    alertActive = false
    if #alertQueue == 0 then
        if alertFrame then
            alertFrame:Hide()
        end
        return
    end

    local entry = table.remove(alertQueue, 1)
    alertActive = true

    if not alertFrame then
        alertFrame = CreateAlertFrame()
    end
    alertFrame.body:SetText(entry.text)
    alertFrame:Show()
    PlayAlertSound()

    C_Timer.After(db.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
            AdvanceQueue()
        end
    end)
end

local function QueueAlert(name, note)
    local label = (note and note ~= true) and (" (%s)"):format(tostring(note)) or ""
    print(("|cffff2222[The List]|r WARNING: %s%s just applied to your key!"):format(name, label))

    table.insert(alertQueue, {
        text = ("%s%s just signed up to your group.\nCheck the Premade Groups applicant list."):format(name, label),
    })

    if not alertActive then
        AdvanceQueue()
    end
end

--------------------------------------------------------------------------
-- Applicant scanning
--------------------------------------------------------------------------

local alerted = {} -- [applicantID] = { [memberIdx] = true }

local function ScanApplicant(applicantID)
    if not applicantID or not db.enabled then
        return
    end

    local ok, id, numMembers = pcall(C_LFGList.GetApplicantInfo, applicantID)
    if not ok or not numMembers then
        return
    end

    alerted[applicantID] = alerted[applicantID] or {}

    for memberIdx = 1, numMembers do
        if not alerted[applicantID][memberIdx] then
            local nameOk, name = pcall(C_LFGList.GetApplicantMemberInfo, applicantID, memberIdx)
            if nameOk and name and IsBlacklisted(name) then
                alerted[applicantID][memberIdx] = true
                QueueAlert(name, db.blacklist[NormalizeName(name)])
            end
        end
    end
end

local function ScanAllApplicants()
    if not db.enabled then
        return
    end

    local ok, applicants = pcall(C_LFGList.GetApplicants)
    if not ok or not applicants then
        wipe(alerted)
        return
    end

    local present = {}
    for _, applicantID in ipairs(applicants) do
        present[applicantID] = true
        ScanApplicant(applicantID)
    end

    for applicantID in pairs(alerted) do
        if not present[applicantID] then
            alerted[applicantID] = nil
        end
    end
end

--------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
eventFrame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        InitDB()
    elseif event == "LFG_LIST_APPLICANT_LIST_UPDATED" then
        ScanAllApplicants()
    elseif event == "LFG_LIST_APPLICANT_UPDATED" then
        ScanApplicant(arg1)
    end
end)

--------------------------------------------------------------------------
-- Export / import
--------------------------------------------------------------------------

StaticPopupDialogs["THELIST_EXPORT"] = {
    text = "The List blacklist export (select all, Ctrl+C):",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self, data)
        self.editBox:SetText(data or "")
        self.editBox:HighlightText()
        self.editBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------

SLASH_THELIST1 = "/thelist"
SLASH_THELIST2 = "/tl"
SlashCmdList["THELIST"] = function(msg)
    msg = (msg or ""):trim()
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "add" and rest ~= "" then
        local name, note = rest:match("^(%S+)%s*(.-)$")
        if AddToBlacklist(name, note) then
            print(("|cffffd200[The List]|r Added '%s' to the blacklist."):format(name))
        else
            print("|cffffd200[The List]|r Usage: /tl add <name> [note]")
        end
    elseif cmd == "remove" and rest ~= "" then
        if RemoveFromBlacklist(rest) then
            print(("|cffffd200[The List]|r Removed '%s' from the blacklist."):format(rest))
        else
            print(("|cffffd200[The List]|r '%s' wasn't on the blacklist."):format(rest))
        end
    elseif cmd == "list" then
        local names = {}
        for name in pairs(db.blacklist) do
            table.insert(names, name)
        end
        table.sort(names)
        if #names == 0 then
            print("|cffffd200[The List]|r Blacklist is empty.")
        else
            print(("|cffffd200[The List]|r Blacklist (%d): %s"):format(#names, table.concat(names, ", ")))
        end
    elseif cmd == "export" then
        local str = ExportBlacklist()
        if str == "" then
            print("|cffffd200[The List]|r Blacklist is empty, nothing to export.")
        else
            StaticPopup_Show("THELIST_EXPORT", nil, nil, str)
        end
    elseif cmd == "import" and rest ~= "" then
        local count = ImportBlacklist(rest, false)
        print(("|cffffd200[The List]|r Imported %d name(s)."):format(count))
    elseif cmd == "test" then
        QueueAlert("Testington", "test")
    elseif cmd == "on" then
        db.enabled = true
        print("|cffffd200[The List]|r Enabled.")
    elseif cmd == "off" then
        db.enabled = false
        print("|cffffd200[The List]|r Disabled.")
    elseif cmd == "sound" then
        db.sound = not db.sound
        print("|cffffd200[The List]|r Alert sound " .. (db.sound and "on." or "off."))
    else
        print("|cffffd200[The List]|r Commands:")
        print("  /tl add <name> [note] - add a player to the blacklist")
        print("  /tl remove <name> - remove a player")
        print("  /tl list - show the blacklist")
        print("  /tl export - get a copyable string of your blacklist (names only)")
        print("  /tl import <str> - merge in a string from /tl export")
        print("  /tl test - fire a test alert")
        print("  /tl on|off - enable/disable warnings")
        print("  /tl sound - toggle alert sound")
    end
end
