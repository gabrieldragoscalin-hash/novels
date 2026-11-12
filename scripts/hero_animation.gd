extends RefCounted
## Continuous locomotion plus independently blended two-arm IK. No full-body frame swaps.
const Art = preload("res://scripts/game_art.gd")
const WeaponArt = preload("res://scripts/weapon_art.gd")
const STRIDE := 104.0
const ARM_LENGTH := 9.0
var phase := 0.0
var move_blend := 0.0
var motion_direction := Vector2.DOWN
var aim_angle := -PI/2
var facing_back := true
var hand_side := 1.0
var primary := Vector2(12,-24)
var support := Vector2(-12,-24)
var weapon_angle := -PI/2
var release_age := 10.0
var last_release := 0
var reverse := false
var time := 0.0
var weapon := "bow"
var windup := 0.0
var laser := false
var meteor := false
var grip := Vector2.ZERO
var muzzle := Vector2.ZERO

func reset() -> void:
	phase = 0; move_blend = 0; release_age = 10; last_release = 0; time = 0
	primary = Vector2(12,-24); support = Vector2(-12,-24)
	aim_angle = -PI/2; weapon_angle = aim_angle; facing_back = true; hand_side = 1.0

func sync_room(serial: int) -> void:
	last_release = serial; release_age = 10; windup = 0

func tick(delta: float, motion: Vector2, aim: Vector2, arsenal, progression, fire_time: float, has_target: bool) -> void:
	time += delta
	var distance := motion.length()
	phase += distance/STRIDE*TAU
	var smoothing := 1.0-exp(-delta*14)
	move_blend = lerpf(move_blend,1.0 if distance>0.01 else 0.0,smoothing)
	if distance>0.01: motion_direction = motion_direction.lerp(motion.normalized(),smoothing).normalized()
	if aim.length_squared()>0.01: aim_angle = lerp_angle(aim_angle,aim.angle(),1.0-exp(-delta*12))
	var direction := Vector2.from_angle(aim_angle)
	if direction.y < -0.25: facing_back = true
	elif direction.y > 0.25: facing_back = false
	# Use the visible leading shoulder when the character turns sideways.
	if direction.x>0.35: hand_side = 1.0
	elif direction.x< -0.35: hand_side = -1.0
	weapon = progression.weapon
	laser = weapon=="wand" and progression.ranks["perpetuum"]>0
	meteor = weapon=="wand" and progression.ranks["meteor"]>0
	release_age += delta
	if arsenal.release_serial!=last_release:
		last_release = arsenal.release_serial; release_age = 0; reverse = arsenal.pose_reverse
	var preparation := minf(0.22,progression.fire_interval()*0.42)
	windup = clampf(1.0-fire_time/maxf(0.03,preparation),0,1) if has_target else 0.0
	if arsenal.charge>0: windup = clampf(arsenal.charge/0.6,0,1)
	var pose := targets(direction)
	# Bounded interpolation prevents rapid extra shots from snapping wrists/weapon poses.
	primary = primary.move_toward(pose["primary"],delta*110)
	support = support.move_toward(pose["support"],delta*110)
	weapon_angle = rotate_toward(weapon_angle,pose["angle"],delta*(22 if weapon=="sword" else 15))

