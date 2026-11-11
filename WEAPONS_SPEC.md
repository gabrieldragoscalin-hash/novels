# Weapons and upgrade revision

This replaces the old side-shot/wall-bounce/status-card prototype. All six weapon
families are equipment copies, available in normal loot/chests/shop pools and in
the testing cheat menu. Equipment changes apply to the next expedition.

## Weapons

| Weapon | Attack |
| --- | --- |
| Bow | Normal traveling arrow |
| Crossbow | Larger arrow, higher damage, slower attack speed |
| Wand | Traveling magic beam; inherently passes through obstacles |
| Sword | Forward slash arc at close range |
| Hammer | Forward cone shockwave, area damage |
| Chakram | Thrown disc; initial hit then up to three additional enemy bounces, reduced damage each bounce |

Targeting chooses the nearest eligible enemy. Attacks normally continue while
moving; Stop and Aim changes stationary bow/crossbow behavior. Melee attacks use
range/cone checks, with obstacles blocking hits unless See All is selected.

## Shared upgrades

- Increased damage, movement speed, attack speed and EXP gain remain.
- Punchthrough remains: each rank allows one more enemy penetration.
- **Extra projectile** replaces the side bullet. Every rank adds one parallel
  projectile, side by side in the same direction, for bow/crossbow/wand/chakram.
  Sword instead adds another alternating slash (left→right, then right→left).
  Hammer instead widens the cone, without increasing its length.
- **Multiple Shots** adds one sequential attack per rank, within the same attack
  cycle. It combines with Extra projectile; sword salvos contain their extra
  alternating slashes, and hammer salvos repeat their widened shockwave.
- **Ricochet** adds one enemy-to-enemy bounce per rank. No wall reflection remains.
- **Follow** homes projectiles toward enemies and, after penetration or bouncing,
  seeks an enemy not already hit by that projectile.
- **See All** lets projectiles and melee hit through obstacles. It is never
  offered for a wand and never reappears after being selected in that run, even
  if traded away. It does not permit attacks to leave the room.

Punchthrough, Ricochet and Follow are offered for projectile weapons, not sword
or hammer. No additional melee-specific upgrade cards are introduced yet.
Old Vitality/critical/status/XP-attraction/regeneration cards are removed from
the card pool. Equipment critical chance and baseline XP attraction still exist.

## Bow and crossbow cards

### Arrow split

At the final enemy hit, split into three arrows: forward, left and right relative
to travel. With Punchthrough/Ricochet, defer splitting until the attack's last hit.
With Follow, children home toward available enemies too. Children do not recursively
split or re-hit enemies already hit by their parent. Replaces Explosive arrows.

### Stop and Aim

When stationary with a target, charge up to three seconds. Automatically release
at three seconds, or release early when movement resumes. No proportional damage
ramp is specified: each released charged attack deals double damage, is larger,
always penetrates enemies and ignores Ricochet and Follow. Normal moving attacks
remain available between charges. Extra projectile and Multiple Shots still work.

### Explosive arrows

Direct enemy impact deals full projectile damage, followed by an area explosion
for 70% of projectile damage to every enemy in range, including the impact victim.
Ordinary explosive arrows stop on impact and ignore Punchthrough/Ricochet.
Obstacle impacts can explode too; See All bypasses those obstacles. Stop and Aim
doubles the explosion radius. Replaces Arrow split.

**Interaction choice for testing:** the request says charged shots always penetrate
and explosive shots do not penetrate. Charged explosive shots prioritize the
charged rule: penetrate, deal doubled impact damage and explode at each distinct
hit with doubled splash radius. They still ignore Follow and Ricochet.

## Wand cards

### Perpetuum

Replaces traveling beams with a continuous laser. Lower damage per tick, faster
hits, and slightly better baseline DPS than the unupgraded wand. It still passes
through obstacles. Extra projectile creates parallel lasers; Multiple Shots adds
staggered laser ticks. Punchthrough extends straight-line hits. Ricochet chains
onto additional enemies; Follow guides the primary beam and remaining penetrations
to additional enemies. Chained/guided later hits deal less damage. Replaces Meteor.

### Magic Meteor

Cast falling meteors at target positions, with area damage on impact. Meteors have
a brief visible fall/landing marker and do not home while falling. Replaces
Perpetuum. Standard penetration, ricochet and homing mechanics do not apply.
While selected, their existing ranks and card slots become:

| Shared slot | Meteor replacement |
| --- | --- |
| Punchthrough | Meteor Size: starts at target enemy size; +20% base radius per rank |
| Ricochet | Meteor Rain: target one additional distinct enemy per rank |
| Follow | Telekinesis: after falling, roll toward the nearest other enemy; deal 25% of falling damage when rolling over enemies and continue straight until leaving the room |

Extra projectile adds another meteor per selected target; Multiple Shots repeats
casts within the attack cycle. Switching back to Perpetuum returns the three
shared ranks to their usual effects. A rolling meteor cannot repeatedly damage
the same enemy. Damage and attack speed affect all wand forms.

## Prototype tuning values

These values are implementation choices for balance testing, not fixed design:

- Common level-1 damage / interval: bow 1 / 0.45s; crossbow 2 / 0.72s;
  wand 1 / 0.34s; sword 3 / 0.65s; hammer 4 / 1.0s; chakram 2 / 0.7s.
- Sword reach 88 units, half-angle 1.1 radians. Hammer reach 125, half-angle
  0.45 radians, +0.14 per Extra projectile rank. Visual slash direction alternates.
- Chakram retains 75% damage on each bounce; Ricochet adds beyond its native three.
- Laser ticks every 0.1s; per-tick damage is base damage × 0.1 / current weapon
  interval × 1.1 × (1 + critical chance), making expected sustained DPS 10% higher.
  The critical multiplier is averaged for smooth continuous laser damage. Laser chain hits retain
  75% of the preceding hit's damage. Fractional damage is preserved.
- Arrow splash radius 64 units (128 with Stop and Aim). Charge size multiplier 1.8.
- Meteor fall delay 0.45s, radius 17 normal /27 boss before size upgrades;
  rolling speed 180 units/s. Size grows linearly from base, not compounded.
- Rank caps: damage uncapped; attack speed 8; movement 5; EXP gain 3;
  Punchthrough/Extra projectile/Multiple Shots/Ricochet 5 each; other cards 1.
  Mutually exclusive cards can reappear when their counterpart replaces them.
- Burst timings are distributed within the weapon interval; no attack-speed penalty
  is added. Each projectile tracks its own prior hits to prevent repeated rewards.

The cheat menu now allows selecting a specific eligible run upgrade, so combinations
can be tested without repeatedly rolling level-up cards. Progression currently ends after floor 5.
