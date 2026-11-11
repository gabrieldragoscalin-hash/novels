extends RefCounted
## Each texture is a complete painting, including all fixed scenery and shadows.
## The common framing places the painted floor at world y166..604.
const RECT := Rect2(0,91,480,576)
const TEXTURES: Array[Texture2D] = [
	preload("res://art/rooms/00_quiet_sanctuary.png"),
	preload("res://art/rooms/01_weathered_flagstones.png"),
	preload("res://art/rooms/02_broken_corners.png"),
	preload("res://art/rooms/03_split_crypt.png"),
	preload("res://art/rooms/04_jade_waterway.png"),
	preload("res://art/rooms/05_molten_aqueduct.png"),
	preload("res://art/rooms/06_drowned_court.png"),
	preload("res://art/rooms/07_ruined_cloister.png"),
	preload("res://art/rooms/08_twin_watercourses.png"),
	preload("res://art/rooms/09_ember_crossing.png")
]
static func texture(layout: int) -> Texture2D: return TEXTURES[posmod(layout,TEXTURES.size())]
