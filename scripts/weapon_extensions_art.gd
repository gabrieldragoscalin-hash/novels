extends RefCounted
const SHEET: Texture2D = preload("res://art/champions/aster_extensions.png")
const FRAMES := {"weapon_spear": [253, 6, 40, 489], "inventory_spear": [149, 497, 238, 518], "weapon_dual_axe": [689, 89, 151, 307], "inventory_dual_axe": [579, 525, 369, 491], "weapon_club": [1221, 10, 116, 469], "inventory_club": [1145, 509, 269, 507]}
static var cache: Dictionary = {}
static func frame(key: String) -> AtlasTexture:
	if cache.has(key): return cache[key]
	var rect: Array = FRAMES[key]
	var texture := AtlasTexture.new(); texture.atlas = SHEET; texture.region = Rect2(rect[0],rect[1],rect[2],rect[3]); texture.filter_clip = true
	cache[key] = texture; return texture