func targets(direction: Vector2) -> Dictionary:
	var side := Vector2(-direction.y,direction.x)
	var center := Vector2(0,-28)
	var recoil := exp(-release_age*18)
	var swing := 0.0
	var hand := center+direction*12+side*2
	var other := Vector2(-hand_side*12,-21)+motion_direction*sin(phase)*2*move_blend
	match weapon:
		"bow":
			hand = center+direction*(13-recoil*2)
			other = hand-direction*(6+windup*4-recoil)
		"crossbow":
			hand = center+direction*(7-recoil*4)+side*2
			other = hand+direction*6
		"wand":
			var cast := 0.5+sin(time*10)*0.12 if laser else recoil
			hand = center+direction*(13+cast*6)+side*4
			if meteor:
				hand = Vector2(hand_side*11,-44+recoil*9)
				other = Vector2(-hand_side*10,-42+recoil*7)
		"sword":
			swing = (-windup*1.05 if release_age>0.22 else sin(minf(1.0,release_age/0.22)*PI)*1.1)*(-1 if reverse else 1)
			hand = center+direction.rotated(swing)*16
		"hammer":
			swing = -windup*1.2+recoil*0.7
			hand = center+direction*(10+recoil*6)+Vector2(0,-windup*10)
			other = hand+direction.rotated(swing)*5
		"chakram":
			hand = center+direction*(10+recoil*11)-side*windup*7
	return {"primary":hand,"support":other,"angle":direction.angle()+swing}

static func elbow(shoulder: Vector2, hand: Vector2, bend: float, length: float = ARM_LENGTH) -> Vector2:
	var delta := hand-shoulder
	var distance := clampf(delta.length(),0.01,length*2-0.01)
	var direction := delta.normalized() if delta.length()>0.001 else Vector2.DOWN
	return shoulder+direction*distance*0.5+Vector2(-direction.y,direction.x)*sqrt(maxf(0,length*length-distance*distance*0.25))*bend

func joints() -> Dictionary:
	var bounce := -absf(sin(phase*2))*0.6*move_blend
	var torso := Vector2(sin(phase)*0.45*move_blend,bounce)
	var main_shoulder := torso+Vector2(hand_side*8,-38)
	var off_shoulder := torso+Vector2(-hand_side*8,-38)
	var main_hand := main_shoulder+(primary-main_shoulder).limit_length(ARM_LENGTH*2-0.1)
	var off_hand := off_shoulder+(support-off_shoulder).limit_length(ARM_LENGTH*2-0.1)
	# Project the complete grip into BOTH reach circles, keeping the second hand
	# attached to the same weapon instead of independently clamping its wrist.
	if weapon in ["bow","crossbow","hammer"]:
		var forward := Vector2.from_angle(weapon_angle)
		var offset: Vector2 = forward*({"crossbow":6.0,"hammer":5.0}.get(weapon,0.0))
		if weapon=="bow": offset = -forward*(6+windup*4-exp(-release_age*18))
		for i in range(12):
			main_hand = off_shoulder-offset+(main_hand-(off_shoulder-offset)).limit_length(ARM_LENGTH*2-0.15)
			main_hand = main_shoulder+(main_hand-main_shoulder).limit_length(ARM_LENGTH*2-0.15)
		off_hand = main_hand+offset
	return {"torso":torso,"main_shoulder":main_shoulder,"off_shoulder":off_shoulder,"main_hand":main_hand,"off_hand":off_hand,"main_elbow":elbow(main_shoulder,main_hand,-hand_side),"off_elbow":elbow(off_shoulder,off_hand,hand_side)}

func draw(canvas: CanvasItem, feet: Vector2) -> void:
	var pose := joints()
	grip = feet+pose["main_hand"]
	var barrel: float = {"bow":5.0,"crossbow":18.5,"wand":20.3,"chakram":7.0}.get(weapon,16.0)
	muzzle = grip+Vector2.from_angle(weapon_angle)*barrel
	# A single body/arm set avoids ghost limbs during a turn. Hysteresis prevents
	# facing flicker; the underlying stride and wrist interpolation stay continuous.
	_draw_facing(canvas,feet,pose,"back" if facing_back else "front",1.0)
	canvas.draw_set_transform(Vector2.ZERO)

