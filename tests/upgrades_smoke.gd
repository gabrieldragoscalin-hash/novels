extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const Progression = preload("res://scripts/progression.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Gear = preload("res://scripts/equipment.gd")
const BOUNDS := Rect2(32,174,416,422)
const PLAYER := Vector2(240,530)
func _initialize() -> void: call_deferred("run")
func encounter(weapon: String = "bow", positions: Array = [Vector2(240,330)], pillars: Array[Rect2] = []):
	var c = Combat.new(BOUNDS,pillars)
	var enemies: Array = []
	for pos in positions:
		var enemy := Dungeon.make_enemy(pos,"normal",1)
		enemy["hp"] = 100.0; enemy["max_hp"] = 100.0; enemies.append(enemy)
	c.enter({"enemies":enemies,"pickups":[],"role":"combat"},PLAYER)
	var stats := Gear.stats(weapon,1); stats["weapon"] = weapon; stats["level"] = 1
	c.progression.apply_loadout(stats); c.progression.base_critical = 0; c.fire_time = 0
	return c
func run() -> void:
	var c = encounter()
	c.progression.ranks["multishot"] = 2
	c.arsenal._fire(PLAYER,0,false,0)
	assert(c.bullets.size()==3 and c.bullets[0]["velocity"]==c.bullets[1]["velocity"] and c.bullets[0]["pos"]!=c.bullets[1]["pos"])
	c = encounter("crossbow"); c.arsenal._fire(PLAYER,0,false,0)
	assert(c.bullets[0]["radius"]>4 and c.progression.damage()==2 and c.progression.fire_interval()>0.45)
	# Burst attacks are staggered, not an immediate spread.
	c = encounter(); c.progression.ranks["multiple_shots"] = 2
	c.arsenal.tick(0.01,PLAYER+Vector2(1,0)); assert(c.bullets.size()==1 and c.arsenal.queued.size()==2)
	c.fire_time = 999; c.arsenal.tick(0.16,PLAYER+Vector2(1,0)); assert(c.bullets.size()==2)
	# Obstacles block arrows, but wands and See All bypass them.
	var pillars: Array[Rect2] = [Rect2(220,390,40,30)]
	for weapon in ["bow","wand"]:
		c = encounter(weapon,[Vector2(240,330)],pillars)
		assert((c.arsenal.nearest(PLAYER)>=0)==(weapon=="wand"))
		c.arsenal._fire(PLAYER,0,false,0); c.arsenal._tick_bullets(0.7)
		assert((c.enemies[0]["hp"]<100)==(weapon=="wand"))
	c = encounter("bow",[Vector2(240,330)],pillars); c.progression.ranks["see_all"] = 1
	c.arsenal._fire(PLAYER,0,false,0); c.arsenal._tick_bullets(0.7); assert(c.enemies[0]["hp"]==99)
	# Ricochet targets another enemy and never reflects off walls.
	c = encounter("bow",[Vector2(240,330),Vector2(320,330)]); c.progression.ranks["ricochet"] = 1
	c.arsenal._fire(PLAYER,0,false,0); c.arsenal._tick_bullets(0.85)
	assert(c.enemies[0]["hp"]==99 and is_equal_approx(c.enemies[1]["hp"],99.15))
	c = encounter(); c.enemies.clear()
	c.bullets.append({"pos":Vector2(440,350),"velocity":Vector2(390,0),"life":1.0,"bounces":4})
	c.arsenal._tick_bullets(0.1); assert(c.bullets.is_empty())
	# Ballista penetrates multiple targets; bow split children follow after a ricochet.
	c = encounter("crossbow",[Vector2(240,330),Vector2(240,260)])
	c.give_upgrade("ballista"); c.give_upgrade("follow")
	c.arsenal._fire(PLAYER,0,false,0); c.arsenal._tick_bullets(0.8)
	assert(c.enemies[0]["hp"]<100 and c.enemies[1]["hp"]<100)
	# Explosions are direct damage plus 45% splash, ignoring ordinary pierce/ricochet.
	c = encounter("bow",[Vector2(240,330),Vector2(275,330)])
	c.progression.ranks["explosive"] = 1; c.progression.ranks["piercing"] = 3; c.progression.ranks["ricochet"] = 3
	c.arsenal._fire(PLAYER,0,false,0); c.arsenal._tick_bullets(0.7)
	assert(is_equal_approx(c.enemies[0]["hp"],98.55) and is_equal_approx(c.enemies[1]["hp"],99.55) and c.bullets.is_empty())
	c = encounter(); c.progression.ranks["explosive"] = 1
	c.arsenal._fire(PLAYER,0,true,0)
	assert(c.bullets[0]["splash"]==52 and c.bullets[0]["remaining"]>100)
	# Split children inherit Follow after the parent's last ricochet hit.
	c = encounter("bow",[Vector2(240,330),Vector2(320,330)])
	c.progression.ranks["arrow_split"] = 1; c.progression.ranks["ricochet"] = 1; c.progression.ranks["follow"] = 1
	c.arsenal._fire(PLAYER,0,false,0); c.arsenal._tick_bullets(0.85)
	assert(c.bullets.size()==3)
	for child in c.bullets: assert(child["follow"] and child["hits"].size()==2)
	# Bow naturally charges while stationary; moving fires ordinary arrows.
	c = encounter(); c.give_upgrade("deep_draw")
	c.arsenal.tick(0.5,PLAYER); assert(c.bullets.is_empty() and c.arsenal.charge==0.5)
	c.arsenal.tick(0.01,PLAYER+Vector2(1,0))
	assert(c.bullets.size()==1 and not c.bullets[0]["charged"])
	c = encounter(); c.arsenal.tick(0.61,PLAYER)
	assert(c.arsenal.release_serial>0)
	# Melee Multishot schedules consecutive strikes; Extra Projectile is ranged-only.
	c = encounter("sword",[Vector2(240,330),Vector2(270,335)])
	c.give_upgrade("multiple_shots"); c.arsenal._schedule(Vector2(240,390),0,false)
	assert(c.arsenal.queued.size()==2 and not c.progression.available_upgrades().has("multishot"))
	c.arsenal._fire(Vector2(240,390),0,false,0)
	assert(c.enemies[0]["hp"]<100 and c.enemies[1]["hp"]<100)
	# Area widens hammer's cone without changing reach.
	c = encounter("hammer"); c.arsenal._fire(Vector2(240,400),0,false,0)
	var wave: Dictionary = c.arsenal.effects[-1].duplicate()
	c.give_upgrade("area"); c.arsenal._fire(Vector2(240,400),0,false,0)
	assert(c.arsenal.effects[-1]["radius"]==wave["radius"] and c.arsenal.effects[-1]["angle"]>wave["angle"])
	# Chakram has separate outward/return contacts and a bounded repeat interval.
	c = encounter("chakram"); c.arsenal._fire(PLAYER,0,false,0)
	assert(c.bullets[0]["v2_path"] and c.bullets[0]["return_contacts"].is_empty())
	c.arsenal.behavior._tick_returning(0.5,PLAYER)
	assert(c.enemies[0]["hp"]<100)
	# Laser is continuous, ignores obstacles and has slightly greater baseline DPS.
	c = encounter("wand"); c.progression.ranks["perpetuum"] = 1
	for i in range(10): c.arsenal._laser(PLAYER,Vector2.UP,0)
	assert(100-c.enemies[0]["hp"]>(1.0+c.progression.critical_chance())/c.progression.fire_interval())
	c = encounter("wand",[Vector2(240,330),Vector2(310,330)])
	c.progression.ranks["perpetuum"] = 1; c.progression.ranks["ricochet"] = 1
	c.arsenal._laser(PLAYER,Vector2.UP,0)
	assert(c.enemies[0]["hp"]<c.enemies[1]["hp"] and c.enemies[1]["hp"]<100)
	# Meteor rank conversion, rain targets, growing AoE and rolling damage.
	c = encounter("wand",[Vector2(240,330),Vector2(310,330)])
	c.progression.ranks["meteor"] = 1; c.progression.ranks["piercing"] = 2; c.progression.ranks["ricochet"] = 1; c.progression.ranks["follow"] = 1
	assert(c.progression.upgrade_info("piercing")[0]=="Meteor Size")
	c.arsenal._fire(PLAYER,0,false,0)
	assert(c.arsenal.meteors.size()==2 and is_equal_approx(c.arsenal.meteors[0]["radius"],23.8))
	c.arsenal._tick_meteors(0.5); assert(c.arsenal.meteors.is_empty() and c.bullets.size()==2)
	assert(is_equal_approx(c.bullets[0]["damage"],0.25) and c.bullets[0]["through"])
	# Weapon-specific pools, one-time cards and replacement pairs.
	var p = Progression.new()
	assert(p.available_upgrades().has("arrow_split") and not p.available_upgrades().has("meteor"))
	p.grant_upgrade("arrow_split"); p.grant_upgrade("explosive"); assert(p.ranks["arrow_split"]==0)
	p.grant_upgrade("arrow_split"); assert(p.ranks["explosive"]==0)
	p.grant_upgrade("see_all"); assert(not p.available_upgrades().has("see_all"))
	p.ranks["see_all"] = 0; assert(not p.available_upgrades().has("see_all"),"See All never reappears even after trading it away")
	p.weapon = "wand"; assert(not p.available_upgrades().has("see_all") and not p.available_upgrades().has("arrow_split"))
	p.grant_upgrade("perpetuum"); p.grant_upgrade("meteor"); assert(p.ranks["perpetuum"]==0)
	p.grant_upgrade("perpetuum"); assert(p.ranks["meteor"]==0)
	for id in ["health","critical","frost","burn","magnet","regeneration"]: assert(not p.available_upgrades().has(id))
	print("PASS: parallel projectiles, consecutive attacks, obstacle bypass, enemy ricochet, ballista penetration, bow charge and split, bounded explosions, melee arcs, returning chakram, laser chains, meteor conversions and exclusive signatures")
	quit(0)
