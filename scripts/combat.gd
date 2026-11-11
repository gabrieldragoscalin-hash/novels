extends RefCounted
var invincible := false
## Pure encounter state, shared with room storage; no enemy respawns on re-entry.
const Progression = preload("res://scripts/progression.gd")
const ENEMY_HP := 4
const ENEMY_SPEED := 75.0
const FIRE_INTERVAL := 0.45
const BULLET_SPEED := 390.0
const MAX_HEALTH := 6
var progression = Progression.new()
var arsenal
var enemy_ai
var hazards: Array = []
var pickups: Array = []
var item_drops: Array = []
var collected_items: Array = []
var health := float(MAX_HEALTH)
var barrier_time := 0.0
var barrier_ready := false
var hurt_time := 0.0
var grace_time := 0.0
var fire_time := 0.0
var enemies: Array = []
var bullets: Array = []
var impacts: Array = []
var regeneration_time := 12.0
var collected_xp_fraction := 0.0
var kills := 0
var hostile_bullets: Array = []
var room_state: Dictionary = {}
var floor_number := 1
var nav := AStarGrid2D.new()
var bounds: Rect2
var obstacles: Array[Rect2]

func _init(room_bounds: Rect2, pillars: Array[Rect2]) -> void:
	enemy_ai = preload("res://scripts/enemy_ai.gd").new(self)
	arsenal = preload("res://scripts/weapons.gd").new(self)
	bounds = room_bounds
	obstacles = pillars
	nav.region = Rect2i(0,0,maxi(1,int(ceil((bounds.size.x-32)/16))),maxi(1,int(ceil((bounds.size.y-32)/16))))
	nav.cell_size = Vector2(16, 16)
	nav.offset = bounds.position+Vector2(16,16)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in range(nav.region.size.y):
		for x in range(nav.region.size.x):
			var cell := Vector2i(x, y)
			nav.set_point_solid(cell, blocked(nav.get_point_position(cell), 15))

func enter(state: Dictionary, player: Vector2) -> void:
	arsenal.reset(player)
	bullets.clear()
	hostile_bullets.clear()
	hazards.clear()
	room_state = state
	impacts.clear()
	fire_time = 0.15
	enemies = state["enemies"]
	grace_time = 0.7
	progression.momentum_active = progression.momentum_pending
	progression.momentum_pending = false
	barrier_time = 0.0; barrier_ready = false
	if progression.ranks["barrier"]>0 and alive_count()>0 and not state.get("barrier_given",false):
		state["barrier_given"] = true; barrier_time = 4.0; barrier_ready = true
	progression.current_health = health
	enemies = state["enemies"]
	if not state.has("pickups"): state["pickups"] = []
	pickups = state["pickups"]
	if not state.has("item_drops"): state["item_drops"] = []
	item_drops = state["item_drops"]
	collected_items.clear()
	# Keep doorway arrivals safe without healing or resurrecting enemies.
	for enemy in enemies:
		if enemy["hp"] <= 0: continue
		if enemy["pos"].distance_to(player) < 90:
			var best: Vector2 = enemy["pos"]
			var score := -1.0
			for y in range(220,561,70):
				for x in range(72,409,56):
					var point := Vector2(x,y)
					if blocked(point,18) or point.distance_to(player)<110: continue
					var occupied := false
					for other in enemies:
						if other!=enemy and other["hp"]>0 and other["pos"].distance_to(point)<35: occupied = true; break
					if not occupied and point.distance_squared_to(player)>score: score = point.distance_squared_to(player); best = point

			enemy["pos"] = best
		enemy["path"] = PackedVector2Array()
		enemy["repath"] = 0.0

func blocked(point: Vector2, radius: float) -> bool:
	if not bounds.grow(-radius).has_point(point): return true
	for obstacle in obstacles:
		if obstacle.grow(radius).has_point(point): return true
	return false

func wall_between(a: Vector2, b: Vector2) -> bool:
	for obstacle in obstacles:
		var rect := obstacle.grow(3)
		if rect.has_point(a) or rect.has_point(b): return true
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in range(4):
			if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null: return true
	return false

