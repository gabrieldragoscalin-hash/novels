extends RefCounted
## Attack scheduling/projectile simulation. Enemy rewards still belong to Combat.
const Balance = preload("res://scripts/combat_balance.gd")
var release_serial := 0
var pose_time := 0.0
var pose_direction := Vector2.DOWN
var pose_reverse := false
var cycle := 0
var splash_hits: Dictionary = {}
var rolling_hits: Dictionary = {}
var combat_ref: WeakRef
var c:
	get: return combat_ref.get_ref()
var queued: Array = []
var last_player := Vector2.ZERO
var charge := 0.0
var effects: Array = []
var meteors: Array = []
var spawned: Array = []

func _init(combat) -> void: combat_ref = weakref(combat)

func reset(player: Vector2) -> void:
	pose_time = 0.0; release_serial = 0
	queued.clear(); effects.clear(); meteors.clear(); splash_hits.clear(); rolling_hits.clear(); cycle = 0; charge = 0; last_player = player

func nearest(origin: Vector2, excluded: Array = [], clear: bool = true) -> int:
	var best := -1
	var distance := INF
	for i in range(c.enemies.size()):
		var enemy: Dictionary = c.enemies[i]
		if enemy["hp"] <= 0 or enemy.get("dormant",false) or excluded.has(i): continue
		if clear and not c.progression.through_obstacles() and c.wall_between(origin,enemy["pos"]): continue
		var d: float = origin.distance_squared_to(enemy["pos"])
		if d < distance: distance = d; best = i
	return best

func tick(delta: float, player: Vector2) -> void:
	pose_time = maxf(0,pose_time-delta)
	var p = c.progression
	for effect in effects: effect["life"] -= delta
	effects = effects.filter(func(e): return e["life"] > 0)
	var moving := player.distance_squared_to(last_player) > 0.001
	last_player = player
	var target := nearest(player)
	var charging: bool = p.weapon in ["bow","crossbow"] and p.ranks["stop_aim"] > 0
	if charging and not moving and target >= 0:
		if c.fire_time<=0: charge += delta
		if charge >= 3.0:
			_schedule(player,target,true); charge = 0; c.fire_time = p.fire_interval()
	elif charging and charge > 0:
		if target >= 0 and c.fire_time<=0:
			_schedule(player,target,charge>=Balance.MIN_CHARGE); c.fire_time = p.fire_interval()
		charge = 0
	elif target >= 0 and c.fire_time <= 0:
		_schedule(player,target,false)
		c.fire_time = 0.1 if p.weapon=="wand" and p.ranks["perpetuum"]>0 else p.fire_interval()
	for attack in queued.duplicate():
		attack["delay"] -= delta
		if attack["delay"] <= 0:
			queued.erase(attack)
			var aim := nearest(player)
			if aim >= 0: _fire(player,aim,attack["charged"],attack["slash"],attack["cycle"])
	_tick_meteors(delta)
	_tick_bullets(delta)

func _schedule(_player: Vector2, _target: int, charged: bool) -> void:
	var p = c.progression
	var attack_cycle := _next_cycle()
	var salvos: int = 1+p.ranks["multiple_shots"]
	var interval: float = 0.1 if p.weapon=="wand" and p.ranks["perpetuum"]>0 else p.fire_interval()
	var slashes: int = 1+p.ranks["multishot"] if p.weapon == "sword" else 1
	for salvo in range(salvos):
		for slash in range(slashes):
			queued.append({"delay":interval*(float(salvo)/salvos+float(slash)/(slashes*salvos)),"charged":charged,"slash":slash,"cycle":attack_cycle})

