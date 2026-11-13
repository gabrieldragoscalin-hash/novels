extends RefCounted
## Weapon identities and bounded secondary effects. Extra attacks share a cycle ledger.
var arsenal_ref: WeakRef
var a:
	get: return arsenal_ref.get_ref()
var c:
	get: return a.c
var p:
	get: return c.progression
var time := 0.0
var magazine := 3
var reload_left := 0.0
var reload_total := 0.0
var counter := 0
var combo_hits := 0
var rhythm := 0.0
var rhythm_age := 0.0
var guard_left := 0.0
var riposte_left := 0.0
var jump_left := 5.0
var healing_second := -1
var healing_spent := 0.0
var focus_target := -1
var focus_hits := 0
var ledgers: Dictionary = {}
var cycle_data: Dictionary = {}
var patches: Array = []
var delayed: Array = []
func _init(arsenal) -> void: arsenal_ref = weakref(arsenal)
func reset() -> void:
	time = 0; magazine = 3+p.ranks["magazine"]; reload_left = 0; counter = 0; combo_hits = 0; rhythm = 0; rhythm_age = 0; guard_left = 0; riposte_left = 0; jump_left = 5; focus_target = -1; focus_hits = 0; ledgers.clear(); cycle_data.clear(); patches.clear(); delayed.clear(); healing_second = -1; healing_spent = 0
func begin_cycle(cycle: int) -> void:
	counter += 1
	cycle_data[cycle] = {"finisher":counter%(3+p.ranks["extended_combo"] if p.weapon=="sword" else 4)==0,"hand":counter%2,"riposte":riposte_left>0}
	if p.weapon=="crossbow":
		magazine -= 1
		if magazine<=0 or p.ranks["ballista"]>0 or p.ranks["repeater"]>0:
			var base := 1.5 if p.ranks["repeater"]>0 else (1.35 if p.ranks["ballista"]>0 else 0.9)
			reload_left = base/(1+0.15*p.ranks["quick_loader"])*p.fire_interval()/p.base_interval
			magazine = 3+p.ranks["magazine"]; reload_total = reload_left
	for ledger in [ledgers,cycle_data]:
		for key in ledger.keys():
			if key<cycle-96: ledger.erase(key)
func tick(delta: float, player: Vector2) -> void:
	time += delta; reload_left = maxf(0,reload_left-delta); guard_left = maxf(0,guard_left-delta); riposte_left = maxf(0,riposte_left-delta); rhythm_age += delta
	if rhythm_age>1.5: rhythm = move_toward(rhythm,0,delta*2)
	for enemy in c.enemies:
		for key in ["stun_left","slow_left","mark_left","bleed_left","tether_left","fracture_left"]: enemy[key] = maxf(0,float(enemy.get(key,0))-delta)
		if enemy.get("fracture_left",0)<=0: enemy["fracture"] = 0.0
		if enemy["hp"]>0 and enemy.get("bleed_left",0)>0: c._damage_enemy(enemy,enemy.get("bleed_dps",0)*delta)
	for patch in patches:
		patch["life"] -= delta; patch["tick"] -= delta
		if patch["tick"]<=0:
			patch["tick"] += 0.3
			for enemy in c.enemies:
				if enemy["hp"]>0 and not c.wall_between(patch["pos"],enemy["pos"]) and patch["pos"].distance_to(enemy["pos"])<patch["radius"]: hit(enemy,patch["damage"],patch["cycle"],{"secondary":true})
	patches = patches.filter(func(x): return x["life"]>0)
	for attack in delayed.duplicate():
		attack["left"] -= delta
		if attack["left"]<=0:
			delayed.erase(attack)
			melee(attack["origin"],attack["direction"],attack["cycle"],not attack.get("jump",false),attack["factor"])
	_tick_returning(delta,player)
	jump_left -= delta
	if p.is_melee() and p.ranks["jump_attack"]>0 and jump_left<=0:
		var target: int = a.nearest(player,[],false)
		if target>=0:
			var aim: Vector2 = player.direction_to(c.enemies[target]["pos"])
			var landing: Vector2 = c.enemies[target]["pos"]-aim*33
			if not c.blocked(landing,13):
				jump_left = 5; a.jump_request = {"pos":landing,"from":player}; c.grace_time = maxf(c.grace_time,0.4)
				var cycle: int = a._next_cycle(); cycle_data[cycle] = {"finisher":false,"hand":0,"riposte":false}
				delayed.append({"origin":landing,"direction":aim,"cycle":cycle,"left":0.3,"factor":1.5/p.delivery_factor(),"jump":true})
