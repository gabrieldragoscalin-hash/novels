extends RefCounted
## Pure encounter state, shared with room storage; no enemy respawns on re-entry.
const Progression = preload("res://scripts/progression.gd")
const ENEMY_HP := 3
const ENEMY_SPEED := 67.0
const FIRE_INTERVAL := 0.45
const BULLET_SPEED := 390.0
const MAX_HEALTH := 6
var progression = Progression.new()
var pickups: Array = []
var health := MAX_HEALTH
var hurt_time := 0.0
var grace_time := 0.0
var fire_time := 0.0
var enemies: Array = []
var bullets: Array = []
var impacts: Array = []
var kills := 0
var nav := AStarGrid2D.new()
var bounds: Rect2
var obstacles: Array[Rect2]

func _init(room_bounds: Rect2, pillars: Array[Rect2]) -> void:
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
	bullets.clear()
	impacts.clear()
	fire_time = 0.15
	grace_time = 0.7
	enemies = state["enemies"]
	if not state.has("pickups"): state["pickups"] = []
	pickups = state["pickups"]
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
	for impact in impacts: impact["life"] -= delta
	impacts = impacts.filter(func(impact): return impact["life"] > 0)
	# Target the nearest enemy with a clear shot. Moving never suppresses firing.
	var target: Dictionary = {}
	var closest := INF
	for enemy in enemies:
		if enemy["hp"] <= 0: continue
		enemy["flash"] = maxf(0, enemy["flash"] - delta)
		var distance: float = player.distance_squared_to(enemy["pos"])
		if distance < closest and not wall_between(player, enemy["pos"]):
			target = enemy
			closest = distance
	if not target.is_empty() and fire_time <= 0:
		bullets.append({"pos": player, "velocity": player.direction_to(target["pos"]) * BULLET_SPEED, "life": 1.6, "hits": [], "remaining": 1 + progression.ranks["piercing"]})
		fire_time = progression.fire_interval()
	# Small swept steps prevent projectiles skipping walls or enemies on slow frames.
	for bullet in bullets:
		if not bullet.has("hits"): bullet["hits"] = []
		if not bullet.has("remaining"): bullet["remaining"] = 1
		bullet["life"] -= delta
		var motion: Vector2 = bullet["velocity"] * delta
		var steps := maxi(1, int(ceil(motion.length() / 5.0)))
		for step in range(steps):
			var next: Vector2 = bullet["pos"] + motion / steps
			if not bounds.has_point(next) or wall_between(bullet["pos"], next):
				bullet["life"] = 0
				break
			bullet["pos"] = next
			var hit := false
			for enemy_index in range(enemies.size()):
				var enemy: Dictionary = enemies[enemy_index]
				if enemy["hp"] > 0 and not bullet["hits"].has(enemy_index) and next.distance_to(enemy["pos"]) <= 17:
					enemy["hp"] -= progression.damage()
					enemy["flash"] = 0.13
					bullet["hits"].append(enemy_index)
					bullet["remaining"] -= 1
					if bullet["remaining"] <= 0: bullet["life"] = 0
					impacts.append({"pos": next, "life": 0.22})
					if enemy["hp"] <= 0:
						kills += 1
						pickups.append({"pos": enemy["pos"], "amount": 2})
					hit = bullet["life"] <= 0
					break
			if hit: break
	bullets = bullets.filter(func(bullet): return bullet["life"] > 0)
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
		var next: Vector2 = enemy["pos"].move_toward(destination, ENEMY_SPEED * delta)
		if not blocked(next, 13): enemy["pos"] = next
		if not enemy["path"].is_empty() and enemy["pos"].distance_to(destination) < 3:
			enemy["path"].remove_at(0)
		if enemy["pos"].distance_to(player) < 26 and hurt_time <= 0 and grace_time <= 0:
			health -= 1
			hurt_time = 1.0
			if health <= 0: break

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
			progression.add_xp(amount)
			if progression.pending > 0: return

func apply_choice(index: int) -> bool:
	var choice: String = progression.choose(index)
	if choice.is_empty(): return false
	if choice == "health": health = mini(health + 2, progression.max_health())
	return true
