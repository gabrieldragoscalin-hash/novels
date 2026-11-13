extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Services = preload("res://scripts/services.gd")
const Progression = preload("res://scripts/progression.gd")
const BOUNDS := Rect2(8,166,464,438)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var h = Hub.new(false)
	assert(h.perks.size()==12 and not h.perks.has("second_chance"))
	var c = Combat.new(BOUNDS,[])
	c.progression.wallet = h
	c.progression.perk_ranks = {"scavenger":25,"loot_gold":25,"recovery":25,"collector":25,"trap_resist":20,"resourceful":20,"elite_hunter":20}
	c.progression.award_coins(20); c.progression.award_coins(20,true); assert(h.coins==55)
	c.health = 1; c.heal(2); assert(c.health==3.5)
	assert(c.progression.pickup_radius()==165)
	c.health = 6; c.grace_time = 0; c.hurt_time = 0; c.progression.damage_reduction = 0.2
	c.hurt(1,true); assert(is_equal_approx(c.health,5.36))
	var d = Dungeon.new(9)
	for cell in d.rooms:
		if d.rooms[cell]["service"]=="shop": d.enter(cell); break
	c.enter(d.rooms[d.current],Vector2(240,530))
	var services = Services.new(d,c,h); services.enter()
	assert(services.price("armor_item")==135 and services.price("upgrade")==18)
	h.coins = 1000; assert(services.buy("armor_item")=="Purchased." and h.coins==865)
	# Vitality heals its exact max-health gain; Full Heal restores all missing HP.
	c = Combat.new(BOUNDS,[]); c.health = 3
	c.give_upgrade("vitality"); assert(is_equal_approx(c.progression.max_health(),6.6) and is_equal_approx(c.health,3.6))
	c.progression.current_health = c.health
	assert(c.progression.available_upgrades().has("medicine"))
	c.give_upgrade("medicine"); assert(is_equal_approx(c.health,6.6))
	c.heal(100); assert(not c.progression.available_upgrades().has("medicine"))
	c.give_upgrade("reach"); assert(c.progression.shot_speed()>c.progression.projectile_speed)
	# Second Chance is rare, immediate, exact 25%, never offered/traded a second time.
	c.give_upgrade("second_chance"); c.health = 0.1; c.hurt_time = 0; c.grace_time = 0
	c.hurt(100); assert(c.progression.revive_used and is_equal_approx(c.health,c.progression.max_health()*0.25))
	assert(not c.progression.available_upgrades().has("second_chance"))
	c.hurt_time = 0; c.grace_time = 0; c.hurt(100); assert(c.health==0)
	c.progression.ranks["second_chance"] = 0
	assert(not c.progression.available_upgrades().has("second_chance"))
	var p = Progression.new(); p.rng.seed = 444
	assert(p.weight("second_chance")<p.weight("explosive") and p.weight("explosive")<p.weight("damage"))
	var revives := 0
	for i in range(2000):
		p.reward_choices()
		assert(p.offers.size()==3 and p.offers[0]!=p.offers[1] and p.offers[2]=="coins")
		if p.offers.has("second_chance"): revives += 1
	assert(revives>0 and revives<50)
	# Barrier and clear rewards cannot be farmed by re-entering the same room.
	c = Combat.new(BOUNDS,[]); c.progression.wallet = h; c.progression.ranks["barrier"] = 1
	c.progression.ranks["momentum"] = 1; c.progression.ranks["salvage"] = 1
	var enemy := Dungeon.make_enemy(Vector2(240,270),"normal",1)
	var state := {"role":"combat","enemies":[enemy]}
	c.enter(state,Vector2(240,530)); c.grace_time = 0; c.hurt(1); assert(c.health==6 and not c.barrier_ready)
	c.enter(state,Vector2(240,530)); assert(not c.barrier_ready)
	c._damage_enemy(enemy,999); c.tick(0.01,Vector2(240,530))
	var coins: int = h.coins; c.tick(0.01,Vector2(240,530)); assert(h.coins==coins )
	c.enter({"role":"empty","enemies":[]},Vector2(240,530)); assert(c.progression.momentum_active and not c.progression.momentum_pending)
	c.enter(state,Vector2(240,530)); assert(not c.progression.momentum_active)
	# Old four-perk saves keep their levels and receive eight locked entries.
	var migrated = Hub.new(false)
	migrated._load({"version":4,"perks":{"starting_upgrade":1,"starting_hp":5,"dodge":2,"boss_damage":3},"perk_purchases":11})
	assert(migrated.perks.size()==12 and migrated.perks["starting_hp"]==5 and migrated.perks["recovery"]==0)
	migrated.coins = 100000
	var unlocked: String = migrated.buy_perk()
	assert(unlocked not in ["starting_upgrade","starting_hp","dodge","boss_damage"] and migrated.perks["starting_hp"]==5)
	# Last enemy activates only when the entire encounter, including waves, has one survivor.
	c = Combat.new(BOUNDS,[]); c.progression.ranks["last_enemy"] = 2
	var one := Dungeon.make_enemy(Vector2(240,270),"normal",1)
	var two := Dungeon.make_enemy(Vector2(192,385),"normal",1)
	c.enter({"role":"combat","enemies":[one,two]},Vector2(240,530)); c.fire_time = 999
	c.tick(0.01,Vector2(240,530)); assert(c.progression.damage()==1)
	c._damage_enemy(one,999); c.tick(0.01,Vector2(240,530)); assert(is_equal_approx(c.progression.damage(),1.3))
	# Ten real floor generations, milestone guardians, safety cap, and gold reward.
	d = Dungeon.new(91)
	for floor_number in range(1,11):
		assert(d.floor_number==floor_number)
		for room in d.rooms.values():
			if room["role"]=="loot" and floor_number%5==0: assert(room["enemies"].size()==1 and room["enemies"][0]["kind"]=="miniboss")
		if floor_number<10: assert(d.advance())
	assert(not d.advance() and d.completed and d.floor_number==10)
	assert(is_equal_approx(Dungeon.BRUTE_HP[4],156*0.85) and is_equal_approx(Dungeon.BOSS_HP[4],900*0.8))
	assert(h.claim_floor(10,"floor-ten")["amount"]==2 and h.pet_slot_unlocked())
	print("PASS: 12 perks, discounts/coins/heals/pickup/trap mitigation, vitality/medicine, rare once-only revive, weighted cards, barrier/salvage/momentum farming protection, 10 floors/guardians, HP reductions and gold keys")
	quit(0)
