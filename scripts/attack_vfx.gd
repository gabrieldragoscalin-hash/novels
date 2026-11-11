extends RefCounted
## Fixed-cell painted animation frames: constant registration throughout each sequence.
const IMPACT: Texture2D = preload("res://art/sanctuary/vfx_impact.png")
const STRIKES: Texture2D = preload("res://art/sanctuary/vfx_strikes.png")
const SHOTS: Texture2D = preload("res://art/sanctuary/vfx_shots.png")
const CLIPS := {
	"explosion":[0,0,8],"meteor":[0,8,4],"rock":[0,12,4],
	"slash":[1,0,4],"wave":[1,4,4],"laser":[1,8,4],"chakram":[1,12,4],
	"arrow":[2,0,4],"bolt":[2,4,4],"magic":[2,8,4],"hit":[2,12,4]
}
static var frames: Dictionary = {}
static func frame(kind: String, index: int) -> AtlasTexture:
	var clip: Array = CLIPS[kind]
	index = clampi(index,0,int(clip[2])-1)
	var key := kind+str(index)
	if frames.has(key): return frames[key]
	var source: Texture2D = [IMPACT,STRIKES,SHOTS][clip[0]]
	var cell: int = clip[1]+index
	var left := floori((cell%4)*source.get_width()/4.0)
	var top := floori(int(cell/4)*source.get_height()/4.0)
	var right := floori((cell%4+1)*source.get_width()/4.0)
	var bottom := floori((int(cell/4)+1)*source.get_height()/4.0)
	var texture := AtlasTexture.new(); texture.atlas = source
	texture.region = Rect2(left,top,right-left,bottom-top); texture.filter_clip = true
	frames[key] = texture; return texture
static func prepare() -> void:
	for kind in CLIPS:
		for index in range(CLIPS[kind][2]): frame(kind,index)
static func at(kind: String, progress: float) -> AtlasTexture:
	return frame(kind,int(clampf(progress,0,0.9999)*CLIPS[kind][2]))