func data(cycle: int) -> Dictionary: return cycle_data.get(cycle,{"finisher":false,"hand":0,"riposte":false})
func bleed(enemy: Dictionary, dps: float, duration: float = 2.0) -> void:
	enemy["bleed_dps"] = maxf(enemy.get("bleed_dps",0),dps); enemy["bleed_left"] = duration
func hit(enemy: Dictionary, amount: float, cycle: int, tags: Dictionary = {}) -> void:
	if enemy["hp"]<=0 or enemy.get("dormant",false): return
	var secondary: bool = tags.get("secondary",false)
	var index: int = c.enemies.find(enemy)
	if p.weapon=="bow" and enemy.get("mark_left",0)>0: amount *= 1+0.1*p.ranks["marked_prey"]
	if p.weapon=="hammer": amount *= 1+minf(0.3,enemy.get("fracture",0.0))
	if p.weapon=="wand" and p.ranks["spell_focus"]>0 and not secondary:
		focus_hits = focus_hits+1 if focus_target==index else 1; focus_target = index
		amount *= 1+minf(0.3,focus_hits*0.02*p.ranks["spell_focus"])
	var before: float = enemy["hp"]; c._damage_enemy(enemy,amount)
	var dealt: float = minf(before,amount)
	if not ledgers.has(cycle): ledgers[cycle] = {"heal":0.0,"slam":false,"targets":{},"residue":false}
	var ledger: Dictionary = ledgers[cycle]
	if p.ranks["lifesteal"]>0:
		if healing_second!=int(time): healing_second = int(time); healing_spent = 0
		var heal: float = minf(dealt*0.01*p.ranks["lifesteal"],minf(maxf(0,p.max_health()*0.02-ledger["heal"]),maxf(0,p.max_health()*0.04-healing_spent)))
		healing_spent += heal
		ledger["heal"] += heal; c.heal(heal)
	if secondary: return
	if p.weapon=="bow":
		if tags.get("charged",false) and p.ranks["marked_prey"]>0: enemy["mark_left"] = 3.0
	if p.weapon=="crossbow":
		if enemy.get("kind","") not in ["boss","miniboss"]:
			enemy["stun_left"] = maxf(enemy.get("stun_left",0),0.06)
			if p.ranks["pinning"]>0 and c.blocked(enemy["pos"]+a.pose_direction*28,13): enemy["stun_left"] = 0.7
	if p.weapon=="wand" and not ledger["residue"] and p.ranks["arcane_residue"]>0:
		ledger["residue"] = true; patch(enemy["pos"],cycle,0.04*p.ranks["arcane_residue"]*tags.get("power",1.0),1.5,30)
	if p.weapon=="dual_axe":
		if enemy.get("axe_hand",-1)!=data(cycle)["hand"] and enemy.has("axe_hand") and p.ranks["crosscut"]>0: bleed(enemy,p.damage()*0.12*p.ranks["crosscut"])
		enemy["axe_hand"] = data(cycle)["hand"]
		if not ledger["targets"].has(index): rhythm = minf(5,rhythm+1); rhythm_age = 0
		if p.ranks["hooked_edges"]>0 and not ledger["targets"].has(index) and enemy["pos"].distance_to(a.last_player)>49*(1+0.05*p.ranks["reach"]): displace(enemy,-(enemy["pos"]-a.last_player).normalized()*8*p.ranks["hooked_edges"],cycle,false)
	if p.weapon=="hammer" and p.ranks["fracture"]>0:
		enemy["fracture"] = minf(0.3,enemy.get("fracture",0.0)+0.03*p.ranks["fracture"]); enemy["fracture_left"] = 3.0
	ledger["targets"][index] = true
	if p.is_melee() and p.ranks["hard_slam"]>0 and not ledger["slam"]:
		ledger["slam"] = true
		var direction: Vector2 = (enemy["pos"]-a.last_player).normalized()
		a._add_effect({"kind":"wave","pos":enemy["pos"],"direction":direction,"radius":100.0,"angle":0.5,"life":0.25,"duration":0.25})
		for other in c.enemies:
			var offset: Vector2 = other["pos"]-enemy["pos"]
			if other!=enemy and offset.length()<100 and absf(direction.angle_to(offset))<0.5 and not c.wall_between(enemy["pos"],other["pos"]): hit(other,amount*0.2,cycle,{"secondary":true})
