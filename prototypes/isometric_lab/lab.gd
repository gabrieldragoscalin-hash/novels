extends Control
## A real 3D, orthographic-camera experiment. No Hub, inventory or saved progression.
const M = preload("res://prototypes/isometric_lab/models.gd")
const Stage = preload("res://prototypes/isometric_lab/stage.gd")
var viewport: SubViewport
var stage: SubViewportContainer
var world: Node3D
var camera: Camera3D
var key_light: DirectionalLight3D
var rig: Dictionary
var obstacles: Array=[]
var enemies: Array=[]
var effects: Array=[]
var player:=Vector2(0,5)
var facing:=Vector2(0.7,0.7).normalized()
var camera_target:=Vector3.ZERO
var clock:=0.0
var stride:=0.0
var walk_blend:=0.0
var attack_left:=0.0
var attack_cycle:=0
var attack_held:=false
var attack_touch:=-1
var motion_direction:=Vector2.ZERO
var dash_left:=0.0
var dash_cooldown:=0.0
var dash_direction:=Vector2.ZERO
var hurt_left:=0.0
var health:=6
var weapon:="sword"
var overview:=false
var low_angle:=false
var low_power:=false
var sparring:=false
var joystick: Control
var pointer:=-1
var stick_origin:=Vector2.ZERO
var stick_position:=Vector2.ZERO
var hud: Control
var status: Label
var frame_button: Button
var angle_button: Button
var weapon_button: Button
var light_button: Button
var dash_button: Button
var attack_button: Button
var probe:=false
var probe_time:=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage=SubViewportContainer.new(); stage.stretch=true; stage.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(stage)
	viewport=SubViewport.new(); viewport.own_world_3d=true; viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; viewport.msaa_3d=Viewport.MSAA_DISABLED; stage.add_child(viewport)
	world=Node3D.new(); viewport.add_child(world)
	var env:=WorldEnvironment.new(); var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR; settings.background_color=Color("303346")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color=Color("9baac0"); settings.ambient_light_energy=0.30
	settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC; env.environment=settings; world.add_child(env)
	key_light=DirectionalLight3D.new(); key_light.rotation_degrees=Vector3(-55,-35,0); key_light.light_color=Color("ffe3b1"); key_light.light_energy=0.80; key_light.shadow_enabled=true
	key_light.directional_shadow_max_distance=65; key_light.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL; world.add_child(key_light)
	var fill:=DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-25,145,0); fill.light_color=Color("85bfc2"); fill.light_energy=0.18; world.add_child(fill)
	obstacles=Stage.build(world)
	M.batch_static(world)
	rig=M.hero(); world.add_child(rig["root"]); M.equip(rig,weapon)
	camera=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.near=0.1; camera.far=160; world.add_child(camera); camera.make_current()
	hud=Control.new(); hud.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(hud)
	label("3D VIEW LAB",Vector2(18,12),22)
	button("Hub",Vector2(390,10),Vector2(72,36),back)
	label("ELYSIAN EMBERS • a different view of the Sanctuary",Vector2(18,47),11)
	status=label("",Vector2(18,72),12)
	frame_button=button("",Vector2.ZERO,Vector2(104,36),func(): overview=not overview; release_stick(); update_camera(1); refresh())
	angle_button=button("",Vector2.ZERO,Vector2(104,36),func(): low_angle=not low_angle; update_camera(1); refresh())
	weapon_button=button("",Vector2.ZERO,Vector2(104,36),func(): weapon="spear" if weapon=="sword" else "sword"; M.equip(rig,weapon); refresh())
	light_button=button("",Vector2.ZERO,Vector2(104,36),func(): low_power=not low_power; key_light.shadow_enabled=not low_power; refresh())
	attack_button=button("Attack • J",Vector2.ZERO,Vector2(142,44),func(): attack())
	attack_button.button_down.connect(func(): attack_held=true)
	attack_button.button_up.connect(func(): attack_held=false)
	dash_button=button("Dash • Space",Vector2.ZERO,Vector2(142,44),dash)
	button("Reset targets",Vector2.ZERO,Vector2(142,44),reset).name="Reset"
	var note=label("Drag anywhere to move • WASD/arrows on PC\nStairs lead to the high terrace. Temporary test; no saved rewards.",Vector2.ZERO,11); note.name="Note"
	resized.connect(layout)
	if OS.has_feature("web"): probe=JavaScriptBridge.eval("new URLSearchParams(location.search).get('iso_probe') === '1'")
	joystick=Control.new(); joystick.mouse_filter=Control.MOUSE_FILTER_IGNORE; joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(joystick); joystick.draw.connect(draw_stick)
	reset(); layout()
	if OS.has_feature("web"): JavaScriptBridge.eval("window.__dungeonReady = 'iso-lab'")
