# Sanity System

A drop-in sanity + hallucination system for a Roblox horror game. **No frameworks, no packages, no Rojo.** You copy 4 scripts into Studio and it runs. Sanity is 0–100 and server-authoritative; the client handles the HUD bar, screen effects, panic audio, and the hallucination that spawns behind you in the dark.

## Install (copy/paste in Studio)

Download the files, open each in a text editor, and copy its contents into a new object in Studio:

| Create this object | Put it here | Paste the file |
|---|---|---|
| **ModuleScript** named `SanityConfig` | `ReplicatedStorage` | `SanityConfig.luau` |
| **ModuleScript** named `FlashlightState` | `ReplicatedStorage` | `FlashlightState.luau` |
| **Script** named `SanityServer` | `ServerScriptService` | `SanityServer.luau` |
| **LocalScript** named `SanityClient` | `StarterPlayer` → `StarterPlayerScripts` | `SanityClient.luau` |

> To make an object: right-click the place in Explorer → Insert Object → pick the type. Rename it exactly as shown.

That's the whole install. Press Play and the sanity bar appears at the bottom.

## Studio setup (needed for the full experience)

1. **The monster:** put your rig `Model` in `ReplicatedStorage`, inside a folder named `Entities`, and name the model `Larry`. (Rename in `SanityConfig` → `HALLUCINATION.ENTITY_NAME`.)
2. **Lights:** select each light-emitting object → in Properties/Tags, add the tag `LightSource`. Sanity refills near them and the monster won't spawn near them. (No tags = the whole map counts as "dark".)
3. **Sounds:** in `SoundService`, make a folder `EntitiesSounds` with this inside — a folder means "pick a random one":
   ```
   EntitiesSounds/
     Breathing/  Monster (Sound)   Player (Sound)
     Warns/      Pst (Sound)
     Screams/    Scream1 (Sound)   Scream2 (Sound)
   ```

## Your flashlight (optional, one line)

If you have a flashlight and want it to banish the monster, add this to your flashlight code where it turns on/off:

```lua
local FlashlightState = require(game.ReplicatedStorage:WaitForChild("FlashlightState"))

FlashlightState.set(true)   -- when the light turns ON
FlashlightState.set(false)  -- when the light turns OFF
```

- Look at the monster with the light **ON** → it fades away, no damage.
- Look at it with the light **OFF** (or if you skip this step) → jumpscare + damage, then it vanishes.

## Using your own bar UI

The default bar is built automatically. To use your own instead:

1. Press Play once so the default bar appears. In the Explorer under your player's `PlayerGui`, copy the `SanityUI` ScreenGui.
2. Stop the game and paste it into `StarterGui`. Now restyle it however you want — colors, position, add images, whatever.
3. Keep two things: the ScreenGui named **`SanityUI`**, and somewhere inside it a Frame named **`Fill`** (that's the part the script stretches). Set the ScreenGui's `ResetOnSpawn` to **false**.

The script finds your `Fill` and drives its width; everything else is yours. (Prefer to build it from scratch? Just make a `SanityUI` ScreenGui with a `Fill` frame inside.)

## Tweak anything — all in `SanityConfig`

| Want to change… | Field |
|---|---|
| How often the monster appears | `HALLUCINATION.CHECK_INTERVAL` |
| Chance it appears (base + low-sanity bonus) | `HALLUCINATION.BASE_CHANCE`, `SANITY_BONUS` |
| How far behind you it spawns | `HALLUCINATION.SPAWN_MIN` / `SPAWN_MAX` |
| How long it stays after a scare | `HALLUCINATION.SCARE_DESPAWN_DELAY` |
| Fade time when the light banishes it | `HALLUCINATION.DISSIPATE_TIME` |
| Which rig / light tag name | `HALLUCINATION.ENTITY_NAME`, `LIGHT_TAG` |
| Scare damage / cooldown | `SCARE_DAMAGE`, `SCARE_COOLDOWN` |
| Sanity drain / regen speed | `DRAIN_PER_SECOND`, `REGEN_PER_SECOND` |
| Health lost at 0 sanity | `ZERO_HEALTH_DPS` |
| When the screen effects start | `EFFECT_THRESHOLD` |
| The horror look (blur / desaturation / tint) | `EFFECTS.*` |
| Breathing / heartbeat volume + pitch | `PLAYER_AUDIO.*` |
| Default bar colors | `UI.BAR_FULL`, `UI.BAR_EMPTY`, `UI.BAR_BG` |
| Which sounds play | `SOUNDS.*` (add `HEARTBEAT` to enable a heartbeat) |
