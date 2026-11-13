extends Control
signal selected(index: int)
const Card = preload("res://scripts/upgrade_card.gd")
const Icons = preload("res://scripts/upgrade_art.gd")
const HomeArt = preload("res://scripts/hub_art.gd")
var phase := "idle"
var elapsed := 0.0
var slow_duration := 0.45
var offer_ids: Array = []
var cards: Array[Button] = []
var pool: Array = []
var title_label: Label
var hint: Label
var veil := 0.0
var committed := false
func setup() -> void:
	# Warm glyph textures during loading, not on the first level-up frame.
	for id in Icons.SHAPES: Icons.texture(id)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mouse_filter = Control.MOUSE_FILTER_STOP; z_index = 20
	title_label = Label.new(); title_label.add_theme_font_override("font",HomeArt.SERIF); title_label.add_theme_font_size_override("font_size",22); title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(title_label)
	title_label.position = Vector2(10,167); title_label.size = Vector2(460,36)
	hint = Label.new(); hint.position = Vector2(16,620); hint.size = Vector2(448,36); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_font_size_override("font_size",12); hint.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hint)
	var hint_bg := StyleBoxFlat.new(); hint_bg.bg_color = Color(0.035,0.1,0.075,0.92); hint_bg.set_corner_radius_all(5)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: hint_bg.set_content_margin(side,6)
	hint.add_theme_stylebox_override("normal",hint_bg)
	for index in range(3):
		var card = Card.new(); card.size = Vector2(132,288); card.pressed.connect(_select.bind(index)); add_child(card); cards.append(card)
	hide()
	visibility_changed.connect(func():
		if not visible: phase = "idle")
func entry(progression, id: String) -> Dictionary:
	if id=="coins": return {"id":id,"title":"%d coins" % progression.coin_reward(),"description":"Keep currency instead of an upgrade","icon":Icons.texture("coins"),"badge":"COINS"}
	var info: Array = progression.upgrade_info(id)
	var glyph: String = {"Meteor Size":"meteor_size","Meteor Rain":"meteor_rain","Telekinesis":"telekinesis"}.get(info[0],id)
	return {"id":id,"title":str(info[0]).replace(" • RARE",""),"description":info[1],"icon":Icons.texture(glyph),"badge":"RARE" if id=="second_chance" else "UPGRADE"}
func present(progression, title: String, slow: bool) -> void:
	phase = "slowing" if slow else "rolling"; slow_duration = 0.45 if slow else 0.0
	elapsed = 0; committed = false; veil = 0; offer_ids = progression.offers.duplicate(); pool.clear()
	for id in progression.available_upgrades(): pool.append(entry(progression,id))
	if offer_ids.has("coins"): pool.append(entry(progression,"coins"))
	if pool.is_empty():
		for id in offer_ids: pool.append(entry(progression,id))
	title_label.text = title; hint.text = "Your blessings are taking shape…"
	for index in range(3):
		cards[index].visible = index<offer_ids.size()
		if index<offer_ids.size(): cards[index].prepare(entry(progression,offer_ids[index]),Vector2((480-(offer_ids.size()*132+(offer_ids.size()-1)*12))/2+index*144,219))
		cards[index].modulate.a = 0; cards[index].disabled = true
	title_label.modulate.a = 0; hint.modulate.a = 0; show(); queue_redraw()
func slowing() -> bool: return visible and phase=="slowing"
func world_speed() -> float:
	return lerpf(0.65,0.15,clampf(elapsed/0.45,0,1)) if slowing() else 0.0
func ready_for_choice() -> bool: return visible and phase=="ready"
func accept(index: int) -> bool:
	if not visible or phase not in ["ready","chosen"] or committed or index<0 or index>=offer_ids.size(): return false
	committed = true; phase = "committed"
	for card in cards: card.disabled = true
	return true
func _select(index: int) -> void:
	if not ready_for_choice(): return
	phase = "selecting"
	for card in cards: card.disabled = true
	var tween := create_tween(); tween.tween_property(cards[index],"modulate",Color("fff1c6"),0.12)
	tween.tween_callback(func():
		if visible and phase=="selecting": phase = "chosen"; selected.emit(index))
func _process(delta: float) -> void:
	if not visible: return
	elapsed += delta
	if phase=="slowing" and elapsed>=slow_duration: phase = "rolling"
	veil = minf(0.32,elapsed*0.5)
	var reveal_time := elapsed-slow_duration
	title_label.modulate.a = clampf(reveal_time/0.18,0,1); hint.modulate.a = title_label.modulate.a
	if phase=="rolling":
		for index in range(offer_ids.size()): cards[index].roll(reveal_time,index*0.12,pool)
		if reveal_time>=0.94+(offer_ids.size()-1)*0.12+0.12:
			phase = "ready"; hint.text = "Choose one blessing · combat is paused"
			for index in range(offer_ids.size()): cards[index].disabled = false
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color(0.012,0.035,0.027,veil))