func label(text: String,pos: Vector2,size_value: int) -> Label:
	var n:=Label.new(); n.text=text; n.position=pos; n.mouse_filter=Control.MOUSE_FILTER_IGNORE; n.add_theme_font_size_override("font_size",size_value); n.add_theme_color_override("font_color",Color("eddfbf")); hud.add_child(n); return n
func button(text: String,pos: Vector2,dimensions: Vector2,action: Callable) -> Button:
	var n:=Button.new(); n.text=text; n.position=pos; n.size=dimensions; n.focus_mode=Control.FOCUS_NONE
	n.add_theme_font_size_override("font_size",12)
	var style:=StyleBoxFlat.new(); style.bg_color=Color("29433f"); style.border_color=Color("b99d70"); style.set_border_width_all(1); style.set_corner_radius_all(6)
	n.add_theme_stylebox_override("normal",style); n.pressed.connect(action); hud.add_child(n); return n
func layout() -> void:
	var size_value:=get_viewport_rect().size
	hud.position.x=maxf(0,(size_value.x-480)/2)
	stage.position=Vector2(0,108); stage.size=Vector2(size_value.x,maxf(260,size_value.y-264))
	var top: float=stage.position.y+stage.size.y+10
	for i in range(4): [frame_button,angle_button,weapon_button,light_button][i].position=Vector2(18+i*113,top)
	attack_button.position=Vector2(18,top+44); dash_button.position=Vector2(169,top+44); hud.get_node("Reset").position=Vector2(320,top+44)
	hud.get_node("Note").position=Vector2(18,top+94)
	update_camera(1); refresh(); queue_redraw()
func reset() -> void:
	for enemy in enemies: enemy["node"].queue_free()
	enemies.clear(); sparring=false; health=6; hurt_left=0; player=Vector2(0,5); attack_left=0; dash_left=0; dash_cooldown=0; release_stick(); attack_held=false; attack_touch=-1
	for point in [Vector2(-2,-1),Vector2(3,2),Vector2(1,-5)]: enemies.append(M.shade(world,Stage.point(point),point.y< -4))
	rig["root"].position=Stage.point(player); camera_target=Stage.point(player)+Vector3.UP; update_camera(1); refresh()
func refresh() -> void:
	if status==null: return
	status.text="HP %d/6  •  %d/3 shades defeated  •  %s" % [health,3-alive(),"Reset to continue" if health<=0 else ("Sparring" if sparring else "Explore • attack to spar")]
	frame_button.text="Follow view" if overview else "Overview"
	angle_button.text="Angle: 35°" if low_angle else "Angle: 50°"
	weapon_button.text=weapon.capitalize()+" ›"
	light_button.text="Light: simple" if low_power else "Light: shadows"
	dash_button.text="Dash • Space" if dash_cooldown<=0 else "Dash %.1fs" % dash_cooldown
