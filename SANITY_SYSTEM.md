# Sanity System

Client–server sanity + hallucination system for a horror game. Sanity is 0–100 and fully **server-authoritative** (the server owns the value and the damage). The client just renders the HUD, screen effects, audio, and the local hallucination.

## Files

Drop these into your game (they auto-load via the module loader — `Init()` / `Start()`):

```
Shared/Modules/SanityConfig.luau      <- all tuning
Shared/Modules/SoundKit.luau          <- audio helper
Shared/Modules/FlashlightState.luau   <- tiny flashlight on/off bridge
Shared/UI/SanityBar.luau              <- the HUD bar (Vide)
Services/SanityService.luau           <- server: sanity, health, scare damage
Controllers/SanityController.luau     <- client: HUD + effects + low-sanity audio
Controllers/HallucinationController.luau  <- client: the entity
```

## Studio setup

1. **Rig:** put your entity `Model` at `ReplicatedStorage.Entities.Larry` (rename via `HALLUCINATION.ENTITY_NAME`).
2. **Lights:** tag every light-emitting object with the `LightSource` CollectionService tag (rename via `LIGHT_TAG`). Sanity regenerates near them; the entity won't spawn near them.
3. **Sounds:** build this under `SoundService.EntitiesSounds` — a folder means "pick a random child":
   ```
   EntitiesSounds/
     Breathing/  Monster (Sound)   Player (Sound)
     Warns/      Pst (Sound)
     Screams/    Scream1 (Sound)   Scream2 (Sound)
   ```

## Flashlight — one line

The hallucination reads a client-side on/off flag. In your own flashlight code, on the client:

```lua
local FlashlightState = require(ReplicatedStorage.Shared.Modules.FlashlightState)

FlashlightState.set(true)   -- when your light turns on
FlashlightState.set(false)  -- when it turns off
```

Look at the entity with the light **off** → jumpscare + damage, then it vanishes.
Look at it with the light **on** → it fades out, no damage.
If you never set it, it's treated as off.

## Customize — all in `SanityConfig.luau`

| Want to change… | Field |
|---|---|
| How often it can appear | `HALLUCINATION.CHECK_INTERVAL` |
| Spawn odds (base + low-sanity bonus) | `HALLUCINATION.BASE_CHANCE`, `SANITY_BONUS` |
| How far behind you it spawns | `HALLUCINATION.SPAWN_MIN` / `SPAWN_MAX` |
| Spread of the spawn cone behind you | `HALLUCINATION.SPAWN_SPREAD` |
| How dead-on you must look to trigger it | `HALLUCINATION.GAZE_DOT` (1 = exact center) |
| How long it lingers after a scare | `HALLUCINATION.SCARE_DESPAWN_DELAY` |
| Fade time when dispelled by the light | `HALLUCINATION.DISSIPATE_TIME` |
| Min distance from a light to spawn | `HALLUCINATION.LIGHT_RADIUS` |
| Which rig / light tag | `HALLUCINATION.ENTITY_NAME`, `LIGHT_TAG` |
| Scare damage / cooldown | `SCARE_DAMAGE`, `SCARE_COOLDOWN` |
| Sanity drain / regen speed | `DRAIN_PER_SECOND`, `REGEN_PER_SECOND` |
| Health lost per second at 0 sanity | `ZERO_HEALTH_DPS` |
| When screen effects kick in | `EFFECT_THRESHOLD` |
| Effect look (blur / desat / tint) | `EFFECTS.*` |
| HUD/effect smoothing speed | `SMOOTH_SPEED` |
| Breathing / heartbeat volume + pitch | `PLAYER_AUDIO.*` |
| Sound assets used | `SOUNDS.*` (set `HEARTBEAT` to enable the heartbeat) |

Bar look/position: top constants in `SanityBar.luau`.

## Security

The server is the only writer of `Humanoid.Health` and the `Sanity` attribute. On a scare, the client fires a **parameterless** event; the server decides the damage, rate-limits it, confirms you're actually in the dark, and only ever damages you. **Never read the flashlight state on the server** — it's a client-only signal.
