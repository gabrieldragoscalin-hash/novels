extends RefCounted
const M = preload("res://prototypes/isometric_lab/models.gd")
const MAIN := [Vector2(-10,-5),Vector2(-6,-9),Vector2(6,-9),Vector2(10,-5),Vector2(10,4),Vector2(6,8),Vector2(-6,8),Vector2(-10,4)]
const WEST := [Vector2(-17,-5),Vector2(-15,-7),Vector2(-12,-7),Vector2(-11,-5),Vector2(-11,0),Vector2(-16,0)]
const LINK := [Vector2(-12,-2.5),Vector2(-8,-2.5),Vector2(-8,-0.5),Vector2(-12,-0.5)]
const STAIRS := [Vector2(-2.1,-10.5),Vector2(2.1,-10.5),Vector2(2.1,-7),Vector2(-2.1,-7)]
const TERRACE := [Vector2(-5,-14),Vector2(5,-14),Vector2(5,-10),Vector2(-5,-10)]
const POLYGONS := [MAIN,WEST,LINK,STAIRS,TERRACE]
static func height_at(pos: Vector2) -> float: return clampf((-pos.y-7)/3,0,1)*1.25 if pos.y<-7 and (absf(pos.x)<2.2 or pos.y<=-10) else 0.0
static func floor_contains(pos: Vector2) -> bool:
	for polygon in POLYGONS:
		if Geometry2D.is_point_in_polygon(pos,PackedVector2Array(polygon)): return true
	return false
static func blocked(pos: Vector2, obstacles: Array, radius: float = 0.28) -> bool:
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
	var n:=MeshInstance3D.new(); n.mesh=top.commit(); var mat:=M.material(color).duplicate(); mat.cull_mode=BaseMaterial3D.CULL_DISABLED; n.material_override=mat; parent.add_child(n)
	var side:=SurfaceTool.new(); side.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(polygon.size()):
		var a: Vector2=polygon[i]; var b: Vector2=polygon[(i+1)%polygon.size()]
		var normal:=Vector3(b.y-a.y,0,a.x-b.x).normalized()
		for v in [Vector3(a.x,height,a.y),Vector3(b.x,height,b.y),Vector3(a.x,height-depth,a.y),Vector3(b.x,height,b.y),Vector3(b.x,height-depth,b.y),Vector3(a.x,height-depth,a.y)]: side.set_normal(normal); side.add_vertex(v)
	var wall:=MeshInstance3D.new(); wall.mesh=side.commit(); var wall_mat:=M.material("45505c").duplicate(); wall_mat.cull_mode=BaseMaterial3D.CULL_DISABLED; wall.material_override=wall_mat; parent.add_child(wall)
	# Bronze rim is modeled at the same coordinates as the actual floor boundary.
	for i in range(polygon.size()):
		var a: Vector2=polygon[i]; var b: Vector2=polygon[(i+1)%polygon.size()]; var mid: Vector2=(a+b)/2
		var rim:=M.box(parent,Vector3(mid.x,height+0.02,mid.y),Vector3(a.distance_to(b),0.07,0.10),"bf9b65")
		rim.rotation.y=-atan2(b.y-a.y,b.x-a.x)
