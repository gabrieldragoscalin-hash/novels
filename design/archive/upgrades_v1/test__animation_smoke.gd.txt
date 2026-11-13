extends SceneTree
const HeroAnimator = preload("res://scripts/hero_animation.gd")
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Art = preload("res://scripts/game_art.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var c = Combat.new(Rect2(8,166,464,438),[])
	var animation = HeroAnimator.new()
	# Repeated releases must never reset walking phase or teleport a wrist.
	for weapon in ["bow","crossbow","wand","sword","hammer","chakram"]:
		c.progression.weapon = weapon
		assert(Art.frame("inventory_"+weapon).atlas==Art.INVENTORY)
		for aim in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2(1,1).normalized(),Vector2(-1,-1).normalized()]:
			for frame in range(90):
				if frame%5==0: c.arsenal.release_serial += 1
				var previous_phase: float = animation.phase
				var previous_hand: Vector2 = animation.primary
				animation.tick(1.0/60,aim*3,aim,c.arsenal,c.progression,float(frame%5)/60,true)
				assert(animation.phase>previous_phase)
				assert(animation.primary.distance_to(previous_hand)<=110.0/60+0.001,"Release teleported wrist")
				var joints: Dictionary = animation.joints()
				if weapon in ["bow","crossbow","hammer"]:
					var distance: float = {"bow":6+animation.windup*4-exp(-animation.release_age*18),"crossbow":6.0,"hammer":5.0}[weapon]
					var offset: Vector2 = Vector2.from_angle(animation.weapon_angle)*distance*(-1 if weapon=="bow" else 1)
					assert((joints["off_hand"]-joints["main_hand"]).distance_to(offset)<0.001,"Support hand detached from weapon")
				assert(animation.hand_side==1.0 or animation.hand_side== -1.0)
				for side in ["main","off"]:
					assert(joints[side+"_hand"].distance_to(joints[side+"_shoulder"])<HeroAnimator.ARM_LENGTH*2)
					assert(is_equal_approx(joints[side+"_elbow"].distance_to(joints[side+"_shoulder"]),HeroAnimator.ARM_LENGTH))
					assert(is_equal_approx(joints[side+"_elbow"].distance_to(joints[side+"_hand"]),HeroAnimator.ARM_LENGTH))
	var resting = HeroAnimator.new(); resting.weapon = "wand"
	var resting_joints: Dictionary = resting.joints()
	assert(resting_joints["main_elbow"].x>resting_joints["main_shoulder"].x)
	assert(resting_joints["off_elbow"].x<resting_joints["off_shoulder"].x)
	var phase: float = animation.phase
	for i in range(40): animation.tick(1.0/60,Vector2.ZERO,Vector2.RIGHT,c.arsenal,c.progression,1,false)
	assert(animation.phase==phase and animation.move_blend<0.001)
	# Same traveled distance produces the same stride phase across frame rates.
	var a = HeroAnimator.new(); var b = HeroAnimator.new()
	for i in range(60): a.tick(1.0/60,Vector2(3,0),Vector2.RIGHT,c.arsenal,c.progression,1,false)
	for i in range(30): b.tick(1.0/30,Vector2(6,0),Vector2.RIGHT,c.arsenal,c.progression,1,false)
	assert(is_equal_approx(a.phase,b.phase))
	# Changing nearest targets near the horizontal plane must not flicker front/back.
	var orientation: bool = a.facing_back
	for i in range(60):
		var aim := Vector2(1,0.02 if i%2==0 else -0.02)
		a.tick(1.0/60,Vector2.ZERO,aim,c.arsenal,c.progression,1,false)
	assert(a.facing_back==orientation)
	c.enemies = [Dungeon.make_enemy(Vector2(240,250),"boss",1)]
	var serial: int = c.arsenal.release_serial
	c.arsenal._fire(Vector2(240,450),0,false,0)
	assert(c.arsenal.release_serial==serial+1)
	print("PASS: six anatomical inventory poses; continuous stride across releases; bounded wrists and connected IK joints; FPS-independent walking; turn hysteresis; actual release events")
	quit()