func _fire(player: Vector2, target: int, charged: bool, slash: int, attack_cycle: int = -1) -> void:
	if attack_cycle<0: attack_cycle = _next_cycle()
	var p = c.progression
	var direction: Vector2 = player.direction_to(c.enemies[target]["pos"])
	if direction == Vector2.ZERO: direction = Vector2.UP
	release_serial += 1
	pose_time = 0.24
	pose_direction = direction
	pose_reverse = slash%2==1
	var count: int = 1+p.ranks["multishot"]
	if p.weapon in ["sword","hammer"]:
		_melee(player,direction,slash); return
	if p.weapon == "wand" and p.ranks["meteor"] > 0:
		var targets: Array = []
		for i in range(1+p.ranks["ricochet"]):
			var next := nearest(player,targets,false)
			if next < 0: break
			targets.append(next)
			for extra in range(count):
				meteors.append({"pos":c.enemies[next]["pos"]+direction.orthogonal()*(extra-(count-1)*0.5)*14,"delay":0.45/(1.0+0.1*p.ranks["reach"]),"radius":(27.0 if c.enemies[next].get("kind","")=="boss" else 17.0)*(1.0+p.ranks["piercing"]*0.2),"damage":p.roll_damage()*p.cycle_output(),"cycle":attack_cycle,"roll":p.ranks["follow"]>0})
		return
	for shot in range(count):
		var origin: Vector2 = player+direction.orthogonal()*(shot-(count-1)*0.5)*12
		if p.weapon == "wand" and p.ranks["perpetuum"] > 0:
			_laser(origin,direction,target); continue
		var critical: bool = p.rng.randf() < p.critical_chance()
		var bullet := {"pos":origin,"velocity":direction*p.shot_speed(),"damage":float(p.damage()*p.delivery_factor()*(p.critical_multiplier() if critical else 1.0)*(2 if charged else 1)),"critical":critical,"life":2.0,"hits":[],"remaining":999 if charged else 1+p.base_pierce+p.ranks["piercing"],"bounces":0 if charged else p.ranks["ricochet"]+(3 if p.weapon=="chakram" else 0),"charged":charged,"follow":p.ranks["follow"]>0 and not charged,"through":p.through_obstacles(),"kind":p.weapon,"radius":8.0 if p.weapon=="crossbow" else 4.0,"split":p.ranks["arrow_split"]>0,"explosive":p.ranks["explosive"]>0,"cycle":attack_cycle,"splash_damage":p.damage()*(p.critical_multiplier() if critical else 1.0)*(2 if charged else 1)*Balance.SPLASH_RATIO,"splash":Balance.SPLASH_RADIUS*(2 if p.ranks["stop_aim"]>0 else 1)}
		bullet["art_launch"] = origin
		bullet["art_distance"] = maxf(45,player.distance_to(c.enemies[target]["pos"]))
		bullet["art_from_player"] = true
		if charged: bullet["radius"] *= 1.8
		c.bullets.append(bullet)

func _melee(origin: Vector2, direction: Vector2, slash: int) -> void:
	var p = c.progression
	var hammer: bool = p.weapon == "hammer"
	var radius: float = (125.0 if hammer else 88.0)*(1.0+p.ranks["reach"]*0.05)
	var angle := minf(1.4,0.45+p.ranks["multishot"]*0.14) if hammer else 1.1
	effects.append({"kind":"wave" if hammer else "slash","pos":origin,"direction":direction,"radius":radius,"angle":angle,"reverse":slash%2==1,"life":0.24,"duration":0.24})
	for enemy in c.enemies:
		if enemy["hp"] <= 0 or enemy.get("dormant",false): continue
		var offset: Vector2 = enemy["pos"]-origin
		if offset.length() > radius+12 or absf(direction.angle_to(offset)) > angle: continue
		if not p.through_obstacles() and c.wall_between(origin,enemy["pos"]): continue
		c._damage_enemy(enemy,p.roll_damage()*p.delivery_factor())

