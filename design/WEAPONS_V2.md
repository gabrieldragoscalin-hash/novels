# Nine-weapon upgrade rework (v2)

The old playable system is preserved in [the v1 archive](archive/upgrades_v1/README.md)
and Git tag `upgrades-v1-before-nine-weapons`. Account equipment and currencies are
preserved. Enemy stats, rooms and the floor-10 cap are unchanged in this revision.

The editable catalog is [weapon_upgrades_v2.json](weapon_upgrades_v2.json).
Run `python tools/build_upgrade_catalog.py` after editing it. Gameplay coefficients
live in `scripts/combat_balance.gd` and `scripts/weapon_behaviors.gd`; descriptions
and caps do not generate combat behavior automatically.

## Weapon identities and starting designs

| Weapon | Identity | Design |
| --- | --- | --- |
| Bow | Fire while moving; stand still to charge a penetrating arrow | Existing Ranger bow |
| Crossbow | High-impact bolts, three-bolt magazine, reload | Existing Iron crossbow |
| Wand | Pulses through scenery; optional laser or meteors | Existing Ember wand |
| Spear | Outward hit, brief lodge, then return; reposition to sweep with recall | Dawnpiercer: long bronze/gold spear, ivory head, crimson binding |
| Chakram | Curved outward path, lingering/return hits, or orbit | Existing Gale chakram |
| Sword | Three-step combo and finisher, optional blade wave or guard | Existing Vanguard sword |
| Dual axe | Alternate hands, build rhythm, finish in a spin or twin strike | Twin Eclipse: paired crescent bronze axes, jade inlays, crimson grips |
| Club | Slow wide swings, knockback and enemy collisions | Titanwood: oversized gnarled timber, bronze bands, jade/crimson details |
| Hammer | Forward ground shockwaves, optional circular slam or fissure | Existing Earthshaker hammer |

The three new weapons include inventory portraits, item/held sprites and gameplay
attacks. They use the shared character rig, grip metadata and weapon hooks rather
than separate animations for every character/weapon combination. The dual axes
render in both hands. These are testable first-pass designs, pending final art.
All nine templates participate in chest/loot generation, synthesis and cheats.

## Shared upgrades

### All weapons

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Increased damage | +15% equipment damage | 12 |
| Increased attack speed | +12% attack speed and reload speed | 8 |
| Increased move speed | +10% movement speed | 5 |
| Vitality | +10% starting maximum HP; heal HP gained | 5 |
| Full heal | Restore all missing HP immediately | Repeatable while injured |
| Lifesteal | Heal 1% of attack damage; capped per attack cycle | 5 |
| Increased EXP gain | +20% experience gained | 3 |
| Projectile speed / melee reach | +10% projectile speed or +5% melee reach | 5 |
| Room barrier | Block one incoming hit per room | 1 |
| Room gold | +3 coins per completed non-start room per rank; once per room/floor | 5 |
| Second Chance • RARE | Revive once at 25% maximum HP this run | 1 |
| Multishot | +1 consecutive attack per cycle; +30% total output | 3 |

### Ranged only

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Ricochet | Bounce to one more enemy | 5 |
| Attack through obstacles | Projectiles pass through obstacles | 1 |
| Follow enemy | Projectiles home toward enemies | 1 |
| Extra projectile | +1 simultaneous parallel projectile; +35% total output | 3 |

### Melee only

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Larger area | Widen the slash or cone by 15% | 5 |
| Jump attack | Every 5 seconds leap to the nearest enemy and strike harder | 1 |
| Hard slam | First hit each cycle sends a 20% damage wave behind its target | 1 |

Full Heal restores all missing HP and is hidden at full health. Room Barrier
blocks one hit regardless of time spent in the room; spending it persists across
revisits. Buying it mid-room activates it if this room has not spent a charge.
Second Chance is rare, instant, exactly 25% max HP and cannot be taken again in
that run. Attack through obstacles is hidden for wands, which already have it.

