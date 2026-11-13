extends Control
signal obtain_requested
const HomeArt = preload("res://scripts/hub_art.gd")
const Card = preload("res://scripts/perk_card.gd")
const Visuals = preload("res://scripts/perk_visuals.gd")
const Reveal = preload("res://scripts/perk_reveal.gd")
const Swipe = preload("res://scripts/swipe_scroll.gd")
var hub
var grid: GridContainer
var scroll
var wallet: Label
var guidance: Label
var price: Label
var obtain_button: Button
var cards: Dictionary = {}
var reveal
var preview: PanelContainer
var preview_title: Label
var preview_effect: Label
var preview_note: Label
var anchor := Rect2()
var touch_preview := false
var last_touch := -10000
var outside_age := 0.0
var hold_id := ""
var hold_age := 0.0
func setup(model, overlay_parent: Control) -> void:
	hub = model; mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new(); title.text = "BLESSINGS"; title.position = Vector2(24,18)
	title.add_theme_font_override("font",HomeArt.SERIF); title.add_theme_font_size_override("font_size",24); title.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(title)
	wallet = _label(self,Vector2(24,53),11,Color("dfbd78"))
	guidance = _label(self,Vector2(24,71),10,Color("9bad9e"))
	scroll = Swipe.new(); scroll.position = Vector2(24,97); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; add_child(scroll)
	grid = GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation",10); grid.add_theme_constant_override("v_separation",10); scroll.add_child(grid)
	for id in hub.PERK_NAMES:
		var card = Card.new(); card.name = "Perk_"+id; card.custom_minimum_size = Vector2(132,132); grid.add_child(card); cards[id] = card
		card.mouse_entered.connect(func():
			if Time.get_ticks_msec()-last_touch>1000 and not scroll.suppress_click(): show_preview(id,card.get_global_rect()))
		card.gui_input.connect(_card_input.bind(id))
	obtain_button = Button.new(); obtain_button.name = "Obtain"; obtain_button.text = "Obtain"; obtain_button.size = Vector2(364,50)
	obtain_button.add_theme_font_override("font",HomeArt.SERIF); obtain_button.add_theme_font_size_override("font_size",20)
	var style := StyleBoxFlat.new(); style.bg_color = Color("29483b"); style.border_color = Color("c4a66b"); style.set_border_width_all(2); style.set_corner_radius_all(7)
	obtain_button.add_theme_stylebox_override("normal",style)
	obtain_button.pressed.connect(func():
		if not reveal.busy and hub.can_buy_perk(): preview.hide(); obtain_requested.emit())
	add_child(obtain_button)
	price = _label(self,Vector2.ZERO,13,Color("e6cc93")); price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; price.size.x = 432
	reveal = Reveal.new(); overlay_parent.add_child(reveal); reveal.setup(); reveal.finished.connect(refresh)
	preview = PanelContainer.new(); preview.name = "PerkPreview"; preview.z_index = 50; overlay_parent.add_child(preview)
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("142b2b"); frame.border_color = Color("bfa36a"); frame.set_border_width_all(2); frame.set_corner_radius_all(5)
	frame.shadow_color = Color(0,0,0,0.6); frame.shadow_size = 10
	for edge in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: frame.set_content_margin(edge,14)
	preview.add_theme_stylebox_override("panel",frame)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",8); preview.add_child(column)
	preview_title = _label(column,Vector2.ZERO,18,Color("eddaaf")); preview_title.add_theme_font_override("font",HomeArt.SERIF)
	preview_effect = _label(column,Vector2.ZERO,15,Color("f1d68d"))
	preview_note = _label(column,Vector2.ZERO,11,Color("a3b6a5"))
	for label in [preview_title,preview_effect,preview_note]: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size.x = 252
	preview.hide(); scroll.swipe_started.connect(func(): preview.hide(); hold_id = "")
	layout(Vector2(480,get_viewport_rect().size.y-94)); refresh()
func _label(parent: Node, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new(); label.position = pos; label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color); label.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(label); return label
func set_model(model) -> void:
	if hub != model: reveal.cancel(); preview.hide()
	hub = model; refresh()
