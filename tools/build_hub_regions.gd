extends SceneTree
## Extract tight UVs only. Generated source artwork is never modified.
const KEYS := ["shop","inventory","play","perks","miscellaneous","settings","bag","details","tasks","login","privileges","event"]
func _initialize() -> void:
	var image := Image.load_from_file("res://art/hub/icons.png")
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	var frames := {}
	for i in range(KEYS.size()):
		var cell := Rect2i(i%4*image.get_width()/4,int(i/4)*image.get_height()/3,image.get_width()/4,image.get_height()/3)
		var low := cell.end; var high := cell.position
		for y in range(cell.position.y,cell.end.y):
			for x in range(cell.position.x,cell.end.x):
				if data[(y*image.get_width()+x)*4+3]<32: continue
				low.x = mini(low.x,x); low.y = mini(low.y,y); high.x = maxi(high.x,x); high.y = maxi(high.y,y)
		assert(high.x>low.x and high.y>low.y)
		frames[KEYS[i]] = [maxi(cell.position.x,low.x-2),maxi(cell.position.y,low.y-2),mini(cell.end.x,high.x+3)-maxi(cell.position.x,low.x-2),mini(cell.end.y,high.y+3)-maxi(cell.position.y,low.y-2)]
	var file := FileAccess.open("res://scripts/hub_art_regions.gd",FileAccess.WRITE)
	file.store_string("extends RefCounted\n# Generated atlas UVs. Source pixels untouched.\nconst FRAMES := "+var_to_str(frames)+"\n")
	print("Generated twelve hub icon regions")
	quit()