func patch(pos: Vector2, cycle: int, factor: float, duration: float, radius: float) -> void:
	if patches.size()>=24: patches.pop_front()
	patches.append({"pos":pos,"life":duration,"tick":0.0,"radius":radius,"damage":p.damage()*factor,"cycle":cycle})
	a._add_effect({"kind":"arcane_patch" if p.weapon=="wand" else "fissure","pos":pos,"direction":a.pose_direction,"radius":radius,"life":duration,"duration":duration})
func displace(enemy: Dictionary, motion: Vector2, cycle: int, collision: bool = true) -> void:
	if enemy.get("kind","") in ["boss","miniboss"]: return
	if enemy.get("kind","")=="brute": motion *= 0.4
	var old: Vector2 = enemy["pos"]
	for i in range(maxi(1,int(motion.length()/5))):
		var point: Vector2 = old+motion*(i+1)/maxi(1,int(motion.length()/5))
		if c.blocked(point,13): break
		enemy["pos"] = point
	if collision:
		for other in c.enemies:
			if other==enemy or other["hp"]<=0: continue
			if not c.wall_between(old,other["pos"]) and Geometry2D.get_closest_point_to_segment(other["pos"],old,enemy["pos"]).distance_to(other["pos"])<24:
				var ledger: Dictionary = ledgers.get(cycle,{})
				var victims: Array = ledger.get("collisions",[])
				var index: int = c.enemies.find(other)
				if victims.has(index): continue
				victims.append(index); ledger["collisions"] = victims
				hit(other,p.damage()*p.cycle_output()*(0.6 if p.ranks["bowling_blow"]>0 else 0.25),cycle,{"secondary":true})
				ledgers[cycle]["collisions"] = victims
				if p.ranks["crowd_pressure"]>0:
					enemy["slow_left"] = 1.0+p.ranks["crowd_pressure"]*0.3
					if other.get("kind","") not in ["boss","miniboss"]: other["slow_left"] = enemy["slow_left"]