func _laser(origin: Vector2, direction: Vector2, target: int) -> void:
	var p = c.progression
	var amount: float = p.damage()*p.delivery_factor()*0.1/p.fire_interval()*1.1*(1.0+p.critical_chance()*(p.critical_multiplier()-1.0))
	var distance := 900.0
	if absf(direction.x)>0.0001: distance = minf(distance,((c.bounds.end.x if direction.x>0 else c.bounds.position.x)-origin.x)/direction.x)
	if absf(direction.y)>0.0001: distance = minf(distance,((c.bounds.end.y if direction.y>0 else c.bounds.position.y)-origin.y)/direction.y)
	var end: Vector2 = origin+direction*distance
	var hits: Array = []
	var limit: int = 1+p.base_pierce+p.ranks["piercing"]
	# Straight penetration chooses enemies in ray order.
	var line: Array = []
	for i in range(c.enemies.size()):
		if c.enemies[i]["hp"] <= 0 or c.enemies[i].get("dormant",false): continue
		var offset: Vector2 = c.enemies[i]["pos"]-origin
		if offset.dot(direction) >= 0 and absf(offset.cross(direction)) < (27 if c.enemies[i].get("kind","")=="boss" else 17)*(1.0+0.05*p.ranks["reach"]): line.append(i)
	line.sort_custom(func(a,b): return origin.distance_squared_to(c.enemies[a]["pos"]) < origin.distance_squared_to(c.enemies[b]["pos"]))
	for i in line.slice(0,limit):
		if not hits.is_empty() and (p.ranks["follow"]>0 or p.ranks["ricochet"]>0): amount *= 0.75
		c._damage_enemy(c.enemies[i],amount); hits.append(i)
	var from := origin
	var chain: bool = p.ranks["ricochet"]>0 or p.ranks["follow"]>0
	if chain:
		# Follow steers the primary ray and subsequent penetration to new targets.
		if hits.is_empty(): c._damage_enemy(c.enemies[target],amount); hits.append(target)
		for index in range(hits.size()):
			var point: Vector2 = c.enemies[hits[index]]["pos"]
			_beam(from,point); from = point
		var remaining: int = p.ranks["ricochet"]+(maxi(0,limit-hits.size()) if p.ranks["follow"]>0 else 0)
		for i in range(remaining):
			var next := nearest(from,hits,false)
			if next < 0: break
			hits.append(next); amount *= 0.75
			var point: Vector2 = c.enemies[next]["pos"]
			c._damage_enemy(c.enemies[next],amount); _beam(from,point); from = point
	else: _beam(origin,end)

func _beam(a: Vector2,b: Vector2) -> void:
	effects.append({"kind":"laser","pos":a,"end":b,"life":0.13,"duration":0.13})

func _tick_meteors(delta: float) -> void:
	for meteor in meteors:
		meteor["delay"] -= delta
		if meteor["delay"] > 0: continue
		_explode(meteor["pos"],meteor["radius"],meteor["damage"],meteor.get("cycle",-1))
		if meteor["roll"]:
			var excluded: Array = []
			for i in range(c.enemies.size()):
				if c.enemies[i]["pos"].distance_to(meteor["pos"]) < 1: excluded.append(i)
			var next := nearest(meteor["pos"],excluded,false)
			if next >= 0:
				c.bullets.append({"pos":meteor["pos"],"velocity":meteor["pos"].direction_to(c.enemies[next]["pos"])*(180*(1.0+0.1*c.progression.ranks["reach"])),"damage":meteor["damage"]*0.25,"radius":meteor["radius"],"life":6.0,"remaining":999,"hits":[],"through":true,"kind":"rolling_meteor","cycle":meteor.get("cycle",-1)})
	meteors = meteors.filter(func(m): return m["delay"]>0)

func _explode(pos: Vector2,radius: float,damage: float, attack_cycle: int = -1) -> void:
	effects.append({"kind":"explosion","pos":pos,"radius":radius,"life":0.3,"duration":0.3})
	for enemy in c.enemies:
		if enemy["hp"] > 0 and not enemy.get("dormant",false) and pos.distance_to(enemy["pos"]) <= radius+12:
			var index: int = c.enemies.find(enemy)
			if attack_cycle>=0:
				if not splash_hits.has(attack_cycle): splash_hits[attack_cycle] = []
				if splash_hits[attack_cycle].has(index): continue
				splash_hits[attack_cycle].append(index)
			c._damage_enemy(enemy,damage)

func _finish(bullet: Dictionary) -> void:
	bullet["life"] = 0
	if bullet.get("split",false) and not bullet.get("hits",[]).is_empty():
		bullet["split"] = false
		var forward: Vector2 = bullet["velocity"].normalized()
		for angle in [-PI/2,0.0,PI/2]:
			var child: Dictionary = bullet.duplicate(true)
			child["velocity"] = forward.rotated(angle)*c.progression.shot_speed()
			child["art_from_player"] = false
			child["damage"] *= Balance.SPLIT_RATIO
			child["life"] = 2.0; child["remaining"] = 999 if child.get("charged",false) else 1; child["bounces"] = 0
			# Children retain exclusions so they do not re-hit their source enemy.
			spawned.append(child)

