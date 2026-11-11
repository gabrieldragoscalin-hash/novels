extends SceneTree
const Dungeon = preload("res://scripts/dungeon.gd")
const Combat = preload("res://scripts/combat.gd")
const Hub = preload("res://scripts/hub.gd")
const Services = preload("res://scripts/services.gd")
const BOUNDS := Rect2(32,174,416,422)
const PLAYER := Vector2(240,530)
func _initialize() -> void: call_deferred("run")
func arena(kind: String,tier: int,pillars: Array[Rect2] = []):
	var c = Combat.new(BOUNDS,pillars)
	c.enter({"role":"combat","enemies":[Dungeon.make_enemy(Vector2(240,270),kind,tier)],"boss_paid":false},PLAYER)
	c.floor_number = tier; c.fire_time = 999
	return c
func run() -> void:
	assert(Dungeon.MAX_FLOOR==5)
	for floor_number in range(1,6):
		var c = arena("shooter",floor_number)
		var enemy: Dictionary = c.enemies[0]; enemy["attack"] = 0.0
		var fire_times: Array = []
		var previous := 0
		for frame in range(130):
			c._enemy_shoot(enemy,0.01,PLAYER)
			if c.hostile_bullets.size()>previous: fire_times.append(frame*0.01); previous = c.hostile_bullets.size()
		assert(fire_times[0]>=0.64,"Shooters must warn before firing")
		if floor_number<=3: assert(c.hostile_bullets.size()==floor_number)
		for i in range(1,fire_times.size()): assert(fire_times[i]-fire_times[i-1]>0.15,"Bursts must be staggered")
	# Brute charge: stationary warning, locked direction, actual movement, recovery.
	var c = arena("brute",1)
	var enemy: Dictionary = c.enemies[0]; enemy["attack"] = 0.0
	c.enemy_ai.tick(enemy,0.01,PLAYER)
	var origin: Vector2 = enemy["pos"]; var aim: Vector2 = enemy["aim"]
	assert(is_equal_approx(enemy["telegraph"],0.9))
	c.enemy_ai.tick(enemy,0.4,Vector2(400,530))
	assert(enemy["pos"]==origin and enemy["aim"]==aim)
	c.enemy_ai.tick(enemy,0.51,PLAYER); assert(enemy["phase"]=="charge")
	c.enemy_ai.tick(enemy,0.1,PLAYER); assert(enemy["pos"].distance_to(origin)>25)
	c.enemy_ai.tick(enemy,0.36,PLAYER); assert(enemy["phase"]=="recover")
	origin = enemy["pos"]; c.enemy_ai.tick(enemy,0.5,PLAYER); assert(enemy["pos"]==origin)
	# Swept charging cannot tunnel through a pillar.
	var pillars: Array[Rect2] = [Rect2(240,280,20,60)]
	c = arena("brute",5,pillars); enemy = c.enemies[0]
	enemy["pos"] = Vector2(200,310); enemy["aim"] = Vector2.RIGHT; enemy["phase"] = "charge"; enemy["phase_time"] = 0.45
	c.enemy_ai.tick(enemy,0.4,PLAYER)
	assert(enemy["pos"].x<227 and enemy["phase"]=="recover" and not c.blocked(enemy["pos"],13))
	# Floor-2 ground attack locks locations and gives time to leave.
	c = arena("boss",2); enemy = c.enemies[0]
	enemy["sequence"] = 2; enemy["attack"] = 0.0; c.grace_time = 0
	c.enemy_ai.tick(enemy,0.01,PLAYER); assert(c.hazards.size()==2)
	c._tick_hazards(0.5,PLAYER); assert(c.health==6)
	c._tick_hazards(0.41,PLAYER); assert(c.health==5)
	c.hurt_time = 0; c._tick_hazards(0.01,PLAYER); assert(c.health==5)
	# Floor-3 boss combines ground markers and spread; half HP accelerates recovery.
	c = arena("boss",3); enemy = c.enemies[0]
	enemy["sequence"] = 2; enemy["attack"] = 0.0
	c.enemy_ai.tick(enemy,0.01,PLAYER); assert(enemy["action"]=="combo" and c.hazards.size()==3)
	c.enemy_ai.tick(enemy,0.66,PLAYER); assert(c.hostile_bullets.size()==7)
	enemy["hp"] = enemy["max_hp"]*0.4; enemy["attack"] = 0.0; enemy["telegraph"] = 0.0
	c.enemy_ai.tick(enemy,0.01,PLAYER); assert(is_equal_approx(enemy["attack"],1.5))
	# Dormant reinforcements count toward room completion, cannot be hit early,
	# survive revisits, and activate exactly once after a marked warning.
	c = Combat.new(BOUNDS,[])
	var first := Dungeon.make_enemy(Vector2(240,270),"normal",1)
	var second := Dungeon.make_enemy(Vector2(192,385),"normal",1); second["dormant"] = true
	var state := {"role":"combat","enemies":[first,second],"encounter":"ambush"}
	c.enter(state,PLAYER); c._damage_enemy(second,999); assert(second["hp"]==4)
	c._damage_enemy(first,999); assert(c.alive_count()==1 and c.arsenal.nearest(PLAYER)==-1)
	c._tick_waves(0.3); assert(second["dormant"] and state["wave_timer"]>0)
	c.enter(state,PLAYER); c._tick_waves(0.61); assert(not second["dormant"])
	c._damage_enemy(second,999); c._tick_waves(10)
	assert(c.alive_count()==0 and c.kills==2 and c.progression.flares==2)
	# All five encounter variants occur; total counts and identities scale together.
	var d = Dungeon.new(9)
	var styles := {}
	for f in range(1,6):
		for room in d.rooms.values():
			if room["role"]=="combat":
				styles[room["encounter"]] = true; assert(room["enemies"].size()==f+3)
		if f<5: d.advance()
	assert(styles.size()==5)
	# Floor-5 treasure guardians gate chest access and pay bigger-enemy rewards.
	for cell in d.rooms:
		if d.rooms[cell]["role"]=="loot": d.enter(cell); break
	c = Combat.new(BOUNDS,[]); c.enter(d.rooms[d.current],PLAYER)
	var h = Hub.new(false); var services = Services.new(d,c,h); services.enter()
	assert(c.enemies.size()==1 and c.enemies[0]["kind"]=="miniboss" and not services.loot())
	c._damage_enemy(c.enemies[0],1000); assert(c.progression.flares==2 and not d.rooms[d.current]["boss_paid"])
	assert(services.loot() and c.progression.flares==22 and not services.loot())
	assert(h.claim_floor(5,"floor-five")["kind"]=="gold" and h.keys["gold"]==1)
	assert(not d.advance() and d.floor_number==5 and d.completed)
	print("PASS: five floors, encounter variants/waves, dormant protection/revisit, shooter bursts/warnings, brute charge/recovery/collision, boss patterns/enrage/ground damage, treasure guardian and gold key")
	quit(0)