Lifesteal uses actual damage, excluding overkill. It heals 1% damage per rank,
capped at 2% max HP per attack cycle and 4% max HP per second before the permanent
Recovery perk. Bleed does not heal. Hard Slam triggers once per cycle and cannot
recursively trigger itself. Jump Attack strikes at 150% damage, checks landing
collision and gives a short safety window. Circular melee attacks gain area
rather than an invisible cone angle. Bosses and mini-bosses resist stun,
displacement and pinning; brutes have reduced knockback.

## Weapon-specific upgrades

Each weapon has three support upgrades and two alternative signatures. Taking
one signature replaces the other; support upgrades remain. Signatures have
relative offer weight 0.35, regular cards 1, Second Chance 0.08. Weapon cards use
that weapon's icon in the existing animated card reveal.

### Bow

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Deep Draw | Charged arrows gain +25% damage | 3 |
| Quick Draw | Charge aimed arrows 20% faster | 3 |
| Marked Prey | Charged hits mark targets; follow-up arrows gain 10% damage | 3 |
| Explosive Arrows | Impact plus 45% splash once per cycle; replaces Arrow Split | 1 |
| Arrow Split | After the final hit, split into 3 weaker arrows; replaces Explosive Arrows | 1 |

### Crossbow

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Larger Magazine | One more bolt before reloading | 3 |
| Quick Loader | Reload 15% faster | 3 |
| Pinning Bolts | Bolts briefly pin small enemies against nearby walls | 1 |
| Repeater | Rapidly fire the magazine, then take a longer reload | 1 |
| Ballista | One huge penetrating bolt with a slower reload | 1 |

### Wand

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Arcane Residue | Spell impacts leave a brief damaging patch | 3 |
| Mana Echo | Every fourth cast repeats at reduced strength | 3 |
| Spell Focus | Repeated hits on one target build up to 30% extra damage | 3 |
| Perpetuum | Replace pulses with a continuous laser | 1 |
| Magic Meteor | Replace pulses with delayed falling meteors | 1 |

### Spear

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Serrated Head | Lodged spears cause a short bleed | 3 |
| Swift Recall | Spears return sooner and faster | 3 |
| Skewer | Penetrate one more enemy on outward throws | 3 |
| Returning Strike | Stronger return hits; reposition to sweep enemies | 1 |
| Impaler | Spears lodge longer and pulse area damage before returning | 1 |

### Chakram

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Wider Arc | Widen the curved flight path | 3 |
| Lingering Disc | Linger longer near the end of outward flight | 3 |
| Serrated Rhythm | Repeated disc hits build a capped damage bonus | 3 |
| Orbiting Blades | Replace throws with blades circling the character | 1 |
| Hunting Discs | Stay out longer, ricocheting between enemies before returning | 1 |

### Sword

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Extended Combo | Add one slash before the stronger finisher | 2 |
| Riposte | After a dodge or guard, the next slash is stronger | 3 |
| Execution | Finishers deal more damage to wounded enemies | 3 |
| Sword Wave | Combo finishers launch a travelling blade wave | 1 |
| Counterguard | Finishers briefly guard the front; a block empowers the next slash | 1 |

### Dual Axe

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Crosscut | Striking with both axes in succession causes bleed | 3 |
| Battle Rhythm | Successful attacks build temporary attack speed | 3 |
| Hooked Edges | Outer hits pull smaller enemies inward | 3 |
| Whirlwind | Completing a combo spins an attack around you | 1 |
| Twin Execution | Periodically strike forward with both axes for focused damage | 1 |

### Club

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Heavy Timber | Increase stagger and knockback | 3 |
| Backswing | Add a weaker return swing | 3 |
| Crowd Pressure | Enemy collisions briefly slow the enemies involved | 3 |
| Bowling Blow | Knocked enemies travel farther and damage those they collide with | 1 |
| Titan’s Grip | Replace sweeps with slow overhead crushing blows | 1 |