func melee(origin: Vector2, direction: Vector2, cycle: int, secondary: bool = false, factor: float = 1.0) -> void:
	var finisher: bool = data(cycle)["finisher"] and not secondary
	var hammer: bool = p.weapon=="hammer"
	var radius: float = {"sword":88.0,"dual_axe":82.0,"club":104.0,"hammer":125.0}.get(p.weapon,88.0)*(1+0.05*p.ranks["reach"])
	if hammer: radius *= 1+0.12*p.ranks["fault_line"]
	var angle: float = {"sword":1.0,"dual_axe":0.9,"club":1.2,"hammer":0.45}.get(p.weapon,1.0)*(1+0.15*p.ranks["area"])
	if hammer: angle /= 1+0.08*p.ranks["fault_line"]
	var circular: bool = (hammer and p.ranks["seismic_slam"]>0) or (p.weapon=="dual_axe" and finisher and p.ranks["whirlwind"]>0)
	if circular: angle = PI; radius *= 0.75*sqrt(1+0.15*p.ranks["area"])
	if p.weapon=="club" and p.ranks["titans_grip"]>0:
		var target: int = a.nearest(origin)
		if target<0 or origin.distance_to(c.enemies[target]["pos"])>radius+12: return
		origin = c.enemies[target]["pos"]; circular = true; angle = PI; radius = 50*(1+0.05*p.ranks["reach"])*sqrt(1+0.15*p.ranks["area"]); factor *= 1.6
	if p.weapon=="sword" and finisher: factor *= 1.35+0.35*p.ranks["extended_combo"]
	if p.weapon=="sword" and data(cycle)["riposte"] and (p.ranks["riposte"]>0 or p.ranks["counterguard"]>0): factor *= 1.25+0.2*p.ranks["riposte"]; riposte_left = 0
	if p.weapon=="dual_axe" and p.ranks["twin_execution"]>0 and finisher: factor *= 1.8; angle = 0.55
	a._add_effect({"kind":"wave" if hammer else "slash","pos":origin,"direction":direction,"radius":radius,"angle":angle,"circular":circular,"reverse":data(cycle)["hand"]==1,"life":0.3,"duration":0.3})
	for enemy in c.enemies:
		var offset: Vector2 = enemy["pos"]-origin
		if offset.length()>radius+12 or (offset.length()>0.01 and absf(direction.angle_to(offset))>angle): continue
		if c.wall_between(origin,enemy["pos"]): continue
		var amount: float = p.roll_damage()*p.delivery_factor()*factor
		if finisher and p.weapon=="sword" and enemy["hp"]<enemy.get("max_hp",enemy["hp"])*0.4: amount *= 1+0.25*p.ranks["execution"]
		hit(enemy,amount,cycle,{"secondary":secondary})
		if p.weapon=="club":
			displace(enemy,direction*(30+12*p.ranks["heavy_timber"])*(2 if p.ranks["bowling_blow"]>0 else 1),cycle)
			if enemy.get("kind","") not in ["boss","miniboss"]: enemy["stun_left"] = (0.1+0.08*p.ranks["heavy_timber"]+(0.3 if p.ranks["titans_grip"]>0 else 0))*(0.4 if enemy.get("kind","")=="brute" else 1)
	if secondary: return
	if p.weapon=="sword" and finisher:
		if p.ranks["counterguard"]>0: guard_left = 0.3
		if p.ranks["sword_wave"]>0:
			c.bullets.append({"pos":origin,"velocity":direction*330,"damage":p.damage()*p.delivery_factor()*0.6,"life":1.0,"hits":[],"remaining":99,"through":false,"kind":"sword_wave","radius":20.0,"cycle":cycle})
	if hammer and p.ranks["aftershock"]>0: delayed.append({"origin":origin,"direction":direction,"cycle":cycle,"left":0.25,"factor":0.2*p.ranks["aftershock"]})
	if p.weapon=="club" and p.ranks["backswing"]>0: delayed.append({"origin":origin,"direction":direction.rotated(0.25),"cycle":cycle,"left":0.22,"factor":0.2*p.ranks["backswing"]})
	if hammer and p.ranks["fissure"]>0 and not data(cycle).get("fissure",false):
		if not cycle_data.has(cycle): cycle_data[cycle] = data(cycle).duplicate()
		cycle_data[cycle]["fissure"] = true
		for step in range(3):
			var distance: float = radius*(step+1)/3.0
			var point: Vector2 = origin+direction*distance
			if not c.wall_between(origin,point): patch(point,cycle,0.12*p.cycle_output(),1.8,22)
