extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const Gear = preload("res://scripts/equipment.gd")
const Catalog = preload("res://scripts/upgrade_catalog.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Hub = preload("res://scripts/hub.gd")
const PLAYER := Vector2(240,480)
func _initialize() -> void: call_deferred("run")
func arena(kind: String):
	var c = Combat.new(Rect2(8,166,464,438),[])
	var enemies: Array = []
	for pos in [Vector2(240,390),Vector2(270,390),Vector2(240,345)]:
		var enemy := Dungeon.make_enemy(pos,"normal",1); enemy["hp"] = 2000.0; enemy["max_hp"] = 2000.0; enemy["attack"] = 999.0; enemies.append(enemy)
	c.enter({"enemies":enemies,"pickups":[],"role":"combat"},PLAYER)
	var stats := Gear.stats(kind,1); stats["weapon"] = kind; stats["level"] = 1; c.progression.apply_loadout(stats); c.progression.base_critical = 0
	return c
func tick(c, seconds: float) -> void:
	for i in range(int(seconds*60)):
		c.tick(1.0/60,PLAYER)
		c.progression.pending = 0; c.progression.offers.clear()
func run() -> void:
	for kind in Catalog.RANGED+Catalog.MELEE:
		var c = arena(kind); var p = c.progression
		var pool: Array = p.available_upgrades()
		for id in pool:
			if Catalog.OWNERS.has(id): assert(Catalog.OWNERS[id]==kind)
		for id in Catalog.RANGED_ONLY: assert(pool.has(id)==(p.is_ranged() and not (id=="see_all" and kind=="wand")))
		for id in Catalog.MELEE_ONLY: assert(pool.has(id)==p.is_melee())
		for retired in ["gatherer","last_enemy","momentum","stop_aim"]: assert(not pool.has(retired))
		tick(c,3)
		var damage := 0.0
		for enemy in c.enemies: damage += 2000-enemy["hp"]
		assert(damage>0,"Weapon must deal actual damage: "+kind)
		assert(c.arsenal.release_serial>0)
		var hub = Hub.new(false); var uid: String = hub.find_equipment(kind); assert(hub.equip_item(uid) and hub.item_type(hub.equipped["weapon"])==kind)
	# Every exclusive signature is exercised against real enemies, not just offered.
	for pair in Catalog.PAIRS:
		for id in pair:
			var kind: String = Catalog.OWNERS[id]
			var c = arena(kind); c.give_upgrade(id); assert(c.progression.ranks[id]==1)
			tick(c,3)
			assert(c.enemies.any(func(e): return e["hp"]<2000),"Signature must remain a functional attack: "+id)
			c.give_upgrade(Catalog.opposite(id)); assert(c.progression.ranks[id]==0 and c.progression.ranks[Catalog.opposite(id)]==1)
	# All support cards can be granted and remain functional together on their owner.
	for kind in Catalog.RANGED+Catalog.MELEE:
		var support = arena(kind)
		for id in Catalog.OWNERS:
			if Catalog.OWNERS[id]==kind and not Catalog.signature(id): support.give_upgrade(id)
		tick(support,4)
		assert(support.enemies.any(func(e): return e["hp"]<2000))
	# Ricochet and Follow select an unhit target on returning throws too.
	var chain = arena("spear")
	chain.enemies[1]["pos"] = Vector2(320,390)
	chain.give_upgrade("ricochet"); chain.give_upgrade("follow")
	chain.arsenal._fire(PLAYER,0,false,0)
	for frame in range(45): chain.arsenal.behavior._tick_returning(1.0/60,PLAYER)
	assert(chain.enemies[0]["hp"]<2000 and (chain.enemies[1]["hp"]<2000 or chain.enemies[2]["hp"]<2000))
	# Full healing, once-per-room barrier, once-only revive, and bounded attack lifesteal.
	var c = arena("bow"); c.health = 1; c.progression.current_health = 1; c.give_upgrade("medicine"); assert(c.health==c.progression.max_health())
	c.give_upgrade("barrier"); c.grace_time = 0; c.hurt(1); assert(c.health==c.progression.max_health() and not c.barrier_ready)
	c.health = 1; c.give_upgrade("lifesteal"); c.arsenal.behavior.hit(c.enemies[0],100,1); var healed: float = c.health-1
	for i in range(20): c.arsenal.behavior.hit(c.enemies[1],100,i+2)
	assert(c.health-1<=c.progression.max_health()*0.04+0.001 and healed>0)
	c = arena("dual_axe"); c.give_upgrade("hard_slam"); c.arsenal._schedule(PLAYER,0,false); tick(c,0.1)
	assert(c.arsenal.behavior.ledgers.size()>0)
	c = arena("hammer"); c.give_upgrade("jump_attack"); c.arsenal.behavior.jump_left = 0; tick(c,0.1); assert(not c.arsenal.jump_request.is_empty())
	c = arena("club"); c.enemies[0]["kind"] = "boss"; c.give_upgrade("heavy_timber"); c.give_upgrade("titans_grip"); tick(c,1)
	assert(c.enemies[0].get("stun_left",0)==0,"Bosses must resist displacement and stagger locks")
	c = arena("crossbow"); c.progression.ranks["magazine"] = 1; tick(c,3); assert(c.arsenal.behavior.reload_total>0)
	c = arena("chakram"); c.give_upgrade("orbiting_blades"); tick(c,0.3); assert(c.bullets[0]["phase"]=="orbit")
	# Multishot cannot multiply persistent fissures/collision damage per victim.
	c = arena("hammer"); c.give_upgrade("fissure")
	for i in range(3): c.give_upgrade("multiple_shots")
	for i in range(4): c.arsenal.behavior.melee(PLAYER,Vector2.UP,90)
	assert(c.arsenal.behavior.patches.size()==3,"One fissure path per cycle")
	c = arena("club"); c.give_upgrade("bowling_blow")
	var body: Dictionary = c.enemies[0]; body["pos"] = Vector2(200,390)
	c.enemies[1]["pos"] = Vector2(240,390)
	c.arsenal.behavior.displace(body,Vector2(40,0),91)
	var hp: float = c.enemies[1]["hp"]
	body["pos"] = Vector2(200,390); c.arsenal.behavior.displace(body,Vector2(40,0),91)
	assert(c.enemies[1]["hp"]==hp,"One collision payout per victim/cycle")
	# Attack cycles that miss every target must not leak combo/echo metadata.
	c = arena("wand")
	for i in range(1000): c.arsenal.behavior.begin_cycle(i)
	assert(c.arsenal.behavior.cycle_data.size()<=97)
	print("PASS: nine weapons, scoped pools, all 18 signatures, preserved equipment, full heal, room barrier, bounded lifesteal, melee specials, boss immunity, magazines and orbiting discs")
	quit()