func layout(dimensions: Vector2) -> void:
	size = dimensions
	var height := clampf((size.y-204-30)/4,116,176)
	for card in cards.values(): card.custom_minimum_size.y = height
	scroll.size = Vector2(432,maxf(240,size.y-204))
	price.position = Vector2(24,size.y-87)
	obtain_button.position = Vector2(58,size.y-62)
	preview.hide()
func refresh() -> void:
	if hub == null or obtain_button==null: return
	var locked_count := 0
	for id in cards:
		cards[id].configure(id,hub.PERK_NAMES[id],hub.perks[id])
		if hub.perks[id]==0: locked_count += 1
	wallet.text = "%s coins" % str(hub.coins)
	guidance.text = "Unlock all twelve blessings before leveling · %d remain" % locked_count if locked_count>0 else "Your blessings endure between expeditions"
	price.text = "%d coins" % hub.perk_price()
	var capped := true
	for id in cards:
		if hub.perks[id]<hub.PERK_CAPS[id]: capped = false
	if capped: price.text = "All blessings fully empowered"
	obtain_button.disabled = reveal.busy or not hub.can_buy_perk()
	queue_redraw()
func present(id: String, before: int) -> void:
	preview.hide(); hold_id = ""; reveal.play(id,hub.PERK_NAMES[id],before,hub.perks[id]); obtain_button.disabled = true
func deactivate() -> void:
	preview.hide(); hold_id = ""; reveal.cancel()
func show_preview(id: String, bounds := Rect2(), touch := false) -> void:
	if reveal.busy or hub.perks.get(id,0)==0 or not is_visible_in_tree(): return
	anchor = cards[id].get_global_rect() if bounds.size==Vector2.ZERO else bounds
	touch_preview = touch; outside_age = 0
	preview_title.text = hub.PERK_NAMES[id]; preview_effect.text = Visuals.effect(id,hub.perks[id])
	preview_note.text = "Maximum blessing" if hub.perks[id]>=hub.PERK_CAPS[id] else "Next: "+Visuals.effect(id,hub.perks[id]+1)
	if id=="scavenger": preview_note.text += "\nExcludes coin cards and purchases."
	preview.size = Vector2(280,0); preview.show(); _place_preview.call_deferred()
func _place_preview() -> void:
	await get_tree().process_frame
	if not preview.visible: return
	preview.reset_size()
	var view := get_viewport_rect().size
	var x := anchor.end.x+8
	if x+preview.size.x>view.x-12: x = anchor.position.x-preview.size.x-8
	var y := anchor.position.y-preview.size.y-8 if touch_preview else anchor.position.y
	preview.global_position = Vector2(clampf(x,12,view.x-preview.size.x-12),clampf(y,12,maxf(12,view.y-preview.size.y-110)))
func _card_input(event: InputEvent, id: String) -> void:
	if event is InputEventScreenTouch:
		if event.pressed: hold_id = id; hold_age = 0
		else:
			hold_id = ""
			if not scroll.suppress_click(): show_preview(id,cards[id].get_global_rect(),true)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		if not scroll.suppress_click(): show_preview(id,cards[id].get_global_rect(),Time.get_ticks_msec()-last_touch<1000)
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch = Time.get_ticks_msec()
		if event.pressed and preview.visible and not preview.get_global_rect().has_point(event.position): preview.hide()
	elif event is InputEventMouseButton and event.pressed and preview.visible:
		if not preview.get_global_rect().has_point(event.position) and not anchor.has_point(event.position): preview.hide()
	if event.is_action_pressed("ui_cancel"): preview.hide()
func _process(delta: float) -> void:
	if not is_visible_in_tree(): preview.hide(); hold_id = ""; return
	if not hold_id.is_empty():
		hold_age += delta
		if hold_age>=0.4: show_preview(hold_id,cards[hold_id].get_global_rect(),true); hold_id = ""
	if preview.visible and not touch_preview:
		var point := get_global_mouse_position()
		if preview.get_global_rect().grow(8).has_point(point) or anchor.grow(8).has_point(point): outside_age = 0
		else:
			outside_age += delta
			if outside_age>0.2: preview.hide()
