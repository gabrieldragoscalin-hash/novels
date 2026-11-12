extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Menu = preload("res://scripts/hub_menu.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(480,800)
	var h = Hub.new(false)
	var target: String = h._add_item("vest",2,0,1)
	h.parts["armor"] = 50
	for i in range(40): h._add_item("bow",0,0,1)
	var menu = Menu.new(); root.add_child(menu); menu.setup(h)
	for index in [0,1,3,4]:
		menu.select_tab(index)
		assert(not menu.player_button.visible and not menu.battlepass_button.visible and not menu.resource_label.visible and not menu.profile_name.visible)
	menu.select_tab(2)
	assert(menu.player_button.visible and menu.battlepass_button.visible)
	menu.select_tab(1)
	for button in menu.future_buttons.values():
		for child in button.get_children(): assert(not child is Label,"Locked slots must have no captions")
	await process_frame
	await process_frame
	menu.item_preview.open(target,Rect2(30,500,98,112),true)
	await process_frame
	await process_frame
	assert(menu.item_preview.visible and menu.item_preview.size.y < 450,"Item previews must remain compact")
	menu.item_preview._equip()
	assert(h.equipped["armor"] == target and menu.item_preview.visible)
	menu.item_preview._upgrade()
	assert(h.inventory[target]["level"] == 2 and h.parts["armor"] == 45)
	menu.item_preview._unequip(); assert(h.equipped["armor"].is_empty())
	menu.item_preview.hide()
	menu._item_clicked(target)
	assert(menu.item_preview.visible,"Items remain inspectable after inventory refresh")
	var scroll = menu.inventory_scroll
	var point: Vector2 = scroll.get_global_rect().position + Vector2(50,100)
	var touch := InputEventScreenTouch.new(); touch.index = 0; touch.position = point; touch.pressed = true
	scroll._input(touch)
	var drag := InputEventScreenDrag.new(); drag.index = 0; drag.position = point-Vector2(0,80)
	scroll._input(drag)
	assert(scroll.scroll_vertical == 80 and scroll.suppress_click())
	assert(not menu.item_preview.visible,"Swiping dismisses previews")
	touch.pressed = false; touch.position = drag.position; scroll._input(touch)
	menu._item_clicked(target)
	assert(not menu.item_preview.visible,"Swiping must not open item details")
	menu.select_tab(2); assert(not menu.item_preview.visible)
	menu.queue_free()
	print("PASS: isolated menu headers, text-free sealed slots, preview equip/upgrade/unequip, swipe scrolling and accidental-tap suppression")
	quit()