func returning(origin: Vector2, direction: Vector2, damage: float, cycle: int, shot: int = 0, count: int = 1) -> void:
	if c.bullets.size()>=192: return
	var orbit: bool = p.weapon=="chakram" and p.ranks["orbiting_blades"]>0
	var target: int = a.nearest(origin)
	var flight: float = origin.distance_to(c.enemies[target]["pos"])/p.shot_speed() if target>=0 else 0.65
	c.bullets.append({"pos":origin,"velocity":direction*p.shot_speed(),"damage":damage,"life":4.0,"hits":[],"remaining":1+p.ranks["skewer"],"through":p.through_obstacles(),"kind":p.weapon,"radius":6.0 if p.weapon=="spear" else 10.0,"cycle":cycle,"v2_path":true,"orbit_offset":TAU*shot/maxi(1,count),"phase":"orbit" if orbit else "out","age":0.0,"flight":maxf(0.2,flight),"phase_age":0.0,"launch":origin,"direction":direction,"contacts":{},"return_contacts":{},"bounces":p.ranks["ricochet"]+(2 if p.ranks["hunting_discs"]>0 else 0)})
func _tick_returning(delta: float, player: Vector2) -> void:
	for bullet in c.bullets:
		if not bullet.get("v2_path",false) or bullet["life"]<=0: continue
		bullet["life"] -= delta; bullet["age"] += delta; bullet["phase_age"] += delta
		var start: Vector2 = bullet["pos"]
		var returning: bool = bullet["phase"]=="return"
		if bullet["phase"]=="orbit":
			bullet["pos"] = player+Vector2.from_angle(time*4+bullet["orbit_offset"])*(64+10*p.ranks["wide_orbit"])
			if bullet["age"]>maxf(0.3,p.fire_interval()): bullet["life"] = 0
		elif bullet["phase"]=="lodged":
			bullet["lodged_age"] = bullet.get("lodged_age",0.0)+delta
			if bullet.has("anchor") and bullet["anchor"]<c.enemies.size(): bullet["pos"] = c.enemies[bullet["anchor"]]["pos"]
			if p.ranks["impaler"]>0 and bullet["phase_age"]>=0.35:
				bullet["phase_age"] = 0
				a._add_effect({"kind":"explosion","pos":bullet["pos"],"radius":45.0,"life":0.25,"duration":0.25})
				for enemy in c.enemies:
					if enemy["hp"]>0 and bullet["pos"].distance_to(enemy["pos"])<57 and not c.wall_between(bullet["pos"],enemy["pos"]): hit(enemy,bullet["damage"]*0.18,bullet["cycle"],{"secondary":true})
			if bullet["lodged_age"]>= (1.15 if p.ranks["impaler"]>0 else 0.24)/(1+0.2*p.ranks["swift_recall"]): bullet["phase"] = "return"; bullet["phase_age"] = 0
			continue
		else:
			var direction: Vector2 = bullet["direction"]
			if returning:
				direction = bullet["pos"].direction_to(player)
			elif p.ranks["follow"]>0:
				var target: int = a.nearest(start,bullet["contacts"].keys(),not bullet["through"])
				if target>=0: direction = start.direction_to(c.enemies[target]["pos"])
			elif p.weapon=="chakram": direction = direction.rotated(sin(bullet["age"]/bullet["flight"]*TAU)*(.22+.06*p.ranks["wide_orbit"]))
			var speed: float = p.shot_speed()*(1+0.15*p.ranks["swift_recall"] if returning else 1)
			if not returning and p.weapon=="chakram" and bullet["age"]>bullet["flight"]: speed *= 1/(1+0.6*p.ranks["lingering_disc"])
			bullet["velocity"] = direction*speed; bullet["pos"] += bullet["velocity"]*delta
			if returning and (bullet["pos"].distance_to(player)<18 or bullet["phase_age"]>3): bullet["life"] = 0
			if not returning and (bullet["age"]>maxf(1.5 if p.ranks["hunting_discs"]>0 else 0.65,bullet["flight"]+0.15)+0.15*p.ranks["lingering_disc"] or not c.bounds.has_point(bullet["pos"])): bullet["phase"] = "return"; bullet["phase_age"] = 0
		var wall: bool = not bullet["through"] and c.wall_between(start,bullet["pos"])
		if wall:
			if bullet["phase"]!="orbit": bullet["phase"] = "return"; bullet["phase_age"] = 0
			continue
		for index in range(c.enemies.size()):
			var enemy: Dictionary = c.enemies[index]
			if enemy["hp"]<=0 or enemy.get("dormant",false): continue
			if Geometry2D.get_closest_point_to_segment(enemy["pos"],start,bullet["pos"]).distance_to(enemy["pos"])>13+bullet["radius"]: continue
			var ledger: Dictionary = bullet["return_contacts"] if returning else bullet["contacts"]
			if ledger.has(index) and (p.weapon=="spear" or time-ledger[index]<0.3): continue
			ledger[index] = time
			var factor := (1.0 if p.ranks["returning_strike"]>0 else 0.4) if returning and p.weapon=="spear" else (0.8 if p.weapon=="spear" else 0.65)
			if p.weapon=="chakram": factor *= 1+minf(0.3,float(bullet.get("repeats",0))*0.05*p.ranks["serrated_rhythm"]); bullet["repeats"] = bullet.get("repeats",0)+1
			hit(enemy,bullet["damage"]*factor*bullet.get("ricochet_damage",1.0),bullet["cycle"])
			if p.weapon=="spear" and not returning:
				if enemy.get("kind","") not in ["boss","miniboss"]: enemy["tether_left"] = 0.35
				bullet["remaining"] -= 1
				if bullet["remaining"]<=0:
					var next: int = a.nearest(enemy["pos"],ledger.keys(),not bullet["through"]) if bullet["bounces"]>0 else -1
					if next>=0:
						bullet["direction"] = enemy["pos"].direction_to(c.enemies[next]["pos"]); bullet["bounces"] -= 1; bullet["remaining"] = 1
						bullet["ricochet_damage"] = bullet.get("ricochet_damage",1.0)*0.85
						bullet["age"] = 0; bullet["flight"] = enemy["pos"].distance_to(c.enemies[next]["pos"])/p.shot_speed()
						break
					bullet["phase"] = "lodged"; bullet["anchor"] = index; bullet["phase_age"] = 0
					if p.ranks["serrated_head"]>0: bleed(enemy,p.damage()*0.12*p.ranks["serrated_head"])
					break
			elif not returning and bullet["bounces"]>0:
				var next: int = a.nearest(enemy["pos"],ledger.keys(),not bullet["through"])
				if next>=0: bullet["direction"] = enemy["pos"].direction_to(c.enemies[next]["pos"]); bullet["bounces"] -= 1; bullet["ricochet_damage"] = bullet.get("ricochet_damage",1.0)*0.85

func meteor_impact(meteor: Dictionary) -> float:
	var cycle: int = meteor.get("cycle",0)
	if p.ranks["arcane_residue"]>0:
		if not ledgers.has(cycle): ledgers[cycle] = {"heal":0.0,"slam":false,"targets":{},"residue":false}
		if not ledgers[cycle]["residue"]:
			ledgers[cycle]["residue"] = true; patch(meteor["pos"],cycle,0.04*p.ranks["arcane_residue"]*meteor.get("power",1),1.5,30)
	var target: int = a.nearest(meteor["pos"],[],false)
	if p.ranks["spell_focus"]>0 and target>=0:
		focus_hits = focus_hits+1 if focus_target==target else 1; focus_target = target
		return 1+minf(0.3,focus_hits*0.02*p.ranks["spell_focus"])
	return 1.0
