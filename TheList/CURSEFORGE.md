# The List

**Warns you when someone on your blacklist applies to your Mythic+ keystone group — before you accidentally invite them.**

Ever posted a key in Premade Groups and invited someone off your own personal "never again" list because the applicant queue moves faster than your memory does? **The List** watches your group's applicant queue and throws up a hard-to-miss red alert — with a sound — the moment a blacklisted name signs up, so you catch it before you hit invite.

## Features

- 🚨 Watches your posted Group Finder listing and flags applicants on your blacklist the instant they apply
- 🔊 Plays an alert sound and drops a flashing on-screen banner so it doesn't get lost in the applicant list
- 📋 Simple slash commands to manage your list — no config UI to dig through
- 💾 Your list lives in SavedVariables, so it survives every addon update automatically
- 🔁 Export/import your list as a plain string to share with people you trust
- ✅ 100% read-only and client-side — it only reads applicant info from the standard Group Finder API. It never invites, declines, or otherwise touches anyone's application for you

## How it works

While you have a group posted, The List checks every applicant against your blacklist. If a match comes in, you get a chat warning, a sound, and a banner naming who applied — the decision to invite or decline is still entirely yours, made from the normal Premade Groups UI.

## Slash Commands

| Command | What it does |
|---|---|
| `/tl add <name> [note]` | Add a player to your blacklist, with an optional reason |
| `/tl remove <name>` | Remove a player from the list |
| `/tl list` | Show everyone currently on your list |
| `/tl export` | Get a copyable string of your list (names only) to share with people you trust |
| `/tl import <string>` | Merge in a list someone shared with you |
| `/tl test` | Fire a test alert without needing a live applicant |
| `/tl on` / `/tl off` | Enable or disable warnings |
| `/tl sound` | Toggle the alert sound |

Names are matched case-insensitively, and `-Realm` suffixes are stripped automatically, so `Name` and `Name-Realm` both work.

## FAQ

**Does this touch other players' clients?** No. Addons are 100% client-side — only you see the alert. It doesn't send, broadcast, or sync anything to anyone automatically.

**Will this get me flagged for anything?** No secure or protected frames are touched, and it never calls invite/decline/kick on your behalf — it only reads applicant info the game already shows you and displays it more clearly.

**Can other people see who's on my list?** No, unless you explicitly `/tl export` and hand the string to them yourself.

## Disclaimer

This is a personal group-management tool, not a public callout list. It doesn't collect or transmit data anywhere, and it can't act on your group for you — you still make every invite/decline decision yourself.
