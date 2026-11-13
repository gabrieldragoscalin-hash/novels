extends Control
## Disposable encounter sandbox. Never opens or writes the player's Hub save.
const Plans = preload("res://prototypes/room_lab/layouts.gd")
const Encounter = preload("res://prototypes/room_lab/combat.gd")
const FloorArt = preload("res://prototypes/room_lab/floor.gd")
const Actors = preload("res://prototypes/room_lab/actors.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Gear = preload("res://scripts/equipment.gd")
const Hero = preload("res://scripts/hero_animation.gd")
const Reveal = preload("res://scripts/upgrade_reveal.gd")
const Home = preload("res://scripts/hub_art.gd")
const TYPES := ["bow","crossbow","wand","spear","chakram","sword","dual_axe","club","hammer"]
var plan: Dictionary
var combat
var hero = Hero.new()
var player := Vector2.ZERO
var camera := Vector2.ZERO
var stage: Control
var world: Node2D
var floor_art
var actors
var reveal
var title: Label
var status: Label
var hint: Label
var weapon_button: Button
var map_button: Button
var safety_button: Button
var pressure_button: Button
var layout_index := 0
var weapon_index := 0
var crowded := false
var overview := false
var safe_mode := false
var completed := false
var shrine_used := false
var clock := 0.0
var zoom := 0.84
var pointer := -1
var stick_origin := Vector2.ZERO
var stick_position := Vector2.ZERO
var last_size := Vector2.ZERO
var probe_requested := false
var probe_elapsed := 0.0
var facing := Vector2.UP
var groups: Array = []
var hud: Control
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	preload("res://scripts/game_art.gd").prepare()
	preload("res://scripts/attack_vfx.gd").prepare()
	stage = Control.new(); stage.clip_contents = true; stage.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(stage)
	world = Node2D.new(); stage.add_child(world)
	floor_art = FloorArt.new(); world.add_child(floor_art)
	actors = Actors.new(); actors.lab_ref = weakref(self); world.add_child(actors)
	hud = Control.new(); hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hud)
	title = label("ROOM LAB",Vector2(18,12),21)
	var hub_exit = button("Hub",Vector2(390,10),Vector2(72,36),back)
	label("Routes • larger spaces • staged enemy packs",Vector2(18,44),12)
	status = label("",Vector2(18,69),12)
	button("‹",Vector2(18,96),Vector2(36,34),func(): reset(layout_index-1))
	button("Next layout ›",Vector2(306,96),Vector2(156,34),func(): reset(layout_index+1))
	hint = label("",Vector2(60,104),12); hint.size.x=238; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	map_button = button("Map",Vector2.ZERO,Vector2(100,40),func(): overview=not overview; release_stick(); layout())
	weapon_button = button("",Vector2.ZERO,Vector2(232,40),func(): weapon_index=posmod(weapon_index+1,TYPES.size()); reset(layout_index))
	button("Restart",Vector2.ZERO,Vector2(100,40),func(): reset(layout_index)).name="Restart"
	safety_button = button("",Vector2.ZERO,Vector2(142,36),func(): safe_mode=not safe_mode; combat.invincible=safe_mode; refresh())
	pressure_button = button("",Vector2.ZERO,Vector2(142,36),func(): crowded=not crowded; reset(layout_index))
	button("3 upgrades",Vector2.ZERO,Vector2(142,36),offer_upgrade).name="Upgrades"
	var note = label("",Vector2.ZERO,11); note.name="Note"; note.size.x=444; note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	reveal = Reveal.new(); add_child(reveal); reveal.setup(); reveal.selected.connect(choose)
	# Keep an escape from the sandbox accessible even while a blessing is rolling.
	hud.remove_child(hub_exit); add_child(hub_exit); hub_exit.z_index=30; hub_exit.name="ExitSandbox"
	if OS.has_feature("web"):
		probe_requested=JavaScriptBridge.eval("new URLSearchParams(location.search).get('lab_probe') === '1'")
		var value = JavaScriptBridge.eval("new URLSearchParams(location.search).get('layout') || '0'")
		if str(value).is_valid_int(): layout_index=posmod(int(str(value)),3)
	resized.connect(layout); reset(layout_index); layout()
	if OS.has_feature("web"): JavaScriptBridge.eval("window.__dungeonReady = 'room-lab'")
func label(text: String, pos: Vector2, font_size: int) -> Label:
	var n := Label.new(); n.text=text; n.position=pos; n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	n.add_theme_font_size_override("font_size",font_size); n.add_theme_color_override("font_color",Color("e7d8b3")); hud.add_child(n); return n
