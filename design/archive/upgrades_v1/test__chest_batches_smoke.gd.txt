extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Menu = preload("res://scripts/hub_menu.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for kind in ["copper","silver","gold"]:
		for count in [1,10]:
			var cost: int = Hub.Economy.GEM_COST[kind] if count==1 else Hub.Economy.GEM_TEN_COST[kind]
			var h = Hub.new(false); h.keys[kind] = count-1; h.gems = cost-1
			var before: Dictionary = h.inventory.duplicate(true)
			var state: int = h.rng.state
			assert(h.chest_offer(kind,count)["payment"]=="gems")
			assert(h.open_chests(kind,count).is_empty() and h.inventory==before and h.keys[kind]==count-1 and h.gems==cost-1 and h.rng.state==state)
			h.gems = cost
			assert(h.open_chests(kind,count).size()==count and h.gems==0 and h.keys[kind]==count-1)
			h.keys[kind] = count; h.gems = cost
			assert(h.chest_offer(kind,count)["payment"]=="key")
			assert(h.open_chests(kind,count).size()==count and h.keys[kind]==0 and h.gems==cost)
		# A batch must exactly match ten separate openings, including pity crossing.
		var batch = Hub.new(false); var singles = Hub.new(false)
		for h in [batch,singles]: h.keys[kind] = 10; h.pity[kind] = 30; h.rng.seed = 8821
		var rewards: Array = batch.open_chests(kind,10)
		for i in range(10): assert(rewards[i]==singles.open_chest(kind))
		assert(batch.inventory==singles.inventory and batch.pity==singles.pity and batch.rng.state==singles.rng.state)
	var h = Hub.new(false); h.keys["gold"] = 9; h.gems = 2700; h.pity["gold"] = 34
	root.size = Vector2i(480,800)
	var menu = Menu.new(); root.add_child(menu); menu.setup(h); menu.select_tab(0)
	await process_frame
	assert(menu.chest_panels["gold"].position.y < menu.chest_panels["copper"].get_parent().position.y)
	assert(menu.chest_panels["copper"].position.x < menu.chest_panels["silver"].position.x)
	for kind in ["gold","copper","silver"]:
		var art = menu.chest_panels[kind].get_node("ChestArtwork")
		assert(art.get_rect().end.x <= menu.chest_panels[kind].size.x and art.get_rect().end.y <= menu.chest_panels[kind].size.y,"Artwork must fit its assigned panel")
	for key in menu.chest_buttons:
		var button: Button = menu.chest_buttons[key]
		assert(button.get_rect().end.x <= button.get_parent().size.x,"Opening buttons must fit their panels")
	assert(menu.chest_buttons["gold_1"].text=="Open 1\n1 key" and menu.chest_buttons["gold_10"].text=="Open 10\n2700 gems")
	assert(menu.chest_buttons["copper_1"].text=="Open 1\n80 gems" and menu.chest_buttons["silver_10"].text=="Open 10\n1350 gems")
	menu.chest_buttons["gold_10"].pressed.emit()
	await process_frame
	for node in menu.shop_grid.find_children("*","Button",true,false):
		if node.has_meta("reward_uid"):
			for child in node.get_children():
				if child is Label: assert(child.size.x <= 90,"Reward labels must wrap inside their cards")
	assert(menu.selected==0 and menu.last_chest_rewards.size()==10 and h.keys["gold"]==9 and h.gems==0)
	assert(h.inventory[menu.last_chest_rewards[0]]["rarity"]==4 and h.inventory[menu.last_chest_rewards[0]]["plus"]==1)
	assert(menu.chest_buttons["gold_10"].disabled)
	var before: int = h.inventory.size()
	menu.shop_scroll.suppress_until = Time.get_ticks_msec()+1000
	menu._open_chest_offer("gold",1)
	assert(h.inventory.size()==before and h.keys["gold"]==9,"A swipe must not spend keys")
	assert(h.open_chests("invalid",10).is_empty() and h.open_chests("gold",3).is_empty())
	var path := "user://chest-batch-test.json"
	h.storage_path = path; h.enabled = true; h.save()
	var restored = Hub.new(true,path)
	assert(restored.inventory==h.inventory and restored.keys==h.keys and restored.pity==h.pity and restored.gems==0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	menu.queue_free()
	print("PASS: chest quotes, 1/10 key thresholds, exact gem discounts, atomic rejection, batch pity equivalence, saved rewards, chest layout and swipe protection")
	quit()