func _draw_facing(c: CanvasItem, feet: Vector2, pose: Dictionary, view: String, alpha: float) -> void:
	var tint := Color(1,1,1,alpha)
	var torso: Vector2 = pose["torso"]
	var cape_angle := sin(phase+0.8)*0.06*move_blend+sin(time*2)*0.015
	c.draw_set_transform(feet+torso+Vector2(0,-40),cape_angle)
	c.draw_texture_rect(Art.frame("rig_"+view+"_cape"),Rect2(-13,0,26,36),false,tint)
	c.draw_set_transform(Vector2.ZERO)
	for leg in [-1,1]:
		var stride: float = phase+(PI if leg<0 else 0)
		var hip := feet+torso+Vector2(leg*3.5,-21)
		var foot := feet+Vector2(leg*4,0)+motion_direction*sin(stride)*5*move_blend+Vector2(0,-maxf(0,cos(stride))*3*move_blend)
		var knee := elbow(hip,foot,float(leg),11.0)
		_segment(c,"rig_"+view+"_thigh",hip,knee,7.5,tint)
		_segment(c,"rig_"+view+"_shin",knee,foot,7.0,tint)
	# Shoulder roots sit UNDER the cuirass, not on top of the neck/armor.
	_arms(c,feet,pose,view,tint,"upper")
	if view=="back": _arms(c,feet,pose,view,tint,"forearm")
	c.draw_texture_rect(Art.frame("rig_"+view+"_torso"),Rect2(feet+torso+Vector2(-10,-43),Vector2(20,24)),false,tint)
	if view=="front": _arms(c,feet,pose,view,tint,"forearm")
	_arms(c,feet,pose,view,tint,"held")
	c.draw_texture_rect(Art.frame("rig_"+view+"_head"),Rect2(feet+torso+Vector2(-7,-55),Vector2(14,15)),false,tint)

func _arms(c: CanvasItem, feet: Vector2, pose: Dictionary, view: String, tint: Color, layer: String) -> void:
	for name in (["off","main"] if layer!="held" else []):
		var shoulder: Vector2 = feet+pose[name+"_shoulder"]
		var joint: Vector2 = feet+pose[name+"_elbow"]
		var hand: Vector2 = feet+pose[name+"_hand"]
		if layer=="upper": _segment(c,"rig_"+view+"_upperarm",shoulder,joint,5.2,tint)
		else: _segment(c,"rig_"+view+"_forearm",joint,hand,4.1,tint)
	if layer!="held": return
	var hand: Vector2 = feet+pose["main_hand"]
	var weapon_tint := tint
	if weapon=="chakram": weapon_tint.a *= clampf((release_age-0.10)/0.12,0,1)
	if weapon_tint.a>0: WeaponArt.draw_gripped(c,weapon,hand,weapon_angle,weapon_tint)
	if weapon=="bow":
		var cross := Vector2(-sin(weapon_angle),cos(weapon_angle))*13
		var pull: Vector2 = feet+pose["off_hand"]
		c.draw_line(hand+cross,pull,Color(0.9,0.83,0.65,tint.a*0.8),0.7)
		c.draw_line(hand-cross,pull,Color(0.9,0.83,0.65,tint.a*0.8),0.7)
	# Hands are painted gripping fists, layered AFTER the shaft/string they hold.
	for name in ["off","main"]:
		var point: Vector2 = feet+pose[name+"_hand"]
		var wrist_angle: float = (point-feet-pose[name+"_elbow"]).angle()-PI/2
		c.draw_set_transform(point,wrist_angle,Vector2(-hand_side if name=="off" else hand_side,1))
		c.draw_texture_rect(Art.frame("rig_"+view+"_hand"),Rect2(-1.9,-2.0,3.8,4.8),false,tint)
		c.draw_set_transform(Vector2.ZERO)

static func _segment(c: CanvasItem, key: String, start: Vector2, end: Vector2, width: float, tint: Color) -> void:
	var length := start.distance_to(end)
	c.draw_set_transform(start,(end-start).angle()-PI/2)
	c.draw_texture_rect(Art.frame(key),Rect2(-width/2,-1,width,length+2),false,tint)
	c.draw_set_transform(Vector2.ZERO)
