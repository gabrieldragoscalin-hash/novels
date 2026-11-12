extends SceneTree
func bounds(image: Image, cell: Rect2i) -> Rect2i:
	var low := cell.end; var high := cell.position
	var data := image.get_data()
	for y in range(cell.position.y,cell.end.y):
		for x in range(cell.position.x,cell.end.x):
			if data[(y*image.get_width()+x)*4+3]<64: continue
			low.x = mini(low.x,x); low.y = mini(low.y,y); high.x = maxi(high.x,x); high.y = maxi(high.y,y)
	assert(high.x>low.x and high.y>low.y)
	return Rect2i(low,high-low+Vector2i.ONE).grow(2).intersection(cell)
func _initialize() -> void:
	var regions := {}
	for skin in ["aster","guard"]:
		var image := Image.load_from_file("res://prototypes/animation_lab/art/"+skin+".png"); image.convert(Image.FORMAT_RGBA8)
		for view in range(3):
			for part in range(8):
				var x := part%4; var y := view*2+int(part/4)
				var cell := Rect2i(x*image.get_width()/4,y*image.get_height()/6,image.get_width()/4,image.get_height()/6)
				regions[skin+"_"+["front","back","side"][view]+"_"+["head","torso","upper","lower","hand","thigh","shin","cape"][part]] = bounds(image,cell)
	for group in ["weapons","hands"]:
		var image := Image.load_from_file("res://prototypes/animation_lab/art/"+group+".png"); image.convert(Image.FORMAT_RGBA8)
		var rows := 1 if group=="weapons" else 2
		for row in range(rows):
			for col in range(3):
				var cell := Rect2i(col*image.get_width()/3,row*image.get_height()/rows,image.get_width()/3,image.get_height()/rows)
				var key: String = ["sun_bow","moon_bow","hammer"][col] if group=="weapons" else ["aster","guard"][row]+"_grip_"+["front","back","side"][col]
				regions[key] = bounds(image,cell)
	var file := FileAccess.open("res://prototypes/animation_lab/generated/atlas.gd",FileAccess.WRITE)
	file.store_string("extends RefCounted\n# UV metadata only. Source pixels unchanged.\nconst REGIONS := "+var_to_str(regions)+"\n")
	print("Lab: generated %d frame bounds" % regions.size()); quit()
