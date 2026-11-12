extends SceneTree
const Atlas = preload("res://prototypes/animation_lab/generated/atlas.gd")
func _initialize() -> void:
	var sheet := load("res://prototypes/animation_lab/art/weapons.png")
	for id in ["sun_bow","moon_bow","hammer"]:
		var profile = load("res://prototypes/animation_lab/weapon_profile.gd").new()
		var texture := AtlasTexture.new(); texture.atlas = sheet; texture.region = Atlas.REGIONS[id]; texture.filter_clip = true
		profile.texture = texture; profile.display_name = {"sun_bow":"Sun bow","moon_bow":"Moon bow","hammer":"War hammer"}[id]
		profile.family = "hammer" if id=="hammer" else "bow"
		profile.size = {"sun_bow":Vector2(43,72),"moon_bow":Vector2(40,72),"hammer":Vector2(38,76)}[id]
		profile.grip_x = {"sun_bow":0.837,"moon_bow":0.828,"hammer":0.5}[id]
		profile.grip_y = 0.8 if id=="hammer" else 0.5
		profile.string_x = -35 if id=="sun_bow" else -32
		profile.tips = Vector2(-35 if id=="sun_bow" else -32,33)
		assert(ResourceSaver.save(profile,"res://prototypes/animation_lab/generated/"+id+".tres")==OK)
	print("Saved three editable weapon attachment profiles"); quit()
