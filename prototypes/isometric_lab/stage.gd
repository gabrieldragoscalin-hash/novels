extends RefCounted
const M = preload("res://prototypes/isometric_lab/models.gd")
const Paint = preload("res://prototypes/isometric_lab/paint.gd")
const MAIN := [Vector2(-10,-9),Vector2(10,-9),Vector2(10,8),Vector2(-10,8)]
const WEST := [Vector2(-17,-5),Vector2(-15,-7),Vector2(-12,-7),Vector2(-11,-5),Vector2(-11,0),Vector2(-16,0)]
const LINK := [Vector2(-12,-2.5),Vector2(-8,-2.5),Vector2(-8,-0.5),Vector2(-12,-0.5)]
const STAIRS := [Vector2(-2.1,-10.5),Vector2(2.1,-10.5),Vector2(2.1,-7),Vector2(-2.1,-7)]
const TERRACE := [Vector2(-5,-14),Vector2(5,-14),Vector2(5,-10),Vector2(-5,-10)]
const POLYGONS := [MAIN,WEST,LINK,STAIRS,TERRACE]
const PIT := Rect2(-2.5,-1,5,4)
static func height_at(pos: Vector2) -> float: return clampf((-pos.y-7)/3,0,1)*1.25 if pos.y<-7 and (absf(pos.x)<2.2 or pos.y<=-10) else 0.0
static func floor_contains(pos: Vector2) -> bool:
	if PIT.has_point(pos): return false
	for polygon in POLYGONS:
		if Geometry2D.is_point_in_polygon(pos,PackedVector2Array(polygon)): return true
	return false
static func blocked(pos: Vector2, obstacles: Array, radius: float = 0.28) -> bool:
	if PIT.grow(radius+0.24).has_point(pos): return true # Stone lip has real thickness.
	for offset in [Vector2.ZERO,Vector2(radius,0),Vector2(-radius,0),Vector2(0,radius),Vector2(0,-radius),Vector2(radius,radius)*0.707,Vector2(-radius,radius)*0.707,Vector2(radius,-radius)*0.707,Vector2(-radius,-radius)*0.707]:
		if not floor_contains(pos+offset): return true
	for rect in obstacles:
		if rect.grow(radius).has_point(pos): return true
	return false
static func point(pos: Vector2) -> Vector3: return Vector3(pos.x,height_at(pos),pos.y)
static func plate(parent: Node3D, polygon: Array, height: float, color: String, depth: float = 0.8) -> void:
	var triangles:=Geometry2D.triangulate_polygon(PackedVector2Array(polygon))
	var top:=SurfaceTool.new(); top.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in triangles:
		top.set_normal(Vector3.UP); top.add_vertex(Vector3(polygon[index].x,height,polygon[index].y))
	var n:=MeshInstance3D.new(); n.mesh=top.commit(); var mat:=M.material(color).duplicate(); mat.cull_mode=BaseMaterial3D.CULL_DISABLED; n.material_override=Paint.surface("floor"); parent.add_child(n)
	var side:=SurfaceTool.new(); side.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(polygon.size()):
		var a: Vector2=polygon[i]; var b: Vector2=polygon[(i+1)%polygon.size()]
		var normal:=Vector3(b.y-a.y,0,a.x-b.x).normalized()
		for v in [Vector3(a.x,height,a.y),Vector3(b.x,height,b.y),Vector3(a.x,height-depth,a.y),Vector3(b.x,height,b.y),Vector3(b.x,height-depth,b.y),Vector3(a.x,height-depth,a.y)]: side.set_normal(normal); side.add_vertex(v)
	var wall:=MeshInstance3D.new(); wall.mesh=side.commit(); var wall_mat:=M.material("45505c").duplicate(); wall_mat.cull_mode=BaseMaterial3D.CULL_DISABLED; wall.material_override=Paint.surface("wall"); parent.add_child(wall)
	# Bronze rim is modeled at the same coordinates as the actual floor boundary.
	for i in range(polygon.size()):
		var a: Vector2=polygon[i]; var b: Vector2=polygon[(i+1)%polygon.size()]; var mid: Vector2=(a+b)/2
		var rim:=M.box(parent,Vector3(mid.x,height+0.02,mid.y),Vector3(a.distance_to(b),0.07,0.10),"53654c")
		rim.rotation.y=-atan2(b.y-a.y,b.x-a.x)