func _cell(point: Vector2) -> Vector2i:
	var cell := Vector2i(((point - nav.offset) / 16.0).round())
	cell.x = clampi(cell.x,0,nav.region.size.x-1)
	cell.y = clampi(cell.y,0,nav.region.size.y-1)
	if nav.is_point_solid(cell):
		var nearest := INF
		var best := cell
		for y in range(maxi(0, cell.y - 3), mini(nav.region.size.y,cell.y+4)):
			for x in range(maxi(0, cell.x - 3), mini(nav.region.size.x,cell.x+4)):
				var candidate := Vector2i(x, y)
				var distance := nav.get_point_position(candidate).distance_squared_to(point)
				if not nav.is_point_solid(candidate) and distance < nearest:
					nearest = distance
					best = candidate
		cell = best
	return cell

func tick(delta: float, player: Vector2) -> void:
	if health <= 0 or progression.pending > 0: return
	barrier_time = maxf(0,barrier_time-delta)
	progression.current_health = health
	progression.last_enemy_active = alive_count()==1
	hurt_time = maxf(0, hurt_time - delta)
	grace_time = maxf(0, grace_time - delta)
	fire_time -= delta
	progression.slow_time = maxf(0, progression.slow_time - delta)
	for impact in impacts: impact["life"] -= delta
	impacts = impacts.filter(func(impact): return impact["life"] > 0)
	for enemy in enemies: enemy["flash"] = maxf(0,enemy.get("flash",0.0)-delta)
	_tick_waves(delta)
	arsenal.tick(delta,player)
	for index in range(item_drops.size()-1,-1,-1):
		if item_drops[index]["pos"].distance_to(player) < 32:
			collected_items.append(item_drops[index])
			item_drops.remove_at(index)
	_collect_xp(delta, player)
	if progression.pending > 0: return
	for enemy in enemies:
		if enemy["hp"]<=0 or enemy.get("dormant",false): continue
		enemy_ai.tick(enemy,delta,player)
		if enemy.get("phase","")!="recover" and enemy["pos"].distance_to(player)<(35 if enemy.get("kind","") in ["boss","miniboss"] else 26):
			hurt(1)
			if health<=0: break
	_tick_hazards(delta,player)
	_tick_hostile(delta, player)
	_tick_trap(delta, player)
	if room_state.get("role","")=="combat" and alive_count()==0 and not room_state.get("combat_paid",false):
		room_state["combat_paid"] = true
		progression.award_coins(3*progression.ranks["salvage"])
		if progression.ranks["momentum"]>0: progression.momentum_pending = true
	if room_state.get("role", "") == "empty" and floor_number >= 3 and alive_count() == 0 and not room_state.get("room_paid", false):
		progression.flares += floor_number + 2
		room_state["room_paid"] = true

func alive_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy["hp"] > 0: count += 1
	return count

func _collect_xp(delta: float, player: Vector2) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[i]
		var distance: float = pickup["pos"].distance_to(player)
		if distance <= progression.pickup_radius() and not wall_between(pickup["pos"], player):
			pickup["pos"] = pickup["pos"].move_toward(player, 240 * delta)
		if pickup["pos"].distance_to(player) <= 20:
			var amount: int = pickup["amount"]
			pickups.remove_at(i)
			var gained: float = amount * progression.xp_multiplier() + collected_xp_fraction
			var whole := int(floor(gained))
			collected_xp_fraction = gained - whole
			progression.add_xp(whole)
			if progression.pending > 0: return

func apply_choice(index: int) -> bool:
	var before: float = progression.max_health()
	var choice: String = progression.choose(index)
	if choice.is_empty(): return false
	apply_upgrade_effect(choice,before)
	progression.current_health = health
	if progression.pending>0: progression._roll_offers()
	return true

func heal(amount: float) -> void:
	health = minf(progression.max_health(),health+amount*progression.healing_multiplier())
	progression.current_health = health

func hurt(amount: int,trap: bool = false) -> void:
	if invincible or hurt_time>0 or grace_time>0 or health<=0: return
	if barrier_ready and barrier_time>0 and progression.ranks["barrier"]>0:
		barrier_ready = false; hurt_time = 1.0; return
	if progression.rng.randf()<progression.dodge_chance: hurt_time = 1.0; return
	health = maxf(0.0,health-amount*(1.0-progression.damage_reduction)*(1.0-0.01*progression.perk("trap_resist") if trap else 1.0))
	if health<=0 and progression.ranks["second_chance"]>0 and not progression.revive_used:
		progression.revive_used = true
		health = progression.max_health()*0.25
		grace_time = 1.5
	progression.current_health = health
	hurt_time = 1.0

