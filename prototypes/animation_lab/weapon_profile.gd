extends Resource
## Artist-facing attachment data. No character-specific animation belongs here.
@export var display_name := "Weapon"
@export_enum("bow","hammer") var family := "bow"
@export var texture: AtlasTexture
@export var size := Vector2(43,72)
@export_range(0,1,0.001) var grip_x := 0.5
@export_range(0,1,0.001) var grip_y := 0.5
@export var string_x := -31.0
@export var tips := Vector2(-30,33)
@export var support := Vector2(0,-13)
var grip: Vector2:
	get: return Vector2(grip_x,grip_y)
