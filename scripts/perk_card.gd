extends Control
## Shared small/large card renderer. Every rank is represented by one actual star.
const Art = preload("res://scripts/perk_visuals.gd")
const HomeArt = preload("res://scripts/hub_art.gd")
var perk_id := "starting_upgrade"
var title := ""
var rank := 0
var locked := true
var large := false
var caption: Label
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	caption = Label.new(); caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; caption.add_theme_font_override("font",HomeArt.SERIF)
	add_child(caption)
	resized.connect(_layout)
func configure(id: String, name_text: String, level: int, sealed: bool = false, big: bool = false) -> void:
	perk_id = id; title = name_text; rank = level; locked = sealed or level==0; large = big
	caption.text = "Locked" if locked else title
	caption.add_theme_color_override("font_color",Color("a1aaa4") if locked else Color("eedcb1"))
	caption.add_theme_font_size_override("font_size",18 if large else 13)
	_layout(); queue_redraw()
func _layout() -> void:
	if caption==null: return
	caption.position = Vector2(7,size.y-63 if large else size.y-36)
	caption.size = Vector2(maxf(1,size.x-14),54 if large else 32)
	pivot_offset = size/2
	queue_redraw()
func star_count() -> int: return 0 if locked else rank
func _draw() -> void:
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("202e2b") if locked else Color("17392f")
	frame.border_color = Color("53605a") if locked else Color("af975c")
	frame.set_border_width_all(2); frame.set_corner_radius_all(7)
	frame.shadow_color = Color(0,0,0,0.4); frame.shadow_size = 4
	draw_style_box(frame,Rect2(Vector2.ZERO,size))
	var tint := Color("6c776a") if locked else Color("d7ba78")
	for x in [8.0,size.x-8]:
		for y in [8.0,size.y-8]:
			draw_colored_polygon(PackedVector2Array([Vector2(x,y-3),Vector2(x+3,y),Vector2(x,y+3),Vector2(x-3,y)]),tint)
	var icon_size := 80.0 if large else clampf(size.y*0.34,40,60)
	var icon_y := 77.0 if large else maxf(39,size.y*0.32)
	if locked: icon_y = size.y*0.25
	var icon: Texture2D = Art.LOCK if locked else Art.ICONS[perk_id]
	draw_texture_rect(icon,Rect2((size.x-icon_size)/2,icon_y,icon_size,icon_size),false,Color("9aa59b") if locked else Color.WHITE)
	if not locked:
		var step := 16.0 if large else 11.0
		for index in range(rank):
			var row := int(index/10); var columns := mini(10,rank-row*10)
			var center := Vector2(size.x/2+(index%10-(columns-1)*0.5)*step,14+row*(step-1))
			var points := PackedVector2Array()
			for k in range(10):
				var angle := -PI/2+k*PI/5
				points.append(center+Vector2(cos(angle),sin(angle))*(step*0.43 if k%2==0 else step*0.19))
			draw_colored_polygon(points,Color("f2cf76"))
