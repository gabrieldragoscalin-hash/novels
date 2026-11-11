extends RefCounted
## Shared tuning contract: equipment supplies base damage; run bonuses are bounded.
const MIN_INTERVAL := 0.08
const DAMAGE_PER_RANK := 0.15
const HASTE_PER_RANK := 0.12
const EXTRA_OUTPUT := 0.35
const BURST_OUTPUT := 0.30
const SPLASH_RATIO := 0.45
const SPLASH_RADIUS := 52.0
const SPLIT_RATIO := 0.45
const RICOCHET_RETENTION := 0.85
const MIN_CHARGE := 0.35
const NORMAL_HP := [5,9,28,46,72,95,120,150,185,225]
const SHOOTER_HP := [4,7,21,34,52,68,86,108,134,162]
const BRUTE_HP := [10.2,19.55,52.7,86.7,132.6,176.8,224.4,280.5,348.5,425.0]
const BOSS_HP := [52.8,96.8,264.0,448.0,720.0,900.0,1120.0,1380.0,1680.0,2000.0]
const GUARDIAN_HP := 184.0
