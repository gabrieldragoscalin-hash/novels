# Combat power budget and regression scenarios

This supersedes earlier flat +1 damage, exponential attack speed, full-strength
extra-shot and repeated-overlapping-splash tuning. Floors1–2 remain forgiving;
the main stat step begins on floor3. This is a balance foundation to iterate on,
not a guarantee that undefined future content will automatically be balanced.

## Damage contract

The order is equipment weapon + bracelet damage, additive run damage multiplier,
critical/charged modifier, delivery coefficient, then applicable boss perk bonus.
Equipment remains meaningful; enemies never auto-scale to a player's loadout.
Later milestone starting floors remain the plan for strong accounts.

- Damage cards: +15% equipment damage per rank, additive, capped12 ranks (+180%).
  Three ranks give1.45× equipment damage, rather than adding3 full damage points.
- Attack speed: +12% per rank, additive, cap8 (+96%), replacing exponential1.15^N.
  A0.08s minimum attack interval bounds firing rate for future very fast weapons.
- Extra projectile: adds one parallel projectile per rank, ranged only. The whole set gains
  +35% output per rank, shared equally across its projectiles. Three
  projectiles total deal1.7× output, not3×. Melee area is a separate card.
- Multiple Shots: still adds one sequential salvo per rank. Combined output gains
  +30% per rank, shared across the salvos. Three salvos give1.6×, not3×.
- These two categories combine as (1+0.35×extra ranks)×(1+0.30×burst ranks).
  Even at both caps, total delivery output is3.895× rather than16×. Their separate
  categories reward combining upgrades while each rank has diminishing relative gain.
- Explosive arrows: full normalized direct damage plus45% of the attack's damage
  as splash, radius52. Each enemy can receive splash only
  once per entire attack cycle, including all parallel shots and sequential bursts.
  All explosion visuals remain; non-overlapping areas can still hit new enemies.
- Split children:45% of parent projectile damage each; no recursive splitting.
- Ordinary enemy ricochets retain85% damage per hop; chakram retains75% as before.
- Meteor overlaps share a cycle budget too: falling damage is applied once per
  victim per cycle, using the combined output multiplier. Rain reaches more
  distinct targets; repeatedly overlapping meteors cannot multiply damage again.
  Rolling meteors also share a once-per-victim rolling-damage ledger per cycle.
- Lasers and sword slashes use the same delivery budget. Continuous laser retains
  its10% baseline DPS advantage. Hammer gains burst output, not bonus damage from
  its cone-width upgrade. Critical damage works across every weapon form.
- Bow now charges naturally while stationary (0.6s before haste/Quick Draw),
  firing a penetrating1.8× shot; moving fires normal arrows. Deep Draw adds0.25×
  base damage per rank. Charging cannot bypass the normal cooldown. Stop and Aim
  is archived, not offered. Crossbow uses magazines/reloads instead.
- Lifesteal is limited to2% maxHP/cycle and4%/second before Recovery, uses actual
  damage rather than overkill, and does not heal from bleed. Secondary attacks
  cannot recursively create more secondary attacks. See [v2](design/WEAPONS_V2.md)
  for the per-weapon caps and trigger rules.
- Enemy hits from attacks stay fractional. We never round each small projectile
  up to a full damage point. Ledgers are bounded and cleared on room transitions.

## Later-floor health

| Enemy | Floor1 | Floor2 | Floor3 | Floor4 | Floor5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Normal |5|9|28|46|72|
| Shooter |4|7|21|34|52|
| Brute |10.2|19.55|52.7|86.7|132.6|
| Boss |52.8|96.8|264|448|720|

Floor5 loot guardian:184HP. Patterns, warnings, one-damage enemy hits and open
boss access remain. We avoid hiding extra difficulty in unavoidable damage or
scaling every early floor upward to counter permanent progression.

## Reproducible scenarios

Run `godot --headless --path . --script tests/power_budget_smoke.gd`.
The test automatically includes every weapon template. It fires actual attacks
for20s into a stationary high-HP boss, with no critical hits, perks or other gear.
This measures uninterrupted damage potential; displayed boss times are HP/DPS
estimates, NOT measured live fights or guaranteed expedition times. Dodging,
travel, aim, crowd layout, gear and card availability change real clear times.

Mid profile:3 damage ranks,2 attack-speed ranks,2 extra-projectile ranks, no burst;
plus Explosive for bow or Perpetuum for wand. Late profile:6 damage,
4 speed,3 extra,3 burst, plus that weapon modifier. For wand beam/meteor variants,
replace Perpetuum with the named form. Melee ignores ranged-only Extra Projectile; returning weapons use shared ranks without a
weapon-specific card. These are explicit fixtures, not promises about exact drop
or card counts on any floor.

| Weapon/form | Profile | DPS | Floor5 boss HP/DPS estimate |
| --- | --- | ---: | ---: |
| bow | mid | 11.20 | 64.3s |
| bow | late | 34.57 | 20.8s |
| crossbow | mid | 7.89 | 91.3s |
| crossbow | late | 27.10 | 26.6s |
| wand | mid | 8.50 | 84.7s |
| wand | late | 30.39 | 23.7s |
| sword | mid | 9.18 | 78.4s |
| sword | late | 26.84 | 26.8s |
| hammer | mid | 7.25 | 99.3s |
| hammer | late | 21.30 | 33.8s |
| chakram | mid | 11.06 | 65.1s |
| chakram | late | 38.69 | 18.6s |
| spear | mid | 11.44 | 63.0s |
| spear | late | 39.74 | 18.1s |
| dual_axe | mid | 7.25 | 99.3s |
| dual_axe | late | 21.66 | 33.2s |
| club | mid | 7.98 | 90.3s |
| club | late | 23.24 | 31.0s |
| wand_beam | late | 30.90 | 23.3s |
| wand_meteor | late | 31.08 | 23.2s |

The reported middle bow setup deals about3.12 direct+splash damage in one complete
three-arrow volley (no crits), versus20.4 under the old flat damage/full-shot/
70%-splash rules. It cannot one-shot a floor3 normal with28HP.

## Adding future content

- Put tuning in `scripts/combat_balance.gd`, keep loadout/permanent bonuses distinct
  from bounded run bonuses, and use `delivery_factor()` for every new attack form.
- Give each attack cycle an ID; secondary area effects must share hit budgets.
  Extra visual projectiles or overlapping areas must not introduce a second,
  unbounded multiplier. Avoid rounding damage per hit.
- Add form-specific scenarios and crowd-overlap checks alongside the automatically
  discovered weapon cases. Check weak, mid and strong builds, not only maximum gear.
- Existing tests enforce the reported no-one-shot case, duplicate-splash protection,
  meteor overlap protection, charge cooldown and bounded ledger history. The
  nine-weapon profiles must improve on baseline while staying under15× baseline.
- Measure live room/boss times on mobile too. A test passing does not establish
  whether movement, enemy pressure, rewards or a new perk feels fair.

## Ten-floor/perk expansion

The shared output-budget formulas remain. Brute HP is reduced15% and boss/guardian
HP20%; floor5 boss is now720. The table above reflects that reduction and the test
reads current HP dynamically. The new weapon support/signature combinations need
further mobile balance testing; the baseline/mid/late benchmarks do not include
all possible support stacks. Retired cards are not in the offer pool.
Floors6–10 and their tuning are documented in BALANCING.md.
