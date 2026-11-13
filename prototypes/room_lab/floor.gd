extends Node2D
## Cached stage geometry; changing a floor plan changes both its drawing and collision.
const TILES: Texture2D = preload("res://art/sanctuary/arena_floor.png")
const Plans = preload("res://prototypes/room_lab/layouts.gd")
var plan: Dictionary = {}
func configure(value: Dictionary) -> void: plan=value; queue_redraw()
func _draw() -> void:
	if plan.is_empty(): return
	var lava: bool = plan["index"]==2
	var pale := Color("a48952") if lava else Color("829b83")
	draw_rect(Plans.BOUNDS.grow(Plans.BOUNDS.size.y),Color("150f16") if lava else Color("071418"))
	# Rivers below the causeways; the floor geometry cuts real silhouettes into them.
	for i in range(-10,40):
		var points := PackedVector2Array()
		for j in range(-10,26): points.append(Vector2(i*103+sin(j*0.9+i)*42,j*135))
		draw_polyline(points,Color("762a1b") if lava else Color("102c30"),20)
		draw_polyline(points,Color("d5732d") if lava else Color("205054"),3)
	# Front cliff faces and continuous foundation shadows anchor the architecture.
	for cell in plan["cells"]:
		var pos := Vector2(cell)*Plans.CELL
		if not plan["cells"].has(cell+Vector2i.DOWN):
			draw_rect(Rect2(pos+Vector2(-3,50),Vector2(62,36)),Color(0,0,0,0.45))
			draw_rect(Rect2(pos+Vector2(0,55),Vector2(56,24)),Color("252d2a"))
			draw_line(pos+Vector2(2,76),pos+Vector2(54,76),Color("47463a"),2)
	for cell in plan["cells"]:
		var pos := Vector2(cell)*Plans.CELL
		var link: bool = plan["bridges"].has(cell)
		var variant: float = posmod(cell.x*13+cell.y*7,5)*0.012
		var color := Color("454637") if link else (Color("344638") if lava else Color("29443e"))
		draw_rect(Rect2(pos,Vector2.ONE*56),color.lightened(variant))
		var source:=Rect2(146+posmod(cell.x,3)*140,282+posmod(cell.y,3)*140,132,132)
		draw_texture_rect_region(TILES,Rect2(pos,Vector2.ONE*56),source,Color(0.95,0.83,0.65) if link else Color(0.74,0.85,0.77))
		draw_rect(Rect2(pos+Vector2.ONE,Vector2.ONE*54),Color("958359") if link else Color("3f5448"),false,0.8)
		draw_line(pos+Vector2(3,3),pos+Vector2(53,3),Color(color.lightened(0.16)),1)
		if link: draw_line(pos+Vector2(5,28),pos+Vector2(51,28),Color("77704d"),1)
		elif posmod(cell.x*3+cell.y,17)==0:
			draw_polyline(PackedVector2Array([pos+Vector2(7,2),pos+Vector2(21,17),pos+Vector2(18,26),pos+Vector2(32,39)]),Color("172d29"),1.3)
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			if plan["cells"].has(cell+direction): continue
			var a := pos; var b := pos
			match direction:
				Vector2i.UP: b += Vector2(56,0)
				Vector2i.DOWN: a += Vector2(0,56); b += Vector2(56,56)
				Vector2i.LEFT: b += Vector2(0,56)
				Vector2i.RIGHT: a += Vector2(56,0); b += Vector2(56,56)
			draw_line(a,b,Color("d1b772"),5)
			draw_line(a+Vector2(0,4),b+Vector2(0,4),Color("5b6048"),2)
	# Inlaid court borders and medallions share the floor plane, not decal props.
	for court in plan["courts"]:
		var rect: Rect2 = court["rect"].grow(-37)
		draw_rect(rect,Color("948155"),false,2)
		draw_rect(rect.grow(-7),Color("48604d"),false,1)
		var center: Vector2 = rect.get_center()
		draw_arc(center,34,0,TAU,32,Color("8c8050"),2)
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-27),center+Vector2(17,0),center+Vector2(0,27),center+Vector2(-17,0)]),Color("3d5140"))
