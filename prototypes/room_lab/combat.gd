extends "res://scripts/combat.gd"
## Sandbox-only collision adapter: scenery blocks shots, open void only blocks bodies.
const Plans = preload("res://prototypes/room_lab/layouts.gd")
var walkable: Dictionary = {}
func _init(plan: Dictionary) -> void:
	walkable = plan["cells"]
	var cover: Array[Rect2] = []; cover.assign(plan["cover"])
	super._init(Plans.BOUNDS,cover)
func blocked(point: Vector2, radius: float) -> bool:
	if super.blocked(point,radius): return true
	for offset in [Vector2.ZERO,Vector2(radius,0),Vector2(-radius,0),Vector2(0,radius),Vector2(0,-radius),Vector2(0.707,0.707)*radius,Vector2(-0.707,0.707)*radius,Vector2(0.707,-0.707)*radius,Vector2(-0.707,-0.707)*radius]:
		if not walkable.has(Vector2i(((point+offset)/Plans.CELL).floor())): return true
	return false
func _tick_waves(_delta: float) -> void:
	# This sandbox activates packs by court entry, never by the square-room wave timer.
	pass
