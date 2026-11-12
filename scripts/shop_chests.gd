extends RefCounted
## Sanctuary chest display. Showcase items are illustrative, never guaranteed drops.
const ART := {"gold":preload("res://art/shop/gold_chest.svg"),"copper":preload("res://art/shop/copper_chest.svg"),"silver":preload("res://art/shop/silver_chest.svg")}
const COLORS := {"gold":Color("d4b56c"),"copper":Color("b98163"),"silver":Color("a2c2bd")}
static func panel(menu, parent: Node, kind: String, dimensions: Vector2) -> Panel:
	var card := Panel.new(); card.name = kind.capitalize()+"Chest"; card.custom_minimum_size = dimensions
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel",menu._style(Color("142d29"),COLORS[kind],2))
	parent.add_child(card); menu.chest_panels[kind] = card
	var title: Label = menu._label(card,kind.to_upper()+" CHEST",Vector2(12,10),18 if kind=="gold" else 14,COLORS[kind])
	title.add_theme_font_override("font",menu.HomeArt.SERIF)
	return card
static func image(parent: Node, kind: String, bounds: Rect2) -> void:
	var art := TextureRect.new(); art.name = "ChestArtwork"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = ART[kind]; art.position = bounds.position; art.size = bounds.size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(art)
static func opening(menu, card: Panel, kind: String, count: int, bounds: Rect2) -> void:
	var offer: Dictionary = menu.hub.chest_offer(kind,count)
	var cost: String = "%d %s" % [offer["cost"],("key" if count==1 else "keys") if offer["payment"]=="key" else "gems"]
	var button: Button = menu._button(card,"Open %d\n%s" % [count,cost],bounds.position,bounds.size,menu._open_chest_offer.bind(kind,count))
	button.name = "Open%d" % count; button.add_theme_font_size_override("font_size",12 if kind=="gold" else 10)
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.tooltip_text = "Uses %d %s keys" % [count,kind] if offer["payment"]=="key" else "Uses %d gems; keeps your %d %s keys" % [offer["cost"],menu.hub.keys[kind],kind]
	button.disabled = not offer["affordable"]
	button.add_theme_stylebox_override("normal",menu._style(Color("29443a"),COLORS[kind]))
	button.size = bounds.size
	menu.chest_buttons["%s_%d" % [kind,count]] = button
static func build(menu, parent: VBoxContainer) -> void:
	menu.chest_panels.clear(); menu.chest_buttons.clear()
	var gold := panel(menu,parent,"gold",Vector2(418,292))
	image(gold,"gold",Rect2(3,38,213,173))
	var hint: Label = menu._label(gold,"POSSIBLE LEGENDARY ITEMS",Vector2(224,41),9,Color("dbc18b"))
	hint.tooltip_text = "Illustrative placeholders. Gold chests can drop common through legendary equipment."
	for index in range(6):
		var tile := Panel.new(); tile.position = Vector2(229+(index%3)*57,65+int(index/3)*58); tile.size = Vector2(49,49)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE; tile.add_theme_stylebox_override("panel",menu._style(Color("20372d"),Color("af9757")))
		gold.add_child(tile); menu._icon(tile,["sword","vest","ring","wand","hood","charm"][index],Vector2(5,5),Vector2(39,39))
	menu._label(gold,"Legendary +1 guarantee in ≤%d" % (35-menu.hub.pity["gold"]),Vector2(12,205),11,Color("dfbd78"))
	opening(menu,gold,"gold",1,Rect2(12,230,192,49))
	opening(menu,gold,"gold",10,Rect2(214,230,192,49))
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",10); parent.add_child(row)
	for kind in ["copper","silver"]:
		var card := panel(menu,row,kind,Vector2(204,220))
		image(card,kind,Rect2(0,45,128,145))
		opening(menu,card,kind,1,Rect2(128,58,70,56))
		opening(menu,card,kind,10,Rect2(128,124,70,56))
		menu._label(card,"%s in ≤%d" % ["Epic" if kind=="copper" else "Legendary",35-menu.hub.pity[kind]],Vector2(10,193),10,COLORS[kind])
		card.tooltip_text = "Drop odds: "+str(menu.hub.Economy.ODDS[kind])+" (common, uncommon, rare, epic, legendary)"
	var odds: Label = menu._label(parent,"",Vector2.ZERO,10,Color("a5b9aa"))
	odds.text = "DROP RATES · common / uncommon / rare / epic / legendary"
	for kind in ["copper","silver","gold"]:
		var weights: Array = menu.hub.Economy.ODDS[kind]
		odds.text += "\n%s: %s%% / %s%% / %s%% / %s%% / %s%%" % [kind.capitalize(),weights[0],weights[1],weights[2],weights[3],weights[4]]
	odds.text += "\n10% of gold legendary drops are +1; any legendary resets pity.\nMythic is not in chests."
	odds.custom_minimum_size = Vector2(418,84)
