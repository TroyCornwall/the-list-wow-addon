# Gallywix Casino Ads

**Flashy fake Gallywix casino ads pop up mid-combat to troll your raid — client-side, harmless, and deeply obnoxious.**

Ever wanted your screen to look like a 2004 freeware download site the second a pull starts? Now it can. **Gallywix Casino Ads** throws up a gaudy, flashing "casino ad" popup — complete with spinning slot reels, rainbow strobing text, a fake countdown timer, and classic early-internet clickbait ("YOU ARE THE 1,000,000th VISITOR!!", "CLAIM YOUR FREE SPINS NOW") — at random intervals while you're in combat. Perfect for messing with raid leads, streamers, or anyone testing on the beta who could use a jumpscare between pulls.

## Features

- 🎰 Pops up automatically when you enter combat, gone the instant combat ends
- 💰 Spinning slot-machine reels (coins, gems, dice) that land on random icons
- 🌈 Old-school flashing rainbow title text and a blinking "CLICK HERE" button
- ⏱️ Fake urgency countdown timer that never actually runs out
- 🎲 8 different rotating ad templates so it doesn't get stale
- 📍 Spawns at a random spot on screen every time
- 🖱️ Draggable, closeable, and fully controllable via slash commands
- ✅ 100% client-side and cosmetic — it doesn't touch your combat log, action bars, or any secure/protected frames, so it's completely safe to run in any raid, including current tier progression

## How it works

While you're in combat, the addon shows a random ad every 8–20 seconds (configurable). Each ad plays a little "ding," spins its slot reels for about a second, and then sits on screen for a few seconds before fading out on its own — or just click the little red X to dismiss it early. Leave combat and any ad currently showing disappears immediately, so it never lingers over a boss kill screen or loot roll.

## Slash Commands

| Command | What it does |
|---|---|
| `/ads` | Toggle the addon on/off |
| `/ads test` | Force-show a random ad right now (no combat required) |
| `/ads on` / `/ads off` | Explicitly enable/disable |
| `/ads freq <min> <max>` | Set how often ads can appear during combat, in seconds (default `8 20`) |

## Compatibility

Built and tested against the **12.1.5** beta client. If Blizzard bumps the beta build number and the addon shows as out-of-date, just enable "Load out of date AddOns" in your AddOns list — it doesn't use any API that's likely to break between beta builds.

## FAQ

**Does this affect other players?** No. Addons are 100% client-side — only you see the popup. It's a prank for your own screen (great for streaming/content or messing with whoever's sitting next to you), not something that touches anyone else's client.

**Will this get me flagged for anything?** No combat, secure, or protected frames are touched. It's a plain UI frame drawn on top of your screen, same as any tooltip or alert addon.

**Can I make it less/more annoying?** Yes — use `/ads freq <min> <max>` to space the ads out further, or `/ads off` to kill it entirely.

## Disclaimer

This addon is a joke. It doesn't gamble, doesn't cost gold, doesn't link to anything, and doesn't collect or send any data anywhere. It just draws an ugly fake ad on your own screen for laughs.