func _enemy_shoot(enemy: Dictionary,delta: float,player: Vector2) -> void:
	enemy_ai.shoot(enemy,delta,player)

func _tick_hostile(delta: float, player: Vector2) -> void:
	for bullet in hostile_bullets:
		bullet["life"] -= delta
		var motion: Vector2 = bullet["velocity"] * delta
		var steps := maxi(1, int(ceil(motion.length() / 5)))
		for i in range(steps):
			var next: Vector2 = bullet["pos"] + motion / steps
			if not bounds.has_point(next) or wall_between(bullet["pos"], next):
				bullet["life"] = 0
				break
			bullet["pos"] = next
			if next.distance_to(player) < 16:
				hurt(1,bullet.get("trap",false))
				bullet["life"] = 0
				break
	hostile_bullets = hostile_bullets.filter(func(b): return b["life"] > 0)

func _tick_trap(delta: float, player: Vector2) -> void:
	if room_state.get("role", "") != "trap": return
	room_state["trap_time"] -= delta
	if room_state["trap_time"] > 0: return
	room_state["trap_time"] = 2.5
	var trap: int = room_state["trap"]
	if trap == 0:
		if player.distance_to(Vector2(240, 385)) < 100: progression.slow_time = 4
	elif trap == 1:
		if player.distance_to(Vector2(240, 385)) < 80: hurt(1,true)
	else:
		for x in [180, 240, 300]:
			hostile_bullets.append({"pos": Vector2(x, 195), "velocity": Vector2(0, 140), "life": 3.0,"trap":true})

func _damage_enemy(enemy: Dictionary, amount: float) -> void:
	if enemy["hp"] <= 0 or enemy.get("dormant",false): return
	var bonus: float = progression.boss_damage_bonus if enemy.get("kind","") in ["boss","miniboss"] else 0.0
	if enemy.get("kind","") in ["brute","miniboss"]: bonus += 0.005*progression.perk("elite_hunter")
	enemy["hp"] -= amount*(1.0+bonus)
	enemy["flash"] = 0.13
	if enemy["hp"] > 0: return
	kills += 1
	if enemy.get("kind", "normal") != "boss" and progression.rng.randf() < 0.02:
		var catalog: Array = preload("res://scripts/equipment.gd").ITEMS.keys()
		item_drops.append({"pos":enemy["pos"],"type":catalog[progression.rng.randi_range(0,catalog.size()-1)],"rarity":0})
	pickups.append({"pos": enemy["pos"], "amount": 8 if enemy.get("kind", "normal") == "boss" else (4 if enemy.get("kind","")=="miniboss" else 2)})
	if enemy.get("kind", "normal") == "boss":
		hostile_bullets.clear()
		hazards.clear()
		grace_time = maxf(grace_time, 0.5)
		if not room_state.get("boss_paid", false):
			progression.flares += 50 + 10 * (floor_number - 1)
			room_state["boss_paid"] = true
	else:
		if room_state.get("role", "") != "boss": progression.flares += 2 if enemy.get("kind", "normal") in ["brute","miniboss"] else 1

func _tick_waves(delta: float) -> void:
	var active := 0
	var dormant := 0
	for enemy in enemies:
		if enemy["hp"]<=0: continue
		if enemy.get("dormant",false): dormant += 1
		else: active += 1
	if active>0 or dormant==0: return
	if not room_state.has("wave_timer"): room_state["wave_timer"] = 0.9
	room_state["wave_timer"] -= delta
	if room_state["wave_timer"]<=0:
		for enemy in enemies:
			if enemy.get("dormant",false): enemy["dormant"] = false

func _tick_hazards(delta: float,player: Vector2) -> void:
	for hazard in hazards:
		hazard["warning"] -= delta; hazard["life"] -= delta
		if hazard["warning"]<=0 and not hazard["fired"]:
			hazard["fired"] = true
			if hazard["pos"].distance_to(player)<=hazard["radius"]: hurt(1)
	hazards = hazards.filter(func(h): return h["life"]>0)

func apply_upgrade_effect(id: String,previous_max: float) -> void:
	if id=="vitality": health = minf(progression.max_health(),health+maxf(0,progression.max_health()-previous_max))
	if id=="medicine": heal(progression.max_health()*0.15)
	progression.current_health = health

func give_upgrade(id: String) -> void:
	var before := progression.max_health()
	progression.grant_upgrade(id)
	apply_upgrade_effect(id,before)