func _tick_bullets(delta: float) -> void:
	for bullet in c.bullets:
		if not bullet.has("hits"): bullet["hits"] = []
		if not bullet.has("remaining"): bullet["remaining"] = 1
		bullet["life"] -= delta
		if bullet["life"] <= 0: _finish(bullet); continue
		if bullet.get("follow",false):
			var target := nearest(bullet["pos"],bullet["hits"],not bullet.get("through",false))
			if target >= 0:
				var speed: float = bullet["velocity"].length()
				bullet["velocity"] = bullet["velocity"].lerp(bullet["pos"].direction_to(c.enemies[target]["pos"])*speed,minf(1,delta*9)).normalized()*speed
		var steps := maxi(1,int(ceil(bullet["velocity"].length()*delta/5.0)))
		for step in range(steps):
			var next: Vector2 = bullet["pos"]+bullet["velocity"]*delta/steps
			var wall: bool = not bullet.get("through",false) and c.wall_between(bullet["pos"],next)
			if not c.bounds.has_point(next) or wall:
				if bullet.get("explosive",false): _explode(bullet["pos"],bullet["splash"],bullet.get("splash_damage",bullet["damage"]*Balance.SPLASH_RATIO),bullet.get("cycle",-1))
				_finish(bullet); break
			bullet["pos"] = next
			for index in range(c.enemies.size()):
				var enemy: Dictionary = c.enemies[index]
				if enemy["hp"]<=0 or enemy.get("dormant",false) or bullet["hits"].has(index): continue
				if next.distance_to(enemy["pos"]) > (23 if enemy.get("kind","")=="boss" else 13)+bullet.get("radius",4.0): continue
				if bullet.get("kind","")=="rolling_meteor":
					var key: int = bullet.get("cycle",-1)
					if not rolling_hits.has(key): rolling_hits[key] = []
					if rolling_hits[key].has(index): bullet["hits"].append(index); continue
					rolling_hits[key].append(index)
				c._damage_enemy(enemy,bullet.get("damage",c.progression.damage()))
				bullet["hits"].append(index)
				c.impacts.append({"pos":next,"life":0.22})
				if bullet.get("explosive",false):
					_explode(next,bullet["splash"],bullet.get("splash_damage",bullet["damage"]*Balance.SPLASH_RATIO),bullet.get("cycle",-1))
					if not bullet.get("charged",false): _finish(bullet); break
				bullet["remaining"] -= 1
				if bullet.get("split",false) and bullet["remaining"]>0 and not _enemy_ahead(bullet):
					if bullet.get("bounces",0)>0: bullet["remaining"] = 0
					else: _finish(bullet)
				if bullet["remaining"] <= 0:
					var next_target := nearest(next,bullet["hits"],not bullet.get("through",false))
					if bullet.get("bounces",0)>0 and next_target>=0:
						bullet["bounces"] -= 1; bullet["remaining"] = 1
						bullet["damage"] *= 0.75 if bullet.get("kind","")=="chakram" else Balance.RICOCHET_RETENTION
						bullet["velocity"] = next.direction_to(c.enemies[next_target]["pos"])*bullet["velocity"].length()
					else: _finish(bullet)
				break
			if bullet["life"] <= 0: break
	c.bullets = c.bullets.filter(func(b): return b["life"]>0)
	c.bullets.append_array(spawned); spawned.clear()

func _enemy_ahead(bullet: Dictionary) -> bool:
	var direction: Vector2 = bullet["velocity"].normalized()
	for i in range(c.enemies.size()):
		if c.enemies[i]["hp"]<=0 or c.enemies[i].get("dormant",false) or bullet["hits"].has(i): continue
		var offset: Vector2 = c.enemies[i]["pos"]-bullet["pos"]
		if offset.dot(direction)<=0 or absf(offset.cross(direction))>bullet.get("radius",4.0)+17: continue
		if not bullet.get("through",false) and c.wall_between(bullet["pos"],c.enemies[i]["pos"]): continue
		return true
	return false

func _next_cycle() -> int:
	cycle += 1
	# More than a projectile's lifetime, bounded across arbitrarily long runs.
	for ledger in [splash_hits,rolling_hits]:
		for key in ledger.keys():
			if key<cycle-128: ledger.erase(key)
	return cycle
