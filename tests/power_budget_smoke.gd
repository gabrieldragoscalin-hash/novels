extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Gear = preload("res://scripts/equipment.gd")
const BOUNDS := Rect2(8,166,464,438)
func _initialize() -> void: call_deferred("run")
func make_arena(weapon: String):
	var c = Combat.new(BOUNDS,[])
	var enemy := Dungeon.make_enemy(Vector2(240,330),"boss",5)
	enemy["hp"] = 1000000.0; enemy["max_hp"] = 1000000.0
	c.enter({"role":"boss","boss_paid":false,"enemies":[enemy]},Vector2(240,530))
	var stats := Gear.stats(weapon,1); stats["weapon"] = weapon; stats["level"] = 1
	c.progression.apply_loadout(stats); c.progression.base_critical = 0
	c.fire_time = 0
	return c
func configure(c,stage: int) -> void:
	if stage==0: return
	c.progression.ranks["damage"] = 3 if stage==1 else 6
	c.progression.ranks["attack_speed"] = 2 if stage==1 else 4
	c.progression.ranks["multishot"] = 2 if stage==1 else 3
	c.progression.ranks["multiple_shots"] = 0 if stage==1 else 3
	if c.progression.weapon in ["bow","crossbow"]: c.progression.ranks["explosive"] = 1
	if c.progression.weapon=="wand": c.progression.ranks["perpetuum"] = 1
func measure(c) -> float:
	var player := Vector2(240,400) if c.progression.weapon in ["sword","hammer"] else Vector2(240,530)
	c.arsenal.reset(player)
	for frame in range(1200):
		c.fire_time -= 1.0/60
		c.arsenal.tick(1.0/60,player)
	return (1000000.0-c.enemies[0]["hp"])/20.0
func run() -> void:
	var report := []
	for weapon in Gear.ITEMS:
		if Gear.ITEMS[weapon]["slot"]!="weapon": continue
		var baseline := measure(make_arena(weapon))
		for stage in range(1,3):
			var c = make_arena(weapon); configure(c,stage)
			var dps := measure(c)
			assert(dps>baseline and dps<baseline*15,"Shared run multipliers must remain bounded")
			report.append({"weapon":weapon,"build":"mid" if stage==1 else "late","dps":snappedf(dps,0.01),"floor3_boss_seconds_stationary":snappedf(330/dps,0.1),"floor5_boss_seconds_stationary":snappedf(900/dps,0.1)})
	for form in ["beam","meteor"]:
		var wand = make_arena("wand"); configure(wand,2)
		wand.progression.ranks["perpetuum"] = 0
		if form=="meteor": wand.progression.ranks["meteor"] = 1
		var output := measure(wand)
		assert(output>0 and output<70)
		report.append({"weapon":"wand_"+form,"build":"late","dps":snappedf(output,0.01),"floor5_boss_seconds_stationary":snappedf(900/output,0.1)})
	# Rain/parallel meteors cannot multiply damage by overlapping the same victim.
	var meteors = make_arena("wand")
	for i in range(6): meteors.arsenal.meteors.append({"pos":Vector2(240,330),"radius":50.0,"damage":10.0,"delay":0.01,"roll":false,"cycle":10})
	meteors.arsenal._tick_meteors(0.1)
	assert(is_equal_approx(1000000.0-meteors.enemies[0]["hp"],10.0))
	# Actual three-projectile explosive volley cannot one-shot floor-3 normals.
	var c = make_arena("bow"); configure(c,1)
	c.arsenal._fire(Vector2(240,530),0,false,0); c.arsenal._tick_bullets(0.7)
	var damage: float = 1000000.0-c.enemies[0]["hp"]
	assert(damage<5 and damage<Dungeon.NORMAL_HP[2])
	# Multiple overlapping explosions in a cycle pay one splash hit, not N hits.
	var hp: float = c.enemies[0]["hp"]
	for i in range(20): c.arsenal._explode(Vector2(240,330),52,10,99)
	assert(is_equal_approx(hp-c.enemies[0]["hp"],10))
	# A distinct attack cycle may hit again.
	c.arsenal._explode(Vector2(240,330),52,10,100)
	assert(is_equal_approx(hp-c.enemies[0]["hp"],20))
	# Stop/Aim tapping cannot bypass the normal firing cooldown.
	c = make_arena("bow"); c.progression.ranks["stop_aim"] = 1
	for i in range(20):
		c.arsenal.charge = 0.01; c.fire_time = 1.0
		c.arsenal.tick(0.01,Vector2(240+i,530))
	assert(c.bullets.is_empty() and c.arsenal.queued.is_empty())
	# Long runs retain only a bounded amount of damage-ledger history.
	for i in range(1000):
		var key: int = c.arsenal._next_cycle(); c.arsenal.splash_hits[key] = [0]
	assert(c.arsenal.splash_hits.size()<=130)
	c.progression.base_interval = 0.001
	c.progression.ranks["attack_speed"] = 8
	assert(c.progression.fire_interval()>=0.08)
	assert(Dungeon.NORMAL_HP[1]<Dungeon.NORMAL_HP[2]*0.4)
	print("POWER_BENCHMARK "+JSON.stringify(report))
	print("PASS: actual 6-weapon DPS scenarios, reported explosive build, splash dedup, distinct cycles, charge cooldown and bounded ledgers")
	quit(0)
