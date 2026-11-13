extends Control
signal finished
const Card = preload("res://scripts/perk_card.gd")
const Visuals = preload("res://scripts/perk_visuals.gd")
const HomeArt = preload("res://scripts/hub_art.gd")
var busy := false
var phase := "idle"
var left_card
var right_card
var heading: Label
var description: Label
var tween: Tween
var glow := 0.0
var card_size := Vector2(184,244)
func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); z_index = 60; mouse_filter = Control.MOUSE_FILTER_STOP
	left_card = Card.new(); right_card = Card.new(); add_child(left_card); add_child(right_card)
	for card in [left_card,right_card]: card.size = card_size; card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading = Label.new(); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font",HomeArt.SERIF); heading.add_theme_font_size_override("font_size",24); heading.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(heading)
	description = Label.new(); description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; description.add_theme_font_size_override("font_size",18)
	description.add_theme_color_override("font_color",Color("f0d89c")); description.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(description)
	resized.connect(func():
		if busy: cancel())
	hide()
func play(id: String, title: String, before: int, after: int) -> void:
	cancel(false)
	busy = true; show(); modulate = Color.WHITE; glow = 0
	var view := get_viewport_rect().size
	var center := Vector2(view.x/2-card_size.x/2,maxf(118,view.y/2-150))
	heading.text = "A BLESSING AWAKENS" if before==0 else "A BLESSING GROWS"
	heading.position = Vector2(view.x/2-220,center.y-67); heading.size = Vector2(440,40)
	description.position = Vector2(view.x/2-208,center.y+card_size.y+26); description.size = Vector2(416,80)
	description.text = Visuals.effect(id,after); description.modulate.a = 0
	left_card.scale = Vector2.ONE; left_card.rotation = 0; left_card.modulate = Color.WHITE
	right_card.scale = Vector2.ONE; right_card.rotation = 0; right_card.modulate = Color.WHITE
	left_card.configure(id,title,before,before==0,true)
	left_card.position = center
	right_card.hide()
	tween = create_tween()
	if before==0:
		phase = "locked"
		tween.tween_interval(0.3)
		tween.tween_callback(func(): phase = "flipping")
		tween.tween_property(left_card,"scale:x",0.025,0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(left_card,"rotation",-0.08,0.45)
		tween.parallel().tween_property(description,"modulate:a",1.0,0.4)
		tween.tween_callback(func(): left_card.configure(id,title,after,false,true); phase = "revealing")
		tween.tween_property(left_card,"scale:x",1.0,0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(left_card,"rotation",0.0,0.5)
	else:
		phase = "merging"
		left_card.position = center+Vector2(-106,0)
		right_card.configure(id,title,1,false,true); right_card.position = center+Vector2(106,0); right_card.show()
		tween.tween_interval(0.85)
		tween.tween_property(left_card,"position",center,0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(right_card,"position",center,0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(right_card,"modulate:a",0.0,0.7)
		tween.tween_callback(func(): right_card.hide(); left_card.configure(id,title,after,false,true); glow = 1)
		tween.tween_property(description,"modulate:a",1.0,0.35)
		tween.parallel().tween_property(self,"glow",0.0,0.5)
	tween.tween_callback(func(): phase = "result")
	tween.tween_interval(1.65)
	tween.tween_property(self,"modulate:a",0.0,0.25)
	tween.tween_callback(cancel)
func cancel(emit_signal := true) -> void:
	var was_busy := busy
	busy = false; phase = "idle"; hide()
	if tween != null and tween.is_valid(): tween.kill()
	if was_busy and emit_signal: finished.emit()
func _process(_delta: float) -> void:
	if visible: queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color(0.018,0.055,0.047,0.96))
	var center := get_viewport_rect().size/2+Vector2(0,-28)
	draw_circle(center,210,Color(0.15,0.3,0.2,0.12+glow*0.12))
	for radius in [210,222]: draw_arc(center,radius,0,TAU,100,Color(0.62,0.52,0.3,0.18+glow*0.3),1)
