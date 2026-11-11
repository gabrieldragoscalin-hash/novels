extends RefCounted
var invincible := false
## Pure encounter state, shared with room storage; no enemy respawns on re-entry.
const Progression = preload("res://scripts/progression.gd")
const ENEMY_HP := 3
const ENEMY_SPEED := 67.0
const FIRE_INTERVAL := 0.45
const BULLET_SPEED := 390.0
const MAX_HEALTH := 6
var progression = Progression.new()
var arsenal
var pickups: Array = []
var item_drops: Array = []
var collected_items: Array = []
var health := MAX_HEALTH
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
	arsenal = preload("res://scripts/weapons.gd").new(self)
	bounds = room_bounds
	obstacles = pillars
	nav.region = Rect2i(0, 0, 25, 25)
	nav.cell_size = Vector2(16, 16)
	nav.offset = Vector2(48, 190)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in range(25):
		for x in range(25):
			var cell := Vector2i(x, y)
			nav.set_point_solid(cell, blocked(nav.get_point_position(cell), 15))

func enter(state: Dictionary, player: Vector2) -> void:
	arsenal.reset(player)
	bullets.clear()
	hostile_bullets.clear()
	room_state = state
	impacts.clear()
	fire_time = 0.15
	grace_time = 0.7
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
			var best := Vector2(240, 270)
			for point in [Vector2(240, 270), Vector2(192, 385), Vector2(288, 385), Vector2(240, 510)]:
				if point.distance_to(player) > best.distance_to(player): best = point
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
	cell.x = clampi(cell.x, 0, 24)
	cell.y = clampi(cell.y, 0, 24)
	if nav.is_point_solid(cell):
		var nearest := INF
		var best := cell
		for y in range(maxi(0, cell.y - 3), mini(25, cell.y + 4)):
			for x in range(maxi(0, cell.x - 3), mini(25, cell.x + 4)):
				var candidate := Vector2i(x, y)
				var distance := nav.get_point_position(candidate).distance_squared_to(point)
				if not nav.is_point_solid(candidate) and distance < nearest:
					nearest = distance
					best = candidate
		cell = best
	return cell

func tick(delta: float, player: Vector2) -> void:
	if health <= 0 or progression.pending > 0: return
	hurt_time = maxf(0, hurt_time - delta)
	grace_time = maxf(0, grace_time - delta)
	fire_time -= delta
	progression.slow_time = maxf(0, progression.slow_time - delta)
	for impact in impacts: impact["life"] -= delta
	impacts = impacts.filter(func(impact): return impact["life"] > 0)
	for enemy in enemies: enemy["flash"] = maxf(0,enemy.get("flash",0.0)-delta)
	arsenal.tick(delta,player)
	for index in range(item_drops.size()-1,-1,-1):
		if item_drops[index]["pos"].distance_to(player) < 32:
			collected_items.append(item_drops[index])
			item_drops.remove_at(index)
	_collect_xp(delta, player)
	if progression.pending > 0: return
	for enemy in enemies:
		if enemy["hp"] <= 0: continue
		enemy["repath"] -= delta
		if enemy["repath"] <= 0:
			enemy["repath"] = 0.3
			enemy["path"] = nav.get_point_path(_cell(enemy["pos"]), _cell(player))
			if enemy["path"].size() > 1: enemy["path"].remove_at(0)
		var destination := player
		if not enemy["path"].is_empty(): destination = enemy["path"][0]
		var kind: String = enemy.get("kind", "normal")
		var speed: float = ENEMY_SPEED + (enemy.get("tier", 1) - 1) * 6
		if kind == "brute": speed *= 0.65
		if kind == "boss": speed *= 0.65
		if kind == "shooter" and enemy["pos"].distance_to(player) < 160 and not wall_between(enemy["pos"], player): speed = 0
		var next: Vector2 = enemy["pos"].move_toward(destination, speed * delta)
		if not blocked(next, 13): enemy["pos"] = next
		if not enemy["path"].is_empty() and enemy["pos"].distance_to(destination) < 3:
			enemy["path"].remove_at(0)
		if enemy["pos"].distance_to(player) < (35 if kind == "boss" else 26):
			hurt(1)
			if health <= 0: break
		if kind in ["shooter", "boss"]: _enemy_shoot(enemy, delta, player)
	_tick_hostile(delta, player)
	_tick_trap(delta, player)
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
		if distance <= 110 and not wall_between(pickup["pos"], player):
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
	var choice: String = progression.choose(index)
	if choice.is_empty(): return false
	return true

func hurt(amount: int) -> void:
	if invincible or hurt_time > 0 or grace_time > 0 or health <= 0: return
	if progression.rng.randf() < progression.dodge_chance:
		hurt_time = 1.0
		return
	health = maxi(0, health - amount)
	hurt_time = 1.0

func _enemy_shoot(enemy: Dictionary, delta: float, player: Vector2) -> void:
	enemy["attack"] -= delta
	if enemy["telegraph"] > 0:
		enemy["telegraph"] -= delta
		if enemy["telegraph"] <= 0:
			var boss: bool = enemy["kind"] == "boss"
			for angle in ([-0.55, -0.28, 0.0, 0.28, 0.55] if floor_number >= 2 else [-0.38, 0.0, 0.38]) if boss else [0.0]:
				hostile_bullets.append({"pos": enemy["pos"], "velocity": enemy["aim"].rotated(angle) * (125 + floor_number * 12), "life": 4.0})
			enemy["attack"] = 1.6 if boss else 2.4
	elif enemy["attack"] <= 0:
		enemy["telegraph"] = 0.65
		enemy["aim"] = enemy["pos"].direction_to(player)

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
				hurt(1)
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
		if player.distance_to(Vector2(240, 385)) < 80: hurt(1)
	else:
		for x in [180, 240, 300]:
			hostile_bullets.append({"pos": Vector2(x, 195), "velocity": Vector2(0, 140), "life": 3.0})

func _damage_enemy(enemy: Dictionary, amount: float) -> void:
	if enemy["hp"] <= 0: return
	enemy["hp"] -= amount * (1.0 + progression.boss_damage_bonus if enemy.get("kind", "") == "boss" else 1.0)
	enemy["flash"] = 0.13
	if enemy["hp"] > 0: return
	kills += 1
	if enemy.get("kind", "normal") != "boss" and progression.rng.randf() < 0.02:
		var catalog: Array = preload("res://scripts/equipment.gd").ITEMS.keys()
		item_drops.append({"pos":enemy["pos"],"type":catalog[progression.rng.randi_range(0,catalog.size()-1)],"rarity":0})
	pickups.append({"pos": enemy["pos"], "amount": 8 if enemy.get("kind", "normal") == "boss" else 2})
	if enemy.get("kind", "normal") == "boss":
		hostile_bullets.clear()
		grace_time = maxf(grace_time, 0.5)
		if not room_state.get("boss_paid", false):
			progression.flares += 50 + 10 * (floor_number - 1)
			room_state["boss_paid"] = true
	else:
		if room_state.get("role", "") != "boss": progression.flares += 2 if enemy.get("kind", "normal") == "brute" else 1