func alive() -> int: return enemies.filter(func(e): return e["hp"]>0).size()
func _physics_process(delta: float) -> void:
	clock+=delta
	attack_left=maxf(0,attack_left-delta); dash_cooldown=maxf(0,dash_cooldown-delta); hurt_left=maxf(0,hurt_left-delta)
	var stick:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	stick+=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	if pointer!=-1: stick+=(stick_position-stick_origin).limit_length(48)/48
	stick=stick.limit_length(1)
	var direction:=screen_direction(stick)
	motion_direction=direction
	if health>0 and not overview:
		if Input.is_physical_key_pressed(KEY_SPACE): dash()
		if attack_held or Input.is_physical_key_pressed(KEY_J): attack()
		if direction.length()>0.01 and attack_left<=0: facing=direction.normalized()
		var motion:=direction*5.4*delta
		if dash_left>0: motion=dash_direction*21*delta; dash_left=maxf(0,dash_left-delta)
		move_player(motion)
		update_enemies(delta)
	walk_blend=move_toward(walk_blend,stick.length() if health>0 and not overview else 0,delta*8)
	stride+=delta*walk_blend
	rig["root"].position=Stage.point(player)
	rig["root"].rotation.y=lerp_angle(rig["root"].rotation.y,atan2(-facing.x,-facing.y),1-exp(-delta*18))
	M.pose(rig,stride,walk_blend,1-attack_left/0.38 if attack_left>0 else 0,weapon)
	for effect in effects.duplicate():
		effect["life"]-=delta
		if effect["life"]<=0: effect["node"].queue_free(); effects.erase(effect)
	update_camera(delta); refresh(); joystick.queue_redraw()
	if probe:
		probe_time+=delta
		if probe_time>0.2:
			probe_time=0
			JavaScriptBridge.eval("window.__isoSnapshot = "+JSON.stringify({"player":[player.x,player.y],"height":Stage.height_at(player),"health":health,"alive":alive(),"weapon":weapon,"attack_cycle":attack_cycle,"camera":[camera.position.x,camera.position.y,camera.position.z],"orthographic":camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"overview":overview,"low_angle":low_angle,"shadows":key_light.shadow_enabled,"pointer":pointer,"fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}))
func screen_direction(stick: Vector2) -> Vector2:
	var right:=Vector2(0.70710678,-0.70710678)
	var down:=Vector2(0.70710678,0.70710678)
	return right*stick.x+down*stick.y
func move_player(motion: Vector2) -> void:
	var steps:=maxi(1,int(ceil(motion.length()/0.10)))
	for i in range(steps):
		var step:=motion/steps
		if not Stage.blocked(player+Vector2(step.x,0),obstacles): player.x+=step.x
		if not Stage.blocked(player+Vector2(0,step.y),obstacles): player.y+=step.y
func update_camera(delta: float) -> void:
	if camera==null: return
	var target:=Vector3(-2,0.7,-2.5) if overview else Stage.point(player)+Vector3(0,0.9,0)
	camera_target=camera_target.lerp(target,1-exp(-delta*8)) if delta<1 else target
	var pitch:=deg_to_rad(35.264 if low_angle else 50.0)
	camera.position=camera_target+Vector3(cos(pitch)*0.70710678,sin(pitch),cos(pitch)*0.70710678)*30
	camera.look_at(camera_target,Vector3.UP)
	camera.size=maxf(32,28*stage.size.y/maxf(1,stage.size.x)) if overview else clampf(stage.size.y/35,16,20)
func attack() -> void:
	if overview or health<=0 or attack_left>0: return
	var best:=5.0; var target: Dictionary={}
	for enemy in enemies:
		var distance: float=enemy["pos"].distance_to(player)
		if enemy["hp"]>0 and distance<best: best=distance; target=enemy
	if not target.is_empty(): facing=player.direction_to(target["pos"])
	attack_left=0.38; attack_cycle+=1; sparring=true
	var reach:=2.1 if weapon=="spear" else 1.7
	for enemy in enemies:
		var offset: Vector2=enemy["pos"]-player
		if enemy["hp"]<=0 or offset.length()>reach or facing.dot(offset.normalized())<(0.85 if weapon=="spear" else 0.35): continue
		enemy["hp"]-=1; enemy["flash"]=0.12
		if enemy["hp"]<=0: enemy["node"].hide()
	var spark:=M.orb(world,Stage.point(player)+Vector3(facing.x*1.2,0.8,facing.y*1.2),Vector3(0.10,0.10,0.60) if weapon=="spear" else Vector3(1.0,0.035,0.17),"ffe2a1")
	spark.rotation.y=atan2(-facing.x,-facing.y); spark.material_override=M.material("ffe2a1",true); effects.append({"node":spark,"life":0.10})
func dash() -> void:
	if overview or health<=0 or dash_cooldown>0: return
	dash_left=0.14; dash_cooldown=0.8; dash_direction=motion_direction.normalized() if motion_direction.length()>0.01 else facing
	var ghost:=M.cylinder(world,Stage.point(player)+Vector3(0,0.8,0),0.35,1.3,"7abcb2",0.20)
	var mat:=M.material("7abcb2",true).duplicate(); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a=0.25; ghost.material_override=mat
	effects.append({"node":ghost,"life":0.20})
func update_enemies(delta: float) -> void:
	if not sparring: return
	for enemy in enemies:
		if enemy["hp"]<=0: continue
		enemy["timer"]-=delta; enemy["flash"]=maxf(0,enemy["flash"]-delta)
		var distance: float=enemy["pos"].distance_to(player)
		if enemy["phase"]=="warning":
			if enemy["timer"]<=0:
				if distance<1.6 and dash_left<=0 and hurt_left<=0: health=maxi(0,health-1); hurt_left=0.9
				enemy["phase"]="recover"; enemy["timer"]=0.9
		elif enemy["phase"]=="recover":
			if enemy["timer"]<=0: enemy["phase"]="idle"
		elif distance<1.3:
			enemy["phase"]="warning"; enemy["timer"]=0.65
		elif distance<5:
			var pos: Vector2=enemy["pos"]+enemy["pos"].direction_to(player)*delta*(1.1 if enemy["brute"] else 1.6)
			if not Stage.blocked(pos,obstacles,0.4): enemy["pos"]=pos
		var node: Node3D=enemy["node"]; node.position=Stage.point(enemy["pos"])
		node.rotation.y=atan2(player.x-enemy["pos"].x,player.y-enemy["pos"].y)+PI
		enemy["body"].scale.x=1+sin(clock*4)*0.035
		enemy["body"].material_override=M.material("e0a867" if enemy["phase"]=="warning" else ("d8d9af" if enemy["flash"]>0 else "405668"))
		node.position.y+=sin(clock*3+enemy["pos"].x)*0.06
func release_stick() -> void: pointer=-1; stick_position=stick_origin
func _input(event: InputEvent) -> void:
	# A second finger must reach action buttons while the first holds the floating stick.
	if event is InputEventScreenTouch:
		if event.pressed and attack_button.get_global_rect().has_point(event.position):
			attack_touch=event.index; attack_held=true; attack()
		elif not event.pressed and event.index==attack_touch: attack_touch=-1; attack_held=false
		if event.pressed and dash_button.get_global_rect().has_point(event.position): dash()
	if event is InputEventScreenTouch and not event.pressed and event.index==pointer: release_stick()
	elif event is InputEventScreenDrag and event.index==pointer: stick_position=event.position
	elif event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and pointer==-2: release_stick()
	elif event is InputEventMouseMotion and pointer==-2: stick_position=event.position
func _unhandled_input(event: InputEvent) -> void:
	if overview or health<=0: return
	if event is InputEventScreenTouch and event.pressed and pointer==-1 and stage.get_rect().has_point(event.position): pointer=event.index; stick_origin=event.position; stick_position=event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not DisplayServer.is_touchscreen_available() and stage.get_rect().has_point(event.position): pointer=-2; stick_origin=event.position; stick_position=event.position
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: release_stick(); attack_held=false; attack_touch=-1
func draw_stick() -> void:
	if pointer!=-1:
		joystick.draw_circle(stick_origin,46,Color(0.8,0.9,0.8,0.12)); joystick.draw_arc(stick_origin,46,0,TAU,32,Color("d4cf9e"),1)
		joystick.draw_circle(stick_origin+(stick_position-stick_origin).limit_length(43),15,Color("d8d5b0"))
func back() -> void:
	if OS.has_feature("web"): JavaScriptBridge.eval("{const u=new URL(location.href); u.searchParams.delete('iso_lab'); u.searchParams.delete('iso_probe'); history.replaceState(null,'',u);}")
	get_tree().change_scene_to_file.call_deferred("res://scenes/room.tscn")
