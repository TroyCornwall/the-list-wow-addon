-- Optional seed list for KeyWarden.
--
-- Entries here are copied into your blacklist ONE TIME, the first time this
-- addon loads on an account. After that, your additions/removals via /kw
-- live in SavedVariables and persist across addon updates on their own —
-- you will rarely need to touch this file. It mainly exists to pre-populate
-- a blacklist on a brand new install (e.g. a fresh PC) before you've had a
-- chance to run /kw add.
--
-- This file ships as part of the addon package, so treat it as visible to
-- anyone who ends up with the zip — that's fine for a private/unlisted
-- CurseForge project scoped to your own friend group, but keep it EMPTY in
-- any build you publish publicly. A public listing turns a personal ignore
-- list into an accusation list anyone can grab, with no verification and no
-- way for the named player to contest it — the kind of content CurseForge
-- pulls addons for. For a one-off share outside the private project, use
-- /kw export and send the string directly instead of editing this file.

KeyWardenSeedBlacklist = {
    -- ["charactername"] = "optional reason",
}