### Hammer

| Upgrade | Effect | Rank cap |
| --- | --- | ---: |
| Aftershock | A weaker second impact strikes the same area | 3 |
| Fault Line | Extend the ground shockwave | 3 |
| Fracture | Repeated hammer hits increase damage from subsequent hammer strikes | 3 |
| Seismic Slam | Replace forward waves with circular shockwaves | 1 |
| Fissure | Forward waves leave a short-lived damaging crack | 1 |

## Interactions and damage safeguards

- Bow charge takes 0.6 seconds before attack-speed and Quick Draw bonuses; charged
  arrows deal 1.8× base damage, plus 0.25× per Deep Draw rank. They penetrate but
  do not home or ricochet. Moving fires ordinary arrows. Charge cannot bypass the
  weapon cooldown. The old Stop and Aim card is retired.
- Extra Projectile means simultaneous parallel shots on ranged weapons only.
  Multishot means consecutive attacks on every weapon. Damage is divided across
  the delivery count: +35% combined output per extra-projectile rank and +30%
  per Multishot rank, rather than full-damage copies. Both cap at 3 ranks.
- Explosive Arrows and Arrow Split belong to bow. Explosions retain 45% splash,
  once per victim per cycle, including bursts. Charged explosions keep radius 52.
- Crossbow reloads after its magazine. Repeater discharges the magazine rapidly
  at 80% bolt damage, then reloads longer; Ballista fires a double-damage heavy
  penetrating bolt and reloads after every attack cycle.
- Wand Mana Echo repeats every fourth cast at 40/55/70% power. Arcane patches
  have a lifetime/count cap; Spell Focus tops out at +30%. Laser/meteor forms
  remain exclusive. Meteor converts Ricochet/Follow into Rain/Telekinesis; Meteor
  Size is offered only in meteor form and gives +20% base radius per rank (cap5).
  Reach becomes faster descent. Overlapping meteors share per-cycle hit budgets.
- Spear damage is 80% outward and 40% returning, or 100% returning with Returning
  Strike. Skewer adds outward penetration. Impaler extends the lodge and pulses
  local damage before returning; lodged spears follow their struck enemy.
- Chakram repeat contacts have a 0.3s interval and separate return tracking.
  Serrated Rhythm tops out at +30%. Orbiting blades maintain continuous angles;
  extra blades are distributed around the character, never stacked together.
- Sword Extended Combo adds a slash and increases finisher strength. Riposte
  follows an actual dodge, near miss or guard. Counterguard protects the front
  briefly after a finisher; it is not permanent invulnerability.
- Club collisions, delayed swings, hammer aftershocks and persistent patches
  cannot recursively create more secondary attacks. Fissures spawn one path per
  cycle and club collisions pay once per victim/cycle, using the normalized output
  budget. Jump damage never shrinks when Multishot is selected. Hammer Fracture caps at30%
  and expires without follow-up hits. Active patches cap24, VFX cap72, returning
  projectiles cap192; hit ledgers retain bounded history.

## Testing and next balance pass

`tests/nine_weapons_smoke.gd` exercises all nine base attacks and all18 signatures,
weapon pools, saved equipment, healing caps, barrier, jump, reload and boss immunity.
The remaining upgrade and power-budget suites test delivery, collisions, splash
and meteor overlap. Browser checks cover actual exported inventory/combat art.
These are prototype numbers; real mobile run timing still needs playtesting before
redesigning enemies/rooms or treating the new builds as final balance.


Upgrade reward update: level-ups and free/start/shop/wheel/loot upgrade rewards
now offer three eligible upgrades. The coin card is removed; direct loot, wheel
and shop currency rewards remain. When fewer than three eligible cards remain
at their caps, show only those cards; if none remain, clear the reward queue
without presenting an empty choice. Never pad the pool with duplicate or coin cards.
