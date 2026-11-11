extends RefCounted
## Rendering-only asset catalog. Gameplay coordinates/collision never depend on art.
const Layout = preload("res://scripts/art_regions.gd")
const ROOM: Texture2D = preload("res://art/sanctuary/room.png")
const CORRUPTION: Texture2D = preload("res://art/sanctuary/corruption.png")
const ACTORS: Texture2D = preload("res://art/sanctuary/actors.png")
const PROPS: Texture2D = preload("res://art/sanctuary/props.png")
const ACTOR_KEYS := ["hero_front","hero_back","normal","shooter","brute","boss","miniboss","merchant"]
const PROP_KEYS := ["pillar","chest_closed","chest_open","shop","healer","upgrade","wheel","exit"]
const REGIONS := [
	{"first":1,"last":10,"name":"The Fallen Sanctuary","production":true},
	{"first":11,"last":20,"name":"The Crimson Court","production":false},
	{"first":21,"last":30,"name":"The Ashen Foundries","production":false},
	{"first":31,"last":40,"name":"The Living Depths","production":false},
	{"first":41,"last":50,"name":"The Hollow Throne","production":false}
]
static var prepared := false
static var frames: Dictionary = {}

static func frame(key: String) -> AtlasTexture:
	if frames.has(key): return frames[key]
	var actor := ACTOR_KEYS.has(key)
	var keys: Array = ACTOR_KEYS if actor else PROP_KEYS
	assert(keys.has(key),"Unknown art frame: "+key)
	var source: Texture2D = ACTORS if actor else PROPS
	var bounds: Array = Layout.FRAMES[key]
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
	texture.filter_clip = true
	frames[key] = texture
	return texture

static func stage(floor_number: int) -> float:
	return clampf((floor_number-3)/7.0,0.0,1.0)

static func floor_tint(floor_number: int) -> Color:
	return Color.WHITE.lerp(Color(0.84,0.84,0.92),stage(floor_number))

static func region(floor_number: int) -> Dictionary:
	for entry in REGIONS:
		if floor_number>=entry["first"] and floor_number<=entry["last"]: return entry
	return {"first":51,"last":100,"name":"Uncharted depths","production":false}

static func prepare() -> void:
	if prepared: return
	for key in ACTOR_KEYS: frame(key)
	for key in PROP_KEYS: frame(key)
	prepared = true

static func pivot(key: String) -> float:
	return float(Layout.PIVOTS.get(key,0.5))
