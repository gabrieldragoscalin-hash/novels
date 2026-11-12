extends PanelContainer
## Non-modal item information. Hover on desktop; tap/hold on touch, tap outside to dismiss.
signal changed
const HomeArt = preload("res://scripts/hub_art.gd")
var hub
var uid := ""
var anchor_rect := Rect2()
var touch_mode := false
var last_touch := -10000
var outside_age := 0.0
var column: VBoxContainer
func setup(model) -> void:
	hub = model; z_index = 25; name = "ItemPreview"
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("142b2b"); frame.border_color = Color("c4a46a")
	frame.set_border_width_all(2); frame.set_corner_radius_all(5)
	frame.shadow_color = Color(0,0,0,0.7); frame.shadow_size = 12
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: frame.set_content_margin(side,14)
	add_theme_stylebox_override("panel",frame)
	column = VBoxContainer.new(); column.add_theme_constant_override("separation",9); add_child(column)
	hide()
func note(text: String, font_size: int = 13, color := Color("d1d9ca")) -> Label:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color)
	label.custom_minimum_size.x = 252; label.size.x = 252
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; column.add_child(label); return label
func action(text: String, disabled: bool, callback: Callable) -> void:
	var button := Button.new(); button.text = text; button.disabled = disabled; button.custom_minimum_size.y = 42
	var style := StyleBoxFlat.new(); style.bg_color = Color("29443d"); style.border_color = Color("9d8456"); style.set_border_width_all(1); style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal",style); button.pressed.connect(callback); column.add_child(button)
func open(item_id: String, bounds: Rect2, touch := false) -> void:
	if not hub.inventory.has(item_id): hide(); return
	uid = item_id; anchor_rect = bounds; touch_mode = touch; outside_age = 0
	for child in column.get_children(): column.remove_child(child); child.queue_free()
	var item: Dictionary = hub.inventory[uid]
	var kind: String = item["type"]
	var slot: String = hub.Equipment.ITEMS[kind]["slot"]
	var category: String = hub.Economy.part_for(slot)
	var heading := note(hub.item_name(uid),19,hub.Economy.COLORS[item["rarity"]]); heading.add_theme_font_override("font",HomeArt.SERIF)
	note("%s  •  LEVEL %d" % [slot.to_upper(),item["level"]],11,Color("dfbd78"))
	note(hub.Equipment.ITEMS[kind]["description"])
	note(hub.Equipment.instance_summary(item),14,Color("f0e5ca"))
	note("%d %s parts available" % [hub.parts[category],category],11)
	var equipped: bool = hub.equipped[slot] == uid
	action("Equipped" if equipped else "Equip",equipped,_equip)
	action("Maximum level" if item["level"] >= hub.Equipment.MAX_LEVEL else "Level up · %d parts" % hub.upgrade_cost(uid),item["level"] >= hub.Equipment.MAX_LEVEL or hub.parts[category] < hub.upgrade_cost(uid),_upgrade)
	if equipped and slot != "weapon": action("Unequip",false,_unequip)
	custom_minimum_size.x = 280; size = Vector2(280,0)
	show(); _place.call_deferred()
func _place() -> void:
	# Wrapped labels need their final width before their height is measured.
	await get_tree().process_frame
	if not is_inside_tree() or not visible: return
	reset_size()
	var view := get_viewport_rect().size
	var x := anchor_rect.end.x + 8
	if x + size.x > view.x - 12: x = anchor_rect.position.x - size.x - 8
	x = clampf(x,12,maxf(12,view.x-size.x-12))
	# Above the touched item leaves its neighbours available to swipe.
	var y := anchor_rect.position.y - size.y - 8 if touch_mode else anchor_rect.position.y
	global_position = Vector2(x,clampf(y,12,maxf(12,view.y-size.y-108)))
func _equip() -> void:
	if hub.equip_item(uid): changed.emit(); open(uid,anchor_rect,touch_mode)
func _upgrade() -> void:
	if hub.upgrade(uid): changed.emit(); open(uid,anchor_rect,touch_mode)
func _unequip() -> void:
	if hub.unequip(hub.Equipment.ITEMS[hub.item_type(uid)]["slot"]): changed.emit(); open(uid,anchor_rect,touch_mode)
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch = Time.get_ticks_msec()
		if event.pressed and visible and not get_global_rect().has_point(event.position): hide()
	elif event is InputEventMouseButton and event.pressed and visible:
		if not get_global_rect().has_point(event.position) and not anchor_rect.has_point(event.position): hide()
	elif event.is_action_pressed("ui_cancel"): hide()
func _process(delta: float) -> void:
	if not visible or touch_mode: return
	var point := get_global_mouse_position()
	if get_global_rect().grow(8).has_point(point) or anchor_rect.grow(8).has_point(point): outside_age = 0
	else:
		outside_age += delta
		if outside_age > 0.2: hide()
