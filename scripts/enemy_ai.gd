extends RefCounted
const Dungeon = preload("res://scripts/dungeon.gd")
var combat_ref: WeakRef
var c:
	get: return combat_ref.get_ref()
func _init(combat) -> void: combat_ref = weakref(combat)

func tick(enemy: Dictionary,delta: float,player: Vector2) -> void:
	var kind: String = enemy.get("kind","normal")
	if kind == "normal": _walk(enemy,delta,player); return
	if kind == "shooter":
		shoot(enemy,delta,player)
		if enemy.get("telegraph",0.0)<=0 and enemy.get("burst_left",0)==0 and (enemy["pos"].distance_to(player)>180 or c.wall_between(enemy["pos"],player)): _walk(enemy,delta,player)
		return
	_heavy(enemy,delta,player)

func _walk(enemy: Dictionary,delta: float,player: Vector2) -> void:
	enemy["repath"] = enemy.get("repath",0.0)-delta
	if enemy["repath"]<=0:
		enemy["repath"] = 0.3
		enemy["path"] = c.nav.get_point_path(c._cell(enemy["pos"]),c._cell(player))
		if enemy["path"].size()>1: enemy["path"].remove_at(0)
	var destination := player
	if not enemy["path"].is_empty(): destination = enemy["path"][0]
	var index := clampi(int(enemy.get("tier",1))-1,0,4)
	var speed: float = Dungeon.ENEMY_SPEEDS[index]*enemy.get("speed_multiplier",1.0)
	if enemy.get("kind","") in ["brute","boss","miniboss"]: speed *= 0.65
	_move(enemy,enemy["pos"].direction_to(destination)*speed*delta)
	if not enemy["path"].is_empty() and enemy["pos"].distance_to(destination)<3: enemy["path"].remove_at(0)

func _move(enemy: Dictionary,motion: Vector2) -> bool:
	var steps := maxi(1,int(ceil(motion.length()/5)))
	for i in range(steps):
		var next: Vector2 = enemy["pos"]+motion/steps
		if c.blocked(next,13): return false
		enemy["pos"] = next
	return true

func shoot(enemy: Dictionary,delta: float,player: Vector2) -> void:
	# Retained entry point for encounter tests and the controller.
	if enemy.get("kind","") in ["boss","miniboss"]: _heavy(enemy,delta,player); return
	var index := clampi(int(enemy.get("tier",c.floor_number))-1,0,4)
	enemy["attack"] -= delta
	if enemy.get("telegraph",0.0)>0:
		enemy["telegraph"] -= delta
		if enemy["telegraph"]<=0:
			enemy["burst_left"] = [1,2,3,3,4][index]
			enemy["burst_time"] = 0.0
	if enemy.get("burst_left",0)>0:
		enemy["burst_time"] -= delta
		while enemy["burst_left"]>0 and enemy["burst_time"]<=0:
			var angles: Array = [0.0]
			if enemy["burst_left"]==1 and index>=3: angles = [-0.12,0.12] if index==3 else [-0.16,0.0,0.16]
			_volley(enemy,angles,Dungeon.SHOT_SPEEDS[index])
			enemy["burst_left"] -= 1; enemy["burst_time"] += 0.18
	if enemy["attack"]<=0 and enemy.get("telegraph",0.0)<=0 and enemy.get("burst_left",0)==0:
		if c.wall_between(enemy["pos"],player): return
		enemy["telegraph"] = 0.65
		enemy["aim"] = enemy["pos"].direction_to(player)
		enemy["action"] = "aim"
		enemy["attack"] = Dungeon.SHOT_INTERVALS[index]

func _heavy(enemy: Dictionary,delta: float,player: Vector2) -> void:
	var index := clampi(int(enemy.get("tier",1))-1,0,4)
	var phase: String = enemy.get("phase","idle")
	var boss: bool = enemy.get("kind","") in ["boss","miniboss"]
	if phase == "recover":
		enemy["phase_time"] -= delta
		if enemy["phase_time"]<=0: enemy["phase"] = "idle"
		return
	if phase == "charge":
		enemy["phase_time"] -= delta
		var motion: Vector2 = enemy["aim"]*(300.0+index*25)*delta
		if not _move(enemy,motion) or enemy["phase_time"]<=0:
			enemy["phase"] = "recover"; enemy["phase_time"] = 0.85
		return
	if enemy.get("telegraph",0.0)>0:
		enemy["telegraph"] -= delta
		if enemy["telegraph"]<=0: _release(enemy,index,player)
		return
	enemy["attack"] -= delta
	if enemy["attack"]>0:
		_walk(enemy,delta,player); return
	var action := "charge"
	if boss:
		var sequence: Array = ["spread","charge"] if index==0 else (["spread","charge","ground"] if index==1 else ["spread","charge","combo"])
		if enemy.get("kind","")=="miniboss": sequence = ["charge","spread"]
		action = sequence[int(enemy.get("sequence",0))%sequence.size()]
		enemy["sequence"] = int(enemy.get("sequence",0))+1
		if action in ["spread","combo"] and c.wall_between(enemy["pos"],player): _walk(enemy,delta,player); return
	enemy["action"] = action
	enemy["aim"] = enemy["pos"].direction_to(player)
	enemy["telegraph"] = Dungeon.CHARGE_WARNINGS[index] if action=="charge" else 0.65
	enemy["attack"] = [2.4,2.2,2.0,1.9,1.8][index] if boss else 2.3
	if boss and index>=2 and enemy["hp"]<enemy["max_hp"]*0.5: enemy["attack"] *= 0.75
	# Ground locations lock at warning start, giving a real window to dodge.
	if action in ["ground","combo"]: _ground(player,index)

func _release(enemy: Dictionary,index: int,_player: Vector2) -> void:
	match enemy["action"]:
		"charge": enemy["phase"] = "charge"; enemy["phase_time"] = 0.45
		"spread", "combo":
			var count: int = [3,5,7,7,9][index]
			if enemy.get("kind","")=="miniboss": count = 3
			var angles: Array = []
			for i in range(count): angles.append((i-(count-1)*0.5)*0.18)
			_volley(enemy,angles,Dungeon.SHOT_SPEEDS[index])
		"ground": pass

func _volley(enemy: Dictionary,angles: Array,speed: float) -> void:
	for angle in angles:
		c.hostile_bullets.append({"pos":enemy["pos"],"velocity":enemy["aim"].rotated(angle)*speed,"life":4.0})

func _ground(player: Vector2,index: int) -> void:
	var offsets := [Vector2.ZERO,Vector2(75,0),Vector2(-75,0),Vector2(0,75),Vector2(0,-75)]
	for i in range(mini(index+1,offsets.size())):
		var pos: Vector2 = player+offsets[i]
		pos = pos.clamp(c.bounds.position+Vector2(40,40),c.bounds.end-Vector2(40,40))
		c.hazards.append({"pos":pos,"radius":35.0+index*2,"warning":0.9,"life":1.15,"fired":false})
