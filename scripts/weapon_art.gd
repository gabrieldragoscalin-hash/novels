extends RefCounted
const Art = preload("res://scripts/game_art.gd")
## Local hand attachment. One authored sprite per weapon; attack transforms are weapon-specific.
static func draw_held(canvas: CanvasItem, weapon: String, hand: Vector2, direction: Vector2, attack: float, scale_factor: float = 1.0, reverse: bool = false, portrait: bool = false) -> void:
	var texture := Art.frame("weapon_"+weapon)
	var progress := clampf(1.0-attack/0.24,0,1)
	var rotation := 0.0 if portrait else direction.angle()+(-PI/2 if weapon=="sword" else PI/2)
	var offset := Vector2.ZERO
	var length: float = {"bow":30.0,"crossbow":27.0,"wand":30.0,"sword":39.0,"hammer":38.0,"chakram":23.0}.get(weapon,30.0)*scale_factor
	if not portrait and attack>0:
		match weapon:
			"sword": rotation += lerpf(-1.3,1.3,progress)*(-1 if reverse else 1)
			"hammer": rotation += lerpf(-1.1,0.4,progress)
			"bow": offset = -direction*sin(progress*PI)*4*scale_factor
			"crossbow": offset = -direction*(1-progress)*5*scale_factor
			"wand": offset = direction*sin(progress*PI)*4*scale_factor
			"chakram": rotation += progress*TAU
	var width := length*texture.get_width()/texture.get_height()
	canvas.draw_set_transform(hand+offset,rotation)
	var grip: float = {"bow":0.52,"crossbow":0.82,"wand":0.75,"sword":0.18,"hammer":0.82,"chakram":0.5}.get(weapon,0.5)
	canvas.draw_texture_rect(texture,Rect2(-width/2,-length*grip,width,length),false)
	canvas.draw_circle(Vector2.ZERO,1.5*scale_factor,Color("6c5034"))
	canvas.draw_set_transform(Vector2.ZERO)
