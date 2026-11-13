extends RefCounted
const Art = preload("res://scripts/game_art.gd")
## Weapon geometry is attached at its real grip; the rig draws fingers over it.
const GRIPS := {"spear":Vector2(0.5,0.62),"dual_axe":Vector2(0.5,0.85),"club":Vector2(0.5,0.86),"bow":Vector2(0.52,0.52),"crossbow":Vector2(0.50,0.66),"wand":Vector2(0.50,0.70),"sword":Vector2(0.50,0.18),"hammer":Vector2(0.50,0.77),"chakram":Vector2(0.16,0.50)}
const LENGTHS := {"spear":61.0,"dual_axe":27.0,"club":46.0,"bow":30.0,"crossbow":28.0,"wand":29.0,"sword":36.0,"hammer":35.0,"chakram":20.0}
static func draw_gripped(canvas: CanvasItem, weapon: String, grip: Vector2, angle: float, tint: Color = Color.WHITE) -> void:
	var texture := Art.frame("weapon_"+weapon)
	var rotation := angle
	if weapon in ["crossbow","wand","hammer","spear","dual_axe","club"]: rotation += PI/2
	elif weapon=="sword": rotation -= PI/2
	var length: float = LENGTHS[weapon]
	var width := length*texture.get_width()/texture.get_height()
	canvas.draw_set_transform(grip,rotation)
	canvas.draw_texture_rect(texture,Rect2(-Vector2(width,length)*GRIPS[weapon],Vector2(width,length)),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
