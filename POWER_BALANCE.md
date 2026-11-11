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
- Extra projectile: still adds one projectile/slash per rank. The whole set gains
  +35% output per rank, shared equally across its projectiles/slashes. Three
  projectiles total deal1.7× output, not3×. Hammer still widens without extra damage.
- Multiple Shots: still adds one sequential salvo per rank. Combined output gains
  +30% per rank, shared across the salvos. Three salvos give1.6×, not3×.
- These two categories combine as (1+0.35×extra ranks)×(1+0.30×burst ranks).
  Even at both caps, total delivery output is6.875× rather than36×. Their separate
  categories reward combining upgrades while each rank has diminishing relative gain.
- Explosive arrows: full normalized direct damage plus45% of the attack's damage
  as splash, radius52 (104 with Stop and Aim). Each enemy can receive splash only
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
- Stop and Aim requires at least0.35s charging for a doubled attack. Early releases
  use an ordinary attack; neither can bypass the normal weapon cooldown. This
  closes the repeated stop/start double-shot exploit. Automatic release stays3s.
- Enemy hits from attacks stay fractional. We never round each small projectile
  up to a full damage point. Ledgers are bounded and cleared on room transitions.

## Later-floor health

| Enemy | Floor1 | Floor2 | Floor3 | Floor4 | Floor5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Normal |5|9|28|46|72|
| Shooter |4|7|21|34|52|
| Brute |12|23|62|102|156|
| Boss |66|121|330|560|900|

Floor5 loot guardian:230HP. Patterns, warnings, one-damage enemy hits and open
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
plus Explosive for bow/crossbow or Perpetuum for wand. Late profile:6 damage,
4 speed,3 extra,3 burst, plus that weapon modifier. For wand beam/meteor variants,
replace Perpetuum with the named form. Melee/chakram use shared ranks without a
weapon-specific card. These are explicit fixtures, not promises about exact drop
or card counts on any floor.

| Weapon/form | Profile | DPS | Floor5 boss HP/DPS estimate |
| --- | --- | ---: | ---: |
| bow | mid | 8.42 | 106.9s |
| bow | late | 25.59 | 35.2s |
| crossbow | mid | 10.60 | 84.9s |
| crossbow | late | 32.65 | 27.6s |
| wand | mid | 8.50 | 105.8s |
| wand | late | 30.39 | 29.6s |
| sword | mid | 13.93 | 64.6s |
| sword | late | 49.40 | 18.2s |
| hammer | mid | 7.25 | 124.1s |
| hammer | late | 21.30 | 42.3s |
| chakram | mid | 8.63 | 104.3s |
| chakram | late | 29.97 | 30.0s |
| wand_beam | late | 30.90 | 29.1s |
| wand_meteor | late | 31.08 | 29.0s |

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
  six-weapon profiles must improve on baseline while staying under15× baseline.
- Measure live room/boss times on mobile too. A test passing does not establish
  whether movement, enemy pressure, rewards or a new perk feels fair.
