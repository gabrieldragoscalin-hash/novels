extends Control
const RIG = preload("res://prototypes/animation_lab/generated/shared_champion.tscn")
const FLOOR: Texture2D = preload("res://art/rooms/00_quiet_sanctuary.png")
var rigs: Array[Node2D] = []
var content: Control
var stage_bottom := 515.0
var zoom := 1.0
var weapon := "sun_bow"
var direction := "side"
var paused := false
var walking := false
var phase_slider: HSlider
var status: Label
var time_label: Label
var weapon_buttons := {}
var direction_buttons := {}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = Control.new(); add_child(content)
	label("ANIMATION LAB",Vector2(20,16),22)
	button("Hub",Vector2(386,12),Vector2(74,36),back_to_hub)
	label("Two skins • one skeleton • shared animation clips",Vector2(20,52),12)
	label("Reference: side view. Front/back art is provisional.",Vector2(20,72),11,Color("cdbb91"))
	for i in range(3):
		var id: String = ["sun_bow","moon_bow","hammer"][i]
		weapon_buttons[id] = button(["Sun bow","Moon bow","Hammer"][i],Vector2(20+i*150,102),Vector2(140,38),func(): weapon=id; reconfigure())
	for i in range(4):
		var id: String = ["front","back","side","left"][i]
		direction_buttons[id] = button(["Front","Back","Right","Left"][i],Vector2(20+i*113,150),Vector2(104,36),func(): direction=id; reconfigure())
	for id in ["aster","guard"]:
		var rig = RIG.instantiate(); content.add_child(rig); rig.configure(id,weapon,direction); rigs.append(rig)
	label("ASTER",Vector2(95,478),13)
	label("TEST SKIN",Vector2(306,478),13)
	button("Attack / hold",Vector2(20,532),Vector2(140,40),func():
		for rig in rigs: rig.attacking = not rig.attacking)
	button("Walk / stand",Vector2(170,532),Vector2(140,40),func(): walking=not walking; sync_flags())
	button("Pause / play",Vector2(320,532),Vector2(140,40),func(): paused=not paused; sync_flags())
	label("SCRUB THE ATTACK",Vector2(20,588),11)
	phase_slider = HSlider.new(); phase_slider.min_value = 0; phase_slider.max_value = 1000; phase_slider.step = 1
	phase_slider.position = Vector2(20,612); phase_slider.size = Vector2(440,35); content.add_child(phase_slider)
	phase_slider.drag_started.connect(func(): paused=true; sync_flags())
	phase_slider.value_changed.connect(func(value):
		if paused:
			for rig in rigs: rig.seek_phase(value/1000.0))
	button("Game size",Vector2(20,662),Vector2(140,38),func(): zoom=0.44; layout())
	button("Inspect size",Vector2(170,662),Vector2(140,38),func(): zoom=1.0; layout())
	button("Grip markers",Vector2(320,662),Vector2(140,38),func():
		for rig in rigs: rig.debug_contacts=not rig.debug_contacts)
	status = label("",Vector2(20,717),12)
	time_label = label("Clips and bone hierarchy are editable in Godot.",Vector2(20,746),11,Color("9eafb0"))
	resized.connect(layout); layout(); reconfigure()
	if OS.has_feature("web"):
		# Test parameters are read separately because JavaScript dictionaries are handles.
		var selected: String = JavaScriptBridge.eval("new URLSearchParams(location.search).get('weapon') || 'sun_bow'")
		var facing: String = JavaScriptBridge.eval("new URLSearchParams(location.search).get('direction') || 'side'")
		var phase: String = JavaScriptBridge.eval("new URLSearchParams(location.search).get('pose') || ''")
		if weapon_buttons.has(selected): weapon=selected
		if direction_buttons.has(facing): direction=facing
		reconfigure()
		if not phase.is_empty(): paused=true; sync_flags(); phase_slider.value=float(phase)*1000
func label(text: String,pos: Vector2,size_value: int,color := Color("eee0bd")) -> Label:
	var node := Label.new(); node.text=text; node.position=pos
	node.add_theme_font_size_override("font_size",size_value); node.add_theme_color_override("font_color",color)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE; content.add_child(node); return node
func button(text: String,pos: Vector2,dimensions: Vector2,action: Callable) -> Button:
	var node := Button.new(); node.text=text; node.position=pos; node.size=dimensions
	node.add_theme_font_size_override("font_size",12)
	var style := StyleBoxFlat.new(); style.bg_color=Color("18353a"); style.border_color=Color("9a8356"); style.set_border_width_all(1); style.set_corner_radius_all(6)
	node.add_theme_stylebox_override("normal",style); node.pressed.connect(action); content.add_child(node); return node
func sync_flags() -> void:
	for rig in rigs: rig.paused=paused; rig.walking=walking
func reconfigure() -> void:
	for i in range(rigs.size()): rigs[i].configure("aster" if i==0 else "guard",weapon,direction)
	for id in weapon_buttons: weapon_buttons[id].modulate=Color("ffe5a6") if id==weapon else Color.WHITE
	for id in direction_buttons: direction_buttons[id].modulate=Color("ffe5a6") if id==direction else Color.WHITE
func layout() -> void:
	content.position=Vector2((get_viewport_rect().size.x-480)/2,0); content.size=Vector2(480,get_viewport_rect().size.y)
	for i in range(rigs.size()): rigs[i].position=Vector2(128+i*210,450); rigs[i].scale=Vector2.ONE*zoom
	queue_redraw()
func _process(_delta: float) -> void:
	if rigs.is_empty() or status==null: return
	if not paused: phase_slider.set_value_no_signal(rigs[0].pose_time*1000)
	status.text="%s • support grip error %.2f px / %.2f px" % ["PAUSED" if paused else "PLAYING",rigs[0].grip_error,rigs[1].grip_error]
func _draw() -> void:
	var view := get_viewport_rect().size; var left := (view.x-480)/2
	draw_rect(Rect2(Vector2.ZERO,view),Color("0b1c23"))
	draw_texture_rect_region(FLOOR,Rect2(left+20,201,440,306),Rect2(FLOOR.get_size()*Vector2(0.07,0.17),FLOOR.get_size()*Vector2(0.86,0.66)),Color(0.7,0.75,0.76))
	for i in range(2):
		draw_set_transform(Vector2(left+128+i*210,451),0,Vector2(1,0.3))
		draw_circle(Vector2.ZERO,31*zoom,Color(0,0,0,0.3))
	draw_set_transform(Vector2.ZERO)

func back_to_hub() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{const u=new URL(location.href);for(const key of ['animation_lab','weapon','direction','pose'])u.searchParams.delete(key);history.replaceState({},'',u.toString());})()")
	get_tree().change_scene_to_file.call_deferred("res://scenes/room.tscn")