func button(text: String, pos: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var n := Button.new(); n.text=text; n.position=pos; n.size=dimensions
	n.add_theme_font_size_override("font_size",12); n.focus_mode=Control.FOCUS_NONE
	var style := StyleBoxFlat.new(); style.bg_color=Color("173732"); style.border_color=Color("aa8d58"); style.set_border_width_all(1); style.set_corner_radius_all(5)
	n.add_theme_stylebox_override("normal",style); n.pressed.connect(action); hud.add_child(n); return n
func layout() -> void:
	last_size=get_viewport_rect().size
	var margin: float=maxf(0,(last_size.x-480)/2)
	hud.position.x=margin
	get_node("ExitSandbox").position.x=390+margin
	reveal.position.x=margin
	stage.position=Vector2(0,140); stage.size=Vector2(last_size.x,maxf(260,last_size.y-284))
	var bottom: float = stage.position.y+stage.size.y+9
	map_button.position=Vector2(18,bottom); weapon_button.position=Vector2(124,bottom); hud.get_node("Restart").position=Vector2(362,bottom)
	safety_button.position=Vector2(18,bottom+47); pressure_button.position=Vector2(169,bottom+47); hud.get_node("Upgrades").position=Vector2(320,bottom+47)
	hud.get_node("Note").position=Vector2(18,bottom+88)
	if overview: zoom=minf((stage.size.x-24)/Plans.BOUNDS.size.x,(stage.size.y-24)/Plans.BOUNDS.size.y)
	else: zoom=0.84
	update_camera(1); refresh()
func reset(index: int) -> void:
	release_stick(); reveal.hide(); layout_index=posmod(index,3); completed=false; shrine_used=false
	plan=Plans.make(layout_index); player=plan["start"]; camera=player; hero=Hero.new()
	combat=Encounter.new(plan); combat.floor_number=2; combat.invincible=safe_mode
	var stats := Gear.stats(TYPES[weapon_index],3); stats["damage"] *= 2.0; stats["health"]=24; stats["weapon"]=TYPES[weapon_index]; stats["level"]=3
	combat.progression.apply_loadout(stats); combat.progression.rng.seed=127+layout_index; combat.health=combat.progression.max_health()
	groups.clear(); var enemies: Array=[]
	for court in plan["courts"]:
		if not court["fight"]: continue
		var members: Array=[]; var amount := 9 if crowded else 6
		for i in range(amount):
			var point: Vector2 = court["center"]+Vector2((i%3-1)*72,(i/3-1)*70)
			if combat.blocked(point,18): point=free_spawn(court["center"],i)
			var enemy := Dungeon.make_enemy(point,["normal","normal","shooter","normal","brute","shooter"][i%6],2)
			enemy["dormant"]=true; enemy["attack"]=0.8+i*0.19
			members.append(enemy); enemies.append(enemy)
		groups.append({"rect":court["rect"],"enemies":members,"active":false})
	combat.enter({"role":"combat","enemies":enemies,"pickups":[]},player)
	floor_art.configure(plan); update_camera(1); refresh()
func free_spawn(origin: Vector2, number: int) -> Vector2:
	for ring in range(1,5):
		for angle in range(12):
			var point := origin+Vector2.from_angle((angle+number)*TAU/12)*ring*35
			if not combat.blocked(point,18): return point
	return combat.nav.get_point_position(combat._cell(origin))
func refresh() -> void:
	if combat==null: return
	hint.text=plan["name"]
	status.text="HP %.0f/%.0f  •  %d remaining  •  Level %d" % [combat.health,combat.progression.max_health(),remaining(),combat.progression.level]
	weapon_button.text=TYPES[weapon_index].replace("_"," ").capitalize()+"  ›"
	map_button.text="Resume" if overview else "Map / pause"
	safety_button.text="Invincible: "+("on" if safe_mode else "off")
	pressure_button.text="Mobs: "+("36" if crowded else "24")
	hud.get_node("Note").text="Sandbox • no saved rewards. Drag anywhere to move; WASD/arrows on PC. Clear all packs, then reach the gold exit."
	if combat.health<=0: status.text="Defeated • restart to test another route"
	elif completed: status.text="Layout cleared • try another route or weapon"
func _physics_process(delta: float) -> void:
	clock+=delta
	if combat==null: return
	var frozen: bool=overview or completed or combat.health<=0
	var speed: float=0.0 if frozen or (reveal.visible and not reveal.slowing()) else (reveal.world_speed() if reveal.slowing() else 1.0)
	var motion := Vector2.ZERO
	if not frozen and not reveal.visible:
		motion=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		motion+=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		if pointer!=-1: motion+=(stick_position-stick_origin).limit_length(48)/48
		motion=motion.limit_length(1)*245*delta*combat.progression.movement_multiplier()
	var before := player
	move_player(motion)
	if motion.length()>0: facing=motion.normalized()
	if speed>0:
		activate_groups()
		if reveal.slowing(): combat.grace_time=maxf(0.15,combat.grace_time)
		combat.tick(delta*speed,player,reveal.slowing())
		if not combat.arsenal.jump_request.is_empty():
			var jump: Dictionary=combat.arsenal.jump_request
			hero.jump_origin=player; player=jump["pos"]; hero.jump_age=0; combat.arsenal.jump_request.clear()
		if combat.progression.pending>0 and not reveal.visible: present_upgrade(true)
		if not shrine_used and player.distance_to(plan["shrine"])<38:
			shrine_used=true; combat.heal(combat.progression.max_health()*0.5)
		if remaining()==0 and player.distance_to(plan["exit"])<48: completed=true; release_stick()
	hero.tick(delta*speed,player-before,facing,combat.arsenal,combat.progression,maxf(0,0.65-combat.fire_time),speed>0)
	update_camera(delta); actors.queue_redraw(); refresh(); queue_redraw()
	if probe_requested:
		probe_elapsed+=delta
		if probe_elapsed>0.2:
			probe_elapsed=0
			JavaScriptBridge.eval("window.__roomLabSnapshot = "+JSON.stringify({"layout":layout_index,"player":[player.x,player.y],"camera":[camera.x,camera.y],"zoom":zoom,"remaining":remaining(),"total":combat.enemies.size(),"awake":combat.enemies.filter(func(e): return e["hp"]>0 and not e.get("dormant",false)).size(),"overview":overview,"offered":combat.progression.offers,"ranks":combat.progression.ranks,"health":combat.health,"weapon":combat.progression.weapon,"pointer":pointer,"stage":[stage.position.x,stage.position.y,stage.size.x,stage.size.y]}))
func remaining() -> int: return combat.enemies.filter(func(e): return e["hp"]>0).size()
func activate_groups() -> void:
	for group in groups:
		if not group["active"] and group["rect"].grow(25).has_point(player):
			group["active"]=true
			for enemy in group["enemies"]: enemy["dormant"]=false
func move_player(motion: Vector2) -> void:
	var steps := maxi(1,int(ceil(motion.length()/6)))
	for i in range(steps):
		var step := motion/steps
		if not combat.blocked(player+Vector2(step.x,0),12): player.x+=step.x
		if not combat.blocked(player+Vector2(0,step.y),12): player.y+=step.y
func update_camera(delta: float) -> void:
	if stage==null or world==null: return
	var target: Vector2=Plans.BOUNDS.get_center() if overview else player+Vector2(0,-65)
	if not overview:
		var half := stage.size/zoom/2
		target=target.clamp(half,Plans.BOUNDS.size-half)
	camera=camera.lerp(target,1-exp(-delta*9)) if delta<1 else target
	world.scale=Vector2.ONE*zoom; world.position=stage.size/2-camera*zoom
func offer_upgrade() -> void:
	if reveal.visible or completed or combat.health<=0: return
	overview=false; layout(); combat.progression.reward_choices(); present_upgrade(false)
func present_upgrade(slow: bool) -> void:
	if combat.progression.pending<=0 or combat.progression.offers.is_empty(): return
	release_stick(); combat.grace_time=maxf(0.8,combat.grace_time)
	reveal.present(combat.progression,"CHOOSE A BLESSING",slow)
func choose(index: int) -> void:
	if not reveal.accept(index): return
	combat.apply_choice(index); reveal.hide(); release_stick()
	if combat.progression.pending>0: present_upgrade(false)
	else: combat.grace_time=maxf(0.6,combat.grace_time)
func release_stick() -> void: pointer=-1; stick_position=stick_origin
func _input(event: InputEvent) -> void:
	# Track an active finger even over the HUD; starting a drag still requires the stage.
	if event is InputEventScreenTouch and not event.pressed and event.index==pointer: release_stick()
	elif event is InputEventScreenDrag and event.index==pointer: stick_position=event.position
	elif event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and pointer==-2: release_stick()
	elif event is InputEventMouseMotion and pointer==-2: stick_position=event.position
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and pointer==-1 and stage.get_rect().has_point(event.position) and not reveal.visible and not overview:
			pointer=event.index; stick_origin=event.position; stick_position=event.position
		elif not event.pressed and event.index==pointer: release_stick()
	elif event is InputEventScreenDrag and event.index==pointer: stick_position=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not DisplayServer.is_touchscreen_available():
		if event.pressed and stage.get_rect().has_point(event.position) and not reveal.visible and not overview:
			pointer=-2; stick_origin=event.position; stick_position=event.position
		elif not event.pressed and pointer==-2: release_stick()
	elif event is InputEventMouseMotion and pointer==-2: stick_position=event.position
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: release_stick()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,Vector2(get_viewport_rect().size.x,140)),Color("091b1c"))
	draw_line(Vector2(18,137),Vector2(462,137),Color("a58a52"),1)
	if is_instance_valid(stage):
		draw_rect(Rect2(0,stage.position.y+stage.size.y,get_viewport_rect().size.x,160),Color("091b1c"))
	if pointer!=-1:
		draw_circle(stick_origin,48,Color(0.5,0.8,0.7,0.12)); draw_arc(stick_origin,48,0,TAU,32,Color("a4baa0"),1.5)
		draw_circle(stick_origin+(stick_position-stick_origin).limit_length(45),15,Color("a5cbb1"))
func back() -> void:
	if OS.has_feature("web"): JavaScriptBridge.eval("{ const u=new URL(location.href); u.searchParams.delete('room_lab'); u.searchParams.delete('layout'); u.searchParams.delete('lab_probe'); history.replaceState(null,'',u); }")
	get_tree().change_scene_to_file.call_deferred("res://scenes/room.tscn")