static func build(parent: Node3D) -> Array[Rect2]:
	var obstacles: Array[Rect2]=[]
	plate(parent,MAIN,0,"477b75"); plate(parent,WEST,0,"b5ad92"); plate(parent,LINK,0.04,"bead86"); plate(parent,TERRACE,1.25,"d6c9a7",2.05)
	for i in range(10): M.box(parent,Vector3(0,(i+1)*0.125/2,-7.15-i*0.3),Vector3(4.2,(i+1)*0.125,0.32),"baae8e" if i%2==0 else "d2bd92")
	# Wide joints instead of a baked room image: slabs follow the real platforms.
	for x in range(-9,10,2):
		for z in range(-8,8,2):
			var pos:=Vector2(x,z)
			if [Vector2(-0.98,-0.98),Vector2(0.98,-0.98),Vector2(0.98,0.98),Vector2(-0.98,0.98)].all(func(offset): return floor_contains(pos+offset)):
				var tile:=M.box(parent,Vector3(x,0.012,z),Vector3(1.95,0.025,1.95),["497d76","4d8077","53847b"][posmod(x*3+z,3)])
				tile.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for pos in [Vector2(-7,-4),Vector2(7,-4),Vector2(-7,4),Vector2(7,4),Vector2(-3,-12),Vector2(3,-12)]:
		column(parent,point(pos),3.3 if pos.y<-10 else 2.5); obstacles.append(Rect2(pos-Vector2.ONE*0.48,Vector2.ONE*0.96))
	# Broken colonnade and a hanging crimson banner frame the high terrace.
	M.box(parent,Vector3(0,4.75,-12),Vector3(7.7,0.40,0.9),"d3c5a3")
	M.box(parent,Vector3(0,4.98,-12),Vector3(8,0.10,1.05),"bb925b")
	M.box(parent,Vector3(0,3.4,-11.92),Vector3(1.35,2.2,0.05),"b64352")
	M.box(parent,Vector3(0,3.5,-11.87),Vector3(0.10,1.8,0.025),"dfb45c")
	for pos in [Vector2(-4,2),Vector2(4,-1)]:
		M.box(parent,point(pos)+Vector3(0,0.38,0),Vector3(1.8,0.75,0.8),"b7b495")
		M.box(parent,point(pos)+Vector3(0,0.78,0),Vector3(1.9,0.12,0.95),"dfc68b")
		obstacles.append(Rect2(pos-Vector2(0.9,0.4),Vector2(1.8,0.8)))
	for pos in [Vector2(-8,1),Vector2(8,1),Vector2(-4,-13),Vector2(4,-13)]: brazier(parent,point(pos))
	# A red-leaf tree gives the side terrace a distinct silhouette and a warm destination.
	var tree:=Vector3(-14,0,-4)
	M.cylinder(parent,tree+Vector3(0,1.1,0),0.20,2.2,"725053",0.13)
	for i in range(5):
		var a:=i*TAU/5
		M.orb(parent,tree+Vector3(sin(a),2.8+i*0.1,cos(a)*0.6),Vector3(2.1,1.5,1.8),["b95750","d27858","af414e"][i%3])
	obstacles.append(Rect2(Vector2(-14.3,-4.3),Vector2(0.6,0.6)))
	# Embers beneath the architecture, with no costly particles or screen-space effects.
	for i in range(18):
		var a:=i*TAU/18
		var rock:=M.cylinder(parent,Vector3(sin(a)*15,-3.5,cos(a)*15),2.1,5,"303a50",0.35)
		rock.rotation.z=sin(i)*0.15
	for i in range(14):
		var line:=M.box(parent,Vector3(-24+i*3.5,-4.5,-4+sin(i*0.8)*10),Vector3(0.45,0.10,42),"d37159",true); line.rotation.y=0.30
	return obstacles
static func column(parent: Node3D, pos: Vector3, height: float) -> void:
	M.box(parent,pos+Vector3(0,0.12,0),Vector3(1.1,0.24,1.1),"a7a38d")
	M.cylinder(parent,pos+Vector3(0,height/2+0.2,0),0.39,height,"d7cfaf",0.31)
	M.cylinder(parent,pos+Vector3(0,0.4,0),0.43,0.10,"c79e58")
	M.box(parent,pos+Vector3(0,height+0.27,0),Vector3(0.95,0.20,0.95),"d5ba80")
static func brazier(parent: Node3D, pos: Vector3) -> void:
	M.cylinder(parent,pos+Vector3(0,0.38,0),0.22,0.76,"61545a",0.15)
	M.cylinder(parent,pos+Vector3(0,0.82,0),0.36,0.15,"c19a63",0.27)
	M.orb(parent,pos+Vector3(0,1.15,0),Vector3(0.37,0.75,0.37),"f5bf71").material_override=M.material("f5bf71",true)
