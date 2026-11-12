extends RefCounted
const Atlas = preload("res://prototypes/animation_lab/generated/atlas.gd")
const SHEETS := {
	"aster":preload("res://prototypes/animation_lab/art/aster.png"),
	"guard":preload("res://prototypes/animation_lab/art/guard.png"),
	"hands":preload("res://prototypes/animation_lab/art/hands.png"),
	"weapons":preload("res://prototypes/animation_lab/art/weapons.png")
}
# Artwork-facing metadata, independent of champion and animation clips.
const WEAPONS := {
	"sun_bow":preload("res://prototypes/animation_lab/generated/sun_bow.tres"),
	"moon_bow":preload("res://prototypes/animation_lab/generated/moon_bow.tres"),
	"hammer":preload("res://prototypes/animation_lab/generated/hammer.tres")
}
static var cache := {}
static func frame(key: String) -> AtlasTexture:
	if WEAPONS.has(key): return WEAPONS[key].texture
	if cache.has(key): return cache[key]
	var source: Texture2D = SHEETS["weapons"] if WEAPONS.has(key) else (SHEETS["hands"] if "_grip_" in key else SHEETS[key.get_slice("_",0)])
	var texture := AtlasTexture.new(); texture.atlas = source; texture.region = Atlas.REGIONS[key]; texture.filter_clip = true
	cache[key] = texture; return texture
