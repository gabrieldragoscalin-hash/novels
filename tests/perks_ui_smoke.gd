extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Visuals = preload("res://scripts/perk_visuals.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(480,800)
	var room = load("res://scenes/room.tscn").instantiate(); root.add_child(room)
	room.hub = Hub.new(false); room.hub.coins = 1000000; room._refresh_hub()
	var menu = room.hub_menu; menu.select_tab(3)
	var page = menu.perk_page
	assert(page.cards.size()==12 and Visuals.ICONS.size()==12)
	for id in page.cards:
		assert(page.cards[id].locked and page.cards[id].caption.text=="Locked" and page.cards[id].star_count()==0)
	page.show_preview("starting_hp",Rect2(),true); assert(not page.preview.visible)
	var coins: int = room.hub.coins
	page.obtain_button.pressed.emit()
	assert(room.hub.perks["starting_upgrade"]==1 and room.hub.coins==coins-250)
	assert(page.reveal.busy and page.reveal.phase=="locked" and page.obtain_button.disabled)
	menu.perk_requested.emit(); assert(room.hub.coins==coins-250 and room.hub.perk_purchases==1,"Animation must block duplicate purchases")
	await create_timer(0.6).timeout
	assert(page.reveal.phase=="flipping" and page.reveal.left_card.scale.x<1)
	await create_timer(0.6).timeout
	assert(not page.reveal.left_card.locked and page.reveal.left_card.star_count()==1 and page.reveal.description.text==Visuals.effect("starting_upgrade",1))
	await create_timer(2.2).timeout
	assert(not page.reveal.busy and not page.obtain_button.disabled)
	for id in room.hub.perks: room.hub.perks[id] = room.hub.PERK_CAPS[id]
	room.hub.perks["starting_hp"] = 24; room.hub.perk_purchases = room.hub._perk_total(); room._refresh_hub()
	var cost: int = room.hub.perk_price(); coins = room.hub.coins
	page.obtain_button.pressed.emit()
	assert(room.hub.perks["starting_hp"]==25 and room.hub.coins==coins-cost)
	assert(page.reveal.phase=="merging" and page.reveal.left_card.star_count()==24 and page.reveal.right_card.star_count()==1)
	assert(page.reveal.left_card.position.x<page.reveal.right_card.position.x)
	await create_timer(1.8).timeout
	assert(page.reveal.left_card.star_count()==25 and not page.reveal.right_card.visible)
	assert(page.reveal.description.text=="Starting HP +25")
	assert(is_equal_approx(page.reveal.left_card.position.x+92,240))
	await create_timer(2.3).timeout
	assert(not page.reveal.busy and page.obtain_button.disabled)
	page.show_preview("starting_hp",Rect2(),true)
	await process_frame
	await process_frame
	assert(page.preview.visible and page.preview_effect.text=="Starting HP +25" and page.preview.size.y<240)
	menu.select_tab(2); assert(not page.preview.visible)
	assert(Visuals.effect("resourceful",3)=="Dungeon shop prices −1.5%")
	assert(Visuals.effect("treasure_sense",25)=="Loot equipment chance +5.0%")
	room.queue_free()
	print("PASS: twelve sealed cards/icons, unlock flip, duplicate purchase guard, star-by-star merge to 25, current-value hover, compact preview and maximum cap")
	quit()