static func rect_polygon(rect: Rect2) -> Array:
	return [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
static func stone(parent: Node3D, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var n:=M.box(parent,pos,size,"34463f"); n.material_override=Paint.surface("wall"); return n
static func build(parent: Node3D) -> Array[Rect2]:
	var obstacles: Array[Rect2]=[]
	# Four floor wings surround a genuine hole, not a decal painted on solid ground.
	for rect in [Rect2(-10,-9,20,8),Rect2(-10,-1,7.5,4),Rect2(2.5,-1,7.5,4),Rect2(-10,3,20,5)]: plate(parent,rect_polygon(rect),0,"243d35",2.8)
	plate(parent,WEST,0,"283d36",2.8); plate(parent,LINK,0,"354d3b",2.8); plate(parent,TERRACE,1.25,"2d4439",4.05)
	for i in range(10): stone(parent,Vector3(0,(i+1)*0.125/2,-7.15-i*0.3),Vector3(4.2,(i+1)*0.125,0.32))
	# Deep black well and carved rim. The lining descends from the same floor boundary.
	M.box(parent,Vector3(0,-2.85,1),Vector3(5,0.08,4),"071210")
	for p in [Vector3(-2.5,-1.4,1),Vector3(2.5,-1.4,1)]: stone(parent,p,Vector3(0.18,2.8,4))
	for p in [Vector3(0,-1.4,-1),Vector3(0,-1.4,3)]: stone(parent,p,Vector3(5,2.8,0.18))
	for p in [Vector3(-2.58,0.14,1),Vector3(2.58,0.14,1)]: stone(parent,p,Vector3(0.32,0.28,4.3))
	for p in [Vector3(0,0.14,-1.08),Vector3(0,0.14,3.08)]: stone(parent,p,Vector3(5.5,0.28,0.32))
	# Tall north/west walls face the playable camera; near walls are cut away.
	for rect in [Rect2(-10,-9.5,7.7,1),Rect2(2.3,-9.5,7.7,1),Rect2(-10.5,-9,1,6.2),Rect2(-10.5,-0.25,1,8.25),Rect2(9.5,-9,1,3)]:
		wall(parent,rect,6.3); obstacles.append(rect)
	# North exit remains a real opening leading up the stairs.
	stone(parent,Vector3(0,5.3,-9),Vector3(4.7,1.1,1.2))
	for side in [-1,1]:
		column(parent,Vector3(side*2.65,0,-8.6),5.4,0.60)
		obstacles.append(Rect2(Vector2(side*2.65-0.65,-9.25),Vector2(1.3,1.3)))
	# Two monumental relief portals; their frames are architecture, not freestanding billboards.
	for x in [-6.1,6.1]: portal(parent,Vector3(x,0,-8.40))
	# Large damaged pillars, rubble and low sarcophagi give deliberate cover positions.
	for pos in [Vector2(-8,-6),Vector2(8,-6),Vector2(-8,5),Vector2(8,5)]:
		column(parent,point(pos),5.5 if pos.y<0 else 2.3,0.92)
		obstacles.append(Rect2(pos-Vector2.ONE*1.0,Vector2.ONE*2.0))
	for pos in [Vector2(-4,2),Vector2(4,-1)]:
		stone(parent,point(pos)+Vector3(0,0.40,0),Vector3(1.8,0.8,0.8))
		stone(parent,point(pos)+Vector3(0,0.84,0),Vector3(2.0,0.16,1.0))
		M.box(parent,point(pos)+Vector3(0,0.94,0),Vector3(1.65,0.03,0.72),"52604a")
		obstacles.append(Rect2(pos-Vector2(0.9,0.4),Vector2(1.8,0.8)))
	# A quieter west shrine replaces the bright tree island.
	for rect in [Rect2(-17.3,-7,1,7),Rect2(-17,-7.4,6,1),Rect2(-17,-0.4,6,0.8)]: wall(parent,rect,4.2); obstacles.append(rect)
	column(parent,Vector3(-14,0,-5),3.8,0.7); obstacles.append(Rect2(-14.8,-5.8,1.6,1.6))
	for pos in [Vector2(-4.3,-7.5),Vector2(4.3,-7.5),Vector2(-3.4,3.8),Vector2(6,5)]: candles(parent,point(pos),pos.x>0)
	for pos in [Vector2(-8.7,-3.3),Vector2(8.4,-3.1),Vector2(-6.7,-7.7),Vector2(6.8,-7.6)]: urn(parent,point(pos))
	for i in range(15):
		var side: float=-1 if i%2==0 else 1
		var pos:=Vector3(side*(8.7+sin(i*1.3)*0.4),0.12,-7.7+fmod(i*0.37,1.4))
		var rubble:=stone(parent,pos,Vector3(0.35+fmod(i*0.17,0.5),0.22,0.40))
		rubble.rotation=Vector3(0.1*sin(i),float(i),0.15*cos(i))
	# Floor medallion lies flush with the paving and uses its own original relief artwork.
	var emblem:=PlaneMesh.new(); emblem.size=Vector2(3,3)
	M.mesh(parent,emblem,Vector3(4.7,0.07,5.0),"334a41").material_override=Paint.surface("medallion")
	# The raised north vault has enclosing walls and a clear entrance, not floating blocks.
	for rect in [Rect2(-5.4,-14.5,10.8,0.7),Rect2(-5.4,-14,0.7,4),Rect2(4.7,-14,0.7,4)]:
		wall(parent,rect,5.2); obstacles.append(rect)
	return obstacles
static func wall(parent: Node3D, footprint: Rect2, height: float) -> void:
	var center:=footprint.get_center()
	stone(parent,Vector3(center.x,height/2,center.y),Vector3(footprint.size.x,height,footprint.size.y))
	for y in [0.22,0.48,height-0.45,height-0.15]:
		stone(parent,Vector3(center.x,y,center.y),Vector3(footprint.size.x+0.16,0.12,footprint.size.y+0.16))
	for y in [0.55,height-0.60]: M.box(parent,Vector3(center.x,y,center.y),Vector3(footprint.size.x+0.19,0.055,footprint.size.y+0.19),"647256")
static func portal(parent: Node3D, base: Vector3) -> void:
	M.box(parent,base+Vector3(0,2.5,0.02),Vector3(3.4,4.9,0.10),"061211")
	for side in [-1,1]:
		stone(parent,base+Vector3(side*1.75,2.7,0.24),Vector3(0.48,5.4,0.58))
		for i in range(3): M.box(parent,base+Vector3(side*(1.60+i*0.10),2.7,0.55),Vector3(0.035,4.9,0.025),"738266")
	stone(parent,base+Vector3(0,5.2,0.3),Vector3(4.0,0.38,0.85))
	stone(parent,base+Vector3(0,0.12,0.65),Vector3(3.9,0.24,2.1))
	var image:=QuadMesh.new(); image.size=Vector2(3.05,4.6)
	M.mesh(parent,image,base+Vector3(0,2.55,0.09),"284737").material_override=Paint.surface("relief")
	for side in [-1,1]: urn(parent,base+Vector3(side*2.05,0,1.0))
static func column(parent: Node3D, pos: Vector3, height: float, radius: float) -> void:
	stone(parent,pos+Vector3(0,0.14,0),Vector3(radius*2.6,0.28,radius*2.6))
	M.cylinder(parent,pos+Vector3(0,height/2+0.25,0),radius,height,"35483b",radius*0.88).material_override=Paint.surface("wall")
	for y in [0.45,0.70,height*0.50,height*0.82,height+0.20]:
		M.cylinder(parent,pos+Vector3(0,y,0),radius*1.05,0.16,"24372e").material_override=Paint.surface("wall")
	if height>4:
		stone(parent,pos+Vector3(0,height+0.35,0),Vector3(radius*2.5,0.28,radius*2.5))
	else:
		var broken:=stone(parent,pos+Vector3(0,height+0.25,0),Vector3(radius*1.7,0.20,radius*1.6)); broken.rotation.z=0.10
static func candles(parent: Node3D, pos: Vector3, green: bool = true) -> void:
	for i in range(3):
		var p:=pos+Vector3(i*0.16,0,absf(sin(i))*0.12)
		var height:=0.22+i*0.085
		M.cylinder(parent,p+Vector3(0,height/2,0),0.05,height,"adae74")
		var flame_color: String="86e3a1" if green else "e9ce82"
		M.cylinder(parent,p+Vector3(0,height+0.10,0),0.055,0.25,flame_color,0).material_override=M.material(flame_color,true)
static func urn(parent: Node3D, pos: Vector3) -> void:
	M.cylinder(parent,pos+Vector3(0,0.40,0),0.24,0.65,"61705b",0.34)
	for y in [0.16,0.45,0.64]: M.cylinder(parent,pos+Vector3(0,y,0),0.31,0.04,"202f29")
	M.cylinder(parent,pos+Vector3(0,0.78,0),0.17,0.16,"4a5e4c",0.17)
	M.cylinder(parent,pos+Vector3(0,0.87,0),0.23,0.06,"829075")
